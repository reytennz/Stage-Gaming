local rounded = {};
function dxDrawRoundedRectangle(id,x, y, w, h, radius, color, post)
    if not rounded[id] then
        rounded[id] = {}
    end
    if not rounded[id][w] then
        rounded[id][w] = {}
    end
    if not rounded[id][w][h] then
        local path = string.format([[<svg width="%s" height="%s" viewBox="0 0 %s %s" fill="none" xmlns="http://www.w3.org/2000/svg"><rect opacity="1" width="%s" height="%s" rx="%s" fill="#FFFFFF"/></svg>]], w, h, w, h, w, h, radius)
        rounded[id][w][h] = svgCreate(w, h, path)
    end
    if rounded[id][w][h] then
        dxDrawImage(x, y, w, h, rounded[id][w][h], 0, 0, 0, color, (post or false))
    end
end

local gradients = {}

function rgbToString(color)
    return table.concat({color[1], color[2], color[3]}, ",")
end

function drawRoundedGradientRectangle(x, y, w, h, array,alpha,postgui)
    local alpha = alpha or 255
    local key = string.format("%d%d%d%d%d%d%s%s%d", w, h, array.radius, array.radius, array.offset.x, array.offset.y, rgbToString(array.color.color1), rgbToString(array.color.color2), array.rotation)
    if not gradients[key] then
        local svgData = string.format([[
            <svg width="%d" height="%d" xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <linearGradient id="grad1" x1="0%%" x2="100%%" y1="0%%" y2="0%%" gradientTransform="rotate(%d)">
                        <stop offset="%d%%" stop-color="rgb(%s)" />
                        <stop offset="%d%%" stop-color="rgb(%s)" />
                    </linearGradient>
                </defs>
                <rect width="%d" height="%d" rx="%d" ry="%d" fill="url(#grad1)" />
            </svg>
        ]], w, h, array.rotation, array.offset.x, rgbToString(array.color.color1), array.offset.y, rgbToString(array.color.color2), w, h, array.radius, array.radius)
        
        gradients[key] = svgCreate(w, h, svgData)
    end
    return dxDrawImage(x, y, w, h, gradients[key], 0, 0, 0, tocolor(255, 255, 255, alpha), postgui or false)
end

function isMouseInPosition ( x, y, width, height )
    if ( not isCursorShowing( ) ) then
        return false
    end
    local sx, sy = guiGetScreenSize ( )
    local cx, cy = getCursorPosition ( )
    local cx, cy = ( cx * sx ), ( cy * sy )
    
    return ( ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) )
end

function hex2rgb(hex) 
    hex = hex:gsub("#","") 
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)) 
  end 

function formatMoney(amount)
	local left,num,right = string.match(tostring(amount),'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end
