--[[
    Araç Kiralama - Client
    Marker'a girince GUI açılır, çıkınca kapanır.
]]

local sx, sy = guiGetScreenSize()
local _cw, _ch = 1920, 1080
local scaleX, scaleY = sx / _cw, sy / _ch
local _scale = math.min(scaleX, scaleY)
local _offX  = (sx - _cw * _scale) / 2
local _offY  = (sy - _ch * _scale) / 2

local rounded = {}
local circles  = {}

-- Custom fontlar (fonts/ klasörüne .ttf koy)
local customFonts = {}
local function loadFonts()
    -- Dosya adı: fonts/Gilroy-Regular.ttf  (veya gilroy-regular.ttf)
    local paths = {
        ["gilroy-regular"] = "fonts/Gilroy-Regular.ttf",
        ["gilroy-bold"]    = "fonts/Gilroy-Bold.ttf",
    }
    for name, path in pairs(paths) do
        if fileExists(path) then
            customFonts[name] = dxCreateFont(path, 12, false, "antialiased")
        end
    end
end
addEventHandler("onClientResourceStart", resourceRoot, loadFonts)

local function getIconTexture(name) return nil end

-- Araç listesi (buton metinleri + model + fiyat)
local vehicleData = {
    { model = 474, name = "Golf", price = 1500 },   -- Golf (ZR-350 benzeri, istersen değiştir)
    { model = 549, name = "Tofaş", price = 1000 }, -- Tofaş (Tampa)
}

local uiElements = {
    {
        id = "window_7", type = "window",
        x = 640, y = 400, w = 520, h = 280,
        title = "Araç Kiralama",
        fontScale = 1.05, font = "gilroy-regular",
        alignX = "left", alignY = "center",
        clip = false, wordBreak = false, colorCoded = true,
        headerHeight = 24, titlePaddingX = 220,
        headerColor = { 52, 120, 240, 240 },
        bodyColor = { 18, 21, 29, 235 },
        textColor = { 255, 255, 255, 255 },
        shadowColor = { 0, 0, 0, 120 },
        shadowOffsetX = 1, shadowOffsetY = 1,
        visible = false,  -- başlangıçta kapalı
        locked = false, parentId = "", groupId = "",
        componentId = "", componentInstanceOf = "", componentDetached = false,
        anchorX = "left", anchorY = "top",
        dockX = "none", dockY = "none",
        dockPaddingRight = 0, dockPaddingBottom = 0,
        relativeW = false, relativeH = false, wPercent = 0, hPercent = 0,
        clickAction = "show", actionTarget = "", actionValue = "",
        animationType = "none", animationTrigger = "auto",
        animationDuration = 1200, animationLoop = false, animationIntensity = 18
    },
    {
        id = "button_19", type = "button",
        x = 800, y = 480, w = 200, h = 40,
        text = "Golf 1500$",
        fontScale = 1, font = "gilroy-regular",
        alignX = "center", alignY = "center",
        clip = false, wordBreak = false, colorCoded = false,
        radius = 10,
        color = { 230, 164, 52, 235 },
        hoverColor = { 247, 191, 92, 245 },
        textColor = { 28, 25, 20, 255 },
        shadowColor = { 255, 255, 255, 0 },
        shadowOffsetX = 1, shadowOffsetY = 1,
        visible = false,
        locked = false, parentId = "", groupId = "",
        componentId = "", componentInstanceOf = "", componentDetached = false,
        anchorX = "left", anchorY = "top",
        dockX = "none", dockY = "none",
        dockPaddingRight = 0, dockPaddingBottom = 0,
        relativeW = false, relativeH = false, wPercent = 0, hPercent = 0,
        clickAction = "rent", actionTarget = "", actionValue = "1",  -- index 1 = Golf
        animationType = "none", animationTrigger = "auto",
        animationDuration = 1200, animationLoop = false, animationIntensity = 18
    },
    {
        id = "button_20", type = "button",
        x = 800, y = 560, w = 200, h = 40,
        text = "Tofaş 1000$",
        fontScale = 1, font = "gilroy-regular",
        alignX = "center", alignY = "center",
        clip = false, wordBreak = false, colorCoded = false,
        radius = 10,
        color = { 230, 164, 52, 235 },
        hoverColor = { 247, 191, 92, 245 },
        textColor = { 28, 25, 20, 255 },
        shadowColor = { 255, 255, 255, 0 },
        shadowOffsetX = 1, shadowOffsetY = 1,
        visible = false,
        locked = false, parentId = "", groupId = "",
        componentId = "", componentInstanceOf = "", componentDetached = false,
        anchorX = "left", anchorY = "top",
        dockX = "none", dockY = "none",
        dockPaddingRight = 0, dockPaddingBottom = 0,
        relativeW = false, relativeH = false, wPercent = 0, hPercent = 0,
        clickAction = "rent", actionTarget = "", actionValue = "2",  -- index 2 = Tofaş
        animationType = "none", animationTrigger = "auto",
        animationDuration = 1200, animationLoop = false, animationIntensity = 18
    },
}

