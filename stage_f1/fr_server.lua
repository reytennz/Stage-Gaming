local g_PlayerData = {}
local g_VehicleData = {}
local chatTime = {}
local lastChatMessage = {}

local _stageServerOutputChatBox = outputChatBox
function outputChatBox(message, visibleTo, r, g, b, colorCoded)
	message = tostring(message or "")
	if not message:find("Stage Gaming", 1, true) then
		message = "#FF7A00[Stage Gaming] #FFFFFF" .. message:gsub("^#%x%x%x%x%x%x%[[^%]]+%]%s*#%x%x%x%x%x%x", "")
	end
	return _stageServerOutputChatBox(message, visibleTo, r or 255, g or 255, b or 255, colorCoded ~= false)
end

g_ArmedVehicles = {
	[425] = true,
	[447] = true,
	[520] = true,
	[430] = true,
	[464] = true,
	[432] = true
}
g_Trailers = {
	[606] = true,
	[607] = true,
	[610] = true,
	[590] = true,
	[569] = true,
	[611] = true,
	[584] = true,
	[608] = true,
	[435] = true,
	[450] = true,
	[591] = true
}

g_RPCFunctions = {
	addPedClothes = { option = 'clothes', descr = 'Modifying clothes' },
	buyVehicle = { option = 'createvehicle', descr = 'Buying vehicles' },
	testDriveVehicle = { option = 'createvehicle', descr = 'Test driving vehicles' },
	fadeVehiclePassengersCamera = true,
	fixVehicle = { option = 'repair', descr = 'Repairing vehicles' },
	giveMeWeapon = { option = 'weapons.enabled', descr = 'Getting weapons' },
	givePedJetPack = { option = 'jetpack', descr = 'Getting a jetpack' },
	removePedClothes = { option = 'clothes', descr = 'Modifying clothes' },
	removePedFromVehicle = true,
	removePedJetPack = { option = 'jetpack', descr = 'Removing a jetpack' },
	setElementAlpha = { option = 'alpha', descr = 'Changing your alpha' },
	setElementInterior = true,
	setMySkin = { option = 'setskin', descr = 'Setting skin' },
	setPedAnimation = { option = 'anim', descr = 'Setting an animation' },
	setPedWalkingStyle = { option = 'walkstyle', descr = 'Setting walking style' },
	--setPedFightingStyle = { option = 'setstyle', descr = 'Setting fighting style' },
	setPedGravity = { option = 'gravity.enabled', descr = 'Setting gravity' },
	setPedStat = { option = 'stats', descr = 'Changing stats' },
	setVehicleColor = true,
	setVehicleHeadLightColor = true,
	setVehicleOverrideLights = { option = 'lights', descr = 'Forcing lights' },
	setVehiclePaintjob = { option = 'paintjob', descr = 'Applying paintjobs' },
	warpMeIntoVehicle = true,
	setWalking = { option='setwalking', descr ='Walking Style' },
    setFighting = { option='setstyle' , descr='Fighting Style' },
	requestGarageList = true,
	activateGarageVehicle = { option = 'createvehicle', descr = 'Activating garage vehicles' },
	deactivateGarageVehicle = true,
	saveGarageVehicleAppearance = true
}

g_OptionDefaults = {
	alpha = true,
	anim = true,
	clothes = true,
	createvehicle = true,
	gamespeed = {
		enabled = true,
		min = 0.0,
		max = 3
	},
	gravity = {
		enabled = true,
		min = 0,
		max = 0.1
	},
	jetpack = true,
	lights = true,
	paintjob = true,
	repair = true,
	setskin = true,
	setstyle = true,
	-- Stage Loading karakter/spawn sistemini kullanir; F1 harita acmaz.
	spawnmaponstart = false,
	spawnmapondeath = false,
	stats = true,
	warp = true,
	walkstyle= true,
	weapons = {
		enabled = true,
		vehiclesenabled = true,
		disallowed = {},
		kniferestrictions = true
	},
	welcometextonstart = true,
	vehicles = {
		maxidletime = 60000,
		idleexplode = true,
		maxperplayer = 2,
		disallowed = {}
	}
}

---------------------------
-- Stage Gaming duello
---------------------------
local duelRequests = {} -- [target] = {from=player, bet=number}
local activeDuels = {}  -- [player] = {opponent=player, bet=number, pot=number}

local duelPosA = { 1368.92, 2175.84, 11.02, 90 }
local duelPosB = { 1412.64, 2175.84, 11.02, 270 }

local function stageName(player)
	if not isElement(player) then return "Oyuncu" end
	return getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
end

local function stageNotify(player, message)
	if isElement(player) then
		outputChatBox("#FF7A00[Stage Gaming] #FFFFFF" .. tostring(message), player, 255, 255, 255, true)
	end
end

local function getStageMoney(player)
	if getResourceFromName("stage_loading") and getResourceState(getResourceFromName("stage_loading")) == "running" then
		return tonumber(exports.stage_loading:stageGetMoney(player)) or 0
	end
	return getPlayerMoney(player)
end

local function setStageMoney(player, amount)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if getResourceFromName("stage_loading") and getResourceState(getResourceFromName("stage_loading")) == "running" then
		return exports.stage_loading:stageSetMoney(player, amount)
	end
	setPlayerMoney(player, amount)
	return true
end

local function clearDuel(player)
	local duel = activeDuels[player]
	if not duel then return end
	local opponent = duel.opponent
	activeDuels[player] = nil
	if isElement(opponent) then activeDuels[opponent] = nil end
end

