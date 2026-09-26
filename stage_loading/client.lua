local screenW, screenH = guiGetScreenSize()
local browserGUI, theBrowser = nil, nil
-- F10 tarayicisi bir kez yuklenir; sonraki acilislar anlik olur.
local menuBrowserGUI, menuBrowser = nil, nil
local menuBrowserReady = false
local cinematicActive = false
local pendingChars = nil
stageInGame = false
menuOpen = false
hudStyle = 1
speedoStyle = 1
fontStyle = 1
healthMode = 1 -- 1 yazi+bar, 2 sadece bar, 3 sadece yazi
nameBarOn = true
crosshairOn = false
crosshairStyle = 1
crosshairSize = 8

-- ========== BROWSER ==========
local function closeBrowser()
    if isElement(browserGUI) then
        destroyElement(browserGUI)
    end
    browserGUI, theBrowser = nil, nil
end

local function sendMenuSelection()
    if isElement(menuBrowser) then
        executeBrowserJavascript(menuBrowser, string.format("setHudSelection(%d,%d,%d,%d,%d);", hudStyle, speedoStyle, fontStyle or 1, healthMode or 1, crosshairOn and (crosshairStyle or 1) or 0))
    end
end

local function createMenuBrowser()
    menuBrowserGUI = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)
    if not menuBrowserGUI then return false end
    menuBrowser = guiGetBrowser(menuBrowserGUI)
    guiSetVisible(menuBrowserGUI, false)
    addEventHandler("onClientBrowserCreated", menuBrowser, function()
        loadBrowserURL(menuBrowser, "http://mta/local/html/menu.html")
        setTimer(function()
            if isElement(menuBrowser) then
                menuBrowserReady = true
                if menuOpen then
                    guiSetVisible(menuBrowserGUI, true)
                    focusBrowser(menuBrowser)
                    sendMenuSelection()
                end
            end
        end, 350, 1)
    end)
    return true
end

local function createBrowserPage(url, onReady)
    closeBrowser()
    browserGUI = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)
    if not browserGUI then
        outputChatBox("#FF5555[Stage] Browser olusturulamadi!", 255, 255, 255, true)
        return
    end
    theBrowser = guiGetBrowser(browserGUI)
    addEventHandler("onClientBrowserCreated", theBrowser, function()
        loadBrowserURL(theBrowser, url)
        focusBrowser(theBrowser)
        guiSetInputMode("no_binds")
        showCursor(true)
        outputChatBox("#AAAAAA[Stage] Ekran yukleniyor...", 255, 255, 255, true)
        if onReady then
            setTimer(onReady, 600, 1)
        end
    end)
end

local function jsString(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", "\\n"):gsub("\r", "")
    return "'" .. value .. "'"
end

local function sendLoadingConfig()
    if not isElement(theBrowser) then return end
    local cfg = StageClientConfig or {}
    local songs = {}
    for _, song in ipairs(cfg.playlist or {}) do
        songs[#songs + 1] = string.format(
            "{title:%s,artist:%s,url:%s}",
            jsString(song.title or "Stage Track"),
            jsString(song.artist or "Stage Gaming"),
            jsString(song.url or "")
        )
    end
    executeBrowserJavascript(theBrowser, string.format(
        "window.applyStageConfig&&window.applyStageConfig({brand:%s,discord:%s,subtitle:%s,video:%s,cover:%s,volume:%s,playlist:[%s]});",
        jsString(cfg.brand or "Stage Gaming"),
        jsString(cfg.discord or "discord.gg/stagegaming"),
        jsString(cfg.loadingSubtitle or "Sunucu dosyalari yukleniyor..."),
        jsString(cfg.backgroundVideo or "assets/video.mp4"),
        jsString(cfg.musicCover or "assets/music_cover.png"),
        tostring(tonumber(cfg.defaultVolume) or 0.4),
        table.concat(songs, ",")
    ))
end

local function showLoginScreen()
    fadeCamera(true, 0.5)
    setPlayerHudComponentVisible("all", false)
    showChat(false)
    showCursor(true)
    setCameraMatrix(1463.5, -1043.8, 78.0, 1480.0, -900.0, 40.0)
    createBrowserPage("http://mta/local/html/index.html", sendLoadingConfig)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(showLoginScreen, 500, 1)
end)

