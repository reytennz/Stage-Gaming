local sx, sy = guiGetScreenSize()
local _cw, _ch = 2560, 1440
local scaleX, scaleY = sx / _cw, sy / _ch
local _scale = math.min(scaleX, scaleY)
local _offX  = (sx - _cw * _scale) / 2
local _offY  = (sy - _ch * _scale) / 2
local rounded = {}
local circles  = {}

local selectedPayment = "nakit" -- Varsayılan: Nakit
local cartItems = {}
local totalPrice = 0

-- PARÇA FİYATLARI artık config.lua > CONFIG.PARCA_FIYATLARI içinden okunuyor
-- (server.lua ile aynı kaynaktan geldiği için ayrı ayrı güncellemeye gerek yok).
local partPrices = CONFIG.PARCA_FIYATLARI

local function getPartPrice(partType, level)
    return (partPrices[partType] and partPrices[partType][level]) or 0
end

-- NOT: Tableti açma/kapatma mantığı (tabletAcik, girisYapildi ve toggleTablet())
-- dosyanın en altında, uiElements tanımlandıktan SONRA tanımlı. Böylece
-- /tablet komutu ve tablet:open/tablet:useItem event'leri aynı tek state'i kullanıyor.

local function getIconTexture(name) return nil end

local function toggleGroup(groupId, visible)
    for _, v in ipairs(uiElements) do
        if v.groupId == groupId then
            v.visible = visible
        end
    end
end

