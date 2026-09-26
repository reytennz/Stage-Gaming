mysql = exports.drp_mysql

local activeGPSs = {}

function findProperty(thePlayer, dimension)
	local dbid = dimension or (thePlayer and getElementDimension(thePlayer) or 0)
	if dbid and tonumber(dbid) and tonumber(dbid) > 0 then
		dbid = tonumber(dbid)
		local foundInterior = exports.drp_pool:getElementByID("interior", dbid)
		if foundInterior then
			local entrance = getElementData(foundInterior, "entrance")
			local interiorExit = getElementData(foundInterior, "exit")
			local interiorStatus = getElementData(foundInterior, "status")
			return dbid, entrance, interiorExit, interiorStatus.type, foundInterior
		end
	end
	return 0
end

function sendPlayersOutside(int)
	local dbid = int
	if tonumber(int) then
		int = exports.drp_pool:getElementByID("interior", int)
	elseif isElement(int) then
		dbid = getElementData(int, "dbid")
	end

	local entrance = getElementData(int, "entrance")
	local exit = getElementData(int, "exit")

	if int and isElement(int) and getElementType(int) == "interior" then
		for key, value in pairs(getElementsByType("player")) do
			if getElementInterior(value) == exit.int and getElementDimension(value) == exit.dim then
				setElementInterior(value, entrance.int)
				setCameraInterior(value, entrance.int)
				setElementDimension(value, entrance.dim)
				setElementPosition(value, entrance.x, entrance.y, entrance.z)
				return true
			end
		end
	end
end

function cleanupProperty(id, donotdestroy)
	if id > 0 then
		if dbExec(exports.drp_mysql:getConnection(), "DELETE FROM shops WHERE dimension = ?", id) then
			local res = getResourceRootElement(getResourceFromName("drp_shop"))
			if res then
				for key, value in pairs(getElementsByType("ped", res)) do
					if getElementDimension(value) == id then
						destroyElement(value)
					end
				end
			end
		end

		if dbExec(exports.drp_mysql:getConnection(), "DELETE FROM atms WHERE dimension = ?", id) then
			local res = getResourceRootElement(getResourceFromName("drp_bank"))
			if res then
				for key, value in pairs(getElementsByType("object", res)) do
					if getElementDimension(value) == id then
						destroyElement(value)
					end
				end
			end
		end

		local resE = getResourceRootElement(getResourceFromName("drp_elevator"))
		if resE then
			exports.drp_elevator:deleteElevatorsFromInterior("MAXIME", "PROPERTYCLEANUP", id)
		end

		if not donotdestroy then
			local res1 = getResourceRootElement(getResourceFromName("drp_object"))
			if res1 then
				exports.drp_object:removeInteriorObjects(id)
			end
		end

		clearSafe(id, true)

		setTimer(function()
			exports.drp_item:deleteAllItemsWithinInt(id, 0, "CLEANUPINT")
		end, 3000, 1)
	end
end

function sellProperty(thePlayer, commandName, bla)
	if bla then
		outputChatBox(
			"[!]#FFFFFF Bu mülkü başka bir oyuncuya satmak için /sell kullanın.",
			thePlayer,
			0,
			0,
			255,
			true
		)
		return
	end

	local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
	if dbid > 0 then
		if interiorType == 2 then
			outputChatBox("[!]#FFFFFF Devlet mülklerini satamazsınız.", thePlayer, 255, 0, 0, true)
		elseif interiorType ~= 3 and commandName == "unrent" then
			outputChatBox("[!]#FFFFFF Bu mülkü kiralamadınız.", thePlayer, 255, 0, 0, true)
		else
			local interiorStatus = getElementData(interiorElement, "status")
			local faction, _ = exports.drp_faction:isPlayerInFaction(thePlayer, interiorStatus.faction)
			local leader =
				exports.drp_faction:hasMemberPermissionTo(thePlayer, interiorStatus.faction, "manage_interiors")
			if interiorStatus.owner == getElementData(thePlayer, "dbid") or (leader and faction) then
				publicSellProperty(thePlayer, dbid, true, not interiorStatus.tokenUsed, false)
				cleanupProperty(dbid, true)
				dbExec(
					exports.drp_mysql:getConnection(),
					"INSERT INTO `interior_logs` (`intID`, `action`, `actor`) VALUES ('"
						.. tostring(dbid)
						.. "', '"
						.. commandName
						.. "', '"
						.. getElementData(thePlayer, "account_id")
						.. "')"
				)
				outputChatBox("[!]#FFFFFF Mülk başarıyla satıldı.", thePlayer, 0, 255, 0, true)
			else
				outputChatBox("[!]#FFFFFF Bu mülkün sahibi siz değilsiniz.", thePlayer, 255, 0, 0, true)
			end
		end
	else
		outputChatBox("[!]#FFFFFF Şu anda herhangi bir mülk içinde değilsiniz.", thePlayer, 255, 0, 0, true)
	end
end
addCommandHandler("sellproperty", sellProperty, false, false)
addCommandHandler("unrent", sellProperty, false, false)

local function movePlayerToEntrance(player, entrance)
	setElementInterior(player, entrance.int)
	setCameraInterior(player, entrance.int)
	setElementDimension(player, entrance.dim)
	setElementPosition(player, entrance.x, entrance.y, entrance.z)
	setElementData(player, "interiormarker", false)
end

local function moveCharactersOutside(interiorId, onlyOffline)
	if interiorId < 1 then
		return
	end

	local dbid, entrance, exit = findProperty(nil, interiorId)

	dbQuery(function(handle)
		local results = dbPoll(handle, 0)
		local offlineCharacterIds = {}
		local playersMoved = {}

		for _, character in ipairs(results) do
			local player = getPlayerFromName(character.name)

			if isElement(player) and not onlyOffline then
				movePlayerToEntrance(player, entrance)
				table.insert(playersMoved, character.id, true)
			else
				table.insert(offlineCharacterIds, character.id)
			end
		end

		for _, player in pairs(getElementsByType("player")) do
			if getElementDimension(player) == interiorId and not playersMoved[player] and not onlyOffline then
				movePlayerToEntrance(player, entrance)
			end
		end

		if #offlineCharacterIds > 0 then
			dbExec(
				exports.drp_mysql:getConnection(),
				"UPDATE characters SET x = ?, y = ?, z = ?, interior = ?, dimension = ? WHERE id IN ("
					.. table.concat(offlineCharacterIds, ", ")
					.. ")",
				entrance.x,
				entrance.y,
				entrance.z,
				entrance.int,
				entrance.dim
			)
		end
	end, exports.drp_mysql:getConnection(), "SELECT id, name FROM characters WHERE dimension = ?", interiorId)
end

