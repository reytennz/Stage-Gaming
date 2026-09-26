local window, list, buyButton, closeButton

local function closeShop()
    if isElement(window) then guiSetVisible(window, false) end
    showCursor(false)
end

addEvent("stageVehicleShop:open", true)
addEventHandler("stageVehicleShop:open", root, function(vehicles)
    if not isElement(window) then
        local sw, sh = guiGetScreenSize()
        window = guiCreateWindow(sw / 2 - 260, sh / 2 - 210, 520, 420, "Stage Gaming - Arac Paneli", false)
        guiWindowSetSizable(window, false)
        list = guiCreateGridList(15, 30, 490, 330, false, window)
        guiGridListAddColumn(list, "Sira", 0.10)
        guiGridListAddColumn(list, "Arac", 0.60)
        guiGridListAddColumn(list, "Fiyat", 0.25)
        buyButton = guiCreateButton(15, 370, 300, 32, "Secili Araci Al", false, window)
        closeButton = guiCreateButton(325, 370, 180, 32, "Kapat", false, window)
        addEventHandler("onClientGUIClick", buyButton, function()
            local row = guiGridListGetSelectedItem(list)
            if row and row >= 0 then triggerServerEvent("stageVehicleShop:buy", localPlayer, guiGridListGetItemData(list, row, 1)) end
        end, false)
        addEventHandler("onClientGUIClick", closeButton, closeShop, false)
    end
    guiGridListClear(list)
    for i, data in ipairs(vehicles or {}) do
        local row = guiGridListAddRow(list)
        guiGridListSetItemText(list, row, 1, tostring(i), false, false)
        guiGridListSetItemText(list, row, 2, data.name, false, false)
        guiGridListSetItemText(list, row, 3, "$" .. tostring(data.price), false, false)
        guiGridListSetItemData(list, row, 1, i)
    end
    guiSetVisible(window, true)
    showCursor(true)
end)

bindKey("escape", "down", function() if isElement(window) and guiGetVisible(window) then closeShop() end end)
