--[[
    stage_admin - admin aksiyonları
    Tüm fonksiyonlar server-side çağrılır ve çağıran admin'in yetkisi
    zaten event handler seviyesinde (network.lua) kontrol edilmiş olmalı.
    Yine de burada da isStaff kontrolü tekrar edilir (defense-in-depth).
]]

-- Anti-cheat'in admin hareketlerini yanlışlıkla flag'lememesi için
-- server-side whitelist. AC modülleri bunu kontrol eder.
AdminBypassFlags = {} -- [player] = { noclip=true, fly=true, god=true, freeze=true }

local function ensureFlags(player)
    AdminBypassFlags[player] = AdminBypassFlags[player] or {}
    return AdminBypassFlags[player]
end

local function grantMovementExemption(player, ms, reason)
    if not isElement(player) then return end
    if type(AdminACGrantMovementExemption) == "function" then
        AdminACGrantMovementExemption(player, ms or 5000, reason or "admin_action")
    end
    local ac = getResourceFromName("stage_anticheat")
    if ac and getResourceState(ac) == "running" then
        pcall(function()
            exports.stage_anticheat:grantMovementExemption(player, ms or 5000, reason or "stage_admin")
        end)
    end
end

addEventHandler("onPlayerQuit", root, function()
    AdminBypassFlags[source] = nil
end)

-- ---------------- Teleport ----------------

function AdminTeleportTo(admin, target)
    if not isElement(admin) or not isElement(target) then return false end
    local x, y, z = getElementPosition(target)
    grantMovementExemption(admin, 6000, "admin_goto")
    setElementPosition(admin, x + 1, y + 1, z)
    if isElement(target) and getElementDimension(admin) ~= getElementDimension(target) then
        setElementDimension(admin, getElementDimension(target))
    end
    setElementInterior(admin, getElementInterior(target))
    return true
end

function AdminBringTo(admin, target)
    if not isElement(admin) or not isElement(target) then return false end
    local x, y, z = getElementPosition(admin)
    grantMovementExemption(target, 6000, "admin_bring")
    setElementDimension(target, getElementDimension(admin))
    setElementInterior(target, getElementInterior(admin))
    setElementPosition(target, x + 1, y + 1, z)
    AdminNotify(target, "Bir yetkili tarafından yanına çağırıldınız.", "info")
    return true
end

function AdminTeleportToCoords(admin, x, y, z)
    if not isElement(admin) then return false end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not (x and y and z) then return false end
    grantMovementExemption(admin, 6000, "admin_coords")
    setElementPosition(admin, x, y, z)
    return true
end

-- ---------------- Freeze ----------------

function AdminFreeze(target, state)
    if not isElement(target) then return false end
    setElementFrozen(target, state)
    local flags = ensureFlags(target)
    flags.freeze = state or nil
    AdminNotify(target, state and "Donduruldunuz." or "Donmanız kaldırıldı.", state and "warning" or "success")
    return true
end

-- ---------------- Invisible ----------------

function AdminSetInvisible(target, state)
    if not isElement(target) then return false end
    setElementAlpha(target, state and 0 or 255)
    setElementData(target, "admin:invisible", state and true or nil)
    return true
end

-- ---------------- Spectate ----------------

local spectating = {} -- [admin] = target

function AdminStartSpectate(admin, target)
    if not isElement(admin) or not isElement(target) then return false end
    spectating[admin] = target
    setCameraTarget(admin, target)
    setElementData(admin, "admin:spectating", true)
    return true
end

function AdminStopSpectate(admin)
    if not isElement(admin) then return false end
    spectating[admin] = nil
    setCameraTarget(admin, admin)
    setElementData(admin, "admin:spectating", nil)
    return true
end

addEventHandler("onPlayerQuit", root, function()
    for adminP, target in pairs(spectating) do
        if target == source and isElement(adminP) then
            AdminStopSpectate(adminP)
        end
    end
end)

-- ---------------- NoClip / Fly / God ----------------
-- İstemci tarafında görsel hareket, ama flag server'da tutulur ve
-- anticheat bu flag'leri her zaman önce kontrol eder.

function AdminSetNoClip(target, state)
    if not isElement(target) then return false end
    local flags = ensureFlags(target)
    flags.noclip = state or nil
    setElementData(target, "admin:noclip", state or nil)
    triggerClientEvent(target, "admin:setNoClip", target, state)
    return true
end

function AdminSetFly(target, state)
    if not isElement(target) then return false end
    local flags = ensureFlags(target)
    flags.fly = state or nil
    setElementData(target, "admin:fly", state or nil)
    triggerClientEvent(target, "admin:setFly", target, state)
    return true
end

function AdminSetGod(target, state)
    if not isElement(target) then return false end
    local flags = ensureFlags(target)
    flags.god = state or nil
    setElementData(target, "admin:god", state or nil)
    return true
end

addEventHandler("onPlayerDamage", root, function()
    local flags = AdminBypassFlags[source]
    if flags and flags.god then
        cancelEvent()
    end
end)

-- ---------------- Kick ----------------

function AdminKick(admin, target, reason)
    if not isElement(target) then return false end
    reason = AdminTrim(reason) ~= "" and reason or "Sebep belirtilmedi"
    AdminLog(admin, getPlayerName(target), "kick", reason)
    local kicked = kickPlayer(target, isElement(admin) and getPlayerName(admin) or "Stage Admin", reason)
    if not kicked then
        outputDebugString("[stage_admin] KICK: kickPlayer başarısız. stage_admin resource için function.kickPlayer ACL yetkisini kontrol edin.", 1)
        if isElement(admin) then AdminNotify(admin, "Kick başarısız: stage_admin için function.kickPlayer ACL yetkisi gerekli.", "error") end
        return false
    end
    return true
end
