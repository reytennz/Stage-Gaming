local panelOpen = false
local commands = {}
local filteredCommands = {}
local scrollOffset = 0
local searchBox
local hits = {}

local function closePanel()
	if isElement(searchBox) then destroyElement(searchBox) end
	searchBox = nil
	panelOpen = false
	commands = {}
	filteredCommands = {}
	hits = {}
	scrollOffset = 0
	showCursor(false)
	guiSetInputEnabled(false)
end

local function refreshCommands()
	local search = isElement(searchBox) and guiGetText(searchBox):lower() or ""
	filteredCommands = {}
	for _, entry in ipairs(commands) do
		local command = tostring(entry.command or "")
		local resource = tostring(entry.resource or "")
		if search == "" or command:lower():find(search, 1, true) or resource:lower():find(search, 1, true) then
			filteredCommands[#filteredCommands + 1] = entry
		end
	end
	local maxOffset = math.max(0, #filteredCommands - 12)
	scrollOffset = math.min(scrollOffset, maxOffset)
end

local function openPanel(rows)
	commands = rows or {}
	table.sort(commands, function(a, b)
		if a.resource == b.resource then return a.command < b.command end
		return a.resource < b.resource
	end)
	local sw, sh = guiGetScreenSize()
	local w, h = 860, 610
	local x, y = (sw - w) / 2, (sh - h) / 2
	if isElement(searchBox) then destroyElement(searchBox) end
	searchBox = guiCreateEdit(x + 28, y + 88, 420, 38, "", false)
	guiEditSetMaxLength(searchBox, 40)
	guiSetInputEnabled(true)
	showCursor(true)
	panelOpen = true
	scrollOffset = 0
	refreshCommands()
end

addEvent("stage_admincommands:open", true)
addEventHandler("stage_admincommands:open", root, function(rows)
	openPanel(rows)
end)

addEventHandler("onClientGUIChanged", root, function(element)
	if panelOpen and element == searchBox then refreshCommands() end
end)

addEventHandler("onClientRender", root, function()
	if not panelOpen then return end
	local sw, sh = guiGetScreenSize()
	local w, h = 860, 610
	local x, y = (sw - w) / 2, (sh - h) / 2
	hits = { rows = {} }
	dxDrawRectangle(0, 0, sw, sh, tocolor(0, 0, 0, 155))
	dxDrawRectangle(x, y, w, h, tocolor(18, 21, 26, 250))
	dxDrawRectangle(x, y, w, 4, tocolor(45, 190, 170, 255))
	dxDrawText("STAGE ADMIN KOMUTLARI", x + 28, y + 22, x + w - 80, y + 58, tocolor(245, 245, 245, 255), 1.25, "default-bold", "left", "center")
	dxDrawText(#filteredCommands .. " komut bulundu", x + 28, y + 58, x + w - 80, y + 80, tocolor(145, 155, 165, 255), 0.82, "default", "left", "center")
	hits.close = { x = x + w - 58, y = y + 18, w = 38, h = 38 }
	dxDrawText("X", hits.close.x, hits.close.y, hits.close.x + hits.close.w, hits.close.y + hits.close.h, tocolor(245, 245, 245, 255), 1.1, "default-bold", "center", "center")

	local listX, listY, rowW, rowH = x + 28, y + 145, w - 76, 38
	for i = 1, 12 do
		local entry = filteredCommands[i + scrollOffset]
		if not entry then break end
		local rowY = listY + (i - 1) * 35
		hits.rows[i] = { x = listX, y = rowY, w = rowW, h = rowH, entry = entry }
		local bg = i % 2 == 0 and tocolor(29, 34, 41, 235) or tocolor(24, 29, 35, 235)
		dxDrawRectangle(listX, rowY, rowW, rowH, bg)
		dxDrawText("/" .. tostring(entry.command), listX + 14, rowY, listX + 270, rowY + rowH, tocolor(235, 240, 242, 255), 0.95, "default-bold", "left", "center")
		dxDrawText(tostring(entry.resource), listX + 310, rowY, listX + rowW - 14, rowY + rowH, tocolor(90, 190, 175, 255), 0.86, "default", "left", "center")
	end
	if #filteredCommands == 0 then
		dxDrawText("Komut bulunamadı.", listX, listY + 40, listX + rowW, listY + 80, tocolor(180, 185, 190, 255), 0.95, "default", "center", "center")
	end
	local barX, barY, barW, barH = x + w - 30, listY, 5, 420
	dxDrawRectangle(barX, barY, barW, barH, tocolor(45, 50, 58, 255))
	local maxOffset = math.max(1, #filteredCommands - 12)
	local thumbY = barY + (barH - 55) * (scrollOffset / maxOffset)
	dxDrawRectangle(barX, thumbY, barW, 55, tocolor(55, 190, 170, 255))
	dxDrawText("Mouse tekerleği: listeyi kaydır | ESC: kapat", x + 28, y + h - 36, x + w - 28, y + h - 12, tocolor(125, 135, 145, 255), 0.78, "default", "left", "center")
end)

addEventHandler("onClientClick", root, function(button, state)
	if not panelOpen or button ~= "left" or state ~= "up" then return end
	if hits.close and isCursorShowing() then
		local cx, cy = getCursorPosition()
		local sw, sh = guiGetScreenSize()
		cx, cy = cx * sw, cy * sh
		if cx >= hits.close.x and cx <= hits.close.x + hits.close.w and cy >= hits.close.y and cy <= hits.close.y + hits.close.h then closePanel(); cancelEvent() end
	end
end)

addEventHandler("onClientKey", root, function(key, press)
	if not panelOpen or not press then return end
	if key == "escape" then
		closePanel()
	elseif key == "mouse_wheel_down" then
		scrollOffset = math.min(math.max(0, #filteredCommands - 12), scrollOffset + 1)
	elseif key == "mouse_wheel_up" then
		scrollOffset = math.max(0, scrollOffset - 1)
	end
end)
