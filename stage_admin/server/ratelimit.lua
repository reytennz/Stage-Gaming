--[[
    stage_admin - basit rate limit (client event abuse önleme)
]]

local lastCall = {} -- [player][key] = tick

function AdminCheckRateLimit(player, key, minMs)
    minMs = minMs or 800
    lastCall[player] = lastCall[player] or {}
    local now = getTickCount()
    local last = lastCall[player][key]
    if last and (now - last) < minMs then
        return false
    end
    lastCall[player][key] = now
    return true
end

addEventHandler("onPlayerQuit", root, function()
    lastCall[source] = nil
end)
