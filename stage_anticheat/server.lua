-- Stage Gaming AntiCheat v3
-- Staff bypass + giriş/spawn toleransı + risk tabanlı karar + 10 dk kalıcı ban.

local CFG = {
    vehicleSpeedKmh = 500,
    playerSpeedKmh = 120,
    consecutiveSamples = 3,
    warningCooldown = 3000,
    teleportExemptMs = 5000,
    joinGraceMs = 45000,
    spawnGraceMs = 12000,
    maxWarnings = 5,
    banSeconds = 600,
    checkInterval = 500,
    warningResetMs = 120000,
    flySamples = 5,
    superJumpHeight = 4.5,
    healthTolerance = 105,
    armorTolerance = 105,
    maxDamage = 150,
}

local settings = {
    speed = true, fly = true, teleport = true, superjump = true,
    vehicleFly = true, rapidFire = true, illegalWeapon = true,
    health = true, armor = true, eventSpam = true, damage = true,
    illegalVehicle = true,
}

local state = {}
local eventRate = {}
local weapons = {}
local settingsFile = "settings.xml"
local acDB = nil
local f1ExemptRate = {}

for i = 0, 46 do weapons[i] = true end

local riskPoints = {
    speed = 20,
    fly = 35,
    teleport = 30,
    superjump = 25,
    vehicleFly = 30,
    rapidFire = 25,
    illegalWeapon = 50,
    health = 45,
    armor = 40,
    damage = 50,
}

local function nowUnix()
    return getRealTime().timestamp
end

local function adminResourceRunning()
    local r = getResourceFromName("stage_admin")
    return r and getResourceState(r) == "running"
end

local function isACAdmin(p)
    if not isElement(p) or getElementType(p) ~= "player" then return false end

    if adminResourceRunning() then
        local ok, result = pcall(function() return exports.stage_admin:AdminIsStaff(p) end)
        if ok and result == true then return true end
    end

    local rank = tostring(getElementData(p, "admin:rank") or "User")
    if rank ~= "" and rank ~= "User" then return true end

    local acc = getPlayerAccount(p)
    if acc and not isGuestAccount(acc) then
        local n = getAccountName(acc)
        for _, g in ipairs({"Admin", "Console"}) do
            local group = aclGetGroup(g)
            if group and isObjectInACLGroup("user." .. n, group) then return true end
        end
    end

    return (tonumber(getElementData(p, "adminlevel")) or 0) >= 1
end

local function saveSettings()
    local xml = xmlLoadFile(settingsFile) or xmlCreateFile(settingsFile, "settings")
    for k, v in pairs(settings) do
        local n = xmlFindChild(xml, k, 0) or xmlCreateChild(xml, k)
        xmlNodeSetAttribute(n, "enabled", v and "1" or "0")
    end
    xmlSaveFile(xml)
    xmlUnloadFile(xml)
end

local function loadSettings()
    local xml = xmlLoadFile(settingsFile)
    if not xml then saveSettings(); return end
    for k in pairs(settings) do
        local n = xmlFindChild(xml, k, 0)
        if n then settings[k] = xmlNodeGetAttribute(n, "enabled") == "1" end
    end
    xmlUnloadFile(xml)
end

local function getState(p)
    if not state[p] then
        state[p] = {
            bad = 0,
            warnings = 0,
            risk = 0,
            lastWarn = 0,
            lastClean = getTickCount(),
            exemptUntil = 0,
            graceUntil = getTickCount() + CFG.joinGraceMs,
            lastPos = nil,
            air = 0,
            reasonCooldown = {},
        }
    end
    return state[p]
end

local function resetState(p)
    state[p] = nil
end

local function trackDetection(p, moduleName, info, action)
    if not adminResourceRunning() then return end
    local s = getState(p)
    pcall(function()
        exports.stage_admin:AdminTrackACDetection(p, moduleName, info or "", s.risk or 0, action or "log")
    end)
end

