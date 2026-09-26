--[[
  stage_chat - server
  Not: executeCommandHandler ACL ister. Yerel komutlar dogrudan calisir.
  Diger resource komutlari icin ACL veya asagidaki not.
]]

addEvent("onChat2Message", true)

local isDefaultOutput = true
local maxLength = 150

local function getPID(p)
  if not isElement(p) then return "?" end
  local v = getElementData(p, "playerid")
  if v == nil or v == false then v = getElementData(p, "id") end
  if v == nil or v == false then v = getElementData(p, "ID") end
  if v == nil or v == false then return "?" end
  return tostring(v)
end

local function cleanName(p)
  if not isElement(p) then return "?" end
  return tostring(getPlayerName(p) or "?"):gsub("#%x%x%x%x%x%x", "")
end

local function isStaff(p)
  if not isElement(p) then return false end
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok, r = pcall(function()
      return exports.stage_admin:AdminIsStaff(p)
    end)
    if ok and r == true then return true end
  end
  return false
end

local function hasAnnounce(p)
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok, r = pcall(function()
      return exports.stage_admin:AdminHasPermission(p, "announce")
    end)
    if ok and r == true then return true end
  end
  return isStaff(p)
end

local function nearbyPlayers(player, range)
  range = tonumber(range) or 30
  local list = {}
  if not isElement(player) then return list end
  local x, y, z = getElementPosition(player)
  local int = getElementInterior(player)
  local dim = getElementDimension(player)
  for _, p in ipairs(getElementsByType("player")) do
    if isElement(p) and getElementInterior(p) == int and getElementDimension(p) == dim then
      local px, py, pz = getElementPosition(p)
      if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
        list[#list + 1] = p
      end
    end
  end
  return list
end

function clear(player)
  if isElement(player) then
    triggerClientEvent(player, "onChat2Clear", player)
  end
end

function show(player, bool)
  if isElement(player) then
    triggerClientEvent(player, "onChat2Show", player, bool == true)
  end
end

function output(player, message)
  message = tostring(message or "")
  if message == "" then return end
  if player == root then
    for _, p in ipairs(getElementsByType("player")) do
      triggerClientEvent(p, "onChat2Output", p, message)
    end
  elseif isElement(player) then
    triggerClientEvent(player, "onChat2Output", player, message)
  end
end

function useDefaultOutput(bool)
  isDefaultOutput = (bool and true) or false
end

local function outputToMany(players, message)
  for i = 1, #players do
    if isElement(players[i]) then
      output(players[i], message)
    end
  end
end

local function sendHeadText(players, targetPlayer, text, r, g, b)
  for i = 1, #players do
    local p = players[i]
    if isElement(p) then
      triggerClientEvent(p, "chat2:headText", p, targetPlayer, text, r, g, b)
    end
  end
end

-- ================= Yerel komut fonksiyonlari (ACL gerekmez) =================

local function cmdMe(player, args)
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if args == "" then
    output(player, "#FF6464Kullanim: /me [aksiyon]")
    return
  end
  local name = cleanName(player)
  local text = "#C060FF* " .. name .. " " .. args
  local near = nearbyPlayers(player, 30)
  outputToMany(near, text)
  sendHeadText(near, player, "* " .. name .. " " .. args, 192, 96, 255)
end

local function cmdDo(player, args)
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if args == "" then
    output(player, "#FF6464Kullanim: /do [aciklama]")
    return
  end
  local name = cleanName(player)
  local text = "#60C060* " .. args .. " ((" .. name .. "))"
  local near = nearbyPlayers(player, 30)
  outputToMany(near, text)
  sendHeadText(near, player, args, 96, 192, 96)
end

local function cmdPm(player, args)
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local targetId, msg = string.match(args, "^(%S+)%s+(.+)$")
  if not targetId or not msg then
    output(player, "#FF6464Kullanim: /pm [ID] [mesaj]")
    return
  end
  local tid = tonumber(targetId)
  local target = nil
  if tid then
    for _, p in ipairs(getElementsByType("player")) do
      if tonumber(getPID(p)) == tid then
        target = p
        break
      end
    end
  end
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi.")
    return
  end
  if target == player then
    output(player, "#FF6464Kendine PM atamazsin.")
    return
  end
  msg = msg:gsub("#%x%x%x%x%x%x", "")
  output(player, "#C8A0FF[PM -> " .. getPID(target) .. "] #FFFFFF" .. msg)
  output(target, "#C8A0FF[PM <- " .. getPID(player) .. " " .. cleanName(player) .. "] #FFFFFF" .. msg)
end

local function cmdDuyuru(player, args)
  if not hasAnnounce(player) then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if args == "" then
    output(player, "#FFC20EKullanim: /duyuru [mesaj]  (veya admin panelden duyuru gonder)")
    return
  end
  -- Chat'e yazma; sadece admin panel bildirim sistemi
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok = pcall(function()
      exports.stage_admin:AdminSendAnnounce(player, "duyuru", args)
    end)
    if ok then
      output(player, "#60C060Duyuru gonderildi (panel bildirimi).")
      return
    end
  end
  -- Fallback: admin:announce client event
  for _, p in ipairs(getElementsByType("player")) do
    triggerClientEvent(p, "admin:announce", p, "duyuru", "DUYURU", args, {90, 160, 255})
  end
  output(player, "#60C060Duyuru gonderildi (panel bildirimi).")
end


-- ================= stage_admin komutlari (ACL / executeCommandHandler YOK) =================

local function hasPerm(player, perm)
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok, r = pcall(function()
      return exports.stage_admin:AdminHasPermission(player, perm)
    end)
    if ok and r == true then return true end
  end
  return isStaff(player)
end

local function cmdA(player, args)
  if not hasPerm(player, "achat") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if args == "" then
    output(player, "#FF6464Kullanim: /a [mesaj]")
    return
  end
  -- Sadece stage_admin admin chat (mavi). Cift/uc mesaj olmasin.
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok = pcall(function()
      exports.stage_admin:AdminChatSend(player, args)
    end)
    if ok then return end
  end
  -- Fallback: sadece bir kez mavi mesaj
  local text = "#5AC8FF[Admin Chat] " .. cleanName(player) .. ": #FFFFFF" .. args
  for _, p in ipairs(getElementsByType("player")) do
    if isStaff(p) then
      output(p, text)
    end
  end
end

local function cmdCv(player, args)
  if not hasPerm(player, "givevehicle") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local model = tonumber(tostring(args or ""):match("^(%S+)"))
  if not model then
    output(player, "#FF6464Kullanim: /cv [arac id]")
    return
  end
  local x, y, z = getElementPosition(player)
  local _, _, rot = getElementRotation(player)
  local veh = createVehicle(model, x + 2, y, z, 0, 0, rot)
  if not veh then
    output(player, "#FF6464Gecersiz arac ID.")
    return
  end
  warpPedIntoVehicle(player, veh)
  output(player, "#60C060Arac olusturuldu: " .. tostring(model))
end

local function cmdDv(player, args)
  if not hasPerm(player, "deletevehicle") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local vehicle = getPedOccupiedVehicle(player)
  if not vehicle then
    output(player, "#FF6464Bir aracın icinde olmalisin.")
    return
  end
  destroyElement(vehicle)
  output(player, "#60C060Arac silindi.")
end

local function cmdDva(player, args)
  if not hasPerm(player, "deleteallvehicles") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local deleted = 0
  for _, veh in ipairs(getElementsByType("vehicle")) do
    local occupied = false
    for seat = 0, getVehicleMaxPassengers(veh) or 3 do
      if getVehicleOccupant(veh, seat) then
        occupied = true
        break
      end
    end
    if not occupied then
      destroyElement(veh)
      deleted = deleted + 1
    end
  end
  -- Chat'e yazma; 30 sn bildirim (admin:announce)
  local msg = deleted .. " bos arac temizlendi."
  output(player, "#60C060" .. deleted .. " bos arac silindi.")
  for _, p in ipairs(getElementsByType("player")) do
    triggerClientEvent(p, "admin:announce", p, "bilgi", "ARAC TEMIZLIGI", msg, {90, 200, 140}, 30000)
  end
end

local function cmdNoon(player, args)
  if not isStaff(player) then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  setTime(12, 0)
  output(player, "#60C060Saat 12:00 olarak ayarlandi.")
end

local function cmdNight(player, args)
  if not isStaff(player) then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  setTime(0, 0)
  output(player, "#60C060Saat 00:00 olarak ayarlandi.")
end


local function findTarget(arg)
  if not arg or arg == "" then return nil end
  local tid = tonumber(arg)
  if tid then
    for _, p in ipairs(getElementsByType("player")) do
      if tonumber(getPID(p)) == tid then return p end
    end
  end
  arg = string.lower(tostring(arg))
  local matches = {}
  for _, p in ipairs(getElementsByType("player")) do
    if string.find(string.lower(cleanName(p)), arg, 1, true) then
      matches[#matches + 1] = p
    end
  end
  if #matches == 1 then return matches[1] end
  return nil
end

local function cmdKick(player, args)
  if not hasPerm(player, "kick") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local targetArg, reason = string.match(tostring(args or ""), "^(%S+)%s*(.*)$")
  local target = findTarget(targetArg)
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi. Kullanim: /kick [ID/isim] [sebep]")
    return
  end
  reason = (reason and reason ~= "") and reason or "Admin kick"
  output(player, "#60C060" .. cleanName(target) .. " atildi.")
  kickPlayer(target, player, reason)
end

local function cmdBan(player, args)
  if not hasPerm(player, "ban") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local targetArg, reason = string.match(tostring(args or ""), "^(%S+)%s*(.*)$")
  local target = findTarget(targetArg)
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi. Kullanim: /ban [ID/isim] [sebep]")
    return
  end
  reason = (reason and reason ~= "") and reason or "Admin ban"
  local name = cleanName(target)
  banPlayer(target, true, false, true, player, reason)
  output(player, "#60C060" .. name .. " banlandi.")
end

local function cmdGoto(player, args)
  if not hasPerm(player, "goto") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local target = findTarget(tostring(args or ""):match("^(%S+)"))
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi. Kullanim: /goto [ID/isim]")
    return
  end
  local x, y, z = getElementPosition(target)
  setElementPosition(player, x + 1, y, z)
  setElementInterior(player, getElementInterior(target))
  setElementDimension(player, getElementDimension(target))
  output(player, "#60C060" .. cleanName(target) .. " konumuna isinlandin.")
end

local function cmdGethere(player, args)
  if not hasPerm(player, "gethere") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local target = findTarget(tostring(args or ""):match("^(%S+)"))
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi. Kullanim: /gethere [ID/isim]")
    return
  end
  local x, y, z = getElementPosition(player)
  setElementPosition(target, x + 1, y, z)
  setElementInterior(target, getElementInterior(player))
  setElementDimension(target, getElementDimension(player))
  output(player, "#60C060" .. cleanName(target) .. " yanina cekildi.")
  output(target, "#5AA0FFBir admin seni yanina cekti.")
end

local function cmdFreeze(player, args)
  if not hasPerm(player, "freeze") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local target = findTarget(tostring(args or ""):match("^(%S+)"))
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi.")
    return
  end
  setElementFrozen(target, true)
  output(player, "#60C060" .. cleanName(target) .. " donduruldu.")
end

local function cmdUnfreeze(player, args)
  if not hasPerm(player, "unfreeze") and not hasPerm(player, "freeze") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local target = findTarget(tostring(args or ""):match("^(%S+)"))
  if not target then
    output(player, "#FF6464Oyuncu bulunamadi.")
    return
  end
  setElementFrozen(target, false)
  output(player, "#60C060" .. cleanName(target) .. " cozuldu.")
end

local function cmdTp(player, args)
  if not hasPerm(player, "tpto") and not hasPerm(player, "goto") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local x, y, z = string.match(tostring(args or ""), "^(%S+)%s+(%S+)%s+(%S+)")
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  if not x or not y or not z then
    output(player, "#FF6464Kullanim: /tp [x] [y] [z]")
    return
  end
  setElementPosition(player, x, y, z)
  output(player, "#60C060Isinlandin.")
end

local function cmdInvisible(player, args)
  if not hasPerm(player, "invisible") then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  local state = not getElementData(player, "stage_chat:invisible")
  setElementData(player, "stage_chat:invisible", state)
  setElementAlpha(player, state and 0 or 255)
  output(player, state and "#60C060Gorunmez oldun." or "#60C060Gorunur oldun.")
end

local function cmdMyrank(player, args)
  local rank = "User"
  local res = getResourceFromName("stage_admin")
  if res and getResourceState(res) == "running" then
    local ok, r = pcall(function()
      return exports.stage_admin:AdminGetRank(player)
    end)
    if ok and r then rank = r end
  end
  output(player, "#5AA0FFRutben: #FFFFFF" .. tostring(rank))
end


local function cmdDepoolustur(player, args)
  if not isStaff(player) then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  -- stage_admin / baska resource varsa oraya birak
  local ok = false
  local okExec, res = pcall(function()
    local a = tostring(args or "")
    if a ~= "" then
      return executeCommandHandler("depoolustur", player, a)
    end
    return executeCommandHandler("depoolustur", player)
  end)
  ok = okExec and res
  if not ok then
    output(player, "#FFC20E/depoolustur bu sunucuda tanimli degil veya ACL engeli var.")
  end
end

local function cmdAdmincommands(player, args)
  if not isStaff(player) then
    output(player, "#FF6464Yetkin yok.")
    return
  end
  output(player, "#5AA0FFAdmin komutlari: #FFFFFF/a /cv /dv /dva /noon /night /kick /ban /goto /gethere /freeze /tp /invisible /duyuru /myrank")
  output(player, "#5AA0FFChat ayarlari: #FFFFFF/chat")
end

local localCommands = {
  me = cmdMe,
  ["do"] = cmdDo,
  pm = cmdPm,
  msg = cmdPm,
  duyuru = cmdDuyuru,
  a = cmdA,
  cv = cmdCv,
  dv = cmdDv,
  dva = cmdDva,
  noon = cmdNoon,
  night = cmdNight,
  kick = cmdKick,
  ban = cmdBan,
  goto = cmdGoto,
  gethere = cmdGethere,
  freeze = cmdFreeze,
  unfreeze = cmdUnfreeze,
  tp = cmdTp,
  invisible = cmdInvisible,
  myrank = cmdMyrank,
  depoolustur = cmdDepoolustur,
  admincommands = cmdAdmincommands,
}

-- Konsoldan /me yazilinca da calissin
addCommandHandler("me", function(player, _, ...)
  if not isElement(player) then return end
  cmdMe(player, table.concat({ ... }, " "))
end, false, false)

addCommandHandler("do", function(player, _, ...)
  if not isElement(player) then return end
  cmdDo(player, table.concat({ ... }, " "))
end, false, false)

addCommandHandler("pm", function(player, _, ...)
  if not isElement(player) then return end
  cmdPm(player, table.concat({ ... }, " "))
end, false, false)

addCommandHandler("msg", function(player, _, ...)
  if not isElement(player) then return end
  cmdPm(player, table.concat({ ... }, " "))
end, false, false)

addCommandHandler("duyuru", function(player, _, ...)
  if not isElement(player) then return end
  cmdDuyuru(player, table.concat({ ... }, " "))
end, false, false)

-- ================= Chat mesaj / komut =================

local function onPlayerChat(message, messageType)
  cancelEvent()
  if not isDefaultOutput then return end
  messageType = tonumber(messageType) or 0
  if messageType ~= 0 and messageType ~= 2 then return end

  local sender = source
  if not isElement(sender) then return end

  local nickname = cleanName(sender)
  local nr, ng, nb = getPlayerNametagColor(sender)
  local nicknameColor = RGBToHex(nr, ng, nb)
  local pid = getPID(sender)
  local text = string.format("#AAAAAA[%s] %s%s#FFFFFF: %s", pid, nicknameColor, nickname, tostring(message))

  if messageType == 0 then
    for _, player in ipairs(getElementsByType("player")) do
      output(player, text)
    end
  elseif messageType == 2 then
    local team = getPlayerTeam(sender)
    if team then
      local tr, tg, tb = getTeamColor(team)
      text = string.format("%s(team) %s", RGBToHex(tr, tg, tb), text)
      for _, player in ipairs(getPlayersInTeam(team)) do
        output(player, text)
      end
    end
  end
end


local function handleResourceCommand(player, cmd, resName)
  if not isStaff(player) and not hasPerm(player, cmd) then
    output(player, "#FF6464Yetkiniz yok.")
    return
  end
  cmd = cmd:lower()
  if cmd == "refresh" then
    refreshResources(true)
    output(player, "#60C060Kaynaklar başarıyla yenilendi (refresh).")
    return
  end
  if not resName or resName == "" then
    output(player, "#FFC20EKullanım: /" .. cmd .. " [kaynak_adi]")
    return
  end
  local target = getResourceFromName(resName)
  if not target then
    output(player, "#FF6464Kaynak bulunamadı: " .. resName)
    return
  end
  if cmd == "start" then
    local ok = startResource(target)
    if ok then output(player, "#60C060" .. resName .. " başlatıldı.")
    else output(player, "#FF6464" .. resName .. " başlatılamadı.") end
  elseif cmd == "restart" then
    local ok = restartResource(target)
    if ok then output(player, "#60C060" .. resName .. " yeniden başlatıldı.")
    else output(player, "#FF6464" .. resName .. " yeniden başlatılamadı.") end
  elseif cmd == "stop" then
    local ok = stopResource(target)
    if ok then output(player, "#60C060" .. resName .. " durduruldu.")
    else output(player, "#FF6464" .. resName .. " durdurulamadı.") end
  end
end

local function handleCommand(player, input)
  if not isElement(player) then return end
  if getElementType(player) ~= "player" then return end

  input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if input == "" or input:sub(1, 1) ~= "/" then return end

  local body = input:sub(2)
  local cmd, rest = string.match(body, "^([%w_]+)%s*(.*)$")
  if not cmd or cmd == "" then return end
  cmd = string.lower(cmd)
  rest = tostring(rest or "")

  -- 0) MTA Sunucu yönetim komutları (/start, /restart, /stop, /refresh)
  if cmd == "start" or cmd == "restart" or cmd == "stop" or cmd == "refresh" then
    handleResourceCommand(player, cmd, rest:match("^(%S+)"))
    return
  end

  -- 1) Yerel komutlar: ACL / executeCommandHandler YOK
  local fn = localCommands[cmd]
  if fn then
    fn(player, rest)
    return
  end

  -- 2) Başka resource komutları (tüm script komutları)
  local ok, result = pcall(function()
    if rest ~= "" then
      return executeCommandHandler(cmd, player, rest)
    else
      return executeCommandHandler(cmd, player)
    end
  end)

  if not ok then
    output(player, "#FF6464Komut çalıştırılamadı (ACL). acl.xml dosyasında resource.stage_chat öğesini Admin grubuna ekleyin.")
    outputServerLog("[stage_chat] executeCommandHandler hata: /" .. cmd .. " " .. tostring(result))
    return
  end
