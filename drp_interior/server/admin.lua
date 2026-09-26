function getNearbyInteriors(thePlayer, commandName)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local posX, posY, posZ = getElementPosition(thePlayer)
		local dimension = getElementDimension(thePlayer)
		outputChatBox("Nearby Interiors:", thePlayer, 255, 126, 0)
		local count = 0
		local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")
		for _, interior in ipairs(possibleInteriors) do
			local interiorEntrance = getElementData(interior, "entrance")
			local interiorExit = getElementData(interior, "exit")

			for _, point in ipairs({ interiorEntrance, interiorExit }) do
				if point.dim == dimension then
					local distance = getDistanceBetweenPoints3D(posX, posY, posZ, point.x, point.y, point.z)
					if distance <= 11 then
						local dbid = getElementData(interior, "dbid")
						local interiorName = getElementData(interior, "name")
						outputChatBox("ID " .. dbid .. ": " .. interiorName, thePlayer, 255, 126, 0)
						count = count + 1
					end
				end
			end
		end

		if count == 0 then
			outputChatBox("None.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("nearbyinteriors", getNearbyInteriors, false, false)
addCommandHandler("nearbyints", getNearbyInteriors, false, false)

function delNearbyInteriors(thePlayer, commandName)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		local posX, posY, posZ = getElementPosition(thePlayer)
		local dimension = getElementDimension(thePlayer)
		outputChatBox("Deleting Nearby Interiors:", thePlayer, 255, 126, 0)
		local count = 0
		local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")
		for _, interior in ipairs(possibleInteriors) do
			local interiorEntrance = getElementData(interior, "entrance")
			local interiorExit = getElementData(interior, "exit")

			for _, point in ipairs({ interiorEntrance, interiorExit }) do
				if point.dim == dimension then
					local distance = getDistanceBetweenPoints3D(posX, posY, posZ, point.x, point.y, point.z)
					if distance <= 6 then
						local dbid = getElementData(interior, "dbid")
						local interiorName = getElementData(interior, "name")
						if deleteInterior(thePlayer, "mass", dbid) then
							count = count + 1
						end
					end
				end
			end
		end
		setElementData(thePlayer, "interiormarker", false)

		if count == 0 then
			outputChatBox("None was deleted", thePlayer, 255, 126, 0)
		else
			outputChatBox(count .. " interiors have been deleted!", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("delnearbyinteriors", delNearbyInteriors, false, false)
addCommandHandler("delnearbyints", delNearbyInteriors, false, false)

function gotoHouse(thePlayer, commandName, houseID, target)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local houseID = tonumber(houseID)
		if not houseID then
			outputChatBox("Kullanım: /" .. commandName .. " [House/Biz ID] (Player)", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, type, interiorElement = findProperty(thePlayer, houseID)
			if entrance then
				if target then
					targetPlayer, targetPlayerName = exports.drp_global:findPlayerByPartialNick(thePlayer, target)
					if targetPlayer and getElementData(targetPlayer, "logged") then
						local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
						local adminUsername = getElementData(thePlayer, "account_username")

						setPlayerInsideInterior(
							interiorElement,
							targetPlayer,
							entrance,
							(getElementDimension(targetPlayer) == 0) or false
						)
						outputChatBox(
							"You sent " .. targetPlayerName .. " to house #" .. houseID,
							thePlayer,
							231,
							217,
							176
						)
						outputChatBox(
							"You were sent to house #" .. houseID .. " by " .. adminTitle .. " " .. adminUsername .. ".",
							targetPlayer,
							231,
							217,
							176
						)

						exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, targetPlayer)
						return true
					else
						outputChatBox("No player found.", thePlayer, 255, 0, 0)
						return
					end
				else
					setPlayerInsideInterior(
						interiorElement,
						thePlayer,
						entrance,
						(getElementDimension(thePlayer) == 0) or false
					)
					outputChatBox("Teleported to House #" .. houseID, thePlayer, 0, 255, 0)

					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, thePlayer)
					return true
				end
			else
				outputChatBox("Invalid House.", thePlayer, 255, 0, 0)
				return false
			end
		end
	end
end
addCommandHandler("gotohouse", gotoHouse)
addCommandHandler("gotoint", gotoHouse)

function gotoHouseInside(thePlayer, commandName, houseID, target)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local houseID = tonumber(houseID)
		if not houseID then
			outputChatBox("Kullanım: /" .. commandName .. " [House/Biz ID] (Player)", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, type, interiorElement = findProperty(thePlayer, houseID)
			if exit then
				if target then
					targetPlayer, targetPlayerName = exports.drp_global:findPlayerByPartialNick(thePlayer, target)
					if targetPlayer and getElementData(targetPlayer, "logged") then
						local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
						local adminUsername = getElementData(thePlayer, "account_username")

						setPlayerInsideInterior(
							interiorElement,
							targetPlayer,
							exit,
							(getElementDimension(targetPlayer) == dbid) or false
						)

						outputChatBox(
							"You sent " .. targetPlayerName .. " inside house #" .. houseID,
							thePlayer,
							231,
							217,
							176
						)
						outputChatBox(
							"You were sent inside house #"
								.. houseID
								.. " by "
								.. adminTitle
								.. " "
								.. adminUsername
								.. ".",
							targetPlayer,
							231,
							217,
							176
						)

						exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, targetPlayer)
						return true
					else
						outputChatBox("No player found.", thePlayer, 255, 0, 0)
						return
					end
				else
					setPlayerInsideInterior(
						interiorElement,
						thePlayer,
						exit,
						(getElementDimension(thePlayer) == dbid) or false
					)

					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, thePlayer)
					outputChatBox("Teleported inside House #" .. houseID, thePlayer, 0, 255, 0)
					return true
				end
			else
				outputChatBox("Invalid House.", thePlayer, 255, 0, 0)
				return
			end
		end
	end
