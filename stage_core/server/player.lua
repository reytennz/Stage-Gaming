--[[
    stage_core - Oyuncu / Account / Character API
]]

function GetAccountName(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return nil
    end
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then
        return nil
    end
    return getAccountName(acc)
end

function IsLoggedIn(player)
    return isElement(player)
        and getElementType(player) == "player"
        and getElementData(player, "stage:logged") == true
end

function GetPlayerID(player)
    if not isElement(player) then return nil end
    return tonumber(getElementData(player, "playerid"))
end

function GetCharacterID(player)
    if not isElement(player) then return nil end
    return tonumber(getElementData(player, "stage:charId"))
end

function GetCharacterName(player)
    if not isElement(player) then return nil end
    local name = getElementData(player, "stage:char")
    if name and name ~= "" then return tostring(name) end
    local n = getElementData(player, "stage:charName")
    local s = getElementData(player, "stage:charSurname")
    if n and s then return tostring(n) .. " " .. tostring(s) end
    return nil
end

function IsCharacterLoaded(player)
    return GetCharacterID(player) ~= nil
end

function GetCharacterData(player)
    if not isElement(player) then return nil end
    return {
        id = GetCharacterID(player),
        slot = tonumber(getElementData(player, "stage:charSlot")),
        name = getElementData(player, "stage:charName"),
        surname = getElementData(player, "stage:charSurname"),
        fullname = GetCharacterName(player),
        age = tonumber(getElementData(player, "stage:charAge")),
        height = tonumber(getElementData(player, "stage:charHeight")),
        skin = tonumber(getElementData(player, "stage:charSkin")) or getElementModel(player),
        country = getElementData(player, "stage:charCountry"),
        tag = getElementData(player, "stage:tag")
    }
end

function GetPlayerInterior(player)
    if not isElement(player) then return 0 end
    return getElementInterior(player)
end

function SetPlayerInterior(player, interior)
    if not isElement(player) then return false end
    interior = math.max(0, math.floor(tonumber(interior) or 0))
    return setElementInterior(player, interior)
end

function GetPlayerDimension(player)
    if not isElement(player) then return 0 end
    return getElementDimension(player)
end

function SetPlayerDimension(player, dimension)
    if not isElement(player) then return false end
    dimension = math.max(0, math.floor(tonumber(dimension) or 0))
    return setElementDimension(player, dimension)
end

function SetPlayerWorld(player, interior, dimension)
    if not isElement(player) then return false end
    interior = math.max(0, math.floor(tonumber(interior) or 0))
    dimension = math.max(0, math.floor(tonumber(dimension) or 0))
    setElementInterior(player, interior)
    setElementDimension(player, dimension)
    return true
end

function GetPlayerWorld(player)
    if not isElement(player) then return nil end
    return {
        interior = getElementInterior(player),
        dimension = getElementDimension(player)
    }
end
