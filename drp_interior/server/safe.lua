safeTable = {}

function clearSafe(dbid, removeItems)
	if safeTable[dbid] then
		if isElement(safeTable[dbid]) then
			if removeItems and exports.drp_global:isResourceRunning("drp_item") then
				exports.drp_item:clearItems(safeTable[dbid])
			end
			destroyElement(safeTable[dbid])
		end
		safeTable[dbid] = nil
		return true
	end
end

function getSafe(dbid)
	if dbid then
		if safeTable[dbid] and isElement(safeTable[dbid]) and getElementType(safeTable[dbid]) == "object" then
			return safeTable[dbid]
		end
	else
		return safeTable
	end
end

local function buidSafe(oid, int, dim, pos, rot)
	local o = createObject(oid or 2332, pos[1], pos[2], pos[3], rot[1], rot[2], rot[3])
	if o then
		setElementInterior(o, int)
		setElementDimension(o, dim)
		setElementDoubleSided(o, true)
		return o
	end
end

function addSafe(dbid, oid, pos, int, rot, clearItems, skipSql)
	clearSafe(dbid, clearItems)
	if not skipSql then
		rot = rot + 180
		pos[3] = pos[3] - 0.5
	end
	safeTable[dbid] = buidSafe(oid, int, dbid, pos, { 0, 0, rot })
	if safeTable[dbid] and not skipSql then
		dbExec(
			exports.drp_mysql:getConnection(),
			"UPDATE interiors SET safepositionX=?, safepositionY=?, safepositionZ=?, safepositionRZ=? WHERE id=? ",
			pos[1],
			pos[2],
			pos[3],
			rot,
			dbid
		)
	end
	return safeTable[dbid]
end

function updateSafe(dbid, pos, rot)
	return dbExec(
		exports.drp_mysql:getConnection(),
		"UPDATE interiors SET safepositionX=?, safepositionY=?, safepositionZ=?, safepositionRZ=? WHERE id=? ",
		pos[1],
		pos[2],
		pos[3],
		rot,
		dbid
	) and setElementPosition(safeTable[dbid], unpack(pos)) and setObjectRotation(safeTable[dbid], 0, 0, rot)
end

addEvent("interior.clearAllSafes", false)
addEventHandler("interior.clearAllSafes", resourceRoot, function()
	for dbid, obj in pairs(safeTable) do
		clearSafe(dbid)
	end
end)

addEventHandler("onResourceStop", resourceRoot, function()
	if exports.drp_global:isResourceRunning("drp_interior-load") then
		local safes = {}
		for dbid, obj in pairs(safeTable) do
			local rot = getElementRotation(obj, "ZXY")
			safes[dbid] = {
				getElementModel(obj),
				{ getElementPosition(obj) },
				getElementInterior(obj),
				rot + 180,
				false,
				true,
			}
		end
		exports.drp_data:save(safes, "interior.safeTable")
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	if exports.drp_global:isResourceRunning("drp_interior-load") then
		local safes = exports.drp_data:get("interior.safeTable")
		if safes then
			for dbid, data in pairs(safes) do
				addSafe(dbid, unpack(data))
			end
		end
	end
end)
