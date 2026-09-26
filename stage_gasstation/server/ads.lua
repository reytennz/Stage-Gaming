local activeAds = {} -- stationId -> list of active ads

function getActiveAds(stationId)
    local qh = dbQ("SELECT * FROM gas_station_ads WHERE station_id=? AND active=1 AND expires_at > NOW()", stationId)
    return dbP(qh) or {}
end

function loadAllActiveAds()
    activeAds = {}
    local qh = dbQ("SELECT * FROM gas_station_ads WHERE active=1 AND expires_at > NOW()")
    local result = dbP(qh) or {}
    for _, ad in ipairs(result) do
        if not activeAds[ad.station_id] then activeAds[ad.station_id] = {} end
        table.insert(activeAds[ad.station_id], ad)
    end
end

function expireAds()
    dbE("UPDATE gas_station_ads SET active=0 WHERE active=1 AND expires_at <= NOW()")
    loadAllActiveAds()
end

addEvent("benzinlik:createAd", true)
addEventHandler("benzinlik:createAd", root, function(stationId, title, message, duration, budget)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end
    if not checkRateLimit(player, "createAd", 5000) then return end

    title = tostring(title or ""):sub(1, 64)
    message = tostring(message or ""):sub(1, 255)
    duration = math.floor(tonumber(duration) or 0)
    budget = math.floor(tonumber(budget) or 0)

    if title == "" or message == "" then
        return outputChatBox("» Başlık ve mesaj zorunlu.", player, 255, 50, 50)
    end
    if duration < Config.AdMinDuration or duration > Config.AdMaxDuration then
        return outputChatBox("» Süre " .. Config.AdMinDuration .. "-" .. Config.AdMaxDuration .. " saniye arasında olmalı.", player, 255, 50, 50)
    end
    if budget < Config.AdMinBudget then
        return outputChatBox("» Minimum bütçe: " .. formatMoney(Config.AdMinBudget), player, 255, 50, 50)
    end
    if stations[stationId].balance < budget then
        return outputChatBox("» Kasada yeterli para yok.", player, 255, 50, 50)
    end

    -- Kasa düş
    addTransaction(stationId, "expense", "ad", budget, "Reklam: " .. title, getAccountNameSafe(player))

    local expires = os.date("%Y-%m-%d %H:%M:%S", os.time() + duration)
    dbE("INSERT INTO gas_station_ads (station_id, title, message, budget, duration, expires_at, active) VALUES (?,?,?,?,?,?,1)",
        stationId, title, message, budget, duration, expires)

    loadAllActiveAds()
    outputChatBox("» Reklam yayınlandı! Süre: " .. duration .. " saniye.", player, 0, 255, 100)
end)

-- Periyodik reklam yayını
local adTimer = nil
function startAdBroadcast()
    if isTimer(adTimer) then killTimer(adTimer) end
    adTimer = setTimer(function()
        expireAds()
        for stationId, ads in pairs(activeAds) do
            if stations[stationId] then
                for _, ad in ipairs(ads) do
                    local data = stations[stationId]
                    local msg = string.format("[REKLAM] %s — %s | Benzin: $%d/L | Dizel: $%d/L",
                        ad.title, ad.message, data.petrol_price, data.diesel_price)
                    outputChatBox(msg, root, 255, 200, 50)
                end
            end
        end
    end, Config.AdInterval, 0)
end

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        loadAllActiveAds()
        startAdBroadcast()
    end, 3000, 1)
end)
