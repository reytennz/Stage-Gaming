--[[
    Inventory - Referans gorsele birebir yakin
    Scale 1920x1080 baz (tam ekran)
]]

local sx, sy = guiGetScreenSize()
local BW, BH = 1920, 1080
local scale = math.min(sx / BW, sy / BH)
local offX = (sx - BW * scale) / 2
local offY = (sy - BH * scale) / 2

local function R()
    sx, sy = guiGetScreenSize()
    scale = math.min(sx / BW, sy / BH)
    offX = (sx - BW * scale) / 2
    offY = (sy - BH * scale) / 2
end

local function S(x, y, w, h)
    return offX + x * scale, offY + y * scale, (w or 0) * scale, (h or 0) * scale
end

local function mouseIn(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local rounded = {}
local function roundRect(id, x, y, w, h, rad, color)
    id = tostring(id)
    w = math.max(1, math.floor(w + 0.5))
    h = math.max(1, math.floor(h + 0.5))
    rad = math.min(math.floor((rad or 0) + 0.5), math.floor(math.min(w, h) / 2))
    if rad <= 0 then dxDrawRectangle(x, y, w, h, color) return end
    rounded[id] = rounded[id] or {}
    rounded[id][w] = rounded[id][w] or {}
    rounded[id][w][h] = rounded[id][w][h] or {}
    if not isElement(rounded[id][w][h][rad]) then
        local svg = string.format(
            '<svg width="%d" height="%d"><rect width="%d" height="%d" rx="%d" fill="#fff"/></svg>',
            w, h, w, h, rad
        )
        local ok, el = pcall(svgCreate, w, h, svg)
        if ok and el then rounded[id][w][h][rad] = el
        else dxDrawRectangle(x, y, w, h, color) return end
    end
    dxDrawImage(x, y, w, h, rounded[id][w][h][rad], 0, 0, 0, color)
end

-- State
local open = false
local depotMode = false
local activeDepotName = "Depo"
local activeDepot = nil
local depotContents = {}
-- Inventory HUD/hotbar is permanently disabled; only the F2 inventory panel is used.
local showHB = false
local inv, hb, weight = {}, {}, 0
local sel = nil -- {t="inv"|"hb", s=slot}
local qty = 1
local notifs = {}
local hits = { inv = {}, hb = {}, btn = {} }
local hoverEntry = nil

-- Drag & drop state
local dragCandidate = nil -- {t="inv"|"hb", s=slot, entry=entryData, x=startScreenX, y=startScreenY}
local dragging = nil      -- same shape as dragCandidate, set once movement exceeds threshold
local mouseHeld = false
local DRAG_THRESHOLD = 7

-- Icon textures (lazy loaded + cached)
local iconCache = {}
local function getIcon(img)
    if not img then return nil end
    local cached = iconCache[img]
    if cached == nil then
        local ok, tex = pcall(dxCreateTexture, "assets/items/" .. img)
        cached = (ok and tex) or false
        iconCache[img] = cached
    end
    if cached == false then return nil end
    return cached
end

local function notify(msg, typ)
    notifs[#notifs + 1] = { m = tostring(msg), t = typ or "info", tick = getTickCount() }
    if #notifs > 5 then table.remove(notifs, 1) end
end

-- Layout design coords (1920x1080)
local COLS, ROWS = 5, 6
local SLOT, GAP = 108, 3
local LPX, LPY = 195, 190          -- left panel origin
local RPX = 1175                   -- right panel
local PPAD = 0
local PH = 57                      -- panel header
local GW = COLS * SLOT + (COLS - 1) * GAP
local GH = ROWS * SLOT + (ROWS - 1) * GAP
local PW = GW + PPAD * 2
local PHh = PH + GH

local HX, HY = 195, 905            -- hizli erisim
-- Hotbar slots use the exact same dimensions as inventory slots.
local HS = SLOT
local HUD_HS = 72

-- Ground pickups: dropped item objects carry element data "inv:dropped" = {item=, count=}
local dropObjs = {}
local nearestDrop = nil
local nearestDepot = nil
local function refreshDrops()
    dropObjs = {}
    for _, obj in ipairs(getElementsByType("object")) do
        if isElement(obj) then
            local dd = getElementData(obj, "inv:dropped")
            if dd and dd.item then
                dropObjs[#dropObjs + 1] = { obj = obj, item = dd.item, count = dd.count or 1 }
            end
        end
    end
end
setTimer(refreshDrops, 700, 0)

local function refreshDepots()
    nearestDepot = nil
    local px, py, pz = getElementPosition(localPlayer)
    local best = 2.8
    for _, obj in ipairs(getElementsByType("object")) do
        if isElement(obj) and getElementData(obj, "inv:depot") then
            local x, y, z = getElementPosition(obj)
            local d = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
            if d < best then best, nearestDepot = d, obj end
        end
    end
end
setTimer(refreshDepots, 500, 0)

-- Fire lock: weapons equipped without real ammo loaded can be held but not fired
local function updateFireLock()
    local locked = getElementData(localPlayer, "inv:lockedWeapon")
    if locked and locked ~= false then
        local slot = getPedWeaponSlot(localPlayer)
        local cur = getPedWeapon(localPlayer, slot)
        if cur == locked then
            toggleControl("fire", false)
            setControlState("fire", false)
        else
            toggleControl("fire", true)
            toggleControl("aim_weapon", true)
        end
    else
        toggleControl("fire", true)
        toggleControl("aim_weapon", true)
    end
end
setTimer(updateFireLock, 200, 0)
addEventHandler("onClientElementDataChange", localPlayer, function(name)
    if name == "inv:lockedWeapon" then updateFireLock() end
end)
addEventHandler("onClientResourceStop", resourceRoot, function() toggleControl("fire", true) end)

addEvent("inv:weaponControls", true)
addEventHandler("inv:weaponControls", root, function(canFire)
    toggleControl("aim_weapon", true)
    toggleControl("fire", canFire ~= false)
    if canFire == false then setControlState("fire", false) end
end)

local function invXY(i)
    local c = (i - 1) % COLS
    local r = math.floor((i - 1) / COLS)
    return LPX + PPAD + c * (SLOT + GAP), LPY + PH + 8 + r * (SLOT + GAP)
end

local function wrdXY(i)
    local c = (i - 1) % COLS
    local r = math.floor((i - 1) / COLS)
    return RPX + PPAD + c * (SLOT + GAP), LPY + PH + 8 + r * (SLOT + GAP)
end

local function hbXY(i)
    return HX + (i - 1) * (HS + 8), HY + 48
end

-- Colors from reference
local TEAL = { 42, 195, 119 }
local PANEL = { 28, 31, 34 }
local SLOT_BG = { 18, 22, 24 }
local SLOT_HOVER = { 30, 35, 38 }
local SLOT_SELECTED = { 75, 35, 88 }
local BORDER = { 61, 66, 70 }
local function applyWeaponWheelLock()
    toggleControl("next_weapon", false)
    toggleControl("previous_weapon", false)
end

local function openUI()
    if open then return end
    open = true
    R()
    applyWeaponWheelLock()
    showCursor(true)
    guiSetInputEnabled(true)
    triggerServerEvent("inv:requestSync", localPlayer)
end

local function closeUI()
    if not open then return end
    open = false
    depotMode = false
    activeDepot = nil
    depotContents = {}
    sel = nil
    dragging, dragCandidate, mouseHeld = nil, nil, false
    applyWeaponWheelLock()
    showCursor(false)
    guiSetInputEnabled(false)
end

-- Inventory is opened with F2. F is intentionally left untouched for gameplay.
local function toggleInventory() if open then closeUI() else openUI() end end
bindKey("F2", "down", toggleInventory)
bindKey("escape", "down", function() if open then cancelEvent() closeUI() end end)
bindKey("e", "down", function()
    if open then return end
    local dep = nearestDepot
    if dep and isElement(dep) then
        triggerServerEvent("inv:depotTry", localPlayer, dep)
        return
    end
    if nearestDrop and isElement(nearestDrop.obj) then
        triggerServerEvent("inv:pickup", localPlayer, nearestDrop.obj)
    end
end)
bindKey("z", "down", function()
    if open then return end
    showHB = not showHB
end)

for i = 1, 5 do
    bindKey(tostring(i), "down", function()
        if open then
            if sel and sel.t == "inv" and inv[sel.s] then
                triggerServerEvent("inv:move", localPlayer, "inv", sel.s, "hotbar", i, inv[sel.s].count or 1)
            end
            return
        end
        if hb[i] and hb[i].item then
            showHB = true
            triggerServerEvent("inv:use", localPlayer, i, true)
            local itm = hb[i].item
            local d = Items[itm]
            triggerItemPopup("Kullanıldı 1x", itm, 1)
        end
    end)
end

local function drawItemVisual(entry, x, y, w, h, dim)
    if not entry or not entry.item or not Items[entry.item] then return end
    local d = Items[entry.item]
    local ia = dim and 90 or 255
    local tex = getIcon(d.image)
    if tex then
        local isz = w * 0.58
        dxDrawImage(x + (w - isz) / 2, y + h * 0.14, isz, isz, tex, 0, 0, 0, tocolor(255, 255, 255, ia))
    else
        dxDrawText(d.label, x + 4, y + h * 0.25, x + w - 4, y + h * 0.65,
            tocolor(230, 235, 245, ia), 0.85 * scale, "default-bold", "center", "center", true)
    end
    dxDrawRectangle(x + 8 * scale, y + h - 27 * scale, w - 16 * scale, 2 * scale,
        tocolor(TEAL[1], TEAL[2], TEAL[3], dim and 70 or 190))
    if entry.count and entry.count > 1 then
        dxDrawText(entry.count .. "x", x + 7 * scale, y + h - 21 * scale, x + w * 0.5, y + h - 5 * scale,
            tocolor(TEAL[1], TEAL[2], TEAL[3], dim and 140 or 255), 0.9 * scale, "default-bold", "left", "bottom")
    end
    local ws
    if d.weapon then
        ws = (entry.ammo and entry.ammo > 0) and (entry.ammo .. " mermi") or "bos"
    else
        ws = string.format("%.2fkg", d.weight * (entry.count or 1))
    end
    dxDrawText(ws, x + w * 0.36, y + h - 21 * scale, x + w - 7 * scale, y + h - 5 * scale,
        tocolor(172, 180, 188, dim and 95 or 245), 0.78 * scale, "default-bold", "right", "bottom")
end

local function drawSlot(id, dx, dy, size, entry, num, selected, dimEntry)
    local x, y, w, h = S(dx, dy, size, size)
    local hov = mouseIn(x, y, w, h)
    local r, g, b = SLOT_BG[1], SLOT_BG[2], SLOT_BG[3]
    local a = selected and 158 or (hov and 104 or 68)
    if selected then r, g, b = SLOT_SELECTED[1], SLOT_SELECTED[2], SLOT_SELECTED[3]
    elseif hov then r, g, b = SLOT_HOVER[1], SLOT_HOVER[2], SLOT_HOVER[3] end
    roundRect(id .. "_shadow", x + 2 * scale, y + 3 * scale, w, h, 4 * scale, tocolor(0, 0, 0, 48))
    roundRect(id, x, y, w, h, 4 * scale, tocolor(r, g, b, a))
    dxDrawRectangle(x + 1, y, w - 2, 1, tocolor(255, 255, 255, hov and 24 or 12))
    dxDrawRectangle(x, y + h - 1, w, 1, tocolor(0, 0, 0, 54))
    if selected then
        dxDrawRectangle(x + 8 * scale, y + h - 4 * scale, w - 16 * scale, 3 * scale, tocolor(TEAL[1], TEAL[2], TEAL[3], 220))
    end
    if num then
        dxDrawText(tostring(num), x + 6 * scale, y + 4 * scale, x + w, y + 20 * scale,
            tocolor(120, 130, 150, 255), 1 * scale, "default-bold", "left", "top")
    end
    -- highlight as a valid drop target while dragging
    if dragging and hov then
        dxDrawRectangle(x, y, w, 2, tocolor(TEAL[1], TEAL[2], TEAL[3], 170))
        dxDrawRectangle(x, y + h - 2, w, 2, tocolor(TEAL[1], TEAL[2], TEAL[3], 170))
        dxDrawRectangle(x, y, 2, h, tocolor(TEAL[1], TEAL[2], TEAL[3], 170))
        dxDrawRectangle(x + w - 2, y, 2, h, tocolor(TEAL[1], TEAL[2], TEAL[3], 170))
    end
    drawItemVisual(entry, x, y, w, h, dimEntry)
    if num and entry and Items[entry.item] then
        dxDrawText(Items[entry.item].label or entry.item, x + 5 * scale, y + h - 38 * scale, x + w - 5 * scale, y + h - 22 * scale,
            tocolor(235, 240, 245, dimEntry and 120 or 240), 0.62 * scale, "default-bold", "center", "center", true)
    end
    if entry and hov and not dragging then
        hoverEntry = { entry = entry, x = x, y = y, w = w, h = h }
    end
    return x, y, w, h
end

local function drawPanel(dx, dy, title, sub, wtxt, iconChar)
    local x, y, w, h = S(dx, dy, PW, PHh)
    local chipText = title == "Envanter" and "user" or title
    local chipW = title == "Envanter" and 92 or 118
    local cx, cy, cw, ch = S(dx, dy, chipW, 48)
    roundRect("p-chip" .. title, cx, cy, cw, ch, 4 * scale, tocolor(58, 61, 64, 182))
    roundRect("p-ico" .. title, cx + 7 * scale, cy + 8 * scale, 32 * scale, 32 * scale, 4 * scale, tocolor(235, 240, 243, 242))
    dxDrawText(iconChar, cx + 7 * scale, cy + 8 * scale, cx + 39 * scale, cy + 40 * scale,
        tocolor(33, 39, 43, 255), 0.98 * scale, "default-bold", "center", "center")
    dxDrawText(chipText, cx + 49 * scale, cy, cx + cw - 10 * scale, cy + ch,
        tocolor(232, 236, 238, 255), 0.95 * scale, "default-bold", "left", "center", true)

    local bx, by, bw, bh = S(dx + w / scale - 256, dy + 8, 256, 40)
    roundRect("p-weight" .. title, bx, by, bw, bh, 4 * scale, tocolor(58, 61, 64, 182))
    roundRect("p-bag" .. title, bx + 10 * scale, by + 4 * scale, 32 * scale, 32 * scale, 4 * scale, tocolor(235, 240, 243, 242))
    dxDrawRectangle(bx + 19 * scale, by + 14 * scale, 14 * scale, 13 * scale, tocolor(33, 39, 43, 230))
    dxDrawRectangle(bx + 22 * scale, by + 10 * scale, 8 * scale, 5 * scale, tocolor(33, 39, 43, 230))
    roundRect("p-barbg" .. title, bx + 56 * scale, by + 9 * scale, 112 * scale, 22 * scale, 4 * scale, tocolor(122, 129, 135, 155))
    dxDrawRectangle(bx + 66 * scale, by + 17 * scale, 92 * scale, 5 * scale, tocolor(49, 53, 57, 188))
    dxDrawText(wtxt, bx + 178 * scale, by, bx + bw - 10 * scale, by + bh,
        tocolor(234, 238, 241, 255), 0.9 * scale, "default-bold", "right", "center", true)
    return x, y, w, h
end

local function drawShell()
    local x, y, w, h = S(0, 0, 1920, 1080)
    dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 22))
end

local function drawHoverCard()
    drawItemPopups()
    if not hoverEntry or not hoverEntry.entry then return end
    local entry = hoverEntry.entry
    local data = Items[entry.item]
    if not data then return end
    local x = hoverEntry.x + hoverEntry.w * 0.12
    local y = hoverEntry.y - 92 * scale
    local w = 166 * scale
    local h = 78 * scale
    if y < 8 * scale then y = hoverEntry.y + hoverEntry.h + 10 * scale end
    roundRect("hovercard", x, y, w, h, 4 * scale, tocolor(13, 15, 16, 202))
    dxDrawRectangle(x, y, w, 1, tocolor(255, 255, 255, 14))
    dxDrawText((entry.count or 1) .. "x", x + 9 * scale, y + 8 * scale, x + 48 * scale, y + 26 * scale,
        tocolor(TEAL[1], TEAL[2], TEAL[3], 255), 0.8 * scale, "default-bold", "left", "top")
    local weightText = data.weapon and ((entry.ammo and entry.ammo > 0) and (entry.ammo .. " mermi") or "Bos") or string.format("%.2fkg", (data.weight or 0) * (entry.count or 1))
    dxDrawText(weightText, x + w - 76 * scale, y + 8 * scale, x + w - 9 * scale, y + 26 * scale,
        tocolor(185, 194, 202, 255), 0.78 * scale, "default-bold", "right", "top")
    dxDrawText(data.label or entry.item, x + 8 * scale, y + 48 * scale, x + w - 8 * scale, y + h - 8 * scale,
        tocolor(238, 242, 245, 255), 0.84 * scale, "default-bold", "center", "center", true)
end


-- Item Action Popup Cards (3. Gorsel - Ekranin alt ortasinda, en altin bir tik ustunde)
local itemPopups = {} -- { { action="Eksildi 2x", item="pistol_ammo", label="Pistol Ammopack", img="2.png", tick=now } }

local function triggerItemPopup(actionText, itemId, count)
    if not itemId then return end
    local data = Items[itemId]
    local label = (data and data.label) or tostring(itemId)
    local img = (data and data.image) or nil
    table.insert(itemPopups, {
        action = actionText,
        item = itemId,
        label = label,
        img = img,
        tick = getTickCount()
    })
    if #itemPopups > 4 then table.remove(itemPopups, 1) end
end

local function drawItemPopups()
    local now = getTickCount()
    local active = {}
    for i = 1, #itemPopups do
        local p = itemPopups[i]
        local age = now - p.tick
        if age <= 3600 then
            table.insert(active, p)
        end
    end
    itemPopups = active
    if #itemPopups == 0 then return end

    local cardW = 142 * scale
    local cardH = 118 * scale
    local gap = 16 * scale
    local totalW = #itemPopups * cardW + (#itemPopups - 1) * gap
    local startX = (sx - totalW) / 2
    local startY = sy - 175 * scale -- Ekranın alt ortası, en altın bir tık üstü

    for i, p in ipairs(itemPopups) do
        local age = now - p.tick
        local alpha = 255
        local offsetY = 0
        if age < 250 then
            local progress = age / 250
            alpha = progress * 255
            offsetY = (1 - progress) * 20 * scale
        elseif age > 3100 then
            local progress = (3600 - age) / 500
            alpha = progress * 255
            offsetY = (1 - progress) * -12 * scale
        end

        local x = startX + (i - 1) * (cardW + gap)
        local y = startY + offsetY

        -- Kart Arka Planı (Yuvarlak koyu kart + hafif kenarlık)
        roundRect("popbg" .. i, x, y, cardW, cardH, 8 * scale, tocolor(20, 24, 30, alpha * 0.95))
        roundRect("popborder" .. i, x - 1, y - 1, cardW + 2, cardH + 2, 8 * scale, tocolor(52, 62, 75, alpha * 0.7))
        roundRect("popbg_inner" .. i, x, y, cardW, cardH, 8 * scale, tocolor(20, 24, 30, alpha * 0.95))

        -- Üst Yazı: Aksiyon (örn: Eksildi 2x, Mermi Yüklendi)
        dxDrawText(p.action, x + 6 * scale, y + 8 * scale, x + cardW - 6 * scale, y + 26 * scale,
            tocolor(240, 245, 250, alpha), 0.88 * scale, "default-bold", "center", "center", true)

        -- Ortada Eşya İkonu
        local isz = 52 * scale
        local ix = x + (cardW - isz) / 2
        local iy = y + (cardH - isz) / 2 - 2 * scale
        local tex = getIcon(p.img)
        if tex then
            dxDrawImage(ix, iy, isz, isz, tex, 0, 0, 0, tocolor(255, 255, 255, alpha))
        else
            dxDrawRectangle(ix, iy, isz, isz, tocolor(40, 48, 58, alpha))
            dxDrawText("?", ix, iy, ix + isz, iy + isz, tocolor(200, 210, 220, alpha), 1 * scale, "default-bold", "center", "center")
        end

        -- Alt Yazı: Eşya Adı (örn: Pistol Ammopack, Glock 19)
        dxDrawText(p.label, x + 4 * scale, y + cardH - 24 * scale, x + cardW - 4 * scale, y + cardH - 6 * scale,
            tocolor(200, 210, 220, alpha * 0.95), 0.82 * scale, "default-bold", "center", "center", true)
    end
end

addEventHandler("onClientRender", root, function()
    hoverEntry = nil
    -- notifs left center
    local ny = sy * 0.45
    local now = getTickCount()
    for i = #notifs, 1, -1 do
        local n = notifs[i]
        if now - n.tick > 3500 then table.remove(notifs, i)
        else
            local a = 255
            local age = now - n.tick
            if age < 200 then a = age / 200 * 255 elseif age > 3100 then a = (3500 - age) / 400 * 255 end
            local col = TEAL
            if n.t == "error" then col = { 220, 70, 70 } elseif n.t == "success" then col = { 70, 200, 130 } end
            local tw = dxGetTextWidth(n.m, 1, "default") + 24 * scale
            local nx = 16 * scale
            roundRect("n" .. i, nx, ny, tw, 32 * scale, 8 * scale, tocolor(14, 16, 22, a * 0.9))
            dxDrawRectangle(nx, ny, 3 * scale, 32 * scale, tocolor(col[1], col[2], col[3], a))
            dxDrawText(n.m, nx + 12 * scale, ny, nx + tw, ny + 32 * scale, tocolor(240, 245, 250, a), 1, "default", "left", "center")
            ny = ny + 40 * scale
        end
    end

    if showHB and not open then
        local total = 5 * HUD_HS + 4 * 10
        local x0 = (BW - total) / 2
        for i = 1, 5 do
            local slotX = x0 + (i - 1) * (HUD_HS + 10)
            local slotY = 960
            local entry = hb[i]
            local hasWeapon = entry and Items[entry.item] and Items[entry.item].weapon
            local x, y, w, h = S(slotX, slotY, HUD_HS, HUD_HS)

            -- Kart arkaplanı ve mor çerçeve (Görsel 2)
            roundRect("hud_hb_bg" .. i, x, y, w, h, 6 * scale, tocolor(22, 26, 32, 235))
            if hasWeapon or (entry and entry.item) then
                roundRect("hud_hb_border" .. i, x - 1, y - 1, w + 2, h + 2, 6 * scale, tocolor(150, 60, 200, 210))
                roundRect("hud_hb_bg2" .. i, x, y, w, h, 6 * scale, tocolor(22, 26, 32, 235))
                -- Cyan alt çizgi
                dxDrawRectangle(x + 6 * scale, y + h - 3 * scale, w - 12 * scale, 2.5 * scale, tocolor(6, 182, 212, 240))
            else
                roundRect("hud_hb_border" .. i, x - 1, y - 1, w + 2, h + 2, 6 * scale, tocolor(48, 55, 66, 180))
                roundRect("hud_hb_bg2" .. i, x, y, w, h, 6 * scale, tocolor(22, 26, 32, 235))
            end

            -- Slot numarası (1, 2, 3, 4, 5) sol üstte
            dxDrawText(tostring(i), x + 6 * scale, y + 4 * scale, x + w, y + 20 * scale,
                tocolor(160, 172, 186, 255), 0.9 * scale, "default-bold", "left", "top")

            if entry and entry.item then
                drawItemVisual(entry, x, y, w, h, false)
                -- Miktar sol altta (mor)
                local countStr = entry.count and (entry.count .. "x") or "1x"
                dxDrawText(countStr, x + 6 * scale, y + h - 16 * scale, x + w, y + h - 4 * scale,
                    tocolor(168, 85, 247, 255), 0.72 * scale, "default-bold", "left", "bottom")
                -- Ağırlık sağ altta
                local itmData = Items[entry.item]
                local weightStr = itmData and string.format("%.2fkg", (itmData.weight or 0.1) * (entry.count or 1)) or ""
                dxDrawText(weightStr, x, y + h - 16 * scale, x + w - 6 * scale, y + h - 4 * scale,
                    tocolor(150, 160, 175, 255), 0.72 * scale, "default-bold", "right", "bottom")
            end
        end
    end

    if not open then
        nearestDrop = nil
        local px, py, pz = getElementPosition(localPlayer)
        local bestD = Config.PickupDistance
        for _, e in ipairs(dropObjs) do
            if isElement(e.obj) then
                local ox, oy, oz = getElementPosition(e.obj)
                local d = getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz)
                if d < 12 then
                    local sxp, syp = getScreenFromWorldPosition(ox, oy, oz + 0.55, 0.35)
                    if sxp then
                        local data = Items[e.item]
                        local label = data and data.label or e.item
                        local icon = data and getIcon(data.image)
                        local isz = 34 * scale
                        local bx, by = sxp - isz / 2, syp - isz - 20 * scale
                        roundRect("dropicon" .. tostring(e.obj), bx - 8 * scale, by - 6 * scale, isz + 16 * scale, isz + 28 * scale, 8 * scale, tocolor(10, 12, 16, 190))
                        if icon then
                            dxDrawImage(bx, by, isz, isz, icon)
                        else
                            dxDrawText("?", bx, by, bx + isz, by + isz, tocolor(200, 205, 215, 255), 1, "default-bold", "center", "center")
                        end
                        local ltxt = label .. (e.count > 1 and (" x" .. e.count) or "")
                        dxDrawText(ltxt, bx - 40 * scale, by + isz + 2 * scale, bx + isz + 40 * scale, by + isz + 20 * scale,
                            tocolor(220, 225, 235, 230), 0.75 * scale, "default", "center", "top")
                    end
                end
                if d <= bestD then
                    bestD = d
                    nearestDrop = e
                end
            end
        end
        if nearestDrop then
            local ox, oy, oz = getElementPosition(nearestDrop.obj)
            local sxp, syp = getScreenFromWorldPosition(ox, oy, oz + 1.0, 0.35)
            if sxp then
                local data = Items[nearestDrop.item]
                local label = data and data.label or nearestDrop.item
                local ptxt = "[E] Al - " .. label .. (nearestDrop.count > 1 and (" x" .. nearestDrop.count) or "")
                local tw = dxGetTextWidth(ptxt, 1 * scale, "default-bold") + 24 * scale
                roundRect("pickprompt", sxp - tw / 2, syp - 50 * scale, tw, 30 * scale, 8 * scale, tocolor(20, 55, 55, 225))
                dxDrawText(ptxt, sxp - tw / 2, syp - 50 * scale, sxp + tw / 2, syp - 20 * scale,
                    tocolor(TEAL[1], TEAL[2], TEAL[3], 255), 1 * scale, "default-bold", "center", "center")
            end
        end
        if nearestDepot and isElement(nearestDepot) then
            local dx, dy, dz = getElementPosition(nearestDepot)
            local sxp, syp = getScreenFromWorldPosition(dx, dy, dz + 1.4, 0.35)
            if sxp then
                local name = getElementData(nearestDepot, "inv:depot") or "Depo"
                dxDrawText("[E] " .. tostring(name), sxp - 120 * scale, syp - 18 * scale, sxp + 120 * scale, syp + 12 * scale,
                    tocolor(TEAL[1], TEAL[2], TEAL[3], 240), 0.9 * scale, "default-bold", "center", "center")
            end
        end
    end

    if not open then return end

    -- Reference style: keep the live game view behind the UI, then darken/desaturate it.
    dxDrawRectangle(0, 0, sx, sy, tocolor(20, 24, 29, 116))
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 86))
    dxDrawRectangle(0, 0, sx, sy * 0.5, tocolor(34, 39, 45, 72))
    dxDrawRectangle(0, sy * 0.5, sx, sy * 0.5, tocolor(18, 16, 12, 46))

    drawShell()

    -- LEFT panel (hotbar is rendered in the center below)
    drawPanel(LPX, LPY, "Envanter", "", string.format("%.0f/%.0f kg", weight, Config.MaxWeight), "U")
    hits.inv = {}
    hits.hb = {}
    hits.world = {}
    for i = 1, Config.InventorySlots do
        local visualSlot = i
        local ix, iy = invXY(visualSlot)
        local selected = sel and sel.t == "inv" and sel.s == i
        local dimEntry = dragging and dragging.t == "inv" and dragging.s == i
        local x, y, w, h = drawSlot("is" .. i, ix, iy, SLOT, inv[i], nil, selected, dimEntry)
        hits.inv[i] = { x = x, y = y, w = w, h = h }
    end

    -- RIGHT panel
    drawPanel(RPX, LPY, depotMode and activeDepotName or "Dunya", "", "0/120 kg", "D")
    for i = 1, Config.WorldSlots do
        local ix, iy = wrdXY(i)
        local x, y, w, h = drawSlot("ws" .. i, ix, iy, SLOT, depotMode and depotContents[i] or nil, nil, false, dragging ~= nil)
        hits.world[i] = { x = x, y = y, w = w, h = h }
    end

    -- CENTER controls
    local cx = (LPX + PW + RPX) / 2
    local cy = LPY + PHh / 2

    -- Five-slot hotbar sits directly under the left inventory panel.
    local hbTotal = 5 * HS + 4 * 8
    local hbx0 = LPX
    for i = 1, 5 do
        local x, y, w, h = drawSlot("bottom_hb" .. i, hbx0 + (i - 1) * (HS + 8), LPY + PHh + 28, HS, hb[i], i, sel and sel.t == "hb" and sel.s == i, dragging and dragging.t == "hb" and dragging.s == i)
        hits.hb[i] = { x = x, y = y, w = w, h = h }
    end

    local qx, qy, qw, qh = S(cx - 55, cy - 112, 110, 45)
    roundRect("qty", qx, qy, qw, qh, 4 * scale, tocolor(7, 8, 10, 218))
    dxDrawRectangle(qx, qy, qw, 1, tocolor(255, 255, 255, 14))
    dxDrawText(tostring(qty), qx, qy, qx + qw, qy + qh, tocolor(235, 238, 242, 255), 1.08 * scale, "default-bold", "center", "center")

    local ux, uy, uw, uh = S(cx - 32, cy - 18, 64, 64)
    local uhov = mouseIn(ux, uy, uw, uh)
    roundRect("use", ux, uy, uw, uh, 6 * scale, tocolor(8, 9, 11, uhov and 236 or 214))
    dxDrawText("H", ux, uy + 3 * scale, ux + uw, uy + uh, tocolor(TEAL[1], TEAL[2], TEAL[3], 255), 1.25 * scale, "default-bold", "center", "center")
    hits.btn.use = { x = ux, y = uy, w = uw, h = uh }

    local vx, vy, vw, vh = S(cx - 32, cy + 78, 64, 64)
    local vhov = mouseIn(vx, vy, vw, vh)
    roundRect("give", vx, vy, vw, vh, 6 * scale, tocolor(8, 9, 11, vhov and 236 or 214))
    dxDrawText("<>", vx, vy + 2 * scale, vx + vw, vy + vh, tocolor(126, 143, 255, 255), 1.18 * scale, "default-bold", "center", "center")
    hits.btn.give = { x = vx, y = vy, w = vw, h = vh }

    local xx, xy, xw, xh = S(cx - 32, cy + 158, 64, 64)
    local xhov = mouseIn(xx, xy, xw, xh)
    roundRect("close", xx, xy, xw, xh, 6 * scale, tocolor(8, 9, 11, xhov and 236 or 214))
    dxDrawText("X", xx, xy, xx + xw, xy + xh, tocolor(128, 138, 145, 255), 1.35 * scale, "default", "center", "center")
    hits.btn.close = { x = xx, y = xy, w = xw, h = xh }

    -- Drop zone is kept subtle; click/drag still works without visible text.
    local dx1, dy1, dw1, dh1 = S(cx - 80, cy + 238, 160, 58)
    roundRect("dropz", dx1, dy1, dw1, dh1, 4 * scale, tocolor(7, 8, 10, 92))
    dxDrawText("DROP", dx1, dy1, dx1 + dw1, dy1 + dh1, tocolor(95, 104, 110, 150), 0.76 * scale, "default-bold", "center", "center")
    hits.btn.dropzone = { x = dx1, y = dy1, w = dw1, h = dh1 }

    -- Drag start detection (once mouse moves past threshold while held on a slot)
    if mouseHeld and dragCandidate and not dragging then
        local cx, cy = getCursorPosition()
        if cx then
            cx, cy = cx * sx, cy * sy
            local ddx, ddy = cx - dragCandidate.x, cy - dragCandidate.y
            if (ddx * ddx + ddy * ddy) > (DRAG_THRESHOLD * DRAG_THRESHOLD) then
                dragging = dragCandidate
            end
        end
    end

    -- Floating dragged item ghost, follows cursor, drawn last so it's on top
    if dragging then
        local cx, cy = getCursorPosition()
        if cx then
            cx, cy = cx * sx, cy * sy
            local gs = SLOT * scale * 0.9
            local gx, gy = cx - gs / 2, cy - gs / 2
            roundRect("dragghost", gx, gy, gs, gs, 12 * scale, tocolor(20, 55, 55, 210))
            dxDrawRectangle(gx, gy, gs, 2, tocolor(TEAL[1], TEAL[2], TEAL[3], 230))
            dxDrawRectangle(gx, gy + gs - 2, gs, 2, tocolor(TEAL[1], TEAL[2], TEAL[3], 230))
            dxDrawRectangle(gx, gy, 2, gs, tocolor(TEAL[1], TEAL[2], TEAL[3], 230))
            dxDrawRectangle(gx + gs - 2, gy, 2, gs, tocolor(TEAL[1], TEAL[2], TEAL[3], 230))
            drawItemVisual(dragging.entry, gx, gy, gs, gs, false)
        end
    end
    drawHoverCard()
    drawItemPopups()
