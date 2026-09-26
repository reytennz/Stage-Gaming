--[[
    Araç Kiralama - Server
]]

-- Spawn noktaları (marker yakınında: -283.63, -2199.48, 28)
local SPAWN_POINTS = {
    { x = -278.0, y = -2199.5, z = 28.0, rot = 90 },
    { x = -278.0, y = -2204.0, z = 28.0, rot = 90 },
    { x = -278.0, y = -2195.0, z = 28.0, rot = 90 },
}

local rentedVehicles = {}  -- [player] = vehicle element

local function getFreeSpawn()
    for _, p in ipairs(SPAWN_POINTS) do
        local nearby = getElementsWithinRange(p.x, p.y, p.z, 4, "vehicle")
        if #nearby == 0 then
            return p
        end
    end
    return SPAWN_POINTS[1] -- doluysa ilkini kullan
end

local function destroyRentedVehicle(player)
    if rentedVehicles[player] and isElement(rentedVehicles[player]) then
        destroyElement(rentedVehicles[player])
    end
    rentedVehicles[player] = nil
end

addEvent("aracKiralama:kirala", true)
addEventHandler("aracKiralama:kirala", root, function(model, price, name)
    local player = client
    if not isElement(player) then return end

    model = tonumber(model)
    price = tonumber(price)
    if not model or not price or price < 0 then return end

    -- Zaten kiraladığı araç varsa eskiyi sil
    destroyRentedVehicle(player)

    local money = getPlayerMoney(player)
    if money < price then
        triggerClientEvent(player, "aracKiralama:mesaj", player,
            "#FF6B6B[Kiralama] #FFFFFFYeterli paran yok! Gerekli: $" .. price, 255, 255, 255)
        return
    end

    takePlayerMoney(player, price)

    local spawn = getFreeSpawn()
    local veh = createVehicle(model, spawn.x, spawn.y, spawn.z, 0, 0, spawn.rot)
    if not veh then
        givePlayerMoney(player, price) -- para iade
        triggerClientEvent(player, "aracKiralama:mesaj", player,
            "#FF6B6B[Kiralama] #FFFFFFAraç oluşturulamadı.", 255, 255, 255)
        return
    end

    setVehicleColor(veh, 230, 164, 52) -- sarımsı renk (GUI ile uyumlu)
    setElementData(veh, "rentedBy", getPlayerName(player))
    setElementData(veh, "rentalVehicle", true)

    warpPedIntoVehicle(player, veh)
    rentedVehicles[player] = veh

    triggerClientEvent(player, "aracKiralama:mesaj", player,
        "#4CAF50[Kiralama] #FFFFFF" .. (name or "Araç") .. " kiralandı! Fiyat: $" .. price, 255, 255, 255)
    triggerClientEvent(player, "aracKiralama:kapat", player)
end)

-- Oyuncu çıkınca aracı sil
addEventHandler("onPlayerQuit", root, function()
    destroyRentedVehicle(source)
end)

-- Araç patlarsa veya silinirse temizle
addEventHandler("onVehicleExplode", root, function()
    for player, veh in pairs(rentedVehicles) do
        if veh == source then
            rentedVehicles[player] = nil
            break
        end
    end
end)

addEventHandler("onElementDestroy", root, function()
    if getElementType(source) ~= "vehicle" then return end
    for player, veh in pairs(rentedVehicles) do
        if veh == source then
            rentedVehicles[player] = nil
            break
        end
    end
end)

-- Komut: /kiralaaracsil  (admin/test için kendi kiraladığı aracı siler)
addCommandHandler("kiralaaracsil", function(player)
    destroyRentedVehicle(player)
    outputChatBox("#4CAF50[Kiralama] #FFFFFFKiralanan araç silindi.", player, 255, 255, 255, true)
end)