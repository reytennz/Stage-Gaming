-- server.lua
-- DRP Performance Tablet Sistemi - drp_mysql (paylaşılan MySQL bağlantısı) kullanır.
-- drp_mysql export'ları: exports.drp_mysql:getConnection() -> standart dbConnect connection objesi

local db = nil

-- Performans notu: connection objesini her sorguda export ile yeniden çekmek yerine
-- bir kere alıp önbellekte tutuyoruz. drp_mysql yeniden başlarsa getDB() otomatik yeniler.
local function getDB()
    if db and isElement(db) then return db end
    db = exports.stage_mysql:getConnection()
    return db
end

addEventHandler("onResourceStart", resourceRoot, function()
    local conn = getDB()
    if not conn then
        outputDebugString("[DRP Tablet] MySQL bağlantısı alınamadı! 'drp_mysql' kaynağı başlamış ve bağlanmış mı kontrol et.", 1)
        return
    end

    -- Tablet hesapları: hem dükkan sahibi hem eleman girişleri aynı tabloda tutulur.
    -- eleman = NULL  -> sahibi hesabı (duty konumu buraya yazılır)
    -- eleman = 1     -> eleman hesabı (duty konumu boş kalır, sahibi'nden okunur)
    dbExec(conn, [[
        CREATE TABLE IF NOT EXISTS mechanic_shops (
            id INT NOT NULL AUTO_INCREMENT,
            mekanik_ismi VARCHAR(64) NOT NULL,
            sifresi VARCHAR(255) NOT NULL,
            sahibi VARCHAR(64) NOT NULL,
            owner_id INT NOT NULL,
            eleman TINYINT(1) DEFAULT NULL,
            duty_x FLOAT DEFAULT NULL,
            duty_y FLOAT DEFAULT NULL,
            duty_z FLOAT DEFAULT NULL,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_mekanik_ismi (mekanik_ismi)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- ==========================================
-- /tabletkur [Mekanik İsmi] [Şifre] [Sahibi] [ID]
-- Dükkan sahibi hesabını oluşturur (eleman = NULL)
-- ==========================================
addCommandHandler(CONFIG.KOMUTLAR.tabletKur, function(player, cmd, isim, sifre, sahibi, ownerId)
    if not isim or not sifre or not sahibi or not ownerId then
        outputChatBox("Kullanım: /tabletkur [Mekanik İsmi] [Şifre] [Sahibi] [ID]", player, 255, 255, 0)
        return
    end

    local conn = getDB()
    if not conn then
        outputChatBox("Veritabanı bağlantısı yok, yetkiliye bildirin.", player, 255, 0, 0)
        return
    end

    local hashedSifre = hash("sha256", sifre)

    -- Aynı isimde hesap var mı diye async kontrol ediyoruz (bloklamıyor).
    dbQuery(function(qh, plyr, mekanikIsmi, sahibiIsim, hashli, ownerIdNum)
        local sonuc = dbPoll(qh, 0)
        if sonuc and #sonuc > 0 then
            outputChatBox("Hata: '" .. mekanikIsmi .. "' isminde bir tablet hesabı zaten var!", plyr, 255, 0, 0)
            return
        end

        dbExec(getDB(),
            "INSERT INTO mechanic_shops (mekanik_ismi, sifresi, sahibi, owner_id, eleman) VALUES (?, ?, ?, ?, NULL)",
            mekanikIsmi, hashli, sahibiIsim, ownerIdNum)

        outputChatBox("Başarılı: '" .. mekanikIsmi .. "' adlı mekanik için tablet hesabı oluşturuldu!", plyr, 0, 255, 0)
    end, {player, isim, sahibi, hashedSifre, tonumber(ownerId)}, conn, "SELECT id FROM mechanic_shops WHERE mekanik_ismi=?", isim)
end)

-- ==========================================
-- /elemanekle [Eleman İsmi] [Şifre] [ID]
-- Sadece giriş yapmış bir dükkan sahibi kullanabilir. Aynı dükkana bağlı eleman hesabı açar.
-- ==========================================
addCommandHandler(CONFIG.KOMUTLAR.elemanEkle, function(player, cmd, elemanIsim, elemanSifre, elemanId)
    local sahibi = getElementData(player, "tablet:sahibi")
    local elemanMi = getElementData(player, "tablet:eleman")

    if not sahibi or elemanMi then
        outputChatBox("Bu komutu kullanmak için tablette dükkan sahibi olarak giriş yapmış olmalısın.", player, 255, 0, 0)
        return
    end

    if not elemanIsim or not elemanSifre or not elemanId then
        outputChatBox("Kullanım: /elemanekle [Eleman İsmi] [Şifre] [ID]", player, 255, 255, 0)
        return
    end

    local conn = getDB()
    if not conn then
        outputChatBox("Veritabanı bağlantısı yok, yetkiliye bildirin.", player, 255, 0, 0)
        return
    end

    local hashedSifre = hash("sha256", elemanSifre)

    dbQuery(function(qh, plyr, isimK, sahibiIsim, hashli, idNum)
        local sonuc = dbPoll(qh, 0)
        if sonuc and #sonuc > 0 then
            outputChatBox("Bu isimde bir tablet hesabı zaten var!", plyr, 255, 0, 0)
            return
        end

        dbExec(getDB(),
            "INSERT INTO mechanic_shops (mekanik_ismi, sifresi, sahibi, owner_id, eleman) VALUES (?, ?, ?, ?, 1)",
            isimK, hashli, sahibiIsim, idNum)

        outputChatBox("Eleman hesabı oluşturuldu: " .. isimK, plyr, 0, 255, 0)
    end, {player, elemanIsim, sahibi, hashedSifre, tonumber(elemanId)}, conn, "SELECT id FROM mechanic_shops WHERE mekanik_ismi=?", elemanIsim)
end)

-- ==========================================
-- İstemciden gelen giriş yapma isteği
-- ==========================================
addEvent("tableteGirisYap", true)
addEventHandler("tableteGirisYap", resourceRoot, function(isim, sifre)
    local player = client
    local conn = getDB()
    if not conn then
        outputChatBox("Veritabanı bağlantısı yok, yetkiliye bildirin.", player, 255, 0, 0)
        return
    end

    local hashedSifre = hash("sha256", sifre)

    dbQuery(function(qh, plyr)
        local sonuc = dbPoll(qh, 0)
        if sonuc and #sonuc > 0 then
            local hesap = sonuc[1]

            -- Oturum bilgisini oyuncu üzerinde tutuyoruz (her sorguda tekrar login aramamak için).
            setElementData(plyr, "tablet:sahibi", hesap.sahibi, false)
            setElementData(plyr, "tablet:eleman", hesap.eleman == 1, false)

            triggerClientEvent(plyr, "tabletGirisBasarili", resourceRoot, {
                sahibi = hesap.sahibi,
                eleman = (hesap.eleman == 1),
                dutyX = hesap.duty_x,
                dutyY = hesap.duty_y,
                dutyZ = hesap.duty_z,
            })
            outputChatBox("Tablete başarıyla giriş yaptınız!", plyr, 0, 255, 0)
        else
            outputChatBox("Hata: Mekanik ismi veya şifre hatalı!", plyr, 255, 0, 0)
        end
    end, {player}, conn,
        "SELECT sahibi, eleman, duty_x, duty_y, duty_z FROM mechanic_shops WHERE mekanik_ismi=? AND sifresi=?",
        isim, hashedSifre)
end)

-- ==========================================
-- Duty konumu ayarlama (sadece dükkan sahibi)
-- ==========================================
addEvent("tablet:dutyAyarla", true)
addEventHandler("tablet:dutyAyarla", resourceRoot, function()
    local player = client
    local sahibi = getElementData(player, "tablet:sahibi")
    local elemanMi = getElementData(player, "tablet:eleman")

    if not sahibi then
        outputChatBox("Önce tablete giriş yapmalısın.", player, 255, 0, 0)
        return
    end
    if elemanMi then
        outputChatBox("Sadece dükkan sahibi duty noktası ayarlayabilir!", player, 255, 0, 0)
        return
    end

    local conn = getDB()
    if not conn then return end

    local x, y, z = getElementPosition(player)
    dbExec(conn, "UPDATE mechanic_shops SET duty_x=?, duty_y=?, duty_z=? WHERE sahibi=? AND eleman IS NULL", x, y, z, sahibi)
    triggerClientEvent(player, "duty:depoKonumuGuncellendi", resourceRoot, x, y, z)
    outputChatBox("Duty noktası buraya kaydedildi.", player, 0, 255, 0)
end)

-- ==========================================================================
-- EXPORT EDİLEN FONKSİYONLAR
-- Bu fonksiyonlar meta.xml'de <export> ile tanımlıdır, başka kaynaklardan
-- şu şekilde çağrılır:  exports.mechanic_tablet:fonksiyonAdi(parametreler)
-- (mechanic_tablet yerine bu kaynağın gerçek klasör/resource adını yaz)
-- ==========================================================================

-- --------------------------------------------------------------------------
-- drpGetPartPrice(partType, level)
-- AÇIKLAMA : Belirtilen parça tipi ve seviyesinin güncel fiyatını döndürür.
--            Fiyatlar config.lua > CONFIG.PARCA_FIYATLARI üzerinden okunur,
--            böylece başka bir kaynak (ör. bir ekonomi/loglama sistemi)
--            fiyatları tekrar tanımlamak zorunda kalmaz.
-- PARAM    : partType (string)  -> "motor" | "fren" | "turbo" | "sanziman"
--            level (number)     -> Parçanın seviyesi (1, 2, 3...)
-- DÖNÜŞ    : number -> Fiyat (₺). Tanımsız parça/seviye ise 0 döner.
-- ÖRNEK    : exports.mechanic_tablet:drpGetPartPrice("motor", 2) -> 9000
-- --------------------------------------------------------------------------
function drpGetPartPrice(partType, level)
    return CONFIG.parcaFiyatiGetir(partType, level)
end

-- --------------------------------------------------------------------------
-- drpGetShopOwner(player)
-- AÇIKLAMA : Oyuncunun tablette giriş yaptığı dükkanın sahibi kimse onun
--            ismini döndürür. Örneğin başka bir kaynağın "bu oyuncu
--            hangi mekanik dükkanına bağlı" bilgisine ihtiyacı olduğunda
--            (ör. görev sistemi, maaş sistemi) kullanılır.
-- PARAM    : player (element) -> Bilgisi sorgulanacak oyuncu
-- DÖNÜŞ    : string | false -> Dükkan sahibinin ismi, giriş yapılmamışsa false
-- ÖRNEK    : exports.mechanic_tablet:drpGetShopOwner(source)
-- --------------------------------------------------------------------------
function drpGetShopOwner(player)
    if not player or not isElement(player) then return false end
    return getElementData(player, "tablet:sahibi") or false
end

-- --------------------------------------------------------------------------
-- drpIsShopEmployee(player)
-- AÇIKLAMA : Oyuncu tablete dükkan sahibi olarak değil, ELEMAN olarak mı
--            giriş yapmış onu söyler. Yetki kontrolü gereken dış
--            sistemlerde (ör. sadece sahibin yapabileceği bir işlem)
--            kullanılabilir.
-- PARAM    : player (element)
-- DÖNÜŞ    : boolean -> true = eleman, false = sahibi veya giriş yok
-- ÖRNEK    : exports.mechanic_tablet:drpIsShopEmployee(source)
-- --------------------------------------------------------------------------
function drpIsShopEmployee(player)
    if not player or not isElement(player) then return false end
    return getElementData(player, "tablet:eleman") == true
end

-- --------------------------------------------------------------------------
-- drpParcaTak(player, vehicle, partType, level)
-- AÇIKLAMA : *** PLACEHOLDER (İSKELET) FONKSİYON ***
--            Satın alınan/seçilen parçanın araca gerçekten takılması
--            (ör. handling değişikliği, motor/fren/turbo/şanzıman
--            istatistiklerinin uygulanması, veritabanına araç upgrade
--            kaydı yazılması vb.) mantığı BURAYA gelecek.
--            Bu mantık henüz tanımlanmadı; asıl işlevi ayrıca
--            anlatılıp doldurulacak. Şimdilik sadece güvenli bir
--            "iskelet" olarak duruyor: hiçbir şeyi bozmadan çağrılabilir,
--            ama gerçek bir işlem yapmaz.
-- PARAM    : player (element)   -> İşlemi başlatan oyuncu (mekanik/eleman)
--            vehicle (element)  -> Parçanın takılacağı araç
--            partType (string)  -> "motor" | "fren" | "turbo" | "sanziman"
--            level (number)     -> Takılacak parçanın seviyesi
-- DÖNÜŞ    : boolean -> Şimdilik her zaman false (henüz gerçek işlem yok)
-- ÖRNEK    : exports.mechanic_tablet:drpParcaTak(source, araç, "motor", 2)
-- --------------------------------------------------------------------------
function drpParcaTak(player, vehicle, partType, level)
    if not isElement(player) or not isElement(vehicle) then return false end
    level = tonumber(level) or 1

    -- Tablet parçası -> tuning parçası eşlemesi (config.lua > CONFIG.PARCA_ESLEME)
    local parcaAdi = CONFIG.tuningParcasiGetir(partType, level)
    if not parcaAdi then
        outputChatBox("[Parça Takma] Geçersiz parça/seviye: " .. tostring(partType) .. " " .. tostring(level), player, 255, 0, 0)
        return false
    end

    -- Zaten takılı mı?
    local takili = getElementData(vehicle, "takili_parcalar") or {}
    for _, p in ipairs(takili) do
        if p == parcaAdi then
            outputChatBox("[Parça Takma] " .. parcaAdi .. " bu araçta zaten takılı.", player, 255, 200, 0)
            return false
        end
    end

    -- Tuning sistemine işle: veri + handling + veritabanı (server.lua içindeki fonksiyonlar)
    table.insert(takili, parcaAdi)
    setElementData(vehicle, "takili_parcalar", takili)
    parcalariKaydet(vehicle)
    araciGuncelle(vehicle, takili)

    outputChatBox("[Parça Takma] " .. parcaAdi .. " araca takıldı. (" .. partType .. " Seviye " .. level .. ")", player, 0, 255, 0)
    local surucu = getVehicleOccupant(vehicle)
    if isElement(surucu) and surucu ~= player then
        outputChatBox("[Stage Tuning] Aracınıza " .. parcaAdi .. " takıldı.", surucu, 0, 255, 0)
    end
    return true
end

-- ==========================================
-- /parcatak KOMUTU
-- Yakındaki araca, tablette seçilen/satın alınan parçayı takmayı dener.
-- Gerçek takma mantığı drpParcaTak() içinde tanımlanacak (şu an placeholder).
-- ==========================================
addCommandHandler(CONFIG.KOMUTLAR.parcaTak, function(player, cmd, partType, level)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        -- Araçta değilse en yakın aracı bul (kumanda.lua'daki mantıkla aynı yaklaşım)
        local px, py, pz = getElementPosition(player)
        local minDist, yakinArac = 6, nil -- 6 birim menzil
        for _, veh in ipairs(getElementsByType("vehicle")) do
            local vx, vy, vz = getElementPosition(veh)
            local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
            if dist < minDist then
                minDist = dist
                yakinArac = veh
            end
        end
        vehicle = yakinArac
    end

    if not vehicle then
        outputChatBox("Yakında bir araç bulunamadı!", player, 255, 0, 0)
        return
    end
    if not partType then
        outputChatBox("Kullanım: /" .. CONFIG.KOMUTLAR.parcaTak .. " [parça tipi] [seviye]", player, 255, 255, 0)
        return
    end

    drpParcaTak(player, vehicle, partType, tonumber(level) or 1)
end)
