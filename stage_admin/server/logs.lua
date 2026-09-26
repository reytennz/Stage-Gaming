--[[
    stage_admin - admin log sistemi
]]

function AdminLog(admin, targetName, action, details)
    local adminName = isElement(admin) and getPlayerName(admin) or AdminSafeTostring(admin)
    local now = getRealTime().timestamp

    AdminDBExec(
        "INSERT INTO admin_logs (admin_name, target_name, action, details, created_at) VALUES (?, ?, ?, ?, ?)",
        adminName, AdminSafeTostring(targetName), action, AdminSafeTostring(details), now
    )

    outputDebugString(("[ADMIN] %s -> %s | %s | %s"):format(adminName, AdminSafeTostring(targetName), action, AdminSafeTostring(details)), 3)

    -- Panel açık olan yetkililere canlı yayınla
    for _, p in ipairs(getElementsByType("player")) do
        if AdminIsStaff(p) and AdminHasPermission(p, "log.view") then
            triggerClientEvent(p, "admin:newLog", p, {
                admin = adminName, target = AdminSafeTostring(targetName),
                action = action, details = AdminSafeTostring(details), created_at = now,
            })
        end
    end
end

function AdminGetLogs(limit)
    limit = tonumber(limit) or 200
    local rows = AdminDBQuery("SELECT * FROM admin_logs ORDER BY id DESC LIMIT ?", limit)
    return rows
end
