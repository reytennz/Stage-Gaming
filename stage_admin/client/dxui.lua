--[[
    stage_admin - DX UI toolkit
    CEGUI kullanmayan, tamamen dxDraw ile çizilen minimal ama işlevsel UI kütüphanesi.
    "Retained rect" yaklaşımı: her frame'de görünür kontroller kendini
    DX.controls tablosuna kaydeder, tıklama bu tabloya göre test edilir.
]]

AdminUIOpen = false -- F5 panel ya da F3 report paneli açıkken true (movement.lua bunu kontrol eder)

DX = {}
DX.controls = {}      -- bu frame'de çizilen tıklanabilir alanlar: [id] = {x,y,w,h,type,onClick}
DX.inputs = {}        -- textbox değerleri: [id] = "metin"
DX.focused = nil       -- odaklı textbox id'si
DX.scroll = {}         -- liste kaydırma offsetleri: [listId] = rowOffset
DX.lastListRects = {}  -- wheel scroll için: [listId] = {x,y,w,h}

local sw, sh = guiGetScreenSize()
local roundedCache = {}
local function roundedPanel(x, y, w, h, color, radius)
    local key = tostring(math.floor(w)) .. "x" .. tostring(math.floor(h)) .. "x" .. tostring(radius or 10)
    if not isElement(roundedCache[key]) then
        local rw,rh,rr=math.floor(w),math.floor(h),math.floor(radius or 10)
        local ok,el=pcall(svgCreate,rw,rh,string.format('<svg width="%d" height="%d"><rect width="%d" height="%d" rx="%d" fill="#fff"/></svg>',rw,rh,rw,rh,rr))
        roundedCache[key]=ok and el or false
    end
    if roundedCache[key] then dxDrawImage(x,y,w,h,roundedCache[key],0,0,0,color) else dxDrawRectangle(x,y,w,h,color) end
end

-- Renk paleti
DX.C = {
    bg        = tocolor(12, 13, 17, 250),
    panel     = tocolor(19, 21, 27, 255),
    panelAlt  = tocolor(24, 26, 33, 255),
    border    = tocolor(40, 43, 52, 255),
    accent    = tocolor(88, 150, 255, 255),
    accentDim = tocolor(88, 150, 255, 60),
    text      = tocolor(219, 221, 230, 255),
    textDim   = tocolor(140, 144, 156, 255),
    success   = tocolor(90, 220, 140, 255),
    danger    = tocolor(240, 90, 90, 255),
    warning   = tocolor(240, 190, 80, 255),
    rowA      = tocolor(22, 24, 30, 255),
    rowB      = tocolor(27, 29, 37, 255),
    rowHover  = tocolor(35, 60, 95, 255),
    rowSel    = tocolor(45, 85, 140, 255),
}

function DX.beginFrame()
    DX.controls = {}
    DX.lastListRects = {}
end

local function pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

function DX.isHovering(x, y, w, h)
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sw, cy * sh
    return pointInRect(cx, cy, x, y, w, h)
end

-- ---------------- temel çizimler ----------------

function DX.panel(x, y, w, h, color)
    roundedPanel(x, y, w, h, color or DX.C.panel, 10)
end

function DX.border(x, y, w, h, color, thickness)
    thickness = thickness or 1
    color = color or DX.C.border
    dxDrawRectangle(x, y, w, thickness, color)
    dxDrawRectangle(x, y + h - thickness, w, thickness, color)
    dxDrawRectangle(x, y, thickness, h, color)
    dxDrawRectangle(x + w - thickness, y, thickness, h, color)
end

function DX.text(txt, x, y, w, h, color, scale, align, valign, wordwrap)
    dxDrawText(txt or "", x, y, x + (w or 200), y + (h or 20), color or DX.C.text,
        scale or 1, "default-bold", align or "left", valign or "center", false, wordwrap or false)
end

-- ---------------- buton ----------------

function DX.button(id, x, y, w, h, label, onClick, accentColor)
    accentColor = accentColor or DX.C.accent
    local hover = DX.isHovering(x, y, w, h)

    DX.panel(x, y, w, h, hover and DX.C.panelAlt or DX.C.panel)
    DX.border(x, y, w, h, hover and accentColor or DX.C.border)
    DX.text(label, x + 4, y, w - 8, h, hover and DX.C.text or DX.C.textDim, 0.85, "center", "center")

    DX.controls[id] = { x = x, y = y, w = w, h = h, type = "button", onClick = onClick }
end

-- ---------------- text input ----------------

function DX.textInput(id, x, y, w, h, placeholder, numericOnly)
    local focused = (DX.focused == id)
    local value = DX.inputs[id] or ""

    DX.panel(x, y, w, h, DX.C.panelAlt)
    DX.border(x, y, w, h, focused and DX.C.accent or DX.C.border)

    local display = value
    if display == "" and not focused then
        DX.text(placeholder or "", x + 8, y, w - 16, h, DX.C.textDim, 0.85, "left", "center")
    else
        if focused and (getTickCount() % 1000) < 500 then display = display .. "|" end
        DX.text(display, x + 8, y, w - 16, h, DX.C.text, 0.85, "left", "center")
    end

    DX.controls[id] = { x = x, y = y, w = w, h = h, type = "input", numericOnly = numericOnly and true or false }
end

function DX.getInput(id)
    return DX.inputs[id] or ""
end

function DX.setInput(id, value)
    DX.inputs[id] = value or ""
end

