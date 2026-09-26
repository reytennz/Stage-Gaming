-- stage_id | server
local db = nil
local sessionIDs = {} -- player -> id (mysql yoksa)

local function getDB()
    if not CONFIG.MYSQL_KULLAN then return nil end
    if db then return db end
    if getResourceFromName("stage_mysql") and getResourceState(getResourceFromName("stage_mysql")) == "running" then
        db = exports.stage_mysql:getConnection()
    end
    return db
end

addEventHandler("onResourceStart", resourceRoot, function()
    local conn = getDB()
    if conn then
        dbExec(conn, [[CREATE TABLE IF NOT EXISTS ]] .. CONFIG.TABLO .. [[ (
            serial VARCHAR(64) PRIMARY KEY,
            player_id INT NOT NULL UNIQUE
        )]])
    end
    -- oturan oyunculara ID ata
    for _, p in ipairs(getElementsByType("player")) do
        assignID(p)
    end
end)

local function nextFreeID(conn)
    local q = dbQuery(conn, "SELECT MAX(player_id) AS m FROM " .. CONFIG.TABLO)
    local r = dbPoll(q, -1)
    local m = r and r[1] and tonumber(r[1].m) or (CONFIG.BASLANGIC_ID - 1)
    return m + 1
end

function assignID(player)
    if not isElement(player) then return end
    if getElementData(player, "playerid") then return end -- stage_loading karakter ID'si atadiysa dokunma
    local serial = getPlayerSerial(player)
    local conn = getDB()
    if conn and serial then
        local q = dbQuery(conn, "SELECT player_id FROM " .. CONFIG.TABLO .. " WHERE serial = ?", serial)
        local r = dbPoll(q, -1)
        if r and r[1] then
            setElementData(player, "playerid", r[1].player_id)
        else
            local newID = nextFreeID(conn)
            dbExec(conn, "INSERT INTO " .. CONFIG.TABLO .. " (serial, player_id) VALUES (?, ?)", serial, newID)
            setElementData(player, "playerid", newID)
        end
    else
        -- mysql yoksa oturum ID'si
        local id = 1
        local used = {}
        for _, p in ipairs(getElementsByType("player")) do
            local d = getElementData(p, "playerid")
            if d then used[tonumber(d)] = true end
        end
        while used[id] do id = id + 1 end
        setElementData(player, "playerid", id)
    end
end

addEventHandler("onPlayerJoin", root, function()
    assignID(source)
end)

addEventHandler("onPlayerQuit", root, function()
    sessionIDs[source] = nil
end)

-- /id <isim veya id> : oyuncu ara
addCommandHandler("id", function(player, cmd, target)
    if not target then
        local myID = getElementData(player, "playerid")
        outputChatBox("Senin ID'n: #ffffff" .. tostring(myID or "?"), player, 255, 170, 0, true)
        return
    end
    local tid = tonumber(target)
    for _, p in ipairs(getElementsByType("player")) do
        local pid = getElementData(p, "playerid")
        if (tid and tonumber(pid) == tid) or (not tid and getPlayerName(p):lower():find(target:lower(), 1, true)) then
            outputChatBox(getPlayerName(p) .. " #ffffff| ID: #ffff00" .. tostring(pid), player, 255, 170, 0, true)
        end
    end
end)

-- export: başka scriptler ID çekebilsin
function getPlayerID(player)
    return getElementData(player, "playerid")
end
