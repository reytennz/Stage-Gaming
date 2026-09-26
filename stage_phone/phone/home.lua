-- Ana ekran cizimi client.lua icinde tutulur.
HomeApp = HomeApp or {}
function HomeApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("home")
    end
end
