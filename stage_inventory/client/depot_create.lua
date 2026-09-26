local depotCreateOpen = false
local depotCreateName
local depotCreateType = "personal"
local depotCreateLocationReady = false
local depotCreateHits = {}

local function depotInside(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    local sx, sy = guiGetScreenSize()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function closeDepotCreate()
    if isElement(depotCreateName) then destroyElement(depotCreateName) end
    depotCreateName = nil
    depotCreateOpen = false
    depotCreateHits = {}
    showCursor(false)
    guiSetInputEnabled(false)
end

local function openDepotCreate()
    if depotCreateOpen then return end
    local sw, sh = guiGetScreenSize()
    local w, h = 520, 430
    local x, y = (sw - w) / 2, (sh - h) / 2
    depotCreateOpen = true
    depotCreateType = "personal"
    depotCreateLocationReady = false
    depotCreateName = guiCreateEdit(x + 80, y + 115, w - 160, 38, "", false)
    guiEditSetMaxLength(depotCreateName, 32)
    guiSetInputEnabled(true)
    showCursor(true)
end

addCommandHandler("depoolustur", openDepotCreate)

addEventHandler("onClientRender", root, function()
    if not depotCreateOpen then return end
    local sw, sh = guiGetScreenSize()
    local w, h = 520, 430
    local x, y = (sw - w) / 2, (sh - h) / 2
    local personalColor = depotCreateType == "personal" and tocolor(35, 145, 125, 255) or tocolor(48, 52, 60, 255)
    local universalColor = depotCreateType == "universal" and tocolor(35, 145, 125, 255) or tocolor(48, 52, 60, 255)
    depotCreateHits = {
        location = { x = x + 80, y = y + 175, w = w - 160, h = 42 },
        personal = { x = x + 80, y = y + 285, w = 160, h = 42 },
        universal = { x = x + 280, y = y + 285, w = 160, h = 42 },
        create = { x = x + 280, y = y + 355, w = 160, h = 42 },
        close = { x = x + 80, y = y + 355, w = 160, h = 42 },
    }

    dxDrawRectangle(0, 0, sw, sh, tocolor(0, 0, 0, 150))
    dxDrawRectangle(x, y, w, h, tocolor(19, 22, 27, 250))
    dxDrawRectangle(x, y, w, 4, tocolor(35, 190, 170, 255))
    dxDrawText("Depo Oluştur", x, y + 25, x + w, y + 65, tocolor(245, 245, 245, 255), 1.35, "default-bold", "center", "center")
    dxDrawText("Depo İsmi", x + 80, y + 85, x + w - 80, y + 110, tocolor(175, 185, 195, 255), 0.95, "default-bold", "left", "center")
    dxDrawText(depotCreateLocationReady and "Konum seçildi" or "Konum seçilmedi", x + 80, y + 222, x + w - 80, y + 250, depotCreateLocationReady and tocolor(90, 220, 140, 255) or tocolor(220, 180, 80, 255), 0.9, "default", "center", "center")
    dxDrawText("Tür", x + 80, y + 260, x + w - 80, y + 280, tocolor(175, 185, 195, 255), 0.95, "default-bold", "left", "center")

    dxDrawRectangle(depotCreateHits.location.x, depotCreateHits.location.y, depotCreateHits.location.w, depotCreateHits.location.h, tocolor(40, 115, 130, 255))
    dxDrawText("Mevcut Konumu Kullan", depotCreateHits.location.x, depotCreateHits.location.y, depotCreateHits.location.x + depotCreateHits.location.w, depotCreateHits.location.y + depotCreateHits.location.h, tocolor(245, 245, 245, 255), 0.95, "default-bold", "center", "center")
    dxDrawRectangle(depotCreateHits.personal.x, depotCreateHits.personal.y, depotCreateHits.personal.w, depotCreateHits.personal.h, personalColor)
    dxDrawRectangle(depotCreateHits.universal.x, depotCreateHits.universal.y, depotCreateHits.universal.w, depotCreateHits.universal.h, universalColor)
    dxDrawText("Kişisel", depotCreateHits.personal.x, depotCreateHits.personal.y, depotCreateHits.personal.x + depotCreateHits.personal.w, depotCreateHits.personal.y + depotCreateHits.personal.h, tocolor(245, 245, 245, 255), 0.95, "default-bold", "center", "center")
    dxDrawText("Ortak", depotCreateHits.universal.x, depotCreateHits.universal.y, depotCreateHits.universal.x + depotCreateHits.universal.w, depotCreateHits.universal.y + depotCreateHits.universal.h, tocolor(245, 245, 245, 255), 0.95, "default-bold", "center", "center")
    dxDrawRectangle(depotCreateHits.close.x, depotCreateHits.close.y, depotCreateHits.close.w, depotCreateHits.close.h, tocolor(55, 60, 68, 255))
    dxDrawRectangle(depotCreateHits.create.x, depotCreateHits.create.y, depotCreateHits.create.w, depotCreateHits.create.h, tocolor(35, 145, 125, 255))
    dxDrawText("Kapat", depotCreateHits.close.x, depotCreateHits.close.y, depotCreateHits.close.x + depotCreateHits.close.w, depotCreateHits.close.y + depotCreateHits.close.h, tocolor(245, 245, 245, 255), 0.95, "default-bold", "center", "center")
    dxDrawText("Oluştur", depotCreateHits.create.x, depotCreateHits.create.y, depotCreateHits.create.x + depotCreateHits.create.w, depotCreateHits.create.y + depotCreateHits.create.h, tocolor(245, 245, 245, 255), 0.95, "default-bold", "center", "center")
end)

addEventHandler("onClientClick", root, function(button, state)
    if not depotCreateOpen or button ~= "left" or state ~= "up" then return end
    for key, hit in pairs(depotCreateHits) do
        if depotInside(hit.x, hit.y, hit.w, hit.h) then
            if key == "location" then
                depotCreateLocationReady = true
            elseif key == "personal" or key == "universal" then
                depotCreateType = key
            elseif key == "close" then
                closeDepotCreate()
            elseif key == "create" then
                local name = guiGetText(depotCreateName)
                if name:gsub("%s+", "") == "" then
                    outputChatBox("Depo ismi girmen gerekiyor.", 255, 80, 80)
                elseif not depotCreateLocationReady then
                    outputChatBox("Önce mevcut konumunu kullan butonuna bas.", 255, 180, 80)
                else
                    triggerServerEvent("inv:createDepot", localPlayer, name, depotCreateType)
                    closeDepotCreate()
                end
            end
            return
        end
    end
end)