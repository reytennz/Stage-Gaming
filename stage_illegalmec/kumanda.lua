local sx, sy = guiGetScreenSize()
local _cw, _ch = 1280, 720
local scaleX, scaleY = sx / _cw, sy / _ch
local _scale = math.min(scaleX, scaleY)
local _offX  = (sx - _cw * _scale) / 2
local _offY  = (sy - _ch * _scale) / 2
local rounded = {}
local circles  = {}

local remoteOpen = false
local vehiclePower = 60 -- Başlangıç gücü %60
local isAntilag = false
local isAirActive = false
local targetVehicle = nil
local isEngineUnlocked = false

-- Sürükleme için değişkenler
local isDraggingPower = false
local dragStartX = 0

-- KUMANDAYI AÇMA KOMUTU
addCommandHandler("kumanda", function()
    remoteOpen = not remoteOpen
    if remoteOpen then
        showCursor(true)
        guiSetInputEnabled(false) -- Chat (F8) açılsın diye false yaptık
        outputChatBox("[Kumanda] Araç kumandası açıldı.", 0, 255, 0)
        
        local px, py, pz = getElementPosition(localPlayer)
        local minDist = 9999
        targetVehicle = nil
        for _, veh in ipairs(getElementsByType("vehicle")) do
            local vx, vy, vz = getElementPosition(veh)
            local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
            if dist < minDist then
                minDist = dist
                targetVehicle = veh
            end
        end
    else
        showCursor(false)
        guiSetInputEnabled(false)
    end
end)

-- ESC (ÇIKIŞ) TUŞU İLE KUMANDAYI KAPATMA
addEventHandler("onClientKey", root, function(key, state)
    if remoteOpen and key == "escape" and state then
        remoteOpen = false
        showCursor(false)
        guiSetInputEnabled(false)
        outputChatBox("[Kumanda] Kapatıldı.", 255, 0, 0)
    end
end)

-- ARACA BİNİNCE MOTORUN AÇIK KALMASINI SAĞLAR
addEventHandler("onClientVehicleEnter", root, function(veh, seat)
    if seat == 0 and remoteOpen and veh == targetVehicle and isEngineUnlocked then
        setVehicleEngineState(veh, true)
    end
end)

