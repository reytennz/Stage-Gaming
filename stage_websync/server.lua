local function dbg(msg, lvl)
    outputDebugString("[stage_websync] " .. tostring(msg), lvl or 3)
end

local function post(payload, label)
    payload = payload or {}
    payload.key = StageWebConfig.key

    local body = toJSON(payload, false)
    if not body then
        dbg(label .. " JSON olusturulamadi.", 1)
        return
    end

    local options = {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["X-Stage-Key"] = StageWebConfig.key,
        },
        postData = body,
        postIsBinary = false,
        connectionAttempts = 2,
        connectTimeout = 10000,
        maxRedirects = 3,
    }

    dbg(label .. " -> HTTP istegi gonderiliyor...", 3)

    local ok, result = pcall(function()
        return fetchRemote(StageWebConfig.url, options, function(data, info)
            info = info or {}
            local status = tonumber(info.statusCode) or 0
            if info.success and status >= 200 and status < 300 then
                dbg(label .. " OK | HTTP " .. status .. " | response=" .. tostring(data), 3)
            else
                dbg(label .. " HATA | HTTP " .. status .. " | " .. tostring(data), 1)
            end
        end)
    end)

    if not ok then
        dbg(label .. " fetchRemote LUA HATASI: " .. tostring(result), 1)
    elseif result == false or result == nil then
        dbg(label .. " fetchRemote baslatilamadi. ACL: function.fetchRemote kontrol et.", 1)
    else
        dbg(label .. " fetchRemote baslatildi.", 3)
    end
end

local function heartbeat()
    post({
        type = "heartbeat",
        players = #getElementsByType("player"),
        max_players = getMaxPlayers(),
        server = "Stage Gaming",
        timestamp = getRealTime().timestamp,
    }, "heartbeat")
end

local function snapshot()
    -- Ilk asamada DB'ye baglanmadan heartbeat test edilir.
    -- DB entegrasyonu daha sonra mevcut stage_loading exportuna gore eklenir.
    heartbeat()
end

addEventHandler("onResourceStart", resourceRoot, function()
    dbg("WebSync baslatildi. URL: " .. tostring(StageWebConfig.url), 3)
    dbg("Mevcut oyuncu: " .. tostring(#getElementsByType("player")) .. " / " .. tostring(getMaxPlayers()), 3)
    dbg("Aktif oyuncu WebSync testi 3 saniye icinde baslayacak.", 3)

    setTimer(snapshot, 3000, 1)
    setTimer(heartbeat, StageWebConfig.heartbeatInterval or 15000, 0)
end)

addEventHandler("onPlayerJoin", root, function()
    setTimer(heartbeat, 1000, 1)
end)

addEventHandler("onPlayerQuit", root, function()
    setTimer(heartbeat, 1000, 1)
end)
