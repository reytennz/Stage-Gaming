--[[
    Galeri stok katalogu
    Kayit: vehicle_id, name, price, stock
    Freeroam handling fiyati KULLANILMAZ.
]]

local catalog = {} -- [modelId] = { id, name, price, stock }
local stockFile = "extensions/stock_data.json"

local DEFAULT_CATALOG = {
    { id = 534, name = "Alfa Romeo Giulia", price = 210000, stock = 6 },
    { id = 461, name = "Aprilia RSV4", price = 620000, stock = 5 },
    { id = 471, name = "ATV Army", price = 160000, stock = 10 },
    { id = 466, name = "Audi A4", price = 430000, stock = 6 },
    { id = 567, name = "Audi R8", price = 900000, stock = 3 },
    { id = 509, name = "Bisiklet Basik Cocuk", price = 160000, stock = 10 },
    { id = 404, name = "BMW 525", price = 260000, stock = 10 },
    { id = 549, name = "BMW Cabrio", price = 260000, stock = 10 },
    { id = 575, name = "BMW E30", price = 260000, stock = 10 },
    { id = 527, name = "BMW E60", price = 620000, stock = 5 },
    { id = 477, name = "BMW M3", price = 620000, stock = 5 },
    { id = 565, name = "BMW M3 V2", price = 620000, stock = 5 },
    { id = 546, name = "BMW M4", price = 900000, stock = 3 },
    { id = 541, name = "BMW M5 F10", price = 900000, stock = 3 },
    { id = 536, name = "Dacia Polis", price = 300000, stock = 7 },
    { id = 494, name = "Dodge Charger 1970", price = 900000, stock = 3 },
    { id = 502, name = "Dodge Demon", price = 900000, stock = 3 },
    { id = 400, name = "Escalade Cadillac", price = 430000, stock = 6 },
    { id = 402, name = "Ferrari 458 Italia", price = 900000, stock = 3 },
    { id = 603, name = "Fiat Albea", price = 185000, stock = 10 },
    { id = 507, name = "Fiat Doblo", price = 300000, stock = 7 },
    { id = 535, name = "Fiat Ducato", price = 300000, stock = 7 },
    { id = 413, name = "Fiat Fiorino", price = 300000, stock = 7 },
    { id = 525, name = "Ford Cekici", price = 300000, stock = 7 },
    { id = 560, name = "Ford Courier", price = 185000, stock = 10 },
    { id = 470, name = "Ford F-150", price = 430000, stock = 6 },
    { id = 529, name = "Ford Focus Sedan", price = 185000, stock = 10 },
    { id = 503, name = "Ford Mustang GT", price = 900000, stock = 3 },
    { id = 585, name = "Ford Transit", price = 300000, stock = 7 },
    { id = 416, name = "Ford Transit", price = 300000, stock = 7 },
    { id = 487, name = "Helikopter", price = 300000, stock = 2 },
    { id = 543, name = "Honda Civic Hb", price = 260000, stock = 10 },
    { id = 561, name = "Honda Civic Type R", price = 620000, stock = 5 },
    { id = 411, name = "Honda Civic VTEC", price = 260000, stock = 10 },
    { id = 426, name = "Honda S2000", price = 620000, stock = 5 },
    { id = 405, name = "Honda S2000 Ustu Acik", price = 620000, stock = 5 },
    { id = 421, name = "Hyundai Accent", price = 185000, stock = 10 },
    { id = 401, name = "Hyundai H 100", price = 185000, stock = 10 },
    { id = 431, name = "Kamil Koc Otobus", price = 300000, stock = 2 },
    { id = 521, name = "Kawasaki Ninja H2R", price = 620000, stock = 5 },
    { id = 581, name = "Kuba Motor", price = 160000, stock = 10 },
    { id = 442, name = "Lada Vaz", price = 185000, stock = 10 },
    { id = 580, name = "Lamborghini Huracan", price = 900000, stock = 3 },
    { id = 558, name = "Mazda RX 7", price = 260000, stock = 10 },
    { id = 587, name = "Mazda RX-8", price = 620000, stock = 5 },
    { id = 445, name = "Mazda Speed 3", price = 260000, stock = 10 },
    { id = 518, name = "Mclaren P1 Sport Pack", price = 900000, stock = 3 },
    { id = 474, name = "Mercedes Actros", price = 430000, stock = 6 },
    { id = 410, name = "Mercedes AMG GT", price = 900000, stock = 3 },
    { id = 479, name = "Mercedes Cls63", price = 900000, stock = 3 },
    { id = 600, name = "Mercedes E 500", price = 430000, stock = 6 },
    { id = 579, name = "Mercedes G63", price = 900000, stock = 3 },
    { id = 533, name = "Mercedes S600 Maybach", price = 900000, stock = 3 },
    { id = 545, name = "Mercedes Sprinter", price = 300000, stock = 7 },
    { id = 492, name = "Mitsubishi Evo 9", price = 620000, stock = 5 },
    { id = 434, name = "Murat 124", price = 185000, stock = 10 },
    { id = 589, name = "Nissan 240 Sx", price = 260000, stock = 10 },
    { id = 562, name = "Nissan 350Z", price = 620000, stock = 5 },
    { id = 517, name = "Nissan Polis", price = 300000, stock = 7 },
    { id = 439, name = "Nissan Qashqai", price = 430000, stock = 6 },
    { id = 555, name = "Nissan Silvia S14", price = 620000, stock = 5 },
    { id = 451, name = "Nissan Silvia S15", price = 620000, stock = 5 },
    { id = 500, name = "Nissan Skyline GT-R35", price = 900000, stock = 3 },
    { id = 412, name = "Nissan Skyline R33", price = 620000, stock = 5 },
    { id = 422, name = "Nissan Skyline R34", price = 620000, stock = 5 },
    { id = 458, name = "Opel Insignia", price = 430000, stock = 6 },
    { id = 605, name = "Peugeot 106", price = 185000, stock = 10 },
    { id = 429, name = "Porsche 911 GT", price = 900000, stock = 3 },
    { id = 576, name = "Range Rover", price = 430000, stock = 6 },
    { id = 505, name = "Range Rover", price = 430000, stock = 6 },
    { id = 559, name = "Renault Clio", price = 185000, stock = 10 },
    { id = 566, name = "Renault Megane 2", price = 185000, stock = 10 },
    { id = 550, name = "Renault Toros", price = 185000, stock = 10 },
    { id = 457, name = "Renault Twizy", price = 160000, stock = 10 },
    { id = 496, name = "Skoda Super B", price = 260000, stock = 10 },
    { id = 526, name = "Subaru Impreza", price = 620000, stock = 5 },
    { id = 415, name = "Tofas Dogan", price = 185000, stock = 10 },
    { id = 491, name = "Tofas Dogan SLX", price = 185000, stock = 10 },
    { id = 582, name = "Tofas Izmir Isi", price = 185000, stock = 10 },
    { id = 596, name = "Tofas Kartal SLX", price = 185000, stock = 10 },
    { id = 551, name = "Tofas Sahin", price = 185000, stock = 10 },
    { id = 438, name = "Tofas Tempra", price = 185000, stock = 10 },
    { id = 418, name = "Toyota Mark 2", price = 185000, stock = 10 },
    { id = 475, name = "Toyota Supra", price = 620000, stock = 5 },
    { id = 542, name = "Toyota Supra 2020", price = 900000, stock = 3 },
    { id = 519, name = "Ucak Solo Turk", price = 300000, stock = 2 },
    { id = 419, name = "Volkswagen Golf", price = 185000, stock = 10 },
    { id = 436, name = "Volkswagen Passat", price = 430000, stock = 6 },
    { id = 602, name = "Volkswagen Scirocco", price = 620000, stock = 5 },
}

