STAGE ADMIN - FIXED BUILD

Bu sürümde:
- Rütbeler serial bazlı SQLite'a kalıcı kaydedilir.
- /setrank ve panelden verilen kalıcı rütbe restart sonrası korunur.
- Alt rütbe permissionları üst rütbelere miras kalır. SuperAdmin/Admin kick/ban vb. işlemleri kaybetmez.
- Oyuncu hedefi exact/ID/partial name ile daha sağlam bulunur.
- Kick/Ban sonucu başarısızsa panelde neden gösterilir.
- Report üstlenme/kapatma/not, ban kaldırma ve diğer işlemlerden sonra panel verileri anında yenilenir.
- Aktif report ve ban listeleri işlem sonrası canlı güncellenir.
- Ban/kick için MTA ACL'de stage_admin resource'ına function.kickPlayer yetkisi verilmelidir.

ÖNEMLİ ACL:
ACL panelinizden veya acl.xml üzerinden stage_admin resource'ına en az:
  function.kickPlayer

yetkisini verin. Aksi halde MTA kickPlayer çağrısını engeller; custom ban kaydı yine oluşabilir fakat oyuncu anında atılamaz.

Eski stage_admin.db dosyanızı silmeyin. Script mevcut veritabanını kullanır.
