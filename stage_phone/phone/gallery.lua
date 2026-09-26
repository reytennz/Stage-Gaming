GalleryApp = GalleryApp or {}
function GalleryApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("gallery")
    end
end
