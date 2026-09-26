Phone = {
    open = false,
    page = "home",
    data = {},
    camera = false,
    call = nil,
    callHistory = {},
    gallery = {},
    selectedPhoto = nil,
    callInput = "",
    msgTarget = "",
    msgText = "",
    bg = 1,
    scale = 1.0,
    island = true,
    dark = true,
    sound = true,
    inputFocus = nil,
    socialText = "",
    contacts = {},
    notes = {},
    contactName = "",
    contactNumber = "",
    noteTitle = "",
    noteBody = "",
    calcDisplay = "0",
    calcAcc = nil,
    calcOp = nil,
    calcFresh = false,
    calcDot = false,
}

local clickList = {}
local textures = {}
local TEX_NONE = false
local iconTextures = {}
local screenSource = nil
local screenSourceW, screenSourceH = 0, 0
local renderBound = false
local preRenderBound = false
local settingsFile = "phone_settings.xml"
local galleryFile = "phone_gallery.txt"
local contactsFile = "phone_contacts.txt"
local notesFile = "phone_notes.txt"
local fontBold = "default-bold"
local fontMain = "default"

local apps = {
    {"camera", "Kamera"},
    {"gallery", "Galeri"},
    {"stagegram", "Stagegram"},
    {"stagex", "StageX"},
    {"messages", "Mesajlar"},
    {"contacts", "Kisiler"},
    {"calls", "Telefon"},
    {"notes", "Notlar"},
    {"calculator", "Hesap"},
    {"settings", "Ayarlar"},
}

local iconLabels = {
    camera = "Kamera",
    gallery = "Galeri",
    stagegram = "Stagegram",
    stagex = "StageX",
    messages = "Mesajlar",
    contacts = "Kisiler",
    calls = "Telefon",
    notes = "Notlar",
    calculator = "Hesap",
    settings = "Ayarlar",
}

local dockApps = {"calls", "messages", "camera", "settings"}
local BG_FALLBACK = "assets/background.png"

local drawHome, drawCamera, drawGallery, drawCalls, drawMessages
local drawSocial, drawSettings, drawContacts, drawNotes, drawCalculator
local drawPhone, capturePhoto, setPhoneOpen, destroyCameraSource, preloadAssets

local function cfg()
    if type(Config) == "table" then
        return Config
    end
    return {
        width = 390,
        height = 760,
        minScale = 0.72,
        maxScale = 1.15,
        maxMessageLength = 500,
        maxTweetLength = 280,
        maxPostCaption = 500,
        maxNoteLength = 2000,
        maxGallery = 40,
        maxCallInput = 16,
        key = "F4",
        command = "telefon",
    }
end

local function C(r, g, b, a)
    return tocolor(r, g, b, a or 255)
end

local function dbg(msg)
    outputDebugString("[Stage Phone] " .. tostring(msg))
end

local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

local function str(v)
    return tostring(v or "")
end

local function hasCircle()
    return type(dxDrawCircle) == "function"
end

local function drawRounded(x, y, w, h, r, color)
    w = tonumber(w) or 0
    h = tonumber(h) or 0
    if w <= 0 or h <= 0 then
        return
    end
    r = tonumber(r) or 0
    if r < 0 then r = 0 end
    r = math.min(r, w / 2, h / 2)
    if r < 1 or not hasCircle() then
        dxDrawRectangle(x, y, w, h, color, false)
        return
    end
    dxDrawRectangle(x + r, y, w - r * 2, h, color, false)
    dxDrawRectangle(x, y + r, r, h - r * 2, color, false)
    dxDrawRectangle(x + w - r, y + r, r, h - r * 2, color, false)
    dxDrawCircle(x + r, y + r, r, 180, 270, color, color, 16, 1, false)
    dxDrawCircle(x + w - r, y + r, r, 270, 360, color, color, 16, 1, false)
    dxDrawCircle(x + r, y + h - r, r, 90, 180, color, color, 16, 1, false)
    dxDrawCircle(x + w - r, y + h - r, r, 0, 90, color, color, 16, 1, false)
end
dxDrawRoundedRectangle = drawRounded

-- Readable text helper: slight size boost + soft shadow for contrast on wallpapers.
local function text(t, x, y, w, h, color, scale, align, valign, wrap)
    t = str(t)
    scale = (scale or 1) * 1.08
    local font = fontBold
    if type(font) ~= "string" and not (font and isElement(font)) then
        font = "default-bold"
    end
    local a = align or "left"
    local v = valign or "center"
    local ww = wrap and true or false
    -- soft shadow for readability over busy wallpapers
    dxDrawText(t, x + 1, y + 1, x + w + 1, y + h + 1, C(0, 0, 0, 120), scale, font, a, v, true, ww, false, false)
    dxDrawText(t, x, y, x + w, y + h, color, scale, font, a, v, true, ww, false, false)
end

