-- Stage HUD System v4.1
-- HUD 1: STAGE ust bar | HUD 2: Infinity | HUD 3: FiveHUD (duzeltilmis)
-- Speedo 1: Decro | Speedo 2: Hiigor (attigin digeri)
-- Ayarlar: font (bold/thin), isim alti can bari, crosshair

local sw, sh = guiGetScreenSize()
local px = sw / 1920
local py = sh / 1080

-- prefs (client.lua da set eder)
fontStyle = fontStyle or 1
healthMode = healthMode or 1
nameBarOn = healthMode ~= 3
crosshairOn = crosshairOn or false
crosshairSize = crosshairSize or 8
crosshairStyle = crosshairStyle or 1 -- 1 cross, 2 dot, 3 circle

local fPoppins, fPoppinsB, fBebas, fBebasSm
local fAeroBold, fAeroBig, fAeroMed
local fFive1, fFive2
local fInter, fInterB, fInterSm

addEventHandler("onClientResourceStart", resourceRoot, function()
    fPoppins  = dxCreateFont("assets/hud/fonts/Poppins-Regular.ttf", 15) or "default"
    fPoppinsB = dxCreateFont("assets/hud/fonts/Poppins-Bold.ttf", 18) or "default-bold"
    fBebas    = dxCreateFont("assets/hud/fonts/BebasNeue-Regular.ttf", 22) or "default-bold"
    fBebasSm  = dxCreateFont("assets/hud/fonts/BebasNeue-Regular.ttf", 8) or "default"
    fAeroBold = dxCreateFont("assets/hud/speedo/AEROMATICSBOLD.ttf", 17 * px) or "default-bold"
    fAeroBig  = dxCreateFont("assets/hud/speedo/AEROMATICSITALIC.ttf", 50 * px) or "default-bold"
    fAeroMed  = dxCreateFont("assets/hud/speedo/AEROMATICSITALIC.ttf", 18 * px) or "default"
    fFive1    = dxCreateFont("assets/hud/five/font1.ttf", 14) or "default"
    fFive2    = dxCreateFont("assets/hud/five/font2.ttf", 12) or "default"
    fInter    = dxCreateFont("assets/hud/speedo2/fonts/Inter-Regular.ttf", 11) or "default"
    fInterB   = dxCreateFont("assets/hud/speedo2/fonts/Inter-SemiBold.ttf", 22) or "default-bold"
    fInterSm  = dxCreateFont("assets/hud/speedo2/fonts/Inter-Regular.ttf", 8) or "default"
    setPlayerHudComponentVisible("all", false)
end)

local function nameFont()
    if fontStyle == 2 then return fPoppins end
    if fontStyle == 3 then return fAeroMed or "default" end
    if fontStyle == 4 then return fBebas or "default-bold" end
    if fontStyle == 5 then return "default-bold" end
    return fPoppinsB
end

local function bodyFont()
    if fontStyle == 2 then return fPoppins end
    if fontStyle == 3 then return fAeroMed or "default" end
    if fontStyle == 4 then return fBebasSm or "default" end
    if fontStyle == 5 then return "default" end
    return fPoppinsB
end

local function wantsHealthBar()
    return (tonumber(healthMode) or 1) ~= 3
end

local function wantsHealthText()
    return (tonumber(healthMode) or 1) ~= 2
end

local function formatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local s = tostring(amount)
    local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if r:sub(1,1) == "," then r = r:sub(2) end
    return r
end

local function getSpeedKmh(veh)
    if not isElement(veh) then return 0 end
    local vx, vy, vz = getElementVelocity(veh)
    return math.floor(math.sqrt(vx*vx + vy*vy + vz*vz) * 180)
end

local function silahisimDonus(id)
    local map = {
        [0]="Yumruk",[1]="Musta",[4]="Bicak",[22]="Colt-45",[23]="Silenced",[24]="Deagle",
        [25]="Shotgun",[28]="Uzi",[29]="MP5",[30]="AK",[31]="M4",[32]="Tec-9",[33]="Rifle",[34]="Sniper"
    }
    return map[id] or "Silah"
end

