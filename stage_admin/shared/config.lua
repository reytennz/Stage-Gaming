--[[
    stage_admin - shared config
    Bu dosya client + server tarafından ortak okunur.
]]

Config = {}

-- ==========================================================
-- GENEL
-- ==========================================================
Config.PanelKey        = "F5"      -- Admin panel açma tuşu
Config.ReportKey       = "F3"      -- Report panel açma tuşu
Config.ChatCommand     = "a"       -- /a admin chat

Config.ResourceName    = "stage_admin"

-- ==========================================================
-- SABİT OWNER LİSTESİ
-- Buraya serial eklenen oyuncu, panelden/komuttan rütbesi
-- değiştirilse bile HER ZAMAN Owner olarak görünür.
-- Serial'ı öğrenmek için oyun içinde: /myrank (adminlevel ile birlikte serial de loglanır)
-- ya da server konsolunda "showserial <isim>" tarzı bir komut yoksa
-- /myrank çıktısındaki bilgiyi kullan.
-- ==========================================================
Config.Owners = {
  "3952D6701949192C60CAC76454D15970",
}

-- ==========================================================
-- RANK SİSTEMİ
-- Sıra önemli: index ne kadar büyükse yetki o kadar yüksek.
-- stage_core IsAdmin() true dönen ama elementData'sı olmayan
-- oyuncular otomatik "Admin" kabul edilir (bkz server/permissions.lua)
-- ==========================================================
Config.Ranks = {
    "User",
    "Moderator",
    "Admin",
    "SuperAdmin",
    "Developer",
    "Owner",
}

-- Her rankın kullanabileceği izinler.
-- "*" o rankın (ve üzerinin) her şeye yetkili olduğu anlamına gelir.
Config.Permissions = {
    Moderator = {
        "panel.open",
        "players.list",
        "kick", "warn", "freeze", "unfreeze",
        "goto", "gethere", "spectate",
        "invisible",
        "achat",
        "report.view", "report.claim", "report.close", "report.note",
    },

    Admin = {
        "kick", "ban", "unban", "warn", "unwarn",
        "freeze", "unfreeze", "goto", "gethere", "tpto",
        "spectate", "invisible", "time",
        "deletevehicle", "deleteallvehicles",
        "givemoney", "giveitem", "givevehicle",
        "achat", "announce",
        "report.view", "report.claim", "report.close", "report.note",
        "event.view",
        "log.view",
    },

    SuperAdmin = {
        "noclip", "fly", "god",
        "temprank", "removerank",
        "event.create", "event.manage",
        "anticheat.view", "anticheat.manage",
        "ban.history", "warn.history",
        "resource.view",
    },

    Developer = { "*" },
    Owner     = { "*" },
}

-- ==========================================================
-- BAN SÜRELERİ (panelde hızlı seçim için, saniye cinsinden)
-- ==========================================================
Config.BanDurations = {
    { label = "10 Dakika", seconds = 60 * 10 },
    { label = "1 Saat",    seconds = 60 * 60 },
    { label = "1 Gün",     seconds = 60 * 60 * 24 },
    { label = "7 Gün",     seconds = 60 * 60 * 24 * 7 },
    { label = "30 Gün",    seconds = 60 * 60 * 24 * 30 },
    { label = "Süresiz",   seconds = 0 },
}

-- ==========================================================
-- REPORT KATEGORİLERİ
-- ==========================================================
Config.ReportReasons = {
    "Hile",
    "Oyuncu Şikayeti",
    "Bug",
    "Admin Şikayeti",
    "Diğer",
}

-- ==========================================================
-- DUYURU TİPLERİ
-- ==========================================================
Config.AnnounceTypes = {
    duyuru  = { label = "DUYURU",  color = { 90, 160, 255 } },
    uyari   = { label = "UYARI",   color = { 255, 120, 90 } },
    bilgi   = { label = "BİLGİ",   color = { 120, 200, 255 } },
    oneri   = { label = "ÖNERİ",   color = { 170, 255, 150 } },
    hata    = { label = "HATA",    color = { 255, 80, 80 } },
}

-- ==========================================================
-- ANTI-CHEAT
-- ==========================================================
Config.AntiCheat = {
    speed     = true,
    fly       = true,
    godmode   = true,
    teleport  = true,
    weapon    = true,
    vehicle   = true,
    explosion = true,
    eventAbuse    = true,
    resourceAbuse = true,
}

-- Her modülün varsayılan aksiyonu: "log" | "warn" | "kick" | "ban"
-- Kritik olmayan tespitlerde asla direkt "ban" kullanma.
Config.AntiCheatAction = {
    speed         = "warn",
    fly           = "warn",
    godmode       = "log",
    teleport      = "warn",
    weapon        = "log",
    vehicle       = "warn",
    explosion     = "warn",
    eventAbuse    = "log",
    resourceAbuse = "log",
}

-- Aynı modülün art arda tetiklenmesinde ne kadar tespitten sonra
-- bir üst seviyeye (warn->kick->ban) otomatik yükseltme yapılsın.
-- 0 = otomatik yükseltme yok, sadece configteki aksiyon uygulanır.
Config.AntiCheatEscalation = {
    speed    = 5,
    fly      = 5,
    teleport = 5,
    vehicle  = 5,
}

-- Toleranslar (false-positive azaltmak için)
-- Hassasiyet seviyesini buradan tek satırla değiştir: "hafif" | "normal" | "siki"
--   hafif -> daha az false-positive, hileleri geç yakalar
--   siki  -> hileleri hızlı yakalar, false-positive riski artar
Config.AntiCheatSensitivity = "normal"

Config.AntiCheatSensitivityPresets = {
    hafif = {
        speedMultiplier  = 1.65,  -- normal hız * bu katsayıdan fazlası şüpheli
        teleportDistance = 90,
        explosionRadius  = 5,
    },
    normal = {
        speedMultiplier  = 1.35,
        teleportDistance = 60,
        explosionRadius  = 3,
    },
    siki = {
        speedMultiplier  = 1.15,
        teleportDistance = 40,
        explosionRadius  = 2,
    },
}

Config.AntiCheatTolerance = Config.AntiCheatSensitivityPresets[Config.AntiCheatSensitivity]
    or Config.AntiCheatSensitivityPresets.normal

-- ==========================================================
-- ITEM / ARAÇ HIZLI SEÇİM (panel dropdown için, opsiyonel liste)
-- Not: gerçek item listesi stage_inventory'den (shared/items.lua) çekilir,
-- bu sadece fallback / araç listesi.
-- ==========================================================
Config.QuickVehicles = {
    { id = 411, name = "Infernus" },
    { id = 451, name = "Turismo" },
    { id = 522, name = "NRG-500" },
    { id = 496, name = "Blista Compact" },
    { id = 579, name = "Club" },
}
