gInteriorName, gOwnerName, gBuyMessage, gBizMessage = nil

timer = nil

intNameFont = dxCreateFont(":drp_ui/public/fonts/UbuntuBold.ttf", 30) or "default"

function showIntName(name, ownerName, inttype, cost, ID)
	if isElement(gInteriorName) and guiGetVisible(gInteriorName) then
		if timer and isTimer(timer) then
			killTimer(timer)
			timer = nil
		end

		destroyElement(gInteriorName)
		gInteriorName = nil

		if isElement(gOwnerName) then
			destroyElement(gOwnerName)
			gOwnerName = nil
		end

		if gBuyMessage then
			destroyElement(gBuyMessage)
			gBuyMessage = nil
		end

		if gBizMessage then
			destroyElement(gBizMessage)
			gBizMessage = nil
		end
	end

	if name == "Hiçbiri" then
		return
	elseif name then
		if inttype == 3 then
			gInteriorName = guiCreateLabel(0.0, 0.84, 1.0, 0.3, tostring(name), true)
			guiSetFont(gInteriorName, intNameFont)
			guiLabelSetHorizontalAlign(gInteriorName, "center", true)
			guiSetAlpha(gInteriorName, 0.0)

			if
				(exports.drp_integration:isPlayerTrialAdmin(localPlayer) and getElementData(localPlayer, "duty_admin"))
				or exports.drp_item:hasItem(localPlayer, 4, ID)
			then
				gOwnerName = guiCreateLabel(0.0, 0.90, 1.0, 0.3, "Kiralayan: " .. tostring(ownerName), true)
				guiSetFont(gOwnerName, "default")
				guiLabelSetHorizontalAlign(gOwnerName, "center", true)
				guiSetAlpha(gOwnerName, 0.0)
			end
		else
			gInteriorName = guiCreateLabel(0.0, 0.84, 1.0, 0.3, tostring(name), true)
			guiSetFont(gInteriorName, intNameFont)
			guiLabelSetHorizontalAlign(gInteriorName, "center", true)
			guiSetAlpha(gInteriorName, 0.0)

			if
				(exports.drp_integration:isPlayerTrialAdmin(localPlayer) and getElementData(localPlayer, "duty_admin"))
				or exports.drp_item:hasItem(localPlayer, 4, ID)
				or exports.drp_item:hasItem(localPlayer, 5, ID)
			then
				gOwnerName = guiCreateLabel(0.0, 0.90, 1.0, 0.3, "Sahibi: " .. tostring(ownerName), true)
				guiSetFont(gOwnerName, "default")
				guiLabelSetHorizontalAlign(gOwnerName, "center", true)
				guiSetAlpha(gOwnerName, 0.0)
			end
		end
		if (ownerName == "Hiçbiri") and (inttype == 3) then
			gBuyMessage = guiCreateLabel(
				0.0,
				0.915,
				1.0,
				0.3,
				"₺" .. tostring(exports.drp_global:formatMoney(cost)) .. " kiralamak için F tuşuna basın.",
				true
			)
			guiSetFont(gBuyMessage, "default")
			guiLabelSetHorizontalAlign(gBuyMessage, "center", true)
			guiSetAlpha(gBuyMessage, 0.0)
		elseif (ownerName == "Hiçbiri") and (inttype < 2) then
			gBuyMessage = guiCreateLabel(
				0.0,
				0.915,
				1.0,
				0.3,
				"₺" .. tostring(exports.drp_global:formatMoney(cost)) .. " satın almak için F tuşuna basın.",
				true
			)
			guiSetFont(gBuyMessage, "default")
			guiLabelSetHorizontalAlign(gBuyMessage, "center", true)
			guiSetAlpha(gBuyMessage, 0.0)
		else
			local msg = "Girmek için F tuşuna basın."
			gBuyMessage = guiCreateLabel(0.0, 0.915, 1.0, 0.3, msg, true)
			guiSetFont(gBuyMessage, "default")
			guiLabelSetHorizontalAlign(gBuyMessage, "center", true)
		end

		timer = setTimer(fadeMessage, 50, 20, true)
	end