local function initBanDB()
    acDB = dbConnect("sqlite", "ac_bans.db")
    if acDB then
        dbExec(acDB, [[CREATE TABLE IF NOT EXISTS ac_bans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            serial TEXT,
            player_name TEXT,
            reason TEXT,
            created_at INTEGER,
            expires_at INTEGER,
            active INTEGER DEFAULT 1
        )]])
        dbExec(acDB, "CREATE INDEX IF NOT EXISTS idx_ac_bans_serial ON ac_bans(serial, active)")
    end
end

local function localActiveBan(serial)
    if not acDB then return nil end
    local rows = dbPoll(dbQuery(acDB,
        "SELECT * FROM ac_bans WHERE serial = ? AND active = 1 ORDER BY id DESC LIMIT 1", serial), -1) or {}
    local row = rows[1]
    if not row then return nil end
    if tonumber(row.expires_at) and tonumber(row.expires_at) <= nowUnix() then
        dbExec(acDB, "UPDATE ac_bans SET active = 0 WHERE id = ?", row.id)
        return nil
    end
    return row
end

local function localBan(p, reason)
    if not acDB then return false end
    local created = nowUnix()
    local expires = created + CFG.banSeconds
    dbExec(acDB,
        "INSERT INTO ac_bans (serial, player_name, reason, created_at, expires_at, active) VALUES (?, ?, ?, ?, ?, 1)",
        getPlayerSerial(p), getPlayerName(p), reason, created, expires)
    kickPlayer(p, "Stage AntiCheat", reason .. " | Ban: 10 dakika")
    return true
end

local function banForTenMinutes(p, reason)
    if not isElement(p) or isACAdmin(p) then return false end

    if adminResourceRunning() then
        local ok, result = pcall(function()
            return exports.stage_admin:AdminBanPlayer("StageAntiCheat", p, reason, CFG.banSeconds)
        end)
        if ok and result then return true end
    end

    return localBan(p, reason)
end

function grantMovementExemption(p, ms, reason)
    if not isElement(p) or getElementType(p) ~= "player" then return false end
    local s = getState(p)
    ms = math.max(1000, math.min(15000, tonumber(ms) or CFG.teleportExemptMs))
    s.exemptUntil = math.max(s.exemptUntil or 0, getTickCount() + ms)
    s.bad = 0
    s.air = 0
    s.lastPos = nil
    return true
end

local function inGraceOrExempt(p)
    local s = getState(p)
    local t = getTickCount()
    return t < (s.graceUntil or 0) or t < (s.exemptUntil or 0)
end

local function detect(p, key, label, info)
    if not isElement(p) then return end
    local s = getState(p)
    local now = getTickCount()

    if inGraceOrExempt(p) then return end

    if isACAdmin(p) then
        -- Adminlara mesaj/uyarı/ban yok. Sadece debug + panel log.
        outputDebugString(("[StageAC] STAFF BYPASS | %s | %s | %s"):format(getPlayerName(p), label, tostring(info or "")), 3)
        trackDetection(p, key, tostring(info or ""), "staff_bypass")
        return
    end

    local last = s.reasonCooldown[key] or 0
    if now - last < CFG.warningCooldown then return end
    s.reasonCooldown[key] = now

    s.warnings = s.warnings + 1
    s.risk = math.min(200, (s.risk or 0) + (riskPoints[key] or 20))
    s.lastWarn = now
    s.lastClean = now

    local shouldBan = s.warnings >= CFG.maxWarnings or s.risk >= 100
    local action = shouldBan and "ban_10m" or "warn"
    trackDetection(p, key, tostring(info or label), action)

    outputDebugString(("[StageAC] %s | %s | warning %d/%d | risk %d"):format(
        getPlayerName(p), label, s.warnings, CFG.maxWarnings, s.risk), 2)

    if shouldBan then
        local reason = ("AntiCheat: %s | risk %d | %d tespit"):format(label, s.risk, s.warnings)
        banForTenMinutes(p, reason)
        resetState(p)
        return
    end

    outputChatBox(("[AntiCheat] %s | Uyarı %d/%d."):format(label, s.warnings, CFG.maxWarnings),
        p, 255, 170, 0, false)