local function finishDuel(winner, loser, reason)
	local duel = activeDuels[winner] or activeDuels[loser]
	if not duel then return end
	local pot = tonumber(duel.pot) or ((tonumber(duel.bet) or 0) * 2)
	clearDuel(winner)
	clearDuel(loser)
	if isElement(winner) then
		setStageMoney(winner, getStageMoney(winner) + pot)
		stageNotify(winner, "Duelloyu kazandin. Kazanc: $" .. pot)
	end
	if isElement(loser) then
		stageNotify(loser, "Duelloyu kaybettin. Bahis gitti.")
	end
	if reason and isElement(winner) then
		stageNotify(winner, reason)
	end
end

addEvent("stageDuel:request", true)
addEventHandler("stageDuel:request", root, function(target, bet)
	local player = client or source
	bet = math.max(0, math.floor(tonumber(bet) or 0))
	if not isElement(player) or not isElement(target) or getElementType(target) ~= "player" or target == player then
		stageNotify(player, "Gecerli bir oyuncu sec.")
		return
	end
	if activeDuels[player] or activeDuels[target] then
		stageNotify(player, "Bu oyunculardan biri zaten duelloda.")
		return
	end
	if getStageMoney(player) < bet then
		stageNotify(player, "Bahis icin yeterli paran yok.")
		return
	end
	duelRequests[target] = { from = player, bet = bet, tick = getTickCount() }
	triggerClientEvent(target, "stageDuel:invite", resourceRoot, player, bet)
	stageNotify(player, stageName(target) .. " oyuncusuna $" .. bet .. " bahisli duello istegi atildi.")
end)

addEvent("stageDuel:respond", true)
addEventHandler("stageDuel:respond", root, function(fromPlayer, accepted)
	local target = client or source
	local req = duelRequests[target]
	if not req or req.from ~= fromPlayer or not isElement(fromPlayer) then
		stageNotify(target, "Duello istegi bulunamadi.")
		return
	end
	duelRequests[target] = nil
	if not accepted then
		stageNotify(target, "Duello istegini reddettin.")
		stageNotify(fromPlayer, stageName(target) .. " duello istegini reddetti.")
		return
	end
	local bet = tonumber(req.bet) or 0
	if activeDuels[fromPlayer] or activeDuels[target] then
		stageNotify(target, "Duello baslatilamadi, oyunculardan biri mesgul.")
		return
	end
	if getStageMoney(fromPlayer) < bet or getStageMoney(target) < bet then
		stageNotify(target, "Oyunculardan birinde bahis icin yeterli para yok.")
		stageNotify(fromPlayer, "Oyunculardan birinde bahis icin yeterli para yok.")
		return
	end
	setStageMoney(fromPlayer, getStageMoney(fromPlayer) - bet)
	setStageMoney(target, getStageMoney(target) - bet)
	local pot = bet * 2
	activeDuels[fromPlayer] = { opponent = target, bet = bet, pot = pot }
	activeDuels[target] = { opponent = fromPlayer, bet = bet, pot = pot }
	setElementInterior(fromPlayer, 0)
	setElementInterior(target, 0)
	setElementDimension(fromPlayer, 0)
	setElementDimension(target, 0)
	spawnPlayer(fromPlayer, duelPosA[1], duelPosA[2], duelPosA[3], duelPosA[4], getElementModel(fromPlayer))
	spawnPlayer(target, duelPosB[1], duelPosB[2], duelPosB[3], duelPosB[4], getElementModel(target))
	giveWeapon(fromPlayer, 24, 80, true)
	giveWeapon(target, 24, 80, true)
	stageNotify(fromPlayer, "Duello basladi. Rakip: " .. stageName(target) .. " | Pot: $" .. pot)
	stageNotify(target, "Duello basladi. Rakip: " .. stageName(fromPlayer) .. " | Pot: $" .. pot)
end)

addEventHandler("onPlayerWasted", root, function(_, killer)
	local duel = activeDuels[source]
	if not duel then return end
	local opponent = duel.opponent
	if killer == opponent then
		finishDuel(opponent, source)
	elseif isElement(opponent) then
		finishDuel(opponent, source, "Rakip oldugu icin duello sana yazildi.")
	end
end)

addEventHandler("onPlayerQuit", root, function()
	local duel = activeDuels[source]
	if duel and isElement(duel.opponent) then
		finishDuel(duel.opponent, source, "Rakip cikis yaptigi icin duello sana yazildi.")
	end
	for target, req in pairs(duelRequests) do
		if target == source or req.from == source then duelRequests[target] = nil end
	end
end)

function getOption(optionName)
	local option = get(optionName:gsub('%.', '/'))
	if option then
		if option == 'true' then
			option = true
		elseif option == 'false' then
			option = false
		end
		return option
	end
	option = g_OptionDefaults
	for i,part in ipairs(optionName:split('.')) do
		option = option[part]
	end
	return option
end

addEventHandler('onResourceStart', resourceRoot,
	function()
		table.each(getElementsByType('player'), joinHandler)
	end
)

function onLocalSettingChange(setting,value)

	if client ~= source then return end
	g_PlayerData[client].settings[setting] = value
	triggerClientEvent("onClientFreeroamLocalSettingChange",client,setting,value)

end

function joinHandler(player)
	if not player then
		player = source
	end
	local r, g, b = math.random(50, 255), math.random(50, 255), math.random(50, 255)
	setPlayerNametagColor(player, r, g, b)
	setElementData( player , "XEnergy.Fighting" , getPedFightingStyle( player ) )
	g_PlayerData[player] = { vehicles = {}, settings={} }
	g_PlayerData[player].blip = createBlipAttachedTo(player, 0, 2, r, g, b)
	addEventHandler("onFreeroamLocalSettingChange",player,onLocalSettingChange)
	if getOption('welcometextonstart') then
		outputChatBox('#FF0000● #ffffffSunucumuza #0066FFHoş Geldiniz', player, 255, 255, 255, true)
		outputChatBox('#FF0000● #ffffffSunucumuzda Vip Ücretsizdir Tuşu #0066FFM #ffffffHarfidir.', player, 255, 255, 255, true)
		outputChatBox('#FF0000● #ffffffKalite Şans Eseri Kazanılamaz', player, 255, 255, 255, true)
		outputChatBox('#FF0000● #ffffffAyasofya  #FF0000Gaming #000000- #ffffff© 2018-2022', player, 255, 255, 255, true)
	end
