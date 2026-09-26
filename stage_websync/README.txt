STAGE GAMING - stage_websync TEST/FIX

Bu surum once sadece heartbeat test eder. stage_loading exportuna bagimli degildir.

KURULUM:
1. stage_websync klasorunu resources icine at.
2. server.cfg: start stage_websync
3. Resource'u restart et.

MTA konsolunda SUNLARI gormen gerekir:
[stage_websync] WebSync baslatildi...
[stage_websync] heartbeat -> HTTP istegi gonderiliyor...
[stage_websync] heartbeat fetchRemote baslatildi.
ve sonrasinda:
[stage_websync] heartbeat OK | HTTP 200 | ...

Eger ACL hatasi gorursen:
/aclrequest allow stage_websync function.fetchRemote
veya ACL editorunde stage_websync icin function.fetchRemote yetkisini ver.

Eger HTTP 404: /api/mta_sync.php yok.
Eger HTTP 403: key uyusmuyor.
Eger HTTP 500/502: site PHP/hosting tarafinda hata var.
Eger HTTP 200 ama site degismiyorsa API gelen JSON'u DB'ye yazmiyordur.
