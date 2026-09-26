--[[
    stage_core - Veritabanı Köprüsü
    Öncelikli olarak stage_mysql'i kullanır.
    Böylece tüm scriptler tek bir merkezi MySQL havuzundan çalışır.
]]

local function getMySQL()
    local r = getResourceFromName('stage_mysql')
    if r and getResourceState(r) == 'running' then
        return true
    end
    return false
end

function CoreDBIsMySQL()
    if getMySQL() then
        return exports.stage_mysql:isMySQL()
    end
    return false
end

function CoreDBQuery(sql, ...)
    if getMySQL() then
        return exports.stage_mysql:querySync(sql, ...)
    end
    return {}
end

function CoreDBExec(sql, ...)
    if getMySQL() then
        return exports.stage_mysql:exec(sql, ...)
    end
    return false
end
