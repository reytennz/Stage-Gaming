local commands = {}

local customSpawnTable = false

local allowedStyles =

{

	[4] = true,

	[5] = true,

	[6] = true,

	[7] = true,

	[15] = true,

	[16] = true,

}

local internallyBannedWeapons = -- Fix for some debug warnings

{

	[19] = true,

	[20] = true,

	[21] = true,

}

local server = setmetatable(

		{},

		{

			__index = function(t, k)

				t[k] = function(...) triggerServerEvent('onServerCall', resourceRoot, k, ...) end

				return t[k]

			end

		}

	)

guiSetInputMode("no_binds_when_editing")

setCameraClip(true, false)



local antiCommandSpam = {} -- Place to store the ticks for anti spam:

local playerGravity = getGravity() -- Player's current gravity set by gravity window --

local knifeRestrictionsOn = false



-- Local settings received from server

local g_settings = {}

local _addCommandHandler = addCommandHandler

local _setElementPosition = setElementPosition



if not (g_PlayerData) then

    g_PlayerData = {}

end



-- Settings are stored in meta.xml

function freeroamSettings(settings)

	if settings then

		g_settings = settings

		for _,gui in ipairs(disableBySetting) do

			guiSetEnabled(getControl(gui.parent,gui.id),g_settings["gui/"..gui.id])

		end

	end

end



-- Store the tries for forced global cooldown

local global_cooldown = 0

function isFunctionOnCD(func, exception)

	local tick = getTickCount()

	-- check if a global cd is active

	if g_settings.command_spam_protection and global_cooldown ~= 0 then

		if tick - global_cooldown <= g_settings.command_spam_ban_duration then

			local duration = math.ceil((g_settings.command_spam_ban_duration-tick+global_cooldown)/1000)

			errMsg("Komut kullanımın " .. duration .." saniye yasaklandı")

			return true

		end

	end



	if not g_settings.command_spam_protection then

		return false

	end



	if not antiCommandSpam[func] then

		antiCommandSpam[func] = {time = tick, tries = 1}

		return false

	end



	local oldTime = antiCommandSpam[func].time

	if (tick-oldTime) > 2000 then

		antiCommandSpam[func].time = tick

		antiCommandSpam[func].tries = 1

		return false

	end



	antiCommandSpam[func].tries = antiCommandSpam[func].tries + 1



	if exception and (antiCommandSpam[func].tries < g_settings.g_settings.tries_required_to_trigger_low_priority) then

		return false

	end



	if (exception == nil) and (antiCommandSpam[func].tries < g_settings.tries_required_to_trigger) then

		return false

	end



	-- activate a global command cooldown

	global_cooldown = tick

	antiCommandSpam[func].tries = 0

	--errMsg("Failed, do not spam the commands!")

	return true

end



local function executeCommand(cmd,...)



	local func = commands[cmd]

	cmd = string.lower(cmd)

	if not commands[cmd] then return end

	if table.find(g_settings["command_exception_commands"],cmd) then

		func(cmd,...)

		return

	end

	if isFunctionOnCD(func) then return end

	func(cmd,...)



end



local function addCommandHandler(cmd,func)



	commands[cmd] = func

	_addCommandHandler(cmd,executeCommand,false)



end



local function cancelKnifeEvent(target)



	if knifingDisabled then

		cancelEvent()

		--errMsg("Knife restrictions are in place")

	end



	if g_PlayerData[localPlayer].knifing or g_PlayerData[target].knifing then

		cancelEvent()

	end



end



local function resetKnifing()



	knifeRestrictionsOn = false



end



local function setElementPosition(element,x,y,z)



	if g_settings["weapons/kniferestrictions"] and not knifeRestrictionsOn then

		knifeRestrictionsOn = true

		setTimer(resetKnifing,5000,1)

	end



	_setElementPosition(element,x,y,z)



end
---------------------------

-- Question window

---------------------------

function showReply(leaf)

local leaf = getSelectedGridListLeaf(wndQuestion, 'question')

	if leaf.name and leaf.desc then

		setControlNumber(wndQuestion, 'replylbl', leaf.desc)

	end

end





wndQuestion = {

	'wnd',

	text = 'Sıkça Sorulan Sorular',

	width = 450,

	controls = {

		{

			'lst',

			id='question',

			width=430,

			height=150,

			columns={

				{text='Sorular', attr='name'}

			},

			rows={xml='data/question.xml', attrs={'name', 'desc'}},

			onitemclick=showReply,

		},

		{'lbl', id='replylbl', align='left', text='                                                      ', height=125},

		{'btn', text='Kapat', closeswindow=true, x=140, width=150, color='FFC700'}

	}

}



---------------------------------------



function setVehicleGhost(sourceVehicle,value)



	local vehicles = getElementsByType("vehicle")

	for _,vehicle in ipairs(vehicles) do

		local vehicleGhost = hasDriverGhost(vehicle)

		setElementCollidableWith(sourceVehicle,vehicle,not value)

		setElementCollidableWith(vehicle,sourceVehicle,not value)

		if value == false and vehicleGhost == true then

			setElementCollidableWith(sourceVehicle,vehicle,not vehicleGhost)

			setElementCollidableWith(vehicle,sourceVehicle,not vehicleGhost)

		end

	end



end



local function onStreamIn()



	if source.type ~= "vehicle" then return end

	setVehicleGhost(source,hasDriverGhost(source))



end



local function onLocalSettingChange(key,value)



        if g_PlayerData[source] then g_PlayerData[source][key] = value end



	if key == "ghostmode" then

		local sourceVehicle = getPedOccupiedVehicle(source)

		if sourceVehicle then

			setVehicleGhost(sourceVehicle,hasDriverGhost(sourceVehicle))

		end

	end



end

---------------------------

-- Set skin window

---------------------------

function skinInit()

	setControlNumber(wndSkin, 'skinid', getElementModel(localPlayer))

end



function showSkinID(leaf)

	if leaf.id then

		setControlNumber(wndSkin, 'skinid', leaf.id)

	end

end



function applySkin()

	local skinID = getControlNumber(wndSkin, 'skinid')

	if skinID then

		server.setMySkin(skinID)

		fadeCamera(true)

	end

end



wndSkin = {

	'wnd',

	text = 'Karakterler',

	width = 250,

	x = -20,

	y = 0.3,

	controls = {

		{

			'lst',

			id='skinlist',

			width=230,

			height=290,

			columns={

				{text='Skin', attr='name'}

			},

			rows={xml='data/skins.xml', attrs={'id', 'name'}},

			onitemclick=showSkinID,

			onitemdoubleclick=applySkin,

			DoubleClickSpamProtected=true,

		},

		{'txt', id='skinid', text='', width=50},

		{'btn', id='Seç', onclick=applySkin, ClickSpamProtected = true,width=70, color="78c534"},

		{'btn', id='Kapat', closeswindow=true,width=70, color='FFC700' },

	},

	oncreate = skinInit

}



function setSkinCommand(cmd, skin)

	skin = skin and tonumber(skin)

	if skin then

		server.setMySkin(skin)

		fadeCamera(true)

		closeWindow(wndSpawnMap)

		closeWindow(wndSetPos)

	end

end

--addCommandHandler('setskin', setSkinCommand)

--addCommandHandler('ss', setSkinCommand)



---------------------------

--- Set animation window

---------------------------



function applyAnimation(leaf)

	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
	if getElementData(localPlayer,"Eventde") == true then  return false end
	if getElementData(localPlayer,"megatron:meslek") == true then  return false end
	if getElementData(localPlayer,"işlemyapıor") == true then return end

	if type(leaf) ~= 'table' then

		leaf = getSelectedGridListLeaf(wndAnim, 'animlist')

		if not leaf then

			return

		end

	end

	server.setPedAnimation(localPlayer, leaf.parent.name, leaf.name, true, true)

end



function stopAnimation()

	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
		if getElementData(localPlayer,"Eventde") == true then  return false end
		if getElementData(localPlayer,"megatron:meslek") == true then  return false end
		if getElementData(localPlayer,"Savas2Etkinlik") == true then  return false end
		if getElementData(localPlayer,"SavasEtkinlik") == true then  return false end
		if getElementData(localPlayer,"işlemyapıor") == true then return end

	server.setPedAnimation(localPlayer, false)

end

addCommandHandler("stopanim", stopAnimation)

bindKey("lshift", "down", stopAnimation)



wndAnim = {

	'wnd',

	text = 'Animasyonlar',

	width = 250,

	x = -20,

	y = 0.3,

	controls = {

		{

			'lst',

			id='animlist',

			width=230,

			height=290,

			columns={

				{text='Animasyonlar', attr='name'}

			},

			rows={xml='data/animations.xml', attrs={'name'}},

			expandlastlevel=false,

			onitemdoubleclick=applyAnimation,

			DoubleClickSpamProtected=true,

		},

		{'btn', id='Başlat', onclick=applyAnimation, ClickSpamProtected=true, width=70},

		{'btn', id='Durdur', onclick=stopAnimation, width=70},

		{'btn', id='Kapat', closeswindow=true, width=70, color='FFC700'}

	}

}



addCommandHandler('anim',

	function(command, lib, name)

		if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
		if getElementData(localPlayer,"Eventde") == true then  return false end
		if getElementData(localPlayer,"megatron:meslek") == true then  return false end
		if getElementData(localPlayer,"Savas2Etkinlik") == true then  return false end
		if getElementData(localPlayer,"SavasEtkinlik") == true then  return false end
		if getElementData(localPlayer,"işlemyapıor") == true then return end

		if lib and name and (

			(lib:lower() == "finale" and name:lower() == "fin_jump_on") or

			(lib:lower() == "finale2" and name:lower() == "fin_cop1_climbout")

		) then

			errMsg('This animation may not be set by command.')

			return

		end

		server.setPedAnimation(localPlayer, lib, name, true, true)

	end

)



function oturCommand()

if getElementData(localPlayer,"işlemyapıor") == true then return end

server.setPedAnimation(localPlayer,"ped","SEAT_idle",-1,true,false,false)

end

addCommandHandler("otur", oturCommand)



---------------------------

-- Weapon window

---------------------------



function addWeapon(leaf, amount)

	if type(leaf) ~= 'table' then

		leaf = getSelectedGridListLeaf(wndWeapon, 'weaplist')

		amount = getControlNumber(wndWeapon, 'amount')

		if not amount or not leaf or not leaf.id then

			return

		end

	end

	if amount < 1 then

		errMsg("Invalid amount")

		return

	end

	server.giveMeWeapon(leaf.id, amount)

end



wndWeapon = {

	'wnd',

	text = 'Temel Eşyalar',

	width = 250,

	controls = {

		{

			'lst',

			id='weaplist',

			width=230,

			height=280,

			columns={

				{text='Temel Eşyalar', attr='name'}

			},

			rows={xml='data/weapons.xml', attrs={'id', 'name'}},

			onitemdoubleclick=function(leaf) addWeapon(leaf, 1500) end,

			DoubleClickSpamProtected=true

		},

		{'br'},

		{'txt', id='amount', text='1500', width=60},

		{'btn', id='Al', onclick=addWeapon, ClickSpamProtected=true, width=70},

		{'btn', id='Kapat', closeswindow=true, width=70, color='FFC700'}

	}

}



---------------------------

-- Walk style

--------------------------- 

function applyWalkStyle( leaf )

    if type( leaf ) ~= 'table' then

        leaf = getSelectedGridListLeaf( wndWalking, 'walkStyle' )

        if not leaf then

            return

        end

    end

    server.setPedWalkingStyle(localPlayer, leaf.id)

