--[[
  Stage Account + Characters + MySQL + Money + Last Position
]]

local db = nil

local function connectDB()
    local c = Config.mysql
    local connStr = string.format(
        "dbname=%s;host=%s;port=%d;charset=utf8",
        c.database, c.host, c.port or 3306
    )
    db = dbConnect("mysql", connStr, c.user, c.password, "share=0")
    if not db then
        outputServerLog("[Stage] MySQL baglantisi BASARISIZ! config.lua kontrol et.")
        outputDebugString("[Stage] MySQL baglantisi basarisiz!", 1)
        return false
    end
    outputServerLog("[Stage] MySQL baglandi.")
    return true
end

local function initTables()
    if not db then return end
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS accounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(32) NOT NULL UNIQUE,
            password VARCHAR(64) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            slot TINYINT NOT NULL,
            name VARCHAR(32) NOT NULL,
            surname VARCHAR(32) NOT NULL,
            age INT NOT NULL DEFAULT 18,
            height INT NOT NULL DEFAULT 175,
            skin INT NOT NULL DEFAULT 0,
            country VARCHAR(16) NOT NULL DEFAULT 'TR',
            tag VARCHAR(32) NOT NULL DEFAULT 'Yeni Oyuncu',
            money INT NOT NULL DEFAULT 300000,
            kills INT NOT NULL DEFAULT 0,
            deaths INT NOT NULL DEFAULT 0,
            drift_seconds INT NOT NULL DEFAULT 0,
            play_seconds INT NOT NULL DEFAULT 0,
            pos_x FLOAT NOT NULL DEFAULT 1969.88184,
            pos_y FLOAT NOT NULL DEFAULT -1760.36328,
            pos_z FLOAT NOT NULL DEFAULT 13.54688,
            pos_rot FLOAT NOT NULL DEFAULT 90,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_acc_slot (account_id, slot),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- karakter etiketi: eski veritabanlari icin otomatik eklenir
    local tq = dbPoll(dbQuery(db, "SHOW COLUMNS FROM characters LIKE 'tag'"), -1)
    if not tq or #tq == 0 then
        dbExec(db, "ALTER TABLE characters ADD COLUMN tag VARCHAR(32) NOT NULL DEFAULT 'Yeni Oyuncu'")
        outputServerLog("[Stage] character tag kolonu eklendi.")
    end
    -- money kolonu yoksa ekle (eski kurulumlar icin) - varsa sessizce gec
    local q = dbQuery(db, "SHOW COLUMNS FROM characters LIKE 'money'")
    local r = dbPoll(q, -1)
    if not r or #r == 0 then
        dbExec(db, "ALTER TABLE characters ADD COLUMN money INT NOT NULL DEFAULT 300000")
        outputServerLog("[Stage] money kolonu eklendi.")
    end
    -- bank_money kolonu: banka bakiyesi characters tablosunda tutulur
    local bq = dbPoll(dbQuery(db, "SHOW COLUMNS FROM characters LIKE 'bank_money'"), -1)
    if not bq or #bq == 0 then
        dbExec(db, "ALTER TABLE characters ADD COLUMN bank_money BIGINT NOT NULL DEFAULT 0")
        outputServerLog("[Stage] bank_money kolonu eklendi.")
    end
    -- Eski veritabanlarini istatistik kolonlariyla uyumlu hale getir.
    for _, column in ipairs({"kills", "deaths", "drift_seconds", "play_seconds"}) do
        local check = dbPoll(dbQuery(db, "SHOW COLUMNS FROM characters LIKE ?", column), -1)
        if not check or #check == 0 then
            dbExec(db, "ALTER TABLE characters ADD COLUMN " .. column .. " INT NOT NULL DEFAULT 0")
        end
    end
end

-- Banka bakiyesi erişimi için export'lar (stage_economy tarafından kullanılır)
function stageGetBank(player)
    if not isElement(player) then return 0 end
    local charId = getElementData(player, "stage:charId")
    if not charId or not db then
        return tonumber(getElementData(player, "bankmoney")) or 0
    end
    local r = dbPoll(dbQuery(db, "SELECT bank_money FROM characters WHERE id=? LIMIT 1", charId), -1)
    return r and r[1] and tonumber(r[1].bank_money) or 0
