-- Stage Phone database hook.
-- UI and gameplay work without MySQL. When Config.mysql.enabled is true,
-- this file tries dbConnect and falls back to memory on any failure.

DB = {
    conn = nil,
    ready = false,
}

local function dbg(msg)
    outputDebugString("[Stage Phone] " .. tostring(msg))
end

local function mysqlConf()
    if type(Config) ~= "table" or type(Config.mysql) ~= "table" then
        return nil
    end
    return Config.mysql
end

function DB.isReady()
    return DB.ready and DB.conn and isElement(DB.conn)
end

function DB.connect()
    DB.ready = false
    DB.conn = nil

    local mysql = mysqlConf()
    if not mysql or mysql.enabled ~= true then
        dbg("MySQL kapali, bellek deposu kullaniliyor.")
        return false
    end

    if type(dbConnect) ~= "function" then
        dbg("dbConnect yok, bellek deposu kullaniliyor.")
        return false
    end

    local host = tostring(mysql.host or "127.0.0.1")
    local port = tonumber(mysql.port) or 3306
    local user = tostring(mysql.user or "root")
    local pass = tostring(mysql.pass or "")
    local name = tostring(mysql.db or "stage_phone")

    local conn = dbConnect(
        "mysql",
        "dbname=" .. name .. ";host=" .. host .. ";port=" .. tostring(port) .. ";charset=utf8",
        user,
        pass
    )
    if not conn then
        dbg("MySQL baglanamadi, bellek deposu kullaniliyor.")
        return false
    end

    DB.conn = conn
    DB.ready = true
    DB.initSchema()
    dbg("MySQL baglantisi hazir.")
    return true
end

function DB.initSchema()
    if not DB.isReady() then
        return
    end
    dbExec(DB.conn, [[CREATE TABLE IF NOT EXISTS stage_gallery (
        id INT AUTO_INCREMENT PRIMARY KEY,
        serial VARCHAR(64) NOT NULL,
        image_url VARCHAR(255) NOT NULL,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(DB.conn, [[CREATE TABLE IF NOT EXISTS stage_calls (
        id INT AUTO_INCREMENT PRIMARY KEY,
        serial VARCHAR(64) NOT NULL,
        number VARCHAR(32) NOT NULL,
        call_type VARCHAR(16) NOT NULL,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(DB.conn, [[CREATE TABLE IF NOT EXISTS stage_contacts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        serial VARCHAR(64) NOT NULL,
        name VARCHAR(64) NOT NULL,
        number VARCHAR(32) NOT NULL
    )]])
    dbExec(DB.conn, [[CREATE TABLE IF NOT EXISTS stage_notes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        serial VARCHAR(64) NOT NULL,
        title VARCHAR(80) NOT NULL,
        body TEXT NOT NULL,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(DB.conn, [[CREATE TABLE IF NOT EXISTS stage_posts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        kind VARCHAR(16) NOT NULL,
        username VARCHAR(64) NOT NULL,
        body VARCHAR(500) NOT NULL,
        image_url VARCHAR(255) DEFAULT NULL,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
end

function DB.query(sql, ...)
    if not DB.isReady() or type(sql) ~= "string" then
        return nil
    end
    local qh = dbQuery(DB.conn, sql, ...)
    if not qh then
        dbg("Sorgu baslatilamadi.")
        return nil
    end
    local result = dbPoll(qh, 80)
    if result == false then
        dbFree(qh)
        dbg("Sorgu sonucu nil/hatali.")
        return nil
    end
    if result == nil then
        dbFree(qh)
        return {}
    end
    return result
end

function DB.exec(sql, ...)
    if not DB.isReady() or type(sql) ~= "string" then
        return false
    end
    return dbExec(DB.conn, sql, ...) and true or false
end

addEventHandler("onResourceStart", resourceRoot, function()
    DB.connect()
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if DB.conn and isElement(DB.conn) then
        destroyElement(DB.conn)
    end
    DB.conn = nil
    DB.ready = false
end)
