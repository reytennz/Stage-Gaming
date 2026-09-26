-- CLIENT.LUA - Sinema Sistemi v3.0
-- YouTube / Twitch remote browser + 3D perde + senkronizasyon
-- Remote browser kullanıldığı için executeBrowserJavascript() KULLANILMAZ.
-- GUI tüm çözünürlüklerde otomatik olarak ortalanır ve ölçeklenir.

local screenWidth, screenHeight = guiGetScreenSize()

-- =========================================================
-- DEĞİŞKENLER
-- =========================================================

local mainWindow = nil
local settingsWindow = nil
local browserGUI = nil
local theBrowser = nil
local webBrowser = nil

local renderActive = false
local tocandoVideo = false
local browserReady = false
local pendingURL = nil
local pendingStartTime = 0

local texturePadrao = nil
local guiReady = false

local audioConfig = {
    volume = 100,
    muted = false,
    distEnabled = true,
    distMax = 50,
    distMin = 5
}

local distanceTimer = nil

-- Dünya üzerindeki sinema perdesi
local TELA = {
    x = 2317.4,
    y = -1542.4,
    z = 30,
    width = 18,
    height = 4.5
}

-- =========================================================
-- YARDIMCI FONKSİYONLAR
-- =========================================================

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function isValidURL(url)
    if not url or type(url) ~= "string" then
        return false
    end

    url = url:gsub("^%s+", ""):gsub("%s+$", "")

    if #url < 10 or #url > 512 then
        return false
    end

    return string.match(url, "^https?://") ~= nil
end

local function extractYouTubeID(url)
    if not url then return nil end

    local id = string.match(url, "[?&]v=([%w%-_]+)")
    if id then return id end

    id = string.match(url, "youtu%.be/([%w%-_]+)")
    if id then return id end

    id = string.match(url, "youtube%.com/live/([%w%-_]+)")
    if id then return id end

    id = string.match(url, "youtube%.com/embed/([%w%-_]+)")
    if id then return id end

    id = string.match(url, "youtube%.com/shorts/([%w%-_]+)")
    if id then return id end

    return nil
end

local function isLiveStream(url)
    if not url or url == "" then
        return false
    end

    return string.find(url, "youtube%.com/live/") ~= nil
        or string.find(url, "twitch%.tv") ~= nil
        or string.find(url, "facebook%.com/.+live") ~= nil
end

local function buildEmbedURL(url, startTime)
    if not url or url == "" then
        return ""
    end

    local startSecs = math.max(0, tonumber(startTime) or 0)

    -- YouTube
    if string.find(url, "youtube%.com") or string.find(url, "youtu%.be") then
        local id = extractYouTubeID(url)

        if id then
            return "https://www.youtube.com/embed/" .. id
                .. "?autoplay=1"
                .. "&iv_load_policy=3"
                .. "&fs=0"
                .. "&rel=0"
                .. "&modestbranding=1"
                .. "&playsinline=1"
                .. "&controls=1"
                .. "&start=" .. startSecs
        end
    end

    -- Twitch kanal
    local twitchChannel = string.match(url, "twitch%.tv/([%w_]+)")
    if twitchChannel and twitchChannel ~= "videos" then
        return "https://player.twitch.tv/?channel="
            .. twitchChannel
            .. "&parent=localhost"
            .. "&autoplay=true"
    end

    -- Twitch VOD
    local twitchVOD = string.match(url, "twitch%.tv/videos/(%d+)")
    if twitchVOD then
        return "https://player.twitch.tv/?video="
            .. twitchVOD
            .. "&parent=localhost"
            .. "&autoplay=true"
    end

    -- Normal HTTP/HTTPS adres
    return url
end

local function getDistanceVolume()
    if not audioConfig.distEnabled then
        return 1.0
    end

    if not isElement(localPlayer) then
        return 1.0
    end

    local px, py, pz = getElementPosition(localPlayer)
    local dist = getDistanceBetweenPoints3D(
        px, py, pz,
        TELA.x, TELA.y, TELA.z
    )

    local dMin = audioConfig.distMin
    local dMax = audioConfig.distMax

    if dMax <= dMin then
        return dist <= dMin and 1.0 or 0.0
    end

    if dist <= dMin then
        return 1.0
    end

    if dist >= dMax then
        return 0.0
    end

    return 1.0 - ((dist - dMin) / (dMax - dMin))
end

