--[[
    stage_core - Para işlemleri
    Native MTA money üzerine ince wrapper.
    Client'tan gelen miktarlara ASLA güvenme; her zaman server tarafında kontrol et.
]]

local function adminLoggerRunning()
    local r = getResourceFromName("stage_admin")
    return r and getResourceState(r) == "running"
end

local function logMoney(player, signedAmount, reason)
    if not adminLoggerRunning() then return end
    pcall(function()
        exports.stage_admin:AdminTrackEconomy(player, signedAmount, reason or "stage_core", "stage_core")
    end)
end

local function economyRunning()
    local resource = getResourceFromName("stage_economy")
    return resource and getResourceState(resource) == "running"
end

function GetMoney(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return 0
    end
    if economyRunning() then
        return exports.stage_economy:GetCash(player)
    end
    return getPlayerMoney(player) or 0
end

function HasMoney(player, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    return GetMoney(player) >= amount
end

function AddMoney(player, amount, reason)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    if economyRunning() then
        if not exports.stage_economy:AddCash(player, amount) then return false end
    else
        givePlayerMoney(player, amount)
    end
    logMoney(player, amount, reason or "Para eklendi")
    return true
end

function RemoveMoney(player, amount, reason)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    if GetMoney(player) < amount then
        return false
    end
    if economyRunning() then
        if not exports.stage_economy:RemoveCash(player, amount) then return false end
    else
        takePlayerMoney(player, amount)
    end
    logMoney(player, -amount, reason or "Para düşüldü")
    return true
end

function SetMoney(player, amount, reason)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then amount = 0 end
    local current = GetMoney(player)
    local delta = amount - current
    if economyRunning() then
        if not exports.stage_economy:SetCash(player, amount) then return false end
    elseif delta > 0 then
        givePlayerMoney(player, delta)
    elseif delta < 0 then
        takePlayerMoney(player, -delta)
    end
    if delta ~= 0 then logMoney(player, delta, reason or "Para ayarlandı") end
    return true
end