end

 

function stopWalkStyle()

    server.setPedWalkingStyle(localPlayer, 0)

end

 

wndWalking = {

    'wnd',

    text = 'Yürüyüş Stilleri',

    width = 250,

    controls = {

        {

            'lst',

            id = 'walkStyle',

            width = 230,

            height = 290,

            columns = {

                { text = 'Stiller', attr = 'name' }

            },

            rows = { xml = 'data/walk.xml', attrs = { 'id', 'name' } },

            onitemdoubleclick = applyWalkStyle

        },

        { 'btn', id = 'Kullan', onclick = applyWalkStyle, width=70},

        { 'btn', id = 'Kaldır', onclick = stopWalkStyle, width=70, color='FFC700' },

        { 'btn', id = 'Kapat', closeswindow = true, width=70 }

    }

}



---------------------------

-- Fighting style

---------------------------



function applyFightStyle( leaf )

    if type( leaf ) ~= 'table' then

        leaf = getSelectedGridListLeaf( wndFighting, 'fightStyle' )

        if not leaf then

            return

        end

    end

    server.setPedFightingStyle( localPlayer, leaf.id )

end

 

function stopFightStyle()

    server.setPedFightingStyle( localPlayer, 0 )

end

 

wndFighting = {

    'wnd',

    text = 'Dövüs Stilleri',

    width = 250,

    controls = {

        {

            'lst',

            id = 'fightStyle',

            width = 230,

            height = 290,

            columns = {

                { text = 'Stiller', attr = 'name' }

            },

            rows = { xml = 'data/fight.xml', attrs = { 'id', 'name' } },

            onitemdoubleclick = applyFightStyle

        },

        { 'btn', id = 'Ayarla', onclick = applyFightStyle, width=70 },

        { 'btn', id = 'Durdur', onclick = stopFightStyle, width=70 },

        { 'btn', id = 'Kapat', closeswindow = true, width=70, color='FFC700' }

    }

}



addCommandHandler('setstyle',

	function(cmd, style)

		style = style and tonumber(style) or 7

		if allowedStyles[style] then

			server.setPedFightingStyle(localPlayer, style)

		end

	end

)



---------------------------

-- Clothes window

---------------------------

function clothesInit()

	if getElementModel(localPlayer) ~= 0 then

		errMsg('CJ (Carl Johnson) olmalısın.')

		closeWindow(wndClothes)

		return

	end

	if not g_Clothes then

		triggerServerEvent('onClothesInit', resourceRoot)

	end

end



addEvent('onClientClothesInit', true)

addEventHandler('onClientClothesInit', resourceRoot,

	function(clothes)

		g_Clothes = clothes.allClothes

		for i,typeGroup in ipairs(g_Clothes) do

			for j,cloth in ipairs(typeGroup.children) do

				if not cloth.name then

					cloth.name = cloth.model .. ' - ' .. cloth.texture

				end

				cloth.wearing =

					clothes.playerClothes[typeGroup.type] and

					clothes.playerClothes[typeGroup.type].texture == cloth.texture and

					clothes.playerClothes[typeGroup.type].model == cloth.model

					or false

			end

			table.sort(typeGroup.children, function(a, b) return a.name < b.name end)

		end

		bindGridListToTable(wndClothes, 'clothes', g_Clothes, false)

	end

)



function clothListClick(cloth)

	setControlText(wndClothes, 'addremove', cloth.wearing and 'Çıkar' or 'Giy')

end



function applyClothes(cloth)

	if not cloth then

		cloth = getSelectedGridListLeaf(wndClothes, 'clothes')

		if not cloth then

			return

		end

	end

	if cloth.wearing then

		cloth.wearing = false

		setControlText(wndClothes, 'addremove', 'Giy')

		server.removePedClothes(localPlayer, cloth.parent.type)

	else

		local prevClothIndex = table.find(cloth.siblings, 'wearing', true)

		if prevClothIndex then

			cloth.siblings[prevClothIndex].wearing = false

		end

		cloth.wearing = true

		setControlText(wndClothes, 'addremove', 'Çıkar')

		server.addPedClothes(localPlayer, cloth.texture, cloth.model, cloth.parent.type)

	end

end



wndClothes = {

	'wnd',

	text = 'Kıyafet',

	x = -20,

	y = 0.3,

	width = 350,

	controls = {

		{

			'lst',

			id='clothes',

			width=330,

			height=390,

			columns={

				{text='Kıyafet', attr='name', width=0.6},

				{text='Üzerindekiler', attr='wearing', enablemodify=true, width=0.3}

			},

			rows={

				{name='Giysi Listesi Alınıyor...'}

			},

			onitemclick=clothListClick,

			onitemdoubleclick=applyClothes,

			DoubleClickSpamProtected=true,

		},

		{'br'},

		{'btn', text='Giy/Çıkar', id='addremove', width=60, onclick=applyClothes, ClickSpamProtected=true},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	},

	oncreate = clothesInit

}



function addClothesCommand(cmd, type, model, texture)

	type = type and tonumber(type)

	if type and model and texture then

		server.addPedClothes(localPlayer, texture, model, type)

	end

end

addCommandHandler('addclothes', addClothesCommand)

addCommandHandler('ac', addClothesCommand)



function removeClothesCommand(cmd, type)

	type = type and tonumber(type)

	if type then

		server.removePedClothes(localPlayer, type)

	end

end

addCommandHandler('removeclothes', removeClothesCommand)

addCommandHandler('rc', removeClothesCommand)



---------------------------

-- Player gravity window

---------------------------

function playerGravInit()

	triggerServerEvent('onPlayerGravInit',localPlayer)

end



addEvent('onClientPlayerGravInit', true)

addEventHandler('onClientPlayerGravInit', resourceRoot,

	function(curgravity)

		setControlText(wndGravity, 'gravval', string.sub(tostring(curgravity), 1, 6))

	end

)



function selectPlayerGrav(leaf)

	setControlNumber(wndGravity, 'gravval', leaf.value)

end



function applyPlayerGrav()

	local grav = getControlNumber(wndGravity, 'gravval')

	if grav then

		playerGravity = grav

		server.setPedGravity(localPlayer, grav)

	end

	closeWindow(wndGravity)

end



function setGravityCommand(cmd, grav)

	if getElementData(g_Me, 'Event') == true then return false end

	if getElementData(g_Me, 'Etkinlik') == true then return false end

	if getElementData(g_Me, 'Taksi.1') == true then return false end

	if getElementData(g_Me, 'Taksi.2') == true then return false end

	if getElementData(g_Me, 'SilahGorev.1') == true then return false end

	if getElementData(g_Me, 'SilahGorev.2') == true then return false end

	if getElementData(g_Me, 'PetrolGorev.1') == true then return false end

	if getElementData(g_Me, 'PetrolGorev.2') == true then return false end

	if getElementData(g_Me, 'UyusturucuGorev.1') == true then return false end

	if getElementData(g_Me, 'UyusturucuGorev.2') == true then return false end

	if getElementData(g_Me, 'ArabaGorev.1') == true then return false end

	if getElementData(g_Me, 'ArabaGorev.2') == true then return false end

	if getElementData(g_Me, 'ArabaEtkinlik') == true then return false end

	local grav = grav and tonumber(grav)

	if grav then

		playerGravity = grav

		server.setPedGravity(localPlayer, tonumber(grav))

	end

end

--addCommandHandler('setgravity', setGravityCommand)

--addCommandHandler('grav', setGravityCommand)



wndGravity = {

	'wnd',

	text = 'Set gravity',

	width = 300,

	controls = {

		{

			'lst',

			id='gravlist',

			width=280,

			height=200,

			columns={

				{text='Gravity', attr='name'}

			},

			rows={

				{name='Space', value=0},

				{name='Moon', value=0.001},

				{name='Normal', value=0.008},

				{name='Strong', value=0.015}

			},

			onitemclick=selectPlayerGrav,

			onitemdoubleclick=applyPlayerGrav,

			DoubleClickSpamProtected=true,

		},

		{'lbl', text='Exact value: '},

		{'txt', id='gravval', text='', width=80},

		{'br'},

		{'btn', id='Değiştir', onclick=applyPlayerGrav,ClickSpamProtected=true},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	},

	oncreate = playerGravInit

}

-----------------------
------Arac God--------
-----------------------
function aracgod1()
if isPedInVehicle(localPlayer) == false then
outputChatBox(" #FFFFFFAraçta değilken kullanamazsın. ", 255, 0, 0, true)
end
if isPedInVehicle(localPlayer) == true then
	local state = guiCheckBoxGetSelected( getControl(wndMain, 'aracgod') )
		outputChatBox((state and "#43A047" or "#43A047").." #FFFFFF Hasarsız Araç Modu "..(state and "aktif." or "kapalı."),0,255,0,true)
--[!] #FFFFFFÖlümsüzlük Aktif Ediliyor...


	if getElementData(localPlayer,"aracgod31") == false then -- Oyuncunun ölümsüzlük datası eğer trueysa yani aktifse
		setElementData(localPlayer,"aracgod31",true)
triggerServerEvent("AracDokunulmazlik_Event", root, localPlayer)
	else -- Eğer oyuncunun ölümsüzlük datası false yani devre dışıysa
		setElementData(localPlayer,"aracgod31",false)
triggerServerEvent("AracDokunulmazlikKapat_Event", root, localPlayer)
	end
end


end
---------------------------

-- Weather

---------------------------



function applyWeather(leaf)

	if not leaf then

		leaf = getSelectedGridListLeaf(wndWeather, 'weatherlist')

		if not leaf then

			return

		end

	end

	server.setWeather(leaf.id)

	closeWindow(wndWeather)

end



wndWeather = {

	'wnd',

	text = 'Hava Durumu',

	width = 250,

	alpha = 1.0,

	controls = {

		{

			'lst',

			id='weatherlist',

			width=230,

			height=290,

			columns = {

				{text='Hava', attr='name'}

			},

			rows={xml='data/weather.xml', attrs={'id', 'name'}},

			onitemdoubleclick=applyWeather

		},

		{'btn', id='Tamam', onclick=applyWeather},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	}

}



function setWeatherCommand(cmd, weather)

	weather = weather and tonumber(weather)

	if weather then

		setWeather(weather)

	end

end

addCommandHandler('setweather', setWeatherCommand)

addCommandHandler('sw', setWeatherCommand)

addEvent("havadurumu:paneldurum",true)
addEventHandler("havadurumu:paneldurum",localPlayer,function(state)
end)

--addEvent("havadurumu:paneldurum",true)
--addEventHandler("havadurumu:paneldurum",root,function()
	--guiSetVisible(wndWeather,not guiGetVisible(wndWeather))
	--triggerEvent("Freeroam:addOpenedWindows",wndWeather,guiGetVisible(wndWeather))	
--end)



---------------------------

-- Warp to player window

---------------------------



local function warpMe(targetPlayer)



	if not g_settings["warp"] then

		errMsg("Işınlanma server tarafından kapatıldı!")

		return

	end



	if targetPlayer == localPlayer then

		errMsg("Kendine ışınlanamazsın!")

		return

	end



	if g_PlayerData[targetPlayer].warping then

		errMsg("Işınlanmak istediğin oyuncuya ışınlanamazsın!")

		return

	end



	local vehicle = getPedOccupiedVehicle(targetPlayer)

	local interior = getElementInterior(targetPlayer)

	if not vehicle then

		-- target player is not in a vehicle - just warp next to him

		local vec = targetPlayer.position + targetPlayer.matrix.right*2

		local x, y, z = vec.x,vec.y,vec.z

		if localPlayer.interior ~= interior then

			fadeCamera(false,1)

			setTimer(setPlayerInterior,1000,1,x,y,z,interior)

		else

			setPlayerPosition(x,y,z)

		end

	else

		-- target player is in a vehicle - warp into it if there's space left

		server.warpMeIntoVehicle(vehicle)

	end



