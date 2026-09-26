--[[
    ==========================================================
    config.lua  (SHARED — hem client hem server bu dosyayı okur)
    DRP Performans Tablet - Merkezi Ayar Dosyası
    ==========================================================
    Buradaki değerleri değiştirerek kodun içine hiç girmeden
    komutları, fiyatları ve mesafeleri yönetebilirsin.
    meta.xml'de bu dosya client.lua/server.lua/depo.lua'dan
    ÖNCE yüklenmeli, aksi halde CONFIG tablosu boş gelir.
]]

CONFIG = {}

-- ==========================================
-- KOMUTLAR
-- Bir komutu değiştirmek istersen sadece buradaki metni değiştir,
-- diğer dosyalarda hiçbir şey elleme.
-- ==========================================
CONFIG.KOMUTLAR = {
    tabletAc   = "tablet",     -- Tableti elle aç/kapa: /tablet
    parcaTak   = "parcatak",   -- Yakındaki araca seçili/satın alınan parçayı takar: /parcatak (işlevi henüz PLACEHOLDER, aşağıda açıklandı)
    tabletKur  = "tabletkur",  -- Dükkan sahibi tablet hesabı açar: /tabletkur [Mekanik İsmi] [Şifre] [Sahibi] [ID]
    elemanEkle = "elemanekle", -- Dükkan sahibi eleman hesabı açar: /elemanekle [Eleman İsmi] [Şifre] [ID]
    depoEkle   = "depoekle",   -- (Admin/Test) Depoya elle eşya ekler: /depoekle [slot] [eşya adı] [miktar]
}

-- ==========================================
-- PARÇA FİYATLARI
-- client.lua sepet/anahtar ekranı ve server.lua fiyat doğrulaması
-- AYNI bu tablodan okur, tek yerden yönetilir.
-- ==========================================
CONFIG.PARCA_FIYATLARI = {
    motor    = { 5000, 9000, 14000, 20000 }, -- Seviye 1-4
    fren     = { 3000, 6000, 10000 },        -- Seviye 1-3
    turbo    = { 12000 },                    -- Tek seviye
    sanziman = { 4000, 8000, 13000, 18000 }, -- Seviye 1-4
}

-- ==========================================
-- DUTY / DEPO (ENVANTER) AYARLARI
-- ==========================================
CONFIG.DUTY_MENZILI        = 3.5 -- [E] ile envanteri açmak için duty konumuna gereken mesafe (birim)
CONFIG.DUTY_PROMPT_MENZILI = 8   -- Dünya üzerinde "Depo [E]" yazısının görünmeye başladığı mesafe
CONFIG.DEPO_SLOT_SAYISI    = 40  -- Envanterdeki toplam slot sayısı (client.lua grid'iyle birebir aynı olmalı)

-- ==========================================
-- PARÇA FİYATI SORGULAMA (yardımcı fonksiyon, hem client hem server kullanabilir)
-- Kullanım: CONFIG.parcaFiyatiGetir("motor", 2) -> 9000
-- ==========================================
function CONFIG.parcaFiyatiGetir(partType, level)
    local liste = CONFIG.PARCA_FIYATLARI[partType]
    if not liste then return 0 end
    return liste[level] or 0
end

-- ==========================================
-- TABLET PARÇASI  ->  TUNING PARÇASI EŞLEMESİ
-- (birleşme sonrası eklendi)
-- Tablet dükkanından /parcatak ile takılan parça, tuning sisteminin
-- (client.lua / server.lua "Performans" tablosu) parça isimlerine çevrilir.
-- Böylece takılan parça gerçekten handling'i değiştirir ve
-- arac_parcalar tablosuna kaydedilir.
-- Buradaki isimler tuning ürün listesiyle BİREBİR aynı olmalı.
-- ==========================================
CONFIG.PARCA_ESLEME = {
    motor    = { "Stage 1", "Stage 2", "Stage 3", "Dövme Piston" },
    turbo    = { "Hibrit Turbo" },
    sanziman = { "Kısa Şanzıman", "Bronz Debriyaj", "Kilitli Diferansiyel", "Drift Kiti" },
    -- NOT: Tuning listesinde ayrı bir "fren" parçası yok. Şimdilik en yakın
    -- karşılıkları eşledim; istersen buradaki isimleri değiştirebilirsin.
    fren     = { "Çelik Saplama", "Çelik Gömlek", "Downpipe" },
}

-- Kullanım: CONFIG.tuningParcasiGetir("motor", 2) -> "Stage 2"
function CONFIG.tuningParcasiGetir(partType, level)
    local liste = CONFIG.PARCA_ESLEME[partType]
    if not liste then return nil end
    return liste[tonumber(level) or 1]
end
