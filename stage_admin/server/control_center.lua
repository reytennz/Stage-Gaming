--[[
    stage_admin - Control Center
    Oyuncu aktivitesi, ekonomi/item geçmişi ve resource yönetimi.
    Ağır sorgular yalnızca panel isteğinde çalışır; canlı sayaçlar cache kullanır.
]]

local sessionStarted = {}
local resourceStartedTick = getTickCount()
local dashboardCache = {
    onlinePlayers = 0,
    onlineAdmins = 0,
    activeReports = 0,
    todayJoins = 0,
    totalResources = 0,
    runningResources = 0,
    acToday = 0,
    uptimeSeconds = 0,
}

local protectedResources = {
    ["stage_admin"] = true,
    ["stage_core"] = true,
}

local function now()
    return getRealTime().timestamp
end

local function cleanName(player)
    if not isElement(player) then return "?" end
    return (getPlayerName(player) or "?"):gsub("#%x%x%x%x%x%x", "")
end

local function accountName(player)
    if not isElement(player) then return "guest" end
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then return "guest" end
    return getAccountName(acc) or "guest"
end

local function ensureActivityRow(player, joined)
    if not isElement(player) then return end
    local serial = getPlayerSerial(player)
    if not serial or serial == "" then return end

    local t = now()
    local rows = AdminDBQuery("SELECT player_serial FROM admin_player_activity WHERE player_serial = ? LIMIT 1", serial)
    if rows[1] then
        if joined then
            AdminDBExec([[UPDATE admin_player_activity
                SET player_name = ?, last_join = ?, join_count = join_count + 1, last_ip = ?, last_account = ?
                WHERE player_serial = ?]],
                cleanName(player), t, getPlayerIP(player) or "", accountName(player), serial)
        else
            AdminDBExec([[UPDATE admin_player_activity
                SET player_name = ?, last_ip = ?, last_account = ? WHERE player_serial = ?]],
                cleanName(player), getPlayerIP(player) or "", accountName(player), serial)
        end
    else
        AdminDBExec([[INSERT INTO admin_player_activity
            (player_serial, player_name, first_seen, last_join, last_quit, total_seconds, join_count, last_ip, last_account)
            VALUES (?, ?, ?, ?, 0, 0, ?, ?, ?)]],
            serial, cleanName(player), t, t, joined and 1 or 0, getPlayerIP(player) or "", accountName(player))
    end
end

local function beginSession(player, countJoin)
    if not isElement(player) then return end
    ensureActivityRow(player, countJoin == true)
    sessionStarted[player] = now()
end

local function finishSession(player)
    local started = sessionStarted[player]
    if not started or not isElement(player) then
        sessionStarted[player] = nil
        return
    end
    local serial = getPlayerSerial(player)
    local t = now()
    local seconds = math.max(0, t - started)
    AdminDBExec([[UPDATE admin_player_activity
        SET player_name = ?, last_quit = ?, total_seconds = total_seconds + ?, last_ip = ?, last_account = ?
        WHERE player_serial = ?]],
        cleanName(player), t, seconds, getPlayerIP(player) or "", accountName(player), serial)
    sessionStarted[player] = nil
end

addEventHandler("onResourceStart", resourceRoot, function()
    -- database.lua bu dosyadan önce yüklendiği için DB burada hazırdır.
    setTimer(function()
        for _, p in ipairs(getElementsByType("player")) do
            beginSession(p, false)
        end
    end, 700, 1)
end)

addEventHandler("onPlayerJoin", root, function()
    beginSession(source, true)
end)

addEventHandler("onPlayerLogin", root, function()
    ensureActivityRow(source, false)
end)

addEventHandler("onPlayerQuit", root, function()
    finishSession(source)
end)