-- ==========================================
-- YENİ MODERN KUMANDA TASARIMI
-- ==========================================
local uiElements = {
    -- 1. ARKA PLAN (Koyu Cam/Ekran)
    { id = "remote_bg", type = "rectangle", x = 520, y = 120, w = 240, h = 480, color = { 10, 12, 18, 240 }, radius = 25, visible = true, groupId = "base_ui" },
    { id = "remote_border", type = "rectangle", x = 525, y = 125, w = 230, h = 470, color = { 30, 35, 50, 100 }, radius = 22, visible = true, groupId = "base_ui" },
    
    -- 2. DAİRE (OPEN) - AÇ/KAPAT BUTONU
    { id = "remote_circle", type = "button", x = 590, y = 155, w = 100, h = 100, radius = 50, color = { 200, 200, 200, 255 }, hoverColor = { 220, 220, 220, 255 }, text = "Open", fontScale = 1.8, font = "default-bold", alignX = "center", alignY = "center", textColor = { 10, 10, 10, 255 }, visible = true, groupId = "base_ui" },

    -- ========================================================
    -- UZAK MENZİL ARAYÜZÜ (50+ METRE)
    -- ========================================================
    { id = "label_call", type = "label", x = 600, y = 280, w = 180, h = 40, text = "Aracı Çağır", fontScale = 1.6, font = "default-bold", alignX = "center", alignY = "center", textColor = { 180, 180, 190, 255 }, visible = true, groupId = "far_ui" },
    { id = "btn_lock_far", type = "button", x = 550, y = 370, w = 180, h = 50, text = "Motoru Kitle", fontScale = 1.2, font = "default-bold", alignX = "center", alignY = "center", radius = 12, color = { 230, 60, 40, 235 }, hoverColor = { 255, 80, 60, 245 }, textColor = { 255, 255, 255, 255 }, visible = true, groupId = "far_ui" },

    -- ========================================================
    -- YAKIN MENZİL ARAYÜZÜ (50 METRE ALTINDA)
    -- ========================================================
    -- OPEN butonu daire olduğu için buradakini kaldırdık.
    
    { id = "btn_air", type = "button", x = 550, y = 310, w = 180, h = 50, text = "Air", fontScale = 1.6, font = "default-bold", alignX = "center", alignY = "center", radius = 12, color = { 25, 128, 190, 255 }, hoverColor = { 50, 150, 210, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "near_ui" },
    
    -- ANTİLAG (Sol Alt)
    { id = "btn_antilag", type = "button", x = 540, y = 410, w = 90, h = 35, text = "Antilag", fontScale = 0.9, font = "default-bold", alignX = "center", alignY = "center", radius = 10, color = { 70, 70, 70, 255 }, hoverColor = { 25, 128, 190, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "near_ui" },
    
    -- GÜÇ BAR'I (Sağ Alt) - Sürüklenebilir
    { id = "power_bar", type = "progressbar", x = 645, y = 415, w = 95, h = 20, progress = 60, text = "60%", color = { 20, 25, 35, 220 }, progressColor = { 72, 199, 130, 255 }, textColor = { 255, 255, 255, 255 }, radius = 10, fontScale = 0.7, font = "default-bold", alignX = "center", alignY = "center", visible = false, groupId = "near_ui" },
}

-- (Yardımcı Çizim Fonksiyonları)
local function rgba(c) if type(c)~="table" then return tocolor(255,255,255,255) end return tocolor(c[1],c[2],c[3],c[4] or 255) end
local function hasColor(c) return type(c)=="table" and (c[4] or 255)>0 end

local function isCursorOnRect(x,y,w,h)
    if not isCursorShowing() then return false end
    local cx,cy=getCursorPosition(); if not cx then return false end
    cx,cy=cx*sx,cy*sy
    return cx>=x and cx<=x+w and cy>=y and cy<=y+h
end

local function _res() sx,sy=guiGetScreenSize(); scaleX,scaleY=sx/_cw,sy/_ch; _scale=math.min(scaleX,scaleY); _offX=(sx-_cw*_scale)/2; _offY=(sy-_ch*_scale)/2 end
addEventHandler("onClientResourceStart",resourceRoot,_res)

local function dxDrawRounded(id,x,y,w,h,radius,color,postGUI)
    id = tostring(id or 'generic')
    w=math.max(1,math.floor(w+0.5)); h=math.max(1,math.floor(h+0.5))
    radius=math.min(math.floor((radius or 0)+0.5), math.floor(math.min(w,h)/2))
    if radius<=0 then dxDrawRectangle(x,y,w,h,color,postGUI or false); return end
    rounded[id]=rounded[id] or {}; rounded[id][w]=rounded[id][w] or {}; rounded[id][w][h]=rounded[id][w][h] or {}
    if not rounded[id][w][h][radius] or not isElement(rounded[id][w][h][radius]) then
        local p=string.format('<svg width="%d" height="%d" viewBox="0 0 %d %d"><rect width="%d" height="%d" rx="%d" fill="#FFF"/></svg>',w,h,w,h,w,h,radius)
        rounded[id][w][h][radius]=svgCreate(w,h,p)
    end
    if rounded[id][w][h][radius] then dxDrawImage(x,y,w,h,rounded[id][w][h][radius],0,0,0,color,postGUI or false) end
end

local function dxDrawCircle(id,x,y,w,h,color,postGUI)
    id = tostring(id or 'generic')
    w=math.max(1,math.floor(w+0.5)); h=math.max(1,math.floor(h+0.5))
    local key=w..'_'..h
    circles[id]=circles[id] or {}
    if not circles[id][key] or not isElement(circles[id][key]) then
        local p=string.format('<svg width="%d" height="%d" viewBox="0 0 %d %d"><ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFF"/></svg>',w,h,w,h,w/2,h/2,w/2,h/2)
        circles[id][key]=svgCreate(w,h,p)
    end
    if circles[id][key] then dxDrawImage(x,y,w,h,circles[id][key],0,0,0,color,postGUI or false) end
end

local function drawStyledText(text,left,top,right,bottom,opts)
    local scale=(opts.fontScale or 1) * _scale
    local _bf={["default"]=true,["default-bold"]=true,["arial"]=true,["bankgothic"]=true,["clear"]=true,["danielbd"]=true,["pricedown"]=true,["sans"]=true,["unifont"]=true}
    local font=(opts.font and _bf[opts.font]) and opts.font or 'default-bold'
    if hasColor(opts.shadowColor) then
        local sx2=(opts.shadowOffsetX or 1)*scaleX; local sy2=(opts.shadowOffsetY or 1)*scaleY
        dxDrawText(text,left+sx2,top+sy2,right+sx2,bottom+sy2,rgba(opts.shadowColor),scale,font,opts.alignX or 'left',opts.alignY or 'center',opts.clip,opts.wordBreak,false,opts.colorCoded)
    end
    dxDrawText(text,left,top,right,bottom,rgba(opts.textColor or {255,255,255,255}),scale,font,opts.alignX or 'left',opts.alignY or 'center',opts.clip,opts.wordBreak,false,opts.colorCoded)
end

local function resolveAnchoredRect(el)
    local x = el.x or 0
    local y = el.y or 0
    local w = (el.relativeW and el.wPercent) and math.max(20, math.floor(_cw * (el.wPercent / 100) + 0.5)) or (el.w or 0)
    local h = (el.relativeH and el.hPercent) and math.max(20, math.floor(_ch * (el.hPercent / 100) + 0.5)) or (el.h or 0)
    if el.dockX == 'fill' then w = math.max(20, _cw - x - math.max(0, el.dockPaddingRight or 0)) elseif el.anchorX == 'center' then x = (_cw - w) / 2 + x elseif el.anchorX == 'right' then x = _cw - w - x end
    if el.dockY == 'fill' then h = math.max(20, _ch - y - math.max(0, el.dockPaddingBottom or 0)) elseif el.anchorY == 'center' then y = (_ch - h) / 2 + y elseif el.anchorY == 'bottom' then y = _ch - h - y end
    return x*_scale+_offX, y*_scale+_offY, w*_scale, h*_scale
end

local function drawUiElement(el)
    local x,y,w,h=resolveAnchoredRect(el)
    if el.type=="rectangle" then
        dxDrawRounded(el.id,x,y,w,h,(el.radius or 0)*_scale,rgba(el.color))
    elseif el.type=="button" then
        local r=(el.radius or 0)*_scale
        local fill=isCursorOnRect(x,y,w,h) and el.hoverColor or el.color
        dxDrawRounded(el.id,x,y,w,h,r,rgba(fill))
        drawStyledText(el.text,x+8*scaleX,y+4*scaleY,x+w-8*scaleX,y+h-4*scaleY,el)
    elseif el.type=="label" then
        drawStyledText(el.text,x,y,x+w,y+h,el)
    elseif el.type=="progressbar" then
        local r=(el.radius or 0)*_scale
        dxDrawRounded(el.id..'_bg',x,y,w,h,r,rgba(el.color))
        local fillW=w*((el.progress or 0)/100)
        dxDrawRounded(el.id..'_fill',x,y,fillW,h,r,rgba(el.progressColor or {72,199,130,255}))
        if el.text and el.text~='' then drawStyledText(el.text,x,y,x+w,y+h,el) end
    elseif el.type=="circle" then
        dxDrawCircle(el.id,x,y,w,h,rgba(el.color))
    end
end

-- ==========================================
-- MESAFE KONTROLÜ VE ARAYÜZ DEĞİŞİMİ
-- ==========================================
local function updateRemoteUI()
    if not remoteOpen then return end
    local px, py, pz = getElementPosition(localPlayer)
    local isClose = false
    if targetVehicle and isElement(targetVehicle) then
        local vx, vy, vz = getElementPosition(targetVehicle)
        local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
        if dist < 50 then isClose = true end
    end
    for _, v in ipairs(uiElements) do
        if v.groupId == "far_ui" then v.visible = not isClose end
        if v.groupId == "near_ui" then v.visible = isClose end
        
        -- Power Bar ve Antilag Renk Güncellemesi
        if v.id == "power_bar" then
            v.progress = vehiclePower
            v.text = vehiclePower .. "%"
        end
        if v.id == "btn_antilag" then
            v.color = isAntilag and {0, 220, 100, 255} or {80, 80, 80, 255} -- Açıkken Yeşil, Kapalıyken Gri
        end
        
        -- Open Butonu (Daire) Renk Güncellemesi
        if v.id == "remote_circle" then
            if isEngineUnlocked then
                v.color = {0, 200, 100, 255} -- Motor Açık (Yeşil)
                v.textColor = {255, 255, 255, 255}
            else
                v.color = {150, 150, 150, 255} -- Motor Kapalı (Gri)
                v.textColor = {10, 10, 10, 255}
            end
        end
    end
end
addEventHandler("onClientRender", root, updateRemoteUI)

-- ==========================================
-- SÜRÜKLEME (DRAG & DROP) SİSTEMİ
-- ==========================================
addEventHandler("onClientMouseMove", root, function(cx, cy)
    if not remoteOpen or not isDraggingPower then return end
    
    -- Bar'ın ekran koordinatlarını çözümle
    local barWidth = 95 * _scale
    local barX = (645 * _scale) + _offX
    
    -- Mouse X konumunu bar X konumuna göre yüzdeye çevir
    local dist = cx - barX
    local percent = math.floor((dist / barWidth) * 100)
    
    -- 0 ile 100 arasında sınırla
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end
    
    -- Gücü güncelle (sürüklerken anlık göster, sunucuya bırakınca gönder)
    if vehiclePower ~= percent then
        vehiclePower = percent
    end
end)

-- ==========================================
-- KUMANDA TIKLAMA SİSTEMİ (DRAG & OPEN/CLOSE)
-- ==========================================
addEventHandler('onClientClick', root, function(btn, state)
    if not remoteOpen then return end
    if btn~='left' then return end
    
    -- Tıklama Basıldığında (Down)
    if state == 'down' then
        for i=#uiElements,1,-1 do
            local el=uiElements[i]
            if el.visible~=false then
                local x,y,w,h=resolveAnchoredRect(el)
                if isCursorOnRect(x,y,w,h) then
                    
                    -- DRAG BAŞLAT: Eğer Power Bar'ına tıklandıysa
                    if el.id == "power_bar" then
                        isDraggingPower = true
                        return
                    end
                    
                    -- 1. UZAKTAN MOTOR KİTLEME
                    if el.id == "btn_lock_far" then
                        outputChatBox("[Kumanda] İzinsiz giriş! Motor kilitlendi.", 255, 80, 80)
                        triggerServerEvent("kumanda:lockEngine", localPlayer, targetVehicle)
                        isEngineUnlocked = false
                        remoteOpen = false
                        showCursor(false)
                        guiSetInputEnabled(false)
                        return
                    end
                    
                    -- 2. DAİREYE TIKLAMA (OPEN MOTOR AÇ/KAPA)
                    if el.id == "remote_circle" then
                        isEngineUnlocked = not isEngineUnlocked
                        if isEngineUnlocked then
                            triggerServerEvent("kumanda:startEngine", localPlayer, targetVehicle)
                        else
                            triggerServerEvent("kumanda:lockEngine", localPlayer, targetVehicle)
                        end
                        return
                    end

                    -- 3. AIR (SÜSPANSİYON YÜKSELT/ALÇALT)
                    if el.id == "btn_air" then
                        isAirActive = not isAirActive
                        triggerServerEvent("kumanda:airToggle", localPlayer, targetVehicle, isAirActive)
                        outputChatBox("[Kumanda] Air Sistemi: " .. (isAirActive and "Yükseltildi" or "Alçaltıldı"), 0, 255, 255)
                        return
                    end

                    -- 4. ANTİLAG (GÜÇ AÇ/KAPAT)
                    if el.id == "btn_antilag" then
                        isAntilag = not isAntilag
                        triggerServerEvent("kumanda:antilagToggle", localPlayer, targetVehicle, isAntilag)
                        return
                    end
                end
            end
        end
        
    -- Tıklama Bırakıldığında (Up) - Drag sonlandır ve veriyi gönder
    elseif state == 'up' then
        if isDraggingPower then
            isDraggingPower = false
            triggerServerEvent("kumanda:setPower", localPlayer, targetVehicle, vehiclePower)
            return
        end
    end
end)

local function renderCreatedUi()
    if not remoteOpen then return end
    for _,el in ipairs(uiElements) do if el.visible~=false then drawUiElement(el) end end
end
addEventHandler("onClientRender", root, renderCreatedUi)
-- ==========================================
-- SUNUCUDAN GELEN İSTEKLERİ İŞLEME EVENTLERİ
-- ==========================================

-- 1. AIR (Araç süspansiyonu)
addEvent("kumanda:clientAir", true)
addEventHandler("kumanda:clientAir", root, function(vehicle, state)
    if isElement(vehicle) then
        if state then
            setVehicleSuspensionHeight(vehicle, 0.15) 
        else
            setVehicleSuspensionHeight(vehicle, 0.0)
        end
    end
end)

-- 2. ANTİLAG (Araç hız limiti / Max Velocity)
addEvent("kumanda:clientAntilag", true)
addEventHandler("kumanda:clientAntilag", root, function(vehicle, state)
    if isElement(vehicle) then
        if state then
            setVehicleMaxVelocity(vehicle, 150) -- Antilag açık
        else
            setVehicleMaxVelocity(vehicle, 90)  -- Antilag kapalı
        end
    end
end)

-- 3. GÜÇ AYARI (Bar'dan gelen yüzde)
addEvent("kumanda:clientPower", true)
addEventHandler("kumanda:clientPower", root, function(vehicle, percentage)
    if isElement(vehicle) then
        local limit = 50 + (percentage * 0.5)
        setVehicleMaxVelocity(vehicle, limit)
    end
end)