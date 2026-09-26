--[[
    stage_admin - client noclip / fly hareket
    Kamera bakış yönüne göre tam 3D hareket. Sadece görsel: gerçek yetki
    ve bypass flag'i server-side tutulur (server/actions.lua).
]]

local noClipActive = false
local flyActive = false
local baseSpeed = 1.1
local sprintMultiplier = 2.4

addEvent("admin:setNoClip", true)
addEventHandler("admin:setNoClip", localPlayer, function(state)
    noClipActive = state
    setElementCollisionsEnabled(localPlayer, not state)
    setElementAlpha(localPlayer, state and 180 or 255)
    toggleControl("jump", not state)
    toggleControl("fire", not state)
    if state then
        setElementVelocity(localPlayer, 0, 0, 0)
    end
end)

addEvent("admin:setFly", true)
addEventHandler("admin:setFly", localPlayer, function(state)
    flyActive = state
    if state then
        setElementVelocity(localPlayer, 0, 0, 0)
    end
end)

-- Kameranın gerçek bakış vektörünü döndürür (normalize edilmiş, 3D)
local function getCameraForwardVector()
    local cx, cy, cz, lx, ly, lz = getCameraMatrix()
    local dx, dy, dz = lx - cx, ly - cy, lz - cz
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len == 0 then return 0, 1, 0 end
    return dx/len, dy/len, dz/len
end

addEventHandler("onClientRender", root, function()
    if not noClipActive and not flyActive then return end
    if AdminUIOpen then return end
    if getElementHealth(localPlayer) <= 0 then return end
    if isChatBoxInputActive and isChatBoxInputActive() then return end

    local px, py, pz = getElementPosition(localPlayer)
    local fx, fy, fz = getCameraForwardVector()

    -- yatay strafe vektörü (forward'a dik, z=0 düzleminde)
    local rightX, rightY = fy, -fx
    local rlen = math.sqrt(rightX*rightX + rightY*rightY)
    if rlen > 0 then rightX, rightY = rightX/rlen, rightY/rlen end

    local moveForward, moveRight, moveUp = 0, 0, 0
    if getKeyState("w") then moveForward = moveForward + 1 end
    if getKeyState("s") then moveForward = moveForward - 1 end
    if getKeyState("d") then moveRight = moveRight + 1 end
    if getKeyState("a") then moveRight = moveRight - 1 end
    if getKeyState("space") then moveUp = moveUp + 1 end
    if getKeyState("lctrl") then moveUp = moveUp - 1 end

    if moveForward == 0 and moveRight == 0 and moveUp == 0 then
        if noClipActive then setElementVelocity(localPlayer, 0, 0, 0) end
        return
    end

    local speed = baseSpeed
    if getKeyState("lshift") then speed = speed * sprintMultiplier end

    local dx = (fx * moveForward + rightX * moveRight)
    local dy = (fy * moveForward + rightY * moveRight)
    local dz = (fz * moveForward) + moveUp * 0.8

    -- normalize et ki çapraz hareket daha hızlı olmasın
    local mlen = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mlen > 0 then dx, dy, dz = dx/mlen, dy/mlen, dz/mlen end

    if noClipActive then
        setElementPosition(localPlayer, px + dx * speed, py + dy * speed, pz + dz * speed)
        setElementVelocity(localPlayer, 0, 0, 0)
    elseif flyActive then
        setElementVelocity(localPlayer, dx * speed * 0.12, dy * speed * 0.12, dz * speed * 0.12)
    end
end)
