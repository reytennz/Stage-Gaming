-- SERVER.LUA - Sinema Modu v2.4 Optimize (Zaman Kontrolü + TR)

local currentURL      = ""
local cinemaActive    = false
local cinemaStartedBy = nil
local playbackStart   = 0     -- Videonun play'e basıldığı anı saklar

local function hasPermission(player)
    return true
end

local function isValidURL(url)
    if not url or type(url) ~= "string" then return false end
    if string.len(url) < 10 or string.len(url) > 512 then return false end
    if not string.find(url, "^https?://") then return false end
    if string.find(url, "^https?://localhost") then return false end
    if string.find(url, "^https?://127%.") then return false end
    if string.find(url, "^https?://192%.168%.") then return false end
    if string.find(url, "^https?://10%.") then return false end
    return true
end

local function triggerAllClients(eventName, ...)
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, eventName, player, ...)
    end
end

-- Play'in başlamasından bu yana geçen saniyeyi döndürür
local function getElapsedTime()
    if not cinemaActive then return 0 end
    return math.floor((getTickCount() - playbackStart) / 1000)
end

addEvent("onCinemaPlay", true)
addEventHandler("onCinemaPlay", root, function(url)
    local player = client

    if not hasPermission(player) then
        outputChatBox("[SİNEMA] Yetkiniz yok.", player, 255, 50, 50)
        return
    end

    if not isValidURL(url) then
        outputChatBox("[SİNEMA] Geçersiz veya izin verilmeyen URL.", player, 255, 100, 0)
        return
    end

    currentURL      = url
    cinemaActive    = true
    cinemaStartedBy = getPlayerName(player)
    playbackStart   = getTickCount() -- Sunucunun o anki zamanını kaydeder

    -- URL'yi başlangıç zamanı 0 olarak herkese gönderir
    triggerAllClients("onCinemaReceiveURL", url, 0)

    local displayURL = string.len(url) > 60 and string.sub(url, 1, 57) .. "..." or url
    outputChatBox("[SİNEMA] " .. cinemaStartedBy .. " başlattı: " .. displayURL, root, 3, 252, 255)
    outputServerLog("[SİNEMA] Play - " .. cinemaStartedBy .. " | URL: " .. url)
end)

addEvent("onCinemaStop", true)
addEventHandler("onCinemaStop", root, function()
    local player = client

    if not hasPermission(player) then
        outputChatBox("[SİNEMA] Yetkiniz yok.", player, 255, 50, 50)
        return
    end

    cinemaActive    = false
    currentURL      = ""
    cinemaStartedBy = nil

    triggerAllClients("onCinemaStopAll")

    outputChatBox("[SİNEMA] " .. getPlayerName(player) .. " sinemayı sonlandırdı.", root, 255, 80, 80)
    outputServerLog("[SİNEMA] Stop - " .. getPlayerName(player))
end)

-- Yeni katılan veya yeniden bağlanan oyuncu, doğru saniyeden senkronize olur
addEventHandler("onPlayerJoin", root, function()
    local newPlayer = source
    if cinemaActive and isValidURL(currentURL) then
        local savedURL = currentURL
        setTimer(function()
            if isElement(newPlayer) and cinemaActive then
                local elapsed = getElapsedTime()
                triggerClientEvent(newPlayer, "onCinemaReceiveURL", newPlayer, savedURL, elapsed)
                outputChatBox("[SİNEMA] Devam eden video senkronize ediliyor...", newPlayer, 3, 252, 255)
            end
        end, 3000, 1)
    end
end)

addCommandHandler("stopcinema", function(player)
    if not hasPermission(player) then
        outputChatBox("[SİNEMA] Yetkiniz yok.", player, 255, 50, 50)
        return
    end
    if not cinemaActive then
        outputChatBox("[SİNEMA] Gösterimde video yok.", player, 200, 200, 200)
        return
    end
    cinemaActive    = false
    currentURL      = ""
    cinemaStartedBy = nil
    triggerAllClients("onCinemaStopAll")
    outputChatBox("[SİNEMA] Sinema komutla sonlandırıldı.", root, 255, 80, 80)
end)

addCommandHandler("cinemainfo", function(player)
    if not hasPermission(player) then return end
    if cinemaActive then
        outputChatBox("[SİNEMA] Durum: AKTİF", player, 3, 252, 255)
        outputChatBox("[SİNEMA] Başlatan: " .. tostring(cinemaStartedBy), player, 3, 252, 255)
        local d = string.len(currentURL) > 60 and string.sub(currentURL, 1, 57) .. "..." or currentURL
        outputChatBox("[SİNEMA] URL: " .. d, player, 3, 252, 255)
    else
        outputChatBox("[SİNEMA] Durum: PASİF", player, 200, 200, 200)
    end
end)


-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy