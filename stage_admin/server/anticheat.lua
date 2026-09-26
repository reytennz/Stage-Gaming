--[[
    stage_admin - Anti-Cheat v2.1
    False-positive azaltılmış hareket analizi + risk sistemi.
    Staff asla AC cezası/uyarısı yemez; tespit sadece loglanır.
]]

local detections = {}          -- [serial][module] = count
local riskScores = {}          -- [serial] = risk
local lastPosition = {}        -- [player] = {x,y,z,tick,dim,int}
local flyHoverTicks = {}       -- [player] = art arda şüpheli tick
local graceUntil = {}          -- [player] = tick
local movementExemptUntil = {} -- [player] = tick
local lastDetectionTick = {}   -- [player][module] = tick

local DETECTION_COOLDOWN = 7000
local JOIN_GRACE_MS = 45000
local MOVE_EXEMPT_MS = 6000
local AC_BAN_SECONDS = 10 * 60

local riskWeight = {
    speed = 20,
    fly = 35,
    teleport = 30,
    vehicle = 25,
    godmode = 45,
    weapon = 45,
    explosion = 30,
    eventAbuse = 30,
    resourceAbuse = 40,
}

local function nowTick()
    return getTickCount()
end

local function isBypassed(player, flag)
    local flags = AdminBypassFlags[player]
    return flags and flags[flag]
end

local function isGrace(player)
    local t = nowTick()
    return t < (graceUntil[player] or 0) or t < (movementExemptUntil[player] or 0)
end

function AdminACGrantMovementExemption(player, ms, reason)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    ms = math.max(1000, math.min(15000, tonumber(ms) or MOVE_EXEMPT_MS))
    movementExemptUntil[player] = math.max(movementExemptUntil[player] or 0, nowTick() + ms)
    lastPosition[player] = nil
    flyHoverTicks[player] = 0
    return true
end

local function moduleCooldown(player, moduleName)
    lastDetectionTick[player] = lastDetectionTick[player] or {}
    local t = nowTick()
    local prev = lastDetectionTick[player][moduleName] or 0
    if t - prev < DETECTION_COOLDOWN then return false end
    lastDetectionTick[player][moduleName] = t
    return true
end

local function sendDetectionToStaff(player, moduleName, info, count, action, risk)
    local chatMsg = ("%s -> %s | %s | risk:%d | aksiyon:%s"):format(
        getPlayerName(player), moduleName, info or "", risk or 0, action or "log")

    for _, p in ipairs(getElementsByType("player")) do
        if AdminHasPermission(p, "anticheat.view") then
            triggerClientEvent(p, "admin:acDetection", p, {
                player = getPlayerName(player), module = moduleName, info = info or "",
                count = count or 0, action = action or "log", risk = risk or 0,
            })
        end
        if AdminIsStaff(p) and action ~= "staff_bypass" then
            triggerClientEvent(p, "admin:chatMessage", p, "AntiCheat", chatMsg)
        end
    end
end

local function recordDetection(player, moduleName, info)
    if not isElement(player) or getElementType(player) ~= "player" then return end
    if isGrace(player) then return end
    if not moduleCooldown(player, moduleName) then return end

    -- Staff hareketleri raporlanır ama oyuncuya hiçbir warning/kick/ban uygulanmaz.
    if AdminIsStaff(player) then
        AdminLog("AntiCheat", getPlayerName(player), "ac_staff_bypass_" .. moduleName, info or "")
        if type(AdminTrackACDetection) == "function" then
            AdminTrackACDetection(player, moduleName, info or "", 0, "staff_bypass")
        end
        sendDetectionToStaff(player, moduleName, info, 0, "staff_bypass", 0)
        return
    end

    local serial = getPlayerSerial(player)
    detections[serial] = detections[serial] or {}
    detections[serial][moduleName] = (detections[serial][moduleName] or 0) + 1
    local count = detections[serial][moduleName]

    local addedRisk = riskWeight[moduleName] or 15
    riskScores[serial] = math.min(200, (riskScores[serial] or 0) + addedRisk)
    local risk = riskScores[serial]

    local baseAction = Config.AntiCheatAction[moduleName] or "log"
    local threshold = Config.AntiCheatEscalation[moduleName] or 0
    local action = baseAction

    -- İstenen davranış: aynı ciddi modül 5 kez yakalanırsa 10 dk ban.
    if (threshold > 0 and count >= threshold) or risk >= 100 then
        action = "ban"
    end

    AdminLog("AntiCheat", getPlayerName(player), "ac_" .. moduleName,
        (info or "") .. " (#" .. count .. ", risk=" .. risk .. ")")

    if type(AdminTrackACDetection) == "function" then
        AdminTrackACDetection(player, moduleName, info or "", risk, action)
    end
    sendDetectionToStaff(player, moduleName, info, count, action, risk)

    if action == "warn" then
        AdminWarnPlayer("AntiCheat", player,
            ("Şüpheli aktivite: %s (%d/%d)"):format(moduleName, count, threshold > 0 and threshold or 5))
    elseif action == "kick" then
        AdminKick("AntiCheat", player, "Şüpheli aktivite: " .. moduleName)
    elseif action == "ban" then
        -- stage_admin kendi serial tablosuna yazar, reconnect sırasında kalan süreyi uygular.
        AdminBanPlayer("AntiCheat", player,
            ("AntiCheat: %s | risk %d"):format(moduleName, risk), AC_BAN_SECONDS)
        detections[serial] = nil
        riskScores[serial] = nil
    end
