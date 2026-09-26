local vehicles = {}
local owned = {}

local function cleanName(name)
    name = tostring(name or "Arac")
    name = name:gsub("•●", ""):gsub("═", ""):gsub("%s+", " ")
    return name:gsub("^%s+", ""):gsub("%s+$", "")
end

local function loadVehicles()
    local xml = xmlLoadFile("vehicle_models.xml")
    if not xml then return end
    local seen = {}
    for _, node in ipairs(xmlNodeGetChildren(xml)) do
        if xmlNodeGetName(node) == "file" then
            local model = tonumber(xmlNodeGetAttribute(node, "model"))
            if model and model >= 400 and model <= 611 and not seen[model] then
                seen[model] = true
                local name = cleanName(xmlNodeGetAttribute(node, "isim"))
                vehicles[#vehicles + 1] = { model = model, name = name, price = VehicleShopConfig.prices[model] or VehicleShopConfig.defaultPrice }
            end
        end
    end
    xmlUnloadFile(xml)
end

local function removeOwned(player)
    if isElement(owned[player]) then destroyElement(owned[player]) end
    owned[player] = nil
end

addEventHandler("onResourceStart", resourceRoot, loadVehicles)
addEventHandler("onPlayerQuit", root, function() removeOwned(source) end)
addEventHandler("onElementDestroy", root, function()
    if getElementType(source) == "vehicle" then
        for player, vehicle in pairs(owned) do if vehicle == source then owned[player] = nil end end
    end
end)

addCommandHandler(VehicleShopConfig.command, function(player)
    if not getElementData(player, "stage:charId") then return end
    triggerClientEvent(player, "stageVehicleShop:open", resourceRoot, vehicles)
end)

addEvent("stageVehicleShop:buy", true)
addEventHandler("stageVehicleShop:buy", root, function(index)
    local player = client
    local data = vehicles[tonumber(index)]
    if not data or not getElementData(player, "stage:charId") then return end
    local money = exports.stage_loading:stageGetMoney(player)
    if money < data.price then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFYeterli paran yok. Fiyat: $" .. data.price, player, 255, 255, 255, true)
        return
    end
    exports.stage_loading:stageSetMoney(player, money - data.price)
    removeOwned(player)
    local x, y, z = getElementPosition(player)
    local _, _, rz = getElementRotation(player)
    local vehicle = createVehicle(data.model, x + 3, y, z + 0.5, 0, 0, rz)
    if not vehicle then return end
    owned[player] = vehicle
    setElementData(vehicle, "stage:owner", getPlayerName(player))
    warpPedIntoVehicle(player, vehicle)
    outputChatBox("#FF7A00[Stage Gaming] #FFFFFF" .. data.name .. " satin alindi.", player, 255, 255, 255, true)
end)
