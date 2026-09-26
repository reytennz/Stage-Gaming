INTERIOR_X = 1
INTERIOR_Y = 2
INTERIOR_Z = 3
INTERIOR_INT = 4
INTERIOR_DIM = 5
INTERIOR_ANGLE = 6
INTERIOR_FEE = 7

INTERIOR_TYPE = 1
INTERIOR_DISABLED = 2
INTERIOR_LOCKED = 3
INTERIOR_OWNER = 4
INTERIOR_COST = 5
INTERIOR_SUPPLIES = 6
INTERIOR_FACTION = 7

InteriorStatus = {
	DISABLED = 0,
	ENABLED = 1,
	BLOCKED = 2,
	SELL = 3,
}

InteriorType = {
	HOUSE = 0,
	BUSINESS = 1,
	GOVERNMENT = 2,
	RENT = 3,
	ELEVATOR = 4,
}

InteriorLock = {
	LOCKED = true,
	UNLOCKED = false,
}

InteriorIcons = {
	[InteriorType.HOUSE] = {
		[InteriorStatus.DISABLED] = 0,
		[InteriorStatus.ENABLED] = 1318,
		[InteriorStatus.BLOCKED] = 0,
		[InteriorStatus.SELL] = 1273,

		__ui = {
			icon = "",
		},
	},
	[InteriorType.BUSINESS] = {
		[InteriorStatus.DISABLED] = 0,
		[InteriorStatus.ENABLED] = 1318,
		[InteriorStatus.BLOCKED] = 0,
		[InteriorStatus.SELL] = 1247,

		__ui = {
			icon = "",
		},
	},
	[InteriorType.GOVERNMENT] = {
		[InteriorStatus.DISABLED] = 0,
		[InteriorStatus.ENABLED] = 1318,
		[InteriorStatus.BLOCKED] = 0,
		[InteriorStatus.SELL] = 1247,

		__ui = {
			icon = "",
		},
	},
	[InteriorType.RENT] = {
		[InteriorStatus.DISABLED] = 0,
		[InteriorStatus.ENABLED] = 1273,
		[InteriorStatus.BLOCKED] = 0,
		[InteriorStatus.SELL] = 1273,

		__ui = {
			icon = "",
		},
	},
	[InteriorType.ELEVATOR] = {
		[InteriorStatus.DISABLED] = 0,
		[InteriorStatus.ENABLED] = 0,
		[InteriorStatus.BLOCKED] = 0,
		[InteriorStatus.SELL] = 0,

		__ui = {
			icon = "",
		},
	},
}

function canEnterInterior(theInterior)
	local interiorID = getElementData(theInterior, "dbid")
	if interiorID then
		local interiorStatus = getElementData(theInterior, "status")
		if interiorStatus.disabled then
			return false, 1, "Bu mülk şu anda devre dışı."
		elseif interiorStatus.locked then
			return false, 2, "Kapı kolunu oynatmaya çalışıyorsunuz, ancak kapının kilitli olduğunu fark ediyorsunuz."
		end
		return true
	end
	return false, 3, "Bir sorun oluştu."
end

function isInteriorForSale(theInterior)
	local interiorStatus = getElementData(theInterior, "status")
	if not interiorStatus then
		return false
	end

	if interiorStatus.type ~= 2 then
		if interiorStatus.owner <= 0 and interiorStatus.faction <= 0 then
			if interiorStatus.locked then
				if not interiorStatus.disabled then
					return true
				end
			end
		end
	end
	return false
end

function tempFix(tab)
	tab.x = tab.x or tab[INTERIOR_X]
	tab.y = tab.y or tab[INTERIOR_Y]
	tab.z = tab.z or tab[INTERIOR_Z]
	tab.int = tab.int or tab[INTERIOR_INT]
	tab.dim = tab.dim or tab[INTERIOR_DIM]
	tab.rot = tab.rot or tab[INTERIOR_ANGLE]
	tab.fee = tab.fee or tab[INTERIOR_FEE]
	tab.type = tab.type or tab[INTERIOR_TYPE]
	tab.disabled = tab.disabled or tab[INTERIOR_DISABLED]
	tab.locked = tab.locked or tab[INTERIOR_LOCKED]
	tab.owner = tab.owner or tab[INTERIOR_OWNER]
	tab.supplies = tab.supplies or tab[INTERIOR_SUPPLIES]
	tab.faction = tab.faction or tab[INTERIOR_FACTION]
	return tab
end
