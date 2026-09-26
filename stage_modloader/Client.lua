-- ============================================
-- MTA San Andreas Mod Loader
-- Otomatik Olarak Oluşturuldu
-- Loader Tarzı: compact
-- Ana Renk: #d0f320
-- Arka Plan: #222222
-- Yazı Rengi: #ffffff
-- ============================================
--
-- Bu Loader SparroWMTA Loader Oluşturma Sistemi İle Oluşturulmuştur.
--
-- Sitemiz : https://sparrow-mta.blogspot.com/
-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/
-- Discord : https://discord.gg/DzgEcvy
-- ============================================

local modsToLoad = {}
local currentMod = 0
local totalMods = 0
local isLoading = false
local loadedSize = 0
local totalSize = 0
local currentModName = ""
local currentModSize = 0
local currentPercentage = 0

-- MB cinsinden boyutu görüntüleme için B/KB/MB/GB olarak biçimlendirir.
-- NOT: Bu yardımcı, kendisini kullanan loadNextMod/drawLoaderUI fonksiyonlarından
-- ÖNCE tanımlanmalıdır; aksi halde Lua onu global sanır ve "nil value" hatası verir.
local function mtFormatSize(mb)
    if mb >= 1024 then
        return string.format("%.2f GB", mb / 1024)
    else
        return string.format("%.2f MB", mb)
    end
end

-- Loader Tasarımı
local loaderStyle = "compact"
local loaderPosition = "bottom"
local barWidthPercent = 40
local loaderFontSize = 14
local primaryColorRGB = {r = 208, g = 243, b = 32}
local bgColorRGB = {r = 34, g = 34, b = 34}
local textColorRGB = {r = 255, g = 255, b = 255}
local modSwitchDelay = 1000 -- ms cinsinden, bir mod indikten sonra diğerine geçiş süresi
local panelOpacity = 255 -- panel/arkaplan zemininin alfa (saydamlık) değeri
local smoothAnimationEnabled = true
local shadowEffectEnabled = true
local smoothedPercentage = 0 -- yumuşak animasyon açıkken yüzde bu değere doğru kayarak ilerler