-- =========================================================
-- SES
-- =========================================================
-- ÖNEMLİ:
-- webBrowser remote browser olduğu için
-- executeBrowserJavascript() kullanılmıyor.
-- MTA'nın desteklediği setBrowserVolume() kullanılıyor.

local function applyAudioConfig()
    if not isElement(webBrowser) or not tocandoVideo then
        return
    end

    local distanceVolume = getDistanceVolume()

    local volume = audioConfig.muted and 0
        or ((audioConfig.volume / 100) * distanceVolume)

    volume = clamp(volume, 0, 1)

    setBrowserVolume(webBrowser, volume)
end

local function startDistanceTick()
    if distanceTimer and isTimer(distanceTimer) then
        return
    end

    distanceTimer = setTimer(function()
        if tocandoVideo and isElement(webBrowser) then
            applyAudioConfig()
        end
    end, 300, 0)
end

local function stopDistanceTick()
    if distanceTimer and isTimer(distanceTimer) then
        killTimer(distanceTimer)
        distanceTimer = nil
    end
end

-- =========================================================
-- 3D PERDE
-- =========================================================

local function webBrowserRender()
    local material = nil

    if tocandoVideo and isElement(webBrowser) then
        material = webBrowser
    elseif isElement(texturePadrao) then
        material = texturePadrao
    end

    if not material then
        return
    end

    dxDrawMaterialLine3D(
        TELA.x,
        TELA.y,
        TELA.z + TELA.height,

        TELA.x,
        TELA.y,
        TELA.z - TELA.height,

        material,
        TELA.width,

        tocolor(255, 255, 255, 255),

        TELA.x + 0.03,
        TELA.y + 1,
        TELA.z
    )
end

local function ensureRender()
    if renderActive then
        return
    end

    addEventHandler(
        "onClientPreRender",
        root,
        webBrowserRender
    )

    renderActive = true
end

-- =========================================================
-- VİDEO BAŞLAT / DURDUR
-- =========================================================

local function loadVideoURL(url, startTime)
    if not isElement(webBrowser) then
        return false
    end

    local finalURL = buildEmbedURL(url, startTime)

    if not isValidURL(finalURL) then
        outputChatBox(
            "[SİNEMA] Video adresi oluşturulamadı.",
            255, 80, 80
        )
        return false
    end

    pendingURL = finalURL
    pendingStartTime = tonumber(startTime) or 0

    if browserReady then
        loadBrowserURL(webBrowser, finalURL)
    end

    return true
end

local function startRender(url, startTime)
    if not url or url == "" then
        return
    end

    if not isElement(webBrowser) then
        outputChatBox(
            "[SİNEMA] Tarayıcı henüz hazır değil.",
            255, 100, 0
        )
        return
    end

    tocandoVideo = true
    ensureRender()

    loadVideoURL(url, startTime or 0)

    startDistanceTick()

    -- Browser'ın yüklenmesi için kısa bir gecikme
    setTimer(function()
        if tocandoVideo and isElement(webBrowser) then
            applyAudioConfig()
        end
    end, 1200, 1)

    if isLiveStream(url) then
        outputChatBox(
            "[SİNEMA] Canlı yayın perdeye yüklendi.",
            255, 80, 80
        )
    else
        outputChatBox(
            "[SİNEMA] Video perdeye yüklendi.",
            3, 252, 255
        )
    end
end

local function stopRender()
    tocandoVideo = false
    pendingURL = nil
    pendingStartTime = 0

    if isElement(webBrowser) then
        -- about:blank KULLANILMIYOR.
        -- MTA remote browser'da desteklenmeyen bir URL şemasıdır.
        setBrowserVolume(webBrowser, 0)
    end

    stopDistanceTick()
end

-- =========================================================
-- GUI YARDIMCILARI
-- =========================================================

local function centerWindow(window, width, height)
    local x = math.floor((screenWidth - width) / 2)
    local y = math.floor((screenHeight - height) / 2)

    guiSetPosition(window, x, y, false)
end

local function setButtonText(button, text)
    if isElement(button) then
        guiSetText(button, text)
    end
end

