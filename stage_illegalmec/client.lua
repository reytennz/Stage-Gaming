-- ==========================================
-- Stage TUNING — CLIENT.LUA v13
-- ==========================================

-- ==========================================
-- 1. AYARLAR & SABITLER
-- ==========================================
local bgW, bgH, rad, sideW = 900, 580, 12, 220
local sx, sy = guiGetScreenSize()

setFarClipDistance(400)
setFogDistance(380)

-- ==========================================
-- 2. ÜRÜN LİSTELERİ
-- ==========================================
local Kategoriler = {"Ana Sayfa","Yazılım","Blok","Turbo","Yakıt","Egzoz","Aktarma","Kozmetik"}
local Urunler = {
    ["Yazılım"]  = {{"Stage 1",15000,"Temel güç haritası.",""},{"Stage 2",35000,"Agresif avans ayarı.","Stage 1"},{"Stage 3",75000,"Limitör iptali.","Stage 2"}},
    ["Blok"]     = {{"Çelik Saplama",15000,"Blok direncini artırır.",""},{"Çelik Gömlek",40000,"Termal dayanıklılık.","Çelik Saplama,Stage"},{"Dövme Piston",85000,"Kırılmaz alt yapı.","Çelik Gömlek"}},
    ["Turbo"]    = {{"Gelişmiş Paller",12000,"Hızlı spool.",""},{"Hibrit Turbo",35000,"Orta seviye basınç.","Gelişmiş Paller,Stage"},{"Big Turbo",80000,"Maksimum PSI.","Hibrit Turbo"}},
    ["Yakıt"]    = {{"Yüksek Basınçlı Pompa",10000,"Kesintisiz yakıt.",""},{"550cc Enjektör",25000,"Daha fazla benzin.","Yüksek Basınçlı Pompa,Stage"},{"1000cc Enjektör",45000,"Zengin karışım.","550cc Enjektör"}},
    ["Egzoz"]    = {{"Spor Susturucu",5000,"Rahat tahliye.",""},{"Downpipe",15000,"Katalizör iptali.","Spor Susturucu,Stage"},{"Krom Düz Boru",25000,"Sıfır geri basınç.","Downpipe"}},
    ["Aktarma"]  = {{"Kısa Şanzıman",20000,"Seri vites geçişi.",""},{"Bronz Debriyaj",30000,"Tork kaçırmaz.","Kısa Şanzıman"},{"Kilitli Diferansiyel",45000,"Yanlama ve tutunma.","Bronz Debriyaj"},{"Drift Kiti",35000,"Tam drift modu.","Kısa Şanzıman"}},
    ["Kozmetik"] = {{"Karaduman",5000,"Zifiri siyah egzoz.","Stage 1"},{"Popcorn Kit",20000,"Alevli çat-pat.","Stage 2"},{"Air Süspansiyon",15000,"Yere basma kiti.",""}},
}

-- ==========================================
-- 3. STATE
-- ==========================================
local panel,aktifArac,panelAlpha,targetAlpha = false,nil,0,0
local seciliKat = "Ana Sayfa"
local isInstalling,installProgress,installItem,installPrice = false,0,"",0
local uyariMetni,uyariTimer = "",nil

-- Marker listesi — server'dan gelir
local markerListesi = {}

-- MyCar
local mycarPanel,mycarAlpha,mycarTarget = false,0,0
local motorMod = "normal"

-- Launch Control
local launchControl  = false
local launchReady    = false
local launchRPM      = 0
local launchAktifTimer = nil   -- 10sn otomatik kapanma
local launchCountdown  = 0     -- geri sayım göstergesi (saniye)

-- Air
local airAcik      = false
local airYukseklik = 0.0

-- Karaduman
local karadumanAcik = true

-- Ses
local egzozSesAcik     = true
local eskiVites        = 0
local sonPatlama,sonTurbo = 0,0

-- Duman
local dumanTex = dxCreateTexture("smoke.png")
local dumanlar = {}

-- DYNO TEST
local dynoListesi   = {}
local dynoFaz       = "idle"     -- "idle" | "hazirlik" | "test" | "sonuc"
local dynoArac      = nil
local dynoBaslangic = 0
local dynoSure      = 10000      -- test süresi (10sn)
local dynoHazirlikSure = 4000    -- hazırlık süresi (4sn)
local dynoRPM       = 0
local dynoSonuc     = nil
local dynoSonucAlpha,dynoSonucTarget = 0,0
local dynoPanelAlpha,dynoPanelTarget = 0,0
local dynoHazirlikAlpha,dynoHazirlikTarget = 0,0
local dynoSabitPos  = nil        -- aracı sabit tutmak için
local dynoMaxRPMUlasilan = 0     -- test boyunca ulaşılan tepe RPM (gerçekçilik için)

-- ==========================================
-- 4. MARKER SİSTEMİ — SERVER'DAN AL
-- ==========================================
addEvent("markerListesiGonder", true)
addEventHandler("markerListesiGonder", root, function(liste)
    -- Eski markerleri temizle
    for _,m in ipairs(markerListesi) do
        if m.marker and isElement(m.marker) then destroyElement(m.marker) end
        if m.blip   and isElement(m.blip)   then destroyElement(m.blip)   end
    end
    markerListesi = {}

    for _,veri in ipairs(liste) do
        local mk = createMarker(veri.x, veri.y, veri.z, "checkpoint", 1.2, 255, 170, 0, 120)
        local bl = createBlipAttachedTo(mk, 27)
        local entry = {marker=mk, blip=bl, x=veri.x, y=veri.y, z=veri.z}
        table.insert(markerListesi, entry)

        addEventHandler("onClientMarkerHit", mk, function(p, md)
            if p == localPlayer and md and isPedInVehicle(p) then
                aktifArac = getPedOccupiedVehicle(p)
                panel     = true
                showCursor(true)
            end
        end)
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        triggerServerEvent("markerListesiIste", localPlayer)
        triggerServerEvent("dynoListesiIste", localPlayer)
    end, 1000, 1)
end)

-- ==========================================
-- 4B. DYNO MARKER SİSTEMİ
-- ==========================================
addEvent("dynoListesiGonder", true)
addEventHandler("dynoListesiGonder", root, function(liste)
    for _,m in ipairs(dynoListesi) do
        if m.marker and isElement(m.marker) then destroyElement(m.marker) end
        if m.blip   and isElement(m.blip)   then destroyElement(m.blip)   end
    end
    dynoListesi = {}

    for _,veri in ipairs(liste) do
        local mk = createMarker(veri.x, veri.y, veri.z, "checkpoint", 1.2, 60, 140, 255, 130)
        local bl = createBlipAttachedTo(mk, 0, 2, 0, 100, 200, 255)
        local entry = {marker=mk, blip=bl, x=veri.x, y=veri.y, z=veri.z}
        table.insert(dynoListesi, entry)

        addEventHandler("onClientMarkerHit", mk, function(p, md)
            if p == localPlayer and md and isPedInVehicle(p) and dynoFaz=="idle" then
                dynoHazirlikBaslat(getPedOccupiedVehicle(p))
            end
        end)
    end
end)

-- Dyno sonucu server'dan geldi
addEvent("dynoSonucGonder", true)
addEventHandler("dynoSonucGonder", root, function(veri)
    dynoSonuc = veri
    dynoFaz   = "sonuc"
    showCursor(true)
end)

