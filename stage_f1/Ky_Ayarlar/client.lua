

sGenislik,sUzunluk = guiGetScreenSize()
Genislik,Uzunluk = 250,355
X = (sGenislik/2) - (Genislik/2)
Y = (sUzunluk/2) - (Uzunluk/2)

panel = guiCreateWindow(X - 240,Y - 135,Genislik + 30,Uzunluk + 190,"#Ayasofya - Ayarlar Panel", false)
guiSetVisible(panel,false)

shadertab = guiCreateButton(2,40,276,20,"Grafik Ayarları", false, panel, "333333", "FFD700")

hdaraba = guiCreateCheckBox(30, 70, 120, 30,"HD Araçlar", true,false, panel)
gokyuzu = guiCreateCheckBox(170, 70, 120, 30,"HD Gökyüzü", false,false, panel)
deniz = guiCreateCheckBox(170, 105, 70, 30,"HD Deniz", false,false, panel)
yollar_kapat = guiCreateCheckBox(30, 105, 110, 30,"HD Yollar", false,false, panel)
kar_aktif = guiCreateCheckBox(30, 140, 110, 30,"Kar Modu", false,false, panel)
shader_detay = guiCreateCheckBox(170, 140, 110, 30,"Oyun Detayı", false,false, panel)

oyuncutab = guiCreateButton(2,180,276,20,"Oyuncu Ayarları", false, panel, "333333", "FFD700")

--olumsuzluk = guiCreateCheckBox(30, 210, 85, 30,"Ölümsüzlük", false,false, panel)
teleportlanma = guiCreateCheckBox(170, 210, 70, 30,"Işınlanmama", false,false, panel)
bicaklanmama = guiCreateCheckBox(30, 245, 85, 30,"Bıçaklanmama", false,false, panel)
skinkaydet = guiCreateCheckBox(170, 245, 110, 30,"Skin Kaydet", false,false, panel)

aractab = guiCreateButton(2,290,276,20,"Araç Ayarları", false, panel, "333333", "FFD700")

aracgodmode = guiCreateCheckBox(30, 320, 110, 30,"Araç Godmode", false,false, panel)
arachayalet = guiCreateCheckBox(170, 320, 110, 30,"Araç Hayalet", false,false, panel)
 --aracrainbow = guiCreateCheckBox(30, 355, 110, 30,"Araç Rainbow", false,false, panel)
araclastik = guiCreateCheckBox(30, 355, 110, 30,"Renkli Lastik İzi", false,false, panel)
guiCheckBoxSetSelected(araclastik, true)
--guiSetEnabled(aracrainbow,false)
araba_ses = guiCreateCheckBox(170, 355, 110, 30,"Araç Sesleri", false,false, panel)

oyunayar = guiCreateButton(2,395,276,20,"Sunucu Ayarları", false, panel, "333333", "FFD700")

--renkli_teker = guiCreateCheckBox(30, 495, 110, 30,"RGB Lastik İzi", false,false, panel)
gorusuzak = guiCreateCheckBox(30, 460, 110, 30,"Görüş Uzaklığı", false,false, panel)
parlakayar = guiCreateCheckBox(170, 460, 110, 30,"Oyun Parlaklık", false,false, panel)


giris_mesaj = guiCreateCheckBox(30, 425, 115, 30,"Giriş/Çıkış Bildirim", false,false, panel)
kill_mesaj = guiCreateCheckBox(170, 425, 110, 30,"Ölme Bildirim", false,false, panel)

harita_gosterge = guiCreateCheckBox(170, 495, 110, 30,"Hud/Radar", false,false, panel)

--kar_aktif = guiCreateButton(10,450,260,25,"Kar Modu Aktifleştir", false, panel, "333333", "FFD700")

addEventHandler("onClientGUIClick", araclastik, function()
	if source == araclastik then
		if guiCheckBoxGetSelected(araclastik) == true then
			setElementData(localPlayer, "arac:lastik:ayar", true)
			triggerEvent("onClientStartShader", root)
		else
			setElementData(localPlayer, "arac:lastik:ayar", false)
			triggerEvent("onClientStopShader", root)
		end
	end
end)