end
addEvent("displayInteriorName", true)
addEventHandler("displayInteriorName", root, showIntName)

function fadeMessage(fadein)
	local alpha = guiGetAlpha(gInteriorName)

	if fadein and alpha then
		local newalpha = alpha + 0.05
		guiSetAlpha(gInteriorName, newalpha)
		if isElement(gOwnerName) then
			guiSetAlpha(gOwnerName, newalpha)
		end

		if gBuyMessage then
			guiSetAlpha(gBuyMessage, newalpha)
		end

		if gBizMessage then
			guiSetAlpha(gBizMessage, newalpha)
		end

		if newalpha >= 1.0 then
			timer = setTimer(hideIntName, 15000, 1)
		end
	elseif alpha then
		local newalpha = alpha - 0.05
		guiSetAlpha(gInteriorName, newalpha)
		if isElement(gOwnerName) then
			guiSetAlpha(gOwnerName, newalpha)
		end

		if gBuyMessage then
			guiSetAlpha(gBuyMessage, newalpha)
		end

		if gBizMessage then
			guiSetAlpha(gBizMessage, newalpha)
		end

		if newalpha <= 0.0 then
			destroyElement(gInteriorName)
			gInteriorName = nil

			if isElement(gOwnerName) then
				destroyElement(gOwnerName)
				gOwnerName = nil
			end

			if gBuyMessage then
				destroyElement(gBuyMessage)
				gBuyMessage = nil
			end

			if gBizMessage then
				destroyElement(gBizMessage)
				gBizMessage = nil
			end
		end
	end
end

function hideIntName()
	setTimer(fadeMessage, 50, 20, false)
end

function createBlipAtXY(inttype, x, y)
	if inttype and tonumber(inttype) then
		if inttype == 3 then
			inttype = 0
		end
		createBlip(x, y, 10, 31 + inttype, 2, 255, 0, 0, 255, 0, 300)
	end
end
addEvent("createBlipAtXY", true)
addEventHandler("createBlipAtXY", root, createBlipAtXY)

function removeBlipAtXY(inttype, x, y)
	if inttype == 3 or type(inttype) ~= "number" then
		inttype = 0
	end
	for key, value in ipairs(getElementsByType("blip")) do
		local bx, by, bz = getElementPosition(value)
		local icon = getBlipIcon(value)

		if icon == 31 + inttype and bx == x and by == y then
			destroyElement(value)
			break
		end
	end
end
addEvent("removeBlipAtXY", true)
addEventHandler("removeBlipAtXY", root, removeBlipAtXY)

local cache = {}

function findProperty(thePlayer, dimension)
	local dbid = tonumber(dimension) or getElementDimension(thePlayer)
	if dbid > 0 then
		if cache[dbid] then
			return unpack(cache[dbid])
		end

		local entrance, exit = nil, nil
		local res = exports.drp_global:isResourceRunning("drp_interior-load")

		if res then
			for key, value in pairs(getElementsByType("pickup", res)) do
				if getElementData(value, "dbid") == dbid then
					entrance = value
					break
				end
			end
		end
		if entrance then
			cache[dbid] = { dbid, entrance }
			return dbid, entrance
		end
	end
	cache[dbid] = { 0 }
	return 0
end

function findParent(element, dimension)
	local dbid, entrance = findProperty(element, dimension)
	return entrance
end

addEvent("setPlayerInsideInterior", true)
addEventHandler("setPlayerInsideInterior", root, function(targetLocation, targetInterior, furniture, camerafade)
	setTimer(function()
		if camerafade then
			fadeCamera(true)
		end
	end, 2000, 1)

	for i = 0, 4 do
		setInteriorFurnitureEnabled(i, furniture and true or false)
	end
end)

