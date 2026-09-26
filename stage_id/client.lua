-- stage_id | client
local screenW, screenH = guiGetScreenSize()

addEventHandler("onClientRender", root, function()
    if not CONFIG.BAS_USTU_GOSTER then return end
    local cx, cy, cz = getCameraMatrix()
    for _, p in ipairs(getElementsByType("player")) do
        if p ~= localPlayer and isElementStreamedIn(p) then
            local id = getElementData(p, "playerid")
            if id then
                local x, y, z = getPedBonePosition(p, 8)
                z = z + 0.35
                local dist = getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
                if dist <= CONFIG.MAX_MESAFE then
                    local sx, sy = getScreenFromWorldPosition(x, y, z)
                    if sx then
                        local scale = math.max(0.6, 1.4 - dist / CONFIG.MAX_MESAFE)
                        dxDrawText("#" .. id, sx + 1, sy + 1, sx, sy, CONFIG.YAZI_CERCEVE, scale, "default-bold", "center", "center")
                        dxDrawText("#" .. id, sx, sy, sx, sy, CONFIG.YAZI_RENK, scale, "default-bold", "center", "center")
                    end
                end
            end
        end
    end
end)
