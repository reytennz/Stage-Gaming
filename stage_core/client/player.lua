-- stage_core - client taraf temel player API
function GetPlayerID() return tonumber(getElementData(localPlayer, "playerid")) end
function GetCharacterID() return tonumber(getElementData(localPlayer, "stage:charId")) end
function GetCharacterName()
    local name = getElementData(localPlayer, "stage:char")
    if name and name ~= "" then return tostring(name) end
    local n, s = getElementData(localPlayer, "stage:charName"), getElementData(localPlayer, "stage:charSurname")
    if n and s then return tostring(n) .. " " .. tostring(s) end
end
function GetCharacterData()
    return {
        id=GetCharacterID(), slot=tonumber(getElementData(localPlayer,"stage:charSlot")),
        name=getElementData(localPlayer,"stage:charName"), surname=getElementData(localPlayer,"stage:charSurname"),
        fullname=GetCharacterName(), age=tonumber(getElementData(localPlayer,"stage:charAge")),
        height=tonumber(getElementData(localPlayer,"stage:charHeight")),
        skin=tonumber(getElementData(localPlayer,"stage:charSkin")) or getElementModel(localPlayer),
        country=getElementData(localPlayer,"stage:charCountry"), tag=getElementData(localPlayer,"stage:tag")
    }
end
function IsCharacterLoaded() return GetCharacterID() ~= nil end
function GetPlayerTag() return getElementData(localPlayer,"stage:tag") end
function GetPlayerInterior() return getElementInterior(localPlayer) end
function SetPlayerInterior(interior) return setElementInterior(localPlayer,math.max(0,math.floor(tonumber(interior) or 0))) end
function GetPlayerDimension() return getElementDimension(localPlayer) end
function SetPlayerDimension(dimension) return setElementDimension(localPlayer,math.max(0,math.floor(tonumber(dimension) or 0))) end
function GetPlayerWorld() return {interior=getElementInterior(localPlayer),dimension=getElementDimension(localPlayer)} end
