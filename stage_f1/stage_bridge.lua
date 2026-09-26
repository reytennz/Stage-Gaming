--[[
    stage_f1 <-> stage_core köprüsü
    Core yoksa native MTA para fonksiyonlarına düşer.
]]

local function coreRunning()
    local res = getResourceFromName("stage_core")
    return res and getResourceState(res) == "running"
end

local function loadingRunning()
    local res = getResourceFromName("stage_loading")
    return res and getResourceState(res) == "running"
end

function StageGetMoney(player)
    if loadingRunning() then
        local ok, money = pcall(function() return exports.stage_loading:stageGetMoney(player) end)
        if ok and money ~= nil then return money end
    end
    if coreRunning() then
        return exports.stage_core:GetMoney(player)
    end
    if not isElement(player) then return 0 end
    return getPlayerMoney(player) or 0
end

function StageHasMoney(player, amount)
    if loadingRunning() then
        amount = math.floor(tonumber(amount) or 0)
        return StageGetMoney(player) >= amount
    end
    if coreRunning() then
        return exports.stage_core:HasMoney(player, amount)
    end
    amount = math.floor(tonumber(amount) or 0)
    return StageGetMoney(player) >= amount
end

function StageAddMoney(player, amount)
    if loadingRunning() then
        local ok, result = pcall(function() return exports.stage_loading:stageGiveMoney(player, amount) end)
        if ok then return result end
    end
    if coreRunning() then
        return exports.stage_core:AddMoney(player, amount)
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not isElement(player) then return false end
    givePlayerMoney(player, amount)
    return true
end

function StageRemoveMoney(player, amount)
    if loadingRunning() then
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 or not isElement(player) then return false end
        local current = StageGetMoney(player)
        if current < amount then return false end
        local ok, result = pcall(function() return exports.stage_loading:stageSetMoney(player, current - amount) end)
        if ok then return result end
    end
    if coreRunning() then
        return exports.stage_core:RemoveMoney(player, amount)
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not isElement(player) then return false end
    if StageGetMoney(player) < amount then return false end
    takePlayerMoney(player, amount)
    return true
end

function StageIsAdmin(player)
    if coreRunning() then
        return exports.stage_core:IsAdmin(player)
    end
    if not isElement(player) then return false end
    local acc = getPlayerAccount(player)
    if acc and not isGuestAccount(acc) then
        local name = getAccountName(acc)
        local ok = pcall(function()
            return isObjectInACLGroup("user." .. name, aclGetGroup("Admin"))
                or isObjectInACLGroup("user." .. name, aclGetGroup("Console"))
        end)
        if ok then return true end
    end
    local level = tonumber(getElementData(player, "adminlevel")) or 0
    return level >= 1
end

function StageFormatMoney(amount)
    if coreRunning() then
        return exports.stage_core:formatMoney(amount)
    end
    local str = tostring(math.floor(tonumber(amount) or 0))
    local formatted = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return "$" .. formatted:gsub("^%.", "")
end