-- FAZ 1: Markere girince hazırlık başlar (4sn)
function dynoHazirlikBaslat(vh)
    if not vh or not isElement(vh) then return end
    dynoFaz       = "hazirlik"
    dynoArac      = vh
    dynoBaslangic = getTickCount()
    dynoRPM       = 0
    dynoMaxRPMUlasilan = 0
    dynoSonuc     = nil
    local x,y,z    = getElementPosition(vh)
    local rx,ry,rz = getElementRotation(vh)
    dynoSabitPos   = {x=x,y=y,z=z,rx=rx,ry=ry,rz=rz}
    playSoundFrontEnd(1)
    outputChatBox("[Dyno] Araç hazırlanıyor...",60,140,255)

    setTimer(function()
        if dynoFaz=="hazirlik" and dynoArac==vh and isElement(vh) then
            dynoTestBaslat(vh)
        end
    end, dynoHazirlikSure, 1)
end

-- FAZ 2: Gerçek test başlar (10sn, RPM ölçülür)
function dynoTestBaslat(vh)
    if not vh or not isElement(vh) then return end
    dynoFaz       = "test"
    dynoBaslangic = getTickCount()
    dynoRPM       = 0
    playSoundFrontEnd(1)
    outputChatBox("[Dyno] Test başladı — GAZA BAS!",60,140,255)
end

-- ==========================================
-- 5. YARDIMCI FONKSİYONLAR
-- ==========================================
function rrect(x,y,w,h,r,c)
    dxDrawRectangle(x,y+r,w,h-r*2,c) dxDrawRectangle(x+r,y,w-r*2,r,c) dxDrawRectangle(x+r,y+h-r,w-r*2,r,c)
    dxDrawCircle(x+r,y+r,r,180,270,c,c,16,1) dxDrawCircle(x+w-r,y+r,r,270,360,c,c,16,1)
    dxDrawCircle(x+r,y+h-r,r,90,180,c,c,16,1) dxDrawCircle(x+w-r,y+h-r,r,0,90,c,c,16,1)
end
-- alias eski isimle de çalışsın
function dxDrawRoundedRect(x,y,w,h,r,c) rrect(x,y,w,h,r,c) end

function isHover(x,y,w,h)
    if not isCursorShowing() then return false end
    local cx,cy=getCursorPosition() return cx*sx>=x and cx*sx<=x+w and cy*sy>=y and cy*sy<=y+h
end

function showUyari(t)
    uyariMetni=t
    if uyariTimer and isTimer(uyariTimer) then killTimer(uyariTimer) end
    uyariTimer=setTimer(function() uyariMetni="" end,3000,1)
    playSoundFrontEnd(4)
end

function checkSahip(n)
    local l=getElementData(aktifArac,"takili_parcalar") or {}
    for _,p in ipairs(l) do if p==n then return true end end return false
end

function checkKilit(req)
    if req=="" then return true,"" end
    local l=getElementData(aktifArac,"takili_parcalar") or {}
    local vs=false for _,p in ipairs(l) do if p:find("Stage") then vs=true break end end
    for _,r in ipairs(split(req,",")) do
        if r=="Stage" then if not vs then return false,"Herhangi bir Yazılım Atılmalı!" end
        else
            local f=false
            for _,p in ipairs(l) do if p==r then f=true break end end
            if r=="Stage 1" and vs then f=true end
            if r=="Stage 2" then for _,p in ipairs(l) do if p=="Stage 2" or p=="Stage 3" then f=true break end end end
            if not f then return false,"["..r:upper().."] Gerekli!" end
        end
    end
    return true,""
end

-- Toggle switch çizici
function drawSwitch(x,y,aktif,al)
    local w,h = 52,26
    local bg = aktif and tocolor(80,200,120,al) or tocolor(50,50,65,al)
    rrect(x,y,w,h,h/2,bg)
    local kx = aktif and (x+w-h+2) or (x+2)
    dxDrawCircle(kx+h/2-2, y+h/2, h/2-3, 0, 360, tocolor(255,255,255,al), tocolor(255,255,255,al), 20, 1)
end

-- Motor mod uygula
function motorModUygula(vh)
    if not vh or not isElement(vh) then return end
    local o=getOriginalHandling(getElementModel(vh)) if not o then return end
    if     motorMod=="eco"   then setVehicleHandling(vh,"maxVelocity",o.maxVelocity*0.85) setVehicleHandling(vh,"engineAcceleration",o.engineAcceleration*0.80)
    elseif motorMod=="sport" then setVehicleHandling(vh,"maxVelocity",o.maxVelocity*1.15) setVehicleHandling(vh,"engineAcceleration",o.engineAcceleration*1.25)
    else                          setVehicleHandling(vh,"maxVelocity",o.maxVelocity)       setVehicleHandling(vh,"engineAcceleration",o.engineAcceleration) end
    triggerServerEvent("araciGuncelleIstek",localPlayer)
end

-- Launch Control başlat (10sn timer)
function launchControlAc(vh)
    if launchAktifTimer and isTimer(launchAktifTimer) then killTimer(launchAktifTimer) end
    launchControl = true
    launchReady   = false
    launchRPM     = 0
    launchCountdown = 10
    -- Her saniye geri say
    launchAktifTimer = setTimer(function()
        launchCountdown = launchCountdown - 1
        if launchCountdown <= 0 then
            launchControl = false
            launchReady   = false
            launchRPM     = 0
            if launchAktifTimer and isTimer(launchAktifTimer) then killTimer(launchAktifTimer) end
        end
    end, 1000, 10)
end