end

function stageSetBank(player, amount)
    if not isElement(player) then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    setElementData(player, "bankmoney", amount, true)
    local charId = getElementData(player, "stage:charId")
    if charId and db then
        return dbExec(db, "UPDATE characters SET bank_money=? WHERE id=?", amount, charId)
    end
    return false
end

function stageAddBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return stageSetBank(player, stageGetBank(player) + amount)
end

function stageRemoveBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local current = stageGetBank(player)
    if current < amount then return false end
    return stageSetBank(player, current - amount)
end


-- MTA hesap senkron (admin panel /login icin)
local function ensureMTAAccountAndLogin(player, username, plainPass)
    if not isElement(player) then return false end
    username = tostring(username or "")
    plainPass = tostring(plainPass or "")
    if username == "" or plainPass == "" then return false end
    local acc = getAccount(username)
    if not acc then
        acc = addAccount(username, plainPass)
        if not acc then
            outputServerLog("[Stage] MTA addAccount basarisiz: " .. username)
            return false
        end
        outputServerLog("[Stage] MTA hesap olusturuldu: " .. username)
    end
    if isGuestAccount(getPlayerAccount(player)) then
        local ok = logIn(player, acc, plainPass)
        if not ok then
            -- sifre MTA hesabinda farkliysa guncelle (sadece ayni isim)
            -- MTA sifre degistirilemez kolayca; yeniden dene
            outputServerLog("[Stage] logIn basarisiz (sifre uyusmuyor olabilir): " .. username)
            return false
        end
    end
    return true
end

local function hashPass(pass)
    return md5(tostring(pass))
end

local function getAccountId(username)
    local q = dbQuery(db, "SELECT id FROM accounts WHERE username=? LIMIT 1", username)
    local r = dbPoll(q, -1)
    if r and r[1] then return r[1].id end
    return nil
end

local function getPlayerCharsPacked(username)
    local packed = {}
    for i = 1, 3 do
        packed[i] = { slot = i, empty = true }
    end
    local accId = getAccountId(username)
    if not accId then return packed end

    local q = dbQuery(db, "SELECT * FROM characters WHERE account_id=?", accId)
    local rows = dbPoll(q, -1)
    if not rows then return packed end

    for _, row in ipairs(rows) do
        local s = tonumber(row.slot) or 1
        if s >= 1 and s <= 3 then
            packed[s] = {
                slot = s,
                id = row.id,
                name = row.name,
                surname = row.surname,
                age = row.age,
                height = row.height,
                skin = row.skin,
                country = row.country,
                tag = row.tag or 'Yeni Oyuncu',
                money = row.money or 0,
                pos_x = row.pos_x,
                pos_y = row.pos_y,
                pos_z = row.pos_z,
                pos_rot = row.pos_rot,
                empty = false,
            }
        end
    end
    return packed
end

local function sendChars(player, username)
    triggerClientEvent(player, "stageShowChars", player, getPlayerCharsPacked(username))
end

-- ========== LOGIN / REGISTER ==========
addEvent("stageLoginServer", true)
addEventHandler("stageLoginServer", root, function(username, password, isRegister)
    local player = client
    if not isElement(player) then return end
    if not db then
        triggerClientEvent(player, "stageLoginResult", player, false, "Veritabani bagli degil!")
        return
    end

    username = string.lower(tostring(username or "")):gsub("%s+", "")
    password = tostring(password or "")
    local reg = (isRegister == true or isRegister == "true" or isRegister == 1 or isRegister == "1")

    if #username < 3 or #password < 3 then
        triggerClientEvent(player, "stageLoginResult", player, false, "Min 3 karakter gerekli!")
        return
    end

    local hashed = hashPass(password)

    if reg then
        if getAccountId(username) then
            triggerClientEvent(player, "stageLoginResult", player, false, "Bu kullanici adi alinmis!")
            return
        end
        local ok = dbExec(db, "INSERT INTO accounts (username, password) VALUES (?, ?)", username, hashed)
        if not ok then
            triggerClientEvent(player, "stageLoginResult", player, false, "Kayit basarisiz!")
            return
        end
        setElementData(player, "stage:logged", true)
        setElementData(player, "stage:user", username)
        ensureMTAAccountAndLogin(player, username, password)
        triggerClientEvent(player, "stageLoginResult", player, true, "Kayit basarili!")
        setTimer(sendChars, 500, 1, player, username)
        return
    end

    local q = dbQuery(db, "SELECT id, password FROM accounts WHERE username=? LIMIT 1", username)
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        triggerClientEvent(player, "stageLoginResult", player, false, "Hesap yok. Once kayit ol.")
        return
    end
    if r[1].password ~= hashed then
        triggerClientEvent(player, "stageLoginResult", player, false, "Sifre yanlis!")
        return
    end

    setElementData(player, "stage:logged", true)
    setElementData(player, "stage:user", username)
    ensureMTAAccountAndLogin(player, username, password)
    triggerClientEvent(player, "stageLoginResult", player, true, "Giris basarili!")
    setTimer(sendChars, 500, 1, player, username)
end)

