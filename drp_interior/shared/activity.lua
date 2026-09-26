function isActive(interiorElement)
	local warningLastLogin, warningLastUsed = nil
	local interiorStatus = getElementData(interiorElement, "status")
	local interiorType = interiorStatus.type or 2
	local interiorOwner = interiorStatus.owner or 0
	local interiorFaction = interiorStatus.faction or 0
	local interiorDisabled = interiorStatus.disabled or false

	if interiorDisabled or interiorType == 2 or interiorFaction ~= 0 or interiorOwner < 1 then
		return true
	else
		local oneDay = 60 * 60 * 24
		local ownerLastLogin = getElementData(interiorElement, "owner_last_login")

		if ownerLastLogin and tonumber(ownerLastLogin) then
			local ownerLastLoginText, ownerLastLoginTextSeconds =
				exports.drp_datetime:formatTimeInterval(ownerLastLogin)
			if ownerLastLoginTextSeconds > oneDay * 30 then
				return false, "Pasif mülk | Sahibi pasif (" .. ownerLastLoginText .. ")", ownerLastLoginTextSeconds
			elseif ownerLastLoginTextSeconds > (oneDay * 30 - oneDay / 2) then
				warningLastLogin = (oneDay * 30) - ownerLastLoginTextSeconds
			end
		end

		local lastUsed = getElementData(interiorElement, "last_used")
		if lastUsed and tonumber(lastUsed) then
			local lastUsedText, lastUsedSeconds = exports.drp_datetime:formatTimeInterval(lastUsed)
			if lastUsedSeconds > oneDay * 14 then
				return false, "Pasif mülk | Son kullanım " .. lastUsedText, lastUsedSeconds
			elseif lastUsedSeconds > (oneDay * 14 - oneDay / 2) then
				warningLastUsed = (oneDay * 14) - lastUsedSeconds
			end
		end
	end

	return true, getMoreCriticalWarning(warningLastUsed, warningLastLogin)
end

function getMoreCriticalWarning(a, b)
	if not a then
		return b
	end
	if not b then
		return a
	end
	if a and b then
		return (a < b) and a or b
	end
	return nil
end