end
addCommandHandler("gotointi", gotoHouseInside)

function setInteriorID(thePlayer, commandName, interiorID)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		local interiors = exports["drp_official-interiors"].getInteriorsList()
		interiorID = tonumber(interiorID)
		if not interiorID then
			outputChatBox(
				"Kullanım: /" .. commandName .. " [interior id] - changes the house interior",
				thePlayer,
				255,
				194,
				14
			)
		elseif not interiors[interiorID] then
			outputChatBox("Invalid ID.", thePlayer, 255, 0, 0)
			return false
		else
			local dbid, entrance, exit, _, intElement = findProperty(thePlayer)
			if exit then
				local interior = interiors[interiorID]
				local ix = interior[2]
				local iy = interior[3]
				local iz = interior[4]
				local optAngle = interior[5]
				local interiorw = interior[1]

				local query = dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE interiors SET interior_id="
						.. interiorID
						.. ", interior="
						.. interiorw
						.. ", interiorx="
						.. ix
						.. ", interiory="
						.. iy
						.. ", interiorz="
						.. iz
						.. ", angle="
						.. optAngle
						.. " WHERE id="
						.. dbid
				)
				if query then
					setElementData(intElement, "interior_id", interiorID)
					cleanupProperty(dbid)
					realReloadInterior(dbid)

					for key, value in pairs(getElementsByType("player")) do
						if isElement(value) and getElementDimension(value) == dbid then
							setElementPosition(value, ix, iy, iz)
							setElementInterior(value, interiorw)
							setCameraInterior(value, interiorw)
						end
					end

					outputChatBox(
						"You have sucessfully changed interior of house #" .. dbid .. " to ID " .. interiorID .. ".",
						thePlayer,
						0,
						255,
						0
					)

					local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
					local adminUsername = getElementData(thePlayer, "account_username")

					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has changed interior of house #"
							.. dbid
							.. " to ID "
							.. interiorID
							.. "."
					)

					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName .. " " .. interiorID, thePlayer)

					return true
				else
					outputChatBox("Interior Update failed.", thePlayer, 255, 0, 0)
					return false
				end
			else
				outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
				return false
			end
		end
	end
end
addCommandHandler("setinteriorid", setInteriorID)
addCommandHandler("setintid", setInteriorID)

