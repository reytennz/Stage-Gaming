addEvent("benzinlik:upgradeLevel", true)
addEventHandler("benzinlik:upgradeLevel", root, function(stationId)
    local player = client
    if not validateClient(player) or not isValidStationOwner(player, stationId) then return end
    if not checkRateLimit(player, "upgrade", 3000) then return end

    local data = stations[stationId]
    local current = data.level or 1
    local nextLevel = current + 1
    local nextData = Config.Levels[nextLevel]

    if not nextData then
        return outputChatBox("» Maksimum seviyeye ulaştın.", player, 255, 50, 50)
    end

    local cost = nextData.upgradeCost
    if data.balance < cost then
        return outputChatBox("» Kasa yetersiz. Gerekli: " .. formatMoney(cost), player, 255, 50, 50)
    end

    addTransaction(stationId, "expense", "upgrade", cost, "Seviye yükseltme → " .. nextData.name, getAccountNameSafe(player))
    updateStationData(stationId, { level = nextLevel })

    outputChatBox("» İşletme seviyesi yükseltildi: " .. nextData.name, player, 0, 255, 100)
    outputChatBox("» Yeni kapasite → Benzin: " .. nextData.capacityPetrol .. "L | Dizel: " .. nextData.capacityDiesel .. "L", player, 200, 200, 200)
end)