addEvent("setPlayerInsideInterior2", true)
addEventHandler("setPlayerInsideInterior2", root, function(targetLocation, targetInterior, furniture)
	if inttimer then
		return
	end

	targetLocation = tempFix(targetLocation)

	if targetLocation.dim ~= 0 then
		setGravity(0)
	end

	setElementFrozen(localPlayer, true)
	setElementPosition(localPlayer, targetLocation.x, targetLocation.y, targetLocation.z, true)

	local currentInt = getElementInterior(localPlayer)
	local currentDim = getElementDimension(localPlayer)

	if targetLocation.int ~= currentInt then
		setElementInterior(localPlayer, targetLocation.int)
	end

	if targetLocation.dim ~= currentDim then
		setElementDimension(localPlayer, targetLocation.dim)
	end

	setCameraInterior(targetLocation.int)

	local rot = targetLocation.rot or targetLocation[INTERIOR_ANGLE]
	if rot then
		setPedRotation(localPlayer, rot)
	end

	for i = 0, 4 do
		setInteriorFurnitureEnabled(i, furniture and true or false)
	end

	inttimer = setTimer(onPlayerPutInInteriorSecond, 1000, 1, targetLocation.dim, targetLocation.int)

	if false and targetInterior then
		local adminnote = tostring(getElementData(targetInterior, "adminnote"))
		if
			string.sub(tostring(adminnote), 1, 8) ~= "userdata"
			and adminnote ~= "\n"
			and getElementData(localPlayer, "duty_admin")
		then
			outputChatBox("[INT MONİTÖR]: " .. adminnote:gsub("\n", " ") .. "[..]", 255, 0, 0)
			outputChatBox(
				"Detaylar için '/checkint " .. getElementData(targetInterior, "dbid") .. "' komutunu kullanın.",
				255,
				255,
				0
			)
		end
	end
end)

function onPlayerPutInInteriorSecond(dimension, interior)
	setCameraInterior(interior)

	local safeToSpawn = true
	if getResourceFromName("drp_object") then
		safeToSpawn = exports.drp_object:isSafeToSpawn()
	end

	if safeToSpawn then
		inttimer = nil
		if isElement(localPlayer) then
			setTimer(onPlayerPutInInteriorThird, 1000, 1)
		end
	else
		setTimer(onPlayerPutInInteriorSecond, 1000, 1, dimension, interior)
	end
end

function onPlayerPutInInteriorThird()
	setGravity(0.008)
	setElementFrozen(localPlayer, false)
	inttimer = nil
end

local purchaseProperty = {
	button = {},
	window = {},
	label = {},
	rad = {},
}

local incompatibleForFurniture = {
	[66] = true,
}

