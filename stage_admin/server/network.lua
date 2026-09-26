--[[
    stage_admin - network layer
    Panelden/komuttan gelen HER istek burada permission kontrolünden geçer.
    Client'tan gelen miktar/hedef bilgilerine asla ham güvenilmez.
]]

local function requirePerm(player, perm)
    if not AdminHasPermission(player, perm) then
        AdminNotify(player, "Bu işlem için yetkiniz yok.", "error")
        return false
    end
    if not AdminCheckRateLimit(player, perm, 400) then
        return false
    end
    return true
end

local function resolveTarget(idOrName)
    if not idOrName then return nil end
    local needle = tostring(idOrName):gsub("#%x%x%x%x%x%x", "")

    for _, p in ipairs(getElementsByType("player")) do
        if tostring(getElementData(p, "admin:sessionId") or "") == needle then
            return p
        end
    end

    local exact = getPlayerFromName(needle)
    if exact then return exact end

    local function strip(n)
        return (n or ""):gsub("#%x%x%x%x%x%x", "")
    end

    local lowerNeedle = needle:lower()
    for _, p in ipairs(getElementsByType("player")) do
        local n = strip(getPlayerName(p))
        if n:lower() == lowerNeedle then return p end
    end

    for _, p in ipairs(getElementsByType("player")) do
        local n = strip(getPlayerName(p))
        if n:lower():find(lowerNeedle, 1, true) then return p end
    end
    return nil
end

local function refreshPanel(player)
    if not isElement(player) or not AdminIsStaff(player) then return end
    local rank = AdminGetRank(player)
    triggerClientEvent(player, "admin:panelData", player, {
        players = (function()
            local out = {}
            for _, p in ipairs(getElementsByType("player")) do
                out[#out+1] = {
                    name = (getPlayerName(p) or ""):gsub("#%x%x%x%x%x%x", ""), id = getElementData(p, "playerid") or getElementData(p, "id") or "-", ping = getPlayerPing(p), rank = AdminGetRank(p),
                    frozen = isElementFrozen(p) or false,
                    invisible = getElementData(p, "admin:invisible") and true or false,
                }
            end
            return out
        end)(),
        myRank = rank,
        permissions = AdminGetPermissions(player),
        reports = AdminHasPermission(player, "report.view") and AdminGetOpenReports() or {},
        bans = (AdminHasPermission(player, "ban.history") or AdminHasPermission(player, "unban")) and AdminGetActiveBans() or {},
        warns = {},
        events = AdminHasPermission(player, "event.view") and AdminGetEvents() or {},
        logs = AdminHasPermission(player, "log.view") and AdminGetLogs(100) or {},
        config = {
            banDurations = Config.BanDurations, reportReasons = Config.ReportReasons,
            announceTypes = Config.AnnounceTypes, ranks = Config.Ranks,
        },
    })
end

local function actionResult(player, ok, message, kind)
    if not isElement(player) then return end
    AdminNotify(player, message, kind or (ok and "success" or "error"))
    if ok then
        refreshPanel(player)
        triggerClientEvent(player, "admin:actionDone", player, message, kind or "success")
    end
end

-- ================= PANEL AÇMA =================

addEvent("admin:requestPanelData", true)
addEventHandler("admin:requestPanelData", root, function()
    local player = client
    if not AdminIsStaff(player) then
        triggerClientEvent(player, "admin:notStaff", player)
        return
    end
    refreshPanel(player)
end)

-- ================= OYUNCU İŞLEMLERİ =================

