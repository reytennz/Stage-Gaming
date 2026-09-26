-- === MySQL bağlantısı (bağımsız / standalone) ===
-- Kendi bilgilerinle doldur:
local MYSQL_HOST = "localhost"
local MYSQL_PORT = "3306"
local MYSQL_USER = "root"
local MYSQL_PASS = ""
local MYSQL_DB   = "mta_server"

connection = dbConnect("mysql", "dbname="..MYSQL_DB..";host="..MYSQL_HOST..";port="..MYSQL_PORT, MYSQL_USER, MYSQL_PASS, "autoreconnect=1;batch=0")
if not connection then
    outputDebugString("[rrp_furniture] MySQL bağlantısı kurulamadı! Bilgileri kontrol et (s_furniture.lua üst kısmı).", 1)
end

Async:setPriority("low")
--Async:setDebug(true)

--Jesse [LOG]
--!!!!! !!!!!---
-- Örnek tablo verisi: {furnitures: {id,x,y,z,interior,dimension,rotation,model,owner,placed,texture} }
--!!!!! !!!!!---
--Jesse [LOG]

Furnitures = {}
local attachedFurnitures = {}
local cache = {}
-- tablo verisi start:
-- cache[dbid]
-- tablo verisi end:
addEventHandler("onResourceStart", getResourceRootElement(),
    function()
    	if not connection then return end
    	dbExec(connection, [[
    		CREATE TABLE IF NOT EXISTS `furnitures` (
    			`id` INT NOT NULL AUTO_INCREMENT,
    			`owner` INT NOT NULL DEFAULT 0,
    			`model` INT NOT NULL DEFAULT 0,
    			`x` FLOAT NOT NULL DEFAULT 0,
    			`y` FLOAT NOT NULL DEFAULT 0,
    			`z` FLOAT NOT NULL DEFAULT 0,
    			`interior` INT NOT NULL DEFAULT 0,
    			`dimension` INT NOT NULL DEFAULT 0,
    			`rotation` FLOAT NOT NULL DEFAULT 0,
    			`placed` INT NOT NULL DEFAULT 0,
    			PRIMARY KEY (`id`)
    		)
    	]])
    	dbQuery(function(query)
            local query, query_lines = dbPoll(query, 0)
            if query_lines > 0 then
                Async:foreach(query, function(v)
				    local id = tonumber(v["id"])          
					local x 		= tonumber(v["x"])
					local y 		= tonumber(v["y"])
					local z 		= tonumber(v["z"])
					local rot 		= tonumber(v["rotation"])
					local interior  = tonumber(v["interior"])
					local dimension = tonumber(v["dimension"])
					local model 	= tonumber(v["model"])
					local owner 	= tonumber(v["owner"])
					local placed 	= tonumber(v["placed"])
					------------------------------------------
					cache[id] = {
						["id"] = id,
						["x"] = x,
						["y"] = y,
						["z"] = z,
						["rot"] = rot,
						["interior"] = interior,
						["dimension"] = dimension,
						["model"] = model,
						["placed"] = placed,
						["allData"] = v,
						["owner"] = owner,
 					}
 					
 					loadObjectWhereID(id)
					
 					
				end)   
				outputDebugString("[Success] Loading furnitures has finished successfuly. Loaded: " .. query_lines .. " furnitures!")

			end
		end, connection, "SELECT * FROM `furnitures`")  
	                 end 
)
--[[
addEventHandler("onPlayerInteriorChange", getRootElement( ),
	function( a, b, toDimension, toInterior)	
		if toDimension ~= 0 then
			setElementData(source,"oldint",toInterior)
			setElementData(source,"olddim",toDimension)
			Async:foreach(cache, function(v) 
				if v["interior"] == toInterior then
					if v["dimension"] == toDimension then
						triggerClientEvent(source,"createFurnObject",source,v)
						
					end
				end
		  end)
		else
			Async:foreach(cache, function(v) 
				if v["interior"] == getElementData(source,"oldint") then
					if v["dimension"] == getElementData(source,"olddim") then
						triggerClientEvent(source,"destroyFurnObject",source,v["interior"],v["dimension"])
					end
				end
			end)
		end
	end
)
addEventHandler("onPlayerSpawn", root, function()
		toInterior = getElementInterior(source)
		toDimension = getElementDimension(source)
		if toDimension ~= 0 then
			setElementData(source,"oldint",toInterior)
			setElementData(source,"olddim",toDimension)
			Async:foreach(cache, function(v) 
				if v["interior"] == toInterior then
					if v["dimension"] == toDimension then
						triggerClientEvent(source,"createFurnObject",source,v)
					end
				end
		    end)
		end
	end
)
]]--
function loadObjectWhereID(dbid)
	local data = cache[dbid]
	
	if data["placed"] == 1 then

		local obj = createObject(data["model"], data["x"],data["y"],data["z"], 0, 0, data["rot"])
		
		setElementData(obj, "Furnitures->isFurniture", true)
		setElementData(obj, "Furnitures->id", data["id"])
		setElementData(obj, "Furnitures->owner", data["owner"])
		setElementData(obj, "Furnitures->Hifi", {channel = 1, state = 0})
		setElementData(obj, "Furnitures->data", data["allData"])
		setElementDimension(obj, data["dimension"])
		setElementInterior(obj, data["interior"])
		setElementDoubleSided(obj, true)
		
	end
