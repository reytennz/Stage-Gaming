function formatMoney(amount)
    local formatted = tostring(math.floor(amount or 0))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return Config.Currency .. formatted
end

function getAccountNameSafe(player)
    if not isElement(player) then return nil end
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then return nil end
    return getAccountName(acc)
end

-- Sadece ACL kontrolü (shared)
function isACLAdmin(player)
    if not isElement(player) then return false end
    local ok, result = pcall(function()
        return hasObjectPermissionTo(player, "command.benzinlikler", false)
            or isObjectInACLGroup("user." .. (getAccountNameSafe(player) or ""), aclGetGroup(Config.AdminACL))
    end)
    return ok and result
end

-- Geriye uyumluluk
function isAdmin(player)
    return isACLAdmin(player)
end

function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function tableCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = tableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function getLevelData(level)
    return Config.Levels[level] or Config.Levels[1]
end
