local playerEquippedSlot = {} -- [player] = hotbar slot currently drawn (or nil)
local DEFAULT_MAGAZINE_SIZE = 12

local function setWeaponReady(player, weaponID, ammo)
    takeWeapon(player, weaponID)
    if ammo and ammo > 0 then
        giveWeapon(player, weaponID, ammo, true)
        toggleControl(player, "aim_weapon", true)
        toggleControl(player, "fire", true)
        setElementData(player, "inv:lockedWeapon", false)
        triggerClientEvent(player, "inv:weaponControls", player, true)
    else
        giveWeapon(player, weaponID, 1, true)
        toggleControl(player, "fire", false)
        setControlState(player, "fire", false)
        setElementData(player, "inv:lockedWeapon", weaponID)
        triggerClientEvent(player, "inv:weaponControls", player, false)
    end
end

local function saveEquippedAmmo(player)
    local slot = playerEquippedSlot[player]
    if not slot then return end
    local hb = dbGetHotbar(player)
    local entry = hb[slot]
    local data = entry and Items[entry.item]
    if not data or not data.weapon then return end
    entry.ammo = getPedTotalAmmo(player) or entry.ammo or 0
    if entry.ammo <= 0 then
        setElementData(player, "inv:lockedWeapon", data.weaponID)
        triggerClientEvent(player, "inv:weaponControls", player, false)
    end
    dbSetHotbar(player, hb)
    syncPlayer(player)
end

local function consumeUsedEntry(player, slot, isHotbar, amount)
    local inv = dbGetInventory(player)
    local hb = dbGetHotbar(player)
    local sourceTable = isHotbar and hb or inv
    local entry = sourceTable[slot]
    amount = math.max(1, tonumber(amount) or 1)
    if not entry or entry.count < amount then return false end
    entry.count = entry.count - amount
    if entry.count <= 0 then sourceTable[slot] = nil end
    dbSetInventory(player, inv)
    dbSetHotbar(player, hb)
    syncPlayer(player)
    return true
end

function useItem(player, slot, isHotbar)
    local entry = isHotbar and dbGetHotbar(player)[slot] or dbGetInventory(player)[slot]
    if not entry then return end
    local data = Items[entry.item]
    if not data or not data.usable then
        triggerClientEvent(player, "inv:notify", player, "Bu item kullanilamaz.", "error")
        return
    end
    if data.ammoFor then
        loadAmmo(player, slot, isHotbar)
        return
    end
    if data.weapon and data.weaponID then
        if not isHotbar then
            triggerClientEvent(player, "inv:notify", player, "Bu silahi kullanmak icin hizli erisime koyun.", "error")
            return
        end
        toggleWeapon(player, slot)
        return
    end
    if data.category == "armor" or entry.item == "armor" then
        if not consumeUsedEntry(player, slot, isHotbar, 1) then return end
        setPedArmor(player, 100)
        triggerClientEvent(player, "inv:notify", player, "Zirh kusanildi.", "success")
        return
    end
    if data.heal then
        if not consumeUsedEntry(player, slot, isHotbar, 1) then return end
        setElementHealth(player, math.min(100, getElementHealth(player) + data.heal))
        triggerClientEvent(player, "inv:notify", player, "Kullanıldı 1x", "success", entry.item, 1)
        return
    end
    triggerClientEvent(player, "inv:notify", player, data.label .. " kullanildi.", "info")
end

-- Draw / holster the weapon in a given hotbar slot. Holstering remembers the
-- currently loaded ammo so re-drawing the same weapon restores it (no ammo lost).
function toggleWeapon(player, slot)
    local hb = dbGetHotbar(player)
    local entry = hb[slot]
    if not entry then return end
    local data = Items[entry.item]
    if not data or not data.weapon then return end

    local curSlot = playerEquippedSlot[player]

    if curSlot == slot then
        -- already drawn -> holster it, remembering real loaded ammo
        entry.ammo = getPedTotalAmmo(player) or 0
        takeWeapon(player, data.weaponID)
        toggleControl(player, "fire", true)
        setElementData(player, "inv:lockedWeapon", false)
        triggerClientEvent(player, "inv:weaponControls", player, true)
        playerEquippedSlot[player] = nil
        dbSetHotbar(player, hb)
        syncPlayer(player)
        triggerClientEvent(player, "inv:notify", player, "Çıkartıldı 1x", "info", entry.item, 1)
        return
    end

    -- holster whatever was previously drawn from another hotbar slot first
    if curSlot and hb[curSlot] then
        local prevData = Items[hb[curSlot].item]
        if prevData and prevData.weapon then
            hb[curSlot].ammo = getPedTotalAmmo(player) or 0
            takeWeapon(player, prevData.weaponID)
        end
    end

    local ammo = entry.ammo or 0
    setWeaponReady(player, data.weaponID, ammo)
    playerEquippedSlot[player] = slot
    dbSetHotbar(player, hb)
    syncPlayer(player)
    if ammo > 0 then
        triggerClientEvent(player, "inv:notify", player, "Kuşanıldı 1x", "success", entry.item, 1)
    else
        triggerClientEvent(player, "inv:notify", player, data.label .. " kusanildi. (Mermi yuklemeden ates edemezsin)", "success")
    end
end

