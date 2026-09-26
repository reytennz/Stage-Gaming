-- depo.lua (Server-side)
-- Dükkan başına depo (envanter) verisi. drp_mysql paylaşılan bağlantısı kullanılır.
-- Veri "sahibi" (dükkan sahibinin ismi) üzerinden izole edilir; sahibi + eleman aynı depoyu görür,
-- böylece farklı dükkanların depoları birbirine karışmaz.

local function getDB()
    return exports.stage_mysql:getConnection()
end

addEventHandler("onResourceStart", resourceRoot, function()
    local conn = getDB()
    if not conn then return end

    dbExec(conn, [[
        CREATE TABLE IF NOT EXISTS mechanic_depo (
            id INT NOT NULL AUTO_INCREMENT,
            sahibi VARCHAR(64) NOT NULL,
            slot INT NOT NULL,
            esya VARCHAR(64) DEFAULT NULL,
            miktar INT DEFAULT 0,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_sahibi_slot (sahibi, slot)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- ==========================================
-- Depo verisini çekme
-- Performans notu: tablet her açıldığında TEK sorgu atılır, sonuç client'ta cache'lenir.
-- Slot başına ayrı sorgu YOK.
-- ==========================================
addEvent("depoVerisiniCek", true)
addEventHandler("depoVerisiniCek", resourceRoot, function()
    local player = client
    local sahibi = getElementData(player, "tablet:sahibi")
    if not sahibi then
        outputChatBox("Önce tablete giriş yapmalısın.", player, 255, 0, 0)
        return
    end

    local conn = getDB()
    if not conn then return end

    dbQuery(function(qh, plyr)
        local sonuc = dbPoll(qh, 0)
        local esyalar = {}
        if sonuc then
            for _, row in ipairs(sonuc) do
                if row.esya and row.esya ~= "" then
                    esyalar["inv_slot" .. row.slot] = {
                        name = row.esya,
                        miktar = tonumber(row.miktar) or 0,
                    }
                end
            end
        end
        triggerClientEvent(plyr, "depoyuGuncelle", resourceRoot, esyalar)
    end, {player}, conn, "SELECT slot, esya, miktar FROM mechanic_depo WHERE sahibi=?", sahibi)
end)

-- ==========================================
-- Eşya işlemi (kullan / al vb.)
-- slotID örn: "inv_slot1"  ->  slot no: 1
-- ==========================================
addEvent("esyaIslemiYap", true)
addEventHandler("esyaIslemiYap", resourceRoot, function(slotID, islem)
    local player = client
    local sahibi = getElementData(player, "tablet:sahibi")
    if not sahibi then return end

    local slotNo = tonumber(tostring(slotID):match("%d+"))
    if not slotNo then return end

    local conn = getDB()
    if not conn then return end

    if islem == "al" or islem == "kullan" then
        -- Depodan 1 adet düşülür, 0'ın altına inmez.
        dbExec(conn, "UPDATE mechanic_depo SET miktar = GREATEST(miktar - 1, 0) WHERE sahibi=? AND slot=?", sahibi, slotNo)
        -- NOT: Eşyanın oyuncuya ne şekilde verileceği (item sistemi, silah, para vb.)
        -- projenin envanter/eşya sistemine göre burada eklenmeli. Şimdilik miktar güncelleniyor.
    end

    outputChatBox("İşlem yapıldı: " .. slotID, player)

    -- Güncel depo verisini tekrar client'a gönder (tek sorgu).
    dbQuery(function(qh, plyr)
        local sonuc = dbPoll(qh, 0)
        local esyalar = {}
        if sonuc then
            for _, row in ipairs(sonuc) do
                if row.esya and row.esya ~= "" then
                    esyalar["inv_slot" .. row.slot] = { name = row.esya, miktar = tonumber(row.miktar) or 0 }
                end
            end
        end
        triggerClientEvent(plyr, "depoyuGuncelle", resourceRoot, esyalar)
    end, {player}, conn, "SELECT slot, esya, miktar FROM mechanic_depo WHERE sahibi=?", sahibi)
end)

-- ==========================================
-- Depoya eşya ekleme (admin/yönetici komutu, test amaçlı)
-- /depoekle [slot] [esya adı] [miktar]
-- ==========================================
addCommandHandler(CONFIG.KOMUTLAR.depoEkle, function(player, cmd, slot, esyaAdi, miktar)
    local sahibi = getElementData(player, "tablet:sahibi")
    if not sahibi then
        outputChatBox("Önce tablete giriş yapmalısın.", player, 255, 0, 0)
        return
    end
    if not slot or not esyaAdi then
        outputChatBox("Kullanım: /" .. CONFIG.KOMUTLAR.depoEkle .. " [slot no] [eşya adı] [miktar]", player, 255, 255, 0)
        return
    end

    local conn = getDB()
    if not conn then return end

    dbExec(conn, [[
        INSERT INTO mechanic_depo (sahibi, slot, esya, miktar) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE esya=VALUES(esya), miktar=VALUES(miktar)
    ]], sahibi, tonumber(slot), esyaAdi, tonumber(miktar) or 1)

    outputChatBox("Depoya eklendi: " .. esyaAdi, player, 0, 255, 0)
end)