local function rgba(c)
    if type(c) ~= "table" then return tocolor(255, 255, 255, 255) end
    return tocolor(c[1], c[2], c[3], c[4] or 255)
end

local function hasColor(c)
    return type(c) == "table" and (c[4] or 255) > 0
end

local function isCursorOnRect(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function _res()
    sx, sy = guiGetScreenSize()
    scaleX, scaleY = sx / _cw, sy / _ch
    _scale = math.min(scaleX, scaleY)
    _offX = (sx - _cw * _scale) / 2
    _offY = (sy - _ch * _scale) / 2
end
addEventHandler("onClientResourceStart", resourceRoot, _res)

local function dxDrawRounded(id, x, y, w, h, radius, color, postGUI)
    id = tostring(id or "generic")
    w = math.max(1, math.floor(w + 0.5))
    h = math.max(1, math.floor(h + 0.5))
    radius = math.min(math.floor((radius or 0) + 0.5), math.floor(math.min(w, h) / 2))
    if radius <= 0 then
        dxDrawRectangle(x, y, w, h, color, postGUI or false)
        return
    end
    rounded[id] = rounded[id] or {}
    rounded[id][w] = rounded[id][w] or {}
    rounded[id][w][h] = rounded[id][w][h] or {}
    if not rounded[id][w][h][radius] or not isElement(rounded[id][w][h][radius]) then
        local p = string.format(
            '<svg width="%d" height="%d" viewBox="0 0 %d %d"><rect width="%d" height="%d" rx="%d" fill="#FFF"/></svg>',
            w, h, w, h, w, h, radius
        )
        rounded[id][w][h][radius] = svgCreate(w, h, p)
    end
    if rounded[id][w][h][radius] then
        dxDrawImage(x, y, w, h, rounded[id][w][h][radius], 0, 0, 0, color, postGUI or false)
    end
end

local function dxDrawCircle(id, x, y, w, h, color, postGUI)
    id = tostring(id or "generic")
    w = math.max(1, math.floor(w + 0.5))
    h = math.max(1, math.floor(h + 0.5))
    local key = w .. "_" .. h
    circles[id] = circles[id] or {}
    if not circles[id][key] or not isElement(circles[id][key]) then
        local p = string.format(
            '<svg width="%d" height="%d" viewBox="0 0 %d %d"><ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFF"/></svg>',
            w, h, w, h, w / 2, h / 2, w / 2, h / 2
        )
        circles[id][key] = svgCreate(w, h, p)
    end
    if circles[id][key] then
        dxDrawImage(x, y, w, h, circles[id][key], 0, 0, 0, color, postGUI or false)
    end
end

function drawOutline(x, y, w, h, color, thickness)
    thickness = thickness or 1
    dxDrawRectangle(x, y, w, thickness, color)
    dxDrawRectangle(x, y + h - thickness, w, thickness, color)
    dxDrawRectangle(x, y, thickness, h, color)
    dxDrawRectangle(x + w - thickness, y, thickness, h, color)
end

function utfLen(s)
    local _, count = tostring(s or ""):gsub("[\128-\191]", "")
    return count
end

function utfSub(s, i, j)
    return string.sub(s, i, j)
end

local function delChar(s)
    if not s or #s == 0 then return "" end
    return string.sub(s, 1, #s - 1)
end

function drawStyledText(text, left, top, right, bottom, opts)
    local scale = (opts.fontScale or 1)
    local fontName = opts.font or "default-bold"

    -- Önce custom font (gilroy-regular vs.), yoksa built-in
    local font = customFonts[fontName]
    if not font or not isElement(font) then
        local _bf = {
            ["default"] = true, ["default-bold"] = true, ["arial"] = true,
            ["bankgothic"] = true, ["clear"] = true, ["danielbd"] = true,
            ["pricedown"] = true, ["sans"] = true, ["unifont"] = true
        }
        font = (_bf[fontName] and fontName) or "default-bold"
    end

    if hasColor(opts.shadowColor) then
        local sx2 = (opts.shadowOffsetX or 1) * scaleX
        local sy2 = (opts.shadowOffsetY or 1) * scaleY
        dxDrawText(text, left + sx2, top + sy2, right + sx2, bottom + sy2,
            rgba(opts.shadowColor), scale, font,
            opts.alignX or "left", opts.alignY or "center",
            opts.clip, opts.wordBreak, false, opts.colorCoded)
    end
    dxDrawText(text, left, top, right, bottom,
        rgba(opts.textColor or { 255, 255, 255, 255 }), scale, font,
        opts.alignX or "left", opts.alignY or "center",
        opts.clip, opts.wordBreak, false, opts.colorCoded)
end

local function resolveAnchoredRect(el)
    local x = el.x or 0
    local y = el.y or 0
    local w = (el.relativeW and el.wPercent) and math.max(20, math.floor(_cw * (el.wPercent / 100) + 0.5)) or (el.w or 0)
    local h = (el.relativeH and el.hPercent) and math.max(20, math.floor(_ch * (el.hPercent / 100) + 0.5)) or (el.h or 0)

    if el.dockX == "fill" then
        w = math.max(20, _cw - x - math.max(0, el.dockPaddingRight or 0))
    elseif el.anchorX == "center" then
        x = (_cw - w) / 2 + x
    elseif el.anchorX == "right" then
        x = _cw - w - x
    end

    if el.dockY == "fill" then
        h = math.max(20, _ch - y - math.max(0, el.dockPaddingBottom or 0))
    elseif el.anchorY == "center" then
        y = (_ch - h) / 2 + y
    elseif el.anchorY == "bottom" then
        y = _ch - h - y
    end

    return x * _scale + _offX, y * _scale + _offY, w * _scale, h * _scale
end

local function drawUiElement(el)
    local x, y, w, h = resolveAnchoredRect(el)

    if el.type == "window" then
        local hh = math.min(h, math.max(24 * scaleY, (el.headerHeight or 40) * scaleY))
        local px = (el.titlePaddingX or 16) * scaleX
        dxDrawRectangle(x, y, w, h, rgba(el.bodyColor))
        dxDrawRectangle(x, y, w, hh, rgba(el.headerColor))
        drawStyledText(el.title, x + px, y, x + w - px, y + hh, el)

    elseif el.type == "rectangle" then
        dxDrawRounded(el.id, x, y, w, h, (el.radius or 0) * math.min(scaleX, scaleY), rgba(el.color))

    elseif el.type == "button" then
        local r = (el.radius or 0) * math.min(scaleX, scaleY)
        local fill = isCursorOnRect(x, y, w, h) and el.hoverColor or el.color
        dxDrawRounded(el.id, x, y, w, h, r, rgba(fill))
        drawStyledText(el.text, x + 8 * scaleX, y + 4 * scaleY, x + w - 8 * scaleX, y + h - 4 * scaleY, el)

    elseif el.type == "label" then
        drawStyledText(el.text, x, y, x + w, y + h, el)

    elseif el.type == "image" then
        local r = (el.radius or 0) * math.min(scaleX, scaleY)
        if el.imagePath and el.imagePath ~= "" then
            local isHttp = el.imagePath:sub(1, 7) == "http://" or el.imagePath:sub(1, 8) == "https://"
            local tex
            if not isHttp then
                if not el._tex or not isElement(el._tex) then
                    el._tex = dxCreateTexture(el.imagePath, "argb", true, "clamp")
                end
                tex = el._tex
            end
            if tex then
                dxDrawImage(x, y, w, h, tex, 0, 0, 0, rgba(el.color or { 255, 255, 255, 255 }))
            else
                dxDrawRounded(el.id, x, y, w, h, r, rgba(el.color or { 255, 255, 255, 255 }))
            end
        end

    elseif el.type == "container" then
        dxDrawRounded(el.id, x, y, w, h, (el.radius or 0) * math.min(scaleX, scaleY), rgba(el.color))

    elseif el.type == "progressbar" then
        local r = (el.radius or 0) * math.min(scaleX, scaleY)
        dxDrawRounded(el.id .. "_bg", x, y, w, h, r, rgba(el.color))
        local fillW = w * ((el.progress or 0) / 100)
        dxDrawRounded(el.id .. "_fill", x, y, fillW, h, r, rgba(el.progressColor or { 72, 199, 130, 255 }))
        if el.text and el.text ~= "" then
            drawStyledText(el.text, x, y, x + w, y + h, el)
        end

    elseif el.type == "checkbox" then
        local box = math.min(h, 22 * scaleY)
        dxDrawRounded(el.id .. "_box", x, y + (h - box) / 2, box, box, 4, rgba(el.boxColor or { 27, 31, 42, 230 }))
        if el.checked then
            dxDrawText("X", x, y + (h - box) / 2, x + box, y + (h + box) / 2,
                rgba(el.checkColor or { 72, 199, 130, 255 }), 1, "default-bold", "center", "center")
        end
        drawStyledText(el.text or "", x + box + 8 * scaleX, y, x + w, y + h, el)

    elseif el.type == "editbox" then
        dxDrawRounded(el.id .. "_eb", x, y, w, h, (el.radius or 0) * math.min(scaleX, scaleY), rgba(el.color or { 20, 24, 32, 235 }))
        if hasColor(el.borderColor) then
            drawOutline(x, y, w, h, rgba(el.borderColor), 1)
        end
        local shown = (el.text and el.text ~= "") and el.text or (el.placeholder or "")
        if el.masked and el.text and el.text ~= "" then
            shown = string.rep("*", utfLen(el.text))
        end
        drawStyledText(shown, x + 12 * scaleX, y, x + w - 12 * scaleX, y + h, {
            font = el.font, fontScale = el.fontScale,
            textColor = (el.text and el.text ~= "") and (el.textColor or { 255, 255, 255, 255 }) or { 160, 165, 180, 255 },
            alignX = "left", alignY = "center"
        })

    elseif el.type == "line" then
        dxDrawLine(x, y + h / 2, x + w, y + h / 2, rgba(el.color or { 255, 255, 255, 200 }), el.thickness or 2)

    elseif el.type == "gradient" then
        local steps = 20
        local c1 = type(el.color) == "table" and el.color or { 255, 255, 255, 255 }
        local c2 = type(el.gradientColor) == "table" and el.gradientColor or { 0, 0, 0, 255 }
        for i = 0, steps - 1 do
            local t = i / (steps - 1)
            local c = {
                c1[1] + (c2[1] - c1[1]) * t,
                c1[2] + (c2[2] - c1[2]) * t,
                c1[3] + (c2[3] - c1[3]) * t,
                (c1[4] or 255) + ((c2[4] or 255) - (c1[4] or 255)) * t
            }
            if el.gradientMode == "vertical" then
                dxDrawRectangle(x, y + (h / steps) * i, w, math.ceil(h / steps), rgba(c))
            else
                dxDrawRectangle(x + (w / steps) * i, y, math.ceil(w / steps), h, rgba(c))
            end
        end

    elseif el.type == "icon" then
        local icon = getIconTexture(el.iconName)
        if icon then
            local size = math.min(w, h, (el.iconSize or 24) * math.min(scaleX, scaleY))
            dxDrawImage(x + (w - size) / 2, y + (h - size) / 2, size, size, icon, 0, 0, 0, rgba(el.color or { 255, 255, 255, 255 }))
        else
            dxDrawText(string.upper((el.iconName or "?"):sub(1, 1)), x, y, x + w, y + h,
                rgba(el.color or { 255, 255, 255, 255 }), 1, "default-bold", "center", "center")
        end

    elseif el.type == "circle" then
        if (el.borderWidth or 0) > 0 and hasColor(el.borderColor) then
            local bw = el.borderWidth * math.min(scaleX, scaleY)
            dxDrawCircle(el.id .. "_b", x - bw, y - bw, w + bw * 2, h + bw * 2, rgba(el.borderColor))
        end
        dxDrawCircle(el.id, x, y, w, h, rgba(el.color))
    end
end

local activeInput = nil
local guiVisible = false

local function setGuiVisible(state)
    guiVisible = state
    for _, el in ipairs(uiElements) do
        el.visible = state
    end
    showCursor(state)
end

addEventHandler("onClientClick", root, function(btn, state)
    if btn ~= "left" or state ~= "down" then return end
    if not guiVisible then return end

    local clickedAny = false
    for i = #uiElements, 1, -1 do
        local el = uiElements[i]
        if el.visible ~= false then
            local x, y, w, h = resolveAnchoredRect(el)
            if isCursorOnRect(x, y, w, h) then
                clickedAny = true
                if el.type == "editbox" then
                    activeInput = el
                else
                    activeInput = nil
                end
                if el.type == "checkbox" then
                    el.checked = not el.checked
                end
                if el.clickAction and el.clickAction ~= "none" then
                    if el.clickAction == "toggle_visibility" then
                        for _, tgt in ipairs(uiElements) do
                            if tgt.id == el.actionTarget then
                                tgt.visible = not tgt.visible
                            end
                        end
                    elseif el.clickAction == "show" then
                        for _, tgt in ipairs(uiElements) do
                            if tgt.id == el.actionTarget then
                                tgt.visible = true
                            end
                        end
                    elseif el.clickAction == "hide" then
                        for _, tgt in ipairs(uiElements) do
                            if tgt.id == el.actionTarget then
                                tgt.visible = false
                            end
                        end
                    elseif el.clickAction == "trigger_event" then
                        triggerEvent(el.actionValue or "", localPlayer, el)
                    elseif el.clickAction == "chat_message" then
                        outputChatBox(el.actionValue or "", 255, 255, 255, true)
                    elseif el.clickAction == "rent" then
                        local idx = tonumber(el.actionValue)
                        if idx and vehicleData[idx] then
                            local data = vehicleData[idx]
                            triggerServerEvent("aracKiralama:kirala", localPlayer, data.model, data.price, data.name)
                        end
                    end
                end
                break
            end
        end
    end
    if not clickedAny then
        activeInput = nil
    end
end)

addEventHandler("onClientCharacter", root, function(char)
    if not activeInput then return end
    activeInput.text = (activeInput.text or "") .. char
end)

addEventHandler("onClientKey", root, function(btn, down)
    if not activeInput or not down then return end
    if btn == "backspace" then
        local t = activeInput.text or ""
        if #t > 0 then
            local u = t:gsub("[\128-\191]", "")
            if #u > 0 then
                activeInput.text = delChar(t)
            end
        end
    end
end)

local function renderCreatedUi()
    if not guiVisible then return end
    for _, el in ipairs(uiElements) do
        if el.visible ~= false then
            drawUiElement(el)
        end
    end
end
addEventHandler("onClientRender", root, renderCreatedUi)

-- ===================== MARKER SİSTEMİ =====================
-- Marker konumu
local MARKER_X, MARKER_Y, MARKER_Z = -283.63110, -2199.48364, 28
local MARKER_SIZE = 2.5

local rentalMarker = createMarker(MARKER_X, MARKER_Y, MARKER_Z - 1, "cylinder", MARKER_SIZE, 52, 120, 240, 150)
local rentalBlip = createBlip(MARKER_X, MARKER_Y, MARKER_Z, 55) -- 55 = araç blip

setElementData(rentalMarker, "aracKiralamaMarker", true)

addEventHandler("onClientMarkerHit", rentalMarker, function(hitElement, matchingDimension)
    if hitElement ~= localPlayer or not matchingDimension then return end
    if isPedInVehicle(localPlayer) then
        outputChatBox("#FF6B6B[Kiralama] #FFFFFFAraçtayken kiralama yapamazsın.", 255, 255, 255, true)
        return
    end
    setGuiVisible(true)
end)

addEventHandler("onClientMarkerLeave", rentalMarker, function(leaveElement, matchingDimension)
    if leaveElement ~= localPlayer or not matchingDimension then return end
    setGuiVisible(false)
end)

-- ESC ile kapatma
addEventHandler("onClientKey", root, function(btn, down)
    if not down or btn ~= "escape" then return end
    if guiVisible then
        setGuiVisible(false)
        cancelEvent()
    end
end)

-- Server'dan gelen mesajlar
addEvent("aracKiralama:mesaj", true)
addEventHandler("aracKiralama:mesaj", root, function(msg, r, g, b)
    outputChatBox(msg, r or 255, g or 255, b or 255, true)
end)

addEvent("aracKiralama:kapat", true)
addEventHandler("aracKiralama:kapat", root, function()
    setGuiVisible(false)
end)