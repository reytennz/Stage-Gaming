--[[
    Modern Koyu Temalı Benzinlik UI
    - Satın alma kartı
    - Gelişmiş Admin Paneli (isim, fiyat, konum, sahip, silme, satışa çıkarma...)
    - Sahip Paneli (tüm sekmeler + gerçek input'lar)
]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local function isMouseIn(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local theme = {
    bg      = tocolor(12, 14, 20, 252),
    header  = tocolor(18, 22, 30, 255),
    accent  = tocolor(16, 185, 110, 255),
    accentH = tocolor(34, 210, 130, 255),
    accentD = tocolor(10, 120, 70, 255),
    card    = tocolor(24, 28, 38, 255),
    card2   = tocolor(32, 36, 48, 255),
    card3   = tocolor(40, 46, 60, 255),
    text    = tocolor(245, 247, 250, 255),
    textDim = tocolor(140, 148, 165, 255),
    textMut = tocolor(100, 108, 125, 255),
    danger  = tocolor(220, 55, 55, 255),
    dangerH = tocolor(240, 70, 70, 255),
    warning = tocolor(251, 191, 36, 255),
    success = tocolor(16, 185, 110, 255),
    line    = tocolor(55, 62, 78, 255),
    petrol  = tocolor(56, 189, 248, 255),
    diesel  = tocolor(251, 191, 36, 255),
}

local function drawPanel(x, y, w, h)
    dxDrawRectangle(x + 5*scale, y + 6*scale, w, h, tocolor(0, 0, 0, 100))
    dxDrawRectangle(x, y, w, h, theme.bg)
    dxDrawRectangle(x, y, 4*scale, h, theme.accent)
end

local function drawBtn(x, y, w, h, label, primary, hover)
    local col = primary and (hover and theme.accentH or theme.accent) or (hover and theme.card3 or theme.card2)
    dxDrawRectangle(x, y, w, h, col)
    if primary then
        dxDrawRectangle(x, y + h - 3*scale, w, 3*scale, theme.accentD)
    end
    dxDrawText(label, x, y, x + w, y + h, theme.text, 1.0*scale, "default-bold", "center", "center")
end

-- ===================== GUI ELEMENT HELPERS =====================
local guiElements = {}

local function clearGuiElements()
    for _, el in ipairs(guiElements) do
        if isElement(el) then destroyElement(el) end
    end
    guiElements = {}
end

local function addGui(el)
    table.insert(guiElements, el)
    return el
end

local function createEdit(x, y, w, h, text, maxLen)
    local edit = guiCreateEdit(x, y, w, h, text or "", false)
    guiSetFont(edit, "default-bold-small")
    guiEditSetMaxLength(edit, maxLen or 64)
    guiSetAlpha(edit, 0.95)
    addGui(edit)
    return edit
end

local function createLabel(x, y, w, h, text, align)
    local lbl = guiCreateLabel(x, y, w, h, text, false)
    guiSetFont(lbl, "default-bold-small")
    guiLabelSetColor(lbl, 200, 200, 210)
    if align then guiLabelSetHorizontalAlign(lbl, align) end
    addGui(lbl)
    return lbl
end

-- ===================== STATE =====================
local buyUI = { visible = false, data = nil }
local successUI = { visible = false, data = nil } -- satın alma sonrası kod ekranı
local codeUI = { visible = false, data = nil, edit = nil } -- yaya: kod gir

local ownerUI = {
    visible = false,
    data = nil,
    products = {},
    stats = {},
    ads = {},
    tab = "overview",
}

local adminUI = {
    visible = false,
    stations = {},
    selected = nil,
    mode = "list", -- list / create / edit
}

-- ===================== EVENTS =====================
addEvent("benzinlik:showBuyUI", true)
addEventHandler("benzinlik:showBuyUI", root, function(data, quote)
    codeUI.visible = false
    if codeUI.edit and isElement(codeUI.edit) then destroyElement(codeUI.edit) codeUI.edit = nil end
    buyUI.visible = true
    buyUI.data = data
    buyUI.quote = quote or {
        price = (data and data.sale_price) or Config.DefaultBuyPrice,
        owned = 0, max = Config.MaxStations or 6,
        canBuy = true, label = "Satış fiyatı", nextSlot = 1
    }
    if not buyUI.quote.price or buyUI.quote.price <= 0 then
        buyUI.quote.price = data.sale_price or Config.DefaultBuyPrice
    end
    showCursor(true)
end)

addEventHandler("benzinlik:showBuyUI", resourceRoot, function(data, quote)
    codeUI.visible = false
    if codeUI.edit and isElement(codeUI.edit) then destroyElement(codeUI.edit) codeUI.edit = nil end
    buyUI.visible = true
    buyUI.data = data
    buyUI.quote = quote or {
        price = (data and (tonumber(data.sale_price) or Config.DefaultBuyPrice)) or Config.DefaultBuyPrice,
        owned = 0, max = Config.MaxStations or 6, canBuy = true, label = "Satış fiyatı", nextSlot = 1
    }
    showCursor(true)
end)


addEvent("benzinlik:forceHideBuy", true)
addEventHandler("benzinlik:forceHideBuy", localPlayer, function()
    buyUI.visible = false
    buyUI.data = nil
end)

addEvent("benzinlik:hideBuyUI", true)
addEventHandler("benzinlik:hideBuyUI", localPlayer, function()
    buyUI.visible = false
    buyUI.data = nil
end)

addEvent("benzinlik:purchaseSuccess", true)
addEventHandler("benzinlik:purchaseSuccess", resourceRoot, function(info)
    buyUI.visible = false
    buyUI.data = nil
    successUI.visible = true
    successUI.data = info
    showCursor(true)
end)

addEvent("benzinlik:showCodeUI", true)
addEventHandler("benzinlik:showCodeUI", localPlayer, function(data)
    if successUI.visible or ownerUI.visible or adminUI.visible or buyUI.visible then return end
    buyUI.visible = false
    codeUI.visible = true
    codeUI.data = data
    showCursor(true)
    if codeUI.edit and isElement(codeUI.edit) then destroyElement(codeUI.edit) end
    local w, h = 400 * scale, 250 * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2
    codeUI.edit = guiCreateEdit(x + 40*scale, y + 100*scale, w - 80*scale, 34*scale, "", false)
    guiSetFont(codeUI.edit, "default-bold-small")
    guiEditSetMaxLength(codeUI.edit, 12)
    guiBringToFront(codeUI.edit)
end)

addEvent("benzinlik:hideCodeUI", true)
addEventHandler("benzinlik:hideCodeUI", localPlayer, function()
    codeUI.visible = false
    codeUI.data = nil
    if codeUI.edit and isElement(codeUI.edit) then destroyElement(codeUI.edit) codeUI.edit = nil end
    if not ownerUI.visible and not adminUI.visible and not buyUI.visible and not successUI.visible then
        showCursor(false)
    end
end)

addEvent("benzinlik:hideAllUI", true)
addEventHandler("benzinlik:hideAllUI", localPlayer, function()
    buyUI.visible = false
    buyUI.data = nil
    successUI.visible = false
    successUI.data = nil
    triggerEvent("benzinlik:hideCodeUI", localPlayer)
    closeOwnerPanel()
    closeAdminPanel()
    triggerEvent("benzinlik:hideFuelUI", localPlayer)
end)

addEvent("benzinlik:openOwnerPanel", true)
addEventHandler("benzinlik:openOwnerPanel", resourceRoot, function(data, products, stats, ads)
    openOwnerPanel(data, products, stats, ads)
end)

addEvent("benzinlik:refreshProducts", true)
addEventHandler("benzinlik:refreshProducts", resourceRoot, function(products)
    ownerUI.products = products or {}
    if ownerUI.visible and ownerUI.tab == "market" then
        rebuildOwnerInputs()
    end
end)

addEvent("benzinlik:ownerQuote", true)
addEventHandler("benzinlik:ownerQuote", resourceRoot, function(quote)
    ownerUI.markerQuote = quote
end)

addEvent("benzinlik:onStationUpdated", true)
addEventHandler("benzinlik:onStationUpdated", localPlayer, function(data)
    if ownerUI.visible and ownerUI.data and ownerUI.data.id == data.id then
        ownerUI.data = data
    end
    if adminUI.visible then
        adminUI.stations[data.id] = data
        if adminUI.selected and adminUI.selected.id == data.id then
            adminUI.selected = data
        end
    end
end)

addEvent("benzinlik:createStation", true)
addEventHandler("benzinlik:createStation", resourceRoot, function(data)
    if adminUI.visible and data and data.id then
        adminUI.stations[data.id] = data
        adminUI.mode = "list"
        adminUI.selected = nil
        rebuildAdminInputs()
    end
end)

addEvent("benzinlik:removeStation", true)
addEventHandler("benzinlik:removeStation", resourceRoot, function(id)
    if adminUI.visible then
        adminUI.stations[id] = nil
        if adminUI.selected and adminUI.selected.id == id then
            adminUI.selected = nil
            adminUI.mode = "list"
        end
        rebuildAdminInputs()
    end
end)

addEvent("benzinlik:openAdminPanel", true)
addEventHandler("benzinlik:openAdminPanel", resourceRoot, function(stations)
    openAdminPanel(stations)
end)

-- ===================== OWNER PANEL =====================
function closeOwnerPanel()
    ownerUI.visible = false
    ownerUI.data = nil
    clearGuiElements()
    showCursor(false)
    guiSetInputMode("allow_binds")
end

function openOwnerPanel(data, products, stats, ads)
    closeAdminPanel()
    ownerUI.visible = true
    ownerUI.data = data
    ownerUI.products = products or {}
    ownerUI.stats = stats or {}
    ownerUI.ads = ads or {}
    ownerUI.tab = "overview"
    showCursor(true)
    guiSetInputMode("no_binds")
    rebuildOwnerInputs()
end

function rebuildOwnerInputs()
    clearGuiElements()
    if not ownerUI.visible or not ownerUI.data then return end

    local data = ownerUI.data
    local w, h = 920 * scale, 600 * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2
    local menuW = 175 * scale
    local cx = x + menuW + 15 * scale
    local cy = y + 60 * scale
    local cw = w - menuW - 30 * scale

    if ownerUI.tab == "fuel" then
        -- Benzin fiyat
        createLabel(cx + 20*scale, cy + 195*scale, 140*scale, 22*scale, "Benzin Satış Fiyatı:")
        local petrolEdit = createEdit(cx + 165*scale, cy + 192*scale, 90*scale, 26*scale, tostring(data.petrol_price or 48), 4)
        local petrolBtn = addGui(guiCreateButton(cx + 265*scale, cy + 192*scale, 70*scale, 26*scale, "Kaydet", false))

        -- Dizel fiyat
        createLabel(cx + 360*scale, cy + 195*scale, 140*scale, 22*scale, "Dizel Satış Fiyatı:")
        local dieselEdit = createEdit(cx + 505*scale, cy + 192*scale, 90*scale, 26*scale, tostring(data.diesel_price or 52), 4)
        local dieselBtn = addGui(guiCreateButton(cx + 605*scale, cy + 192*scale, 70*scale, 26*scale, "Kaydet", false))

        -- Toptan alım
        createLabel(cx + 20*scale, cy + 240*scale, 200*scale, 22*scale, "Toptan Alım (Litre):")
        local litersEdit = createEdit(cx + 180*scale, cy + 237*scale, 80*scale, 26*scale, "500", 5)
        local buyPetrolBtn = addGui(guiCreateButton(cx + 275*scale, cy + 237*scale, 130*scale, 26*scale, "Benzin Al", false))
        local buyDieselBtn = addGui(guiCreateButton(cx + 415*scale, cy + 237*scale, 130*scale, 26*scale, "Dizel Al", false))

        addEventHandler("onClientGUIClick", petrolBtn, function()
            local val = tonumber(guiGetText(petrolEdit))
            if val then triggerServerEvent("benzinlik:setFuelPrice", localPlayer, data.id, "petrol", val) end
        end, false)
        addEventHandler("onClientGUIClick", dieselBtn, function()
            local val = tonumber(guiGetText(dieselEdit))
            if val then triggerServerEvent("benzinlik:setFuelPrice", localPlayer, data.id, "diesel", val) end
        end, false)
        addEventHandler("onClientGUIClick", buyPetrolBtn, function()
            local val = tonumber(guiGetText(litersEdit))
            if val then triggerServerEvent("benzinlik:buyWholesale", localPlayer, data.id, "petrol", val) end
        end, false)
        addEventHandler("onClientGUIClick", buyDieselBtn, function()
            local val = tonumber(guiGetText(litersEdit))
            if val then triggerServerEvent("benzinlik:buyWholesale", localPlayer, data.id, "diesel", val) end
        end, false)

    elseif ownerUI.tab == "cash" then
        createLabel(cx + 20*scale, cy + 80*scale, 120*scale, 22*scale, "Miktar ($):")
        local amountEdit = createEdit(cx + 140*scale, cy + 77*scale, 140*scale, 28*scale, "10000", 10)
        local depBtn = addGui(guiCreateButton(cx + 300*scale, cy + 77*scale, 120*scale, 28*scale, "Yatır", false))
        local witBtn = addGui(guiCreateButton(cx + 435*scale, cy + 77*scale, 120*scale, 28*scale, "Çek", false))

        addEventHandler("onClientGUIClick", depBtn, function()
            local val = tonumber(guiGetText(amountEdit))
            if val and val > 0 then triggerServerEvent("benzinlik:deposit", localPlayer, data.id, val) end
        end, false)
        addEventHandler("onClientGUIClick", witBtn, function()
            local val = tonumber(guiGetText(amountEdit))
            if val and val > 0 then triggerServerEvent("benzinlik:withdraw", localPlayer, data.id, val) end
        end, false)

    elseif ownerUI.tab == "ads" then
        createLabel(cx + 20*scale, cy + 15*scale, 200*scale, 22*scale, "Reklam Başlığı:")
        local titleEdit = createEdit(cx + 20*scale, cy + 40*scale, 300*scale, 28*scale, "", 64)
        createLabel(cx + 20*scale, cy + 80*scale, 200*scale, 22*scale, "Reklam Mesajı:")
        local msgEdit = createEdit(cx + 20*scale, cy + 105*scale, 500*scale, 28*scale, "", 200)
        createLabel(cx + 20*scale, cy + 145*scale, 120*scale, 22*scale, "Süre (sn):")
        local durEdit = createEdit(cx + 130*scale, cy + 142*scale, 80*scale, 28*scale, "1800", 5)
        createLabel(cx + 230*scale, cy + 145*scale, 100*scale, 22*scale, "Bütçe ($):")
        local budEdit = createEdit(cx + 330*scale, cy + 142*scale, 100*scale, 28*scale, "10000", 8)
        local createAdBtn = addGui(guiCreateButton(cx + 450*scale, cy + 142*scale, 120*scale, 28*scale, "Yayınla", false))

        addEventHandler("onClientGUIClick", createAdBtn, function()
            local title = guiGetText(titleEdit)
            local msg = guiGetText(msgEdit)
            local dur = tonumber(guiGetText(durEdit))
            local bud = tonumber(guiGetText(budEdit))
            if title ~= "" and msg ~= "" and dur and bud then
                triggerServerEvent("benzinlik:createAd", localPlayer, data.id, title, msg, dur, bud)
            end
        end, false)

    elseif ownerUI.tab == "market" then
        createLabel(cx + 20*scale, cy + 10*scale, 200*scale, 22*scale, "Yeni Ürün Adı:")
        local nameEdit = createEdit(cx + 20*scale, cy + 35*scale, 160*scale, 26*scale, "", 32)
        createLabel(cx + 195*scale, cy + 10*scale, 80*scale, 22*scale, "Alış:")
        local buyEdit = createEdit(cx + 195*scale, cy + 35*scale, 60*scale, 26*scale, "10", 5)
        createLabel(cx + 270*scale, cy + 10*scale, 80*scale, 22*scale, "Satış:")
        local sellEdit = createEdit(cx + 270*scale, cy + 35*scale, 60*scale, 26*scale, "20", 5)
        createLabel(cx + 345*scale, cy + 10*scale, 80*scale, 22*scale, "Stok:")
        local stockEdit = createEdit(cx + 345*scale, cy + 35*scale, 60*scale, 26*scale, "30", 5)
        local addBtn = addGui(guiCreateButton(cx + 420*scale, cy + 35*scale, 100*scale, 26*scale, "Ekle", false))

        addEventHandler("onClientGUIClick", addBtn, function()
            local n = guiGetText(nameEdit)
            local b = tonumber(guiGetText(buyEdit))
            local s = tonumber(guiGetText(sellEdit))
            local st = tonumber(guiGetText(stockEdit))
            if n ~= "" and b and s and st then
                triggerServerEvent("benzinlik:addProduct", localPlayer, data.id, n, b, s, st)
            end
        end, false)

    elseif ownerUI.tab == "security" then
        createLabel(cx + 25*scale, cy + 210*scale, 200*scale, 22*scale, "Yeni giriş kodu:")
        local codeEdit = createEdit(cx + 25*scale, cy + 235*scale, 200*scale, 30*scale, tostring(data.code or ""), 12)
        local saveBtn = addGui(guiCreateButton(cx + 240*scale, cy + 235*scale, 120*scale, 30*scale, "Kaydet", false))
        addEventHandler("onClientGUIClick", saveBtn, function()
            local nc = guiGetText(codeEdit)
            if nc and nc ~= "" then
                triggerServerEvent("benzinlik:changeCode", localPlayer, data.id, nc)
            else
                outputChatBox("» Yeni kod yaz.", 255, 200, 0)
            end
        end, false)

    elseif ownerUI.tab == "marker" then
        triggerServerEvent("benzinlik:requestOwnerQuote", localPlayer, data.id)
        createLabel(cx + 25*scale, cy + 235*scale, 400*scale, 22*scale, "Bulunduğun yere ek marker koy (aynı kod):")
        local addBtn = addGui(guiCreateButton(cx + 25*scale, cy + 265*scale, 200*scale, 34*scale, "MARKER EKLE", false))
        addEventHandler("onClientGUIClick", addBtn, function()
            triggerServerEvent("benzinlik:ownerAddMarker", localPlayer, data.id)
        end, false)
    end
end

-- ===================== ADMIN PANEL =====================
function closeAdminPanel()
    adminUI.visible = false
    adminUI.selected = nil
    adminUI.mode = "list"
    clearGuiElements()
    showCursor(false)
    guiSetInputMode("allow_binds")
end

function openAdminPanel(stations)
    closeOwnerPanel()
    adminUI.visible = true
    adminUI.stations = stations or {}
    adminUI.selected = nil
    adminUI.mode = "list"
    showCursor(true)
    guiSetInputMode("no_binds")
    rebuildAdminInputs()
end

function rebuildAdminInputs()
    clearGuiElements()
    if not adminUI.visible then return end

    local w, h = 860 * scale, 560 * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2

    if adminUI.mode == "create" then
        createLabel(x + 30*scale, y + 95*scale, 300*scale, 24*scale, "Marker / Benzinlik Adı:")
        local nameEdit = createEdit(x + 30*scale, y + 120*scale, 300*scale, 32*scale, "Yeni Benzinlik", 48)

        createLabel(x + 350*scale, y + 95*scale, 220*scale, 24*scale, "Liste fiyatı ($ - bilgilendirme):")
        local priceEdit = createEdit(x + 350*scale, y + 120*scale, 160*scale, 32*scale, tostring(Config.DefaultBuyPrice), 10)

        local createBtn = addGui(guiCreateButton(x + 30*scale, y + 175*scale, 220*scale, 40*scale, "MARKER EKLE (Konumum)", false))
        local backBtn = addGui(guiCreateButton(x + 270*scale, y + 175*scale, 120*scale, 40*scale, "Geri", false))

        addEventHandler("onClientGUIClick", createBtn, function()
            local name = guiGetText(nameEdit)
            local price = tonumber(guiGetText(priceEdit)) or Config.DefaultBuyPrice
            if name and name ~= "" then
                triggerServerEvent("benzinlik:adminCreate", localPlayer, name, price)
                adminUI.mode = "list"
            end
        end, false)
        addEventHandler("onClientGUIClick", backBtn, function()
            adminUI.mode = "list"
            rebuildAdminInputs()
        end, false)

    elseif adminUI.mode == "edit" and adminUI.selected then
        local st = adminUI.selected
        createLabel(x + 30*scale, y + 65*scale, 400*scale, 24*scale, "Düzenleniyor: #" .. st.id .. "  " .. (st.name or ""))

        -- İsim
        createLabel(x + 30*scale, y + 100*scale, 120*scale, 22*scale, "İsim:")
        local nameEdit = createEdit(x + 140*scale, y + 97*scale, 220*scale, 28*scale, st.name or "", 48)
        local renameBtn = addGui(guiCreateButton(x + 375*scale, y + 97*scale, 90*scale, 28*scale, "Kaydet", false))

        -- Satış fiyatı
        createLabel(x + 30*scale, y + 145*scale, 120*scale, 22*scale, "Satış Fiyatı:")
        local saleEdit = createEdit(x + 140*scale, y + 142*scale, 140*scale, 28*scale, tostring(st.sale_price or Config.DefaultBuyPrice), 10)
        local saleBtn = addGui(guiCreateButton(x + 295*scale, y + 142*scale, 110*scale, 28*scale, "Satışa Çıkar", false))
        local removeSaleBtn = addGui(guiCreateButton(x + 420*scale, y + 142*scale, 120*scale, 28*scale, "Satıştan Kaldır", false))

        -- Sahip
        createLabel(x + 30*scale, y + 190*scale, 120*scale, 22*scale, "Sahip (hesap):")
        local ownerEdit = createEdit(x + 140*scale, y + 187*scale, 180*scale, 28*scale, st.owner or "", 32)
        local ownerBtn = addGui(guiCreateButton(x + 335*scale, y + 187*scale, 110*scale, 28*scale, "Sahip Yap", false))
        local stateBtn = addGui(guiCreateButton(x + 460*scale, y + 187*scale, 110*scale, 28*scale, "Devlete Ver", false))

        -- Konum
        local posBtn = addGui(guiCreateButton(x + 30*scale, y + 240*scale, 220*scale, 34*scale, "Konumu Oyuncuya Taşı", false))
        local delBtn = addGui(guiCreateButton(x + 270*scale, y + 240*scale, 140*scale, 34*scale, "SİL", false))
        local backBtn = addGui(guiCreateButton(x + 430*scale, y + 240*scale, 100*scale, 34*scale, "Geri", false))

        -- Bilgi
        createLabel(x + 30*scale, y + 295*scale, 500*scale, 22*scale, "Kod: " .. (st.code or "?") .. "  |  Seviye: " .. (st.level or 1) .. "  |  Kasa: " .. formatMoney(st.balance or 0))
        createLabel(x + 30*scale, y + 320*scale, 500*scale, 22*scale, string.format("Konum: %.1f, %.1f, %.1f", st.posX or 0, st.posY or 0, st.posZ or 0))

        addEventHandler("onClientGUIClick", renameBtn, function()
            local n = guiGetText(nameEdit)
            if n and n ~= "" then
                triggerServerEvent("benzinlik:renameStation", localPlayer, st.id, n)
            end
        end, false)
        addEventHandler("onClientGUIClick", saleBtn, function()
            local p = tonumber(guiGetText(saleEdit))
            if p then triggerServerEvent("benzinlik:setForSale", localPlayer, st.id, p) end
        end, false)
        addEventHandler("onClientGUIClick", removeSaleBtn, function()
            triggerServerEvent("benzinlik:removeFromSale", localPlayer, st.id)
        end, false)
        addEventHandler("onClientGUIClick", ownerBtn, function()
            local o = guiGetText(ownerEdit)
            triggerServerEvent("benzinlik:changeOwner", localPlayer, st.id, o ~= "" and o or nil)
        end, false)
        addEventHandler("onClientGUIClick", stateBtn, function()
            triggerServerEvent("benzinlik:changeOwner", localPlayer, st.id, nil)
        end, false)
        addEventHandler("onClientGUIClick", posBtn, function()
            triggerServerEvent("benzinlik:changePosition", localPlayer, st.id)
        end, false)
        addEventHandler("onClientGUIClick", delBtn, function()
            triggerServerEvent("benzinlik:adminDelete", localPlayer, st.id)
            adminUI.selected = nil
            adminUI.mode = "list"
            setTimer(rebuildAdminInputs, 400, 1)
        end, false)
        addEventHandler("onClientGUIClick", backBtn, function()
            adminUI.mode = "list"
            adminUI.selected = nil
            rebuildAdminInputs()
        end, false)
    end
end

-- ===================== RENDER =====================
addEventHandler("onClientRender", root, function()
    -- ========== SATIN ALMA ==========
    if buyUI.visible and buyUI.data then
        local data = buyUI.data
        local q = buyUI.quote or { price = 0, owned = 0, max = 6, canBuy = true, label = "1. benzinlik", nextSlot = 1 }
        local w, h = 440 * scale, 360 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        drawPanel(x, y, w, h)
        dxDrawRectangle(x + 4*scale, y, w - 4*scale, 56*scale, theme.header)
        dxDrawText("SATILIK BENZİNLİK", x + 20*scale, y, x + w - 20*scale, y + 56*scale, theme.text, 1.25*scale, "default-bold", "center", "center")

        local py = y + 70*scale
        dxDrawText(data.name or "Benzinlik", x + 28*scale, py, x + w - 28*scale, py + 24*scale, theme.text, 1.15*scale, "default-bold", "left", "center")
        py = py + 28*scale
        dxDrawText("Senin benzinliklerin:  " .. (q.owned or 0) .. " / " .. (q.max or 6), x + 28*scale, py, x + w - 28*scale, py + 20*scale, theme.textDim, 0.95*scale, "default", "left", "center")
        py = py + 28*scale
        dxDrawRectangle(x + 28*scale, py, w - 56*scale, 64*scale, theme.card)
        dxDrawText("Satış fiyatı", x + 44*scale, py + 8*scale, x + w - 44*scale, py + 28*scale, theme.textMut, 0.85*scale, "default", "left", "center")
        local priceText = formatMoney(q.price or data.sale_price or Config.DefaultBuyPrice)
        dxDrawText(priceText, x + 44*scale, py + 28*scale, x + w - 44*scale, py + 58*scale, theme.accent, 1.45*scale, "default-bold", "left", "center")
        py = py + 76*scale
        dxDrawText("Satın alınca bu işletmeye özel giriş kodu oluşur.", x + 28*scale, py, x + w - 28*scale, py + 18*scale, theme.textMut, 0.85*scale, "default", "left", "center")
        py = py + 22*scale
        dxDrawText("Sadece bu benzinlik yönetilir · max " .. tostring(q.max or 6) .. " işletme", x + 28*scale, py, x + w - 28*scale, py + 18*scale, theme.warning, 0.9*scale, "default", "left", "center")
        py = py + 22*scale
        dxDrawText("Panel: kod gir veya /benzinlik KOD", x + 28*scale, py, x + w - 28*scale, py + 18*scale, theme.textMut, 0.85*scale, "default", "left", "center")
        py = py + 32*scale
        local btnW = (w - 68*scale) / 2
        if q.canBuy then
            drawBtn(x + 28*scale, py, btnW, 44*scale, "SATIN AL", true, isMouseIn(x + 28*scale, py, btnW, 44*scale))
        else
            drawBtn(x + 28*scale, py, btnW, 44*scale, "LİMİT DOLU", false, false)
        end
        drawBtn(x + 40*scale + btnW, py, btnW, 44*scale, "KAPAT", false, isMouseIn(x + 40*scale + btnW, py, btnW, 44*scale))
    end

    -- ========== SATIN ALMA BAŞARI ==========
    if successUI.visible and successUI.data then
        local info = successUI.data
        local w, h = 460 * scale, 300 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        drawPanel(x, y, w, h)
        dxDrawRectangle(x + 4*scale, y, w - 4*scale, 56*scale, theme.header)
        dxDrawText("✓  SATIN ALINDI", x + 20*scale, y, x + w - 20*scale, y + 56*scale, theme.success, 1.25*scale, "default-bold", "center", "center")

        local py = y + 72*scale
        dxDrawText(info.name or "Benzinlik", x + 24*scale, py, x + w - 24*scale, py + 24*scale, theme.text, 1.1*scale, "default-bold", "center", "center")
        py = py + 36*scale
        dxDrawText("İŞLETME KODUN", x + 24*scale, py, x + w - 24*scale, py + 20*scale, theme.textMut, 0.85*scale, "default", "center", "center")
        py = py + 26*scale
        dxDrawRectangle(x + 50*scale, py, w - 100*scale, 52*scale, theme.card2)
        dxDrawRectangle(x + 50*scale, py, w - 100*scale, 3*scale, theme.accent)
        dxDrawText(tostring(info.code or "??????"), x + 50*scale, py, x + w - 50*scale, py + 52*scale, theme.accent, 1.7*scale, "default-bold", "center", "center")
        py = py + 64*scale
        dxDrawText("Kodu sakla · Benzinliğe girip yazarak paneli aç", x + 24*scale, py, x + w - 24*scale, py + 20*scale, theme.warning, 0.9*scale, "default", "center", "center")
        py = py + 24*scale
        dxDrawText("/benzinlik " .. tostring(info.code or ""), x + 24*scale, py, x + w - 24*scale, py + 18*scale, theme.textDim, 0.9*scale, "default", "center", "center")
        py = py + 32*scale
        drawBtn(x + 90*scale, py, w - 180*scale, 44*scale, "TAMAM", true, isMouseIn(x + 90*scale, py, w - 180*scale, 44*scale))
    end

    -- ========== KOD GİRİŞ ==========
    if codeUI.visible and codeUI.data then
        local data = codeUI.data
        local w, h = 400 * scale, 250 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        drawPanel(x, y, w, h)
        dxDrawRectangle(x + 4*scale, y, w - 4*scale, 56*scale, theme.header)
        dxDrawText("İŞLETME PANELİ", x + 20*scale, y, x + w - 20*scale, y + 36*scale, theme.text, 1.2*scale, "default-bold", "center", "center")
        dxDrawText(data.name or "Benzinlik", x + 20*scale, y + 32*scale, x + w - 20*scale, y + 52*scale, theme.textMut, 0.85*scale, "default", "center", "center")

        local py = y + 72*scale
        dxDrawText("İşletme kodunu gir", x + 24*scale, py, x + w - 24*scale, py + 22*scale, theme.textDim, 0.95*scale, "default", "center", "center")
        py = py + 90*scale
        local half = (w - 64*scale) / 2
        drawBtn(x + 24*scale, py, half, 44*scale, "PANELİ AÇ", true, isMouseIn(x + 24*scale, py, half, 44*scale))
        drawBtn(x + 40*scale + half, py, half, 44*scale, "KAPAT", false, isMouseIn(x + 40*scale + half, py, half, 44*scale))
    end

    -- ========== SAHİP PANELİ ==========
    if ownerUI.visible and ownerUI.data then
        local data = ownerUI.data
        local w, h = 920 * scale, 600 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2

        dxDrawRectangle(x + 5*scale, y + 5*scale, w, h, tocolor(0,0,0,70))
        dxDrawRectangle(x, y, w, h, theme.bg)
        dxDrawRectangle(x, y, w, 52*scale, theme.header)
        dxDrawRectangle(x, y + 52*scale, w, 3*scale, theme.accent)

        dxDrawText(data.name or "İşletme", x + 20*scale, y, x + w - 120*scale, y + 52*scale, theme.text, 1.2*scale, "default-bold", "left", "center")
        dxDrawText("Kod: " .. (data.code or "?"), x + w - 280*scale, y, x + w - 70*scale, y + 52*scale, theme.textDim, 0.95*scale, "default", "right", "center")

        local closeH = isMouseIn(x + w - 48*scale, y + 10*scale, 36*scale, 32*scale)
        dxDrawRectangle(x + w - 48*scale, y + 10*scale, 36*scale, 32*scale, closeH and theme.dangerH or theme.danger)
        dxDrawText("✕", x + w - 48*scale, y + 10*scale, x + w - 12*scale, y + 42*scale, theme.text, 1.2*scale, "default-bold", "center", "center")

        -- Sol menü
        local tabs = {
            {id="overview", label="Genel Bakış"},
            {id="fuel",     label="Yakıt"},
            {id="market",   label="Market"},
            {id="cash",     label="Kasa"},
            {id="ads",      label="Reklam"},
            {id="level",    label="Seviye"},
            {id="stats",    label="İstatistik"},
            {id="security", label="Giriş Kodu"},
            {id="marker",   label="Marker Ekle"},
        }
        local menuW = 175 * scale
        for i, tab in ipairs(tabs) do
            local ty = y + 65*scale + (i-1)*42*scale
            local active = ownerUI.tab == tab.id
            local hover = isMouseIn(x + 10*scale, ty, menuW - 20*scale, 42*scale)
            local col = active and theme.accent or (hover and theme.card2 or theme.card)
            dxDrawRectangle(x + 10*scale, ty, menuW - 20*scale, 42*scale, col)
            if active then
                dxDrawRectangle(x + 10*scale, ty, 4*scale, 42*scale, tocolor(255,255,255,180))
            end
            dxDrawText(tab.label, x + 10*scale, ty, x + menuW - 10*scale, ty + 42*scale, theme.text, 1*scale, "default-bold", "center", "center")
        end

        -- İçerik
        local cx = x + menuW + 15*scale
        local cy = y + 65*scale
        local cw = w - menuW - 30*scale
        local ch = h - 85*scale
        dxDrawRectangle(cx, cy, cw, ch, theme.card)

        if ownerUI.tab == "overview" then
            local levelData = getLevelData(data.level)
            local items = {
                {"İşletme Adı", data.name},
                {"Sahip", data.owner or Config.StateOwnerName},
                {"Seviye", levelData.name},
                {"Kasa", formatMoney(data.balance or 0)},
                {"Benzin Stoğu", (data.petrol_stock or 0) .. " / " .. levelData.capacityPetrol .. " L"},
                {"Dizel Stoğu", (data.diesel_stock or 0) .. " / " .. levelData.capacityDiesel .. " L"},
                {"Benzin Fiyatı", formatMoney(data.petrol_price) .. "/L"},
                {"Dizel Fiyatı", formatMoney(data.diesel_price) .. "/L"},
            }
            for i, item in ipairs(items) do
                local ly = cy + 20*scale + (i-1)*38*scale
                dxDrawRectangle(cx + 15*scale, ly, cw - 30*scale, 34*scale, (i%2==0) and theme.card2 or tocolor(0,0,0,0))
                dxDrawText(item[1], cx + 25*scale, ly, cx + 220*scale, ly + 34*scale, theme.textDim, 0.95*scale, "default", "left", "center")
                dxDrawText(item[2], cx + 230*scale, ly, cx + cw - 25*scale, ly + 34*scale, theme.text, 1*scale, "default-bold", "left", "center")
            end

        elseif ownerUI.tab == "fuel" then
            local levelData = getLevelData(data.level)
            -- Benzin kart
            dxDrawRectangle(cx + 15*scale, cy + 15*scale, (cw-40*scale)/2, 160*scale, theme.card2)
            dxDrawText("BENZİN", cx + 30*scale, cy + 25*scale, cx + 200*scale, cy + 50*scale, theme.accent, 1.15*scale, "default-bold", "left", "center")
            dxDrawText((data.petrol_stock or 0) .. " L", cx + 30*scale, cy + 55*scale, cx + 300*scale, cy + 85*scale, theme.text, 1.4*scale, "default-bold", "left", "center")
            dxDrawText("Kapasite: " .. levelData.capacityPetrol .. " L", cx + 30*scale, cy + 90*scale, cx + 300*scale, cy + 112*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            dxDrawText("Alış: " .. formatMoney(data.petrol_buy) .. "/L   |   Satış: " .. formatMoney(data.petrol_price) .. "/L", cx + 30*scale, cy + 120*scale, cx + 350*scale, cy + 145*scale, theme.textDim, 0.9*scale, "default", "left", "center")

            -- Dizel kart
            local dx2 = cx + 15*scale + (cw-40*scale)/2 + 10*scale
            dxDrawRectangle(dx2, cy + 15*scale, (cw-40*scale)/2, 160*scale, theme.card2)
            dxDrawText("DİZEL", dx2 + 15*scale, cy + 25*scale, dx2 + 200*scale, cy + 50*scale, theme.accent, 1.15*scale, "default-bold", "left", "center")
            dxDrawText((data.diesel_stock or 0) .. " L", dx2 + 15*scale, cy + 55*scale, dx2 + 300*scale, cy + 85*scale, theme.text, 1.4*scale, "default-bold", "left", "center")
            dxDrawText("Kapasite: " .. levelData.capacityDiesel .. " L", dx2 + 15*scale, cy + 90*scale, dx2 + 300*scale, cy + 112*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            dxDrawText("Alış: " .. formatMoney(data.diesel_buy) .. "/L   |   Satış: " .. formatMoney(data.diesel_price) .. "/L", dx2 + 15*scale, cy + 120*scale, dx2 + 350*scale, cy + 145*scale, theme.textDim, 0.9*scale, "default", "left", "center")

        elseif ownerUI.tab == "market" then
            dxDrawText("Mevcut Ürünler", cx + 20*scale, cy + 75*scale, cx + cw - 20*scale, cy + 100*scale, theme.text, 1*scale, "default-bold", "left", "center")
            for i, prod in ipairs(ownerUI.products) do
                if i > 10 then break end
                local ly = cy + 110*scale + (i-1)*32*scale
                dxDrawText(prod.name, cx + 25*scale, ly, cx + 180*scale, ly + 28*scale, theme.text, 0.95*scale, "default", "left", "center")
                dxDrawText("Stok " .. prod.stock, cx + 180*scale, ly, cx + 270*scale, ly + 28*scale, theme.textDim, 0.9*scale, "default", "left", "center")
                dxDrawText("Alış " .. formatMoney(prod.buy_price), cx + 270*scale, ly, cx + 380*scale, ly + 28*scale, theme.textDim, 0.9*scale, "default", "left", "center")
                dxDrawText("Satış " .. formatMoney(prod.sell_price), cx + 380*scale, ly, cx + 500*scale, ly + 28*scale, theme.text, 0.9*scale, "default", "left", "center")
                dxDrawText(prod.active == 1 and "Aktif" or "Pasif", cx + 500*scale, ly, cx + cw - 20*scale, ly + 28*scale, prod.active == 1 and theme.success or theme.danger, 0.9*scale, "default", "left", "center")
            end

        elseif ownerUI.tab == "cash" then
            dxDrawText("Kasa Bakiyesi", cx + 25*scale, cy + 25*scale, cx + cw - 25*scale, cy + 50*scale, theme.textDim, 1*scale, "default", "left", "center")
            dxDrawText(formatMoney(data.balance or 0), cx + 25*scale, cy + 50*scale, cx + cw - 25*scale, cy + 90*scale, theme.accent, 1.6*scale, "default-bold", "left", "center")

        elseif ownerUI.tab == "ads" then
            dxDrawText("Aktif Reklamlar", cx + 20*scale, cy + 200*scale, cx + cw - 20*scale, cy + 225*scale, theme.text, 1*scale, "default-bold", "left", "center")
            if #ownerUI.ads == 0 then
                dxDrawText("Aktif reklam bulunmuyor.", cx + 25*scale, cy + 235*scale, cx + cw - 25*scale, cy + 260*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            else
                for i, ad in ipairs(ownerUI.ads) do
                    local ly = cy + 235*scale + (i-1)*45*scale
                    dxDrawText(ad.title, cx + 25*scale, ly, cx + cw - 25*scale, ly + 20*scale, theme.accent, 1*scale, "default-bold", "left", "center")
                    dxDrawText(ad.message, cx + 25*scale, ly + 20*scale, cx + cw - 25*scale, ly + 40*scale, theme.textDim, 0.9*scale, "default", "left", "center")
                end
            end

        elseif ownerUI.tab == "level" then
            local levelData = getLevelData(data.level)
            local nextData = Config.Levels[(data.level or 1) + 1]
            dxDrawText("Mevcut Seviye", cx + 25*scale, cy + 25*scale, cx + cw - 25*scale, cy + 50*scale, theme.textDim, 1*scale, "default", "left", "center")
            dxDrawText(levelData.name, cx + 25*scale, cy + 50*scale, cx + cw - 25*scale, cy + 85*scale, theme.accent, 1.4*scale, "default-bold", "left", "center")
            dxDrawText("Benzin Kapasitesi: " .. levelData.capacityPetrol .. " L", cx + 25*scale, cy + 100*scale, cx + cw - 25*scale, cy + 125*scale, theme.text, 1*scale, "default", "left", "center")
            dxDrawText("Dizel Kapasitesi: " .. levelData.capacityDiesel .. " L", cx + 25*scale, cy + 130*scale, cx + cw - 25*scale, cy + 155*scale, theme.text, 1*scale, "default", "left", "center")
            dxDrawText("Maksimum Ürün: " .. levelData.maxProducts, cx + 25*scale, cy + 160*scale, cx + cw - 25*scale, cy + 185*scale, theme.text, 1*scale, "default", "left", "center")

            if nextData then
                dxDrawText("Sonraki Seviye: " .. nextData.name, cx + 25*scale, cy + 220*scale, cx + cw - 25*scale, cy + 245*scale, theme.warning, 1.1*scale, "default-bold", "left", "center")
                dxDrawText("Maliyet: " .. formatMoney(nextData.upgradeCost), cx + 25*scale, cy + 250*scale, cx + cw - 25*scale, cy + 275*scale, theme.text, 1*scale, "default", "left", "center")
                local upH = isMouseIn(cx + 25*scale, cy + 300*scale, 220*scale, 44*scale)
                dxDrawRectangle(cx + 25*scale, cy + 300*scale, 220*scale, 44*scale, upH and theme.accentH or theme.accent)
                dxDrawText("SEVİYE YÜKSELT", cx + 25*scale, cy + 300*scale, cx + 245*scale, cy + 344*scale, theme.text, 1.1*scale, "default-bold", "center", "center")
            else
                dxDrawText("Maksimum seviyeye ulaştın!", cx + 25*scale, cy + 230*scale, cx + cw - 25*scale, cy + 260*scale, theme.success, 1.15*scale, "default-bold", "left", "center")
            end

        elseif ownerUI.tab == "stats" then
            dxDrawText("Son 7 Gün", cx + 20*scale, cy + 15*scale, cx + cw - 20*scale, cy + 40*scale, theme.text, 1.05*scale, "default-bold", "left", "center")
            if #ownerUI.stats == 0 then
                dxDrawText("Henüz istatistik verisi yok.", cx + 25*scale, cy + 55*scale, cx + cw - 25*scale, cy + 80*scale, theme.textDim, 1*scale, "default", "left", "center")
            else
                for i, s in ipairs(ownerUI.stats) do
                    local ly = cy + 50*scale + (i-1)*36*scale
                    local net = (s.income or 0) - (s.expense or 0)
                    dxDrawRectangle(cx + 15*scale, ly, cw - 30*scale, 32*scale, (i%2==0) and theme.card2 or tocolor(0,0,0,0))
                    dxDrawText(tostring(s.date), cx + 25*scale, ly, cx + 130*scale, ly + 32*scale, theme.textDim, 0.9*scale, "default", "left", "center")
                    dxDrawText("+" .. formatMoney(s.income or 0), cx + 140*scale, ly, cx + 270*scale, ly + 32*scale, theme.success, 0.9*scale, "default", "left", "center")
                    dxDrawText("-" .. formatMoney(s.expense or 0), cx + 280*scale, ly, cx + 410*scale, ly + 32*scale, theme.danger, 0.9*scale, "default", "left", "center")
                    dxDrawText("Net " .. formatMoney(net), cx + 420*scale, ly, cx + 550*scale, ly + 32*scale, theme.text, 0.95*scale, "default-bold", "left", "center")
                    dxDrawText((s.customers or 0) .. " müşteri", cx + 560*scale, ly, cx + cw - 25*scale, ly + 32*scale, theme.textDim, 0.9*scale, "default", "left", "center")
                end
            end

        elseif ownerUI.tab == "security" then
            dxDrawText("Giriş Kodu / Şifre", cx + 25*scale, cy + 20*scale, cx + cw - 25*scale, cy + 48*scale, theme.text, 1.2*scale, "default-bold", "left", "center")
            dxDrawText("Mevcut kod", cx + 25*scale, cy + 60*scale, cx + cw - 25*scale, cy + 82*scale, theme.textMut, 0.9*scale, "default", "left", "center")
            dxDrawRectangle(cx + 25*scale, cy + 88*scale, 220*scale, 44*scale, theme.card2)
            dxDrawText(tostring(data.code or "????"), cx + 25*scale, cy + 88*scale, cx + 245*scale, cy + 132*scale, theme.accent, 1.4*scale, "default-bold", "center", "center")
            dxDrawText("Yeni kodu yazıp kaydet — sonra bu şifreyle girersin.", cx + 25*scale, cy + 150*scale, cx + cw - 25*scale, cy + 175*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            dxDrawText("4-12 karakter · harf/rakam · örnek: 12345 veya BENZIN1", cx + 25*scale, cy + 178*scale, cx + cw - 25*scale, cy + 200*scale, theme.textMut, 0.85*scale, "default", "left", "center")

        elseif ownerUI.tab == "marker" then
            local q = ownerUI.markerQuote
            dxDrawText("Yeni Marker Ekle", cx + 25*scale, cy + 20*scale, cx + cw - 25*scale, cy + 48*scale, theme.text, 1.2*scale, "default-bold", "left", "center")
            dxDrawText("Aynı işletmeye ek marker (yeni benzinlik değil). Kod aynı kalır.", cx + 25*scale, cy + 55*scale, cx + cw - 25*scale, cy + 78*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            if q then
                dxDrawText("Bu işletmenin markerları: " .. (q.count or 1) .. " / " .. (q.max or 6), cx + 25*scale, cy + 95*scale, cx + cw - 25*scale, cy + 120*scale, theme.text, 1.05*scale, "default-bold", "left", "center")
                dxDrawRectangle(cx + 25*scale, cy + 130*scale, 280*scale, 56*scale, theme.card2)
                dxDrawText(q.label or "Sıradaki", cx + 40*scale, cy + 136*scale, cx + 290*scale, cy + 156*scale, theme.textMut, 0.85*scale, "default", "left", "center")
                local pt = (q.price or 0) <= 0 and "BEDAVA" or formatMoney(q.price)
                dxDrawText(pt, cx + 40*scale, cy + 156*scale, cx + 290*scale, cy + 182*scale, theme.accent, 1.35*scale, "default-bold", "left", "center")
                dxDrawText("Ana marker bedava · 2. ek $10.000 · sonrası $150.000 · max 6", cx + 25*scale, cy + 200*scale, cx + cw - 25*scale, cy + 222*scale, theme.warning, 0.9*scale, "default", "left", "center")
            else
                dxDrawText("Fiyat bilgisi yükleniyor…", cx + 25*scale, cy + 100*scale, cx + cw - 25*scale, cy + 130*scale, theme.textMut, 1*scale, "default", "left", "center")
            end
        end
    end

    -- ========== ADMIN PANELİ ==========
    if adminUI.visible then
        local w, h = 860 * scale, 560 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2

        dxDrawRectangle(x + 5*scale, y + 5*scale, w, h, tocolor(0,0,0,70))
        dxDrawRectangle(x, y, w, h, theme.bg)
        dxDrawRectangle(x, y, w, 50*scale, theme.header)
        dxDrawRectangle(x, y + 50*scale, w, 3*scale, theme.accent)

        dxDrawText("Benzinlik Yönetim Paneli", x + 20*scale, y, x + w - 70*scale, y + 50*scale, theme.text, 1.25*scale, "default-bold", "left", "center")

        local closeH = isMouseIn(x + w - 48*scale, y + 9*scale, 36*scale, 32*scale)
        dxDrawRectangle(x + w - 48*scale, y + 9*scale, 36*scale, 32*scale, closeH and theme.dangerH or theme.danger)
        dxDrawText("✕", x + w - 48*scale, y + 9*scale, x + w - 12*scale, y + 41*scale, theme.text, 1.2*scale, "default-bold", "center", "center")

        if adminUI.mode == "list" then
            local createH = isMouseIn(x + 20*scale, y + 65*scale, 200*scale, 40*scale)
            dxDrawRectangle(x + 20*scale, y + 65*scale, 200*scale, 40*scale, createH and theme.accentH or theme.accent)
            dxDrawText("+  MARKER EKLE", x + 20*scale, y + 65*scale, x + 220*scale, y + 105*scale, theme.text, 1.05*scale, "default-bold", "center", "center")

            local cnt = 0
            for _ in pairs(adminUI.stations) do cnt = cnt + 1 end
            local maxS = Config.MaxStations or 6
            dxDrawText("Marker sayısı: " .. cnt .. " / " .. maxS .. "   ·   1. alım bedava, 2. $10.000, sonrası $150.000", x + 240*scale, y + 65*scale, x + w - 20*scale, y + 105*scale, theme.textDim, 0.9*scale, "default", "left", "center")

            dxDrawText("Mevcut markerlar  (tıkla = düzenle)", x + 20*scale, y + 118*scale, x + w - 20*scale, y + 140*scale, theme.textDim, 0.95*scale, "default", "left", "center")

            local list = {}
            for _, st in pairs(adminUI.stations) do table.insert(list, st) end
            table.sort(list, function(a,b) return (a.id or 0) < (b.id or 0) end)

            for i, st in ipairs(list) do
                if i > 11 then break end
                local ly = y + 145*scale + (i-1)*34*scale
                local hover = isMouseIn(x + 20*scale, ly, w - 40*scale, 32*scale)
                local selected = adminUI.selected and adminUI.selected.id == st.id
                dxDrawRectangle(x + 20*scale, ly, w - 40*scale, 32*scale, selected and theme.accent or (hover and theme.card2 or tocolor(0,0,0,0)))

                local ownerStr = st.owner or "Devlet"
                local saleStr = st.for_sale == 1 and ("  •  SATILIK " .. formatMoney(st.sale_price or 0)) or ""
                dxDrawText(string.format("#%d   %s   [%s]   %s%s", st.id, st.name or "?", st.code or "?", ownerStr, saleStr),
                    x + 30*scale, ly, x + w - 30*scale, ly + 32*scale, theme.text, 0.95*scale, "default", "left", "center")
            end

        elseif adminUI.mode == "create" then
            dxDrawText("MARKER EKLE", x + 25*scale, y + 58*scale, x + w - 25*scale, y + 85*scale, theme.text, 1.2*scale, "default-bold", "left", "center")
            dxDrawText("Bulunduğun konuma yeni satılık benzinlik markerı eklenir. Max 6.", x + 25*scale, y + 230*scale, x + w - 25*scale, y + 255*scale, theme.textDim, 0.95*scale, "default", "left", "center")
            dxDrawText("Oyuncu alım fiyatı: 1. bedava · 2. $10.000 · sonrası $150.000", x + 25*scale, y + 255*scale, x + w - 25*scale, y + 278*scale, theme.warning, 0.9*scale, "default", "left", "center")

        elseif adminUI.mode == "edit" and adminUI.selected then
            dxDrawText("Benzinlik Düzenle", x + 25*scale, y + 55*scale, x + w - 25*scale, y + 78*scale, theme.text, 1.1*scale, "default-bold", "left", "center")
        end
    end
end)

-- ===================== CLICK =====================
addEventHandler("onClientClick", root, function(button, state)
    if button ~= "left" or state ~= "down" then return end
    local cx, cy = getCursorPosition()
    if not cx then return end
    cx, cy = cx * sx, cy * sy

    -- Satın alma
    if buyUI.visible and buyUI.data then
        local w, h = 440 * scale, 360 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        local py = y + 70*scale + 28*scale + 28*scale + 76*scale + 22*scale + 22*scale + 32*scale
        local btnW = (w - 68*scale) / 2
        local q = buyUI.quote or { canBuy = true }
        if isMouseIn(x + 28*scale, py, btnW, 44*scale) then
            if q.canBuy ~= false then
                triggerServerEvent("benzinlik:buyStation", localPlayer, buyUI.data.id)
            else
                outputChatBox("» Maksimum market limitine ulaştın.", 255, 80, 80)
            end
            return
        end
        if isMouseIn(x + 40*scale + btnW, py, btnW, 44*scale) then
            buyUI.visible = false
            buyUI.data = nil
            showCursor(false)
            return
        end
    end

    -- Satın alma başarı
    if successUI.visible and successUI.data then
        local w, h = 460 * scale, 300 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        local py = y + 72*scale + 36*scale + 26*scale + 64*scale + 24*scale + 32*scale
        if isMouseIn(x + 90*scale, py, w - 180*scale, 44*scale) then
            successUI.visible = false
            successUI.data = nil
            showCursor(false)
            return
        end
    end

    -- Kod girişi
    if codeUI.visible and codeUI.data then
        local w, h = 400 * scale, 250 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2
        local py = y + 72*scale + 90*scale
        local half = (w - 64*scale) / 2
        if isMouseIn(x + 24*scale, py, half, 44*scale) then
            local code = ""
            if codeUI.edit and isElement(codeUI.edit) then
                code = guiGetText(codeUI.edit) or ""
            end
            if code ~= "" then
                triggerServerEvent("benzinlik:openByCode", localPlayer, code)
                triggerEvent("benzinlik:hideCodeUI", localPlayer)
            else
                outputChatBox("» Kod gir.", 255, 200, 0)
            end
            return
        end
        if isMouseIn(x + 40*scale + half, py, half, 44*scale) then
            triggerEvent("benzinlik:hideCodeUI", localPlayer)
            return
        end
    end

    -- Sahip paneli
    if ownerUI.visible and ownerUI.data then
        local w, h = 920 * scale, 600 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2

        if isMouseIn(x + w - 48*scale, y + 10*scale, 36*scale, 32*scale) then
            closeOwnerPanel()
            return
        end

        local tabs = {"overview","fuel","market","cash","ads","level","stats","security","marker"}
        local menuW = 175 * scale
        for i, tabId in ipairs(tabs) do
            local ty = y + 65*scale + (i-1)*42*scale
            if isMouseIn(x + 10*scale, ty, menuW - 20*scale, 42*scale) then
                ownerUI.tab = tabId
                rebuildOwnerInputs()
                return
            end
        end

        if ownerUI.tab == "level" then
            local nextData = Config.Levels[(ownerUI.data.level or 1) + 1]
            if nextData then
                local cx = x + menuW + 15*scale
                local cy = y + 65*scale
                if isMouseIn(cx + 25*scale, cy + 300*scale, 220*scale, 44*scale) then
                    triggerServerEvent("benzinlik:upgradeLevel", localPlayer, ownerUI.data.id)
                    return
                end
            end
        end
    end

    -- Admin paneli
    if adminUI.visible then
        local w, h = 860 * scale, 560 * scale
        local x = (sx - w) / 2
        local y = (sy - h) / 2

        if isMouseIn(x + w - 48*scale, y + 9*scale, 36*scale, 32*scale) then
            closeAdminPanel()
            return
        end

        if adminUI.mode == "list" then
            if isMouseIn(x + 20*scale, y + 65*scale, 200*scale, 40*scale) then
                adminUI.mode = "create"
                rebuildAdminInputs()
                return
            end

            local list = {}
            for _, st in pairs(adminUI.stations) do table.insert(list, st) end
            table.sort(list, function(a,b) return (a.id or 0) < (b.id or 0) end)
            for i, st in ipairs(list) do
                if i > 11 then break end
                local ly = y + 145*scale + (i-1)*34*scale
                if isMouseIn(x + 20*scale, ly, w - 40*scale, 32*scale) then
                    adminUI.selected = st
                    adminUI.mode = "edit"
                    rebuildAdminInputs()
                    return
                end
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not press then return end
    if key == "escape" then
        if buyUI.visible or successUI.visible or codeUI.visible or ownerUI.visible or adminUI.visible then
            buyUI.visible = false
            buyUI.data = nil
            successUI.visible = false
            successUI.data = nil
            triggerEvent("benzinlik:hideCodeUI", localPlayer)
            closeOwnerPanel()
            closeAdminPanel()
            cancelEvent()
        end
    end
end)
