--[[
    stage_economy/server.lua
    Merkezi MySQL (stage_mysql) entegrasyonu + Kalıcı Nakit ve Banka sistemi.
    Sunucu veya resource restart yese dahi paralar ASLA sıfırlanmaz!
]]

local function mysqlRunning()
    local r = getResourceFromName("stage_mysql")
    return r and getResourceState(r) == "running"
end

local function loadingRunning()
    local r = getResourceFromName("stage_loading")
    return r and getResourceState(r) == "running"
end

-- ======== NAKİT ========

function GetCash(player)
    if not isElement(player) then return 0 end
    return getPlayerMoney(player) or 0
end

function SetCash(player, amount)
    if not isElement(player) then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    setPlayerMoney(player, amount)
    setElementData(player, "money", amount, true)
    
    if mysqlRunning() then
        pcall(function() exports.stage_mysql:savePlayerMoney(player, amount, GetBank(player)) end)
    elseif loadingRunning() then
        pcall(function() exports.stage_loading:stageSetMoney(player, amount) end)
    end
    return true
end

function AddCash(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local newTotal = GetCash(player) + amount
    return SetCash(player, newTotal)
end

function RemoveCash(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local current = GetCash(player)
    if current < amount then return false end
    return SetCash(player, current - amount)
end

-- ======== BANKA ========

function GetBank(player)
    if not isElement(player) then return 0 end
    local val = tonumber(getElementData(player, "bankmoney"))
    if val then return val end
    if loadingRunning() then
        local ok, v = pcall(function() return exports.stage_loading:stageGetBank(player) end)
        if ok and v then return tonumber(v) or 0 end
    end
    return 0
end

function SetBank(player, amount)
    if not isElement(player) then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    setElementData(player, "bankmoney", amount, true)
    
    if mysqlRunning() then
        pcall(function() exports.stage_mysql:savePlayerMoney(player, GetCash(player), amount) end)
    elseif loadingRunning() then
        pcall(function() exports.stage_loading:stageSetBank(player, amount) end)
    end
    return true
end

function AddBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return SetBank(player, GetBank(player) + amount)
end

function RemoveBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local current = GetBank(player)
    if current < amount then return false end
    return SetBank(player, current - amount)
end

-- ======== YEDEKLEME VE KURTARMA EVENTLERİ ========

local function restorePlayerEconomy(player)
    if not isElement(player) then return end
    if mysqlRunning() then
        local ok, cash, bank = pcall(function() return exports.stage_mysql:loadPlayerMoney(player) end)
        if ok and (cash > 0 or bank > 0) then
            -- Eğer oyuncunun mevcut parası 0 ise ve veri tabanında parası varsa yükle
            if getPlayerMoney(player) == 0 and cash > 0 then
                setPlayerMoney(player, cash)
                setElementData(player, "money", cash, true)
            end
            if (tonumber(getElementData(player, "bankmoney")) or 0) == 0 and bank > 0 then
                setElementData(player, "bankmoney", bank, true)
            end
        end
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        restorePlayerEconomy(player)
    end
    outputDebugString("[stage_economy] stage_mysql destekli kalici ekonomi aktif.", 3)
end)

addEventHandler("onPlayerJoin", root, function()
    setTimer(function(p)
        if isElement(p) then restorePlayerEconomy(p) end
    end, 1500, 1, source)
end)

addEventHandler("onPlayerQuit", root, function()
    if mysqlRunning() then
        pcall(function() exports.stage_mysql:savePlayerMoney(source, GetCash(source), GetBank(source)) end)
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        if mysqlRunning() then
            pcall(function() exports.stage_mysql:savePlayerMoney(player, GetCash(player), GetBank(player)) end)
        end
    end
end)

-- Aliaslar
function giveMoney(p, a) return AddCash(p, a) end
function takeMoney(p, a) return RemoveCash(p, a) end
function getMoney(p) return GetCash(p) end
function setMoney(p, a) return SetCash(p, a) end
