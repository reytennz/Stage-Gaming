NotesApp = NotesApp or {}
function NotesApp.create(title, body)
    if type(title) ~= "string" then title = "" end
    if type(body) ~= "string" then body = "" end
    if title == "" and body == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:note", localPlayer, title, body)
    end
end
function NotesApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("notes")
    end
end
