--[[
    ==========================================================
    db.lua  (SERVER) — BİRLEŞİK VERİTABANI KATMANI
    ==========================================================
    Eskiden tuning tarafı exports.stage_core:execAsync/query
    çağırıyordu, ancak stage_core böyle bir fonksiyon export
    ETMİYOR (sadece CoreDBQuery/CoreDBExec var). Tablet tarafı
    ise zaten exports.stage_mysql:getConnection() kullanıyordu.

    Bu yüzden birleşmiş kaynakta TEK bağlantı var: stage_mysql.
    Hem tuning (arac_parcalar) hem tablet (mechanic_shops,
    mechanic_depo) tabloları bu bağlantıyı kullanır.
]]

local _db = nil

-- Paylaşılan MySQL bağlantısını döndürür (kopmuşsa yeniden alır)
function getStageDB()
    if not _db or not isElement(_db) then
        _db = exports.stage_mysql:getConnection()
    end
    if not _db or not isElement(_db) then
        outputDebugString("[Stage Illegalmec] MySQL bağlantısı alınamadı! 'stage_mysql' kaynağı başlamış mı?", 1)
        return false
    end
    return _db
end

-- Kaynak başlarken gerekli tüm tabloları oluşturur
addEventHandler("onResourceStart", resourceRoot, function()
    local db = getStageDB()
    if not db then return end

    -- Tuning: araca takılı parçalar (plaka -> JSON liste)
    dbExec(db, [[CREATE TABLE IF NOT EXISTS `arac_parcalar` (
        `plaka` VARCHAR(32) NOT NULL,
        `veriler` TEXT,
        PRIMARY KEY (`plaka`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    -- Tablet: mekanik dükkanları
    dbExec(db, [[CREATE TABLE IF NOT EXISTS `mechanic_shops` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `mekanik_ismi` VARCHAR(64) NOT NULL,
        `sifresi` VARCHAR(255) NOT NULL,
        `sahibi` VARCHAR(64) NOT NULL,
        `owner_id` INT NOT NULL,
        `eleman` TINYINT(1) DEFAULT NULL,
        `duty_x` FLOAT DEFAULT NULL,
        `duty_y` FLOAT DEFAULT NULL,
        `duty_z` FLOAT DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_mekanik_ismi` (`mekanik_ismi`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    -- Tablet: dükkan deposu
    dbExec(db, [[CREATE TABLE IF NOT EXISTS `mechanic_depo` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `sahibi` VARCHAR(64) NOT NULL,
        `slot` INT NOT NULL,
        `esya` VARCHAR(64) DEFAULT NULL,
        `miktar` INT DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_sahibi_slot` (`sahibi`,`slot`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)