end
addEventHandler('onPlayerJoin', root, joinHandler)

local settingsToSend = {
	"command_spam_protection",
	"tries_required_to_trigger",
	"tries_required_to_trigger_low_priority",
	"command_spam_ban_duration",
	"command_exception_commands",
	"removeHex",
	"spawnmapondeath",
	"weapons/kniferestrictions",
	"kill",
	"warp",
	"gamespeed/enabled",
	"gamespeed/min",
	"gamespeed/max",
	"gui/antiram",
	"gui/disablewarp",
	"gui/disableknife",
	"vehicles/disallowed_warp",
}

local function updateSettings()
	local settings = {}
	for _, setting in ipairs(settingsToSend) do
		settings[setting] = getOption(setting)
	end
	return settings
end

local function sendSettings(player,settingPlayer,settings)

	for setting,value in pairs(settings) do
		if isElement(player) and isElement(settingPlayer) then
			triggerClientEvent(player,"onClientFreeroamLocalSettingChange",settingPlayer,setting,value)
		end
	end

end

addEvent('onLoadedAtClient', true)
addEventHandler('onLoadedAtClient', resourceRoot,
	function()
		-- Stage Loading aktifken oyuncunun spawnini bu resource yonetmez.
		if getElementData(client, "stage:logged") then
			local settings = updateSettings()
			clientCall(client, 'freeroamSettings', settings)
			return
		end
		-- Spawn haritasi veya otomatik spawn (Stage Loading yoksa fallback)
		local needsSpawn = isPedDead(client) or isPedTerminated(client)
		if needsSpawn then
			if getOption('spawnmaponstart') then
				clientCall(client, 'showWelcomeMap')
			end
			-- 8 sn icinde haritadan secmezse Grove Street'e otomatik spawn
			setTimer(function(player)
				if not isElement(player) then return end
				if isPedDead(player) or isPedTerminated(player) then
					local x, y, z = 2495.0, -1687.0, 13.5  -- Grove Street LS
					spawnPlayer(player, x, y, z, 0, getElementModel(player) > 0 and getElementModel(player) or 0)
					setCameraTarget(player, player)
					setElementInterior(player, 0)
					setElementDimension(player, 0)
					setCameraInterior(player, 0)
					fadeCamera(player, true)
					outputChatBox('[ⓘ] Otomatik spawn: Grove Street. F1 > Harita ile konum degistirebilirsin.', player, 0, 150, 255, true)
				end
			end, 8000, 1, client)
		end
		local settings = updateSettings()
		clientCall(client, 'freeroamSettings', settings)
		for player,data in pairs(g_PlayerData) do
			if player ~= client then
				local settings = data.settings
				setTimer(sendSettings,1500,1,client,player,settings)
			end
		end
	end,
	false
)

-- Yeni giren / resource basinda olu oyuncular
addEventHandler('onPlayerJoin', root, function()
	local player = source
	setTimer(function(p)
		if not isElement(p) then return end
		if isPedTerminated(p) or isPedDead(p) then
			-- Kamerayi ac, client yuklenene kadar bekle
			fadeCamera(p, true)
		end
	end, 500, 1, player)
end, true, 'low')

function onSettingChange(key,_,new)
	local access = key:sub(1, 1) -- we always have modifiers
	if access ~= "*" and access ~= "#" and access ~= "@" then
		return
	end

	local resource = key:sub(2, 9)
	if key:sub(2, 9) ~= getThisResource().name then
		return
	end

	local setting = key:sub(11)
	if not table.find(settingsToSend, setting) then
		return
	end

	local settings = updateSettings()
	for index,player in ipairs(getElementsByType("player")) do
		clientCall(player, 'freeroamSettings', settings)
	end
end
addEventHandler("onSettingChange", root, onSettingChange)

function showMap(player)

	if isPedDead(player) then
		clientCall(player, "showMap")
	end

end

addEvent('onClothesInit', true)
addEventHandler('onClothesInit', resourceRoot,
	function()
		local result = {}
		local texture, model
		-- get all clothes
		result.allClothes = {}
		local typeGroup, index
		for type=0,17 do
			typeGroup = {'group', type = type, name = getClothesTypeName(type), children = {}}
			table.insert(result.allClothes, typeGroup)
			index = 0
			texture, model = getClothesByTypeIndex(type, index)
			while texture do
				table.insert(typeGroup.children, {id = index, texture = texture, model = model})
				index = index + 1
				texture, model = getClothesByTypeIndex(type, index)
			end
		end
		-- get current player clothes { type = {texture=texture, model=model} }
		result.playerClothes = {}
		for type=0,17 do
			texture, model = getPedClothes(client, type)
			if texture then
				result.playerClothes[type] = {texture = texture, model = model}
			end
		end
		triggerClientEvent(client, 'onClientClothesInit', resourceRoot, result)
	end
)

addEvent("setElementAlpha",true)
addEventHandler("setElementAlpha", root, function(alpha)
	local alpha = alpha or 255
	setElementAlpha(client,alpha)
end)

addEvent('onPlayerGravInit', true)
addEventHandler('onPlayerGravInit', root,
	function()
		if client ~= source then return end
		triggerClientEvent(client, 'onClientPlayerGravInit', client, getPedGravity(client))
	end
)

