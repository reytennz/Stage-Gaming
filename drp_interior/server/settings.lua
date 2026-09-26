function getInteriorSetting(interiorID, key)
	if interiorID and interiorID > 0 then
		if interiorID > 20000 then
			vehicleID = interiorID - 20000
			local vehicleElement = exports.drp_pool:getElementByID("vehicle", vehicleID)
			if vehicleElement then
				local data = getElementData(vehicleElement, "settings") or {}
				return data[tostring(key)]
			else
				return false
			end
		else
			local interiorElement = exports.drp_pool:getElementByID("interior", interiorID)
			if interiorElement then
				local data = getElementData(interiorElement, "settings") or {}
				return data[tostring(key)]
			else
				return false
			end
		end
	end
	return false
end

function saveInteriorSettings(element, interiorID, isVehicleInterior, data)
	if interiorID and data then
		if isVehicleInterior then
			vehicleID = interiorID - 20000
			if not element then
				element = exports.drp_pool:getElementByID("vehicle", vehicleID)
			end
			if element then
				dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE `vehicles` SET `settings` = ? WHERE `id` = ? LIMIT 1;",
					toJSON(data),
					vehicleID
				)
				setElementData(element, "settings", data)
			end
		else
			if not element then
				element = exports.drp_pool:getElementByID("interior", interiorID)
			end
			if element then
				dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE `interiors` SET `settings` = ? WHERE `id` = ?",
					toJSON(data),
					interiorID
				)
				setElementData(element, "settings", data)
			end
		end
	end
end
addEvent("interior.saveSettings", true)
addEventHandler("interior.saveSettings", resourceRoot, saveInteriorSettings)

function openInteriorSettings(thePlayer, cmd)
	local playerInterior = getElementInterior(thePlayer)
	local playerDimension = getElementDimension(thePlayer)

	if playerInterior > 0 and playerDimension > 0 then
		local interiorID = playerDimension
		if
			(interiorID < 20000 and exports.drp_item:hasItem(thePlayer, 4, interiorID))
			or (interiorID < 20000 and exports.drp_item:hasItem(thePlayer, 5, interiorID))
			or (interiorID > 20000 and exports.drp_item:hasItem(thePlayer, 3, interiorID - 20000))
			or (exports.drp_integration:isPlayerManager(thePlayer) and exports.drp_global:isAdminOnDuty(thePlayer))
		then
			if interiorID > 20000 then
				vehicleID = interiorID - 20000
				local vehicleElement = exports.drp_pool:getElementByID("vehicle", vehicleID)
				if vehicleElement then
					local data = getElementData(vehicleElement, "settings") or {}
					triggerClientEvent(
						thePlayer,
						"interior.settingsGui",
						vehicleElement,
						playerInterior,
						playerDimension,
						data
					)
				else
					return false
				end
			else
				local interiorElement = exports.drp_pool:getElementByID("interior", interiorID)
				if interiorElement then
					local data = getElementData(interiorElement, "settings") or {}
					local result = triggerClientEvent(
						thePlayer,
						"interior.settingsGui",
						thePlayer,
						interiorElement,
						playerInterior,
						playerDimension,
						data
					)
				else
					return false
				end
			end
		end
	end
end
addCommandHandler("intsettings", openInteriorSettings)
addCommandHandler("interiorsettings", openInteriorSettings)
addCommandHandler("intset", openInteriorSettings)