addEvent("admin:action", true)
addEventHandler("admin:action", root, function(action, targetName, payload)
    local player = client
    action = tostring(action or "")

    -- HTML panel isimleri -> gerçek aksiyon
    local aliases = {
        goto = "teleportTo", bring = "bringTo",
        givecash = "givemoney", takecash = "takemoney",
        givebank = "givebank", takebank = "takebank",
        togglegod = "god", mute = "mute",
    }
    action = aliases[action] or action

    local perms = {
        teleportTo = "goto", bringTo = "gethere", teleportCoords = "tpto",
        spectate = "spectate", stopSpectate = "spectate",
        freeze = "freeze", unfreeze = "unfreeze",
        invisible = "invisible", invisibleOff = "invisible",
        noclip = "noclip", fly = "fly", god = "god",
        kick = "kick", ban = "ban", warn = "warn",
        givemoney = "givemoney", takemoney = "givemoney",
        givebank = "givemoney", takebank = "givemoney",
        giveitem = "giveitem", givevehicle = "givevehicle",
        temprank = "temprank", removerank = "removerank",
        mute = "kick",
    }
    local perm = perms[action]
    if not perm or not requirePerm(player, perm) then return end

    local function payloadAmount()
        if type(payload) == "number" then return tonumber(payload) end
        if type(payload) ~= "table" then return tonumber(payload) end
        return tonumber(payload.amount) or tonumber(payload.value) or tonumber(payload.model)
    end
    local function payloadText()
        if type(payload) == "string" then return payload end
        if type(payload) ~= "table" then return tostring(payload or "") end
        return tostring(payload.reason or payload.value or payload.note or "")
    end

    local target = targetName and resolveTarget(targetName) or nil

    if action == "teleportTo" and target then
        actionResult(player, AdminTeleportTo(player, target), "Oyuncuya ışınlandınız.")
    elseif action == "bringTo" and target then
        actionResult(player, AdminBringTo(player, target), "Oyuncu yanınıza getirildi.")
    elseif action == "teleportCoords" and type(payload) == "table" then
        AdminTeleportToCoords(player, payload.x, payload.y, payload.z)
    elseif action == "spectate" and target then
        AdminStartSpectate(player, target)
    elseif action == "stopSpectate" then
        AdminStopSpectate(player)
    elseif action == "freeze" and target then
        local state = not isElementFrozen(target)
        actionResult(player, AdminFreeze(target, state), state and "Oyuncu donduruldu." or "Donma kaldırıldı.")
        AdminLog(player, getPlayerName(target), "freeze", tostring(state))
    elseif action == "unfreeze" and target then
        actionResult(player, AdminFreeze(target, false), "Oyuncunun donması kaldırıldı.")
        AdminLog(player, getPlayerName(target), "unfreeze", "")
    elseif action == "invisible" and target then
        AdminSetInvisible(target, true)
        AdminLog(player, getPlayerName(target), "invisible", "")
    elseif action == "invisibleOff" and target then
        AdminSetInvisible(target, false)
        AdminLog(player, getPlayerName(target), "invisible_off", "")
    elseif action == "noclip" then
        AdminSetNoClip(player, payload == true)
        AdminLog(player, getPlayerName(player), "noclip", tostring(payload))
    elseif action == "fly" then
        AdminSetFly(player, payload == true)
        AdminLog(player, getPlayerName(player), "fly", tostring(payload))
    elseif action == "god" then
        local flags = AdminBypassFlags[target or player] or {}
        local state
        if payload == true or payload == false then
            state = payload
        else
            state = not flags.god
        end
        AdminSetGod(target or player, state)
        AdminLog(player, getPlayerName(target or player), "god", tostring(state))
        actionResult(player, true, state and "God mode açıldı." or "God mode kapandı.")
    elseif action == "mute" and target then
        local muted = isPlayerMuted(target)
        setPlayerMuted(target, not muted)
        AdminLog(player, getPlayerName(target), "mute", tostring(not muted))
        actionResult(player, true, muted and "Susturma kaldırıldı." or "Oyuncu susturuldu.")
    elseif action == "kick" and target then
        local ok = AdminKick(player, target, payloadText())
        if isElement(player) then actionResult(player, ok, ok and "Oyuncu sunucudan atıldı." or "Kick işlemi başarısız.", ok and "success" or "error") end
    elseif action == "ban" and target then
        local reason, duration
        if type(payload) == "table" then
            reason = payload.reason or payload.value
            duration = tonumber(payload.duration)
        else
            reason = payloadText()
        end
        local ok = AdminBanPlayer(player, target, reason, duration)
        if isElement(player) then actionResult(player, ok, ok and "Oyuncu banlandı." or "Ban işlemi başarısız.", ok and "success" or "error") end
    elseif action == "warn" and target then
        local ok = AdminWarnPlayer(player, target, payloadText())
        actionResult(player, ok, ok and "Oyuncu uyarıldı." or "Uyarı işlemi başarısız.", ok and "success" or "error")
    elseif action == "givemoney" and target then
        local amount = math.floor(payloadAmount() or 0)
        if amount > 0 and amount <= 1000000000 then
            local ok = AdminAddMoney(target, amount)
            AdminLog(player, getPlayerName(target), "givemoney", AdminFormatMoney(amount))
            AdminNotify(target, "Bir yetkili size " .. AdminFormatMoney(amount) .. " verdi.", "success")
            actionResult(player, ok, ok and ("Nakit verildi: " .. AdminFormatMoney(amount)) or "Para verilemedi.", ok and "success" or "error")
        else
            actionResult(player, false, "Geçerli bir miktar gir.", "error")
        end
    elseif action == "takemoney" and target then
        local amount = math.floor(payloadAmount() or 0)
        if amount > 0 then
            local ok = AdminRemoveMoney(target, amount)
            AdminLog(player, getPlayerName(target), "takemoney", AdminFormatMoney(amount))
            actionResult(player, ok, ok and "Nakit alındı." or "Yetersiz nakit.", ok and "success" or "error")
        else
            actionResult(player, false, "Geçerli bir miktar gir.", "error")
        end
    elseif action == "givebank" and target then
        local amount = math.floor(payloadAmount() or 0)
        if amount > 0 and amount <= 1000000000 then
            local ok = AdminAddBank(target, amount)
            AdminLog(player, getPlayerName(target), "givebank", AdminFormatMoney(amount))
            actionResult(player, ok, ok and ("Bankaya yatırıldı: " .. AdminFormatMoney(amount)) or "Banka işlemi başarısız.", ok and "success" or "error")
        else
            actionResult(player, false, "Geçerli bir miktar gir.", "error")
        end
    elseif action == "takebank" and target then
        local amount = math.floor(payloadAmount() or 0)
        if amount > 0 then
            local ok = AdminRemoveBank(target, amount)
            AdminLog(player, getPlayerName(target), "takebank", AdminFormatMoney(amount))
            actionResult(player, ok, ok and "Bankadan çekildi." or "Yetersiz bakiye.", ok and "success" or "error")
        else
            actionResult(player, false, "Geçerli bir miktar gir.", "error")
        end
    elseif action == "giveitem" and target and type(payload) == "table" then
        local ok, err = AdminGiveItem(target, payload.item, payload.amount)
        if ok then
            AdminLog(player, getPlayerName(target), "giveitem", tostring(payload.item) .. " x" .. tostring(payload.amount))
            AdminNotify(target, "Bir yetkili size item verdi.", "success")
            actionResult(player, true, "Item verildi.", "success")
        else
            AdminNotify(player, "Item verilemedi: " .. tostring(err), "error")
        end
    elseif action == "givevehicle" and target then
        local model = payloadAmount()
        if type(payload) == "table" and payload.model then model = tonumber(payload.model) or model end
        local ok = AdminGiveVehicle(target, model, nil, nil, nil, getPlayerName(player))
        if ok then
            AdminLog(player, getPlayerName(target), "givevehicle", tostring(model))
            AdminNotify(target, "Bir yetkili size araç verdi.", "success")
            actionResult(player, true, "Araç verildi (model " .. tostring(model) .. ").", "success")
        else
            actionResult(player, false, "Araç verilemedi. Model ID doğru mu?", "error")
        end
    elseif action == "temprank" and target and type(payload) == "table" then
        if AdminGiveTempRank(player, target, payload.rank, payload.duration) then
            AdminLog(player, getPlayerName(target), "temprank", payload.rank .. " / " .. AdminFormatDuration(payload.duration))
            AdminNotify(target, "Yetki seviyeniz: " .. payload.rank, "success")
            actionResult(player, true, "Rütbe kaydedildi: " .. payload.rank, "success")
        else
            actionResult(player, false, "Rütbe kaydedilemedi.", "error")
        end
    elseif action == "removerank" and target then
        local ok = AdminRemoveRank(target)
        AdminLog(player, getPlayerName(target), "removerank", "")
        actionResult(player, ok, ok and "Rütbe kaldırıldı." or "Rütbe kaldırılamadı.", ok and "success" or "error")
    else
        if not target then
            actionResult(player, false, "Hedef oyuncu bulunamadı.", "error")
        end
    end
end)

