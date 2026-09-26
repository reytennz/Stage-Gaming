--[[
    stage_core - client notify (HTML CEF)
    sa.html tasarımıyla birebir uyumlu bildirim sistemi
]]

local sx, sy = guiGetScreenSize()
local browserW = 360
local browserH = 580
local browserX = sx - browserW - 20
local browserY = 30

local notifyBrowser = nil
local browserReady = false
local pendingQueue = {}
local activeCount = 0

local function createNotifyBrowser()
    if isElement(notifyBrowser) then return end
    
    notifyBrowser = createBrowser(browserW, browserH, true, true)
    if not notifyBrowser then return end

    addEventHandler("onClientBrowserCreated", notifyBrowser, function()
        loadBrowserURL(source, "http://mta/local/html/notify.html")
    end)
    
    addEventHandler("onClientBrowserDocumentReady", notifyBrowser, function()
        browserReady = true
        for _, code in ipairs(pendingQueue) do
            executeBrowserJavascript(notifyBrowser, code)
        end
        pendingQueue = {}
    end)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    createNotifyBrowser()
end)

addEventHandler("onClientRender", root, function()
    if isElement(notifyBrowser) and browserReady and activeCount > 0 then
        dxDrawImage(browserX, browserY, browserW, browserH, notifyBrowser, 0, 0, 0, tocolor(255, 255, 255, 255), true)
    end
end)

function ShowHtmlNotification(message, ntype, title, count, duration)
    if not message or message == "" then return end
    ntype = tostring(ntype or "info"):lower()
    title = tostring(title or "")
    message = tostring(message or "")
    count = tostring(count or "")
    duration = tonumber(duration) or 5000

    if not isElement(notifyBrowser) then
        createNotifyBrowser()
    end

    local js = string.format("addNotification(%q, %q, %q, %q, %d);", ntype, title, message, count, duration)
    
    activeCount = activeCount + 1
    setTimer(function()
        if activeCount > 0 then
            activeCount = activeCount - 1
        end
    end, duration + 600, 1)

    if browserReady and isElement(notifyBrowser) then
        executeBrowserJavascript(notifyBrowser, js)
    else
        table.insert(pendingQueue, js)
    end
end

addEvent("stage_core:notify", true)
addEventHandler("stage_core:notify", root, function(message, ntype, title, count, duration)
    ShowHtmlNotification(message, ntype, title, count, duration)
end)

-- Client export
function Notify(message, ntype, title, count, duration)
    ShowHtmlNotification(message, ntype, title, count, duration)
end

-- Test komutu: /testnotify [success/info/warning/error] [mesaj]
addCommandHandler("testnotify", function(cmd, ntype, ...)
    local msg = table.concat({...}, " ")
    if msg == "" then msg = "Bu bir test bildirimidir." end
    ShowHtmlNotification(msg, ntype or "success", "", "1x", 5000)
end)