end

addEventHandler("onPlayerQuit", root, function()
    resetState(source)
    eventRate[source] = nil
    f1ExemptRate[source] = nil
end)

addEventHandler("onPlayerJoin", root, function()
    local p = source
    local s = getState(p)
    s.graceUntil = getTickCount() + CFG.joinGraceMs

    -- Sadece daha önce gerçekten banlanmış oyuncunun kalan süresini uygula.
    -- Yeni giriş yapan temiz oyuncu hareket analizi grace bittikten sonra başlar.
    local row = localActiveBan(getPlayerSerial(p))
    if row then
        local left = math.max(1, tonumber(row.expires_at) - nowUnix())
        kickPlayer(p, "Stage AntiCheat", ("Aktif AntiCheat banı. Kalan: %d sn | %s"):format(left, row.reason or ""))
    end
end)

addEventHandler("onPlayerSpawn", root, function()
    local s = getState(source)
    s.graceUntil = getTickCount() + CFG.spawnGraceMs
    s.lastPos = nil
end)

addEventHandler("onPlayerVehicleEnter", root, function()
    grantMovementExemption(source, 5000, "vehicle_enter")
end)
addEventHandler("onPlayerVehicleExit", root, function()
    grantMovementExemption(source, 5000, "vehicle_exit")
end)

-- F1 panelin client-side teleportu için kısa ve rate-limitli istisna.
addEvent("stageAC:f1Teleport", true)
addEventHandler("stageAC:f1Teleport", root, function()
    if not client or client ~= source then return end
    local now = getTickCount()
    local r = f1ExemptRate[client] or {window = now, count = 0}
    if now - r.window > 60000 then r.window = now; r.count = 0 end
    r.count = r.count + 1
    f1ExemptRate[client] = r
    if r.count <= 8 then
        grantMovementExemption(client, 3500, "f1_teleport")
    end
end)

addEvent("stageAC:serverTeleport", true)
addEventHandler("stageAC:serverTeleport", root, function(p)
    -- Geriye dönük uyumluluk. Sadece bu resource'un kendi server çağrısı geçerli.
    if source ~= resourceRoot or not isElement(p) then return end
    grantMovementExemption(p, CFG.teleportExemptMs, "server_teleport")
end)

addEvent("stageAC:getSettings", true)
addEventHandler("stageAC:getSettings", root, function()
    if not isACAdmin(client) then return end
    triggerClientEvent(client, "stageAC:settings", resourceRoot, settings)
end)

addEvent("stageAC:setSetting", true)
addEventHandler("stageAC:setSetting", root, function(key, value)
    if not isACAdmin(client) or settings[key] == nil then return end
    settings[key] = value == true
    saveSettings()
    triggerClientEvent(root, "stageAC:settings", resourceRoot, settings)
end)

local function speedOf(p)
    local v = getPedOccupiedVehicle(p)
    local e = v or p
    if not isElement(e) then return 0, false end
    local x, y, z = getElementVelocity(e)
    return math.sqrt(x*x + y*y + z*z) * 180, v ~= false and v ~= nil
end

local function distance(a, b)
    return math.sqrt((a[1]-b[1])^2 + (a[2]-b[2])^2 + (a[3]-b[3])^2)
end