function hou_circle(x, y, w, h, color, startAngle, endAngle, width)
    width = width or 2
    local cx, cy, rx, ry = x, y, w/2, h/2
    local steps = math.max(10, math.floor(math.abs(endAngle - startAngle) / 2.5))
    local prevX, prevY
    for i = 0, steps do
        local a = math.rad(startAngle + (endAngle - startAngle) * (i / steps))
        local px2 = cx + math.cos(a) * rx
        local py2 = cy + math.sin(a) * ry
        if prevX then dxDrawLine(prevX, prevY, px2, py2, color, width) end
        prevX, prevY = px2, py2
    end
end

-- ========== HUD 1: STAGE ust bar ==========
function drawHudSRP()
    local rtx, rty = sw - 95, 20
    local time = getRealTime()
    local hour = string.format("%02d", time.hour)
    local minute = string.format("%02d", time.minute)
    local dateText = string.format("%02d.%02d", time.monthday, time.month + 1)
    local charName = tostring(getElementData(localPlayer, "stage:char") or getPlayerName(localPlayer))
    local pid = getElementData(localPlayer, "playerid") or getElementData(localPlayer, "stage:id") or 0
    local hp = math.floor(getElementHealth(localPlayer) or 100)

    if fileExists("assets/hud/image/siyah.png") then
        dxDrawImage(rtx - 1825, rty - 20, 1920, 200, "assets/hud/image/siyah.png", 0, 0, 0, tocolor(255,255,255,150))
    end
    -- HUD 1: FIVE yazısı kaldırıldı, yerine Para & Banka bilgisi eklendi
    local myCash = math.floor(tonumber(getPlayerMoney(localPlayer) or 0) or 0)
    local myBank = tonumber(getElementData(localPlayer, "bankmoney")) or tonumber(getElementData(localPlayer, "stage:bankmoney")) or 0
    dxDrawText("$" .. formatMoney(myCash), rtx - 15, rty + 4, rtx + 85, rty + 22,
        tocolor(61, 214, 140, 245), 1.0, bodyFont(), "right", "center")
    dxDrawText("$" .. formatMoney(myBank), rtx - 15, rty + 22, rtx + 85, rty + 40,
        tocolor(113, 206, 249, 245), 0.95, bodyFont(), "right", "center")
    dxDrawRectangle(rtx - 20, rty + 16, 2, 45, tocolor(255,255,255,100))
    dxDrawText(hour .. ":" .. minute, rtx - 100, rty + 40, nil, nil, tocolor(255,255,255), 1, bodyFont())
    dxDrawText(dateText, rtx - 160, rty + 40, nil, nil, tocolor(255,255,255), 1, bodyFont())
    dxDrawText("STAGE GAMING", rtx - 35, rty + 15, nil, nil, tocolor(255,255,255), 1, bodyFont(), "right")
    dxDrawText("ID", rtx - 200, rty + 15, nil, nil, tocolor(255,255,255,200), 1, bodyFont(), "right")
    dxDrawText(tostring(pid), rtx - 208, rty + 40, nil, nil, tocolor(255,255,255), 1, bodyFont(), "center")
    dxDrawText("KARAKTER ADI", rtx - 250, rty + 15, nil, nil, tocolor(255,255,255,200), 1, bodyFont(), "right")
    dxDrawText(charName, rtx - 303, rty + 40, nil, nil, tocolor(255,255,255), 1, nameFont(), "center")

    if wantsHealthBar() then
        local barW, barH = 140, 6
        local bx = rtx - 303 - 20
        local by = rty + 62
        dxDrawRectangle(bx, by, barW, barH, tocolor(40, 40, 50, 200))
        dxDrawRectangle(bx, by, barW * (hp / 100), barH, tocolor(130, 55, 200, 255))
    end
    if wantsHealthText() then
        local barW = 140
        local bx = rtx - 303 - 20
        local by = rty + 62
        dxDrawText("Can  " .. hp .. "%", bx, by + 8, bx + barW, by + 22, tocolor(220, 210, 240, 230), 1, fBebasSm, "left", "top")
    end

    dxDrawText(silahisimDonus(getPedWeapon(localPlayer)), rtx + 77, rty + 110, nil, nil, tocolor(200,200,200), 1, bodyFont(), "right")
    dxDrawText(getPedAmmoInClip(localPlayer, getPedWeaponSlot(localPlayer)) .. "  |  " .. getPedTotalAmmo(localPlayer), rtx + 75, rty + 135, nil, nil, tocolor(255,255,255), 1, bodyFont(), "right")
