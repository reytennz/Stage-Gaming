outToInRadius = 25
inToOutRadius = 15

function interiorShout(thePlayer, commandName, ...)
	local playerName = getPlayerName(thePlayer)

	local r, g, b = 255, 255, 255
	local focus = getElementData(thePlayer, "focus")
	local message = table.concat({ ... }, " ")

	if type(focus) == "table" then
		for player, color in pairs(focus) do
			if player == thePlayer then
				r, g, b = unpack(color)
			end
		end
	end

	local x, y, z = getElementPosition(thePlayer)
	local dimension = getElementDimension(thePlayer)
	local possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")

	for _, interior in ipairs(possibleInteriors) do
		local interiorEntrance = getElementData(interior, "entrance")
		local interiorExit = getElementData(interior, "exit")

		for _, point in ipairs({ interiorEntrance, interiorExit }) do
			if point.dim == dimension then
				local distance = getDistanceBetweenPoints3D(x, y, z, point.x, point.y, point.z)
				if distance <= outToInRadius then
					local dbid = getElementData(interior, "dbid")
					local interiorName = getElementData(interior, "name")
					local players = getElementsByType("player")

					for _, value in ipairs(players) do
						if getElementData(value, "logged") then
							local playerDim = getElementDimension(value)
							local playerDim2 = getElementDimension(thePlayer)
							if (playerDim == dbid) and (playerDim2 ~= playerDim) then
								outputChatBox(
									playerName:gsub("_", " ") .. " (Bağırma): " .. message .. "!",
									value,
									200,
									200,
									200
								)
							end
						end
					end
				end
			end
		end
	end

	x, y, z = getElementPosition(thePlayer)
	dimension = getElementDimension(thePlayer)
	possibleInteriors = exports.drp_pool:getPoolElementsByType("interior")

	for _, interior in ipairs(possibleInteriors) do
		local interiorEntrance = getElementData(interior, "entrance")
		local interiorExit = getElementData(interior, "exit")

		for _, point in ipairs({ interiorEntrance, interiorExit }) do
			if point.dim == dimension then
				local distance = getDistanceBetweenPoints3D(x, y, z, point.x, point.y, point.z)
				if (distance <= 60) and (dimension > 0) then
					local dbid = getElementData(interior, "dbid")

					local query = dbQuery(
						exports.drp_mysql:getConnection(),
						"SELECT x, y, z, dimensionwithin, interiorwithin FROM interiors WHERE id = ?",
						dbid
					)
					local result = dbPoll(query, -1)
					if not result or #result == 0 then return end

					local row = result[1]
					local cx = tonumber(row.x)
					local cy = tonumber(row.y)
					local cz = tonumber(row.z)
					local dimensionwithin = tonumber(row.dimensionwithin)
					local interiorwithin = tonumber(row.interiorwithin)
					local interiorName = getElementData(interior, "name")

					local shoutCol = createColSphere(cx, cy, cz, inToOutRadius)
					setElementDimension(shoutCol, dimensionwithin)
					setElementInterior(shoutCol, interiorwithin)

					local players = getElementsByType("player")
					for _, value in ipairs(players) do
						if getElementData(value, "logged") then
							local isPlayerInTheCol = isElementWithinColShape(value, shoutCol)
							local playerDim = getElementDimension(value)
							local playerDim2 = getElementDimension(thePlayer)

							if isPlayerInTheCol and (value ~= thePlayer) and (playerDim2 ~= playerDim) then
								outputChatBox(
									playerName:gsub("_", " ") .. " (Bağırma): " .. message .. "!",
									value,
									200,
									200,
									200
								)
							end
						end
					end

					destroyElement(shoutCol)
					shoutCol = nil
				end
			end
		end
	end
end
addCommandHandler("s", interiorShout, false, false)
