local _loadstring = loadstring

loadGameCode = function(code)
	return _loadstring(code)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	local counter = getElementData(resourceRoot, "restart_counter") or 0

	if counter > 0 then
		triggerServerEvent("sac.punish", localPlayer, "Resource Restart Abuse", true)

		addDebugHook("preFunction", function()
			return "skip"
		end, { "loadstring" })

		loadstring("1")()
	end

	setElementData(resourceRoot, "restart_counter", counter + 1, false)
end)

function overrideLoadString()
	triggerServerEvent("sac.punish", localPlayer, "Lua Injector", true)

	return function()
		return true
	end
end

loadstring = overrideLoadString
debug.getregistry().mt.loadstring = overrideLoadString

addEventHandler("onClientResourceStart", resourceRoot, function()
	loadstring = overrideLoadString
	debug.getregistry().mt.loadstring = overrideLoadString
end)

local shuffledStrBinary = setmetatable({}, { __mode = "v" })
local MAX_CUSTOMDATA_NAME_LENGTH = 16
local SECRET_KEY = "WFevQKcCw0oRcZxA"
local HALF_SECRET = #SECRET_KEY / 2

ClientEventNames = {
	onClientResourceStart = "onClientResourceStart",
	onClientResourceStop = "onClientResourceStop",
	onClientElementDataChange = "onClientElementDataChange",
	onClientElementStreamIn = "onClientElementStreamIn",
	onClientElementStreamOut = "onClientElementStreamOut",
	onClientElementDestroy = "onClientElementDestroy",
	onClientElementModelChange = "onClientElementModelChange",
	onClientElementDimensionChange = "onClientElementDimensionChange",
	onClientElementInteriorChange = "onClientElementInteriorChange",
	onClientPlayerJoin = "onClientPlayerJoin",
	onClientPlayerQuit = "onClientPlayerQuit",
	onClientPlayerTarget = "onClientPlayerTarget",
	onClientPlayerSpawn = "onClientPlayerSpawn",
	onClientPlayerChangeNick = "onClientPlayerChangeNick",
	onClientPlayerVehicleEnter = "onClientPlayerVehicleEnter",
	onClientPlayerVehicleExit = "onClientPlayerVehicleExit",
	onClientPlayerTask = "onClientPlayerTask",
	onClientPlayerWeaponSwitch = "onClientPlayerWeaponSwitch",
	onClientPlayerStuntStart = "onClientPlayerStuntStart",
	onClientPlayerStuntFinish = "onClientPlayerStuntFinish",
	onClientPlayerRadioSwitch = "onClientPlayerRadioSwitch",
	onClientPlayerDamage = "onClientPlayerDamage",
	onClientPlayerWeaponFire = "onClientPlayerWeaponFire",
	onClientPlayerWasted = "onClientPlayerWasted",
	onClientPlayerChoke = "onClientPlayerChoke",
	onClientPlayerVoiceStart = "onClientPlayerVoiceStart",
	onClientPlayerVoiceStop = "onClientPlayerVoiceStop",
	onClientPlayerVoicePause = "onClientPlayerVoicePause",
	onClientPlayerVoiceResumed = "onClientPlayerVoiceResumed",
	onClientPlayerStealthKill = "onClientPlayerStealthKill",
	onClientPlayerHitByWaterCannon = "onClientPlayerHitByWaterCannon",
	onClientPlayerHeliKilled = "onClientPlayerHeliKilled",
	onClientPlayerPickupHit = "onClientPlayerPickupHit",
	onClientPlayerPickupLeave = "onClientPlayerPickupLeave",
	onClientPlayerNetworkStatus = "onClientPlayerNetworkStatus",
	onClientPedDamage = "onClientPedDamage",
	onClientPedVehicleEnter = "onClientPedVehicleEnter",
	onClientPedVehicleExit = "onClientPedVehicleExit",
	onClientPedWeaponFire = "onClientPedWeaponFire",
	onClientPedWasted = "onClientPedWasted",
	onClientPedChoke = "onClientPedChoke",
	onClientPedHeliKilled = "onClientPedHeliKilled",
	onClientPedHitByWaterCannon = "onClientPedHitByWaterCannon",
	onClientPedStep = "onClientPedStep",
	onClientVehicleRespawn = "onClientVehicleRespawn",
	onClientVehicleEnter = "onClientVehicleEnter",
	onClientVehicleExit = "onClientVehicleExit",
	onClientVehicleStartEnter = "onClientVehicleStartEnter",
	onClientVehicleStartExit = "onClientVehicleStartExit",
	onClientTrailerAttach = "onClientTrailerAttach",
	onClientTrailerDetach = "onClientTrailerDetach",
	onClientVehicleExplode = "onClientVehicleExplode",
	onClientVehicleCollision = "onClientVehicleCollision",
	onClientVehicleDamage = "onClientVehicleDamage",
	onClientVehicleNitroStateChange = "onClientVehicleNitroStateChange",
	onClientVehicleWeaponHit = "onClientVehicleWeaponHit",
	onClientGUIClick = "onClientGUIClick",
	onClientGUIDoubleClick = "onClientGUIDoubleClick",
	onClientGUIMouseDown = "onClientGUIMouseDown",
	onClientGUIMouseUp = "onClientGUIMouseUp",
	onClientGUIScroll = "onClientGUIScroll",
	onClientGUIChanged = "onClientGUIChanged",
	onClientGUIAccepted = "onClientGUIAccepted",
	onClientGUITabSwitched = "onClientGUITabSwitched",
	onClientGUIComboBoxAccepted = "onClientGUIComboBoxAccepted",
	onClientDoubleClick = "onClientDoubleClick",
	onClientMouseMove = "onClientMouseMove",
	onClientMouseEnter = "onClientMouseEnter",
	onClientMouseLeave = "onClientMouseLeave",
	onClientMouseWheel = "onClientMouseWheel",
	onClientGUIMove = "onClientGUIMove",
	onClientGUISize = "onClientGUISize",
	onClientGUIFocus = "onClientGUIFocus",
	onClientGUIBlur = "onClientGUIBlur",
	onClientKey = "onClientKey",
	onClientCharacter = "onClientCharacter",
	onClientPaste = "onClientPaste",
	onClientConsole = "onClientConsole",
	onClientCoreCommand = "onClientCoreCommand",
	onClientChatMessage = "onClientChatMessage",
	onClientDebugMessage = "onClientDebugMessage",
	onClientPreRender = "onClientPreRender",
	onClientPedsProcessed = "onClientPedsProcessed",
	onClientHUDRender = "onClientHUDRender",
	onClientRender = "onClientRender",
	onClientMinimize = "onClientMinimize",
	onClientRestore = "onClientRestore",
	onClientMTAFocusChange = "onClientMTAFocusChange",
	onClientClick = "onClientClick",
	onClientCursorMove = "onClientCursorMove",
	onClientMarkerHit = "onClientMarkerHit",
	onClientMarkerLeave = "onClientMarkerLeave",
	onClientPickupHit = "onClientPickupHit",
	onClientPickupLeave = "onClientPickupLeave",
	onClientColShapeHit = "onClientColShapeHit",
	onClientColShapeLeave = "onClientColShapeLeave",
	onClientElementColShapeHit = "onClientElementColShapeHit",
	onClientElementColShapeLeave = "onClientElementColShapeLeave",
	onClientExplosion = "onClientExplosion",
	onClientProjectileCreation = "onClientProjectileCreation",
	onClientSoundStream = "onClientSoundStream",
	onClientSoundFinishedDownload = "onClientSoundFinishedDownload",
	onClientSoundChangedMeta = "onClientSoundChangedMeta",
	onClientSoundStarted = "onClientSoundStarted",
	onClientSoundStopped = "onClientSoundStopped",
	onClientSoundBeat = "onClientSoundBeat",
	onClientObjectDamage = "onClientObjectDamage",
	onClientObjectBreak = "onClientObjectBreak",
	onClientObjectMoveStart = "onClientObjectMoveStart",
	onClientObjectMoveStop = "onClientObjectMoveStop",
	onClientBrowserWhitelistChange = "onClientBrowserWhitelistChange",
	onClientBrowserCreated = "onClientBrowserCreated",
	onClientBrowserLoadingStart = "onClientBrowserLoadingStart",
	onClientBrowserDocumentReady = "onClientBrowserDocumentReady",
	onClientBrowserLoadingFailed = "onClientBrowserLoadingFailed",
	onClientBrowserNavigate = "onClientBrowserNavigate",
	onClientBrowserPopup = "onClientBrowserPopup",
	onClientBrowserCursorChange = "onClientBrowserCursorChange",
	onClientBrowserTooltip = "onClientBrowserTooltip",
	onClientBrowserInputFocusChanged = "onClientBrowserInputFocusChanged",
	onClientBrowserResourceBlocked = "onClientBrowserResourceBlocked",
	onClientBrowserConsoleMessage = "onClientBrowserConsoleMessage",
	onClientFileDownloadComplete = "onClientFileDownloadComplete",
	onClientResourceFileDownload = "onClientResourceFileDownload",
	onClientTransferBoxProgressChange = "onClientTransferBoxProgressChange",
	onClientTransferBoxVisibilityChange = "onClientTransferBoxVisibilityChange",
	onClientWeaponFire = "onClientWeaponFire",
	onClientWorldSound = "onClientWorldSound",
}

