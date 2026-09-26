BİRLEŞME NOTLARI — stage_illegalmec (tuning) + drp_performance (tablet)
======================================================================

KURULUM
-------
1) Eski "drp_performance" kaynağını sunucudan kaldır (stop + sil).
   Artık gerek yok, içeriği bu kaynağa taşındı.
2) Bu klasörü sunucunda "stage_illegalmec" olarak değiştir/üzerine yaz.
3) refresh + restart stage_illegalmec

DOSYA DÜZENİ
------------
config.lua        : PAYLAŞILAN ayarlar (komutlar, parça fiyatları, depo, eşleme tablosu)
db.lua            : ORTAK veritabanı katmanı (tüm tablolar burada oluşur)
server.lua        : Tuning mantığı (handling, dyno, satın alma, motor patlama)
client.lua        : Tuning arayüzü (marker, panel, dyno, launch, air)
tablet_server.lua : Tablet hesapları, giriş, duty, export fonksiyonları
tablet_client.lua : Tablet arayüzü
depo.lua          : Dükkan deposu (envanter)
kumanda.lua       : Araç kumandası arayüzü

YAPILAN DEĞİŞİKLİKLER
---------------------
1) TEK VERİTABANI: Tuning tarafı "exports.stage_core:execAsync / :query"
   çağırıyordu, ama stage_core böyle bir fonksiyon EXPORT ETMİYOR
   (sadece CoreDBQuery/CoreDBExec var) — yani o kayıtlar hiç çalışmıyordu.
   Artık her şey tablet tarafının da kullandığı stage_mysql bağlantısından
   gidiyor (db.lua > getStageDB()).

2) HATA DÜZELTMESİ (araciYukle): fonksiyon içinde tanımsız "veh" ve "db"
   değişkenleri kullanılıyordu, araç parçaları araca binerken hiç
   yüklenmiyordu. Düzeltildi (dbQuery + dbPoll ile).

3) SQL UYUMU: "INSERT OR REPLACE" (SQLite söz dizimi) MySQL'de çalışmaz;
   "REPLACE INTO" olarak değiştirildi ve tek fonksiyona toplandı:
   parcalariKaydet(arac).

4) /parcatak ARTIK ÇALIŞIYOR: drpParcaTak() placeholder'dı ("bu özellik
   henüz yapılandırılmadı" diyordu). Şimdi tablet parçasını tuning
   parçasına çevirip araca gerçekten takıyor: handling uygulanıyor ve
   arac_parcalar tablosuna kaydediliyor.
   Eşleme tablosu: config.lua > CONFIG.PARCA_ESLEME (istediğin gibi düzenle)
   NOT: Tuning listesinde ayrı bir "fren" parçası olmadığı için fren
   seviyeleri en yakın parçalara eşlendi; oradan değiştirebilirsin.

5) ÇAKIŞMA TEMİZLİĞİ: kumanda.lua içindeki drawStyledText fonksiyonu,
   tablet_client.lua'daki aynı isimli fonksiyonu ezmemesi için "local"
   yapıldı. client.lua ve server.lua "client/server" olarak iki kez
   olmasın diye tablet dosyaları tablet_client.lua / tablet_server.lua
   adıyla eklendi.

6) PARA/YETKİ: İstediğin gibi bırakıldı — tuning satın alma oyuncunun
   kendi parasından (stage_economy) düşüyor, dükkan/eleman şartı yok.

KOMUTLAR (hepsi tek kaynakta)
-----------------------------
Tuning : /mycar /egzoz /karaduman /air /stagebul /fullcar (admin)
Tablet : /tablet /tabletkur /elemanekle /depoekle /parcatak /kumanda
