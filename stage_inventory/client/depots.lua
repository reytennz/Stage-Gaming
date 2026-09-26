local depotsOpen = false
local depotList = {}
local selectedDepot
local depotNameEdit
local depotHits = {}

local function depotMouseIn(hit)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    local sw, sh = guiGetScreenSize()
    if not cx then return false end
    cx, cy = cx * sw, cy * sh
    return cx >= hit.x and cx <= hit.x + hit.w and cy >= hit.y and cy <= hit.y + hit.h
end

local function closeDepots()
    if isElement(depotNameEdit) then destroyElement(depotNameEdit) end
    depotNameEdit = nil
    depotsOpen = false
    depotList = {}
    selectedDepot = nil
    depotHits = {}
    showCursor(false)
    guiSetInputEnabled(false)
end

local function openDepots()
    if depotsOpen then return end
    local sw, sh = guiGetScreenSize()
    depotNameEdit = guiCreateEdit((sw - 760) / 2 + 390, (sh - 560) / 2 + 270, 320, 38, "", false)
    depotsOpen = true
    showCursor(true)
    guiSetInputEnabled(true)
    triggerServerEvent("inv:requestDepots", localPlayer)
end

addCommandHandler("depolar", openDepots)

addEvent("inv:depotList", true)
addEventHandler("inv:depotList", root, function(list)
    local selectedObject = selectedDepot and selectedDepot.object
    depotList = list or {}
    selectedDepot = depotList[1]
    for _, depot in ipairs(depotList) do
        if depot.object == selectedObject then selectedDepot = depot break end
    end
    if isElement(depotNameEdit) then
        guiSetText(depotNameEdit, selectedDepot and selectedDepot.name or "")
    end
end)

addEvent("inv:depotDeleted", true)
addEventHandler("inv:depotDeleted", root, function(obj)
    for i = #depotList, 1, -1 do
        if depotList[i].object == obj then table.remove(depotList, i) end
    end
    selectedDepot = depotList[1]
    if isElement(depotNameEdit) then guiSetText(depotNameEdit, selectedDepot and selectedDepot.name or "") end
end)