end



function warpInit()

	setControlText(wndWarp, 'search', '')

	warpUpdate()

end



function warpTo(leaf)

	if not leaf then

		leaf = getSelectedGridListLeaf(wndWarp, 'playerlist')

		if not leaf then

			return

		end

	end

	if isElement(leaf.player) then

		warpMe(leaf.player)

	end

	closeWindow(wndWarp)

end



function warpUpdate()

	local function getPlayersByPartName(text)

		if not text or text == '' then

			return getElementsByType("player")

		else

			local players = {}

			for _, player in ipairs(getElementsByType("player")) do

				if string.find(getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):upper(), text:upper(), 1, true) then

					table.insert(players, player)

				end

			end

			return players

		end

	end

	

	local text = getControlText(wndWarp, 'search')

	local players = table.map(getPlayersByPartName(text), 

		function(p) 

			local pName = getPlayerName(p)

			if g_settings["hidecolortext"] then

				pName = pName:gsub("#%x%x%x%x%x%x", "")

			end

			return { player = p, name = pName } 

		end)

	table.sort(players, function(a, b) return a.name < b.name end)

	bindGridListToTable(wndWarp, 'playerlist', players, true)

end



wndWarp = {

	'wnd',

	text = 'Oyuncuya Işınlan',

	width = 300,

	controls = {

		{'txt', id='search', text='', width = 280, onchanged=warpUpdate},

		{

			'lst',

			id='playerlist',

			width=280,

			height=330,

			columns={

				{text='Player', attr='name'}

			},

			onitemdoubleclick=warpTo,

			DoubleClickSpamProtected=true,

		},

		{'btn', id='Işınlan', onclick=warpTo, ClickSpamProtected=true},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	},

	oncreate = warpInit

}


---------------------------
-- Gardrop
---------------------------

local outfitList
local outfits

function initOutfits()
	outfitList = wndOutfits.controls[1].element
	if outfits then return end
	loadOutfits()
	addEventHandler('onClientGUIDoubleClick', outfitList, loadClothes)
end

function loadOutfits()
	outfits = {}

	local xml = xmlLoadFile('outfits.xml')
	if not xml then
		xml = xmlCreateFile('outfits.xml', 'catalog')
	end
	guiGridListClear(outfitList)
	for i,child in ipairs (xmlNodeGetChildren(xml) or {}) do
		local row = guiGridListAddRow(outfitList)
		guiGridListSetItemText(outfitList, row, 1, tostring(xmlNodeGetAttribute(child, 'name')), false, false)
		outfits[row+1] = {}
		for j=0,17 do
			table.insert(outfits[row+1], j, xmlNodeGetAttribute(child, 'c'..j))
		end
	end
end

function saveOutfits()
	if fileExists('outfits.xml') then
		fileDelete('outfits.xml')
	end
	local xml = xmlCreateFile('outfits.xml', 'catalog')
	for row=0,(guiGridListGetRowCount(outfitList)-1) do
		local child = xmlCreateChild(xml, 'outfit')
		xmlNodeSetAttribute(child, 'name', guiGridListGetItemText(outfitList, row, 1))
		for k,v in pairs (outfits[row+1]) do
			xmlNodeSetAttribute(child, 'c'..k,v)
		end
	end
	xmlSaveFile(xml)
	xmlUnloadFile(xml)
end

function saveOutfit()
	local name = getControlText(wndOutfits,'outfitname')
	if name ~= "" then
		local row = guiGridListAddRow(outfitList)
		outfits[row+1] = {}
		for i=0,17 do
			local texture,model = getPedClothes (localPlayer, i)
			if texture and model then
				table.insert(outfits[row+1], i, texture ..', '.. model)
			else
				table.insert(outfits[row+1], i, 'none')
			end
		end
		guiGridListSetItemText(outfitList, row, 1, name, false, false)
		setControlText(wndOutfits, 'outfitname', '')
		saveOutfits()
	else
		outputChatBox('Kıyafet Sistemi: Kaydedeceğiniz Kıyafet Setinin Adını Giriniz!')
	end
end

function deleteOutfit()
	local row = guiGridListGetSelectedItem(outfitList)
	if row and row ~= -1 then
		table.remove(outfits, row+1)
		guiGridListRemoveRow(outfitList, row)
		saveOutfits()
	end
end

function loadClothes()
	local row = guiGridListGetSelectedItem(outfitList)
	if row and row ~= -1 then
		for k,v in pairs (outfits[row+1]) do
			if v ~= 'none' then
				local clothes = split(v, ', ')
				server.addPedClothes(localPlayer, clothes[1], clothes[2], k)
			else
				server.removePedClothes(localPlayer, k)
			end
		end
	end
end

wndOutfits = {
	'wnd',
	text = 'Kaydettiğim Kıyafetler',
	width = 170,
	x = -400,
	y = 0.3,
	controls = {
		{
			'lst',
			id='outfits',
			width=150,
			height=250,
			columns={
				{text='Kayıtlı Setler', attr='name', width=0.85},
			}
		},
		{'txt', id='outfitname', text='', width=100},
		{'btn', id='Kaydet', onclick=saveOutfit, width=45},
		{'btn', id='Setini Kaldır', onclick=deleteOutfit, width=100},
		{'btn', id='Kapat', closeswindow=true, width=45}
	},
	oncreate = initOutfits
}

---------------------------

-- Jetpack toggle

---------------------------

noktalar = {

	{ 1496.52759, -1833.08374, 2516.02661 },

	--{ 1493.3000488281, -1829.8000488281, 2516 },

	--{ 1509.1999511719, -1827.3000488281, 2516 },

}



addCommandHandler("devmode", function()

        setDevelopmentMode(true)

    end

)



function alanagirdi(giren)

	if ( giren == localPlayer ) then

	--	triggerServerEvent("zafer:jetpacksil",localPlayer)

		--setElementPosition(localPlayer,1508.46606, -1827.74304, 2516.02661)

	--	for _,vehicle in ipairs(getElementsByType("player")) do

	--		destroyElement(vehicle)

	---	end

	end

end



for i,v in pairs(noktalar) do

   drop_konum = createColSphere(v[1], v[2], v[3], 44)

   addEventHandler("onClientColShapeHit",drop_konum,alanagirdi)

end



function isPlayerInGorev()

	return getElementData(localPlayer,"isWorking") == 1

end



function toggleJetPack()

if  isElementWithinColShape(localPlayer,drop_konum) then outputChatBox("#0066ff[✘] #ffffffDropta iken jetpack kullanamazsınız.",255,0,0,true) return end

if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end

if getElementData(localPlayer,"ayarlarmenu") == true then outputChatBox("#0066ff[✘] #ffffffNargile alanında iken jetpack kullanamazsınız.",255,0,0,true) return false end

if getElementData(localPlayer,"isWorking") == true then outputChatBox("#0066ff[✘] #ffffffGörevdeyken jetpack kullanamazsınız.",255,0,0,true) return false end

if getElementData(localPlayer, 'Turf') == true then return false end

	if not doesPedHaveJetPack(localPlayer) then

		server.givePedJetPack(localPlayer)

		--guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), true)

	else

		server.removePedJetPack(localPlayer)

		--guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), false)

	end

end



bindKey('j', 'down', toggleJetPack)



addCommandHandler('jetpack', toggleJetPack)

addCommandHandler('jp', toggleJetPack)





---------------------------
-- Fall off bike toggle
---------------------------
function toggleFallOffBike()
	if getElementData(localPlayer, 'Turf') == true then return false end
	setPedCanBeKnockedOffBike(localPlayer, guiCheckBoxGetSelected(getControl(wndMain, 'falloff')))
end


---------------------------

-- Set position window

---------------------------

do

	local screenWidth, screenHeight = guiGetScreenSize()

	g_MapSide = (screenHeight * 0.85)

end



function setPosInit()

	local x, y, z = getElementPosition(localPlayer)

	setControlNumbers(wndSetPos, { x = x, y = y, z = z })



	addEventHandler('onClientRender', root, updatePlayerBlips)

end



function fillInPosition(relX, relY, btn)

	if (btn == 'right') then

		closeWindow (wndSetPos)

		return

	end



	local x = relX*6000 - 3000

	local y = 3000 - relY*6000

	local hit, hitX, hitY, hitZ

	hit, hitX, hitY, hitZ = processLineOfSight(x, y, 3000, x, y, -3000)

	setControlNumbers(wndSetPos, { x = x, y = y, z = hitZ or 0 })

end



function setPosClick()

	if setPlayerPosition(getControlNumbers(wndSetPos, {'x', 'y', 'z'})) ~= false then

		if getElementInterior(localPlayer) ~= 0 then

			local vehicle = localPlayer.vehicle

			if vehicle and vehicle.interior ~= 0 then

				server.setElementInterior(getPedOccupiedVehicle(localPlayer), 0)

				local occupants = vehicle.occupants

				for seat,occupant in pairs(occupants) do

					if occupant.interior ~= 0 then

						server.setElementInterior(occupant,0)

					end

				end

			end

			if localPlayer.interior ~= 0 then

				server.setElementInterior(localPlayer,0)

			end

		end

		closeWindow(wndSetPos)

	end

end



local function forceFade()



	fadeCamera(false,0)



end



local function calmVehicle(veh)



	if not isElement(veh) then return end

	local z = veh.rotation.z

	veh.velocity = Vector3(0,0,0)

	veh.turnVelocity = Vector3(0,0,0)

	veh.rotation = Vector3(0,0,z)

	if not (localPlayer.inVehicle and localPlayer.vehicle) then

		server.warpMeIntoVehicle(veh)

	end



end



local function retryTeleport(elem,x,y,z,isVehicle,distanceToGround)



	local hit, groundX, groundY, groundZ = processLineOfSight(x, y, 3000, x, y, -3000)

	if hit then

		local waterZ = getWaterLevel(x, y, 100)

		z = (waterZ and math.max(groundZ, waterZ) or groundZ) + distanceToGround

		setElementPosition(elem,x, y, z + distanceToGround)

		setCameraPlayerMode()

		setGravity(grav)

		if isVehicle then

			server.fadeVehiclePassengersCamera(true)

			setTimer(calmVehicle,100,1,elem)

		else

			fadeCamera(true)

		end

		killTimer(g_TeleportTimer)

		g_TeleportTimer = nil

		grav = nil

	end



end