-- ============================================
-- ARAÇ MODLARI
-- ============================================
table.insert(modsToLoad, {
    id = 400,
    type = "vehicle",
    name = "Araç audi-a7",
    dffFile = "Mods/Araba/400.dff",
    txdFile = "Mods/Araba/400.txd",
    size = 25.38
})
table.insert(modsToLoad, {
    id = 401,
    type = "vehicle",
    name = "Araç Audi-A8",
    dffFile = "Mods/Araba/401.dff",
    txdFile = "Mods/Araba/401.txd",
    size = 11.31
})
table.insert(modsToLoad, {
    id = 404,
    type = "vehicle",
    name = "Araç Audi-R8",
    dffFile = "Mods/Araba/404.dff",
    txdFile = "Mods/Araba/404.txd",
    size = 13.79
})
table.insert(modsToLoad, {
    id = 405,
    type = "vehicle",
    name = "Araç Audi-RS7",
    dffFile = "Mods/Araba/405.dff",
    txdFile = "Mods/Araba/405.txd",
    size = 8.68
})
table.insert(modsToLoad, {
    id = 409,
    type = "vehicle",
    name = "Araç Audi-S5",
    dffFile = "Mods/Araba/409.dff",
    txdFile = "Mods/Araba/409.txd",
    size = 8.86
})
table.insert(modsToLoad, {
    id = 419,
    type = "vehicle",
    name = "Araç Audi-TT-RS",
    dffFile = "Mods/Araba/419.dff",
    txdFile = "Mods/Araba/419.txd",
    size = 5.77
})
table.insert(modsToLoad, {
    id = 420,
    type = "vehicle",
    name = "Araç Bmw-540i-G30",
    dffFile = "Mods/Araba/420.dff",
    txdFile = "Mods/Araba/420.txd",
    size = 10.40
})
table.insert(modsToLoad, {
    id = 421,
    type = "vehicle",
    name = "Araç Bmw-760Li",
    dffFile = "Mods/Araba/421.dff",
    txdFile = "Mods/Araba/421.txd",
    size = 13.76
})
table.insert(modsToLoad, {
    id = 426,
    type = "vehicle",
    name = "Araç Bmw-E60",
    dffFile = "Mods/Araba/426.dff",
    txdFile = "Mods/Araba/426.txd",
    size = 14.75
})
table.insert(modsToLoad, {
    id = 438,
    type = "vehicle",
    name = "Araç Bmw-m2",
    dffFile = "Mods/Araba/438.dff",
    txdFile = "Mods/Araba/438.txd",
    size = 12.56
})
table.insert(modsToLoad, {
    id = 442,
    type = "vehicle",
    name = "Araç Bmw-m4",
    dffFile = "Mods/Araba/442.dff",
    txdFile = "Mods/Araba/442.txd",
    size = 5.96
})
table.insert(modsToLoad, {
    id = 454,
    type = "vehicle",
    name = "Araç Bmw-m5-e39",
    dffFile = "Mods/Araba/454.dff",
    txdFile = "Mods/Araba/454.txd",
    size = 9.88
})
table.insert(modsToLoad, {
    id = 455,
    type = "vehicle",
    name = "Araç Bmw-m5-f90",
    dffFile = "Mods/Araba/455.dff",
    txdFile = "Mods/Araba/455.txd",
    size = 11.68
})
table.insert(modsToLoad, {
    id = 456,
    type = "vehicle",
    name = "Araç Bmw-m8",
    dffFile = "Mods/Araba/456.dff",
    txdFile = "Mods/Araba/456.txd",
    size = 13.40
})
table.insert(modsToLoad, {
    id = 458,
    type = "vehicle",
    name = "Araç bmw-m8-anger",
    dffFile = "Mods/Araba/458.dff",
    txdFile = "Mods/Araba/458.txd",
    size = 15.15
})
table.insert(modsToLoad, {
    id = 467,
    type = "vehicle",
    name = "Araç Bmw-x5",
    dffFile = "Mods/Araba/467.dff",
    txdFile = "Mods/Araba/467.txd",
    size = 12.25
})
table.insert(modsToLoad, {
    id = 470,
    type = "vehicle",
    name = "Araç Bmw-x6",
    dffFile = "Mods/Araba/470.dff",
    txdFile = "Mods/Araba/470.txd",
    size = 12.79
})
table.insert(modsToLoad, {
    id = 479,
    type = "vehicle",
    name = "Araç lamborghini-urus-mansory",
    dffFile = "Mods/Araba/479.dff",
    txdFile = "Mods/Araba/479.txd",
    size = 7.78
})
table.insert(modsToLoad, {
    id = 491,
    type = "vehicle",
    name = "Araç Mercedes-Benz-AMG-GT",
    dffFile = "Mods/Araba/491.dff",
    txdFile = "Mods/Araba/491.txd",
    size = 14.11
})
table.insert(modsToLoad, {
    id = 492,
    type = "vehicle",
    name = "Araç Mercedes-Benz-C63",
    dffFile = "Mods/Araba/492.dff",
    txdFile = "Mods/Araba/492.txd",
    size = 12.75
})
table.insert(modsToLoad, {
    id = 507,
    type = "vehicle",
    name = "Araç mercedes-benz-cle",
    dffFile = "Mods/Araba/507.dff",
    txdFile = "Mods/Araba/507.txd",
    size = 15.93
})
table.insert(modsToLoad, {
    id = 529,
    type = "vehicle",
    name = "Araç mercedes-benz-e53",
    dffFile = "Mods/Araba/529.dff",
    txdFile = "Mods/Araba/529.txd",
    size = 9.12
})
table.insert(modsToLoad, {
    id = 540,
    type = "vehicle",
    name = "Araç Mercedes-Benz-E63S",
    dffFile = "Mods/Araba/540.dff",
    txdFile = "Mods/Araba/540.txd",
    size = 13.55
})
table.insert(modsToLoad, {
    id = 542,
    type = "vehicle",
    name = "Araç mercedes-benz-eqs-suv",
    dffFile = "Mods/Araba/542.dff",
    txdFile = "Mods/Araba/542.txd",
    size = 16.30
})
table.insert(modsToLoad, {
    id = 556,
    type = "vehicle",
    name = "Araç Mercedes-Benz-G65",
    dffFile = "Mods/Araba/556.dff",
    txdFile = "Mods/Araba/556.txd",
    size = 17.62
})
table.insert(modsToLoad, {
    id = 557,
    type = "vehicle",
    name = "Araç Mercedes-Benz-W140",
    dffFile = "Mods/Araba/557.dff",
    txdFile = "Mods/Araba/557.txd",
    size = 7.54
})
table.insert(modsToLoad, {
    id = 550,
    type = "vehicle",
    name = "Araç Mercedes-Benz-W221",
    dffFile = "Mods/Araba/550.dff",
    txdFile = "Mods/Araba/550.txd",
    size = 11.48
})
table.insert(modsToLoad, {
    id = 551,
    type = "vehicle",
    name = "Araç Mercedes-Benz-X222",
    dffFile = "Mods/Araba/551.dff",
    txdFile = "Mods/Araba/551.txd",
    size = 12.92
})