end)

local lastC, lastS = 0, 0

local function endDrag()
    -- Called on mouse-up: if a real drag happened, drop onto whatever is under the cursor
    if dragging then
        local cx, cy = getCursorPosition()
        if cx then
            cx, cy = cx * sx, cy * sy
            local from = dragging

            for i, h in pairs(hits.inv or {}) do
                if from.t ~= "world" and cx >= h.x and cx <= h.x + h.w and cy >= h.y and cy <= h.y + h.h then
                    if not (from.t == "inv" and from.s == i) then
                        triggerServerEvent("inv:move", localPlayer, from.t == "hb" and "hotbar" or "inv", from.s, "inv", i, from.entry.count or 1)
                    end
                    dragging, dragCandidate, mouseHeld = nil, nil, false
                    return
                end
            end
            if from.t == "world" and depotMode and isElement(activeDepot) then
                for i, h in pairs(hits.inv or {}) do
                    if cx >= h.x and cx <= h.x + h.w and cy >= h.y and cy <= h.y + h.h then
                        triggerServerEvent("inv:depotTake", localPlayer, activeDepot, from.s, from.entry.count or 1)
                        dragging, dragCandidate, mouseHeld = nil, nil, false
                        return
                    end
                end
            end
            for i, h in pairs(hits.hb or {}) do
                if cx >= h.x and cx <= h.x + h.w and cy >= h.y and cy <= h.y + h.h then
                    if not (from.t == "hb" and from.s == i) then
                        triggerServerEvent("inv:move", localPlayer, from.t == "hb" and "hotbar" or "inv", from.s, "hotbar", i, from.entry.count or 1)
                        notify("Hotbara tasindi", "success")
                    end
                    dragging, dragCandidate, mouseHeld = nil, nil, false
                    return
                end
            end
            -- Dropping onto any World slot creates a ground pickup.
            if from.t == "inv" then
                for _, h in pairs(hits.world or {}) do
                    if cx >= h.x and cx <= h.x + h.w and cy >= h.y and cy <= h.y + h.h then
                        if depotMode and isElement(activeDepot) then
                            triggerServerEvent("inv:depotStore", localPlayer, activeDepot, from.s, from.entry.count or 1)
                        else
                            triggerServerEvent("inv:drop", localPlayer, from.s, from.entry.count or 1)
                        end
                        notify("Item dünyaya bırakıldı", "success")
                        dragging, dragCandidate, mouseHeld = nil, nil, false
                        return
                    end
                end
            end
            local dz = hits.btn.dropzone
            if dz and from.t == "inv" and cx >= dz.x and cx <= dz.x + dz.w and cy >= dz.y and cy <= dz.y + dz.h then
                triggerServerEvent("inv:drop", localPlayer, from.s, from.entry.count or 1)
                dragging, dragCandidate, mouseHeld = nil, nil, false
                return
            end
        end
    end
    dragging, dragCandidate, mouseHeld = nil, nil, false