end

local function onChatMessage(message, messageType)
  local player = client
  if not isElement(player) then return end
  if type(message) ~= "string" then return end

  message = message:gsub("^%s+", ""):gsub("%s+$", "")
  if message == "" then return end
  if string.len(message) > maxLength then return end

  if message:sub(1, 1) == "/" then
    handleCommand(player, message)
    return
  end

  triggerEvent("onPlayerChat", player, message, tonumber(messageType) or 0)
end

-- outputChatBox hook (ACL gerekebilir)
local function listenForOutputChatBox(_, _, _, _, _, message, receiver, r, g, b)
  receiver = receiver or root
  local hex = ""
  if r and g and b then
    hex = RGBToHex(r, g, b) or ""
  end
  output(receiver, tostring(hex) .. tostring(message or ""))
  return "skip"
end

local function listenForShowChat(_, _, _, _, _, player, bool)
  if isElement(player) then
    show(player, bool)
  end
  return "skip"
end

local function listenForClearChatBox(_, _, _, _, _, player)
  if isElement(player) then
    clear(player)
  end
  return "skip"
end

addEventHandler("onResourceStart", resourceRoot, function()
  pcall(function()
    addDebugHook("preFunction", listenForOutputChatBox, { "outputChatBox" })
    addDebugHook("preFunction", listenForShowChat, { "showChat" })
    addDebugHook("preFunction", listenForClearChatBox, { "clearChatBox" })
  end)
  outputServerLog("[stage_chat] yuklendi. /me /do /pm ACL gerektirmez. /cv /a icin resource.stage_chat Admin grubunda olmali.")
end)

addEventHandler("onResourceStop", resourceRoot, function()
  pcall(function()
    removeDebugHook("preFunction", listenForOutputChatBox)
    removeDebugHook("preFunction", listenForShowChat)
    removeDebugHook("preFunction", listenForClearChatBox)
  end)
end)

addEventHandler("onPlayerChat", root, onPlayerChat)
addEventHandler("onChat2Message", resourceRoot, onChatMessage)