function setPlayerPosition(x, y, z)

	triggerServerEvent("stageAC:f1Teleport", localPlayer)

	local elem = getPedOccupiedVehicle(localPlayer)

	local distanceToGround

	local isVehicle

	if elem then

		if getPlayerOccupiedSeat(localPlayer) ~= 0 then

			errMsg('Sadece Araç Koltuğundakiler Bu Komutu Kullanabilir.')

			return

		end

		distanceToGround = getElementDistanceFromCentreOfMassToBaseOfModel(elem) + 3

		isVehicle = true

	else

		elem = localPlayer

		distanceToGround = 0.4

		isVehicle = false

	end

	local hit, hitX, hitY, hitZ = processLineOfSight(x, y, 3000, x, y, -3000)

	if not hit then

		if isVehicle then

			server.fadeVehiclePassengersCamera(false)

		else

			fadeCamera(false)

		end

		if isTimer(g_TeleportMatrixTimer) then killTimer(g_TeleportMatrixTimer) end

		g_TeleportMatrixTimer = setTimer(setCameraMatrix, 1000, 1, x, y, z)

		if not grav then

			grav = getGravity()

			setGravity(0.001)

		end

		if isTimer(g_TeleportTimer) then killTimer(g_TeleportTimer) end

		g_TeleportTimer = setTimer(

			function()

				local hit, groundX, groundY, groundZ = processLineOfSight(x, y, 3000, x, y, -3000)

				if hit then

					local waterZ = getWaterLevel(x, y, 100)

					z = (waterZ and math.max(groundZ, waterZ) or groundZ) + distanceToGround

					if isPedDead(localPlayer) then

						server.spawnMe(x, y, z)

					else

						setElementPosition(elem, x, y, z)

					end

					setCameraPlayerMode()

					setGravity(grav)

					if isVehicle then

						server.fadeVehiclePassengersCamera(true)

					else

						fadeCamera(true)

					end

					killTimer(g_TeleportTimer)

					g_TeleportTimer = nil

					grav = nil

				end

			end,

			500,

			0

		)

	else

		if isPedDead(localPlayer) then

			server.spawnMe(x, y, z + distanceToGround)

		else

			setElementPosition(elem, x, y, z + distanceToGround)

			if isVehicle then

				setTimer(setElementVelocity, 100, 1, elem, 0, 0, 0)

				setTimer(setElementAngularVelocity, 100, 1, elem, 0, 0, 0)

			end

		end

	end

end



local blipPlayers = {}



local function destroyBlip()



	blipPlayers[source] = nil



end



local function warpToBlip()



	local wnd = isWindowOpen(wndSpawnMap) and wndSpawnMap or wndSetPos

	local elem = blipPlayers[source]



	if isElement(elem) then

		warpMe(elem)

		closeWindow(wnd)

	end



end



function updatePlayerBlips()

	if not g_PlayerData then

		return

	end

	local wnd = isWindowOpen(wndSpawnMap) and wndSpawnMap or wndSetPos

	local mapControl = getControl(wnd, 'map')

	for elem,player in pairs(g_PlayerData) do

		if not player.gui.mapBlip then

			local playerName = player.name

			if g_settings["hidecolortext"] then

				playerName = playerName:gsub("#%x%x%x%x%x%x", "")

			end

			player.gui.mapBlip = guiCreateStaticImage(0, 0, 9, 9, elem == localPlayer and 'localplayerblip.png' or 'playerblip.png', false, mapControl)

			player.gui.mapLabelShadow = guiCreateLabel(0, 0, 100, 14, playerName, false, mapControl)

			local labelWidth = guiLabelGetTextExtent(player.gui.mapLabelShadow)

			guiSetSize(player.gui.mapLabelShadow, labelWidth, 14, false)

			guiSetFont(player.gui.mapLabelShadow, 'default-bold-small')

			guiLabelSetColor(player.gui.mapLabelShadow, 255, 255, 255)

			player.gui.mapLabel = guiCreateLabel(0, 0, labelWidth, 14, playerName, false, mapControl)

			guiSetFont(player.gui.mapLabel, 'default-bold-small')

			guiLabelSetColor(player.gui.mapLabel, 0, 0, 0)

			for i,name in ipairs({'mapBlip', 'mapLabelShadow'}) do

				blipPlayers[player.gui[name]] = elem

				addEventHandler('onClientGUIDoubleClick', player.gui[name],warpToBlip,false)

				addEventHandler("onClientElementDestroy", player.gui[name],destroyBlip)

			end

		end

		local yazi = guiGetText(getControl(wndSetPos, 'playerSearch'))

		local x, y = getElementPosition(elem)

		local visible = (localPlayer.interior == elem.interior and localPlayer.dimension == elem.dimension)

		x = math.floor((x + 3000) * g_MapSide / 6000) - 4

		y = math.floor((3000 - y) * g_MapSide / 6000) - 4

		guiSetPosition(player.gui.mapBlip, x, y, false)

		guiSetPosition(player.gui.mapLabelShadow, x + 14, y - 4, false)

		guiSetPosition(player.gui.mapLabel, x + 13, y - 5, false)

		if yazi ~= "Oyuncu Ara..." then

			local playerName = player.name

			if g_settings["hidecolortext"] then

				playerName = playerName:gsub("#%x%x%x%x%x%x", "")

			end

			local yazi = guiGetText(getControl(wndSetPos, 'playerSearch')):lower()

			visible = (localPlayer.interior== elem.interior and (localPlayer.dimension == elem.dimension) and (type(playerName:find(yazi,1,true)) == "number") ) 

		end

		guiSetVisible(player.gui.mapBlip,visible)

		guiSetVisible(player.gui.mapLabelShadow,visible)

		guiSetVisible(player.gui.mapLabel,visible)

	end

end



function updateName(oldNick, newNick)

	if (not g_PlayerData) then return end

	local source = getElementType(source) == "player" and source or oldNick

	local player = g_PlayerData[source]

	player.name = newNick

	if player.gui.mapLabel then

		guiSetText(player.gui.mapLabelShadow, newNick)

		guiSetText(player.gui.mapLabel, newNick)

		local labelWidth = guiLabelGetTextExtent(player.gui.mapLabelShadow)

		guiSetSize(player.gui.mapLabelShadow, labelWidth, 14, false)

		guiSetSize(player.gui.mapLabel, labelWidth, 14, false)

	end

end



addEventHandler('onClientPlayerChangeNick', root,updateName)



function closePositionWindow()

	removeEventHandler('onClientRender', root, updatePlayerBlips)

end



wndSetPos = {

	'wnd',

	text = 'Harita',

	width = g_MapSide + 20,

	controls = {

		{'img', id='map', src='map.png', width=g_MapSide, height=g_MapSide, onclick=fillInPosition, ondoubleclick=setPosClick, DoubleClickSpamProtected=true},

		{'txt', id='x', text='', width=60},

		{'txt', id='y', text='', width=60},

		{'txt', id='z', text='', width=60},

		{'txt', id='playerSearch', text='Oyuncu Ara...', width=90, onclick=setSearchClick},

		{'btn', id='Işınlan', onclick=setPosClick, ClickSpamProtected=true},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	},

	oncreate = setPosInit,

	onclose = closePositionWindow

}



function getPosCommand(cmd, playerName)

	if getElementData(localPlayer, 'Turf') == true then return false end

	if getElementData(localPlayer, 'isWorking') == true then return false end

	local player, sentenceStart



	if playerName then

		player = getPlayerFromName(playerName)

		if not player then

			errMsg('There is no player named "' .. playerName .. '".')

			return

		end

		playerName = getPlayerName(player)		-- make sure case is correct

		sentenceStart = playerName .. ' is '

	else

		player = localPlayer

		sentenceStart = 'You are '

	end



	local px, py, pz = getElementPosition(player)

	local vehicle = getPedOccupiedVehicle(player)

	if vehicle then

		outputChatBox(sentenceStart .. 'in a ' .. getVehicleName(vehicle), 0, 255, 0)

	else

		outputChatBox(sentenceStart .. 'on foot', 0, 255, 0)

	end

	outputChatBox(sentenceStart .. 'at {' .. string.format("%.5f", px) .. ', ' .. string.format("%.5f", py) .. ', ' .. string.format("%.5f", pz) .. '}', 0, 255, 0)

end

addCommandHandler('getpos', getPosCommand)

addCommandHandler('gp', getPosCommand)



function setPosCommand(cmd, x, y, z, r)

	if getElementData(localPlayer, 'KolayAl2') == true then return false end

	if getElementData(localPlayer, 'NormalAl2') == true then return false end

	if getElementData(localPlayer, 'ZorAl2') == true then return false end

	if getElementData(localPlayer, 'Normal2') == true then return false end

	if getElementData(localPlayer, 'Uyusturucu2') == true then return false end

	if getElementData(localPlayer, 'Zor2') == true then return false end

	if getElementData(localPlayer, 'Tir2') == true then return false end

	if getElementData(localPlayer, 'Ambulans.2') == true then return false end

	if getElementData(localPlayer, 'PetrolGorev.1') == true then return false end

	if getElementData(localPlayer, 'SilahGorev.1') == true then return false end

	if getElementData(localPlayer, 'UyusturucuGorev.1') == true then return false end

	if getElementData(localPlayer, 'UyusturucuGorev.2') == true then return false end

	if getElementData(localPlayer, 'SilahGorev.2') == true then return false end

	if getElementData(localPlayer, 'KamyonGorev.1') == true then return false end

	if getElementData(localPlayer, 'KamyonGorev.2') == true then return false end

	if getElementData(localPlayer, 'KamyonAl2') == true then return false end

	if getElementData(localPlayer, 'YarisEtkinlik') == true then return false end

	if getElementData(localPlayer, 'ArabaEtkinlik') == true then return false end

	if getElementData(localPlayer, 'FallOutEtkinlik') == true then return false end

	if getElementData(localPlayer, 'BisikletEtkinlik') == true then return false end

	if getElementData(localPlayer, 'SavasEtkinlik') == true then return false end

	if getElementData(localPlayer, 'Dust2Etkinlik') == true then return false end
	if getElementData(localPlayer, 'job_lesorub') == true then return false end
	if getElementData(localPlayer, 'job') == true then return false end
	if getElementData(localPlayer, 'tirci') == true then return false end
	if getElementData(localPlayer, 'Job.Gruz2') == true then return false end
	if getElementData(localPlayer, 'Job.Gruz') == true then return false end
	if getElementData(localPlayer, 'derevo') == true then return false end
	if getElementData(localPlayer, 'madencil') == true then return false end
	if getElementData(localPlayer, 'returnVeh_Le_Ra') == true then return false end
	if getElementData(localPlayer, 'Veh_Le_Ra_Ragruz') == true then return false end
	if getElementData(localPlayer, 'KamyonAl2') == true then return false end
	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
	if getElementData(localPlayer,"Eventde") == true then  return false end
	if getElementData(localPlayer,"megatron:meslek") == true then  return false end
	if getElementData(localPlayer,"işlemyapıor") == true then return end

	-- Handle setpos if used like: x, y, z, r or x,y,z,r

	local x, y, z, r = string.gsub(x or "", ",", " "), string.gsub(y or "", ",", " "), string.gsub(z or "", ",", " "), string.gsub(r or "", ",", " ")

	-- Extra handling for x,y,z,r

	if (x and y == "" and not tonumber(x)) then

		x, y, z, r = unpack(split(x, " "))

	end

	

	local px, py, pz = getElementPosition(localPlayer)

	local pr = getPedRotation(localPlayer)

	

	local message = ""

	if (not tonumber(x)) then

		message = "X "

	end

	if (not tonumber(y)) then

		message = message.."Y "

	end

	if (not tonumber(z)) then

		message = message.."Z "

	end

	if (message ~= "") then

	end

	

	setPlayerPosition(tonumber(x) or px, tonumber(y) or py, tonumber(z) or pz)

	if (isPedInVehicle(localPlayer)) then

		local vehicle = getPedOccupiedVehicle(localPlayer)

		if (vehicle and isElement(vehicle) and getVehicleController(vehicle) == localPlayer) then

			setElementRotation(vehicle, 0, 0, tonumber(r) or pr)

		end

	else

		setPedRotation(localPlayer, tonumber(r) or pr)

	end

end

addCommandHandler('setpos', setPosCommand)

addCommandHandler('sp', setPosCommand)



---------------------------

-- Spawn map window

---------------------------

function warpMapInit()

	addEventHandler('onClientRender', root, updatePlayerBlips)

end