-- One ammo item adds one magazine to the drawn weapon, capped per weapon.
-- Ammo is stored on the hotbar weapon entry so moving/holstering keeps it.
function loadAmmo(player, slot, isHotbar)
    local inv = dbGetInventory(player)
    local hb = dbGetHotbar(player)
    local sourceTable = isHotbar and hb or inv
    local firstEntry = sourceTable[slot]
    if not firstEntry then return end
    local data = Items[firstEntry.item]
    if not data or not data.ammoFor then return end

    local curSlot = playerEquippedSlot[player]
    local hbEntry = curSlot and hb[curSlot]
    local weaponData = hbEntry and Items[hbEntry.item]
    if not weaponData or weaponData.weaponID ~= data.ammoFor then
        triggerClientEvent(player, "inv:notify", player, "Once bu mermiye uygun silahi kusanin.", "error")
        return
    end

    local magazineSize = tonumber(data.magazineSize) or tonumber(weaponData.magazineSize) or DEFAULT_MAGAZINE_SIZE
    local maxAmmo = tonumber(data.maxAmmo) or tonumber(weaponData.maxAmmo) or magazineSize
    local currentAmmo
    if getElementData(player, "inv:lockedWeapon") == data.ammoFor then
        currentAmmo = tonumber(hbEntry.ammo) or 0
    else
        currentAmmo = math.max(tonumber(getPedTotalAmmo(player)) or 0, tonumber(hbEntry.ammo) or 0)
    end
    if currentAmmo >= maxAmmo then
        hbEntry.ammo = maxAmmo
        dbSetHotbar(player, hb)
        syncPlayer(player)
        triggerClientEvent(player, "inv:notify", player, "Mermi zaten full. (" .. maxAmmo .. ")", "error")
        return
    end

    if firstEntry.count <= 0 then return end
    firstEntry.count = firstEntry.count - 1
    if firstEntry.count <= 0 then sourceTable[slot] = nil end

    local addAmmo = math.min(magazineSize, maxAmmo - currentAmmo)
    local newAmmo = currentAmmo + addAmmo
    setWeaponReady(player, data.ammoFor, newAmmo)
    hbEntry.ammo = newAmmo
    dbSetInventory(player, inv)
    dbSetHotbar(player, hb)
    syncPlayer(player)
    triggerClientEvent(player, "inv:notify", player, "Mermi Yüklendi", "success", data.ammoFor, 1)
end

addEventHandler("onPlayerQuit", root, function()
    local slot = playerEquippedSlot[source]
    if not slot then return end
    local hb = dbGetHotbar(source)
    local entry = hb[slot]
    if entry and Items[entry.item] and Items[entry.item].weapon then
        entry.ammo = getPedTotalAmmo(source) or entry.ammo or 0
        dbSetHotbar(source, hb)
    end
    playerEquippedSlot[source] = nil
end)

addEventHandler("onPlayerWasted", root, function()
    local slot = playerEquippedSlot[source]
    if not slot then return end
    local hb = dbGetHotbar(source)
    local entry = hb[slot]
    if entry and Items[entry.item] and Items[entry.item].weapon then
        entry.ammo = getPedTotalAmmo(source) or entry.ammo or 0
        dbSetHotbar(source, hb)
    end
    playerEquippedSlot[source] = nil
    setElementData(source, "inv:lockedWeapon", false)
end)

addEventHandler("onPlayerWeaponFire", root, function()
    local player = source
    setTimer(function()
        if isElement(player) then
            saveEquippedAmmo(player)
        end
    end, 50, 1)
end)

function dropItem(player, slot, amount)
    local inv = dbGetInventory(player)
    local entry = inv[slot]
    if not entry then return end
    local data = Items[entry.item]
    if not data or data.droppable == false then return end
    amount = math.min(tonumber(amount) or entry.count, entry.count)
    local x, y, z = getElementPosition(player)
    local obj = createObject(1271, x + 0.6, y, z - 0.9)
    setElementCollisionsEnabled(obj, false)
    setElementData(obj, "inv:dropped", { item = entry.item, count = amount })
    setElementData(obj, "inv:label", data.label .. " x" .. amount)
    entry.count = entry.count - amount
    if entry.count <= 0 then inv[slot] = nil end
    dbSetInventory(player, inv)
    syncPlayer(player)
    triggerClientEvent(player, "inv:notify", player, "Eksildi " .. amount .. "x", "info", entry.item, amount)
end

function giveItemToPlayer(player, target, slot, amount)
    if not isElement(target) or player == target then return end
    local px, py, pz = getElementPosition(player)
    local tx, ty, tz = getElementPosition(target)
    if getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) > Config.GiveDistance then
        triggerClientEvent(player, "inv:notify", player, "Oyuncu cok uzakta.", "error")
        return
    end
    local inv = dbGetInventory(player)
    local entry = inv[slot]
    if not entry then return end
    local data = Items[entry.item]
    if not data or data.tradable == false then return end
    amount = math.min(tonumber(amount) or 1, entry.count)
    if not canCarry(target, entry.item, amount) then
        triggerClientEvent(player, "inv:notify", player, "Hedefin envanteri dolu.", "error")
        return
    end
    takeItem(player, entry.item, amount)
    giveItem(target, entry.item, amount)
    triggerClientEvent(player, "inv:notify", player, amount .. "x " .. data.label .. " verildi.", "success")
end
