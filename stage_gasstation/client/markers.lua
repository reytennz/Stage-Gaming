local markers = {}
local extraByStation = {}

function destroyAllMarkers()
    for _, elems in pairs(markers) do
        if isElement(elems.marker) then destroyElement(elems.marker) end
        if isElement(elems.blip) then destroyElement(elems.blip) end
        if isElement(elems.col) then destroyElement(elems.col) end
    end
    markers = {}
end

local function makeKey(stationId, extraId)
    if extraId then return "e:" .. tostring(extraId) end
    return "s:" .. tostring(stationId)
end

function createOneMarker(stationId, data, x, y, z, extraId)
    local key = makeKey(stationId, extraId)
    if markers[key] then
        if isElement(markers[key].marker) then destroyElement(markers[key].marker) end
        if isElement(markers[key].blip) then destroyElement(markers[key].blip) end
        if isElement(markers[key].col) then destroyElement(markers[key].col) end
    end

    local color = Config.MarkerColorState
    local blipIcon = Config.BlipID
    local blipName = data.name or "Benzinlik"

    if tonumber(data.for_sale) == 1 then
        color = Config.MarkerColorSale
        blipIcon = Config.SaleBlipID
        blipName = "Satilik - " .. (data.name or "Benzinlik")
    elseif data.owner then
        color = Config.MarkerColorOwned
    end

    local size = Config.MarkerSize or 1.8
    local marker = createMarker(x, y, z - 0.95, "cylinder", size, color[1], color[2], color[3], color[4])
    setElementData(marker, "benzinlik:id", stationId, false)

    local blip = createBlip(x, y, z, blipIcon, 2, color[1], color[2], color[3], 255, 0, 300)
    setElementData(blip, "blipName", blipName, false)

    local col = createColSphere(x, y, z, size + 1.2)
    setElementData(col, "benzinlik:id", stationId, false)

    markers[key] = {
        marker = marker, blip = blip, col = col,
        stationId = stationId, pos = { x = x, y = y, z = z },
        data = data, extraId = extraId
    }
end

function createStationMarker(data)
    if not data or not data.id then return end
    createOneMarker(data.id, data, data.posX, data.posY, data.posZ, nil)
    for _, em in ipairs(extraByStation[data.id] or {}) do
        createOneMarker(data.id, data, em.posX, em.posY, em.posZ, em.id)
    end
end

addEvent("benzinlik:rebuildMarkers", true)
addEventHandler("benzinlik:rebuildMarkers", localPlayer, function()
    destroyAllMarkers()
    for id, data in pairs(getLocalStations()) do
        createStationMarker(data)
    end
end)

addEvent("benzinlik:syncExtraMarkers", true)
addEventHandler("benzinlik:syncExtraMarkers", resourceRoot, function(map)
    extraByStation = map or {}
    triggerEvent("benzinlik:rebuildMarkers", localPlayer)
end)

addEvent("benzinlik:addExtraMarker", true)
addEventHandler("benzinlik:addExtraMarker", resourceRoot, function(stationId, row)
    if not extraByStation[stationId] then extraByStation[stationId] = {} end
    table.insert(extraByStation[stationId], row)
    local data = getStationById(stationId)
    if data and row then
        createOneMarker(stationId, data, row.posX, row.posY, row.posZ, row.id)
    end
end)

addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    for _, elems in pairs(markers) do
        local data = elems.data or getStationById(elems.stationId)
        if data and elems.pos then
            local x, y, z = elems.pos.x, elems.pos.y, elems.pos.z
            local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
            if dist < 28 then
                local sx2, sy2 = getScreenFromWorldPosition(x, y, z + 1.1)
                if sx2 and sy2 then
                    local alpha = math.floor(255 * math.max(0, 1 - (dist / 28)))
                    local name = data.name or "Benzinlik"
                    local sub
                    if tonumber(data.for_sale) == 1 then
                        sub = "SATILIK  " .. formatMoney(data.sale_price or Config.DefaultBuyPrice)
                    else
                        sub = "Kod: " .. tostring(data.code or "----")
                    end
                    local tw = math.max(dxGetTextWidth(name, 1.05, "default-bold"), dxGetTextWidth(sub, 0.9, "default")) + 20
                    dxDrawRectangle(sx2 - tw/2, sy2 - 24, tw, 46, tocolor(12, 14, 20, math.floor(alpha * 0.88)))
                    dxDrawText(name, sx2 - tw/2, sy2 - 22, sx2 + tw/2, sy2 - 2, tocolor(255, 255, 255, alpha), 1.05, "default-bold", "center", "center")
                    dxDrawText(sub, sx2 - tw/2, sy2 - 2, sx2 + tw/2, sy2 + 18, tocolor(180, 185, 195, alpha), 0.9, "default", "center", "center")
                end
            end
        end
    end
end)

addEventHandler("onClientColShapeHit", root, function(hitElement, matchingDimension)
    if hitElement ~= localPlayer or not matchingDimension then return end
    local id = getElementData(source, "benzinlik:id")
    if not id then return end
    local data = getStationById(id)
    if not data then return end
    if tonumber(data.for_sale) == 1 then
        triggerServerEvent("benzinlik:requestBuyQuote", localPlayer, data.id)
        return
    end
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getPedOccupiedVehicleSeat(localPlayer) == 0 then
        triggerEvent("benzinlik:showFuelUI", localPlayer, data)
    else
        triggerEvent("benzinlik:showCodeUI", localPlayer, data)
    end
end)

addEventHandler("onClientColShapeLeave", root, function(leaveElement)
    if leaveElement ~= localPlayer then return end
    if getElementData(source, "benzinlik:id") then
        triggerEvent("benzinlik:hideFuelUI", localPlayer)
        triggerEvent("benzinlik:hideBuyUI", localPlayer)
        triggerEvent("benzinlik:hideCodeUI", localPlayer)
    end
end)

addEventHandler("onClientPlayerVehicleExit", localPlayer, function()
    triggerEvent("benzinlik:hideFuelUI", localPlayer)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    destroyAllMarkers()
end)
