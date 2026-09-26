-----------------
-----Ön Ayar-----
-----------------
r = math.random(1,255)
g = math.random(1,255)
b = math.random(1,255)
----------------------------
-----Arac Dokunulmazlık-----
----------------------------
function AracDokunulmazlik_Modu(source)
if (isPedInVehicle(source ))then
if (isVehicleDamageProof(getPedOccupiedVehicle(source)) == false) then
setVehicleDamageProof(getPedOccupiedVehicle(source), true )
end
end
end
addEvent("AracDokunulmazlik_Event", true )
addEventHandler("AracDokunulmazlik_Event", resourceRoot, AracDokunulmazlik_Modu)

function AracDokunulmazlikKapat_Modu(source)
if (isPedInVehicle (source)) then
setVehicleDamageProof(getPedOccupiedVehicle(source), false )
end
end
addEvent("AracDokunulmazlikKapat_Event", true)
addEventHandler("AracDokunulmazlikKapat_Event", resourceRoot, AracDokunulmazlikKapat_Modu)
----------------------------
-----Ölümsüzlük Şeffaf-----
----------------------------
addEvent("setElementAlpha",true)
addEventHandler("setElementAlpha", root, function(alpha)
	local alpha = alpha or 255
	setElementAlpha(client,alpha)
end)
----------------------------
-----Ölümsüzlük-----
----------------------------
kontroller = {
	"fire", -- ateş
	"aim_weapon", -- nişan alma
	"next_weapon", -- sonraki silaha geçiş
	"previous_weapon", -- önceki silaha geçiş
}

function Olumsuz_olma(olumsuzol)
if isElement(olumsuzol) and getElementType(olumsuzol) == "player" then -- eğer olumsuzol varsa ve tipi "player" ise
for i,kontrl in pairs(kontroller) do toggleControl(olumsuzol, kontrl, false) end -- kontroller tablosundaki kontrolleri devredışı bırakıyoz
end
end
addEvent("Olumsuz_olma",true)
addEventHandler("Olumsuz_olma", resourceRoot, Olumsuz_olma)

function Olumsuz_Olmama(olumsuzolma)
if isElement(olumsuzolma) and getElementType(olumsuzolma) == "player" then -- eğer olumsuzolma varsa ve tipi "player" ise
for i,kontrl in pairs(kontroller) do toggleControl(olumsuzolma, kontrl, true) end -- kontroller tablosunda kontrolleri aktifleştiriyoruz
end
end
addEvent("Olumsuz_Olmama",true)
addEventHandler("Olumsuz_Olmama", resourceRoot, Olumsuz_Olmama)

function Alpha_Olma(source)
if not (getElementAlpha(source) == 150) then
setElementAlpha(source, 150)
end
end
addEvent("Alpha_Olma",true)
addEventHandler("Alpha_Olma", resourceRoot, Alpha_Olma)

function Alpha_Olmama(source)
if (getElementAlpha(source) == 150) then
setElementAlpha(source, 255)
end
end
addEvent("Alpha_Olmama",true)
addEventHandler("Alpha_Olmama", resourceRoot, Alpha_Olmama)
----------------------
-----Şişman/Zayıf-----
----------------------
function SismanlikUygula()
if not (getElementModel(source) == 0) then
return outputChatBox("CJ Karakterine İhtiyacın Var", source, 0, 102, 255)
end
--outputChatBox("#0066ffCJ Karakterin #0066ffŞişman #FFFFFFOldu", source, 190, 190, 190, true)
setPedStat(source, 21, 999)
end
addEvent ("SismanlikUygula", true)
addEventHandler ("SismanlikUygula", getRootElement(), SismanlikUygula)

function SismanlikSil()
if not (getElementModel(source) == 0) then
return outputChatBox("CJ Karakterine İhtiyacın Var", source, 0, 102, 255)
end
--outputChatBox("#0066ffCJ Karakterin #0066ffZayıf #FFFFFFOldu", source, 190, 190, 190, true)
setPedStat(source, 21, 1)
end
addEvent ("SismanlikSil", true)
addEventHandler ("SismanlikSil", getRootElement(), SismanlikSil)
----------------------
-----Kaslı/Kassız-----
----------------------
function KasUygula()
if not (getElementModel(source) == 0) then
return outputChatBox("CJ (Carl Johnson) olmalısın.", source, 0, 102, 255)
end
--outputChatBox("#0066ffKas #ffffffDüzeyini Değiştirdin.", source, 190, 190, 190, true)
setPedStat(source, 23, 999)
end
addEvent ("KasUygula", true)
addEventHandler ("KasUygula", getRootElement(), KasUygula)

function KasSil()
if not (getElementModel(source) == 0) then
return outputChatBox("CJ (Carl Johnson) olmalısın.", source, 0, 102, 255)
end
--outputChatBox("#0066ffKas #ffffffDüzeyini Değiştirdin.", source, 190, 190, 190, true)
setPedStat(source, 23, 1)
end
addEvent ("KasSil", true)
addEventHandler ("KasSil", getRootElement(), KasSil)