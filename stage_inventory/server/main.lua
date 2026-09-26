addEventHandler("onResourceStart", resourceRoot, function()
    for _, p in ipairs(getElementsByType("player")) do
        dbInitPlayer(p)
        syncPlayer(p)
    end
end)

addEventHandler("onPlayerJoin", root, function()
    setTimer(function(p) if isElement(p) then dbInitPlayer(p) syncPlayer(p) end end, 1000, 1, source)
end)

addEvent("inv:requestSync", true)
addEventHandler("inv:requestSync", root, function()
    dbInitPlayer(client)
    syncPlayer(client)
end)

local function createDepotForPlayer(player, name, depotType)
    name = tostring(name or ""):sub(1, 32)
    if name == "" or not isElement(player) then return false end
    depotType = depotType == "universal" and "universal" or "personal"
    if depotType == "universal" and not isInvAdmin(player) then
        triggerClientEvent(player, "inv:notify", player, "Ortak depo oluşturma yetkin yok.", "error")
        return false
    end
    local x, y, z = getElementPosition(player)
    local obj = createObject(1271, x, y, z - 0.9)
    if not obj then return false end
    setElementCollisionsEnabled(obj, true)
    local data = dbCreateDepot(name, depotType, depotType == "universal" and "*" or getPlayerSerial(player),
        x, y, z, getElementInterior(player), getElementDimension(player))
    dbRegisterDepot(obj, data)
    setElementInterior(obj, data.interior)
    setElementDimension(obj, data.dimension)
    setElementData(obj, "inv:depot", data.name, true)
    setElementData(obj, "inv:depotType", data.depotType, true)
    setElementData(obj, "inv:depotOwner", data.ownerKey, true)
    setElementData(obj, "inv:depotContents", data.contents, true)
    triggerClientEvent(player, "inv:notify", player, "Depo oluşturuldu: " .. name, "success")
    return true
end

addEvent("inv:createDepot", true)
addEventHandler("inv:createDepot", root, function(name, depotType)
    createDepotForPlayer(client, name, depotType)
end)

addEvent("inv:requestDepots", true)
addEventHandler("inv:requestDepots", root, function()
    if not isInvAdmin(client) then return end
    triggerClientEvent(client, "inv:depotList", client, dbGetAllDepots())
end)

addEvent("inv:updateDepot", true)
addEventHandler("inv:updateDepot", root, function(obj, name, moveHere)
    if not isInvAdmin(client) or not isElement(obj) then return end
    local data = dbGetDepot(obj)
    if not data then return end
    name = tostring(name or ""):sub(1, 32)
    if name:gsub("%s+", "") == "" then
        triggerClientEvent(client, "inv:notify", client, "Depo ismi boş olamaz.", "error")
        return
    end
    data.name = name
    if moveHere == true then
        data.x, data.y, data.z = getElementPosition(client)
        data.interior, data.dimension = getElementInterior(client), getElementDimension(client)
        setElementPosition(obj, data.x, data.y, data.z - 0.9)
        setElementInterior(obj, data.interior)
        setElementDimension(obj, data.dimension)
    end
    setElementData(obj, "inv:depot", data.name, true)
    dbSaveDepot(obj)
    triggerClientEvent(client, "inv:notify", client, "Depo güncellendi.", "success")
    triggerClientEvent(client, "inv:depotList", client, dbGetAllDepots())
end)

addEvent("inv:deleteDepot", true)
addEventHandler("inv:deleteDepot", root, function(obj)
    if not isInvAdmin(client) or not isElement(obj) then return end
    if dbDeleteDepot(obj) then
        triggerClientEvent(client, "inv:notify", client, "Depo silindi.", "success")
        triggerClientEvent(client, "inv:depotDeleted", client, obj)
    end
end)

addEvent("inv:depotTry", true)
addEventHandler("inv:depotTry", root, function(obj)
    if not isElement(obj) or not getElementData(obj, "inv:depot") then return end
    local x, y, z = getElementPosition(client)
    local ox, oy, oz = getElementPosition(obj)
    if getDistanceBetweenPoints3D(x, y, z, ox, oy, oz) > 4 then return end
    local typ = getElementData(obj, "inv:depotType") or "personal"
    local owner = getElementData(obj, "inv:depotOwner")
    if typ == "personal" and owner ~= getPlayerSerial(client) then
        triggerClientEvent(client, "inv:notify", client, "Bu kişisel depoya erişimin yok.", "error")
        return
    end
    triggerClientEvent(client, "inv:openDepot", client, getElementData(obj, "inv:depot"), obj, getElementData(obj, "inv:depotContents") or {})
end)

addEvent("inv:depotStore", true)
addEventHandler("inv:depotStore", root, function(obj, slot, amount)
    if not isElement(obj) or not getElementData(obj, "inv:depot") then return end
    local x, y, z = getElementPosition(client)
    local ox, oy, oz = getElementPosition(obj)
    if getDistanceBetweenPoints3D(x, y, z, ox, oy, oz) > 4 then return end
    local typ = getElementData(obj, "inv:depotType") or "personal"
    if typ == "personal" and getElementData(obj, "inv:depotOwner") ~= getPlayerSerial(client) then return end
    local inv = dbGetInventory(client)
    local entry = inv[tonumber(slot)]
    if not entry then return end
    amount = math.min(tonumber(amount) or entry.count, entry.count)
    local contents = getElementData(obj, "inv:depotContents") or {}
    local free
    for i = 1, Config.WorldSlots do if not contents[i] then free = i break end end
    if not free then return end
    contents[free] = { item = entry.item, count = amount, ammo = entry.ammo }
    entry.count = entry.count - amount
    if entry.count <= 0 then inv[tonumber(slot)] = nil end
    setElementData(obj, "inv:depotContents", contents, true)
    local data = dbGetDepot(obj)
    if data then
        data.contents = contents
        dbSaveDepot(obj)
    end
    dbSetInventory(client, inv)
    syncPlayer(client)
    triggerClientEvent(client, "inv:depotSync", client, contents)
end)