-- Okunabilir JSON: her arac alt alta
-- [
--   {
--     "id": 411,
--     "name": "BMW M4",
--     "price": 950000,
--     "stock": 5
--   },
--   ...
-- ]
local function escapeJsonStr(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "")
    return s
end

local function saveCatalog()
    local list = {}
    for _, v in pairs(catalog) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    local lines = { "[" }
    for i, v in ipairs(list) do
        local comma = (i < #list) and "," or ""
        table.insert(lines, "  {")
        table.insert(lines, '    "id": ' .. tostring(v.id) .. ",")
        table.insert(lines, '    "name": "' .. escapeJsonStr(v.name) .. '",')
        table.insert(lines, '    "price": ' .. tostring(math.floor(v.price or 0)) .. ",")
        table.insert(lines, '    "stock": ' .. tostring(math.floor(v.stock or 0)))
        table.insert(lines, "  }" .. comma)
    end
    table.insert(lines, "]")
    table.insert(lines, "")

    if fileExists(stockFile) then fileDelete(stockFile) end
    local f = fileCreate(stockFile)
    if f then
        fileWrite(f, table.concat(lines, "\n"))
        fileClose(f)
    end
end

local function loadCatalog()
    catalog = {}
    if fileExists(stockFile) then
        local f = fileOpen(stockFile)
        if f then
            local data = fileRead(f, fileGetSize(f))
            fileClose(f)
            local ok, t = pcall(fromJSON, data)
            if ok and type(t) == "table" then
                -- Yeni format: dizi [ {id,name,price,stock}, ... ]
                -- Eski format: { "411" = { ... }, ... }
                local isArray = (t[1] ~= nil)
                if isArray then
                    for _, v in ipairs(t) do
                        if type(v) == "table" then
                            local id = tonumber(v.id)
                            if id then
                                catalog[id] = {
                                    id = id,
                                    name = tostring(v.name or ("ID "..id)),
                                    price = math.max(0, tonumber(v.price) or 0),
                                    stock = math.max(0, tonumber(v.stock) or 0),
                                }
                            end
                        end
                    end
                else
                    for k, v in pairs(t) do
                        if type(v) == "table" then
                            local id = tonumber(v.id or k)
                            if id then
                                catalog[id] = {
                                    id = id,
                                    name = tostring(v.name or ("ID "..id)),
                                    price = math.max(0, tonumber(v.price) or 0),
                                    stock = math.max(0, tonumber(v.stock) or 0),
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    if not next(catalog) then
        for _, v in ipairs(DEFAULT_CATALOG) do
            catalog[v.id] = { id = v.id, name = v.name, price = v.price, stock = v.stock }
        end
        saveCatalog()
    end
end

local function catalogList()
    local list = {}
    for _, v in pairs(catalog) do
        table.insert(list, { id = v.id, name = v.name, price = v.price, stock = v.stock })
    end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

function getStockCatalogEntry(model)
    model = tonumber(model)
    return model and catalog[model] or nil
end

local _getVehiclePrice = getVehiclePrice
function getVehiclePrice(model)
    model = tonumber(model)
    local e = catalog[model]
    if e then return e.price end
    if _getVehiclePrice then return _getVehiclePrice(model) end
    return 15000
end

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        loadCatalog()
        outputDebugString("[F1 Stock] Katalog: " .. tostring(#catalogList()) .. " arac", 3)
    end, 150, 1)
end)

addEvent("f1stock:requestAll", true)
addEventHandler("f1stock:requestAll", root, function()
    local player = client
    if not isElement(player) then return end
    triggerClientEvent(player, "f1stock:receiveCatalog", resourceRoot, catalogList())
end)

local _buyVehicleOrig = buyVehicle
function buyVehicle(vehID)
    local player = client or source
    vehID = tonumber(vehID)
    if not vehID then return end
    local entry = catalog[vehID]
    if not entry then
        errMsg("Bu arac galeride yok.", player)
        return
    end
    if (entry.stock or 0) <= 0 then
        errMsg("Bu arac stokta yok.", player)
        return
    end
    local price = entry.price or 0
    if not StageHasMoney(player, price) then
        errMsg(("[✘] Yeterli paraniz yok. (Fiyat: $%s)"):format(formatMoney and formatMoney(price) or tostring(price)), player)
        return
    end
    if not StageRemoveMoney(player, price) then
        errMsg("[✘] Para islemi basarisiz oldu, satin alma iptal edildi.", player)
        return
    end
    entry.stock = entry.stock - 1
    saveCatalog()
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())

    local serial = getPlayerSerial(player)
    local garage = ensureGarage(serial)
    local id = garage.nextId
    garage.nextId = id + 1
    garage.vehicles[id] = {
        model = vehID,
        name = entry.name,
        plate = generateGaragePlate(),
        active = false,
        colors = {255,255,255, 255,255,255, 0,0,0, 0,0,0},
        headlight = {255,255,255},
        wheelcolor = {0,0,0},
    }
    outputChatBox(("[✔] %s satin alindi ($%s). Kalan stok: %d"):format(
        entry.name, formatMoney and formatMoney(price) or tostring(price), entry.stock
    ), player, 0, 255, 0, true)
    if countActiveGarageVehicles(serial) < MAX_ACTIVE_GARAGE_VEHICLES then
        local vehicle = spawnGarageVehicle(player, serial, id)
        if vehicle then
            outputChatBox("[ⓘ] Araciniz yaninizda hazir.", player, 0, 150, 255, true)
        end
    else
        outputChatBox(("[ⓘ] En fazla %d aktif arac. F1 > Araclarim'dan aktif edin."):format(MAX_ACTIVE_GARAGE_VEHICLES), player, 255, 200, 0, true)
    end
    saveGarageData()
    sendGarageList(player)
    triggerClientEvent(player, "stageGarage:openAfterBuy", resourceRoot)
end

local function isStockAdmin(player)
    if StageIsAdmin then
        return StageIsAdmin(player)
    end
    if not isElement(player) then return false end
    local acc = getPlayerAccount(player)
    if acc and not isGuestAccount(acc) then
        if isObjectInACLGroup("user." .. getAccountName(acc), aclGetGroup("Admin")) then return true end
        if isObjectInACLGroup("user." .. getAccountName(acc), aclGetGroup("Console")) then return true end
    end
    if getElementData(player, "adminlevel") and tonumber(getElementData(player, "adminlevel")) >= 1 then return true end
    return false
end

addCommandHandler("stok", function(player)
    if not isStockAdmin(player) then
        outputChatBox("[✘] Bu komutu kullanma yetkiniz yok.", player, 255, 50, 50)
        return
    end
    triggerClientEvent(player, "f1stock:openAdmin", player, catalogList())
end)

addEvent("f1stock:adminAction", true)
addEventHandler("f1stock:adminAction", root, function(model, action, amount)
    local player = client
    if not isStockAdmin(player) then return end
    model = tonumber(model)
    amount = math.floor(tonumber(amount) or 0)
    local e = catalog[model]
    if not e then
        outputChatBox("[Stok] Arac katalogda yok.", player, 255, 200, 0)
        return
    end
    if action == "add" then e.stock = e.stock + amount
    elseif action == "remove" then e.stock = math.max(0, e.stock - amount)
    elseif action == "set" then e.stock = math.max(0, amount)
    elseif action == "reset" then e.stock = 0
    end
    saveCatalog()
    outputChatBox(("[Stok] %s (ID %d) stok: %d"):format(e.name, model, e.stock), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
    triggerClientEvent(player, "f1stock:openAdmin", player, catalogList())
end)

addEvent("f1stock:adminSetPrice", true)
addEventHandler("f1stock:adminSetPrice", root, function(model, price)
    local player = client
    if not isStockAdmin(player) then return end
    model = tonumber(model)
    price = math.max(0, math.floor(tonumber(price) or 0))
    local e = catalog[model]
    if not e then return end
    e.price = price
    saveCatalog()
    outputChatBox(("[Stok] %s fiyat: $%s"):format(e.name, tostring(price)), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
    triggerClientEvent(player, "f1stock:openAdmin", player, catalogList())
end)

addCommandHandler("stokekle", function(player, _, model, price, stock, ...)
    if not isStockAdmin(player) then
        outputChatBox("[✘] Yetkiniz yok.", player, 255, 50, 50)
        return
    end
    model = tonumber(model)
    price = tonumber(price)
    stock = tonumber(stock) or 1
    local name = table.concat({ ... }, " ")
    if not model or not price then
        outputChatBox("Kullanim: /stokekle [id] [fiyat] [stok] [isim...]", player, 255, 200, 0)
        return
    end
    name = (name ~= "" and name) or getVehicleNameFromModel(model) or ("ID "..model)
    catalog[model] = { id = model, name = name, price = price, stock = stock }
    saveCatalog()
    outputChatBox(("[Stok] Eklendi: %s ID:%d $%s stok:%d"):format(name, model, tostring(price), stock), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
end)

addCommandHandler("stokayar", function(player, _, model, amount)
    if not isStockAdmin(player) then return end
    model = tonumber(model)
    amount = tonumber(amount)
    if not model or not amount or not catalog[model] then
        outputChatBox("Kullanim: /stokayar [id] [stok]", player, 255, 200, 0)
        return
    end
    catalog[model].stock = math.max(0, math.floor(amount))
    saveCatalog()
    outputChatBox(("[Stok] %s stok: %d"):format(catalog[model].name, catalog[model].stock), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
end)

addCommandHandler("stokfiyat", function(player, _, model, price)
    if not isStockAdmin(player) then return end
    model = tonumber(model)
    price = tonumber(price)
    if not model or not price or not catalog[model] then
        outputChatBox("Kullanim: /stokfiyat [id] [fiyat]", player, 255, 200, 0)
        return
    end
    catalog[model].price = math.max(0, math.floor(price))
    saveCatalog()
    outputChatBox(("[Stok] %s fiyat: $%s"):format(catalog[model].name, tostring(catalog[model].price)), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
end)

-- Isim degistir (orijinal GTA ismi degil, senin yazdigin)
addEvent("f1stock:adminSetName", true)
addEventHandler("f1stock:adminSetName", root, function(model, name)
    local player = client
    if not isStockAdmin(player) then return end
    model = tonumber(model)
    if type(name) ~= "string" then return end
    name = name:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 48)
    if name == "" then
        outputChatBox("[Stok] Isim bos olamaz.", player, 255, 50, 50)
        return
    end
    local e = catalog[model]
    if not e then
        outputChatBox("[Stok] Arac katalogda yok.", player, 255, 200, 0)
        return
    end
    e.name = name
    saveCatalog()
    outputChatBox(("[Stok] ID %d ismi artik: %s"):format(model, name), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
    triggerClientEvent(player, "f1stock:openAdmin", player, catalogList())
end)

addCommandHandler("stokisim", function(player, _, model, ...)
    if not isStockAdmin(player) then
        outputChatBox("[✘] Yetkiniz yok.", player, 255, 50, 50)
        return
    end
    model = tonumber(model)
    local name = table.concat({ ... }, " ")
    if not model or name == "" then
        outputChatBox("Kullanim: /stokisim [id] [istedigin isim]", player, 255, 200, 0)
        outputChatBox("Ornek: /stokisim 411 BMW M4 Competition", player, 255, 200, 0)
        return
    end
    if not catalog[model] then
        outputChatBox("[Stok] Bu ID katalogda yok. Once /stokekle ile ekle.", player, 255, 50, 50)
        return
    end
    catalog[model].name = name:sub(1, 48)
    saveCatalog()
    outputChatBox(("[Stok] ID %d galeri ismi: %s"):format(model, catalog[model].name), player, 0, 255, 100)
    triggerClientEvent(root, "f1stock:catalogUpdated", resourceRoot, catalogList())
end)

