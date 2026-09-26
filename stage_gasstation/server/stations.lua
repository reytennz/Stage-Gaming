stations = {}          -- id -> full data
codeToId = {}
local stationElements = {} -- id -> {marker, blip} (server tarafında sadece data tutuyoruz, client render eder)

-- Basit sayısal şifre: 12345, 12346, ...
local nextSimpleCode = 12345

function generateCode()
    local code
    local tries = 0
    repeat
        code = tostring(nextSimpleCode)
        nextSimpleCode = nextSimpleCode + 1
        if nextSimpleCode > 99999 then
            nextSimpleCode = 10000
        end
        tries = tries + 1
        if tries > 90000 then
            -- yedek: rastgele 5 haneli
            code = tostring(math.random(10000, 99999))
        end
    until not codeToId[code]
    return code
end

-- Sahip giriş kodunu değiştirir
addEvent("benzinlik:changeCode", true)
addEventHandler("benzinlik:changeCode", root, function(stationId, newCode)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "changeCode", 2000) then return end
    if not isValidStationOwner(player, stationId) then
        return outputChatBox("» Bu işletmenin sahibi değilsin.", player, 255, 50, 50)
    end
    if not stations[stationId] then return end

    newCode = tostring(newCode or ""):gsub("%s+", "")
    if #newCode < 4 or #newCode > 12 then
        return outputChatBox("» Kod 4-12 karakter olmalı.", player, 255, 50, 50)
    end
    -- Sadece harf/rakam
    if not newCode:match("^[%w]+$") then
        return outputChatBox("» Kod sadece harf ve rakam içerebilir.", player, 255, 50, 50)
    end
    newCode = string.upper(newCode)

    if codeToId[newCode] and codeToId[newCode] ~= stationId then
        return outputChatBox("» Bu kod başka bir işletmede kullanılıyor.", player, 255, 50, 50)
    end

    local old = stations[stationId].code
    if old and codeToId[old] == stationId then
        codeToId[old] = nil
    end
    codeToId[newCode] = stationId
    updateStationData(stationId, { code = newCode })

    dbE("INSERT INTO gas_station_logs (station_id, action, details, player) VALUES (?,?,?,?)",
        stationId, "change_code", "Kod değişti: " .. tostring(old) .. " → " .. newCode, getAccountNameSafe(player))

    outputChatBox("» Giriş kodu güncellendi: §e" .. newCode, player, 0, 255, 100)
    -- Panel verisini tazele
    triggerClientEvent(player, "benzinlik:onStationUpdated", resourceRoot, stations[stationId])
end)

function loadStations()
    stations = {}
    codeToId = {}

    local qh = dbQ("SELECT * FROM gas_stations")
    local result = dbP(qh)
    if not result then return end

    local maxNum = 12344
    for _, row in ipairs(result) do
        row.id = tonumber(row.id) or row.id
        row.for_sale = tonumber(row.for_sale) or 0
        row.sale_price = tonumber(row.sale_price) or 0
        row.level = tonumber(row.level) or 1
        row.balance = tonumber(row.balance) or 0
        row.petrol_stock = tonumber(row.petrol_stock) or 0
        row.diesel_stock = tonumber(row.diesel_stock) or 0
        row.petrol_price = tonumber(row.petrol_price) or 48
        row.diesel_price = tonumber(row.diesel_price) or 52
        stations[row.id] = row
        codeToId[tostring(row.code)] = row.id
        local n = tonumber(row.code)
        if n and n > maxNum then maxNum = n end
    end
    nextSimpleCode = maxNum + 1
    if nextSimpleCode > 99999 then nextSimpleCode = 10000 end

    -- Ürünleri de yükle
    for id in pairs(stations) do
        loadProductsForStation(id)
    end

    -- Ek markerları senkronize et
    local extraMap = {}
    local eq = dbQ("SELECT * FROM gas_station_extra_markers")
    local er = dbP(eq) or {}
    for _, row in ipairs(er) do
        if not extraMap[row.station_id] then extraMap[row.station_id] = {} end
        table.insert(extraMap[row.station_id], row)
    end

    triggerClientEvent(root, "benzinlik:syncAllStations", resourceRoot, stations)
    triggerClientEvent(root, "benzinlik:syncExtraMarkers", resourceRoot, extraMap)
    outputDebugString("[Benzinlik] " .. #result .. " benzinlik yüklendi.")
end

function createStation(name, x, y, z, rot, creator)
    local code = generateCode()
    local qh = dbQ([[
        INSERT INTO gas_stations 
        (code, name, owner, posX, posY, posZ, rot, level, balance, petrol_stock, diesel_stock, 
         petrol_price, diesel_price, petrol_buy, diesel_buy, for_sale, sale_price)
        VALUES (?, ?, NULL, ?, ?, ?, ?, 1, 0, ?, ?, ?, ?, ?, ?, 1, ?)
    ]], code, name, x, y, z, rot or 0,
        Config.DefaultPetrolStock, Config.DefaultDieselStock,
        Config.DefaultPetrolPrice, Config.DefaultDieselPrice,
        Config.DefaultPetrolBuy, Config.DefaultDieselBuy,
        Config.DefaultBuyPrice)

    local result = dbP(qh)
    if not result then return false end

    local id = result.insert_id or dbP(dbQ("SELECT LAST_INSERT_ID() as id"))[1].id

    -- Varsayılan ürünleri ekle
    for _, prod in ipairs(Config.DefaultProducts) do
        dbE("INSERT INTO gas_station_products (station_id, name, buy_price, sell_price, stock, active) VALUES (?,?,?,?,?,1)",
            id, prod.name, prod.buy, prod.sell, prod.stock)
    end

    local data = {
        id = id, code = code, name = name, owner = nil,
        posX = x, posY = y, posZ = z, rot = rot or 0,
        level = 1, balance = 0,
        petrol_stock = Config.DefaultPetrolStock, diesel_stock = Config.DefaultDieselStock,
        petrol_price = Config.DefaultPetrolPrice, diesel_price = Config.DefaultDieselPrice,
        petrol_buy = Config.DefaultPetrolBuy, diesel_buy = Config.DefaultDieselBuy,
        for_sale = 1, sale_price = Config.DefaultBuyPrice
    }

    stations[id] = data
    codeToId[code] = id
    loadProductsForStation(id)

    dbE("INSERT INTO gas_station_logs (station_id, action, details, player) VALUES (?,?,?,?)",
        id, "create", "Benzinlik oluşturuldu: " .. name, getAccountNameSafe(creator) or "SYSTEM")

    triggerClientEvent(root, "benzinlik:createStation", resourceRoot, data)
    return id
end

function deleteStation(id, admin)
    if not stations[id] then return false end
    local name = stations[id].name
    dbE("DELETE FROM gas_stations WHERE id=?", id)
    stations[id] = nil
    for c, sid in pairs(codeToId) do
        if sid == id then codeToId[c] = nil break end
    end
    dbE("INSERT INTO gas_station_logs (station_id, action, details, player) VALUES (?,?,?,?)",
        id, "delete", "Silindi: " .. name, getAccountNameSafe(admin) or "SYSTEM")
    triggerClientEvent(root, "benzinlik:removeStation", resourceRoot, id)
    return true
end

function updateStationData(id, fields)
    if not stations[id] then return false end
    local sets, values = {}, {}
    for k, v in pairs(fields) do
        table.insert(sets, "`" .. k .. "`=?")
        table.insert(values, v)
        stations[id][k] = v
    end
    if #sets == 0 then return false end
    table.insert(values, id)
    dbE("UPDATE gas_stations SET " .. table.concat(sets, ",") .. " WHERE id=?", unpack(values))
    triggerClientEvent(root, "benzinlik:updateStation", resourceRoot, stations[id])
    return true
end

-- Admin komutu
-- Kullanım:
--   /benzinlikler              → ACL Admin veya daha önce kod girmişse açar
--   /benzinlikler KOD          → Admin kodu doğruysa yetki verir ve paneli açar
addCommandHandler("benzinlikler", function(player, _, code)
    if isBenzinlikAdmin(player) then
        triggerClientEvent(player, "benzinlik:openAdminPanel", resourceRoot, stations)
        return
    end

    if code and code ~= "" then
        if authorizeWithCode(player, code) then
            outputChatBox("» Admin kodu kabul edildi. Yönetim paneli açılıyor.", player, 0, 255, 100)
            triggerClientEvent(player, "benzinlik:openAdminPanel", resourceRoot, stations)
        else
            outputChatBox("» Hatalı admin kodu.", player, 255, 50, 50)
        end
        return
    end

    outputChatBox("» Yetkin yok. Kullanım: /benzinlikler ADMIN_KODU", player, 255, 200, 0)
end)

-- Sahip paneli
addCommandHandler("benzinlik", function(player, _, code)
    if not code or code == "" then
        return outputChatBox("» Kullanım: /benzinlik KOD", player, 255, 200, 0)
    end
    code = code:upper()
    local id = codeToId[code]
    if not id or not stations[id] then
        return outputChatBox("» Geçersiz işletme kodu.", player, 255, 50, 50)
    end
    if not isValidStationOwner(player, id) then
        return outputChatBox("» Bu işletmenin sahibi değilsin.", player, 255, 50, 50)
    end
    -- Ürün + istatistik + reklam verilerini de gönder
    local products = getProducts(id)
    local stats = getStationStats(id)
    local ads = getActiveAds(id)
    triggerClientEvent(player, "benzinlik:openOwnerPanel", resourceRoot, stations[id], products, stats, ads)
end)

function countStations()
    local n = 0
    for _ in pairs(stations) do n = n + 1 end
    return n
end

function countOwnedBy(accountName)
    if not accountName then return 0 end
    local n = 0
    for _, st in pairs(stations) do
        if st.owner == accountName then n = n + 1 end
    end
    return n
end

-- Oyuncunun sıradaki satın alma fiyatı (sahip olduğu sayıya göre)
-- Ana konum + ek marker sayısı
function countMarkersForStation(stationId)
    local n = 1 -- ana konum
    local qh = dbQ("SELECT COUNT(*) AS c FROM gas_station_extra_markers WHERE station_id=?", stationId)
    local r = dbP(qh)
    if r and r[1] then n = n + (tonumber(r[1].c) or 0) end
    return n
end

function getExtraMarkers(stationId)
    local qh = dbQ("SELECT * FROM gas_station_extra_markers WHERE station_id=?", stationId)
    return dbP(qh) or {}
end

-- Sonraki ek marker fiyatı (mevcut marker sayısına göre)
-- 1 = sadece ana (ücretsiz geldi) → 2. marker 10k, 3+ 150k
function getNextMarkerPrice(currentMarkerCount)
    local c = tonumber(currentMarkerCount) or 1
    if c < 1 then c = 1 end
    if c >= (Config.MaxMarkersPerStation or 6) then return nil end
    if c == 1 then
        return Config.MarkerPriceFirstExtra or 10000
    end
    return Config.MarkerPriceNext or 150000
end

function getMarkerQuote(stationId)
    local count = countMarkersForStation(stationId)
    local maxM = Config.MaxMarkersPerStation or 6
    local price = getNextMarkerPrice(count)
    return {
        count = count,
        max = maxM,
        price = price or 0,
        canAdd = price ~= nil,
        label = price and ((count + 1) .. ". marker") or "Limit dolu",
        nextSlot = count + 1
    }
end

-- Satılık benzinlik teklifi: adminin belirlediği sale_price (para)
function getBuyQuote(player, stationId)
    local data = stationId and stations[stationId]
    local price = Config.DefaultBuyPrice
    if data then
        price = (data.sale_price and data.sale_price > 0) and data.sale_price or Config.DefaultBuyPrice
    end
    local acc = getAccountNameSafe(player)
    local owned = countOwnedBy(acc)
    local maxS = Config.MaxStations or 6
    return {
        owned = owned,
        max = maxS,
        price = price,
        canBuy = owned < maxS,
        label = "Satış fiyatı",
        nextSlot = owned + 1
    }
end

-- Satın alma teklifi (UI için)
addEvent("benzinlik:requestBuyQuote", true)
addEventHandler("benzinlik:requestBuyQuote", root, function(stationId)
    local player = client
    stationId = tonumber(stationId)
    if not validateClient(player) or not stationId or not stations[stationId] then return end
    local data = stations[stationId]
    if tonumber(data.for_sale) ~= 1 then return end
    local quote = getBuyQuote(player, stationId)
    triggerClientEvent(player, "benzinlik:showBuyUI", resourceRoot, data, quote)
    -- client hem root hem resourceRoot dinliyor
end)

-- Sahip paneli: sıradaki ek marker fiyatı
addEvent("benzinlik:requestOwnerQuote", true)
addEventHandler("benzinlik:requestOwnerQuote", root, function(stationId)
    local player = client
    if not validateClient(player) then return end
    if not stationId or not stations[stationId] or not isValidStationOwner(player, stationId) then return end
    local quote = getMarkerQuote(stationId)
    triggerClientEvent(player, "benzinlik:ownerQuote", resourceRoot, quote)
end)

-- Sahip: sadece ek marker (yeni işletme DEĞİL — aynı kod, aynı yönetim)
addEvent("benzinlik:ownerAddMarker", true)
addEventHandler("benzinlik:ownerAddMarker", root, function(stationId)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "ownerAddMarker", 3000) then return end
    if not stationId or not stations[stationId] then return end
    if not isValidStationOwner(player, stationId) then
        return outputChatBox("» Bu işletmenin sahibi değilsin.", player, 255, 50, 50)
    end

    local quote = getMarkerQuote(stationId)
    if not quote.canAdd then
        return outputChatBox("» Bu işletme için maksimum marker (" .. quote.max .. ").", player, 255, 50, 50)
    end

    local price = quote.price or 0
    if price > 0 and GS_GetMoney(player) < price then
        return outputChatBox("» Yeterli paran yok. Gerekli: " .. formatMoney(price), player, 255, 50, 50)
    end

    if price > 0 then
        GS_RemoveMoney(player, price)
    end

    local x, y, z = getElementPosition(player)
    dbE("INSERT INTO gas_station_extra_markers (station_id, posX, posY, posZ) VALUES (?,?,?,?)",
        stationId, x, y, z)

    local qh = dbQ("SELECT LAST_INSERT_ID() AS id")
    local r = dbP(qh)
    local mid = r and r[1] and r[1].id

    dbE("INSERT INTO gas_station_logs (station_id, action, details, player) VALUES (?,?,?,?)",
        stationId, "add_marker", "Ek marker: " .. formatMoney(price), getAccountNameSafe(player))

    -- Client'a yeni marker senkronu
    triggerClientEvent(root, "benzinlik:addExtraMarker", resourceRoot, stationId, {
        id = mid, station_id = stationId, posX = x, posY = y, posZ = z
    })

    outputChatBox("» Marker eklendi (" .. quote.nextSlot .. "/" .. quote.max .. "). Aynı işletme kodu: §e" .. tostring(stations[stationId].code), player, 0, 255, 100)
    outputChatBox("» Ödenen: " .. formatMoney(price), player, 200, 200, 200)

    triggerClientEvent(player, "benzinlik:ownerQuote", resourceRoot, getMarkerQuote(stationId))
end)

