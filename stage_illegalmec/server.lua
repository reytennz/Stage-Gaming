-- ==========================================
-- 0. MARKER LİSTESİ — buraya konum gir
-- ==========================================
local MarkerKonumlari = {
    -- {x=-1669.63, y=553.36, z=37.27},
     {x=-307.51550, y=-2182.51855, z=30.63999},
}

addEvent("markerListesiIste", true)
addEventHandler("markerListesiIste", root, function()
    triggerClientEvent(client, "markerListesiGonder", resourceRoot, MarkerKonumlari)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, "markerListesiGonder", resourceRoot, MarkerKonumlari)
    end
end)

addEventHandler("onPlayerJoin", root, function()
    triggerClientEvent(source, "markerListesiGonder", resourceRoot, MarkerKonumlari)
end)

-- ==========================================
-- 0B. DYNO MARKER LİSTESİ — buraya konum gir
-- ==========================================
local DynoKonumlari = {
    -- {x=-1669.63, y=5573.36, z=37.27},
   {x=2512.9580078125, y=-2074.078125, z=14.446882247925}
}

addEvent("dynoListesiIste", true)
addEventHandler("dynoListesiIste", root, function()
    triggerClientEvent(client, "dynoListesiGonder", resourceRoot, DynoKonumlari)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, "dynoListesiGonder", resourceRoot, DynoKonumlari)
    end
end)

addEventHandler("onPlayerJoin", root, function()
    triggerClientEvent(source, "dynoListesiGonder", resourceRoot, DynoKonumlari)
end)

-- ==========================================
-- 1. HER PARÇANIN FİZİKSEL ETKİSİ
-- ==========================================
local Performans = {
    ["Stage 1"] = {hiz = 1.05, tork = 1.0, risk = 5},
    ["Stage 2"] = {hiz = 2.10, tork = 2.10, risk = 24},
    ["Stage 3"] = {hiz = 3.18, tork = 2.35, risk = 50},
    ["Çelik Saplama"] = {hiz = 1.0, tork = 1.0, risk = -15},
    ["Çelik Gömlek"] = {hiz = 1.0, tork = 1.0, risk = -30},
    ["Dövme Piston"] = {hiz = 1.0, tork = 1.0, risk = -60}, 
    ["Gelişmiş Paller"] = {hiz = 1.02, tork = 1.08, risk = 5},
    ["Hibrit Turbo"] = {hiz = 1.10, tork = 1.22, risk = 20},
    ["Big Turbo"] = {hiz = 1.25, tork = 1.50, risk = 50},
    ["Yüksek Basınçlı Pompa"] = {hiz = 1.0, tork = 1.05, risk = 2},
    ["550cc Enjektör"] = {hiz = 1.03, tork = 1.08, risk = 5},
    ["1000cc Enjektör"] = {hiz = 1.06, tork = 1.15, risk = 10},
    ["Spor Susturucu"] = {hiz = 1.01, tork = 1.02, risk = 0},
    ["Downpipe"] = {hiz = 1.03, tork = 1.05, risk = 2},
    ["Krom Düz Boru"] = {hiz = 1.06, tork = 1.08, risk = 5},
    ["Kısa Şanzıman"] = {hiz = 0.95, tork = 1.25, risk = 5}, 
    ["Bronz Debriyaj"] = {hiz = 1.0, tork = 1.15, risk = 0},
    ["Kilitli Diferansiyel"] = {hiz = 1.0, tork = 1.0, risk = 5},
    ["Drift Kiti"] = {hiz = 1.0, tork = 1.0, risk = 0},
    ["Karaduman"] = {hiz = 1.0, tork = 1.0, risk = 0},
    ["Popcorn Kit"] = {hiz = 1.0, tork = 1.0, risk = 0},
    ["Air Süspansiyon"] = {hiz = 1.0, tork = 1.0, risk = 0}
}

-- ==========================================
-- 2. VERİTABANI
-- Tablolar db.lua içinde (stage_mysql bağlantısı) oluşturuluyor.
-- ==========================================


