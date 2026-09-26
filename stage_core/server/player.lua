--[[
    stage_core - Oyuncu / Account yardımcıları
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
    return GetAccountName(player) ~= nil
end