-- ============================================
-- YÜKLEME SİSTEMİ
-- ============================================

local pendingDownloads = {}
local dlWatchdog = nil -- takılan dosyada kuyruğu kilitlememek için zamanlayıcı

function loadMods()
    totalMods = #modsToLoad
    currentMod = 0
    isLoading = true
    smoothedPercentage = 0
    showChat(false)
    setPlayerHudComponentVisible("all", false)
    loadedSize = 0
    totalSize = 0
    
    for i, mod in ipairs(modsToLoad) do
        totalSize = totalSize + mod.size
    end
    
    outputDebugString("[Mod Loader] Modlar indirilmeye başlandı...", 3, 0, 255, 0)
    loadNextMod()
end

-- Bir sonraki modun dosyalarını indirme kuyruğuna alır
function loadNextMod()
    if currentMod < totalMods then
        currentMod = currentMod + 1
        local mod = modsToLoad[currentMod]
        
        loadedSize = loadedSize + mod.size
        currentModName = mod.name
        currentModSize = mod.size
        currentPercentage = math.floor((loadedSize / totalSize) * 100)
        
        outputDebugString("[" .. currentMod .. "/" .. totalMods .. "] İndiriliyor: " .. mod.name .. " (" .. mtFormatSize(mod.size) .. ") - %" .. currentPercentage, 3, 0, 200, 255)
        
        pendingDownloads = {}
        table.insert(pendingDownloads, {file = mod.txdFile, kind = "txd", mod = mod})
        table.insert(pendingDownloads, {file = mod.dffFile, kind = "dff", mod = mod})
        if mod.colFile then
            table.insert(pendingDownloads, {file = mod.colFile, kind = "col", mod = mod})
        end
        
        downloadModFiles()
    else
        isLoading = false
        showChat(true)
        setPlayerHudComponentVisible("all", true)
        outputDebugString("[Mod Loader] ✓ Tüm modlar başarıyla indirildi ve yüklendi!", 3, 0, 255, 0)
    end
end