function setMySkin(skinid)
	if getElementModel(source) == skinid then return end
	if isPedDead(source) then
		local x, y, z = getElementPosition(source)
		if isPedTerminated(source) then
			x = 0
			y = 0
			z = 3
		end
		local r = getPedRotation(source)
		local interior = getElementInterior(source)
		spawnPlayer(source, x, y, z, r, skinid)
		setElementInterior(source, interior)
		setCameraInterior(source, interior)
	else
		setElementModel(source, skinid)
	end
	setCameraTarget(source, source)
	setCameraInterior(source, getElementInterior(source))
end

function setWalking(ID)

	if( source )then

	if table.find(getOption('walkings.disallowed'), ID) then
	
			errMsg('Sistem aktif değil.', source)
			
		else
			setPedWalkingStyle( source , tonumber(ID) )
		end
		
	end
end

local _setPedFightingStyle = setPedFightingStyle
function setFighting( ID )
if( source )then
if table.find(getOption('fighting.disallowed'), ID) then
        errMsg('Sistem aktif değil.', source)
    else
    _setPedFightingStyle( source , tonumber(ID) )
    setElementData( source , "XEnergy.Fighting" , getPedFightingStyle(source) );
    end
end
end

function setPedFightingStyle( ped , ID )
if( ped and (isElement(ped) and (getElementType(ped) == 'player' or getElementType( ped ) == 'ped') ) )then
if table.find(getOption('fighting.disallowed'), ID) then
        errMsg('Sistem aktif değil', ped)
    else
    _setPedFightingStyle( ped , tonumber(ID) )
    setElementData( ped , "XEnergy.Fighting" , getPedFightingStyle(source) );
    end
end
end


-- BLUR --

function changeBlurLevel1()
    setPlayerBlurLevel ( source, 0 )
end
addEventHandler ( "onPlayerJoin", getRootElement(), changeBlurLevel1 )
 
function scriptStart()
    setPlayerBlurLevel ( getRootElement(), 0)
end
addEventHandler ("onResourceStart",getResourceRootElement(getThisResource()),scriptStart)

function spawnMe(x, y, z)
	if not x then
		x, y, z = getElementPosition(source)
	end
	if isPedTerminated(source) then
		repeat until spawnPlayer(source, x, y, z, 0, math.random(9, 288))
	else
		spawnPlayer(source, x, y, z, 0, getPedSkin(source))
	end

	setCameraTarget(source, source)
	setCameraInterior(source, getElementInterior(source))
end

function warpMeIntoVehicle(vehicle)

	if not isElement(vehicle) then return end

	if isPedDead(source) then
		spawnMe()
	end

	if getPedOccupiedVehicle(source) then
		outputChatBox('[HATA] Öncelikle şöför koltuğuna geçiniz.', source, 255,0,0, true)
		return
	end
	local interior = getElementInterior(vehicle)
	local numseats = getVehicleMaxPassengers(vehicle)
	local driver = getVehicleController(vehicle)
	for i=0,numseats do
		if not getVehicleOccupant(vehicle, i) then
			if isPedDead(source) then
				local x, y, z = getElementPosition(vehicle)
				spawnMe(x + 4, y, z + 1)
			end
			setElementInterior(source, interior)
			setCameraInterior(source, interior)
			warpPedIntoVehicle(source, vehicle, i)
			return
		end
	end
	if isElement(driver) then
		outputChatBox("[HATA] #555555"..getPlayerName(driver) .. ' #ff0000adlı oyuncunun aracında boş koltuk yok.', source, 255, 0, 0, true)
	end

end

local sawnoffAntiAbuse = {}
function giveMeWeapon(weapon, amount)
	if table.find(getOption('weapons.disallowed'), weapon) then
		errMsg((getWeaponNameFromID(weapon) or tostring(weapon)) .. ' adlı silahın kullanılması yasaktır.', source)
	else
		giveWeapon(source, weapon, amount, true)
		if weapon == 26 then
			if not sawnoffAntiAbuse[source] then
				setControlState (source, "aim_weapon", false)
				setControlState (source, "fire", false)
				toggleControl (source, "fire", false)
				reloadPedWeapon (source)
				sawnoffAntiAbuse[source] = setTimer (function(source)
					if not source then return end
					toggleControl (source, "fire", true)
					sawnoffAntiAbuse[source] = nil
				end, 3000, 1, source)
			end
        end
	end
end

---------------------------
-- Vehicle showroom: normal MTA money economy
-- (mirrors the price formula on the client, calculated here again
-- server-side so the price actually charged can never be spoofed)
---------------------------
function getVehiclePrice(model)
	model = tonumber(model)
	if not model then return 15000 end
	local ok, h = pcall(getOriginalHandling, model)
	if not ok or not h then return 15000 end
	local price = (h.maxVelocity or 200) * 35 + (h.mass or 1500) * 4 + (h.engineAcceleration or 5) * 150
	price = math.floor(price / 50) * 50
	if price < 3000 then price = 3000 end
	if price > 300000 then price = 300000 end
	return price
end

function formatMoney(amount)
	if StageFormatMoney then
		return StageFormatMoney(amount)
	end
	local str = tostring(math.floor(amount or 0))
	local formatted = str:reverse():gsub('(%d%d%d)', '%1.'):reverse()
	return formatted:gsub('^%.', '')
end