addEvent("inv:depotTake", true)
addEventHandler("inv:depotTake", root, function(obj, slot, amount)
    if not isElement(obj) or not getElementData(obj, "inv:depot") then return end
    local x, y, z = getElementPosition(client)
    local ox, oy, oz = getElementPosition(obj)
    if getDistanceBetweenPoints3D(x, y, z, ox, oy, oz) > 4 then return end
    local typ = getElementData(obj, "inv:depotType") or "personal"
    if typ == "personal" and getElementData(obj, "inv:depotOwner") ~= getPlayerSerial(client) then return end
    local contents = getElementData(obj, "inv:depotContents") or {}
    local entry = contents[tonumber(slot)]
    if not entry then return end
    amount = math.min(tonumber(amount) or entry.count, entry.count)
    if not giveItem(client, entry.item, amount) then return end
    entry.count = entry.count - amount
    if entry.count <= 0 then contents[tonumber(slot)] = nil end
    setElementData(obj, "inv:depotContents", contents, true)
    local data = dbGetDepot(obj)
    if data then
        data.contents = contents
        dbSaveDepot(obj)
    end
    triggerClientEvent(client, "inv:depotSync", client, contents)
end)

addEvent("inv:use", true)
addEventHandler("inv:use", root, function(slot, isHotbar)
    useItem(client, tonumber(slot), isHotbar == true)
end)

addEvent("inv:drop", true)
addEventHandler("inv:drop", root, function(slot, amount)
    dropItem(client, tonumber(slot), amount)
end)

addEvent("inv:move", true)
addEventHandler("inv:move", root, function(fromType, fromSlot, toType, toSlot, amount)
    moveItem(client, fromType, tonumber(fromSlot), toType, tonumber(toSlot), amount)
end)

addEvent("inv:giveTo", true)
addEventHandler("inv:giveTo", root, function(target, slot, amount)
    if isElement(target) then giveItemToPlayer(client, target, tonumber(slot), amount) end
end)

addEvent("inv:pickup", true)
addEventHandler("inv:pickup", root, function(obj)
    if not isElement(obj) then return end
    local data = getElementData(obj, "inv:dropped")
    if not data then return end
    local x,y,z = getElementPosition(client)
    local ox,oy,oz = getElementPosition(obj)
    if getDistanceBetweenPoints3D(x,y,z,ox,oy,oz) > Config.PickupDistance + 1 then return end
    if giveItem(client, data.item, data.count) then
        destroyElement(obj)
        local d = Items[data.item]
        local label = d and d.label or data.item
        triggerClientEvent(client, "inv:notify", client, "+" .. data.count .. " " .. label, "success")
    else
        triggerClientEvent(client, "inv:notify", client, "Envanter dolu.", "error")
    end
end)

function isInvAdmin(player)
    if getResourceFromName("stage_core") and getResourceState(getResourceFromName("stage_core")) == "running" then
        return exports.stage_core:IsAdmin(player)
    end
    -- fallback ACL
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then return false end
    local name = getAccountName(acc)
    local ok = pcall(function()
        return isObjectInACLGroup("user." .. name, aclGetGroup("Admin"))
            or isObjectInACLGroup("user." .. name, aclGetGroup("Console"))
    end)
    return ok
end

addEvent("inv:adminGive", true)
addEventHandler("inv:adminGive", root, function(itemId, count)
    if not isInvAdmin(client) then return end
    itemId = tostring(itemId or "")
    count = tonumber(count) or 1
    if count < 1 then count = 1 end
    if count > 1000 then count = 1000 end
    if Items[itemId] then giveItem(client, itemId, count) end
end)

addCommandHandler("inventory", function(p) triggerClientEvent(p, "inv:toggle", p) end)

addCommandHandler("giveitem", function(p, cmd, itemId, count)
    if not isInvAdmin(p) then
        outputChatBox("Bu komutu kullanma yetkin yok.", p, 255, 50, 50)
        return
    end
    if not itemId or not Items[itemId] then
        outputChatBox("Kullanim: /giveitem [id] [adet]  ornek: /giveitem ak47 1", p, 255, 100, 100)
        return
    end
    giveItem(p, itemId, tonumber(count) or 1)
end)

addCommandHandler("clearinv", function(p)
    if not isInvAdmin(p) then
        outputChatBox("Bu komutu kullanma yetkin yok.", p, 255, 50, 50)
        return
    end
    dbSetInventory(p, {})
    dbSetHotbar(p, {})
    syncPlayer(p)
end)

addCommandHandler("items", function(p)
    triggerClientEvent(p, "inv:openItems", p)
end)

function openInventory(p) triggerClientEvent(p, "inv:open", p) end
function closeInventory(p) triggerClientEvent(p, "inv:close", p) end

-- Stage alias export'lar
function AddItem(player, itemId, count)
    return giveItem(player, itemId, count)
end

function RemoveItem(player, itemId, count)
    return takeItem(player, itemId, count)
end

function HasItem(player, itemId, count)
    return hasItem(player, itemId, count)
end

function GetItemCount(player, itemId)
    return getItemCount(player, itemId)
end