function araciGuncelle(vh, parcalar)
    if not isElement(vh) then return end
    
    -- Önce orijinal handling değerlerini al
    local orjinal = getOriginalHandling(getElementModel(vh))
    if not orjinal then return end

    -- Orijinal değerleri sıfırla (temiz başlangıç)
    setVehicleHandling(vh, "maxVelocity",        orjinal.maxVelocity)
    setVehicleHandling(vh, "engineAcceleration", orjinal.engineAcceleration)
    setVehicleHandling(vh, "tractionMultiplier", orjinal.tractionMultiplier)
    setVehicleHandling(vh, "suspensionLowerLimit", orjinal.suspensionLowerLimit or -0.10)
    setVehicleHandling(vh, "suspensionUpperLimit", orjinal.suspensionUpperLimit or  0.25)
    setVehicleHandling(vh, "suspensionForce",      orjinal.suspensionForce     or  1.5)
    setVehicleHandling(vh, "suspensionDamping",    orjinal.suspensionDamping   or  0.15)
    setVehicleHandling(vh, "brakeBias",            orjinal.brakeBias           or  0.5)
    setVehicleHandling(vh, "steeringLock",         orjinal.steeringLock        or  35)

    local carp_hiz, carp_tork = 1.0, 1.0
    local hasAir, hasKilitli, hasDrift = false, false, false

    -- Hangi özel parçalar var önce belirle
    for _, p in ipairs(parcalar) do
        if p == "Kilitli Diferansiyel" then hasKilitli = true end
        if p == "Drift Kiti"           then hasDrift   = true end
        if p == "Air Süspansiyon"      then hasAir     = true end
    end

    for _, p in ipairs(parcalar) do
        local d = Performans[p]
        if d then
            carp_hiz  = carp_hiz  * (d.hiz  or 1.0)
            carp_tork = carp_tork * (d.tork or 1.0)
            if p == "Dövme Piston" then setElementData(vh, "motor_block", "forged") end
            -- Kısa şanzıman: sadece fren dengesi, direksiyon; traction dokunma
            if p == "Kısa Şanzıman" then
                setVehicleHandling(vh, "brakeBias",    0.58)
                setVehicleHandling(vh, "steeringLock", 32)
            end
            -- Bronz debriyaj: daha sert amortisör
            if p == "Bronz Debriyaj" then
                setVehicleHandling(vh, "suspensionDamping", (orjinal.suspensionDamping or 0.15) + 0.04)
            end
        end
    end

    -- Air süspansiyon: alçaltma + yumuşak sürüş
    if hasAir then
        setVehicleHandling(vh, "suspensionLowerLimit", -0.20)
        setVehicleHandling(vh, "suspensionUpperLimit",  0.10)
        setVehicleHandling(vh, "suspensionForce",       0.95)
        setVehicleHandling(vh, "suspensionDamping",     0.08)
    end

    setVehicleHandling(vh, "maxVelocity",        orjinal.maxVelocity        * carp_hiz)
    setVehicleHandling(vh, "engineAcceleration", orjinal.engineAcceleration * carp_tork)

    -- tractionMultiplier: sadece Drift Kiti kaydırır, diğer her durumda sıkı tut
    if hasDrift then
        -- Drift Kiti: arka kayar, geniş direksiyon
        setVehicleHandling(vh, "tractionMultiplier", orjinal.tractionMultiplier * 0.45)
        setVehicleHandling(vh, "brakeBias",    0.20)
        setVehicleHandling(vh, "steeringLock", 45)
    elseif hasKilitli then
        -- Kilitli diferansiyel: tam tutunma, kayma yok
        setVehicleHandling(vh, "tractionMultiplier", orjinal.tractionMultiplier * 1.40)
    else
        -- Normal durum: orijinal traction, kalkışta sarsıntı yok
        setVehicleHandling(vh, "tractionMultiplier", orjinal.tractionMultiplier)
    end
end

-- Parça listesini veritabanına yazar (tek yerden, stage_mysql bağlantısıyla)
function parcalariKaydet(vh)
    if not isElement(vh) then return end
    local plaka = getVehiclePlateText(vh)
    if not plaka then return end
    local db = getStageDB()
    if not db then return end
    local liste = getElementData(vh, "takili_parcalar") or {}
    dbExec(db, "REPLACE INTO arac_parcalar (plaka, veriler) VALUES (?, ?)", plaka, toJSON(liste))