local function updateGUI()
    if not guiReady then
        return
    end

    if isElement(CINEMA and CINEMA.label and CINEMA.label[1]) then
        guiSetText(
            CINEMA.label[1],
            "Ses: " .. audioConfig.volume .. "%"
        )
    end

    if isElement(CINEMA and CINEMA.label and CINEMA.label[2]) then
        guiSetText(
            CINEMA.label[2],
            "Mesafe: " ..
            (audioConfig.distEnabled and "AÇIK" or "KAPALI")
        )
    end

    if isElement(CINEMA and CINEMA.label and CINEMA.label[3]) then
        guiSetText(
            CINEMA.label[3],
            "Maksimum: " .. audioConfig.distMax .. " m"
        )
    end

    if isElement(CINEMA and CINEMA.label and CINEMA.label[4]) then
        guiSetText(
            CINEMA.label[4],
            "Durum: " .. (audioConfig.muted and "SESSİZ" or "AÇIK")
        )
    end
end

local function getCurrentURL()
    if not isElement(CINEMA.edit[1]) then
        return ""
    end

    return guiGetText(CINEMA.edit[1]) or ""
end

local function showMainWindow(state)
    if not isElement(mainWindow) then
        return
    end

    guiSetVisible(mainWindow, state)

    if state then
        guiBringToFront(mainWindow)
        showCursor(true)
        guiSetInputEnabled(true)
    else
        if isElement(settingsWindow) then
            guiSetVisible(settingsWindow, false)
        end

        showCursor(false)
        guiSetInputEnabled(false)
    end
end

-- =========================================================
-- GUI
-- =========================================================

CINEMA = {
    button = {},
    edit = {},
    scroll = {},
    label = {}
}