setTimer(function()
    local now = getTickCount()
    for _, p in ipairs(getElementsByType("player")) do
        local s = getState(p)

        if isACAdmin(p) then
            -- Staff için hareket analizi tutmuyoruz; yanlış uyarı/ban tamamen engellendi.
            s.bad = 0
            s.air = 0
            s.lastPos = nil
        elseif not inGraceOrExempt(p) then
            local x, y, z = getElementPosition(p)
            local pos = {x, y, z}
            local vehicle = getPedOccupiedVehicle(p)
            local spd = speedOf(p)
            local dim, interior = getElementDimension(p), getElementInterior(p)

            if s.lastPos and (s.lastPos[4] ~= dim or s.lastPos[5] ~= interior) then
                s.lastPos = nil
                grantMovementExemption(p, 3500, "dimension_change")
            end

            if settings.speed and spd > (vehicle and CFG.vehicleSpeedKmh or CFG.playerSpeedKmh) then
                s.bad = s.bad + 1
                if s.bad >= CFG.consecutiveSamples then
                    detect(p, "speed", "Speed Hack", math.floor(spd) .. " km/h")
                    s.bad = 0
                end
            else
                s.bad = 0
            end

            if settings.teleport and s.lastPos and not vehicle and distance(pos, s.lastPos) > 80 then
                detect(p, "teleport", "Şüpheli Teleport", ("%.1f metre"):format(distance(pos, s.lastPos)))
            end

            if settings.fly and not vehicle and not isPedOnGround(p)
                and math.abs(z - (s.lastPos and s.lastPos[3] or z)) < 0.15 then
                s.air = s.air + 1
                if s.air >= CFG.flySamples then
                    detect(p, "fly", "Fly / Air Walk", "havada sabit")
                    s.air = 0
                end
            else
                s.air = 0
            end

            if settings.superjump and s.lastPos and not vehicle and isPedOnGround(p)
                and z - s.lastPos[3] > CFG.superJumpHeight then
                detect(p, "superjump", "Super Jump", ("dz=%.2f"):format(z - s.lastPos[3]))
            end

            if settings.vehicleFly and vehicle and not isVehicleOnGround(vehicle) then
                local _, _, vz = getElementVelocity(vehicle)
                if math.abs(vz) > 0.30 then
                    detect(p, "vehicleFly", "Vehicle Fly", ("vz=%.2f"):format(vz))
                end
            end

            if settings.health and getElementHealth(p) > CFG.healthTolerance then
                setElementHealth(p, CFG.healthTolerance)
                detect(p, "health", "Health Hack", tostring(getElementHealth(p)))
            end

            if settings.armor and getPedArmor(p) > CFG.armorTolerance then
                setPedArmor(p, CFG.armorTolerance)
                detect(p, "armor", "Armor Hack", tostring(getPedArmor(p)))
            end

            s.lastPos = {x, y, z, dim, interior}

            if s.warnings > 0 and now - s.lastClean > CFG.warningResetMs then
                s.warnings = math.max(0, s.warnings - 1)
                s.risk = math.max(0, (s.risk or 0) - 20)
                s.lastClean = now
            end
        else
            s.bad = 0
            s.air = 0
            s.lastPos = nil
        end
    end
end, CFG.checkInterval, 0)

addEventHandler("onPlayerDamage", root, function(attacker, weapon, bodypart, loss)
    if isACAdmin(source) then return end
    if settings.damage and tonumber(loss) and loss > CFG.maxDamage then
        cancelEvent()
        detect(source, "damage", "Anormal Damage", tostring(loss))
    end
end)

addEventHandler("onPlayerWeaponSwitch", root, function(prev, current)
    if isACAdmin(source) then return end
    if settings.illegalWeapon and not weapons[current] then
        takeWeapon(source, current)
        detect(source, "illegalWeapon", "Illegal Weapon", tostring(current))
    end
end)

addEventHandler("onPlayerWeaponFire", root, function(weapon)
    if isACAdmin(source) or not settings.rapidFire then return end
    local now = getTickCount()
    local r = eventRate[source] or {t = 0, n = 0}
    if now - r.t > 1000 then r.t = now; r.n = 0 end
    r.n = r.n + 1
    eventRate[source] = r
    if r.n > 18 then
        detect(source, "rapidFire", "Rapid Fire / Fire Spam", tostring(r.n) .. "/s")
        r.n = 0
    end
end)

addEventHandler("onResourceStart", resourceRoot, function()
    loadSettings()
    initBanDB()
    for _, p in ipairs(getElementsByType("player")) do
        local s = getState(p)
        s.graceUntil = getTickCount() + 15000
    end
    outputDebugString("[StageAC] AntiCheat v3 aktif. Staff bypass + 10dk risk ban + movement grace.", 3)
end)