function purchasePropertyGUI(interior, cost, isHouse, isRentable, neighborhood)
	if isElement(purchaseProperty.window[1]) then
		closePropertyGUI()
	end

	local intID = getElementData(interior, "dbid")
	local viewstate = getElementData(localPlayer, "viewingInterior")
	if viewstate then
		triggerServerEvent("endViewPropertyInterior", localPlayer, localPlayer)
		return
	end
	showCursor(true)

	purchaseProperty.window[1] = guiCreateWindow(607, 396, 499, 210, "Mülk Satın Alma", false)
	guiWindowSetSizable(purchaseProperty.window[1], false)
	guiSetAlpha(purchaseProperty.window[1], 0.89)
	exports.drp_global:centerWindow(purchaseProperty.window[1])

	local margin = 13
	local btnW = 113
	local btnPosX = margin
	local fTable = {}

	for k, v in pairs(getElementData(localPlayer, "faction")) do
		if exports.drp_faction:hasMemberPermissionTo(localPlayer, k, "manage_interiors") then
			fTable[k] = v
		end
	end

	local btnTextSet = { "Nakit kullanarak satın al", "Banka yoluyla satın al" }
	if exports.drp_item:hasItem(localPlayer, 262) and (cost <= 40000) and isHouse and not isRentable then
		btnTextSet = { "Token ile satın al", "Banka yoluyla satın al" }
		exports.drp_infobox:addBox(
			"error",
			"Yeni bir karakter kullanıyorsunuz, bu yüzden karakterinizde bu evi satın almak için kullanabileceğiniz bir ev jetonu var."
		)
	end

	if size(fTable) > 0 then
		btnTextSet = { "Kendin için\nsatın al", "Birlik için\nsatın al" }
	end

	purchaseProperty.button[1] =
		guiCreateButton(btnPosX, 156, btnW, 43, btnTextSet[1], false, purchaseProperty.window[1])
	guiSetProperty(purchaseProperty.button[1], "NormalTextColour", "FFAAAAAA")
	btnPosX = btnPosX + btnW + margin / 2
	purchaseProperty.button[2] =
		guiCreateButton(btnPosX, 156, btnW, 43, btnTextSet[2], false, purchaseProperty.window[1])
	guiSetProperty(purchaseProperty.button[2], "NormalTextColour", "FFAAAAAA")
	btnPosX = btnPosX + btnW + margin / 2
	purchaseProperty.button[4] =
		guiCreateButton(btnPosX, 156, btnW, 43, "Mülk Önizleme", false, purchaseProperty.window[1])
	guiSetProperty(purchaseProperty.button[4], "NormalTextColour", "FFAAAAAA")
	btnPosX = btnPosX + btnW + margin / 2
	purchaseProperty.button[3] = guiCreateButton(btnPosX, 156, btnW, 43, "Kapat", false, purchaseProperty.window[1])
	guiSetProperty(purchaseProperty.button[3], "NormalTextColour", "FFAAAAAA")

	purchaseProperty.label[2] = guiCreateLabel(
		110,
		44,
		315,
		20,
		"Daha sonra ödeme yönteminizi seçebilirsiniz.",
		false,
		purchaseProperty.window[1]
	)
	purchaseProperty.label[3] = guiCreateLabel(20, 70, 88, 15, "Mülk Adı:", false, purchaseProperty.window[1])
	purchaseProperty.label[6] = guiCreateLabel(20, 90, 93, 15, "Komşu:", false, purchaseProperty.window[1])
	purchaseProperty.label[4] = guiCreateLabel(20, 110, 100, 15, "Fiyat:", false, purchaseProperty.window[1])
	purchaseProperty.label[5] = guiCreateLabel(250, 110, 73, 15, "Vergi:", false, purchaseProperty.window[1])
	purchaseProperty.label[11] = guiCreateLabel(
		20,
		130,
		315,
		15,
		"Mobilyalarınızın etkinleştirilmesini ister misiniz?",
		false,
		purchaseProperty.window[1]
	)

	purchaseProperty.label[7] = guiCreateLabel(117, 70, 400, 15, "", false, purchaseProperty.window[1])
	purchaseProperty.label[9] = guiCreateLabel(117, 90, 400, 15, "", false, purchaseProperty.window[1])
	purchaseProperty.label[8] = guiCreateLabel(117, 110, 91, 15, "", false, purchaseProperty.window[1])
	purchaseProperty.label[10] = guiCreateLabel(323, 110, 98, 15, "", false, purchaseProperty.window[1])

	purchaseProperty.rad[1] = guiCreateRadioButton(280, 128, 50, 20, "Evet", false, purchaseProperty.window[1])
	purchaseProperty.rad[2] = guiCreateRadioButton(330, 128, 50, 20, "Hayır", false, purchaseProperty.window[1])
	guiRadioButtonSetSelected(purchaseProperty.rad[1], true)

	if incompatibleForFurniture[getElementData(interior, "exit")[4]] then
		guiSetEnabled(purchaseProperty.rad[1], false)
		guiSetEnabled(purchaseProperty.rad[2], false)
	end

	guiSetFont(purchaseProperty.label[2], "default-bold-small")
	guiSetFont(purchaseProperty.label[3], "default-bold-small")
	guiSetFont(purchaseProperty.label[4], "default-bold-small")
	guiSetFont(purchaseProperty.label[5], "default-bold-small")
	guiSetFont(purchaseProperty.label[6], "default-bold-small")

	addEventHandler("onClientGUIClick", purchaseProperty.button[3], closePropertyGUI, false)

	addEventHandler("onClientGUIClick", purchaseProperty.button[1], function()
		local btnText = guiGetText(purchaseProperty.button[1])
		if btnText == "Nakit kullanarak satın al" then
			triggerServerEvent(
				"buyPropertyWithCash",
				localPlayer,
				interior,
				cost,
				isHouse,
				isRentable,
				guiRadioButtonGetSelected(purchaseProperty.rad[1])
			)
			closePropertyGUI()
		elseif btnText == "Token ile satın al" then
			triggerServerEvent(
				"buyPropertyWithToken",
				localPlayer,
				interior,
				guiRadioButtonGetSelected(purchaseProperty.rad[1])
			)
			closePropertyGUI()
		else
			btnTextSet = { "Nakit kullanarak satın al", "Banka yoluyla satın al", "Token ile satın al" }
			guiSetText(purchaseProperty.button[1], btnTextSet[1])
			guiSetText(purchaseProperty.button[2], btnTextSet[2])
			guiSetText(purchaseProperty.button[4], btnTextSet[3])
			guiSetEnabled(purchaseProperty.button[4], false)
			guiSetProperty(purchaseProperty.button[4], "NormalTextColour", "FF00FF00")

			if exports.drp_item:hasItem(localPlayer, 262) and (cost <= 40000) and isHouse and not isRentable then
				exports.drp_infobox:addBox(
					"error",
					"Yeni bir karakter kullanıyorsunuz, bu yüzden karakterinizde bu evi satın almak için kullanabileceğiniz bir ev jetonu var."
				)
				guiSetEnabled(purchaseProperty.button[4], true)
			end
		end
	end, false)

	addEventHandler("onClientGUIClick", purchaseProperty.button[2], function()
		local btnText = guiGetText(purchaseProperty.button[2])
		if btnText == "Banka yoluyla satın al" then
			triggerServerEvent(
				"buyPropertyWithBank",
				localPlayer,
				interior,
				cost,
				isHouse,
				isRentable,
				guiRadioButtonGetSelected(purchaseProperty.rad[1])
			)
			closePropertyGUI()
		else
			if isRentable then
				outputChatBox("[!]#FFFFFF Şu anda birlikler kiralanabilir mülklere sahip olamıyor.", 255, 0, 0, true)
			else
				startBuyingForFaction(interior, cost, isHouse, guiRadioButtonGetSelected(purchaseProperty.rad[1]))
			end
		end
	end, false)

	addEventHandler("onClientGUIClick", purchaseProperty.button[4], function()
		local btnText = guiGetText(purchaseProperty.button[4])
		if btnText == "Mülk Önizleme" then
			triggerServerEvent("viewPropertyInterior", localPlayer, intID)
			closePropertyGUI()
		else
			triggerServerEvent(
				"buyPropertyWithToken",
				localPlayer,
				interior,
				guiRadioButtonGetSelected(purchaseProperty.rad[1])
			)
			closePropertyGUI()
		end
	end, false)

	local interiorName = getElementData(interior, "name")
	if isHouse then
		local theTax = exports.drp_global:getPropertyTaxRate(0)
		purchaseProperty.label[1] = guiCreateLabel(
			50,
			26,
			419,
			18,
			"Lütfen bu mülk hakkında aşağıdaki bilgileri doğrulayın.",
			false,
			purchaseProperty.window[1]
		)
		guiLabelSetHorizontalAlign(purchaseProperty.label[1], "center", false)
		taxTax = cost * theTax
		guiSetText(purchaseProperty.label[10], "₺" .. exports.drp_global:formatMoney(taxTax))
	elseif isRentable then
		guiSetText(purchaseProperty.window[1], "Kiralık Mülk")
		purchaseProperty.label[1] = guiCreateLabel(
			50,
			26,
			419,
			18,
			"Lütfen bu kiralanabilir mülk hakkında aşağıdaki bilgileri doğrulayın.",
			false,
			purchaseProperty.window[1]
		)
		guiLabelSetHorizontalAlign(purchaseProperty.label[1], "center", false)
		guiSetVisible(purchaseProperty.label[5], false)
		guiSetText(purchaseProperty.label[4], "Maaş Günü Başına Maliyet:")
	else
		local theTax = exports.drp_global:getPropertyTaxRate(1)
		guiSetText(purchaseProperty.window[1], "İşletme Satın Al")
		purchaseProperty.label[1] = guiCreateLabel(
			50,
			26,
			419,
			18,
			"Lütfen bu işletme mülkü hakkında aşağıdaki bilgileri doğrulayın.",
			false,
			purchaseProperty.window[1]
		)
		guiLabelSetHorizontalAlign(purchaseProperty.label[1], "center", false)
		taxtax = cost * theTax
		guiSetText(purchaseProperty.label[10], "₺" .. exports.drp_global:formatMoney(taxtax))
	end
	guiSetText(purchaseProperty.label[9], neighborhood)
	guiSetText(purchaseProperty.label[7], tostring(interiorName))
	guiSetText(purchaseProperty.label[8], "₺" .. exports.drp_global:formatMoney(cost))

	triggerEvent("hud:convertUI", localPlayer, purchaseProperty.window[1])
