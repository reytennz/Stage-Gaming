--[[
  stage_chat - client
]]

local chatInstance
local chatInstanceLoading
local chatInstanceLoaded
local browserGui

local chatSettings = {
  bx = 0.01,
  by = 0.01,
  bw = 0.30,
  bh = 0.42,
  fontScale = 1.0,
  opacity = 1.0,
  textR = 255, textG = 255, textB = 255,
  bgR = 10, bgG = 12, bgB = 18, bgA = 220,
  accentR = 61, accentG = 214, accentB = 140
}

local settingsOpen = false
local dragMode = false
local dragging = false
local dragOffX, dragOffY = 0, 0

local state = {
  show = false,
  activeInputKeyButton = nil,
  activeScrollKeyButton = nil
}

local inputKeyButtons = {
  ["t"] = { "say", 0 },
  ["y"] = { "teamsay", 2 }
}

local scrollKeyButtons = {
  ["pgup"] = "scrollup",
  ["pgdn"] = "scrolldown"
}

addEvent("onChat2Loaded")
addEvent("onChat2EnterButton")
addEvent("onChat2Output", true)
addEvent("onChat2Clear", true)
addEvent("onChat2Show", true)
addEvent("onChat2Typing")
addEvent("onChat2OpenSettings")
addEvent("chat2:headText", true)

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function loadChatSettings()
  local data = getElementData(localPlayer, "stage_chat:ui")
  if type(data) == "table" then
    for k, v in pairs(data) do
      if chatSettings[k] ~= nil then
        chatSettings[k] = v
      end
    end
  end
end

local function saveChatSettings()
  setElementData(localPlayer, "stage_chat:ui", chatSettings, false)
end

local function execute(eval)
  if chatInstance then
    executeBrowserJavascript(chatInstance, eval)
  end
end

local function applyBrowserLayout()
  if isElement(browserGui) then
    guiSetPosition(browserGui, chatSettings.bx, chatSettings.by, true)
    guiSetSize(browserGui, chatSettings.bw, chatSettings.bh, true)
  end
  if chatInstanceLoaded then
    execute(string.format("applyChatSettings(%s)", toJSON(chatSettings)))
  end
end

function create()
  loadChatSettings()
  local browser = guiCreateBrowser(chatSettings.bx, chatSettings.by, chatSettings.bw, chatSettings.bh, true, true, true)
  if not browser then return end
  browserGui = browser
  chatInstance = guiGetBrowser(browser)
  chatInstanceLoading = true
  addEventHandler("onClientBrowserCreated", chatInstance, load)
end

function load()
  loadBrowserURL(chatInstance, "http://mta/local/index.html")
end

function output(message)
  if not chatInstanceLoaded then
    setTimer(output, 250, 1, message)
    return
  end
  if not state.show then return end
  execute(string.format("addMessage(%s)", toJSON(tostring(message))))
end

function clear()
  execute("clear()")
end

function isChatVisible()
  return state.show
end

function show(bool)
  if chatInstanceLoaded ~= true then
    if chatInstanceLoading ~= true then
      create()
    end
    setTimer(show, 300, 1, bool)
    return
  end
  execute(string.format("show(%s)", tostring(bool)))
  state.show = bool
end

function registerKeyButtons()
  for keyButton, definition in pairs(inputKeyButtons) do
    bindKey(keyButton, "down", onChatInputButton, keyButton, definition)
  end
  for keyButton, definition in pairs(scrollKeyButtons) do
    bindKey(keyButton, "down", onChatScrollStartButton, keyButton, definition)
    bindKey(keyButton, "up", onChatScrollStopButton, keyButton, definition)
  end
end

function onChatLoaded()
  chatInstanceLoaded = true
  focusBrowser(chatInstance)
  applyBrowserLayout()
  show(true)
end

function onChatInputButton(_, _, keyButton, definition)
  if not state.show then return end
  if state.activeInputKeyButton then return end
  execute(string.format("showInput(%s)", toJSON(definition[1])))
  focusBrowser(chatInstance)
  guiSetInputEnabled(true)
  state.activeInputKeyButton = keyButton
end

function onChatEnterButton(message)
  if not state.show then return end
  if not state.activeInputKeyButton then return end
  execute("hideInput()")
  guiSetInputEnabled(false)
  if type(message) == "table" then
    message = tostring(message[1] or "")
  else
    message = tostring(message or "")
  end
  local msgType = 0
  local def = inputKeyButtons[state.activeInputKeyButton]
  if def then msgType = def[2] or 0 end
  if message ~= "" then
    local trimmed = message:gsub("^%s+", "")
    if trimmed:sub(1, 1) == "/" then
      local body = trimmed:sub(2)
      local cmd, rest = string.match(body, "^([%w_]+)%s*(.*)$")
      if cmd then
        cmd = string.lower(cmd)
        -- Client-side MTA komutları (debugscript, clearchat, showchat, chat vb.)
        if cmd == "debugscript" or cmd == "clearchat" or cmd == "showchat" or cmd == "chat" then
          executeCommandHandler(cmd, rest or "")
          state.activeInputKeyButton = nil
          return
        end
      end
    end
    triggerServerEvent("onChat2Message", resourceRoot, message, msgType)
  end
  state.activeInputKeyButton = nil
end

function onChatScrollStartButton(_, _, keyButton, definition)
  if state.activeScrollKeyButton then return end
  execute(string.format("startScroll(%s)", toJSON(definition)))
  state.activeScrollKeyButton = keyButton
end

function onChatScrollStopButton()
  if not state.activeScrollKeyButton then return end
  execute("stopScroll()")
  state.activeScrollKeyButton = nil
end

-- Yazma sesi
local lastTypingSound = 0
addEventHandler("onChat2Typing", root, function()
  local now = getTickCount()
  if now - lastTypingSound < 45 then return end
  lastTypingSound = now
  if fileExists("sounds/typing.mp3") then
    local s = playSound("sounds/typing.mp3")
    if s then setSoundVolume(s, 0.35) end
  end
end)

-- Kafa ustu /me /do
local headTexts = {}
addEventHandler("chat2:headText", root, function(player, text, r, g, b)
  if not isElement(player) then return end
  headTexts[player] = {
    text = tostring(text or ""),
    r = tonumber(r) or 255,
    g = tonumber(g) or 255,
    b = tonumber(b) or 255,
    untilTick = getTickCount() + 6000
  }
end)

addEventHandler("onClientRender", root, function()
  local now = getTickCount()
  local cx, cy, cz = getCameraMatrix()
  for player, data in pairs(headTexts) do
    if (not isElement(player)) or now > data.untilTick then
      headTexts[player] = nil
    else
      local x, y, z = getPedBonePosition(player, 8)
      if not x then
        x, y, z = getElementPosition(player)
        z = z + 1.0
      end
      z = z + 0.35
      local dist = getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
      if dist < 35 then
        local sx, sy = getScreenFromWorldPosition(x, y, z)
        if sx and sy then
          local scale = 1.2 - math.min(dist, 30) / 40
          dxDrawText(data.text, sx + 1, sy + 1, sx + 1, sy + 1, tocolor(0, 0, 0, 200), scale, "default-bold", "center", "bottom", false, false, false, true)
          dxDrawText(data.text, sx, sy, sx, sy, tocolor(data.r, data.g, data.b, 255), scale, "default-bold", "center", "bottom", false, false, false, true)
        end
      end
    end
  end
end)

-- admin:chatMessage ve admin:announce artik stage_admin tarafindan
-- isleniyor (mavi admin chat + ust bildirim). Burada tekrar yazma:
-- cift/uc mesaj olmasin. stage_admin outputChatBox -> hook -> mavi.

local function listenForOutputChatBox(_, _, _, _, _, message, r, g, b)
  local hex = ""
  if r and g and b then
    hex = RGBToHex(r, g, b)
  end
  output(tostring(hex) .. tostring(message))
  return "skip"
end

local function listenForShowChat(_, _, _, _, _, bool)
  show(bool)
  return "skip"
end

local function listenForClearChatBox()
  clear()
  return "skip"
end

-- Secili renk hedefi: "text" | "bg" | "accent"
local colorTarget = "text"
local COLOR_PRESETS = {
  {255,255,255}, {220,220,220}, {180,180,190}, {40,40,48}, {10,12,18},
  {255,90,90},   {255,160,60},  {255,220,80},  {90,220,140}, {60,200,255},
  {90,140,255},  {180,100,255}, {255,100,200}, {61,214,140}, {90,160,255},
}

local function getColorKeys(target)
  if target == "bg" then return "bgR", "bgG", "bgB" end
  if target == "accent" then return "accentR", "accentG", "accentB" end
  return "textR", "textG", "textB"
end

-- Ayar paneli
local function drawChatSettingsPanel()
  if not settingsOpen then return end
  local sw, sh = guiGetScreenSize()
  local w, h = 400, 560
  local x, y = (sw - w) / 2, (sh - h) / 2
  dxDrawRectangle(x, y, w, h, tocolor(16, 18, 28, 245), true)
  dxDrawRectangle(x, y, w, 36, tocolor(45, 180, 120, 255), true)
  dxDrawText("Chat Ayarlari", x, y, x + w, y + 36, tocolor(10, 20, 15, 255), 1.15, "default-bold", "center", "center", false, false, true)

  local rows = {
    { key = "bx", label = "Konum X", step = 0.01, min = 0, max = 0.85 },
    { key = "by", label = "Konum Y", step = 0.01, min = 0, max = 0.85 },
    { key = "bw", label = "Genislik", step = 0.02, min = 0.15, max = 0.9 },
    { key = "bh", label = "Yukseklik", step = 0.02, min = 0.15, max = 0.9 },
    { key = "fontScale", label = "Yazi boyutu", step = 0.05, min = 0.5, max = 2.0 },
  }
  local oy = y + 48
  for _, row in ipairs(rows) do
    local val = chatSettings[row.key] or 0
    dxDrawText(row.label, x + 16, oy, x + 170, oy + 22, tocolor(220, 225, 235, 255), 1.0, "default-bold", "left", "center", false, false, true)
    dxDrawText(string.format("%.2f", val), x + 160, oy, x + w - 90, oy + 22, tocolor(120, 200, 255, 255), 1.0, "default", "right", "center", false, false, true)
    dxDrawRectangle(x + 16, oy + 24, 28, 22, tocolor(50, 55, 70, 255), true)
    dxDrawText("-", x + 16, oy + 24, x + 44, oy + 46, tocolor(255, 255, 255, 255), 1.1, "default-bold", "center", "center", false, false, true)
    dxDrawRectangle(x + w - 44, oy + 24, 28, 22, tocolor(50, 55, 70, 255), true)
    dxDrawText("+", x + w - 44, oy + 24, x + w - 16, oy + 46, tocolor(255, 255, 255, 255), 1.1, "default-bold", "center", "center", false, false, true)
    oy = oy + 48
  end

  -- Hizli konum: Uste / Sola
  dxDrawRectangle(x + 16, oy, (w - 40) / 2, 26, tocolor(50, 55, 70, 230), true)
  dxDrawText("Uste tasi", x + 16, oy, x + 16 + (w - 40) / 2, oy + 26, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center", false, false, true)
  dxDrawRectangle(x + 24 + (w - 40) / 2, oy, (w - 40) / 2, 26, tocolor(50, 55, 70, 230), true)
  dxDrawText("Sola tasi", x + 24 + (w - 40) / 2, oy, x + w - 16, oy + 26, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center", false, false, true)
  oy = oy + 34

  dxDrawText("Renk sec (hedef)", x + 16, oy, x + w - 16, oy + 20, tocolor(61, 214, 140, 255), 1.0, "default-bold", "left", "center", false, false, true)
  oy = oy + 22
  local targets = {
    { id = "text", label = "Yazi" },
    { id = "bg", label = "Arkaplan" },
    { id = "accent", label = "Vurgu" },
  }
  local tw = (w - 48) / 3
  for i, t in ipairs(targets) do
    local tx = x + 16 + (i - 1) * (tw + 8)
    local col = (colorTarget == t.id) and tocolor(61, 214, 140, 230) or tocolor(50, 55, 70, 230)
    dxDrawRectangle(tx, oy, tw, 24, col, true)
    dxDrawText(t.label, tx, oy, tx + tw, oy + 24, tocolor(255, 255, 255, 255), 0.9, "default-bold", "center", "center", false, false, true)
  end
  oy = oy + 30

  -- Palette
  local cell = 22
  local gap = 4
  local cols = 5
  for i, p in ipairs(COLOR_PRESETS) do
    local ci = (i - 1) % cols
    local ri = math.floor((i - 1) / cols)
    local px = x + 16 + ci * (cell + gap)
    local py = oy + ri * (cell + gap)
    dxDrawRectangle(px, py, cell, cell, tocolor(p[1], p[2], p[3], 255), true)
    dxDrawRectangle(px, py, cell, 1, tocolor(0, 0, 0, 120), true)
  end
  local paletteRows = math.ceil(#COLOR_PRESETS / cols)
  oy = oy + paletteRows * (cell + gap) + 8

  -- RGB ince ayar
  local rk, gk, bk = getColorKeys(colorTarget)
  local r, g, b = chatSettings[rk] or 255, chatSettings[gk] or 255, chatSettings[bk] or 255
  dxDrawRectangle(x + 16, oy, 36, 22, tocolor(r, g, b, 255), true)
  dxDrawText(string.format("R:%d G:%d B:%d", r, g, b), x + 58, oy, x + w - 16, oy + 22, tocolor(200, 205, 215, 255), 0.9, "default", "left", "center", false, false, true)
  oy = oy + 28
  local channels = {
    { key = rk, label = "R", col = tocolor(255, 120, 120, 255) },
    { key = gk, label = "G", col = tocolor(120, 255, 120, 255) },
    { key = bk, label = "B", col = tocolor(120, 160, 255, 255) },
  }
  for _, ch in ipairs(channels) do
    dxDrawText(ch.label, x + 16, oy, x + 36, oy + 20, ch.col, 0.95, "default-bold", "left", "center", false, false, true)
    dxDrawRectangle(x + 40, oy, 22, 20, tocolor(50, 55, 70, 255), true)
    dxDrawText("-", x + 40, oy, x + 62, oy + 20, tocolor(255, 255, 255, 255), 0.9, "default-bold", "center", "center", false, false, true)
    dxDrawRectangle(x + 66, oy, 22, 20, tocolor(50, 55, 70, 255), true)
    dxDrawText("+", x + 66, oy, x + 88, oy + 20, tocolor(255, 255, 255, 255), 0.9, "default-bold", "center", "center", false, false, true)
    local val = chatSettings[ch.key] or 0
    local barW = w - 120
    dxDrawRectangle(x + 96, oy + 6, barW, 8, tocolor(40, 44, 55, 255), true)
    dxDrawRectangle(x + 96, oy + 6, barW * (val / 255), 8, ch.col, true)
    oy = oy + 24
  end

  oy = oy + 6
  local dragCol = dragMode and tocolor(61, 214, 140, 230) or tocolor(50, 55, 70, 230)
  dxDrawRectangle(x + 16, oy, w - 32, 28, dragCol, true)
  dxDrawText(dragMode and "Surukleme: ACIK (chat'i tut ve surukle)" or "Suruklemeyi Ac", x + 16, oy, x + w - 16, oy + 28, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center", false, false, true)

  dxDrawRectangle(x + 16, y + h - 40, w - 32, 28, tocolor(180, 60, 60, 230), true)
  dxDrawText("Kapat (ESC)", x + 16, y + h - 40, x + w - 16, y + h - 12, tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", false, false, true)
end

addEventHandler("onClientRender", root, drawChatSettingsPanel)

addEventHandler("onClientClick", root, function(btn, stateBtn, cx, cy)
  if btn ~= "left" then return end
  local sw, sh = guiGetScreenSize()

  if dragMode and isElement(browserGui) then
    local bx, by = guiGetPosition(browserGui, true)
    local bw, bh = guiGetSize(browserGui, true)
    local absX, absY = bx * sw, by * sh
    local absW, absH = bw * sw, bh * sh
    if stateBtn == "down" then
      if cx >= absX and cx <= absX + absW and cy >= absY and cy <= absY + absH then
        local pw, ph = 400, 560
        local px, py = (sw - pw) / 2, (sh - ph) / 2
        if not (settingsOpen and cx >= px and cx <= px + pw and cy >= py and cy <= py + ph) then
          dragging = true
          dragOffX = cx - absX
          dragOffY = cy - absY
          return
        end
      end
    elseif stateBtn == "up" then
      if dragging then
        dragging = false
        saveChatSettings()
        return
      end
    end
  end

  if not settingsOpen or stateBtn ~= "down" then return end
  local w, h = 400, 560
  local x, y = (sw - w) / 2, (sh - h) / 2

  if cx >= x + 16 and cx <= x + w - 16 and cy >= y + h - 40 and cy <= y + h - 12 then
    settingsOpen = false
    dragMode = false
    dragging = false
    showCursor(false)
    saveChatSettings()
    return
  end

  local rows = {
    { key = "bx", step = 0.01, min = 0, max = 0.85 },
    { key = "by", step = 0.01, min = 0, max = 0.85 },
    { key = "bw", step = 0.02, min = 0.15, max = 0.9 },
    { key = "bh", step = 0.02, min = 0.15, max = 0.9 },
    { key = "fontScale", step = 0.05, min = 0.5, max = 2.0 },
  }
  local oy = y + 48
  for _, row in ipairs(rows) do
    if cx >= x + 16 and cx <= x + 44 and cy >= oy + 24 and cy <= oy + 46 then
      chatSettings[row.key] = clamp((chatSettings[row.key] or 0) - row.step, row.min, row.max)
      applyBrowserLayout()
      saveChatSettings()
      return
    end
    if cx >= x + w - 44 and cx <= x + w - 16 and cy >= oy + 24 and cy <= oy + 46 then
      chatSettings[row.key] = clamp((chatSettings[row.key] or 0) + row.step, row.min, row.max)
      applyBrowserLayout()
      saveChatSettings()
      return
    end
    oy = oy + 48
  end

  -- Uste / Sola tasi
  local half = (w - 40) / 2
  if cy >= oy and cy <= oy + 26 then
    if cx >= x + 16 and cx <= x + 16 + half then
      chatSettings.by = 0
      applyBrowserLayout()
      saveChatSettings()
      return
    end
    if cx >= x + 24 + half and cx <= x + w - 16 then
      chatSettings.bx = 0.01
      applyBrowserLayout()
      saveChatSettings()
      return
    end
  end
  oy = oy + 34

  -- Renk hedefi
  oy = oy + 22
  local targets = { "text", "bg", "accent" }
  local tw = (w - 48) / 3
  for i, tid in ipairs(targets) do
    local tx = x + 16 + (i - 1) * (tw + 8)
    if cx >= tx and cx <= tx + tw and cy >= oy and cy <= oy + 24 then
      colorTarget = tid
      return
    end
  end
  oy = oy + 30

  -- Palette click
  local cell, gap, cols = 22, 4, 5
  for i, p in ipairs(COLOR_PRESETS) do
    local ci = (i - 1) % cols
    local ri = math.floor((i - 1) / cols)
    local px = x + 16 + ci * (cell + gap)
    local py = oy + ri * (cell + gap)
    if cx >= px and cx <= px + cell and cy >= py and cy <= py + cell then
      local rk, gk, bk = getColorKeys(colorTarget)
      chatSettings[rk], chatSettings[gk], chatSettings[bk] = p[1], p[2], p[3]
      applyBrowserLayout()
      saveChatSettings()
      return
    end
  end
  local paletteRows = math.ceil(#COLOR_PRESETS / cols)
  oy = oy + paletteRows * (cell + gap) + 8

  -- RGB preview skip
  oy = oy + 28
  local rk, gk, bk = getColorKeys(colorTarget)
  local channels = { rk, gk, bk }
  local function adj(key, delta)
    chatSettings[key] = clamp((chatSettings[key] or 0) + delta, 0, 255)
    applyBrowserLayout()
    saveChatSettings()
  end
  for _, key in ipairs(channels) do
    if cx >= x + 40 and cx <= x + 62 and cy >= oy and cy <= oy + 20 then adj(key, -10) return end
    if cx >= x + 66 and cx <= x + 88 and cy >= oy and cy <= oy + 20 then adj(key, 10) return end
    -- bar click
    local barW = w - 120
    if cx >= x + 96 and cx <= x + 96 + barW and cy >= oy and cy <= oy + 20 then
      local ratio = clamp((cx - (x + 96)) / barW, 0, 1)
      chatSettings[key] = math.floor(ratio * 255 + 0.5)
      applyBrowserLayout()
      saveChatSettings()
      return
    end
    oy = oy + 24
  end

  oy = oy + 6
  if cx >= x + 16 and cx <= x + w - 16 and cy >= oy and cy <= oy + 28 then
    dragMode = not dragMode
    if not dragMode then dragging = false end
    return
  end
end)

addEventHandler("onClientCursorMove", root, function(_, _, cx, cy)
  if not dragging or not isElement(browserGui) then return end
  local sw, sh = guiGetScreenSize()
  local nx = clamp((cx - dragOffX) / sw, 0, 0.9)
  local ny = clamp((cy - dragOffY) / sh, 0, 0.9)
  chatSettings.bx = nx
  chatSettings.by = ny
  guiSetPosition(browserGui, nx, ny, true)
end)

local function toggleSettings()
  settingsOpen = not settingsOpen
  showCursor(settingsOpen)
  if settingsOpen then
    loadChatSettings()
  else
    dragMode = false
    dragging = false
    saveChatSettings()
  end
end

addEventHandler("onChat2OpenSettings", root, toggleSettings)
addCommandHandler("chat", toggleSettings)

addEventHandler("onClientKey", root, function(btn, press)
  if not press then return end
  if btn == "escape" then
    if settingsOpen then
      settingsOpen = false
      dragMode = false
      dragging = false
      showCursor(false)
      saveChatSettings()
      cancelEvent()
      return
    end
    if state.activeInputKeyButton then
      execute("hideInput()")
      guiSetInputEnabled(false)
      state.activeInputKeyButton = nil
      cancelEvent()
    end
  end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
  showChat(false)
  pcall(function()
    addDebugHook("preFunction", listenForShowChat, { "showChat" })
    addDebugHook("preFunction", listenForOutputChatBox, { "outputChatBox" })
    addDebugHook("preFunction", listenForClearChatBox, { "clearChatBox" })
  end)
  registerKeyButtons()
  create()
  setTimer(function()
    show(true)
  end, 600, 1)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
  showChat(true)
  pcall(function()
    removeDebugHook("preFunction", listenForShowChat)
    removeDebugHook("preFunction", listenForOutputChatBox)
    removeDebugHook("preFunction", listenForClearChatBox)
  end)
  if state.activeInputKeyButton then
    guiSetInputEnabled(false)
  end
end)

addEventHandler("onChat2Loaded", root, onChatLoaded)
addEventHandler("onChat2EnterButton", root, onChatEnterButton)
addEventHandler("onChat2Output", root, function(msg) output(msg) end)
addEventHandler("onChat2Clear", root, clear)
addEventHandler("onChat2Show", root, function(bool) show(bool) end)