end

function Furnitures.loadMyFurnitures(dbid)
	if not dbid then return end
	local myFurnitures = {}
	--insertQuery = dbPoll(dbQuery(connection,"SELECT * FROM furnitures WHERE owner = " .. dbid .. " AND placed = 0"),-1)
	dbQuery(function(queryHandle, player)
		local result, rows, err = dbPoll(queryHandle, 0)
		if rows > 0 then
			for k, v in pairs(result) do                
				local id_ = tonumber(v["id"])
				local x_ 		= tonumber(v["x"])
				local y_ 		= tonumber(v["y"])
				local z_ 		= tonumber(v["z"])
				local rot_ 		= tonumber(v["rotation"])
				local interior_  = tonumber(v["interior"])
				local dimension_ = tonumber(v["dimension"])
				local model_ 	= tonumber(v["model"])
				local owner_ 	= tonumber(v["owner"])
				local placed_ 	= tonumber(v["placed"])
				------------------------------------------
				myFurnitures[#myFurnitures + 1] = {id = id_, x = x_, y = y_, z = z_, rot = rot_, interior = interior_, dimension = dimension_, model = model_, owner = owner_, placed = placed_}
			end         
		end
		-- Standalone düzeltmesi: sonuç boş olsa bile (rows == 0) client'a mutlaka
		-- gönder, yoksa panel "yükleniyor" durumunda takılı kalır.
		triggerClientEvent(player, "GetMyFurnitures", player, myFurnitures)

	end, {source}, connection, "SELECT * FROM furnitures WHERE owner = "..dbid.." AND placed = 0")
end
addEvent("Furnitures->loadMyFurnitures", true)
addEventHandler("Furnitures->loadMyFurnitures", root, Furnitures.loadMyFurnitures)

function Furnitures.attachFurniture(player, furniture, data)
	attachedFurnitures[player] = furniture
	
	--attachElements(attachedFurnitures[player], player, 0, 1)
	setElementData(player, "Furniture->isFurnitureOnHand", true)
	setElementCollisionsEnabled(attachedFurnitures[player], false)
end
addEvent("Furnitures->attachFurniture", true)
addEventHandler("Furnitures->attachFurniture", root, Furnitures.attachFurniture)

function Furnitures.setPosition(player,furniture,data)
	x,y,z,rot = unpack(data)
	setElementPosition(attachedFurnitures[player],x,y,z)
	--setElementRotation(attachedFurnitures[player],0,0,rot)
end
addEvent("Furnitures->setPos", true)
addEventHandler("Furnitures->setPos", root, Furnitures.setPosition)

function Furnitures.destroy(player, furniture)
	setElementData(player, "Furniture->isFurnitureOnHand", false)
	dbExec(connection, "UPDATE furnitures SET placed = ? WHERE id = ?", 0, getElementData(furniture, "Furnitures->id"))
	if isElement(furniture) then destroyElement(furniture) end
end
addEvent("Furnitures->destroyFurniture", true)
addEventHandler("Furnitures->destroyFurniture", root, Furnitures.destroy)

function Furnitures.drop(player, furniture, x,y,z,int,dim,rot)
	local id = getElementData(furniture, "Furnitures->id")

	attachedFurnitures[player] = nil
	detachElements(furniture, player)
	setElementPosition(furniture, x,y,z)
	setElementRotation(furniture, 0, 0, rot)
	setElementInterior(furniture,int)
	setElementDimension(furniture,dim)
	setElementCollisionsEnabled(furniture, true)

	dbExec(connection, "UPDATE furnitures SET `x`='" .. (x) .. "', `y`='" .. (y) .. "', `z`='" .. (z) .. "', `interior`='" .. (int) .. "', `dimension`='" .. (dim) .. "', `rotation`='" .. (rot) .. "', `placed`='1' WHERE `id`='" .. (id) .. "'")

end
addEvent("Furnitures->drop", true)
addEventHandler("Furnitures->drop", root, Furnitures.drop)

function Furnitures.insert(owner, model)
	--local insertInfo, _, insertID = dbPoll(dbQuery(connection, "INSERT INTO furnitures SET owner = ?, model = ?", owner, model), -1)
	dbQuery(connection, "INSERT INTO furnitures SET owner = ?, model = ?", owner, model)
end
addEvent("Furnitures->insert", true)
addEventHandler("Furnitures->insert", root, Furnitures.insert)

function Furnitures.delete(id)
	dbExec(connection, "DELETE FROM furnitures WHERE id = ?", id)
	--dbExec(mysql:getConnection(),"DELETE FROM furnitures WHERE id='" .. (id) .. "' LIMIT 1")
end
addEvent("Furnitures->delete", true)
addEventHandler("Furnitures->delete", root, Furnitures.delete)

function Furnitures.create(player, data)
	local rot = getPedRotation(player)
	local x, y, z = getElementPosition(player)
	dbExec(connection, "UPDATE furnitures SET x = ?, y = ?, z = ?, rotation = ?, placed = ?, interior = ?, dimension = ? WHERE id = ?", x, y, z, rot, 1, getElementInterior(player), getElementDimension(player), id)

	local interior  = getElementInterior(player)
	local dimension = getElementDimension(player)
	local model 	= tonumber(data.model)
	local owner 	= tonumber(data.owner)
	------------------------------------------
	local obj = createObject(model, x, y, z, 0, 0, rot)
	setElementData(obj, "Furnitures->isFurniture", true)
	setElementData(obj, "Furnitures->id", tonumber(data.id))
	setElementData(obj, "Furnitures->owner", owner)
	setElementData(obj, "Furnitures->data", data)
	setElementDimension(obj, dimension)
	setElementInterior(obj, interior)
	setElementDoubleSided(obj, true)
	
	setElementData(obj, "Furniture->used", true)
	setElementData(player, "Furniture->isFurnitureOnHand", true)
	
	Furnitures.attachFurniture(player, obj, data)
	triggerClientEvent(player, "Furnitures->receiveElement", player, obj)
end
addEvent("Furnitures->create", true)
addEventHandler("Furnitures->create", root, Furnitures.create)

-- dbid = mobilya sahipliği için kullanılan oyuncu kimliği.
-- Kendi login/hesap sisteminiz "dbid" element datasını zaten dolduruyorsa bu kısım devre dışı kalır.
-- Doldurmuyorsa MTA hesap ID'sini otomatik kullanır (standalone).
addEventHandler("onPlayerLogin", root, function(_, account)
	if not getElementData(source, "dbid") and account and not isGuestAccount(account) then
		setElementData(source, "dbid", getAccountID(account))
	end
end)

addEventHandler("onPlayerQuit", getRootElement(), function()
	local obj = attachedFurnitures[source]
	if obj then
		local data = getElementData(obj, "Furnitures->data") or {}
		setElementPosition(obj, data.x, data.y, data.z)
		setElementRotation(obj, data.rotation)
		
		setElementCollisionsEnabled(obj, true)
		setElementData(obj, "Furniture->used", false)
		attachedFurnitures[source] = nil
	end
end)
local hifiScale = {}
addEvent("Furnitures->playSound", true)
addEventHandler("Furnitures->playSound", root, function(_, data, object)
	setElementData(object,"dbid",data.id)
	hifiScale[data.id] = setTimer(function(object1,dbid)
		setObjectScale(object,getObjectScale(object)+0.07)
		setTimer(function()
			setObjectScale(object1,getObjectScale(object1)-0.07)
		end,150,1,object1)
	end, 3500,0,object,data.id)
	triggerClientEvent(getRootElement(), "Furnitures->playSoundC", getRootElement(), data,object)
end)	

addEvent("Furnitures->removeSound", true)
addEventHandler("Furnitures->removeSound", root, function(_, data, object)

	if isTimer(hifiScale[data.id]) then 
		killTimer(hifiScale[data.id])
	end
	triggerClientEvent(getRootElement(), "Furnitures->removeSoundC", getRootElement(), data,object)
end)