end

addEventHandler("onClientClick", root, function(btn, state)
    if not open or btn ~= "left" then return end

    if state == "up" then
        endDrag()
        return
    end
    if state ~= "down" then return end

    -- inv slots
    for i, h in pairs(hits.inv or {}) do
        if mouseIn(h.x, h.y, h.w, h.h) then
            if inv[i] then
                local now = getTickCount()
                if lastS == i and now - lastC < 350 then
                    triggerServerEvent("inv:use", localPlayer, i, false)
                    lastC = 0
                else
                    sel = { t = "inv", s = i }
                    lastC, lastS = now, i
                end
                mouseHeld = true
                dragCandidate = { t = "inv", s = i, entry = inv[i], x = h.x + h.w / 2, y = h.y + h.h / 2 }
            else
                sel = nil
            end
            return
        end
    end

    -- hotbar
    for i, h in pairs(hits.hb or {}) do
        if mouseIn(h.x, h.y, h.w, h.h) then
            if sel and sel.t == "inv" and inv[sel.s] then
                triggerServerEvent("inv:move", localPlayer, "inv", sel.s, "hotbar", i, inv[sel.s].count or 1)
                notify("Hotbara tasindi", "success")
                sel = nil
            elseif hb[i] then
                sel = { t = "hb", s = i }
                mouseHeld = true
                dragCandidate = { t = "hb", s = i, entry = hb[i], x = h.x + h.w / 2, y = h.y + h.h / 2 }
            end
            return
        end
    end

    -- depot contents can be dragged back into the inventory
    if depotMode then
        for i, h in pairs(hits.world or {}) do
            if mouseIn(h.x, h.y, h.w, h.h) and depotContents[i] then
                mouseHeld = true
                dragCandidate = { t = "world", s = i, entry = depotContents[i], x = h.x + h.w / 2, y = h.y + h.h / 2 }
                return
            end
        end
    end

    -- buttons
    if hits.btn.use and mouseIn(hits.btn.use.x, hits.btn.use.y, hits.btn.use.w, hits.btn.use.h) then
        if sel then triggerServerEvent("inv:use", localPlayer, sel.s, sel.t == "hb") end
        return
    end
    if hits.btn.give and mouseIn(hits.btn.give.x, hits.btn.give.y, hits.btn.give.w, hits.btn.give.h) then
        if sel and sel.t == "inv" then
            local nearest, nd = nil, Config.GiveDistance
            local px, py, pz = getElementPosition(localPlayer)
            for _, p in ipairs(getElementsByType("player")) do
                if p ~= localPlayer then
                    local x, y, z = getElementPosition(p)
                    local d = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
                    if d < nd then nearest, nd = p, d end
                end
            end
            if nearest then triggerServerEvent("inv:giveTo", localPlayer, nearest, sel.s, qty)
            else notify("Yakinda oyuncu yok", "error") end
        end
        return
    end
    if hits.btn.close and mouseIn(hits.btn.close.x, hits.btn.close.y, hits.btn.close.w, hits.btn.close.h) then
        closeUI()
        return
    end
    if hits.btn.dropzone and mouseIn(hits.btn.dropzone.x, hits.btn.dropzone.y, hits.btn.dropzone.w, hits.btn.dropzone.h) then
        if sel and sel.t == "inv" then
            triggerServerEvent("inv:drop", localPlayer, sel.s, qty)
        end
        return
    end
end)

