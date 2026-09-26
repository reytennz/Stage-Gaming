local productsCache = {} -- stationId -> {product rows}

function loadProductsForStation(stationId)
    local qh = dbQ("SELECT * FROM gas_station_products WHERE station_id = ?", stationId)
    local result = dbP(qh) or {}
    productsCache[stationId] = result
    return result
end

function getProducts(stationId)
    if not productsCache[stationId] then
        return loadProductsForStation(stationId)
    end
    return productsCache[stationId]
end

function refreshProducts(stationId)
    productsCache[stationId] = nil
    return loadProductsForStation(stationId)
end

-- Client market için ürün listesi
addEvent("benzinlik:requestProducts", true)
addEventHandler("benzinlik:requestProducts", root, function(stationId)
    local player = client
    if not validateClient(player) or not stations[stationId] then return end
    triggerClientEvent(player, "benzinlik:receiveProducts", resourceRoot, getProducts(stationId))
end)

addEvent("benzinlik:addProduct", true)
addEventHandler("benzinlik:addProduct", root, function(stationId, name, buyPrice, sellPrice, stock)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end

    name = tostring(name or ""):sub(1, 64)
    if name == "" then return end

    buyPrice = math.floor(tonumber(buyPrice) or 0)
    sellPrice = math.floor(tonumber(sellPrice) or 0)
    stock = math.floor(tonumber(stock) or 0)

    local levelData = getLevelData(stations[stationId].level)
    local current = getProducts(stationId)
    if #current >= levelData.maxProducts then
        return outputChatBox("» Maksimum ürün limitine ulaştın (Seviye " .. stations[stationId].level .. ").", player, 255, 50, 50)
    end

    dbE("INSERT INTO gas_station_products (station_id, name, buy_price, sell_price, stock, active) VALUES (?,?,?,?,?,1)",
        stationId, name, buyPrice, sellPrice, stock)

    refreshProducts(stationId)
    outputChatBox("» Ürün eklendi: " .. name, player, 0, 255, 100)
    triggerClientEvent(player, "benzinlik:refreshProducts", resourceRoot, getProducts(stationId))
end)

addEvent("benzinlik:updateProduct", true)
addEventHandler("benzinlik:updateProduct", root, function(stationId, productId, fields)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end

    local sets, values = {}, {}
    if fields.name then table.insert(sets, "name=?") table.insert(values, tostring(fields.name):sub(1,64)) end
    if fields.buy_price then table.insert(sets, "buy_price=?") table.insert(values, math.floor(tonumber(fields.buy_price) or 0)) end
    if fields.sell_price then table.insert(sets, "sell_price=?") table.insert(values, math.floor(tonumber(fields.sell_price) or 0)) end
    if fields.stock then table.insert(sets, "stock=?") table.insert(values, math.floor(tonumber(fields.stock) or 0)) end
    if fields.active ~= nil then table.insert(sets, "active=?") table.insert(values, fields.active and 1 or 0) end

    if #sets == 0 then return end
    table.insert(values, productId)
    table.insert(values, stationId)
    dbE("UPDATE gas_station_products SET " .. table.concat(sets, ",") .. " WHERE id=? AND station_id=?", unpack(values))

    refreshProducts(stationId)
    triggerClientEvent(player, "benzinlik:refreshProducts", resourceRoot, getProducts(stationId))
end)

addEvent("benzinlik:deleteProduct", true)
addEventHandler("benzinlik:deleteProduct", root, function(stationId, productId)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end
    dbE("DELETE FROM gas_station_products WHERE id=? AND station_id=?", productId, stationId)
    refreshProducts(stationId)
    triggerClientEvent(player, "benzinlik:refreshProducts", resourceRoot, getProducts(stationId))
    outputChatBox("» Ürün silindi.", player, 0, 255, 100)
end)

-- Market satışı (oyuncu tarafından)
addEvent("benzinlik:buyProduct", true)
addEventHandler("benzinlik:buyProduct", root, function(stationId, productId, quantity)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "buyProduct", 1500) then return end
    if not stations[stationId] then return end

    quantity = math.floor(tonumber(quantity) or 1)
    if quantity < 1 then return end

    local prods = getProducts(stationId)
    local product
    for _, p in ipairs(prods) do
        if p.id == productId then product = p break end
    end
    if not product or product.active ~= 1 then
        return outputChatBox("» Ürün bulunamadı veya pasif.", player, 255, 50, 50)
    end
    if product.stock < quantity then
        return outputChatBox("» Yetersiz stok.", player, 255, 50, 50)
    end

    local total = product.sell_price * quantity
    if GS_GetMoney(player) < total then
        return outputChatBox("» Yeterli paran yok.", player, 255, 50, 50)
    end

    GS_RemoveMoney(player, total)
    dbE("UPDATE gas_station_products SET stock = stock - ? WHERE id=?", quantity, productId)
    refreshProducts(stationId)

    addTransaction(stationId, "income", "market", total,
        quantity .. "x " .. product.name, getAccountNameSafe(player))

    -- İstatistik
    local today = os.date("%Y-%m-%d")
    dbE([[
        INSERT INTO gas_station_stats (station_id, date, market_sold, customers, income)
        VALUES (?, ?, ?, 1, ?)
        ON DUPLICATE KEY UPDATE 
            market_sold = market_sold + VALUES(market_sold),
            customers = customers + 1,
            income = income + VALUES(income)
    ]], stationId, today, quantity, total)

    outputChatBox("» " .. quantity .. "x " .. product.name .. " satın alındı. Toplam: " .. formatMoney(total), player, 0, 255, 100)
end)
