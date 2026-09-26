stage_factions — goat_factions'ın stage_core'a portu
======================================================

KURULUM
-------
1. Bu klasörü "stage_factions" adıyla server'ının resources/ klasörüne koy.
2. meta.xml'de <oop>true</oop> zaten açık — stage_core de OOP kullanıyor, sorun olmaz.
3. Bağımlılık: stage_core ve stage_mysql'in ÇALIŞIYOR olması gerekiyor (para, admin,
   veritabanı, bildirim hepsi oradan geliyor).
4. Resource'u başlat: `start stage_factions`
   İlk açılışta factions / faction_members / faction_logs tabloları otomatik oluşturulur
   (CREATE TABLE IF NOT EXISTS), elle SQL çalıştırmana gerek yok.

NE DEĞİŞTİ (goat_ -> stage_ portu)
-----------------------------------
- Kimlik: goat'taki "characters" tablosu / dbid yerine artık MTA HESAP ADI kullanılıyor
  (stage_core:GetAccountName). Yani bu sistemde tek hesap = tek "karakter".
- goat_scope        -> kaldırıldı, native `getElementsByType("team")` taraması (func/server.lua)
- goat_database     -> stage_core: CoreDBQuery / CoreDBExec
- goat_common       -> stage_core: IsAdmin, HasMoney, RemoveMoney, formatMoney
                        (isPlayerDeveloper / isPlayerTrialAdmin / isPlayerSupporter gibi
                        alt-admin seviyeleri stage_core'da yok, hepsi IsAdmin'e indirildi)
- goat_alert        -> stage_core: Notify
- goat_cache        -> kaldırıldı; log'larda artık direkt hesap adı saklanıyor, ekstra
                        isim çözümlemesine gerek yok
- goat_assets:getFont -> önce kendi files/fonts/*.ttf dosyanı yüklemeyi dener, o dosya
                        yoksa (senin serverinde yok) otomatik olarak MTA'nın hazır
                        "default"/"default-bold" fontuna düşer. FontAwesome ikon fontu
                        pakette yoktu; ikon karakterleri düzgün görünmeyebilir — kendi
                        .ttf dosyanı files/fonts/ altına koyarsan otomatik onu kullanır.
- goat_library      -> kullanılmıyor (araç isim çözümlemesi, aşağıya bak)

ÇIKARILANLAR
------------
- /abv, /abg (araç -> birliğe ekleme) ve araç respawn komutları KALDIRILDI, çünkü
  stage_arac'ta henüz araç sahiplik/veritabanı sistemi yok. server.lua içinde
  "ARAÇ ENTEGRASYONU" notunu bulup, kendi araç tablon hazır olduğunda geri ekleyebilirsin.

ÖNEMLİ DÜZELTME (v1.0.1)
-------------------------
İlk versiyonda stage_core'un fonksiyonlarını (IsAdmin, HasMoney, CoreDBExec vb.)
yanlışlıkla düz global fonksiyon gibi çağırmıştım. Başka bir resource'un
fonksiyonuna erişmek için MTA'da exports.stage_core:FonksiyonAdı(...) yazman
gerekiyor — bu yüzden resource başlarken hata veriyordu, takımlar hiç
kurulmuyordu, F3 açılırken (localPlayer.team boş kaldığı için) çöküyordu ve
/birlikkur da aynı sebepten çalışmıyordu. Bütün çağrılar artık
exports.stage_core:... şeklinde düzeltildi.

KOMUTLAR (aynı kaldı)
---------------------
/birlikkur [isim], /renamefaction [isim], /setfaction, /setfactionleader,
/birlikonayla, /showfactions, /f, /fl, /togglef (togf), /togglefaction (togfaction)

YENİ ÖZELLİKLER (v1.0.2)
--------------------------
- Logo: F3 panelinin sol üst köşesinde artık components/logo.png gösteriliyor.
- /birlikkur artık isimsiz yazılırsa (chat'e sadece "/birlikkur" yazarsan) logolu,
  isim giriş kutusu olan bir pencere açılır ("Kur" / "Vazgeç" butonlu). Eski
  kullanım da (chat'ten direkt "/birlikkur İsim") hâlâ çalışıyor, ikisi de aynı
  yere (createFactionForPlayer) gidiyor.
- Sıralama: F3 panelinde yeni bir sekme ("Sıralama") eklendi, banka bakiyesine
  göre en zengin birlikleri listeliyor (1., 2., 3. altın/gümüş/bronz renkli).
  Ayrıca herkese açık /birliksiralama komutu da aynı veriyi ayrı bir pencerede
  (grid list) gösteriyor — F3 içinde olmayan/birliksiz oyuncular da kullanabilir.