function setInteriorPrice(thePlayer, commandName, cost)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		cost = tonumber(cost)
		if not cost then
			outputChatBox("Kullanım: /" .. commandName .. " [price]", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
			if exit then
				local query = dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE interiors SET cost=" .. cost .. " WHERE id=" .. dbid
				)
				if query then
					local interiorStatus = getElementData(interiorElement, "status")
					interiorStatus.cost = cost
					setElementData(interiorElement, "status", interiorStatus)
					outputChatBox(
						"Interior cost is now ₺" .. exports.drp_global:formatMoney(cost) .. ".",
						thePlayer,
						0,
						255,
						0
					)

					local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
					local adminUsername = getElementData(thePlayer, "account_username")

					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has changed interior price of house #"
							.. dbid
							.. " to ₺"
							.. cost
							.. "."
					)

					exports["drp_interior-manager"]:addInteriorLogs(
						dbid,
						commandName .. " " .. tostring(cost),
						thePlayer
					)
					return true
				else
					outputChatBox("Interior Update failed.", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setinteriorprice", setInteriorPrice)
addCommandHandler("setintprice", setInteriorPrice)

function getInteriorPrice(thePlayer)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
		if exit then
			local interiorStatus = getElementData(interiorElement, "status")
			outputChatBox(
				"This Interior costs ₺" .. exports.drp_global:formatMoney(interiorStatus.cost) .. ".",
				thePlayer,
				255,
				194,
				14
			)
		else
			outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("getinteriorprice", getInteriorPrice)
addCommandHandler("getintprice", getInteriorPrice)

function setInteriorType(thePlayer, commandName, type)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		type = math.ceil(tonumber(type) or -1)
		if not type or type < 0 or type > 3 then
			outputChatBox("Kullanım: /" .. commandName .. " [type (0-3)]", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
			if exit then
				if type ~= interiorType then
					local query = dbExec(
						exports.drp_mysql:getConnection(),
						"UPDATE interiors SET type = ? WHERE id = ?",
						type,
						dbid
					)
					if query then
						local interiorStatus = getElementData(interiorElement, "status")
						interiorStatus.type = type
						outputChatBox("Interior type is now " .. type .. ".", thePlayer, 0, 255, 0)
						if type == 2 then
							local query2 = dbExec(
								exports.drp_mysql:getConnection(),
								"UPDATE interiors SET owner = 0 WHERE id = ?",
								dbid
							)
							if query2 then
								interiorStatus.owner = 0
								outputChatBox(
									"Set the interior type to no-one due interior type 2.",
									thePlayer,
									0,
									255,
									0
								)
							end
						end

						local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
						local adminUsername = getElementData(thePlayer, "account_username")

						exports.drp_global:sendMessageToAdmins(
							"[INTERIOR]: "
								.. adminTitle
								.. " "
								.. getPlayerName(thePlayer):gsub("_", " ")
								.. " ("
								.. adminUsername
								.. ") has changed interior type of house #"
								.. dbid
								.. " to type "
								.. type
								.. "."
						)

						setElementData(interiorElement, "status", interiorStatus)

						exports["drp_interior-manager"]:addInteriorLogs(
							dbid,
							commandName .. " " .. tostring(type),
							thePlayer
						)

						return true
					else
						outputChatBox("Interior Update failed.", thePlayer, 255, 0, 0)
					end
				else
					outputChatBox("Interior has this type already.", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setinteriortype", setInteriorType)
addCommandHandler("setinttype", setInteriorType)

function getInteriorType(thePlayer)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
		if exit then
			outputChatBox("This Interior's type is " .. interiorType .. ".", thePlayer, 255, 194, 14)
		else
			outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("getinteriortype", getInteriorType)
addCommandHandler("getinttype", getInteriorType)

function getInteriorID(thePlayer, commandName)
	local theId = nil
	local myDim = getElementDimension(thePlayer)
	if myDim > 0 then
		local theInterior = exports.drp_pool:getElementByID("interior", myDim)
		theId = theInterior and getElementData(theInterior, "interior_id") or nil
		if not theId then
			local interior = getElementInterior(thePlayer)
			local x, y, z = getElementPosition(thePlayer)
			local interiors = exports["drp_official-interiors"]:getInteriorsList()
			for k, v in pairs(interiors) do
				if interior == v[1] and getDistanceBetweenPoints3D(x, y, z, v[2], v[3], v[4]) < 10 then
					theId = k
					dbExec(
						exports.drp_mysql:getConnection(),
						"UPDATE interiors SET interior_id=? WHERE `id`=?",
						k,
						myDim
					)
					setElementData(theInterior, "interior_id", k)
					break
				end
			end
		end
	end
	if theId then
		outputChatBox("Interior ID: " .. theId, thePlayer)
	else
		outputChatBox("Interior ID not found.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("getinteriorid", getInteriorID)
addCommandHandler("getintid", getInteriorID)

function toggleInterior(thePlayer, commandName, id)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		id = tonumber(id)
		if not id then
			outputChatBox("Kullanım: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, inttype, interiorElement = findProperty(thePlayer, id)
			if entrance then
				local interiorStatus = getElementData(interiorElement, "status")
				local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
				local adminUsername = getElementData(thePlayer, "account_username")

				if interiorStatus.disabled then
					dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET disabled = 0 WHERE id = " .. dbid)
					outputChatBox("Interior " .. dbid .. " is now enabled", thePlayer)
					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has enabled Interior #"
							.. dbid
							.. "."
					)
					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName .. " on", thePlayer)
				else
					dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET disabled = 1 WHERE id = " .. dbid)
					outputChatBox("Interior " .. dbid .. " is now disabled", thePlayer)
					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has disabled Interior #"
							.. dbid
							.. "."
					)
					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName .. " off", thePlayer)
				end
				realReloadInterior(dbid)
			end
		end
	end
end
addCommandHandler("toggleinterior", toggleInterior)
addCommandHandler("togint", toggleInterior)

function reloadInterior(thePlayer, commandName, interiorID)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		if not interiorID then
			outputChatBox("Kullanım: /" .. commandName .. " [Interior ID]", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit, interiorType = findProperty(thePlayer, tonumber(interiorID))
			if dbid ~= 0 then
				realReloadInterior(dbid)
				outputChatBox("Reloaded Interior #" .. dbid, thePlayer, 0, 255, 0)
			else
				if exports["drp_interior-load"]:loadOne(tonumber(interiorID), false) then
					outputChatBox("Loaded Interior #" .. tonumber(interiorID), thePlayer, 0, 255, 0)
				end
			end
		end
	end
end
addCommandHandler("reloadinterior", reloadInterior, false, false)
addCommandHandler("reloadint", reloadInterior, false, false)

function deleteInterior(thePlayer, commandName, houseID)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		houseID = tonumber(houseID)
		if not houseID then
			outputChatBox("Kullanım: /" .. commandName .. " [House/Biz ID]", thePlayer, 255, 194, 14)
			return false
		else
			local dbid, entrance, exit, type, interiorElement = findProperty(thePlayer, tonumber(houseID))

			local active, details2 = isActive(interiorElement)
			if commandName ~= "mass" and active and getElementData(thePlayer, "confirm:delint") ~= houseID then
				outputChatBox(
					"You are about to delete an interior while it's appearing to be an active interior.",
					thePlayer
				)
				outputChatBox("Please type /" .. commandName .. " " .. houseID .. " once again to proceed.", thePlayer)
				setElementData(thePlayer, "confirm:delint", houseID)
				return false
			end

			if dbid ~= 0 then
				sendPlayersOutside(interiorElement)

				dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE `interiors` SET `deleted`=?, `deletedDate`=NOW() WHERE id=? ",
					getElementData(thePlayer, "account_username"),
					dbid
				)
				setElementData(thePlayer, "mostRecentDeletedInterior", dbid, false)

				exports["drp_interior-load"]:unload(dbid)

				outputChatBox("[DELINT] Interior #" .. dbid .. " has been deleted!", thePlayer, 0, 255, 0)
				outputChatBox("To restore this interior, do '/restoreint " .. dbid .. "'.", thePlayer, 255, 194, 14)
				exports.drp_global:sendMessageToAdmins(
					"[INTERIOR] "
						.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
						.. " has deleted Interior #"
						.. dbid
						.. "."
				)

				exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, thePlayer)

				removeElementData(thePlayer, "confirm:delint")
				return true
			else
				return false
			end
		end
	end
end
addCommandHandler("delinterior", deleteInterior, false, false)
addCommandHandler("delint", deleteInterior, false, false)

function restoreInt(thePlayer, commandName, houseID)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		if not showLoadingProgressTimer then
			houseID = tonumber(houseID)
			if not houseID then
				outputChatBox("Kullanım: /" .. commandName .. " [House/Biz ID]", thePlayer, 255, 194, 14)
				return
			end

			if houseID ~= 0 then
				local qh = dbQuery(
					exports.drp_mysql:getConnection(),
					"SELECT `deleted` FROM `interiors` WHERE `id` = ? LIMIT 1",
					houseID
				)
				local result = dbPoll(qh, -1)

				if not result or #result == 0 then
					outputChatBox("[RESTOREINT] Int #" .. houseID .. " not found in Database!", thePlayer, 255, 0, 0)
					return
				end

				if tostring(result[1].deleted) == "0" then
					outputChatBox("[RESTOREINT] Interior #" .. houseID .. " isn't deleted!", thePlayer, 255, 0, 0)
					return
				end

				local success = dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE `interiors` SET `deleted` = '0' WHERE `id` = ?",
					houseID
				)
				if success then
					exports["drp_interior-load"]:loadOne(houseID)
					outputChatBox("[RESTOREINT] Interior #" .. houseID .. " has been restored!", thePlayer, 0, 255, 0)

					local adminUsername = getElementData(thePlayer, "account_username")
					local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)

					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has restored Interior #"
							.. houseID
							.. "."
					)

					exports["drp_interior-manager"]:addInteriorLogs(houseID, commandName, thePlayer)
					return true
				else
					outputChatBox("[RESTOREINT] Database Error!", thePlayer, 255, 0, 0)
					return false
				end
			end
		else
			outputChatBox("Please wait until the interior system loading is done..", thePlayer, 255, 0, 0)
			return false
		end
	end
end
addCommandHandler("restoreint", restoreInt, false, false)
addCommandHandler("restoreinterior", restoreInt, false, false)

function removeInterior(thePlayer, commandName, houseID)
	if exports.drp_integration:isPlayerManager(thePlayer) or commandName == "MOVETOLS" then
		if not showLoadingProgressTimer then
			houseID = tonumber(houseID) or getElementData(thePlayer, "mostRecentDeletedInterior")
			if not houseID then
				outputChatBox("Kullanım: /" .. commandName .. " [House/Biz ID]", thePlayer, 255, 194, 14)
				return
			end

			if houseID ~= 0 then
				if commandName ~= "MOVETOLS" then
					local query = dbQuery(
						exports.drp_mysql:getConnection(),
						"SELECT `deleted` FROM interiors WHERE id=?",
						houseID
					)
					local result = dbPoll(query, -1)

					if not result or #result == 0 then
						outputChatBox("[REMOVEINT] Int #" .. houseID .. " not found in Database!", thePlayer, 255, 0, 0)
						return
					elseif result[1].deleted == 0 or result[1].deleted == "0" then
						outputChatBox(
							"[REMOVEINT] To remove this Interior permanently from Database, please use '/delint "
								.. houseID
								.. "' first.",
							thePlayer,
							255,
							0,
							0
						)
						return
					end
				end

				local success1 =
					dbExec(exports.drp_mysql:getConnection(), "DELETE FROM `interiors` WHERE `id`=?", houseID)
				local success2 = dbExec(
					exports.drp_mysql:getConnection(),
					"DELETE FROM `interior_textures` WHERE `interior`=?",
					houseID
				)

				if success1 and success2 then
					clearSafe(houseID, true)
					cleanupProperty(houseID)

					outputChatBox(
						"[REMOVEINT] Interior #" .. houseID .. " has been removed completely from Database!",
						thePlayer,
						0,
						255,
						0
					)

					local adminUsername = getElementData(thePlayer, "account_username")
					local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)

					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has removed Interior #"
							.. houseID
							.. " permanently from database."
					)

					if
						not dbExec(
							exports.drp_mysql:getConnection(),
							"DELETE FROM `interior_logs` WHERE `intID`=?",
							houseID
						)
					then
						outputDebugString(
							"[INTERIOR MANAGER] Failed to clean previous logs #" .. houseID .. " from `interior_logs`."
						)
					end

					if
						not dbExec(
							exports.drp_mysql:getConnection(),
							"DELETE FROM `interior_business` WHERE `intID`=?",
							houseID
						)
					then
						outputDebugString(
							"[INTERIOR MANAGER] Failed to clean previous business data #"
								.. houseID
								.. " from `interior_business`."
						)
					end

					if
						not dbExec(
							exports.drp_mysql:getConnection(),
							"DELETE FROM `interior_notes` WHERE `intid`=?",
							houseID
						)
					then
						outputDebugString(
							"[INTERIOR MANAGER] Failed to clean previous notes #"
								.. houseID
								.. " from `interior_notes`."
						)
					end

					if commandName == "MOVETOLS" then
						realReloadInterior(houseID)
					end

					local mQuery = dbQuery(
						exports.drp_mysql:getConnection(),
						"SELECT id FROM `interiors` WHERE `dimensionwithin`=?",
						houseID
					)
					local mResult = dbPoll(mQuery, -1)
					if mResult and #mResult > 0 then
						for _, row in ipairs(mResult) do
							removeInterior(thePlayer, "MOVETOLS", tonumber(row.id))
						end
					end
				else
					outputChatBox("[REMOVEINT] Database Error!", thePlayer, 255, 0, 0)
				end
			end
		else
			outputChatBox("Please wait until the interior system loading is done..", thePlayer, 255, 0, 0)
			return false
		end
	end
end
addCommandHandler("removeint", removeInterior, false, false)
addCommandHandler("removeinterior", removeInterior, false, false)