addEventHandler("onClientRender", root, function()
    if not depotsOpen then return end
    local sw, sh = guiGetScreenSize()
    local w, h = 760, 560
    local x, y = (sw - w) / 2, (sh - h) / 2
    depotHits = { rows = {} }
    dxDrawRectangle(0, 0, sw, sh, tocolor(0, 0, 0, 155))
    dxDrawRectangle(x, y, w, h, tocolor(19, 22, 27, 250))
    dxDrawRectangle(x, y, w, 4, tocolor(35, 190, 170, 255))
    dxDrawText("Depolar", x + 28, y + 18, x + w - 70, y + 58, tocolor(245, 245, 245, 255), 1.35, "default-bold", "left", "center")
    dxDrawText("Mevcut depoları yönet", x + 28, y + 55, x + w - 70, y + 82, tocolor(145, 155, 165, 255), 0.88, "default", "left", "center")
    depotHits.close = { x = x + w - 58, y = y + 15, w = 38, h = 38 }
    dxDrawText("X", depotHits.close.x, depotHits.close.y, depotHits.close.x + depotHits.close.w, depotHits.close.y + depotHits.close.h, tocolor(245, 245, 245, 255), 1.1, "default-bold", "center", "center")

    local listX, listY, listW = x + 28, y + 105, 325
    dxDrawText("Depo listesi", listX, listY - 28, listX + listW, listY, tocolor(180, 190, 200, 255), 0.9, "default-bold", "left", "center")
    for i, depot in ipairs(depotList) do
        local rowY = listY + (i - 1) * 48
        if rowY > y + h - 35 then break end
        local selected = selectedDepot == depot
        depotHits.rows[i] = { x = listX, y = rowY, w = listW, h = 40, depot = depot }
        dxDrawRectangle(listX, rowY, listW, 40, selected and tocolor(35, 110, 98, 255) or tocolor(35, 40, 47, 255))
        dxDrawText(depot.name or "Depo", listX + 12, rowY + 4, listX + listW - 12, rowY + 23, tocolor(245, 245, 245, 255), 0.92, "default-bold", "left", "center")
        dxDrawText(string.format("%.1f, %.1f, %.1f", depot.x or 0, depot.y or 0, depot.z or 0), listX + 12, rowY + 22, listX + listW - 12, rowY + 38, tocolor(170, 180, 185, 255), 0.72, "default", "left", "center")
    end
    if #depotList == 0 then dxDrawText("Kayıtlı depo yok.", listX, listY + 20, listX + listW, listY + 55, tocolor(180, 185, 190, 255), 0.95, "default", "center", "center") end

    local rightX, rightY, rightW = x + 390, y + 125, 320
    dxDrawText("Seçili depo", rightX, rightY - 28, rightX + rightW, rightY, tocolor(180, 190, 200, 255), 0.9, "default-bold", "left", "center")
    dxDrawText(selectedDepot and (selectedDepot.depotType == "universal" and "Ortak" or "Kişisel") or "-", rightX, rightY + 42, rightX + rightW, rightY + 68, tocolor(180, 190, 200, 255), 0.9, "default", "left", "center")
    depotHits.move = { x = rightX, y = rightY + 82, w = rightW, h = 42 }
    depotHits.rename = { x = rightX, y = rightY + 195, w = rightW, h = 42 }
    depotHits.delete = { x = rightX, y = rightY + 250, w = rightW, h = 42 }
    dxDrawRectangle(depotHits.move.x, depotHits.move.y, depotHits.move.w, depotHits.move.h, tocolor(40, 115, 130, 255))
    dxDrawText("Konumuma Taşı", depotHits.move.x, depotHits.move.y, depotHits.move.x + depotHits.move.w, depotHits.move.y + depotHits.move.h, tocolor(245, 245, 245, 255), 0.92, "default-bold", "center", "center")
    dxDrawText("Yeni depo ismi", rightX, rightY + 155, rightX + rightW, rightY + 180, tocolor(180, 190, 200, 255), 0.88, "default-bold", "left", "center")
    dxDrawRectangle(depotHits.rename.x, depotHits.rename.y, depotHits.rename.w, depotHits.rename.h, tocolor(35, 145, 125, 255))
    dxDrawText("İsmi Güncelle", depotHits.rename.x, depotHits.rename.y, depotHits.rename.x + depotHits.rename.w, depotHits.rename.y + depotHits.rename.h, tocolor(245, 245, 245, 255), 0.92, "default-bold", "center", "center")
    dxDrawRectangle(depotHits.delete.x, depotHits.delete.y, depotHits.delete.w, depotHits.delete.h, tocolor(165, 65, 65, 255))
    dxDrawText("Depoyu Sil", depotHits.delete.x, depotHits.delete.y, depotHits.delete.x + depotHits.delete.w, depotHits.delete.y + depotHits.delete.h, tocolor(245, 245, 245, 255), 0.92, "default-bold", "center", "center")
end)

addEventHandler("onClientClick", root, function(button, state)
    if not depotsOpen or button ~= "left" or state ~= "up" then return end
    if depotHits.close and depotMouseIn(depotHits.close) then closeDepots() return end
    for i, hit in pairs(depotHits.rows or {}) do
        if depotMouseIn(hit) then
            selectedDepot = hit.depot
            if isElement(depotNameEdit) then guiSetText(depotNameEdit, selectedDepot.name or "") end
            return
        end
    end
    if not selectedDepot then return end
    if depotMouseIn(depotHits.move) then
        triggerServerEvent("inv:updateDepot", localPlayer, selectedDepot.object, selectedDepot.name, true)
    elseif depotMouseIn(depotHits.rename) then
        triggerServerEvent("inv:updateDepot", localPlayer, selectedDepot.object, guiGetText(depotNameEdit), false)
    elseif depotMouseIn(depotHits.delete) then
        triggerServerEvent("inv:deleteDepot", localPlayer, selectedDepot.object)
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if depotsOpen and press and key == "escape" then closeDepots() end
end)