-- ==========================================
-- 6. RENDER
-- ==========================================
addEventHandler("onClientRender", root, function()

    -- HOLOGRAM MARKERLAR
    for _,m in ipairs(markerListesi) do
        if m.marker and isElement(m.marker) then
            local cx,cy,cz=getCameraMatrix()
            local dist=getDistanceBetweenPoints3D(cx,cy,cz,m.x,m.y,m.z)
            if dist<40 then
                local t   = getTickCount()
                local bob = math.sin(t/500)*0.12          -- yukarı-aşağı sallanma
                local rot = (t/18)%360                    -- dış halka dönüşü
                local rot2= (360-(t/12)%360)              -- iç halka ters dönüş
                local pulse = 0.7+math.abs(math.sin(t/700))*0.3  -- parlaklık nabzı
                local aAl = math.floor(200*pulse)
                local dimAl= math.floor(100*pulse)

                -- Mesafeye göre alfa azalt
                local distFade = math.max(0, 1-(dist-20)/20)
                aAl  = math.floor(aAl  * distFade)
                dimAl= math.floor(dimAl* distFade)

                -- 1. ZEMIN: küçük dolgu dairesi (sarı, yarı saydam)
                dxDrawCircle(m.x, m.y, m.z, 1.2, 0, 360, tocolor(255,170,0,dimAl), tocolor(255,170,0,0), 32, 1)

                -- 2. DIŞ HALKA: kesik kesik dönen 8 parça
                for i=0,7 do
                    local a1=math.rad(i*45+rot)
                    local a2=math.rad(i*45+32+rot)
                    local r=1.6
                    dxDrawLine3D(
                        m.x+math.cos(a1)*r, m.y+math.sin(a1)*r, m.z+0.02,
                        m.x+math.cos(a2)*r, m.y+math.sin(a2)*r, m.z+0.02,
                        tocolor(255,170,0,aAl), 3)
                end

                -- 3. İÇ HALKA: ters dönen 4 parça, ince
                for i=0,3 do
                    local a1=math.rad(i*90+rot2)
                    local a2=math.rad(i*90+60+rot2)
                    local r=0.9
                    dxDrawLine3D(
                        m.x+math.cos(a1)*r, m.y+math.sin(a1)*r, m.z+0.02,
                        m.x+math.cos(a2)*r, m.y+math.sin(a2)*r, m.z+0.02,
                        tocolor(255,220,80,dimAl), 2)
                end

                -- 4. DİKEY IŞIN: zeminden yukarı 4 ince çizgi
                local beamH = 1.8 + bob
                for i=0,3 do
                    local a=math.rad(i*90+rot*0.3)
                    local r=0.18
                    dxDrawLine3D(
                        m.x+math.cos(a)*r, m.y+math.sin(a)*r, m.z,
                        m.x+math.cos(a)*r, m.y+math.sin(a)*r, m.z+beamH,
                        tocolor(255,200,60,math.floor(80*pulse*distFade)), 1)
                end

                -- 5. EKRAN ETİKETİ
                local scrX,scrY=getScreenFromWorldPosition(m.x,m.y,m.z+beamH+0.3+bob)
                if scrX and scrY then
                    local fAl=math.floor(255*pulse*distFade)
                    -- Gölge
                    dxDrawText("Stage TUNING",scrX+1,scrY+1,scrX+1,scrY+1,tocolor(0,0,0,fAl),0.95,"default-bold","center","center")
                    -- Ana yazı sarı
                    dxDrawText("Stage TUNING",scrX,scrY,scrX,scrY,tocolor(255,170,0,fAl),0.95,"default-bold","center","center")
                    -- Alt yazı
                    dxDrawText("Araçla alana gir",scrX,scrY+20,scrX,scrY+20,tocolor(200,200,200,math.floor(fAl*0.7)),0.75,"default","center","center")
                end
            end
        end
    end

    -- DYNO HOLOGRAM (mavi versiyon)
    for _,m in ipairs(dynoListesi) do
        if m.marker and isElement(m.marker) then
            local cx,cy,cz=getCameraMatrix()
            local dist=getDistanceBetweenPoints3D(cx,cy,cz,m.x,m.y,m.z)
            if dist<40 then
                local t=getTickCount()
                local bob=math.sin(t/500)*0.12
                local rot=(t/18)%360
                local rot2=(360-(t/12)%360)
                local pulse=0.7+math.abs(math.sin(t/700))*0.3
                local aAl=math.floor(200*pulse)
                local dimAl=math.floor(100*pulse)
                local distFade=math.max(0,1-(dist-20)/20)
                aAl=math.floor(aAl*distFade) dimAl=math.floor(dimAl*distFade)

                dxDrawCircle(m.x,m.y,m.z,1.2,0,360,tocolor(60,140,255,dimAl),tocolor(60,140,255,0),32,1)
                for i=0,7 do
                    local a1,a2=math.rad(i*45+rot),math.rad(i*45+32+rot)
                    dxDrawLine3D(m.x+math.cos(a1)*1.6,m.y+math.sin(a1)*1.6,m.z+0.02,m.x+math.cos(a2)*1.6,m.y+math.sin(a2)*1.6,m.z+0.02,tocolor(60,140,255,aAl),3)
                end
                for i=0,3 do
                    local a1,a2=math.rad(i*90+rot2),math.rad(i*90+60+rot2)
                    dxDrawLine3D(m.x+math.cos(a1)*0.9,m.y+math.sin(a1)*0.9,m.z+0.02,m.x+math.cos(a2)*0.9,m.y+math.sin(a2)*0.9,m.z+0.02,tocolor(120,180,255,dimAl),2)
                end
                local beamH=1.8+bob
                for i=0,3 do
                    local a=math.rad(i*90+rot*0.3)
                    dxDrawLine3D(m.x+math.cos(a)*0.18,m.y+math.sin(a)*0.18,m.z,m.x+math.cos(a)*0.18,m.y+math.sin(a)*0.18,m.z+beamH,tocolor(100,170,255,math.floor(80*pulse*distFade)),1)
                end
                local scrX,scrY=getScreenFromWorldPosition(m.x,m.y,m.z+beamH+0.3+bob)
                if scrX and scrY then
                    local fAl=math.floor(255*pulse*distFade)
                    dxDrawText("DYNO TEST",scrX+1,scrY+1,scrX+1,scrY+1,tocolor(0,0,0,fAl),0.95,"default-bold","center","center")
                    dxDrawText("DYNO TEST",scrX,scrY,scrX,scrY,tocolor(60,140,255,fAl),0.95,"default-bold","center","center")
                    dxDrawText("Araçla alana gir",scrX,scrY+20,scrX,scrY+20,tocolor(200,200,200,math.floor(fAl*0.7)),0.75,"default","center","center")
                end
            end
        end
    end

    -- DYNO HAZIRLIK / TEST FAZLARI — aracı sabit tut
    if (dynoFaz=="hazirlik" or dynoFaz=="test") and dynoArac and isElement(dynoArac) then
        -- Oyuncu araçtan çıktıysa iptal et
        if getPedOccupiedVehicle(localPlayer) ~= dynoArac then
            dynoFaz  = "idle"
            dynoArac = nil
            outputChatBox("[Dyno] Test iptal edildi — araçtan ayrıldınız.",255,80,80)
        else
            local gecen = getTickCount()-dynoBaslangic
            -- Aracı sabit pozisyonda kilitle
            setElementPosition(dynoArac, dynoSabitPos.x, dynoSabitPos.y, dynoSabitPos.z)
            setElementRotation(dynoArac, dynoSabitPos.rx, dynoSabitPos.ry, dynoSabitPos.rz)
            setElementVelocity(dynoArac, 0,0,0)
            setElementAngularVelocity(dynoArac, 0,0,0)

            if dynoFaz=="test" then
                -- Gaza basılıyorsa RPM yükselt (gerçekçi ivme eğrisi)
                if getPedControlState("accelerate") then
                    dynoRPM = math.min(100, dynoRPM + 1.4)
                else
                    dynoRPM = math.max(0, dynoRPM - 2.5)
                end
                if dynoRPM > dynoMaxRPMUlasilan then dynoMaxRPMUlasilan = dynoRPM end

                -- Egzoz duman efekti
                if dynoRPM > 30 and gecen % 100 < 20 then
                    local mat=getElementMatrix(dynoArac)
                    local ex=-2.5*mat[2][1]+mat[4][1]
                    local ey=-2.5*mat[2][2]+mat[4][2]
                    local ez=-2.5*mat[2][3]+mat[4][3]
                    for i=1,2 do
                        local sX,sY=(math.random()-0.5)*0.06,(math.random()-0.5)*0.06
                        table.insert(dumanlar,{pos={ex+sX,ey+sY,ez},vel={sX,sY,0.015},size=0.4,alpha=200,scale=0.02})
                    end
                end

                if gecen >= dynoSure then
                    dynoFaz = "idle"
                    triggerServerEvent("dynoTestIste", localPlayer, dynoMaxRPMUlasilan)
                    dynoArac = nil
                end
            end
        end
    end

    -- DYNO HAZIRLIK OVERLAY (4sn geri sayım)
    if dynoFaz=="hazirlik" then dynoHazirlikTarget=1 else dynoHazirlikTarget=0 end
    dynoHazirlikAlpha = dynoHazirlikAlpha + (dynoHazirlikTarget-dynoHazirlikAlpha)*0.15
    if dynoHazirlikAlpha>0.01 then drawDynoHazirlik(dynoHazirlikAlpha) end

    -- DYNO TEST HUD
    if dynoFaz=="test" then drawDynoHUD() end

    -- DYNO SONUÇ PANELİ
    if dynoFaz=="sonuc" then dynoPanelTarget=1 else dynoPanelTarget=0 end
    dynoPanelAlpha = dynoPanelAlpha + (dynoPanelTarget-dynoPanelAlpha)*0.1
    if dynoPanelAlpha>0.01 and dynoSonuc then drawDynoSonuc(dynoPanelAlpha) end

    -- SES & DUMAN & LAUNCH & AIR
    local vh=getPedOccupiedVehicle(localPlayer)
    if vh and getVehicleController(vh)==localPlayer then
        local pL=getElementData(vh,"takili_parcalar") or {}
        local vTurbo,vPop,vDuman,hasAir=false,false,false,false
        for _,p in ipairs(pL) do
            if p:find("Turbo")    then vTurbo=true end
            if p=="Popcorn Kit"   then vPop=true   end
            if p=="Karaduman" and karadumanAcik then vDuman=true end
            if p=="Air Süspansiyon" then hasAir=true end
        end

        local vX2,vY2,vZ2=getElementVelocity(vh)
        local hiz=math.sqrt(vX2*vX2+vY2*vY2+vZ2*vZ2)*180
        local vites=getVehicleCurrentGear(vh)
        local mat=getElementMatrix(vh)
        local ex=-2.5*mat[2][1]-0.5*mat[3][1]+mat[4][1]
        local ey=-2.5*mat[2][2]-0.5*mat[3][2]+mat[4][2]
        local ez=-2.5*mat[2][3]-0.5*mat[3][3]+mat[4][3]

        -- Turbo sesi
        if egzozSesAcik and vTurbo and vites>eskiVites and vites>1 then
            local t=getTickCount()
            if t-sonTurbo>800 then
                local s=playSound3D("sounds/turbo.wav",mat[4][1],mat[4][2],mat[4][3])
                if s then setSoundMaxDistance(s,30) end
                sonTurbo=t
            end
        end
        eskiVites=vites

        -- Pop sesi
        if egzozSesAcik and vPop and not getPedControlState("accelerate") and hiz>25 then
            local t=getTickCount()
            if t-sonPatlama>200 then
                local s=playSound3D("sounds/pop.wav",ex,ey,ez)
                if s then setSoundMaxDistance(s,40) end
                local ynX,ynY,ynZ=-mat[2][1],-mat[2][2],-mat[2][3]
                fxAddSparks(ex,ey,ez,ynX*0.5,ynY*0.5,ynZ*0.5+0.1,1.5,8,0,false,0.4,0.8)
                fxAddSparks(ex,ey,ez,ynX*0.3,ynY*0.3,ynZ*0.3+0.15,1.2,5,0,false,0.2,0.5)
                fxAddBulletSplash(ex,ey,ez)
                setTimer(function() if isElement(vh) then fxAddSparks(ex,ey,ez,ynX*0.2,ynY*0.2,ynZ*0.2,0.8,4,0,false,0.3,0.6) end end,60,1)
                sonPatlama=t
            end
        end

        -- Karaduman
        if vDuman and getPedControlState("accelerate") and hiz>5 then
            for i=1,6 do
                local sX,sY,sZ=(math.random()-0.5)*0.08,(math.random()-0.5)*0.08,(math.random()-0.5)*0.04
                table.insert(dumanlar,{pos={ex+sX,ey+sY,ez+sZ},vel={vX2*0.2+sX,vY2*0.2+sY,vZ2*0.2+sZ},size=math.random(4,9)/10,alpha=255,scale=math.random(10,18)/100})
            end
        end

        -- Launch Control logic
        if launchControl and hasAir then
            local gaz =getPedControlState("accelerate")
            local fren=getPedControlState("brake_reverse")
            if fren and gaz then
                launchReady=true
                launchRPM=math.min(launchRPM+2,100)
                setElementVelocity(vh,0,0,0)
                for i=1,3 do
                    local sX,sY=(math.random()-0.5)*0.12,(math.random()-0.5)*0.12
                    table.insert(dumanlar,{pos={ex+sX,ey+sY,ez},vel={0,0,0.02},size=0.3,alpha=180,scale=0.025})
                end
            elseif launchReady and gaz and not fren then
                launchReady=false
                -- MAX 100 km/h = ~27.8 m/s → MTA velocity birimi ~0.0154 per km/h
                local maxVel = 100 * 0.01543   -- ~1.543 MTA birimi
                local guc = (launchRPM/100) * maxVel
                local fwX,fwY = mat[2][1]*guc, mat[2][2]*guc
                setElementVelocity(vh,fwX,fwY,0.03)
                for i=1,16 do
                    local sX,sY=(math.random()-0.5)*0.2,(math.random()-0.5)*0.2
                    table.insert(dumanlar,{pos={ex+sX,ey+sY,ez},vel={-fwX*0.08+sX,-fwY*0.08+sY,0.04},size=0.5,alpha=240,scale=0.035})
                end
                launchRPM=0
                -- Timer'ı durdur (fırlatma bitti)
                if launchAktifTimer and isTimer(launchAktifTimer) then killTimer(launchAktifTimer) end
                launchControl=false
            elseif not gaz then
                launchReady=false
                launchRPM=math.max(0,launchRPM-3)
            end
        end

        -- Air Süspansiyon WASD/Shift/Ctrl
        if airAcik and hasAir then
            local rx,ry=0,0
            if getKeyState("arrow_u") then ry=-0.015 end
            if getKeyState("arrow_d") then ry= 0.015 end
            if getKeyState("arrow_l") then rx=-0.015 end
            if getKeyState("arrow_r") then rx= 0.015 end
            if getKeyState("lctrl")   then airYukseklik=math.max(-1.0,airYukseklik-0.01) end
            if getKeyState("lshift")  then airYukseklik=math.min(1.0,airYukseklik+0.01)  end
            local base=-0.20+airYukseklik*0.18
            setVehicleHandling(vh,"suspensionLowerLimit",base)
            setVehicleHandling(vh,"suspensionUpperLimit",base+0.30)
            if rx~=0 or ry~=0 then
                local cr,cp,cy2=getVehicleRotation(vh)
                setVehicleRotation(vh,cr+ry*57,cp+rx*57,cy2)
            end
        end
    end

    -- Duman render
    for i=#dumanlar,1,-1 do
        local d=dumanlar[i]
        d.pos[1]=d.pos[1]+d.vel[1] d.pos[2]=d.pos[2]+d.vel[2] d.pos[3]=d.pos[3]+d.vel[3]
        d.size=d.size+d.scale d.alpha=d.alpha-2.5
        if d.alpha<=0 then table.remove(dumanlar,i)
        elseif dumanTex then dxDrawMaterialLine3D(d.pos[1],d.pos[2],d.pos[3],d.pos[1],d.pos[2],d.pos[3]+d.size,dumanTex,d.size,tocolor(10,10,10,d.alpha)) end
    end

    -- TUNING PANELİ
    if panel then targetAlpha=1 else targetAlpha=0 end
    panelAlpha=panelAlpha+(targetAlpha-panelAlpha)*0.1
    if panelAlpha>0.01 then drawTuningPanel(panelAlpha) end

    -- MYCAR PANELİ
    if mycarPanel then mycarTarget=1 else mycarTarget=0 end
    mycarAlpha=mycarAlpha+(mycarTarget-mycarAlpha)*0.1
    if mycarAlpha>0.01 then drawMycarPanel(mycarAlpha) end

    -- LAUNCH CONTROL HUD
    if launchControl then drawLaunchHUD() end

    -- AIR HUD
    if airAcik then drawAirHUD() end
end)