local uiElements = {
    -- ========================================================
    -- 1. TABLET ÇERÇEVESİ (FRAME_UI) - BEYAZ BAR BURADA
    -- ========================================================
    { id = "dıssiyahkapak", type = "rectangle", x = 292, y = 157, w = 1976, h = 1126, color = { 12, 12, 14, 255 }, radius = 80, visible = true, groupId = "frame_ui" },
    { id = "ekrandıscerceve", type = "rectangle", x = 300, y = 165, w = 1960, h = 1110, color = { 65, 68, 75, 255 }, radius = 72, visible = true, groupId = "frame_ui" },
    { id = "ekran", type = "image", x = 312, y = 177, w = 1936, h = 1086, imagePath = "assets/tablet_bg.png", color = { 255, 255, 255, 255 }, radius = 60, visible = true, groupId = "frame_ui" },
    { id = "ahizebar", type = "rectangle", x = 332, y = 192, w = 1896, h = 45, color = { 0, 0, 0, 100 }, radius = 22, visible = true, groupId = "frame_ui_top" },
    { id = "sol yazı", type = "label", x = 360, y = 192, w = 400, h = 45, text = "Drp Performans", fontScale = 1.2, font = "default-bold", alignX = "left", alignY = "center", textColor = { 255, 255, 255, 240 }, shadowColor = { 0, 0, 0, 200 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "frame_ui_top" },
    { id = "sağ yazı", type = "label", x = 1620, y = 192, w = 600, h = 45, text = "WiFi ‧ ‧ ‧ ‧", fontScale = 1.2, font = "default-bold", alignX = "right", alignY = "center", textColor = { 255, 255, 255, 240 }, shadowColor = { 0, 0, 0, 200 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "frame_ui_top" },
    { id = "kamera", type = "circle", x = 1270, y = 235, w = 20, h = 20, color = { 5, 5, 8, 255 }, visible = true, groupId = "frame_ui_top" },
    
    -- BEYAZ BAR (HOME BAR) - HEMEN HEMEN HER YERDE GÖRÜNÜR
    { id = "ortatus", type = "rectangle", x = 1130, y = 1245, w = 300, h = 8, color = { 255, 255, 255, 220 }, radius = 4, visible = true, groupId = "frame_ui_top" },

    -- ========================================================
    -- 2. ANA EKRAN UYGULAMALARI (HOME_UI)
    -- ========================================================
    { id = "market", type = "image", x = 370, y = 270, w = 140, h = 140, imagePath = "assets/market.png", color = { 255, 255, 255, 255 }, radius = 24, visible = true, groupId = "home_ui" },
    { id = "label_106", type = "label", x = 370, y = 425, w = 140, h = 30, text = "Parça Dükkanı", fontScale = 1.3, font = "default-bold", alignX = "center", alignY = "top", textColor = { 255, 255, 255, 255 }, shadowColor = { 0, 0, 0, 190 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "home_ui" },

    { id = "app_duty", type = "image", x = 550, y = 270, w = 140, h = 140, imagePath = "assets/duty.png", color = { 255, 255, 255, 255 }, radius = 24, visible = true, groupId = "home_ui" },
    { id = "label_duty", type = "label", x = 550, y = 425, w = 140, h = 30, text = "Duty", fontScale = 1.3, font = "default-bold", alignX = "center", alignY = "top", textColor = { 255, 255, 255, 255 }, shadowColor = { 0, 0, 0, 190 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "home_ui" },

    { id = "app_key", type = "image", x = 730, y = 270, w = 140, h = 140, imagePath = "assets/key.png", color = { 255, 255, 255, 255 }, radius = 24, visible = true, groupId = "home_ui" },
    { id = "label_key", type = "label", x = 730, y = 425, w = 140, h = 30, text = "Anahtar", fontScale = 1.3, font = "default-bold", alignX = "center", alignY = "top", textColor = { 255, 255, 255, 255 }, shadowColor = { 0, 0, 0, 190 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "home_ui" },

    { id = "app_settings", type = "image", x = 910, y = 270, w = 140, h = 140, imagePath = "assets/settings.png", color = { 255, 255, 255, 255 }, radius = 24, visible = true, groupId = "home_ui" },
    { id = "label_settings", type = "label", x = 910, y = 425, w = 140, h = 30, text = "Ayarlar", fontScale = 1.3, font = "default-bold", alignX = "center", alignY = "top", textColor = { 255, 255, 255, 255 }, shadowColor = { 0, 0, 0, 190 }, shadowOffsetX = 1, shadowOffsetY = 1, visible = true, groupId = "home_ui" },

    -- ========================================================
    -- 3. PARÇA DÜKKANI (MARKET_UI) - İÇERİK EKLENDİ
    -- ========================================================
    { id = "market_bg", type = "rectangle", x = 312, y = 177, w = 1936, h = 1086, color = { 15, 17, 22, 255 }, radius = 60, visible = false, groupId = "market_ui" },
    { id = "market_left_box", type = "rectangle", x = 340, y = 230, w = 580, h = 980, color = { 22, 25, 34, 255 }, radius = 20, visible = false, groupId = "market_ui" },
    { id = "market_right_box", type = "rectangle", x = 940, y = 230, w = 1280, h = 980, color = { 22, 25, 34, 255 }, radius = 20, visible = false, groupId = "market_ui" },
    { id = "market_back_btn", type = "label", x = 370, y = 280, w = 150, h = 40, text = "← Geri", fontScale = 1.3, alignX = "left", alignY = "center", textColor = { 180, 180, 190, 255 }, visible = false, groupId = "market_ui" },
    { id = "market_main_title", type = "label", x = 560, y = 280, w = 400, h = 40, text = "Parça Dükkanı", fontScale = 1.6, alignX = "left", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- SOL PANEL (GÖREV DURUMU)
    { id = "depo_title", type = "label", x = 360, y = 350, w = 540, h = 30, text = "DEPO & GÖREV DURUMU", fontScale = 0.9, alignX = "left", textColor = { 140, 140, 150, 255 }, visible = false, groupId = "market_ui" },
    { id = "depo_status", type = "label", x = 390, y = 390, w = 500, h = 50, text = "Duty Durumu: KAPALI", fontScale = 1.2, alignX = "left", textColor = { 255, 100, 100, 255 }, visible = false, groupId = "market_ui" },

    -- SAĞ PANEL (PARÇA LİSTESİ)
    { id = "parts_title", type = "label", x = 970, y = 350, w = 1240, h = 30, text = "PARÇA LİSTESİ", fontScale = 1, alignX = "left", textColor = { 140, 140, 150, 255 }, visible = false, groupId = "market_ui" },

    -- MOTOR (Seviye 1-4)
    { id = "motor_1", type = "button", x = 970, y = 410, w = 280, h = 50, text = "Motor Seviye 1", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "motor_2", type = "button", x = 1265, y = 410, w = 280, h = 50, text = "Motor Seviye 2", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "motor_3", type = "button", x = 1560, y = 410, w = 280, h = 50, text = "Motor Seviye 3", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "motor_4", type = "button", x = 1855, y = 410, w = 280, h = 50, text = "Motor Seviye 4", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- FREN (Seviye 1-3)
    { id = "fren_1", type = "button", x = 970, y = 490, w = 280, h = 50, text = "Fren Seviye 1", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "fren_2", type = "button", x = 1265, y = 490, w = 280, h = 50, text = "Fren Seviye 2", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "fren_3", type = "button", x = 1560, y = 490, w = 280, h = 50, text = "Fren Seviye 3", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- TURBO (Tek Seviye)
    { id = "turbo_1", type = "button", x = 970, y = 570, w = 280, h = 50, text = "Turbo Takımı", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- ŞANZIMAN (Seviye 1-4)
    { id = "sanziman_1", type = "button", x = 970, y = 650, w = 280, h = 50, text = "Şanzıman Seviye 1", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "sanziman_2", type = "button", x = 1265, y = 650, w = 280, h = 50, text = "Şanzıman Seviye 2", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "sanziman_3", type = "button", x = 1560, y = 650, w = 280, h = 50, text = "Şanzıman Seviye 3", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "sanziman_4", type = "button", x = 1855, y = 650, w = 280, h = 50, text = "Şanzıman Seviye 4", fontScale = 1.1, radius = 10, color = { 45, 45, 55, 255 }, hoverColor = { 70, 70, 85, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- SEPET EKRANI (ALT SOL)
    { id = "cart_box", type = "rectangle", x = 360, y = 460, w = 540, h = 500, color = { 22, 25, 34, 255 }, radius = 20, visible = false, groupId = "market_ui" },
    { id = "cart_title", type = "label", x = 380, y = 480, w = 500, h = 40, text = "SEPETİNİZ", fontScale = 1.2, alignX = "left", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "cart_list", type = "label", x = 380, y = 530, w = 500, h = 270, text = "Sepet Boş", fontScale = 1.0, alignX = "left", alignY = "top", textColor = { 200, 200, 200, 255 }, wordBreak = true, visible = false, groupId = "market_ui" },
    { id = "cart_total", type = "label", x = 380, y = 880, w = 500, h = 40, text = "Toplam: 0 ₺", fontScale = 1.4, alignX = "center", textColor = { 255, 200, 50, 255 }, visible = false, groupId = "market_ui" },
    { id = "cart_buy_btn", type = "button", x = 660, y = 800, w = 240, h = 60, text = "Sepete Ekle", radius = 14, fontScale = 1.2, color = { 72, 199, 130, 255 }, hoverColor = { 100, 220, 160, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },
    { id = "cart_clear_btn", type = "button", x = 380, y = 800, w = 240, h = 60, text = "Sepeti Boşalt", radius = 14, fontScale = 1.2, color = { 200, 50, 50, 255 }, hoverColor = { 230, 80, 80, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "market_ui" },

    -- ========================================================
    -- 4. DUTY UYGULAMASI (DUTY_UI)
    -- ========================================================
    { id = "duty_bg", type = "rectangle", x = 312, y = 177, w = 1936, h = 1086, color = { 15, 17, 22, 255 }, radius = 60, visible = false, groupId = "duty_ui" },
    { id = "duty_back_btn", type = "label", x = 370, y = 280, w = 150, h = 40, text = "← Geri", fontScale = 1.3, alignX = "left", alignY = "center", textColor = { 180, 180, 190, 255 }, visible = false, groupId = "duty_ui" },
    { id = "duty_main_title", type = "label", x = 560, y = 280, w = 400, h = 40, text = "Duty Paneli", fontScale = 1.6, alignX = "left", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "duty_ui" },

    { id = "depo_loc_label", type = "label", x = 800, y = 350, w = 600, h = 50, text = "DEPO KONUMU", fontScale = 1.6, alignX = "center", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "duty_ui" },
    { id = "depo_current_pos", type = "label", x = 800, y = 420, w = 600, h = 40, text = "Henüz ayarlanmadı.", fontScale = 1.3, alignX = "center", alignY = "center", textColor = { 200, 200, 200, 255 }, visible = false, groupId = "duty_ui" },
    { id = "depo_find_btn", type = "button", x = 900, y = 480, w = 400, h = 60, radius = 14, text = "Depo Konumunu Bul (Otomatik)", fontScale = 1.2, color = { 25, 128, 190, 255 }, hoverColor = { 50, 150, 210, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "duty_ui" },

    { id = "duty_skin_label", type = "label", x = 800, y = 580, w = 600, h = 50, text = "Kıyafet Skin ID:", fontScale = 1.4, alignX = "center", alignY = "center", textColor = { 200, 200, 200, 255 }, visible = false, groupId = "duty_ui" },
    { id = "duty_skin_input", type = "editbox", x = 1000, y = 640, w = 200, h = 50, radius = 12, color = { 15, 17, 24, 255 }, borderColor = { 30, 35, 45, 255 }, placeholder = "Skin ID...", text = "0", alignX = "center", alignY = "center", fontScale = 1.2, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "duty_ui" },
    { id = "duty_start_btn", type = "button", x = 1000, y = 730, w = 400, h = 80, radius = 20, text = "Duty'ye Başla", fontScale = 1.5, alignX = "center", alignY = "center", color = { 72, 199, 130, 255 }, hoverColor = { 100, 220, 160, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "duty_ui" },

    -- ========================================================
    -- 5. ANAHTAR UYGULAMASI (KEY_UI)
    -- ========================================================
    { id = "key_bg", type = "rectangle", x = 312, y = 177, w = 1936, h = 1086, color = { 15, 17, 22, 255 }, radius = 60, visible = false, groupId = "key_ui" },
    { id = "key_back_btn", type = "label", x = 370, y = 280, w = 150, h = 40, text = "← Geri", fontScale = 1.3, alignX = "left", alignY = "center", textColor = { 180, 180, 190, 255 }, visible = false, groupId = "key_ui" },
    { id = "key_title", type = "label", x = 560, y = 280, w = 400, h = 40, text = "Parça Anahtarı Oluştur", fontScale = 1.6, alignX = "left", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },

    { id = "key_car_label", type = "label", x = 800, y = 380, w = 600, h = 40, text = "Araç ID", fontScale = 1.4, alignX = "center", alignY = "center", textColor = { 200, 200, 200, 255 }, visible = false, groupId = "key_ui" },
    { id = "key_car_input", type = "editbox", x = 900, y = 430, w = 400, h = 50, radius = 12, color = { 15, 17, 24, 255 }, borderColor = { 30, 35, 45, 255 }, placeholder = "Araç ID giriniz...", text = "", alignX = "center", alignY = "center", fontScale = 1.2, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },

    { id = "key_payer_label", type = "label", x = 800, y = 520, w = 600, h = 40, text = "Ödeyecek Kişi ID", fontScale = 1.4, alignX = "center", alignY = "center", textColor = { 200, 200, 200, 255 }, visible = false, groupId = "key_ui" },
    { id = "key_payer_input", type = "editbox", x = 900, y = 570, w = 400, h = 50, radius = 12, color = { 15, 17, 24, 255 }, borderColor = { 30, 35, 45, 255 }, placeholder = "Ödeyecek kişi ID'si...", text = "", alignX = "center", alignY = "center", fontScale = 1.2, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },

    { id = "key_price_label", type = "label", x = 800, y = 660, w = 600, h = 40, text = "Toplam Tutar: 0 ₺", fontScale = 1.8, alignX = "center", alignY = "center", textColor = { 255, 200, 50, 255 }, visible = false, groupId = "key_ui" },

    { id = "pay_cash_bg", type = "rectangle", x = 800, y = 730, w = 250, h = 60, radius = 12, color = { 26, 45, 42, 255 }, visible = false, groupId = "key_ui" },
    { id = "pay_cash_txt", type = "label", x = 800, y = 730, w = 250, h = 60, text = "💵 Nakit", fontScale = 1.3, alignX = "center", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },
    { id = "pay_bank_bg", type = "rectangle", x = 1100, y = 730, w = 250, h = 60, radius = 12, color = { 35, 38, 50, 255 }, visible = false, groupId = "key_ui" },
    { id = "pay_bank_txt", type = "label", x = 1100, y = 730, w = 250, h = 60, text = "🏦 Banka", fontScale = 1.3, alignX = "center", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },

    { id = "key_buy_btn", type = "button", x = 900, y = 830, w = 350, h = 70, radius = 20, text = "Anahtarı Al", fontScale = 1.3, alignX = "center", alignY = "center", color = { 25, 128, 190, 255 }, hoverColor = { 50, 150, 210, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "key_ui" },

    -- ========================================================
    -- 6. AYARLAR UYGULAMASI (SETTINGS_UI) - İÇERİK EKLENDİ
    -- ========================================================
    { id = "settings_bg", type = "rectangle", x = 312, y = 177, w = 1936, h = 1086, color = { 15, 17, 22, 255 }, radius = 60, visible = false, groupId = "settings_ui" },
    { id = "settings_back_btn", type = "label", x = 370, y = 280, w = 150, h = 40, text = "← Geri", fontScale = 1.3, alignX = "left", alignY = "center", textColor = { 180, 180, 190, 255 }, visible = false, groupId = "settings_ui" },
    { id = "settings_main_title", type = "label", x = 560, y = 280, w = 400, h = 40, text = "Ayarlar", fontScale = 1.6, alignX = "left", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "settings_ui" },
    { id = "settings_bg_label", type = "label", x = 800, y = 400, w = 600, h = 50, text = "Arka Plan Resmi Seçin", fontScale = 1.4, alignX = "center", alignY = "center", textColor = { 200, 200, 200, 255 }, visible = false, groupId = "settings_ui" },

    -- 3 ARKA PLAN SEÇENEĞİ (KÜÇÜK KARE ÖNİZLEME)
    { id = "settings_thumb_frame_0", type = "rectangle", x = 780, y = 480, w = 200, h = 200, color = { 25, 128, 190, 255 }, radius = 16, visible = false, groupId = "settings_ui" },
    { id = "settings_thumb_0", type = "image", x = 786, y = 486, w = 188, h = 188, imagePath = "assets/tablet_bg.png", color = { 255, 255, 255, 255 }, radius = 12, visible = false, groupId = "settings_ui" },

    { id = "settings_thumb_frame_1", type = "rectangle", x = 1000, y = 480, w = 200, h = 200, color = { 60, 64, 72, 255 }, radius = 16, visible = false, groupId = "settings_ui" },
    { id = "settings_thumb_1", type = "image", x = 1006, y = 486, w = 188, h = 188, imagePath = "assets/tablet_bg1.png", color = { 255, 255, 255, 255 }, radius = 12, visible = false, groupId = "settings_ui" },

    { id = "settings_thumb_frame_2", type = "rectangle", x = 1220, y = 480, w = 200, h = 200, color = { 60, 64, 72, 255 }, radius = 16, visible = false, groupId = "settings_ui" },
    { id = "settings_thumb_2", type = "image", x = 1226, y = 486, w = 188, h = 188, imagePath = "assets/tablet_bg2.png", color = { 255, 255, 255, 255 }, radius = 12, visible = false, groupId = "settings_ui" },

    { id = "settings_bg_info", type = "label", x = 780, y = 700, w = 640, h = 40, text = "Seçtiğiniz görsele tıklayın, anında uygulanır.", fontScale = 1.1, alignX = "center", alignY = "center", textColor = { 140, 140, 150, 255 }, visible = false, groupId = "settings_ui" },

    -- === GİRİŞ (LOGIN) EKRANI BİLEŞENLERİ (Başlangıçta gizli, tüm ekranı kaplar) ===
    { id = "login_bg", type = "rectangle", x = 312, y = 177, w = 1936, h = 1086, color = { 15, 17, 22, 255 }, radius = 60, visible = false },
    { id = "login_title", type = "label", x = 312, y = 400, w = 1936, h = 60, text = "Mekanik Tablet Girişi", fontScale = 1.8, font = "gilroy-bold", alignX = "center", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false },
    { id = "login_kullanici", type = "editbox", x = 980, y = 560, w = 600, h = 60, placeholder = "Mekanik İsmi", color = { 22, 28, 42, 250 }, borderColor = { 40, 46, 60, 255 }, textColor = { 255, 255, 255, 255 }, fontScale = 1.3, radius = 12, visible = false },
    { id = "login_sifre", type = "editbox", x = 980, y = 640, w = 600, h = 60, placeholder = "Şifre", masked = true, color = { 22, 28, 42, 250 }, borderColor = { 40, 46, 60, 255 }, textColor = { 255, 255, 255, 255 }, fontScale = 1.3, radius = 12, visible = false },
    { id = "login_btn", type = "button", x = 980, y = 730, w = 600, h = 60, text = "Giriş Yap", fontScale = 1.3, font = "gilroy-bold", alignX = "center", alignY = "center", radius = 12, color = { 63, 124, 255, 240 }, hoverColor = { 92, 150, 255, 250 }, textColor = { 255, 255, 255, 255 }, visible = false },

}

-- ========================================================
-- ENVANTER PENCERESİ (DEPO_UI)
-- Duty konumunda [E] ile açılır. ARTIK TABLET GÖRÜNÜMÜ DEĞİL:
-- Tablet çerçevesi/üst bar/beyaz bar hiç çizilmiyor; ekranın ortasında
-- bağımsız, klasik "oyun envanteri" tarzı bir pencere açılıyor.
-- Kapatmak için sağ üstteki ✕ butonu veya ESC kullanılır.
-- 40 slot (8 sütun x 5 satır), koyu mor/eflatun tema + pricedown başlık.
-- ========================================================
local DEPO_PANEL_W, DEPO_PANEL_H = 1500, 940
local DEPO_PANEL_X = (2560 - DEPO_PANEL_W) / 2
local DEPO_PANEL_Y = (1440 - DEPO_PANEL_H) / 2

local DEPO_COLS, DEPO_ROWS = 8, 5
local DEPO_SLOT_W, DEPO_SLOT_H = 160, 124
local DEPO_GAP_X, DEPO_GAP_Y = 18, 14
local DEPO_GRID_W = DEPO_COLS * DEPO_SLOT_W + (DEPO_COLS - 1) * DEPO_GAP_X
local DEPO_START_X = DEPO_PANEL_X + (DEPO_PANEL_W - DEPO_GRID_W) / 2
local DEPO_START_Y = DEPO_PANEL_Y + 158

local DEPO_SLOT_COLOR = { 42, 32, 64, 235 }
local DEPO_ACCENT = { 178, 130, 255, 255 }

-- Arka plandaki her şeyi karartan tam ekran örtü (tablet çerçevesi tamamen gizli kalır)
table.insert(uiElements, { id = "depo_backdrop", type = "rectangle", x = 0, y = 0, w = 2560, h = 1440, color = { 6, 4, 10, 175 }, radius = 0, visible = false, groupId = "depo_ui" })

table.insert(uiElements, { id = "depo_bg", type = "rectangle", x = DEPO_PANEL_X, y = DEPO_PANEL_Y, w = DEPO_PANEL_W, h = DEPO_PANEL_H, color = { 16, 12, 26, 250 }, radius = 28, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_header_line", type = "rectangle", x = DEPO_PANEL_X, y = DEPO_PANEL_Y + 136, w = DEPO_PANEL_W, h = 2, color = { 100, 70, 160, 160 }, radius = 0, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_panel_title", type = "label", x = DEPO_PANEL_X + 46, y = DEPO_PANEL_Y + 52, w = 700, h = 44, text = "D E P O", fontScale = 1.7, font = "bankgothic", alignX = "left", alignY = "center", textColor = DEPO_ACCENT, shadowColor = { 0, 0, 0, 200 }, shadowOffsetX = 2, shadowOffsetY = 2, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_subtitle", type = "label", x = DEPO_PANEL_X + 48, y = DEPO_PANEL_Y + 98, w = 700, h = 24, text = "DRP Depo Sistemi ‧ Kişisel Envanter", fontScale = 0.85, font = "default", alignX = "left", alignY = "center", textColor = { 150, 140, 175, 220 }, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_kapat_btn", type = "button", x = DEPO_PANEL_X + DEPO_PANEL_W - 92, y = DEPO_PANEL_Y + 34, w = 52, h = 52, text = "✕", fontScale = 1.4, font = "default-bold", radius = 14, color = { 40, 22, 30, 255 }, hoverColor = { 200, 60, 70, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "depo_ui" })

for i = 1, DEPO_COLS * DEPO_ROWS do
    local col = (i - 1) % DEPO_COLS
    local row = math.floor((i - 1) / DEPO_COLS)
    local sx2 = DEPO_START_X + col * (DEPO_SLOT_W + DEPO_GAP_X)
    local sy2 = DEPO_START_Y + row * (DEPO_SLOT_H + DEPO_GAP_Y)

    table.insert(uiElements, { id = "env_slot_bg_" .. i, type = "rectangle", x = sx2, y = sy2, w = DEPO_SLOT_W, h = DEPO_SLOT_H, color = DEPO_SLOT_COLOR, radius = 16, visible = false, groupId = "depo_ui" })
    table.insert(uiElements, { id = "env_slot_num_" .. i, type = "label", x = sx2 + 10, y = sy2 + 6, w = 40, h = 22, text = tostring(i), fontScale = 0.7, font = "default-bold", alignX = "left", alignY = "center", textColor = { 120, 110, 150, 200 }, visible = false, groupId = "depo_ui" })
    table.insert(uiElements, { id = "env_slot_name_" .. i, type = "label", x = sx2 + 8, y = sy2 + 28, w = DEPO_SLOT_W - 16, h = DEPO_SLOT_H - 54, text = "Boş", fontScale = 0.95, font = "default-bold", alignX = "center", alignY = "center", textColor = { 110, 105, 130, 180 }, wordBreak = true, visible = false, groupId = "depo_ui" })
    table.insert(uiElements, { id = "env_slot_qty_" .. i, type = "label", x = sx2, y = sy2 + DEPO_SLOT_H - 26, w = DEPO_SLOT_W - 10, h = 20, text = "", fontScale = 0.85, font = "default-bold", alignX = "right", alignY = "center", textColor = DEPO_ACCENT, visible = false, groupId = "depo_ui" })
end

-- Seçili eşya detay paneli (alt bar)
table.insert(uiElements, { id = "depo_detail_bg", type = "rectangle", x = DEPO_START_X, y = DEPO_START_Y + DEPO_ROWS * DEPO_SLOT_H + (DEPO_ROWS - 1) * DEPO_GAP_Y + 20, w = DEPO_GRID_W, h = 68, color = { 26, 18, 42, 240 }, radius = 16, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_detail_name", type = "label", x = DEPO_START_X + 24, y = DEPO_START_Y + DEPO_ROWS * DEPO_SLOT_H + (DEPO_ROWS - 1) * DEPO_GAP_Y + 20, w = 700, h = 68, text = "Bir eşya seçin", fontScale = 1.1, font = "default-bold", alignX = "left", alignY = "center", textColor = { 255, 255, 255, 255 }, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_detail_qty", type = "label", x = DEPO_START_X + 760, y = DEPO_START_Y + DEPO_ROWS * DEPO_SLOT_H + (DEPO_ROWS - 1) * DEPO_GAP_Y + 20, w = 380, h = 68, text = "", fontScale = 1.0, font = "default-bold", alignX = "left", alignY = "center", textColor = DEPO_ACCENT, visible = false, groupId = "depo_ui" })
table.insert(uiElements, { id = "depo_kullan_btn", type = "button", x = DEPO_START_X + DEPO_GRID_W - 210, y = DEPO_START_Y + DEPO_ROWS * DEPO_SLOT_H + (DEPO_ROWS - 1) * DEPO_GAP_Y + 29, w = 210, h = 50, text = "Kullan", fontScale = 1.1, font = "default-bold", radius = 12, color = { 130, 90, 255, 255 }, hoverColor = { 160, 120, 255, 255 }, textColor = { 255, 255, 255, 255 }, visible = false, groupId = "depo_ui" })



local bgOptions = {
    "assets/tablet_bg.png",
    "assets/tablet_bg1.png",
    "assets/tablet_bg2.png",
}
local selectedBgIndex = 0 -- 0 = tablet_bg.png (varsayılan)

local function applySelectedBgVisual(index)
    selectedBgIndex = index
    for _, v in ipairs(uiElements) do
        if v.id == "ekran" then
            v.imagePath = bgOptions[index + 1]
            v._tex = nil -- yeniden yüklesin
        end
        if v.id == "settings_thumb_frame_0" then v.color = (index == 0) and {25, 128, 190, 255} or {60, 64, 72, 255} end
        if v.id == "settings_thumb_frame_1" then v.color = (index == 1) and {25, 128, 190, 255} or {60, 64, 72, 255} end
        if v.id == "settings_thumb_frame_2" then v.color = (index == 2) and {25, 128, 190, 255} or {60, 64, 72, 255} end
    end
end

local function toggleGroup(groupId, visible)
    for _, v in ipairs(uiElements) do
        if v.groupId == groupId then
            v.visible = visible
        end
    end
end

local function rgba(c) if type(c)~="table" then return tocolor(255,255,255,255) end return tocolor(c[1],c[2],c[3],c[4] or 255) end
local function hasColor(c) return type(c)=="table" and (c[4] or 255)>0 end

local function isCursorOnRect(x,y,w,h)
    if not isCursorShowing() then return false end
    local cx,cy=getCursorPosition(); if not cx then return false end
    cx,cy=cx*sx,cy*sy
    return cx>=x and cx<=x+w and cy>=y and cy<=y+h
end

local function _res() sx,sy=guiGetScreenSize(); scaleX,scaleY=sx/_cw,sy/_ch; _scale=math.min(scaleX,scaleY); _offX=(sx-_cw*_scale)/2; _offY=(sy-_ch*_scale)/2 end
addEventHandler("onClientResourceStart",resourceRoot,_res)

local function dxDrawRounded(id,x,y,w,h,radius,color,postGUI)
    id = tostring(id or 'generic')
    w=math.max(1,math.floor(w+0.5)); h=math.max(1,math.floor(h+0.5))
    radius=math.min(math.floor((radius or 0)+0.5), math.floor(math.min(w,h)/2))
    if radius<=0 then dxDrawRectangle(x,y,w,h,color,postGUI or false); return end
    rounded[id]=rounded[id] or {}; rounded[id][w]=rounded[id][w] or {}; rounded[id][w][h]=rounded[id][w][h] or {}
    if not rounded[id][w][h][radius] or not isElement(rounded[id][w][h][radius]) then
        local p=string.format('<svg width="%d" height="%d" viewBox="0 0 %d %d"><rect width="%d" height="%d" rx="%d" fill="#FFF"/></svg>',w,h,w,h,w,h,radius)
        rounded[id][w][h][radius]=svgCreate(w,h,p)
    end
    if rounded[id][w][h][radius] then dxDrawImage(x,y,w,h,rounded[id][w][h][radius],0,0,0,color,postGUI or false) end
end

local function dxDrawCircle(id,x,y,w,h,color,postGUI)
    id = tostring(id or 'generic')
    w=math.max(1,math.floor(w+0.5)); h=math.max(1,math.floor(h+0.5))
    local key=w..'_'..h
    circles[id]=circles[id] or {}
    if not circles[id][key] or not isElement(circles[id][key]) then
        local p=string.format('<svg width="%d" height="%d" viewBox="0 0 %d %d"><ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFF"/></svg>',w,h,w,h,w/2,h/2,w/2,h/2)
        circles[id][key]=svgCreate(w,h,p)
    end
    if circles[id][key] then dxDrawImage(x,y,w,h,circles[id][key],0,0,0,color,postGUI or false) end
end

function drawOutline(x,y,w,h,color,thickness)
    thickness = thickness or 1
    dxDrawRectangle(x,y,w,thickness,color)
    dxDrawRectangle(x,y+h-thickness,w,thickness,color)
    dxDrawRectangle(x,y,thickness,h,color)
    dxDrawRectangle(x+w-thickness,y,thickness,h,color)
end
function utfLen(s) local _, count = tostring(s or ''):gsub('[^\128-\191]', '') return count end
local function delChar(s) if not s or #s==0 then return "" end return string.sub(s, 1, #s-1) end

function drawStyledText(text,left,top,right,bottom,opts)
    local scale=(opts.fontScale or 1) * _scale
    local _bf={["default"]=true,["default-bold"]=true,["arial"]=true,["bankgothic"]=true,["clear"]=true,["danielbd"]=true,["pricedown"]=true,["sans"]=true,["unifont"]=true}
    local font=(opts.font and _bf[opts.font]) and opts.font or 'default-bold'
    if hasColor(opts.shadowColor) then
        local sx2=(opts.shadowOffsetX or 1)*scaleX; local sy2=(opts.shadowOffsetY or 1)*scaleY
        dxDrawText(text,left+sx2,top+sy2,right+sx2,bottom+sy2,rgba(opts.shadowColor),scale,font,opts.alignX or 'left',opts.alignY or 'center',opts.clip,opts.wordBreak,false,opts.colorCoded)
    end
    dxDrawText(text,left,top,right,bottom,rgba(opts.textColor or {255,255,255,255}),scale,font,opts.alignX or 'left',opts.alignY or 'center',opts.clip,opts.wordBreak,false,opts.colorCoded)
end

local function resolveAnchoredRect(el)
    local x = el.x or 0
    local y = el.y or 0
    local w = (el.relativeW and el.wPercent) and math.max(20, math.floor(_cw * (el.wPercent / 100) + 0.5)) or (el.w or 0)
    local h = (el.relativeH and el.hPercent) and math.max(20, math.floor(_ch * (el.hPercent / 100) + 0.5)) or (el.h or 0)
    if el.dockX == 'fill' then w = math.max(20, _cw - x - math.max(0, el.dockPaddingRight or 0)) elseif el.anchorX == 'center' then x = (_cw - w) / 2 + x elseif el.anchorX == 'right' then x = _cw - w - x end
    if el.dockY == 'fill' then h = math.max(20, _ch - y - math.max(0, el.dockPaddingBottom or 0)) elseif el.anchorY == 'center' then y = (_ch - h) / 2 + y elseif el.anchorY == 'bottom' then y = _ch - h - y end
    return x*_scale+_offX, y*_scale+_offY, w*_scale, h*_scale
end

local function drawUiElement(el)
    local x,y,w,h=resolveAnchoredRect(el)
    if el.type=="window" then
        local hh=math.min(h,math.max(24*scaleY,(el.headerHeight or 40)*scaleY))
        local px=(el.titlePaddingX or 16)*scaleX
        dxDrawRectangle(x,y,w,h,rgba(el.bodyColor))
        dxDrawRectangle(x,y,w,hh,rgba(el.headerColor))
        drawStyledText(el.title,x+px,y,x+w-px,y+hh,el)
    elseif el.type=="rectangle" then
        dxDrawRounded(el.id,x,y,w,h,(el.radius or 0)*_scale,rgba(el.color))
    elseif el.type=="button" then
        local r=(el.radius or 0)*_scale
        local fill=isCursorOnRect(x,y,w,h) and el.hoverColor or el.color
        dxDrawRounded(el.id,x,y,w,h,r,rgba(fill))
        drawStyledText(el.text,x+8*scaleX,y+4*scaleY,x+w-8*scaleX,y+h-4*scaleY,el)
    elseif el.type=="label" then
        drawStyledText(el.text,x,y,x+w,y+h,el)
    elseif el.type=="image" then
        local r=(el.radius or 0)*_scale
        if el.imagePath and el.imagePath~="" then
            if not el._tex or not isElement(el._tex) then
                if fileExists(el.imagePath) then
                    el._tex = dxCreateTexture(el.imagePath, "argb", true, "clamp")
                end
            end
            if el._tex and isElement(el._tex) then
                dxDrawImage(x, y, w, h, el._tex, 0, 0, 0, rgba(el.color or {255,255,255,255}))
            else
                dxDrawRounded(el.id, x, y, w, h, r, tocolor(30, 30, 35, 255))
            end
        else
            dxDrawRounded(el.id,x,y,w,h,r,rgba(el.color or {255,255,255,255}))
        end
    elseif el.type=="container" then
        dxDrawRounded(el.id,x,y,w,h,(el.radius or 0)*_scale,rgba(el.color))
    elseif el.type=="progressbar" then
        local r=(el.radius or 0)*_scale
        dxDrawRounded(el.id..'_bg',x,y,w,h,r,rgba(el.color))
        local fillW=w*((el.progress or 0)/100)
        dxDrawRounded(el.id..'_fill',x,y,fillW,h,r,rgba(el.progressColor or {72,199,130,255}))
        if el.text and el.text~='' then drawStyledText(el.text,x,y,x+w,y+h,el) end
    elseif el.type=="checkbox" then
        local box=math.min(h,22*scaleY)
        dxDrawRounded(el.id..'_box',x,y+(h-box)/2,box,box,4,rgba(el.boxColor or {27,31,42,230}))
        if el.checked then dxDrawText('✔',x,y+(h-box)/2,x+box,y+(h+box)/2,rgba(el.checkColor or {72,199,130,255}),1,'default-bold','center','center') end
        drawStyledText(el.text or '',x+box+8*scaleX,y,x+w,y+h,el)
    elseif el.type=="editbox" then
        dxDrawRounded(el.id..'_eb',x,y,w,h,(el.radius or 0)*_scale,rgba(el.color or {20,24,32,235}))
        if hasColor(el.borderColor) then drawOutline(x,y,w,h,rgba(el.borderColor),1) end
        local shown=(el.text and el.text~='') and el.text or (el.placeholder or '')
        if el.masked and el.text and el.text~='' then shown=string.rep('*', utfLen(el.text)) end
        drawStyledText(shown,x+12*scaleX,y,x+w-12*scaleX,y+h,{font=el.font,fontScale=el.fontScale,textColor=(el.text and el.text~='') and (el.textColor or {255,255,255,255}) or {160,165,180,255},alignX='left',alignY='center'})
    elseif el.type=="line" then
        dxDrawLine(x,y+h/2,x+w,y+h/2,rgba(el.color or {255,255,255,200}),el.thickness or 2)
    elseif el.type=="gradient" then
        local steps=20
        local c1 = type(el.color)=='table' and el.color or {255,255,255,255}; local c2 = type(el.gradientColor)=='table' and el.gradientColor or {0,0,0,255}; for i=0,steps-1 do local t=i/(steps-1); local c={c1[1]+(c2[1]-c1[1])*t, c1[2]+(c2[2]-c1[2])*t, c1[3]+(c2[3]-c1[3])*t, (c1[4] or 255)+((c2[4] or 255)-(c1[4] or 255))*t}; if el.gradientMode=='vertical' then dxDrawRectangle(x,y+(h/steps)*i,w,math.ceil(h/steps),rgba(c)) else dxDrawRectangle(x+(w/steps)*i,y,math.ceil(w/steps),h,rgba(c)) end end
    elseif el.type=="icon" then
        local icon = getIconTexture(el.iconName)
        if icon then
            local size=math.min(w,h,(el.iconSize or 24)*_scale)
            dxDrawImage(x+(w-size)/2,y+(h-size)/2,size,size,icon,0,0,0,rgba(el.color or {255,255,255,255}))
        else
            dxDrawText(string.upper((el.iconName or '?'):sub(1,1)),x,y,x+w,y+h,rgba(el.color or {255,255,255,255}),1,'default-bold','center','center')
        end
    elseif el.type=="circle" then
        if (el.borderWidth or 0)>0 and hasColor(el.borderColor) then
            local bw=el.borderWidth*_scale
            dxDrawCircle(el.id..'_b',x-bw,y-bw,w+bw*2,h+bw*2,rgba(el.borderColor))
        end
        dxDrawCircle(el.id,x,y,w,h,rgba(el.color))
    end
end

local tabletAcik = false
local girisYapildi = false
local dutyPos = nil -- Giriş yapılınca sunucudan gelen duty konumu: {x=.., y=.., z=..}
local DUTY_RANGE = CONFIG.DUTY_MENZILI -- Duty konumuna E ile envanter açmak için gereken mesafe (birim)
local activeInput = nil
local depoData = {} -- Sunucudan gelen envanter verisi: { ["inv_slot1"] = {name=.., miktar=..}, ... }
local selectedSlot = nil -- Şu an detay panelinde seçili olan slot numarası
local DEPO_TOTAL_SLOTS = CONFIG.DEPO_SLOT_SAYISI

local function depoDetayiSifirla()
    selectedSlot = nil
    for _, v in ipairs(uiElements) do
        if v.id == "depo_detail_name" then v.text = "Bir eşya seçin" end
        if v.id == "depo_detail_qty" then v.text = "" end
        if v.id:match("^env_slot_bg_%d+$") then v.color = { 42, 32, 64, 235 } end
    end
end

addEventHandler('onClientClick', root, function(btn, state)
    if not tabletAcik then return end
    if btn~='left' or state~='down' then return end
    
    for i=#uiElements,1,-1 do
        local el=uiElements[i]
        if el.visible~=false then
            local x,y,w,h=resolveAnchoredRect(el)
            if isCursorOnRect(x,y,w,h) then
                
                -- ANA SAYFA UYGULAMALARI
                if el.id == "market" then
                    toggleGroup("home_ui", false)
                    toggleGroup("market_ui", true)
                    return
                end
                if el.id == "app_duty" then
                    toggleGroup("home_ui", false)
                    toggleGroup("duty_ui", true)
                    return
                end
                if el.id == "app_key" then
                    toggleGroup("home_ui", false)
                    toggleGroup("key_ui", true)
                    triggerServerEvent("key:requestTotal", localPlayer)
                    return
                end
                if el.id == "app_settings" then
                    toggleGroup("home_ui", false)
                    toggleGroup("settings_ui", true)
                    return
                end
                
                -- HOME BAR (BEYAZ ÇUBUK)
                if el.id == "ortatus" then
                    local isPageOpen = false
                    for _, v in ipairs(uiElements) do
                        if (v.groupId == "market_ui" or v.groupId == "duty_ui" or v.groupId == "key_ui" or v.groupId == "settings_ui") and v.visible == true then
                            isPageOpen = true
                            break
                        end
                    end
                    if isPageOpen then
                        toggleGroup("market_ui", false)
                        toggleGroup("duty_ui", false)
                        toggleGroup("key_ui", false)
                        toggleGroup("settings_ui", false)
                        toggleGroup("home_ui", true)
                    else
                        tabletAcik = false
                        showCursor(false)
                        guiSetInputEnabled(false)
                        for _, v in ipairs(uiElements) do v.visible = false end
                        activeInput = nil
                    end
                    return
                end
                
                -- GERİ BUTONLARI
                if el.id == "market_back_btn" then
                    toggleGroup("market_ui", false)
                    toggleGroup("home_ui", true)
                    return
                end
                if el.id == "duty_back_btn" then
                    toggleGroup("duty_ui", false)
                    toggleGroup("home_ui", true)
                    return
                end
                if el.id == "key_back_btn" then
                    toggleGroup("key_ui", false)
                    toggleGroup("home_ui", true)
                    return
                end
                if el.id == "settings_back_btn" then
                    toggleGroup("settings_ui", false)
                    toggleGroup("home_ui", true)
                    return
                end
                if el.id == "depo_kapat_btn" then
                    -- Envanter tablet menüsünden bağımsız açıldığı için "geri" değil, direkt kapatır.
                    tabletAcik = false
                    showCursor(false)
                    guiSetInputEnabled(false)
                    for _, v in ipairs(uiElements) do v.visible = false end
                    activeInput = nil
                    return
                end

                -- ENVANTER: SLOT SEÇİMİ (arka plan / numara / isim / miktar hangisine tıklanırsa tıklansın yakalar)
                do
                    local slotNum = el.id:match("^env_slot_bg_(%d+)$")
                        or el.id:match("^env_slot_num_(%d+)$")
                        or el.id:match("^env_slot_name_(%d+)$")
                        or el.id:match("^env_slot_qty_(%d+)$")
                    if slotNum then
                        slotNum = tonumber(slotNum)
                        selectedSlot = slotNum
                        local item = depoData["inv_slot" .. slotNum]
                        for _, v in ipairs(uiElements) do
                            if v.id == "depo_detail_name" then
                                v.text = item and item.name or ("Boş Slot (#" .. slotNum .. ")")
                            elseif v.id == "depo_detail_qty" then
                                v.text = item and ("Miktar: " .. (item.miktar or 0)) or ""
                            elseif v.id:match("^env_slot_bg_%d+$") then
                                local n = tonumber(v.id:match("%d+"))
                                v.color = (n == slotNum) and { 130, 90, 255, 255 } or { 42, 32, 64, 235 }
                            end
                        end
                        return
                    end
                end
                if el.id == "depo_kullan_btn" then
                    if not selectedSlot then
                        outputChatBox("Önce bir slot seçin!", 255, 100, 100)
                        return
                    end
                    if not depoData["inv_slot" .. selectedSlot] then
                        outputChatBox("Bu slot boş!", 255, 100, 100)
                        return
                    end
                    triggerServerEvent("esyaIslemiYap", resourceRoot, "inv_slot" .. selectedSlot, "kullan")
                    return
                end
                
                -- DUTY İŞLEMLERİ
                if el.id == "depo_find_btn" then
                    triggerServerEvent("tablet:dutyAyarla", resourceRoot)
                    return
                end
                if el.id == "duty_start_btn" then
                    local skinID = ""
                    for _, v in ipairs(uiElements) do
                        if v.id == "duty_skin_input" then skinID = v.text end
                    end
                    triggerServerEvent("duty:toggle", localPlayer, skinID)
                    return
                end
                
                -- PARÇA SEPETİ (Butonların hepsini yakalar)
                if el.id == "motor_1" or el.id == "motor_2" or el.id == "motor_3" or el.id == "motor_4" or
                   el.id == "fren_1" or el.id == "fren_2" or el.id == "fren_3" or
                   el.id == "turbo_1" or
                   el.id == "sanziman_1" or el.id == "sanziman_2" or el.id == "sanziman_3" or el.id == "sanziman_4" then
                    local partType, level = el.id:match("(%a+)_(%d+)")
                    level = tonumber(level)
                    local price = getPartPrice(partType, level)
                    table.insert(cartItems, {name = el.text, partType = partType, level = level, price = price})
                    updateCartUI()
                    return
                end

                -- AYARLAR: ARKA PLAN SEÇİMİ (3 KÜÇÜK ÖNİZLEME)
                if el.id == "settings_thumb_0" or el.id == "settings_thumb_frame_0" then
                    applySelectedBgVisual(0)
                    triggerServerEvent("settings:changeBG", localPlayer, bgOptions[1])
                    return
                end
                if el.id == "settings_thumb_1" or el.id == "settings_thumb_frame_1" then
                    applySelectedBgVisual(1)
                    triggerServerEvent("settings:changeBG", localPlayer, bgOptions[2])
                    return
                end
                if el.id == "settings_thumb_2" or el.id == "settings_thumb_frame_2" then
                    applySelectedBgVisual(2)
                    triggerServerEvent("settings:changeBG", localPlayer, bgOptions[3])
                    return
                end
                
                if el.id == "cart_clear_btn" then
                    cartItems = {}
                    updateCartUI()
                    return
                end
                if el.id == "cart_buy_btn" then
                    if #cartItems == 0 then
                        outputChatBox("Sepet boş!", 255, 0, 0)
                        return
                    end
                    triggerServerEvent("part:buyMultiple", localPlayer, cartItems)
                    cartItems = {}
                    updateCartUI()
                    return
                end
                
                -- ANAHTAR ÖDEME
                if el.id == "pay_cash_bg" or el.id == "pay_cash_txt" then
                    selectedPayment = "nakit"
                    for _, v in ipairs(uiElements) do
                        if v.id == "pay_cash_bg" then v.color = {26, 45, 42, 255} end
                        if v.id == "pay_bank_bg" then v.color = {35, 38, 50, 255} end
                    end
                    return
                end
                if el.id == "pay_bank_bg" or el.id == "pay_bank_txt" then
                    selectedPayment = "banka"
                    for _, v in ipairs(uiElements) do
                        if v.id == "pay_bank_bg" then v.color = {26, 45, 42, 255} end
                        if v.id == "pay_cash_bg" then v.color = {35, 38, 50, 255} end
                    end
                    return
                end
                if el.id == "key_buy_btn" then
                    local vehicleID = ""
                    local payerID = ""
                    for _, v in ipairs(uiElements) do
                        if v.id == "key_car_input" then vehicleID = v.text end
                        if v.id == "key_payer_input" then payerID = v.text end
                    end
                    if vehicleID == "" or payerID == "" then
                        outputChatBox("Lütfen Araç ID ve Ödeyecek Kişi ID'yi doldurun!", 255, 0, 0)
                        return
                    end
                    triggerServerEvent("key:buy", localPlayer, vehicleID, payerID, selectedPayment)
                    return
                end
                
                -- GİRİŞ (LOGIN) EKRANI
                if el.id == "login_btn" then
                    triggerEvent("loginTiklandi", localPlayer, el)
                    return
                end

                if el.type=='editbox' then activeInput=el else activeInput=nil end
                
                break
            end
        end
    end
end)

addEventHandler('onClientCharacter', root, function(char)
    if not tabletAcik or not activeInput then return end
    activeInput.text = (activeInput.text or '')..char
end)

addEventHandler('onClientKey', root, function(btn, down)
    if not tabletAcik or not activeInput or not down then return end
    if btn=='backspace' then
        local t=activeInput.text or ''
        if #t > 0 then
            local u=t:gsub('[\128-\191]', '')
            if #u>0 then activeInput.text=delChar(t) end
        end
    end
end)

addEvent("key:totalUpdated", true)
addEventHandler("key:totalUpdated", root, function(total)
    for _, v in ipairs(uiElements) do
        if v.id == "key_price_label" then v.text = "Toplam Tutar: " .. total .. " ₺" end
    end
end)

addEvent("settings:bgChanged", true)
addEventHandler("settings:bgChanged", root, function(path)
    for index, p in ipairs(bgOptions) do
        if p == path then
            applySelectedBgVisual(index - 1)
            break
        end
    end
end)

function updateCartUI()
    local listText = ""
    totalPrice = 0
    if #cartItems == 0 then
        listText = "Sepet Boş"
    else
        for i, item in ipairs(cartItems) do
            listText = listText .. item.name .. " - " .. (item.price or 0) .. " ₺\n"
            totalPrice = totalPrice + (item.price or 0)
        end
    end
    for _, v in ipairs(uiElements) do
        if v.id == "cart_list" then v.text = listText end
        if v.id == "cart_total" then v.text = "Toplam: " .. totalPrice .. " ₺" end
        if v.id == "key_price_label" then v.text = "Toplam Tutar: " .. totalPrice .. " ₺" end
    end
end

-- Sunucudan güncel envanter verisi geldiğinde slotları doldurur
addEvent("depoyuGuncelle", true)
addEventHandler("depoyuGuncelle", resourceRoot, function(esyalar)
    depoData = esyalar or {}
    for i = 1, DEPO_TOTAL_SLOTS do
        local item = depoData["inv_slot" .. i]
        for _, v in ipairs(uiElements) do
            if v.id == "env_slot_name_" .. i then
                v.text = item and item.name or "Boş"
                v.textColor = item and { 255, 255, 255, 255 } or { 110, 105, 130, 180 }
            elseif v.id == "env_slot_qty_" .. i then
                v.text = (item and item.miktar and item.miktar > 0) and ("x" .. item.miktar) or ""
            end
        end
    end
    -- Seçili slot artık depoda yoksa (tükendiyse) detay panelini sıfırla
    if selectedSlot and not depoData["inv_slot" .. selectedSlot] then
        depoDetayiSifirla()
    end
end)

addEvent("duty:updateStatus", true)
addEventHandler("duty:updateStatus", root, function(isOnDuty)
    for _, v in ipairs(uiElements) do
        if v.id == "depo_status" then
            if isOnDuty then
                v.text = "Duty Durumu: AÇIK (Depoya gidebilirsin!)"
                v.textColor = { 0, 255, 0, 255 }
            else
                v.text = "Duty Durumu: KAPALI (Duty'ye giriş yap!)"
                v.textColor = { 255, 100, 100, 255 }
            end
        end
    end
end)

local function renderCreatedUi()
    if not tabletAcik then return end
    for _,el in ipairs(uiElements) do if el.visible~=false and el.groupId~="frame_ui_top" then drawUiElement(el) end end
    for _,el in ipairs(uiElements) do if el.visible~=false and el.groupId=="frame_ui_top" then drawUiElement(el) end end
end
addEventHandler("onClientRender", root, renderCreatedUi)
-- ==========================================
-- TABLET MANTIĞI VE GİRİŞ (LOGIN) SİSTEMİ
-- ==========================================

-- Tableti açma/kapatma (tek ortak fonksiyon - hem /tablet komutu hem item kullanımı bunu çağırır)
local function toggleTablet()
    tabletAcik = not tabletAcik
    showCursor(tabletAcik)
    guiSetInputEnabled(tabletAcik)

    if tabletAcik then
        for _, el in ipairs(uiElements) do
            if el.groupId == "frame_ui" or el.groupId == "frame_ui_top" then
                -- Çerçeve ve üst bar her zaman görünür olmalı
                el.visible = true
            elseif string.sub(el.id, 1, 5) == "login" then
                -- Giriş yapılmadıysa login ekranı, yapıldıysa gizli
                el.visible = not girisYapildi
            elseif el.groupId == "depo_ui" then
                -- Envanter artık normal açılışta otomatik gelmiyor; sadece duty konumunda E ile açılıyor
                el.visible = false
            elseif el.groupId == "home_ui" then
                -- Ana menü ikonları sadece giriş yapıldıktan sonra görünür
                el.visible = girisYapildi
            else
                -- market_ui / duty_ui / key_ui / settings_ui gibi alt uygulama ekranları
                -- her tablet açılışında kapalı başlar (ana menüden tıklanarak açılır)
                el.visible = false
            end
        end
    else
        -- Tablet kapanırken ekrandaki her şeyi gizle
        for _, el in ipairs(uiElements) do
            el.visible = false
        end
        activeInput = nil -- Seçili input (editbox) kutusunu sıfırla
    end
end

-- /tablet yazınca aç/kapa
addCommandHandler(CONFIG.KOMUTLAR.tabletAc, function()
    toggleTablet()
end)

-- Tablet bir eşya/item olarak kullanıldığında (item sisteminiz bu event'i tetikleyecek)
addEvent("tablet:useItem", true)
addEventHandler("tablet:useItem", root, function()
    toggleTablet()
end)

-- Dışarıdan da tetiklenebilsin diye (ör. NPC, market vb.)
addEvent("tablet:open", true)
addEventHandler("tablet:open", root, function()
    toggleTablet()
end)

-- "Giriş Yap" butonuna tıklandığında (actionValue = "loginTiklandi") burası tetiklenir
addEvent("loginTiklandi", false)
addEventHandler("loginTiklandi", localPlayer, function(butonElemani)
    local kullaniciAdi = ""
    local sifre = ""
    
    -- Editboxlara yazılan yazıları değişkene alıyoruz
    for _, el in ipairs(uiElements) do
        if el.id == "login_kullanici" then
            kullaniciAdi = el.text or ""
        elseif el.id == "login_sifre" then
            sifre = el.text or ""
        end
    end
    
    -- Eğer kutular boşsa uyarı veriyoruz
    if kullaniciAdi == "" or sifre == "" then
        outputChatBox("Lütfen mekanik ismi ve şifre girin!", 255, 0, 0)
        return
    end
    
    -- Bilgileri doğrulanması için sunucuya iletiyoruz
    triggerServerEvent("tableteGirisYap", resourceRoot, kullaniciAdi, sifre)
end)

-- Sunucu bilgileri doğruladığında bu event tetiklenir
addEvent("duty:depoKonumuGuncellendi", true)
addEventHandler("duty:depoKonumuGuncellendi", resourceRoot, function(x, y, z)
    dutyPos = { x = x, y = y, z = z }
    for _, el in ipairs(uiElements) do
        if el.id == "depo_current_pos" then
            el.text = string.format("Ayarlandı: %.0f, %.0f, %.0f", x, y, z)
        end
    end
end)

addEvent("tabletGirisBasarili", true)
addEventHandler("tabletGirisBasarili", resourceRoot, function(data)
    girisYapildi = true -- Artık giriş yapıldı olarak işaretliyoruz

    if data and data.dutyX then
        dutyPos = { x = data.dutyX, y = data.dutyY, z = data.dutyZ }
    end

    -- Login ekranındaki bileşenleri gizleyip, ana menüyü gösteriyoruz
    -- (Depo artık otomatik açılmıyor; sadece duty konumunda E ile açılıyor)
    for _, el in ipairs(uiElements) do
        if string.sub(el.id, 1, 5) == "login" then
            el.visible = false
            el.text = "" -- Kutuların içini temizliyoruz (Güvenlik amaçlı)
        elseif el.groupId == "depo_ui" then
            el.visible = false -- Envanter artık sadece duty konumunda E ile açılır
        elseif el.groupId == "home_ui" then
            el.visible = true
        end
    end
    activeInput = nil
end)

-- ==========================================
-- Duty konumunda E tuşuna basınca depo doğrudan açılır
-- ==========================================
bindKey("e", "down", function()
    if not girisYapildi or not dutyPos then return end
    if tabletAcik then return end -- Tablet zaten açıksa E'nin başka işlevlere karışmasını engelle

    local px, py, pz = getElementPosition(localPlayer)
    local mesafe = getDistanceBetweenPoints3D(px, py, pz, dutyPos.x, dutyPos.y, dutyPos.z)
    if mesafe > DUTY_RANGE then return end

    tabletAcik = true
    showCursor(true)
    guiSetInputEnabled(true)

    -- Envanter artık tablet görünümü kullanmıyor: sadece depo_ui grubu gösterilir,
    -- tablet çerçevesi/üst bar/beyaz bar (frame_ui, frame_ui_top) hiç açılmaz.
    for _, el in ipairs(uiElements) do
        el.visible = (el.groupId == "depo_ui")
    end
    depoDetayiSifirla()

    triggerServerEvent("depoVerisiniCek", resourceRoot)
end)

-- Envanter ESC ile de kapatılabilir (tablet menüsünden bağımsız açıldığı için beyaz bar yok)
bindKey("escape", "down", function()
    if not tabletAcik then return end
    local depoAcikMi = false
    for _, el in ipairs(uiElements) do
        if el.groupId == "depo_ui" and el.visible == true then
            depoAcikMi = true
            break
        end
    end
    if not depoAcikMi then return end

    tabletAcik = false
    showCursor(false)
    guiSetInputEnabled(false)
    for _, el in ipairs(uiElements) do el.visible = false end
    activeInput = nil
end)

-- ==========================================
-- Duty konumunda "Depo [E]" yazısını dünya üzerinde göster
-- ==========================================
local DUTY_PROMPT_RANGE = CONFIG.DUTY_PROMPT_MENZILI -- Yazının görüneceği menzil

local function renderDutyPrompt()
    if not girisYapildi or not dutyPos or tabletAcik then return end

    local px, py, pz = getElementPosition(localPlayer)
    local mesafe = getDistanceBetweenPoints3D(px, py, pz, dutyPos.x, dutyPos.y, dutyPos.z)
    if mesafe > DUTY_PROMPT_RANGE then return end

    local sx2, sy2 = getScreenFromWorldPosition(dutyPos.x, dutyPos.y, dutyPos.z + 1.2)
    if not sx2 then return end

    local yakinMi = mesafe <= DUTY_RANGE
    local renk = yakinMi and tocolor(255, 255, 255, 255) or tocolor(200, 200, 200, 180)
    local metin = "Depo [E]"

    dxDrawText(metin, sx2 + 1, sy2 + 1, sx2 + 1, sy2 + 1, tocolor(0, 0, 0, 190), 1.1, "default-bold", "center", "center")
    dxDrawText(metin, sx2, sy2, sx2, sy2, renk, 1.1, "default-bold", "center", "center")
end
addEventHandler("onClientRender", root, renderDutyPrompt)