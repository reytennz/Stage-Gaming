local sw, sh = guiGetScreenSize()
local bankVisible, activeTab = false, "home"
local authed = false
local latest = nil
local bankEdits = {}
local activeEdit = nil
local panelCreated = false
local amount, pin, target, loginPinEdit
local loginError = nil
local svg = {}

local function round(id, x, y, w, h, r, colour)
    w, h = math.max(1, math.floor(w)), math.max(1, math.floor(h))
    local k = id .. w .. h .. r
    if not svg[k] or not isElement(svg[k]) then
        svg[k] = svgCreate(w, h, string.format('<svg width="%d" height="%d"><rect width="%d" height="%d" rx="%d" fill="#fff"/></svg>', w, h, w, h, r))
    end
    if svg[k] and isElement(svg[k]) then
        dxDrawImage(x, y, w, h, svg[k], 0, 0, 0, colour)
    else
        dxDrawRectangle(x, y, w, h, colour)
    end
end

local function fmt(n)
    return "$" .. tostring(math.floor(tonumber(n) or 0)):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

local function isMouseIn(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sw, cy * sh
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function focusEdit(edit, x, y, w, h)
    for _, e in ipairs(bankEdits) do
        if e ~= edit and isElement(e) then
            guiSetVisible(e, false)
        end
    end
    activeEdit = edit
    if edit and isElement(edit) then
        guiSetPosition(edit, x, y, false)
        guiSetSize(edit, w, h, false)
        guiSetVisible(edit, true)
        guiBringToFront(edit)
        guiSetInputEnabled(true)
    else
        guiSetInputEnabled(false)
    end
end

local function close()
    bankVisible = false
    authed = false
    loginError = nil
    focusEdit(nil)
    for _, edit in pairs(bankEdits) do
        if isElement(edit) then
            guiSetVisible(edit, false)
        end
    end
    guiSetInputEnabled(false)
    showCursor(false)
end

local function makePanel()
    if panelCreated then return end
    panelCreated = true

    amount = guiCreateEdit(0, 0, 1, 1, "", false)
    pin = guiCreateEdit(0, 0, 1, 1, "", false)
    target = guiCreateEdit(0, 0, 1, 1, "", false)
    loginPinEdit = guiCreateEdit(0, 0, 1, 1, "", false)

    guiEditSetMaxLength(amount, 12)
    guiEditSetMaxLength(pin, 6)
    guiEditSetMaxLength(target, 32)
    guiEditSetMaxLength(loginPinEdit, 6)

    guiEditSetMasked(pin, true)
    guiEditSetMasked(loginPinEdit, true)

    for _, edit in ipairs({amount, pin, target, loginPinEdit}) do
        guiSetAlpha(edit, 0)
        guiSetVisible(edit, false)
        table.insert(bankEdits, edit)
    end
end

local function drawField(x, y, w, h, title, edit, masked)
    if title and title ~= "" then
        dxDrawText(title, x, y - 20, x + w, y, tocolor(255, 204, 0, 230), 0.78, "default-bold", "left", "center")
    end
    local isFocused = (activeEdit == edit)
    local isHover = isMouseIn(x, y, w, h)
    
    round("fld_" .. (title ~= "" and title or tostring(edit)), x, y, w, h, 8, tocolor(20, 24, 30, 245))
    dxDrawRectangle(x + 1, y + h - 2, w - 2, 2, isFocused and tocolor(255, 204, 0, 255) or (isHover and tocolor(255, 204, 0, 180) or tocolor(255, 204, 0, 110)))
    
    local value = (edit and isElement(edit)) and guiGetText(edit) or ""
    if masked and value ~= "" then
        value = string.rep("●", #value)
    end
    local displayText = value ~= "" and value or (isFocused and "" or "Yazınız...")
    local displayColor = value ~= "" and tocolor(245, 245, 245, 255) or tocolor(120, 130, 145, 180)
    dxDrawText(displayText, x + 14, y, x + w - 14, y + h, displayColor, 0.88, "default-bold", "left", "center")
end

local function bankButton(id, x, y, w, h, text, isPrimary, isDanger)
    local isHover = isMouseIn(x, y, w, h)
    if isDanger then
        round("btn_" .. id, x, y, w, h, 8, isHover and tocolor(230, 60, 60, 250) or tocolor(185, 45, 45, 235))
        dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255), 0.88, "default-bold", "center", "center")
    elseif isPrimary then
        round("btn_" .. id, x, y, w, h, 8, isHover and tocolor(255, 220, 50, 255) or tocolor(255, 204, 0, 245))
        dxDrawText(text, x, y, x + w, y + h, tocolor(16, 18, 22, 255), 0.9, "default-bold", "center", "center")
    else
        round("btn_" .. id, x, y, w, h, 8, isHover and tocolor(38, 44, 54, 245) or tocolor(26, 30, 38, 235))
        dxDrawText(text, x, y, x + w, y + h, tocolor(235, 240, 245, 255), 0.88, "default-bold", "center", "center")
    end