function removeDeletedInteriors(thePlayer, commandName)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		if not getElementData(thePlayer, "confirm:removeDeletedInteriors") then
			outputChatBox("Removes all deleted interiors completely and permanently from SQL.", thePlayer, 255, 194, 14)
			outputChatBox(
				"And there will be no way to recover them, /"
					.. commandName
					.. " again to start it. /cancelremovedeletedints to cancel.",
				thePlayer,
				255,
				194,
				14
			)
			setElementData(thePlayer, "confirm:removeDeletedInteriors", true)
		else
			removeElementData(thePlayer, "confirm:removeDeletedInteriors")

			local query =
				dbQuery(exports.drp_mysql:getConnection(), "SELECT `id` FROM `interiors` WHERE `deleted` != '0'")
			local results = dbPoll(query, -1)

			local count = 0
			if results and #results > 0 then
				for _, row in ipairs(results) do
					removeInterior(thePlayer, "MOVETOLS", tonumber(row.id))
					count = count + 1
				end

				local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
				local adminUsername = getElementData(thePlayer, "account_username")

				exports.drp_global:sendMessageToAdmins(
					"[INTERIOR]: "
						.. adminTitle
						.. " "
						.. getPlayerName(thePlayer):gsub("_", " ")
						.. " ("
						.. adminUsername
						.. ") has executed a massive int remove command on "
						.. count
						.. " deleted interiors permanently from database.",
					root,
					255,
					0,
					0
				)
			else
				outputChatBox("No deleted interiors found to remove.", thePlayer, 255, 255, 0)
			end
		end
	end
end
addCommandHandler("removedeletedints", removeDeletedInteriors, false, false)
addCommandHandler("removedeletedinteriors", removeDeletedInteriors, false, false)

function removeForSaleInteriors(thePlayer, commandName)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		if not getElementData(thePlayer, "confirm:removeForSaleInteriors") then
			outputChatBox(
				"Removes all for-sale interiors completely and permanently from SQL.",
				thePlayer,
				255,
				194,
				14
			)
			outputChatBox(
				"And there will be no way to recover them, /"
					.. commandName
					.. " again to start it. /cancelremoveforsaleints to cancel.",
				thePlayer,
				255,
				194,
				14
			)
			setElementData(thePlayer, "confirm:removeForSaleInteriors", true)
		else
			removeElementData(thePlayer, "confirm:removeForSaleInteriors")

			local query =
				dbQuery(exports.drp_mysql:getConnection(), "SELECT `id` FROM `interiors` WHERE `owner` = '-1'")
			local results = dbPoll(query, -1)

			local count = 0
			if results and #results > 0 then
				for _, row in ipairs(results) do
					removeInterior(thePlayer, "MOVETOLS", tonumber(row.id))
					count = count + 1
				end

				local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)
				local adminUsername = getElementData(thePlayer, "account_username")

				exports.drp_global:sendMessageToAdmins(
					"[INTERIOR]: "
						.. adminTitle
						.. " "
						.. getPlayerName(thePlayer):gsub("_", " ")
						.. " ("
						.. adminUsername
						.. ") has executed a massive int remove command on "
						.. count
						.. " for-sale interiors permanently from database.",
					root,
					255,
					0,
					0
				)
			else
				outputChatBox("No for-sale interiors found to remove.", thePlayer, 255, 255, 0)
			end
		end
	end
end
addCommandHandler("removeforsaleints", removeForSaleInteriors, false, false)
addCommandHandler("removeforsaleinteriors", removeForSaleInteriors, false, false)

function cancelRemoveDeletedInts(thePlayer)
	if
		exports.drp_integration:isPlayerManager(thePlayer)
		and getElementData(thePlayer, "confirm:removeDeletedInteriors")
	then
		if removeElementData(thePlayer, "confirm:removeDeletedInteriors") then
			outputChatBox("Request to remove all deleted interiors has been cancelled.", thePlayer)
		end
	end
end
addCommandHandler("cancelremovedeletedints", cancelRemoveDeletedInts, false, false)
addCommandHandler("cancelremovedeletedints", cancelRemoveDeletedInts, false, false)

function cancelRemoveForSaleInts(thePlayer)
	if
		exports.drp_integration:isPlayerManager(thePlayer)
		and getElementData(thePlayer, "confirm:removeForSaleInteriors")
	then
		if removeElementData(thePlayer, "confirm:removeForSaleInteriors") then
			outputChatBox("Request to remove all for-sale interiors has been cancelled.", thePlayer)
		end
	end
end
addCommandHandler("cancelremoveforsaleints", cancelRemoveForSaleInts, false, false)
addCommandHandler("cancelremoveforsaleints", cancelRemoveForSaleInts, false, false)

function deleteThisInterior(thePlayer, commandName)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		local interior = getElementInterior(thePlayer)

		if interior == 0 then
			outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
		else
			local dbid, entrance, exit = findProperty(thePlayer)
			deleteInterior(thePlayer, "delint", dbid)
			setElementData(thePlayer, "interiormarker", false)
		end
	end
end
addCommandHandler("delthisint", deleteThisInterior, false, false)
addCommandHandler("delthisinterior", deleteThisInterior, false, false)

