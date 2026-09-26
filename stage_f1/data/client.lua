------------------------
-----Panel Ortalama-----
------------------------
sC,sD = guiGetScreenSize()
C,D = 500,120
A = (sC/2) - (C/2)
B = (sD/2) - (D/2)
---------------
-----Panel-----
---------------
panel = guiCreateWindow(10, 10, 241, 100, "Oyuncu Kontrolleri", false)
guiWindowSetSizable(panel, false)
guiSetVisible(panel,false)
--------------------
-----Oyuncu God-----
--------------------
ozellik1 = guiCreateCheckBox(5, 30, 130, 25, "Ölümsüzlük", false, false, panel)
guiSetFont(ozellik1, "default-bold-small")
--------------------
-----Araç God-----
--------------------
ozellik5 = guiCreateCheckBox(5, 60, 100, 25, "Araç God", false, false, panel)
guiSetFont(ozellik5, "default-bold-small")
--------------------------------------
-----Ölümsüzlük Modu Fonksiyon-----
--------------------------------------
function D_Modu()
if guiCheckBoxGetSelected(ozellik1) == true then
triggerServerEvent("Alpha_Olma", getRootElement(), localPlayer)
outputChatBox("#0066ffÖlümsüzlük Modu #FFFFFFAktif", 255, 255, 255, true)
addEventHandler("onClientPlayerDamage", localPlayer, nodamage)
addEventHandler("onClientRender", root, render)
triggerServerEvent("Olumsuz_olma", getRootElement(), localPlayer)
else
outputChatBox("#0066ffÖlümsüzlük Modu #ffffffKapatıldı", 255, 255, 255, true)
triggerServerEvent("Alpha_Olmama", getRootElement(), localPlayer)
removeEventHandler("onClientPlayerDamage", localPlayer, nodamage)
removeEventHandler("onClientRender", root, render)
triggerServerEvent("Olumsuz_Olmama", getRootElement(), localPlayer)
end
end
addEventHandler("onClientGUIClick", ozellik1, D_Modu, false)

function nodamage()
cancelEvent()
end

function render()
	if getPedWeaponSlot(localPlayer) ~= 0 then
	setPedWeaponSlot(localPlayer,0)
	end	
end
---------------------------------
-----Arac Dokunulmazlık Modu-----
---------------------------------
function AracD_Modu()
if isPedInVehicle(localPlayer) == false then
outputChatBox("#0066ffHata : #ffffffHasarsız araç modu arabada değilken kullanılamaz", 255, 0, 0, true)
end
if isPedInVehicle(localPlayer) == true then
if guiCheckBoxGetSelected(ozellik5) == true then
triggerServerEvent("AracDokunulmazlik_Event", root, localPlayer)
outputChatBox("#0066ffHasarsız Araç Modu #ffffffAktif", 255, 255, 255, true)
else
triggerServerEvent("AracDokunulmazlikKapat_Event", root, localPlayer)
outputChatBox("#0066ffHasarsız Araç Modu #ffffffKapatıldı", 255, 255, 255, true)
end
else
guiCheckBoxSetSelected(ozellik5, false)
end
end
addEventHandler("onClientGUIClick", ozellik5, AracD_Modu, false)

---------------------------
-----Şişman/zayıf Modu-----
---------------------------
buton6 = guiCreateButton(170, 30, 67, 25, "Şişmanla", false, panel)
guiSetFont(buton6, "default-bold-small")
addEventHandler ( "onClientGUIClick",root,function()
if source==buton6 then
triggerServerEvent ("SismanlikUygula", localPlayer)
end
end) 

buton7 = guiCreateButton(170, 63, 67, 25, "Zayıfla", false, panel)
guiSetFont(buton7, "default-bold-small")
addEventHandler ( "onClientGUIClick",root,function()
if source==buton7 then
triggerServerEvent ("SismanlikSil", localPlayer)
end
end)

---------------------------
-----Kaslı Modu-----
---------------------------
buton4 = guiCreateButton(95, 30, 67, 25, "Kaslı Ol", false, panel)
guiSetFont(buton4, "default-bold-small")
addEventHandler ( "onClientGUIClick",root,function()
if source==buton4 then
triggerServerEvent ("KasUygula", localPlayer)
end
end) 

buton5 = guiCreateButton(95, 63, 67, 25, "Kaslı Olma", false, panel)
guiSetFont(buton5, "default-bold-small")
addEventHandler ( "onClientGUIClick",root,function()
if source==buton5 then
triggerServerEvent ("KasSil", localPlayer)
end
end)
------------------------------
-----Panel Aç/Kapat-----
---------------------------------
function ackapa()
if getElementData(localPlayer,"Turf") then return false end
if (guiGetVisible (panel) == true) then
guiSetVisible(panel, false)
showCursor(false)
elseif (guiGetVisible (panel) == false) then
guiSetVisible(panel, true)
showCursor(true)
end
end
bindKey("F1", "down", ackapa)
addCommandHandler ("fr", ackapa)