-- ========== CREATE CHARACTER ==========
addEvent("stageCreateChar", true)
addEventHandler("stageCreateChar", root, function(slot, name, surname, age, height, skin, country)
    local player = client
    if not isElement(player) or not db then return end
    if not getElementData(player, "stage:logged") then return end
    local username = getElementData(player, "stage:user")
    if not username then return end

    slot = tonumber(slot) or 1
    if slot < 1 or slot > 3 then
        triggerClientEvent(player, "stageCharResult", player, false, "Gecersiz slot!")
        return
    end

    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    surname = tostring(surname or ""):gsub("^%s+", ""):gsub("%s+$", "")
    age = tonumber(age) or 18
    height = tonumber(height) or 175
    skin = tonumber(skin) or 0
    country = tostring(country or "TR")
    local startMoney = Config.startMoney or 5000

    if #name < 2 or #surname < 2 then
        triggerClientEvent(player, "stageCharResult", player, false, "Isim/soyisim en az 2 karakter!")
        return
    end
    if age < 16 or age > 80 then
        triggerClientEvent(player, "stageCharResult", player, false, "Yas 16-80 arasi!")
        return
    end
    if height < 150 or height > 210 then
        triggerClientEvent(player, "stageCharResult", player, false, "Boy 150-210 arasi!")
        return
    end

    local accId = getAccountId(username)
    if not accId then
        triggerClientEvent(player, "stageCharResult", player, false, "Hesap bulunamadi!")
        return
    end

    local q = dbQuery(db, "SELECT id FROM characters WHERE account_id=? AND slot=? LIMIT 1", accId, slot)
    local r = dbPoll(q, -1)
    if r and r[1] then
        triggerClientEvent(player, "stageCharResult", player, false, "Bu slot dolu!")
        return
    end

    local igs = Config.igsSpawn
    local ok = dbExec(db,
        [[INSERT INTO characters
        (account_id, slot, name, surname, age, height, skin, country, money, pos_x, pos_y, pos_z, pos_rot)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        accId, slot, name, surname, age, height, skin, country, startMoney,
        igs[1], igs[2], igs[3], igs[4]
    )

    if ok then
        triggerClientEvent(player, "stageCharResult", player, true, "Karakter olusturuldu!", getPlayerCharsPacked(username))
    else
        triggerClientEvent(player, "stageCharResult", player, false, "Kaydedilemedi!")
    end
end)

-- ========== SELECT CHARACTER ==========
addEvent("stageSelectChar", true)
addEventHandler("stageSelectChar", root, function(slot)
    local player = client
    if not isElement(player) or not db then return end
    if not getElementData(player, "stage:logged") then return end
    local username = getElementData(player, "stage:user")
    if not username then return end

    slot = tonumber(slot) or 1
    local accId = getAccountId(username)
    if not accId then return end

    local q = dbQuery(db, "SELECT * FROM characters WHERE account_id=? AND slot=? LIMIT 1", accId, slot)
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        triggerClientEvent(player, "stageCharResult", player, false, "Bu slotta karakter yok!")
        return
    end

    local char = r[1]
    setElementData(player, "stage:charId", char.id)
    setElementData(player, "stage:char", char.name .. " " .. char.surname, true)
    setElementData(player, "stage:charName", char.name, true)
    setElementData(player, "stage:charSurname", char.surname, true)
    setElementData(player, "stage:charAge", tonumber(char.age) or 18, true)
    setElementData(player, "stage:charHeight", tonumber(char.height) or 175, true)
    setElementData(player, "stage:charSkin", tonumber(char.skin) or 0, true)
    setElementData(player, "stage:charCountry", char.country or "TR", true)
    setElementData(player, "stage:tag", char.tag or "Yeni Oyuncu", true)
    setElementData(player, "stage:charSlot", slot)
    setElementData(player, "playerid", char.id, true)

    local x, y, z, rot = char.pos_x, char.pos_y, char.pos_z, char.pos_rot
    local money = tonumber(char.money) or 0

    local bank = tonumber(char.bank_money) or 0
    setElementFrozen(player, false)
    spawnPlayer(player, x, y, z, rot, char.skin)
    setElementModel(player, char.skin)
    setPlayerMoney(player, money)
    setElementData(player, "money", money, true)
    setElementData(player, "bankmoney", bank, true)
    setElementData(player, "stage:bankmoney", bank, true)
    -- Karakter ismini nametag yap
    local fullName = tostring(char.name) .. " " .. tostring(char.surname)
    setPlayerNametagText(player, fullName)
    setPlayerNametagShowing(player, false)
    fadeCamera(player, true)
    setCameraTarget(player, player)

    local charData = {
        id = char.id, slot = slot,
        name = char.name, surname = char.surname,
        tag = char.tag or 'Yeni Oyuncu',
        age = char.age, height = char.height,
        skin = char.skin, country = char.country,
        money = money,
    }
    triggerClientEvent(player, "stageSpawned", player, charData)
    outputServerLog("[Stage] SPAWN " .. username .. " -> " .. char.name .. " $" .. money)
end)

-- ========== SAVE POS + MONEY ==========
local function savePlayerData(player)
    if not isElement(player) or not db then return end
    local charId = getElementData(player, "stage:charId")
    if not charId then return end

    local money = getPlayerMoney(player)
    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)

    -- Oluyse pozisyonu bozma, sadece parayi kaydet
    if isPedDead(player) then
        dbExec(db, "UPDATE characters SET money=? WHERE id=?", money, charId)
        return
    end

    dbExec(db,
        "UPDATE characters SET money=?, pos_x=?, pos_y=?, pos_z=?, pos_rot=? WHERE id=?",
        money, x, y, z, rot, charId
    )
end

setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        if getElementData(player, "stage:charId") then
            savePlayerData(player)
        end
    end
end, (Config and Config.saveInterval) or 30000, 0)