-- Satın alma
addEvent("benzinlik:buyStation", true)
addEventHandler("benzinlik:buyStation", root, function(stationId)
    local player = client
    stationId = tonumber(stationId)
    if not validateClient(player) or not checkRateLimit(player, "buy", 3000) then return end
    if not stationId or not stations[stationId] then
        return outputChatBox("» Benzinlik bulunamadı.", player, 255, 50, 50)
    end

    local data = stations[stationId]
    if tonumber(data.for_sale) ~= 1 then
        return outputChatBox("» Bu benzinlik satışta değil.", player, 255, 50, 50)
    end

    local acc = getAccountNameSafe(player)
    if not acc then
        return outputChatBox("» Hesabınla giriş yapmalısın.", player, 255, 50, 50)
    end

    local owned = countOwnedBy(acc)
    local maxS = Config.MaxStations or 6
    if owned >= maxS then
        return outputChatBox("» Maksimum " .. maxS .. " benzinlik alabilirsin.", player, 255, 50, 50)
    end

    local price = tonumber(data.sale_price) or 0
    if price <= 0 then price = Config.DefaultBuyPrice or 750000 end
    price = math.floor(price)

    if GS_GetMoney(player) < price then
        return outputChatBox("» Yeterli paran yok. Gerekli: " .. formatMoney(price), player, 255, 50, 50)
    end

    GS_RemoveMoney(player, price)

    local newCode = generateCode()
    updateStationData(stationId, {
        owner = acc,
        for_sale = 0,
        sale_price = 0,
        code = newCode
    })
    codeToId[newCode] = stationId
    for c, sid in pairs(codeToId) do
        if sid == stationId and c ~= newCode then
            codeToId[c] = nil
        end
    end

    dbE("INSERT INTO gas_station_logs (station_id, action, details, player) VALUES (?,?,?,?)",
        stationId, "purchase", "Satın alındı: " .. formatMoney(price), acc)

    outputChatBox("» Benzinlik satın alındı! Kod: §e" .. newCode, player, 0, 255, 100)
    outputChatBox("» Ödenen: " .. formatMoney(price), player, 200, 200, 200)
    outputChatBox("» Panel: /benzinlik " .. newCode .. "  veya benzinlikte kodu gir.", player, 200, 200, 200)

    triggerClientEvent(player, "benzinlik:purchaseSuccess", resourceRoot, {
        id = stationId,
        name = stations[stationId].name,
        code = newCode,
        price = price,
        slot = owned + 1,
        owned = owned + 1,
        max = maxS
    })
end)

