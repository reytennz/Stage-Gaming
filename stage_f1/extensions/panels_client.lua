--[[
    Eksik F1 panelleri - mevcut gui pencere sistemine uyumlu
    Sunucu Hakkinda | Meslekler | Ayarlar | Sahibinden | Air
    Galeri stok gosterimi + Admin /stok
]]

local _stageOriginalOutputChatBox = outputChatBox
function outputChatBox(message, r, g, b, colorCoded)
    message = tostring(message or "")
    if not message:find("Stage Gaming", 1, true) then
        message = "#FF7A00[Stage Gaming] #FFFFFF" .. message:gsub("^#%x%x%x%x%x%x%[[^%]]+%]%s*#%x%x%x%x%x%x", "")
    end
    return _stageOriginalOutputChatBox(message, r or 255, g or 255, b or 255, colorCoded ~= false)
end

---------------------------
-- Yardimcilar
---------------------------
local function moneyFmt(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local k
    while true do
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return "$" .. s
end

---------------------------
-- SUNUCU HAKKINDA
---------------------------
function aboutPanelInit()
    local name = getServerName and getServerName() or "#Stage Gaming"
    setControlText(wndAbout, "sname", name)
    setControlText(wndAbout, "sfounder", "Stage Team")
    setControlText(wndAbout, "sonline", tostring(#getElementsByType("player")))
    setControlText(wndAbout, "sdiscord", "discord.gg/stagegaming")

    -- Top jobs
    local jobs = JobsData or {}
    local sorted = {}
    for _, j in ipairs(jobs) do table.insert(sorted, j) end
    table.sort(sorted, function(a,b) return a.salary > b.salary end)
    local lines = {}
    for i = 1, math.min(5, #sorted) do
        table.insert(lines, i .. ". " .. sorted[i].name .. "  -  " .. moneyFmt(sorted[i].salary))
    end
    setControlText(wndAbout, "topjobs", table.concat(lines, "\n"))

    setControlText(wndAbout, "activities",
        "• Meslek yap (Meslekler paneli)\n" ..
        "• Arac satin al (Sifir Arac Galerisi)\n" ..
        "• Arac sat (Sahibinden.com)\n" ..
        "• Arac modifiye et\n" ..
        "• Sahibinden ilani olustur\n" ..
        "• Etkinliklere katil"
    )
end

function openAboutPanel()
    if not wndAbout.element then createWindow(wndAbout) end
    showCursor(true)
    -- createWindow already shows; ensure visible
    if isWindowOpen(wndAbout) then
        -- refresh
        aboutPanelInit()
    else
        createWindow(wndAbout)
        aboutPanelInit()
    end
    -- Toggle style: use show via gui
    guiSetVisible(wndAbout.element, true)
    aboutPanelInit()
end

wndAbout = {
    "wnd",
    text = "Sunucu Hakkinda",
    width = 420,
    controls = {
        {"lbl", text = "Sunucu Adi:", width = 120, align = "left"},
        {"lbl", id = "sname", text = "-", width = 260, align = "left"},
        {"br"},
        {"lbl", text = "Kurucu:", width = 120, align = "left"},
        {"lbl", id = "sfounder", text = "-", width = 260, align = "left"},
        {"br"},
        {"lbl", text = "Aktif Oyuncu:", width = 120, align = "left"},
        {"lbl", id = "sonline", text = "0", width = 260, align = "left"},
        {"br"},
        {"lbl", text = "Discord:", width = 120, align = "left"},
        {"lbl", id = "sdiscord", text = "-", width = 260, align = "left"},
        {"br"},
        {"lbl", text = "En Cok Para Kazandiran Meslekler:", width = 400, align = "left"},
        {"br"},
        {"lbl", id = "topjobs", text = "-", width = 400, height = 80, align = "left"},
        {"br"},
        {"lbl", text = "Yapabilecekleriniz:", width = 400, align = "left"},
        {"br"},
        {"lbl", id = "activities", text = "-", width = 400, height = 100, align = "left"},
        {"br"},
        {"btn", id = "Kapat", closeswindow = true, width = 120, color = "FFD700"},
    },
    oncreate = aboutPanelInit,
}

---------------------------
-- MESLEKLER
---------------------------
local jobRows = {} -- row -> job id

function jobsPanelInit()
    local list = getControl(wndJobs, "joblist")
    if not list then return end
    guiGridListClear(list)
    jobRows = {}
    for _, j in ipairs(JobsData or {}) do
        local row = guiGridListAddRow(list)
        guiGridListSetItemText(list, row, 1, j.name, false, false)
        guiGridListSetItemText(list, row, 2, moneyFmt(j.salary), false, false)
        guiGridListSetItemText(list, row, 3, j.location or "-", false, false)
        jobRows[row + 1] = j.id
    end
end

function jobTeleport()
    local list = getControl(wndJobs, "joblist")
    local row = guiGridListGetSelectedItem(list)
    if not row or row < 0 then
        outputChatBox("#ff9900[Meslek] #ffffffOnce listeden bir meslek secin.", 255, 255, 255, true)
        return
    end
    local jid = jobRows[row + 1]
    if not jid then return end
    triggerServerEvent("f1jobs:teleport", localPlayer, jid)
end

function jobShowDesc()
    local list = getControl(wndJobs, "joblist")
    local row = guiGridListGetSelectedItem(list)
    if not row or row < 0 then return end
    local jid = jobRows[row + 1]
    local job = getJobById(jid)
    if job then
        setControlText(wndJobs, "jobdesc", job.description or "")
    end
end

wndJobs = {
    "wnd",
    text = "Meslekler",
    width = 460,
    controls = {
        {
            "lst",
            id = "joblist",
            width = 440,
            height = 280,
            columns = {
                { text = "Meslek", attr = "name", width = 0.40 },
                { text = "Ort. Kazanc", attr = "salary", width = 0.25 },
                { text = "Konum", attr = "loc", width = 0.35 },
            },
            onitemclick = jobShowDesc,
        },
        {"lbl", id = "jobdesc", text = "Bir meslek secin...", width = 440, align = "left"},
        {"br"},
        {"btn", text = "MESLEGE ISINLAN", onclick = jobTeleport, width = 200, color = "FFD700"},
        {"btn", id = "Kapat", closeswindow = true, width = 100},
    },
    oncreate = jobsPanelInit,
}

function openJobsPanel()
    if not wndJobs.element then createWindow(wndJobs) end
    guiSetVisible(wndJobs.element, true)
    jobsPanelInit()
    showCursor(true)
end

---------------------------
-- AYARLAR (FPS)
---------------------------
local settingsData = {
    farClip = 600,
    showFPS = false,
    motionBlur = false,
}

local function applySettingsPreset(name)
    if name == "low" then
        settingsData.farClip = 300
        settingsData.motionBlur = false
        setFarClipDistance(300)
        if setBlurLevel then setBlurLevel(0) end
        outputChatBox("#00ff66[Ayarlar] #ffffffDusuk FPS profili uygulandi.", 255, 255, 255, true)
    elseif name == "balanced" then
        settingsData.farClip = 600
        settingsData.motionBlur = false
        setFarClipDistance(600)
        if setBlurLevel then setBlurLevel(0) end
        outputChatBox("#00ff66[Ayarlar] #ffffffDengeli profil uygulandi.", 255, 255, 255, true)
    elseif name == "high" then
        settingsData.farClip = 1200
        settingsData.motionBlur = true
        setFarClipDistance(1200)
        if setBlurLevel then setBlurLevel(36) end
        outputChatBox("#00ff66[Ayarlar] #ffffffYuksek profil uygulandi.", 255, 255, 255, true)
    end
    setControlText(wndSettings, "farclipval", tostring(settingsData.farClip))
end

function settingsInit()
    setControlText(wndSettings, "farclipval", tostring(settingsData.farClip))
end

function settingsFarClipApply()
    local v = getControlNumber(wndSettings, "farclipedit")
    if not v then
        outputChatBox("#ff9900[Ayarlar] #ffffffGecerli bir sayi girin (100-3000).", 255, 255, 255, true)
        return
    end
    v = math.max(100, math.min(3000, v))
    settingsData.farClip = v
    setFarClipDistance(v)
    setControlText(wndSettings, "farclipval", tostring(v))
    outputChatBox("#00ff66[Ayarlar] #ffffffGorus mesafesi: " .. v, 255, 255, 255, true)
end

function settingsToggleFPS()
    settingsData.showFPS = not settingsData.showFPS
    outputChatBox("#00ff66[Ayarlar] #ffffffFPS gostergesi: " .. (settingsData.showFPS and "ACIK" or "KAPALI"), 255, 255, 255, true)
end

function settingsToggleBlur()
    settingsData.motionBlur = not settingsData.motionBlur
    if setBlurLevel then setBlurLevel(settingsData.motionBlur and 36 or 0) end
    outputChatBox("#00ff66[Ayarlar] #ffffffMotion Blur: " .. (settingsData.motionBlur and "ACIK" or "KAPALI"), 255, 255, 255, true)
end

wndSettings = {
    "wnd",
    text = "Ayarlar - FPS / Grafik",
    width = 400,
    controls = {
        {"lbl", text = "Hazir Profiller:", width = 380, align = "left"},
        {"br"},
        {"btn", text = "Dusuk FPS", onclick = function() applySettingsPreset("low") end, width = 120, color = "FF5500"},
        {"btn", text = "Dengeli", onclick = function() applySettingsPreset("balanced") end, width = 120, color = "FFD700"},
        {"btn", text = "Yuksek", onclick = function() applySettingsPreset("high") end, width = 120, color = "00AA00"},
        {"br"},
        {"lbl", text = "Gorus Mesafesi (Far Clip):", width = 220, align = "left"},
        {"lbl", id = "farclipval", text = "600", width = 80, align = "left"},
        {"br"},
        {"txt", id = "farclipedit", text = "600", width = 120},
        {"btn", text = "Uygula", onclick = settingsFarClipApply, width = 100},
        {"br"},
        {"btn", text = "FPS Gostergesi Ac/Kapa", onclick = settingsToggleFPS, width = 200},
        {"btn", text = "Motion Blur Ac/Kapa", onclick = settingsToggleBlur, width = 180},
        {"br"},
        {"lbl", text = "Arac / Ped gorus mesafesi oyun ayarlarindan da etkilenir.", width = 380, align = "left"},
        {"br"},
        {"btn", id = "Kapat", closeswindow = true, width = 120, color = "FFD700"},
    },
    oncreate = settingsInit,
}

function openSettingsPanel()
    if not wndSettings.element then createWindow(wndSettings) end
    guiSetVisible(wndSettings.element, true)
    settingsInit()
    showCursor(true)
end

-- FPS overlay
local fpsFrames, fpsLast, fpsValue = 0, getTickCount(), 0
addEventHandler("onClientRender", root, function()
    if not settingsData.showFPS then return end
    fpsFrames = fpsFrames + 1
    local now = getTickCount()
    if now - fpsLast >= 1000 then
        fpsValue = fpsFrames
        fpsFrames = 0
        fpsLast = now
    end
    local sw = guiGetScreenSize()
    dxDrawText("FPS: " .. fpsValue, sw - 90, 8, sw - 10, 28, tocolor(255, 200, 50, 220), 1.1, "default-bold", "right", "center")
end)

---------------------------
-- SAHIBINDEN
---------------------------
local sahibindenRows = {}
local listingForm = { title = "", desc = "", price = "" }

function sahibindenRefresh()
    triggerServerEvent("sahibinden:requestList", localPlayer)
end

addEvent("sahibinden:receiveList", true)
addEventHandler("sahibinden:receiveList", root, function(list)
    local grid = getControl(wndSahibinden, "listinglist")
    if not grid then return end
    guiGridListClear(grid)
    sahibindenRows = {}
    for _, L in ipairs(list or {}) do
        local row = guiGridListAddRow(grid)
        guiGridListSetItemText(grid, row, 1, L.name or "-", false, false)
        guiGridListSetItemText(grid, row, 2, L.seller or "-", false, false)
        guiGridListSetItemText(grid, row, 3, moneyFmt(L.price), false, false)
        guiGridListSetItemText(grid, row, 4, L.title ~= "" and L.title or "-", false, false)
        sahibindenRows[row + 1] = L.id
    end
end)

addEvent("sahibinden:listUpdated", true)
addEventHandler("sahibinden:listUpdated", root, function()
    if wndSahibinden and wndSahibinden.element and guiGetVisible(wndSahibinden.element) then
        sahibindenRefresh()
    end
end)

function sahibindenBuy()
    local grid = getControl(wndSahibinden, "listinglist")
    local row = guiGridListGetSelectedItem(grid)
    if not row or row < 0 then
        outputChatBox("#ff9900[Sahibinden] #ffffffOnce bir ilan secin.", 255, 255, 255, true)
        return
    end
    local id = sahibindenRows[row + 1]
    if id then
        triggerServerEvent("sahibinden:buy", localPlayer, id)
    end
end

function sahibindenCreate()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
        outputChatBox("#ff9900[Sahibinden] #ffffffIlan vermek icin aracın sofor koltugunda olun.", 255, 255, 255, true)
        return
    end
    local price = tonumber(getControlText(wndSahibinden, "priceedit"))
    if not price or price <= 0 then
        outputChatBox("#ff9900[Sahibinden] #ffffffGecerli bir fiyat girin.", 255, 255, 255, true)
        return
    end
    local title = getControlText(wndSahibinden, "titleedit") or ""
    local desc = getControlText(wndSahibinden, "descedit") or ""
    triggerServerEvent("sahibinden:create", localPlayer, veh, title, desc, price)
end

wndSahibinden = {
    "wnd",
    text = "Sahibinden.com",
    width = 520,
    controls = {
        {
            "lst",
            id = "listinglist",
            width = 500,
            height = 220,
            columns = {
                { text = "Arac", attr = "name", width = 0.28 },
                { text = "Satici", attr = "seller", width = 0.25 },
                { text = "Fiyat", attr = "price", width = 0.20 },
                { text = "Baslik", attr = "title", width = 0.27 },
            },
        },
        {"btn", text = "Satin Al", onclick = sahibindenBuy, width = 120, color = "00AA00"},
        {"btn", text = "Yenile", onclick = sahibindenRefresh, width = 100},
        {"br"},
        {"lbl", text = "--- Ilan Ver (aracta sofor ol) ---", width = 500, align = "left"},
        {"br"},
        {"lbl", text = "Baslik (opsiyonel):", width = 140, align = "left"},
        {"txt", id = "titleedit", text = "", width = 340},
        {"br"},
        {"lbl", text = "Aciklama (ops.):", width = 140, align = "left"},
        {"txt", id = "descedit", text = "", width = 340},
        {"br"},
        {"lbl", text = "Fiyat (zorunlu):", width = 140, align = "left"},
        {"txt", id = "priceedit", text = "", width = 160},
        {"btn", text = "Ilana Ver", onclick = sahibindenCreate, width = 140, color = "FFD700"},
        {"br"},
        {"btn", id = "Kapat", closeswindow = true, width = 120},
    },
    oncreate = sahibindenRefresh,
}

function openSahibindenPanel()
    if not wndSahibinden.element then createWindow(wndSahibinden) end
    guiSetVisible(wndSahibinden.element, true)
    sahibindenRefresh()
    showCursor(true)
end

---------------------------
-- AIR (mevcut AirSystem event)
---------------------------
local airHeight = 0

function airUp()
    airHeight = math.min(0.4, airHeight + 0.05)
    triggerEvent("air:adjust", localPlayer, airHeight)
    -- Alternatif: bazi air sistemleri export kullanir
    outputChatBox("#00ff66[Air] #ffffffYukseklik: " .. string.format("%.2f", airHeight), 255, 255, 255, true)
end

function airDown()
    airHeight = math.max(-0.3, airHeight - 0.05)
    triggerEvent("air:adjust", localPlayer, airHeight)
    outputChatBox("#00ff66[Air] #ffffffYukseklik: " .. string.format("%.2f", airHeight), 255, 255, 255, true)
end

function airReset()
    airHeight = 0
    triggerEvent("air:adjust", localPlayer, 0)
    outputChatBox("#00ff66[Air] #ffffffSifirlandi.", 255, 255, 255, true)
end

function airPanelInit()
    if not getPedOccupiedVehicle(localPlayer) then
        outputChatBox("#ff9900[Air] #ffffffOnce bir araca binin.", 255, 255, 255, true)
    end
end

wndAir = {
    "wnd",
    text = "Air / Hava Suspansiyon",
    width = 320,
    oncreate = airPanelInit,
    controls = {
        {"lbl", text = "Aractayken yukseklik ayarlayin.", width = 300, align = "left"},
        {"br"},
        {"btn", text = "YUKSELT  ▲", onclick = airUp, width = 140, color = "FF5500"},
        {"btn", text = "ALCALT  ▼", onclick = airDown, width = 140, color = "FF5500"},
        {"br"},
        {"btn", text = "SIFIRLA", onclick = airReset, width = 140},
        {"btn", id = "Kapat", closeswindow = true, width = 140, color = "FFD700"},
        {"br"},
        {"lbl", text = "Not: Tam air fizigi icin AirSystem resource acik olmali.", width = 300, align = "left"},
    },
}

function openAirPanel()
    if not getPedOccupiedVehicle(localPlayer) then
        outputChatBox("#ff9900[Air] #ffffffOnce bir araca binin.", 255, 255, 255, true)
        return
    end
    if not wndAir.element then createWindow(wndAir) end
    guiSetVisible(wndAir.element, true)
    showCursor(true)
end

---------------------------
-- GALERI STOK (mevcut wndCreateVehicle uzerine)
---------------------------
-- Katalog (isim, id, fiyat, stok) — freeroam yok
addEvent("f1stock:receiveCatalog", true)
addEventHandler("f1stock:receiveCatalog", root, function(list)
    g_GalleryCatalog = list or {}
    if type(fillGalleryGrid) == "function" then
        fillGalleryGrid(g_GalleryCatalog)
    elseif type(refreshVehicleShowroomStock) == "function" then
        refreshVehicleShowroomStock()
    end
end)

addEvent("f1stock:catalogUpdated", true)
addEventHandler("f1stock:catalogUpdated", root, function(list)
    g_GalleryCatalog = list or {}
    if type(fillGalleryGrid) == "function" then
        fillGalleryGrid(g_GalleryCatalog)
    end
end)

-- vehicleShowroomInit / buySelectedVehicle fr_client'ta tanimli;
-- panels_client ONCE yuklendigi icin sarmalamayi resource start'ta yap.
addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(vehicleShowroomInit) == "function" and not _G._f1stockWrapped then
        _G._f1stockWrapped = true
        local _vehicleShowroomInit = vehicleShowroomInit
        function vehicleShowroomInit()
            triggerServerEvent("f1stock:requestAll", localPlayer)
            _vehicleShowroomInit()
            setTimer(function()
                if not xmlToTable or not applyToLeaves or not getVehiclePrice then return end
                local tree = xmlToTable("data/vehicles.xml", {"id", "name"})
                if not tree then return end
                applyToLeaves(tree, function(leaf)
                    if leaf.id and leaf.id > 0 then
                        local price = getVehiclePrice(leaf.id)
                        local stock = g_StockCache[leaf.id]
                        if stock == nil then
                            leaf.price = "$" .. formatMoney(price)
                        elseif stock <= 0 then
                            leaf.price = "STOK YOK"
                        else
                            leaf.price = "$" .. formatMoney(price) .. " | Stok:" .. stock
                        end
                    else
                        leaf.price = ""
                    end
                end)
                if wndCreateVehicle then
                    bindGridListToTable(wndCreateVehicle, "vehicles", tree, true)
                end
            end, 400, 1)
        end

        if type(buySelectedVehicle) == "function" then
            local _buySelectedVehicle = buySelectedVehicle
            function buySelectedVehicle(leaf)
                if not leaf then
                    leaf = getSelectedGridListLeaf(wndCreateVehicle, "vehicles")
                end
                if leaf and leaf.id and g_StockCache[leaf.id] ~= nil and g_StockCache[leaf.id] <= 0 then
                    outputChatBox("#ff0000[✘] #ffffffBu arac stokta yok.", 255, 255, 255, true)
                    return
                end
                _buySelectedVehicle(leaf)
            end
        end
    end
end)

local adminStockRows = {}
local adminSelected = nil -- {id, name, price, stock}

local function adminUpdateSelectedLabel()
    if not wndAdminStock or not wndAdminStock.element then return end
    if not adminSelected then
        setControlText(wndAdminStock, "selinfo", "Secili: (yok)  |  Listeden arac secin")
        return
    end
    setControlText(wndAdminStock, "selinfo",
        ("Secili: ID %s  |  %s  |  Fiyat %s  |  Stok %s"):format(
            tostring(adminSelected.id),
            adminSelected.name or "-",
            moneyFmt(adminSelected.price or 0),
            tostring(adminSelected.stock or 0)
        )
    )
end

addEvent("f1stock:openAdmin", true)
addEventHandler("f1stock:openAdmin", root, function(rows)
    createWindow(wndAdminStock)
    showCursor(true)
    local grid = getControl(wndAdminStock, "stocklist")
    if not grid then return end
    guiGridListClear(grid)
    adminStockRows = {}
    adminSelected = nil
    for _, r in ipairs(rows or {}) do
        local row = guiGridListAddRow(grid)
        guiGridListSetItemText(grid, row, 1, tostring(r.id), false, false)
        guiGridListSetItemText(grid, row, 2, r.name or "-", false, false)
        guiGridListSetItemText(grid, row, 3, moneyFmt(r.price), false, false)
        guiGridListSetItemText(grid, row, 4, tostring(r.stock), false, false)
        adminStockRows[row + 1] = { id = r.id, name = r.name, price = r.price, stock = r.stock }
    end
    adminUpdateSelectedLabel()
end)

function adminStockSelect()
    local grid = getControl(wndAdminStock, "stocklist")
    local row = guiGridListGetSelectedItem(grid)
    if not row or row < 0 then
        adminSelected = nil
    else
        adminSelected = adminStockRows[row + 1]
    end
    adminUpdateSelectedLabel()
    if adminSelected and wndAdminStock.element then
        -- Secilen aracin OZEL ismini kutuya yaz (orijinal GTA ismi degil)
        setControlText(wndAdminStock, "nameedit", adminSelected.name or "")
        setControlText(wndAdminStock, "stockedit", tostring(adminSelected.stock or 0))
        setControlText(wndAdminStock, "priceedit", tostring(adminSelected.price or 0))
    end
end

local function adminStockAction(delta)
    if not adminSelected then
        -- try current selection
        adminStockSelect()
    end
    if not adminSelected then
        outputChatBox("#ff9900[Stok] #ffffffOnce listeden bir arac secin.", 255, 255, 255, true)
        return
    end
    local model = adminSelected.id
    if delta == 0 then
        triggerServerEvent("f1stock:adminAction", localPlayer, model, "reset", 0)
    elseif delta > 0 then
        triggerServerEvent("f1stock:adminAction", localPlayer, model, "add", delta)
    else
        triggerServerEvent("f1stock:adminAction", localPlayer, model, "remove", math.abs(delta))
    end
end

function adminStockSetExact()
    if not adminSelected then adminStockSelect() end
    if not adminSelected then
        outputChatBox("#ff9900[Stok] #ffffffOnce listeden bir arac secin.", 255, 255, 255, true)
        return
    end
    local v = getControlNumber(wndAdminStock, "stockedit")
    if v == nil then
        outputChatBox("#ff9900[Stok] #ffffffGecerli bir stok sayisi girin.", 255, 255, 255, true)
        return
    end
    triggerServerEvent("f1stock:adminAction", localPlayer, adminSelected.id, "set", math.max(0, math.floor(v)))
end

function adminStockSetName()
    if not adminSelected then adminStockSelect() end
    if not adminSelected then
        outputChatBox("#ff9900[Stok] #ffffffOnce listeden bir arac secin.", 255, 255, 255, true)
        return
    end
    local name = getControlText(wndAdminStock, "nameedit") or ""
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        outputChatBox("#ff9900[Stok] #ffffffIsim bos olamaz.", 255, 255, 255, true)
        return
    end
    triggerServerEvent("f1stock:adminSetName", localPlayer, adminSelected.id, name)
end

function adminStockSetPrice()
    if not adminSelected then adminStockSelect() end
    if not adminSelected then
        outputChatBox("#ff9900[Stok] #ffffffOnce listeden bir arac secin.", 255, 255, 255, true)
        return
    end
    local v = getControlNumber(wndAdminStock, "priceedit")
    if v == nil then
        outputChatBox("#ff9900[Stok] #ffffffGecerli fiyat girin.", 255, 255, 255, true)
        return
    end
    triggerServerEvent("f1stock:adminSetPrice", localPlayer, adminSelected.id, math.max(0, math.floor(v)))
end

wndAdminStock = {
    "wnd",
    text = "Admin Stok Yonetimi (/stok)",
    width = 580,
    controls = {
        {"lbl", id = "selinfo", text = "Secili: (yok)", width = 560, align = "left"},
        {"br"},
        {
            "lst",
            id = "stocklist",
            width = 560,
            height = 280,
            columns = {
                { text = "ID", attr = "id", width = 0.12 },
                { text = "Arac", attr = "name", width = 0.38 },
                { text = "Fiyat", attr = "price", width = 0.25 },
                { text = "Stok", attr = "stock", width = 0.25 },
            },
            onitemclick = adminStockSelect,
        },
        {"br"},
        {"btn", text = "+1", onclick = function() adminStockAction(1) end, width = 50, color = "00AA00"},
        {"btn", text = "+5", onclick = function() adminStockAction(5) end, width = 50, color = "00AA00"},
        {"btn", text = "+10", onclick = function() adminStockAction(10) end, width = 50, color = "00AA00"},
        {"btn", text = "-1", onclick = function() adminStockAction(-1) end, width = 50, color = "AA0000"},
        {"btn", text = "-5", onclick = function() adminStockAction(-5) end, width = 50, color = "AA0000"},
        {"btn", text = "-10", onclick = function() adminStockAction(-10) end, width = 50, color = "AA0000"},
        {"btn", text = "Sifirla", onclick = function() adminStockAction(0) end, width = 80, color = "FFD700"},
        {"br"},
        {"lbl", text = "Stok ayarla:", width = 100, align = "left"},
        {"txt", id = "stockedit", text = "0", width = 80},
        {"btn", text = "Uygula", onclick = adminStockSetExact, width = 100, color = "FF5500"},
        {"br"},
        {"lbl", text = "/stokekle [id] [miktar]  |  /stokayar [id] [stok]", width = 560, align = "left"},
        {"br"},
        {"btn", id = "Kapat", closeswindow = true, width = 120},
    },
}

---------------------------
-- MODIFIYE
---------------------------
local function modifiyeVehicle()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        outputChatBox("#ff9900[Modifiye] #ffffffModifiye icin once bir araca bin.", 255, 255, 255, true)
        return false
    end
    if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
        outputChatBox("#ff9900[Modifiye] #ffffffModifiye panelini sadece surucu kullanabilir.", 255, 255, 255, true)
        return false
    end
    return vehicle
end

function modifiyeRepair()
    local vehicle = modifiyeVehicle()
    if vehicle then triggerServerEvent("onServerCall", resourceRoot, "fixVehicle", vehicle) end
end

function modifiyeColor()
    if modifiyeVehicle() and type(openColorPicker) == "function" then
        openColorPicker()
    end
end

function modifiyePaintjob()
    if modifiyeVehicle() and wndPaintjob then
        createWindow(wndPaintjob)
        showCursor(true)
    end
end

function modifiyeTurbo()
    local vehicle = modifiyeVehicle()
    if not vehicle then return end
    local data = getElementData(vehicle, "vehicle:upgrades") or {}
    local state = not data.turbo
    setElementData(vehicle, "vehicle:upgrades", { turbo = state, als = data.als or false })
    outputChatBox(state and "#00ff66[Modifiye] #ffffffTurbo acildi." or "#ff5555[Modifiye] #ffffffTurbo kapatildi.", 255, 255, 255, true)
end

function modifiyeVehicleControl()
    if modifiyeVehicle() then
        triggerEvent("stageVehicleControl:openPanel", localPlayer)
    end
end

wndModifiye = {
    "wnd",
    text = "Modifiye",
    width = 340,
    controls = {
        {"lbl", text = "Aractayken kullanilabilir.", width = 320, align = "left"},
        {"br"},
        {"btn", text = "Tamir Et", onclick = modifiyeRepair, width = 150, color = "FFD700"},
        {"btn", text = "Renk / Boya", onclick = modifiyeColor, width = 150},
        {"br"},
        {"btn", text = "Paintjob", onclick = modifiyePaintjob, width = 150},
        {"btn", text = "Turbo Ac/Kapat", onclick = modifiyeTurbo, width = 150},
        {"br"},
        {"btn", text = "Arac Kontrol Paneli", onclick = modifiyeVehicleControl, width = 300, color = "FF5500"},
        {"br"},
        {"btn", id = "Kapat", closeswindow = true, width = 120},
    },
}

function openModifiyePanel()
    if not modifiyeVehicle() then return end
    createWindow(wndModifiye)
    showCursor(true)
end

---------------------------
-- Ana F1 butonlarini bagla (comingSoon yerine)
---------------------------
function openAboutFromMain()
    openAboutPanel()
end

-- Override coming soon buttons by replacing functions used in wndMain
-- wndMain zaten olusturulmus olabilir; onclick referanslarini fr_client'da degistirecegiz

---------------------------
-- CRITICAL: fr_client yuklenirken open* fonksiyonlari yoktu,
-- bu yuzden onclick=nil kaydedildi. Resource start ONCESI burada bagla.
---------------------------
local function rewireMainButtons()
    if not wndMain or not wndMain.controls then return end
    local map = {
        swhakkinda = openAboutPanel,
        ["swhakkında"] = openAboutPanel,
        ayarlar = openSettingsPanel,
        meslekler = openJobsPanel,
        sahibinden = openSahibindenPanel,
        air = openAirPanel,
        modifiye = openModifiyePanel,
        siralama = openLeaderboardPanel,
        duello = openDuelPanel,
    }
    for _, ctrl in pairs(wndMain.controls) do
        if type(ctrl) == "table" and ctrl.id and map[ctrl.id] then
            ctrl.onclick = map[ctrl.id]
            ctrl.event = nil
            ctrl.window = nil
        end
    end
end

rewireMainButtons()

-- createWindow cagrilmadan once de emin ol
addEventHandler("onClientResourceStart", resourceRoot, function()
    rewireMainButtons()
    -- Eger pencere zaten kurulduysa, buton handlerlarini manuel bagla
    if wndMain and wndMain.element and wndMain.controls then
        for _, ctrl in pairs(wndMain.controls) do
            if type(ctrl) == "table" and ctrl.element and ctrl.onclick then
                local fn = ctrl.onclick
                -- Eski handler kalabilir; yenisini ekle (MTA multiple handlers ok)
                addEventHandler("onClientGUIClick", ctrl.element, function()
                    fn()
                end, false)
            end
        end
    end
end, true)

-- open* fonksiyonlarini createWindow API'sine gore sadeleştir
function openAboutPanel()
    createWindow(wndAbout)
    showCursor(true)
end

function openJobsPanel()
    createWindow(wndJobs)
    showCursor(true)
end

function openSettingsPanel()
    createWindow(wndSettings)
    showCursor(true)
end

function openSahibindenPanel()
    createWindow(wndSahibinden)
    showCursor(true)
end

function openAirPanel()
    if not getPedOccupiedVehicle(localPlayer) then
        outputChatBox("#ff9900[Air] #ffffffOnce bir araca binin.", 255, 255, 255, true)
        return
    end
    createWindow(wndAir)
    showCursor(true)
end

function openModifiyePanel()
    if not modifiyeVehicle() then return end
    createWindow(wndModifiye)
    showCursor(true)
end

---------------------------
-- DUELLO
---------------------------
local duelRows = {}
local pendingDuelFrom = nil

local function stageNotify(message, r, g, b)
    outputChatBox("#FF7A00[Stage Gaming] #FFFFFF" .. tostring(message), r or 255, g or 255, b or 255, true)
end

local function cleanPlayerName(name)
    return tostring(name or "-"):gsub("#%x%x%x%x%x%x", "")
end

function duelPanelInit()
    local grid = getControl(wndDuel, "players")
    if not grid then return end
    guiGridListClear(grid)
    duelRows = {}
    for _, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer then
            local row = guiGridListAddRow(grid)
            guiGridListSetItemText(grid, row, 1, cleanPlayerName(getPlayerName(player)), false, false)
            guiGridListSetItemText(grid, row, 2, tostring(getElementData(player, "stage:kills") or "-"), false, false)
            guiGridListSetItemData(grid, row, 1, player)
            duelRows[row + 1] = player
        end
    end
end

function duelSendRequest()
    local grid = getControl(wndDuel, "players")
    local row = grid and guiGridListGetSelectedItem(grid) or -1
    if not row or row < 0 then
        stageNotify("Once duello atilacak oyuncuyu sec.")
        return
    end
    local target = duelRows[row + 1] or guiGridListGetItemData(grid, row, 1)
    local bet = math.floor(getControlNumber(wndDuel, "bet") or 0)
    if not isElement(target) then
        stageNotify("Oyuncu bulunamadi, listeyi yenile.")
        return
    end
    if bet < 0 then bet = 0 end
    triggerServerEvent("stageDuel:request", localPlayer, target, bet)
end

function duelAcceptRequest()
    if pendingDuelFrom and isElement(pendingDuelFrom) then
        triggerServerEvent("stageDuel:respond", localPlayer, pendingDuelFrom, true)
    end
    pendingDuelFrom = nil
    if wndDuelInvite and wndDuelInvite.element then closeWindow(wndDuelInvite) end
end

function duelDeclineRequest()
    if pendingDuelFrom and isElement(pendingDuelFrom) then
        triggerServerEvent("stageDuel:respond", localPlayer, pendingDuelFrom, false)
    end
    pendingDuelFrom = nil
    if wndDuelInvite and wndDuelInvite.element then closeWindow(wndDuelInvite) end
end

addEvent("stageDuel:notify", true)
addEventHandler("stageDuel:notify", root, function(message)
    stageNotify(message)
end)

addEvent("stageDuel:invite", true)
addEventHandler("stageDuel:invite", root, function(fromPlayer, bet)
    pendingDuelFrom = fromPlayer
    local text = cleanPlayerName(getPlayerName(fromPlayer)) .. " sana duello atti. Bahis: $" .. tostring(bet or 0)
    if wndDuelInvite and wndDuelInvite.element then closeWindow(wndDuelInvite) end
    wndDuelInvite.controls[1].text = text
    createWindow(wndDuelInvite)
    showCursor(true)
end)

wndDuel = {
    "wnd",
    text = "Duello",
    width = 420,
    controls = {
        {
            "lst",
            id = "players",
            width = 400,
            height = 250,
            columns = {
                { text = "Oyuncu", attr = "name", width = 0.72 },
                { text = "Kill", attr = "kills", width = 0.20 },
            },
        },
        {"br"},
        {"lbl", text = "Bahis:", width = 80, align = "left"},
        {"txt", id = "bet", text = "0", width = 130},
        {"btn", text = "Istek At", onclick = duelSendRequest, width = 140, color = "FFD700"},
        {"br"},
        {"btn", text = "Yenile", onclick = duelPanelInit, width = 100},
        {"btn", id = "Kapat", closeswindow = true, width = 100},
    },
    oncreate = duelPanelInit,
}

wndDuelInvite = {
    "wnd",
    text = "Duello Istegi",
    width = 360,
    controls = {
        {"lbl", text = "-", width = 340, align = "left"},
        {"br"},
        {"btn", text = "Kabul Et", onclick = duelAcceptRequest, width = 150, color = "00AA00"},
        {"btn", text = "Reddet", onclick = duelDeclineRequest, width = 150, color = "AA0000"},
    },
}

function openDuelPanel()
    createWindow(wndDuel)
    showCursor(true)
    duelPanelInit()
end

---------------------------
-- SIRALAMA
---------------------------
local leaderboardRows = {}
local leaderboardMode = "kills"
local leaderboardModeNames = {
    kills = "Oldurme",
    drift = "Drift",
    time = "Zaman",
}

local function fmtDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

local function leaderboardScore(rowData)
    if leaderboardMode == "drift" then
        return fmtDuration(rowData.drift_seconds)
    elseif leaderboardMode == "time" then
        return fmtDuration(rowData.play_seconds)
    end
    return tostring(rowData.kills or 0)
end

local function fillLeaderboard(mode, rows)
    if type(mode) == "table" then
        rows = mode
        mode = leaderboardMode
    end
    leaderboardMode = tostring(mode or leaderboardMode or "kills")
    local grid = getControl(wndLeaderboard, "leaders")
    if not grid then return end
    guiGridListClear(grid)
    leaderboardRows = rows or {}
    setControlText(wndLeaderboard, "activetab", "Sekme: " .. (leaderboardModeNames[leaderboardMode] or "Oldurme"))
    for i, rowData in ipairs(leaderboardRows) do
        local row = guiGridListAddRow(grid)
        guiGridListSetItemText(grid, row, 1, tostring(i), false, false)
        guiGridListSetItemText(grid, row, 2, tostring(rowData.name or "-"), false, false)
        guiGridListSetItemText(grid, row, 3, leaderboardScore(rowData), false, leaderboardMode == "kills")
        guiGridListSetItemText(grid, row, 4, tostring(rowData.kills or 0), false, true)
        guiGridListSetItemText(grid, row, 5, fmtDuration(rowData.drift_seconds), false, false)
        guiGridListSetItemText(grid, row, 6, fmtDuration(rowData.play_seconds), false, false)
    end
end

addEvent("stageStats:receiveLeaderboard", true)
addEventHandler("stageStats:receiveLeaderboard", root, fillLeaderboard)

function leaderboardSetMode(mode)
    leaderboardMode = mode or leaderboardMode or "kills"
    triggerServerEvent("stageStats:requestLeaderboard", localPlayer, leaderboardMode)
end

function leaderboardInit()
    leaderboardSetMode(leaderboardMode or "kills")
end

wndLeaderboard = {
    "wnd",
    text = "Siralama Paneli",
    width = 620,
    controls = {
        {"btn", text = "Oldurme", onclick = function() leaderboardSetMode("kills") end, width = 120, color = "FFD700"},
        {"btn", text = "Drift", onclick = function() leaderboardSetMode("drift") end, width = 120},
        {"btn", text = "Zaman", onclick = function() leaderboardSetMode("time") end, width = 120},
        {"br"},
        {"lbl", id = "activetab", text = "Sekme: Oldurme", width = 600, align = "left"},
        {"br"},
        {
            "lst",
            id = "leaders",
            width = 600,
            height = 330,
            columns = {
                { text = "#", attr = "rank", width = 0.08 },
                { text = "Oyuncu", attr = "name", width = 0.30 },
                { text = "Skor", attr = "score", width = 0.17 },
                { text = "Oldurme", attr = "kills", width = 0.13 },
                { text = "Drift", attr = "drift_seconds", width = 0.15 },
                { text = "Zaman", attr = "play_seconds", width = 0.15 },
            },
        },
        {"br"},
        {"btn", text = "Yenile", onclick = leaderboardInit, width = 120, color = "FFD700"},
        {"btn", id = "Kapat", closeswindow = true, width = 100},
    },
    oncreate = leaderboardInit,
}

function openLeaderboardPanel()
    createWindow(wndLeaderboard)
    showCursor(true)
    leaderboardInit()
end

-- Debug: komutla da acilabilsin
addCommandHandler("f1about", openAboutPanel)
addCommandHandler("f1meslek", openJobsPanel)
addCommandHandler("f1ayar", openSettingsPanel)
addCommandHandler("f1sahibinden", openSahibindenPanel)
addCommandHandler("f1air", openAirPanel)
addCommandHandler("f1siralama", openLeaderboardPanel)

outputDebugString("[F1 extensions] panels_client loaded, buttons rewired", 3)
