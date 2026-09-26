CONFIG = {
    -- ID üstte görünsün mü
    BAS_USTU_GOSTER = true,
    MAX_MESAFE = 40,          -- kaç metreden görünür
    YAZI_RENK = tocolor(255, 255, 255, 255),
    YAZI_CERCEVE = tocolor(0, 0, 0, 200),

    -- Hesap ID'si için stage_mysql kullan (yoksa oturum ID'si verilir)
    MYSQL_KULLAN = true,
    TABLO = "player_ids",     -- kalıcı hesap ID tablosu

    BASLANGIC_ID = 1000,      -- ilk hesap ID'si
}
