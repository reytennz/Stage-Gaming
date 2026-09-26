-- ============================================================
-- Stage Loading + Radar köprüsü
-- Bu dosya radar/sourceC.lua'dan ÖNCE yüklenir.
-- ============================================================

StageRadarConfig = {
    -- Mini harita (sol altta) açık mı?
    minimap = true,
    -- Mini harita konumu / boyutu
    minimapX = 10,
    minimapY = nil, -- nil = ekranın altına hizala
    minimapW = 260,
    minimapH = 205,
    -- F11 büyük haritası açıkken imleç görünsün mü?
    bigmapCursor = true,
    -- Kullanılacak harita resmi
    mapFile = "radar/files/map2.png",
}

-- ============================================================
-- Haritada gosterilecek sabit bliplar
-- { x, y, z, "blips/DOSYA.png", uzaktanGoster, gorunmeMesafesi, boyut, renk }
-- Istemedigin satirin basina -- koy, yeni yer icin yeni satir ekle.
-- ============================================================
StageRadarBlips = {
    -- Hastaneler
    { 1177.5, -1323.5, 14.0, "blips/hospital.png", true, 9999, 20, 0xFFFFFFFF },
    { 2034.0, -1404.5, 17.2, "blips/hospital.png", true, 9999, 20, 0xFFFFFFFF },
    { 1607.0, 1815.0, 10.8, "blips/hospital.png", true, 9999, 20, 0xFFFFFFFF },
    { -2655.0, 635.0, 14.5, "blips/hospital.png", true, 9999, 20, 0xFFFFFFFF },
    { -1514.5, 2526.0, 55.7, "blips/hospital.png", true, 9999, 20, 0xFFFFFFFF },
    -- Polis
    { 1554.5, -1675.5, 16.2, "blips/pd.png", true, 9999, 20, 0xFFFFFFFF },
    { -1605.5, 711.0, 13.9, "blips/pd.png", true, 9999, 20, 0xFFFFFFFF },
    { 2287.5, 2432.0, 10.8, "blips/pd.png", true, 9999, 20, 0xFFFFFFFF },
    { -2438.0, 2290.0, 4.9, "blips/sheriffblip.png", true, 9999, 20, 0xFFFFFFFF },
    -- Belediye
    { 1481.5, -1771.0, 18.8, "blips/city_hall.png", true, 9999, 20, 0xFFFFFFFF },
    -- Bankalar
    { 1462.0, -1013.0, 26.8, "blips/bank.png", true, 9999, 20, 0xFFFFFFFF },
    { -1613.0, -2724.5, 48.5, "blips/bank.png", true, 9999, 20, 0xFFFFFFFF },
    { 2145.5, 1631.0, 12.3, "blips/bank.png", true, 9999, 20, 0xFFFFFFFF },
    -- Benzinlikler
    { 1004.0, -937.0, 42.2, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { 1944.5, -1772.5, 13.4, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { -1609.0, -2718.0, 48.5, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { -2408.0, 976.0, 45.3, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { 2202.0, 2474.0, 10.8, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { -91.0, -1169.0, 2.4, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    { 2115.0, 920.0, 10.8, "blips/gas_station.png", true, 9999, 18, 0xFFFFFFFF },
    -- Market ve yemek
    { 1352.5, -1758.5, 13.5, "blips/shop.png", true, 9999, 18, 0xFFFFFFFF },
    { 2400.0, -1980.0, 13.5, "blips/shop.png", true, 9999, 18, 0xFFFFFFFF },
    { -2489.0, 2360.0, 4.9, "blips/shop.png", true, 9999, 18, 0xFFFFFFFF },
    { 2104.0, 2228.0, 11.0, "blips/burger.png", true, 9999, 18, 0xFFFFFFFF },
    { 1198.5, -918.0, 43.1, "blips/cluckin.png", true, 9999, 18, 0xFFFFFFFF },
    -- Kiyafet
    { 2244.0, -1665.0, 15.5, "blips/clothes_shop.png", true, 9999, 18, 0xFFFFFFFF },
    { 462.0, -1500.0, 32.0, "blips/binco.png", true, 9999, 18, 0xFFFFFFFF },
    -- Arac, tuning, tamir
    { 2645.0, -2028.0, 13.5, "blips/car_shop.png", true, 9999, 20, 0xFFFFFFFF },
    { 1041.0, -1029.0, 32.0, "blips/tuning.png", true, 9999, 20, 0xFFFFFFFF },
    { 2387.0, 1035.0, 10.8, "blips/tuning_workshop.png", true, 9999, 20, 0xFFFFFFFF },
    { 1024.5, -1024.0, 32.1, "blips/car_repair.png", true, 9999, 18, 0xFFFFFFFF },
    -- Silah
    { 1368.0, -1279.5, 13.5, "blips/weapon_shop.png", true, 9999, 18, 0xFFFFFFFF },
    { 2159.0, 943.0, 10.8, "blips/weapon_shop.png", true, 9999, 18, 0xFFFFFFFF },
    -- Spor
    { 1972.0, -1176.0, 25.4, "blips/gym.png", true, 9999, 18, 0xFFFFFFFF },
    -- Havalimani
    { 1685.0, -2334.0, 13.5, "blips/airport.png", true, 9999, 20, 0xFFFFFFFF },
    { -1425.0, -290.0, 14.1, "blips/airport.png", true, 9999, 20, 0xFFFFFFFF },
    { 1676.0, 1449.0, 10.8, "blips/airport.png", true, 9999, 20, 0xFFFFFFFF },
}

local sw, sh = guiGetScreenSize()

-- Mini harita konumu
function StageRadarMinimapPos()
    local y = StageRadarConfig.minimapY
    if not y then
        y = sh - StageRadarConfig.minimapH - 20
    end
    return StageRadarConfig.minimapX, y, StageRadarConfig.minimapW, StageRadarConfig.minimapH
end

-- Radar/harita çizilebilir mi? (giriş yapılmış ve HUD gizli değilse)
function StageRadarCanDraw()
    if not localPlayer then return false end
    if not getElementData(localPlayer, "stage:logged") then return false end
    if getElementData(localPlayer, "hud:ep") then return false end
    return true
end

-- F11 haritası açılıp kapanırken imleç
function StageRadarCursor(show)
    if not StageRadarConfig.bigmapCursor then return end
    showCursor(show and true or false)
end

-- Giriş yapılmadığında / karakter seçimine dönüldüğünde büyük harita kapalı kalsın
addEventHandler("onClientElementDataChange", localPlayer,
    function(dataName)
        if dataName == "stage:logged" and not getElementData(localPlayer, "stage:logged") then
            if bigmapIsVisible then
                bigmapIsVisible = false
                setElementData(localPlayer, "bigmapIsVisible", false, false)
                StageRadarCursor(false)
            end
        end
    end
)
