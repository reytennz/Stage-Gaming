--[[
    stage_admin - oyuncu araç kayıtları
    Adminlerin oyunculara verdiği araçlar ve F1 garaj araçları MySQL'de tutulur.
]]

function AdminRegisterVehicle(player, veh, adminName)
    if not isElement(player) or not isElement(veh) then return end
    local serial = getPlayerSerial(player)
    if not serial or serial == "" then return end

    local model = getElementModel(veh)
    AdminDBExec(
        "INSERT INTO admin_player_vehicles (owner_serial, owner_name, model, model_name, plate, given_by, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        serial,
        getPlayerName(player),
        model,
        getVehicleNameFromModel(model) or "?",
        getVehiclePlateText(veh) or "",
        adminName or "?",
        getRealTime().timestamp
    )
end

function AdminGetPlayerVehicles(serial)
    if not serial or serial == "" then return {} end
    local res = {}

    -- 1. F1 Garaj tablosundan araçlar (f1_garage_vehicles)
    local garageRows = AdminDBQuery(
        "SELECT id, model, name as model_name, plate, 'Garaj' as given_by FROM f1_garage_vehicles WHERE player_serial = ? ORDER BY id DESC LIMIT 30",
        serial
    )
    if garageRows and #garageRows > 0 then
        for _, r in ipairs(garageRows) do
            local m = tonumber(r.model) or 400
            table.insert(res, {
                model = m,
                model_name = (r.model_name and r.model_name ~= "") and r.model_name or (getVehicleNameFromModel(m) or tostring(m)),
                plate = (r.plate and r.plate ~= "") and r.plate or "-",
                given_by = "F1 Garaj",
                created_at = os and os.time and os.time() or 0
            })
        end
    end

    -- 2. Admin tarafından verilen araç kayıtları (admin_player_vehicles)
    local adminRows = AdminDBQuery(
        "SELECT model, model_name, plate, given_by, created_at FROM admin_player_vehicles WHERE owner_serial = ? ORDER BY id DESC LIMIT 30",
        serial
    )
    if adminRows and #adminRows > 0 then
        for _, r in ipairs(adminRows) do
            local m = tonumber(r.model) or 400
            table.insert(res, {
                model = m,
                model_name = (r.model_name and r.model_name ~= "") and r.model_name or (getVehicleNameFromModel(m) or tostring(m)),
                plate = (r.plate and r.plate ~= "") and r.plate or "-",
                given_by = r.given_by or "Admin",
                created_at = tonumber(r.created_at) or 0
            })
        end
    end

    -- 3. Oyuncunun dünyadaki aktif sürdüğü araç
    for _, p in ipairs(getElementsByType("player")) do
        if getPlayerSerial(p) == serial then
            local liveVeh = getPedOccupiedVehicle(p)
            if isElement(liveVeh) then
                local m = getElementModel(liveVeh)
                table.insert(res, 1, {
                    model = m,
                    model_name = (getVehicleNameFromModel(m) or "Araç") .. " (Aktif Sürüş)",
                    plate = getVehiclePlateText(liveVeh) or "-",
                    given_by = "Canlı Sürüş",
                    created_at = getRealTime().timestamp
                })
            end
            break
        end
    end

    return res
end
