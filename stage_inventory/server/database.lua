local playerInventories, playerHotbars = {}, {}
local depots = {}
local playerKeys = {}
local db = nil

local function getMysqlConfig()
    return Config.MySQL or Config.mysql or {}
end

local function connectInventoryDB()
    local c = getMysqlConfig()
    if c.enabled == false then return false end
    local database = c.database or c.dbname or "stage"
    local connStr = string.format(
        "dbname=%s;host=%s;port=%d;charset=utf8",
        database,
        c.host or "localhost",
        tonumber(c.port) or 3306
    )
    db = dbConnect("mysql", connStr, c.user or "root", c.password or "", "share=1")
    if not db then
        outputDebugString("[Stage Inventory] MySQL baglantisi basarisiz, gecici cache kullanilacak.", 1)
        return false
    end
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS stage_inventory_players (
            player_key VARCHAR(96) NOT NULL PRIMARY KEY,
            inventory_json LONGTEXT NOT NULL,
            hotbar_json LONGTEXT NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS stage_inventory_depots (
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(32) NOT NULL,
            depot_type VARCHAR(16) NOT NULL DEFAULT 'personal',
            owner_key VARCHAR(96) NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            interior INT NOT NULL DEFAULT 0,
            dimension INT NOT NULL DEFAULT 0,
            contents_json LONGTEXT NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    outputDebugString("[Stage Inventory] MySQL baglandi.")
    return true
end

local function unpackDepotContents(json)
    local contents = {}
    local ok, decoded = pcall(fromJSON, json or "")
    if not ok or type(decoded) ~= "table" then return contents end
    for _, row in pairs(decoded) do
        local slot = tonumber(row.slot)
        if slot and row.item and tonumber(row.count) then
            contents[slot] = { item = tostring(row.item), count = tonumber(row.count), ammo = tonumber(row.ammo) or nil }
        end
    end
    return contents
end

local function packDepotContents(contents)
    local packed = {}
    for slot, entry in pairs(contents or {}) do
        if entry and entry.item and entry.count then
            packed[#packed + 1] = { slot = tonumber(slot), item = entry.item, count = tonumber(entry.count), ammo = entry.ammo }
        end
    end
    return toJSON(packed, true)
end

function dbSaveDepot(obj)
    local data = depots[obj]
    if not db or not data or not isElement(obj) then return false end
    dbExec(db, [[
        UPDATE stage_inventory_depots SET name = ?, depot_type = ?, owner_key = ?, x = ?, y = ?, z = ?,
            interior = ?, dimension = ?, contents_json = ? WHERE id = ?
    ]], data.name, data.depotType, data.ownerKey, data.x, data.y, data.z,
        data.interior, data.dimension, packDepotContents(data.contents), data.id)
    return true
end

function dbCreateDepot(name, depotType, ownerKey, x, y, z, interior, dimension)
    return {
        name = name, depotType = depotType, ownerKey = ownerKey, x = x, y = y, z = z,
        interior = interior, dimension = dimension, contents = {},
    }
end

function dbLoadDepots()
    if not db then return end
    local rows = dbPoll(dbQuery(db, "SELECT * FROM stage_inventory_depots"), -1) or {}
    for _, row in ipairs(rows) do
        local obj = createObject(1271, row.x, row.y, row.z - 0.9, 0, 0, 0)
        if obj then
            local data = {
                id = tonumber(row.id), name = row.name, depotType = row.depot_type, ownerKey = row.owner_key,
                x = tonumber(row.x), y = tonumber(row.y), z = tonumber(row.z),
                interior = tonumber(row.interior) or 0, dimension = tonumber(row.dimension) or 0,
                contents = unpackDepotContents(row.contents_json),
            }
            depots[obj] = data
            setElementInterior(obj, data.interior)
            setElementDimension(obj, data.dimension)
            setElementData(obj, "inv:depot", data.name, true)
            setElementData(obj, "inv:depotType", data.depotType, true)
            setElementData(obj, "inv:depotOwner", data.ownerKey, true)
            setElementData(obj, "inv:depotContents", data.contents, true)
        end
    end
end

function dbRegisterDepot(obj, data)
    depots[obj] = data
    if db then
        local qh = dbQuery(db, [[
            INSERT INTO stage_inventory_depots (name, depot_type, owner_key, x, y, z, interior, dimension, contents_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], data.name, data.depotType, data.ownerKey, data.x, data.y, data.z,
            data.interior, data.dimension, packDepotContents(data.contents))
        local _, _, lastInsertId = dbPoll(qh, -1)
        data.id = lastInsertId
    end
    return true
end

function dbGetDepot(obj)
    return depots[obj]
end

function dbGetAllDepots()
    local list = {}
    for obj, data in pairs(depots) do
        if isElement(obj) then
            list[#list + 1] = {
                object = obj, id = data.id, name = data.name, depotType = data.depotType,
                ownerKey = data.ownerKey, x = data.x, y = data.y, z = data.z,
                interior = data.interior, dimension = data.dimension,
            }
        end
    end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

function dbDeleteDepot(obj)
    local data = depots[obj]
    if not data then return false end
    if db and data.id then dbExec(db, "DELETE FROM stage_inventory_depots WHERE id = ?", data.id) end
    depots[obj] = nil
    if isElement(obj) then destroyElement(obj) end
    return true
end

local function getPlayerKey(p)
    if not isElement(p) then return nil end
    local acc = getPlayerAccount(p)
    if acc and not isGuestAccount(acc) then
        return "acc:" .. getAccountName(acc)
    end
    return "serial:" .. getPlayerSerial(p)
end

local function defaultInventory()
    return {
        [1] = { item = "colt", count = 1 },
        [2] = { item = "pistol_ammo", count = 172 },
        [3] = { item = "bandage", count = 5 },
        [4] = { item = "water", count = 2 },
    }
end

local function defaultHotbar()
    return { [1] = { item = "colt", count = 1 } }
end

local function packSlots(slots)
    local packed = {}
    for slot, entry in pairs(slots or {}) do
        if entry and entry.item and entry.count then
            local row = { slot = tonumber(slot), item = entry.item, count = tonumber(entry.count) or 1 }
            if entry.ammo ~= nil then row.ammo = tonumber(entry.ammo) or 0 end
            packed[#packed + 1] = row
        end
    end
    return packed
end

local function unpackSlots(json)
    local slots = {}
    if not json or json == "" then return slots end
    local ok, decoded = pcall(fromJSON, json)
    if not ok or type(decoded) ~= "table" then return slots end
    for _, row in pairs(decoded) do
        if type(row) == "table" and row.slot and row.item and row.count then
            local slot = tonumber(row.slot)
            if slot then
                slots[slot] = { item = tostring(row.item), count = tonumber(row.count) or 1 }
                if row.ammo ~= nil then slots[slot].ammo = tonumber(row.ammo) or 0 end
            end
        end
    end
    return slots
end

local function savePlayerInventory(p)
    if not db or not isElement(p) then return false end
    local key = playerKeys[p] or getPlayerKey(p)
    if not key then return false end
    playerKeys[p] = key
    local invJson = toJSON(packSlots(playerInventories[p] or {}), true)
    local hotbarJson = toJSON(packSlots(playerHotbars[p] or {}), true)
    dbExec(db, [[
        INSERT INTO stage_inventory_players (player_key, inventory_json, hotbar_json)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE inventory_json = VALUES(inventory_json), hotbar_json = VALUES(hotbar_json)
    ]], key, invJson, hotbarJson)
    return true
end

local function loadPlayerInventory(p)
    if not db or not isElement(p) then return false end
    local key = getPlayerKey(p)
    if not key then return false end
    playerKeys[p] = key
    local qh = dbQuery(db, "SELECT inventory_json, hotbar_json FROM stage_inventory_players WHERE player_key = ? LIMIT 1", key)
    local rows = dbPoll(qh, -1)
    if rows and rows[1] then
        playerInventories[p] = unpackSlots(rows[1].inventory_json)
        playerHotbars[p] = unpackSlots(rows[1].hotbar_json)
        return true
    end
    playerInventories[p] = defaultInventory()
    playerHotbars[p] = defaultHotbar()
    savePlayerInventory(p)
    return true
end

local function saveAllInventories()
    for p in pairs(playerInventories) do
        savePlayerInventory(p)
    end
end

function dbGetInventory(p) return playerInventories[p] or {} end
function dbGetHotbar(p) return playerHotbars[p] or {} end

function dbSetInventory(p, inv)
    playerInventories[p] = inv or {}
    savePlayerInventory(p)
end

function dbSetHotbar(p, hb)
    playerHotbars[p] = hb or {}
    savePlayerInventory(p)
end

function dbInitPlayer(p)
    if playerInventories[p] then return end
    if not loadPlayerInventory(p) then
        playerKeys[p] = getPlayerKey(p)
        playerInventories[p] = defaultInventory()
        playerHotbars[p] = defaultHotbar()
    end
end

function dbClearPlayer(p)
    savePlayerInventory(p)
    playerInventories[p] = nil
    playerHotbars[p] = nil
    playerKeys[p] = nil
end

addEventHandler("onResourceStart", resourceRoot, function()
    connectInventoryDB()
    dbLoadDepots()
end)

addEventHandler("onResourceStop", resourceRoot, function()
    saveAllInventories()
    for obj in pairs(depots) do dbSaveDepot(obj) end
    if db then
        destroyElement(db)
        db = nil
    end
end)

addEventHandler("onPlayerQuit", root, function()
    local p = source
    setTimer(function() dbClearPlayer(p) end, 1000, 1)
end)

addEventHandler("onPlayerLogin", root, function()
    local p = source
    dbClearPlayer(p)
    dbInitPlayer(p)
    if syncPlayer then syncPlayer(p) end
end)

addEventHandler("onPlayerLogout", root, function()
    local p = source
    dbClearPlayer(p)
    dbInitPlayer(p)
    if syncPlayer then syncPlayer(p) end
end)
