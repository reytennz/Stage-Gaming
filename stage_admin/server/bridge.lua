--[[
    stage_admin - bridge
    stage_core / stage_inventory export köprüsü. Sistemlerin iç koduna
    dokunmadan, sadece export üzerinden konuşur. Core/inventory yoksa
    (ya da kapalıysa) düşük seviyeli native fallback kullanılır.
]]

local function resourceRunning(name)
    local r = getResourceFromName(name)
    return r and getResourceState(r) == "running"
end

local function coreCall(method, ...)
    if not resourceRunning("stage_core") then return false, nil end
    local args = { ... }
    local ok, result = pcall(function()
        return exports.stage_core[method](unpack(args))
    end)
    if ok then return true, result end
    return false, nil
end

local function numData(player, keys)
    for _, key in ipairs(keys) do
        local v = tonumber(getElementData(player, key))
        if v then return v end
    end
    return nil
end

function AdminNotify(player, message, msgType)
    if not isElement(player) then return end
    if resourceRunning("stage_core") then
        local ok = pcall(function() exports.stage_core:Notify(player, message, msgType or "info") end)
        if ok then return end
    end
    triggerClientEvent(player, "admin:notify", player, message, msgType or "info")
end

local function econCall(method, ...)
    if not resourceRunning("stage_economy") then return false, nil end
    local args = { ... }
    local ok, result = pcall(function()
        return exports.stage_economy[method](unpack(args))
    end)
    if ok then return true, result end
    return false, nil
end

local function loadingCall(method, ...)
    if not resourceRunning("stage_loading") then return false, nil end
    local args = { ... }
    local ok, result = pcall(function()
        return exports.stage_loading[method](unpack(args))
    end)
    if ok then return true, result end
    return false, nil
end

function AdminReadCash(player)
    if not isElement(player) then return 0 end
    local ed = numData(player, { "money", "cash", "Money", "nakit", "para", "stage:money" })
    if ed and ed > 0 then return math.floor(ed) end
    local ok, r = econCall("GetCash", player)
    if ok and tonumber(r) and tonumber(r) > 0 then return math.floor(tonumber(r)) end
    ok, r = coreCall("GetMoney", player)
    if ok and tonumber(r) and tonumber(r) > 0 then return math.floor(tonumber(r)) end
    ok, r = loadingCall("stageGetMoney", player)
    if ok and tonumber(r) and tonumber(r) > 0 then return math.floor(tonumber(r)) end
    return math.floor(tonumber(getPlayerMoney(player)) or 0)
end

function AdminReadBank(player)
    if not isElement(player) then return 0 end
    local ed = numData(player, { "bankmoney", "bank", "bank_money", "Bank", "banka", "stage:bankmoney" })
    if ed and ed > 0 then return math.floor(ed) end
    local ok, r = econCall("GetBank", player)
    if ok and tonumber(r) and tonumber(r) > 0 then return math.floor(tonumber(r)) end
    ok, r = loadingCall("stageGetBank", player)
    if ok and tonumber(r) and tonumber(r) > 0 then return math.floor(tonumber(r)) end
    return ed or 0
end

function AdminGetWallet(player)
    return {
        cash = AdminReadCash(player),
        bank = AdminReadBank(player),
    }
end

function AdminAddMoney(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local ok, result = coreCall("AddMoney", player, amount)
    if ok then
        if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, amount, "admin_give_cash", "Stage Admin") end
        return result ~= false
    end
    givePlayerMoney(player, amount)
    if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, amount, "admin_give_cash", "Stage Admin") end
    return true
end

function AdminRemoveMoney(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local ok, result = coreCall("RemoveMoney", player, amount)
    if ok then
        if result ~= false and type(AdminTrackEconomy) == "function" then
            AdminTrackEconomy(player, -amount, "admin_take_cash", "Stage Admin")
        end
        return result ~= false
    end
    if getPlayerMoney(player) < amount then return false end
    takePlayerMoney(player, amount)
    if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, -amount, "admin_take_cash", "Stage Admin") end
    return true
end

function AdminAddBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok, result = coreCall("AddBank", player, amount)
    if not ok then ok, result = coreCall("addBank", player, amount) end
    if not ok then ok, result = coreCall("GiveBank", player, amount) end
    if ok and result ~= false then
        if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, amount, "admin_give_bank", "Stage Admin") end
        return true
    end
    local cur = AdminReadBank(player)
    setElementData(player, "bank", cur + amount)
    if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, amount, "admin_give_bank", "Stage Admin") end
    return true
end

function AdminRemoveBank(player, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok, result = coreCall("RemoveBank", player, amount)
    if not ok then ok, result = coreCall("removeBank", player, amount) end
    if ok and result ~= false then
        if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, -amount, "admin_take_bank", "Stage Admin") end
        return true
    end
    local cur = AdminReadBank(player)
    if cur < amount then return false end
    setElementData(player, "bank", cur - amount)
    if type(AdminTrackEconomy) == "function" then AdminTrackEconomy(player, -amount, "admin_take_bank", "Stage Admin") end
    return true
end

function AdminGiveItem(player, itemId, amount)
    if not isElement(player) then return false end
    amount = math.floor(tonumber(amount) or 1)
    if amount <= 0 then return false end

    if resourceRunning("stage_inventory") then
        local ok, result = pcall(function() return exports.stage_inventory:giveItem(player, itemId, amount) end)
        if ok then return result end
    end
    return false, "stage_inventory çalışmıyor"
end

function AdminGiveVehicle(player, model, x, y, z, adminName)
    if not isElement(player) then return false end
    model = tonumber(model)
    if not model then return false end

    local px, py, pz
    if x and y and z then
        px, py, pz = x, y, z
    else
        px, py, pz = getElementPosition(player)
        px = px + 3
    end

    local veh = createVehicle(model, px, py, pz)
    if not veh then return false end
    warpPedIntoVehicle(player, veh)
    if type(AdminRegisterVehicle) == "function" then
        AdminRegisterVehicle(player, veh, adminName or "Admin")
    end
    return true, veh
end

function AdminFormatMoney(amount)
    if resourceRunning("stage_core") then
        local ok, result = pcall(function() return exports.stage_core:formatMoney(amount) end)
        if ok and result then return result end
    end
    amount = math.floor(tonumber(amount) or 0)
    local s = tostring(amount)
    local k
    while true do
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return "$" .. s
end