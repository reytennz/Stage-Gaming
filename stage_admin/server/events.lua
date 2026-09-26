--[[
    stage_admin - etkinlik sistemi
]]

function AdminCreateEvent(admin, name, description, reward, startsAt, endsAt, capacity)
    name = AdminTrim(name)
    if name == "" then return false end

    AdminDBExec(
        "INSERT INTO admin_events (name, description, reward, starts_at, ends_at, capacity, created_by, active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)",
        name, AdminTrim(description), AdminTrim(reward), tonumber(startsAt) or 0, tonumber(endsAt) or 0,
        tonumber(capacity) or 0, getPlayerName(admin)
    )

    AdminLog(admin, "-", "event_create", name)

    AdminBroadcastAnnounce("duyuru", ("Yeni Etkinlik: %s\n%s"):format(name, AdminTrim(description)))
    return true
end

function AdminSetEventActive(admin, eventId, state)
    eventId = tonumber(eventId)
    if not eventId then return false end
    AdminDBExec("UPDATE admin_events SET active = ? WHERE id = ?", state and 1 or 0, eventId)
    AdminLog(admin, "#" .. eventId, state and "event_activate" or "event_deactivate", "")
    return true
end

function AdminGetEvents()
    return AdminDBQuery("SELECT * FROM admin_events ORDER BY id DESC")
end
