-- Rate-limit, sahiplik ve admin kod yetkilendirmesi
local lastAction = {}
local codeAuthorized = {} -- [player] = true (admin kodu ile giriş)

function checkRateLimit(player, action, cooldownMs)
    if not isElement(player) then return false end
    local key = tostring(player) .. ":" .. action
    local now = getTickCount()
    if lastAction[key] and (now - lastAction[key]) < (cooldownMs or 1000) then
        return false
    end
    lastAction[key] = now
    return true
end

function isValidStationOwner(player, stationId)
    if not isElement(player) or not stationId then return false end
    local acc = getAccountNameSafe(player)
    if not acc then return false end
    local data = stations[stationId]
    return data and data.owner == acc
end

function validateClient(player)
    return isElement(player) and getElementType(player) == "player"
end

-- ACL Admin VEYA admin kodu ile yetkilendirilmiş
function isBenzinlikAdmin(player)
    if not isElement(player) then return false end
    if isACLAdmin(player) then return true end
    if codeAuthorized[player] then return true end
    return false
end

function authorizeWithCode(player, code)
    if not isElement(player) then return false end
    local cfg = tostring(Config.AdminCode or "")
    if cfg == "" then return false end
    if tostring(code or "") == cfg then
        codeAuthorized[player] = true
        return true
    end
    return false
end

function revokeCodeAuth(player)
    if player then codeAuthorized[player] = nil end
end

-- Server tarafında isAdmin = kod + ACL
function isAdmin(player)
    return isBenzinlikAdmin(player)
end

addEventHandler("onPlayerQuit", root, function()
    local keyPrefix = tostring(source) .. ":"
    for k in pairs(lastAction) do
        if k:find(keyPrefix, 1, true) == 1 then
            lastAction[k] = nil
        end
    end
    codeAuthorized[source] = nil
end)
