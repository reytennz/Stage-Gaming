--[[
    Sahibinden - oyuncudan oyuncuya arac satisi
]]

local listings = {}
local nextId = 1
local vehToListing = {}

local function isAdmin(player)
    if StageIsAdmin then
        return StageIsAdmin(player)
    end
    local acc = getPlayerAccount(player)
    if acc and not isGuestAccount(acc) then
        local name = getAccountName(acc)
        if isObjectInACLGroup("user."..name, aclGetGroup("Admin")) then return true end
        if isObjectInACLGroup("user."..name, aclGetGroup("Console")) then return true end
    end
    if getElementData(player, "adminlevel") and tonumber(getElementData(player, "adminlevel")) >= 1 then return true end
    return false
end

addEvent("sahibinden:requestList", true)
addEventHandler("sahibinden:requestList", root, function()
    local player = client
    if not isElement(player) then return end
    local out = {}
    for id, L in pairs(listings) do
        if L.status == "active" and isElement(L.vehicle) then
            table.insert(out, {
                id = L.id,
                model = L.model,
                name = L.name,
                seller = L.sellerName,
                title = L.title,
                description = L.description,
                price = L.price,
                created = L.created,
            })
        end
    end
    table.sort(out, function(a,b) return (a.created or 0) > (b.created or 0) end)
    triggerClientEvent(player, "sahibinden:receiveList", player, out)
end)

addEvent("sahibinden:create", true)
addEventHandler("sahibinden:create", root, function(veh, title, description, price)
    local player = client
    if not isElement(player) then return end
    if not isElement(veh) or getElementType(veh) ~= "vehicle" then
        outputChatBox("[Sahibinden] Gecersiz arac.", player, 255, 50, 50)
        return
    end
    price = math.floor(tonumber(price) or 0)
    if price <= 0 then
        outputChatBox("[Sahibinden] Gecerli bir fiyat girin.", player, 255, 50, 50)
        return
    end
    -- Surucu olmali
    if getPedOccupiedVehicle(player) ~= veh or getPedOccupiedVehicleSeat(player) ~= 0 then
        outputChatBox("[Sahibinden] Ilan vermek icin aracın sofor koltugunda olun.", player, 255, 50, 50)
        return
    end
    if vehToListing[veh] then
        outputChatBox("[Sahibinden] Bu arac zaten ilanda.", player, 255, 50, 50)
        return
    end

    title = type(title) == "string" and title:sub(1, 64) or ""
    description = type(description) == "string" and description:sub(1, 200) or ""

    local model = getElementModel(veh)
    local id = nextId
    nextId = nextId + 1

    listings[id] = {
        id = id,
        vehicle = veh,
        model = model,
        name = getVehicleNameFromModel(model) or ("ID "..model),
        seller = player,
        sellerName = getPlayerName(player),
        title = title,
        description = description,
        price = price,
        created = getRealTime().timestamp,
        status = "active",
        processing = false,
    }
    vehToListing[veh] = id
    setElementData(veh, "sahibinden", true)
    setElementData(veh, "sahibinden_price", price)
    setElementFrozen(veh, true)
    setVehicleEngineState(veh, false)
    removePedFromVehicle(player)

    outputChatBox("[Sahibinden] Ilan olusturuldu: "..listings[id].name.." - $"..tostring(price), player, 0, 255, 100)
    triggerClientEvent(root, "sahibinden:listUpdated", resourceRoot)
end)

addEvent("sahibinden:buy", true)
addEventHandler("sahibinden:buy", root, function(listingId)
    local player = client
    if not isElement(player) then return end
    listingId = tonumber(listingId)
    local L = listings[listingId]
    if not L or L.status ~= "active" then
        outputChatBox("[Sahibinden] Ilan bulunamadi.", player, 255, 50, 50)
        return
    end
    if L.processing then
        outputChatBox("[Sahibinden] Islem devam ediyor.", player, 255, 50, 50)
        return
    end
    if not isElement(L.vehicle) then
        L.status = "removed"
        outputChatBox("[Sahibinden] Arac artik mevcut degil.", player, 255, 50, 50)
        triggerClientEvent(root, "sahibinden:listUpdated", resourceRoot)
        return
    end
    if L.seller == player then
        outputChatBox("[Sahibinden] Kendi ilaninizi alamazsiniz.", player, 255, 50, 50)
        return
    end

    L.processing = true
    local price = L.price
    if not StageHasMoney(player, price) then
        L.processing = false
        outputChatBox("[Sahibinden] Yeterli paraniz yok.", player, 255, 50, 50)
        return
    end

    StageRemoveMoney(player, price)
    if isElement(L.seller) then
        StageAddMoney(L.seller, price)
        outputChatBox("[Sahibinden] Araciniz satildi! +"..price.."$  Alici: "..getPlayerName(player), L.seller, 0, 255, 100)
    end

    setElementData(L.vehicle, "sahibinden", false)
    removeElementData(L.vehicle, "sahibinden_price")
    setElementFrozen(L.vehicle, false)
    setElementData(L.vehicle, "owner", getPlayerName(player))

    vehToListing[L.vehicle] = nil
    L.status = "sold"
    L.processing = false

    warpPedIntoVehicle(player, L.vehicle)
    outputChatBox("[Sahibinden] "..L.name.." satin alindi!", player, 0, 255, 100)
    triggerClientEvent(root, "sahibinden:listUpdated", resourceRoot)
end)

addEvent("sahibinden:cancel", true)
addEventHandler("sahibinden:cancel", root, function(listingId)
    local player = client
    listingId = tonumber(listingId)
    local L = listings[listingId]
    if not L or L.status ~= "active" then return end
    if L.seller ~= player and not isAdmin(player) then return end
    if isElement(L.vehicle) then
        setElementData(L.vehicle, "sahibinden", false)
        removeElementData(L.vehicle, "sahibinden_price")
        setElementFrozen(L.vehicle, false)
        vehToListing[L.vehicle] = nil
    end
    L.status = "cancelled"
    outputChatBox("[Sahibinden] Ilan iptal edildi.", player, 255, 200, 0)
    triggerClientEvent(root, "sahibinden:listUpdated", resourceRoot)
end)

addEventHandler("onElementDestroy", root, function()
    if getElementType(source) == "vehicle" and vehToListing[source] then
        local id = vehToListing[source]
        if listings[id] then listings[id].status = "removed" end
        vehToListing[source] = nil
        triggerClientEvent(root, "sahibinden:listUpdated", resourceRoot)
    end
end)