end

local menuItems = {
    { id = "home", label = "Ana Sayfa", icon = "📊 " },
    { id = "deposit", label = "Para Yatır", icon = "📥 " },
    { id = "withdraw", label = "Para Çek", icon = "📤 " },
    { id = "transfer", label = "Transfer", icon = "🔁 " },
    { id = "close", label = "Kapat", icon = "✕ " }, -- Transfer'in hemen altında!
}

local numpadKeys = {
    {"1", "2", "3"},
    {"4", "5", "6"},
    {"7", "8", "9"},
    {"C", "0", "⌫"}
}

local function drawBank()
    if not bankVisible then return end

    local bankW = math.min(920, sw - 40)
    local bankH = math.min(580, sh - 40)
    local bankX = math.floor((sw - bankW) / 2)
    local bankY = math.floor((sh - bankH) / 2)
    local headerH = 70
    local sideW = 210

    -- Karartma Arka Planı
    dxDrawRectangle(0, 0, sw, sh, tocolor(0, 0, 0, 140))

    -- Ana Pencere Gövdesi (Siyah / Koyu Grafit)
    round("bankShell", bankX, bankY, bankW, bankH, 10, tocolor(14, 16, 20, 250))
    dxDrawRectangle(bankX + 2, bankY, bankW - 4, 3, tocolor(255, 204, 0, 255)) -- En üst altın sarısı çizgi

    -- Üst Başlık Alanı
    dxDrawRectangle(bankX, bankY + 3, bankW, headerH - 3, tocolor(19, 22, 28, 245))
    dxDrawLine(bankX, bankY + headerH, bankX + bankW, bankY + headerH, tocolor(255, 204, 0, 60), 1)

    -- STAGE BANK Logosu (Sarı & Beyaz)
    dxDrawText("STAGE", bankX + 24, bankY + 14, bankX + 115, bankY + 38, tocolor(255, 204, 0, 255), 1.15, "default-bold", "left", "center")
    dxDrawText("BANK", bankX + 24, bankY + 36, bankX + 115, bankY + 60, tocolor(245, 245, 245, 255), 1.15, "default-bold", "left", "center")

    dxDrawLine(bankX + 110, bankY + 18, bankX + 110, bankY + 54, tocolor(55, 62, 75, 180), 1)
    dxDrawText("DASHBOARD & ONLINE BANKACILIK", bankX + 125, bankY + 20, bankX + 450, bankY + 52, tocolor(165, 172, 185, 220), 0.78, "default-bold", "left", "center")

    -- Üst Sağ Kapatma Butonu [X]
    local closeX, closeY, closeSize = bankX + bankW - 42, bankY + 18, 30
    local isCloseHover = isMouseIn(closeX, closeY, closeSize, closeSize)
    round("topClose", closeX, closeY, closeSize, closeSize, 6, isCloseHover and tocolor(200, 50, 50, 200) or tocolor(28, 32, 40, 180))
    dxDrawText("✕", closeX, closeY, closeX + closeSize, closeY + closeSize, isCloseHover and tocolor(255, 255, 255) or tocolor(170, 175, 185), 0.85, "default-bold", "center", "center")

    -- Sol Menü Alanı
    dxDrawRectangle(bankX, bankY + headerH + 1, sideW, bankH - headerH - 1, tocolor(16, 18, 23, 235))
    dxDrawLine(bankX + sideW, bankY + headerH + 1, bankX + sideW, bankY + bankH, tocolor(35, 40, 50, 180), 1)

    local menuStartX = bankX + 14
    local menuW = sideW - 28
    local menuStartY = bankY + 92
    local itemH = 40
    local itemGap = 8

    if not authed then
        -- Giriş yapılmamışken Menü (Giriş Yap ve Kapat)
        local loginItems = {
            { id = "auth", label = "Giriş Yap", icon = "🔒 " },
            { id = "close", label = "Kapat", icon = "✕ " }
        }
        for i, item in ipairs(loginItems) do
            local itemY = menuStartY + (i - 1) * (itemH + itemGap)
            local isHover = isMouseIn(menuStartX, itemY, menuW, itemH)
            if item.id == "close" then
                round("lmenu_" .. item.id, menuStartX, itemY, menuW, itemH, 6, isHover and tocolor(200, 50, 50, 45) or tocolor(26, 22, 25, 200))
                dxDrawRectangle(menuStartX, itemY, 4, itemH, isHover and tocolor(235, 65, 65, 255) or tocolor(190, 55, 55, 200))
                dxDrawText(item.icon .. item.label, menuStartX + 16, itemY, menuStartX + menuW, itemY + itemH, isHover and tocolor(255, 120, 120, 255) or tocolor(220, 100, 100, 230), 0.82, "default-bold", "left", "center")
            else
                round("lmenu_" .. item.id, menuStartX, itemY, menuW, itemH, 6, tocolor(255, 204, 0, 32))
                dxDrawRectangle(menuStartX, itemY, 4, itemH, tocolor(255, 204, 0, 255))
                dxDrawText(item.icon .. item.label, menuStartX + 16, itemY, menuStartX + menuW, itemY + itemH, tocolor(255, 204, 0, 255), 0.85, "default-bold", "left", "center")
            end
        end
    else
        -- Giriş Yapıldıktan Sonra Menü (Ana Sayfa, Para Yatır, Para Çek, Transfer, Kapat)
        for i, item in ipairs(menuItems) do
            local itemY = menuStartY + (i - 1) * (itemH + itemGap)
            local isHover = isMouseIn(menuStartX, itemY, menuW, itemH)

            if item.id == "close" then
                -- Kapat Butonu (Transfer'in hemen altında, kırmızı/koyu şık vurgulu)
                round("menu_" .. item.id, menuStartX, itemY, menuW, itemH, 6, isHover and tocolor(200, 50, 50, 45) or tocolor(26, 22, 25, 200))
                dxDrawRectangle(menuStartX, itemY, 4, itemH, isHover and tocolor(235, 65, 65, 255) or tocolor(190, 55, 55, 200))
                dxDrawText(item.icon .. item.label, menuStartX + 16, itemY, menuStartX + menuW, itemY + itemH, isHover and tocolor(255, 120, 120, 255) or tocolor(220, 100, 100, 230), 0.82, "default-bold", "left", "center")
            else
                local isActive = (activeTab == item.id)
                if isActive then
                    round("menu_" .. item.id, menuStartX, itemY, menuW, itemH, 6, tocolor(255, 204, 0, 32))
                    dxDrawRectangle(menuStartX, itemY, 4, itemH, tocolor(255, 204, 0, 255))
                    dxDrawText(item.icon .. item.label, menuStartX + 16, itemY, menuStartX + menuW, itemY + itemH, tocolor(255, 204, 0, 255), 0.85, "default-bold", "left", "center")
                else
                    if isHover then
                        round("menu_" .. item.id, menuStartX, itemY, menuW, itemH, 6, tocolor(255, 255, 255, 10))
                    end
                    dxDrawText(item.icon .. item.label, menuStartX + 16, itemY, menuStartX + menuW, itemY + itemH, isHover and tocolor(245, 245, 245, 255) or tocolor(160, 168, 180, 220), 0.82, "default-bold", "left", "center")
                end
            end
        end
    end

    -- Sol Alt Bilgi
    dxDrawText("ESC ile de kapatabilirsiniz", bankX + 14, bankY + bankH - 30, bankX + sideW - 14, bankY + bankH - 10, tocolor(100, 108, 120, 180), 0.72, "default", "center", "center")

    -- Sağ İçerik Alanı
    local cx = bankX + sideW + 30
    local right = bankX + bankW - 30
    local cw = right - cx

    if not authed then
        -- ================= ŞİFRELİ GİRİŞ EKRANI (DASHBOARD GUİ FORMATINDA) =================
        local isFirstTime = (latest and not latest.hasPin)
        local loginTitle = isFirstTime and "YENİ PIN KODU BELİRLEME" or "GÜVENLİ BANKA GİRİŞİ"
        local loginSub = isFirstTime and "Hesabınız için lütfen 4-6 haneli güvenlik PIN kodunuzu oluşturun." or "Banka işlemlerinize erişebilmek için lütfen PIN kodunuzu giriniz."

        dxDrawText(loginTitle, cx, bankY + 86, right, bankY + 110, tocolor(255, 204, 0, 255), 1.1, "default-bold", "left", "center")
        dxDrawText(loginSub, cx, bankY + 110, right, bankY + 130, tocolor(150, 158, 170, 220), 0.78, "default", "left", "center")

        -- Ortalanmış PIN Kartı
        local pinCardW = 340
        local pinCardH = 340
        local pinCardX = cx + math.floor((cw - pinCardW) / 2)
        local pinCardY = bankY + 145

        round("pinCardBox", pinCardX, pinCardY, pinCardW, pinCardH, 10, tocolor(21, 25, 32, 240))
        dxDrawRectangle(pinCardX + 2, pinCardY, pinCardW - 4, 2, tocolor(255, 204, 0, 200))

        -- PIN Girdi Alanı
        drawField(pinCardX + 20, pinCardY + 30, pinCardW - 40, 44, "GÜVENLİK PIN KODU", loginPinEdit, true)

        -- Sarı Numpad Tuş Takımı
        local nStartX = pinCardX + 20
        local nStartY = pinCardY + 88
        local kw = 94
        local kh = 38
        local kgap = 9

        for r, row in ipairs(numpadKeys) do
            for c, k in ipairs(row) do
                local kx = nStartX + (c - 1) * (kw + kgap)
                local ky = nStartY + (r - 1) * (kh + kgap)
                local isHover = isMouseIn(kx, ky, kw, kh)

                if k == "C" then
                    round("npk_" .. k, kx, ky, kw, kh, 6, isHover and tocolor(180, 50, 50, 220) or tocolor(28, 24, 26, 230))
                    dxDrawText(k, kx, ky, kx + kw, ky + kh, isHover and tocolor(255, 255, 255) or tocolor(230, 100, 100), 0.95, "default-bold", "center", "center")
                elseif k == "⌫" then
                    round("npk_" .. k, kx, ky, kw, kh, 6, isHover and tocolor(255, 204, 0, 50) or tocolor(28, 32, 40, 230))
                    dxDrawText(k, kx, ky, kx + kw, ky + kh, isHover and tocolor(255, 204, 0) or tocolor(200, 205, 215), 0.95, "default-bold", "center", "center")
                else
                    round("npk_" .. k, kx, ky, kw, kh, 6, isHover and tocolor(255, 204, 0, 40) or tocolor(26, 30, 38, 230))
                    dxDrawText(k, kx, ky, kx + kw, ky + kh, isHover and tocolor(255, 204, 0) or tocolor(240, 240, 245), 0.98, "default-bold", "center", "center")
                end
            end
        end

        -- Giriş Yap / PIN Kaydet Butonu
        local btnY = nStartY + 4 * (kh + kgap) + 4
        bankButton("loginSubmit", pinCardX + 20, btnY, pinCardW - 40, 42, isFirstTime and "PIN'İ KAYDET" or "GİRİŞ YAP", true)

        -- Hata Mesajı
        if loginError then
            dxDrawText(loginError, pinCardX + 10, btnY + 44, pinCardX + pinCardW - 10, btnY + 64, tocolor(245, 80, 80, 255), 0.78, "default-bold", "center", "center")
        end
    else
        -- ================= TAM DASHBOARD GÖRÜNÜMÜ =================
        -- Karşılama Başlığı
        dxDrawText("HOŞ GELDİNİZ, " .. string.upper(getPlayerName(localPlayer)), cx, bankY + 86, right, bankY + 110, tocolor(255, 204, 0, 255), 1.05, "default-bold", "left", "center")
        dxDrawText("Stage Bank Güvenli Hesap ve Bakiye Yönetim Paneli", cx, bankY + 110, right, bankY + 130, tocolor(150, 158, 170, 220), 0.76, "default", "left", "center")

        -- Bakiye ve Nakit Kartları
        local cardW = math.floor((cw - 16) / 2)
        local cardH = 76
        local cardY = bankY + 140

        -- Kart 1: Banka Bakiyesi (Sarı Vurgulu)
        round("card_balance", cx, cardY, cardW, cardH, 8, tocolor(21, 25, 32, 240))
        dxDrawRectangle(cx + 2, cardY, cardW - 4, 2, tocolor(255, 204, 0, 220))
        dxDrawText("BANKA BAKİYESİ", cx + 16, cardY + 10, cx + cardW - 16, cardY + 30, tocolor(255, 204, 0, 220), 0.74, "default-bold", "left", "center")
        dxDrawText(fmt(latest and latest.balance or 0), cx + 16, cardY + 32, cx + cardW - 16, cardY + 68, tocolor(255, 255, 255, 255), 1.35, "default-bold", "left", "center")

        -- Kart 2: Nakit Para (Yeşil Vurgulu)
        local c2x = cx + cardW + 16
        round("card_cash", c2x, cardY, cardW, cardH, 8, tocolor(21, 25, 32, 240))
        dxDrawRectangle(c2x + 2, cardY, cardW - 4, 2, tocolor(75, 195, 120, 180))
        dxDrawText("CÜZDANDAKİ NAKİT PARA", c2x + 16, cardY + 10, c2x + cardW - 16, cardY + 30, tocolor(150, 190, 160, 220), 0.74, "default-bold", "left", "center")
        dxDrawText(fmt(latest and latest.cash or 0), c2x + 16, cardY + 32, c2x + cardW - 16, cardY + 68, tocolor(245, 245, 245, 255), 1.35, "default-bold", "left", "center")

        -- Kartların Altındaki Dinamik Form / Tab Alanı
        local formY = cardY + cardH + 18

        if activeTab == "home" then
            dxDrawText("SON HESAP HAREKETLERİ", cx, formY, cx + 300, formY + 26, tocolor(240, 240, 240, 255), 0.92, "default-bold", "left", "center")

            local rows = latest and latest.history or {}
            if #rows > 0 then
                for i = 1, math.min(5, #rows) do
                    local row = rows[i]
                    local ry = formY + 32 + (i - 1) * 44
                    round("row" .. i, cx, ry, cw, 38, 6, tocolor(20, 24, 30, 200))
                    dxDrawRectangle(cx + 1, ry, cw - 2, 1, tocolor(255, 255, 255, 10))

                    dxDrawText(row.transaction_type or "İşlem", cx + 16, ry, cx + 180, ry + 38, tocolor(230, 235, 245), 0.82, "default-bold", "left", "center")
                    local isPositive = (row.transaction_type == "Yatirma" or row.transaction_type == "Transfer Alindi")
                    dxDrawText(fmt(row.amount), cx + 190, ry, cx + 330, ry + 38, isPositive and tocolor(75, 205, 120) or tocolor(255, 195, 60), 0.85, "default-bold", "left", "center")
                    
                    local noteText = (row.counterparty and row.counterparty ~= "") and row.counterparty or (row.note and row.note ~= "" and row.note or "-")
                    dxDrawText(noteText, cx + 340, ry, right - 16, ry + 38, tocolor(150, 158, 170), 0.78, "default", "right", "center")
                end
            else
                dxDrawText("Henüz bir hesap hareketiniz bulunmuyor.", cx, formY + 45, right, formY + 85, tocolor(130, 138, 150), 0.82, "default", "center", "center")
            end
        else
            local title = (activeTab == "deposit" and "HESABA PARA YATIR") or (activeTab == "withdraw" and "BANKADAN PARA ÇEK") or "BANKA TRANSFERİ"
            local sub = (activeTab == "deposit" and "Yatırmak istediğiniz tutarı ve 4-6 haneli banka PIN kodunuzu girin.") or
                        (activeTab == "withdraw" and "Çekmek istediğiniz nakit tutarını ve PIN kodunuzu girin.") or
                        "Başka bir oyuncuya bakiye göndermek için oyuncu adını, tutarı ve PIN kodunuzu girin."
            
            dxDrawText(title, cx, formY, right, formY + 28, tocolor(255, 204, 0, 255), 1.02, "default-bold", "left", "center")
            dxDrawText(sub, cx, formY + 28, right, formY + 50, tocolor(145, 155, 168), 0.78, "default", "left", "center")

            drawField(cx, formY + 70, 250, 42, "MİKTAR ($)", amount, false)
            drawField(cx + 270, formY + 70, 240, 42, "PIN KODU", pin, true)

            if activeTab == "transfer" then
                drawField(cx, formY + 146, 510, 42, "HEDEF OYUNCU ADI", target, false)
            end

            local btnY = formY + (activeTab == "transfer" and 218 or 146)
            local btnText = (activeTab == "deposit" and "Hesaba Yatır") or (activeTab == "withdraw" and "Para Çek") or "Transfer Gönder"
            bankButton("submit", cx, btnY, 250, 44, btnText, true)
        end
    end
end

local function submitTransaction()
    local amt = guiGetText(amount)
    local p = guiGetText(pin)
    local tgt = guiGetText(target)
    if not amt or amt == "" then
        outputChatBox("[Banka] Lütfen bir miktar giriniz.", 255, 180, 80)
        return
    end
    if not p or p == "" then
        outputChatBox("[Banka] Lütfen banka PIN kodunuzu giriniz.", 255, 180, 80)
        return
    end
    if activeTab == "transfer" and (not tgt or tgt == "") then
        outputChatBox("[Banka] Lütfen hedef oyuncu adını giriniz.", 255, 180, 80)
        return
    end
    triggerServerEvent("stage_bank:transaction", localPlayer, activeTab, amt, p, tgt)
end

local function submitLoginPin()
    local p = guiGetText(loginPinEdit)
    if not p or #p < 4 or #p > 6 then
        loginError = "PIN kodu 4-6 haneli olmalıdır!"
        return
    end
    loginError = nil
    if latest and not latest.hasPin then
        triggerServerEvent("stage_bank:setPin", localPlayer, p)
    else
        triggerServerEvent("stage_bank:verifyPin", localPlayer, p)
    end
end

addEventHandler("onClientClick", root, function(button, state, mx, my)
    if button ~= "left" or state ~= "up" or not bankVisible then return end

    local bankW = math.min(920, sw - 40)
    local bankH = math.min(580, sh - 40)
    local bankX = math.floor((sw - bankW) / 2)
    local bankY = math.floor((sh - bankH) / 2)
    local headerH = 70
    local sideW = 210

    -- 1. Üst Sağ Kapatma Butonu [X]
    local closeX, closeY, closeSize = bankX + bankW - 42, bankY + 18, 30
    if mx >= closeX and mx <= closeX + closeSize and my >= closeY and my <= closeY + closeSize then
        close()
        return
    end

    local menuStartX = bankX + 14
    local menuW = sideW - 28
    local menuStartY = bankY + 92
    local itemH = 40
    local itemGap = 8

    -- GİRİŞ YAPILMAMIŞ DURUM:
    if not authed then
        -- Sol Menüde Kapat Butonu (2. buton)
        local closeItemY = menuStartY + (2 - 1) * (itemH + itemGap)
        if mx >= menuStartX and mx <= menuStartX + menuW and my >= closeItemY and my <= closeItemY + itemH then
            close()
            return
        end

        -- PIN Kartı Alanları:
        local cx = bankX + sideW + 30
        local right = bankX + bankW - 30
        local cw = right - cx
        local pinCardW = 340
        local pinCardX = cx + math.floor((cw - pinCardW) / 2)
        local pinCardY = bankY + 145

        -- PIN Girdi Alanına Tıklama
        if mx >= pinCardX + 20 and mx <= pinCardX + pinCardW - 20 and my >= pinCardY + 30 and my <= pinCardY + 74 then
            focusEdit(loginPinEdit, pinCardX + 20, pinCardY + 30, pinCardW - 40, 44)
            return
        end

        -- Numpad Tuşlarına Tıklama
        local nStartX = pinCardX + 20
        local nStartY = pinCardY + 88
        local kw = 94
        local kh = 38
        local kgap = 9

        for r, row in ipairs(numpadKeys) do
            for c, k in ipairs(row) do
                local kx = nStartX + (c - 1) * (kw + kgap)
                local ky = nStartY + (r - 1) * (kh + kgap)
                if mx >= kx and mx <= kx + kw and my >= ky and my <= ky + kh then
                    local cur = guiGetText(loginPinEdit)
                    if k == "C" then
                        guiSetText(loginPinEdit, "")
                        loginError = nil
                    elseif k == "⌫" then
                        if #cur > 0 then
                            guiSetText(loginPinEdit, cur:sub(1, #cur - 1))
                        end
                    else
                        if #cur < 6 then
                            guiSetText(loginPinEdit, cur .. k)
                        end
                    end
                    return
                end
            end
        end

        -- Giriş Yap / Kaydet Butonu
        local btnY = nStartY + 4 * (kh + kgap) + 4
        if mx >= pinCardX + 20 and mx <= pinCardX + pinCardW - 20 and my >= btnY and my <= btnY + 42 then
            submitLoginPin()
            return
        end

        focusEdit(nil)
        return
    end

    -- GİRİŞ YAPILMIŞ DURUM:
    -- Sol Menü Tıklamaları (Ana Sayfa, Para Yatır, Para Çek, Transfer, Kapat)
    for i, item in ipairs(menuItems) do
        local itemY = menuStartY + (i - 1) * (itemH + itemGap)
        if mx >= menuStartX and mx <= menuStartX + menuW and my >= itemY and my <= itemY + itemH then
            if item.id == "close" then
                close()
                return
            else
                activeTab = item.id
                focusEdit(nil)
                return
            end
        end
    end

    -- Sağ İçerik Alanı Tıklamaları
    local cx = bankX + sideW + 30
    local right = bankX + bankW - 30
    local cardH = 76
    local cardY = bankY + 140
    local formY = cardY + cardH + 18

    if activeTab == "home" then
        focusEdit(nil)
        return
    end

    -- Yatırma / Çekme / Transfer Alanları:
    -- Miktar Alanı (cx, formY + 70, 250, 42)
    if mx >= cx and mx <= cx + 250 and my >= formY + 70 and my <= formY + 112 then
        focusEdit(amount, cx, formY + 70, 250, 42)
        return
    end

    -- PIN Alanı (cx + 270, formY + 70, 240, 42)
    if mx >= cx + 270 and mx <= cx + 510 and my >= formY + 70 and my <= formY + 112 then
        focusEdit(pin, cx + 270, formY + 70, 240, 42)
        return
    end

    -- Hedef Oyuncu Alanı (Transfer) (cx, formY + 146, 510, 42)
    if activeTab == "transfer" and mx >= cx and mx <= cx + 510 and my >= formY + 146 and my <= formY + 188 then
        focusEdit(target, cx, formY + 146, 510, 42)
        return
    end

    -- İşlem Onay Butonu
    local btnY = formY + (activeTab == "transfer" and 218 or 146)
    if mx >= cx and mx <= cx + 250 and my >= btnY and my <= btnY + 44 then
        submitTransaction()
        return
    end

    -- Boş bir alana tıklandıysa odağı kaldır
    focusEdit(nil)
end)

addEventHandler("onClientRender", root, drawBank)

addEvent("stage_bank:data", true)
addEventHandler("stage_bank:data", root, function(data)
    makePanel()
    latest = data
    guiSetText(loginPinEdit, "")
    loginError = nil
    bankVisible = true
    showCursor(true)

    local bankW = math.min(920, sw - 40)
    local bankH = math.min(580, sh - 40)
    local bankX = math.floor((sw - bankW) / 2)
    local bankY = math.floor((sh - bankH) / 2)
    local sideW = 210
    local cx = bankX + sideW + 30
    local right = bankX + bankW - 30
    local cw = right - cx
    local pinCardW = 340
    local pinCardX = cx + math.floor((cw - pinCardW) / 2)
    local pinCardY = bankY + 145

    if not authed then
        focusEdit(loginPinEdit, pinCardX + 20, pinCardY + 30, pinCardW - 40, 44)
    end
end)

addEvent("stage_bank:pinResult", true)
addEventHandler("stage_bank:pinResult", root, function(ok)
    if ok then
        authed = true
        activeTab = "home"
        loginError = nil
        guiSetText(pin, guiGetText(loginPinEdit))
        guiSetText(loginPinEdit, "")
        focusEdit(nil)
    else
        loginError = "Hatalı PIN kodu! Lütfen tekrar deneyiniz."
        guiSetText(loginPinEdit, "")
        outputChatBox("[Banka] PIN kodu hatalı.", 255, 80, 80)
    end
end)

bindKey("e", "down", function()
    if not bankVisible then
        triggerServerEvent("stage_bank:open", localPlayer)
    end
end)

bindKey("escape", "down", function()
    if bankVisible then
        close()
    end
end)

bindKey("enter", "down", function()
    if bankVisible and not authed then
        submitLoginPin()
    end
end)

bindKey("num_enter", "down", function()
    if bankVisible and not authed then
        submitLoginPin()
    end
end)

