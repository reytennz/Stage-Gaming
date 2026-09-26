# Stage Phone v2.0.1

Reytennz Development Native DX iPhone tarzi telefon sistemi.
Bu surum mevcut yapiyi koruyarak debugscript 3 hatalarini, nil cakismalarini, texture leaklerini ve olcek kirilmalarini duzeltir.

## Kontrol
- `F4` veya `/telefon` ile ac / kapat
- ESC: uygulama > ana ekran > telefonu kapat
- Home indicator: ana ekran

## Ayarlar
- Telefon boyutu: %75 / %90 / %100 / %110
- BG 1 / BG 2 / BG 3 (`assets/background1.png`, `background2.png`, `background3.png`, yedek: `background.png`)
- Dynamic Island ac/kapat
- Ses ac/kapat
- Ayarlar `phone_settings.xml` ile client tarafinda saklanir

## Uygulamalar
Kamera, Galeri, Stagegram, StageX, Mesajlar, Kisiler, Telefon, Notlar, Hesap Makinesi, Ayarlar

## Kurulum
1. `stage_phone` klasorunu `resources` icine koy
2. `start stage_phone`
3. MySQL kullanmak istersen `config.lua` icinde `Config.mysql.enabled = true` yap. Kapaliysa bellek deposu kullanilir, resource crash olmaz.