addEvent("inv:sync", true)
addEventHandler("inv:sync", root, function(i, h, w)
    inv = i or {}
    hb = h or {}
    weight = w or 0
end)

addEvent("inv:toggle", true)
addEventHandler("inv:toggle", root, function() if open then closeUI() else openUI() end end)
addEvent("inv:open", true)
addEventHandler("inv:open", root, openUI)
addEvent("inv:close", true)
addEventHandler("inv:close", root, closeUI)
addEvent("inv:openDepot", true)
addEventHandler("inv:openDepot", root, function(name, obj, contents)
    depotMode = true
    activeDepotName = tostring(name or "Depo")
    activeDepot = obj
    depotContents = contents or {}
    openUI()
end)
addEvent("inv:depotSync", true)
addEventHandler("inv:depotSync", root, function(contents)
    depotContents = contents or {}
end)
-- original hook replaced
-- addEvent("inv:notify", true)
addEventHandler("inv:notify", root, function(m, t) notify(m, t) end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    R()
    applyWeaponWheelLock()
    setTimer(function() triggerServerEvent("inv:requestSync", localPlayer) end, 500, 1)
    outputChatBox("#2dc8b4[Envanter] #ffffffF2 ac/kapat | Item sec + hotbara tikla veya 1-5 | /items", 255, 255, 255, true)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
    showChat(true)
    for _, name in ipairs(HUD_COMPONENTS) do
        showPlayerHudComponent(name, true)
    end
    toggleControl("next_weapon", true)
    toggleControl("previous_weapon", true)
end)

addEvent("inv:notify", true)
addEventHandler("inv:notify", root, function(msg, typ, itemId, count)
    notify(msg, typ)
    if itemId then
        triggerItemPopup(msg, itemId, count or 1)
    else
        for k, d in pairs(Items or {}) do
            if string.find(string.lower(msg), string.lower(d.label or k)) then
                triggerItemPopup(msg, k, 1)
                break
            end
        end
    end
end)