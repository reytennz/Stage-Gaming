CallsApp = CallsApp or {}
function CallsApp.call(number)
    if type(number) ~= "string" or number == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:call", localPlayer, number)
    end
end
function CallsApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("calls")
    end
end
