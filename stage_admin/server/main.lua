--[[
    stage_admin - server main
]]

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[stage_admin] yüklendi. Panel: " .. Config.PanelKey .. " | Report: " .. Config.ReportKey, 3)

    if not getResourceFromName("stage_core") then
        outputDebugString("[stage_admin] UYARI: stage_core bulunamadı, para/notify native fallback kullanılacak.", 2)
    end
    if not getResourceFromName("stage_inventory") then
        outputDebugString("[stage_admin] UYARI: stage_inventory bulunamadı, item verme devre dışı kalacak.", 2)
    end
end)

addEvent("admin:requestDashboard", true)
addEventHandler("admin:requestDashboard", root, function()
    local player = client
    if not AdminIsStaff(player) then return end

    local data = type(AdminGetDashboardCache) == "function" and AdminGetDashboardCache() or nil
    if not data then
        local onlineAdmins = 0
        for _, p in ipairs(getElementsByType("player")) do
            if AdminIsStaff(p) then onlineAdmins = onlineAdmins + 1 end
        end
        data = {
            onlinePlayers = #getElementsByType("player"),
            activeReports = #AdminGetOpenReports(),
            onlineAdmins = onlineAdmins,
            todayJoins = 0, totalResources = 0, runningResources = 0, acToday = 0, uptimeSeconds = 0,
        }
    end
    triggerClientEvent(player, "admin:dashboardData", player, data)
end)
-- Işınlanılacak yerlerin listesi: [isim] = {x, y, z, interior, dimension}
local places = {
    ["banka"]    = {x = 1310.30957, y = -1370.20081, z = 13.84522, interior = 0, dimension = 0},
    ["hastane"]  = { x = 1177.5, y = -1323.8, z = 14.1, interior = 0, dimension = 0 },
    ["belediye"] = { x = 1481.0, y = -1771.5, z = 18.8, interior = 0, dimension = 0 },
    ["sf"]       = { x = -1988.6, y = 138.2, z = 27.7, interior = 0, dimension = 0 },
    ["lv"]       = { x = 1691.7, y = 1450.4, z = 10.8, interior = 0, dimension = 0 },
    ["kenevir"]  = { x= -277.79504, y = -2198.17603, z = 28.67861, interior = 0, dimension = 0 },
}

-- Yetki kontrolü (Varsayılan olarak "Admin" ACL grubunu kontrol eder)
local function isAdmin(player)
    local account = getPlayerAccount(player)
    if isGuestAccount(account) then return false end
    local accName = getAccountName(account)
    return isObjectInACLGroup("user." .. accName, aclGetGroup("Admin"))
end

local function gotoPlaceCommand(player, commandName, placeName)
    if not isAdmin(player) then
        outputChatBox("[HATA] Bu komutu kullanmak için yetkiniz yok.", player, 255, 60, 60)
        return
    end

    if not placeName then
        outputChatBox("Kullanım: /" .. commandName .. " [yer_adı]", player, 255, 200, 0)
        
        -- Mevcut yerleri listele
        local available = {}
        for name, _ in pairs(places) do
            table.insert(available, name)
        end
        outputChatBox("Mevcut yerler: " .. table.concat(available, ", "), player, 200, 200, 200)
        return
    end

    local targetKey = string.lower(placeName)
    local loc = places[targetKey]

    if not loc then
        outputChatBox("[HATA] '" .. placeName .. "' adında bir konum bulunamadı.", player, 255, 60, 60)
        return
    end

    -- Oyuncu araçtaysa aracıyla birlikte ışınla
    local vehicle = getPedOccupiedVehicle(player)
    local targetElement = vehicle or player

    setElementPosition(targetElement, loc.x, loc.y, loc.z)
    setElementInterior(targetElement, loc.interior or 0)
    setElementDimension(targetElement, loc.dimension or 0)

    outputChatBox("[IŞINLANMA] Başarıyla '" .. targetKey .. "' konumuna ışınlandınız.", player, 60, 255, 60)
end

-- Hem /gotoplace hem de yazım hatasına karşı /gotopalce olarak kaydeder
addCommandHandler("gotoplace", gotoPlaceCommand, false, false)
addCommandHandler("gotopalce", gotoPlaceCommand, false, false)
