--[[
    stage_core - HTML Notify Server Bridge
    type: "success" | "error" | "info" | "warning"
]]

local COLORS = {
    success = { 46, 204, 113 },
    error   = { 231, 76, 60 },
    info    = { 0, 188, 212 },
    warning = { 241, 196, 15 },
}

function Notify(player, message, ntype, title, count, duration)
    if not isElement(player) or getElementType(player) ~= "player" then
        return
    end
    message = tostring(message or "")
    if message == "" then return end

    ntype = ntype or "info"
    title = title or ""
    count = count or ""
    duration = tonumber(duration) or 5000
    local c = COLORS[ntype] or COLORS.info

    -- Client HTML CEF Event
    triggerClientEvent(player, "stage_core:notify", player, message, ntype, title, count, duration)

    -- Fallback chat log
    outputChatBox("» " .. message, player, c[1], c[2], c[3], true)
end

-- Rate limit
local lastAction = {}

function CheckRateLimit(player, action, cooldownMs)
    if not isElement(player) then return false end
    action = tostring(action or "default")
    cooldownMs = tonumber(cooldownMs) or (CoreConfig and CoreConfig.DefaultRateLimit) or 800

    local key = tostring(player) .. ":" .. action
    local now = getTickCount()
    if lastAction[key] and (now - lastAction[key]) < cooldownMs then
        return false
    end
    lastAction[key] = now
    return true
end

addEventHandler("onPlayerQuit", root, function()
    local prefix = tostring(source) .. ":"
    for k in pairs(lastAction) do
        if k:sub(1, #prefix) == prefix then
            lastAction[k] = nil
        end
    end
end)