end

function araciYukle(vh)
    if not isElement(vh) then return end
    local plaka = getVehiclePlateText(vh)
    if not plaka then return end
    local db = getStageDB()
    if not db then return end

    dbQuery(function(qh, arac)
        local res = dbPoll(qh, 0)
        if res and res[1] and isElement(arac) then
            local pList = fromJSON(res[1].veriler) or {}
            setElementData(arac, "takili_parcalar", pList)
            araciGuncelle(arac, pList)
        end
    end, {vh}, db, "SELECT veriler FROM arac_parcalar WHERE plaka=?", plaka)
end

addEventHandler("onResourceStart", resourceRoot, function()
    for _, v in ipairs(getElementsByType("vehicle")) do araciYukle(v) end
end)

addEventHandler("onVehicleEnter", root, function() 
    araciYukle(source) 
end)

-- ==========================================
-- 3. SATIN ALMA İŞLEMİ VE KAYIT
-- ==========================================
addEvent("yazilimSatinAl", true)
addEventHandler("yazilimSatinAl", root, function(pIsim, fiyat)
    local vh = getPedOccupiedVehicle(client)
    if not vh then return end

    -- drp_global para kontrolü
    local mevcutPara = exports.stage_economy:getMoney(client)
    if not mevcutPara or mevcutPara < fiyat then
        outputChatBox("[Revans Tuning] Yetersiz bakiye! Gereken: $" .. fiyat, client, 255, 0, 0)
        return
    end

    -- drp_global para çekme
    if not exports.stage_economy:takeMoney(client, fiyat) then
        outputChatBox("[Revans Tuning] Para çekme işlemi başarısız.", client, 255, 0, 0)
        return
    end
    
    local takili = getElementData(vh, "takili_parcalar") or {}
    table.insert(takili, pIsim)
    setElementData(vh, "takili_parcalar", takili)

    parcalariKaydet(vh)


    araciGuncelle(vh, takili)
    outputChatBox("[Revans Tuning] "..pIsim.." başarıyla kuruldu.", client, 0, 255, 0)
end)

-- ==========================================
-- 4B. MOTOR MOD İSTEĞİ (client motorModUygula çağırınca)
-- ==========================================
addEvent("araciGuncelleIstek", true)
addEventHandler("araciGuncelleIstek", root, function()
    local vh = getPedOccupiedVehicle(client)
    if not vh then return end
    local pList = getElementData(vh, "takili_parcalar") or {}
    araciGuncelle(vh, pList)
end)

-- ==========================================
-- 4C. DYNO TEST — SONUÇ HESAPLAMA (gerçekçi)
-- ==========================================
addEvent("dynoTestIste", true)
addEventHandler("dynoTestIste", root, function(maxRPMUlasilan)
    local vh = getPedOccupiedVehicle(client)
    if not vh or not isElement(vh) then return end

    local h   = getVehicleHandling(vh)
    local orj = getOriginalHandling(getElementModel(vh))
    if not h or not orj then return end

    -- Oyuncunun gaz performansı (0-100) — hiç gaza basmadıysa düşük sonuç gösterir
    local gazPerf = tonumber(maxRPMUlasilan) or 100
    gazPerf = math.max(35, math.min(100, gazPerf))  -- min %35 taban (motor rölantide bile bir şey gösterir)
    local gazCarpan = gazPerf / 100

    -- Gerçek km/h dönüşümü (GTA SA: velocity birimi * 180 ≈ km/h)
    local maxHiz = math.floor(h.maxVelocity * 180 * gazCarpan)
    maxHiz = math.min(maxHiz, 400)

    -- Orijinal araca göre yüzdesel artış oranları
    local hizOrani  = h.maxVelocity / orj.maxVelocity
    local torkOrani = h.engineAcceleration / orj.engineAcceleration

    -- Referans: standart bir GTA SA aracı ~ 150 HP / 220 Nm kabul edilir
    local baseHP   = 150
    local baseTork = 220

    local hp   = math.floor(baseHP * torkOrani * ((hizOrani+torkOrani)/2) * gazCarpan)
    local tork = math.floor(baseTork * torkOrani * gazCarpan)

    -- 0-100: ivme arttıkça süre düşer, orijinali referans alır (~7.5sn standart)
    local baseZeroYuz = 7.5
    local zeroYuz = (baseZeroYuz / torkOrani) / gazCarpan
    zeroYuz = math.max(2.5, zeroYuz)
    zeroYuz = math.floor(zeroYuz * 10) / 10

    local pList = getElementData(vh, "takili_parcalar") or {}

    triggerClientEvent(client, "dynoSonucGonder", resourceRoot, {
        maxHiz  = maxHiz,
        tork    = tork,
        hp      = hp,
        zeroYuz = zeroYuz,
        parcaSayisi = #pList,
        hizArtis  = math.floor((hizOrani-1)*100),
        torkArtis = math.floor((torkOrani-1)*100),
    })
end)


