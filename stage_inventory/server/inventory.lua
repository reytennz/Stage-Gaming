function findFreeSlot(inv, maxSlots)
    maxSlots = maxSlots or Config.InventorySlots
    for i = 1, maxSlots do if not inv[i] then return i end end
    return nil
end

function canCarry(player, itemId, count)
    local data = Items[itemId]
    if not data then return false end
    return (calculateWeight(dbGetInventory(player)) + data.weight * (count or 1)) <= Config.MaxWeight
end

function giveItem(player, itemId, count)
    if not isElement(player) or not Items[itemId] then return false end
    count = math.max(1, tonumber(count) or 1)
    local data = Items[itemId]
    local inv = dbGetInventory(player)
    if not canCarry(player, itemId, count) then
        triggerClientEvent(player, "inv:notify", player, "Envanter kapasitesi dolu.", "error")
        return false
    end
    if data.stack > 1 then
        for slot, entry in pairs(inv) do
            if entry.item == itemId and entry.count < data.stack then
                local add = math.min(count, data.stack - entry.count)
                entry.count = entry.count + add
                count = count - add
                if count <= 0 then
                    dbSetInventory(player, inv)
                    syncPlayer(player)
                    triggerClientEvent(player, "inv:notify", player, "Eklendi " .. add .. "x", "success", itemId, add)
                    return true
                end
            end
        end
    end
    while count > 0 do
        local free = findFreeSlot(inv)
        if not free then
            triggerClientEvent(player, "inv:notify", player, "Bos slot yok.", "error")
            dbSetInventory(player, inv)
            syncPlayer(player)
            return false
        end
        local toAdd = math.min(count, data.stack)
        inv[free] = { item = itemId, count = toAdd }
        count = count - toAdd
        triggerClientEvent(player, "inv:notify", player, "Eklendi " .. toAdd .. "x", "success", itemId, toAdd)
    end
    dbSetInventory(player, inv)
    syncPlayer(player)
    return true
end

function takeItem(player, itemId, count)
    if not isElement(player) or not Items[itemId] then return false end
    count = math.max(1, tonumber(count) or 1)
    local inv = dbGetInventory(player)
    local removed = 0
    for slot = Config.InventorySlots, 1, -1 do
        local entry = inv[slot]
        if entry and entry.item == itemId then
            local take = math.min(count - removed, entry.count)
            entry.count = entry.count - take
            removed = removed + take
            if entry.count <= 0 then inv[slot] = nil end
            if removed >= count then break end
        end
    end
    local hb = dbGetHotbar(player)
    for i = 1, Config.HotbarSlots do
        if hb[i] and hb[i].item == itemId then
            if hb[i].count <= count then hb[i] = nil else hb[i].count = hb[i].count - count end
        end
    end
    dbSetHotbar(player, hb)
    dbSetInventory(player, inv)
    syncPlayer(player)
    return removed > 0
end

function getItemCount(player, itemId)
    local t = 0
    for _, e in pairs(dbGetInventory(player)) do if e.item == itemId then t = t + e.count end end
    return t
end

function hasItem(player, itemId, count) return getItemCount(player, itemId) >= (count or 1) end
function getPlayerInventory(player) return dbGetInventory(player) end

function syncPlayer(player)
    if not isElement(player) then return end
    triggerClientEvent(player, "inv:sync", player, dbGetInventory(player), dbGetHotbar(player), calculateWeight(dbGetInventory(player)))
end

local function cloneEntry(entry, count)
    if not entry then return nil end
    local copy = {}
    for k, v in pairs(entry) do copy[k] = v end
    if count then copy.count = count end
    return copy
end

function moveItem(player, fromType, fromSlot, toType, toSlot, amount)
    local inv, hb = dbGetInventory(player), dbGetHotbar(player)
    amount = tonumber(amount) or 1
    local sourceTable = (fromType == "inv") and inv or ((fromType == "hotbar") and hb or nil)
    local destTable = (toType == "inv") and inv or ((toType == "hotbar") and hb or nil)
    if not sourceTable or not destTable then return false end
    local src = sourceTable[fromSlot]
    if not src then return false end
    amount = math.min(amount, src.count)
    local data = Items[src.item]
    if not data then return false end
    if fromType == toType and fromSlot == toSlot then return false end
    local dest = destTable[toSlot]
    if dest then
        if dest.item == src.item and data.stack > 1 then
            local move = math.min(amount, data.stack - dest.count)
            if move <= 0 then return false end
            dest.count = dest.count + move
            src.count = src.count - move
            if src.count <= 0 then sourceTable[fromSlot] = nil end
        else
            sourceTable[fromSlot], destTable[toSlot] = dest, src
        end
    else
        if amount >= src.count then
            destTable[toSlot] = cloneEntry(src, src.count)
            sourceTable[fromSlot] = nil
        else
            destTable[toSlot] = cloneEntry(src, amount)
            src.count = src.count - amount
        end
    end
    dbSetInventory(player, inv)
    dbSetHotbar(player, hb)
    syncPlayer(player)
    return true
end