addEventHandler("onPlayerQuit", root, function()
    savePlayerData(source)
    removeElementData(source, "stage:logged")
    removeElementData(source, "stage:user")
    removeElementData(source, "stage:char")
    removeElementData(source, "stage:charId")
    removeElementData(source, "stage:charSlot")
    removeElementData(source, "playerid")
end)

addEventHandler("onPlayerWasted", root, function(_, killer)
    savePlayerData(source)
    local victimId = getElementData(source, "stage:charId")
    if victimId and db then dbExec(db, "UPDATE characters SET deaths=deaths+1 WHERE id=?", victimId) end
    local killerId = killer and killer ~= source and isElement(killer) and getElementType(killer) == "player" and getElementData(killer, "stage:charId") or nil
    if killerId and db then dbExec(db, "UPDATE characters SET kills=kills+1 WHERE id=?", killerId) end

    if Config.respawnAtLoadingSpawn and victimId then
        local player = source
        local x, y, z, rot = unpack(Config.igsSpawn)
        dbExec(db, "UPDATE characters SET pos_x=?, pos_y=?, pos_z=?, pos_rot=? WHERE id=?", x, y, z, rot, victimId)
        setTimer(function()
            if not isElement(player) or not isPedDead(player) then return end
            spawnPlayer(player, x, y, z, rot, getElementModel(player))
            setElementInterior(player, 0)
            setElementDimension(player, 0)
            setCameraTarget(player, player)
            fadeCamera(player, true)
        end, tonumber(Config.respawnDelay) or 2500, 1)
    end
end)

