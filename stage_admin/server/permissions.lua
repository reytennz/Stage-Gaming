--[[
    stage_admin - persistent permission / rank system
    Ranklar serial bazlı SQLite'a kaydedilir ve restart sonrası korunur.
]]

local tempRankCache = {}

local function coreIsAdmin(player)
    local core = getResourceFromName("stage_core")
    if core and getResourceState(core) == "running" then
        local ok, result = pcall(function() return exports.stage_core:IsAdmin(player) end)
        if ok then return result == true end
    end
    return false
end

local function rankIndex(rankName)
    for i, r in ipairs(Config.Ranks) do
        if r == rankName then return i end
    end
    return 0
end

local function validRank(rank)
    return rankIndex(rank) > 0
end

local function loadTempRanks()
    tempRankCache = {}
    local rows = AdminDBQuery("SELECT * FROM admin_temprank WHERE active = 1")
    local now = getRealTime().timestamp
    for _, row in ipairs(rows) do
        local exp = tonumber(row.expires_at) or 0
        if exp == 0 or exp > now then
            tempRankCache[row.player_serial] = {
                rank = row.rank, expires_at = exp, name = row.player_name
            }
        else
            AdminDBExec("UPDATE admin_temprank SET active = 0 WHERE id = ?", row.id)
        end
    end

    -- Oyuncular zaten online ise elementData'yı da senkronla.
    for _, p in ipairs(getElementsByType("player")) do
        local serial = getPlayerSerial(p)
        local r = tempRankCache[serial]
        if r then setElementData(p, "admin:rank", r.rank) end
    end
end

-- database.lua önce hazır olsun.
addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(loadTempRanks, 500, 1)
end)

function AdminGetRank(player)
    if not isElement(player) then return "User" end
    local serial = getPlayerSerial(player)

    for _, ownerSerial in ipairs(Config.Owners or {}) do
        if ownerSerial == serial then return "Owner" end
    end

    local temp = tempRankCache[serial]
    if temp then
        if temp.expires_at == 0 or temp.expires_at > getRealTime().timestamp then
            return temp.rank
        end
        tempRankCache[serial] = nil
        AdminDBExec("UPDATE admin_temprank SET active = 0 WHERE player_serial = ?", serial)
    end

    local dataRank = getElementData(player, "admin:rank")
    if dataRank and rankIndex(dataRank) > 1 then
        return dataRank
    end

    if coreIsAdmin(player) then
        local level = tonumber(getElementData(player, "adminlevel")) or 0
        if level >= 5 then return "Owner"
        elseif level >= 4 then return "Developer"
        elseif level >= 3 then return "SuperAdmin"
        elseif level >= 2 then return "Admin"
        else return "Moderator" end
    end

    return "User"
end

-- Kalıcı rütbe. Console / diğer resource'lar için de kullanılır.
function AdminSetRank(player, rank)
    if not isElement(player) or not validRank(rank) then return false end
    local serial, name = getPlayerSerial(player), getPlayerName(player)
    local now = getRealTime().timestamp

    AdminDBExec("DELETE FROM admin_temprank WHERE player_serial = ?", serial)
    AdminDBExec(
        "INSERT INTO admin_temprank (player_name, player_serial, rank, given_by, created_at, expires_at, active) VALUES (?, ?, ?, ?, ?, 0, 1)",
        name, serial, rank, "Console", now
    )
    tempRankCache[serial] = { rank = rank, expires_at = 0, name = name }
    setElementData(player, "admin:rank", rank)
    return true
end

-- Permissionlar alt rütbelerden miras alınır.
function AdminGetPermissions(player)
    local out, seen = {}, {}
    if not isElement(player) then return out end
    local idx = rankIndex(AdminGetRank(player))
    for i = 2, idx do
        local rank = Config.Ranks[i]
        for _, p in ipairs(Config.Permissions[rank] or {}) do
            if not seen[p] then
                seen[p] = true
                out[#out+1] = p
            end
        end
    end
    return out
end

function AdminHasPermission(player, permission)
    if not isElement(player) then return false end
    local idx = rankIndex(AdminGetRank(player))
    if idx <= 1 then return false end
    for i = 2, idx do
        local rank = Config.Ranks[i]
        for _, p in ipairs(Config.Permissions[rank] or {}) do
            if p == "*" or p == permission then return true end
        end
    end
    return false
end

function AdminIsStaff(player)
    return AdminGetRank(player) ~= "User"
end

function AdminGiveTempRank(admin, target, rank, durationSeconds)
    if not isElement(target) or not validRank(rank) then return false end
    local serial, name = getPlayerSerial(target), getPlayerName(target)
    local now = getRealTime().timestamp
    durationSeconds = math.max(0, tonumber(durationSeconds) or 0)
    local expires = durationSeconds > 0 and (now + durationSeconds) or 0

    AdminDBExec("DELETE FROM admin_temprank WHERE player_serial = ?", serial)
    AdminDBExec(
        "INSERT INTO admin_temprank (player_name, player_serial, rank, given_by, created_at, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)",
        name, serial, rank, isElement(admin) and getPlayerName(admin) or "Console", now, expires
    )

    tempRankCache[serial] = { rank = rank, expires_at = expires, name = name }
    setElementData(target, "admin:rank", rank)

    if durationSeconds > 0 then
        setTimer(function()
            local current = tempRankCache[serial]
            if current and current.expires_at == expires then
                tempRankCache[serial] = nil
                AdminDBExec("UPDATE admin_temprank SET active = 0 WHERE player_serial = ?", serial)
                if isElement(target) then
                    setElementData(target, "admin:rank", nil)
                    AdminNotify(target, "Geçici yetkiniz sona erdi.", "info")
                end
            end
        end, durationSeconds * 1000, 1)
    end
    return true
end

function AdminRemoveRank(target)
    if not isElement(target) then return false end
    local serial = getPlayerSerial(target)
    tempRankCache[serial] = nil
    AdminDBExec("UPDATE admin_temprank SET active = 0 WHERE player_serial = ?", serial)
    setElementData(target, "admin:rank", nil)
    return true
end

addEventHandler("onPlayerQuit", root, function()
    tempRankCache[getPlayerSerial(source)] = tempRankCache[getPlayerSerial(source)]
end)
