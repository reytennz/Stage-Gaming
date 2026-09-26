-- goat_scope yerine: id'sine göre native MTA "team" elementi arıyoruz.
function getTeamFromfactionID(factionID)
	factionID = tonumber(factionID)
	if not factionID then return false end
	for _, theTeam in ipairs(getElementsByType("team")) do
		if tonumber(getElementData(theTeam, "id")) == factionID then
			return theTeam
		end
	end
	return false
end

function getfactionName(factionID)
	local theTeam = getTeamFromfactionID(factionID)
	if theTeam then
		local name = getTeamName(theTeam)
		if name then
			return tostring(name)
		end
	end
	return false
end

function getfactionType(factionID)
	local theTeam = getTeamFromfactionID(factionID)
	if theTeam then
		local ftype = tonumber(getElementData(theTeam, "type"))
		if ftype then
			return ftype
		end
	end
	return false
end

function getfactionFromName(factionName)
	for _, theTeam in ipairs(getElementsByType("team")) do
		if string.lower(getTeamName(theTeam)) == string.lower(factionName) then
			return theTeam
		end
	end
	return false
end

function getfactionIDFromName(factionName)
	local theTeam = getfactionFromName(factionName)
	if theTeam then
		local id = tonumber(getElementData(theTeam, "id"))
		if id then
			return id
		end
	end
	return false
end
