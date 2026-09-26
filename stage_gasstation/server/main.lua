addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        if connection then
            loadStations()
        end
    end, 2000, 1)

    -- Minimum stok uyarısı (sahibe)
    setTimer(function()
        for id, data in pairs(stations) do
            if data.owner then
                local levelData = getLevelData(data.level)
                if (data.petrol_stock or 0) < Config.MinStockWarning or (data.diesel_stock or 0) < Config.MinStockWarning then
                    for _, player in ipairs(getElementsByType("player")) do
                        if getAccountNameSafe(player) == data.owner then
                            outputChatBox("» [Benzinlik] Stok uyarısı! " .. data.name .. " yakıt stoğu düşük.", player, 255, 180, 0)
                        end
                    end
                end
            end
        end
    end, 300000, 0) -- 5 dakikada bir
end)

-- Oyuncu girdiğinde istasyonları senkronize et
addEventHandler("onPlayerJoin", root, function()
    setTimer(function(player)
        if isElement(player) then
            triggerClientEvent(player, "benzinlik:syncAllStations", resourceRoot, stations)
        end
    end, 2000, 1, source)
end)

-- Yakıt alma (client/fuel.lua'dan)
addEvent("benzinlik:buyFuel", true)
addEventHandler("benzinlik:buyFuel", root, function(stationId, fuelType, liters)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "buyFuel", 2000) then return end
    if not stations[stationId] then return end

    liters = math.floor(tonumber(liters) or 0)
    if liters < 1 or liters > 100 then
        return outputChatBox("» Geçersiz litre (1-100).", player, 255, 50, 50)
    end

    local data = stations[stationId]
    local stockKey = fuelType .. "_stock"
    local priceKey = fuelType .. "_price"
    local stock = data[stockKey] or 0
    local price = data[priceKey] or 50

    if stock < liters then
        return outputChatBox("» Yetersiz stok. Mevcut: " .. stock .. "L", player, 255, 50, 50)
    end

    local total = liters * price
    if GS_GetMoney(player) < total then
        return outputChatBox("» Yeterli paran yok. Gerekli: " .. formatMoney(total), player, 255, 50, 50)
    end

    -- Araç kontrolü
    local veh = getPedOccupiedVehicle(player)
    if not veh then
        return outputChatBox("» Bir araçta olmalısın.", player, 255, 50, 50)
    end

    GS_RemoveMoney(player, total)
    local paid = addFuelSale(stationId, fuelType, liters, price, player)

    -- Client'a yakıt ekle (gerçek yakıt sistemi entegrasyonu için event)
    triggerClientEvent(player, "benzinlik:addVehicleFuel", resourceRoot, liters, fuelType)

    outputChatBox("» " .. liters .. "L " .. (fuelType == "petrol" and "Benzin" or "Dizel") .. " alındı. Toplam: " .. formatMoney(paid), player, 0, 255, 100)
end)

outputDebugString("[Benzinlik] Server main yüklendi.")
