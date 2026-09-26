ContactsApp = ContactsApp or {}
function ContactsApp.add(name, number)
    if type(name) ~= "string" or type(number) ~= "string" then
        return
    end
    if name == "" or number == "" then
        return
    end
    if localPlayer and isElement(localPlayer) then
        triggerServerEvent("stagephone:contact", localPlayer, name, number)
    end
end
function ContactsApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("contacts")
    end
end