function publicSellProperty(thePlayer, dbid, showmessages, giveMoney, CLEANUP)
	local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer, dbid)
	local query = dbExec(
		exports.drp_mysql:getConnection(),
		"UPDATE interiors SET owner=-1, faction=0, locked=1, tokenUsed=0, safepositionX=NULL, safepositionY=NULL, safepositionZ=NULL, safepositionRZ=NULL WHERE id=?",
		dbid
	)
	if query then
		local interiorStatus = getElementData(interiorElement, "status")

		moveCharactersOutside(dbid)
		clearSafe(dbid, true)

		if interiorType == 0 or interiorType == 1 then
			if interiorType == 1 then
				dbExec(exports.drp_mysql:getConnection(), "DELETE FROM interior_business WHERE intID = ?", dbid)
			end

			local gov = exports.drp_faction:getFactionFromID(3)

			if interiorStatus.owner == getElementData(thePlayer, "dbid") then
				local money = math.ceil(interiorStatus.cost * 2 / 3)
				if giveMoney then
					exports.drp_global:giveMoney(thePlayer, money)
					exports.drp_global:takeMoney(gov, money)
				end

				if showmessages then
					if CLEANUP == "FORCESELL" then
						exports.drp_global:sendMessageToAdmins(
							"[ADM] "
								.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
								.. " has force-sold interior #"
								.. dbid
								.. " ("
								.. getElementData(interiorElement, "name")
								.. ")."
						)
						exports["drp_interior-manager"]:addInteriorLogs(dbid, "FORCESELL", thePlayer)
					elseif giveMoney then
						outputChatBox(
							"[!]#FFFFFF Mülkünüz ₺"
								.. exports.drp_global:formatMoney(money)
								.. " karşılığında satıldı.",
							thePlayer,
							0,
							255,
							0,
							true
						)
					else
						outputChatBox(
							"[!]#FFFFFF Bu mülk, daha önce bir token ile alındığı için ₺0 karşılığında satıldı.",
							thePlayer,
							0,
							255,
							0,
							true
						)
					end
				end

				exports.drp_item:deleteAll(interiorType == 0 and 4 or 5, dbid)
			elseif exports.drp_faction:isPlayerInFaction(thePlayer, interiorStatus.faction) then
				local money = math.ceil(interiorStatus.cost * 2 / 3)
				local faction = exports.drp_faction:getFactionFromID(interiorStatus.faction)

				if giveMoney and faction then
					exports.drp_global:giveMoney(faction, money)
					exports.drp_global:takeMoney(gov, money)
				end

				if showmessages then
					if CLEANUP == "FORCESELL" then
						exports.drp_global:sendMessageToAdmins(
							"[ADM] "
								.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
								.. " has force-sold interior #"
								.. dbid
								.. " ("
								.. getElementData(interiorElement, "name")
								.. ")."
						)
						exports["drp_interior-manager"]:addInteriorLogs(dbid, "FORCESELL", thePlayer)
					elseif faction then
						if giveMoney then
							outputChatBox(
								"[!]#FFFFFF Mülk ₺"
									.. exports.drp_global:formatMoney(money)
									.. " karşılığında satıldı (Bankaya aktarıldı: '"
									.. getTeamName(faction)
									.. "')",
								thePlayer,
								0,
								255,
								0,
								true
							)
						else
							outputChatBox(
								"[!]#FFFFFF Token ile alınmış ve fraksiyona atanmış mülk ₺0 karşılığında satıldı.",
								thePlayer,
								0,
								255,
								0,
								true
							)
						end
					end
				end

				exports.drp_item:deleteAll(interiorType == 0 and 4 or 5, dbid)
			else
				if showmessages then
					if CLEANUP == "FORCESELL" then
						exports.drp_global:sendMessageToAdmins(
							"[ADM] "
								.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
								.. " has force-sold interior #"
								.. dbid
								.. " ("
								.. getElementData(interiorElement, "name")
								.. ")."
						)
						exports["drp_interior-manager"]:addInteriorLogs(dbid, "FORCESELL", thePlayer)
					else
						outputChatBox(
							"[!]#FFFFFF Bu mülk artık sahipsiz olarak ayarlandı.",
							thePlayer,
							0,
							255,
							0,
							true
						)
					end
				end
			end
		else
			if showmessages then
				if CLEANUP == "FORCESELL" then
					exports.drp_global:sendMessageToAdmins(
						"[ADM] "
							.. exports.drp_global:getPlayerFullAdminTitle(thePlayer)
							.. " has force-sold interior #"
							.. dbid
							.. " ("
							.. getElementData(interiorElement, "name")
							.. ")."
					)
					exports["drp_interior-manager"]:addInteriorLogs(dbid, "FORCESELL", thePlayer)
				else
					outputChatBox("[!]#FFFFFF Artık bu mülkü kiralamıyorsunuz.", thePlayer, 0, 255, 0, true)
				end
			end

			exports.drp_item:deleteAll(interiorType == 0 and 4 or 5, dbid)
		end
		realReloadInterior(dbid, { thePlayer })
	else
		outputChatBox("[!]#FFFFFF Bir sorun oluştu.", thePlayer, 255, 0, 0, true)
	end
end

function sellTo(thePlayer, commandName, targetPlayerName)
	local dbid, entrance, exit, interiorType, interiorElement = findProperty(thePlayer)
	if dbid > 0 and not isPedInVehicle(thePlayer) then
		local interiorStatus = getElementData(interiorElement, "status")
		if interiorStatus.type == 2 then
			outputChatBox("You cannot sell a government property.", thePlayer, 255, 0, 0)
		elseif not targetPlayerName then
			outputChatBox("Kullanım: /" .. commandName .. " [Karakter Adı / ID]", thePlayer, 255, 194, 14)
			outputChatBox("Sells the Property you're in to that Player.", thePlayer, 255, 194, 14)
			outputChatBox("Ask the buyer to use /pay to recieve the money for the Property.", thePlayer, 255, 194, 14)
		else
			local targetPlayer, targetPlayerName =
				exports.drp_global:findPlayerByPartialNick(thePlayer, targetPlayerName)
			if targetPlayer and getElementData(targetPlayer, "dbid") then
				local px, py, pz = getElementPosition(thePlayer)
				local tx, ty, tz = getElementPosition(targetPlayer)
				if
					getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) < 10
					and getElementDimension(targetPlayer) == getElementDimension(thePlayer)
				then
					if not exports.drp_global:canPlayerBuyInterior(targetPlayer) then
						outputChatBox(targetPlayerName .. " has already too much interiors.", thePlayer, 255, 0, 0)
						outputChatBox(
							(getPlayerName(thePlayer):gsub("_", " "))
								.. " tried to sell you an interior, but you have too much interiors already.",
							targetPlayer,
							255,
							0,
							0
						)
						return false
					end
					if interiorStatus.tokenUsed then
						outputChatBox(
							"This interior was purchased via a token and therefore cannot be sold to other players. Use /sellproperty instead.",
							thePlayer,
							255,
							0,
							0
						)
						return
					end

					if
						interiorStatus.owner == getElementData(thePlayer, "dbid")
						or exports.drp_integration:isPlayerManager(thePlayer)
					then
						if getElementData(targetPlayer, "dbid") ~= interiorStatus.owner then
							if exports.drp_item:hasSpaceForItem(targetPlayer, 4, dbid) then
								local query = dbExec(
									exports.drp_mysql:getConnection(),
									"UPDATE interiors SET owner = '"
										.. getElementData(targetPlayer, "dbid")
										.. "', faction=0, last_used=NOW() WHERE id='"
										.. dbid
										.. "'"
								)
								if query then
									local keytype = 4
									if interiorType == 1 then
										keytype = 5
									end

									moveCharactersOutside(dbid, true)
									exports.drp_item:deleteAll(4, dbid)
									exports.drp_item:deleteAll(5, dbid)
									exports.drp_item:giveItem(targetPlayer, keytype, dbid)

									if interiorType == 0 or interiorType == 1 then
										outputChatBox(
											"You've successfully sold your property to " .. targetPlayerName .. ".",
											thePlayer,
											0,
											255,
											0
										)
										outputChatBox(
											(getPlayerName(thePlayer):gsub("_", " ")) .. " sold you this property.",
											targetPlayer,
											0,
											255,
											0
										)
									else
										outputChatBox(
											targetPlayerName .. " has taken over your rent contract.",
											thePlayer,
											0,
											255,
											0
										)
										outputChatBox(
											"You did take over "
												.. getPlayerName(thePlayer):gsub("_", " ")
												.. "'s renting contract.",
											targetPlayer,
											0,
											255,
											0
										)
									end

									realReloadInterior(dbid, { targetPlayer, thePlayer })
									exports["drp_interior-manager"]:addInteriorLogs(
										dbid,
										commandName
											.. " to "
											.. targetPlayerName
											.. "("
											.. getElementData(targetPlayer, "account_username")
											.. ")",
										thePlayer
									)
								else
									outputChatBox("Error 09002 - Report on Forums.", thePlayer, 255, 0, 0)
								end
							else
								outputChatBox(
									targetPlayerName .. " has no space for the property keys.",
									thePlayer,
									255,
									0,
									0
								)
							end
						else
							outputChatBox("You can't sell your own property to yourself.", thePlayer, 255, 0, 0)
						end
					else
						outputChatBox("This property is not yours.", thePlayer, 255, 0, 0)
					end
				else
					outputChatBox("You are too far away from " .. targetPlayerName .. ".", thePlayer, 255, 0, 0)
				end
			end
		end
	end