-- ---------------- liste (gridlist muadili) ----------------
-- columns: { {label="Ad", width=0.4}, ... }  (width oranları toplamı ~1 olmalı)
-- rows: { {col1, col2, ...}, ... }
function DX.list(id, x, y, w, h, columns, rows, onRowClick, selectedIndex)
    DX.panel(x, y, w, h, DX.C.panelAlt)
    DX.border(x, y, w, h)

    local headerH = 24
    local rowH = 22
    local cx = x
    for _, col in ipairs(columns) do
        local cw = col.width * w
        DX.text(col.label, cx + 6, y, cw - 6, headerH, DX.C.textDim, 0.8, "left", "center")
        cx = cx + cw
    end
    dxDrawRectangle(x, y + headerH, w, 1, DX.C.border)

    local visibleRows = math.floor((h - headerH) / rowH)
    local offset = DX.scroll[id] or 0
    local maxOffset = math.max(0, #rows - visibleRows)
    if offset > maxOffset then offset = maxOffset end
    DX.scroll[id] = offset

    DX.lastListRects[id] = { x = x, y = y, w = w, h = h }

    for i = 1, visibleRows do
        local rowIndex = i + offset
        local row = rows[rowIndex]
        if not row then break end

        local ry = y + headerH + (i - 1) * rowH
        local hover = DX.isHovering(x, ry, w, rowH)
        local isSelected = (selectedIndex == rowIndex)

        local bg = (rowIndex % 2 == 0) and DX.C.rowA or DX.C.rowB
        if isSelected then bg = DX.C.rowSel elseif hover then bg = DX.C.rowHover end
        dxDrawRectangle(x, ry, w, rowH, bg)
        if isSelected then
            dxDrawRectangle(x, ry, 4, rowH, DX.C.accent)
            DX.border(x, ry, w, rowH, DX.C.accent, 1)
        end

        cx = x
        for ci, col in ipairs(columns) do
            local cw = col.width * w
            DX.text(tostring(row[ci] or ""), cx + 6, ry, cw - 8, rowH, isSelected and DX.C.accent or DX.C.text, 0.75, "left", "center", false)
            cx = cx + cw
        end

        DX.controls[id .. "_row_" .. rowIndex] = {
            x = x, y = ry, w = w, h = rowH, type = "button",
            onClick = function() if onRowClick then onRowClick(rowIndex, row) end end,
        }
    end

    if #rows > visibleRows then
        local barH = h - headerH
        local thumbH = math.max(20, barH * (visibleRows / #rows))
        local thumbY = y + headerH + (barH - thumbH) * (offset / maxOffset)
        dxDrawRectangle(x + w - 4, y + headerH, 4, barH, tocolor(0,0,0,80))
        dxDrawRectangle(x + w - 4, thumbY, 4, thumbH, DX.C.accent)
    end
end

function DX.scrollList(id, delta)
    DX.scroll[id] = math.max(0, (DX.scroll[id] or 0) + delta)
end

-- ---------------- sekmeler ----------------

function DX.tabs(id, x, y, w, h, tabNames, activeIndex, onChange)
    local tabW = w / #tabNames
    for i, name in ipairs(tabNames) do
        local tx = x + (i - 1) * tabW
        local active = (i == activeIndex)
        local hover = DX.isHovering(tx, y, tabW, h)

        DX.panel(tx, y, tabW, h, active and DX.C.accentDim or (hover and DX.C.panelAlt or DX.C.bg))
        if active then DX.border(tx, y, tabW, h, DX.C.accent, 1) end
        DX.text(name, tx + 2, y, tabW - 4, h, active and DX.C.accent or DX.C.textDim, 0.72, "center", "center")
        if active then
            dxDrawRectangle(tx, y + h - 2, tabW, 2, DX.C.accent)
        end

        DX.controls[id .. "_tab_" .. i] = {
            x = tx, y = y, w = tabW, h = h, type = "button",
            onClick = function() if onChange then onChange(i) end end,
        }
    end
end

-- ---------------- global input event'leri ----------------

addEventHandler("onClientClick", root, function(button, state, ax, ay)
    if button ~= "left" or state ~= "down" then return end
    local hitInput = nil
    for id, c in pairs(DX.controls) do
        if pointInRect(ax, ay, c.x, c.y, c.w, c.h) then
            if c.type == "input" then
                hitInput = id
            elseif c.type == "button" and c.onClick then
                c.onClick()
                return
            end
        end
    end
    DX.focused = hitInput
end)

addEventHandler("onClientCharacter", root, function(char)
    if not DX.focused then return end
    local ctrl = DX.controls[DX.focused]
    local current = DX.inputs[DX.focused] or ""
    if ctrl and ctrl.numericOnly and not char:match("^[%d%.%-]$") then return end
    if #current < 80 then
        DX.inputs[DX.focused] = current .. char
    end
    cancelEvent()
end)

addEventHandler("onClientKey", root, function(key, down)
    if not DX.focused or not down then return end
    if key == "backspace" then
        local current = DX.inputs[DX.focused] or ""
        DX.inputs[DX.focused] = current:sub(1, -2)
        cancelEvent()
    elseif key == "enter" or key == "num_enter" or key == "tab" or key == "escape" then
        DX.focused = nil
    end
end)

bindKey("mouse_wheel_up", "down", function()
    local cx, cy = getCursorPosition()
    if not cx then return end
    cx, cy = cx * sw, cy * sh
    for id, r in pairs(DX.lastListRects) do
        if pointInRect(cx, cy, r.x, r.y, r.w, r.h) then
            DX.scrollList(id, -1)
            return
        end
    end
end)

bindKey("mouse_wheel_down", "down", function()
    local cx, cy = getCursorPosition()
    if not cx then return end
    cx, cy = cx * sw, cy * sh
    for id, r in pairs(DX.lastListRects) do
        if pointInRect(cx, cy, r.x, r.y, r.w, r.h) then
            DX.scrollList(id, 1)
            return
        end
    end
end)
