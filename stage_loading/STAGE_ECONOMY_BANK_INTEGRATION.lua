-- stage_economy/server.lua
-- Stage Core ortak DB uzerinde serial bazli kalici nakit + banka.
-- Banka bakiyesi bankmoney element datasinda senkron tutulur (Stage HUD bunu okur).
local cashCache, bankCache = {}, {}

local function dbQuery(sql, ...)
    local result = exports.stage_core:CoreDBQuery(sql, ...)
    return type(result) == "table" and result or {}
end

local function dbExec(sql, ...)
    return exports.stage_core:CoreDBExec(sql, ...)
end

local function playerKey(player)
    return isElement(player) and getPlayerSerial(player) or nil
end

local function validPlayer(player)
    return isElement(player) and getElementType(player) == "player"
end

local function now()
    return getRealTime().timestamp
end

local function ensureAccount(player)
    if not validPlayer(player) then return nil end
    local key = playerKey(player)
    if not key then return nil end
    local rows = dbQuery("SELECT player_serial FROM economy_accounts WHERE player_serial = ? LIMIT 1", key)
    if not rows[1] then
        dbExec("INSERT INTO economy_accounts (player_serial, player_name, cash, bank, updated_at) VALUES (?, ?, ?, ?, ?)",
            key, getPlayerName(player), math.max(0, getPlayerMoney(player) or 0), 0, now())
    end
    return key
end

local function loadCash(player)
    if not validPlayer(player) then return 0 end
    local key = ensureAccount(player)
    if not key then return 0 end
    if cashCache[key] ~= nil then
        -- Native MTA para fonksiyonlarini kullanan eski resource'larla uyum.
        local nativeCash = math.max(0, getPlayerMoney(player) or 0)
        if nativeCash ~= cashCache[key] then
            cashCache[key] = nativeCash
            dbExec("UPDATE economy_accounts SET cash = ?, player_name = ?, updated_at = ? WHERE player_serial = ?",
                nativeCash, getPlayerName(player), now(), key)
        end
        return cashCache[key]
    end
    local rows = dbQuery("SELECT cash FROM economy_accounts WHERE player_serial = ? LIMIT 1", key)
    local cash = math.max(0, math.floor(tonumber(rows[1] and rows[1].cash) or getPlayerMoney(player) or 0))
    cashCache[key] = cash
    setPlayerMoney(player, cash)
    dbExec("UPDATE economy_accounts SET cash = ?, player_name = ?, updated_at = ? WHERE player_serial = ?",
        cash, getPlayerName(player), now(), key)
    return cash
end

local function saveCash(player, amount)
    local key = ensureAccount(player)
    if not key then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    cashCache[key] = amount
    setPlayerMoney(player, amount)
    return dbExec("UPDATE economy_accounts SET cash = ?, player_name = ?, updated_at = ? WHERE player_serial = ?",
        amount, getPlayerName(player), now(), key)
end

local function loadBank(player)
    if not validPlayer(player) then return 0 end
    local key = ensureAccount(player)
    if not key then return 0 end
    if bankCache[key] ~= nil then
        setElementData(player, "bankmoney", bankCache[key], true)
        return bankCache[key]
    end
    local rows = dbQuery("SELECT bank FROM economy_accounts WHERE player_serial = ? LIMIT 1", key)
    local bank = math.max(0, math.floor(tonumber(rows[1] and rows[1].bank) or 0))
    bankCache[key] = bank
    setElementData(player, "bankmoney", bank, true)
    return bank
end

local function saveBank(player, amount)
    local key = ensureAccount(player)
    if not key then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    bankCache[key] = amount
    setElementData(player, "bankmoney", amount, true)
    return dbExec("UPDATE economy_accounts SET bank = ?, player_name = ?, updated_at = ? WHERE player_serial = ?",
        amount, getPlayerName(player), now(), key)
end

function GetCash(player) return loadCash(player) end
function SetCash(player, amount)
    if not validPlayer(player) then return false end
    return saveCash(player, amount)
end
function AddCash(player, amount)
    if not validPlayer(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return saveCash(player, loadCash(player) + amount)
end
function RemoveCash(player, amount)
    if not validPlayer(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local current = loadCash(player)
    if current < amount then return false end
    return saveCash(player, current - amount)
end

function GetBank(player) return loadBank(player) end
function SetBank(player, amount)
    if not validPlayer(player) then return false end
    return saveBank(player, amount)
end
function AddBank(player, amount)
    if not validPlayer(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return saveBank(player, loadBank(player) + amount)
end
function RemoveBank(player, amount)
    if not validPlayer(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local current = loadBank(player)
    if current < amount then return false end
    return saveBank(player, current - amount)
end

addEventHandler("onResourceStart", resourceRoot, function()
    local isMysql = false
    pcall(function() isMysql = exports.stage_core:CoreDBIsMySQL() == true end)
    if isMysql then
        dbExec([[CREATE TABLE IF NOT EXISTS economy_accounts (
            player_serial VARCHAR(64) NOT NULL PRIMARY KEY,
            player_name VARCHAR(128) NOT NULL,
            cash BIGINT NOT NULL DEFAULT 0,
            bank BIGINT NOT NULL DEFAULT 0,
            updated_at BIGINT NOT NULL
        )]])
        -- Mevcut MySQL tablosuna banka kolonu ekle; zaten varsa hata zararsizdir.
        pcall(function() dbExec("ALTER TABLE economy_accounts ADD COLUMN bank BIGINT NOT NULL DEFAULT 0") end)
    else
        dbExec([[CREATE TABLE IF NOT EXISTS economy_accounts (
            player_serial TEXT PRIMARY KEY,
            player_name TEXT NOT NULL,
            cash INTEGER NOT NULL DEFAULT 0,
            bank INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL
        )]])
        -- SQLite eski tablo migration'i.
        pcall(function() dbExec("ALTER TABLE economy_accounts ADD COLUMN bank INTEGER NOT NULL DEFAULT 0") end)
    end
    for _, player in ipairs(getElementsByType("player")) do
        loadCash(player)
        loadBank(player)
    end
    outputDebugString("[stage_economy] Kalici nakit + banka ekonomisi hazir.", 3)
end)

addEventHandler("onPlayerLogin", root, function()
    loadCash(source)
    loadBank(source)
end)

addEventHandler("onPlayerQuit", root, function()
    local key = playerKey(source)
    if key then cashCache[key], bankCache[key] = nil, nil end
end)
