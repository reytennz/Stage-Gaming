--[[
    stage_mysql - Merkezi Veritabanı Yapılandırması
    Tüm Stage scriptleri buradaki tek bağlantıyı kullanır.
]]

MySQLConfig = {
    host = "localhost",
    port = 3306,
    user = "root",
    password = "R.yakup.12345",
    database = "stage",
    charset = "utf8mb4",
    
    -- MySQL bağlantısı başarısız olursa sunucunun çökmemesi ve verilerin kaybolmaması için
    -- otomatik SQLite (stage_database.db) yedeğine geçilsin mi? (Önerilen: true)
    autoFallbackSQLite = true,
}