addEventHandler("onClientResourceStart", resourceRoot, function()

    -- Varsayılan perde görüntüsü
    if fileExists("tela_padrao.png") then
        texturePadrao = dxCreateTexture(
            "tela_padrao.png",
            "argb",
            true,
            "clamp"
        )
    end

    -- Remote browser:
    -- YouTube / Twitch gibi internet içerikleri için FALSE.
    webBrowser = createBrowser(
        screenWidth,
        screenHeight,
        false,
        false
    )

    ensureRender()

    if isElement(webBrowser) then

        addEventHandler(
            "onClientBrowserCreated",
            webBrowser,
            function()

                browserReady = true

                -- Bekleyen video varsa yükle
                if pendingURL and pendingURL ~= "" then
                    loadBrowserURL(
                        source,
                        pendingURL
                    )
                else
                    -- Boş bırakmak yerine güvenli bir HTTP sayfası
                    -- kullanıyoruz. about:blank KULLANILMIYOR.
                    loadBrowserURL(
                        source,
                        "https://www.youtube.com"
                    )
                end

                if tocandoVideo then
                    setTimer(function()
                        if tocandoVideo and isElement(source) then
                            applyAudioConfig()
                        end
                    end, 1000, 1)
                end
            end
        )
    end

    -- =====================================================
    -- ANA PENCERE
    -- =====================================================

    local winW = math.min(820, screenWidth - 30)
    local winH = math.min(570, screenHeight - 40)

    winW = math.max(winW, 600)
    winH = math.max(winH, 430)

    mainWindow = guiCreateWindow(
        0, 0,
        winW, winH,
        "SİNEMA",
        false
    )

    centerWindow(mainWindow, winW, winH)

    guiWindowSetSizable(mainWindow, false)
    guiSetVisible(mainWindow, false)

    guiSetProperty(
        mainWindow,
        "CaptionColour",
        "FF00CCFF"
    )

    -- =====================================================
    -- URL
    -- =====================================================

    guiCreateLabel(
        15, 30,
        winW - 30, 20,
        "Video / yayın adresi",
        false,
        mainWindow
    )

    CINEMA.edit[1] = guiCreateEdit(
        15, 52,
        winW - 30, 32,
        "",
        false,
        mainWindow
    )

    guiEditSetMaxLength(
        CINEMA.edit[1],
        512
    )

    guiSetProperty(
        CINEMA.edit[1],
        "NormalTextColour",
        "FFFFFFFF"
    )

    -- =====================================================
    -- ANA BUTONLAR
    -- =====================================================

    local gap = 8
    local usableW = winW - 30

    local b1 = math.floor((usableW - gap * 2) / 3)

    CINEMA.button[1] = guiCreateButton(
        15, 92,
        b1, 38,
        "URL'Yİ AL",
        false,
        mainWindow
    )

    CINEMA.button[2] = guiCreateButton(
        15 + b1 + gap, 92,
        b1, 38,
        "HERKESE OYNAT",
        false,
        mainWindow
    )

    CINEMA.button[3] = guiCreateButton(
        15 + (b1 + gap) * 2, 92,
        b1, 38,
        "SİNEMAYI DURDUR",
        false,
        mainWindow
    )

    -- =====================================================
    -- TARAYICI ÖNİZLEME
    -- =====================================================

    local previewY = 142
    local previewH = winH - previewY - 105

    previewH = math.max(previewH, 180)

    browserGUI = guiCreateBrowser(
        15,
        previewY,
        usableW,
        previewH,
        false,
        false,
        false,
        mainWindow
    )

    theBrowser = guiGetBrowser(browserGUI)
    local guiBrowserElement = theBrowser

    if isElement(guiBrowserElement) then
        addEventHandler(
            "onClientBrowserCreated",
            guiBrowserElement,
            function()
                loadBrowserURL(
                    source,
                    "https://www.youtube.com"
                )
            end
        )
    end

    -- =====================================================
    -- ALT BUTONLAR
    -- =====================================================

    local bottomY = winH - 88

    CINEMA.button[4] = guiCreateButton(
        15,
        bottomY,
        b1,
        34,
        "SES AYARLARI",
        false,
        mainWindow
    )

    CINEMA.button[5] = guiCreateButton(
        15 + b1 + gap,
        bottomY,
        b1,
        34,
        "URL YAPIŞTIR",
        false,
        mainWindow
    )

    CINEMA.button[6] = guiCreateButton(
        15 + (b1 + gap) * 2,
        bottomY,
        b1,
        34,
        "KAPAT",
        false,
        mainWindow
    )

    guiCreateLabel(
        15,
        winH - 47,
        usableW,
        20,
        "Komut: /cinema",
        false,
        mainWindow
    )

    -- =====================================================
    -- SES AYARLARI PENCERESİ
    -- =====================================================

    local sw = math.min(430, screenWidth - 30)
    local sh = math.min(330, screenHeight - 40)

    sw = math.max(sw, 360)
    sh = math.max(sh, 290)

    settingsWindow = guiCreateWindow(
        0, 0,
        sw, sh,
        "SES AYARLARI",
        false
    )

    centerWindow(settingsWindow, sw, sh)

    guiWindowSetSizable(
        settingsWindow,
        false
    )

    guiSetVisible(
        settingsWindow,
        false
    )

    guiSetProperty(
        settingsWindow,
        "CaptionColour",
        "FF00FF88"
    )

    -- Ses seviyesi
    CINEMA.label[1] = guiCreateLabel(
        20, 35,
        sw - 40, 22,
        "Ses: 100%",
        false,
        settingsWindow
    )

    CINEMA.scroll[1] = guiCreateScrollBar(
        20, 60,
        sw - 40, 20,
        true,
        false,
        settingsWindow
    )

    -- Mesafe sistemi
    CINEMA.label[2] = guiCreateLabel(
        20, 100,
        sw - 40, 22,
        "Mesafe: AÇIK",
        false,
        settingsWindow
    )

    CINEMA.button[7] = guiCreateButton(
        20, 125,
        sw - 40, 32,
        "MESAFELİ SESİ AÇ / KAPAT",
        false,
        settingsWindow
    )

    -- Maksimum mesafe
    CINEMA.label[3] = guiCreateLabel(
        20, 170,
        sw - 40, 22,
        "Maksimum: 50 m",
        false,
        settingsWindow
    )

    CINEMA.scroll[2] = guiCreateScrollBar(
        20, 195,
        sw - 40, 20,
        true,
        false,
        settingsWindow
    )

    -- Sessiz
    CINEMA.label[4] = guiCreateLabel(
        20, 235,
        sw - 40, 22,
        "Durum: AÇIK",
        false,
        settingsWindow
    )

    CINEMA.button[8] = guiCreateButton(
        20, 260,
        sw - 40, 32,
        "SESİ KAPAT / AÇ",
        false,
        settingsWindow
    )

    guiScrollBarSetScrollPosition(
        CINEMA.scroll[1],
        100
    )

    guiScrollBarSetScrollPosition(
        CINEMA.scroll[2],
        8
    )

    guiReady = true
    updateGUI()

end)

-- =========================================================
-- SCROLL EVENT
-- =========================================================