-- Marker üzerinden kod ile panel açma
addEvent("benzinlik:openByCode", true)
addEventHandler("benzinlik:openByCode", root, function(code)
    local player = client
    if not validateClient(player) or not checkRateLimit(player, "openByCode", 1500) then return end
    if not code or code == "" then
        return outputChatBox("» Kod girilmedi.", player, 255, 50, 50)
    end

    code = string.upper(tostring(code):gsub("%s+", ""))
    local id = codeToId[code]
    if not id then
        -- büyük/küçük duyarsız tarama
        for c, sid in pairs(codeToId) do
            if string.upper(tostring(c)) == code then id = sid break end
        end
    end
    if not id or not stations[id] then
        return outputChatBox("» Geçersiz işletme kodu.", player, 255, 50, 50)
    end
    if not isValidStationOwner(player, id) then
        return outputChatBox("» Bu işletmenin sahibi değilsin.", player, 255, 50, 50)
    end

    local products = getProducts(id)
    local stats = getStationStats(id)
    local ads = getActiveAds(id)
    triggerClientEvent(player, "benzinlik:openOwnerPanel", resourceRoot, stations[id], products, stats, ads)
end)

-- Admin: oluştur
addEvent("benzinlik:adminCreate", true)
addEventHandler("benzinlik:adminCreate", root, function(name, salePrice)
    local player = client
    if not validateClient(player) or not isAdmin(player) then return end
    if not name or name == "" then name = "Benzinlik" end
    salePrice = tonumber(salePrice) or Config.DefaultBuyPrice

    local maxS = Config.MaxStations or 6
    if countStations() >= maxS then
        return outputChatBox("» Sunucuda maksimum " .. maxS .. " benzinlik olabilir.", player, 255, 50, 50)
    end

    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    local id = createStation(name, x, y, z, rot, player)
    if id then
        updateStationData(id, { sale_price = salePrice, for_sale = 1 })
        outputChatBox("» Benzinlik oluşturuldu. ID: " .. id .. " | Kod: " .. stations[id].code .. " (" .. countStations() .. "/" .. maxS .. ")", player, 0, 255, 100)
    else
        outputChatBox("» Oluşturma başarısız.", player, 255, 50, 50)
    end
end)

