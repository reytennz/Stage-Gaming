--[[
    stage_core - Temel sistem API koprusu.
    Diger resource'lar icin ortak, guvenli export katmani.
]]
local function resourceRunning(name)
    local r = getResourceFromName(name)
    return r and getResourceState(r) == "running"
end

function GetBank(player)
    if not isElement(player) or getElementType(player) ~= "player" then return 0 end
    if resourceRunning("stage_economy") then
        local ok, value = pcall(function() return exports.stage_economy:GetBank(player) end)
        if ok then return tonumber(value) or 0 end
    end
    return tonumber(getElementData(player, "bankmoney")) or 0
end
function HasBank(player, amount)
    amount = math.floor(tonumber(amount) or 0)
    return amount <= 0 or GetBank(player) >= amount
end
function AddBank(player, amount)
    if not isElement(player) or not resourceRunning("stage_economy") then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok, result = pcall(function() return exports.stage_economy:AddBank(player, amount) end)
    return ok and result == true
end
function RemoveBank(player, amount)
    if not isElement(player) or not resourceRunning("stage_economy") then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or GetBank(player) < amount then return false end
    local ok, result = pcall(function() return exports.stage_economy:RemoveBank(player, amount) end)
    return ok and result == true
end
function SetBank(player, amount)
    if not isElement(player) or not resourceRunning("stage_economy") then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local ok, result = pcall(function() return exports.stage_economy:SetBank(player, amount) end)
    return ok and result == true
end

function AddItem(player, itemId, count)
    if not resourceRunning("stage_inventory") then return false end
    local ok, result = pcall(function() return exports.stage_inventory:giveItem(player, itemId, count) end)
    return ok and result == true
end
function RemoveItem(player, itemId, count)
    if not resourceRunning("stage_inventory") then return false end
    local ok, result = pcall(function() return exports.stage_inventory:takeItem(player, itemId, count) end)
    return ok and result == true
end
function HasItem(player, itemId, count)
    if not resourceRunning("stage_inventory") then return false end
    local ok, result = pcall(function() return exports.stage_inventory:hasItem(player, itemId, count) end)
    return ok and result == true
end
function GetItemCount(player, itemId)
    if not resourceRunning("stage_inventory") then return 0 end
    local ok, result = pcall(function() return exports.stage_inventory:getItemCount(player, itemId) end)
    return ok and tonumber(result) or 0
end
function GetInventory(player)
    if not resourceRunning("stage_inventory") then return {} end
    local ok, result = pcall(function() return exports.stage_inventory:getPlayerInventory(player) end)
    return ok and result or {}
end
function OpenInventory(player)
    if not resourceRunning("stage_inventory") then return false end
    local ok, result = pcall(function() return exports.stage_inventory:openInventory(player) end)
    return ok and result ~= false
end
function CloseInventory(player)
    if not resourceRunning("stage_inventory") then return false end
    local ok, result = pcall(function() return exports.stage_inventory:closeInventory(player) end)
    return ok and result ~= false
end