function updateInteriorEntrance(thePlayer, commandName, intID)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local intID = tonumber(intID)
		if not intID then
			outputChatBox("Kullanım: /" .. commandName .. " [Interior ID]", thePlayer, 255, 194, 14)
		else
			local dbid, entrance, exit = findProperty(thePlayer, intID)
			if entrance then
				local dw = getElementDimension(thePlayer)
				local iw = getElementInterior(thePlayer)
				local x, y, z = getElementPosition(thePlayer)
				local rot = getPedRotation(thePlayer)
				local query = dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE interiors SET x='"
						.. x
						.. "', y='"
						.. y
						.. "', z='"
						.. z
						.. "', angle='"
						.. rot
						.. "', dimensionwithin='"
						.. dw
						.. "', interiorwithin='"
						.. iw
						.. "' WHERE id='"
						.. dbid
						.. "'"
				)

				if query then
					realReloadInterior(dbid)

					outputChatBox("Interior Entrance #" .. dbid .. " has been Updated!", thePlayer, 0, 255, 0)

					local adminUsername = getElementData(thePlayer, "account_username")
					local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)

					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. adminTitle
							.. " "
							.. getPlayerName(thePlayer):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has moved Interior #"
							.. dbid
							.. " to new location."
					)

					exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, thePlayer)

					return true
				else
					outputChatBox("Error with the query.", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("Invalid Interior ID.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setinteriorentrance", updateInteriorEntrance, false, false)
addCommandHandler("setintentrance", updateInteriorEntrance, false, false)

function createInterior(thePlayer, commandName, interiorId, inttype, cost, ...)
	if exports.drp_integration:isPlayerManager(thePlayer) then
		local cost = tonumber(cost)
		if
			(
				not interiorId
				or not inttype
				or not cost
				or not (...)
				or ((tonumber(inttype) < 0) or (tonumber(inttype) > 3))
			) and (commandName:lower() == "addint" or commandName:lower() == "addinterior")
		then
			outputChatBox(
				"Kullanım: /" .. commandName .. " [Interior ID] [TYPE] [Cost] [Name] [Admin Note - Optional]",
				thePlayer,
				255,
				194,
				14
			)
			outputChatBox("TYPE 0: House", thePlayer, 255, 194, 14)
			outputChatBox("TYPE 1: Business", thePlayer, 255, 194, 14)
			outputChatBox("TYPE 2: Government (Unbuyable)", thePlayer, 255, 194, 14)
			outputChatBox("TYPE 3: Rentable", thePlayer, 255, 194, 14)
			outputChatBox("/addnewint to create an interior quickly.", thePlayer, 255, 194, 0)
		else
			local owner, locked = nil, nil
			local x, y, z = getElementPosition(thePlayer)
			local dimension = getElementDimension(thePlayer)
			local interiorwithin = getElementInterior(thePlayer)

			if commandName:lower() == "addnewint" then
				name = "Garage"
				inttype = 0
				owner = -1
				locked = 1
				cost = 8000
				interiorId = 119
			else
				name = table.concat({ ... }, " ")

				inttype = tonumber(inttype)
				owner = nil
				locked = nil

				if inttype == 2 then
					owner = 0
					locked = 0
				else
					owner = -1
					locked = 1
				end
			end
			local interiors = exports["drp_official-interiors"].getInteriorsList()
			interior = interiors[tonumber(interiorId)]
			if interior then
				local ix = interior[2]
				local iy = interior[3]
				local iz = interior[4]
				local optAngle = interior[5]
				local interiorw = interior[1]
				local defaultSupplies = "[ [ ] ]"

				local rot = getPedRotation(thePlayer)
				local qh = dbQuery(
					exports.drp_mysql:getConnection(),
					"INSERT INTO interiors SET interior_id=?, creator=?, id="
						.. exports.drp_mysql:getSmallestID("interiors")
						.. ", x=?, y=?, z=?, "
						.. " type=?, owner=?, locked=?, cost=?, name=?, interior=?, interiorx=?, interiory=?, interiorz=?, dimensionwithin=?, interiorwithin=?, angle=?, angleexit=?, supplies=?, createdDate=NOW() ",
					interiorId,
					getElementData(thePlayer, "account_username"),
					x,
					y,
					z,
					inttype,
					owner,
					locked,
					cost,
					name,
					interiorw,
					ix,
					iy,
					iz,
					dimension,
					interiorwithin,
					optAngle,
					rot,
					defaultSupplies
				)
				local res, rows, inserted_id = dbPoll(qh, 10000)
				if res and rows > 0 then
					local uid = tonumber(inserted_id)
					if uid and uid > 20000 then
						outputChatBox("Failed to create interior: Reached max limit.", thePlayer, 255, 0, 0)
						outputChatBox(
							"This script version supports a maximum of 20,000 interiors (current: "
								.. tostring(uid)
								.. ").",
							thePlayer,
							255,
							0,
							0
						)
						dbExec(
							exports.drp_mysql:getConnection(),
							"DELETE FROM `interiors` WHERE `id`=? LIMIT 1;",
							inserted_id
						)
						dbFree(qh)
						return false
					end
					if tonumber(inttype) == 1 then
						dbExec(
							exports.drp_mysql:getConnection(),
							"INSERT INTO `interior_business` SET `intID`=? ",
							inserted_id
						)
					end
					outputChatBox("Created Interior with ID " .. inserted_id .. ".", thePlayer, 255, 194, 14)
					exports["drp_interior-load"]:loadOne(inserted_id)
					exports.drp_global:sendMessageToAdmins(
						"[INTERIOR]: "
							.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
							.. " has created Interior #"
							.. inserted_id
							.. " with name '"
							.. name
							.. "', type "
							.. inttype
							.. ", price: ₺"
							.. cost
							.. ")."
					)
					exports["drp_interior-manager"]:addInteriorLogs(
						inserted_id,
						commandName .. " - id " .. interiorId .. " - price ₺" .. cost .. " - name " .. name,
						thePlayer
					)
					return true
				end
				dbFree(qh)
			else
				outputChatBox(
					"Failed to create interior - There is no such interior (" .. (interiorID or "??") .. ").",
					thePlayer,
					255,
					0,
					0
				)
			end
		end
	end
end
addCommandHandler("addinterior", createInterior, false, false)
addCommandHandler("addint", createInterior, false, false)
addCommandHandler("addnewint", createInterior, false, false)

function updateInteriorExit(thePlayer, commandName)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local dimension = getElementDimension(thePlayer)

		if dimension == 0 then
			outputChatBox("You are not in an interior.", thePlayer, 255, 0, 0)
		else
			local dbid = getElementDimension(thePlayer)
			local x, y, z = getElementPosition(thePlayer)
			local interior = getElementInterior(thePlayer)
			local _, _, rot = getElementRotation(thePlayer)
			local query = dbExec(
				exports.drp_mysql:getConnection(),
				"UPDATE interiors SET interiorx='"
					.. x
					.. "', interiory='"
					.. y
					.. "', interiorz='"
					.. z
					.. "', angleexit='"
					.. rot
					.. "', `interior`='"
					.. tostring(interior)
					.. "' WHERE id='"
					.. dbid
					.. "'"
			)
			outputChatBox("Interior Exit Position Updated!", thePlayer, 0, 255, 0)

			exports["drp_interior-manager"]:addInteriorLogs(dbid, commandName, thePlayer)

			realReloadInterior(dbid)
			return true
		end
	end
end
addCommandHandler("setinteriorexit", updateInteriorExit, false, false)
addCommandHandler("setintexit", updateInteriorExit, false, false)

function changeInteriorName(thePlayer, commandName, ...)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		local id = getElementDimension(thePlayer)
		if not (...) then
			outputChatBox("Kullanım: /" .. commandName .. " [New Name]", thePlayer, 255, 194, 14)
		elseif dimension == 0 then
			outputChatBox("You are not inside an interior.", thePlayer, 255, 0, 0)
		else
			name = table.concat({ ... }, " ")

			dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET name = ? WHERE id = ?", name, id)
			outputChatBox("Interior name changed to " .. name .. ".", thePlayer, 0, 255, 0)

			local adminUsername = getElementData(thePlayer, "account_username")
			local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)

			exports.drp_global:sendMessageToAdmins(
				"[INTERIOR]: "
					.. adminTitle
					.. " "
					.. getPlayerName(thePlayer):gsub("_", " ")
					.. " ("
					.. adminUsername
					.. ") has changed Interior #"
					.. id
					.. "'s name to '"
					.. name
					.. "'."
			)

			exports["drp_interior-manager"]:addInteriorLogs(id, commandName .. " " .. name, thePlayer)

			realReloadInterior(id)
			return true
		end
	end