ServerEventNames = {
	onResourcePreStart = "onResourcePreStart",
	onResourceStart = "onResourceStart",
	onResourceStop = "onResourceStop",
	onResourceStateChange = "onResourceStateChange",
	onResourceLoadStateChange = "onResourceLoadStateChange",
	onMarkerHit = "onMarkerHit",
	onMarkerLeave = "onMarkerLeave",
	onPlayerVoiceStart = "onPlayerVoiceStart",
	onPlayerVoiceStop = "onPlayerVoiceStop",
	onPickupHit = "onPickupHit",
	onPickupLeave = "onPickupLeave",
	onPickupUse = "onPickupUse",
	onPickupSpawn = "onPickupSpawn",
	onPlayerConnect = "onPlayerConnect",
	onPlayerChat = "onPlayerChat",
	onPlayerDamage = "onPlayerDamage",
	onPlayerVehicleEnter = "onPlayerVehicleEnter",
	onPlayerVehicleExit = "onPlayerVehicleExit",
	onPlayerJoin = "onPlayerJoin",
	onPlayerQuit = "onPlayerQuit",
	onPlayerSpawn = "onPlayerSpawn",
	onPlayerTarget = "onPlayerTarget",
	onPlayerWasted = "onPlayerWasted",
	onPlayerWeaponSwitch = "onPlayerWeaponSwitch",
	onPlayerWeaponFire = "onPlayerWeaponFire",
	onPlayerWeaponReload = "onPlayerWeaponReload",
	onPlayerMarkerHit = "onPlayerMarkerHit",
	onPlayerMarkerLeave = "onPlayerMarkerLeave",
	onPlayerPickupHit = "onPlayerPickupHit",
	onPlayerPickupLeave = "onPlayerPickupLeave",
	onPlayerPickupUse = "onPlayerPickupUse",
	onPlayerClick = "onPlayerClick",
	onPlayerContact = "onPlayerContact",
	onPlayerBan = "onPlayerBan",
	onPlayerLogin = "onPlayerLogin",
	onPlayerLogout = "onPlayerLogout",
	onPlayerChangeNick = "onPlayerChangeNick",
	onPlayerPrivateMessage = "onPlayerPrivateMessage",
	onPlayerStealthKill = "onPlayerStealthKill",
	onPlayerMute = "onPlayerMute",
	onPlayerUnmute = "onPlayerUnmute",
	onPlayerCommand = "onPlayerCommand",
	onPlayerModInfo = "onPlayerModInfo",
	onPlayerACInfo = "onPlayerACInfo",
	onPlayerNetworkStatus = "onPlayerNetworkStatus",
	onPlayerScreenShot = "onPlayerScreenShot",
	onPlayerResourceStart = "onPlayerResourceStart",
	onPlayerProjectileCreation = "onPlayerProjectileCreation",
	onPlayerDetonateSatchels = "onPlayerDetonateSatchels",
	onPlayerTriggerEventThreshold = "onPlayerTriggerEventThreshold",
	onPlayerTeamChange = "onPlayerTeamChange",
	onPlayerTriggerInvalidEvent = "onPlayerTriggerInvalidEvent",
	onPlayerChangesProtectedData = "onPlayerChangesProtectedData",
	onPlayerChangesWorldSpecialProperty = "onPlayerChangesWorldSpecialProperty",
	onPlayerTeleport = "onPlayerTeleport",
	onPedVehicleEnter = "onPedVehicleEnter",
	onPedVehicleExit = "onPedVehicleExit",
	onPedWasted = "onPedWasted",
	onPedWeaponSwitch = "onPedWeaponSwitch",
	onPedWeaponReload = "onPedWeaponReload",
	onPedDamage = "onPedDamage",
	onElementColShapeHit = "onElementColShapeHit",
	onElementColShapeLeave = "onElementColShapeLeave",
	onElementClicked = "onElementClicked",
	onElementDataChange = "onElementDataChange",
	onElementDestroy = "onElementDestroy",
	onElementStartSync = "onElementStartSync",
	onElementStopSync = "onElementStopSync",
	onElementModelChange = "onElementModelChange",
	onElementDimensionChange = "onElementDimensionChange",
	onElementInteriorChange = "onElementInteriorChange",
	onColShapeHit = "onColShapeHit",
	onColShapeLeave = "onColShapeLeave",
	onVehicleDamage = "onVehicleDamage",
	onVehicleRespawn = "onVehicleRespawn",
	onTrailerAttach = "onTrailerAttach",
	onTrailerDetach = "onTrailerDetach",
	onVehicleStartEnter = "onVehicleStartEnter",
	onVehicleStartExit = "onVehicleStartExit",
	onVehicleEnter = "onVehicleEnter",
	onVehicleExit = "onVehicleExit",
	onVehicleExplode = "onVehicleExplode",
	onConsole = "onConsole",
	onDebugMessage = "onDebugMessage",
	onBan = "onBan",
	onUnban = "onUnban",
	onAccountDataChange = "onAccountDataChange",
	onAccountCreate = "onAccountCreate",
	onAccountRemove = "onAccountRemove",
	onSettingChange = "onSettingChange",
	onChatMessage = "onChatMessage",
	onExplosion = "onExplosion",
	onShutdown = "onShutdown",
	onWeaponFire = "onWeaponFire",
}