-- Kuyruktaki bir sonraki dosyayı indirir.
-- NOT: Dosya oyuncunun diskinde önceden (önceki bir oturumdan) mevcut olsa
-- bile downloadFile() HER ZAMAN çağrılır. fileExists() true dönse dahi MTA bu
-- dosyayı bu resource oturumu için henüz "indirildi" olarak işaretlememiş
-- olabilir; dosya doğrudan engineLoadDFF/TXD ile açılmaya çalışılırsa
-- "Attempt to load ... before onClientFileDownloadComplete event" uyarısı
-- oluşur. downloadFile() çağrıldığında dosya zaten güncelse gerçek bir ağ
-- indirmesi yapılmaz ve onClientFileDownloadComplete olayı anında (aynı
-- tick'te) tetiklenir; yani performans kaybı olmadan uyarı da önlenmiş olur.
function downloadModFiles()
    if #pendingDownloads > 0 then
        local entry = pendingDownloads[1]
        if dlWatchdog and isTimer(dlWatchdog) then killTimer(dlWatchdog) end
        dlWatchdog = setTimer(function()
            outputDebugString("[HATA] Zaman aşımı (60 sn), atlanıyor: " .. entry.file, 3, 255, 0, 0)
            table.remove(pendingDownloads, 1)
            downloadModFiles()
        end, 60000, 1)
        downloadFile(entry.file)
    else
        setTimer(loadNextMod, modSwitchDelay, 1)
    end
end

-- İndirilen dosyayı türüne göre modele uygular
function applyDownloadedFile(entry)
    local mod = entry.mod
    if entry.kind == "txd" then
        local txd = engineLoadTXD(entry.file)
        if txd then
            engineImportTXD(txd, tonumber(mod.id))
        else
            outputDebugString("[HATA] TXD yüklenemedi: " .. entry.file, 3, 255, 0, 0)
        end
    elseif entry.kind == "dff" then
        local dff = engineLoadDFF(entry.file)
        if dff then
            engineReplaceModel(dff, tonumber(mod.id))
        else
            outputDebugString("[HATA] DFF yüklenemedi: " .. entry.file, 3, 255, 0, 0)
        end
    elseif entry.kind == "col" then
        local col = engineLoadCOL(entry.file)
        if col then
            engineReplaceCOL(col, tonumber(mod.id))
        else
            outputDebugString("[HATA] COL yüklenemedi: " .. entry.file, 3, 255, 0, 0)
        end
    end
end

-- meta.xml'de download="false" olduğu için dosyalar burada manuel indiriliyor
addEventHandler("onClientFileDownloadComplete", root, function(name, success)
    if source == resourceRoot then
        if dlWatchdog and isTimer(dlWatchdog) then killTimer(dlWatchdog) dlWatchdog = nil end
        if #pendingDownloads > 0 and pendingDownloads[1].file == name then
            if success then
                applyDownloadedFile(pendingDownloads[1])
                table.remove(pendingDownloads, 1)
            else
                local entry = pendingDownloads[1]
                entry.retries = (entry.retries or 0) + 1
                if entry.retries <= 3 then
                    outputDebugString("[UYARI] İndirme başarısız, tekrar deneniyor (" .. entry.retries .. "/3): " .. name, 3, 255, 200, 0)
                else
                    outputDebugString("[HATA] Dosya 3 denemede indirilemedi, atlanıyor: " .. name, 3, 255, 0, 0)
                    table.remove(pendingDownloads, 1)
                end
            end
            downloadModFiles()
        end
    end
end)

-- Oyuncu sunucuya katıldığında modları indirmeye başla
addEventHandler("onClientResourceStart", resourceRoot, function()
    loadMods()
end)

-- Yükleme tamamlanmadan resource durursa chat/HUD gizli kalmasın diye güvenlik önlemi
addEventHandler("onClientResourceStop", resourceRoot, function()
    if isLoading then
        showChat(true)
        setPlayerHudComponentVisible("all", true)
    end
end)

-- ============================================
-- YÜKLEME EKRANI (PROGRESS BAR)
-- ============================================

local screenW, screenH = guiGetScreenSize()

-- ============================================
-- TAM EKRAN ARKAPLAN SLAYTI
-- ============================================

local bgImagePaths = {
    "Loader/bg1.png",
}
local bgSlideInterval = 5000 -- ms cinsinden görseller arası geçiş süresi
local bgTransitionEffect = "fade" -- geçiş efekti: cut (keskin), fade (yumuşak), slide (yatay kayma), zoom (yakınlaşma), dip (kararma)
local bgTransitionDuration = 800 -- ms cinsinden tek bir geçişin süresi
local bgTextures = {}
local bgCurrentIndex = 1
local bgPrevIndex = nil -- geçiş anında ekrandan çıkan önceki görselin sırası
local bgTransitionStart = 0 -- geçişin başladığı tick (getTickCount)

-- Arkaplan görselleri meta.xml'de download="true" ile paketlenir, yani resource
-- başlamadan önce oyuncuda hazır olurlar; bu yüzden mod dosyaları gibi manuel
-- indirme kuyruğu/onClientFileDownloadComplete beklemesine gerek yoktur.
local function loadBgTextures()
    for i, path in ipairs(bgImagePaths) do
        local tex = dxCreateTexture(path)
        if tex then
            table.insert(bgTextures, tex)
        else
            outputDebugString("[HATA] Arkaplan görseli yüklenemedi: " .. path, 3, 255, 0, 0)
        end
    end
    if #bgTextures > 1 then
        setTimer(function()
            if bgTransitionEffect == "cut" then
                bgCurrentIndex = (bgCurrentIndex % #bgTextures) + 1
            else
                bgPrevIndex = bgCurrentIndex
                bgCurrentIndex = (bgCurrentIndex % #bgTextures) + 1
                bgTransitionStart = getTickCount()
            end
        end, bgSlideInterval, 0)
    end
end
addEventHandler("onClientResourceStart", resourceRoot, function()
    loadBgTextures()
end)

-- Görseli oranını bozmadan ekranı uçtan uca kaplayacak şekilde (cover/crop)
-- çizer; alfa (saydamlık), yatay kaydırma ve zum destekler — geçiş efektlerinde kullanılır.
local function drawBgCover(tex, alpha, offsetX, zoom)
    if not tex then return end
    local texW, texH = dxGetMaterialSize(tex)
    if not texW or texW == 0 or not texH or texH == 0 then return end
    local baseScale = math.max(screenW / texW, screenH / texH)
    local s = baseScale * (zoom or 1)
    local drawW, drawH = texW * s, texH * s
    local drawX = (screenW - drawW) / 2 + (offsetX or 0)
    local drawY = (screenH - drawH) / 2
    dxDrawImage(drawX, drawY, drawW, drawH, tex, 0, 0, 0, tocolor(255, 255, 255, alpha or 255))
end

-- Seçilen bgTransitionEffect değerine göre önceki ve yeni görseli birlikte çizer.
-- p: geçiş ilerlemesi (0 = başı, 1 = sonu); bitince önceki görsel bırakılır.
local function drawBgSlideshow()
    local cur = bgTextures[bgCurrentIndex]
    if not cur then return end
    local prev = (bgPrevIndex and bgTextures[bgPrevIndex]) or nil
    local p = 1
    if prev then
        p = (getTickCount() - bgTransitionStart) / bgTransitionDuration
        if p >= 1 then
            p = 1
            bgPrevIndex = nil
            prev = nil
        elseif p < 0 then
            p = 0
        end
    end
    if bgTransitionEffect == "cut" or not prev then
        drawBgCover(cur)
    elseif bgTransitionEffect == "fade" then
        drawBgCover(prev)
        drawBgCover(cur, math.floor(255 * p))
    elseif bgTransitionEffect == "slide" then
        drawBgCover(prev, 255, -p * screenW)
        drawBgCover(cur, 255, (1 - p) * screenW)
    elseif bgTransitionEffect == "zoom" then
        drawBgCover(prev)
        drawBgCover(cur, math.floor(255 * p), 0, 1.2 - 0.2 * p)
    elseif bgTransitionEffect == "dip" then
        if p < 0.5 then
            drawBgCover(prev)
            dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, math.floor(255 * (p * 2))))
        else
            drawBgCover(cur)
            dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, math.floor(255 * (1 - (p - 0.5) * 2))))
        end
    else
        drawBgCover(cur)
    end
