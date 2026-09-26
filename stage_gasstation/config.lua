Config = {
    -- Genel
    Language = "tr",
    Currency = "$",
    AdminACL = "Admin",
    -- Admin menü kodu (paylaşılabilir). /benzinlikler KOD ile açılır.
    -- Boş bırakırsan sadece ACL Admin açabilir.
    AdminCode = "benzin2026",
    StateOwnerName = "Devlet",

    -- Varsayılan değerler
    DefaultBuyPrice = 750000,
    DefaultPetrolPrice = 48,
    DefaultDieselPrice = 52,
    DefaultPetrolBuy = 40,
    DefaultDieselBuy = 43,
    DefaultPetrolStock = 2000,
    DefaultDieselStock = 2000,

    -- Benzinlik (admin oluşturur, oyuncu satılık alır → sale_price)
    MaxStations = 6,

    -- Ek marker (sahip panelinden, aynı işletmeye bağlı)
    -- Ana konum = 1 marker (bedava). Ek marker: 2. = 10.000, sonrası = 150.000, max 6
    MaxMarkersPerStation = 6,
    MarkerPriceFirstExtra = 10000,   -- 2. marker
    MarkerPriceNext = 150000,        -- 3. ve sonrası

    -- Seviye sistemi
    Levels = {
        [1] = { name = "Seviye 1 - Küçük", capacityPetrol = 5000,  capacityDiesel = 5000,  maxProducts = 5,  upgradeCost = 0 },
        [2] = { name = "Seviye 2 - Orta",  capacityPetrol = 10000, capacityDiesel = 10000, maxProducts = 8,  upgradeCost = 250000 },
        [3] = { name = "Seviye 3 - Büyük", capacityPetrol = 20000, capacityDiesel = 20000, maxProducts = 12, upgradeCost = 500000 },
        [4] = { name = "Premium",         capacityPetrol = 50000, capacityDiesel = 50000, maxProducts = 20, upgradeCost = 1000000 },
    },

    -- Marker / Blip
    BlipID = 42,
    SaleBlipID = 52,
    MarkerSize = 1.8,
    MarkerColorOwned = {0, 210, 90, 120},
    MarkerColorSale  = {255, 170, 30, 140},
    MarkerColorState = {40, 140, 255, 120},

    -- Yakıt
    FuelTypes = {
        petrol = { name = "Benzin", key = "petrol" },
        diesel = { name = "Dizel",  key = "diesel" },
    },

    -- Market varsayılan ürünler
    DefaultProducts = {
        { name = "Su",              buy = 5,  sell = 12, stock = 50 },
        { name = "Kola",            buy = 8,  sell = 18, stock = 40 },
        { name = "Enerji İçeceği",  buy = 12, sell = 25, stock = 30 },
        { name = "Sandviç",         buy = 15, sell = 30, stock = 25 },
        { name = "Çikolata",        buy = 6,  sell = 14, stock = 40 },
        { name = "Cips",            buy = 7,  sell = 16, stock = 35 },
        { name = "Kahve",           buy = 10, sell = 22, stock = 30 },
    },

    -- Reklam
    AdInterval     = 180000,   -- 3 dakika
    AdMaxDuration  = 7200,     -- 2 saat
    AdMinBudget    = 5000,
    AdMinDuration  = 300,      -- 5 dakika

    -- Performans / Güncelleme
    UpdateInterval = 60000,    -- 60 saniye (reklam + istatistik)
    MinStockWarning = 500,     -- litre altında uyarı

    -- MySQL
    MySQL = {
        host     = "localhost",
        dbname   = "stage",
        user     = "root",
        password = "R.yakup.12345",
        port     = 3306,
    },
}
