--[[
    stage_admin - shared utils
]]

function AdminFormatDuration(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return "Süresiz" end

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local mins = math.floor(seconds / 60)

    local parts = {}
    if days > 0 then parts[#parts+1] = days .. "g" end
    if hours > 0 then parts[#parts+1] = hours .. "s" end
    if mins > 0 then parts[#parts+1] = mins .. "d" end
    if #parts == 0 then parts[#parts+1] = "1d" end
    return table.concat(parts, " ")
end

function AdminSafeTostring(v)
    if v == nil then return "" end
    return tostring(v)
end

function AdminTrim(s)
    if type(s) ~= "string" then return "" end
    return s:match("^%s*(.-)%s*$")
end
