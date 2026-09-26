local hitPickup = nil

function enterInterior()
	if not hitPickup then
		return
	end

	local localDimension = getElementDimension(localPlayer)

	local vehicleElement = false
	local theVehicle = getPedOccupiedVehicle(localPlayer)
	if theVehicle and getVehicleOccupant(theVehicle, 0) == localPlayer then
		vehicleElement = theVehicle
	end

	local foundInterior = getElementParent(hitPickup)
	local interiorID = getElementData(foundInterior, "dbid")

	if interiorID then
		local canEnter, errorCode, errorMsg = canEnterInterior(foundInterior)
		if canEnter or isInteriorForSale(foundInterior) then
			if getElementType(foundInterior) == "interior" then
				if not vehicleElement then
					triggerServerEvent("interior.enter", foundInterior)
				end
			else
				triggerServerEvent("elevator.enter", foundInterior, getElementData(hitPickup, "type") == "entrance")
			end
		else
			outputChatBox("[!]#FFFFFF " .. errorMsg, 255, 0, 0, true)
		end
	end
end

function bindKeys()
	bindKey("enter", "down", enterInterior)
	bindKey("f", "down", enterInterior)
	toggleControl("enter_exit", false)
end

function unbindKeys()
	unbindKey("enter", "down", enterInterior)
	unbindKey("f", "down", enterInterior)
	toggleControl("enter_exit", true)
end

local isLastSourceInterior = nil
function hitInteriorPickup(theElement, matchingdimension)
	local pickup = getElementParent(source)
	if getElementType(pickup) == "interior" or getElementType(pickup) == "elevator" then
		local isVehicle = false
		local theVehicle = getPedOccupiedVehicle(localPlayer)
		if theVehicle and theVehicle == theElement and getVehicleOccupant(theVehicle, 0) == localPlayer then
			isVehicle = true
		end

		if matchingdimension and (theElement == localPlayer or isVehicle) then
			if getElementType(pickup) == "interior" or getElementType(pickup) == "elevator" then
				bindKeys()
				hitPickup = source
				playSoundFrontEnd(2)

				if getElementType(pickup) == "interior" then
					isLastSourceInterior = true
				else
					isLastSourceInterior = nil
				end
			end
		end
		cancelEvent()
	end
end
addEventHandler("onClientPickupHit", root, hitInteriorPickup)

function leaveInteriorPickup(theElement, matchingdimension)
	local isVehicle = false
	local theVehicle = getPedOccupiedVehicle(localPlayer)
	if theVehicle and theVehicle == theElement and getVehicleOccupant(theVehicle, 0) == localPlayer then
		isVehicle = true
	end

	if hitPickup == source and (theElement == localPlayer or isVehicle) then
		hitPickup = nil
	end
end
addEventHandler("onClientPickupLeave", root, leaveInteriorPickup)

addEventHandler("onClientPlayerVehicleExit", root, function(player, seat)
    if player == localPlayer and seat == 0 and hitPickup then
        cancelEvent()
    end
end)

local screenSize = Vector2(guiGetScreenSize())

local containerSize = {
	width = 48,
	height = 48,
}

local containerPosition = {
	x = screenSize.x / 2 - containerSize.width / 2,
	y = screenSize.y - containerSize.height - 32,
}

local fonts = useFonts()
local theme = useTheme()