end
addCommandHandler("sell", sellTo, false, false)

function realReloadInterior(id, updatePlayers)
	exports["drp_interior-load"]:unload(tonumber(id))
	exports["drp_interior-load"]:loadOne(id, updatePlayers)
end

function buyInterior(player, pickup, cost, isHouse, isRentable)
	if not exports.drp_global:canPlayerBuyInterior(player) then
		outputChatBox("You have already had too much interiors.", player, 255, 0, 0)
		return false
	end

	local dbid = getElementData(player, "dbid")

	if isRentable then
		local query = dbQuery(
			exports.drp_mysql:getConnection(),
			"SELECT COUNT(*) AS cntval FROM `interiors` WHERE `owner` = ? AND `type` = 3",
			dbid
		)
		local result = dbPoll(query, -1)

		if result and result[1] and tonumber(result[1].cntval) > 0 then
			outputChatBox("You are already renting another house.", player, 255, 0, 0)
			return false
		end
	elseif not exports.drp_item:hasSpaceForItem(player, 4, 1) then
		outputChatBox("You do not have the space for the keys.", player, 255, 0, 0)
		return false
	end

	if exports.drp_global:takeMoney(player, cost) then
		if isHouse then
			outputChatBox(
				"Congratulations! You have just bought this house for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				player,
				255,
				194,
				14
			)
			exports.drp_global:giveMoney(getTeamFromName("İstanbul Büyükşehir Belediyesi"), cost)
		elseif isRentable then
			outputChatBox(
				"Congratulations! You are now renting this property for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				player,
				255,
				194,
				14
			)
		else
			outputChatBox(
				"Congratulations! You have just bought this business for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				player,
				255,
				194,
				14
			)
			exports.drp_global:giveMoney(getTeamFromName("İstanbul Büyükşehir Belediyesi"), cost)
		end

		local pickupid = getElementData(pickup, "dbid")

		dbExec(
			exports.drp_mysql:getConnection(),
			"UPDATE `interiors` SET `owner` = ?, `locked` = 0, `tokenUsed` = 0, `last_used` = NOW() WHERE `id` = ?",
			dbid,
			pickupid
		)

		exports.drp_item:deleteAll(4, pickupid)
		exports.drp_item:deleteAll(5, pickupid)

		if isHouse or isRentable then
			exports.drp_item:giveItem(player, 4, pickupid)
		else
			exports.drp_item:giveItem(player, 5, pickupid)
		end

		realReloadInterior(tonumber(pickupid), { player })

		exports["drp_interior-manager"]:addInteriorLogs(
			pickupid,
			"Bought/rented, ₺" .. exports.drp_global:formatMoney(cost) .. ", " .. getPlayerName(player),
			player
		)
	else
		outputChatBox("Sorry, you cannot afford to purchase this property.", player, 255, 194, 14)
	end
end

function buyPropertyForFaction(interior, cost, isHouse, furniture, factionName)
	if client and source and client ~= source then
		exports.drp_sac:banForEventAbuse(client, eventName)
		return
	end

	local factionId = exports.drp_faction:getFactionIDFromName(factionName)

	local can, reason = exports.drp_global:canPlayerFactionBuyInterior(source, cost, factionId)
	if not can then
		outputChatBox(reason, source, 255, 0, 0)
		return
	end

	local theFaction = can
	if not exports.drp_global:takeMoney(theFaction, cost) then
		outputChatBox("Could not take money from your faction bank.", source, 255, 0, 0)
		return
	end

	local gov = getTeamFromName("İstanbul Büyükşehir Belediyesi")
	local intName = getElementData(interior, "name")
	local intId = getElementData(interior, "dbid")
	exports.drp_global:giveMoney(gov, cost)

	if
		not dbExec(
			exports.drp_mysql:getConnection(),
			"UPDATE interiors SET owner='-1', faction='"
				.. factionId
				.. "', locked=0, tokenUsed=0, last_used=NOW(), furniture="
				.. (furniture and 1 or 0)
				.. " WHERE id='"
				.. intId
				.. "'"
		)
	then
		exports.drp_global:giveMoney(theFaction, cost)
		exports.drp_global:takeMoney(gov, cost)
		outputChatBox("Internal error code 334INT2.", source, 255, 0, 0)
		return false
	end
	local factionName = getTeamName(theFaction):gsub("_", " ")
	outputChatBox(
		"Congratulations! You have just bought this property for your faction '"
			.. factionName
			.. "' for ₺"
			.. exports.drp_global:formatMoney(cost)
			.. ".",
		source,
		255,
		194,
		14
	)

	exports.drp_item:deleteAll(isHouse and 4 or 5, intId)
	exports.drp_item:giveItem(source, isHouse and 4 or 5, intId)

	exports["drp_interior-manager"]:addInteriorLogs(
		intId,
		"Bought for faction '"
			.. factionName
			.. "', ₺"
			.. exports.drp_global:formatMoney(cost)
			.. ", "
			.. getPlayerName(source),
		source
	)

	local entrance = getElementData(interior, "entrance")
	triggerLatentClientEvent(source, "createBlipAtXY", source, entrance.type, entrance.x, entrance.y)

	realReloadInterior(tonumber(intId))
	return true
end
addEvent("buyPropertyForFaction", true)
addEventHandler("buyPropertyForFaction", root, buyPropertyForFaction)

