--[[
    Yakıt + Market UI — premium koyu tema
]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local fuelUI = {
    visible = false,
    data = nil,
    tab = "fuel",
    selectedLiters = 20,
    selectedType = "petrol",
    products = {},
}

local T = {
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
    border  = tocolor(55, 62, 78, 255),
    petrol  = tocolor(56, 189, 248, 255),
    diesel  = tocolor(251, 191, 36, 255),
}

local function mouseIn(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function panel(x, y, w, h)
    dxDrawRectangle(x + 5*scale, y + 6*scale, w, h, tocolor(0, 0, 0, 100))
    dxDrawRectangle(x, y, w, h, T.bg)
    dxDrawRectangle(x, y, 4*scale, h, T.accent)
end

local function btn(x, y, w, h, label, primary, hover)
    local col
    if primary then
        col = hover and T.accentH or T.accent
    else
        col = hover and T.card3 or T.card2
    end
    dxDrawRectangle(x, y, w, h, col)
    if primary then
        dxDrawRectangle(x, y + h - 3*scale, w, 3*scale, T.accentD)
    end
    dxDrawText(label, x, y, x + w, y + h, T.text, 1.0*scale, "default-bold", "center", "center")
end

addEvent("benzinlik:receiveProducts", true)
addEventHandler("benzinlik:receiveProducts", resourceRoot, function(products)
    fuelUI.products = products or {}
end)

addEvent("benzinlik:showFuelUI", true)
addEventHandler("benzinlik:showFuelUI", localPlayer, function(data)
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or getPedOccupiedVehicleSeat(localPlayer) ~= 0 then return end
    fuelUI.visible = true
    fuelUI.data = data
    fuelUI.tab = "fuel"
    fuelUI.selectedLiters = 20
    fuelUI.selectedType = "petrol"
    showCursor(true)
    triggerServerEvent("benzinlik:requestProducts", localPlayer, data.id)
end)

addEvent("benzinlik:hideFuelUI", true)
addEventHandler("benzinlik:hideFuelUI", localPlayer, function()
    fuelUI.visible = false
    fuelUI.data = nil
    showCursor(false)
end)

addEvent("benzinlik:addVehicleFuel", true)
addEventHandler("benzinlik:addVehicleFuel", resourceRoot, function(liters, fuelType)
    if not getPedOccupiedVehicle(localPlayer) then return end
    outputChatBox("» Araca " .. liters .. "L yakıt eklendi. (Yakıt sisteminize entegre edin)", 0, 200, 255)
end)

addEventHandler("onClientRender", root, function()
    if not fuelUI.visible or not fuelUI.data then return end
    if not getPedOccupiedVehicle(localPlayer) then
        fuelUI.visible = false
        fuelUI.data = nil
        showCursor(false)
        return
    end
    if not isCursorShowing() then showCursor(true) end

    local data = fuelUI.data
    local w, h = 520 * scale, 460 * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2

    panel(x, y, w, h)

    -- Header
    dxDrawRectangle(x + 4*scale, y, w - 4*scale, 56*scale, T.header)
    dxDrawText(data.name or "Benzinlik", x + 24*scale, y, x + w - 70*scale, y + 56*scale, T.text, 1.25*scale, "default-bold", "left", "center")
    dxDrawText("YAKIT  ·  MARKET", x + 24*scale, y + 32*scale, x + w - 70*scale, y + 52*scale, T.textMut, 0.8*scale, "default", "left", "center")

    local cH = mouseIn(x + w - 48*scale, y + 12*scale, 32*scale, 32*scale)
    dxDrawRectangle(x + w - 48*scale, y + 12*scale, 32*scale, 32*scale, cH and tocolor(220, 60, 60, 255) or T.card2)
    dxDrawText("✕", x + w - 48*scale, y + 12*scale, x + w - 16*scale, y + 44*scale, T.text, 1.1*scale, "default-bold", "center", "center")

    -- Tabs
    local tabY = y + 68*scale
    local tabW = (w - 48*scale) / 2
    local fHov = mouseIn(x + 16*scale, tabY, tabW, 40*scale)
    local mHov = mouseIn(x + 24*scale + tabW, tabY, tabW, 40*scale)

    dxDrawRectangle(x + 16*scale, tabY, tabW, 40*scale, fuelUI.tab == "fuel" and T.accent or (fHov and T.card3 or T.card))
    dxDrawText("⛽  YAKIT", x + 16*scale, tabY, x + 16*scale + tabW, tabY + 40*scale, T.text, 1.0*scale, "default-bold", "center", "center")

    dxDrawRectangle(x + 24*scale + tabW, tabY, tabW, 40*scale, fuelUI.tab == "market" and T.accent or (mHov and T.card3 or T.card))
    dxDrawText("🛒  MARKET", x + 24*scale + tabW, tabY, x + 24*scale + tabW * 2, tabY + 40*scale, T.text, 1.0*scale, "default-bold", "center", "center")

    local cy = tabY + 56*scale

    if fuelUI.tab == "fuel" then
        local cardW = (w - 48*scale) / 2

        -- Benzin kart
        dxDrawRectangle(x + 16*scale, cy, cardW, 88*scale, T.card)
        dxDrawRectangle(x + 16*scale, cy, 4*scale, 88*scale, T.petrol)
        dxDrawText("BENZİN", x + 32*scale, cy + 10*scale, x + 16*scale + cardW, cy + 30*scale, T.petrol, 0.9*scale, "default-bold", "left", "center")
        dxDrawText(formatMoney(data.petrol_price) .. "/L", x + 32*scale, cy + 32*scale, x + 16*scale + cardW, cy + 58*scale, T.text, 1.35*scale, "default-bold", "left", "center")
        dxDrawText("Stok  " .. (data.petrol_stock or 0) .. " L", x + 32*scale, cy + 60*scale, x + 16*scale + cardW, cy + 80*scale, T.textDim, 0.9*scale, "default", "left", "center")

        -- Dizel kart
        local dx2 = x + 24*scale + cardW
        dxDrawRectangle(dx2, cy, cardW, 88*scale, T.card)
        dxDrawRectangle(dx2, cy, 4*scale, 88*scale, T.diesel)
        dxDrawText("DİZEL", dx2 + 16*scale, cy + 10*scale, dx2 + cardW, cy + 30*scale, T.diesel, 0.9*scale, "default-bold", "left", "center")
        dxDrawText(formatMoney(data.diesel_price) .. "/L", dx2 + 16*scale, cy + 32*scale, dx2 + cardW, cy + 58*scale, T.text, 1.35*scale, "default-bold", "left", "center")
        dxDrawText("Stok  " .. (data.diesel_stock or 0) .. " L", dx2 + 16*scale, cy + 60*scale, dx2 + cardW, cy + 80*scale, T.textDim, 0.9*scale, "default", "left", "center")

        local py = cy + 108*scale
        dxDrawText("Yakıt tipi seç", x + 16*scale, py, x + w - 16*scale, py + 22*scale, T.textDim, 0.9*scale, "default", "left", "center")
        py = py + 28*scale

        local bW = (w - 48*scale) / 2
        local pSel = fuelUI.selectedType == "petrol"
        local dSel = fuelUI.selectedType == "diesel"
        dxDrawRectangle(x + 16*scale, py, bW, 44*scale, pSel and T.petrol or T.card2)
        dxDrawText(pSel and "●  BENZİN" or "○  BENZİN", x + 16*scale, py, x + 16*scale + bW, py + 44*scale, T.text, 1.0*scale, "default-bold", "center", "center")
        dxDrawRectangle(x + 24*scale + bW, py, bW, 44*scale, dSel and T.diesel or T.card2)
        dxDrawText(dSel and "●  DİZEL" or "○  DİZEL", x + 24*scale + bW, py, x + 24*scale + bW * 2, py + 44*scale, T.text, 1.0*scale, "default-bold", "center", "center")

        py = py + 60*scale
        dxDrawText("Litre", x + 16*scale, py, x + w - 16*scale, py + 20*scale, T.textDim, 0.9*scale, "default", "center", "center")
        py = py + 26*scale

        local mH = mouseIn(x + 90*scale, py, 52*scale, 40*scale)
        local pH = mouseIn(x + w - 142*scale, py, 52*scale, 40*scale)
        dxDrawRectangle(x + 90*scale, py, 52*scale, 40*scale, mH and T.card3 or T.card)
        dxDrawText("−", x + 90*scale, py, x + 142*scale, py + 40*scale, T.text, 1.5*scale, "default-bold", "center", "center")
        dxDrawText(tostring(fuelUI.selectedLiters) .. " L", x + 150*scale, py, x + w - 150*scale, py + 40*scale, T.text, 1.4*scale, "default-bold", "center", "center")
        dxDrawRectangle(x + w - 142*scale, py, 52*scale, 40*scale, pH and T.card3 or T.card)
        dxDrawText("+", x + w - 142*scale, py, x + w - 90*scale, py + 40*scale, T.text, 1.5*scale, "default-bold", "center", "center")

        py = py + 52*scale
        local price = (fuelUI.selectedType == "petrol" and data.petrol_price or data.diesel_price) or 50
        local total = fuelUI.selectedLiters * price
        dxDrawRectangle(x + 16*scale, py, w - 32*scale, 44*scale, T.card)
        dxDrawText("Toplam", x + 28*scale, py, x + 150*scale, py + 44*scale, T.textDim, 0.95*scale, "default", "left", "center")
        dxDrawText(formatMoney(total), x + 150*scale, py, x + w - 28*scale, py + 44*scale, T.accent, 1.35*scale, "default-bold", "right", "center")

        py = py + 56*scale
        local buyH = mouseIn(x + 16*scale, py, w - 32*scale, 48*scale)
        btn(x + 16*scale, py, w - 32*scale, 48*scale, "YAKIT DOLDUR", true, buyH)

    else
        dxDrawText("Market ürünleri", x + 20*scale, cy, x + w - 20*scale, cy + 24*scale, T.textDim, 0.95*scale, "default", "left", "center")
        local listY = cy + 32*scale
        local shown = 0
        if #fuelUI.products == 0 then
            dxDrawText("Ürün yok veya yükleniyor…", x + 20*scale, listY + 40*scale, x + w - 20*scale, listY + 70*scale, T.textMut, 1*scale, "default", "center", "center")
        else
            for _, prod in ipairs(fuelUI.products) do
                if prod.active == 1 and (prod.stock or 0) > 0 then
                    shown = shown + 1
                    if shown > 7 then break end
                    local ly = listY + (shown - 1) * 42 * scale
                    dxDrawRectangle(x + 16*scale, ly, w - 32*scale, 38*scale, T.card)
                    dxDrawText(prod.name, x + 28*scale, ly, x + 200*scale, ly + 38*scale, T.text, 0.95*scale, "default-bold", "left", "center")
                    dxDrawText(formatMoney(prod.sell_price), x + 200*scale, ly, x + 300*scale, ly + 38*scale, T.accent, 0.95*scale, "default-bold", "left", "center")
                    dxDrawText("×" .. prod.stock, x + 300*scale, ly, x + 380*scale, ly + 38*scale, T.textDim, 0.9*scale, "default", "left", "center")
                    local bH = mouseIn(x + w - 108*scale, ly + 5*scale, 76*scale, 28*scale)
                    dxDrawRectangle(x + w - 108*scale, ly + 5*scale, 76*scale, 28*scale, bH and T.accentH or T.accent)
                    dxDrawText("AL", x + w - 108*scale, ly + 5*scale, x + w - 32*scale, ly + 33*scale, T.text, 0.9*scale, "default-bold", "center", "center")
                end
            end
            if shown == 0 then
                dxDrawText("Satışta ürün yok.", x + 20*scale, listY + 40*scale, x + w - 20*scale, listY + 70*scale, T.textMut, 1*scale, "default", "center", "center")
            end
        end
    end
end)

addEventHandler("onClientClick", root, function(button, state)
    if button ~= "left" or state ~= "down" or not fuelUI.visible or not fuelUI.data then return end
    local data = fuelUI.data
    local w, h = 520 * scale, 460 * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2

    if mouseIn(x + w - 48*scale, y + 12*scale, 32*scale, 32*scale) then
        fuelUI.visible = false
        fuelUI.data = nil
        showCursor(false)
        return
    end

    local tabY = y + 68*scale
    local tabW = (w - 48*scale) / 2
    if mouseIn(x + 16*scale, tabY, tabW, 40*scale) then fuelUI.tab = "fuel" return end
    if mouseIn(x + 24*scale + tabW, tabY, tabW, 40*scale) then fuelUI.tab = "market" return end

    if fuelUI.tab == "fuel" then
        local cy = tabY + 56*scale
        local py = cy + 108*scale + 28*scale
        local bW = (w - 48*scale) / 2
        if mouseIn(x + 16*scale, py, bW, 44*scale) then fuelUI.selectedType = "petrol" return end
        if mouseIn(x + 24*scale + bW, py, bW, 44*scale) then fuelUI.selectedType = "diesel" return end
        py = py + 60*scale + 26*scale
        if mouseIn(x + 90*scale, py, 52*scale, 40*scale) then
            fuelUI.selectedLiters = math.max(1, fuelUI.selectedLiters - 5)
            return
        end
        if mouseIn(x + w - 142*scale, py, 52*scale, 40*scale) then
            fuelUI.selectedLiters = math.min(100, fuelUI.selectedLiters + 5)
            return
        end
        py = py + 52*scale + 56*scale
        if mouseIn(x + 16*scale, py, w - 32*scale, 48*scale) then
            triggerServerEvent("benzinlik:buyFuel", localPlayer, data.id, fuelUI.selectedType, fuelUI.selectedLiters)
            return
        end
    else
        local listY = tabY + 56*scale + 32*scale
        local shown = 0
        for _, prod in ipairs(fuelUI.products) do
            if prod.active == 1 and (prod.stock or 0) > 0 then
                shown = shown + 1
                if shown > 7 then break end
                local ly = listY + (shown - 1) * 42 * scale
                if mouseIn(x + w - 108*scale, ly + 5*scale, 76*scale, 28*scale) then
                    triggerServerEvent("benzinlik:buyProduct", localPlayer, data.id, prod.id, 1)
                    return
                end
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not press or not fuelUI.visible then return end
    if key == "escape" then
        fuelUI.visible = false
        fuelUI.data = nil
        showCursor(false)
        cancelEvent()
    end
end)