-- ================= BAN YÖNETİMİ (offline dahil) =================

addEvent("admin:banOffline", true)
addEventHandler("admin:banOffline", root, function(serial, name, reason, duration)
    local player = client
    if not requirePerm(player, "ban") then return end
    AdminBanBySerial(player, serial, name, reason, duration)
end)

addEvent("admin:unban", true)
addEventHandler("admin:unban", root, function(banId)
    local player = client
    if not requirePerm(player, "unban") then return end
    local ok = AdminUnban(player, banId)
    actionResult(player, ok, ok and "Ban kaldırıldı." or "Ban kaldırma başarısız.", ok and "success" or "error")
end)

addEvent("admin:unwarn", true)
addEventHandler("admin:unwarn", root, function(warnId)
    local player = client
    if not requirePerm(player, "unwarn") then return end
    local ok = AdminRemoveWarn(player, warnId)
    actionResult(player, ok, ok and "Uyarı kaldırıldı." or "Uyarı kaldırma başarısız.", ok and "success" or "error")
end)

addEvent("admin:getPlayerHistory", true)
addEventHandler("admin:getPlayerHistory", root, function(targetName)
    local player = client
    if not AdminIsStaff(player) then return end
    local target = resolveTarget(targetName)
    if not target then return end
    local serial = getPlayerSerial(target)
    triggerClientEvent(player, "admin:playerHistory", player, {
        warns = AdminGetWarnsForSerial(serial),
        bans = AdminDBQuery("SELECT * FROM admin_bans WHERE player_serial = ? ORDER BY id DESC", serial),
    })
end)

