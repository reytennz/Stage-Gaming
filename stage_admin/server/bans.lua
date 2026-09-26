--[[
    stage_admin - ban sistemi (kendi tablomuz, MTA native ban listesinin üstüne)
]]

local function activeBanForSerial(serial)
    local rows = AdminDBQuery("SELECT * FROM admin_bans WHERE player_serial = ? AND active = 1 ORDER BY id DESC LIMIT 1", serial)
    if #rows == 0 then return nil end
    local row = rows[1]
    local now = getRealTime().timestamp
    if row.expires_at ~= 0 and row.expires_at <= now then
        AdminDBExec("UPDATE admin_bans SET active = 0 WHERE id = ?", row.id)
        return nil
    end
    return row
end

function AdminBanPlayer(admin, target, reason, durationSeconds)
    if not isElement(target) then return false end
    reason = AdminTrim(reason) ~= "" and reason or "Sebep belirtilmedi"
    durationSeconds = tonumber(durationSeconds) or 0

    local serial = getPlayerSerial(target)
    local name = getPlayerName(target)
    local now = getRealTime().timestamp
    local expires = durationSeconds > 0 and (now + durationSeconds) or 0

    AdminDBExec(
        "INSERT INTO admin_bans (player_name, player_serial, admin_name, reason, created_at, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)",
        name, serial, isElement(admin) and getPlayerName(admin) or AdminSafeTostring(admin or "Console"), reason, now, expires
    )

    AdminLog(admin, name, "ban", reason .. " | Süre: " .. AdminFormatDuration(durationSeconds))

    local msg = ("Yasaklandınız.\nSebep: %s\nSüre: %s"):format(reason, AdminFormatDuration(durationSeconds))
    local kicker = isElement(admin) and getPlayerName(admin) or "Stage Admin"
    local kicked = kickPlayer(target, kicker, msg)
    if not kicked then
        outputDebugString("[stage_admin] BAN: kickPlayer başarısız. stage_admin resource için function.kickPlayer ACL yetkisini kontrol edin.", 1)
        AdminNotify(admin, "Ban DB'ye kaydedildi ancak oyuncu atılamadı. ACL: function.kickPlayer yetkisini verin.", "error")
        return false
    end
    return true
end

-- Serial ile offline ban (panelden isim/serial girerek)
function AdminBanBySerial(admin, serial, name, reason, durationSeconds)
    if not serial or serial == "" then return false end
    reason = AdminTrim(reason) ~= "" and reason or "Sebep belirtilmedi"
    durationSeconds = tonumber(durationSeconds) or 0
    local now = getRealTime().timestamp
    local expires = durationSeconds > 0 and (now + durationSeconds) or 0

    AdminDBExec(
        "INSERT INTO admin_bans (player_name, player_serial, admin_name, reason, created_at, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)",
        name or "?", serial, isElement(admin) and getPlayerName(admin) or AdminSafeTostring(admin or "Console"), reason, now, expires
    )
    AdminLog(admin, name or serial, "ban_offline", reason)
    return true
end

function AdminUnban(admin, banId)
    banId = tonumber(banId)
    if not banId then return false end
    AdminDBExec("UPDATE admin_bans SET active = 0 WHERE id = ?", banId)
    AdminLog(admin, "#" .. banId, "unban", "")
    return true
end

function AdminGetActiveBans()
    return AdminDBQuery("SELECT * FROM admin_bans WHERE active = 1 ORDER BY id DESC")
end

function AdminGetBanHistory(limit)
    return AdminDBQuery("SELECT * FROM admin_bans ORDER BY id DESC LIMIT ?", tonumber(limit) or 200)
end

-- Bağlantı anında ban kontrolü
addEventHandler("onPlayerLogin", root, function() end) -- placeholder (RP olmadığından login şart değil)

addEventHandler("onPlayerJoin", root, function()
    local player = source
    local serial = getPlayerSerial(player)
    local ban = activeBanForSerial(serial)
    if ban then
        local remaining = ban.expires_at == 0 and "Süresiz" or AdminFormatDuration(ban.expires_at - getRealTime().timestamp)
        kickPlayer(player, "AntiBan", ("Yasaklısınız. Sebep: %s | Kalan: %s"):format(ban.reason, remaining))
    end
end)