-- Oyun ve drift suresi MySQL'de tutulur. Drift: surucu, el freni ve hareket halinde.
setTimer(function()
    if not db then return end
    for _, player in ipairs(getElementsByType("player")) do
        local charId = getElementData(player, "stage:charId")
        if charId then
            local drift = 0
            local vehicle = getPedOccupiedVehicle(player)
            if vehicle and getVehicleController(vehicle) == player and getPedControlState(player, "handbrake") then
                local vx, vy, vz = getElementVelocity(vehicle)
                if (vx * vx + vy * vy + vz * vz) > 0.003 then drift = 1 end
            end
            dbExec(db, "UPDATE characters SET play_seconds=play_seconds+1, drift_seconds=drift_seconds+? WHERE id=?", drift, charId)
        end
    end
end, 1000, 0)

-- Para degisince hemen kaydet (givePlayerMoney / takePlayerMoney vs)
addEventHandler("onPlayerMoneyChange", root, function(prev, current)
    local charId = getElementData(source, "stage:charId")
    if charId and db then
        dbExec(db, "UPDATE characters SET money=? WHERE id=?", current, charId)
    end
end)

addEventHandler("onResourceStart", resourceRoot, function()
    if connectDB() then
        initTables()
        outputServerLog("[Stage] MySQL tables ready (money + position).")
    end
end)


-- ========== KARAKTER DEGISTIR (F10) ==========
addEvent("stageRequestCharSelect", true)
addEventHandler("stageRequestCharSelect", root, function()
    local player = client
    if not isElement(player) then return end
    local username = getElementData(player, "stage:user")
    if not username then
        triggerClientEvent(player, "stageLoginResult", player, false, "Once giris yapmalisin!")
        return
    end
    -- pozisyon/para kaydet
    savePlayerData(player)
    -- karakter spawn verisini temizle (secime don)
    removeElementData(player, "stage:charId")
    removeElementData(player, "stage:char")
    removeElementData(player, "stage:charSlot")
    removeElementData(player, "playerid")
    -- oyuncuyu gecici olarak disari al
    fadeCamera(player, false, 0.5)
    setElementFrozen(player, true)
    setElementPosition(player, 0, 0, 5)
    setCameraMatrix(player, 1969, -1760, 40, 1969, -1760, 13)
    setTimer(function()
        if not isElement(player) then return end
        triggerClientEvent(player, "stageShowChars", player, getPlayerCharsPacked(username))
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFKarakter secim ekrani.", player, 255, 255, 255, true)
    end, 600, 1)
end)

-- ========== /login (admin panel icin MTA hesabi) ==========
-- Kullanim: /login sifre   veya  /login kullanici sifre
addCommandHandler("login", function(player, cmd, arg1, ...)
    if not isElement(player) then return end
    local rest = {...}
    local username, plainPass
    if arg1 and #rest > 0 then
        username = string.lower(tostring(arg1)):gsub("%s+", "")
        plainPass = table.concat(rest, " ")
    else
        username = getElementData(player, "stage:user")
        plainPass = tostring(arg1 or "")
    end
    if not username or username == "" or plainPass == "" then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFKullanim: /login [sifre]  veya  /login [kullanici] [sifre]", player, 255, 255, 255, true)
        return
    end
    if not db then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFVeritabani yok!", player, 255, 255, 255, true)
        return
    end
    local hashed = hashPass(plainPass)
    local q = dbQuery(db, "SELECT id, password FROM accounts WHERE username=? LIMIT 1", username)
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFHesap bulunamadi.", player, 255, 255, 255, true)
        return
    end
    if r[1].password ~= hashed then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFSifre yanlis!", player, 255, 255, 255, true)
        return
    end
    setElementData(player, "stage:logged", true)
    setElementData(player, "stage:user", username)
    local ok = ensureMTAAccountAndLogin(player, username, plainPass)
    if ok then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFMTA girisi OK. Admin panel kullanabilirsin.", player, 255, 255, 255, true)
        outputServerLog("[Stage] /login OK " .. username .. " -> " .. getPlayerName(player))
    else
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFStage hesabi dogrulandi ama MTA logIn basarisiz. Hesap sifresi eslesmiyor olabilir.", player, 255, 255, 255, true)
    end
end, false, false)


addEventHandler("onResourceStop", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        savePlayerData(player)
    end
    if db then destroyElement(db) end
end)

