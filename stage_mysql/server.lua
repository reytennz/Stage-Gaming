--[[
    stage_mysql - Merkezi Veritabanı Yöneticisi
    Tüm resource'lar için tek bağlantı, otomatik tablo oluşturma ve para koruma sistemi.
]]

local db = nil
local isUsingMySQL = false
local ready = false

local function initDatabase()
    local c = MySQLConfig
    local connStr = string.format("dbname=%s;host=%s;port=%d;charset=%s", c.database, c.host, c.port or 3306, c.charset or "utf8mb4")
    
    outputServerLog("[stage_mysql] MySQL sunucusuna baglaniliyor...")
    db = dbConnect("mysql", connStr, c.user, c.password, "share=1;autoreconnect=1")
    
    if db then
        isUsingMySQL = true
        ready = true
        outputServerLog("[stage_mysql] >> MySQL BAGLANTISI BASARILI! (Veritabani: " .. c.database .. ")")
    else
        outputServerLog("[stage_mysql] UYARI: MySQL baglantisi kurulamadi!")
        if c.autoFallbackSQLite then
            outputServerLog("[stage_mysql] >> Veri kaybi olmamasi icin otomatik SQLite (stage_database.db) devreye sokuluyor.")
            db = dbConnect("sqlite", "stage_database.db")
            if db then
                isUsingMySQL = false
                ready = true
                outputServerLog("[stage_mysql] >> SQLite baglantisi aktif, veriler guvende!")
            else
                outputServerLog("[stage_mysql] HATA: SQLite bile olusturulamadi!", 1)
            end
        end
    end

    if db then
        createTables()
    end
end

function createTables()
    if not db then return end
    
    -- Hesaplar tablosu
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(64) NOT NULL UNIQUE,
            password VARCHAR(128) NOT NULL,
            serial VARCHAR(64) DEFAULT '',
            ip VARCHAR(32) DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Karakterler tablosu
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS characters (
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            account_id INT NOT NULL,
            slot TINYINT NOT NULL DEFAULT 1,
            name VARCHAR(32) NOT NULL,
            surname VARCHAR(32) NOT NULL,
            age INT NOT NULL DEFAULT 21,
            skin INT NOT NULL DEFAULT 0,
            money BIGINT NOT NULL DEFAULT 50000,
            bank_money BIGINT NOT NULL DEFAULT 100000,
            pos_x FLOAT DEFAULT 1969.88,
            pos_y FLOAT DEFAULT -1760.36,
            pos_z FLOAT DEFAULT 13.54,
            pos_rot FLOAT DEFAULT 90.0,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            drift_seconds INT DEFAULT 0,
            play_seconds INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Para koruma tablosu (Serial ve Hesap bazlı acil durum kasası - restartlarda para ASLA silinmez!)
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS player_money_backup (
            identifier VARCHAR(64) PRIMARY KEY,
            cash BIGINT NOT NULL DEFAULT 0,
            bank BIGINT NOT NULL DEFAULT 0,
            last_char_name VARCHAR(64) DEFAULT '',
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

-- ================= EXPORT FONKSİYONLARI =================

function getConnection()
    return db
end

function isReady()
    return ready and db ~= nil
end

function isMySQL()
    return isUsingMySQL
end

function query(str, ...)
    if not db then return nil end
    return dbQuery(db, str, ...)
end

function querySync(str, ...)
    if not db then return {} end
    local qh = dbQuery(db, str, ...)
    if not qh then return {} end
    local res = dbPoll(qh, -1)
    return res or {}
end

function exec(str, ...)
    if not db then return false end
    return dbExec(db, str, ...)
end

function poll(qh, timeout)
    if not qh then return nil end
    return dbPoll(qh, timeout or -1)
end

-- ================= OYUNCU PARA YEDEKLEME VE KURTARMA SİSTEMİ =================
-- Karakter seçilmese bile, veya restart atılsa bile serial/hesap üzerinden para güvencede tutulur!

function savePlayerMoney(player, cash, bank)
    if not isElement(player) or not db then return false end
    cash = math.max(0, math.floor(tonumber(cash) or getPlayerMoney(player) or 0))
    bank = math.max(0, math.floor(tonumber(bank) or getElementData(player, "bankmoney") or 0))
    
    local charId = getElementData(player, "stage:charId")
    if charId then
        dbExec(db, "UPDATE characters SET money=?, bank_money=? WHERE id=?", cash, bank, charId)
    end
    
    local serial = getPlayerSerial(player)
    local account = getPlayerAccount(player)
    local accName = (account and not isGuestAccount(account)) and getAccountName(account) or serial
    local charName = getPlayerName(player)
    
    dbExec(db, [[
        INSERT INTO player_money_backup (identifier, cash, bank, last_char_name)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE cash=?, bank=?, last_char_name=?
    ]], accName, cash, bank, charName, cash, bank, charName)
    
    -- Serial yedeği de al
    if serial and serial ~= accName then
        dbExec(db, [[
            INSERT INTO player_money_backup (identifier, cash, bank, last_char_name)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE cash=?, bank=?, last_char_name=?
        ]], serial, cash, bank, charName, cash, bank, charName)
    end
    
    return true
end

function loadPlayerMoney(player)
    if not isElement(player) or not db then return 0, 0 end
    
    local charId = getElementData(player, "stage:charId")
    if charId then
        local q = querySync("SELECT money, bank_money FROM characters WHERE id=? LIMIT 1", charId)
        if q and q[1] then
            return tonumber(q[1].money) or 0, tonumber(q[1].bank_money) or 0
        end
    end
    
    local serial = getPlayerSerial(player)
    local account = getPlayerAccount(player)
    local accName = (account and not isGuestAccount(account)) and getAccountName(account) or serial
    
    local q = querySync("SELECT cash, bank FROM player_money_backup WHERE identifier=? OR identifier=? LIMIT 1", accName, serial)
    if q and q[1] then
        return tonumber(q[1].cash) or 0, tonumber(q[1].bank) or 0
    end
    
    return 0, 0
end

-- Otomatik periyodik kaydetme & stop anında kaydetme
setTimer(function()
    for _, p in ipairs(getElementsByType("player")) do
        savePlayerMoney(p)
    end
end, 20000, 0)

addEventHandler("onPlayerQuit", root, function()
    savePlayerMoney(source)
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for _, p in ipairs(getElementsByType("player")) do
        savePlayerMoney(p)
    end
end)

addEventHandler("onResourceStart", resourceRoot, initDatabase)