addEventHandler(
    "onClientGUIScroll",
    root,
    function()

        if not guiReady then
            return
        end

        if source == CINEMA.scroll[1] then

            audioConfig.volume = math.floor(
                guiScrollBarGetScrollPosition(source)
            )

            updateGUI()
            applyAudioConfig()

        elseif source == CINEMA.scroll[2] then

            local pos = guiScrollBarGetScrollPosition(source)

            -- 10 - 500 metre
            audioConfig.distMax = math.floor(
                10 + ((pos / 100) * 490)
            )

            audioConfig.distMax = math.max(
                audioConfig.distMin + 1,
                audioConfig.distMax
            )

            updateGUI()
            applyAudioConfig()
        end
    end
)

-- =========================================================
-- CLICK EVENT
-- =========================================================

addEventHandler(
    "onClientGUIClick",
    root,
    function(button, state)

        if state ~= "up" then
            return
        end

        if not guiReady then
            return
        end

        -- URL'Yİ AL
        if source == CINEMA.button[1] then

            if isElement(theBrowser) then
                local url = getBrowserURL(theBrowser)

                if url and url ~= "" then
                    guiSetText(
                        CINEMA.edit[1],
                        url
                    )
                else
                    outputChatBox(
                        "[SİNEMA] Tarayıcıda URL bulunamadı.",
                        255, 150, 0
                    )
                end
            else
                outputChatBox(
                    "[SİNEMA] Tarayıcı hazır değil.",
                    255, 150, 0
                )
            end

        -- HERKESE OYNAT
        elseif source == CINEMA.button[2] then

            local url = getCurrentURL()

            if not isValidURL(url) then
                outputChatBox(
                    "[SİNEMA] Geçerli bir HTTP/HTTPS URL girin.",
                    255, 100, 0
                )
                return
            end

            triggerServerEvent(
                "onCinemaPlay",
                localPlayer,
                url
            )

        -- DURDUR
        elseif source == CINEMA.button[3] then

            triggerServerEvent(
                "onCinemaStop",
                localPlayer
            )

        -- SES AYARLARI
        elseif source == CINEMA.button[4] then

            if isElement(settingsWindow) then

                local visible =
                    not guiGetVisible(settingsWindow)

                guiSetVisible(
                    settingsWindow,
                    visible
                )

                if visible then
                    guiBringToFront(settingsWindow)
                end
            end

        -- URL YAPIŞTIR
        elseif source == CINEMA.button[5] then

            guiSetInputEnabled(true)

            guiBringToFront(mainWindow)

            guiFocus(
                CINEMA.edit[1]
            )

            outputChatBox(
                "[SİNEMA] URL alanına adresi yapıştırabilirsiniz.",
                0, 200, 255
            )

        -- KAPAT
        elseif source == CINEMA.button[6] then

            showMainWindow(false)

        -- MESAFELİ SES
        elseif source == CINEMA.button[7] then

            audioConfig.distEnabled =
                not audioConfig.distEnabled

            updateGUI()
            applyAudioConfig()

        -- SESİ KAPAT
        elseif source == CINEMA.button[8] then

            audioConfig.muted =
                not audioConfig.muted

            updateGUI()
            applyAudioConfig()
        end
    end
)

-- =========================================================
-- SERVER'DAN VİDEO
-- =========================================================

addEvent(
    "onCinemaReceiveURL",
    true
)

addEventHandler(
    "onCinemaReceiveURL",
    root,
    function(url, startTime)

        if not url or url == "" then
            return
        end

        startRender(
            url,
            tonumber(startTime) or 0
        )
    end
)

-- =========================================================
-- SERVER'DAN DURDUR
-- =========================================================

addEvent(
    "onCinemaStopAll",
    true
)

addEventHandler(
    "onCinemaStopAll",
    root,
    function()

        stopRender()

        outputChatBox(
            "[SİNEMA] Gösterim sonlandırıldı.",
            255, 80, 80
        )
    end
)

-- =========================================================
-- /cinema
-- =========================================================

addCommandHandler(
    "cinema",
    function()

        if not isElement(mainWindow) then
            return
        end

        local state =
            not guiGetVisible(mainWindow)

        showMainWindow(state)

    end
)

-- =========================================================
-- RESOURCE STOP
-- =========================================================

addEventHandler(
    "onClientResourceStop",
    resourceRoot,
    function()

        stopRender()
        stopDistanceTick()

        if isElement(webBrowser) then
            destroyElement(webBrowser)
        end

        if isElement(texturePadrao) then
            destroyElement(texturePadrao)
        end
    end
)


-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy