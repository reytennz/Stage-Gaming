--[[
    stage_admin - HTML CEF panel
    Wiki kuralları:
      1) isLocal = true  (local HTML için zorunlu)
      2) isTransparent = false (boşken görünmez olmasın)
      3) loadBrowserURL SADECE onClientBrowserCreated / kısa timer sonrası
      4) URL: http://mta/local/html/panel.html  ("local" = bu resource)
      5) guiCreateBrowser = tıklama/klavye otomatik
]]

local sw, sh = guiGetScreenSize()
local guiEl = nil
local browser = nil
local useDx = false
local panelOpen = false
local pageReady = false
local loadAttempted = false
local urlIndex = 1
local urls = {}

panelData = {}
dashboard = {}
controlData = {}
playerTrace = {}
selectedPlayer = nil
AdminMyRank = "User"
AdminIsStaffClient = false
AdminUIOpen = false
AdminSelfToggle = { noclip = false, fly = false, god = false }

local function buildUrls()
    local res = getResourceName(getThisResource()) or "stage_admin"
    urls = {
        "http://mta/local/html/panel.html",
        "http://mta/" .. res .. "/html/panel.html",
        "http://mta/local/panel.html",
        "http://mta/" .. res .. "/panel.html",
    }
end

local function jsonEncode(t)
    local s = toJSON(t, true)
    if type(s) ~= "string" then return "null" end
    if s:sub(1, 1) == "[" and s:sub(-1) == "]" then
        s = s:sub(2, -2)
    end
    return s
end

local function sendToBrowser(fn, data)
    if not browser or not isElement(browser) or not pageReady then return end
    executeBrowserJavascript(browser, fn .. "(" .. jsonEncode(data) .. ")")
end

local function requestData()
    triggerServerEvent("admin:requestPanelData", localPlayer)
    triggerServerEvent("admin:requestDashboard", localPlayer)
    triggerServerEvent("admin:requestControlData", localPlayer)
end

local function handleAction(action, params)
    params = params or {}
    local realAction = params.subaction or params.action or action
    if action == "close" then
        if panelOpen then TogglePanel() end
    elseif action == "selectPlayer" then
        local name = params.name or ""
        if name ~= "" then
            selectedPlayer = name
            triggerServerEvent("admin:requestPlayerDetail", localPlayer, name)
        end
    elseif action == "trace" then
        if (params.serial or "") ~= "" then
            triggerServerEvent("admin:requestPlayerTrace", localPlayer, params.serial)
        end
    elseif action == "unban" then
        triggerServerEvent("admin:unbanById", localPlayer, tonumber(params.id))
    elseif action == "reportAction" then
        triggerServerEvent("admin:reportAction", localPlayer, params.type, tonumber(params.id), params.note or "")
    elseif action == "requestData" then
        requestData()
    elseif action == "manageResource" then
        triggerServerEvent("admin:manageResource", localPlayer, params.resAction, params.resName)
    elseif action == "createEvent" then
        triggerServerEvent("admin:createEvent", localPlayer, params.name, params.desc, params.reward, params.duration)
    else
        -- Genişletilmiş aksiyon handler (givecash, givebank, givevehicle, warn, kick, ban, giveitem, temprank vb.)
        local payload = {}
        if params.value then payload.value = params.value end
        if params.reason then payload.reason = params.reason end
        if params.model then payload.model = tonumber(params.model) or params.model end
        if params.duration then payload.duration = tonumber(params.duration) end
        if params.item then payload.item = params.item end
        if params.amount then payload.amount = tonumber(params.amount) or tonumber(params.value) end
        if params.rank then payload.rank = params.rank end

        local targetPlayer = params.player or selectedPlayer or ""
        triggerServerEvent("admin:action", localPlayer, realAction, targetPlayer, payload)
    end
end

local function ajaxHandler(get, post)
    local src = {}
    if type(get) == "table" then for k, v in pairs(get) do src[k] = v end end
    if type(post) == "table" then for k, v in pairs(post) do src[k] = v end end
    if src.action then handleAction(src.action, src) end
    return "ok"
end

local function currentUrl()
    return urls[urlIndex]
end

local function tryLoad(b)
    if not b or not isElement(b) then return end
    local path = currentUrl()
    if not path then
        outputChatBox("[Stage Admin] HTML dosyası bulunamadı. meta.xml <file src=\"html/panel.html\" /> kontrol et.", 240, 90, 90)
        return
    end
    loadAttempted = true
    outputDebugString("[Stage Admin] CEF load: " .. path)
    loadBrowserURL(b, path)
end

local function onCreated()
    if source ~= browser then return end
    setBrowserAjaxHandler(source, "bridge.html", ajaxHandler)
    urlIndex = 1
    tryLoad(source)
    focusBrowser(source)
end

local function onReady(url)
    if source ~= browser then return end
    pageReady = true
    outputChatBox("[Stage Admin] HTML panel açıldı.", 90, 220, 140)
    if panelOpen then
        focusBrowser(browser)
        requestData()
    end
end

local function onFail(url, errCode, errDesc)
    if source ~= browser then return end
    outputChatBox("[Stage Admin] Yükleme başarısız (" .. tostring(errCode) .. "): " .. tostring(url), 240, 140, 80)
    urlIndex = urlIndex + 1
    if urls[urlIndex] then
        tryLoad(source)
    else
        outputChatBox("[Stage Admin] Tüm HTML yolları denendi. Resource adının klasör adıyla aynı olduğundan emin ol (stage_admin).", 240, 90, 90)
    end
end

local function onNavigate(url)
    if source ~= browser then return end
    if type(url) ~= "string" then return end
    if url:find("^stage://") or url:find("bridge%.html") then
        cancelEvent()
        if url:find("^stage://admin/") then
            local rest = url:gsub("^stage://admin/", "")
            local action, qs = rest:match("^([^?]+)%??(.*)")
            local params = {}
            if qs then
                for k, v in qs:gmatch("([^&=]+)=([^&]*)") do
                    v = tostring(v):gsub("%%(%x%x)", function(h)
                        return string.char(tonumber(h, 16) or 0)
                    end)
                    params[k] = v
                end
            end
            if action then handleAction(action, params) end
        end
    end
end

-- DX fallback input (sadece guiCreateBrowser yoksa)
local inputBound = false
local function bindDxInput()
    if inputBound then return end
    inputBound = true
    addEventHandler("onClientCursorMove", root, function(_, _, x, y)
        if panelOpen and browser and isElement(browser) then
            injectBrowserMouseMove(browser, x, y)
        end
    end)
    addEventHandler("onClientClick", root, function(btn, state)
        if not panelOpen or not browser or not isElement(browser) then return end
        if state == "down" then
            injectBrowserMouseDown(browser, btn)
        else
            injectBrowserMouseUp(browser, btn)
        end
    end)
    addEventHandler("onClientMouseWheel", root, function(rel)
        if panelOpen and browser and isElement(browser) then
            injectBrowserMouseWheel(browser, 0, rel * 40)
        end
    end)
end

local function createBrowserNow()
    buildUrls()

    addEventHandler("onClientBrowserCreated", root, onCreated)
    addEventHandler("onClientBrowserDocumentReady", root, onReady)
    addEventHandler("onClientBrowserLoadingFailed", root, onFail)
    addEventHandler("onClientBrowserNavigate", root, onNavigate)

    -- GUI browser: tıklama/yazma otomatik. opaque (false) = HTML yoksa bile siyah/beyaz kutu görünür
    guiEl = guiCreateBrowser(0, 0, sw, sh, true, false, false)
    if guiEl then
        browser = guiGetBrowser(guiEl)
        guiSetVisible(guiEl, false)
        guiSetAlpha(guiEl, 1)
        useDx = false
    else
        -- fallback DX texture browser
        browser = createBrowser(sw, sh, true, false)
        useDx = true
        if browser then bindDxInput() end
    end

    if not browser then
        outputChatBox("[Stage Admin] CEF tarayıcı oluşturulamadı. MTA ayarlarından Browser'ı aç.", 240, 90, 90)
        return false
    end

    setBrowserAjaxHandler(browser, "bridge.html", ajaxHandler)

    -- Event kaçarsa (race) yine yükle
    setTimer(function()
        if browser and isElement(browser) and not loadAttempted then
            tryLoad(browser)
        end
    end, 250, 1)

    setTimer(function()
        if browser and isElement(browser) and not pageReady and not loadAttempted then
            tryLoad(browser)
        end
    end, 1000, 1)

    return true
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    createBrowserNow()
end)

function TogglePanel()
    panelOpen = not panelOpen
    AdminUIOpen = panelOpen

    if panelOpen then
        if not browser or not isElement(browser) then
            if not createBrowserNow() then
                panelOpen = false
                AdminUIOpen = false
                return
            end
        end
        if guiEl and isElement(guiEl) then
            guiSetVisible(guiEl, true)
            guiBringToFront(guiEl)
        end
        if isElement(browser) then
            setBrowserRenderingPaused(browser, false)
            focusBrowser(browser)
        end
        showCursor(true)
        guiSetInputEnabled(true)
        guiSetInputMode("no_binds")
        toggleAllControls(false)
        if pageReady then requestData() end
    else
        if guiEl and isElement(guiEl) then
            guiSetVisible(guiEl, false)
        end
        showCursor(false)
        guiSetInputEnabled(false)
        guiSetInputMode("allow_binds")
        toggleAllControls(true)
    end
end

bindKey(Config.PanelKey, "down", TogglePanel)
addCommandHandler("adminpanel", TogglePanel)

bindKey("escape", "down", function()
    if panelOpen then
        TogglePanel()
        cancelEvent()
    end
end)

-- Sadece DX fallback'te çiz (GUI browser kendini çizer)
addEventHandler("onClientRender", root, function()
    if not panelOpen then return end
    if useDx and browser and isElement(browser) then
        dxDrawImage(0, 0, sw, sh, browser, 0, 0, 0, tocolor(255, 255, 255, 255), true)
    end
end)

addEvent("admin:notStaff", true)
addEventHandler("admin:notStaff", localPlayer, function()
    outputChatBox("[Stage Admin] Yetkiniz bulunmuyor. Panel kapatılıyor.", 240, 90, 90)
    if panelOpen then TogglePanel() end
end)

addEvent("admin:panelData", true)
addEventHandler("admin:panelData", localPlayer, function(data)
    panelData = data
    AdminMyRank = data.myRank or "User"
    AdminIsStaffClient = AdminMyRank ~= "User"
    local rankColor = "#888"
    if AdminMyRank == "Admin" or AdminMyRank == "SuperAdmin" or AdminMyRank == "Owner" or AdminMyRank == "Developer" then
        rankColor = "#4f8ef7"
    elseif AdminMyRank == "Moderator" then
        rankColor = "#3ecf8e"
    end
    if browser and pageReady then
        executeBrowserJavascript(browser,
            "var el=document.getElementById('rank-badge');if(el){el.textContent=" .. jsonEncode(AdminMyRank) ..
            ";el.style.background='" .. rankColor .. "';}")
    end
    sendToBrowser("window.updatePanelData", {
        bans      = data.bans or {},
        reports   = data.reports or {},
        logs      = data.logs or {},
        events    = data.events or {},
        dashboard = dashboard or {},
    })
    local playerList = {}
    for _, p in ipairs(data.players or {}) do
        playerList[#playerList + 1] = {
            name   = p.name or (p.element and getPlayerName(p.element)) or "?",
            online = true,
            id     = p.id or 0,
        }
    end
    sendToBrowser("window.updatePlayers", playerList)
end)

addEvent("admin:dashboardData", true)
addEventHandler("admin:dashboardData", localPlayer, function(data)
    dashboard = data
    sendToBrowser("window.updateDashboard", data)
end)

addEvent("admin:controlData", true)
addEventHandler("admin:controlData", localPlayer, function(data)
    controlData = data or {}
    if type(controlData.dashboard) == "table" then
        dashboard = controlData.dashboard
        sendToBrowser("window.updateDashboard", dashboard)
    end
    sendToBrowser("window.updateTrackList", controlData.activity or {})
    if controlData.resources then
        sendToBrowser("window.updateResources", controlData.resources or {})
    end
end)

addEvent("admin:playerTraceData", true)
addEventHandler("admin:playerTraceData", localPlayer, function(data)
    playerTrace = data or {}
    sendToBrowser("window.updateTraceDetail", data)
    sendToBrowser("window.updatePlayerDetail", data)
end)

addEvent("admin:actionDone", true)
addEventHandler("admin:actionDone", localPlayer, function()
    if panelOpen then
        triggerServerEvent("admin:requestPanelData", localPlayer)
        triggerServerEvent("admin:requestControlData", localPlayer)
        if selectedPlayer then
            triggerServerEvent("admin:requestPlayerDetail", localPlayer, selectedPlayer)
        end
    end
end)

addEvent("admin:newReport", true)
addEventHandler("admin:newReport", localPlayer, function()
    if panelOpen then
        triggerServerEvent("admin:requestPanelData", localPlayer)
    end
end)

addEvent("admin:notify", true)
addEventHandler("admin:notify", localPlayer, function(message, msgType)
    if not browser or not isElement(browser) or not pageReady then return end
    local title = msgType == "success" and "Başarılı"
               or msgType == "error"   and "Hata"
               or msgType == "warning" and "Uyarı"
               or "Bilgi"
    executeBrowserJavascript(browser,
        "if(window.mtaNotify)window.mtaNotify(" ..
        toJSON(title) .. "," ..
        toJSON(message) .. "," ..
        toJSON(msgType or "info") .. ")")
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if guiEl and isElement(guiEl) then destroyElement(guiEl) end
    if useDx and browser and isElement(browser) then destroyElement(browser) end
    guiEl, browser = nil, nil
    showCursor(false)
    guiSetInputEnabled(false)
    guiSetInputMode("allow_binds")
    toggleAllControls(true)
end)