function spawnMapDoubleClick(relX, relY)

	setPlayerPosition(relX*6000 - 3000, 3000 - relY*6000, 0)

	closeWindow(wndSpawnMap)

end



function closeSpawnMap()

	showCursor(false)

	removeEventHandler('onClientRender', root, updatePlayerBlips)

	for elem,data in pairs(g_PlayerData) do

		for i,name in ipairs({'mapBlip', 'mapLabelShadow', 'mapLabel'}) do

			if data.gui[name] then

				destroyElement(data.gui[name])

				data.gui[name] = nil

			end

		end

	end

end



wndSpawnMap = {

	'wnd',

	text = 'Select spawn position',

	width = g_MapSide + 20,

	controls = {

		{'img', id='map', src='map.png', width=g_MapSide, height=g_MapSide, ondoubleclick=spawnMapDoubleClick},

		{'lbl', text='Welcome to freeroam. Double click a location on the map to spawn.', width=g_MapSide-60, align='center'},

		{'btn', id='close', closeswindow=true}

	},

	oncreate = warpMapInit,

	onclose = closeSpawnMap

}



---------------------------

-- Create vehicle window

---------------------------

---------------------------
-- Vehicle prices (normal MTA economy)
---------------------------
-- Prices are derived from each vehicle's default handling data (top speed,
-- mass, acceleration) so every model gets a sensible, non-hardcoded price.
-- The server calculates this same value independently before taking money,
-- so a player can never fake a cheaper price from the client.
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
	local str = tostring(math.floor(amount))
	local formatted = str:reverse():gsub('(%d%d%d)', '%1.'):reverse()
	return formatted:gsub('^%.', '')
end

-- Galeri: sadece stok katalogu (isim, id, fiyat, stok) — freeroam xml/handling YOK
g_GalleryCatalog = g_GalleryCatalog or {}
g_GalleryRows = {} -- row+1 -> vehicle id

function vehicleShowroomInit()
	triggerServerEvent('f1stock:requestAll', localPlayer)
	fillGalleryGrid(g_GalleryCatalog)
end

function fillGalleryGrid(list)
	local grid = getControl(wndCreateVehicle, 'vehicles')
	if not grid then return end
	guiGridListClear(grid)
	g_GalleryRows = {}
	list = list or {}
	table.sort(list, function(a, b) return (a.name or '') < (b.name or '') end)
	for _, v in ipairs(list) do
		local row = guiGridListAddRow(grid)
		guiGridListSetItemText(grid, row, 1, v.name or ('ID '..tostring(v.id)), false, false)
		guiGridListSetItemText(grid, row, 2, tostring(v.id), false, false)
		guiGridListSetItemText(grid, row, 3, '$' .. formatMoney(v.price or 0), false, false)
		local st = tonumber(v.stock) or 0
		guiGridListSetItemText(grid, row, 4, st <= 0 and 'STOK YOK' or tostring(st), false, false)
		g_GalleryRows[row + 1] = v.id
	end
end

function refreshVehicleShowroomStock()
	if not wndCreateVehicle or not wndCreateVehicle.element then return end
	if not isWindowOpen(wndCreateVehicle) then return end
	fillGalleryGrid(g_GalleryCatalog)
end

function getSelectedGalleryVehicleId()
	local grid = getControl(wndCreateVehicle, 'vehicles')
	if not grid then return nil end
	local row = guiGridListGetSelectedItem(grid)
	if not row or row < 0 then return nil end
	return g_GalleryRows[row + 1]
end

function testDriveSelectedVehicle()
	local id = getSelectedGalleryVehicleId()
	if not id then
		outputChatBox('#0066ff[✘] #ffffffÖnce listeden bir araç seçin.', 255, 0, 0, true)
		return
	end
	server.testDriveVehicle(id)
end

function buySelectedVehicle()
	local id = getSelectedGalleryVehicleId()
	if not id then
		outputChatBox('#0066ff[✘] #ffffffÖnce listeden bir araç seçin.', 255, 0, 0, true)
		return
	end
	local st = 0
	for _, v in ipairs(g_GalleryCatalog) do
		if v.id == id then st = tonumber(v.stock) or 0 break end
	end
	if st <= 0 then
		outputChatBox('#ff0000[✘] #ffffffBu araç stokta yok.', 255, 255, 255, true)
		return
	end
	server.buyVehicle(id)
end

wndCreateVehicle = {

	'wnd',

	text = 'Araç Galerisi',

	width = 480,

	controls = {

		{

			'lst',

			id='vehicles',

			width=460,

			height=340,

			columns={

				{text='İsim', attr='name', width=0.35},

				{text='ID', attr='id', width=0.15},

				{text='Fiyat', attr='price', width=0.25},

				{text='Stok', attr='stock', width=0.25}

			},

		},

		{'btn', id='Dene', onclick=testDriveSelectedVehicle, ClickSpamProtected=true, width=100},

		{'btn', id='Satın Al', onclick=buySelectedVehicle, ClickSpamProtected=true, width=100},

		{'btn', id='Kapat', closeswindow=true, width=90, color='FFD700'},

	},

	oncreate = vehicleShowroomInit

}

---------------------------
-- Araçlarım (My Vehicles / Garage)
---------------------------

local myVehicleList
local myVehicleRows = {} -- [row+1] = {id=, active=}

function initMyVehicles()
	myVehicleList = wndMyVehicles.controls[1].element
	server.requestGarageList()
end

function refreshMyVehicles(list)
	if not myVehicleList then return end
	guiGridListClear(myVehicleList)
	myVehicleRows = {}
	for i, veh in ipairs(list) do
		local row = guiGridListAddRow(myVehicleList)
		guiGridListSetItemText(myVehicleList, row, 1, veh.name, false, false)
		guiGridListSetItemText(myVehicleList, row, 2, veh.plate, false, false)
		guiGridListSetItemText(myVehicleList, row, 3, veh.active and 'Aktif' or 'Pasif', false, false)
		myVehicleRows[row+1] = {id = veh.id, active = veh.active}
	end
end
addEvent('onClientGarageList', true)
addEventHandler('onClientGarageList', resourceRoot, function(list) refreshMyVehicles(list) end)

addEvent('stageGarage:openAfterBuy', true)
addEventHandler('stageGarage:openAfterBuy', resourceRoot, function()
	createWindow(wndMyVehicles)
	showCursor(true)
	initMyVehicles()
end)

function toggleSelectedGarageVehicle()
	local row = guiGridListGetSelectedItem(myVehicleList)
	if not row or row == -1 then
		outputChatBox('#0066ff[✘] #ffffffÖnce listeden bir araç seçin.', 255, 0, 0, true)
		return
	end
	local info = myVehicleRows[row+1]
	if not info then return end
	if info.active then
		server.deactivateGarageVehicle(info.id)
	else
		server.activateGarageVehicle(info.id)
	end
end

wndMyVehicles = {
	'wnd',
	text = 'Araçlarım',
	width = 400,
	controls = {
		{
			'lst',
			id='myvehiclelist',
			width=400,
			height=260,
			columns={
				{text='Araç', attr='name', width=0.45},
				{text='Plaka', attr='plate', width=0.30},
				{text='Durum', attr='status', width=0.25}
			}
		},
		{'btn', id='Aktif Et / Pasif Et', onclick=toggleSelectedGarageVehicle, ClickSpamProtected=true, width=280},
		{'btn', id='Kapat', closeswindow=true, width=110, color='FFD700'},
	},
	oncreate = initMyVehicles
}

addCommandHandler('araclarim', function()
	if isWindowOpen(wndMyVehicles) then
		closeWindow(wndMyVehicles)
	else
		createWindow(wndMyVehicles)
		showCursor(true)
	end
end)



---------------------------

-- Repair vehicle

---------------------------

function repairVehicle()
	if getElementData(localPlayer, 'Turf') == true then return false end
	if getElementData(localPlayer, 'Eventde') == true then return false end
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then return end
	if vehicle then
		server.fixVehicle(vehicle)
	end
end



addCommandHandler('repair', repairVehicle)

addCommandHandler('rp', repairVehicle)



---------------------------

-- Flip vehicle

---------------------------

function flipVehicle()

if getElementData(localPlayer, 'Turf') == true then return false end
if getElementData(localPlayer, 'Eventde') == true then return false end

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if vehicle then

		local rX, rY, rZ = getElementRotation(vehicle)

		setElementRotation(vehicle, 0, 0, (rX > 90 and rX < 270) and (rZ + 180) or rZ)

	end

end



addCommandHandler('flip', flipVehicle)

addCommandHandler('f', flipVehicle)





---------------------------

-- Toggle lights

---------------------------

function forceLightsOn()

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if not vehicle then

		return

	end

	if guiCheckBoxGetSelected(getControl(wndMain, 'lightson')) then

		server.setVehicleOverrideLights(vehicle, 2)

		guiCheckBoxSetSelected(getControl(wndMain, 'lightsoff'), false)

	else

		server.setVehicleOverrideLights(vehicle, 0)

	end

end



function forceLightsOff()

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if not vehicle then

		return

	end

	if guiCheckBoxGetSelected(getControl(wndMain, 'lightsoff')) then

		server.setVehicleOverrideLights(vehicle, 1)

		guiCheckBoxSetSelected(getControl(wndMain, 'lightson'), false)

	else

		server.setVehicleOverrideLights(vehicle, 0)

	end

end





---------------------------

-- Color

---------------------------



function setColorCommand(cmd, ...)

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if not vehicle then

		return

	end

	local colors = { getVehicleColor(vehicle) }

	local args = { ... }

	for i=1,12 do

		colors[i] = args[i] and tonumber(args[i]) or colors[i]

	end

	server.setVehicleColor(vehicle, unpack(colors))

end

addCommandHandler('color', setColorCommand)

addCommandHandler('cl', setColorCommand)



function openColorPicker()

	editingVehicle = getPedOccupiedVehicle(localPlayer)

	if (editingVehicle) then

		colorPicker.openSelect(colors)

	end

end



function closedColorPicker()

	local r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4 = getVehicleColor(editingVehicle, true)

	server.setVehicleColor(editingVehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4)

	local r, g, b = getVehicleHeadLightColor(editingVehicle)

	server.setVehicleHeadLightColor(editingVehicle, r, g, b)

	server.saveGarageVehicleAppearance(editingVehicle)

	editingVehicle = nil

end



local r6,g6,b6,r7,g7,b7

function updateColor()

	if (not colorPicker.isSelectOpen) then return end

	local r, g, b = colorPicker.updateTempColors()

	if (editingVehicle and isElement(editingVehicle)) then

		local r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4  = getVehicleColor(editingVehicle, true)

		if (guiCheckBoxGetSelected(checkColor1)) then

			r1, g1, b1 = r, g, b

		end

		if (guiCheckBoxGetSelected(checkColor2)) then

			r2, g2, b2 = r, g, b

		end

		if (guiCheckBoxGetSelected(checkColor3)) then

			r3, g3, b3 = r, g, b

		end

		if (guiCheckBoxGetSelected(checkColor4)) then

			r4, g4, b4 = r, g, b

		end

		if (guiCheckBoxGetSelected(checkColor5)) then

			setVehicleHeadLightColor(editingVehicle, r, g, b)

		end

		if (guiCheckBoxGetSelected(checkColor6)) then

			if (r6 ~= r) or (g6 ~= g) or (b6 ~= b) then

				r6,g6,b6 = r, g, b

				setElementData(editingVehicle,"WheelsColorF",{r/255,g/255,b/255})

				setElementData(editingVehicle,"WheelsColorR",{r/255,g/255,b/255})

			end	

		end

		setVehicleColor(editingVehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4)

	end

