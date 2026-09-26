--[[
    stage_bank - server
    Banka bakiyesi artık stage_economy üzerinden MySQL'de tutulur.
    Kendi SQLite tablosu (bank_accounts/bank_transactions) kaldırıldı.
    stage_economy export'ları: GetBank, AddBank, RemoveBank, SetBank
]]

local function econRunning()
    local r = getResourceFromName("stage_economy")
    return r and getResourceState(r) == "running"
end

local function coreRunning()
    local r = getResourceFromName("stage_core")
    return r and getResourceState(r) == "running"
end

local function notify(player, message, kind)
    if coreRunning() then
        exports.stage_core:Notify(player, message, kind or "info")
    else
        outputChatBox("[Banka] " .. message, player, 80, 180, 255)
    end
end

local function getBank(player)
    if econRunning() then
        local ok, v = pcall(function() return exports.stage_economy:GetBank(player) end)
        if ok then return tonumber(v) or 0 end
    end
    return tonumber(getElementData(player, "bankmoney")) or 0
end

local function addBank(player, amount)
    if econRunning() then
        local ok, v = pcall(function() return exports.stage_economy:AddBank(player, amount) end)
        if ok then return v end
    end
    return false
end

local function removeBank(player, amount)
    if econRunning() then
        local ok, v = pcall(function() return exports.stage_economy:RemoveBank(player, amount) end)
        if ok then return v end
    end
    return false
end

local function getCash(player)
    if coreRunning() then
        local ok, v = pcall(function() return exports.stage_core:GetMoney(player) end)
        if ok then return tonumber(v) or 0 end
    end
    return getPlayerMoney(player) or 0
end

local function removeCash(player, amount)
    if coreRunning() then
        local ok, v = pcall(function() return exports.stage_core:RemoveMoney(player, amount) end)
        if ok then return v end
    end
    if getPlayerMoney(player) < amount then return false end
    takePlayerMoney(player, amount)
    return true
end

local function addCash(player, amount)
    if coreRunning() then
        local ok, v = pcall(function() return exports.stage_core:AddMoney(player, amount) end)
        if ok then return v end
    end
    givePlayerMoney(player, amount)
    return true
end

local function amount(value)
    value = math.floor(tonumber(value) or 0)
    if value < 1 or value > BankConfig.maxTransaction then return nil end
    return value
end

local function keyFor(player)
    return isElement(player) and getPlayerSerial(player) or nil
end

local function sendData(player)
    local bank = getBank(player)
    local cash = getCash(player)
    triggerClientEvent(player, "stage_bank:data", resourceRoot, {
        balance = bank,
        hasPin  = false, -- PIN sistemi kaldırıldı, economy tabanlı artık
        cash    = cash,
        history = {},
    })
end

local function atATM(player)
    for _, pos in ipairs(BankConfig.atmLocations) do
        local x, y, z = getElementPosition(player)
        if getDistanceBetweenPoints3D(x, y, z, pos[1], pos[2], pos[3]) <= 3 then return true end
    end
    return false
end

addEventHandler("onResourceStart", resourceRoot, function()
    for _, p in ipairs(BankConfig.atmLocations) do
        local marker = createMarker(p[1], p[2], p[3] - 1, "cylinder", 1.2, 50, 160, 255, 100)
        setElementData(marker, "stage_bank:atm", true)
        createBlip(p[1], p[2], p[3], 52, 2, 50, 160, 255, 255, 0, 180)
    end
    for _, player in ipairs(getElementsByType("player")) do
        setElementData(player, "bankmoney", getBank(player), true)
    end
end)

addEventHandler("onPlayerJoin", root, function()
    setTimer(function(player)
        if isElement(player) then
            setElementData(player, "bankmoney", getBank(player), true)
        end
    end, 1500, 1, source)
end)

addEvent("stage_bank:open", true)
addEventHandler("stage_bank:open", root, function()
    if client ~= source or not atATM(client) then return end
    sendData(client)
end)

-- PIN sistemi kaldırıldı; eski clientlar hata almaktan korunmak için boş yanıt:
addEvent("stage_bank:setPin", true)
addEventHandler("stage_bank:setPin", root, function()
    if client ~= source then return end
    triggerClientEvent(client, "stage_bank:pinResult", resourceRoot, true)
end)

addEvent("stage_bank:verifyPin", true)
addEventHandler("stage_bank:verifyPin", root, function()
    if client ~= source then return end
    triggerClientEvent(client, "stage_bank:pinResult", resourceRoot, true)
end)

addEvent("stage_bank:transaction", true)
addEventHandler("stage_bank:transaction", root, function(action, rawAmount, pin, targetName)
    if client ~= source or not atATM(client) then return end
    local value = amount(rawAmount)
    if not value then return notify(client, "Geçerli bir miktar gir.", "error") end

    if action == "deposit" then
        if not removeCash(client, value) then
            return notify(client, "Nakit paran yetersiz.", "error")
        end
        addBank(client, value)
        notify(client, "Para hesabına yatırıldı.", "success")

    elseif action == "withdraw" then
        if getBank(client) < value then
            return notify(client, "Banka bakiyen yetersiz.", "error")
        end
        if not removeBank(client, value) then
            return notify(client, "Çekim başarısız.", "error")
        end
        addCash(client, value)
        notify(client, "Para nakit olarak verildi.", "success")

    elseif action == "transfer" then
        local target = getPlayerFromName(tostring(targetName or ""))
        if not target or target == client then
            return notify(client, "Geçerli bir online oyuncu seç.", "error")
        end
        if getBank(client) < value then
            return notify(client, "Banka bakiyen yetersiz.", "error")
        end
        if not removeBank(client, value) then
            return notify(client, "Transfer başarısız.", "error")
        end
        addBank(target, value)
        notify(client, "Transfer başarıyla gönderildi.", "success")
        notify(target, getPlayerName(client) .. " sana banka transferi gönderdi.", "success")
        setElementData(target, "bankmoney", getBank(target), true)
    else
        return
    end

    setElementData(client, "bankmoney", getBank(client), true)
    sendData(client)
end)