-- ========== SINEMATIK ==========
local CINE_PATH = {
    {1463.5, -1043.8, 78.0,  1480.0, -900.0, 40.0},
    {1550.0, -1200.0, 55.0,  1700.0, -1400.0, 25.0},
    {1750.0, -1500.0, 40.0,  1900.0, -1650.0, 20.0},
    {1900.0, -1700.0, 28.0,  1969.0, -1760.0, 14.0},
    {1969.8, -1785.0, 22.0,  1969.8, -1760.0, 13.5},
}
local CINE_TIME = 6000

local function easeInOut(t)
    if t < 0.5 then return 2 * t * t end
    return 1 - ((-2 * t + 2) ^ 2) / 2
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function samplePath(path, t)
    local n = #path
    if n == 1 then return unpack(path[1]) end
    local seg = (n - 1) * t
    local i = math.floor(seg) + 1
    if i >= n then return unpack(path[n]) end
    local f = easeInOut(seg - (i - 1))
    local a, b = path[i], path[i + 1]
    return lerp(a[1], b[1], f), lerp(a[2], b[2], f), lerp(a[3], b[3], f),
           lerp(a[4], b[4], f), lerp(a[5], b[5], f), lerp(a[6], b[6], f)
end

function startCinematic()
    if cinematicActive then return end
    cinematicActive = true
    closeBrowser()
    showChat(false)
    showCursor(false)
    setPlayerHudComponentVisible("all", false)
    guiSetInputMode("allow_binds")
    fadeCamera(false, 0.4)

    setTimer(function()
        fadeCamera(true, 1.0)
        local startTick = getTickCount()
        local cx, cy, cz, lx, ly, lz = samplePath(CINE_PATH, 0)
        setCameraMatrix(cx, cy, cz, lx, ly, lz)

        local function renderCine()
            local progress = (getTickCount() - startTick) / CINE_TIME
            if progress >= 1 then
                removeEventHandler("onClientRender", root, renderCine)
                cinematicActive = false
                local ex, ey, ez, elx, ely, elz = unpack(CINE_PATH[#CINE_PATH])
                setCameraMatrix(ex, ey, ez, elx, ely, elz)
                fadeCamera(false, 0.5)
                setTimer(function()
                    fadeCamera(true, 0.6)
                    openCharUI(pendingChars)
                end, 550, 1)
                return
            end
            local x, y, z, lx, ly, lz = samplePath(CINE_PATH, progress)
            setCameraMatrix(x, y, z, lx, ly, lz)
        end
        addEventHandler("onClientRender", root, renderCine)
    end, 450, 1)
end

-- ========== LOGIN ==========
addEvent("stageLogin", true)
addEventHandler("stageLogin", root, function(username, password, isRegister)
    outputChatBox("#AAAAAA[Stage] Giris istegi gonderiliyor...", 255, 255, 255, true)
    triggerServerEvent("stageLoginServer", localPlayer, username, password, isRegister)
end)

addEvent("stageLoginResult", true)
addEventHandler("stageLoginResult", root, function(success, message)
    outputChatBox((success and "#00FF88" or "#FF5555") .. "[Stage] #FFFFFF" .. tostring(message), 255, 255, 255, true)
    if not success then
        if isElement(theBrowser) then
            local safe = tostring(message or "Hata"):gsub("'", "\\'")
            executeBrowserJavascript(theBrowser, "showError('" .. safe .. "')")
        end
        return
    end
    closeBrowser()
    showCursor(false)
    guiSetInputMode("allow_binds")
end)

addEvent("stageShowChars", true)
addEventHandler("stageShowChars", root, function(chars)
    pendingChars = chars
    -- Karakter degistirden geliyorsa direkt secim ekrani (sinematik yok)
    if getElementData(localPlayer, "stage:logged") and not stageInGame then
        closeBrowser()
        showChat(false)
        showCursor(false)
        setPlayerHudComponentVisible("all", false)
        fadeCamera(false, 0.3)
        setTimer(function()
            fadeCamera(true, 0.5)
            openCharUI(pendingChars)
        end, 400, 1)
    else
        startCinematic()
    end
end)

-- ========== CHAR UI ==========
function sendCharsToJS(chars)
    if not isElement(theBrowser) then return end
    local parts = {}
    for i = 1, 3 do
        local c = chars and chars[i]
        if c and c.empty ~= true and c.name then
            parts[i] = string.format(
                '{slot:%d,name:%q,surname:%q,age:%d,height:%d,skin:%d,country:%q,empty:false,money:%d}',
                tonumber(c.slot) or i,
                tostring(c.name or ""),
                tostring(c.surname or ""),
                tonumber(c.age) or 18,
                tonumber(c.height) or 175,
                tonumber(c.skin) or 0,
                tostring(c.country or "TR"),
                tonumber(c.money) or 0
            )
        else
            parts[i] = string.format('{slot:%d,empty:true}', i)
        end
    end
    executeBrowserJavascript(theBrowser, "setCharacters([" .. table.concat(parts, ",") .. "]);")
end

function openCharUI(chars)
    createBrowserPage("http://mta/local/html/chars.html", function()
        sendCharsToJS(chars)
    end)
end

addEvent("stageCreateChar", true)
addEventHandler("stageCreateChar", root, function(slot, name, surname, age, height, skin, country)
    triggerServerEvent("stageCreateChar", localPlayer, slot, name, surname, age, height, skin, country)
end)

addEvent("stageSelectChar", true)
addEventHandler("stageSelectChar", root, function(slot)
    triggerServerEvent("stageSelectChar", localPlayer, slot)
end)

addEvent("stageCharResult", true)
addEventHandler("stageCharResult", root, function(success, message, chars)
    if isElement(theBrowser) then
        local safe = tostring(message or ""):gsub("'", "\\'")
        executeBrowserJavascript(theBrowser, "showCharMsg('" .. safe .. "', " .. (success and "true" or "false") .. ")")
        if success and chars then
            sendCharsToJS(chars)
        end
    end
    outputChatBox((success and "#00FF88" or "#FF5555") .. "[Stage] #FFFFFF" .. tostring(message), 255, 255, 255, true)
end)

addEvent("stageSpawned", true)
addEventHandler("stageSpawned", root, function(char)
    closeBrowser()
    guiSetInputMode("allow_binds")
    showCursor(false)
    setPlayerHudComponentVisible("all", false) -- custom HUD kullanıyoruz
    showChat(true)
    setCameraTarget(localPlayer)
    local n = tostring(char and char.name or "") .. " " .. tostring(char and char.surname or "")
    outputChatBox("#00FF88[Stage] #FFFFFFHos geldin, " .. n, 255, 255, 255, true)
    outputChatBox("#AAAAAA[Stage] #FFFFFFMenü için #7dd3fcF10 #FFFFFFtuşuna bas.", 255, 255, 255, true)
    stageInGame = true
    setPlayerNametagShowing(localPlayer, false)
    loadHudPrefs()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    closeBrowser()
    if isElement(menuBrowserGUI) then destroyElement(menuBrowserGUI) end
    guiSetInputMode("allow_binds")
    showCursor(false)
    setPlayerHudComponentVisible("all", true)
    showChat(true)
end)



-- ========== CUSTOM NAMETAG + ICONS ==========
local iconSS, iconMic, iconWrite, iconRibbon

addEventHandler("onClientResourceStart", resourceRoot, function()
    iconSS = dxCreateTexture("assets/icon_ss.png")
    iconMic = dxCreateTexture("assets/icon_mic.png")
    iconWrite = dxCreateTexture("assets/icon_write.png")
    iconRibbon = dxCreateTexture("assets/icon_ribbon.png")
end)

local function drawNametagIcons(sx, sy, scale, alpha, player)
    local icons = {}
    -- Her zaman isim altinda/yaninda gosterilecek durum ikonlari
    if getElementData(player, "stage:ss") then icons[#icons+1] = iconSS end
    if getElementData(player, "stage:voice") or isElementStreamedIn(player) then
        -- mic: voice data varsa veya varsayilan gosterim icin stage:talking
        if getElementData(player, "stage:talking") then icons[#icons+1] = iconMic end
    end
    if getElementData(player, "stage:typing") then icons[#icons+1] = iconWrite end
    if getElementData(player, "stage:help") then icons[#icons+1] = iconRibbon end

    if #icons == 0 then return end
    local size = 18 * scale
    local gap = 4
    local totalW = #icons * size + (#icons - 1) * gap
    local startX = sx - totalW / 2
    local iy = sy - 22 * scale
    for i, tex in ipairs(icons) do
        if tex then
            dxDrawImage(startX + (i - 1) * (size + gap), iy, size, size, tex, 0, 0, 0, tocolor(255, 255, 255, alpha))
        end
    end
end

-- Nametag fontlari (XBold / XThin)
local nametagFontBold, nametagFontThin
addEventHandler("onClientResourceStart", resourceRoot, function()
    nametagFontBold = dxCreateFont("assets/hud/fonts/Poppins-Bold.ttf", 14) or "default-bold"
    nametagFontThin = dxCreateFont("assets/hud/fonts/Poppins-Regular.ttf", 14) or "default"
end)

local function getNametagFont()
    if fontStyle == 2 then
        return nametagFontThin or "default"
    end
    return nametagFontBold or "default-bold"
end

local function stageNametagRender()
    local px, py, pz = getElementPosition(localPlayer)
    local font = getNametagFont()
    for _, player in ipairs(getElementsByType("player", root, true)) do
        local name = getElementData(player, "stage:char")
        if name and type(name) == "string" and name ~= "" then
            local x, y, z = getElementPosition(player)
            local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
            if dist < 30 then
                local sx, sy = getScreenFromWorldPosition(x, y, z + 0.95)
                if sx and sy then
                    local scale = 1.15 - (dist / 35)
                    if scale < 0.65 then scale = 0.65 end
                    local alpha = 255
                    if dist > 20 then
                        alpha = math.floor(255 * (1 - (dist - 20) / 10))
                        if alpha < 0 then alpha = 0 end
                    end
                    -- isim biraz asagida (kafa ustu degil, omuz/gogus hizasi)
                    local nameY = sy + 18 * scale
                    drawNametagIcons(sx, nameY - 4 * scale, scale, alpha, player)

                    -- isim (secilen font: XBold / XThin)
                    dxDrawText(name, sx + 1, nameY + 1, sx + 1, nameY + 1, tocolor(0, 0, 0, math.floor(alpha * 0.85)), scale, font, "center", "bottom")
                    dxDrawText(name, sx, nameY, sx, nameY, tocolor(255, 255, 255, alpha), scale, font, "center", "bottom")

                    -- isim alti can bari + yuzde
                    if (tonumber(healthMode) or 1) ~= 3 then
                        local hp = math.floor(getElementHealth(player) or 100)
                        local barW = 72 * scale
                        local barH = 7 * scale
                        local bx = sx - barW / 2
                        local by = nameY + 6 * scale
                        local pad = 2 * scale

                        -- dis cerceve (koyu)
                        dxDrawRectangle(bx - pad, by - pad, barW + pad * 2, barH + pad * 2, tocolor(0, 0, 0, math.floor(alpha * 0.75)))
                        -- ic arka plan
                        dxDrawRectangle(bx, by, barW, barH, tocolor(25, 25, 32, alpha))

                        -- dolgu (gradient hissi: 2 katman)
                        local fill = barW * math.min(1, math.max(0, hp / 100))
                        local r, g, b = 120, 50, 200
                        if hp <= 25 then r, g, b = 210, 45, 45
                        elseif hp <= 50 then r, g, b = 230, 140, 35
                        elseif hp <= 75 then r, g, b = 90, 180, 90 end

                        if fill > 0 then
                            dxDrawRectangle(bx, by, fill, barH, tocolor(r, g, b, alpha))
                            -- ust parlak cizgi
                            dxDrawRectangle(bx, by, fill, math.max(1, barH * 0.35), tocolor(math.min(255, r + 50), math.min(255, g + 50), math.min(255, b + 50), math.floor(alpha * 0.55)))
                        end

                        if (tonumber(healthMode) or 1) ~= 2 then
                            local pct = hp .. "%"
                            dxDrawText(pct, sx + 1, by + barH / 2 + 1, sx + 1, by + barH / 2 + 1, tocolor(0, 0, 0, alpha), scale * 0.72, "default-bold", "center", "center")
                            dxDrawText(pct, sx, by + barH / 2, sx, by + barH / 2, tocolor(255, 255, 255, alpha), scale * 0.72, "default-bold", "center", "center")
                        end
                    elseif (tonumber(healthMode) or 1) == 3 then
                        local hp = math.floor(getElementHealth(player) or 100)
                        dxDrawText(hp .. "%", sx + 1, nameY + 8 * scale, sx + 1, nameY + 8 * scale, tocolor(0, 0, 0, alpha), scale * 0.72, "default-bold", "center", "center")
                        dxDrawText(hp .. "%", sx, nameY + 7 * scale, sx, nameY + 7 * scale, tocolor(255, 255, 255, alpha), scale * 0.72, "default-bold", "center", "center")
                    end
                end
            end
        end
    end
end
addEventHandler("onClientRender", root, stageNametagRender)

-- Ornek: B tusuna basili tutunca talking (test)
bindKey("b", "down", function()
    setElementData(localPlayer, "stage:talking", true, true)
end)
bindKey("b", "up", function()
    setElementData(localPlayer, "stage:talking", false, true)
end)
bindKey("t", "down", function()
    setElementData(localPlayer, "stage:typing", true, true)
end)
-- chat acilinca typing; kapaninca false (basit)
addEventHandler("onClientChatMessage", root, function()
    setElementData(localPlayer, "stage:typing", false, true)
end)

-- ========== F10 MENU + HUD + SPEEDOMETER ==========

local function loadHudPrefs()
    local h = tonumber(getElementData(localPlayer, "stage:hudStyle"))
    local s = tonumber(getElementData(localPlayer, "stage:speedoStyle"))
    local f = tonumber(getElementData(localPlayer, "stage:fontStyle"))
    local hm = tonumber(getElementData(localPlayer, "stage:healthMode"))
    local ch = tonumber(getElementData(localPlayer, "stage:crosshair"))
    if h and h >= 1 and h <= 3 then hudStyle = h end
    if s and s >= 1 and s <= 3 then speedoStyle = s end
    if f and f >= 1 and f <= 5 then fontStyle = f end
    if hm and hm >= 1 and hm <= 3 then healthMode = hm end
    nameBarOn = healthMode ~= 3
    if ch then
        if ch == 0 then
            crosshairOn = false
            crosshairStyle = 1
        else
            crosshairOn = true
            crosshairStyle = ch
        end
    end
end

local function saveHudPrefs()
    setElementData(localPlayer, "stage:hudStyle", hudStyle, false)
    setElementData(localPlayer, "stage:speedoStyle", speedoStyle, false)
    setElementData(localPlayer, "stage:fontStyle", fontStyle, false)
    setElementData(localPlayer, "stage:healthMode", healthMode, false)
    setElementData(localPlayer, "stage:nameBar", nameBarOn and 1 or 0, false)
    setElementData(localPlayer, "stage:crosshair", crosshairOn and (crosshairStyle or 1) or 0, false)
end

function StageHudSetOption(key, value)
    if key == "hudStyle" then
        value = tonumber(value)
        if value and value >= 1 and value <= 3 then hudStyle = value else return false end
    elseif key == "speedoStyle" then
        value = tonumber(value)
        if value and value >= 1 and value <= 3 then speedoStyle = value else return false end
    elseif key == "fontStyle" then
        value = tonumber(value)
        if value and value >= 1 and value <= 5 then fontStyle = value else return false end
    elseif key == "healthMode" then
        value = tonumber(value)
        if value and value >= 1 and value <= 3 then
            healthMode = value
            nameBarOn = healthMode ~= 3
        else
            return false
        end
    elseif key == "crosshair" then
        value = tonumber(value) or 0
        crosshairOn = value > 0
        crosshairStyle = value > 0 and value or 1
    else
        return false
    end
    saveHudPrefs()
    return true
end

function StageHudGetOptions()
    return {
        hudStyle = hudStyle,
        speedoStyle = speedoStyle,
        fontStyle = fontStyle,
        healthMode = healthMode,
        crosshair = crosshairOn and crosshairStyle or 0,
    }
end

function openStageMenu()
    if not stageInGame or menuOpen or cinematicActive then return end
    menuOpen = true
    showCursor(true)
    guiSetInputMode("no_binds")
    if not isElement(menuBrowserGUI) then
        createMenuBrowser()
    elseif menuBrowserReady then
        guiSetVisible(menuBrowserGUI, true)
        focusBrowser(menuBrowser)
        sendMenuSelection()
    end
end

function closeStageMenu()
    if not menuOpen then return end
    menuOpen = false
    if isElement(menuBrowserGUI) then guiSetVisible(menuBrowserGUI, false) end
    showCursor(false)
    guiSetInputMode("allow_binds")
end

bindKey("F10", "down", function()
    if not stageInGame then return end
    if menuOpen then
        closeStageMenu()
    else
        openStageMenu()
    end
end)

addEvent("stageMenuAction", true)
addEventHandler("stageMenuAction", root, function(action, a, b, c, d, e)
    if action == "close" then
        closeStageMenu()
    elseif action == "chars" then
        closeStageMenu()
        stageInGame = false
        showCursor(true)
        guiSetInputMode("no_binds_when_editing")
        triggerServerEvent("stageRequestCharSelect", localPlayer)
        outputChatBox("#00FF88[Stage] #FFFFFFKarakter secimine donuluyor...", 255, 255, 255, true)
    elseif action == "saveHud" then
        hudStyle = tonumber(a) or 1
        speedoStyle = tonumber(b) or 1
        fontStyle = tonumber(c) or 1
        healthMode = tonumber(d) or 1
        nameBarOn = healthMode ~= 3
        local ch = tonumber(e) or 0
        if ch == 0 then
            crosshairOn = false
            crosshairStyle = 1
        else
            crosshairOn = true
            crosshairStyle = ch
        end
        if hudStyle < 1 or hudStyle > 3 then hudStyle = 1 end
        if speedoStyle < 1 or speedoStyle > 3 then speedoStyle = 1 end
        if fontStyle < 1 or fontStyle > 5 then fontStyle = 1 end
        if healthMode < 1 or healthMode > 3 then healthMode = 1 end
        saveHudPrefs()
        local fontName = ({"Poppins Bold","Poppins Regular","Roboto","Bebas Neue","Default"})[fontStyle] or "Poppins Bold"
        local healthName = ({"Yazi + Bar","Sadece Bar","Sadece Yazi"})[healthMode] or "Yazi + Bar"
        local crossName = ({"Kapali","+","Nokta","Daire"})[ch + 1] or "Kapali"
        outputChatBox("#00FF88[Stage] #FFFFFFHUD " .. hudStyle .. " · Speedo " .. speedoStyle .. " · Font " .. fontName .. " · Can " .. healthName .. " · Cross " .. crossName, 255, 255, 255, true)
        closeStageMenu()
    end
end)
