PhoneNotifications = PhoneNotifications or {}
function PhoneNotifications.show(message)
    if type(message) ~= "string" or message == "" then
        return
    end
    outputChatBox("[Telefon] " .. message, 120, 200, 255)
end