end
addEvent("openPropertyGUI", true)
addEventHandler("openPropertyGUI", root, purchasePropertyGUI)

function closePropertyGUI()
	destroyElement(purchaseProperty.window[1])
	showCursor(false)
	closeStartBuying()
end

local factionBuyGUI = {
	button = {},
	window = {},
	combobox = {},
}
function startBuyingForFaction(interior, cost, isHouse, furniture)
	closeStartBuying()

	factionBuyGUI.window[1] = guiCreateWindow(766, 385, 399, 121, "Bu mülk için birlik seçin", false)
	guiWindowSetSizable(factionBuyGUI.window[1], false)
	guiSetAlpha(factionBuyGUI.window[1], 0.89)
	exports.drp_global:centerWindow(factionBuyGUI.window[1])
	guiSetEnabled(purchaseProperty.window[1], false)

	factionBuyGUI.button[1] = guiCreateButton(13, 64, 111, 42, "İptal", false, factionBuyGUI.window[1])
	guiSetProperty(factionBuyGUI.button[1], "NormalTextColour", "FFAAAAAA")
	factionBuyGUI.combobox[1] =
		guiCreateComboBox(13, 35, 366, 113, "Satın almak için bir birlik seçin", false, factionBuyGUI.window[1])
	factionBuyGUI.button[2] = guiCreateButton(268, 64, 111, 42, "Onayla", false, factionBuyGUI.window[1])
	guiSetProperty(factionBuyGUI.button[2], "NormalTextColour", "FFAAAAAA")

	for k, v in pairs(getElementData(localPlayer, "faction")) do
		if exports.drp_faction:hasMemberPermissionTo(localPlayer, k, "manage_interiors") then
			guiComboBoxAddItem(factionBuyGUI.combobox[1], exports.drp_faction:getFactionName(k))
		end
	end

	addEventHandler("onClientGUIClick", factionBuyGUI.button[2], function()
		local name =
			guiComboBoxGetItemText(factionBuyGUI.combobox[1], guiComboBoxGetSelected(factionBuyGUI.combobox[1]))
		if name ~= "Satın almak için bir birlik seçin" then
			triggerServerEvent(
				"buyPropertyForFaction",
				localPlayer,
				interior,
				cost,
				isHouse,
				guiRadioButtonGetSelected(purchaseProperty.rad[1]),
				name
			)
			closePropertyGUI()
		else
			outputChatBox("[!]#FFFFFF Lütfen bir birlik seçin.", 255, 0, 0, true)
		end
	end, false)

	addEventHandler("onClientGUIClick", factionBuyGUI.button[1], closeStartBuying, false)
end

function closeStartBuying()
	if factionBuyGUI.window[1] and isElement(factionBuyGUI.window[1]) then
		destroyElement(factionBuyGUI.window[1])
		factionBuyGUI.window[1] = nil
		if purchaseProperty.window[1] and isElement(purchaseProperty.window[1]) then
			guiSetEnabled(purchaseProperty.window[1], true)
		end
	end
end