end

local function startGrace(player, ms)
    if not isElement(player) then return end
    graceUntil[player] = nowTick() + (ms or JOIN_GRACE_MS)
    lastPosition[player] = nil
    flyHoverTicks[player] = 0
end

addEventHandler("onPlayerJoin", root, function() startGrace(source, JOIN_GRACE_MS) end)
addEventHandler("onPlayerSpawn", root, function() startGrace(source, 12000) end)
addEventHandler("onPlayerWasted", root, function()
    lastPosition[source] = nil
    startGrace(source, 8000)
end)
addEventHandler("onPlayerVehicleEnter", root, function() AdminACGrantMovementExemption(source, 5000, "vehicle_enter") end)
addEventHandler("onPlayerVehicleExit", root, function() AdminACGrantMovementExemption(source, 5000, "vehicle_exit") end)
addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    lastPosition[source] = nil
    flyHoverTicks[source] = nil
    graceUntil[source] = nil
    movementExemptUntil[source] = nil
    lastDetectionTick[source] = nil
    detections[serial] = nil
    riskScores[serial] = nil
end)

-- Resource restart sırasında zaten online olanları koru.
addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        startGrace(player, 15000)
    end
end)

-- ---------------- Hareket / Speed / Teleport ----------------
setTimer(function()
    if not (Config.AntiCheat.speed or Config.AntiCheat.teleport) then return end

    for _, player in ipairs(getElementsByType("player")) do
        if getElementHealth(player) > 0 and not isBypassed(player, "fly") and not isBypassed(player, "noclip") then
            if isGrace(player) then
                lastPosition[player] = nil
            else
                local x, y, z = getElementPosition(player)
                local now = nowTick()
                local dim, interior = getElementDimension(player), getElementInterior(player)
                local prev = lastPosition[player]

                if prev then
                    local contextChanged = prev.dim ~= dim or prev.int ~= interior
                    local dt = (now - prev.tick) / 1000
                    if not contextChanged and dt > 0.25 and dt < 2.5 then
                        local dist = getDistanceBetweenPoints3D(x, y, z, prev.x, prev.y, prev.z)
                        local speed = dist / dt
                        local vehicle = getPedOccupiedVehicle(player)
                        local isFalling = (z - prev.z) < -3

                        if Config.AntiCheat.teleport and not vehicle
                            and dist > (Config.AntiCheatTolerance.teleportDistance or 60) then
                            recordDetection(player, "teleport", ("%.1fm / %.2fs"):format(dist, dt))
                        elseif Config.AntiCheat.speed and not isFalling then
                            local maxSpeed = vehicle and 70 or 13 -- m/s referans
                            if speed > maxSpeed * (Config.AntiCheatTolerance.speedMultiplier or 1.35) then
                                recordDetection(player, "speed", ("%.1f m/s"):format(speed))
                            end
                        end
                    end
                end

                lastPosition[player] = { x = x, y = y, z = z, tick = now, dim = dim, int = interior }
            end
        else
            lastPosition[player] = nil
        end
    end
end, 1000, 0)

-- ---------------- Fly ----------------
setTimer(function()
    if not Config.AntiCheat.fly then return end
    for _, player in ipairs(getElementsByType("player")) do
        if not isGrace(player) and not AdminIsStaff(player)
            and not isBypassed(player, "fly") and not isBypassed(player, "noclip")
            and getElementHealth(player) > 0 and not getPedOccupiedVehicle(player) then

            local _, _, vz = getElementVelocity(player)
            local _, _, z = getElementPosition(player)
            if vz > -0.025 and vz < 0.025 and not isPedOnGround(player) then
                flyHoverTicks[player] = (flyHoverTicks[player] or 0) + 1
                if flyHoverTicks[player] >= 6 then
                    recordDetection(player, "fly", ("havada sabit, z=%.1f"):format(z))
                    flyHoverTicks[player] = 0
                end
            else
                flyHoverTicks[player] = 0
            end
        else
            flyHoverTicks[player] = 0
        end
    end
end, 1000, 0)

AdminACEventTrigger = function(player, eventName)
    if not Config.AntiCheat.eventAbuse then return end
    recordDetection(player, "eventAbuse", eventName)
end

function AdminGetDetectionStats()
    local out = {}
    for _, player in ipairs(getElementsByType("player")) do
        local serial = getPlayerSerial(player)
        if detections[serial] then
            out[#out + 1] = {
                player = getPlayerName(player),
                counts = detections[serial],
                risk = riskScores[serial] or 0,
            }
        end
    end
    return out
end