-- Diğer Stage resource'larının çağırabileceği hafif log köprüleri.
function AdminTrackEconomy(player, amount, reason, sourceName)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false end
    local direction = amount > 0 and "+" or "-"
    AdminDBExec([[INSERT INTO admin_economy_logs
        (player_serial, player_name, amount, direction, reason, source_name, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        getPlayerSerial(player), cleanName(player), math.abs(amount), direction,
        AdminSafeTostring(reason ~= nil and reason or "Bilinmiyor"),
        AdminSafeTostring(sourceName ~= nil and sourceName or "unknown"), now())
    return true
end

function AdminTrackItem(player, itemId, amount, action, sourceName)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    AdminDBExec([[INSERT INTO admin_item_logs
        (player_serial, player_name, item_id, amount, action, source_name, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        getPlayerSerial(player), cleanName(player), tostring(itemId or "?"), amount,
        AdminSafeTostring(action ~= nil and action or "unknown"),
        AdminSafeTostring(sourceName ~= nil and sourceName or "unknown"), now())
    return true
end

function AdminTrackACDetection(player, moduleName, info, risk, action)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    AdminDBExec([[INSERT INTO admin_ac_events
        (player_serial, player_name, module, info, risk, action, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        getPlayerSerial(player), cleanName(player), tostring(moduleName or "unknown"),
        AdminSafeTostring(info ~= nil and info or ""), math.floor(tonumber(risk) or 0),
        tostring(action or "log"), now())
    return true
end

local function currentSessionSeconds(serial)
    for player, started in pairs(sessionStarted) do
        if isElement(player) and getPlayerSerial(player) == serial then
            return math.max(0, now() - started), player
        end
    end
    return 0, nil
end

local function getActivityRows(limit)
    limit = math.min(300, math.max(1, tonumber(limit) or 120))
    local rows = AdminDBQuery("SELECT * FROM admin_player_activity ORDER BY last_join DESC LIMIT ?", limit)
    for _, row in ipairs(rows) do
        local extra, onlinePlayer = currentSessionSeconds(row.player_serial)
        row.session_seconds = extra
        row.display_total_seconds = (tonumber(row.total_seconds) or 0) + extra
        row.online = onlinePlayer and true or false
        if onlinePlayer then
            row.player_name = cleanName(onlinePlayer)
        end
    end
    return rows
end

local function getResourceRows()
    local out = {}
    for _, res in ipairs(getResources()) do
        local name = getResourceName(res)
        out[#out + 1] = {
            name = name,
            state = getResourceState(res),
            protected = protectedResources[name] and true or false,
        }
    end
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    return out
end

local function updateDashboardCache()
    local onlineAdmins = 0
    for _, p in ipairs(getElementsByType("player")) do
        if AdminIsStaff(p) then onlineAdmins = onlineAdmins + 1 end
    end

    local totalResources, runningResources = 0, 0
    for _, res in ipairs(getResources()) do
        totalResources = totalResources + 1
        if getResourceState(res) == "running" then runningResources = runningResources + 1 end
    end

    local rt = getRealTime()
    local dayStart = rt.timestamp - (rt.hour * 3600 + rt.minute * 60 + rt.second)
    local today = AdminDBQuery("SELECT COUNT(*) AS n FROM admin_player_activity WHERE last_join >= ?", dayStart)
    local ac = AdminDBQuery("SELECT COUNT(*) AS n FROM admin_ac_events WHERE created_at >= ?", dayStart)

    dashboardCache = {
        onlinePlayers = #getElementsByType("player"),
        onlineAdmins = onlineAdmins,
        activeReports = #AdminGetOpenReports(),
        todayJoins = tonumber(today[1] and today[1].n) or 0,
        totalResources = totalResources,
        runningResources = runningResources,
        acToday = tonumber(ac[1] and ac[1].n) or 0,
        uptimeSeconds = math.floor((getTickCount() - resourceStartedTick) / 1000),
    }
end

setTimer(updateDashboardCache, 5000, 0)
setTimer(updateDashboardCache, 1000, 1)

function AdminGetDashboardCache()
    dashboardCache.uptimeSeconds = math.floor((getTickCount() - resourceStartedTick) / 1000)
    dashboardCache.onlinePlayers = #getElementsByType("player")
    return dashboardCache
end

local function sendControlData(player)
    if not isElement(player) or not AdminIsStaff(player) then return end
    triggerClientEvent(player, "admin:controlData", player, {
        resources = AdminHasPermission(player, "resource.view") and getResourceRows() or {},
        activity = (function()
            local list = getActivityRows(150)
            local seen = {}
            for _, r in ipairs(list) do seen[r.player_serial] = true end
            for _, p in ipairs(getElementsByType("player")) do
                local s = getPlayerSerial(p)
                if not seen[s] then
                    local extra = currentSessionSeconds(s)
                    table.insert(list, 1, {
                        player_serial = s,
                        player_name = cleanName(p),
                        online = true,
                        session_seconds = extra,
                        display_total_seconds = extra,
                        join_count = 1,
                        last_join = getRealTime().timestamp
                    })
                    seen[s] = true
                end
            end
            return list
        end)(),
        dashboard = AdminGetDashboardCache(),
        canManageResources = AdminHasPermission(player, "resource.manage"),
    })
end

addEvent("admin:requestControlData", true)
addEventHandler("admin:requestControlData", root, function()
    local player = client
    if not player or not AdminIsStaff(player) then return end
    if not AdminCheckRateLimit(player, "control.data", 600) then return end
    sendControlData(player)
end)

addEvent("admin:requestPlayerTrace", true)
addEventHandler("admin:requestPlayerTrace", root, function(serial)
    local player = client
    if not player or not AdminHasPermission(player, "log.view") then return end
    if not AdminCheckRateLimit(player, "control.trace", 500) then return end
    serial = tostring(serial or "")
    if serial == "" then return end

    local profile = AdminDBQuery("SELECT * FROM admin_player_activity WHERE player_serial = ? LIMIT 1", serial)[1] or {}
    local extra, onlinePlayer = currentSessionSeconds(serial)
    profile.display_total_seconds = (tonumber(profile.total_seconds) or 0) + extra
    profile.online = onlinePlayer and true or false
    profile.session_seconds = extra
    if onlinePlayer then profile.player_name = cleanName(onlinePlayer) end

    triggerClientEvent(player, "admin:playerTraceData", player, {
        profile = profile,
        economy = AdminDBQuery("SELECT * FROM admin_economy_logs WHERE player_serial = ? ORDER BY id DESC LIMIT 60", serial),
        items = AdminDBQuery("SELECT * FROM admin_item_logs WHERE player_serial = ? ORDER BY id DESC LIMIT 60", serial),
        ac = AdminDBQuery("SELECT * FROM admin_ac_events WHERE player_serial = ? ORDER BY id DESC LIMIT 60", serial),
    })
end)

addEvent("admin:resourceAction", true)
addEventHandler("admin:resourceAction", root, function(resourceName, action)
    local player = client
    if not player or not AdminHasPermission(player, "resource.manage") then
        if player then AdminNotify(player, "Resource yönetimi için Developer/Owner yetkisi gerekli.", "error") end
        return
    end
    if not AdminCheckRateLimit(player, "resource.manage", 900) then return end

    resourceName = tostring(resourceName or "")
    action = tostring(action or "")
    local res = getResourceFromName(resourceName)
    if not res then
        AdminNotify(player, "Resource bulunamadı: " .. resourceName, "error")
        return
    end

    if protectedResources[resourceName] and (action == "stop" or action == "restart") then
        AdminNotify(player, resourceName .. " korumalı resource; panelden durdurulamaz/restartlanamaz.", "warning")
        return
    end

    local ok = false
    if action == "start" then
        ok = getResourceState(res) == "running" or startResource(res)
    elseif action == "stop" then
        ok = getResourceState(res) == "stopped" or stopResource(res)
    elseif action == "restart" then
        ok = getResourceState(res) == "running" and restartResource(res) or startResource(res)
    else
        return
    end

    AdminLog(player, resourceName, "resource_" .. action, ok and "OK" or "FAILED")
    AdminNotify(player, resourceName .. " -> " .. action .. (ok and " tamamlandı." or " başarısız."), ok and "success" or "error")
    setTimer(function()
        if isElement(player) then sendControlData(player) end
    end, 600, 1)
end)


addEvent("admin:giveItem", true)
addEventHandler("admin:giveItem", root, function(item, amount)
    if not client or not AdminHasPermission(client, "giveitem") then return end
    local target = client
    local invRes = getResourceFromName("stage_inventory")
    if invRes and getResourceState(invRes) == "running" then
        local fn = exports.stage_inventory and exports.stage_inventory.giveItem
        if fn then exports.stage_inventory:giveItem(target, item, amount or 1) end
    end
end)

addEvent("admin:spawnVehicle", true)
addEventHandler("admin:spawnVehicle", root, function(model)
    if not client or not AdminHasPermission(client, "givevehicle") then return end
    model=tonumber(model)
    if not model then return end
    local x,y,z=getElementPosition(client)
    local v=createVehicle(model,x+3,y,z)
    if v then warpPedIntoVehicle(client,v) end
end)

local function getWallet(serial, player)
    if isElement(player) and type(AdminGetWallet) == "function" then
        return AdminGetWallet(player)
    end
    return { cash = 0, bank = 0 }
end

local function getLiveVehicle(player)
    if not isElement(player) then return nil end
    local veh = getPedOccupiedVehicle(player)
    if not isElement(veh) then return nil end
    local model = getElementModel(veh)
    return {
        model = model,
        model_name = getVehicleNameFromModel(model) or tostring(model),
        plate = getVehiclePlateText(veh) or "-",
    }
end
-- HTML panel: oyuncu adıyla seçilince tam detay (wallet + vehicles + trace) gönder
addEvent("admin:requestPlayerDetail", true)
addEventHandler("admin:requestPlayerDetail", root, function(playerName)
    local admin = client
    if not admin or not AdminIsStaff(admin) then return end
    playerName = tostring(playerName or ""):gsub("#%x%x%x%x%x%x", "")
    if playerName == "" then return end

    local function strip(n)
        return (n or ""):gsub("#%x%x%x%x%x%x", "")
    end

    local target = nil
    for _, p in ipairs(getElementsByType("player")) do
        if strip(getPlayerName(p)) == playerName or getPlayerName(p) == playerName then
            target = p
            break
        end
    end
    if not target then
        local lower = playerName:lower()
        for _, p in ipairs(getElementsByType("player")) do
            if strip(getPlayerName(p)):lower():find(lower, 1, true) then
                target = p
                break
            end
        end
    end

    local serial = target and getPlayerSerial(target) or nil
    if not serial then
        local row = AdminDBQuery("SELECT player_serial FROM admin_player_activity WHERE player_name=? LIMIT 1", playerName)
        serial = row and row[1] and row[1].player_serial or nil
    end
    if not serial then
        AdminNotify(admin, "Oyuncu bulunamadı: " .. playerName, "error")
        return
    end

    local profile = AdminDBQuery("SELECT * FROM admin_player_activity WHERE player_serial=? LIMIT 1", serial)[1] or {}
    local extra, onlinePlayer = currentSessionSeconds(serial)
    profile.display_total_seconds = (tonumber(profile.total_seconds) or 0) + extra
    profile.online = (onlinePlayer or target) and true or false
    profile.session_seconds = extra
    local live = onlinePlayer or target
    if live then profile.player_name = cleanName(live) end
    if not profile.player_name or profile.player_name == "" then
        profile.player_name = playerName
    end

    triggerClientEvent(admin, "admin:playerTraceData", admin, {
        serial      = serial,
        ip          = live and getPlayerIP(live) or (profile.last_ip or "-"),
        profile     = profile,
        wallet      = getWallet(serial, live),
        liveVehicle = getLiveVehicle(live),
        vehicles    = type(AdminGetPlayerVehicles) == "function" and AdminGetPlayerVehicles(serial) or {},
        economy     = AdminDBQuery("SELECT * FROM admin_economy_logs WHERE player_serial=? ORDER BY id DESC LIMIT 60", serial),
        items       = AdminDBQuery("SELECT * FROM admin_item_logs   WHERE player_serial=? ORDER BY id DESC LIMIT 60", serial),
        ac          = AdminDBQuery("SELECT * FROM admin_ac_events   WHERE player_serial=? ORDER BY id DESC LIMIT 60", serial),
    })
end)

-- HTML panel: unban by ID
addEvent("admin:unbanById", true)
addEventHandler("admin:unbanById", root, function(banId)
    local admin = client
    if not admin or not AdminHasPermission(admin, "ban") then return end
    banId = tonumber(banId)
    if not banId then return end
    AdminDBExec("UPDATE admin_bans SET active=0 WHERE id=?", banId)
    AdminLog(admin, "-", "unban", "ID:" .. banId)
    triggerClientEvent(admin, "admin:actionDone", admin, "Ban kaldırıldı.", "success")
end)
