connection = nil

function initDatabase()
    local cfg = Config.MySQL
    local connStr = string.format("dbname=%s;host=%s;port=%d", cfg.dbname, cfg.host, cfg.port or 3306)
    connection = dbConnect("mysql", connStr, cfg.user, cfg.password, "share=1")

    if not connection then
        outputDebugString("[Benzinlik] MySQL bağlantısı başarısız! Lütfen config.lua içindeki bilgileri kontrol edin.", 1)
        return false
    end

    -- Schema'yı çalıştır
    local file = fileOpen("sql/schema.sql", true)
    if file then
        local size = fileGetSize(file)
        local sql = fileRead(file, size)
        fileClose(file)

        for query in string.gmatch(sql .. ";", "([^;]+);") do
            local trimmed = query:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" and not trimmed:match("^%-%-") then
                dbExec(connection, trimmed)
            end
        end
    else
        outputDebugString("[Benzinlik] schema.sql okunamadı!", 2)
    end

    outputDebugString("[Benzinlik] Database başarıyla bağlandı ve tablolar kontrol edildi.")
    return true
end

function dbQ(...)
    return dbQuery(connection, ...)
end

function dbE(...)
    return dbExec(connection, ...)
end

function dbP(qh, timeout)
    return dbPoll(qh, timeout or -1)
end

addEventHandler("onResourceStart", resourceRoot, function()
    if not initDatabase() then
        cancelEvent()
        return
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if connection then
        destroyElement(connection)
        connection = nil
    end
end)
