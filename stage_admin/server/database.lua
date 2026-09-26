--[[
    stage_admin - database
    SQLite kaldırıldı. stage_loading'in MySQL bağlantısı kullanılır.
    Bağlantı: exports.stage_loading:stageGetDatabase()
]]

local db = nil

local function getDB()
    if db and isElement(db) then return db end
    local r = getResourceFromName("stage_loading")
    if not r or getResourceState(r) ~= "running" then return nil end
    local ok, handle = pcall(function() return exports.stage_loading:stageGetDatabase() end)
    if ok and handle then db = handle end
    return db
end

local function execute(query, ...)
    local conn = getDB()
    if not conn then return false end
    local ok, result = pcall(dbExec, conn, query, ...)
    if not ok then
        outputDebugString("[stage_admin] DB exec hata: " .. tostring(result), 1)
        return false
    end
    return true
end

local function initTables()
    local conn = getDB()
    if not conn then
        outputDebugString("[stage_admin] MySQL bağlantısı yok, tablolar oluşturulamadı!", 1)
        return
    end

    execute([[
        CREATE TABLE IF NOT EXISTS admin_bans (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(128),
            player_serial VARCHAR(64),
            admin_name VARCHAR(128),
            reason TEXT,
            created_at BIGINT,
            expires_at BIGINT,
            active TINYINT DEFAULT 1,
            INDEX idx_bans_serial_active (player_serial, active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_warns (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(128),
            player_serial VARCHAR(64),
            admin_name VARCHAR(128),
            reason TEXT,
            created_at BIGINT,
            active TINYINT DEFAULT 1,
            INDEX idx_warns_serial (player_serial)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_temprank (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(128) UNIQUE,
            player_serial VARCHAR(64),
            rank VARCHAR(64),
            given_by VARCHAR(128),
            created_at BIGINT,
            expires_at BIGINT,
            active TINYINT DEFAULT 1,
            INDEX idx_temprank_serial_active (player_serial, active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(128),
            reason VARCHAR(255),
            description TEXT,
            created_at BIGINT,
            status VARCHAR(16) DEFAULT 'open',
            claimed_by VARCHAR(128),
            note TEXT,
            closed_at BIGINT,
            INDEX idx_reports_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(128),
            description TEXT,
            reward VARCHAR(255),
            starts_at BIGINT,
            ends_at BIGINT,
            capacity INT,
            created_by VARCHAR(128),
            active TINYINT DEFAULT 1
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_name VARCHAR(128),
            target_name VARCHAR(128),
            action VARCHAR(64),
            details TEXT,
            created_at BIGINT,
            INDEX idx_logs_admin (admin_name),
            INDEX idx_logs_action (action)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_player_activity (
            player_serial VARCHAR(64) PRIMARY KEY,
            player_name VARCHAR(128),
            first_seen BIGINT,
            last_join BIGINT,
            last_quit BIGINT,
            total_seconds BIGINT DEFAULT 0,
            join_count INT DEFAULT 0,
            last_ip VARCHAR(64),
            last_account VARCHAR(128),
            INDEX idx_activity_last_join (last_join)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_economy_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_serial VARCHAR(64),
            player_name VARCHAR(128),
            amount BIGINT,
            direction VARCHAR(8),
            reason TEXT,
            source_name VARCHAR(128),
            created_at BIGINT,
            INDEX idx_eco_serial_time (player_serial, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_item_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_serial VARCHAR(64),
            player_name VARCHAR(128),
            item_id VARCHAR(64),
            amount INT,
            action VARCHAR(32),
            source_name VARCHAR(128),
            created_at BIGINT,
            INDEX idx_item_serial_time (player_serial, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_ac_events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_serial VARCHAR(64),
            player_name VARCHAR(128),
            module VARCHAR(64),
            info TEXT,
            risk INT DEFAULT 0,
            action VARCHAR(32),
            created_at BIGINT,
            INDEX idx_ac_serial_time (player_serial, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    execute([[
        CREATE TABLE IF NOT EXISTS admin_player_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_serial VARCHAR(64),
            owner_name VARCHAR(128),
            model INT,
            model_name VARCHAR(64),
            plate VARCHAR(16),
            given_by VARCHAR(128),
            created_at BIGINT,
            INDEX idx_vehicles_owner (owner_serial)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    outputDebugString("[stage_admin] MySQL tabloları hazır.", 3)
end

-- stage_loading başlayana kadar bekle, sonra tabloları oluştur
addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        initTables()
    end, 2500, 1)
end)

addEventHandler("onResourceStart", root, function(res)
    if getResourceName(res) == "stage_loading" then
        db = nil -- bağlantıyı sıfırla, getDB yeniden alacak
        setTimer(initTables, 1000, 1)
    end
end)

-- ---- Generic query helpers ----

function AdminDBQuery(query, ...)
    local conn = getDB()
    if not conn then return {} end
    local h = dbQuery(conn, query, ...)
    local result = dbPoll(h, -1)
    return result or {}
end

function AdminDBExec(query, ...)
    return execute(query, ...)
end