-- Admin: sil
addEvent("benzinlik:adminDelete", true)
addEventHandler("benzinlik:adminDelete", root, function(stationId)
    local player = client
    if not validateClient(player) or not isAdmin(player) then return end
    if deleteStation(stationId, player) then
        outputChatBox("» Benzinlik silindi.", player, 0, 255, 100)
    end
end)

-- Admin / Sahip: satışa çıkar
addEvent("benzinlik:setForSale", true)
addEventHandler("benzinlik:setForSale", root, function(stationId, price)
    local player = client
    if not validateClient(player) then return end
    if not isAdmin(player) and not isValidStationOwner(player, stationId) then return end

    price = tonumber(price) or 0
    if price < 0 then price = 0 end

    updateStationData(stationId, {
        for_sale = 1,
        sale_price = price
    })
    outputChatBox("» Benzinlik satışa çıkarıldı: " .. formatMoney(price), player, 0, 255, 100)
end)

-- Admin / Sahip: satıştan kaldır
addEvent("benzinlik:removeFromSale", true)
addEventHandler("benzinlik:removeFromSale", root, function(stationId)
    local player = client
    if not validateClient(player) then return end
    if not isAdmin(player) and not isValidStationOwner(player, stationId) then return end

    updateStationData(stationId, { for_sale = 0, sale_price = 0 })
    outputChatBox("» Satıştan kaldırıldı.", player, 0, 255, 100)
end)