end

-- ========== HUD 2: Infinity ==========
function drawHudInfinity()
    local w, h = 325, 175
    local x, y = sw - w - 15, 15
    if dxDrawRoundedRectangle then
        dxDrawRoundedRectangle(1, x, y, w, 75, 10, tocolor(25, 25, 25))
    else
        dxDrawRectangle(x, y, w, 75, tocolor(25, 25, 25, 230))
    end
    if fileExists("assets/hud/img/infinity.png") then
        dxDrawImage(x + 60, y, 50, 50, "assets/hud/img/infinity.png")
    end
    dxDrawText("STAGE GAMING", x + 40, y + 45, nil, nil, tocolor(129, 130, 135), 1, bodyFont())
    dxDrawText("stage", x + 55, y + 57, nil, nil, tocolor(129, 130, 135), 1, bodyFont())

    if dxDrawRoundedRectangle then
        dxDrawRoundedRectangle(2, x + 190, y + 5, 30, 30, 5, tocolor(25, 25, 25))
        dxDrawRoundedRectangle(3, x + 190, y + 40, 30, 30, 5, tocolor(25, 25, 25))
    end
    if fileExists("assets/hud/img/player.png") then
        local r,g,b = 113, 206, 249
        if hex2rgb then r,g,b = hex2rgb("#71cef9") end
        dxDrawImage(x + 195, y + 10, 20, 20, "assets/hud/img/player.png", 0, 0, 0, tocolor(r,g,b))
    end
    dxDrawText("Aktif Oyuncu", x + 225, y + 7.5, nil, nil, tocolor(129, 130, 135), 1, bodyFont())
    dxDrawText(#getElementsByType("player"), x + 225, y + 20, nil, nil, tocolor(255, 255, 255), 1, nameFont())

    if fileExists("assets/hud/img/clock.png") then
        local r,g,b = 113, 206, 249
        if hex2rgb then r,g,b = hex2rgb("#71cef9") end
        dxDrawImage(x + 195, y + 45, 20, 20, "assets/hud/img/clock.png", 0, 0, 0, tocolor(r,g,b))
    end
    local time = getRealTime()
    dxDrawText("Saat", x + 225, y + 42, nil, nil, tocolor(129, 130, 135), 1, bodyFont())
    dxDrawText(string.format("%02d:%02d", time.hour, time.minute), x + 225, y + 56, nil, nil, tocolor(255, 255, 255), 1, nameFont())

    if drawRoundedGradientRectangle and hex2rgb then
        drawRoundedGradientRectangle(x, y + 85, 157.5, 50, {
            radius = 5, offset = { x = 0, y = 100 },
            color = { color1 = { hex2rgb("#71cef9") }, color2 = { 16, 16, 16 } },
            rotation = 10,
        }, 125, false)
        drawRoundedGradientRectangle(x + 167.5, y + 85, 157.5, 50, {
            radius = 5, offset = { x = 0, y = 100 },
            color = { color1 = { hex2rgb("#71cef9") }, color2 = { 16, 16, 16 } },
            rotation = 10,
        }, 125, false)
    else
        dxDrawRectangle(x, y + 85, 157.5, 50, tocolor(20, 35, 50, 220))
        dxDrawRectangle(x + 167.5, y + 85, 157.5, 50, tocolor(20, 35, 50, 220))
    end
    if fileExists("assets/hud/img/money.png") then
        local r,g,b = 113, 206, 249
        if hex2rgb then r,g,b = hex2rgb("#71cef9") end
        dxDrawImage(x + 12.5, y + 97.5, 25, 25, "assets/hud/img/money.png", 0, 0, 0, tocolor(r,g,b))
    end
    dxDrawText("Nakit", x + 43, y + 97.5, nil, nil, tocolor(129, 130, 135), 1, bodyFont())
    dxDrawText("$" .. formatMoney(getPlayerMoney(localPlayer) or 0), x + 43, y + 110, nil, nil, tocolor(159, 160, 165), 1, nameFont())
    if fileExists("assets/hud/img/bankmoney.png") then
        local r,g,b = 113, 206, 249
        if hex2rgb then r,g,b = hex2rgb("#71cef9") end
        dxDrawImage(x + 180, y + 97.5, 25, 25, "assets/hud/img/bankmoney.png", 0, 0, 0, tocolor(r,g,b))
    end
    dxDrawText("Banka", x + 210, y + 97.5, nil, nil, tocolor(129, 130, 135), 1, bodyFont())
    dxDrawText("$" .. formatMoney(getElementData(localPlayer, "bankmoney") or 0), x + 210, y + 110, nil, nil, tocolor(179, 180, 185), 1, nameFont())

    if wantsHealthBar() then
        local hp = math.floor(getElementHealth(localPlayer) or 100)
        local bx, by, barW, barH = x, y + 145, w, 8
        dxDrawRectangle(bx, by, barW, barH, tocolor(40, 40, 50, 200))
        dxDrawRectangle(bx, by, barW * (hp / 100), barH, tocolor(113, 206, 249, 255))
    end
    if wantsHealthText() then
        local hp = math.floor(getElementHealth(localPlayer) or 100)
        local bx, by, barW = x, y + 145, w
        dxDrawText("Can " .. hp .. "%", bx, by + 10, bx + barW, by + 24, tocolor(200, 220, 240, 230), 1, fBebasSm, "left", "top")
    end
end

-- ========== HUD 3: FiveHUD - yeni buyuk tasarim ==========
function drawHudFive()
    -- Referans tasarim: buyuk, sag ustte, iki parcali modern panel.
    -- Ortadaki eski para HUD'u burada KULLANILMAZ.
    local scale = math.max(0.86, math.min(1.15, sw / 1920))
    local panelW, panelH = 500 * scale, 154 * scale
    local x, y = sw - panelW - (28 * scale), 28 * scale

    local cash = math.floor(tonumber(getPlayerMoney(localPlayer) or 0) or 0)
    local bank = tonumber(getElementData(localPlayer, "bankmoney"))
        or tonumber(getElementData(localPlayer, "bankMoney"))
        or tonumber(getElementData(localPlayer, "stage:bankmoney"))
        or tonumber(getElementData(localPlayer, "stage:bank"))
        or tonumber(getElementData(localPlayer, "bank")) or 0
    bank = math.max(0, math.floor(bank))

    local hp = math.max(0, math.min(100, tonumber(getElementHealth(localPlayer) or 100) or 100))
    local armor = math.max(0, math.min(100, tonumber(getPedArmor(localPlayer) or 0) or 0))

    local bg = tocolor(7, 10, 13, 242)
    local bg2 = tocolor(13, 16, 21, 248)
    local yellow = tocolor(245, 196, 20, 255)
    local blue = tocolor(31, 151, 231, 255)
    local white = tocolor(242, 244, 247, 255)
    local muted = tocolor(165, 170, 178, 235)

    -- Ana ust panel
    dxDrawRoundedRectangle(9001, x, y, panelW, 94 * scale, 13 * scale, bg)

    -- Sol wallet ikonu / ayirici
    if fileExists("assets/hud/i_wallet.png") then
        dxDrawImage(x + 20 * scale, y + 17 * scale, 38 * scale, 38 * scale,
            "assets/hud/i_wallet.png", 0, 0, 0, yellow)
    end
    dxDrawRectangle(x + 72 * scale, y + 17 * scale, 2 * scale, 37 * scale, tocolor(75, 78, 84, 160))

    -- Ortadaki R markasi
    dxDrawText("R", x + panelW * 0.45, y + 5 * scale, x + panelW * 0.55, y + 55 * scale,
        white, 1.8 * scale, fAeroBig or fBebas or "default-bold", "center", "center")

    -- Sag su/durum ikonu
    if fileExists("assets/hud/icon_water.png") then
        dxDrawImage(x + panelW - 58 * scale, y + 15 * scale, 35 * scale, 35 * scale,
            "assets/hud/icon_water.png", 0, 0, 0, blue)
    else
        dxDrawText("●", x + panelW - 58 * scale, y + 14 * scale, x + panelW - 20 * scale, y + 48 * scale,
            blue, 1.2 * scale, "default-bold", "center", "center")
    end

    -- Can / armor progress barlari
    local barY = y + 66 * scale
    local barH = 10 * scale
    local gap = 16 * scale
    local barW = (panelW - 42 * scale - gap) / 2
    local leftX = x + 21 * scale
    local rightX = leftX + barW + gap

    dxDrawRoundedRectangle(9002, leftX, barY, barW, barH, 5 * scale, tocolor(48, 50, 54, 220))
    dxDrawRoundedRectangle(9003, leftX, barY, barW * (hp / 100), barH, 5 * scale, yellow)
    dxDrawRoundedRectangle(9004, rightX, barY, barW, barH, 5 * scale, tocolor(18, 62, 84, 230))
    dxDrawRoundedRectangle(9005, rightX, barY, barW * (armor / 100), barH, 5 * scale, blue)

    -- Alt para kutulari
    local boxY = y + 102 * scale
    local boxGap = 3 * scale
    local boxW = (panelW - boxGap) / 2
    local boxH = 52 * scale

    dxDrawRoundedRectangle(9006, x, boxY, boxW, boxH, 11 * scale, bg2)
    dxDrawRoundedRectangle(9007, x + boxW + boxGap, boxY, boxW, boxH, 11 * scale, bg2)

    -- Nakit
    if fileExists("assets/hud/img/money.png") then
        dxDrawImage(x + 17 * scale, boxY + 13 * scale, 25 * scale, 25 * scale,
            "assets/hud/img/money.png", 0, 0, 0, yellow)
    end
    dxDrawText("$ " .. formatMoney(cash), x + 51 * scale, boxY + 4 * scale,
        x + boxW - 12 * scale, boxY + boxH - 4 * scale,
        white, 0.95 * scale, fPoppinsB or nameFont(), "left", "center", true)

    -- Banka
    if fileExists("assets/hud/img/bankmoney.png") then
        dxDrawImage(x + boxW + boxGap + 17 * scale, boxY + 13 * scale, 25 * scale, 25 * scale,
            "assets/hud/img/bankmoney.png", 0, 0, 0, blue)
    end
    dxDrawText("$ " .. formatMoney(bank), x + boxW + boxGap + 51 * scale, boxY + 4 * scale,
        x + panelW - 12 * scale, boxY + boxH - 4 * scale,
        white, 0.95 * scale, fPoppinsB or nameFont(), "left", "center", true)
end

-- ========== SPEEDO 1: Decro ==========
function getVehicleRPM(vehicle)
    if not vehicle then return 0 end
    if getVehicleEngineState(vehicle) ~= true then return 0 end
    local speed = getSpeedKmh(vehicle)
    local gear = getVehicleCurrentGear(vehicle)
    local rpm
    if gear > 0 then rpm = math.floor((speed / gear) * 180 + 0.5)
    else rpm = math.floor(speed * 180 + 0.5) end
    if rpm < 650 then rpm = math.random(650, 750)
    elseif rpm >= 9800 then rpm = math.random(9800, 9900) end
    return rpm
end

function drawSpeedoDecro()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end
    local sizeX, sizeY = 350 * px, 350 * px
    local posX, posY = sw - sizeX, sh - sizeY
    local kmh = getSpeedKmh(veh)
    local rotation = math.floor((270 / 9800) * getVehicleRPM(veh) + 0.5)
    if rotation >= 180 then rotation = math.random(179, 200) end
    local cfuel = math.ceil(tonumber(getElementData(veh, "fuel") or getElementData(veh, "stage:fuel") or 50) or 50)
    local mfuel = tonumber(getElementData(veh, "maxFuel")) or 100
    local fuelRatio = math.min(1, math.max(0, cfuel / mfuel))
    local gear = getVehicleCurrentGear(veh)
    if gear == 0 then gear = (kmh <= 1) and "N" or "R"
    elseif gear == 1 and kmh <= 2 then gear = "N" end

    if fileExists("assets/hud/speedo/Spedo.png") then
        dxDrawImage(posX, posY, sizeX, sizeY, "assets/hud/speedo/Spedo.png", 0, 0, 0, tocolor(255,255,255,255))
    end
    if fileExists("assets/hud/speedo/strelkaspedo.png") then
        dxDrawImage(posX, posY, sizeX, sizeY, "assets/hud/speedo/strelkaspedo.png", rotation - 35, 0, 0, tocolor(255,255,255,255))
    end
    if fileExists("assets/hud/speedo/krug.png") then
        dxDrawImage(posX, posY, sizeX, sizeY, "assets/hud/speedo/krug.png")
    end
    if fileExists("assets/hud/speedo/benz.png") then
        dxDrawImage(posX + 40 * px, posY + 200 * px, 80 * px, 80 * px, "assets/hud/speedo/benz.png", 0, 0, 0, tocolor(255,255,255,200))
    end
    if fileExists("assets/hud/speedo/strelkabenz.png") then
        local benzRot = -125 + fuelRatio * 145
        dxDrawImage(posX + 40 * px, posY + 200 * px, 80 * px, 80 * px, "assets/hud/speedo/strelkabenz.png", benzRot, 0, 0, tocolor(255,255,255,255))
    end
    dxDrawText(tostring(gear), posX + 5 * px, posY - 2 * px, posX + sizeX, posY + sizeY, tocolor(0,255,255), 1, fAeroBold, "center", "center")
    dxDrawText(tostring(kmh), posX + 60 * px, posY + 250 * px, posX + sizeX, posY + 250 * px, tocolor(255,255,255), 1, fAeroBig, "center", "center")

    if fileExists("assets/hud/speedo/engine.png") then
        local col = getVehicleEngineState(veh) and tocolor(0,255,0) or tocolor(255,255,255)
        dxDrawImage(posX - 100 * px, posY - 140 * px, 512 * px, 512 * px, "assets/hud/speedo/engine.png", 0, 0, 0, col)
    end
    if fileExists("assets/hud/speedo/light.png") then
        local col = (getVehicleOverrideLights(veh) == 2) and tocolor(0,255,0) or tocolor(255,255,255)
        dxDrawImage(posX - 60 * px, posY - 140 * px, 512 * px, 512 * px, "assets/hud/speedo/light.png", 0, 0, 0, col)
    end
    if fileExists("assets/hud/speedo/lock.png") then
        local col = isVehicleLocked(veh) and tocolor(200,0,0) or tocolor(0,255,0)
        dxDrawImage(posX - 20 * px, posY - 120 * px, 512 * px, 512 * px, "assets/hud/speedo/lock.png", 0, 0, 0, col)
    end
end

-- ========== SPEEDO 2: Hiigor tarz (attigin digeri) ==========
function drawSpeedoHiigor()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    local cx = sw - 160 * px
    local cy = sh - 140 * py
    local size = 130 * px
    local kmh = getSpeedKmh(veh)
    local maxV = 200
    local handling = getVehicleHandling(veh)
    if handling and handling.maxVelocity then maxV = math.max(50, handling.maxVelocity) end
    local ratio = math.min(1, kmh / maxV)
    local fuel = tonumber(getElementData(veh, "fuel") or getElementData(veh, "stage:fuel") or 100) or 100
    local col = {158, 105, 244}

    -- arka daire
    if fileExists("assets/hud/speedo2/base-circle.png") then
        dxDrawImage(cx - size / 2, cy - size / 2, size, size, "assets/hud/speedo2/base-circle.png", 0, 0, 0, tocolor(255,255,255,230))
    else
        dxDrawRectangle(cx - size / 2, cy - size / 2, size, size, tocolor(20, 20, 28, 200))
    end

    -- progress yay
    hou_circle(cx, cy, size - 8, size - 8, tocolor(80, 80, 90, 200), 120, 420, 5)
    hou_circle(cx, cy, size - 8, size - 8, tocolor(col[1], col[2], col[3], 255), 120, 120 + ratio * 300, 5)

    -- hiz yazisi
    dxDrawText(string.format("%03d", kmh), cx - 40, cy - 22, cx + 40, cy + 18, tocolor(255,255,255,255), 1, fInterB or fBebas, "center", "center")
    dxDrawText("km/h", cx - 30, cy + 16, cx + 30, cy + 32, tocolor(200,200,210,220), 1, fInterSm or fBebasSm, "center", "center")

    -- ikonlar alt satir
    local iy = cy + size / 2 + 8
    local icons = {
        {"assets/hud/speedo2/belt.png", 10, 12},
        {"assets/hud/speedo2/engine.png", 14, 13},
        {"assets/hud/speedo2/light_vehicle.png", 12, 9},
        {"assets/hud/speedo2/door.png", 10, 9},
        {"assets/hud/speedo2/gas.png", 9, 10},
    }
    local totalW = #icons * 28
    local ix = cx - totalW / 2
    for i, ic in ipairs(icons) do
        local path, iw, ih = ic[1], ic[2] * px * 1.2, ic[3] * px * 1.2
        local colI = tocolor(245, 255, 250, 220)
        if i == 3 and getVehicleOverrideLights(veh) == 2 then colI = tocolor(0, 255, 120, 255) end
        if i == 4 and isVehicleLocked(veh) then colI = tocolor(255, 60, 60, 255) end
        if i == 2 and getVehicleEngineState(veh) then colI = tocolor(0, 255, 120, 255) end
        if fileExists(path) then
            dxDrawImage(ix + (i - 1) * 28, iy, iw + 4, ih + 4, path, 0, 0, 0, colI)
        end
    end
    dxDrawText(math.floor(fuel) .. "%", cx - 20, iy + 18, cx + 20, iy + 32, tocolor(245,255,250,230), 1, fInterSm or fBebasSm, "center", "center")
end

function drawSpeedoStageDigital()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    local w, h = 255 * px, 94 * py
    local x, y = sw - w - 32 * px, sh - h - 38 * py
    local kmh = getSpeedKmh(veh)
    local hp = math.max(0, math.min(100, (getElementHealth(veh) or 1000) / 10))
    local fuel = tonumber(getElementData(veh, "fuel") or getElementData(veh, "stage:fuel") or 100) or 100

    dxDrawRectangle(x, y, w, h, tocolor(7, 13, 19, 185))
    dxDrawRectangle(x, y, 4 * px, h, tocolor(39, 214, 198, 235))
    dxDrawText(string.format("%03d", kmh), x + 18 * px, y + 8 * py, x + 140 * px, y + 58 * py, tocolor(255,255,255,245), 1, fInterB or nameFont(), "left", "center")
    dxDrawText("KM/H", x + 126 * px, y + 24 * py, x + 196 * px, y + 50 * py, tocolor(39,214,198,230), 1, fInter or bodyFont(), "left", "center")
    dxDrawText("FUEL " .. math.floor(fuel) .. "%", x + 20 * px, y + 62 * py, x + 118 * px, y + 82 * py, tocolor(245, 198, 76, 230), 1, fInterSm or bodyFont(), "left", "center")
    dxDrawText("ENGINE " .. math.floor(hp) .. "%", x + 126 * px, y + 62 * py, x + w - 14 * px, y + 82 * py, tocolor(210, 226, 232, 225), 1, fInterSm or bodyFont(), "left", "center")
end

-- ========== CROSSHAIR ==========
function drawCrosshair()
    if not crosshairOn then return end
    if isPedInVehicle(localPlayer) then return end
    local weapon = getPedWeapon(localPlayer)
    if not weapon or weapon <= 0 then return end
    if not getPedControlState("aim_weapon") then return end
    local cx, cy = sw / 2, sh / 2
    local s = tonumber(crosshairSize) or 8
    local col = tocolor(255, 255, 255, 220)
    local style = tonumber(crosshairStyle) or 1
    if style == 1 then
        -- cross
        dxDrawRectangle(cx - s, cy - 1, s * 2, 2, col)
        dxDrawRectangle(cx - 1, cy - s, 2, s * 2, col)
        dxDrawRectangle(cx - 2, cy - 2, 4, 4, tocolor(0,0,0,120))
    elseif style == 2 then
        -- dot
        dxDrawRectangle(cx - s / 2, cy - s / 2, s, s, col)
    else
        -- circle
        hou_circle(cx, cy, s * 2, s * 2, col, 0, 360, 2)
    end
end


-- ========== ANA RENDER ==========
addEventHandler("onClientRender", root, function()
    if not stageInGame then return end
    if menuOpen or cinematicActive then return end
    if getElementData(localPlayer, "hudkapa") then return end

    local hs = tonumber(hudStyle) or 1
    local ss = tonumber(speedoStyle) or 1

    if hs == 1 then
        drawHudSRP()
    elseif hs == 2 then
        drawHudInfinity()
    else
        drawHudFive()
    end

    if ss == 1 then
        drawSpeedoDecro()
    elseif ss == 2 then
        drawSpeedoHiigor()
    else
        drawSpeedoStageDigital()
    end

    drawCrosshair()
end, true, "low-99999")