end

addEventHandler("onClientRender", root, updateColor)



---------------------------

-- Paintjob

---------------------------



function paintjobInit()

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if not vehicle then

		errMsg('You need to be in a car to change its paintjob.')

		closeWindow(wndPaintjob)

		return

	end

	local paint = getVehiclePaintjob(vehicle)

	if paint then

		guiGridListSetSelectedItem(getControl(wndPaintjob, 'paintjoblist'), paint+1, 1)

	end

end



function applyPaintjob(paint)

	server.setVehiclePaintjob(getPedOccupiedVehicle(localPlayer), paint.id)

end



wndPaintjob = {

	'wnd',

	text = 'Car paintjob',

	width = 220,

	x = -20,

	y = 0.3,

	controls = {

		{

			'lst',

			id='paintjoblist',

			width=200,

			height=130,

			columns={

				{text='Paintjob ID', attr='id'}

			},

			rows={

				{id=0},

				{id=1},

				{id=2},

				{id=3}

			},

			onitemclick=applyPaintjob,

			ClickSpamProtected=true,

			ondoubleclick=function() closeWindow(wndPaintjob) end

		},

		{'btn', id='close', closeswindow=true},

	},

	oncreate = paintjobInit

}



function setPaintjobCommand(cmd, paint)

	local vehicle = getPedOccupiedVehicle(localPlayer)

	paint = paint and tonumber(paint)

	if not paint or not vehicle then

		return

	end

	server.setVehiclePaintjob(vehicle, paint)

end

addCommandHandler('paintjob', setPaintjobCommand)

addCommandHandler('pj', setPaintjobCommand)





---------------------------

-- Time

---------------------------

function timeInit()

	local hours, minutes = getTime()

	setControlNumbers(wndTime, { hours = hours, minutes = minutes })

end



function selectTime(leaf)

	setControlNumbers(wndTime, { hours = leaf.h, minutes = leaf.m })

end



function applyTime()

	local hours, minutes = getControlNumbers(wndTime, { 'hours', 'minutes' })

	setTime(hours, minutes)

	closeWindow(wndTime)

end



wndTime = {

	'wnd',

	text = 'Set time',

	width = 220,

	controls = {

		{

			'lst',

			id='timelist',

			width=200,

			height=150,

			columns={

				{text='Time', attr='name'}

			},

			rows={

				{name='Midnight',  h=0, m=0},

				{name='Dawn',      h=5, m=0},

				{name='Morning',   h=9, m=0},

				{name='Noon',      h=12, m=0},

				{name='Afternoon', h=15, m=0},

				{name='Evening',   h=20, m=0},

				{name='Night',     h=22, m=0}

			},

			onitemclick=selectTime,

			ondoubleclick=applyTime

		},

		{'txt', id='hours', text='', width=40},

		{'lbl', text=':'},

		{'txt', id='minutes', text='', width=40},

		{'btn', id='Uygula', onclick=applyTime, color="78c534"},

		{'btn', id='Kapat', closeswindow=true, color='FFC700'}

	},

	oncreate = timeInit

}



function setTimeCommand(cmd, hours, minutes)

	if not hours then

		return

	end

	local curHours, curMinutes = getTime()

	hours = tonumber(hours) or curHours

	minutes = minutes and tonumber(minutes) or curMinutes

	setTime(hours, minutes)

end

addCommandHandler('saat', setTimeCommand)

addCommandHandler('st', setTimeCommand)



function toggleFreezeTime()

	local state = guiCheckBoxGetSelected(getControl(wndMain, 'freezetime'))

	--guiCheckBoxSetSelected(getControl(wndMain, 'freezetime'), not state)

	setTimeFrozen(state)

end



function setTimeFrozen(state, h, m, w)

	--guiCheckBoxSetSelected(getControl(wndMain, 'freezetime'), state)

	if state then

		if not g_TimeFreezeTimer then

			g_TimeFreezeTimer = setTimer(function() setTime(h, m) setWeather(w) end, 5000, 0)

			setMinuteDuration(9001)

		end

	else

		if g_TimeFreezeTimer then

			killTimer(g_TimeFreezeTimer)

			g_TimeFreezeTimer = nil

		end

		setMinuteDuration(1000)

	end

end



---------------------------

-- Handling

---------------------------

function aracdisi()

	--local vehicle = getPedOccupiedVehicle(g_Me)

	if not vehicle then

		errMsg('Hand eklemek için bir arabanız olmalıdır.')

		--closeWindow(wndHandlingg)

		return

	end

end	

wndHandlingg = {

	'wnd',

	text = 'Handlar',

	width = 385,

	controls = {

        {'btn', id='4x4 Drift 1', height  = 37, width = 180},

		{'btn', id='4x4 Drift 2', height  = 37, width = 180},

		{'btn', id='4x2 Drift 1', height  = 37, width = 180},

		{'btn', id='4x2 Drift 2', height  = 37, width = 180},

		{'btn', id='4x2 Drift 3', height  = 37, width = 180},

		{'btn', id='Ters Drift', height  = 37, width = 180},

		{'btn', id='Ön Kaldırma', height  = 37, width = 180},

		{'btn', id='Motor Sürüş', height  = 37, width = 180},

		{'br'},

		{'btn', id='Kapat', height  = 20, width = 362, closeswindow=true, color='FFC700'},

	},

    oncreate = aracdisi	

}