end
addCommandHandler("setinteriorname", changeInteriorName, false, false)
addCommandHandler("setintname", changeInteriorName, false, false)

function forceSellProperty(thePlayer, commandName, intID)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		if not intID and getElementDimension(thePlayer) > 0 then
			intID = getElementDimension(thePlayer)
		end

		if not intID or not tonumber(intID) or (tonumber(intID) % 1 ~= 0) or (tonumber(intID) <= 0) then
			outputChatBox("Kullanım: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
			outputChatBox("Force sells a property.", thePlayer, 200, 194, 14)
			return
		end

		local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")
		local foundInt = false

		for _, interior in ipairs(possibleInteriors) do
			if getElementData(interior, "dbid") == tonumber(intID) then
				foundInt = interior
				break
			end
		end

		if not foundInt then
			outputChatBox("Interior ID not found in game.", thePlayer, 255, 0, 0)
			return
		end

		local active, details2 = isActive(foundInt)
		if active and getElementData(thePlayer, "confirm:fsell") ~= intID then
			outputChatBox(
				"You are about to forcesell an interior while it's appearing to be an active interior.",
				thePlayer
			)
			outputChatBox("Please type /" .. commandName .. " " .. intID .. " once again to proceed.", thePlayer)
			setElementData(thePlayer, "confirm:fsell", intID)
			return false
		end

		local interiorEntrance = getElementData(foundInt, "entrance")
		local interiorExit = getElementData(foundInt, "exit")
		local interiorStatus = getElementData(foundInt, "status")

		if interiorStatus.type == 2 then
			outputChatBox("You cannot force-sell a government property.", thePlayer, 255, 0, 0)
		elseif interiorStatus.owner < 1 and interiorStatus.faction < 1 then
			outputChatBox("This property is not owned by anyone at the moment.", thePlayer, 255, 0, 0)
		else
			publicSellProperty(thePlayer, tonumber(intID), true, false, "FORCESELL")
			cleanupProperty(tonumber(intID), true)
			exports["drp_interior-manager"]:addInteriorLogs(intID, commandName, thePlayer)
			setElementData(thePlayer, "confirm:fsell", nil)
		end
	end
end
addCommandHandler("forcesell", forceSellProperty, false, false)
addCommandHandler("fsell", forceSellProperty, false, false)

function forcesellFactionInterior(factionId, intId)
	if client and source and client ~= source then
		exports.drp_sac:banForEventAbuse(client, eventName)
		return
	end

	if not exports.drp_integration:isPlayerTrialAdmin(source) then
		return false
	end

	if not intId or not tonumber(intId) or (tonumber(intId) % 1 ~= 0) or (tonumber(intId) <= 0) then
		return false
	end

	local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")
	local foundInt = false
	for _, interior in ipairs(possibleInteriors) do
		if getElementData(interior, "dbid") == tonumber(intId) then
			foundInt = interior
			break
		end
	end

	if not foundInt then
		return false
	end

	local interiorEntrance = getElementData(foundInt, "entrance")
	local interiorExit = getElementData(foundInt, "exit")
	local interiorStatus = getElementData(foundInt, "status")

	if interiorStatus.type == 2 then
		return false
	elseif interiorStatus.owner < 1 and interiorStatus.faction < 1 then
		return false
	else
		publicSellProperty(source, tonumber(intId), false, false, "FORCESELL")
		exports["drp_interior-manager"]:addInteriorLogs(
			intId,
			"Interior forcesold upon faction deletion (Faction ID: " .. factionId .. ").",
			source
		)
		cleanupProperty(tonumber(intId), true)
	end
end
addEvent("interior:factionfsell", false)
addEventHandler("interior:factionfsell", root, forcesellFactionInterior)

function changeInteriorAddress(thePlayer, commandName, id, ...)
	if exports.drp_integration:isPlayerTrialAdmin(thePlayer) then
		if not id or not (...) then
			outputChatBox(
				"Kullanım: /" .. commandName .. " [Interior ID] [Address or 'reset']",
				thePlayer,
				255,
				194,
				14
			)
			outputChatBox("Kullanım: 'reset' will remove the interiors address.", thePlayer, 255, 194, 14)
		else
			if not tonumber(id) then
				if id == "*" and getElementDimension(thePlayer) > 0 then
					id = getElementDimension(thePlayer)
				else
					outputChatBox("Invalid interior ID specified.", thePlayer, 255, 0, 0)
					return false
				end
			end

			address = table.concat({ ... }, " ")
			if address == "reset" then
				dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET address=NULL WHERE id=?", id)
				outputChatBox("Interior (#" .. id .. ") address has been reset.", thePlayer, 0, 255, 0)
			else
				dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET address=? WHERE id=?", address, id)
				outputChatBox("Interior (#" .. id .. ") address changed to " .. address .. ".", thePlayer, 0, 255, 0)
			end

			local adminUsername = getElementData(thePlayer, "account_username")
			local adminTitle = exports.drp_global:getPlayerAdminTitle(thePlayer)

			exports.drp_global:sendMessageToAdmins(
				"[INTERIOR]: "
					.. adminTitle
					.. " "
					.. getPlayerName(thePlayer):gsub("_", " ")
					.. " ("
					.. adminUsername
					.. ") has changed Interior #"
					.. id
					.. "'s address to '"
					.. address
					.. "'."
			)

			exports["drp_interior-manager"]:addInteriorLogs(id, commandName .. " " .. address, thePlayer)

			realReloadInterior(id)
			return true
		end
	end
end
addCommandHandler("setinterioraddress", changeInteriorAddress)
addCommandHandler("setintaddress", changeInteriorAddress)

function teleportToMarker(thePlayer, commandName)
	if getElementData(thePlayer, "recovery") then
		outputChatBox("You cannot use this command while in recovery!", thePlayer, 255, 194, 14)
		return
	end

	if getElementData(thePlayer, "jailed") then
		outputChatBox("You cannot use this command in jail!", thePlayer, 255, 194, 14)
		return
	end

	local houseID = getElementDimension(thePlayer)
	if not houseID or houseID == 0 then
		outputChatBox("This command only works inside an interior.", thePlayer, 255, 0, 0)
	else
		local dbid, entrance, exit, type, interiorElement = findProperty(thePlayer, houseID)
		if isPedInVehicle(thePlayer) then
			local theVehicle = getPedOccupiedVehicle(thePlayer)
			local respawnPos = getElementData(theVehicle, "respawn_position")
			if not respawnPos then
				return
			end

			local pos = {}
			local posTab = split(respawnPos, ",")
			for i, v in ipairs(posTab) do
				pos[i] = v
			end

			if dbid ~= houseID then
				return
			end

			setElementFrozen(thePlayer, true)
			setElementFrozen(theVehicle, true)
			setElementPosition(theVehicle, pos[1], pos[2], pos[3])
			setTimer(function(thePlayer, theVehicle)
				setElementFrozen(thePlayer, false)
				setElementFrozen(theVehicle, false)
			end, 1000, 1, thePlayer, theVehicle)
			exports["drp_interior-manager"]:addInteriorLogs(dbid, "VEHICLE ANTIFALL", thePlayer)
			local affectedElements = {}
			table.insert(affectedElements, interiorElement)
			for key, value in pairs(getElementsByType("player")) do
				local playerdimension = getElementDimension(value)

				if houseID == playerdimension then
					if getElementData(value, "logged") then
						table.insert(affectedElements, value)
						outputChatBox(
							"(( "
								.. getPlayerName(thePlayer):gsub("_", " ")
								.. "'s vehicle ("
								.. getElementData(theVehicle, "dbid")
								.. ") teleported to the vehicle respawn point. ))",
							value,
							196,
							255,
							255
						)
					end
				end
			end
			return
		end

		local x, y, z = getElementPosition(thePlayer)
		local difference = exit.z - z
		setElementPosition(thePlayer, exit.x, exit.y, exit.z)

		exports["drp_interior-manager"]:addInteriorLogs(dbid, "ANTIFALL", thePlayer)

		local affectedElements = {}
		table.insert(affectedElements, interiorElement)
		for key, value in pairs(getElementsByType("player")) do
			local playerdimension = getElementDimension(value)

			if houseID == playerdimension then
				if getElementData(value, "logged") then
					table.insert(affectedElements, value)
					outputChatBox(
						"(( " .. getPlayerName(thePlayer):gsub("_", " ") .. " teleported to the interior entrance. ))",
						value,
						196,
						255,
						255
					)
				end
			end
		end
	end
end
addCommandHandler("goup", teleportToMarker)
addCommandHandler("antifall", teleportToMarker)
addCommandHandler("falling", teleportToMarker)
addCommandHandler("lifealert", teleportToMarker)