-- ==========================================
-- 5. /fullcar [id] - TÜM PARÇALARI EKLE
-- ==========================================
local TumParcalar = {
    "Stage 1", "Stage 2", "Stage 3",
    "Çelik Saplama", "Çelik Gömlek", "Dövme Piston",
    "Gelişmiş Paller", "Hibrit Turbo", "Big Turbo",
    "Yüksek Basınçlı Pompa", "550cc Enjektör", "1000cc Enjektör",
    "Spor Susturucu", "Downpipe", "Krom Düz Boru",
    "Kısa Şanzıman", "Bronz Debriyaj", "Kilitli Diferansiyel",
    "Karaduman", "Popcorn Kit", "Air Süspansiyon"
}

addCommandHandler("fullcar", function(player, cmd, targetID)
    -- Sadece admin/mod kullanabilsin
    if not isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Admin"))
    and not isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Moderator")) then
        outputChatBox("[Stage Tuning] Bu komut sadece adminler içindir.", player, 255, 0, 0)
        return
    end

    local target
    if targetID then
        target = getPlayerFromName(targetID) or getElementsByType("player")[tonumber(targetID)]
        -- ID ile de dene
        for _, p in ipairs(getElementsByType("player")) do
            if tostring(getElementID(p)) == tostring(targetID) or getPlayerName(p):lower():find(targetID:lower()) then
                target = p
                break
            end
        end
    else
        target = player
    end

    if not target or not isElement(target) then
        outputChatBox("[Stage Tuning] Oyuncu bulunamadı.", player, 255, 0, 0)
        return
    end

    local vh = getPedOccupiedVehicle(target)
    if not vh then
        outputChatBox("[Stage Tuning] Hedef oyuncu araçta değil.", player, 255, 0, 0)
        return
    end

    setElementData(vh, "takili_parcalar", TumParcalar)
    parcalariKaydet(vh)

    araciGuncelle(vh, TumParcalar)

    local targetName = getPlayerName(target)
    outputChatBox("[Revans Tuning] " .. targetName .. " aracına tüm parçalar eklendi. (" .. #TumParcalar .. " parça)", player, 0, 255, 0)
    if target ~= player then
        outputChatBox("[Stage Tuning] Aracınıza tüm parçalar admin tarafından eklendi.", target, 0, 255, 0)
    end
end)

-- ==========================================
-- 6. MOTOR PATLAMA SİMÜLASYONU
-- ==========================================
setTimer(function()
    for _, vh in ipairs(getElementsByType("vehicle")) do
        local parcalar = getElementData(vh, "takili_parcalar") or {}
        local riskSkoru, forged = 0, (getElementData(vh, "motor_block") == "forged")
        
        for _, p in ipairs(parcalar) do 
            if Performans[p] then riskSkoru = riskSkoru + (Performans[p].risk or 0) end 
        end

        if riskSkoru > 45 and not forged then
            if getVehicleEngineState(vh) and getVehicleCurrentGear(vh) > 0 then
                local hp = getElementHealth(vh)
                if hp > 300 then setElementHealth(vh, hp - 8) end
            end
        end
    end
end, 3000, 0)
