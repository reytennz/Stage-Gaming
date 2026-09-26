SettingsApp = SettingsApp or {}
function SettingsApp.setScale(scale)
    if Phone and Phone.setScale then
        Phone.setScale(scale)
    end
end
function SettingsApp.setBackground(index)
    if Phone and Phone.setBackground then
        Phone.setBackground(index)
    end
end
function SettingsApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("settings")
    end
end
