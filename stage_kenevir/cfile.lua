-- KENEVİR SİSTEMİ - CLIENT
-- Eski sistem korunarak: doğru 4 köşe + yerde yeşil alan + yeşil/kırmızı yaprak marker

local sx, sy = guiGetScreenSize()
local w, h = 45, 45
local wx, wy = (sx-w)/2, (sy-h)/250
local wr, wq = (sx-w)/225, (sy-h)/150


local zeminTexture = dxCreateTexture("zemin.png")
local leafGreen = dxCreateTexture("assets/leaf_green.png", "argb", true, "clamp")
local leafRed = dxCreateTexture("assets/leaf_red.png", "argb", true, "clamp")
local glowGreen = dxCreateTexture("assets/glow_green.png", "argb", true, "clamp")
local glowRed = dxCreateTexture("assets/glow_red.png", "argb", true, "clamp")

local field = {
    {-292.54974, -2151.90186, 28},
    {-264.60464, -2144.79565, 28},
    {-259.97311, -2163.19165, 29},
    {-287.80783, -2170.20581, 28},
}

local plantPoints = {
    {-292.54974, -2151.90186, 28},
    {-264.60464, -2144.79565, 28.},
    {-259.97311, -2163.19165, 29},
    {-287.80783, -2170.20581, 28},
}

-- Satış noktası: kullanıcının verdiği konum
local saleX, saleY, saleZ = -247.72949, -2225.23242, 28

local function distanceTo(x, y, z)
    local px, py, pz = getElementPosition(localPlayer)
    return getDistanceBetweenPoints3D(px, py, pz, x, y, z)
end

local function getFieldCenter()
    local x, y, z = 0, 0, 0
    for _, p in ipairs(field) do
        x = x + p[1]
        y = y + p[2]
        z = z + p[3]
    end
    return x/#field, y/#field, z/#field
end

local fieldX, fieldY, fieldZ = getFieldCenter()

local function drawGroundTexture()
    if not zeminTexture then return end

    -- 4 köşeli alanın iki karşı kenarının orta noktaları.
    -- Böylece texture havaya değil, doğrudan hangar zeminine serilir.
    local a, b, c, d = field[1], field[2], field[3], field[4]

    local x1 = (a[1] + b[1]) / 2
    local y1 = (a[2] + b[2]) / 2
    local z1 = (a[3] + b[3]) / 2 + 0.012

    local x2 = (d[1] + c[1]) / 2
    local y2 = (d[2] + c[2]) / 2
    local z2 = (d[3] + c[3]) / 2 + 0.012

    local width = getDistanceBetweenPoints2D(a[1], a[2], b[1], b[2])

    dxDrawMaterialLine3D(
        x1, y1, z1,
        x2, y2, z2,
        zeminTexture,
        width,
        tocolor(255, 255, 255, 115),
        false,
        fieldX, fieldY, fieldZ + 1.0
    )
end

local function drawMarker3D(x, y, z, leafTexture, glowTexture, color, distance)
    if distance > 35 or not leafTexture then return end

    -- Yaprak zemine sıfıra yakın oturur; havada dik durmaz.
    local groundZ = z + 0.012
    local alpha = math.max(80, math.min(255, 255 - distance * 6))

    -- Zemindeki küçük ışık halkası
    if glowTexture then
        dxDrawMaterialLine3D(
            x - 0.85, y, groundZ,
            x + 0.85, y, groundZ,
            glowTexture,
            1.70,
            tocolor(color[1], color[2], color[3], math.min(150, alpha)),
            false,
            x, y, groundZ + 1.0
        )
    end

    -- Kenevir yaprağı yere yatık çizilir.
    dxDrawMaterialLine3D(
        x - 0.48, y, groundZ + 0.002,
        x + 0.48, y, groundZ + 0.002,
        leafTexture,
        0.96,
        tocolor(color[1], color[2], color[3], alpha),
        false,
        x, y, groundZ + 1.0
    )
end

local function drawWorldPrompt(text, x, y, z)
    local screenX, screenY = getScreenFromWorldPosition(x, y, z)
    if not screenX or not screenY then return end

    local boxW, boxH = 300, 46
    local boxX, boxY = screenX - boxW / 2, screenY - boxH / 2

    rectangle(boxX + 2, boxY + 3, boxW, boxH, tocolor(0, 0, 0, 120), {0.18, 0.18, 0.18, 0.18})
    rectangle(boxX, boxY, boxW, boxH, tocolor(45, 45, 45, 235), {0.18, 0.18, 0.18, 0.18})

    dxDrawText(
        text,
        boxX, boxY, boxX + boxW, boxY + boxH,
        tocolor(255, 255, 255, 255),
        1.05,
        "default-bold",
        "center", "center", false, false, false
    )
end

local function getNearestPlant(px, py, pz)
    local nearest, nearestDist
    for _, point in ipairs(plantPoints) do
        local d = getDistanceBetweenPoints3D(px, py, pz, point[1], point[2], point[3])
        if not nearestDist or d < nearestDist then
            nearest = point
            nearestDist = d
        end
    end
    return nearest, nearestDist
end

addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)

    -- YEŞİL TOPLAMA ALANI
    local fieldDistance = getDistanceBetweenPoints3D(px, py, pz, fieldX, fieldY, fieldZ)
    if fieldDistance <= 55 then
        drawGroundTexture()

        for _, point in ipairs(plantPoints) do
            local pd = getDistanceBetweenPoints3D(px, py, pz, point[1], point[2], point[3])
            if pd <= 35 then
                drawMarker3D(point[1], point[2], point[3], leafGreen, glowGreen, {0, 255, 35}, pd)
            end
        end
    end

    -- KIRMIZI SATIŞ NOKTASI
    local saleDistance = getDistanceBetweenPoints3D(px, py, pz, saleX, saleY, saleZ)
    if saleDistance <= 35 then
        drawMarker3D(saleX, saleY, saleZ, leafRed, glowRed, {255, 20, 20}, saleDistance)
    end

    -- E PANELİ: etkileşim noktasının ÜSTÜNDE gösterilir.
    if getElementData(localPlayer, "kenevir:e") then
        local islemTuru = getElementData(localPlayer, "kenevir:tur")
        local isX2 = getElementData(root, "kenevir:etkinlik")

        if islemTuru == "satma" then
            drawWorldPrompt('Satmak için "E" tuşuna basınız', saleX, saleY, saleZ + 1.65)
        elseif islemTuru == "toplama" then
            local nearestPlant = getNearestPlant(px, py, pz)
            if nearestPlant then
                drawWorldPrompt('Toplamak için "E" tuşuna basınız', nearestPlant[1], nearestPlant[2], nearestPlant[3] + 1.65)
            end
        end

        if isX2 then
            dxDrawText("2x Etkinliği Aktif!", sx/2, sy/2+100, sx, sy, tocolor(0,255,0,255), 1.5, "default-bold", "center")
        end
    end
end)

addEvent("kenevir:toplama", true)
addEventHandler("kenevir:toplama", localPlayer, function(sure)
    setTimer(function()
        if not isElement(localPlayer) then return end
        triggerServerEvent("kenevir:ver", localPlayer, localPlayer)
        setElementData(localPlayer, "kenevir:top", false)
        setElementData(localPlayer, "bind:engel", false)
    end, sure, 1)
end)
