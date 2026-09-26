STAGE v3.0 - MySQL Account + Character + Last Position

KURULUM:
1. MySQL'de database olustur:
   CREATE DATABASE stage CHARACTER SET utf8mb4;

2. config.lua duzenle:
   host, user, password, database

3. MTA'da mysql modulunun aktif oldugundan emin ol
   (genelde varsayilan gelir)

4. start stage_loading

AKIS:
- Login/Register
- Sinematik Vinewood -> IGS
- 3 karakter slotu
- Ilk olusturma: IGS spawn + konum kayit
- Sonraki girisler: son kaldigin yer

Pozisyon her 30 sn ve cikis/resource stop'ta kaydedilir.

MEDIA:
- client_config.lua icinden login videosu, sarki listesi, varsayilan ses ve yazilar degisir.
- Yeni mp3/ogg/mp4 dosyasini resource icine koyduysan meta.xml icine <file src="..."/> olarak ekle.
- URL kullanirsan client_config.lua icinde direkt https://... yazabilirsin.

F10:
- Karakter degistirme, HUD 1/2/3, speedometer 1/2/3, font, karakter cani ve crosshair buradan secilir.
- Crosshair sadece silahla nisan alirken gorunur.