function renkli_teker ()
if guiCheckBoxGetSelected(rgbTeker) == true then
local durum = 1
triggerEvent("Lastik:aktif", localPlayer)
triggerServerEvent("LastikMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("LastikMesaj",localPlayer,durum)
triggerEvent("Lastik:pasif", localPlayer)
end
end
addEventHandler("onClientGUIClick", rgbTeker, renkli_teker, false)

function oldurme_mesaj ()
if guiCheckBoxGetSelected(kill_mesaj) == true then
local durum = 1
setElementData(localPlayer,"oldurme:mesaj",false)
triggerServerEvent("OldurmeMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("OldurmeMesaj",localPlayer,durum)
setElementData(localPlayer,"oldurme:mesaj",true)
end
end
addEventHandler("onClientGUIClick", kill_mesaj, oldurme_mesaj, false)

function giris_mesajlar ()
if guiCheckBoxGetSelected(giris_mesaj) == true then
local durum = 1
setElementData(localPlayer,"giris:mesaj",false)
triggerServerEvent("GirisMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("GirisMesaj",localPlayer,durum)
setElementData(localPlayer,"giris:mesaj",true)
end
end
addEventHandler("onClientGUIClick", giris_mesaj, giris_mesajlar, false)

function kar_ayar ()
if guiCheckBoxGetSelected(kar_aktif) == true then
local durum = 1
triggerEvent("karmodu:aktif", localPlayer)
triggerServerEvent("HDkarMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("HDkarMesaj",localPlayer,durum)
triggerEvent("karmodu:pasif", localPlayer)
end
end
addEventHandler("onClientGUIClick", kar_aktif, kar_ayar, false)


function radar_gosterge ()
if guiCheckBoxGetSelected(harita_gosterge) == true then
local durum = 1
triggerServerEvent("HaritaMesaj",localPlayer,durum)
setPlayerHudComponentVisible("radar", true)
else
local durum = 0
triggerServerEvent("HaritaMesaj",localPlayer,durum)
setPlayerHudComponentVisible("radar", false)
end
end
addEventHandler("onClientGUIClick", harita_gosterge, radar_gosterge, false)

function yollar_script ()
if guiCheckBoxGetSelected(yollar_kapat) == true then
local durum = 0
triggerServerEvent("YollarMesaj",localPlayer,durum)
setElementData(localPlayer,"yollar_durum",true)
triggerEvent("yol:aktif",localPlayer)
else
local durum = 1
setElementData(localPlayer,"yollar_durum",false)
triggerServerEvent("YollarMesaj",localPlayer,durum)
triggerEvent("yol:deaktif",localPlayer)
end
end
addEventHandler("onClientGUIClick", yollar_kapat, yollar_script, false)


function arabases_ayar ()
if guiCheckBoxGetSelected(araba_ses) == true then
local durum = 1
triggerEvent("arabases:ayar", localPlayer,durum)
triggerServerEvent("SESarabaMesaj",localPlayer,durum)
else
local durum = 0
triggerEvent("arabases:ayar", localPlayer,durum)
triggerServerEvent("SESarabaMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", araba_ses,  arabases_ayar, false)

addEvent("ayarlar:panel", true)
addEventHandler("ayarlar:panel",root,function()
guiSetVisible(panel, not guiGetVisible(panel))
end)

texShader = dxCreateShader ( "Ky_Ayarlar/texreplace.fx" )

function kapat ()
guiSetVisible(panel,false)
showCursor(false)
end
bindKey("F1", "down", kapat)

function selected ()
guiCheckBoxSetSelected(dumankapat,true)
guiCheckBoxSetSelected(araba_ses,true)
guiCheckBoxSetSelected(giris_mesaj,true)
guiCheckBoxSetSelected(kill_mesaj,true)
guiCheckBoxSetSelected(harita_gosterge,true)
end
addEventHandler("onClientResourceStart",resourceRoot,selected)

function silah_kontrol ()
if ( getElementData(localPlayer,"olumsuzluk:oyuncu") == true ) then
if getPedWeaponSlot(localPlayer) ~= 0 then
setPedWeaponSlot(localPlayer,0)
end
end
end		
addEventHandler ( "onClientRender", getRootElement(), silah_kontrol)

function oyuncu_hasar ()
if ( getElementData(localPlayer,"olumsuzluk:oyuncu") == true ) then
cancelEvent()
end
end
addEventHandler("onClientPlayerDamage", getRootElement(), oyuncu_hasar)
	
function teleport_ac ()
local state = guiCheckBoxGetSelected(teleportlanma)
triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"warping",state)
triggerServerEvent("TeleportMesaj",localPlayer)
end
addEventHandler("onClientGUIClick", teleportlanma, teleport_ac, false)

function bicaklar_ac ()
local state = guiCheckBoxGetSelected(bicaklanmama)
triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"knifing",state)
triggerServerEvent("BicakMesaj",localPlayer)
end
addEventHandler("onClientGUIClick", bicaklanmama, bicaklar_ac, false)

function arac_hayalet ()
local state = guiCheckBoxGetSelected(arachayalet)
triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"ghostmode",state)
triggerServerEvent("HayaletMesaj",localPlayer)
end
addEventHandler("onClientGUIClick", arachayalet, arac_hayalet, false)

function skin_ayar ()
if guiCheckBoxGetSelected(skinkaydet) == true then
local durum = 1
triggerServerEvent("SkinMesaj",localPlayer,durum)
setElementData(localPlayer,"skin:kaydet",true)
else
local durum = 0
triggerServerEvent("SkinMesaj",localPlayer,durum)
setElementData(localPlayer,"skin:kaydet",false)
end
end
addEventHandler("onClientGUIClick", skinkaydet, skin_ayar, false)

function duman_ayar ()
if guiCheckBoxGetSelected(dumankapat) == true then
engineRemoveShaderFromWorldTexture(texShader,"collisionsmoke")
local durum = 1
triggerServerEvent("DumanMesaj",localPlayer,durum)
else
local durum = 0
engineApplyShaderToWorldTexture(texShader,"collisionsmoke")
triggerServerEvent("DumanMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", dumankapat, duman_ayar, false)

function oyun_parlaklik ()
if guiCheckBoxGetSelected(parlakayar) == true then
setFogDistance(250)
local durum = 1
triggerServerEvent("ParlaklikMesaj",localPlayer,durum)
else
local durum = 0
setFogDistance(50)
triggerServerEvent("ParlaklikMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", parlakayar, oyun_parlaklik, false)

function gorus_uzaklik ()
if guiCheckBoxGetSelected(gorusuzak) == true then
setFarClipDistance(2000)
local durum = 1
triggerServerEvent("UzaklikMesaj",localPlayer,durum)
else
local durum = 0
setFarClipDistance(650)
triggerServerEvent("UzaklikMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", gorusuzak, gorus_uzaklik, false)

function arac_rainbow ()
if guiCheckBoxGetSelected(aracrainbow) == true then
triggerServerEvent("onColor", localPlayer, 200, false)
local durum = 1
triggerServerEvent("RainbowMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("onColorStop", localPlayer)
triggerServerEvent("RainbowMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", aracrainbow, arac_rainbow, false)

function arac_godmode ()
if guiCheckBoxGetSelected(aracgodmode) == true then
triggerServerEvent("AracDokunulmazlik_Event", root, localPlayer)
local durum = 1
triggerServerEvent("GodmodeMesaj",localPlayer,durum)
else
triggerServerEvent("AracDokunulmazlikKapat_Event", root, localPlayer)
local durum = 0
triggerServerEvent("GodmodeMesaj",localPlayer,durum)
end
end
addEventHandler("onClientGUIClick", aracgodmode, arac_godmode, false)

function olumsuzluk_ac ()
if guiCheckBoxGetSelected(olumsuzluk) == true then
setTimer(function() -- saniye olayı
setElementData(localPlayer,"olumsuzluk:oyuncu",true)
local durum = 1
triggerServerEvent("GodMesaj",localPlayer,durum)
triggerServerEvent("setElementAlpha",localPlayer,100)
setElementData(localPlayer,"Ust_durum","Ölümsüz")
end,4000,1)
else
setElementData(localPlayer,"olumsuzluk:oyuncu",false)
setElementData(localPlayer,"Ust_durum",nil)
local durum = 0
triggerServerEvent("GodMesaj",localPlayer,durum)
triggerServerEvent("setElementAlpha",localPlayer,255)
end
end
addEventHandler("onClientGUIClick", olumsuzluk, olumsuzluk_ac, false)

function hdaraclar()
if guiCheckBoxGetSelected(hdaraba) == true then
triggerEvent( "switchCarPaintReflect", resourceRoot, true)
local durum = 1
triggerServerEvent("HDaracMesaj",localPlayer,durum)
else
local durum = 0
triggerServerEvent("HDaracMesaj",localPlayer,durum)
triggerEvent( "switchCarPaintReflect", resourceRoot, false)
end
end
addEventHandler("onClientGUIClick", hdaraba, hdaraclar, false)

function hdgokyuzu()
if guiCheckBoxGetSelected(gokyuzu) == true then
triggerEvent( "switchSkyAlt", resourceRoot, true )
local durum = 1
triggerServerEvent("HDairMesaj",localPlayer,1)
else
local durum = 0
triggerServerEvent("HDairMesaj",localPlayer,0)
triggerEvent( "switchSkyAlt", resourceRoot, false )
end
end
addEventHandler("onClientGUIClick", gokyuzu, hdgokyuzu, false)

function hddeniz()
if guiCheckBoxGetSelected(deniz) == true then
local durum = 1
triggerServerEvent("HDwaterMesaj",localPlayer,durum)
shader_water_enabled(1)
else
local durum = 0
triggerServerEvent("HDwaterMesaj",localPlayer,durum)
shader_water_enabled(0)
end
end
addEventHandler("onClientGUIClick", deniz, hddeniz, false)

function shader_detaylar()
if guiCheckBoxGetSelected(shader_detay) == true then
local durum = 1
triggerServerEvent("HDdetaylar",localPlayer,durum)
triggerEvent("detaylar:ac",localPlayer)
else
local durum = 0
triggerServerEvent("HDdetaylar",localPlayer,durum)
triggerEvent("detaylar:kapat",localPlayer)
end
end
addEventHandler("onClientGUIClick", shader_detay, shader_detaylar, false)

function switchCarPaintRefLite( isCPRefOn )
	outputDebugString( "switchCarPaintRefLite: " .. tostring(isCPRefOn) )
	if isCPRefOn then
		startCarPaintRefLite()
	else
		stopCarPaintRefLite()
	end
end
addEvent( "switchCarPaintRefLite", true )
addEventHandler( "switchCarPaintRefLite", resourceRoot, switchCarPaintRefLite )

function switchSkyAlt( sbaOn )
	outputDebugString( "switchSkyAlt: " .. tostring(sbaOn) )
	if sbaOn then
		startShaderResource()
	else
		stopShaderResource()
	end
end
addEvent( "switchSkyAlt", true )
addEventHandler( "switchSkyAlt", resourceRoot, switchSkyAlt )