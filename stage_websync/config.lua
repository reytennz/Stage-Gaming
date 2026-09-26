StageWebConfig = {
    enabled = true,

    -- Web sitendeki /api/mta_sync.php adresi.
    url = "https://stage.gt.tc/api/mta_sync.php",

    -- Sitedeki config/site.php icindeki MTA_SYNC_KEY ile AYNI olmali.
    -- Guvenlik icin burada gercek anahtar bulunmuyor.
    key = "zkZbe_B7M0BYF7r4csmVx0nttlXHaQWoG0Lbl57hE6E",

    -- Ilk snapshot resource basladiktan sonra gonderilir.
    startupDelay = 5000,

    -- Canli sunucu bilgisi.
    heartbeatInterval = 15000,

    -- Hesap + karakter + admin log snapshot'i.
    snapshotInterval = 60000,

    requestTimeout = 10000,
    debug = true,
}
