local galleries = {}
local histories = {}
local contacts = {}
local notes = {}
local posts = { instagram = {}, twitter = {} }
local activeCalls = {}
local phoneNumbers = {}
local usedNumbers = {}

local function dbg(msg)
    outputDebugString("[Stage Phone] " .. tostring(msg))
end

local function playerOk(p)
    return p and isElement(p) and getElementType(p) == "player"
end

local function getActor()
    if playerOk(client) then
        return client
    end
    if playerOk(source) then
        return source
    end
    return nil
end

local function stripCodes(s)
    s = tostring(s or "")
    s = s:gsub("#%x%x%x%x%x%x", "")
    return s
end

local function trim(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function clampStr(s, maxLen)
    s = tostring(s or "")
    maxLen = tonumber(maxLen) or 200
    if #s > maxLen then
        s = s:sub(1, maxLen)
    end
    return s
end

local function playerName(p)
    if not playerOk(p) then
        return "Bilinmeyen"
    end
    return stripCodes(getPlayerName(p) or "Bilinmeyen")
end

local function serialOf(p)
    if not playerOk(p) then
        return "unknown"
    end
    local s = getPlayerSerial(p)
    if type(s) == "string" and s ~= "" then
        return s
    end
    return "name:" .. playerName(p)
end

local function nextNumber()
    local n = 5550100 + math.random(10, 8999)
    local guard = 0
    while usedNumbers[tostring(n)] and guard < 200 do
        n = 5550100 + math.random(10, 8999)
        guard = guard + 1
    end
    return tostring(n)
end

local function getNumber(p)
    if not playerOk(p) then
        return nil
    end
    if phoneNumbers[p] then
        return phoneNumbers[p]
    end
    local existing = getElementData(p, "stagephone:number")
    if type(existing) == "string" and existing ~= "" then
        phoneNumbers[p] = existing
        usedNumbers[existing] = p
        return existing
    end
    local num = nextNumber()
    phoneNumbers[p] = num
    usedNumbers[num] = p
    setElementData(p, "stagephone:number", num)
    return num
end

local function findPlayer(query)
    query = trim(stripCodes(query))
    if query == "" then
        return nil
    end
    local qlow = query:lower()
    local matches = {}
    local players = getElementsByType("player")
    for i = 1, #players do
        local p = players[i]
        if playerOk(p) then
            local num = getNumber(p)
            local name = playerName(p)
            if num == query or name == query or name:lower() == qlow then
                return p
            end
            if name:lower():find(qlow, 1, true) then
                matches[#matches + 1] = p
            end
        end
    end
    if #matches == 1 then
        return matches[1]
    end
    return nil
end

local function limitList(list, maxCount)
    maxCount = maxCount or 40
    while #list > maxCount do
        table.remove(list)
    end
    return list
end

local function addHistory(p, number, callType)
    if not playerOk(p) then
        return
    end
    histories[p] = histories[p] or {}
    table.insert(histories[p], 1, {
        number = tostring(number or "Bilinmeyen"),
        call_type = tostring(callType or "outgoing"),
    })
    limitList(histories[p], 20)
    if DB and DB.isReady and DB.isReady() then
        DB.exec(
            "INSERT INTO stage_calls (serial, number, call_type) VALUES (?, ?, ?)",
            serialOf(p),
            tostring(number or ""),
            tostring(callType or "outgoing")
        )
    end
end

local function sendError(p, msg)
    if playerOk(p) then
        triggerClientEvent(p, "stagephone:error", resourceRoot, tostring(msg or "Hata"))
    end
end

local function endPair(a, reason)
    local info = a and activeCalls[a] or nil
    local b = info and info.peer or nil
    if a then
        activeCalls[a] = nil
    end
    if b then
        activeCalls[b] = nil
    end
    if playerOk(a) then
        triggerClientEvent(a, "stagephone:endCall", resourceRoot)
    end
    if playerOk(b) then
        triggerClientEvent(b, "stagephone:endCall", resourceRoot)
    end
    if reason then
        dbg("Arama kapatildi: " .. tostring(reason))
    end
end

function sendPhoneData(p)
    if not playerOk(p) then
        return
    end
    local payload = {
        user = {
            name = playerName(p),
            number = getNumber(p),
        },
        gallery = galleries[p] or {},
        calls = histories[p] or {},
        contacts = contacts[p] or {},
        notes = notes[p] or {},
        instagram = posts.instagram or {},
        twitter = posts.twitter or {},
    }
    triggerClientEvent(p, "stagephone:data", resourceRoot, payload)
end

addEvent("stagephone:load", true)
addEventHandler("stagephone:load", root, function()
    local p = getActor()
    if not p then
        return
    end
    getNumber(p)
    galleries[p] = galleries[p] or {}
    histories[p] = histories[p] or {}
    contacts[p] = contacts[p] or {}
    notes[p] = notes[p] or {}
    sendPhoneData(p)
end)

addEvent("stagephone:galleryAdd", true)
addEventHandler("stagephone:galleryAdd", root, function(path)
    local p = getActor()
    if not p then
        return
    end
    if type(path) ~= "string" then
        sendError(p, "Gecersiz galeri dosyasi.")
        return
    end
    path = clampStr(path, 180)
    if path == "" or path:find("%.%.") or path:find("[\n\r]") then
        sendError(p, "Gecersiz galeri dosyasi.")
        return
    end
    galleries[p] = galleries[p] or {}
    table.insert(galleries[p], 1, { image_url = path })
    limitList(galleries[p], (Config and Config.maxGallery) or 40)
    if DB and DB.isReady and DB.isReady() then
        DB.exec("INSERT INTO stage_gallery (serial, image_url) VALUES (?, ?)", serialOf(p), path)
    end
end)

addEvent("stagephone:message", true)
addEventHandler("stagephone:message", root, function(target, text)
    local p = getActor()
    if not p then
        return
    end
    if type(target) ~= "string" or type(text) ~= "string" then
        sendError(p, "Gecersiz mesaj.")
        return
    end
    text = clampStr(trim(text), (Config and Config.maxMessageLength) or 500)
    target = clampStr(trim(stripCodes(target)), 40)
    if target == "" or text == "" then
        sendError(p, "Hedef ve mesaj gerekli.")
        return
    end
    local other = findPlayer(target)
    if not other then
        sendError(p, "Oyuncu bulunamadi.")
        return
    end
    if other == p then
        sendError(p, "Kendine mesaj gonderemezsin.")
        return
    end
    triggerClientEvent(other, "stagephone:messageReceived", resourceRoot, playerName(p), text)
    triggerClientEvent(p, "stagephone:messageReceived", resourceRoot, "Sen -> " .. playerName(other), text)
end)

addEvent("stagephone:post", true)
addEventHandler("stagephone:post", root, function(kind, text, image)
    local p = getActor()
    if not p then
        return
    end
    if type(kind) ~= "string" or type(text) ~= "string" then
        sendError(p, "Gecersiz gonderi.")
        return
    end
    if kind ~= "instagram" and kind ~= "twitter" then
        sendError(p, "Gecersiz gonderi turu.")
        return
    end
    local maxLen = 280
    if kind == "instagram" then
        maxLen = (Config and Config.maxPostCaption) or 500
    else
        maxLen = (Config and Config.maxTweetLength) or 280
    end
    text = clampStr(trim(text), maxLen)
    if text == "" then
        sendError(p, "Gonderi bos olamaz.")
        return
    end
    local imageUrl = nil
    if type(image) == "string" and image ~= "" and not image:find("%.%.") then
        imageUrl = clampStr(image, 180)
    end
    local row = {
        user = playerName(p),
        text = text,
        image = imageUrl,
        created = getRealTime().timestamp,
    }
    posts[kind] = posts[kind] or {}
    table.insert(posts[kind], 1, row)
    limitList(posts[kind], 30)
    if DB and DB.isReady and DB.isReady() then
        DB.exec(
            "INSERT INTO stage_posts (kind, username, body, image_url) VALUES (?, ?, ?, ?)",
            kind,
            row.user,
            row.text,
            imageUrl or ""
        )
    end
    local players = getElementsByType("player")
    for i = 1, #players do
        if playerOk(players[i]) then
            sendPhoneData(players[i])
        end
    end
end)

addEvent("stagephone:contact", true)
addEventHandler("stagephone:contact", root, function(name, number)
    local p = getActor()
    if not p then
        return
    end
    if type(name) ~= "string" or type(number) ~= "string" then
        sendError(p, "Gecersiz kisi.")
        return
    end
    name = clampStr(trim(stripCodes(name)), 32)
    number = clampStr(trim(number), 16)
    if name == "" or number == "" then
        sendError(p, "Isim ve numara gerekli.")
        return
    end
    contacts[p] = contacts[p] or {}
    table.insert(contacts[p], 1, { name = name, number = number })
    limitList(contacts[p], 40)
    if DB and DB.isReady and DB.isReady() then
        DB.exec(
            "INSERT INTO stage_contacts (serial, name, number) VALUES (?, ?, ?)",
            serialOf(p),
            name,
            number
        )
    end
    sendPhoneData(p)
end)

addEvent("stagephone:note", true)
addEventHandler("stagephone:note", root, function(title, body)
    local p = getActor()
    if not p then
        return
    end
    if type(title) ~= "string" or type(body) ~= "string" then
        sendError(p, "Gecersiz not.")
        return
    end
    title = clampStr(trim(title), 80)
    body = clampStr(trim(body), (Config and Config.maxNoteLength) or 2000)
    if title == "" and body == "" then
        sendError(p, "Not bos olamaz.")
        return
    end
    if title == "" then
        title = "Not"
    end
    notes[p] = notes[p] or {}
    table.insert(notes[p], 1, { title = title, body = body })
    limitList(notes[p], 40)
    if DB and DB.isReady and DB.isReady() then
        DB.exec(
            "INSERT INTO stage_notes (serial, title, body) VALUES (?, ?, ?)",
            serialOf(p),
            title,
            body
        )
    end
    sendPhoneData(p)
end)

addEvent("stagephone:call", true)
addEventHandler("stagephone:call", root, function(number)
    local p = getActor()
    if not p then
        return
    end
    if type(number) ~= "string" then
        sendError(p, "Gecersiz telefon numarasi.")
        return
    end
    number = clampStr(trim(stripCodes(number)), 32)
    if number == "" then
        sendError(p, "Gecersiz telefon numarasi.")
        return
    end
    if activeCalls[p] then
        sendError(p, "Zaten bir aramadasin.")
        return
    end
    local other = findPlayer(number)
    if not other then
        sendError(p, "Oyuncu bulunamadi.")
        triggerClientEvent(p, "stagephone:endCall", resourceRoot)
        addHistory(p, number, "outgoing")
        return
    end
    if other == p then
        sendError(p, "Kendini arayamazsin.")
        triggerClientEvent(p, "stagephone:endCall", resourceRoot)
        return
    end
    if activeCalls[other] then
        sendError(p, "Numara mesgul.")
        triggerClientEvent(p, "stagephone:callStatus", resourceRoot, "Mesgul", getNumber(other) or number)
        setTimer(function()
            if playerOk(p) then
                triggerClientEvent(p, "stagephone:endCall", resourceRoot)
            end
        end, 1200, 1)
        addHistory(p, getNumber(other) or number, "outgoing")
        return
    end
    local fromNum = getNumber(p)
    local toNum = getNumber(other)
    activeCalls[p] = { peer = other, outgoing = true, status = "ringing" }
    activeCalls[other] = { peer = p, outgoing = false, status = "ringing" }
    addHistory(p, toNum or number, "outgoing")
    addHistory(other, fromNum or playerName(p), "incoming")
    triggerClientEvent(p, "stagephone:callStatus", resourceRoot, "Araniyor...", toNum or number)
    triggerClientEvent(other, "stagephone:incomingCall", resourceRoot, fromNum or playerName(p))
end)

addEvent("stagephone:callAnswer", true)
addEventHandler("stagephone:callAnswer", root, function()
    local p = getActor()
    if not p then
        return
    end
    local info = activeCalls[p]
    if not info or not playerOk(info.peer) then
        sendError(p, "Aktif arama yok.")
        triggerClientEvent(p, "stagephone:endCall", resourceRoot)
        return
    end
    local other = info.peer
    info.status = "talking"
    if activeCalls[other] then
        activeCalls[other].status = "talking"
    end
    triggerClientEvent(p, "stagephone:callStatus", resourceRoot, "Gorusmede", getNumber(other) or playerName(other))
    triggerClientEvent(other, "stagephone:callStatus", resourceRoot, "Gorusmede", getNumber(p) or playerName(p))
end)

addEvent("stagephone:callEnd", true)
addEventHandler("stagephone:callEnd", root, function()
    local p = getActor()
    if not p then
        return
    end
    endPair(p, "hangup")
end)

local function forgetPlayer(p)
    if activeCalls[p] then
        endPair(p, "quit")
    end
    local num = phoneNumbers[p]
    if num then
        usedNumbers[num] = nil
    end
    phoneNumbers[p] = nil
    galleries[p] = nil
    histories[p] = nil
    contacts[p] = nil
    notes[p] = nil
end

addEventHandler("onPlayerQuit", root, function()
    forgetPlayer(source)
end)

addEventHandler("onPlayerJoin", root, function()
    getNumber(source)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    local players = getElementsByType("player")
    for i = 1, #players do
        if playerOk(players[i]) then
            getNumber(players[i])
        end
    end
    dbg("Server hazir.")
end)

addEventHandler("onResourceStop", resourceRoot, function()
    local players = getElementsByType("player")
    for i = 1, #players do
        local p = players[i]
        if playerOk(p) and activeCalls[p] then
            triggerClientEvent(p, "stagephone:endCall", resourceRoot)
        end
    end
    activeCalls = {}
end)
