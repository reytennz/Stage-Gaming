StageX = StageX or {}
function StageX.post(text)
    if type(text) ~= "string" or text == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:post", localPlayer, "twitter", text)
    end
end
function StageX.open()
    if Phone and Phone.setPage then
        Phone.setPage("stagex")
    end
end