-- ==========================================
-- 7. TUNING PANELİ
-- ==========================================
function drawTuningPanel(alpha)
    local al=math.floor(255*alpha)
    local bgX,bgY=(sx-bgW)/2,(sy-bgH)/2
    rrect(bgX,bgY,bgW,bgH,rad,tocolor(10,10,10,math.floor(252*alpha)))
    rrect(bgX,bgY,sideW,bgH,rad,tocolor(16,16,16,al))
    dxDrawText("⚙",bgX+25,bgY+25,bgX+25,bgY+25,tocolor(255,170,0,al),1.8,"default-bold")
    dxDrawText("Stage TUNING",bgX+65,bgY+32,bgX+65,bgY+32,tocolor(255,255,255,al),1.1,"default-bold")
    for i,kat in ipairs(Kategoriler) do
        local kY=bgY+90+(i-1)*55
        local h=isHover(bgX+15,kY,sideW-30,42) and not isInstalling
        local c=(seciliKat==kat) and tocolor(255,255,255,al) or (h and tocolor(200,200,200,al) or tocolor(80,80,80,al))
        if seciliKat==kat then rrect(bgX+15,kY,sideW-30,42,8,tocolor(32,32,32,al)) dxDrawRectangle(bgX+15,kY+10,3,22,tocolor(255,170,0,al)) end
        dxDrawText(kat,bgX+45,kY,bgX+sideW,kY+42,c,1.0,"default-bold","left","center")
    end
    local xOff,pW=bgX+sideW+35,bgW-sideW-70
    dxDrawText("✕",bgX+bgW-40,bgY+25,bgX+bgW-40,bgY+25,isHover(bgX+bgW-45,bgY+25,20,20) and not isInstalling and tocolor(255,50,50,al) or tocolor(150,150,150,al),1.2,"default-bold")
    if uyariMetni~="" then dxDrawText(uyariMetni,xOff,bgY+10,xOff,bgY+10,tocolor(255,50,50,al),1.0,"default-bold") end
    if isInstalling then
        rrect(xOff,bgY+200,pW,80,10,tocolor(20,20,20,al))
        dxDrawText("🛠️ "..installItem.." Kuruluyor...",xOff+20,bgY+215,xOff+20,bgY+215,tocolor(200,200,200,al),1.2,"default-bold")
        dxDrawRectangle(xOff+20,bgY+250,pW-40,15,tocolor(40,40,40,al))
        dxDrawRectangle(xOff+20,bgY+250,(pW-40)*(installProgress/100),15,tocolor(255,170,0,al))
        installProgress=installProgress+1.2
        if installProgress>=100 then isInstalling=false triggerServerEvent("yazilimSatinAl",localPlayer,installItem,installPrice) end
        return
    end
    if seciliKat=="Ana Sayfa" then
        dxDrawText("ARAÇ TEKNİK VERİLERİ",xOff,bgY+35,xOff,bgY+35,tocolor(255,170,0,al),1.1,"default-bold")
        local tP=getElementData(aktifArac,"takili_parcalar") or {}
        local data={{"PLAKA",getVehiclePlateText(aktifArac) or "?"},{"MOTOR SAĞLIĞI","%"..math.floor(getElementHealth(aktifArac)/10)},{"TAKILI PARÇA",#tP.." Adet"},{"BLOK DURUMU",getElementData(aktifArac,"motor_block")=="forged" and "#00FF00FORGED" or "#FF5500STANDART"},{"MOTOR MOD",motorMod:upper()}}
        for i,v in ipairs(data) do
            local kY=bgY+80+(i-1)*82
            rrect(xOff,kY,pW,72,12,tocolor(25,25,25,al))
            dxDrawText(v[1],xOff+20,kY+12,xOff+20,kY+12,tocolor(120,120,120,al),0.8,"default-bold")
            dxDrawText(v[2],xOff+20,kY+32,xOff+20,kY+32,tocolor(255,255,255,al),1.2,"default-bold","left","top",false,false,false,true)
        end
    else
        dxDrawText(seciliKat:upper().." KURULUMU",xOff,bgY+35,xOff,bgY+35,tocolor(150,150,150,al),1.0,"default-bold")
        for i,p in ipairs(Urunler[seciliKat] or {}) do
            local pY=bgY+80+(i-1)*75
            local h=isHover(xOff,pY,pW,65)
            local sahip=checkSahip(p[1])
            local ok,neden=checkKilit(p[4])
            rrect(xOff,pY,pW,65,10,(not ok) and tocolor(20,10,10,al) or (h and tocolor(40,40,40,al) or tocolor(28,28,28,al)))
            if sahip then
                dxDrawText("✓ "..p[1],xOff+20,pY+22,xOff+20,pY+22,tocolor(0,255,0,al),1.1,"default-bold")
                dxDrawText("TAKILI",xOff+pW-25,pY,xOff+pW-25,pY+65,tocolor(0,255,0,al),1.1,"default-bold","right","center")
            elseif not ok then
                dxDrawText("🔒 "..p[1],xOff+20,pY+15,xOff+20,pY+15,tocolor(150,50,50,al),1.1,"default-bold")
                dxDrawText("Kilit: "..neden,xOff+20,pY+38,xOff+20,pY+38,tocolor(255,100,100,al),0.9,"default-bold")
            else
                dxDrawText(p[1],xOff+20,pY+15,xOff+20,pY+15,tocolor(255,255,255,al),1.1,"default-bold")
                dxDrawText(p[3],xOff+20,pY+38,xOff+20,pY+38,tocolor(130,130,130,al),0.9,"default")
                dxDrawText("$"..p[2],xOff+pW-25,pY,xOff+pW-25,pY+65,tocolor(255,255,255,al),1.1,"default-bold","right","center")
            end
        end
    end
end

-- ==========================================
-- 8. MYCAR PANELİ — Modern kart layout
-- ==========================================
function drawMycarPanel(alpha)
    local al  = math.floor(255*alpha)
    local mW  = 560
    local mH  = 390
    local mX2 = (sx-mW)/2
    local mY2 = (sy-mH)/2

    -- Ana arka plan
    rrect(mX2,mY2,mW,mH,16,tocolor(12,12,18,al))
    -- Üst başlık şeridi
    rrect(mX2,mY2,mW,52,16,tocolor(22,22,34,al))
    dxDrawRectangle(mX2,mY2+36,mW,16,tocolor(22,22,34,al))  -- alt köşe düzeltme
    -- Başlık aksanı çizgisi
    dxDrawRectangle(mX2+16,mY2+48,mW-32,2,tocolor(255,170,0,math.floor(120*alpha)))

    dxDrawText("ARAÇ KONTROLPANELİ",mX2+20,mY2+16,mX2+mW-50,mY2+16,tocolor(255,255,255,al),1.0,"default-bold")
    dxDrawText("MyCar",mX2+20,mY2+16,mX2+mW-50,mY2+16,tocolor(255,170,0,al),1.0,"default-bold")
    dxDrawText("✕",mX2+mW-36,mY2+14,mX2+mW-36,mY2+14,isHover(mX2+mW-44,mY2+8,36,36) and tocolor(255,60,60,al) or tocolor(120,120,140,al),1.1,"default-bold")

    -- ── MOTOR MODU ──────────────────────────
    local row1Y = mY2+62
    dxDrawText("MOTOR MODU",mX2+20,row1Y,mX2+20,row1Y,tocolor(100,100,120,al),0.82,"default-bold")

    local mods     = {"eco","normal","sport"}
    local modLabel = {"ECO","NORMAL","SPORT"}
    local modAccent= {tocolor(50,210,110,al), tocolor(180,180,200,al), tocolor(255,120,50,al)}
    local modW     = 158
    for i,m in ipairs(mods) do
        local bX=mX2+16+(i-1)*(modW+6)
        local bY=row1Y+22
        local sel=(motorMod==m)
        local cardCol = sel and tocolor(22,22,34,al) or tocolor(18,18,28,al)
        rrect(bX,bY,modW,56,10,cardCol)
        if sel then
            -- Seçili kart: renkli alt şerit
            dxDrawRectangle(bX+10,bY+50,modW-20,4,modAccent[i])
        end
        local tCol = sel and modAccent[i] or tocolor(70,70,90,al)
        dxDrawText(modLabel[i],bX+modW/2,bY+20,bX+modW/2,bY+20,tCol,1.0,"default-bold","center","center")
        -- Alt ikon satırı
        local subTxt = (m=="eco" and "↓ Yakıt") or (m=="normal" and "= Standart") or "↑ Güç"
        local subCol = sel and tocolor(180,180,190,al) or tocolor(50,50,65,al)
        dxDrawText(subTxt,bX+modW/2,bY+36,bX+modW/2,bY+36,subCol,0.78,"default","center","center")
    end

    -- ── TOGGLE KARTLARI ──────────────────────
    local row2Y = mY2+200
    local cards = {
        {label="Launch Control", sub="Air Süsp. gerekli", aktif=launchControl, renk=tocolor(255,80,80,al)},
        {label="Air Süspansiyon", sub="WASD + Shift/Ctrl", aktif=airAcik, renk=tocolor(80,140,255,al)},
        {label="Karaduman", sub="Egzoz dumanı", aktif=karadumanAcik, renk=tocolor(180,180,180,al)},
    }
    local cW = (mW-32)/3 - 4
    for i,card in ipairs(cards) do
        local cX = mX2+16+(i-1)*(cW+6)
        local cY = row2Y
        local cH = 110
        rrect(cX,cY,cW,cH,10,tocolor(18,18,28,al))
        -- Aktifse üst aksanı
        if card.aktif then
            dxDrawRectangle(cX+10,cY+4,cW-20,3,card.renk)
        end
        local tCol = card.aktif and tocolor(240,240,245,al) or tocolor(80,80,100,al)
        dxDrawText(card.label,cX+cW/2,cY+22,cX+cW/2,cY+22,tCol,0.78,"default-bold","center","center")
        dxDrawText(card.sub,cX+cW/2,cY+40,cX+cW/2,cY+40,tocolor(70,70,90,al),0.72,"default","center","center")
        -- Toggle switch
        drawSwitch(cX+cW/2-26,cY+60,card.aktif,al)
        local stateStr = card.aktif and "AKTİF" or "KAPALI"
        local sCol = card.aktif and card.renk or tocolor(60,60,80,al)
        dxDrawText(stateStr,cX+cW/2,cY+92,cX+cW/2,cY+92,sCol,0.75,"default-bold","center","center")
    end

    -- Uyarı satırı (Launch Control için Air gerekli mesajı)
    local vh=getPedOccupiedVehicle(localPlayer)
    local hasAirL=false
    if vh then local pL=getElementData(vh,"takili_parcalar") or {} for _,p in ipairs(pL) do if p=="Air Süspansiyon" then hasAirL=true break end end end
    if not hasAirL then
        dxDrawText("⚠  Launch Control için Air Süspansiyon takılı olmalıdır",mX2+mW/2,mY2+mH-20,mX2+mW/2,mY2+mH-20,tocolor(255,120,50,math.floor(160*alpha)),0.78,"default","center","center")
    end
end

-- ==========================================
-- 9. LAUNCH CONTROL HUD — Modern overlay
-- ==========================================
function drawLaunchHUD()
    local w,h = 300,110
    local hX  = (sx-w)/2
    local hY  = sy-h-60

    -- Arka panel
    rrect(hX,hY,w,h,14,tocolor(10,10,16,210))
    -- Üst çizgi — hazır değilse turuncu, hazırsa kırmızı
    local accentCol = launchReady and tocolor(255,60,60,255) or tocolor(255,170,0,220)
    dxDrawRectangle(hX+14,hY+4,w-28,3,accentCol)

    -- Başlık
    dxDrawText("LAUNCH CONTROL",hX+w/2,hY+18,hX+w/2,hY+18,tocolor(255,255,255,240),0.88,"default-bold","center","center")

    -- Geri sayım rozeti
    dxDrawText(launchCountdown.."s",hX+w-30,hY+14,hX+w-30,hY+14,tocolor(255,170,0,200),0.85,"default-bold","center","center")

    -- RPM bar
    local barX,barY,barW,barH = hX+16,hY+38,w-32,14
    rrect(barX-2,barY-2,barW+4,barH+4,6,tocolor(20,20,30,220))
    dxDrawRectangle(barX,barY,barW,barH,tocolor(30,30,42,255))
    if launchRPM>0 then
        -- gradient: yeşil → sarı → kırmızı
        local barFill = barW*(launchRPM/100)
        local r = math.floor(255*(launchRPM/100))
        local g = math.floor(255*(1-launchRPM/100))
        dxDrawRectangle(barX,barY,barFill,barH,tocolor(r,g,40,255))
    end
    dxDrawText("RPM",barX,barY+barH+4,barX,barY+barH+4,tocolor(100,100,120,200),0.72,"default-bold")
    dxDrawText(launchRPM.."%",barX+barW,barY+barH+4,barX+barW,barY+barH+4,accentCol,0.78,"default-bold","right")

    -- Durum satırı
    local statusTxt = launchReady and "GAZ bırak → FIRLATMA!" or "FREN + GAZ tuşuna bas"
    dxDrawText(statusTxt,hX+w/2,hY+h-16,hX+w/2,hY+h-16,tocolor(200,200,210,200),0.78,"default","center","center")
end

-- ==========================================
-- 10. AIR HUD — Sağ alt, modern gauge
-- ==========================================
function drawAirHUD()
    local w,h = 220,90
    local hX  = sx-w-20
    local hY  = sy-h-20

    rrect(hX,hY,w,h,12,tocolor(10,10,20,210))
    dxDrawRectangle(hX+12,hY+4,w-24,3,tocolor(80,140,255,200))

    dxDrawText("AIR SÜSP.",hX+16,hY+14,hX+16,hY+14,tocolor(80,140,255,240),0.85,"default-bold")
    dxDrawText("AKTİF",hX+w-16,hY+14,hX+w-16,hY+14,tocolor(80,200,120,220),0.78,"default-bold","right")

    -- Yükseklik bar (dikey gösterge)
    local barX,barY,barW,barH = hX+16,hY+38,w-32,14
    rrect(barX-2,barY-2,barW+4,barH+4,6,tocolor(20,20,35,220))
    dxDrawRectangle(barX,barY,barW,barH,tocolor(25,25,40,255))
    local pct=(airYukseklik+1)/2   -- 0..1
    local fillW=barW*pct
    dxDrawRectangle(barX,barY,fillW,barH,tocolor(80,140,255,230))
    -- Orta işareti
    dxDrawRectangle(barX+barW/2-1,barY-3,2,barH+6,tocolor(255,170,0,160))

    local lvlTxt = string.format("%.0f%%", pct*100)
    dxDrawText(lvlTxt,hX+w-16,barY+barH+4,hX+w-16,barY+barH+4,tocolor(80,140,255,200),0.75,"default-bold","right")
    dxDrawText("↑↓←→ eğim  |  Shift/Ctrl yükseklik",hX+w/2,hY+h-12,hX+w/2,hY+h-12,tocolor(80,80,110,180),0.68,"default","center","center")
end

-- ==========================================
-- 10B. DYNO HAZIRLIK OVERLAY — 4sn geri sayım
-- ==========================================
function drawDynoHazirlik(alpha)
    if dynoFaz~="hazirlik" then return end
    local al = math.floor(255*alpha)
    local gecen = getTickCount()-dynoBaslangic
    local kalan = math.max(0, (dynoHazirlikSure-gecen)/1000)
    local kalanInt = math.ceil(kalan)

    -- Tüm ekranı hafif karart
    dxDrawRectangle(0,0,sx,sy,tocolor(5,8,15,math.floor(120*alpha)))

    local w,h = 420,220
    local pX,pY = (sx-w)/2, (sy-h)/2
    rrect(pX,pY,w,h,20,tocolor(8,10,18,math.floor(245*alpha)))
    dxDrawRectangle(pX+20,pY+58,w-40,2,tocolor(60,140,255,math.floor(150*alpha)))

    dxDrawText("DYNAMOMETRE",pX+w/2,pY+22,pX+w/2,pY+22,tocolor(60,140,255,al),1.1,"default-bold","center","center")
    dxDrawText("Araç sabitleniyor...",pX+w/2,pY+44,pX+w/2,pY+44,tocolor(140,140,160,al),0.8,"default","center","center")

    -- Büyük dönen sayaç halkası
    local cx,cy,r = pX+w/2, pY+135, 55
    local pct = 1-(kalan/(dynoHazirlikSure/1000))
    -- Arka halka
    dxDrawCircle(cx,cy,r,0,360,tocolor(0,0,0,0),tocolor(25,25,38,al),48,1)
    for i=0,360,6 do
        local ang = i
        local ringAl = (ang/360 <= pct) and al or math.floor(al*0.15)
        local a1 = math.rad(ang-90)
        local a2 = math.rad(ang-90+5)
        local x1,y1 = cx+math.cos(a1)*r, cy+math.sin(a1)*r
        local x2,y2 = cx+math.cos(a2)*r, cy+math.sin(a2)*r
        dxDrawLine(x1,y1,x2,y2,tocolor(60,140,255,ringAl),5)
    end
    dxDrawText(tostring(kalanInt),cx,cy,cx,cy,tocolor(255,255,255,al),2.2,"default-bold","center","center")

    dxDrawText("Az sonra gaz kontrolü size geçecek",pX+w/2,pY+h-26,pX+w/2,pY+h-26,tocolor(100,100,120,al),0.78,"default","center","center")
end

-- ==========================================
-- 10C. DYNO TEST HUD — modern RPM göstergesi
-- ==========================================
function drawDynoHUD()
    local w,h = 400,160
    local hX  = (sx-w)/2
    local hY  = 80

    rrect(hX,hY,w,h,18,tocolor(8,10,18,225))
    dxDrawRectangle(hX+20,hY+8,w-40,3,tocolor(60,140,255,230))

    local gecen = getTickCount()-dynoBaslangic
    local kalan = math.max(0, math.ceil((dynoSure-gecen)/1000))

    dxDrawText("⚡ DYNO TEST",hX+24,hY+22,hX+24,hY+22,tocolor(255,255,255,245),1.0,"default-bold","left","center")
    -- Geri sayım rozeti
    rrect(hX+w-66,hY+14,46,28,8,tocolor(60,140,255,60))
    dxDrawText(kalan.."s",hX+w-43,hY+28,hX+w-43,hY+28,tocolor(120,180,255,255),0.95,"default-bold","center","center")

    -- RPM Gauge — büyük segment bar
    local barX,barY,barW,barH = hX+24,hY+58,w-48,24
    rrect(barX-2,barY-2,barW+4,barH+4,10,tocolor(18,18,28,220))
    dxDrawRectangle(barX,barY,barW,barH,tocolor(24,24,36,255))
    -- Segmentli dolum (20 dilim)
    local segCount = 24
    local segGap   = 2
    local segW     = (barW-(segCount-1)*segGap)/segCount
    local doluSeg  = math.floor((dynoRPM/100)*segCount)
    for i=0,segCount-1 do
        local sxp = barX + i*(segW+segGap)
        if i < doluSeg then
            local t = i/segCount
            local r = math.floor(60+ t*195)
            local g = math.floor(200-(t*160))
            dxDrawRectangle(sxp,barY+2,segW,barH-4,tocolor(r,g,50,255))
        else
            dxDrawRectangle(sxp,barY+2,segW,barH-4,tocolor(35,35,48,180))
        end
    end
    dxDrawText("RPM",barX,barY+barH+8,barX,barY+barH+8,tocolor(120,120,140,220),0.8,"default-bold")
    dxDrawText(math.floor(dynoRPM).."%",barX+barW,barY+barH+8,barX+barW,barY+barH+8,tocolor(120,180,255,230),0.85,"default-bold","right")

    -- Zaman ilerleme çizgisi (ince)
    local pY = hY+h-26
    local pct = math.min(1, gecen/dynoSure)
    dxDrawRectangle(barX,pY,barW,5,tocolor(28,28,40,200))
    dxDrawRectangle(barX,pY,barW*pct,5,tocolor(80,200,120,220))

    local statusTxt = getPedControlState("accelerate") and "Devam et, gazı bırakma!" or "🔺 GAZA BAS!"
    local sCol = getPedControlState("accelerate") and tocolor(150,200,160,220) or tocolor(255,170,0,255)
    dxDrawText(statusTxt,hX+w/2,hY+h-8,hX+w/2,hY+h-8,sCol,0.85,"default-bold","center","center")
end

-- ==========================================
-- 10D. DYNO SONUÇ PANELİ — modern, grafikli
-- ==========================================
function drawDynoSonuc(alpha)
    if not dynoSonuc then return end
    local al = math.floor(255*alpha)
    local w,h = 520,440
    local pX,pY = (sx-w)/2, (sy-h)/2

    -- Arka karartma
    dxDrawRectangle(0,0,sx,sy,tocolor(0,0,0,math.floor(100*alpha)))

    rrect(pX,pY,w,h,20,tocolor(9,10,17,math.floor(250*alpha)))
    rrect(pX,pY,w,64,20,tocolor(16,18,30,al))
    dxDrawRectangle(pX,pY+48,w,16,tocolor(16,18,30,al))
    dxDrawRectangle(pX+20,pY+60,w-40,2,tocolor(60,140,255,math.floor(170*alpha)))

    dxDrawText("DYNAMOMETRE SONUÇLARI",pX+w/2,pY+24,pX+w/2,pY+24,tocolor(255,255,255,al),1.15,"default-bold","center","center")
    dxDrawText("✕",pX+w-40,pY+18,pX+w-40,pY+18,isHover(pX+w-48,pY+10,36,36) and tocolor(255,60,60,al) or tocolor(130,130,150,al),1.2,"default-bold")

    -- 4 büyük istatistik kartı (2x2)
    local stats = {
        {label="GÜÇ",     value=dynoSonuc.hp,     birim="HP",   renk=tocolor(255,120,50,al),  ikon="🔥"},
        {label="TORK",    value=dynoSonuc.tork,   birim="Nm",   renk=tocolor(255,200,50,al),  ikon="⚙"},
        {label="MAX HIZ", value=dynoSonuc.maxHiz, birim="km/h", renk=tocolor(60,200,255,al),  ikon="💨"},
        {label="0-100",   value=dynoSonuc.zeroYuz,birim="sn",   renk=tocolor(160,100,255,al), ikon="⏱"},
    }
    local cW,cH = (w-60)/2, 96
    for i,st in ipairs(stats) do
        local col = (i-1)%2
        local row = math.floor((i-1)/2)
        local cX = pX+20+col*(cW+20)
        local cY = pY+82+row*(cH+14)
        rrect(cX,cY,cW,cH,14,tocolor(18,18,30,al))
        dxDrawRectangle(cX,cY,4,cH,st.renk)
        dxDrawText(st.ikon.."  "..st.label,cX+22,cY+16,cX+22,cY+16,tocolor(130,130,150,al),0.82,"default-bold")
        dxDrawText(tostring(st.value),cX+22,cY+38,cX+22,cY+38,st.renk,1.6,"default-bold")
        dxDrawText(st.birim,cX+22+dxGetTextWidth(tostring(st.value),1.6,"default-bold")+30,cY+50,cX+22,cY+50,tocolor(110,110,130,al),0.85,"default-bold")
    end

    -- Artış yüzdeleri (varsa)
    local infoY = pY+82+2*(cH+14)+6
    if dynoSonuc.hizArtis and dynoSonuc.torkArtis then
        local hizTxt  = (dynoSonuc.hizArtis>=0  and "+"..dynoSonuc.hizArtis.."%"  or dynoSonuc.hizArtis.."%")
        local torkTxt = (dynoSonuc.torkArtis>=0 and "+"..dynoSonuc.torkArtis.."%" or dynoSonuc.torkArtis.."%")
        rrect(pX+20,infoY,w-40,40,10,tocolor(16,18,28,al))
        dxDrawText("Orijinale Göre:",pX+36,infoY+20,pX+36,infoY+20,tocolor(120,120,140,al),0.8,"default-bold","left","center")
        dxDrawText("Hız "..hizTxt,pX+w/2-20,infoY+20,pX+w/2-20,infoY+20,dynoSonuc.hizArtis>=0 and tocolor(80,220,140,al) or tocolor(220,80,80,al),0.85,"default-bold","center","center")
        dxDrawText("Tork "..torkTxt,pX+w-36,infoY+20,pX+w-36,infoY+20,dynoSonuc.torkArtis>=0 and tocolor(80,220,140,al) or tocolor(220,80,80,al),0.85,"default-bold","right","center")
    end

    -- Alt bilgi
    dxDrawText("Takılı Parça: "..dynoSonuc.parcaSayisi.." adet",pX+w/2,pY+h-44,pX+w/2,pY+h-44,tocolor(150,150,160,al),0.85,"default")
    dxDrawText("Kapatmak için tıklayın",pX+w/2,pY+h-22,pX+w/2,pY+h-22,tocolor(80,80,100,al),0.75,"default")
end

-- ==========================================
-- 11. TIKLAMA
-- ==========================================
addEventHandler("onClientClick", root, function(b,s)
    if b~="left" or s~="down" then return end

    -- Dyno sonuç paneli kapatma (herhangi bir yere tıklayınca kapanır)
    if dynoSonuc and dynoPanelAlpha>0.5 then
        dynoSonuc = nil
        dynoFaz   = "idle"
        if not panel and not mycarPanel then showCursor(false) end
        return
    end

    -- MyCar
    if mycarPanel and mycarAlpha>0.5 then
        local mW,mH=560,390
        local mX2,mY2=(sx-mW)/2,(sy-mH)/2
        if isHover(mX2+mW-44,mY2+8,36,36) then mycarPanel=false showCursor(false) return end
        -- Motor mod kartları
        local modW=158
        for i,m in ipairs({"eco","normal","sport"}) do
            if isHover(mX2+16+(i-1)*(modW+6),mY2+84,modW,56) then
                motorMod=m
                local vh=getPedOccupiedVehicle(localPlayer) if vh then motorModUygula(vh) end
                return
            end
        end
        -- Toggle kartları
        local row2Y=mY2+200
        local cW=(mW-32)/3-4
        -- Launch Control
        if isHover(mX2+16,row2Y,cW,110) then
            local vh=getPedOccupiedVehicle(localPlayer)
            local ok=false
            if vh then local pL=getElementData(vh,"takili_parcalar") or {} for _,p in ipairs(pL) do if p=="Air Süspansiyon" then ok=true break end end end
            if ok then
                if not launchControl then launchControlAc(vh)
                else
                    if launchAktifTimer and isTimer(launchAktifTimer) then killTimer(launchAktifTimer) end
                    launchControl=false launchReady=false launchRPM=0
                end
            else
                outputChatBox("[MyCar] Launch Control için Air Süspansiyon gerekli!",255,80,50)
            end
            return
        end
        -- Air
        if isHover(mX2+16+(cW+6),row2Y,cW,110) then
            local vh=getPedOccupiedVehicle(localPlayer)
            local ok=false
            if vh then local pL=getElementData(vh,"takili_parcalar") or {} for _,p in ipairs(pL) do if p=="Air Süspansiyon" then ok=true break end end end
            if ok then airAcik=not airAcik
            else outputChatBox("[MyCar] Air Süspansiyon takılı değil!",255,80,50) end
            return
        end
        -- Karaduman
        if isHover(mX2+16+(cW+6)*2,row2Y,cW,110) then
            karadumanAcik=not karadumanAcik return
        end
        return
    end

    -- Tuning panel
    if not panel or isInstalling then return end
    local bgX,bgY=(sx-bgW)/2,(sy-bgH)/2
    if isHover(bgX+bgW-45,bgY+25,20,20) then panel=false showCursor(false) return end
    for i,kat in ipairs(Kategoriler) do
        if isHover(bgX+15,bgY+90+(i-1)*55,sideW-30,42) then seciliKat=kat return end
    end
    if seciliKat~="Ana Sayfa" then
        local xOff,pW=bgX+sideW+35,bgW-sideW-70
        for i,p in ipairs(Urunler[seciliKat] or {}) do
            if isHover(xOff,bgY+80+(i-1)*75,pW,65) then
                if checkSahip(p[1]) then showUyari("BU PARÇA ZATEN TAKILI!") return end
                local ok,neden=checkKilit(p[4]) if not ok then showUyari(neden) return end
                local para=exports.drp_global:getMoney(localPlayer) or 0
                if para>=p[2] then isInstalling=true installProgress=0 installItem=p[1] installPrice=p[2] playSoundFrontEnd(1)
                else showUyari("YETERSİZ BAKİYE! (Gereken: $"..p[2]..")") end
                return
            end
        end
    end
end)

-- ==========================================
-- 12. KOMUTLAR
-- ==========================================
addCommandHandler("mycar",    function() mycarPanel=not mycarPanel showCursor(mycarPanel) end)
addCommandHandler("egzoz",    function() egzozSesAcik=not egzozSesAcik outputChatBox("[Stage] Egzoz sesi: "..(egzozSesAcik and "AÇIK" or "KAPALI"),egzozSesAcik and 0 or 200,egzozSesAcik and 200 or 80,0) end)
addCommandHandler("karaduman",function() karadumanAcik=not karadumanAcik outputChatBox("[Stage] Karaduman: "..(karadumanAcik and "AÇIK" or "KAPALI"),150,150,150) end)
addCommandHandler("air", function()
    local vh=getPedOccupiedVehicle(localPlayer) if not vh then outputChatBox("[Air] Araçta değilsiniz.",255,80,80) return end
    local pL=getElementData(vh,"takili_parcalar") or {} local has=false
    for _,p in ipairs(pL) do if p=="Air Süspansiyon" then has=true break end end
    if not has then outputChatBox("[Air] Air Süspansiyon takılı değil!",255,80,80) return end
    airAcik=not airAcik
    outputChatBox("[Air] "..(airAcik and "AKTİF" or "KAPALI"),80,140,255)
end)
addCommandHandler("stagebul", function()
    local px,py,pz=getElementPosition(localPlayer) local n=0
    for _,vh in ipairs(getElementsByType("vehicle")) do
        if isElement(vh) then
            local vx,vy,vz=getElementPosition(vh)
            local d=getDistanceBetweenPoints3D(px,py,pz,vx,vy,vz)
            if d<=50 and d>1 then
                local pL=getElementData(vh,"takili_parcalar") or {}
                if #pL>0 then n=n+1 outputChatBox(string.format("[StageBul] #%d | %s | %.0fm | %s",n,getVehiclePlateText(vh) or "?",d,table.concat(pL,", ")),255,200,0) end
            end
        end
    end
    if n==0 then outputChatBox("[StageBul] 50m çevrede modifiyeli araç yok.",180,180,180) end
end)
