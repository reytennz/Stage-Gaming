local localStations = {}

addEvent("benzinlik:syncAllStations", true)
addEventHandler("benzinlik:syncAllStations", resourceRoot, function(data)
    localStations = data or {}
    triggerEvent("benzinlik:rebuildMarkers", localPlayer)
end)

addEvent("benzinlik:createStation", true)
addEventHandler("benzinlik:createStation", resourceRoot, function(data)
    if data and data.id then
        localStations[data.id] = data
        triggerEvent("benzinlik:rebuildMarkers", localPlayer)
    end
end)

addEvent("benzinlik:updateStation", true)
addEventHandler("benzinlik:updateStation", resourceRoot, function(data)
    if data and data.id then
        localStations[data.id] = data
        triggerEvent("benzinlik:rebuildMarkers", localPlayer)
        -- Eğer panel açıksa güncelle
        triggerEvent("benzinlik:onStationUpdated", localPlayer, data)
    end
end)

addEvent("benzinlik:removeStation", true)
addEventHandler("benzinlik:removeStation", resourceRoot, function(id)
    localStations[id] = nil
    triggerEvent("benzinlik:rebuildMarkers", localPlayer)
end)

function getLocalStations()
    return localStations
end

function getStationById(id)
    return localStations[id]
end

-- Yakın benzinlik bul
function getNearestStation(maxDist)
    maxDist = maxDist or 15
    local px, py, pz = getElementPosition(localPlayer)
    local nearest, nearestDist = nil, maxDist
    for id, data in pairs(localStations) do
        local dist = getDistanceBetweenPoints3D(px, py, pz, data.posX, data.posY, data.posZ)
        if dist < nearestDist then
            nearest = data
            nearestDist = dist
        end
    end
    return nearest, nearestDist
end