addEventHandler("onClientGUIClick",root,

    function ()

        if ( source == getControl(wndHandlingg,'4x4 Drift 1') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr1", getPedOccupiedVehicle( localPlayer ) )

		elseif ( source == getControl(wndHandlingg,'4x4 Drift 2') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr2", getPedOccupiedVehicle( localPlayer ) )

		elseif ( source == getControl(wndHandlingg,'4x2 Drift 1') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr3", getPedOccupiedVehicle( localPlayer ) )

        elseif ( source == getControl(wndHandlingg,'4x2 Drift 2') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr4", getPedOccupiedVehicle( localPlayer ) )		

        elseif ( source == getControl(wndHandlingg,'4x2 Drift 3') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr5", getPedOccupiedVehicle( localPlayer ) )		

        elseif ( source == getControl(wndHandlingg,'Ters Drift') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr6", getPedOccupiedVehicle( localPlayer ) )		

        elseif ( source == getControl(wndHandlingg,'Ön Kaldırma') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr7", getPedOccupiedVehicle( localPlayer ) )		

        elseif ( source == getControl(wndHandlingg,'Motor Sürüş') ) then

           triggerServerEvent( "onVehicleChangeHandling", localPlayer, "Nastr8", getPedOccupiedVehicle( localPlayer ) )				

        end

    end

)

---------------------------

-- Weather

---------------------------

function applyWeather(leaf)

	if not leaf then

		leaf = getSelectedGridListLeaf(wndWeather, 'weatherlist')

		if not leaf then

			return

		end

	end

	setWeather(leaf.id)

	closeWindow(wndWeather)

end



wndWeather = {

	'wnd',

	text = 'Set weather',

	width = 250,

	controls = {

		{

			'lst',

			id='weatherlist',

			width=230,

			height=290,

			columns = {

				{text='Weather type', attr='name'}

			},

			rows={xml='data/weather.xml', attrs={'id', 'name'}},

			onitemdoubleclick=applyWeather

		},

		{'btn', id='ok', onclick=applyWeather},

		{'btn', id='cancel', closeswindow=true}

	}

}



function setWeatherCommand(cmd, weather)

	weather = weather and tonumber(weather)

	if weather then

		setWeather(weather)

	end

end

addCommandHandler('setweather', setWeatherCommand)

addCommandHandler('sw', setWeatherCommand)



---------------------------

-- Game speed

---------------------------



function setMyGameSpeed(speed)



	speed = speed and tonumber(speed) or 1



	if g_settings["gamespeed/enabled"] then

		if speed > g_settings["gamespeed/max"] then

			errMsg(('Maximum allowed gamespeed is %.5f'):format(g_settings['gamespeed/max']))

		elseif speed < g_settings["gamespeed/min"] then

			errMsg(('Minimum allowed gamespeed is %.5f'):format(g_settings['gamespeed/min']))

		else

			setGameSpeed(speed)

		end

	else

		errMsg("Setting game speed is disallowed!")

	end



end



function gameSpeedInit()

	setControlNumber(wndGameSpeed, 'speed', getGameSpeed())

end



function selectGameSpeed(leaf)

	setControlNumber(wndGameSpeed, 'speed', leaf.id)

end



function applyGameSpeed()

	speed = getControlNumber(wndGameSpeed, 'speed')

	if speed then

		setMyGameSpeed(speed)

	end

	closeWindow(wndGameSpeed)

end



wndGameSpeed = {

	'wnd',

	text = 'Set game speed',

	width = 220,

	controls = {

		{

			'lst',

			id='speedlist',

			width=200,

			height=150,

			columns={

				{text='Speed', attr='name'}

			},

			rows={

				{id=3, name='3x'},

				{id=2, name='2x'},

				{id=1, name='1x'},

				{id=0.5, name='0.5x'}

			},

			onitemclick=selectGameSpeed,

			ondoubleclick=applyGameSpeed

		},

		{'txt', id='speed', text='', width=40},

		{'btn', id='ok', onclick=applyGameSpeed},

		{'btn', id='cancel', closeswindow=true}

	},

	oncreate = gameSpeedInit

}



---------------------------

-- Chat Gizle

---------------------------



local isChatVisible = true

   function chat()

  if isChatVisible then

    showChat(false)

    isChatVisible = false

  else

    showChat(true)

    isChatVisible = true

  end

end

---------------------------

-- Main window

---------------------------



function toggleWarping(state)



	--local state = guiCheckBoxGetSelected( getControl(wndMain, 'disablewarp') )

	triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"warping",state)

	--outputChatBox("Artık diğer oyuncular yanına "..(state and "ışınlanamaz" or "ışınlanabilir"),0,102,255)



end
addEvent("Freeroam:Işınlanma", true)
addEventHandler("Freeroam:Işınlanma", root, toggleWarping)


function toggleGhostmode()



	local state = guiCheckBoxGetSelected( getControl(wndMain, 'antiram') )

	triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"ghostmode",state)

	outputChatBox("Araç Hayalet Modu "..(state and "Aktif" or "Kapalı"),0,102,255)





end


function updateGUI(updateVehicle)

	-- update position

	--local x, y, z = getElementPosition(localPlayer)

	--setControlNumbers(wndMain, {xpos=math.ceil(x), ypos=math.ceil(y), zpos=math.ceil(z)})

end



function mainWndShow()

	if not getPedOccupiedVehicle(localPlayer) then

		hideControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')

	end

	updateTimer = updateTimer or setTimer(updateGUI, 2000, 0)

	updateGUI(true)

end



function mainWndClose()

	killTimer(updateTimer)

	updateTimer = nil

	colorPicker.closeSelect()

end


function hasDriverGhost(vehicle)



	if not g_PlayerData then return end

	if not isElement(vehicle) then return end

	if getElementType(vehicle) ~= "vehicle" then return end



	local driver = getVehicleController(vehicle)

	if g_PlayerData[driver] and g_PlayerData[driver].ghostmode then return true end

	return false



end
--[[
--## GOD MODE ##--
function render()
    if getPedWeaponSlot(localPlayer) ~= 0 then
    setPedWeaponSlot(localPlayer,0)
    end
end

function iptalFunc()
    cancelEvent()
end

function unDamaged()
local state = guiCheckBoxGetSelected(getControl(wndMain,'godMode'))
if state == true then
	guiSetEnabled(getControl(wndMain, 'godMode'), false)
	triggerServerEvent("unDamaged", root, localPlayer)
	addEventHandler("onClientRender", root, render)
	exports.HudYamasi:drawProgressBar("unDamaged", "Ölümsüzlük Açılıyor", 30, 150, 255,25*1000)
	setTimer ( function()
		addEventHandler("onClientPlayerDamage", localPlayer, iptalFunc)
		guiSetEnabled(getControl(wndMain, 'godMode'), true)
	end, 25*1000, 1 )
elseif state == false then
	removeEventHandler("onClientPlayerDamage", localPlayer, iptalFunc)
	triggerServerEvent("unDamagedClose", root, localPlayer)
	removeEventHandler("onClientRender", root, render)
end
end
]]

-----ÖLÜMSÜZLÜK---------

--------------------------

setElementData(localPlayer,"buton:data",true)

function olumsuzFunction ()

if getElementData(localPlayer,"buton:data") == true then
--exports.hudyamasi:drawProgressBar("OlumsuzPro", "Ölümsüzlük Açılıyor", 30, 150, 255,0)
    setTimer ( function()
--    addEventHandler("onClientPlayerDamage", localPlayer, iptalFunc)
        --guiSetEnabled(getControl(wndMain, 'godMode'), true)
        end, 0, 1 )

setTimer(function()
setElementData(localPlayer,"olumsuz:aktif",true)

outputChatBox(" #ffffffÖlümsüzlük modu Aktif !", 0, 255, 0, true)

triggerServerEvent("setElementAlpha",localPlayer,100)
toggleControl ("fire", false)

setElementData(localPlayer,"buton:data",false)
end,0,1)

else

setElementData(localPlayer,"olumsuz:aktif",false)

outputChatBox("#ffffffÖlümsüzlük modu Kapatıldı !", 255, 0, 0, true)

triggerServerEvent("setElementAlpha",localPlayer,255)

setElementData(localPlayer,"buton:data",true)
toggleControl ("fire", true)

end

end



function player_damage ()

if getElementData(localPlayer,"olumsuz:aktif") == true then

cancelEvent()

end

end

addEventHandler("onClientPlayerDamage", getRootElement(), player_damage)



function silah_kontrol ()

if getElementData(localPlayer,"olumsuz:aktif") == true then

if getPedWeaponSlot(localPlayer) ~= 0 then

setPedWeaponSlot(localPlayer,0)

end

end

end

addEventHandler ( "onClientRender", getRootElement(), silah_kontrol)
----------------------------------------------------------------------------

----------------------------------------------------------------------------
local function renderKnifingTag()
	if getElementData(localPlayer, "olumsuz:aktif") then return end
	if not g_PlayerData then return end
	for _,p in ipairs (getElementsByType ('player', root, true)) do
		if g_PlayerData[p] and g_PlayerData[p].knifing then
			local px,py,pz = getElementPosition(p)
			local x,y,d = getScreenFromWorldPosition (px, py, pz+1.3)
			if x and y and d < 20 then
				dxDrawText ('Dokunulmaz', x+1, y+1, x, y, tocolor (0, 0, 0), 1, 'default-bold', 'center')
				dxDrawText ('Dokunulmaz', x, y, x, y, tocolor (0, 200, 0), 1, 'default-bold', 'center')
				setPedWeaponSlot(p, 0)
			end
		end
    end
end
addEventHandler ('onClientRender', root, renderKnifingTag)
----------------------------------------------------------------------------

----------------------------------------------------------------------------



function onEnterVehicle(vehicle,seat)

	if source == localPlayer then

		showControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')

		guiCheckBoxSetSelected(getControl(wndMain, 'lightson'), getVehicleOverrideLights(vehicle) == 2)

		guiCheckBoxSetSelected(getControl(wndMain, 'lightsoff'), getVehicleOverrideLights(vehicle) == 1)

	end

	if seat == 0 and g_PlayerData[source] then

		setVehicleGhost(vehicle,hasDriverGhost(vehicle))

	end

end



function onExitVehicle(vehicle,seat)

	if (eventName == "onClientPlayerVehicleExit" and source == localPlayer) or (eventName == "onClientElementDestroy" and getElementType(source) == "vehicle" and getPedOccupiedVehicle(localPlayer) == source) then

		hideControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')

		closeWindow(wndColor)

	elseif vehicle and seat == 0 then

		if source and g_PlayerData[source] then

			setVehicleGhost(vehicle,hasDriverGhost(vehicle))

		end

	end

end



function killLocalPlayer()

if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end

if getElementData(localPlayer,"işlemyapıor") == true then return end

	if g_settings["kill"] then

		setElementHealth(localPlayer,0)

	else

		errMsg("Killing yourself is disallowed!")

	end

end

addCommandHandler('kill', killLocalPlayer)



function kamberPanel()
	if not getPedOccupiedVehicle(localPlayer) then errMsg('Kamber eklemek için bir arabaya sahip olmalısın.') return end
    if getVehicleController(getPedOccupiedVehicle(localPlayer) ) ~= localPlayer then
        errMsg('Kamber sistemini açman için sürücü sahibi olman gerekmektedir.')
		return
    end
	triggerEvent("JantOzellestirme:KamberPanel",resourceRoot)
	
end

---------------------------
-- Bookmarks window
---------------------------

local bookmarkList
local bookmarks

function initBookmarks ()
	bookmarkList = wndBookmarks.controls[1].element
	if bookmarks then return end
	loadBookmarks ()
	addEventHandler('onClientGUIDoubleClick',bookmarkList,gotoBookmark)
end

function loadBookmarks ()
	bookmarks = {}
	local xml = xmlLoadFile('bookmarks.xml')
	if not xml then
		xml = xmlCreateFile('bookmarks.xml','catalog')
	end
	guiGridListClear(bookmarkList)
	for i,child in ipairs (xmlNodeGetChildren(xml) or {}) do
		local row = guiGridListAddRow(bookmarkList)
		guiGridListSetItemText(bookmarkList,row,1,tostring(xmlNodeGetAttribute(child,'name')),false,false)
		guiGridListSetItemText(bookmarkList,row,2,tostring(xmlNodeGetAttribute(child,'zone')),false,false)
		bookmarks[row+1] = {tonumber(xmlNodeGetAttribute(child,'x')),tonumber(xmlNodeGetAttribute(child,'y')),tonumber(xmlNodeGetAttribute(child,'z'))}
	end
	xmlUnloadFile(xml)
end

function saveBookmarks ()
	if fileExists('bookmarks.xml') then
		fileDelete('bookmarks.xml')
	end
	local xml = xmlCreateFile('bookmarks.xml','catalog')
	for row=0,(guiGridListGetRowCount(bookmarkList)-1) do
		local child = xmlCreateChild(xml,'bookmark')
		xmlNodeSetAttribute(child,'name',guiGridListGetItemText(bookmarkList,row,1))
		xmlNodeSetAttribute(child,'zone',guiGridListGetItemText(bookmarkList,row,2))
		xmlNodeSetAttribute(child,'x',tostring(bookmarks[row+1][1]))
		xmlNodeSetAttribute(child,'y',tostring(bookmarks[row+1][2]))
		xmlNodeSetAttribute(child,'z',tostring(bookmarks[row+1][3]))
	end
	xmlSaveFile(xml)
	xmlUnloadFile(xml)
end

function saveLocation ()
	local name = getControlText(wndBookmarks,'bookmarkname')
	if name ~= '' then
		local x,y,z = getElementPosition(localPlayer)
		local zone = getZoneName(x,y,z,false)
		if x and y and z then
			local row = guiGridListAddRow(bookmarkList)
			guiGridListSetItemText(bookmarkList,row,1,name,false,false)
			guiGridListSetItemText(bookmarkList,row,2,zone,false,false)
			bookmarks[row+1] = {x,y,z}
			setControlText(wndBookmarks,'bookmarkname','')
			saveBookmarks()
		end
	else
		errMsg('Öncelikle kayıt edeceğiniz bölgenin adını giriniz.')
	end
end

function deleteLocation ()
	local row,column = guiGridListGetSelectedItem(bookmarkList)
	if row and row ~= -1 then
		table.remove(bookmarks,row+1)
		guiGridListRemoveRow(bookmarkList,row)
		saveBookmarks()
	end
end

function gotoBookmark ()
	local row = guiGridListGetSelectedItem(bookmarkList)
	if row and row ~= -1 then
		setPlayerPosition(unpack(bookmarks[row+1]))
	end
end

wndBookmarks = {
	'wnd',
	text = 'Kayıtlı Bölgeler',
	width = 400,
	x = -300,
	y = 0.2,
	controls = {
		{
			'lst',
			id='bookmarklist',
			width=400,
			columns={
				{text='Kayıt Adı', attr='name', width=0.3},
				{text='Bölge', attr='zone', width=0.6}
			}
		},
		{'txt', id='bookmarkname', text='', width=225},
		{'btn', id='save current location', text='Ekle', onclick=saveLocation, width=150},
		{'btn', id='delete selected location', text='Sil', onclick=deleteLocation, width=225},
		{'btn', id='close', text='Kapat', closeswindow=true, width=150}
	},
	oncreate = initBookmarks
}


------------------------------
-----AntiLag Panel-----
------------------------------
function LagPaneli()
LagSistemiAc()
end



setTimer(function()
guiLabelSetColor (getControl(wndMain,'swhakkında'), 255, 255, 0 )
guiLabelSetColor (getControl(wndMain,'gorevsistem'), 255, 255, 0 )
guiLabelSetColor (getControl(wndMain,'animpanel'), 255, 0, 255 )
end,1000,1)

function comingSoonFeature()
	outputChatBox('#ff9900[ⓘ] #ffffffBu özellik yakında eklenecek.', 255, 255, 255, true)
end

wndMain = {

	'wnd',

	text = '#Stage Gaming - F1 Panel ',

	x = 10,

	y = 130,

	width = 240,

	controls = {

	{'br'},
		{'chk', id='aracgod', text='Hasarsız Araç', onclick=aracgod1, width = 105,x = 10},
		{'chk', id='olumsuz', text='Ölümsüzlük', onclick=olumsuzFunction, width = 105,x = 125},
		{'br'},
		{'btn', id='swhakkında', text='Sunucu Hakkında', window=wndAbout, width = 220,x = 10, color="FFD700"},
		{'br'},
		{'btn', id='ayarlar', text='Ayarlar', window=wndSettings, width = 105,x = 10,color="FFD700"},
		{'btn', id='meslekler', text='Meslekler', window=wndJobs, width = 105,x = 125},
		{'br'},
		{'btn', id='Modları Yönet', event='modlar:yonet', width = 220,x = 10,color="FFD700"},
		{'br'},
		{'btn', id='paragonder', text='Para Gönder', event='panel:transfer', width = 105,x = 10},
		{'btn', id='siralama', text='Sıralama Paneli', onclick=openLeaderboardPanel, width = 105,x = 125},
		{'br'},
		{'btn', id='Karakterler', window=wndSkin, width = 105,x = 10},
		{'btn', id='weapon', text='Temel Eşyalar', window=wndWeapon, width = 105,x = 125},
		{'br'},
		{'btn', id='Ölüm', text='İntihar', onclick=killLocalPlayer, width = 105,x = 10},
		{'btn', id='clothes', text='CJ Kıyafet', window=wndClothes, width = 105,x = 125},
		{'br'},
		{'btn', id='bookmarks', text='Teleport Panel', window=wndBookmarks, width = 105,x = 10},
		{'btn', id='Animasyonlar', window=wndAnim, width = 105,x = 125},
		{'br'},
		{'btn', id='Işınlan', window=wndWarp, width = 105,x = 10},
		{'btn', id='twitter', text='Twitter', onclick=comingSoonFeature, width = 105,x = 125},
		{'br'},
		{'btn', id='duello', text='Düello', onclick=openDuelPanel, width = 105,x = 10},
		{'btn', id='Hava Durumu', window=wndWeather, width = 105,x = 125},
		{'br'},
		{'btn', id='setpos', text='Harita', window=wndSetPos, width= 220,x = 10,color="FFD700"},
		{'br'},
		{'btn', id='createvehicle', text='Sıfır Araç Galerisi', window=wndCreateVehicle, width=105, x=10},
		{'btn', id='myvehicles', text='Araçlarım', window=wndMyVehicles, width=105, x=125},
		{'br'},
		{'btn', id='sahibinden', text='Sahibinden.com', window=wndSahibinden, width=220, x=10},
		{'br'},
		{'chk', id='disableknife', text='Bıçak Engel', onclick=toggleKnifing, width = 105,x = 10},
		{'chk', id='falloff', text='Motordan Düşme', onclick=toggleFallOffBike, width = 105,x = 125},
		{'br'},
		{'chk', id='lightson', text='Farı Aç', onclick=forceLightsOn, width = 105,x = 10},
		{'chk', id='lightsoff', text='Farı Kapat', onclick=forceLightsOff, width = 105,x = 125},
		{'br'},
		{'btn', id='Boya', onclick=openColorPicker, width = 220,x = 10},

	},

	oncreate = mainWndShow,

	onclose = mainWndClose

}



disableBySetting =

{

	{parent=wndMain, id="antiram"},

	{parent=wndMain, id="disablewarp"},

	{parent=wndMain, id="disableknife"},

}



function errMsg(msg)

	outputChatBox("#FF7A00[Stage Gaming] #FFFFFF" .. tostring(msg), 255, 255, 255, true)

end



addEventHandler('onClientResourceStart', resourceRoot,

	function()

		fadeCamera(true)

		getPlayers()

		setJetpackMaxHeight ( 9001 )

		triggerServerEvent('onLoadedAtClient', resourceRoot)

		createWindow(wndMain)

		hideAllWindows()

		bindKey('f1', 'down', toggleFRWindow)

		guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), doesPedHaveJetPack(localPlayer))

		guiCheckBoxSetSelected(getControl(wndMain, 'falloff'), canPedBeKnockedOffBike(localPlayer))

	end

)



function showWelcomeMap()
	-- Oyuncu ilk giriste / oluyken spawn haritasi
	createWindow(wndSpawnMap)
	showCursor(true)
	fadeCamera(true)
end

function showMap()
	createWindow(wndSetPos)
	showCursor(true)
end

-- Harita cift tik: yerde spawn (z=0 yerine ground)
local _spawnMapDoubleClick = spawnMapDoubleClick
function spawnMapDoubleClick(relX, relY)
	local x = relX * 6000 - 3000
	local y = 3000 - relY * 6000
	setPlayerPosition(x, y, 0)
	closeWindow(wndSpawnMap)
	showCursor(false)
	fadeCamera(true)
end

local timerkoruma
local serius = {}


function toggleFRWindow()
if not getElementData(localPlayer,"megatron:meslek") or getElementData(localPlayer,"Durum") == "Madenci" then
    if isWindowOpen(wndMain) then

        showCursor(false)

        hideAllWindows()

        colorPicker.closeSelect()
		triggerEvent("wheelSystem:setWindowState",root,false)
		triggerEvent("kornasistemi:paneldurum",root,false)
		--triggerEvent("ayarlarwindow:paneldurum",root,false)
		--triggerEvent("youtubepanel:paneldurum",root,false)
		triggerEvent("tuningpanel:paneldurum",root,false)
		triggerEvent("crosspanel:paneldurum",root,false)
		--triggerEvent("yardimpanel:paneldurum",root,false)
		triggerEvent("modsistem:paneldurum",root,false)
		triggerEvent("arackaplamasistemi:paneldurum",root,false)
		--triggerEvent("plakasistemi:servertrigeryolla",root,false)

    else

        if guiGetInputMode() ~= "no_binds_when_editing" then

            guiSetInputMode("no_binds_when_editing")

        end

        if getElementData(localPlayer,"isWorking") == 1 then

            errMsg("Görevde iken F1 panele erişemezsin.")

            return

        end

        if getElementDimension(localPlayer) ~= 0 then

            errMsg("F1 panele erişmek için /kill yaz.")

            return

        end


        showCursor(true)

        showAllWindows()

    end
end
end

--
addCommandHandler("fr",function()
	if not getElementData(localPlayer,"megatron:meslek") or getElementData(localPlayer,"Durum") == "Madenci" then
    if isWindowOpen(wndMain) then
        showCursor(false)
        hideAllWindows()
        colorPicker.closeSelect()
		triggerEvent("wheelSystem:setWindowState",root,false)
		triggerEvent("kornasistemi:paneldurum",root,false)
		--triggerEvent("ayarlarwindow:paneldurum",root,false)
		--triggerEvent("youtubepanel:paneldurum",root,false)
		triggerEvent("tuningpanel:paneldurum",root,false)
		triggerEvent("crosspanel:paneldurum",root,false)
		--triggerEvent("yardimpanel:paneldurum",root,false)
		triggerEvent("modsistem:paneldurum",root,false)
		triggerEvent("arackaplamasistemi:paneldurum",root,false)
		--triggerEvent("plakasistemi:servertrigeryolla",root,false)
    else
        if guiGetInputMode() ~= "no_binds_when_editing" then
            guiSetInputMode("no_binds_when_editing")
        end
        if getElementData(localPlayer,"isWorking") == 1 then
            errMsg("Görevde iken F1 panele erişemezsin.")
            return
        end
        if getElementDimension(localPlayer) ~= 0 then
            errMsg("F1 panele erişmek için /kill yaz.")
            return
        end
		if isTimer(timerkoruma) or serius == true then
			errMsg("F1 panele erişmek için 5dk bekle.")
			return
		end		
		serius = true
		--toggleFRWindow()
		timerkoruma = setTimer(function()
			serius = nil
		end,5000,1)
        showCursor(true)
        showAllWindows()
		end
	end
end)
--[[

--]]

addEvent("onPlayerGetJob",true)

addEvent("onPlayerFinishJob",true)

addEvent("onPlayerQuitJob",true)

addEvent("EventSistem:onClientJoinEvent",true)

addEvent("TurfSistem:onClientPlayerEnterTurf",true)



function f1panelkapat()

	showCursor(false)

	hideAllWindows()

	colorPicker.closeSelect()

end



addEventHandler("onPlayerGetJob",localPlayer,function()

	f1panelkapat()

end)

addEventHandler("EventSistem:onClientJoinEvent",localPlayer,function()

	f1panelkapat()

end)

addEventHandler("TurfSistem:onClientPlayerEnterTurf",localPlayer,function()

	f1panelkapat()

end)



function getPlayers()

	g_PlayerData = {}

	table.each(getElementsByType('player'), joinHandler)

end



function joinHandler(player)

	if (not g_PlayerData) then return end

	g_PlayerData[player or source] = { name = getPlayerName(player or source), gui = {} }

end



function quitHandler()

	if (not g_PlayerData) then return end

	local veh = getPedOccupiedVehicle(source)

	local seat = (veh and getVehicleController(veh) == localPlayer) and 0 or 1

	if seat == 0 then

		onExitVehicle(veh,0)

	end

	table.each(g_PlayerData[source].gui, destroyElement)

	g_PlayerData[source] = nil

end



function wastedHandler()

	if source == localPlayer then

		onExitVehicle()

		if g_settings["spawnmapondeath"] then

			setTimer(showMap,2000,1)

		end

	else

		local veh = getPedOccupiedVehicle(source)

		local seat = (veh and getVehicleController(veh) == localPlayer) and 0 or 1

		if seat == 0 then

			onExitVehicle(veh,0)

		end

	end

end



local function removeForcedFade()

	removeEventHandler("onClientPreRender",root,forceFade)

	fadeCamera(true)

end



local function checkCustomSpawn()



	if type(customSpawnTable) == "table" then

		local x,y,z = unpack(customSpawnTable)

		setPlayerPosition(x,y,z,true)

		customSpawnTable = false

		setTimer(removeForcedFade,100,1)

	end



end



addEventHandler('onClientPlayerJoin', root, joinHandler)

addEventHandler('onClientPlayerQuit', root, quitHandler)

addEventHandler('onClientPlayerWasted', root, wastedHandler)

addEventHandler('onClientPlayerVehicleEnter', root, onEnterVehicle)

addEventHandler('onClientPlayerVehicleExit', root, onExitVehicle)

addEventHandler("onClientElementDestroy", root, onExitVehicle)

addEventHandler("onClientPlayerSpawn", localPlayer, checkCustomSpawn)



function getPlayerName(player)

	return g_settings["removeHex"] and player.name:gsub("#%x%x%x%x%x%x","") or player.name

end



addEventHandler('onClientResourceStop', resourceRoot,

	function()

		showCursor(false)

		setPedAnimation(localPlayer, false)

	end

)



function setVehicleGhost(sourceVehicle,value)



	  local vehicles = getElementsByType("vehicle")

	  for _,vehicle in ipairs(vehicles) do

		local vehicleGhost = hasDriverGhost(vehicle)

		if isElement(sourceVehicle) and isElement(vehicle) then

		   setElementCollidableWith(sourceVehicle,vehicle,not value)

		   setElementCollidableWith(vehicle,sourceVehicle,not value)

		end

		if value == false and vehicleGhost == true and isElement(sourceVehicle) and isElement(vehicle) then

			setElementCollidableWith(sourceVehicle,vehicle,not vehicleGhost)

			setElementCollidableWith(vehicle,sourceVehicle,not vehicleGhost)

		end

	end



end



local function onStreamIn()



	if source.type ~= "vehicle" then return end

	setVehicleGhost(source,hasDriverGhost(source))



end



local function onLocalSettingChange(key,value)



	g_PlayerData[source][key] = value



	if key == "ghostmode" then

		local sourceVehicle = getPedOccupiedVehicle(source)

		if sourceVehicle then

			setVehicleGhost(sourceVehicle,hasDriverGhost(sourceVehicle))

		end

	end



end



local function renderKnifingTag()

	if not g_PlayerData then return end

	for _,p in ipairs (getElementsByType ("player", root, true)) do

		if g_PlayerData[p] and g_PlayerData[p].knifing then

			local px,py,pz = getElementPosition(p)

			local x,y,d = getScreenFromWorldPosition (px, py, pz+1.3)

			if x and y and d < 20 then

				--dxDrawText ("Disabled Knifing", x+1, y+1, x, y, tocolor (0, 0, 0), 0.5, "bankgothic", "center")

				--dxDrawText ("Disabled Knifing", x, y, x, y, tocolor (220, 220, 0), 0.5, "bankgothic", "center")

			end

		end

    end

end



addEventHandler ("onClientRender", root, renderKnifingTag)



addEvent("onClientFreeroamLocalSettingChange",true)

addEventHandler("onClientFreeroamLocalSettingChange",root,onLocalSettingChange)

addEventHandler("onClientPlayerStealthKill",localPlayer,cancelKnifeEvent)

addEventHandler("onClientElementStreamIn",root,onStreamIn)



function windowf1_closeserius()

	showCursor(false)

	hideAllWindows()

	guiSetVisible(OyuncuKontrolleri, false)

end
