-- stage_core - oyuncu etiketi
local MAX_DISTANCE = 25

addEventHandler("onClientRender", root, function()
    local cx, cy, cz = getCameraMatrix()

    for _, player in ipairs(getElementsByType("player")) do
        if isElementStreamedIn(player) then
            local tag = getElementData(player, "stage:tag")
            if tag and tag ~= "" then
                local x, y, z = getPedBonePosition(player, 8)
                z = z + 0.55
                local dist = getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)

                if dist <= MAX_DISTANCE then
                    local sx, sy = getScreenFromWorldPosition(x, y, z)
                    if sx and sy then
                        local scale = math.max(0.65, 1.15 - dist / MAX_DISTANCE)
                        dxDrawText(
                            tostring(tag),
                            sx + 1, sy + 1, sx + 1, sy + 1,
                            tocolor(0,0,0,210), scale, "default-bold",
                            "center", "center"
                        )
                        dxDrawText(
                            tostring(tag),
                            sx, sy, sx, sy,
                            tocolor(255,215,80,255), scale, "default-bold",
                            "center", "center"
                        )
                    end
                end
            end
        end
    end
end)
