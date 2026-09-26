--[[
    stage_admin - bildirim / duyuru UI
]]

local toasts = {}   -- { text, type, expire }
local announces = {} -- { title, message, color, expire, y }

local sw, sh = guiGetScreenSize()

local typeColors = {
    success = { 90, 220, 140 },
    error   = { 240, 90, 90 },
    warning = { 240, 190, 80 },
    info    = { 90, 170, 240 },
}

addEvent("admin:notify", true)
addEventHandler("admin:notify", localPlayer, function(message, msgType)
    pcall(function()
        if exports.stage_core and exports.stage_core.Notify then
            exports.stage_core:Notify(message, msgType or "info")
        else
            triggerEvent("stage_core:notify", localPlayer, message, msgType or "info")
        end
    end)
end)

addEvent("admin:announce", true)
addEventHandler("admin:announce", localPlayer, function(annType, label, message, color, durationMs)
    if #announces >= 4 then
        table.remove(announces, 1)
    end
    local dur = tonumber(durationMs) or 7000
    if dur < 2000 then dur = 2000 end
    if dur > 60000 then dur = 60000 end
    announces[#announces+1] = {
        label = label, message = message, color = color or {90,160,255},
        startTick = getTickCount(), duration = dur,
    }
    playSoundFrontEnd(43)
end)

addEventHandler("onClientRender", root, function()
    local now = getTickCount()
    -- Announce banner (üst orta) — slide-in + fade, ikon şeridi, gölgeli kart
    local ay = 50
    for i = #announces, 1, -1 do
        local a = announces[i]
        local elapsed = now - a.startTick
        if elapsed > a.duration then
            table.remove(announces, i)
        else
            local c = a.color
            local w, h = 480, 60

            -- giriş animasyonu (ilk 250ms yukarıdan kayarak + fade in), son 400ms fade out
            local slide = math.min(1, elapsed / 250)
            local fadeOut = 1
            if elapsed > a.duration - 400 then
                fadeOut = math.max(0, (a.duration - elapsed) / 400)
            end
            local alpha = math.floor(255 * slide * fadeOut)
            local offsetY = (1 - slide) * -20

            local x = (sw - w) / 2
            local y = ay + offsetY

            -- gölge
            dxDrawRectangle(x + 3, y + 4, w, h, tocolor(0, 0, 0, math.floor(alpha * 0.35)))
            -- ana kart
            dxDrawRectangle(x, y, w, h, tocolor(14, 15, 19, math.floor(alpha * 0.94)))
            -- sol renk şeridi
            dxDrawRectangle(x, y, 5, h, tocolor(c[1], c[2], c[3], alpha))
            -- ince alt çizgi
            dxDrawRectangle(x, y + h - 2, w, 2, tocolor(c[1], c[2], c[3], math.floor(alpha * 0.5)))

            dxDrawText(a.label, x + 20, y + 8, x + w - 12, y + 28, tocolor(c[1], c[2], c[3], alpha), 1.05, "default-bold", "left", "top")
            dxDrawText(a.message, x + 20, y + 28, x + w - 12, y + h - 6, tocolor(225, 225, 230, alpha), 0.9, "default", "left", "top", false, true)

            ay = ay + h + 10
        end
    end
end)
