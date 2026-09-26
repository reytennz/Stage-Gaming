function addTransaction(stationId, type, category, amount, description, playerName)
    if not stations[stationId] then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false end

    dbE("INSERT INTO gas_station_transactions (station_id, type, category, amount, description, player) VALUES (?,?,?,?,?,?)",
        stationId, type, category, amount, description or "", playerName or "SYSTEM")

    -- Kasa güncelle
    local newBalance = stations[stationId].balance
    if type == "income" then
        newBalance = newBalance + amount
    else
        newBalance = newBalance - amount
    end
    updateStationData(stationId, { balance = newBalance })

    -- Günlük istatistik
    local today = os.date("%Y-%m-%d")
    local field = (type == "income") and "income" or "expense"
    dbE([[
        INSERT INTO gas_station_stats (station_id, date, income, expense)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            income = income + VALUES(income),
            expense = expense + VALUES(expense)
    ]], stationId, today,
        type == "income" and amount or 0,
        type == "expense" and amount or 0)

    return true
end

function addFuelSale(stationId, fuelType, liters, pricePerLiter, player)
    local total = math.floor(liters * pricePerLiter)
    local cat = (fuelType == "petrol") and "petrol_sale" or "diesel_sale"
    local desc = liters .. "L " .. (fuelType == "petrol" and "Benzin" or "Dizel") .. " satışı"

    addTransaction(stationId, "income", cat, total, desc, getAccountNameSafe(player))

    -- Stok düş
    local stockKey = fuelType .. "_stock"
    local newStock = math.max(0, (stations[stationId][stockKey] or 0) - liters)
    updateStationData(stationId, { [stockKey] = newStock })

    -- İstatistik
    local today = os.date("%Y-%m-%d")
    local soldField = (fuelType == "petrol") and "petrol_sold" or "diesel_sold"
    dbE([[
        INSERT INTO gas_station_stats (station_id, date, ]] .. soldField .. [[, customers)
        VALUES (?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE 
            ]] .. soldField .. [[ = ]] .. soldField .. [[ + VALUES(]] .. soldField .. [[),
            customers = customers + 1
    ]], stationId, today, liters)

    return total
end

function buyWholesaleFuel(player, stationId, fuelType, liters)
    if not isValidStationOwner(player, stationId) then return false, "Yetkisiz" end
    liters = math.floor(tonumber(liters) or 0)
    if liters <= 0 then return false, "Geçersiz miktar" end

    local data = stations[stationId]
    local levelData = getLevelData(data.level)
    local capacity = (fuelType == "petrol") and levelData.capacityPetrol or levelData.capacityDiesel
    local stockKey = fuelType .. "_stock"
    local current = data[stockKey] or 0

    if current + liters > capacity then
        return false, "Depo kapasitesi yetersiz. Kalan: " .. (capacity - current) .. "L"
    end

    local buyPrice = (fuelType == "petrol") and data.petrol_buy or data.diesel_buy
    local totalCost = liters * buyPrice

    if data.balance < totalCost then
        return false, "Kasa yetersiz. Gerekli: " .. formatMoney(totalCost)
    end

    -- Kasa düş + stok artır
    addTransaction(stationId, "expense", "buy_fuel", totalCost,
        liters .. "L " .. (fuelType == "petrol" and "Benzin" or "Dizel") .. " toptan alımı",
        getAccountNameSafe(player))

    updateStationData(stationId, { [stockKey] = current + liters })
    return true, "Başarılı"
end

-- Para yatırma (oyuncudan kasaya)
addEvent("benzinlik:deposit", true)
addEventHandler("benzinlik:deposit", root, function(stationId, amount)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "deposit", 2000) then return end
    if not isValidStationOwner(player, stationId) then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if GS_GetMoney(player) < amount then
        return outputChatBox("» Yeterli paran yok.", player, 255, 50, 50)
    end

    GS_RemoveMoney(player, amount)
    addTransaction(stationId, "income", "deposit", amount, "Para yatırma", getAccountNameSafe(player))
    outputChatBox("» " .. formatMoney(amount) .. " kasaya yatırıldı.", player, 0, 255, 100)
end)

-- Para çekme (kasadan oyuncuya)
addEvent("benzinlik:withdraw", true)
addEventHandler("benzinlik:withdraw", root, function(stationId, amount)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "withdraw", 2000) then return end
    if not isValidStationOwner(player, stationId) then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if stations[stationId].balance < amount then
        return outputChatBox("» Kasada yeterli para yok.", player, 255, 50, 50)
    end

    addTransaction(stationId, "expense", "withdraw", amount, "Para çekme", getAccountNameSafe(player))
    GS_AddMoney(player, amount)
    outputChatBox("» " .. formatMoney(amount) .. " çekildi.", player, 0, 255, 100)
end)

-- Fiyat değiştir
addEvent("benzinlik:setFuelPrice", true)
addEventHandler("benzinlik:setFuelPrice", root, function(stationId, fuelType, newPrice)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end
    newPrice = math.floor(tonumber(newPrice) or 0)
    if newPrice < 1 or newPrice > 500 then
        return outputChatBox("» Fiyat 1-500 arasında olmalı.", player, 255, 50, 50)
    end

    local key = (fuelType == "petrol") and "petrol_price" or "diesel_price"
    updateStationData(stationId, { [key] = newPrice })
    outputChatBox("» " .. (fuelType == "petrol" and "Benzin" or "Dizel") .. " satış fiyatı: " .. formatMoney(newPrice) .. "/L", player, 0, 255, 100)
end)

-- Toptan yakıt al
addEvent("benzinlik:buyWholesale", true)
addEventHandler("benzinlik:buyWholesale", root, function(stationId, fuelType, liters)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "wholesale", 2000) then return end
    local ok, msg = buyWholesaleFuel(player, stationId, fuelType, liters)
    outputChatBox("» " .. msg, player, ok and 0 or 255, ok and 255 or 50, ok and 100 or 50)
end)

function getStationStats(stationId)
    local qh = dbQ([[
        SELECT date, petrol_sold, diesel_sold, market_sold, customers, income, expense
        FROM gas_station_stats
        WHERE station_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ORDER BY date ASC
    ]], stationId)
    return dbP(qh) or {}
end
