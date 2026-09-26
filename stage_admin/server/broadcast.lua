--[[
    stage_admin - duyuru + admin chat
]]

function AdminBroadcastAnnounce(annType, message)
    local def = Config.AnnounceTypes[annType] or Config.AnnounceTypes.duyuru
    message = AdminTrim(message)
    if message == "" then return false end

    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, "admin:announce", p, annType, def.label, message, def.color)
        pcall(function()
            if exports.stage_core and exports.stage_core.Notify then
                exports.stage_core:Notify(p, message, annType == "uyari" and "warning" or (annType == "hata" and "error" or "info"), def.label or "DUYURU", "", 8000)
            end
        end)
    end
    return true
end

function AdminSendAnnounce(admin, annType, message)
    local ok = AdminBroadcastAnnounce(annType, message)
    if ok then
        AdminLog(admin, "-", "announce", (Config.AnnounceTypes[annType] and Config.AnnounceTypes[annType].label or annType) .. ": " .. message)
    end
    return ok
end

-- ---------------- Admin Chat ----------------

function AdminChatSend(sender, message)
    message = AdminTrim(message)
    if message == "" then return end

    local senderName = isElement(sender) and getPlayerName(sender) or "Console"
    for _, p in ipairs(getElementsByType("player")) do
        if AdminIsStaff(p) then
            triggerClientEvent(p, "admin:chatMessage", p, senderName, message)
        end
    end
end

addCommandHandler(Config.ChatCommand, function(player, _, ...)
    if not AdminHasPermission(player, "achat") then
        AdminNotify(player, "Bu komutu kullanma yetkiniz yok.", "error")
        return
    end
    local message = table.concat({...}, " ")
    if AdminTrim(message) == "" then return end
    AdminChatSend(player, message)
end)