local function hit(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function addHit(id, x, y, w, h)
    if not id or not x or not y or not w or not h then
        return
    end
    if w <= 0 or h <= 0 then
        return
    end
    clickList[#clickList + 1] = {id = id, x = x, y = y, w = w, h = h}
end

local function destroyTex(map)
    if type(map) ~= "table" then
        return
    end
    for k, tex in pairs(map) do
        if tex and tex ~= TEX_NONE and isElement(tex) then
            destroyElement(tex)
        end
        map[k] = nil
    end
end

local function getTex(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    local cached = textures[path]
    if cached == TEX_NONE then
        return nil
    end
    if cached and isElement(cached) then
        return cached
    end
    if cached and not isElement(cached) then
        textures[path] = nil
    end
    if not fileExists(path) then
        textures[path] = TEX_NONE
        dbg("Texture yuklenemedi: " .. path)
        return nil
    end
    local tex = dxCreateTexture(path, "argb", true, "clamp")
    if tex and isElement(tex) then
        textures[path] = tex
        return tex
    end
    textures[path] = TEX_NONE
    dbg("Texture yuklenemedi: " .. path)
    return nil
end

local function bgPath(index)
    index = tonumber(index) or 1
    if index <= 1 then
        return "assets/background1.png"
    elseif index == 2 then
        return "assets/background2.png"
    end
    return "assets/background3.png"
end

local function getWallpaper()
    local tex = getTex(bgPath(Phone.bg))
    if tex then
        return tex
    end
    return getTex(BG_FALLBACK)
end

local function getAppIcon(name)
    name = str(name)
    if iconTextures[name] == TEX_NONE then
        return nil
    end
    if iconTextures[name] and isElement(iconTextures[name]) then
        return iconTextures[name]
    end
    local path = "assets/icons/" .. name .. ".png"
    local tex = getTex(path)
    if tex then
        iconTextures[name] = tex
        return tex
    end
    iconTextures[name] = TEX_NONE
    return nil
end

local function loadSettings()
    local c = cfg()
    Phone.scale = tonumber(c.defaultScale) or 1.0
    Phone.bg = 1
    Phone.island = true
    Phone.sound = true
    if not fileExists(settingsFile) then
        return
    end
    local f = fileOpen(settingsFile)
    if not f then
        return
    end
    local size = fileGetSize(f) or 0
    local raw = ""
    if size > 0 then
        raw = fileRead(f, size) or ""
    end
    fileClose(f)
    Phone.scale = clamp(tonumber(raw:match('scale="([%d%.]+)"')) or Phone.scale, c.minScale or 0.72, c.maxScale or 1.15)
    Phone.bg = clamp(tonumber(raw:match('bg="(%d+)"')) or 1, 1, 3)
    local island = raw:match('island="([01])"')
    if island then
        Phone.island = island ~= "0"
    end
    local sound = raw:match('sound="([01])"')
    if sound then
        Phone.sound = sound ~= "0"
    end
end

local function saveSettings()
    if fileExists(settingsFile) then
        fileDelete(settingsFile)
    end
    local f = fileCreate(settingsFile)
    if not f then
        dbg("Ayar dosyasi yazilamadi.")
        return
    end
    fileWrite(f, string.format(
        '<settings scale="%.2f" bg="%d" island="%d" sound="%d"/>',
        Phone.scale or 1,
        Phone.bg or 1,
        Phone.island and 1 or 0,
        Phone.sound and 1 or 0
    ))
    fileClose(f)
end

local function splitLines(raw)
    local out = {}
    raw = str(raw)
    for line in string.gmatch(raw .. "\n", "(.-)\n") do
        line = line:gsub("\r", "")
        if line ~= "" then
            out[#out + 1] = line
        end
    end
    return out
end

local function readLines(path)
    if not fileExists(path) then
        return {}
    end
    local f = fileOpen(path)
    if not f then
        return {}
    end
    local size = fileGetSize(f) or 0
    local raw = ""
    if size > 0 then
        raw = fileRead(f, size) or ""
    end
    fileClose(f)
    return splitLines(raw)
end

local function writeLines(path, lines)
    if fileExists(path) then
        fileDelete(path)
    end
    local f = fileCreate(path)
    if not f then
        return
    end
    for i = 1, #lines do
        fileWrite(f, str(lines[i]) .. "\n")
    end
    fileClose(f)
end

local function saveGallery()
    writeLines(galleryFile, Phone.gallery or {})
end

local function saveContacts()
    local lines = {}
    local list = Phone.contacts or {}
    for i = 1, #list do
        local row = list[i]
        if type(row) == "table" then
            lines[#lines + 1] = str(row.name) .. "\t" .. str(row.number)
        end
    end
    writeLines(contactsFile, lines)
end

local function saveNotes()
    local lines = {}
    local list = Phone.notes or {}
    for i = 1, #list do
        local row = list[i]
        if type(row) == "table" then
            lines[#lines + 1] = str(row.title):gsub("\t", " ") .. "\t" .. str(row.body):gsub("\n", " ")
        end
    end
    writeLines(notesFile, lines)
end

local function loadLocalData()
    Phone.gallery = {}
    local g = readLines(galleryFile)
    for i = 1, #g do
        if fileExists(g[i]) then
            Phone.gallery[#Phone.gallery + 1] = g[i]
        end
    end
    Phone.contacts = {}
    local c = readLines(contactsFile)
    for i = 1, #c do
        local name, number = c[i]:match("^(.-)\t(.*)$")
        if name and number then
            Phone.contacts[#Phone.contacts + 1] = {name = name, number = number}
        end
    end
    Phone.notes = {}
    local n = readLines(notesFile)
    for i = 1, #n do
        local title, body = n[i]:match("^(.-)\t(.*)$")
        if title then
            Phone.notes[#Phone.notes + 1] = {title = title, body = body or ""}
        end
    end
end

function Phone.setScale(v)
    local c = cfg()
    Phone.scale = clamp(tonumber(v) or 1, c.minScale or 0.72, c.maxScale or 1.15)
    saveSettings()
end

function Phone.setBackground(i)
    Phone.bg = clamp(tonumber(i) or 1, 1, 3)
    saveSettings()
end

function Phone.setPage(name)
    name = str(name)
    if name == "" then
        name = "home"
    end
    if Phone.page == "camera" and name ~= "camera" then
        destroyCameraSource()
        Phone.camera = false
    end
    Phone.page = name
    Phone.selectedPhoto = nil
    Phone.inputFocus = nil
    if name == "calls" then
        Phone.inputFocus = "call"
    elseif name == "messages" then
        if Phone.msgTarget == "" then
            Phone.inputFocus = "msgTarget"
        else
            Phone.inputFocus = "msgText"
        end
    elseif name == "notes" then
        Phone.inputFocus = "noteTitle"
    elseif name == "contacts" then
        Phone.inputFocus = "contactName"
    elseif name == "stagegram" or name == "stagex" then
        Phone.inputFocus = "socialText"
    elseif name == "camera" then
        Phone.camera = true
    end
end

local function phoneRect()
    local sx, sy = guiGetScreenSize()
    if not sx or not sy or sx < 1 or sy < 1 then
        return 0, 0, 280, 540, 0.72
    end
    local c = cfg()
    local bw = tonumber(c.width) or 390
    local bh = tonumber(c.height) or 760
    if bw < 1 then bw = 390 end
    if bh < 1 then bh = 760 end
    local scale = clamp(Phone.scale or 1, c.minScale or 0.72, c.maxScale or 1.15)
    local h = bh * scale
    local maxH = sy * 0.86
    if h > maxH then
        h = maxH
    end
    if h < 360 then
        h = 360
    end
    local w = h * (bw / bh)
    if w < 200 then
        w = 200
    end
    if w > sx * 0.5 then
        w = sx * 0.5
        h = w * (bh / bw)
    end
    local x = sx - w - math.max(28, sx * 0.025)
    local y = (sy - h) / 2
    if y < 8 then y = 8 end
    if x < 8 then x = 8 end
    return x, y, w, h, w / bw
end

local function wallpaper(x, y, w, h, dim)
    local tex = getWallpaper()
    if tex then
        dxDrawImage(x, y, w, h, tex, 0, 0, 0, C(255, 255, 255, 255), false)
    else
        dxDrawRectangle(x, y, w, h, C(8, 10, 14, 255), false)
    end
    dxDrawRectangle(x, y, w, h, C(0, 0, 0, dim or 40), false)
end

local function maskCorners(x, y, w, h, r, color)
    r = math.max(10, tonumber(r) or 18)
    if not hasCircle() then
        return
    end
    dxDrawCircle(x, y, r, 180, 270, color, color, 18, 1, false)
    dxDrawCircle(x + w, y, r, 270, 360, color, color, 18, 1, false)
    dxDrawCircle(x, y + h, r, 90, 180, color, color, 18, 1, false)
    dxDrawCircle(x + w, y + h, r, 0, 90, color, color, 18, 1, false)
end

local function drawStatus(x, y, w, s)
    text(os.date("%H:%M"), x + 16 * s, y + 6 * s, 70 * s, 26 * s, C(255, 255, 255), 0.88, "left")
    if Phone.island then
        local iw, ih = 122 * s, 30 * s
        local ix = x + (w - iw) / 2
        drawRounded(ix, y + 7 * s, iw, ih, 15 * s, C(0, 0, 0, 250))
        if hasCircle() then
            dxDrawCircle(ix + 22 * s, y + 22 * s, 3.4 * s, 0, 360, C(28, 28, 32), C(28, 28, 32), 12, 1, false)
            dxDrawCircle(ix + iw - 24 * s, y + 22 * s, 4.2 * s, 0, 360, C(36, 36, 40), C(36, 36, 40), 12, 1, false)
        end
    end
    local rx = x + w - 90 * s
    text("|||", rx, y + 6 * s, 30 * s, 26 * s, C(250, 250, 252), 0.62, "center")
    drawRounded(rx + 30 * s, y + 12 * s, 24 * s, 12 * s, 3 * s, C(240, 242, 246))
    drawRounded(rx + 32 * s, y + 14 * s, 17 * s, 8 * s, 2 * s, C(52, 199, 89))
    dxDrawRectangle(rx + 54 * s, y + 15 * s, 2 * s, 6 * s, C(240, 242, 246), false)
end

local function homeIndicator(x, y, w, h, s)
    local iw, ih = 92 * s, 5 * s
    local ix = x + (w - iw) / 2
    local iy = y + h - 16 * s
    drawRounded(ix, iy, iw, ih, 3 * s, C(255, 255, 255, 220))
    addHit("home", x + w * 0.2, y + h - 28 * s, w * 0.6, 28 * s)
end

local function header(x, y, w, s, title)
    local hy = y + 40 * s
    addHit("back", x + 2 * s, hy, 58 * s, 38 * s)
    text("<", x + 8 * s, hy, 34 * s, 38 * s, C(255, 255, 255), 1.2, "center")
    text(title, x + 48 * s, hy, w - 72 * s, 38 * s, C(255, 255, 255), 1.05)
end

local function appIcon(name, x, y, size, showLabel, s)
    local tex = getAppIcon(name)
    if tex then
        dxDrawImage(x, y, size, size, tex, 0, 0, 0, C(255, 255, 255, 255), false)
    else
        drawRounded(x, y, size, size, 16, C(42, 48, 58, 240))
        text((str(name):sub(1, 1)):upper(), x, y, size, size, C(255, 255, 255), 0.95, "center")
    end
    if showLabel then
        text(iconLabels[name] or name, x - 10 * s, y + size + 3 * s, size + 20 * s, 18 * s, C(252, 252, 255, 250), 0.62, "center")
    end
end

local function drawMiniWidget(x, y, w, h, title, value, sub, s)
    drawRounded(x, y, w, h, 16 * s, C(10, 14, 20, 175))
    text(title, x + 12 * s, y + 6 * s, w - 24 * s, 16 * s, C(190, 200, 214, 240), 0.58)
    text(value, x + 12 * s, y + 22 * s, w - 24 * s, 24 * s, C(255, 255, 255), 0.92)
    if sub then
        text(sub, x + 12 * s, y + h - 18 * s, w - 24 * s, 14 * s, C(170, 180, 196, 230), 0.52)
    end
end

drawHome = function(x, y, w, h, s)
    local widgetY = y + 48 * s
    local widgetH = 58 * s
    drawMiniWidget(x + 14 * s, widgetY, w * 0.48, widgetH, "BUGUN", os.date("%d.%m"), os.date("%A"), s)
    local number = "-"
    if Phone.data and Phone.data.user and Phone.data.user.number then
        number = str(Phone.data.user.number)
    end
    drawMiniWidget(x + w * 0.52, widgetY, w * 0.44, widgetH, "TELEFON", number, "Stage Network", s)

    local dockH = 68 * s
    local dockY = y + h - 20 * s - dockH
    local gridTop = widgetY + widgetH + 20 * s
    local gridBottom = dockY - 12 * s
    local cols = 4
    local rows = 3
    local marginX = 20 * s
    local iconSize = 56 * s
    local labelH = 20 * s
    local innerW = w - marginX * 2
    local gapX = (innerW - cols * iconSize) / (cols - 1)
    if gapX < 8 * s then
        iconSize = (innerW - 8 * s * (cols - 1)) / cols
        gapX = 8 * s
    end
    local rowPitch = iconSize + labelH + 12 * s
    local need = rows * rowPitch - 12 * s
    if need > (gridBottom - gridTop) and (gridBottom - gridTop) > 80 then
        local fit = (gridBottom - gridTop + 12 * s) / rows
        iconSize = math.max(38 * s, fit - labelH - 12 * s)
        rowPitch = iconSize + labelH + 12 * s
        gapX = (innerW - cols * iconSize) / (cols - 1)
    end
    local left = x + marginX
    for i = 1, #apps do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local ix = left + col * (iconSize + gapX)
        local iy = gridTop + row * rowPitch
        if iy + iconSize <= gridBottom + 4 then
            appIcon(apps[i][1], ix, iy, iconSize, true, s)
            addHit("app:" .. apps[i][1], ix - 6, iy - 6, iconSize + 12, iconSize + labelH + 6)
        end
    end

    drawRounded(x + 12 * s, dockY, w - 24 * s, dockH, 24 * s, C(12, 16, 24, 195))
    local ds = 48 * s
    local dg = 20 * s
    local dockW = 4 * ds + 3 * dg
    local dx0 = x + (w - dockW) / 2
    local iy = dockY + (dockH - ds) / 2
    for i = 1, #dockApps do
        local ix = dx0 + (i - 1) * (ds + dg)
        appIcon(dockApps[i], ix, iy, ds, false, s)
        addHit("dock:" .. dockApps[i], ix - 4, iy - 4, ds + 8, ds + 8)
    end
end

local function ensureScreenSource(w, h)
    w = math.max(64, math.floor(w))
    h = math.max(64, math.floor(h))
    if screenSource and isElement(screenSource) and screenSourceW == w and screenSourceH == h then
        return screenSource
    end
    destroyCameraSource()
    local src = dxCreateScreenSource(w, h)
    if src and isElement(src) then
        screenSource = src
        screenSourceW = w
        screenSourceH = h
        return src
    end
    dbg("Kamera ekran kaynagi olusturulamadi.")
    screenSource = nil
    return nil
end

destroyCameraSource = function()
    if screenSource and isElement(screenSource) then
        destroyElement(screenSource)
    end
    screenSource = nil
    screenSourceW = 0
    screenSourceH = 0
end

drawCamera = function(x, y, w, h, s)
    dxDrawRectangle(x, y, w, h, C(0, 0, 0, 255), false)
    header(x, y, w, s, "Kamera")
    local viewY = y + 82 * s
    local viewH = h - 180 * s
    local viewW = w - 24 * s
    local src = ensureScreenSource(viewW, viewH)
    if src then
        dxDrawImage(x + 12 * s, viewY, viewW, viewH, src, 0, 0, 0, C(255, 255, 255, 255), false)
    else
        drawRounded(x + 12 * s, viewY, viewW, viewH, 16 * s, C(20, 22, 26, 255))
        text("Kamera hazir degil", x, viewY, w, viewH, C(180, 186, 196), 0.7, "center")
    end
    drawRounded(x + 14 * s, y + h - 86 * s, w - 28 * s, 62 * s, 24 * s, C(12, 14, 18, 230))
    if hasCircle() then
        dxDrawCircle(x + w / 2, y + h - 55 * s, 24 * s, 0, 360, C(245, 245, 245), C(245, 245, 245), 20, 1, false)
        dxDrawCircle(x + w / 2, y + h - 55 * s, 18 * s, 0, 360, C(40, 42, 48), C(40, 42, 48), 20, 1, false)
    else
        drawRounded(x + w / 2 - 24 * s, y + h - 79 * s, 48 * s, 48 * s, 24 * s, C(245, 245, 245))
    end
    addHit("camera:shot", x + w / 2 - 34 * s, y + h - 90 * s, 68 * s, 68 * s)
end

capturePhoto = function()
    if not screenSource or not isElement(screenSource) then
        dbg("Fotograf cekilemedi: ekran kaynagi yok.")
        return
    end
    dxUpdateScreenSource(screenSource, true)
    local px = dxGetTexturePixels(screenSource)
    if not px then
        dbg("Fotograf cekilemedi: piksel okunamadi.")
        return
    end
    local data = dxConvertPixels(px, "png")
    if not data then
        dbg("Fotograf cekilemedi: png donusumu basarisiz.")
        return
    end
    local path = "stagephone_photo_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
    local f = fileCreate(path)
    if not f then
        dbg("Fotograf cekilemedi: dosya yazilamadi.")
        return
    end
    fileWrite(f, data)
    fileClose(f)
    Phone.gallery = Phone.gallery or {}
    table.insert(Phone.gallery, 1, path)
    local maxG = (cfg().maxGallery) or 40
    while #Phone.gallery > maxG do
        table.remove(Phone.gallery)
    end
    saveGallery()
    Phone.setPage("gallery")
    Phone.selectedPhoto = path
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:galleryAdd", localPlayer, path)
    end
    if Phone.sound then
        playSoundFrontEnd(101)
    end
end

drawGallery = function(x, y, w, h, s)
    header(x, y, w, s, "Galeri")
    local list = Phone.gallery or {}
    if Phone.selectedPhoto then
        local tex = getTex(Phone.selectedPhoto)
        local py = y + 82 * s
        local ph = h - 120 * s
        if tex then
            dxDrawImage(x + 12 * s, py, w - 24 * s, ph, tex, 0, 0, 0, C(255, 255, 255, 255), false)
        else
            drawRounded(x + 12 * s, py, w - 24 * s, ph, 16 * s, C(28, 32, 40))
            text("Dosya acilamadi", x, py, w, ph, C(200, 205, 214), 0.75, "center")
        end
        addHit("gallery:close", x + 12 * s, py, w - 24 * s, ph)
        text("Kapatmak icin dokun", x, y + h - 38 * s, w, 20 * s, C(200, 208, 220, 220), 0.5, "center")
        return
    end
    if #list == 0 then
        text("Henuz fotograf yok", x + 20 * s, y + 180 * s, w - 40 * s, 40 * s, C(190, 198, 210), 0.78, "center")
        text("Kamera ile cekim yap", x + 20 * s, y + 220 * s, w - 40 * s, 24 * s, C(140, 150, 164), 0.55, "center")
        return
    end
    local cols = 3
    local pad = 10 * s
    local tw = (w - 24 * s - pad * (cols - 1)) / cols
    local th = tw * 0.86
    local top = y + 86 * s
    for i = 1, #list do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local ix = x + 12 * s + col * (tw + pad)
        local iy = top + row * (th + pad)
        if iy + th < y + h - 28 * s then
            local tex = getTex(list[i])
            if tex then
                dxDrawImage(ix, iy, tw, th, tex, 0, 0, 0, C(255, 255, 255, 255), false)
            else
                drawRounded(ix, iy, tw, th, 10 * s, C(36, 40, 48))
            end
            addHit("gallery:" .. i, ix, iy, tw, th)
        end
    end
end

drawCalls = function(x, y, w, h, s)
    header(x, y, w, s, "Telefon")
    text("Numara", x + 18 * s, y + 82 * s, w - 36 * s, 18 * s, C(200, 210, 222), 0.62)
    drawRounded(x + 14 * s, y + 102 * s, w - 28 * s, 46 * s, 14 * s, C(24, 28, 36, 240))
    local shown = Phone.callInput ~= "" and Phone.callInput or "Numara gir"
    local col = Phone.callInput ~= "" and C(255, 255, 255) or C(140, 150, 164)
    text(shown, x + 26 * s, y + 108 * s, w - 52 * s, 34 * s, col, 0.9)
    addHit("focus:call", x + 14 * s, y + 102 * s, w - 28 * s, 46 * s)

    local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"}
    local pad = 8 * s
    local kw = (w - 28 * s - pad * 2) / 3
    local kh = 42 * s
    local startY = y + 158 * s
    for i = 1, #keys do
        local coln = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local kx = x + 14 * s + coln * (kw + pad)
        local ky = startY + row * (kh + 7 * s)
        drawRounded(kx, ky, kw, kh, 14 * s, C(255, 255, 255, 24))
        text(keys[i], kx, ky, kw, kh, C(255, 255, 255), 0.95, "center")
        addHit("dial:" .. keys[i], kx, ky, kw, kh)
    end

    local callY = startY + 4 * (kh + 7 * s) + 8 * s
    drawRounded(x + 14 * s, callY, w - 28 * s, 44 * s, 16 * s, C(48, 176, 90, 250))
    text("ARA", x + 14 * s, callY, w - 28 * s, 44 * s, C(255, 255, 255), 0.82, "center")
    addHit("call:dial", x + 14 * s, callY, w - 28 * s, 44 * s)

    text("Son aramalar", x + 18 * s, callY + 52 * s, w - 36 * s, 20 * s, C(255, 255, 255), 0.78)
    local hist = Phone.callHistory or {}
    for i = 1, math.min(3, #hist) do
        local yy = callY + 76 * s + (i - 1) * 38 * s
        if yy + 32 * s < y + h - 24 * s then
            local row = hist[i]
            local number = "Bilinmeyen"
            local callType = "Giden"
            if type(row) == "table" then
                number = str(row.number ~= nil and row.number or "Bilinmeyen")
                if row.call_type == "incoming" then
                    callType = "Gelen"
                end
            end
            text(number, x + 20 * s, yy, w * 0.55, 32 * s, C(240, 244, 250), 0.72)
            text(callType, x + w - 102 * s, yy, 80 * s, 32 * s, C(180, 190, 204), 0.62, "right")
        end
    end
end

drawMessages = function(x, y, w, h, s)
    header(x, y, w, s, "Mesajlar")
    text("Kime", x + 18 * s, y + 82 * s, w - 36 * s, 18 * s, C(200, 210, 222), 0.62)
    local tcol = Phone.inputFocus == "msgTarget" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 102 * s, w - 28 * s, 44 * s, 14 * s, tcol)
    text(Phone.msgTarget ~= "" and Phone.msgTarget or "Oyuncu adi / telefon", x + 26 * s, y + 108 * s, w - 52 * s, 32 * s, C(235, 240, 248), 0.78)
    addHit("focus:msgTarget", x + 14 * s, y + 102 * s, w - 28 * s, 44 * s)

    text("Mesaj", x + 18 * s, y + 158 * s, w - 36 * s, 18 * s, C(200, 210, 222), 0.62)
    local bcol = Phone.inputFocus == "msgText" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 178 * s, w - 28 * s, 96 * s, 14 * s, bcol)
    text(Phone.msgText ~= "" and Phone.msgText or "Mesaj yaz...", x + 26 * s, y + 186 * s, w - 52 * s, 80 * s, C(235, 240, 248), 0.78, "left", "top", true)
    addHit("focus:msgText", x + 14 * s, y + 178 * s, w - 28 * s, 96 * s)

    drawRounded(x + 14 * s, y + 288 * s, w - 28 * s, 44 * s, 16 * s, C(55, 112, 180, 250))
    text("GONDER", x + 14 * s, y + 288 * s, w - 30 * s, 44 * s, C(255, 255, 255), 0.8, "center")
    addHit("msg:send", x + 14 * s, y + 288 * s, w - 30 * s, 44 * s)
    text("Alana dokun, klavyeden yaz, ESC ile kapat.", x + 18 * s, y + 344 * s, w - 36 * s, 36 * s, C(170, 180, 194), 0.6, "center", "center", true)
end

drawSocial = function(x, y, w, h, s, kind, title)
    header(x, y, w, s, title)
    local placeholder = kind == "instagram" and "Aciklama yaz..." or "Gonderi yaz..."
    drawRounded(x + 14 * s, y + 84 * s, w - 28 * s, 62 * s, 16 * s, C(255, 255, 255, 20))
    text(Phone.socialText ~= "" and Phone.socialText or placeholder, x + 24 * s, y + 90 * s, w - 130 * s, 30 * s, C(235, 240, 248), 0.72)
    addHit("focus:socialText", x + 14 * s, y + 84 * s, w - 130 * s, 40 * s)
    drawRounded(x + w - 108 * s, y + 94 * s, 82 * s, 28 * s, 12 * s, C(55, 112, 180, 250))
    text("Paylas", x + w - 108 * s, y + 94 * s, 82 * s, 28 * s, C(255, 255, 255), 0.62, "center")
    addHit("social:post", x + w - 108 * s, y + 94 * s, 82 * s, 28 * s)

    local feed = {}
    if Phone.data and type(Phone.data[kind]) == "table" then
        feed = Phone.data[kind]
    end
    if #feed == 0 then
        text("Henuz gonderi yok", x + 18 * s, y + 220 * s, w - 36 * s, 30 * s, C(200, 208, 220), 0.8, "center")
        text("Ilk paylasimi sen yap.", x + 18 * s, y + 252 * s, w - 36 * s, 22 * s, C(160, 170, 184), 0.62, "center")
        return
    end
    local yy = y + 160 * s
    local maxN = math.min(#feed, 4)
    for i = 1, maxN do
        local row = feed[i]
        if type(row) == "table" and yy + 90 * s < y + h - 24 * s then
            drawRounded(x + 14 * s, yy, w - 28 * s, 88 * s, 16 * s, C(18, 22, 30, 235))
            text(str(row.user ~= nil and row.user or "Kullanici"), x + 26 * s, yy + 10 * s, w - 52 * s, 22 * s, C(250, 250, 255), 0.72)
            text(str(row.text ~= nil and row.text or ""), x + 26 * s, yy + 36 * s, w - 52 * s, 44 * s, C(210, 218, 228), 0.65, "left", "top", true)
            yy = yy + 98 * s
        end
    end
end

drawSettings = function(x, y, w, h, s)
    header(x, y, w, s, "Ayarlar")
    text("Telefon boyutu", x + 18 * s, y + 82 * s, w - 36 * s, 18 * s, C(200, 210, 222), 0.62)
    local scales = {0.75, 0.9, 1.0, 1.1}
    local bw = (w - 28 * s - 21 * s) / 4
    for i = 1, #scales do
        local bx = x + 14 * s + (i - 1) * (bw + 7 * s)
        local on = math.abs((Phone.scale or 1) - scales[i]) < 0.03
        drawRounded(bx, y + 106 * s, bw, 38 * s, 12 * s, on and C(55, 112, 180, 250) or C(255, 255, 255, 22))
        text(tostring(math.floor(scales[i] * 100)) .. "%", bx, y + 106 * s, bw, 38 * s, C(255, 255, 255), 0.7, "center")
        addHit("scale:" .. tostring(scales[i]), bx, y + 106 * s, bw, 38 * s)
    end

    text("Duvar kagidi", x + 18 * s, y + 158 * s, w - 36 * s, 18 * s, C(200, 210, 222), 0.62)
    local gap = 8 * s
    local tw = (w - 28 * s - gap * 2) / 3
    local th = 98 * s
    for i = 1, 3 do
        local bx = x + 14 * s + (i - 1) * (tw + gap)
        local tex = getTex(bgPath(i))
        if not tex then
            tex = getTex(BG_FALLBACK)
        end
        if tex then
            dxDrawImage(bx, y + 182 * s, tw, th, tex, 0, 0, 0, C(255, 255, 255, 255), false)
        else
            drawRounded(bx, y + 182 * s, tw, th, 12 * s, C(40, 44, 52))
        end
        if Phone.bg == i then
            dxDrawRectangle(bx, y + 182 * s, tw, 4 * s, C(55, 145, 240), false)
        end
        text("BG " .. i, bx, y + 182 * s + th + 4 * s, tw, 18 * s, C(245, 248, 252), 0.62, "center")
        addHit("bg:" .. i, bx, y + 182 * s, tw, th + 22 * s)
    end

    local iy = y + 182 * s + th + 34 * s
    drawRounded(x + 14 * s, iy, w - 28 * s, 46 * s, 14 * s, C(255, 255, 255, 18))
    text("Dynamic Island", x + 26 * s, iy, 170 * s, 46 * s, C(245, 248, 252), 0.75)
    text(Phone.island and "ACIK" or "KAPALI", x + w - 112 * s, iy, 84 * s, 46 * s, Phone.island and C(75, 210, 135) or C(160, 170, 185), 0.7, "right")
    addHit("toggle:island", x + 14 * s, iy, w - 28 * s, 46 * s)

    drawRounded(x + 14 * s, iy + 54 * s, w - 28 * s, 46 * s, 14 * s, C(255, 255, 255, 18))
    text("Ses", x + 26 * s, iy + 54 * s, 170 * s, 46 * s, C(245, 248, 252), 0.75)
    text(Phone.sound and "ACIK" or "KAPALI", x + w - 112 * s, iy + 54 * s, 84 * s, 46 * s, Phone.sound and C(75, 210, 135) or C(160, 170, 185), 0.7, "right")
    addHit("toggle:sound", x + 14 * s, iy + 54 * s, w - 28 * s, 46 * s)

    text("Ayarlar bu cihazda kaydedilir.", x + 18 * s, y + h - 40 * s, w - 36 * s, 20 * s, C(160, 170, 184), 0.58, "center")
end

drawContacts = function(x, y, w, h, s)
    header(x, y, w, s, "Kisiler")
    local ncol = Phone.inputFocus == "contactName" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 84 * s, w - 28 * s, 40 * s, 12 * s, ncol)
    text(Phone.contactName ~= "" and Phone.contactName or "Isim", x + 26 * s, y + 88 * s, w - 52 * s, 32 * s, C(235, 240, 248), 0.72)
    addHit("focus:contactName", x + 14 * s, y + 84 * s, w - 28 * s, 40 * s)
    local xcol = Phone.inputFocus == "contactNumber" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 130 * s, w - 28 * s, 40 * s, 12 * s, xcol)
    text(Phone.contactNumber ~= "" and Phone.contactNumber or "Numara", x + 26 * s, y + 134 * s, w - 52 * s, 32 * s, C(235, 240, 248), 0.72)
    addHit("focus:contactNumber", x + 14 * s, y + 130 * s, w - 28 * s, 40 * s)
    drawRounded(x + 14 * s, y + 178 * s, w - 28 * s, 40 * s, 14 * s, C(55, 112, 180, 250))
    text("EKLE", x + 14 * s, y + 178 * s, w - 28 * s, 40 * s, C(255, 255, 255), 0.75, "center")
    addHit("contact:add", x + 14 * s, y + 178 * s, w - 30 * s, 40 * s)

    local list = Phone.contacts or {}
    if Phone.data and type(Phone.data.contacts) == "table" and #Phone.data.contacts > 0 then
        list = Phone.data.contacts
    end
    if #list == 0 then
        text("Kayitli kisi yok", x, y + 250 * s, w, 26 * s, C(180, 190, 202), 0.75, "center")
        return
    end
    local yy = y + 230 * s
    for i = 1, math.min(#list, 8) do
        local row = list[i]
        if type(row) == "table" and yy + 42 * s < y + h - 24 * s then
            drawRounded(x + 14 * s, yy, w - 28 * s, 40 * s, 12 * s, C(255, 255, 255, 16))
            text(str(row.name), x + 26 * s, yy, w * 0.5, 40 * s, C(245, 248, 252), 0.7)
            text(str(row.number), x + w * 0.5, yy, w * 0.42, 40 * s, C(180, 190, 204), 0.62, "right")
            addHit("contact:call:" .. i, x + 14 * s, yy, w - 28 * s, 40 * s)
            yy = yy + 46 * s
        end
    end
end

drawNotes = function(x, y, w, h, s)
    header(x, y, w, s, "Notlar")
    local tcol = Phone.inputFocus == "noteTitle" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 84 * s, w - 28 * s, 40 * s, 12 * s, tcol)
    text(Phone.noteTitle ~= "" and Phone.noteTitle or "Baslik", x + 26 * s, y + 88 * s, w - 52 * s, 32 * s, C(235, 240, 248), 0.72)
    addHit("focus:noteTitle", x + 14 * s, y + 84 * s, w - 28 * s, 40 * s)
    local bcol = Phone.inputFocus == "noteBody" and C(42, 52, 68, 250) or C(24, 28, 36, 240)
    drawRounded(x + 14 * s, y + 130 * s, w - 28 * s, 74 * s, 12 * s, bcol)
    text(Phone.noteBody ~= "" and Phone.noteBody or "Not yaz...", x + 26 * s, y + 136 * s, w - 52 * s, 62 * s, C(235, 240, 248), 0.7, "left", "top", true)
    addHit("focus:noteBody", x + 14 * s, y + 130 * s, w - 28 * s, 74 * s)
    drawRounded(x + 14 * s, y + 212 * s, w - 28 * s, 38 * s, 14 * s, C(55, 112, 180, 250))
    text("KAYDET", x + 14 * s, y + 212 * s, w - 30 * s, 38 * s, C(255, 255, 255), 0.72, "center")
    addHit("note:save", x + 14 * s, y + 212 * s, w - 30 * s, 38 * s)

    local list = Phone.notes or {}
    if Phone.data and type(Phone.data.notes) == "table" and #Phone.data.notes > 0 then
        list = Phone.data.notes
    end
    local yy = y + 262 * s
    if #list == 0 then
        text("Kayitli not yok", x, yy, w, 26 * s, C(180, 190, 202), 0.75, "center")
        return
    end
    for i = 1, math.min(#list, 7) do
        local row = list[i]
        if type(row) == "table" and yy + 38 * s < y + h - 24 * s then
            drawRounded(x + 14 * s, yy, w - 28 * s, 36 * s, 10 * s, C(255, 255, 255, 16))
            text(str(row.title), x + 26 * s, yy, w - 52 * s, 36 * s, C(245, 248, 252), 0.68)
            addHit("note:open:" .. i, x + 14 * s, yy, w - 28 * s, 36 * s)
            yy = yy + 42 * s
        end
    end
end

local function calcInput(key)
    local d = Phone.calcDisplay or "0"
    if key == "C" or key == "AC" then
        Phone.calcDisplay = "0"
        Phone.calcAcc = nil
        Phone.calcOp = nil
        Phone.calcFresh = false
        Phone.calcDot = false
        return
    end
    if key == "+/-" then
        if d:sub(1, 1) == "-" then
            Phone.calcDisplay = d:sub(2)
        else
            Phone.calcDisplay = "-" .. d
        end
        return
    end
    if key == "." then
        if Phone.calcFresh then
            Phone.calcDisplay = "0."
            Phone.calcFresh = false
            Phone.calcDot = true
            return
        end
        if not Phone.calcDot and not d:find(".", 1, true) then
            Phone.calcDisplay = d .. "."
            Phone.calcDot = true
        end
        return
    end
    if key == "%" then
        local n = tonumber(d)
        if n then
            Phone.calcDisplay = tostring(n / 100)
            Phone.calcFresh = true
        end
        return
    end
    local ops = {["+"] = true, ["-"] = true, ["x"] = true, ["/"] = true}
    if ops[key] or key == "=" then
        local n = tonumber(d)
        if not n then
            Phone.calcDisplay = "0"
            return
        end
        if Phone.calcAcc and Phone.calcOp and not Phone.calcFresh then
            local a = Phone.calcAcc
            local op = Phone.calcOp
            local res = n
            if op == "+" then res = a + n
            elseif op == "-" then res = a - n
            elseif op == "x" then res = a * n
            elseif op == "/" then
                if n == 0 then
                    Phone.calcDisplay = "Hata"
                    Phone.calcAcc = nil
                    Phone.calcOp = nil
                    Phone.calcFresh = true
                    return
                end
                res = a / n
            end
            if res ~= math.floor(res) then
                Phone.calcDisplay = string.format("%.6f", res):gsub("0+$", ""):gsub("%.$", "")
            else
                Phone.calcDisplay = tostring(res)
            end
            Phone.calcAcc = res
        else
            Phone.calcAcc = n
        end
        Phone.calcOp = (key == "=") and nil or key
        Phone.calcFresh = true
        Phone.calcDot = false
        return
    end
    if key:match("^%d$") then
        if Phone.calcFresh or d == "0" or d == "Hata" then
            Phone.calcDisplay = key
            Phone.calcFresh = false
            Phone.calcDot = false
        elseif #d < 12 then
            Phone.calcDisplay = d .. key
        end
    end
end
Phone.calcPress = calcInput

drawCalculator = function(x, y, w, h, s)
    header(x, y, w, s, "Hesap")
    drawRounded(x + 14 * s, y + 84 * s, w - 28 * s, 70 * s, 16 * s, C(16, 20, 26, 245))
    text(Phone.calcDisplay or "0", x + 24 * s, y + 96 * s, w - 48 * s, 48 * s, C(255, 255, 255), 1.35, "right")
    local keys = {
        {"C", "+/-", "%", "/"},
        {"7", "8", "9", "x"},
        {"4", "5", "6", "-"},
        {"1", "2", "3", "+"},
        {"0", "", ".", "="},
    }
    local pad = 8 * s
    local kw = (w - 28 * s - pad * 3) / 4
    local kh = 44 * s
    local top = y + 166 * s
    for r = 1, #keys do
        for c = 1, 4 do
            local key = keys[r][c]
            if key ~= "" then
                local kx = x + 14 * s + (c - 1) * (kw + pad)
                local ky = top + (r - 1) * (kh + pad)
                if ky + kh < y + h - 20 * s then
                    local isOp = (key == "+" or key == "-" or key == "x" or key == "/" or key == "=")
                    local bg = isOp and C(240, 154, 55, 250) or C(255, 255, 255, 20)
                    if key == "C" or key == "+/-" or key == "%" then
                        bg = C(88, 94, 108, 240)
                    end
                    local ww = key == "0" and (kw * 2 + pad) or kw
                    drawRounded(kx, ky, ww, kh, 14 * s, bg)
                    text(key, kx, ky, ww, kh, C(255, 255, 255), 0.95, "center")
                    addHit("calc:" .. key, kx, ky, ww, kh)
                end
            end
        end
    end
end

local function drawCallOverlay(x, y, w, h, s)
    local sx, sy = guiGetScreenSize()
    dxDrawRectangle(0, 0, sx, sy, C(0, 0, 0, 130), false)
    drawRounded(x + 18 * s, y + 180 * s, w - 36 * s, 260 * s, 24 * s, C(16, 20, 28, 252))
    text("TELEFON ARAMASI", x + 32 * s, y + 200 * s, w - 64 * s, 26 * s, C(180, 190, 205), 0.68, "center")
    text(str(Phone.call.number or "Bilinmeyen"), x + 32 * s, y + 240 * s, w - 64 * s, 42 * s, C(255, 255, 255), 1.15, "center")
    text(str(Phone.call.status or "Araniyor..."), x + 32 * s, y + 288 * s, w - 64 * s, 30 * s, C(120, 220, 165), 0.8, "center")
    if Phone.call.status == "Gelen arama" then
        drawRounded(x + 36 * s, y + 350 * s, 108 * s, 46 * s, 16 * s, C(45, 140, 78, 255))
        text("KABUL", x + 36 * s, y + 350 * s, 108 * s, 46 * s, C(255, 255, 255), 0.72, "center")
        addHit("call:accept", x + 36 * s, y + 350 * s, 108 * s, 46 * s)
        drawRounded(x + w - 144 * s, y + 350 * s, 108 * s, 46 * s, 16 * s, C(160, 55, 62, 255))
        text("REDDET", x + w - 144 * s, y + 350 * s, 108 * s, 46 * s, C(255, 255, 255), 0.72, "center")
        addHit("call:end", x + w - 144 * s, y + 350 * s, 108 * s, 46 * s)
    else
        drawRounded(x + (w - 148 * s) / 2, y + 350 * s, 148 * s, 46 * s, 16 * s, C(160, 55, 62, 255))
        text("KAPAT", x + (w - 148 * s) / 2, y + 350 * s, 148 * s, 46 * s, C(255, 255, 255), 0.75, "center")
        addHit("call:end", x + (w - 148 * s) / 2, y + 350 * s, 148 * s, 46 * s)
    end
end

drawPhone = function()
    if not Phone.open then
        return
    end
    clickList = {}
    local x, y, w, h, s = phoneRect()
    if w <= 0 or h <= 0 then
        return
    end
    local bezel = 10
    drawRounded(x - bezel, y - bezel, w + bezel * 2, h + bezel * 2, 42, C(6, 6, 8, 255))
    drawRounded(x - 3, y - 3, w + 6, h + 6, 36, C(28, 30, 34, 255))
    drawRounded(x, y, w, h, 32, C(0, 0, 0, 255))

    if Phone.page == "camera" then
        drawCamera(x, y, w, h, s)
    else
        -- Slightly stronger dim on app pages so text stays readable over wallpaper
        wallpaper(x, y, w, h, Phone.page == "home" and 42 or 110)
        if Phone.page == "home" then
            drawHome(x, y, w, h, s)
        elseif Phone.page == "gallery" then
            drawGallery(x, y, w, h, s)
        elseif Phone.page == "calls" then
            drawCalls(x, y, w, h, s)
        elseif Phone.page == "messages" then
            drawMessages(x, y, w, h, s)
        elseif Phone.page == "stagegram" then
            drawSocial(x, y, w, h, s, "instagram", "Stagegram")
        elseif Phone.page == "stagex" then
            drawSocial(x, y, w, h, s, "twitter", "StageX")
        elseif Phone.page == "settings" then
            drawSettings(x, y, w, h, s)
        elseif Phone.page == "contacts" then
            drawContacts(x, y, w, h, s)
        elseif Phone.page == "notes" then
            drawNotes(x, y, w, h, s)
        elseif Phone.page == "calculator" then
            drawCalculator(x, y, w, h, s)
        else
            header(x, y, w, s, Phone.page)
            text("Bu uygulama Stage Phone altyapisina hazir.", x + 24 * s, y + 180 * s, w - 48 * s, 48 * s, C(190, 198, 210), 0.7, "center", "center", true)
        end
    end
    drawStatus(x, y, w, s)
    homeIndicator(x, y, w, h, s)
    maskCorners(x, y, w, h, 22, C(6, 6, 8, 255))
    if Phone.call and Phone.call.active then
        drawCallOverlay(x, y, w, h, s)
    end
end

local function onPreRender()
    if Phone.open and Phone.page == "camera" and screenSource and isElement(screenSource) then
        dxUpdateScreenSource(screenSource, true)
    end
end

local function bindRender()
    if not renderBound then
        addEventHandler("onClientRender", root, drawPhone, true, "low-5")
        renderBound = true
    end
    if not preRenderBound then
        addEventHandler("onClientPreRender", root, onPreRender)
        preRenderBound = true
    end
end

local function unbindRender()
    if renderBound then
        removeEventHandler("onClientRender", root, drawPhone)
        renderBound = false
    end
    if preRenderBound then
        removeEventHandler("onClientPreRender", root, onPreRender)
        preRenderBound = false
    end
end

local function setInputMode(open)
    if open then
        showCursor(true)
        if type(guiSetInputMode) == "function" then
            guiSetInputMode("no_binds")
        end
    else
        showCursor(false)
        if type(guiSetInputMode) == "function" then
            guiSetInputMode("allow_binds")
        end
    end
end

setPhoneOpen = function(state, page)
    state = state and true or false
    if state then
        Phone.open = true
        Phone.setPage(page or Phone.page or "home")
        setInputMode(true)
        bindRender()
        if localPlayer and isElement(localPlayer) then
            triggerServerEvent("stagephone:load", localPlayer)
        end
    else
        Phone.open = false
        Phone.inputFocus = nil
        destroyCameraSource()
        Phone.camera = false
        setInputMode(false)
        unbindRender()
    end
end

function togglePhone()
    if Phone.open then
        if Phone.call and Phone.call.active then
            if localPlayer and isElement(localPlayer) then
                triggerServerEvent("stagephone:callEnd", localPlayer)
            end
            Phone.call = nil
        end
        setPhoneOpen(false)
    else
        Phone.page = "home"
        setPhoneOpen(true, "home")
    end
end

function isEventHandlerAdded(eventName, attachedTo, fn)
    if type(eventName) ~= "string" or not isElement(attachedTo) or type(fn) ~= "function" then
        return false
    end
    if type(getEventHandlers) ~= "function" then
        return false
    end
    local ok, attached = pcall(getEventHandlers, eventName, attachedTo)
    if not ok or type(attached) ~= "table" then
        return false
    end
    for i = 1, #attached do
        if attached[i] == fn then
            return true
        end
    end
    return false
end

local function mergeServerData(data)
    if type(data) ~= "table" then
        data = {}
    end
    Phone.data = data
    if type(data.gallery) == "table" then
        local merged = {}
        local seen = {}
        for i = 1, #Phone.gallery do
            local p = Phone.gallery[i]
            if p and not seen[p] then
                merged[#merged + 1] = p
                seen[p] = true
            end
        end
        for i = 1, #data.gallery do
            local row = data.gallery[i]
            local path = nil
            if type(row) == "table" then
                path = row.image_url
            elseif type(row) == "string" then
                path = row
            end
            if path and not seen[path] then
                merged[#merged + 1] = path
                seen[path] = true
            end
        end
        Phone.gallery = merged
        saveGallery()
    end
    if type(data.calls) == "table" then
        Phone.callHistory = data.calls
    end
    if type(data.contacts) == "table" and #data.contacts > 0 then
        Phone.contacts = data.contacts
        saveContacts()
    end
    if type(data.notes) == "table" and #data.notes > 0 then
        Phone.notes = data.notes
        saveNotes()
    end
end

addEvent("stagephone:data", true)
addEventHandler("stagephone:data", root, function(data)
    mergeServerData(data)
end)

addEvent("stagephone:error", true)
addEventHandler("stagephone:error", root, function(msg)
    outputChatBox("[Telefon] " .. str(msg), 255, 200, 0)
    if Phone.call and Phone.call.status == "Araniyor..." then
        Phone.call = nil
    end
end)

addEvent("stagephone:incomingCall", true)
addEventHandler("stagephone:incomingCall", root, function(number)
    Phone.call = {active = true, number = str(number), status = "Gelen arama"}
    Phone.page = "calls"
    setPhoneOpen(true, "calls")
    if Phone.sound then
        playSoundFrontEnd(45)
    end
end)

addEvent("stagephone:callStatus", true)
addEventHandler("stagephone:callStatus", root, function(status, number)
    Phone.call = {active = true, number = str(number), status = str(status)}
end)

addEvent("stagephone:endCall", true)
addEventHandler("stagephone:endCall", root, function()
    Phone.call = nil
end)

addEvent("stagephone:messageReceived", true)
addEventHandler("stagephone:messageReceived", root, function(sender, message)
    outputChatBox("[Telefon] " .. str(sender) .. ": " .. str(message), 120, 200, 255)
end)

local function startCall()
    if Phone.callInput == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:call", localPlayer, Phone.callInput)
    end
    Phone.call = {active = true, number = Phone.callInput, status = "Araniyor..."}
end

local function sendMessage()
    if Phone.msgTarget == "" or Phone.msgText == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:message", localPlayer, Phone.msgTarget, Phone.msgText)
    end
    Phone.msgText = ""
end

local function handleClick(id)
    if id == "back" or id == "home" then
        if Phone.selectedPhoto then
            Phone.selectedPhoto = nil
            return
        end
        Phone.setPage("home")
        return
    end
    if id:sub(1, 4) == "app:" then
        Phone.setPage(id:sub(5))
        return
    end
    if id:sub(1, 5) == "dock:" then
        Phone.setPage(id:sub(6))
        return
    end
    if id == "camera:shot" then
        capturePhoto()
        return
    end
    if id:sub(1, 5) == "dial:" then
        local maxC = cfg().maxCallInput or 16
        local k = id:sub(6)
        if #(Phone.callInput or "") < maxC then
            Phone.callInput = (Phone.callInput or "") .. k
        end
        Phone.inputFocus = "call"
        return
    end
    if id == "call:dial" then
        startCall()
        return
    end
    if id == "call:accept" then
        if localPlayer and isElement(localPlayer) then
            triggerServerEvent("stagephone:callAnswer", localPlayer)
        end
        if Phone.call then
            Phone.call.status = "Gorusmede"
        end
        return
    end
    if id == "call:end" then
        if localPlayer and isElement(localPlayer) then
            triggerServerEvent("stagephone:callEnd", localPlayer)
        end
        Phone.call = nil
        return
    end
    if id == "msg:send" then
        sendMessage()
        return
    end
    if id:sub(1, 6) == "scale:" then
        Phone.setScale(tonumber(id:sub(7)))
        return
    end
    if id:sub(1, 3) == "bg:" then
        Phone.setBackground(tonumber(id:sub(4)))
        return
    end
    if id == "toggle:island" then
        Phone.island = not Phone.island
        saveSettings()
        return
    end
    if id == "toggle:sound" then
        Phone.sound = not Phone.sound
        saveSettings()
        return
    end
    if id == "social:post" then
        local textPost = str(Phone.socialText)
        textPost = textPost:gsub("^%s+", ""):gsub("%s+$", "")
        if textPost == "" then
            return
        end
        local kind = Phone.page == "stagegram" and "instagram" or "twitter"
        local image = nil
        if kind == "instagram" and Phone.gallery and Phone.gallery[1] then
            image = Phone.gallery[1]
        end
        if localPlayer and isElement(localPlayer) then
            triggerServerEvent("stagephone:post", localPlayer, kind, textPost, image)
        end
        Phone.socialText = ""
        return
    end
    if id:sub(1, 8) == "gallery:" then
        if id == "gallery:close" then
            Phone.selectedPhoto = nil
            return
        end
        local idx = tonumber(id:sub(9))
        if idx and Phone.gallery and Phone.gallery[idx] then
            Phone.selectedPhoto = Phone.gallery[idx]
        end
        return
    end
    if id:sub(1, 6) == "focus:" then
        Phone.inputFocus = id:sub(7)
        return
    end
    if id == "contact:add" then
        if Phone.contactName ~= "" and Phone.contactNumber ~= "" then
            Phone.contacts = Phone.contacts or {}
            table.insert(Phone.contacts, 1, {name = Phone.contactName, number = Phone.contactNumber})
            saveContacts()
            if localPlayer and isElement(localPlayer) then
                triggerServerEvent("stagephone:contact", localPlayer, Phone.contactName, Phone.contactNumber)
            end
            Phone.contactName = ""
            Phone.contactNumber = ""
        end
        return
    end
    if id:sub(1, 13) == "contact:call:" then
        local idx = tonumber(id:sub(14))
        local list = Phone.contacts or {}
        if Phone.data and type(Phone.data.contacts) == "table" and #Phone.data.contacts > 0 then
            list = Phone.data.contacts
        end
        if idx and list[idx] and list[idx].number then
            Phone.callInput = str(list[idx].number)
            Phone.setPage("calls")
        end
        return
    end
    if id == "note:save" then
        if Phone.noteTitle ~= "" or Phone.noteBody ~= "" then
            local title = Phone.noteTitle ~= "" and Phone.noteTitle or "Not"
            Phone.notes = Phone.notes or {}
            table.insert(Phone.notes, 1, {title = title, body = Phone.noteBody})
            saveNotes()
            if localPlayer and isElement(localPlayer) then
                triggerServerEvent("stagephone:note", localPlayer, title, Phone.noteBody)
            end
            Phone.noteTitle = ""
            Phone.noteBody = ""
        end
        return
    end
    if id:sub(1, 10) == "note:open:" then
        local idx = tonumber(id:sub(11))
        local list = Phone.notes or {}
        if idx and list[idx] then
            Phone.noteTitle = str(list[idx].title)
            Phone.noteBody = str(list[idx].body)
            Phone.inputFocus = "noteBody"
        end
        return
    end
    if id:sub(1, 5) == "calc:" then
        calcInput(id:sub(6))
        return
    end
end

addEventHandler("onClientClick", root, function(btn, state)
    if not Phone.open or btn ~= "left" or state ~= "down" then
        return
    end
    local cx, cy = getCursorPosition()
    if not cx or not cy then
        return
    end
    local sx, sy = guiGetScreenSize()
    local mx, my = cx * sx, cy * sy
    for i = #clickList, 1, -1 do
        local a = clickList[i]
        if a and hit(mx, my, a.x, a.y, a.w, a.h) then
            handleClick(a.id)
            return
        end
    end
end)

local function fieldMax(focus)
    local c = cfg()
    if focus == "call" then return c.maxCallInput or 16 end
    if focus == "msgText" then return c.maxMessageLength or 500 end
    if focus == "socialText" then
        if Phone.page == "stagex" then return c.maxTweetLength or 280 end
        return c.maxPostCaption or 500
    end
    if focus == "noteBody" then return c.maxNoteLength or 2000 end
    if focus == "noteTitle" then return 80 end
    if focus == "contactName" then return 32 end
    if focus == "contactNumber" then return 16 end
    if focus == "msgTarget" then return 32 end
    return 64
end

local function appendField(c)
    local focus = Phone.inputFocus
    if not focus then
        return
    end
    local maxLen = fieldMax(focus)
    local function add(cur)
        cur = str(cur)
        if #cur >= maxLen then
            return cur
        end
        return cur .. c
    end
    if focus == "call" then
        if c:match("[0-9%*#%+]") then
            Phone.callInput = add(Phone.callInput)
        end
    elseif focus == "msgTarget" then
        Phone.msgTarget = add(Phone.msgTarget)
    elseif focus == "msgText" then
        Phone.msgText = add(Phone.msgText)
    elseif focus == "socialText" then
        Phone.socialText = add(Phone.socialText)
    elseif focus == "noteTitle" then
        Phone.noteTitle = add(Phone.noteTitle)
    elseif focus == "noteBody" then
        Phone.noteBody = add(Phone.noteBody)
    elseif focus == "contactName" then
        Phone.contactName = add(Phone.contactName)
    elseif focus == "contactNumber" then
        if c:match("[0-9%+]") then
            Phone.contactNumber = add(Phone.contactNumber)
        end
    end
end

local function backspaceField()
    local focus = Phone.inputFocus
    local function cut(v)
        v = str(v)
        if #v <= 0 then return "" end
        return v:sub(1, -2)
    end
    if focus == "call" or Phone.page == "calls" then
        Phone.callInput = cut(Phone.callInput)
    elseif focus == "msgTarget" then
        Phone.msgTarget = cut(Phone.msgTarget)
    elseif focus == "msgText" then
        Phone.msgText = cut(Phone.msgText)
    elseif focus == "socialText" then
        Phone.socialText = cut(Phone.socialText)
    elseif focus == "noteTitle" then
        Phone.noteTitle = cut(Phone.noteTitle)
    elseif focus == "noteBody" then
        Phone.noteBody = cut(Phone.noteBody)
    elseif focus == "contactName" then
        Phone.contactName = cut(Phone.contactName)
    elseif focus == "contactNumber" then
        Phone.contactNumber = cut(Phone.contactNumber)
    elseif Phone.page == "messages" then
        Phone.msgText = cut(Phone.msgText)
    end
end

addEventHandler("onClientCharacter", root, function(c)
    if not Phone.open then
        return
    end
    if not Phone.inputFocus then
        if Phone.page == "calls" then
            Phone.inputFocus = "call"
        elseif Phone.page == "messages" then
            Phone.inputFocus = "msgText"
        else
            return
        end
    end
    if type(c) ~= "string" or c == "" then
        return
    end
    appendField(c)
end)

addEventHandler("onClientKey", root, function(key, press)
    if not Phone.open or not press then
        return
    end
    if key == "escape" then
        cancelEvent()
        if Phone.selectedPhoto then
            Phone.selectedPhoto = nil
            return
        end
        if Phone.call and Phone.call.active then
            if localPlayer and isElement(localPlayer) then
                triggerServerEvent("stagephone:callEnd", localPlayer)
            end
            Phone.call = nil
            return
        end
        if Phone.page ~= "home" then
            Phone.setPage("home")
            return
        end
        togglePhone()
        return
    end
    if key == "backspace" then
        cancelEvent()
        backspaceField()
        return
    end
    if key == "enter" then
        cancelEvent()
        if Phone.page == "calls" then
            startCall()
        elseif Phone.page == "messages" then
            sendMessage()
        elseif Phone.page == "stagegram" or Phone.page == "stagex" then
            handleClick("social:post")
        elseif Phone.page == "notes" then
            handleClick("note:save")
        elseif Phone.page == "contacts" then
            handleClick("contact:add")
        end
        return
    end
    if key == "t" or key == "y" then
        cancelEvent()
    end
end)

preloadAssets = function()
    getTex(BG_FALLBACK)
    for i = 1, 3 do
        getTex(bgPath(i))
    end
    for i = 1, #apps do
        getAppIcon(apps[i][1])
    end
    fontBold = "default-bold"
    fontMain = "default"
    if fileExists("assets/fonts/SFPro.ttf") then
        local created = dxCreateFont("assets/fonts/SFPro.ttf", 12, false, "proof")
        if created and isElement(created) then
            fontBold = created
        else
            dbg("Font yuklenemedi, varsayilan kullaniliyor.")
        end
    end
end

local function cleanup()
    setPhoneOpen(false)
    destroyCameraSource()
    destroyTex(textures)
    iconTextures = {}
    if fontBold and isElement(fontBold) then
        destroyElement(fontBold)
        fontBold = "default-bold"
    end
    Phone.call = nil
    Phone.open = false
    renderBound = false
    preRenderBound = false
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    loadSettings()
    loadLocalData()
    preloadAssets()
    local c = cfg()
    if c.key and type(c.key) == "string" then
        bindKey(c.key, "down", togglePhone)
    end
    if c.command and type(c.command) == "string" then
        addCommandHandler(c.command, togglePhone)
    end
    dbg("Client hazir.")
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    cleanup()
end)