setTimer(function()
	if not localPlayer:getData("logged") then
		return
	end

	local pickups =
		getElementsWithinRange(localPlayer.position, 7, "pickup", localPlayer.interior, localPlayer.dimension)
	for i = 1, #pickups do
		local pickup = pickups[i]
		if pickup then
			local id = pickup:getData("dbid")
			local positionX, positionY =
				getScreenFromWorldPosition(pickup.position.x, pickup.position.y, pickup.position.z + 0.25)

			if positionX and positionY and id then
				local status = pickup:getData("status")
				local name = pickup:getData("name") or ""
				local locked = status.locked or false
				local type = status.type or 0
				local owner = status.owner or 0
				local ownerName = exports.drp_cache:getCharacterNameFromID(owner) or "Hükümet"
				
				if type == InteriorType.ELEVATOR then
					return
				end

				if ownerName == "" then
					ownerName = "Hükümet"
				end

				local zoneName = exports.drp_global:getZoneName(pickup.position.x, pickup.position.y, pickup.position.z)
				name = name .. ", " .. zoneName

				local lockedState = locked == InteriorLock.LOCKED and "#e74c3cKİLİTLİ" or "#2ecc71AÇIK"

				dxDrawBorderText(
					"[" .. lockedState .. "#FFFFFF]\n" .. name .. "\nKapı No: " .. id .. "\nSahip: " .. ownerName,
					positionX,
					positionY,
					positionX,
					positionY,
					tocolor(255, 255, 255),
					tocolor(0, 0, 0),
					1,
					"default-bold",
					"center",
					"top",
					false,
					false,
					false,
					true
				)
			end
		end
	end

	if not (hitPickup and isElement(hitPickup)) then
		unbindKeys()
		return
	end

	local interior = hitPickup

	local id = interior:getData("dbid")
	local status = interior:getData("status")
	local name = interior:getData("name") or ""
	local ownerName = exports.drp_cache:getCharacterNameFromID(status.owner) or "-"
	local type = status.type or 0
	local locked = status.locked or false

	local textWidth = dxGetTextWidth(name, 1, fonts.body.regular) + containerSize.width

	if not InteriorIcons[type] then
		return
	end

	local icon = InteriorIcons[type].__ui.icon

	local detailsText = "[" .. id .. "] "

	local lockedText = (
		locked == InteriorLock.LOCKED and theme.RED[600] .. "[Kilitli]" or theme.GREEN[600] .. "[Açık]"
	) .. theme.GRAY[300]
	detailsText = detailsText .. lockedText .. " "

	if type ~= InteriorType.GOVERNMENT and ownerName then
		local ownerText = theme.GRAY[300] .. "[Sahip: " .. ownerName .. "]"
		detailsText = detailsText .. ownerText .. " "
	end

	local detailsTextWidth = dxGetTextWidth(detailsText:gsub("#%x%x%x%x%x%x", ""), 1, fonts.body.regular)
		+ containerSize.width

	if textWidth < detailsTextWidth then
		textWidth = detailsTextWidth
	end

	local nameContainerSize = {
		x = textWidth,
		y = containerSize.height / 1.25,
	}

	local nameContainerPosition = {
		x = containerPosition.x + containerSize.width / 2,
		y = containerPosition.y + containerSize.height / 2 - nameContainerSize.y / 2,
	}

	local infoContainerPosition = {
		x = containerPosition.x - nameContainerSize.x + containerSize.width / 2,
		y = containerPosition.y + containerSize.height / 2 - nameContainerSize.y / 2,
	}

	drawRoundedRectangle({
		position = nameContainerPosition,
		size = nameContainerSize,

		color = theme.GRAY[800],
		alpha = 1,
		radius = 8,

		section = false,
		postGUI = false,
	})
	dxDrawText(
		name,
		nameContainerPosition.x - 10,
		nameContainerPosition.y,
		nameContainerPosition.x + nameContainerSize.x - 10,
		nameContainerPosition.y + nameContainerSize.y,
		rgba(theme.GRAY[300], 1),
		1,
		fonts.body.regular,
		"right",
		"center"
	)

	drawRoundedRectangle({
		position = infoContainerPosition,
		size = nameContainerSize,

		color = theme.GRAY[800],
		alpha = 1,
		radius = 8,

		section = false,
		postGUI = false,
	})
	dxDrawText(
		detailsText,
		infoContainerPosition.x + 10,
		infoContainerPosition.y,
		infoContainerPosition.x + nameContainerSize.x + 10,
		infoContainerPosition.y + nameContainerSize.y,
		rgba(theme.GRAY[300], 1),
		1,
		fonts.body.regular,
		"left",
		"center",
		false,
		false,
		false,
		true
	)

	drawRoundedRectangle({
		position = containerPosition,
		size = {
			x = containerSize.width,
			y = containerSize.height,
		},

		color = theme.GRAY[900],
		alpha = 1,
		radius = containerSize.width / 2,

		section = false,
		postGUI = false,
	})
	dxDrawText(
		icon,
		containerPosition.x,
		containerPosition.y,
		containerPosition.x + containerSize.width + 1,
		containerPosition.y + containerSize.height + 2,
		rgba(theme.GRAY[400], 1),
		0.7,
		fonts.icon,
		"center",
		"center"
	)

	dxDrawText(
		"Geçiş yapmak için 'F' tuşuna basın.",
		0,
		0,
		screenSize.x + 1,
		screenSize.y - 14,
		rgba(theme.GRAY[800], 1),
		1,
		fonts.body.regular,
		"center",
		"bottom"
	)
	dxDrawText(
		"Geçiş yapmak için 'F' tuşuna basın.",
		0,
		0,
		screenSize.x,
		screenSize.y - 15,
		rgba(theme.GRAY[400], 1),
		1,
		fonts.body.regular,
		"center",
		"bottom"
	)
end, 0, 0)

function dxDrawBorderText(
	text,
	x,
	y,
	w,
	h,
	color,
	borderColor,
	scale,
	font,
	alignX,
	alignY,
	clip,
	wordBreak,
	postGUI,
	colorCoded
)
	if not font then
		return
	end

	local textWithoutColors = string.gsub(text, "#......", "")
	dxDrawText(
		textWithoutColors,
		x - 1,
		y - 1,
		w - 1,
		h - 1,
		borderColor,
		scale,
		font,
		alignX,
		alignY,
		clip,
		wordBreak,
		postGUI,
		colorCoded,
		true
	)
	dxDrawText(
		textWithoutColors,
		x - 1,
		y + 1,
		w - 1,
		h + 1,
		borderColor,
		scale,
		font,
		alignX,
		alignY,
		clip,
		wordBreak,
		postGUI,
		colorCoded,
		true
	)
	dxDrawText(
		textWithoutColors,
		x + 1,
		y - 1,
		w + 1,
		h - 1,
		borderColor,
		scale,
		font,
		alignX,
		alignY,
		clip,
		wordBreak,
		postGUI,
		colorCoded,
		true
	)
	dxDrawText(
		textWithoutColors,
		x + 1,
		y + 1,
		w + 1,
		h + 1,
		borderColor,
		scale,
		font,
		alignX,
		alignY,
		clip,
		wordBreak,
		postGUI,
		colorCoded,
		true
	)
	dxDrawText(text, x, y, w, h, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
end