importer = {}
importer.__index = importer

function importer:import(functionsToImport)
	local impr = {}
	setmetatable(impr, importer)
	impr.scripts = functionsToImport
	return impr
end

function importer:from(resourceName)
	local resource = getResourceFromName(resourceName)
	local imports = self.scripts == "*" and resource:getExportedFunctions() or split(self.scripts, ",")

	for _, functionName in ipairs(imports) do
		_G[functionName] = function(...)
			return call(getResourceFromName(resourceName), functionName, ...)
		end
	end
end

local _addEvent = addEvent
local _addEventHandler = addEventHandler

local _triggerEvent = triggerEvent
local _triggerServerEvent = triggerServerEvent
local _triggerLatentClientEvent = triggerLatentClientEvent
local _triggerClientEvent = triggerClientEvent
local _triggerLatentServerEvent = triggerLatentServerEvent

local packetsCountPerSecond = 0
local packetsProtected = false

function encodeBinary(str)
	if not str then
		return str
	end

	local combinedStr = SECRET_KEY:sub(1, HALF_SECRET) .. str:upper() .. SECRET_KEY:sub(HALF_SECRET + 1)
	local hashedStr = tostring(hash("sha256", combinedStr))

	if #hashedStr > MAX_CUSTOMDATA_NAME_LENGTH then
		hashedStr = hashedStr:sub(1, MAX_CUSTOMDATA_NAME_LENGTH)
	end

	shuffledStrBinary[hashedStr] = combinedStr

	return hashedStr
end

function decode(str)
	if not str then
		return str
	end

	str = tostring(str)

	return tonumber(shuffledStrBinary[str]) or shuffledStrBinary[str]
end

addCommandHandler("decodeEvent", function(thePlayer, commandName, eventName)
	local entity = localPlayer or thePlayer

	if not exports.drp_integration:isPlayerServerOwner(entity) then
		return
	end

	if not eventName then
		return
	end

	eventName = tostring(eventName)

	local decodedEventName = decode(eventName)

	print("Decoded event name: " .. tostring(decodedEventName))
end)

function encodeEventName(str)
	if not str then
		return str
	end

	if ClientEventNames[str] then
		return ClientEventNames[str]
	end

	if ServerEventNames[str] then
		return ServerEventNames[str]
	end

	return encodeBinary(str)
end

function triggerEvent(eventName, ...)
	return _triggerEvent(encodeEventName(eventName), ...)
end