-- Export: baska scriptlerden para setlemek icin
local function stageAdminTrackMoney(player, signedAmount, reason)
    local r = getResourceFromName("stage_admin")
    if not r or getResourceState(r) ~= "running" then return end
    if tonumber(signedAmount) == 0 then return end
    pcall(function()
        exports.stage_admin:AdminTrackEconomy(player, signedAmount, reason or "stage_loading", "stage_loading")
    end)
end

function stageSetMoney(player, amount, reason)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then amount = 0 end
    local before = getPlayerMoney(player) or 0
    setPlayerMoney(player, amount)
    setElementData(player, "money", amount, true)
    local charId = getElementData(player, "stage:charId")
    if charId and db then
        dbExec(db, "UPDATE characters SET money=? WHERE id=?", amount, charId)
    end
    stageAdminTrackMoney(player, amount - before, reason or "Para ayarlandı")
    return true
end

function stageGiveMoney(player, amount, reason)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    givePlayerMoney(player, amount)
    stageAdminTrackMoney(player, amount, reason or "Para eklendi")
    setElementData(player, "money", getPlayerMoney(player), true)
    local charId = getElementData(player, "stage:charId")
    if charId and db then
        dbExec(db, "UPDATE characters SET money=? WHERE id=?", getPlayerMoney(player), charId)
    end
    return true
end

function stageGetMoney(player)
    if not isElement(player) then return 0 end
    return getPlayerMoney(player)
end

function stageGetDatabase()
    return db
end

function stageResetStats(player)
    if not isElement(player) or not db then return false end
    local charId = getElementData(player, "stage:charId")
    if not charId then return false end
    return dbExec(db, "UPDATE characters SET kills=0, deaths=0, drift_seconds=0, play_seconds=0 WHERE id=?", charId)
end

addEvent("stageStats:requestLeaderboard", true)
addEventHandler("stageStats:requestLeaderboard", root, function(mode)
    local player = client or source
    if not isElement(player) or not db then return end
    mode = tostring(mode or "kills")
    local orderBy = "kills DESC, drift_seconds DESC, play_seconds DESC"
    if mode == "drift" then
        orderBy = "drift_seconds DESC, kills DESC, play_seconds DESC"
    elseif mode == "time" then
        orderBy = "play_seconds DESC, kills DESC, drift_seconds DESC"
    end
    local q = dbQuery(db, [[
        SELECT name, kills, deaths, drift_seconds, play_seconds
        FROM characters
        ORDER BY ]] .. orderBy .. [[
        LIMIT 25
    ]])
    local rows = dbPoll(q, -1) or {}
    triggerClientEvent(player, "stageStats:receiveLeaderboard", resourceRoot, mode, rows)
end)

local function isStatsAdmin(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then return false end
    local name = getAccountName(account)
    for _, groupName in ipairs({"Admin", "Console", "SuperModerator"}) do
        local group = aclGetGroup(groupName)
        if group and isObjectInACLGroup("user." .. name, group) then return true end
    end
    return false
end

addCommandHandler("resetstats", function(player, _, targetName)
    if not isStatsAdmin(player) then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFBu komut sadece yetkililer icin.", player, 255, 255, 255, true)
        return
    end
    local target = player
    if targetName and targetName ~= "" then
        for _, p in ipairs(getElementsByType("player")) do
            if string.find(string.lower(getPlayerName(p)), string.lower(targetName), 1, true) then target = p break end
        end
    end
    if stageResetStats(target) then
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFIstatistikler sifirlandi: " .. getPlayerName(target), player, 255, 255, 255, true)
    else
        outputChatBox("#FF7A00[Stage Gaming] #FFFFFFOyuncunun aktif karakteri yok.", player, 255, 255, 255, true)
    end
end)

-- stage_core karakter etiketi API
function stageSetCharacterTag(player, tag)
    if not isElement(player) or not db then return false end
    local charId = getElementData(player, "stage:charId")
    if not charId then return false end

    tag = tostring(tag or ""):gsub("[%c\r\n]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if tag == "" then tag = "Yeni Oyuncu" end
    tag = tag:sub(1, 32)

    local ok = dbExec(db, "UPDATE characters SET tag=? WHERE id=?", tag, charId)
    if ok then
        setElementData(player, "stage:tag", tag, true)
    end
    return ok
end