---------------------------
-- Garage (Araçlarım) - persistent vehicle ownership
---------------------------
MAX_ACTIVE_GARAGE_VEHICLES = 3
-- XML garage sistemi kaldırıldı, tüm araç verisi MySQL'de tutulur.
-- Tablo: f1_garage_vehicles (stage_loading MySQL bağlantısı kullanılır)
g_Garage = {}                 -- [serial] = { nextId = n, vehicles = { [id] = {model=,plate=,active=,colors=,headlight=,wheelcolor=} } }
g_GarageVehicleElement = {}   -- [serial][id] = currently spawned vehicle element
g_ElementGarageInfo = {}      -- [vehicleElement] = { serial = , id = }

-- stage_loading'in MySQL bağlantısını kullan
local function getDB()
    local r = getResourceFromName("stage_loading")
    if not r or getResourceState(r) ~= "running" then return nil end
    local ok, db = pcall(function() return exports.stage_loading:stageGetDatabase() end)
    return ok and db or nil
end

local function dbQ(sql, ...)
    local db = getDB()
    if not db then return {} end
    local h = dbQuery(db, sql, ...)
    return dbPoll(h, -1) or {}
end

local function dbE(sql, ...)
    local db = getDB()
    if not db then return false end
    return dbExec(db, sql, ...)
end

local function colorsToStr(c)
    return table.concat(c, ",")
end