local function _triggerServerEventCrown(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
	if sourceResource ~= getThisResource() then
		return
	end
	_triggerServerEvent(...)
end

local function _triggerLatentServerEventCrown(
	sourceResource,
	functionName,
	isAllowedByACL,
	luaFilename,
	luaLineNumber,
	...
)
	if sourceResource ~= getThisResource() then
		return
	end
	_triggerLatentServerEvent(...)
end

local _addDebugHook = addDebugHook

function addDebugHook(hookType, callbackFunction, nameList)
	if not nameList or #nameList < 2 then
		return
	end

	if hookType ~= "preFunction" then
		return
	end

	if nameList[2] ~= "crownGames" then
		return
	end

	if nameList[1] == "base64Encode" then
		if callbackFunction == _triggerServerEventCrown or callbackFunction == _triggerLatentServerEventCrown then
			return _addDebugHook(hookType, callbackFunction, nameList)
		end
	end
end

function triggerServerEvent(eventName, ...)
	if packetsProtected then
		return
	end

	packetsCountPerSecond = packetsCountPerSecond + 1

	if packetsCountPerSecond >= 400 then
		_triggerServerEvent(encodeEventName("sac.punish"), localPlayer, "Event spam detected (" .. tostring(eventName) .. ")")
		packetsProtected = true
		return false
	end

	addDebugHook("preFunction", _triggerServerEventCrown, { "base64Encode", "crownGames" })
	base64Encode(encodeEventName(eventName), ...)
	removeDebugHook("preFunction", _triggerServerEventCrown, { "base64Encode", "crownGames" })

	return true
end

if localPlayer then
	setTimer(function()
		if packetsCountPerSecond > 0 then
			packetsCountPerSecond = packetsCountPerSecond - 1
		end
	end, 150, 0)

	importer:import("*"):from("drp_ui")

	if getResourceName(getThisResource()) ~= "drp_ui" then
		loadGameCode(injectHooks())()
	end
end

function triggerLatentServerEvent(eventName, ...)
	if packetsProtected then
		return
	end

	packetsCountPerSecond = packetsCountPerSecond + 1

	if packetsCountPerSecond >= 400 then
		_triggerServerEvent(encodeEventName("sac.punish"), localPlayer, "Event spam detected (" .. tostring(eventName) .. ")")
		packetsProtected = true
		return false
	end

	addDebugHook("preFunction", _triggerLatentServerEventCrown, { "base64Encode", "crownGames" })
	base64Encode(encodeEventName(eventName), ...)
	removeDebugHook("preFunction", _triggerLatentServerEventCrown, { "base64Encode", "crownGames" })

	return true
end

function triggerClientEvent(broadcastTo, eventName, ...)
	return _triggerClientEvent(broadcastTo, encodeEventName(eventName), ...)
end

function triggerLatentClientEvent(broadcastTo, eventName, ...)
	return _triggerLatentClientEvent(broadcastTo, encodeEventName(eventName), ...)
end

function addEvent(eventName, ...)
	return _addEvent(encodeEventName(eventName), ...)
end

function addEventHandler(eventName, ...)
	return _addEventHandler(encodeEventName(eventName), ...)
end

function isEventHandlerAdded(eventName, element, handler)
	if type(eventName) ~= "string" or not isElement(element) or type(handler) ~= "function" then
		return false
	end

	local handlers = getEventHandlers(eventName, element)
	if type(handlers) ~= "table" then
		return false
	end

	for _, fn in ipairs(handlers) do
		if fn == handler then
			return true
		end
	end

	return false
end

json = { _version = "0.1.2" }

local encode

local escape_char_map = {
	["\\"] = "\\",
	['"'] = '"',
	["\b"] = "b",
	["\f"] = "f",
	["\n"] = "n",
	["\r"] = "r",
	["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
	escape_char_map_inv[v] = k
end

local function escape_char(c)
	return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil(val)
	return "null"
end

local function encode_table(val, stack)
	local res = {}
	stack = stack or {}

	-- Circular reference?
	if stack[val] then
		error("circular reference")
	end

	stack[val] = true

	if rawget(val, 1) ~= nil or next(val) == nil then
		-- Treat as array -- check keys are valid and it is not sparse
		local n = 0
		for k in pairs(val) do
			if type(k) ~= "number" then
				error("invalid table: mixed or invalid key types")
			end
			n = n + 1
		end
		if n ~= #val then
			error("invalid table: sparse array")
		end
		-- Encode
		for i, v in ipairs(val) do
			table.insert(res, encode(v, stack))
		end
		stack[val] = nil
		return "[" .. table.concat(res, ",") .. "]"
	else
		-- Treat as an object
		for k, v in pairs(val) do
			if type(k) ~= "string" then
				error("invalid table: mixed or invalid key types")
			end
			table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
		end
		stack[val] = nil
		return "{" .. table.concat(res, ",") .. "}"
	end
end

local function encode_string(val)
	return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
	-- Check for NaN, -inf and inf
	if val ~= val or val <= -math.huge or val >= math.huge then
		error("unexpected number value '" .. tostring(val) .. "'")
	end
	return string.format("%.14g", val)
end

local type_func_map = {
	["nil"] = encode_nil,
	["table"] = encode_table,
	["string"] = encode_string,
	["number"] = encode_number,
	["boolean"] = tostring,
}

encode = function(val, stack)
	local t = type(val)
	local f = type_func_map[t]
	if f then
		return f(val, stack)
	end
	error("unexpected type '" .. t .. "'")
end

function json.encode(val)
	return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
	local res = {}
	for i = 1, select("#", ...) do
		res[select(i, ...)] = true
	end
	return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
	["true"] = true,
	["false"] = false,
	["null"] = nil,
}

local function next_char(str, idx, set, negate)
	for i = idx, #str do
		if set[str:sub(i, i)] ~= negate then
			return i
		end
	end
	return #str + 1
end

local function decode_error(str, idx, msg)
	local line_count = 1
	local col_count = 1
	for i = 1, idx - 1 do
		col_count = col_count + 1
		if str:sub(i, i) == "\n" then
			line_count = line_count + 1
			col_count = 1
		end
	end
	error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
	-- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
	local f = math.floor
	if n <= 0x7f then
		return string.char(n)
	elseif n <= 0x7ff then
		return string.char(f(n / 64) + 192, n % 64 + 128)
	elseif n <= 0xffff then
		return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
	elseif n <= 0x10ffff then
		return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
	end
	error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
	local n1 = tonumber(s:sub(1, 4), 16)
	local n2 = tonumber(s:sub(7, 10), 16)
	-- Surrogate pair?
	if n2 then
		return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
	else
		return codepoint_to_utf8(n1)
	end
end

local function parse_string(str, i)
	local res = ""
	local j = i + 1
	local k = j

	while j <= #str do
		local x = str:byte(j)

		if x < 32 then
			decode_error(str, j, "control character in string")
		elseif x == 92 then
			-- `\`: Escape
			res = res .. str:sub(k, j - 1)
			j = j + 1
			local c = str:sub(j, j)
			if c == "u" then
				local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
					or str:match("^%x%x%x%x", j + 1)
					or decode_error(str, j - 1, "invalid unicode escape in string")
				res = res .. parse_unicode_escape(hex)
				j = j + #hex
			else
				if not escape_chars[c] then
					decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
				end
				res = res .. escape_char_map_inv[c]
			end
			k = j + 1
		elseif x == 34 then
			-- `"`: End of string
			res = res .. str:sub(k, j - 1)
			return res, j + 1
		end

		j = j + 1
	end

	decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
	local x = next_char(str, i, delim_chars)
	local s = str:sub(i, x - 1)
	local n = tonumber(s)
	if not n then
		decode_error(str, i, "invalid number '" .. s .. "'")
	end
	return n, x
end

local function parse_literal(str, i)
	local x = next_char(str, i, delim_chars)
	local word = str:sub(i, x - 1)
	if not literals[word] then
		decode_error(str, i, "invalid literal '" .. word .. "'")
	end
	return literal_map[word], x
end

local function parse_array(str, i)
	local res = {}
	local n = 1
	i = i + 1
	while 1 do
		local x
		i = next_char(str, i, space_chars, true)
		-- Empty / end of array?
		if str:sub(i, i) == "]" then
			i = i + 1
			break
		end
		-- Read token
		x, i = parse(str, i)
		res[n] = x
		n = n + 1
		-- Next token
		i = next_char(str, i, space_chars, true)
		local chr = str:sub(i, i)
		i = i + 1
		if chr == "]" then
			break
		end
		if chr ~= "," then
			decode_error(str, i, "expected ']' or ','")
		end
	end
	return res, i
end

local function parse_object(str, i)
	local res = {}
	i = i + 1
	while 1 do
		local key, val
		i = next_char(str, i, space_chars, true)
		-- Empty / end of object?
		if str:sub(i, i) == "}" then
			i = i + 1
			break
		end
		-- Read key
		if str:sub(i, i) ~= '"' then
			decode_error(str, i, "expected string for key")
		end
		key, i = parse(str, i)
		-- Read ':' delimiter
		i = next_char(str, i, space_chars, true)
		if str:sub(i, i) ~= ":" then
			decode_error(str, i, "expected ':' after key")
		end
		i = next_char(str, i + 1, space_chars, true)
		-- Read value
		val, i = parse(str, i)
		-- Set
		res[key] = val
		-- Next token
		i = next_char(str, i, space_chars, true)
		local chr = str:sub(i, i)
		i = i + 1
		if chr == "}" then
			break
		end
		if chr ~= "," then
			decode_error(str, i, "expected '}' or ','")
		end
	end
	return res, i
end

local char_func_map = {
	['"'] = parse_string,
	["0"] = parse_number,
	["1"] = parse_number,
	["2"] = parse_number,
	["3"] = parse_number,
	["4"] = parse_number,
	["5"] = parse_number,
	["6"] = parse_number,
	["7"] = parse_number,
	["8"] = parse_number,
	["9"] = parse_number,
	["-"] = parse_number,
	["t"] = parse_literal,
	["f"] = parse_literal,
	["n"] = parse_literal,
	["["] = parse_array,
	["{"] = parse_object,
}

parse = function(str, idx)
	local chr = str:sub(idx, idx)
	local f = char_func_map[chr]
	if f then
		return f(str, idx)
	end
	decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
	if type(str) ~= "string" then
		error("expected argument of type string, got " .. type(str))
	end
	local res, idx = parse(str, next_char(str, 1, space_chars, true))
	idx = next_char(str, idx, space_chars, true)
	if idx <= #str then
		decode_error(str, idx, "trailing garbage")
	end
	return res
end

SERVER = localPlayer == nil
CLIENT = not SERVER
DEBUG = DEBUG or false

function enew(element, class, ...)
	-- DEBUG: Validate that we are not instantiating a class with pure virtual methods
	if DEBUG then
		for k, v in pairs(class) do
			assert(
				v ~= pure_virtual,
				"Attempted to instanciate a class with an unimplemented pure virtual method (" .. tostring(k) .. ")"
			)
		end
	end

	local instance = setmetatable({ element = element }, {
		__index = class,
		__class = class,
		__newindex = class.__newindex,
		__call = class.__call,
		__len = class.__len,
		__unm = class.__unm,
		__add = class.__add,
		__sub = class.__sub,
		__mul = class.__mul,
		__div = class.__div,
		__pow = class.__pow,
		__concat = class.__concat,
	})

	oop.elementInfo[element] = instance

	local callDerivedConstructor
	callDerivedConstructor = function(parentClasses, instance, ...)
		for k, v in pairs(parentClasses) do
			if rawget(v, "virtual_constructor") then
				rawget(v, "virtual_constructor")(instance, ...)
			end
			local s = superMultiple(v)
			callDerivedConstructor(s, instance, ...)
		end
	end

	callDerivedConstructor(superMultiple(class), element, ...)

	-- Call constructor
	if rawget(class, "constructor") then
		rawget(class, "constructor")(element, ...)
	end
	element.constructor = false

	-- Add the destruction handler
	if isElement(element) then
		addEventHandler(
			triggerClientEvent ~= nil and "onElementDestroy" or "onClientElementDestroy",
			element,
			__removeElementIndex,
			false,
			"low-999999"
		)
	end
	return element
end

function new(class, ...)
	assert(type(class) == "table", "first argument provided to new is not a table")

	-- DEBUG: Validate that we are not instantiating a class with pure virtual methods
	if DEBUG then
		for k, v in pairs(class) do
			assert(
				v ~= pure_virtual,
				"Attempted to instanciate a class with an unimplemented pure virtual method (" .. tostring(k) .. ")"
			)
		end
	end

	local instance = setmetatable({}, {
		__index = class,
		__class = class,
		__newindex = class.__newindex,
		__call = class.__call,
		__len = class.__len,
		__unm = class.__unm,
		__add = class.__add,
		__sub = class.__sub,
		__mul = class.__mul,
		__div = class.__div,
		__pow = class.__pow,
		__concat = class.__concat,
	})

	-- Call derived constructors
	local callDerivedConstructor
	callDerivedConstructor = function(self, instance, ...)
		for k, v in pairs(self) do
			if rawget(v, "virtual_constructor") then
				rawget(v, "virtual_constructor")(instance, ...)
			end
			local s = superMultiple(v)
			callDerivedConstructor(s, instance, ...)
		end
	end

	callDerivedConstructor(superMultiple(class), instance, ...)

	-- Call constructor
	if rawget(class, "constructor") then
		rawget(class, "constructor")(instance, ...)
	end
	instance.constructor = false

	return instance
end

function delete(self, ...)
	if self.destructor then
		--if rawget(self, "destructor") then
		self:destructor(...)
	end

	-- Prevent the destructor to be called twice
	self.destructor = false

	local callDerivedDestructor
	callDerivedDestructor = function(parentClasses, instance, ...)
		for k, v in pairs(parentClasses) do
			if rawget(v, "virtual_destructor") then
				rawget(v, "virtual_destructor")(instance, ...)
			end
			local s = superMultiple(v)
			callDerivedDestructor(s, instance, ...)
		end
	end
	callDerivedDestructor(superMultiple(self), self, ...)
end

function superMultiple(self)
	if isElement(self) then
		assert(oop.elementInfo[self], "Cannot get the superclass of this element") -- at least: not yet
		self = oop.elementInfo[self]
	end

	local metatable = getmetatable(self)
	if not metatable then
		return {}
	end

	if metatable.__class then
		-- we're dealing with a class object
		return superMultiple(metatable.__class)
	end

	if metatable.__super then
		-- we're dealing with a class
		return metatable.__super or {}
	end
end

function super(self)
	return superMultiple(self)[1]
end

function classof(self)
	if isElement(self) then
		assert(oop.elementInfo[self], "Cannot get the class of this element") -- at least: not yet
		self = oop.elementInfo[self]
	end

	local metatable = getmetatable(self)
	if metatable then
		return metatable.__class
	end
	return {}
end

function inherit(from, what)
	assert(from, "Attempt to inherit a nil table value")
	if not what then
		local classt = setmetatable({}, { __index = _inheritIndex, __super = { from } })
		if from.onInherit then
			from.onInherit(classt)
		end
		return classt
	end

	local metatable = getmetatable(what) or {}
	local oldsuper = metatable and metatable.__super or {}
	table.insert(oldsuper, 1, from)
	metatable.__super = oldsuper
	metatable.__index = _inheritIndex

	-- Inherit __call
	for k, v in ipairs(metatable.__super) do
		if v.__call then
			metatable.__call = v.__call
			break
		end
	end

	return setmetatable(what, metatable)
end

function _inheritIndex(self, key)
	for k, v in pairs(superMultiple(self)) do
		if v[key] then
			return v[key]
		end
	end
	return nil
end

---// __removeElementIndex()
---|| @desc: This function calls delete on the hidden source parameter to invoke the destructor
---|| !!! Avoid calling this function manually unless you know what you're doing! !!!
---\\
function __removeElementIndex()
	delete(source)
end

function instanceof(self, class, direct)
	if direct then
		return classof(self) == class
	end

	for k, v in pairs(superMultiple(self)) do
		if v == class then
			return true
		end
	end

	local check = false
	-- Check if any of 'self's base classes is inheriting from 'class'
	for k, v in pairs(superMultiple(self)) do
		check = instanceof(v, class, false)
		if check then
			break
		end
	end
	return check
end

function pure_virtual()
	error("Function implementation missing")
end

function bind(func, ...)
	if not func then
		if DEBUG then
			outputConsole(debug.traceback())
			outputServerLog(debug.traceback())
		end
		error("Bad function pointer @ bind. See console for more details")
	end

	local boundParams = { ... }
	return function(...)
		local params = {}
		local boundParamSize = select("#", unpack(boundParams))
		for i = 1, boundParamSize do
			params[i] = boundParams[i]
		end

		local funcParams = { ... }
		for i = 1, select("#", ...) do
			params[boundParamSize + i] = funcParams[i]
		end
		return func(unpack(params))
	end
end

function load(class, ...)
	assert(type(class) == "table", "first argument provided to load is not a table")
	local instance = setmetatable({}, {
		__index = class,
		__class = class,
		__newindex = class.__newindex,
		__call = class.__call,
	})

	-- Call load
	if rawget(class, "load") then
		rawget(class, "load")(instance, ...)
	end
	instance.load = false

	return instance
end

-- Magic to allow MTA elements to be used as data storage
-- e.g. localPlayer.foo = 12
oop = {}
oop.elementInfo = setmetatable({}, { __mode = "k" })
oop.elementClasses = {}

oop.prepareClass = function(name)
	local mt = debug.getregistry().mt[name]

	if not mt then
		return
	end

	-- Store MTA's metafunctions
	local __mtaindex = mt.__index
	local __mtanewindex = mt.__newindex
	local __set = mt.__set

	mt.__index = function(self, key)
		if not oop.handled then
			if not oop.elementInfo[self] and isElement(self) then
				enew(self, oop.elementClasses[getElementType(self)] or {})
			end
			if oop.elementInfo[self] and oop.elementInfo[self][key] ~= nil then
				oop.handled = false
				return oop.elementInfo[self][key]
			end
			oop.handled = true
		end
		local value = __mtaindex(self, key)
		oop.handled = false
		return value
	end

	mt.__newindex = function(self, key, value)
		if __set[key] ~= nil then
			__mtanewindex(self, key, value)
			return
		end

		if not oop.elementInfo[self] and isElement(self) then
			enew(self, oop.elementClasses[getElementType(self)] or {})
		end

		oop.elementInfo[self][key] = value
	end
end

function registerElementClass(name, class)
	assert(type(name) == "string", "Bad argument #1 for registerElementClass")
	assert(type(class) == "table", "Bad argument #2 for registerElementClass")
	oop.elementClasses[name] = class
end

oop.initClasses = function()
	-- this has to match
	--	(Server) MTA10_Server\mods\deathmatch\logic\lua\CLuaMain.cpp
	--	(Client) MTA10\mods\shared_logic\lua\CLuaMain.cpp
	if SERVER then
		oop.prepareClass("ACL")
		oop.prepareClass("ACLGroup")
		oop.prepareClass("Account")
		oop.prepareClass("Ban")
		oop.prepareClass("Connection")
		oop.prepareClass("QueryHandle")
		oop.prepareClass("TextDisplay")
		oop.prepareClass("TextItem")
	elseif CLIENT then
		oop.prepareClass("Browser")
		oop.prepareClass("Camera")
		oop.prepareClass("Light")
		oop.prepareClass("Projectile")
		oop.prepareClass("SearchLight")
		oop.prepareClass("Sound")
		oop.prepareClass("Sound3D")
		oop.prepareClass("Weapon")
		oop.prepareClass("Effect")
		oop.prepareClass("GuiElement")
		oop.prepareClass("GuiWindow")
		oop.prepareClass("GuiButton")
		oop.prepareClass("GuiEdit")
		oop.prepareClass("GuiLabel")
		oop.prepareClass("GuiMemo")
		oop.prepareClass("GuiStaticImage")
		oop.prepareClass("GuiComboBox")
		oop.prepareClass("GuiCheckBox")
		oop.prepareClass("GuiRadioButton")
		oop.prepareClass("GuiScrollPane")
		oop.prepareClass("GuiScrollBar")
		oop.prepareClass("GuiProgressBar")
		oop.prepareClass("GuiGridList")
		oop.prepareClass("GuiTabPanel")
		oop.prepareClass("GuiTab")
		oop.prepareClass("GuiFont")
		oop.prepareClass("GuiBrowser")
		oop.prepareClass("EngineCOL")
		oop.prepareClass("EngineTXD")
		oop.prepareClass("EngineDFF")
		oop.prepareClass("DxMaterial")
		oop.prepareClass("DxTexture")
		oop.prepareClass("DxFont")
		oop.prepareClass("DxShader")
		oop.prepareClass("DxScreenSource")
		oop.prepareClass("DxRenderTarget")
		oop.prepareClass("Weapon")
	end

	oop.prepareClass("Object")
	oop.prepareClass("Ped")
	oop.prepareClass("Pickup")
	oop.prepareClass("Player")
	oop.prepareClass("RadarArea")
	--oop.prepareClass("Vector2")
	--oop.prepareClass("Vector3")
	--oop.prepareClass("Vector4")
	--oop.prepareClass("Matrix")
	oop.prepareClass("Element")
	oop.prepareClass("Blip")
	oop.prepareClass("ColShape")
	oop.prepareClass("File")
	oop.prepareClass("Marker")
	oop.prepareClass("Vehicle")
	oop.prepareClass("Water")
	oop.prepareClass("XML")
	oop.prepareClass("Timer")
	oop.prepareClass("Team")
	oop.prepareClass("Resource")
end
--oop.initClasses()

local __CLASSNAME__
local __BASECLASSES__
local __CLASSES__ = {}
local __MEMBERS__
local __IS_STATIC = false

function static_class(name)
	__IS_STATIC = true
	return class(name)
end

function maybeExtends(name)
	if name == extends then
		return extends
	else
		return buildClass(name)
	end
end

local __MEMBERNAME__
function buildMember(data)
	__MEMBERS__[__MEMBERNAME__] = data
end

function buildClass(definition)
	__CLASSES__[__CLASSNAME__] = definition
	_G[__CLASSNAME__] = definition
	definition.__CLASSNAME__ = __CLASSNAME__
	definition.__members__ = __MEMBERS__
	local parents = {}
	for k, v in pairs(__BASECLASSES__) do
		parents[k] = __CLASSES__[v]
	end

	-- Prepare parent members
	local defaults = {}
	for k, class in pairs(parents) do
		for name, member in pairs(class.__members__) do
			defaults[name] = member.default
		end
	end

	for k, v in pairs(__MEMBERS__) do
		defaults[k] = v.default
	end

	setmetatable(definition, {
		__index = function(self, key)
			for k, v in pairs(parents) do
				if v[key] then
					return v[key]
				end
			end
		end,

		__call = function(...)
			local member = defaults
			local instance = setmetatable({ __members__ = member, __class__ = definition }, {
				__index = function(self, key)
					if definition.__members__[key] then
						if definition.__members__[key].get then
							return definition.__members__[key].get(self)
						end
						return self.__members__[key]
					end

					return definition[key]
				end,
				-- Todo: Other metamethods

				__newindex = function(self, key, value)
					if definition.__members__[key] then
						if definition.__members__[key].set then
							if not definition.__members__[key].set(self, value) then
								return
							end
						end
						self.__members__[key] = value
					end

					-- Implicit member creation
					-- If you want, replace this by an error
					-- and make sure to add this line above
					-- to ensure proper setting for non-setter
					-- members
					self.__members__[key] = value
				end,
			})

			return instance
		end,
	})

	if __IS_STATIC then
		if definition.constructor then
			definition:constructor()
		end
	end
	__IS_STATIC = false
end

function class(name)
	__CLASSNAME__ = name
	__BASECLASSES__ = {}
	__MEMBERS__ = {}
	return maybeExtends
end

function extends(name)
	if type(name) == "string" then
		-- Handle base classes
		__BASECLASSES__[#__BASECLASSES__ + 1] = name
		return extends
	else
		-- Handle class definition
		return buildClass(name)
	end
end

function member(name)
	__MEMBERNAME__ = name
	__MEMBERS__[name] = {}
	return buildMember
end

local function loadAsync()
	local class = {
		_VERSION = "Slither 20140904",
		_DESCRIPTION = "Slither is a pythonic class library for lua",
		_URL = "http://bitbucket.org/bartbes/slither",
		_LICENSE = _LICENSE,
	}

	local function stringtotable(path)
		local t = _G
		local name

		for part in path:gmatch("[^%.]+") do
			t = name and t[name] or t
			name = part
		end

		return t, name
	end

	local function class_generator(name, b, t)
		local parents = {}
		for _, v in ipairs(b) do
			parents[v] = true
			for _, v in ipairs(v.__parents__) do
				parents[v] = true
			end
		end

		local temp = { __parents__ = {} }
		for i, v in pairs(parents) do
			table.insert(temp.__parents__, i)
		end

		local class = setmetatable(temp, {
			__index = function(self, key)
				if key == "__class__" then
					return temp
				end
				if key == "__name__" then
					return name
				end
				if t[key] ~= nil then
					return t[key]
				end
				for i, v in ipairs(b) do
					if v[key] ~= nil then
						return v[key]
					end
				end
				if tostring(key):match("^__.+__$") then
					return
				end
				if self.__getattr__ then
					return self:__getattr__(key)
				end
			end,

			__newindex = function(self, key, value)
				t[key] = value
			end,

			allocate = function(instance)
				local smt = getmetatable(temp)
				local mt = { __index = smt.__index }

				function mt:__newindex(key, value)
					if self.__setattr__ then
						return self:__setattr__(key, value)
					else
						return rawset(self, key, value)
					end
				end

				if temp.__cmp__ then
					if not smt.eq or not smt.lt then
						function smt.eq(a, b)
							return a.__cmp__(a, b) == 0
						end
						function smt.lt(a, b)
							return a.__cmp__(a, b) < 0
						end
					end
					mt.__eq = smt.eq
					mt.__lt = smt.lt
				end

				for i, v in pairs({
					__call__ = "__call",
					__len__ = "__len",
					__add__ = "__add",
					__sub__ = "__sub",
					__mul__ = "__mul",
					__div__ = "__div",
					__mod__ = "__mod",
					__pow__ = "__pow",
					__neg__ = "__unm",
					__concat__ = "__concat",
					__str__ = "__tostring",
				}) do
					if temp[i] then
						mt[v] = temp[i]
					end
				end

				return setmetatable(instance or {}, mt)
			end,

			__call = function(self, ...)
				local instance = getmetatable(self).allocate()
				if instance.__init__ then
					instance:__init__(...)
				end
				return instance
			end,
		})

		for i, v in ipairs(t.__attributes__ or {}) do
			class = v(class) or class
		end

		return class
	end

	local function inheritance_handler(set, name, ...)
		local args = { ... }

		for i = 1, select("#", ...) do
			if args[i] == nil then
				error("nil passed to class, check the parents")
			end
		end

		local t = nil
		if #args == 1 and type(args[1]) == "table" and not args[1].__class__ then
			t = args[1]
			args = {}
		end

		for i, v in ipairs(args) do
			if type(v) == "string" then
				local t, name = stringtotable(v)
				args[i] = t[name]
			end
		end

		local func = function(t)
			local class = class_generator(name, args, t)
			if set then
				local root_table, name = stringtotable(name)
				root_table[name] = class
			end
			return class
		end

		if t then
			return func(t)
		else
			return func
		end
	end

	function class.private(name)
		return function(...)
			return inheritance_handler(false, name, ...)
		end
	end

	class = setmetatable(class, {
		__call = function(self, name)
			return function(...)
				return inheritance_handler(true, name, ...)
			end
		end,
	})

	function class.issubclass(class, parents)
		if parents.__class__ then
			parents = { parents }
		end
		for i, v in ipairs(parents) do
			local found = true
			if v ~= class then
				found = false
				for _, p in ipairs(class.__parents__) do
					if v == p then
						found = true
						break
					end
				end
			end
			if not found then
				return false
			end
		end
		return true
	end

	function class.isinstance(obj, parents)
		return type(obj) == "table" and obj.__class__ and class.issubclass(obj.__class__, parents)
	end

	-- Export a Class Commons interface
	-- to allow interoperability between
	-- class libraries.
	-- See https://github.com/bartbes/Class-Commons
	--
	-- NOTE: Implicitly global, as per specification, unfortunately there's no nice
	-- way to both provide this extra interface, and use locals.
	if common_class ~= false then
		common = {}
		function common.class(name, prototype, superclass)
			prototype.__init__ = prototype.init
			return class_generator(name, { superclass }, prototype)
		end

		function common.instance(class, ...)
			return class(...)
		end
	end

	---------
	-- End of slither.lua dependency
	---------

	return class
end

local class = loadAsync()

--- GTA:MTA Lua async thread scheduler.
-- @author Inlife
-- @license MIT
-- @url https://github.com/Inlife/mta-lua-async
-- @dependency slither.lua https://bitbucket.org/bartbes/slither

class("_Async")({

	-- Constructor mehtod
	-- Starts timer to manage scheduler
	-- @access public
	-- @usage local asyncmanager = async();
	__init__ = function(self)
		self.threads = {}
		self.resting = 50 -- in ms (resting time)
		self.maxtime = 200 -- in ms (max thread iteration time)
		self.current = 0 -- starting frame (resting)
		self.state = "suspended" -- current scheduler executor state
		self.debug = false
		self.priority = {
			low = { 500, 50 }, -- better fps
			normal = { 200, 200 }, -- medium
			high = { 50, 500 }, -- better perfomance
		}

		self:setPriority("low")
	end,

	-- Switch scheduler state
	-- @access private
	-- @param boolean [istimer] Identifies whether or not
	-- switcher was called from main loop
	switch = function(self, istimer)
		self.state = "running"

		if self.current + 1 <= #self.threads then
			self.current = self.current + 1
			self:execute(self.current)
		else
			self.current = 0

			if #self.threads <= 0 then
				self.state = "suspended"
				return
			end

			-- setTimer(function theFunction, int timeInterval, int timesToExecute)
			-- (GTA:MTA server scripting function)
			-- For other environments use alternatives.
			setTimer(function()
				self:switch()
			end, self.resting, 1)
		end
	end,

	-- Managing thread (resuming, removing)
	-- In case of "dead" thread, removing, and skipping to the next (recursive)
	-- @access private
	-- @param int id Thread id (in table async.threads)
	execute = function(self, id)
		local thread = self.threads[id]

		if thread == nil or coroutine.status(thread) == "dead" then
			table.remove(self.threads, id)
			self:switch()
		elseif thread and coroutine.status(thread) ~= "running" and coroutine.status(thread) ~= "normal" then
			coroutine.resume(thread)
			self:switch()
		end
	end,

	-- Adding thread
	-- @access private
	-- @param function func Function to operate with
	add = function(self, func)
		local thread = coroutine.create(func)
		table.insert(self.threads, thread)
	end,

	-- Set priority for executor
	-- Use before you call 'iterate' or 'foreach'
	-- @access public
	-- @param string|int param1 "low"|"normal"|"high" or number to set 'resting' time
	-- @param int|void param2 number to set 'maxtime' of thread
	-- @usage async:setPriority("normal");
	-- @usage async:setPriority(50, 200);
	setPriority = function(self, param1, param2)
		if type(param1) == "string" then
			if self.priority[param1] ~= nil then
				self.resting = self.priority[param1][1]
				self.maxtime = self.priority[param1][2]
			end
		else
			self.resting = param1
			self.maxtime = param2
		end
	end,

	-- Set debug mode enabled/disabled
	-- @access public
	-- @param boolean value true - enabled, false - disabled
	-- @usage async:setDebug(true);
	setDebug = function(self, value)
		self.debug = value
	end,

	-- Iterate on interval (for cycle)
	-- @access public
	-- @param int from Iterate from
	-- @param int to Iterate to
	-- @param function func Iterate using func
	-- Function func params:
	-- @param int [i] Iteration index
	-- @param function [callback] Callback function, called when execution finished
	-- Usage:
	-- @usage async:iterate(1, 10000, function(i)
	--     print(i);
	-- end);
	iterate = function(self, from, to, func, callback)
		self:add(function()
			local a = getTickCount()
			local lastresume = getTickCount()
			for i = from, to do
				func(i)

				-- int getTickCount()
				-- (GTA:MTA server scripting function)
				-- For other environments use alternatives.
				if getTickCount() > lastresume + self.maxtime then
					coroutine.yield()
					lastresume = getTickCount()
				end
			end
			if self.debug then
				print("[DEBUG]Async iterate: " .. (getTickCount() - a) .. "ms")
			end
			if callback then
				callback()
			end
		end)

		self:switch()
	end,

	-- Iterate over array (foreach cycle)
	-- @access public
	-- @param table array Input array
	-- @param function func Iterate using func
	-- Function func params:
	-- @param int [v] Iteration value
	-- @param int [k] Iteration key
	-- @param function [callback] Callback function, called when execution finished
	-- Usage:
	-- @usage async:foreach(vehicles, function(vehicle, id)
	--     print(vehicle.title);
	-- end);
	foreach = function(self, array, func, callback)
		self:add(function()
			local a = getTickCount()
			local lastresume = getTickCount()
			for k, v in ipairs(array) do
				func(v, k)

				-- int getTickCount()
				-- (GTA:MTA server scripting function)
				-- For other environments use alternatives.
				if getTickCount() > lastresume + self.maxtime then
					coroutine.yield()
					lastresume = getTickCount()
				end
			end
			if self.debug then
				print("[DEBUG]Async foreach: " .. (getTickCount() - a) .. "ms")
			end
			if callback then
				callback()
			end
		end)

		self:switch()
	end,

	-- foreach_pairs
	-- Iterate over array (foreach cycle)
	-- @access public
	-- @param table array Input array
	-- @param function func Iterate using func
	-- Function func params:
	-- @param int [v] Iteration value
	-- @param int [k] Iteration key
	-- @param function [callback] Callback function, called when execution finished
	-- Usage:
	-- @usage async:foreach(vehicles, function(vehicle, id)
	--     print(vehicle.title);
	-- end);
	foreach_pairs = function(self, array, func, callback)
		self:add(function()
			local a = getTickCount()
			local lastresume = getTickCount()
			for k, v in pairs(array) do
				func(v, k)

				-- int getTickCount()
				-- (GTA:MTA server scripting function)
				-- For other environments use alternatives.
				if getTickCount() > lastresume + self.maxtime then
					coroutine.yield()
					lastresume = getTickCount()
				end
			end
			if self.debug then
				print("[DEBUG]Async foreach_pairs: " .. (getTickCount() - a) .. "ms")
			end
			if callback then
				callback()
			end
		end)

		self:switch()
	end,
})

Async = {
	instance = nil,
}

local function getInstance()
	if Async.instance == nil then
		Async.instance = _Async()
	end

	return Async.instance
end

function Async:setDebug(...)
	getInstance():setDebug(...)
end

function Async:setPriority(...)
	getInstance():setPriority(...)
end

function Async:iterate(...)
	getInstance():iterate(...)
end

function Async:foreach(...)
	getInstance():foreach(...)
end

function Async:foreach_pairs(...)
	getInstance():foreach_pairs(...)
end

function table:find(callback)
	for k, v in pairs(self) do
		if callback(v, k) then
			return v, k
		end
	end
end

function table:keys()
	local keys = {}
	for k, _ in pairs(self) do
		table.insert(keys, k)
	end
	return keys
end

function table:values()
	local values = {}
	for _, v in pairs(self) do
		table.insert(values, v)
	end
	return values
end

function table:map(callback)
	local newTable = {}
	for k, v in pairs(self) do
		newTable[k] = callback(v, k)
	end
	return newTable
end

function table:foreach(callback)
	local newTable = {}
	for k, v in pairs(self) do
		table.insert(newTable, callback(v, k))
	end
	return newTable
end

function table:filter(callback)
	local newTable = {}
	for k, v in pairs(self) do
		if callback(v, k) then
			newTable[k] = v
		end
	end
	return newTable
end

function table:reduce(callback, initialValue)
	local accumulator = initialValue
	for k, v in pairs(self) do
		accumulator = callback(accumulator, v, k)
	end
	return accumulator
end

function table:includes(value)
	for _, v in pairs(self) do
		if tostring(v) == tostring(value) then
			return true
		end
	end
	return false
end

function table:every(callback)
	for k, v in pairs(self) do
		if not callback(v, k) then
			return false
		end
	end
	return true
end

function table:some(callback)
	for k, v in pairs(self) do
		if callback(v, k) then
			return true
		end
	end
	return false
end

function each(array, callback)
	if type(array) == "table" then
		for key, value in pairs(array) do
			callback(key, value)
		end
	end
end

function eachi(array, callback)
	local result = {}
	for key, value in pairs(array) do
		table.insert(result, callback(key, value))
	end
	return result
end

function filter(array, callback)
	local result = {}
	for key, value in pairs(array) do
		if callback(key, value) then
			result[key] = value
		end
	end
	return result
end

function map(array, callback)
	local result = {}
	for key, value in pairs(array) do
		result[key] = callback(key, value)
	end
	return result
end

function reduce(array, callback, initial)
	local result = initial
	for key, value in pairs(array) do
		result = callback(result, key, value)
	end
	return result
end

function some(array, callback)
	for key, value in pairs(array) do
		if callback(key, value) then
			return true
		end
	end
	return false
end

function every(array, callback)
	for key, value in pairs(array) do
		if not callback(key, value) then
			return false
		end
	end
	return true
end

function find(array, callback)
	for key, value in pairs(array) do
		if callback(key, value) then
			return value
		end
	end
end

function merge(...)
	local result = {}
	for _, array in ipairs({ ... }) do
		for key, value in pairs(array) do
			result[key] = value
		end
	end
	return result
end

function clone(array)
	local result = {}
	for key, value in pairs(array) do
		result[key] = value
	end
	return result
end

function keys(array)
	local result = {}
	for key, _ in pairs(array) do
		table.insert(result, key)
	end
	return result
end

function values(array)
	local result = {}
	for _, value in pairs(array) do
		table.insert(result, value)
	end
	return result
end

function size(array)
	local count = 0
	for _, _ in pairs(array) do
		count = count + 1
	end
	return count
end
