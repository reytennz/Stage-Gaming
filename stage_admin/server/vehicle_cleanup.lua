-- Boş araç temizliği: 30 saniyelik duyurudan sonra çalışır.

local vehicleCleanupTimer
local vehicleCleanupInProgress = false

local function vehicleHasOccupant(vehicle)
    for _, occupant in pairs(getVehicleOccupants(vehicle) or {}) do
        if isElement(occupant) then return true end
    end
    return false
end

local function deleteEmptyVehicles()
    local deleted = 0
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        if isElement(vehicle) and not vehicleHasOccupant(vehicle) and destroyElement(vehicle) then
            deleted = deleted + 1
        end
    end
    return deleted
end

function AdminStartVehicleCleanup()
    if vehicleCleanupInProgress then return false end

    vehicleCleanupInProgress = true
    local secondsLeft = 30
    AdminBroadcastAnnounce("duyuru", "Boş araç temizliği " .. secondsLeft .. " saniye içinde başlayacak.")

    vehicleCleanupTimer = setTimer(function()
        secondsLeft = secondsLeft - 1
        if secondsLeft > 0 then
            AdminBroadcastAnnounce("duyuru", "Boş araç temizliği " .. secondsLeft .. " saniye içinde başlayacak.")
            return
        end

        if isTimer(vehicleCleanupTimer) then killTimer(vehicleCleanupTimer) end
        vehicleCleanupTimer = nil
        vehicleCleanupInProgress = false

        local deleted = deleteEmptyVehicles()
        AdminBroadcastAnnounce("duyuru", deleted .. " boş araç silindi. İçinde oyuncu olan araçlar korundu.")
    end, 1000, 30)

    return true
end

setTimer(AdminStartVehicleCleanup, 30 * 60 * 1000, 0)