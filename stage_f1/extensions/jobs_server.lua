--[[
    Meslek isinlama
]]

addEvent("f1jobs:teleport", true)
addEventHandler("f1jobs:teleport", root, function(jobId)
    local player = client
    if not isElement(player) then return end
    local job = getJobById(jobId)
    if not job then
        outputChatBox("[Meslek] Meslek bulunamadi.", player, 255, 50, 50)
        return
    end
    if isPedInVehicle(player) then
        removePedFromVehicle(player)
    end
    triggerEvent("stageAC:serverTeleport", resourceRoot, player)
    local ac = getResourceFromName("stage_anticheat")
    if ac and getResourceState(ac) == "running" then
        pcall(function() exports.stage_anticheat:grantMovementExemption(player, 6000, "stage_f1_job") end)
    end
    setElementPosition(player, job.x, job.y, job.z)
    setElementInterior(player, 0)
    setElementDimension(player, 0)
    outputChatBox("[Meslek] "..job.name.." konumuna isinlandiniz.", player, 0, 255, 100)
end)
