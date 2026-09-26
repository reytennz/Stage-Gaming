--[[
    stage_admin - report sistemi
]]

local reportCooldown = {} -- [serial] = timestamp

function AdminCreateReport(player, reason, description)
    if not isElement(player) then return false end
    local serial = getPlayerSerial(player)
    local now = getRealTime().timestamp

    if reportCooldown[serial] and (now - reportCooldown[serial]) < 30 then
        AdminNotify(player, "Çok sık report gönderiyorsunuz, biraz bekleyin.", "error")
        return false
    end
    reportCooldown[serial] = now

    reason = AdminTrim(reason)
    description = AdminTrim(description)
    if reason == "" then return false end
    if #description > 500 then description = description:sub(1, 500) end

    AdminDBExec(
        "INSERT INTO admin_reports (player_name, reason, description, created_at, status) VALUES (?, ?, ?, ?, 'open')",
        getPlayerName(player), reason, description, now
    )

    AdminNotify(player, "Raporunuz alındı, yetkililer inceleyecek.", "success")

    -- Aktif yetkililere bildir
    for _, p in ipairs(getElementsByType("player")) do
        if AdminHasPermission(p, "report.view") then
            triggerClientEvent(p, "admin:newReport", p)
            AdminNotify(p, "Yeni report: " .. getPlayerName(player) .. " (" .. reason .. ")", "info")
        end
    end

    return true
end

function AdminGetOpenReports()
    return AdminDBQuery("SELECT * FROM admin_reports WHERE status != 'closed' ORDER BY id DESC")
end

function AdminGetAllReports(limit)
    return AdminDBQuery("SELECT * FROM admin_reports ORDER BY id DESC LIMIT ?", tonumber(limit) or 200)
end

local function broadcastReports()
    for _, p in ipairs(getElementsByType("player")) do
        if AdminHasPermission(p, "report.view") then
            triggerClientEvent(p, "admin:newReport", p)
        end
    end
end

function AdminClaimReport(admin, reportId)
    reportId = tonumber(reportId)
    if not reportId then return false end
    AdminDBExec("UPDATE admin_reports SET status = 'claimed', claimed_by = ? WHERE id = ?", getPlayerName(admin), reportId)
    AdminLog(admin, "#" .. reportId, "report_claim", "")
    broadcastReports()
    return true
end

function AdminCloseReport(admin, reportId, note)
    reportId = tonumber(reportId)
    if not reportId then return false end
    AdminDBExec("UPDATE admin_reports SET status = 'closed', note = ?, closed_at = ? WHERE id = ?",
        AdminTrim(note), getRealTime().timestamp, reportId)
    AdminLog(admin, "#" .. reportId, "report_close", note or "")
    broadcastReports()
    return true
end

function AdminNoteReport(admin, reportId, note)
    reportId = tonumber(reportId)
    if not reportId then return false end
    AdminDBExec("UPDATE admin_reports SET note = ? WHERE id = ?", AdminTrim(note), reportId)
    AdminLog(admin, "#" .. reportId, "report_note", note or "")
    broadcastReports()
    return true
end


function AdminCancelReport(player)
    if not isElement(player) then return false end
    local pName = getPlayerName(player)
    local openR = AdminDBQuery("SELECT id FROM admin_reports WHERE player_name = ? AND status = 'open' ORDER BY id DESC LIMIT 1", pName)
    if not openR or #openR == 0 then
        AdminNotify(player, "Geri çekilebilecek açık bir raporunuz bulunmuyor (yetkili almış veya kapanmış olabilir).", "error")
        return false
    end
    local repId = openR[1].id
    AdminDBExec("UPDATE admin_reports SET status = 'closed', note = 'Oyuncu tarafından geri çekildi', closed_at = ? WHERE id = ?", getRealTime().timestamp, repId)
    AdminNotify(player, "Raporunuz başarıyla geri çekildi.", "info")
    broadcastReports()
    return true
end

addCommandHandler("reportiptal", function(player)
    AdminCancelReport(player)
end)
