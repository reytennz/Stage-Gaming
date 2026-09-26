MessagesApp = MessagesApp or {}
function MessagesApp.send(target, text)
    if type(target) ~= "string" or type(text) ~= "string" then
        return
    end
    if target == "" or text == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:message", localPlayer, target, text)
    end
end
function MessagesApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("messages")
    end
end
