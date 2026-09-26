CameraApp = CameraApp or {}
function CameraApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("camera")
    end
end