end

local function getBarGeometry(barHeight)
    local barWidth = screenW * (barWidthPercent / 100)
    local barX = (screenW - barWidth) / 2
    local barY
    if loaderPosition == "top" then
        barY = screenH * 0.08
    elseif loaderPosition == "center" then
        barY = (screenH / 2) - (barHeight / 2)
    else
        barY = screenH - (screenH * 0.14)
    end
    return barX, barY, barWidth, barHeight
end

local function drawLoaderUI()
    local fontScale = loaderFontSize / 9
    local percentage = math.floor(smoothedPercentage + 0.5)
    local modName = currentModName ~= "" and currentModName or "Hazırlanıyor..."
    local modSize = currentModSize
    local bgColorA = tocolor(bgColorRGB.r, bgColorRGB.g, bgColorRGB.b, panelOpacity)
    local shadowColorA = tocolor(0, 0, 0, math.floor(panelOpacity * 0.55))
    local primaryColorA = tocolor(primaryColorRGB.r, primaryColorRGB.g, primaryColorRGB.b, 255)
    local textColorA = tocolor(textColorRGB.r, textColorRGB.g, textColorRGB.b, 255)
    local mutedColorA = tocolor(textColorRGB.r, textColorRGB.g, textColorRGB.b, 160)
    local dimPrimaryA = tocolor(primaryColorRGB.r, primaryColorRGB.g, primaryColorRGB.b, 120)
    local label = modName .. "   -   " .. mtFormatSize(modSize) .. "   -   %" .. percentage
    
    if loaderStyle == "frame" then
        local labelHeight = loaderFontSize + 10
        local barHeight = 16
        local border = 2
        local barX, barY, barWidth = getBarGeometry(labelHeight + barHeight)
        
        dxDrawText(label, barX, barY, barX + barWidth, barY + labelHeight, textColorA, fontScale, "default-bold", "center", "bottom")
        
        local innerBarY = barY + labelHeight
        if shadowEffectEnabled then
            dxDrawRectangle(barX + 3, innerBarY + 3, barWidth, barHeight, shadowColorA)
        end
        dxDrawRectangle(barX, innerBarY, barWidth, barHeight, primaryColorA)
        dxDrawRectangle(barX + border, innerBarY + border, barWidth - border * 2, barHeight - border * 2, bgColorA)
        dxDrawRectangle(barX + border, innerBarY + border, math.max((barWidth - border * 2) * (percentage / 100), 2), barHeight - border * 2, primaryColorA)
        
    elseif loaderStyle == "segmented" then
        local labelHeight = loaderFontSize + 10
        local barHeight = 18
        local barX, barY, barWidth = getBarGeometry(labelHeight + barHeight)
        
        dxDrawText(label, barX, barY, barX + barWidth, barY + labelHeight, textColorA, fontScale, "default-bold", "center", "bottom")
        
        local innerBarY = barY + labelHeight
        local segmentCount = 24
        local gap = 3
        local segmentWidth = (barWidth - gap * (segmentCount - 1)) / segmentCount
        local filledSegments = math.floor(segmentCount * (percentage / 100) + 0.5)
        for i = 0, segmentCount - 1 do
            local segX = barX + i * (segmentWidth + gap)
            local segColor = (i < filledSegments) and primaryColorA or bgColorA
            dxDrawRectangle(segX, innerBarY, segmentWidth, barHeight, segColor)
        end
        
    elseif loaderStyle == "sideLabel" then
        local rowHeight = loaderFontSize + 14
        local barHeight = 10
        local gapA = 8
        local barX, barY, barWidth = getBarGeometry(rowHeight + gapA + barHeight)
        
        local percentWidth = 70
        dxDrawText("%" .. percentage, barX, barY, barX + percentWidth, barY + rowHeight, primaryColorA, fontScale * 1.6, "default-bold", "left", "center")
        dxDrawText(modName, barX + percentWidth, barY, barX + barWidth, barY + rowHeight / 2, textColorA, fontScale * 0.9, "default-bold", "left", "bottom")
        dxDrawText(mtFormatSize(modSize), barX + percentWidth, barY + rowHeight / 2, barX + barWidth, barY + rowHeight, mutedColorA, fontScale * 0.65, "default-bold", "left", "top")
        
        local innerBarY = barY + rowHeight + gapA
        dxDrawRectangle(barX, innerBarY, barWidth, barHeight, bgColorA)
        dxDrawRectangle(barX, innerBarY, math.max(barWidth * (percentage / 100), 2), barHeight, primaryColorA)
        
    elseif loaderStyle == "minimal" then
        local labelHeight = loaderFontSize + 10
        local barHeight = 4
        local barX, barY, barWidth = getBarGeometry(labelHeight + barHeight)
        
        dxDrawText(label, barX, barY, barX + barWidth, barY + labelHeight, textColorA, fontScale, "default-bold", "center", "bottom")
        
        local innerBarY = barY + labelHeight
        dxDrawRectangle(barX, innerBarY, barWidth, barHeight, bgColorA)
        dxDrawRectangle(barX, innerBarY, math.max(barWidth * (percentage / 100), 2), barHeight, primaryColorA)
        
    elseif loaderStyle == "inside" then
        local nameRowHeight = loaderFontSize + 6
        local barHeight = 22
        local barX, barY, barWidth = getBarGeometry(nameRowHeight + 6 + barHeight)
        
        dxDrawText(modName, barX, barY, barX + barWidth, barY + nameRowHeight, textColorA, fontScale, "default-bold", "left", "bottom")
        dxDrawText(mtFormatSize(modSize), barX, barY, barX + barWidth, barY + nameRowHeight, mutedColorA, fontScale * 0.75, "default-bold", "right", "bottom")
        
        local innerBarY = barY + nameRowHeight + 6
        dxDrawRectangle(barX, innerBarY, barWidth, barHeight, bgColorA)
        dxDrawRectangle(barX, innerBarY, math.max(barWidth * (percentage / 100), 2), barHeight, primaryColorA)
        dxDrawText("%" .. percentage, barX, innerBarY, barX + barWidth, innerBarY + barHeight, tocolor(255, 255, 255, 255), fontScale, "default-bold", "center", "center")
        
    elseif loaderStyle == "dual" then
        local pctHeight = loaderFontSize + 12
        local nameHeight = loaderFontSize + 4
        local barHeight = 6
        local barX, barY, barWidth = getBarGeometry(pctHeight + 4 + nameHeight + 6 + barHeight + 4 + barHeight)
        
        dxDrawText("%" .. percentage, barX, barY, barX + barWidth, barY + pctHeight, primaryColorA, fontScale * 1.4, "default-bold", "center", "bottom")
        dxDrawText(modName .. "   -   " .. mtFormatSize(modSize), barX, barY + pctHeight + 4, barX + barWidth, barY + pctHeight + 4 + nameHeight, textColorA, fontScale * 0.75, "default-bold", "center", "center")
        
        local bar1Y = barY + pctHeight + 4 + nameHeight + 6
        dxDrawRectangle(barX, bar1Y, barWidth, barHeight, bgColorA)
        dxDrawRectangle(barX, bar1Y, math.max(barWidth * (percentage / 100), 2), barHeight, primaryColorA)
        local bar2Y = bar1Y + barHeight + 4
        dxDrawRectangle(barX, bar2Y, barWidth, barHeight, bgColorA)
        dxDrawRectangle(barX, bar2Y, math.max(barWidth * (percentage / 100), 2), barHeight, dimPrimaryA)
        
    elseif loaderStyle == "split" then
        local box1H = loaderFontSize + 14
        local box2H = loaderFontSize + 16
        local gap = 8
        local panelX, panelY, panelWidth = getBarGeometry(box1H + gap + box2H)
        
        dxDrawRectangle(panelX, panelY, panelWidth, box1H, bgColorA)
        dxDrawText(modName, panelX + 12, panelY, panelX + panelWidth - 12, panelY + box1H, textColorA, fontScale, "default-bold", "left", "center")
        dxDrawText(mtFormatSize(modSize), panelX + 12, panelY, panelX + panelWidth - 12, panelY + box1H, mutedColorA, fontScale * 0.75, "default-bold", "right", "center")
        
        local box2Y = panelY + box1H + gap
        dxDrawRectangle(panelX, box2Y, panelWidth, box2H, bgColorA)
        local pctW = 64
        local inX = panelX + 12
        local barW = panelWidth - 24 - pctW - 10
        local barH = 10
        local barY2 = box2Y + (box2H - barH) / 2
        dxDrawRectangle(inX, barY2, barW, barH, tocolor(0, 0, 0, 90))
        dxDrawRectangle(inX, barY2, math.max(barW * (percentage / 100), 2), barH, primaryColorA)
        dxDrawText("%" .. percentage, inX + barW + 10, box2Y, panelX + panelWidth - 12, box2Y + box2H, primaryColorA, fontScale, "default-bold", "right", "center")
        
    elseif loaderStyle == "neon" then
        local labelHeight = loaderFontSize + 10
        local glowHeight = 14
        local barHeight = 6
        local barX, barY, barWidth = getBarGeometry(labelHeight + glowHeight)
        
        dxDrawText(label, barX, barY, barX + barWidth, barY + labelHeight, textColorA, fontScale, "default-bold", "center", "bottom")
        
        local glowY = barY + labelHeight
        dxDrawRectangle(barX, glowY, barWidth, glowHeight, tocolor(primaryColorRGB.r, primaryColorRGB.g, primaryColorRGB.b, 70))
        dxDrawRectangle(barX, glowY + 4, math.max(barWidth * (percentage / 100), 2), barHeight, primaryColorA)
        
    elseif loaderStyle == "compact" then
        local nameHeight = loaderFontSize
        local rowHeight = 16
        local gap = 6
        local pctW = 56
        local barX, barY, barWidth = getBarGeometry(nameHeight + gap + rowHeight)
        
        dxDrawText(modName .. "   -   " .. mtFormatSize(modSize), barX, barY, barX + barWidth, barY + nameHeight, mutedColorA, fontScale * 0.7, "default-bold", "left", "center")
        
        local barW = barWidth - pctW - 10
        local barH = 12
        local barY2 = barY + nameHeight + gap + (rowHeight - barH) / 2
        dxDrawRectangle(barX, barY2, barW, barH, bgColorA)
        dxDrawRectangle(barX, barY2, math.max(barW * (percentage / 100), 2), barH, primaryColorA)
        dxDrawText("%" .. percentage, barX + barW + 10, barY + nameHeight + gap, barX + barWidth, barY + nameHeight + gap + rowHeight, primaryColorA, fontScale, "default-bold", "left", "center")
        
    else
        local padding = 18
        local barHeight = 10
        local nameRowHeight = loaderFontSize + 6
        local sizeRowHeight = math.floor(loaderFontSize * 0.75) + 6
        local gapA, gapB = 10, 8
        local panelHeight = padding * 2 + nameRowHeight + gapA + barHeight + gapB + sizeRowHeight
        local panelX, panelY, panelWidth = getBarGeometry(panelHeight)
        
        local innerX = panelX + padding
        local innerWidth = panelWidth - padding * 2
        
        -- Panel arka planı (gölge açıksa altına hafif kaydırılmış koyu bir kopya çizilir)
        if shadowEffectEnabled then
            dxDrawRectangle(panelX + 5, panelY + 5, panelWidth, panelHeight, shadowColorA)
        end
        dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, bgColorA)
        
        -- Mod adı (sol) ve yüzde (sağ)
        local nameY = panelY + padding
        dxDrawText(modName, innerX, nameY, innerX + innerWidth * 0.65, nameY + nameRowHeight, textColorA, fontScale, "default-bold", "left", "center")
        dxDrawText("%" .. percentage, innerX, nameY, innerX + innerWidth, nameY + nameRowHeight, primaryColorA, fontScale * 1.05, "default-bold", "right", "center")
        
        -- İlerleme çubuğu
        local barY = nameY + nameRowHeight + gapA
        dxDrawRectangle(innerX, barY, innerWidth, barHeight, tocolor(0, 0, 0, 90))
        dxDrawRectangle(innerX, barY, math.max(innerWidth * (percentage / 100), 2), barHeight, primaryColorA)
        
        -- Boyut bilgisi
        local sizeY = barY + barHeight + gapB
        dxDrawText(mtFormatSize(modSize), innerX, sizeY, innerX + innerWidth, sizeY + sizeRowHeight, mutedColorA, fontScale * 0.78, "default-bold", "left", "center")
    end
end

addEventHandler("onClientRender", root, function()
    if isLoading then
        drawBgSlideshow()
        if smoothAnimationEnabled then
            smoothedPercentage = smoothedPercentage + (currentPercentage - smoothedPercentage) * 0.15
            if math.abs(currentPercentage - smoothedPercentage) < 0.2 then
                smoothedPercentage = currentPercentage
            end
        else
            smoothedPercentage = currentPercentage
        end
        drawLoaderUI()
    end
end)
