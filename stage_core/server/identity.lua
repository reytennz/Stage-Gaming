--[[
    stage_core - Character Tag / Icon
    Tag karaktere bağlıdır. Yeni karakter varsayılan olarak "Yeni Oyuncu" alır.
]]

local DEFAULT_TAG = "Yeni Oyuncu"
local MAX_TAG_LENGTH = 32

local function cleanTag(tag)
    tag = tostring(tag or ""):gsub("[%c\r\n]", " ")
    tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
    if tag == "" then return nil end
    if tag:lower() == "sil" or tag:lower() == "kaldir" or tag:lower() == "kaldır" then
        return nil
    end
    return tag:sub(1, MAX_TAG_LENGTH)
end

function GetPlayerTag(player)
    if not isElement(player) then return nil end
    return getElementData(player, "stage:tag")
end

function SetPlayerTag(player, tag)
    if not isElement(player) or getElementType(player) ~= "player" then return false end
    tag = cleanTag(tag)
    if not tag then return ClearPlayerTag(player) end

    setElementData(player, "stage:tag", tag, true)

    local charId = getElementData(player, "stage:charId")
    if charId then
        local ok = pcall(function()
            return exports.stage_loading:stageSetCharacterTag(player, tag)
        end)
        if not ok then
            -- stage_loading henüz hazır değilse elementData yine aktif kalır.
        end
    end
    return true
end

function ClearPlayerTag(player)
    if not isElement(player) then return false end
    setElementData(player, "stage:tag", nil, true)

    local charId = getElementData(player, "stage:charId")
    if charId then
        pcall(function()
            exports.stage_loading:stageSetCharacterTag(player, nil)
        end)
    end
    return true
end

local function applyDefaultTag(player)
    if not isElement(player) then return end
    if not getElementData(player, "stage:tag") then
        setElementData(player, "stage:tag", DEFAULT_TAG, true)
    end
end

addEventHandler("onPlayerJoin", root, function()
    applyDefaultTag(source)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        if not getElementData(player, "stage:tag") then
            applyDefaultTag(player)
        end
    end
end)

addCommandHandler("icon", function(player, _, targetId, ...)
    if not isElement(player) or not IsAdmin(player) then
        if isElement(player) then outputChatBox("#FF5555[Stage] Bu komutu kullanamazsın.", player, 255,255,255,true) end
        return
    end

    local id = tonumber(targetId)
    if not id then
        outputChatBox("#FFCC00Kullanım: /icon [ID] [Etiket]", player, 255,255,255,true)
        return
    end

    local target
    for _, p in ipairs(getElementsByType("player")) do
        if tonumber(getElementData(p, "playerid")) == id then
            target = p
            break
        end
    end

    if not target then
        outputChatBox("#FF5555[Stage] Oyuncu bulunamadı.", player, 255,255,255,true)
        return
    end

    local tag = table.concat({...}, " ")
    if tag == "" then
        outputChatBox("#FFCC00Kullanım: /icon [ID] [Etiket]  |  sil", player, 255,255,255,true)
        return
    end

    if SetPlayerTag(target, tag) then
        local shown = GetPlayerTag(target) or "Yok"
        outputChatBox("#55FF99[Stage] #FFFFFF" .. tostring(GetCharacterName(target) or getPlayerName(target)) .. " etiketi: #55CCFF" .. shown, player,255,255,255,true)
        if target ~= player then
            outputChatBox("#55CCFF[Stage] #FFFFFFEtiketin: #55CCFF" .. shown, target,255,255,255,true)
        end
    end
end)
