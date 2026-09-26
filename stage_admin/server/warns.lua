--[[
    stage_admin - uyarı sistemi
]]

function AdminWarnPlayer(admin, target, reason)
    if not isElement(target) then return false end
    reason = AdminTrim(reason) ~= "" and reason or "Sebep belirtilmedi"

    local serial = getPlayerSerial(target)
    local name = getPlayerName(target)
    local now = getRealTime().timestamp

    AdminDBExec(
        "INSERT INTO admin_warns (player_name, player_serial, admin_name, reason, created_at, active) VALUES (?, ?, ?, ?, ?, 1)",
        name, serial, isElement(admin) and getPlayerName(admin) or "Console", reason, now
    )

    local count = AdminGetActiveWarnCount(serial)
    AdminLog(admin, name, "warn", reason .. " (" .. count .. ". uyarı)")
    AdminNotify(target, ("%d. Uyarı: %s"):format(count, reason), "warning")

    return true, count
end

function AdminGetActiveWarnCount(serial)
    local rows = AdminDBQuery("SELECT COUNT(*) as c FROM admin_warns WHERE player_serial = ? AND active = 1", serial)
    if #rows == 0 then return 0 end
    return tonumber(rows[1].c) or 0
end

function AdminGetWarnsForSerial(serial)
    return AdminDBQuery("SELECT * FROM admin_warns WHERE player_serial = ? ORDER BY id DESC", serial)
end

function AdminRemoveWarn(admin, warnId)
    warnId = tonumber(warnId)
    if not warnId then return false end
    AdminDBExec("UPDATE admin_warns SET active = 0 WHERE id = ?", warnId)
    AdminLog(admin, "#" .. warnId, "unwarn", "")
    return true
end
