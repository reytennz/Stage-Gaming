--[[
    stage_admin - F3 report paneli (native DX)
]]

local sw, sh = guiGetScreenSize()
local open = false
local selectedReason = nil

local W, H = 420, 340
local X, Y = (sw - W) / 2, (sh - H) / 2

function toggle(state)
    open = state
    showCursor(open)
    toggleAllControls(not open)
    AdminUIOpen = open
    if open then
        selectedReason = nil
        DX.setInput("report_desc", "")
    else
        DX.focused = nil
    end
end

bindKey(Config.ReportKey, "down", function()
    toggle(not open)
end)

addEventHandler("onClientRender", root, function()
    if not open then return end
    DX.beginFrame()

    local ok, err = pcall(function()
        DX.panel(X, Y, W, H, DX.C.bg)
        DX.border(X, Y, W, H, DX.C.border, 2)
        DX.panel(X, Y, W, 40, DX.C.panel)
        DX.text("Şikayet / Report Oluştur", X + 14, Y, W - 60, 40, DX.C.accent, 1, "left", "center")
        DX.button("report_close", X + W - 34, Y + 6, 28, 28, "X", function() toggle(false) end, DX.C.danger)

        DX.text("Sebep seçin:", X + 14, Y + 50, 300, 18, DX.C.textDim, 0.8, "left", "center")

        local bh, gap = 26, 6
        local col = 2
        local btnW = (W - 28 - gap) / col
        for i, reason in ipairs(Config.ReportReasons) do
            local ci = (i - 1) % col
            local ri = math.floor((i - 1) / col)
            local bx = X + 14 + ci * (btnW + gap)
            local by = Y + 72 + ri * (bh + gap)
            DX.button("report_reason_" .. i, bx, by, btnW, bh, reason, function()
                selectedReason = reason
            end, selectedReason == reason and DX.C.accent or DX.C.border)
        end

        local descY = Y + 72 + math.ceil(#Config.ReportReasons / col) * (bh + gap) + 10
        DX.text("Açıklama:", X + 14, descY, 300, 16, DX.C.textDim, 0.8, "left", "center")
        DX.textInput("report_desc", X + 14, descY + 18, W - 28, 60, "Açıklama yazın (opsiyonel)...")

        
        DX.button("report_cancel", X + 14, descY + 126, W - 28, 26, "Mevcut Raporumu Geri Çek", function()
            triggerServerEvent("admin:cancelReport", localPlayer)
            toggle(false)
        end, DX.C.danger)

        DX.button("report_send", X + 14, descY + 90, W - 28, 30, "Gönder", function()
            if not selectedReason then
                triggerEvent("admin:notify", localPlayer, "Lütfen bir sebep seçin.", "error")
                return
            end
            triggerServerEvent("admin:submitReport", localPlayer, selectedReason, DX.getInput("report_desc"))
            toggle(false)
        end, DX.C.success)
    end)

    if not ok then
        dxDrawRectangle(X, Y, W, 120, tocolor(20, 10, 10, 245))
        dxDrawText("REPORT PANEL - HATA:", X + 10, Y + 10, X + W - 10, Y + 30, tocolor(255,100,100,255), 0.9, "default-bold", "left", "top")
        dxDrawText(tostring(err), X + 10, Y + 34, X + W - 10, Y + 116, tocolor(255,220,220,255), 0.85, "default", "left", "top", false, true)
    end
end)