function buyInteriorCash(pickup, cost, isHouse, isRentable, furniture)
	if client and source and client ~= source then
		exports.drp_sac:banForEventAbuse(client, eventName)
		return
	end

	if not exports.drp_global:canPlayerBuyInterior(client) then
		outputChatBox(
			"Maksimum mülk sayısına ulaştınız. Daha fazla mülke sahip olmak için mülk slotu satın almanız gerekiyor.",
			client,
			255,
			0,
			0
		)
		return
	end

	local dbid = getElementData(client, "dbid")

	if isRentable then
		local query = dbQuery(
			exports.drp_mysql:getConnection(),
			"SELECT COUNT(*) AS cntval FROM `interiors` WHERE `owner` = ? AND `type` = 3",
			dbid
		)
		local result = dbPoll(query, -1)

		if result and result[1] and tonumber(result[1].cntval) > 0 then
			outputChatBox("You are already renting another house.", client, 255, 0, 0)
			return
		end
	elseif not exports.drp_item:hasSpaceForItem(client, 4, 1) then
		outputChatBox("You do not have the space for the keys.", client, 255, 0, 0)
		return
	end

	if exports.drp_global:takeMoney(client, cost) then
		local pickupid = getElementData(pickup, "dbid")
		local intName = getElementData(pickup, "name")
		local gov = getTeamFromName("İstanbul Büyükşehir Belediyesi")
		local govID = getElementData(gov, "id")

		if isHouse then
			outputChatBox(
				"Congratulations! You have just bought this house for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				client,
				255,
				194,
				14
			)
			exports.drp_global:giveMoney(gov, cost)
		elseif isRentable then
			outputChatBox(
				"Congratulations! You are now renting this property for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				client,
				255,
				194,
				14
			)
		else
			outputChatBox(
				"Congratulations! You have just bought this business for ₺"
					.. exports.drp_global:formatMoney(cost)
					.. ".",
				client,
				255,
				194,
				14
			)
			exports.drp_global:giveMoney(gov, cost)
		end

		dbExec(
			exports.drp_mysql:getConnection(),
			"UPDATE `interiors` SET `owner` = ?, `locked` = 0, `tokenUsed` = 0, `last_used` = NOW(), `furniture` = ? WHERE `id` = ?",
			dbid,
			(furniture and 1 or 0),
			pickupid
		)

		exports.drp_item:deleteAll(isHouse and 4 or 5, pickupid)
		exports.drp_item:giveItem(client, isHouse and 4 or 5, pickupid)

		exports["drp_interior-manager"]:addInteriorLogs(
			pickupid,
			"Bought/rented, ₺" .. exports.drp_global:formatMoney(cost) .. ", " .. getPlayerName(client),
			client
		)

		local entrance = getElementData(pickup, "entrance")
		triggerLatentClientEvent(client, "createBlipAtXY", client, entrance.type, entrance.x, entrance.y)

		realReloadInterior(tonumber(pickupid), { client })
	else
		outputChatBox("Sorry, you cannot afford to purchase this property.", client, 255, 194, 14)
	end
end
addEvent("buyPropertyWithCash", true)
addEventHandler("buyPropertyWithCash", root, buyInteriorCash)

function buyInteriorBank(pickup, cost, isHouse, isRentable, furniture)
	if client and source and client ~= source then
		exports.drp_sac:banForEventAbuse(client, eventName)
		return
	end

	if not exports.drp_global:canPlayerBuyInterior(client) then
		outputChatBox(
			"Maksimum mülk sayısına ulaştınız. Daha fazla mülke sahip olmak için mülk slotu satın almanız gerekiyor.",
			client,
			255,
			0,
			0
		)
		return
	end

	local dbid = getElementData(client, "dbid")

	if isRentable then
		local query = dbQuery(
			exports.drp_mysql:getConnection(),
			"SELECT COUNT(*) AS cntval FROM `interiors` WHERE `owner` = ? AND `type` = 3",
			dbid
		)
		local result = dbPoll(query, -1)

		if result and result[1] and tonumber(result[1].cntval) > 0 then
			outputChatBox("You are already renting another house.", client, 255, 0, 0)
			return
		end
	elseif not exports.drp_item:hasSpaceForItem(client, 4, 1) then
		outputChatBox("You do not have the space for the keys.", client, 255, 0, 0)
		return
	end

	if not exports.drp_bank:takeBankMoney(client, cost) then
		outputChatBox("You lack the money in your bank to buy this property", client, 255, 0, 0)
		return
	end

	local pickupid = getElementData(pickup, "dbid")
	local gov = getTeamFromName("İstanbul Büyükşehir Belediyesi")
	local govID = getElementData(gov, "id")
	local intName = getElementData(pickup, "name")

	if isHouse then
		outputChatBox(
			"Congratulations! You have just bought this house for ₺" .. exports.drp_global:formatMoney(cost) .. ".",
			client,
			255,
			194,
			14
		)
		exports.drp_global:giveMoney(gov, cost)
	elseif isRentable then
		outputChatBox(
			"Congratulations! You are now renting this property for ₺" .. exports.drp_global:formatMoney(cost) .. ".",
			client,
			255,
			194,
			14
		)
	else
		outputChatBox(
			"Congratulations! You have just bought this business for ₺" .. exports.drp_global:formatMoney(cost) .. ".",
			client,
			255,
			194,
			14
		)
		exports.drp_global:giveMoney(gov, cost)
	end

	dbExec(
		exports.drp_mysql:getConnection(),
		"UPDATE `interiors` SET `owner` = ?, `locked` = 0, `last_used` = NOW(), `tokenUsed` = 0, `furniture` = ? WHERE `id` = ?",
		dbid,
		(furniture and 1 or 0),
		pickupid
	)

	exports.drp_item:deleteAll(isHouse and 4 or 5, pickupid)
	exports.drp_item:giveItem(client, isHouse and 4 or 5, pickupid)

	exports["drp_interior-manager"]:addInteriorLogs(
		pickupid,
		"Bought/rented, ₺" .. exports.drp_global:formatMoney(cost) .. ", " .. getPlayerName(client),
		client
	)

	local entrance = getElementData(pickup, "entrance")
	triggerLatentClientEvent(client, "createBlipAtXY", client, entrance.type, entrance.x, entrance.y)

	realReloadInterior(tonumber(pickupid), { client })
end
addEvent("buyPropertyWithBank", true)
addEventHandler("buyPropertyWithBank", root, buyInteriorBank)

function buyInteriorToken(pickup, furniture)
	if client and source and client ~= source then
		exports.drp_sac:banForEventAbuse(client, eventName)
		return
	end

	if not exports.drp_global:canPlayerBuyInterior(client) then
		outputChatBox(
			"Maksimum mülk sayısına ulaştınız. Daha fazla mülke sahip olmak için mülk slotu satın almanız gerekiyor.",
			client,
			255,
			0,
			0
		)
		return
	end

	if not exports.drp_item:hasSpaceForItem(client, 4, 1) then
		outputChatBox("You do not have the space for the keys.", client, 255, 0, 0)
		return
	end

	if not exports.drp_item:takeItem(client, 262) then
		outputChatBox("You do not have a token to buy this property", client, 255, 0, 0)
	else
		local charid = getElementData(client, "dbid")
		local pickupid = getElementData(pickup, "dbid")
		outputChatBox(
			"Congratulations! You have just used a token to purchase this house, remember this house holds no cash value and you cannot sell it to friends.",
			client,
			255,
			194,
			14
		)

		dbExec(
			exports.drp_mysql:getConnection(),
			"UPDATE interiors SET owner='"
				.. charid
				.. "', locked=0, last_used=NOW(), furniture="
				.. (furniture and 1 or 0)
				.. " , tokenUsed=1 WHERE id='"
				.. pickupid
				.. "'"
		)

		exports.drp_item:deleteAll(4, pickupid)
		exports.drp_item:giveItem(client, 4, pickupid)

		exports["drp_interior-manager"]:addInteriorLogs(pickupid, "Bought - TOKEN, " .. getPlayerName(client), client)

		local entrance = getElementData(pickup, "entrance")
		triggerLatentClientEvent(client, "createBlipAtXY", client, entrance.type, entrance.x, entrance.y)

		realReloadInterior(tonumber(pickupid), { client })
	end
