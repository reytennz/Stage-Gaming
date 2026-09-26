local function isAdmin(p)
    if type(IsAdmin) == "function" then return IsAdmin(p) end
    return hasObjectPermissionTo(p, "function.kickPlayer", false)
end
addCommandHandler("stageadmin", function(p)
    if not isAdmin(p) then return end
    triggerClientEvent(p, "stage_admin:open", resourceRoot)
end)
addEvent("stage_admin:request", true)
addEventHandler("stage_admin:request", root, function()
    if not isAdmin(client) then return end
    local list = {}
    for _, p in ipairs(getElementsByType("player")) do
        list[#list+1] = { name=getPlayerName(p), id=getElementData(p,"playerid") or "-" }
    end
    triggerClientEvent(client, "stage_admin:data", resourceRoot, list)
end)