-- ================= REPORT =================

addEvent("admin:submitReport", true)
addEventHandler("admin:submitReport", root, function(reason, description)
    if not AdminCheckRateLimit(client, "report", 2000) then return end
    AdminCreateReport(client, reason, description)
end)

addEvent("admin:reportAction", true)
addEventHandler("admin:reportAction", root, function(action, reportId, payload)
    local player = client
    if action == "claim" and requirePerm(player, "report.claim") then
        local ok = AdminClaimReport(player, reportId)
        actionResult(player, ok, ok and "Report üstlenildi." or "Report işlemi başarısız.", ok and "success" or "error")
    elseif action == "close" and requirePerm(player, "report.close") then
        local ok = AdminCloseReport(player, reportId, payload)
        actionResult(player, ok, ok and "Report kapatıldı." or "Report kapatma başarısız.", ok and "success" or "error")
    elseif action == "note" and requirePerm(player, "report.note") then
        local ok = AdminNoteReport(player, reportId, payload)
        actionResult(player, ok, ok and "Report notu kaydedildi." or "Not kaydedilemedi.", ok and "success" or "error")
    elseif action == "goto" and requirePerm(player, "goto") then
        local rows = AdminDBQuery("SELECT * FROM admin_reports WHERE id = ?", tonumber(reportId))
        if rows[1] then
            local target = getPlayerFromName(rows[1].player_name)
            if target then AdminTeleportTo(player, target) end
        end
    elseif action == "bring" and requirePerm(player, "gethere") then
        local rows = AdminDBQuery("SELECT * FROM admin_reports WHERE id = ?", tonumber(reportId))
        if rows[1] then
            local target = getPlayerFromName(rows[1].player_name)
            if target then AdminBringTo(player, target) end
        end
    end
end)

-- ================= DUYURU =================

addEvent("admin:sendAnnounce", true)
addEventHandler("admin:sendAnnounce", root, function(annType, message)
    local player = client
    if not requirePerm(player, "announce") then return end
    AdminSendAnnounce(player, annType, message)
end)

-- ================= ETKİNLİK =================

addEvent("admin:createEvent", true)
addEventHandler("admin:createEvent", root, function(data)
    local player = client
    if not requirePerm(player, "event.create") or type(data) ~= "table" then return end
    AdminCreateEvent(player, data.name, data.description, data.reward, data.startsAt, data.endsAt, data.capacity)
end)

addEvent("admin:setEventActive", true)
addEventHandler("admin:setEventActive", root, function(eventId, state)
    local player = client
    if not requirePerm(player, "event.manage") then return end
    AdminSetEventActive(player, eventId, state)
end)

-- ================= ADMIN CHAT (panel içinden) =================

addEvent("admin:sendChat", true)
addEventHandler("admin:sendChat", root, function(message)
    local player = client
    if not requirePerm(player, "achat") then return end
    AdminChatSend(player, message)
end)


addEvent("admin:manageResource", true)
addEventHandler("admin:manageResource", root, function(action, resName)
    local player = client
    if not AdminIsStaff(player) or not AdminHasPermission(player, "resource.view") then return end
    resName = tostring(resName or "")
    local res = getResourceFromName(resName)
    if not res then
        actionResult(player, false, "Resource bulunamadı: " .. resName, "error")
        return
    end
    if action == "start" then
        local ok = startResource(res)
        actionResult(player, ok, ok and (resName .. " başlatıldı.") or (resName .. " başlatılamadı."), ok and "success" or "error")
    elseif action == "stop" then
        local ok = stopResource(res)
        actionResult(player, ok, ok and (resName .. " durduruldu.") or (resName .. " durdurulamadı."), ok and "success" or "error")
    elseif action == "restart" then
        local ok = restartResource(res)
        actionResult(player, ok, ok and (resName .. " yeniden başlatıldı.") or (resName .. " yeniden başlatılamadı."), ok and "success" or "error")
    end
end)

addEvent("admin:createEvent", true)
addEventHandler("admin:createEvent", root, function(name, desc, reward, durationMin)
    local player = client
    if not AdminIsStaff(player) or not AdminHasPermission(player, "event.view") then return end
    local now = getRealTime().timestamp
    local dur = (tonumber(durationMin) or 30) * 60
    local ok = AdminCreateEvent(player, name, desc, reward, now, now + dur, 50)
    actionResult(player, ok, ok and "Etkinlik başarıyla oluşturuldu ve duyuruldu!" or "Etkinlik oluşturulamadı.", ok and "success" or "error")
end)

addEvent("admin:cancelReport", true)
addEventHandler("admin:cancelReport", root, function()
    local player = client
    AdminCancelReport(player)
end)