end
addEvent("buyPropertyWithToken", true)
addEventHandler("buyPropertyWithToken", root, buyInteriorToken)

function enterInterior()
	if source and client then
		local canEnter, errorCode, errorMsg = canEnterInterior(source)
		if canEnter then
			setPlayerInsideInterior(source, client)
		elseif isInteriorForSale(source) then
			local interiorStatus = getElementData(source, "status")
			local cost = interiorStatus.cost
			local isHouse = interiorStatus.type == 0
			local isRentable = interiorStatus.type == 3
			local neighborhood = exports.drp_global:getElementZoneName(source)
			triggerClientEvent(client, "openPropertyGUI", client, source, cost, isHouse, isRentable, neighborhood)
		else
			outputChatBox("[!]#FFFFFF " .. errorMsg, client, 255, 0, 0, true)
		end
	end
end
addEvent("interior.enter", true)
addEventHandler("interior.enter", root, enterInterior)

local interiorTimer = {}

function setPlayerInsideInterior(theInterior, thePlayer, teleportTo, sameInt, elevator)
	if interiorTimer[thePlayer] or not theInterior then
		return false
	end

	interiorTimer[thePlayer] = true

	local enter = true
	if not teleportTo then
		local pedCurrentDimension = getElementDimension(thePlayer)
		local entrance = getElementData(theInterior, "entrance")
		local interiorExit = getElementData(theInterior, "exit")
		if (entrance.dim or entrance[INTERIOR_DIM]) == pedCurrentDimension then
			teleportTo = interiorExit
			enter = true
		else
			teleportTo = entrance
			enter = false
		end
	end

	if (teleportTo.dim or teleportTo[INTERIOR_DIM]) ~= 0 then
		furniture = getElementData(theInterior, "status").furniture
	end

	if isElement(elevator) and getElementType(elevator) == "elevator" then
		doorGoThru(elevator, thePlayer)
	else
		doorGoThru(theInterior, thePlayer)
	end

	teleportTo = tempFix(teleportTo)

	triggerClientEvent(thePlayer, "cantFallOffBike", thePlayer)
	triggerClientEvent(thePlayer, "setPlayerInsideInterior", theInterior, teleportTo, theInterior, furniture)
	setElementInterior(thePlayer, teleportTo.int)
	setElementDimension(thePlayer, teleportTo.dim)
	if teleportTo.rot then
		setElementRotation(thePlayer, 0, 0, teleportTo.rot)
	end
	setElementPosition(thePlayer, teleportTo.x, teleportTo.y, teleportTo.z, true)

	setPedAnimation(thePlayer)

	if sameInt and interiorTimer[thePlayer] then
		interiorTimer[thePlayer] = false
	end

	local dbid = getElementData(theInterior, "dbid")
	dbExec(exports.drp_mysql:getConnection(), "UPDATE `interiors` SET `last_used` = NOW() WHERE `id` = ?", dbid)
	setElementData(theInterior, "last_used", exports.drp_datetime:now(), true)

	exports["drp_interior-manager"]:addInteriorLogs(dbid, enter and "Entered" or "Exited", thePlayer)
	return true
end

addEventHandler("onPlayerInteriorChange", root, function(toInterior, toDimension)
	setElementAlpha(client, getElementData(client, "invisible") and 0 or 255)
	interiorTimer[client] = false
end)

function setPlayerInsideInterior2(theInterior, thePlayer)
	local teleportTo = nil
	local pedCurrentDimension = getElementDimension(thePlayer)
	local entrance = getElementData(theInterior, "entrance")
	local interiorExit = getElementData(theInterior, "exit")
	local interiorStatus = getElementData(theInterior, "status")

	if entrance.dim == pedCurrentDimension then
		teleportTo = interiorExit
	else
		teleportTo = entrance
	end

	if teleportTo then
		triggerClientEvent(
			thePlayer,
			"setPlayerInsideInterior2",
			theInterior,
			teleportTo,
			theInterior,
			interiorStatus.furniture
		)

		setElementInterior(thePlayer, teleportTo.int)
		setElementDimension(thePlayer, teleportTo.dim)

		doorGoThru(theInterior, thePlayer)
		local dbid = getElementData(theInterior, "dbid")
		dbExec(exports.drp_mysql:getConnection(), "UPDATE `interiors` SET `last_used`=NOW() WHERE `id`=?", dbid)
		setElementData(theInterior, "last_used", exports.drp_datetime:now(), true)
	end
end

function setPlayerInsideInterior3(theInterior, thePlayer, teleportTo, sameInt, elevator, camerafade)
	if interiorTimer[thePlayer] then
		return false
	end
	interiorTimer[thePlayer] = true

	local enter = true
	if not teleportTo then
		return false
	end
	local dbid

	if camerafade then
		fadeCamera(thePlayer, false)
	end

	if teleportTo.int > 0 and teleportTo.dim > 0 then
		if teleportTo.dim > 20000 then
			if not theVehicle then
				theVehicle = exports.drp_pool:getElementByID("vehicle", teleportTo.dim - 20000) or false
			end
			dbid = teleportTo.dim - 20000
			dbExec(exports.drp_mysql:getConnection(), "UPDATE `vehicles` SET `lastUsed`=NOW() WHERE `id`=?", dbid)
			if theVehicle then
				setElementData(theVehicle, "last_used", exports.drp_datetime:now(), true)
			end
		else
			if not theInterior then
				theInterior = exports.drp_pool:getElementByID("interior", teleportTo.dim) or false
			end
			dbid = teleportTo.dim
			dbExec(exports.drp_mysql:getConnection(), "UPDATE `interiors` SET `last_used`=NOW() WHERE `id`=?", dbid)
			if theInterior then
				setElementData(theInterior, "last_used", exports.drp_datetime:now(), true)
			end
		end
	else
		theInterior = false
		theVehicle = false
	end

	local playerDim = getElementDimension(thePlayer)
	if playerDim ~= 0 then
		if playerDim > 20000 then
			local playerInterior = exports.drp_pool:getElementByID("vehicle", teleportTo.dim - 20000) or false
			dbExec(
				exports.drp_mysql:getConnection(),
				"UPDATE `vehicles` SET `last_used`=NOW() WHERE `id`=?",
				playerDim - 20000
			)
			if playerInterior then
				setElementData(playerInterior, "last_used", exports.drp_datetime:now(), true)
			end
		else
			local playerInterior = exports.drp_pool:getElementByID("interior", playerDim) or false
			dbExec(
				exports.drp_mysql:getConnection(),
				"UPDATE `interiors` SET `last_used`=NOW() WHERE `id`=?",
				playerDim
			)
			if playerInterior then
				setElementData(playerInterior, "last_used", exports.drp_datetime:now(), true)
			end
		end
	end

	if theInterior then
		furniture = getElementData(theInterior, "status").furniture
	end

	triggerClientEvent(thePlayer, "cantFallOffBike", thePlayer)
	triggerClientEvent(thePlayer, "setPlayerInsideInterior", thePlayer, teleportTo, theInterior, furniture, camerafade)
	setElementInterior(thePlayer, teleportTo.int)
	setElementDimension(thePlayer, teleportTo.dim)
	if teleportTo.rot then
		setElementRotation(thePlayer, 0, 0, teleportTo.rot)
	end
	setElementPosition(thePlayer, teleportTo.x, teleportTo.y, teleportTo.z, true)

	if theInterior and dbid then
		exports["drp_interior-manager"]:addInteriorLogs(dbid, enter and "Entered" or "Exited", thePlayer)
	end
	return true
