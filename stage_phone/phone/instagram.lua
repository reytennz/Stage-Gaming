Stagegram = Stagegram or {}
function Stagegram.post(text)
    if type(text) ~= "string" or text == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:post", localPlayer, "instagram", text)
    end
end
function Stagegram.open()
    if Phone and Phone.setPage then
        Phone.setPage("stagegram")
    end
end
