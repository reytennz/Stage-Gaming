--[[
    stage_core - Admin kontrolü
    ACL + adminlevel elementData (F1 uyumluluğu)
]]

function IsACLAdmin(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    local ok, result = pcall(function()
        local accName = GetAccountName(player)
        if not accName then return false end

        local groups = (CoreConfig and CoreConfig.AdminACL) or { "Admin", "Console" }
        for _, groupName in ipairs(groups) do
            local group = aclGetGroup(groupName)
            if group and isObjectInACLGroup("user." .. accName, group) then
                return true
            end
        end

        -- Eski benzinlik uyumluluğu
        if hasObjectPermissionTo(player, "command.benzinlikler", false) then
            return true
        end

        return false
    end)

    return ok and result == true
end

function IsAdmin(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    if IsACLAdmin(player) then
        return true
    end

    -- F1 / diğer sistemler: adminlevel elementData
    local level = tonumber(getElementData(player, "adminlevel")) or 0
    local minLevel = (CoreConfig and CoreConfig.MinAdminLevel) or 1
    if level >= minLevel then
        return true
    end

    return false
end