end

function moveSafe(thePlayer, commandName)
	local x, y, z = getElementPosition(thePlayer)
	local rotz = getPedRotation(thePlayer)
	local dbid = getElementDimension(thePlayer)
	local interior = getElementInterior(thePlayer)
	if
		(
			dbid < 19000
			and (exports.drp_item:hasItem(thePlayer, 5, dbid) or exports.drp_item:hasItem(thePlayer, 4, dbid))
		) or (dbid >= 20000 and exports.drp_item:hasItem(thePlayer, 3, dbid - 20000))
	then
		if
			getPedContactElement(thePlayer) == safeTable[dbid]
			or getPedContactElement(thePlayer) == exports.drp_vehicle:getSafe(dbid - 20000)
		then
			outputChatBox("Please move to a new position before repositioning a safe.", thePlayer, 255, 0, 0)
		else
			z = z - 0.5
			rotz = rotz + 180
			if dbid >= 20000 and exports.drp_vehicle:getSafe(dbid - 20000) then
				local safe = exports.drp_vehicle:getSafe(dbid - 20000)
				dbExec(
					exports.drp_mysql:getConnection(),
					"UPDATE vehicles SET safepositionX='"
						.. x
						.. "', safepositionY='"
						.. y
						.. "', safepositionZ='"
						.. z
						.. "', safepositionRZ='"
						.. rotz
						.. "' WHERE id='"
						.. (dbid - 20000)
						.. "'"
				)
				setElementPosition(safe, x, y, z)
				setObjectRotation(safe, 0, 0, rotz)
			elseif dbid > 0 and getSafe(dbid) then
				if not updateSafe(dbid, { x, y, z }, rotz) then
					outputChatBox("Errors occurred while moving safe.", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("You need a safe to move!", thePlayer, 255, 0, 0)
			end
		end
	else
		outputChatBox("You need the keys of this interior to move the Safe.", thePlayer, 255, 0, 0)
	end
	outputChatBox(
		"WARNING: These types of Safes are deprecated. You can buy a Storage Generic Safe from any Electronic stores.",
		thePlayer,
		255,
		0,
		0
	)
end
addCommandHandler("movesafe", moveSafe)

local function hasKey(source, key)
	if exports.drp_item:hasItem(source, 4, key) or exports.drp_item:hasItem(source, 5, key) then
		return true, false
	else
		if getElementData(source, "duty_admin") then
			return true, true
		else
			return false, false
		end
	end
	return false, false
end

function lockUnlockHouseEvent(player, checkdistance)
	if player then
		source = player
	end

	local itemValue = nil
	local found = nil
	local foundpoint = nil
	local minDistance = 2
	local interiorName = ""
	local pPosX, pPosY, pPosZ = getElementPosition(source)
	local dimension = getElementDimension(source)

	local canEnter, byAdmin = nil

	local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")
	for _, interior in ipairs(possibleInteriors) do
		local entrance = getElementData(interior, "entrance")
		local interiorExit = getElementData(interior, "exit")
		for _, point in ipairs({ entrance, interiorExit }) do
			if point.dim == dimension then
				local distance = getDistanceBetweenPoints3D(pPosX, pPosY, pPosZ, point.x, point.y, point.z) or 20
				if distance < minDistance then
					local interiorID = getElementData(interior, "dbid")
					canEnter, byAdmin = hasKey(source, interiorID)
					if canEnter then
						found = interior
						foundpoint = point
						itemValue = interiorID
						minDistance = distance
						interiorName = getElementData(interior, "name")
					end
				end
			end
		end
	end

	local possibleElevators = exports.drp_pool:getPoolElementsByType("elevator")
	for _, elevator in ipairs(possibleElevators) do
		local elevatorEntrance = tempFix(getElementData(elevator, "entrance"))
		local elevatorExit = tempFix(getElementData(elevator, "exit"))

		for _, point in ipairs({ elevatorEntrance, elevatorExit }) do
			if point.dim == dimension then
				local distance = getDistanceBetweenPoints3D(pPosX, pPosY, pPosZ, point.x, point.y, point.z)
				if distance < minDistance then
					if hasKey(source, elevatorEntrance.dim) and elevatorEntrance.dim ~= 0 then
						found = elevator
						foundpoint = point
						itemValue = elevatorEntrance.dim
						minDistance = distance
					elseif hasKey(source, elevatorExit.dim) and elevatorExit.dim ~= 0 then
						found = elevator
						foundpoint = point
						itemValue = elevatorExit.dim
						minDistance = distance
					end
				end
			end
		end
	end

	if checkdistance then
		return found, minDistance
	end

	if found and itemValue then
		local dbid, entrance, exit, interiorType, interiorElement = findProperty(source, itemValue)
		local playSoundAt = getElementType(found) == "elevator" and found or interiorElement

		if getElementData(interiorElement, "keypad_lock") then
			if not (exports.drp_integration:isPlayerTrialAdmin(source, true)) then
				exports.drp_infobox:addBox(
					source,
					"error",
					"Bu kapı anahtarsızdır, erişmek için Anahtarsız Dijital Kapı Kilidi'ni kullanmanız gerekir."
				)
				return false
			end
		end

		local interiorStatus = getElementData(interiorElement, "status")
		local locked = interiorStatus.locked and 1 or 0

		locked = 1 - locked

		local newRealLockedValue = false
		dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET locked=? WHERE id=? LIMIT 1", locked, itemValue)
		if locked == 0 then
			doorUnlockSound(playSoundAt, source)
			if byAdmin then
				exports.drp_global:sendMessageToAdmins(
					"[ADM] "
						.. exports.drp_global:getPlayerFullAdminTitle(source)
						.. " isimli yetkili mülk ID #"
						.. itemValue
						.. " anahtarsız açtı."
				)
				exports.drp_global:sendLocalText(source, "* Kapı artık açık olmalı.", 255, 51, 102, 30, {}, true)
				exports["drp_interior-manager"]:addInteriorLogs(itemValue, "anahtarsız açıldı", source)
			else
				exports.drp_global:sendLocalMeAction(source, "kapıyı açmak için anahtarı deliğe sokar.")
			end
		else
			doorLockSound(playSoundAt, source)
			newRealLockedValue = true
			if byAdmin then
				exports.drp_global:sendMessageToAdmins(
					"[ADM] "
						.. exports.drp_global:getPlayerFullAdminTitle(source)
						.. " isimli yetkili mülk ID #"
						.. itemValue
						.. " anahtarsız kilitledi."
				)
				exports.drp_global:sendLocalText(source, "* Kapı artık kilitli olmalı.", 255, 51, 102, 30, {}, true)
				exports["drp_interior-manager"]:addInteriorLogs(itemValue, "anahtarsız kilitlendi", source)
			else
				exports.drp_global:sendLocalMeAction(source, "kapıyı kilitlemek için anahtarı deliğe sokar.")
			end
		end

		interiorStatus.locked = newRealLockedValue
		setElementData(interiorElement, "status", interiorStatus)
	else
		cancelEvent()
	end
end
addEvent("lockUnlockHouse", false)
addEventHandler("lockUnlockHouse", root, lockUnlockHouseEvent)

addEvent("lockUnlockHouseID", true)
addEventHandler("lockUnlockHouseID", root, function(id, usingKeypad, playSoundAt)
	local hasKey1, byAdmin = hasKey(source, id)
	id = tonumber(id)
	if id and (hasKey1 or usingKeypad) then
		local query =
			dbQuery(exports.drp_mysql:getConnection(), "SELECT 1 - locked AS val FROM interiors WHERE id = ?", id)
		local result = dbPoll(query, -1)
		local locked = 0
		if result and result[1] then
			locked = tonumber(result[1].val)
		end

		dbExec(exports.drp_mysql:getConnection(), "UPDATE interiors SET locked = ? WHERE id = ? LIMIT 1", locked, id)

		if not usingKeypad then
			local dbid, entrance, exit, interiorType, interiorElement = findProperty(source, id)
			if not isElement(playSoundAt) or getElementType(playSoundAt) ~= "elevator" then
				playSoundAt = interiorElement
			end

			if getElementData(interiorElement, "keypad_lock") then
				if not exports.drp_integration:isPlayerTrialAdmin(source, true) then
					exports.drp_infobox:addBox(
						source,
						"error",
						"This door is keyless, you must use the keypad to access it."
					)
					return false
				end
			end

			if locked == 0 then
				if byAdmin then
					local adminTitle = exports.drp_global:getPlayerAdminTitle(source)
					local adminUsername = getElementData(source, "account_username")
					exports.drp_global:sendMessageToAdmins(
						"[ADM] "
							.. adminTitle
							.. " "
							.. getPlayerName(source):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has unlocked Interior ID #"
							.. id
							.. " without key."
					)
					exports.drp_global:sendLocalText(
						source,
						"* The door should now be open.",
						255,
						51,
						102,
						30,
						{},
						true
					)
					exports["drp_interior-manager"]:addInteriorLogs(id, "unlock without key", source)
				else
					exports.drp_global:sendLocalMeAction(source, "puts the key in the door to unlock it.")
				end
			else
				local newRealLockedValue = true
				if byAdmin then
					local adminTitle = exports.drp_global:getPlayerAdminTitle(source)
					local adminUsername = getElementData(source, "account_username")
					exports.drp_global:sendMessageToAdmins(
						"[ADM] "
							.. adminTitle
							.. " "
							.. getPlayerName(source):gsub("_", " ")
							.. " ("
							.. adminUsername
							.. ") has locked Interior ID #"
							.. id
							.. " without key."
					)
					exports.drp_global:sendLocalText(
						source,
						"* The door should now be locked.",
						255,
						51,
						102,
						30,
						{},
						true
					)
					exports["drp_interior-manager"]:addInteriorLogs(id, "lock without key", source)
				else
					exports.drp_global:sendLocalMeAction(source, "puts the key in the door to lock it.")
				end
			end

			if interiorElement then
				local interiorStatus = getElementData(interiorElement, "status")
				interiorStatus.locked = (locked ~= 0)
				setElementData(interiorElement, "status", interiorStatus)
				if locked ~= 0 then
					doorLockSound(playSoundAt, source)
				else
					doorUnlockSound(playSoundAt, source)
				end
			end
		else
			if locked == 0 then
				exports.drp_global:sendLocalMeAction(source, "kapıyı açar.")
			else
				local newRealLockedValue = true
				exports.drp_global:sendLocalMeAction(source, "kapıyı kilitler.")
			end

			local dbid, entrance, exit, interiorType, interiorElement = findProperty(source, id)
			if not isElement(playSoundAt) or getElementType(playSoundAt) ~= "elevator" then
				playSoundAt = interiorElement
			end

			if interiorElement then
				local interiorStatus = getElementData(interiorElement, "status")
				interiorStatus.locked = (locked ~= 0)
				setElementData(interiorElement, "status", interiorStatus)
				if locked ~= 0 then
					doorLockSound(playSoundAt, source)
				else
					doorUnlockSound(playSoundAt, source)
				end
			end
			triggerClientEvent(
				source,
				"keypadRecieveResponseFromServer",
				source,
				locked == 0 and "unlocked" or "locked",
				false
			)
		end
	else
		cancelEvent()
	end
end)

function findParent(element, dimension)
	local dbid, entrance, exit, type, interiorElement = findProperty(element, dimension)
	return interiorElement
end

function client_requestHUDinfo()
	if not isElement(source) or (getElementType(source) ~= "interior" and getElementType(source) ~= "elevator") then
		return false
	end

	local theVehicle = getPedOccupiedVehicle(client)
	if theVehicle and (getVehicleOccupant(theVehicle, 0) ~= client) then
		return false
	end

	setElementData(client, "interiormarker", true)

	local interiorID, interiorName, interiorStatus, entrance, interiorExit = nil
	if getElementType(source) == "elevator" then
		local playerDimension = getElementDimension(client)
		local elevatorEntranceDimension = getElementData(source, "entrance").dim
		local elevatorExitDimension = getElementData(source, "exit").dim

		if playerDimension ~= elevatorEntranceDimension and elevatorEntranceDimension ~= 0 then
			local dbid, entrance, exit, type, interiorElement = findProperty(client, elevatorEntranceDimension)
			if dbid and interiorElement then
				interiorID = getElementData(interiorElement, "dbid")
				interiorName = getElementData(interiorElement, "name")
				interiorStatus = getElementData(interiorElement, "status")
				entrance = getElementData(interiorElement, "entrance")
				interiorExit = getElementData(interiorElement, "exit")
			end
		elseif elevatorExitDimension ~= 0 then
			local dbid, entrance, exit, type, interiorElement = findProperty(client, elevatorExitDimension)
			if dbid and interiorElement then
				interiorID = getElementData(interiorElement, "dbid")
				interiorName = getElementData(interiorElement, "name")
				interiorStatus = getElementData(interiorElement, "status")
				entrance = getElementData(interiorElement, "entrance")
				interiorExit = getElementData(interiorElement, "exit")
			end
		end

		if not dbid then
			interiorID = -1
			interiorName = "Hiçbiri"
			interiorStatus = {}
			entrance = {}
			interiorStatus.type = 2
			interiorStatus.cost = 0
			interiorStatus.owner = -1
			entrance.fee = 0
		end
	else
		interiorName = getElementData(source, "name")
		interiorStatus = getElementData(source, "status")
		entrance = getElementData(source, "entrance")
		interiorExit = getElementData(source, "exit")
	end

	local interiorOwnerName = exports.drp_cache:getCharacterName(interiorStatus.owner) or "Hiçbiri"
	local interiorType = interiorStatus.type or 2
	local interiorCost = interiorStatus.cost or 0

	triggerClientEvent(
		client,
		"displayInteriorName",
		source,
		interiorName or "Asansör",
		interiorOwnerName,
		interiorType or 2,
		interiorCost or 0,
		interiorID or -1
	)
end
addEvent("interior.requestHUD", true)
addEventHandler("interior.requestHUD", root, client_requestHUDinfo)

local interiorPreviews = {}

function timedInteriorView(houseID)
	local dbid, entrance, exit, type, interiorElement = findProperty(client, houseID)
	if entrance then
		if interiorPreviews[client] then
			endTimedInteriorView(client)
		end

		setPlayerInsideInterior(interiorElement, client)
		outputChatBox(
			"[!]#FFFFFF Şu anda bu mülkü görüntülüyorsunuz. Hiçbir eşyayı bırakamazsınız. Mülkü terk ederek görüntülemeden çıkabilir veya 60 saniyelik zamanlayıcının dolmasını bekleyebilirsiniz.",
			client,
			0,
			255,
			0,
			true
		)

		setElementData(
			client,
			"viewingInterior",
			{ getElementDimension(client), getElementInterior(client), getElementPosition(client) },
			true
		)

		interiorPreviews[client] = {
			timer = setTimer(function(player)
				endTimedInteriorView(player)
			end, 60000, 1, client),
			houseID = houseID,
		}
	else
		outputChatBox("[!]#FFFFFF Geçersiz mülk.", client, 255, 0, 0, true)
	end
end
addEvent("viewPropertyInterior", true)
addEventHandler("viewPropertyInterior", root, timedInteriorView)

function endTimedInteriorView(thePlayer, changedCharacter)
	if client and thePlayer ~= client then
		return
	end

	local info = interiorPreviews[thePlayer]
	local pos = getElementData(thePlayer, "viewingInterior")

	if info and isTimer(info.timer) then
		killTimer(info.timer)
	end

	if info and pos then
		local houseID = info.houseID
		local dbid, entrance, exit, type, interiorElement = findProperty(thePlayer, houseID)
		if entrance then
			if not changedCharacter then
				setPlayerInsideInterior(interiorElement, thePlayer)
			end

			outputChatBox("[!]#FFFFFF Zamanlı izlemeniz sona erdi.", thePlayer, 0, 255, 0, true)
		else
			outputChatBox("[!]#FFFFFF Geçersiz mülk.", client, 255, 0, 0, true)
		end
	end

	interiorPreviews[thePlayer] = nil
	removeElementData(thePlayer, "viewingInterior")
end
addEvent("endViewPropertyInterior", true)
addEventHandler("endViewPropertyInterior", root, endTimedInteriorView)

addEventHandler("onPlayerQuit", root, function()
	if interiorPreviews[source] then
		killTimer(interiorPreviews[source].timer)
		interiorPreviews[source] = nil
	end
end)

function findInteriorGPS(thePlayer, commandName, intID)
	local playerID = getElementData(thePlayer, "dbid")

	if not intID or not tonumber(intID) then
		outputChatBox("Kullanım: /" .. commandName .. " [Kapı Numarası]", thePlayer, 255, 194, 14)
		return false
	end

	intID = tonumber(intID)

	if activeGPSs[playerID] then
		outputChatBox(
			"[!]#FFFFFF GPS zaten çalışıyor, devre dışı bırakmak için /kgps yazın.",
			thePlayer,
			255,
			0,
			0,
			true
		)
		return false
	end

	if not exports.drp_item:hasItem(thePlayer, 2) then
		outputChatBox("[!]#FFFFFF Bunu yapmak için bir telefonunuzun olması gerekir.", thePlayer, 255, 0, 0, true)
		return false
	end

	local interior = exports.drp_pool:getElementByID("interior", intID)
	if not interior then
		outputChatBox(
			"[!]#FFFFFF Belirtilen kapı numarasına sahip bir mülk bulunamadı.",
			thePlayer,
			255,
			0,
			0,
			true
		)
		return false
	end

	local intposX, intposY, intposZ = getElementPosition(interior)

	activeGPSs[playerID] = {
		blip = createBlip(intposX, intposY, intposZ, 41, 2, 255, 255, 255, 255, 0, 99999, thePlayer),
		marker = createMarker(intposX, intposY, intposZ, "checkpoint", 3, 255, 0, 0, 255, thePlayer),
	}

	if activeGPSs[playerID].blip and activeGPSs[playerID].marker then
		attachElements(activeGPSs[playerID].marker, interior)
		attachElements(activeGPSs[playerID].blip, interior)
		outputChatBox("[!]#FFFFFF Görüntülenen ev numarası GPS'e kaydedildi.", thePlayer, 0, 255, 0, true)
		outputChatBox("[!]#FFFFFF İşareti kaldırmak için /kgps yazın.", thePlayer, 0, 255, 0, true)
	else
		destroyElement(activeGPSs[playerID].blip)
		destroyElement(activeGPSs[playerID].marker)
		activeGPSs[playerID] = nil
		outputChatBox("[!]#FFFFFF GPS işaretleyicileri oluşturulurken bir sorun oluştu.", thePlayer, 255, 0, 0, true)
	end
end
addCommandHandler("intbul", findInteriorGPS, false, false)
addCommandHandler("interiorbul", findInteriorGPS, false, false)
addCommandHandler("evbul", findInteriorGPS, false, false)
addCommandHandler("mgps", findInteriorGPS, false, false)
addCommandHandler("gps", findInteriorGPS, false, false)

function clearGPS(thePlayer, commandName)
	local playerID = getElementData(thePlayer, "dbid")

	if activeGPSs[playerID] then
		if isElement(activeGPSs[playerID].marker) then
			destroyElement(activeGPSs[playerID].marker)
		end
		if isElement(activeGPSs[playerID].blip) then
			destroyElement(activeGPSs[playerID].blip)
		end
		activeGPSs[playerID] = nil
		outputChatBox("[!]#FFFFFF Kapı numarası GPS'si silindi.", thePlayer, 0, 255, 0, true)
	else
		outputChatBox("[!]#FFFFFF Şu anda aktif bir GPS'iniz yok.", thePlayer, 255, 0, 0, true)
	end
end
addCommandHandler("kgps", clearGPS, false, false)

addCommandHandler("kasacek", function(thePlayer)
	local dbid, entrance, exit, interiorType, interiorElement = exports.drp_interior:findProperty(thePlayer)

	if not interiorElement then
		outputChatBox("[!]#FFFFFF Bir mülk içerisinde değilsiniz.", thePlayer, 255, 0, 0, true)
		return
	end

	local status = getElementData(interiorElement, "status")
	if not status then
		outputChatBox("[!]#FFFFFF Bu mülk bir işletme değil.", thePlayer, 255, 0, 0, true)
		return
	end

	local type = status.type
	local owner = status.owner
	local playerDBID = getElementData(thePlayer, "dbid")

	if type ~= 1 or owner ~= playerDBID then
		outputChatBox("[!]#FFFFFF Bu işletmenin sahibi siz değilsiniz.", thePlayer, 255, 0, 0, true)
		return
	end

	local cashbox = getElementData(interiorElement, "cashbox") or 0
	if cashbox <= 0 then
		outputChatBox("[!]#FFFFFF Kasada para yok.", thePlayer, 255, 0, 0, true)
		return
	end

	exports.drp_global:giveMoney(thePlayer, cashbox)

	setElementData(interiorElement, "cashbox", 0)
	dbExec(exports.drp_mysql:getConnection(), "UPDATE interior_business SET cashbox = 0 WHERE intID = ?", dbid)

	outputChatBox(
		"[!]#FFFFFF İşletmenizin kasasındaki ₺"
			.. exports.drp_global:formatMoney(cashbox)
			.. " hesabınıza aktarıldı.",
		thePlayer,
		0,
		255,
		0,
		true
	)
end, false, false)