local function strToColors(s, default)
    local t = {}
    for v in tostring(s or ""):gmatch("([^,]+)") do t[#t+1] = tonumber(v) or 0 end
    while #t < (default or 12) do t[#t+1] = 0 end
    return t
end

function ensureGarage(serial)
    if not g_Garage[serial] then
        g_Garage[serial] = { nextId = 1, vehicles = {} }
    end
    return g_Garage[serial]
end

function countActiveGarageVehicles(serial)
    local data = g_Garage[serial]
    if not data then return 0 end
    local count = 0
    for id, veh in pairs(data.vehicles) do
        if veh.active then count = count + 1 end
    end
    return count
end

function generateGaragePlate()
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local out = {}
    for i = 1, 3 do out[i] = letters:sub(math.random(1, #letters), math.random(1, #letters)) end
    return table.concat(out) .. ' ' .. math.random(100, 999)
end

-- MySQL'den tüm araçları yükle (resource start)
function loadGarageData()
    local db = getDB()
    if not db then
        outputServerLog("[stage_f1] MySQL bağlantısı yok, garage yüklenemedi!")
        return
    end
    -- Tablo yoksa oluştur
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS f1_garage_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_serial VARCHAR(64) NOT NULL,
            garage_slot INT NOT NULL DEFAULT 1,
            model INT NOT NULL,
            name VARCHAR(64),
            plate VARCHAR(16) NOT NULL DEFAULT '',
            colors VARCHAR(128) NOT NULL DEFAULT '255,255,255,255,255,255,0,0,0,0,0,0',
            headlight VARCHAR(32) NOT NULL DEFAULT '255,255,255',
            wheelcolor VARCHAR(32) NOT NULL DEFAULT '0,0,0',
            updated_at BIGINT NOT NULL DEFAULT 0,
            UNIQUE KEY uniq_serial_slot (player_serial, garage_slot)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    local rows = dbPoll(dbQuery(db, "SELECT * FROM f1_garage_vehicles"), -1) or {}
    for _, row in ipairs(rows) do
        local serial = tostring(row.player_serial or "")
        local id = tonumber(row.garage_slot) or 1
        if serial ~= "" then
            local garage = ensureGarage(serial)
            garage.vehicles[id] = {
                model      = tonumber(row.model),
                name       = row.name,
                plate      = tostring(row.plate or ''),
                active     = false,
                colors     = strToColors(row.colors, 12),
                headlight  = strToColors(row.headlight, 3),
                wheelcolor = strToColors(row.wheelcolor, 3),
            }
            if id >= garage.nextId then garage.nextId = id + 1 end
        end
    end
    outputServerLog("[stage_f1] Garage verisi MySQL'den yüklendi.")
end
addEventHandler('onResourceStart', resourceRoot, function()
    setTimer(loadGarageData, 2000, 1) -- stage_loading hazır olsun diye kısa bekle
end)

-- Tek bir araç kaydını MySQL'e yaz
local function saveVehicleRow(serial, id, veh)
    if not veh then return end
    dbE([[
        INSERT INTO f1_garage_vehicles
            (player_serial, garage_slot, model, name, plate, colors, headlight, wheelcolor, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            model=VALUES(model), name=VALUES(name), plate=VALUES(plate),
            colors=VALUES(colors), headlight=VALUES(headlight),
            wheelcolor=VALUES(wheelcolor), updated_at=VALUES(updated_at)
    ]],
        serial, id, veh.model or 0,
        veh.name or getVehicleNameFromModel(veh.model) or "",
        veh.plate or '',
        colorsToStr(veh.colors or {255,255,255,255,255,255,0,0,0,0,0,0}),
        colorsToStr(veh.headlight or {255,255,255}),
        colorsToStr(veh.wheelcolor or {0,0,0}),
        getRealTime().timestamp
    )
end

-- saveGarageData: eski kod ile uyumluluk için tüm in-memory veriyi MySQL'e döker
function saveGarageData()
    for serial, data in pairs(g_Garage) do
        for id, veh in pairs(data.vehicles) do
            saveVehicleRow(serial, id, veh)
        end
    end
end

-- Araç silme (satış/çöp için)
function deleteGarageVehicle(serial, id)
    g_Garage[serial] = g_Garage[serial] or { nextId = 1, vehicles = {} }
    g_Garage[serial].vehicles[id] = nil
    dbE("DELETE FROM f1_garage_vehicles WHERE player_serial=? AND garage_slot=?", serial, id)
end

function spawnGarageVehicle(player, serial, id)
	local data = g_Garage[serial]
	local veh = data and data.vehicles[id]
	if not veh then return false end
	local element = getPedOccupiedVehicle(player) or player
	local px,py,pz = getElementPosition(element)
	local _,_,prot = getElementRotation(element)
	local posVector = Vector3(px,py,pz+2)
	local rotVector = Vector3(0,0,prot)
	local vehMatrix = Matrix(posVector,rotVector)
	local vehPos = posVector+vehMatrix.right*3
	local vehicle = Vehicle(veh.model, vehPos, rotVector) or false
	if not vehicle then return false end
	vehicle.interior = player.interior
	vehicle.dimension = player.dimension
	if vehicle.vehicleType == "Bike" then vehicle.velocity = Vector3(0,0,-0.01) end

	local c = veh.colors
	setVehicleColor(vehicle, c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])
	setVehicleHeadLightColor(vehicle, veh.headlight[1], veh.headlight[2], veh.headlight[3])
	local w = veh.wheelcolor
	setElementData(vehicle, 'WheelsColorF', {w[1]/255, w[2]/255, w[3]/255})
	setElementData(vehicle, 'WheelsColorR', {w[1]/255, w[2]/255, w[3]/255})
	if veh.plate and veh.plate ~= '' then setVehiclePlateText(vehicle, veh.plate) end

	table.insert(g_PlayerData[player].vehicles, vehicle)
	g_VehicleData[vehicle] = { creator = player, timers = {} }
	g_GarageVehicleElement[serial] = g_GarageVehicleElement[serial] or {}
	g_GarageVehicleElement[serial][id] = vehicle
	g_ElementGarageInfo[vehicle] = { serial = serial, id = id }
	veh.active = true
	return vehicle
end

function sendGarageList(player)
	local serial = getPlayerSerial(player)
	local data = g_Garage[serial]
	local list = {}
	if data then
		for id, veh in pairs(data.vehicles) do
			table.insert(list, {
				id = id,
				name = veh.name or getVehicleNameFromModel(veh.model) or tostring(veh.model),
				plate = veh.plate,
				active = veh.active
			})
		end
	end
	table.sort(list, function(a,b) return a.id < b.id end)
	triggerClientEvent(player, 'onClientGarageList', resourceRoot, list)
end

function requestGarageList()
	sendGarageList(source)
end

function activateGarageVehicle(id)
	id = tonumber(id)
	if not id then return end
	local serial = getPlayerSerial(source)
	local data = g_Garage[serial]
	if not data or not data.vehicles[id] or data.vehicles[id].active then return end
	if countActiveGarageVehicles(serial) >= MAX_ACTIVE_GARAGE_VEHICLES then
		errMsg(('[✘] Aynı anda en fazla %d araç aktif olabilir. Önce birini pasif yapın.'):format(MAX_ACTIVE_GARAGE_VEHICLES), source)
		return
	end
	local vehicle = spawnGarageVehicle(source, serial, id)
	if vehicle then
		outputChatBox('[✔] Araç yanınızda hazır.', source, 0, 255, 0, true)
		saveGarageData()
	end
	sendGarageList(source)
end

function deactivateGarageVehicle(id)
	id = tonumber(id)
	if not id then return end
	local serial = getPlayerSerial(source)
	local data = g_Garage[serial]
	if not data or not data.vehicles[id] then return end
	local vehicle = g_GarageVehicleElement[serial] and g_GarageVehicleElement[serial][id]
	if vehicle and isElement(vehicle) then
		unloadVehicle(vehicle) -- also clears garage active state, see unloadVehicle
	else
		data.vehicles[id].active = false
		saveGarageData()
	end
	outputChatBox('[ⓘ] Araç garaja kaldırıldı.', source, 0, 150, 255, true)
	sendGarageList(source)
end

function saveGarageVehicleAppearance(vehicle)
	if not isElement(vehicle) then return end
	local garageInfo = g_ElementGarageInfo[vehicle]
	if not garageInfo then return end
	if g_VehicleData[vehicle] and g_VehicleData[vehicle].creator ~= source then return end
	local data = g_Garage[garageInfo.serial]
	local veh = data and data.vehicles[garageInfo.id]
	if not veh then return end
	local r1,g1,b1,r2,g2,b2,r3,g3,b3,r4,g4,b4 = getVehicleColor(vehicle, true)
	veh.colors = {r1,g1,b1,r2,g2,b2,r3,g3,b3,r4,g4,b4}
	local hr,hg,hb = getVehicleHeadLightColor(vehicle)
	veh.headlight = {hr,hg,hb}
	local wf = getElementData(vehicle, 'WheelsColorF')
	if wf then
		veh.wheelcolor = {math.floor((wf[1] or 0)*255), math.floor((wf[2] or 0)*255), math.floor((wf[3] or 0)*255)}
	end
	saveVehicleRow(garageInfo.serial, garageInfo.id, veh)
end

function spawnVehicleForPlayer(vehID, isTestDrive)
	local element = getPedOccupiedVehicle(source) or source
	local px,py,pz = getElementPosition(element)
	local _,_,prot = getElementRotation(element)
	local posVector = Vector3(px,py,pz+2)
	local rotVector = Vector3(0,0,prot)
	local vehMatrix = Matrix(posVector,rotVector)
	local vehPos = posVector+vehMatrix.right*3
	local vehicle = Vehicle(vehID, vehPos, rotVector) or false
	if vehicle then
		vehicle.interior = source.interior
		vehicle.dimension = source.dimension
		if vehicle.vehicleType == "Bike" then vehicle.velocity = Vector3(0,0,-0.01) end
		table.insert(g_PlayerData[source].vehicles, vehicle)
		g_VehicleData[vehicle] = { creator = source, timers = {}, testDrive = isTestDrive or nil }
		if g_Trailers[vehID] then
			if getOption('vehicles.idleexplode') then
				g_VehicleData[vehicle].timers.fire = setTimer(commitArsonOnVehicle, getOption('vehicles.maxidletime'), 1, vehicle)
			end
			g_VehicleData[vehicle].timers.destroy = setTimer(unloadVehicle, getOption('vehicles.maxidletime') + (getOption('vehicles.idleexplode') and 10000 or 0), 1, vehicle)
		end
	end
	return vehicle
end

function buyVehicle(vehID)
	vehID = tonumber(vehID)
	if not vehID then return end
	if table.find(getOption('vehicles.disallowed'), vehID) then
		errMsg(getVehicleNameFromModel(vehID):gsub('y$', 'ie') .. ' adlı aracın kullanılması yasaktır.', source)
		return
	end
	local price = getVehiclePrice(vehID)
	if not StageHasMoney(source, price) then
		errMsg(('[✘] Bu aracı satın almak için yeterli paranız yok. (Fiyat: $%s)'):format(formatMoney(price)), source)
		return
	end
	StageRemoveMoney(source, price)

	local serial = getPlayerSerial(source)
	local garage = ensureGarage(serial)
	local id = garage.nextId
	garage.nextId = id + 1
	garage.vehicles[id] = {
		model = vehID,
		plate = generateGaragePlate(),
		active = false,
		colors = {255,255,255, 255,255,255, 0,0,0, 0,0,0},
		headlight = {255,255,255},
		wheelcolor = {0,0,0}
	}

	outputChatBox(('[✔] %s adlı aracı $%s karşılığında satın aldınız ve garajınıza eklendi.'):format(getVehicleNameFromModel(vehID), formatMoney(price)), source, 0, 255, 0, true)

	if countActiveGarageVehicles(serial) < MAX_ACTIVE_GARAGE_VEHICLES then
		local vehicle = spawnGarageVehicle(source, serial, id)
		if vehicle then
			outputChatBox('[ⓘ] Aracınız yanınızda hazır.', source, 0, 150, 255, true)
		end
	else
		outputChatBox(('[ⓘ] Aynı anda en fazla %d araç aktif olabilir. Aracınızı F1 > Araçlarım panelinden aktif edebilirsiniz.'):format(MAX_ACTIVE_GARAGE_VEHICLES), source, 255, 200, 0, true)
	end

	saveGarageData()
	sendGarageList(source)
end

function testDriveVehicle(vehID)
	vehID = tonumber(vehID)
	if not vehID then return end
	if table.find(getOption('vehicles.disallowed'), vehID) then
		errMsg(getVehicleNameFromModel(vehID):gsub('y$', 'ie') .. ' adlı aracın kullanılması yasaktır.', source)
		return
	end
	local vehicleList = g_PlayerData[source].vehicles
	if #vehicleList >= getOption('vehicles.maxperplayer') then unloadVehicle(vehicleList[1]) end
	local vehicle = spawnVehicleForPlayer(vehID, true)
	if vehicle then
		outputChatBox('[ⓘ] Test sürüşü başladı, araç 60 saniye sonra geri alınacak. Beğendiyseniz F1 panelinden "Satın Al" ile alabilirsiniz.', source, 0, 150, 255, true)
		g_VehicleData[vehicle].timers.testdrive = setTimer(
			function()
				if isElement(vehicle) then
					outputChatBox('[ⓘ] Test sürüşü süresi doldu.', source, 0, 150, 255, true)
					unloadVehicle(vehicle)
				end
			end,
			60000, 1
		)
	end
end

_setPlayerGravity = setPedGravity
function setPedGravity(player, grav)
	if grav < getOption('gravity.min') then
		errMsg(('Minimum allowed gravity is %.5f'):format(getOption('gravity.min')), player)
	elseif grav > getOption('gravity.max') then
		errMsg(('Maximum allowed gravity is %.5f'):format(getOption('gravity.max')), player)
	else
		_setPlayerGravity(player, grav)
	end
end

function fadeVehiclePassengersCamera(toggle)
	local vehicle = getPedOccupiedVehicle(source)
	if not vehicle then
		return
	end
	local player
	for i=0,getVehicleMaxPassengers(vehicle) do
		player = getVehicleOccupant(vehicle, i)
		if player then
			fadeCamera(player, toggle)
		end
	end
end

addEventHandler('onVehicleEnter', root,
	function(player, seat)
		if not g_VehicleData[source] then
			return
		end
		if g_VehicleData[source].timers.fire then
			killTimer(g_VehicleData[source].timers.fire)
			g_VehicleData[source].timers.fire = nil
		end
		if g_VehicleData[source].timers.destroy then
			killTimer(g_VehicleData[source].timers.destroy)
			g_VehicleData[source].timers.destroy = nil
		end
		if not getOption('weapons.vehiclesenabled') and g_ArmedVehicles[getElementModel(source)] then
			toggleControl(player, 'vehicle_fire', false)
			toggleControl(player, 'vehicle_secondary_fire', false)
		end
		-- Fast Hunter/Hydra on custom gravity fix
		if getElementModel(source) == 425 or getElementModel(source) == 520 then
			if getPedGravity(player) ~= 0.008 then
				g_PlayerData[player].previousGravity = getPedGravity(player)
				setPedGravity(player, 0.008)
			end
		end
	end
)

addEventHandler('onVehicleExit', root,
	function(player, seat)
		if not g_VehicleData[source] then
			return
		end
		if not g_VehicleData[source].timers.fire then
			for i=0,getVehicleMaxPassengers(source) or 1 do
				if getVehicleOccupant(source, i) then
					return
				end
			end
			if getOption('vehicles.idleexplode') then
				g_VehicleData[source].timers.fire = setTimer(commitArsonOnVehicle, getOption('vehicles.maxidletime'), 1, source)
			end
			g_VehicleData[source].timers.destroy = setTimer(unloadVehicle, getOption('vehicles.maxidletime') + (getOption('vehicles.idleexplode') and 10000 or 0), 1, source)
		end
		if g_ArmedVehicles[getElementModel(source)] then
			toggleControl(player, 'vehicle_fire', true)
			toggleControl(player, 'vehicle_secondary_fire', true)
		end

		if g_PlayerData[player].previousGravity then
			setPedGravity(player, g_PlayerData[player].previousGravity)
			g_PlayerData[player].previousGravity = nil
		end
	end
)

function commitArsonOnVehicle(vehicle)
	g_VehicleData[vehicle].timers.fire = nil
	setElementHealth(vehicle, 0)
end

addEventHandler('onVehicleExplode', root,
	function()
		if not g_VehicleData[source] then
			return
		end
		if g_VehicleData[source].timers.fire then
			killTimer(g_VehicleData[source].timers.fire)
			g_VehicleData[source].timers.fire = nil
		end
		if not g_VehicleData[source].timers.destroy then
			g_VehicleData[source].timers.destroy = setTimer(unloadVehicle, 5000, 1, source)
		end
		if getVehicleController(source) then
			if g_PlayerData[getVehicleController(source)].previousGravity then
				setPedGravity(getVehicleController(source), g_PlayerData[getVehicleController(source)].previousGravity)
				g_PlayerData[getVehicleController(source)].previousGravity = nil
			end
		end
	end
)

function unloadVehicle(vehicle)
	if not g_VehicleData[vehicle] then
		return
	end
	for name,timer in pairs(g_VehicleData[vehicle].timers) do
		if isTimer(timer) then
			killTimer(timer)
		end
		g_VehicleData[vehicle].timers[name] = nil
	end
	local creator = g_VehicleData[vehicle].creator
	if g_PlayerData[creator] then
		table.removevalue(g_PlayerData[creator].vehicles, vehicle)
	end
	local garageInfo = g_ElementGarageInfo[vehicle]
	if garageInfo then
		local data = g_Garage[garageInfo.serial]
		if data and data.vehicles[garageInfo.id] then
			data.vehicles[garageInfo.id].active = false
		end
		if g_GarageVehicleElement[garageInfo.serial] then
			g_GarageVehicleElement[garageInfo.serial][garageInfo.id] = nil
		end
		g_ElementGarageInfo[vehicle] = nil
		saveGarageData()
	end
	g_VehicleData[vehicle] = nil
	if isElement(vehicle) then
		destroyElement(vehicle)
	end
end

function quitHandler(player)
	if g_PlayerData[source].blip and isElement(g_PlayerData[source].blip) then
		destroyElement(g_PlayerData[source].blip)
	end
	if sawnoffAntiAbuse[source] and isTimer (sawnoffAntiAbuse[source]) then
		killTimer (sawnoffAntiAbuse[source])
		sawnoffAntiAbuse[source] = nil
	end
	table.each(g_PlayerData[source].vehicles, unloadVehicle)
	removeEventHandler("onFreeroamLocalSettingChange",source,onLocalSettingChange)
	g_PlayerData[source] = nil
	chatTime[source] = nil
	lastChatMessage[source] = nil
end
----------------------------
-----Arac Dokunulmazlık-----
----------------------------
function AracDokunulmazlik_Modu(source)
if (isPedInVehicle(source ))then
if (isVehicleDamageProof(getPedOccupiedVehicle(source)) == false) then
setVehicleDamageProof(getPedOccupiedVehicle(source), true )
end
end
end
addEvent("AracDokunulmazlik_Event", true )
addEventHandler("AracDokunulmazlik_Event", resourceRoot, AracDokunulmazlik_Modu)

function AracDokunulmazlikKapat_Modu(source)
if (isPedInVehicle (source)) then
setVehicleDamageProof(getPedOccupiedVehicle(source), false )
end
end
addEvent("AracDokunulmazlikKapat_Event", true)
addEventHandler("AracDokunulmazlikKapat_Event", resourceRoot, AracDokunulmazlikKapat_Modu)

addEventHandler('onPlayerQuit', root, quitHandler)

addEvent('onServerCall', true)
addEventHandler('onServerCall', resourceRoot,
	function(fnName, ...)
		source = client		-- Some called functions require 'source' to be set to the triggering client
		local fnInfo = g_RPCFunctions[fnName]

		-- Custom check made to intercept the jetpack on custom gravity
		if fnInfo and type(fnInfo) ~= "boolean" and tostring(fnInfo.option) == "jetpack" then
			if tonumber(("%.3f"):format(getPedGravity(source))) ~= 0.008 then
				errMsg("Jetpack yalnızca yerçekimi 0.008 olursa kullanabilirsiniz", source)
				return
			end
		end

		if fnInfo and ((type(fnInfo) == 'boolean' and fnInfo) or (type(fnInfo) == 'table' and getOption(fnInfo.option))) then
			local fn = _G
			for i,pathpart in ipairs(fnName:split('.')) do
				fn = fn[pathpart]
			end
			fn(...)
		elseif type(fnInfo) == 'table' then
			errMsg(fnInfo.descr .. ' adlı fonksiyon bulunamadı.', source)
		end
	end
)

function clientCall(player, fnName, ...)
	triggerClientEvent(player, 'onClientCall', resourceRoot, fnName, ...)
end

function getPlayerName(player)
	return getOption("removeHex") and player.name:gsub("#%x%x%x%x%x%x","") or player.name
end

addEvent("onFreeroamLocalSettingChange",true)