-- Sahip değiştir (admin)
addEvent("benzinlik:changeOwner", true)
addEventHandler("benzinlik:changeOwner", root, function(stationId, newOwner)
    local player = client
    if not validateClient(player) or not isAdmin(player) then return end
    if not stations[stationId] then return end

    newOwner = (newOwner and newOwner ~= "") and newOwner or nil
    updateStationData(stationId, { owner = newOwner, for_sale = newOwner and 0 or 1 })
    outputChatBox("» Sahip güncellendi: " .. (newOwner or "Devlet"), player, 0, 255, 100)
end)

-- Konum değiştir
addEvent("benzinlik:changePosition", true)
addEventHandler("benzinlik:changePosition", root, function(stationId)
    local player = client
    if not validateClient(player) or not isAdmin(player) then return end
    if not stations[stationId] then return end

    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    updateStationData(stationId, { posX = x, posY = y, posZ = z, rot = rot })
    outputChatBox("» Konum güncellendi.", player, 0, 255, 100)
end)

-- İsim değiştir
addEvent("benzinlik:renameStation", true)
addEventHandler("benzinlik:renameStation", root, function(stationId, newName)
    local player = client
    if not validateClient(player) then return end
    if not isAdmin(player) and not isValidStationOwner(player, stationId) then return end
    if not newName or newName == "" then return end
    updateStationData(stationId, { name = newName })
    outputChatBox("» İsim güncellendi: " .. newName, player, 0, 255, 100)
end)
