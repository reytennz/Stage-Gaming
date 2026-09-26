--[[
    stage_factions - server.lua
    goat_factions portu. Kimlik = MTA hesap adı (stage_core:GetAccountName).
    "characters" tablosu yerine kendi "faction_members" tablomuzu kullanıyoruz,
    çünkü stage paketinde çoklu karakter / characters tablosu yok.

    NOT: /abv, /abg (araç birliğe ekleme) ve araç respawn komutları kaldırıldı,
    çünkü stage_arac'ta henüz araç sahiplik/veritabanı sistemi yok. O sistem
    eklendiğinde kolayca geri eklenebilir (aşağıdaki 'ARAÇ ENTEGRASYONU' notuna bak).
]]

local faction_logs = {}

local function ensureTables()
	exports.stage_core:CoreDBExec([[CREATE TABLE IF NOT EXISTS factions (
		id INT PRIMARY KEY,
		name VARCHAR(32) NOT NULL,
		bankbalance INT NOT NULL DEFAULT 0,
		type INT NOT NULL DEFAULT 0,
		motd TEXT,
		note TEXT,
		fnote TEXT,
		max_interiors INT DEFAULT 0,
		level INT DEFAULT 1,
		xp INT DEFAULT 0,
		approval INT DEFAULT 0
	)]])

	-- rank_1..20 / wage_1..20 kolonlarını tek tek garanti altına al
	for i = 1, 20 do
		exports.stage_core:CoreDBExec("ALTER TABLE factions ADD COLUMN IF NOT EXISTS rank_" .. i .. " VARCHAR(32)")
		exports.stage_core:CoreDBExec("ALTER TABLE factions ADD COLUMN IF NOT EXISTS wage_" .. i .. " INT DEFAULT 0")
	end

	exports.stage_core:CoreDBExec([[CREATE TABLE IF NOT EXISTS faction_members (
		account_name VARCHAR(64) PRIMARY KEY,
		faction_id INT NOT NULL DEFAULT -1,
		faction_rank INT NOT NULL DEFAULT 1,
		faction_leader INT NOT NULL DEFAULT 0,
		duty INT NOT NULL DEFAULT 0
	)]])

	exports.stage_core:CoreDBExec([[CREATE TABLE IF NOT EXISTS faction_logs (
		id INT AUTO_INCREMENT PRIMARY KEY,
		date VARCHAR(64),
		admin VARCHAR(64),
		user VARCHAR(64),
		action TEXT,
		faction_id INT
	)]])
end

function addFactionLog(admin, user, action, factionID)
	if not (admin and user and action and factionID) then return end
	if not faction_logs[factionID] then faction_logs[factionID] = {} end

	local time = getRealTime()
	local formattedTime = monthNames[time.month] .. ' ' .. (time.monthday) .. ' - ' .. dayNames[time.weekday] .. ' ' .. string.format("%02d:%02d", time.hour, time.minute)
	exports.stage_core:CoreDBExec("INSERT INTO faction_logs (date, admin, user, action, faction_id) VALUES (?, ?, ?, ?, ?)", formattedTime, admin, user, action, factionID)
	table.insert(faction_logs[factionID], { admin = admin, user = user, action = action, faction_id = factionID, date = formattedTime })
end

-- Bir hesabın birlik üyeliği satırını garanti eder ve döner
local function ensureMemberRow(accountName)
	local rows = exports.stage_core:CoreDBQuery("SELECT * FROM faction_members WHERE account_name = ?", accountName)
	if rows and rows[1] then
		return rows[1]
	end
	exports.stage_core:CoreDBExec("INSERT INTO faction_members (account_name, faction_id, faction_rank, faction_leader, duty) VALUES (?, -1, 1, 0, 0)", accountName)
	return { account_name = accountName, faction_id = -1, faction_rank = 1, faction_leader = 0, duty = 0 }
end

local function loadFactionsFromDB()
	local rows = exports.stage_core:CoreDBQuery("SELECT * FROM factions ORDER BY id ASC")
	if not rows then return end

	local citteam = getTeamFromName('Sivil') or Team.create('Sivil', 255, 255, 255)

	for _, row in ipairs(rows) do
		local id = tonumber(row.id)
		local name = row.name
		local money = tonumber(row.bankbalance)
		local factionType = tonumber(row.type)
		local theTeam = getTeamFromName(tostring(name)) or Team.create(tostring(name))
		if theTeam then
			theTeam:setData('type', factionType)
			theTeam:setData('money', money)
			theTeam:setData('id', id)

			local factionRanks, factionWages = {}, {}
			for i = 1, 20 do
				factionRanks[i] = row['rank_' .. i]
				factionWages[i] = tonumber(row['wage_' .. i])
			end
			theTeam:setData('ranks', factionRanks)
			theTeam:setData('wages', factionWages)
			theTeam:setData('motd', row.motd)
			theTeam:setData('note', row.note == nil and "" or row.note)
			theTeam:setData('fnote', row.fnote == nil and "" or row.fnote)
			theTeam:setData('max_interiors', tonumber(row.max_interiors))
			theTeam:setData('level', tonumber(row.level))
			theTeam:setData('xp', tonumber(row.xp))
			theTeam:setData('approval', tonumber(row.approval))

			if not faction_logs[id] then faction_logs[id] = {} end
			local logRows = exports.stage_core:CoreDBQuery("SELECT * FROM faction_logs WHERE faction_id = ?", id)
			if logRows then faction_logs[id] = logRows end
		end
	end

	-- Oturumdaki oyuncuları doğru takıma ata
	for _, thePlayer in ipairs(getElementsByType('player')) do
		if exports.stage_core:IsLoggedIn(thePlayer) then
			local member = ensureMemberRow(exports.stage_core:GetAccountName(thePlayer))
			thePlayer.team = getTeamFromfactionID(member.faction_id) or citteam
			thePlayer:setData('faction', tonumber(member.faction_id))
			thePlayer:setData('factionrank', tonumber(member.faction_rank))
			thePlayer:setData('factionleader', tonumber(member.faction_leader))
		end
	end
end

addEventHandler('onResourceStart', resourceRoot, function()
	ensureTables()
	loadFactionsFromDB()
end)

-- Hesabına giriş yapan oyuncuyu doğru birliğe/takıma bağla
addEventHandler('onPlayerLogin', root, function()
	local thePlayer = source
	local accountName = exports.stage_core:GetAccountName(thePlayer)
	if not accountName then return end

	local member = ensureMemberRow(accountName)
	local citteam = getTeamFromName('Sivil') or Team.create('Sivil', 255, 255, 255)
	thePlayer.team = getTeamFromfactionID(member.faction_id) or citteam
	thePlayer:setData('faction', tonumber(member.faction_id))
	thePlayer:setData('factionrank', tonumber(member.faction_rank))
	thePlayer:setData('factionleader', tonumber(member.faction_leader))
end)

--[[ ARAÇ ENTEGRASYONU
	stage_arac'a gerçek bir araç sahiplik/veritabanı sistemi eklediğinde,
	burada 'faction -> respawn' / 'faction -> respawn -> all' event'lerini
	goat sürümündeki mantıkla (theVehicle:getData('faction'), :respawn()) geri
	ekleyebilirsin. O tablo/kolonlar bende yok, o yüzden çıkardım.
]]

addEvent('faction -> leave', true)
addEventHandler('faction -> leave', root, function()
	local thePlayer = source
	local accountName = exports.stage_core:GetAccountName(thePlayer)
	if not accountName then return end

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_id=-1, faction_leader=0, faction_rank=1, duty=0 WHERE account_name=?", accountName) then
		local playerTeam = thePlayer.team
		local factionID = tonumber(thePlayer:getData('faction')) or -1
		if playerTeam then
			for _, value in ipairs(playerTeam.players) do
				outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli üye birlikten ayrıldı.', value, 0, 0, 255, true)
			end
		end
		thePlayer.team = getTeamFromName('Sivil')
		thePlayer:setData('faction', -1)
		thePlayer:setData('factionrank', 1)
		thePlayer:setData('factionleader', 0)
		addFactionLog(accountName, accountName, 'Birlikten ayrıldı.', factionID)
	end
end)

addEvent('faction -> receive', true)
addEventHandler('faction -> receive', root, function()
	local thePlayer = source
	local factionID = tonumber(thePlayer:getData('faction')) or -1

	local members = exports.stage_core:CoreDBQuery("SELECT * FROM faction_members WHERE faction_id = ?", factionID) or {}
	triggerClientEvent(thePlayer, 'faction -> loadClient', thePlayer, members)

	-- Araç listesi: faction_vehicles tablon yoksa boş döner (aşağıdaki not'a bak)
	triggerClientEvent(thePlayer, 'faction -> loadClient', thePlayer, nil, {})
	triggerClientEvent(thePlayer, 'faction -> loadClient', thePlayer, nil, nil, faction_logs[factionID])
end)

addEvent('faction -> leaderboard', true)
addEventHandler('faction -> leaderboard', root, function()
	local thePlayer = source
	local rows = exports.stage_core:CoreDBQuery("SELECT name, bankbalance FROM factions ORDER BY bankbalance DESC LIMIT 50") or {}
	triggerClientEvent(thePlayer, 'faction -> loadLeaderboard', thePlayer, rows)
end)

addEvent('faction -> kick', true)
addEventHandler('faction -> kick', root, function(targetAccountName)
	local thePlayer = source
	if not targetAccountName then return end

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_id=-1, faction_leader=0, faction_rank=1, duty=0 WHERE account_name=?", targetAccountName) then
		for _, p in ipairs(getElementsByType('player')) do
			if exports.stage_core:GetAccountName(p) == targetAccountName then
				p.team = getTeamFromName('Sivil')
				p:setData('faction', -1)
				p:setData('factionleader', 0)
				outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli lider sizi birlikten uzaklaştırdı!', p, 0, 0, 255, true)
				break
			end
		end
		local playerTeam = thePlayer.team
		local factionID = tonumber(thePlayer:getData('faction')) or -1
		if playerTeam then
			for _, value in ipairs(playerTeam.players) do
				outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli lider ' .. targetAccountName .. ' isimli üyeyi birlikten uzaklaştırdı!', value, 0, 0, 255, true)
			end
		end
		addFactionLog(exports.stage_core:GetAccountName(thePlayer), targetAccountName, 'Birlikten uzaklaştırıldı.', factionID)
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 0, 0, 255, true)
	end
end)

addEvent('faction -> setLeader', true)
addEventHandler('faction -> setLeader', root, function(targetAccountName)
	local thePlayer = source
	if not targetAccountName then return end

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_leader=1 WHERE account_name=?", targetAccountName) then
		for _, p in ipairs(getElementsByType('player')) do
			if exports.stage_core:GetAccountName(p) == targetAccountName then
				p:setData('factionleader', 1)
				outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli lider sizi lider olarak atadı!', p, 0, 255, 0, true)
				break
			end
		end
		local playerTeam = thePlayer.team
		local factionID = tonumber(thePlayer:getData('faction')) or -1
		if playerTeam then
			for _, value in ipairs(playerTeam.players) do
				outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli lider ' .. targetAccountName .. ' isimli üyeyi lider olarak atadı!', value, 0, 0, 255, true)
			end
		end
		addFactionLog(exports.stage_core:GetAccountName(thePlayer), targetAccountName, 'Liderlik verildi.', factionID)
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 0, 0, 255, true)
	end
end)

addEvent('faction -> rank -> user', true)
addEventHandler('faction -> rank -> user', root, function(targetAccountName, num)
	local thePlayer = source
	if not (targetAccountName and num) then return end
	num = tonumber(num)

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_rank=? WHERE account_name=?", num, targetAccountName) then
		local playerTeam = thePlayer.team
		local factionID = tonumber(thePlayer:getData('faction')) or -1
		exports.stage_core:Notify(thePlayer, "Başarıyla " .. targetAccountName .. " adlı kişinin rütbesini düzenlediniz.", "success")
		for _, p in ipairs(getElementsByType('player')) do
			if exports.stage_core:GetAccountName(p) == targetAccountName then
				p:setData('factionrank', num)
			end
		end
		if playerTeam then
			for _, value in ipairs(playerTeam.players) do
				outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli lider ' .. targetAccountName .. ' isimli üyenin rütbesini düzenledi!', value, 0, 0, 255, true)
			end
		end
		addFactionLog(exports.stage_core:GetAccountName(thePlayer), targetAccountName, 'Rütbesini değiştirdi.', factionID)
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 0, 0, 255, true)
	end
end)

addEvent('faction -> edit -> rank', true)
addEventHandler('faction -> edit -> rank', root, function(ranks, wages, factionID)
	local thePlayer = source
	if not (ranks and wages) then return end

	local playerTeam = thePlayer.team
	local sets, params = {}, {}
	for index, value in ipairs(ranks) do
		table.insert(sets, "rank_" .. index .. "=?")
		table.insert(params, tostring(value))
	end
	for index, value in ipairs(wages) do
		table.insert(sets, "wage_" .. index .. "=?")
		table.insert(params, tonumber(value) or 0)
	end
	table.insert(params, factionID)
	exports.stage_core:CoreDBExec("UPDATE factions SET " .. table.concat(sets, ", ") .. " WHERE id=?", unpack(params))
	if playerTeam then
		playerTeam:setData('ranks', ranks)
		playerTeam:setData('wages', wages)
	end
	addFactionLog(exports.stage_core:GetAccountName(thePlayer), exports.stage_core:GetAccountName(thePlayer), 'Rütbe isimlerini ve maaşlarını güncelledi.', factionID)
end)

addEvent('faction -> edit -> note', true)
addEventHandler('faction -> edit -> note', root, function(note, factionID)
	local thePlayer = source
	if not (note and factionID) then return end

	local playerTeam = thePlayer.team
	exports.stage_core:CoreDBExec("UPDATE factions SET note=? WHERE id=?", note, factionID)
	if playerTeam then
		playerTeam:setData('note', note)
		for _, value in ipairs(playerTeam.players) do
			outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli lider birlik notunu güncelledi.', value, 0, 0, 255, true)
		end
	end
	addFactionLog(exports.stage_core:GetAccountName(thePlayer), exports.stage_core:GetAccountName(thePlayer), 'Birlik notunu güncelledi.', factionID)
end)

addEvent('faction -> invite', true)
addEventHandler('faction -> invite', root, function(status, factionID, members, vehicles, player)
	local thePlayer = source
	if status == 'send' then
		if factionID and members and player then
			player:setData('faction -> invite', { factionID = factionID, inviter = thePlayer })
			outputChatBox('>>#F9F9F9 Birlik daveti başarıyla gönderildi.', thePlayer, 0, 255, 0, true)
			outputChatBox('>>#F9F9F9 ' .. (thePlayer.name:gsub('_', ' ')) .. ', seni bir birliğe davet etti.', player, 0, 255, 0, true)
			triggerClientEvent(player, 'faction -> openInvite', player, { members = members, vehicles = vehicles, player = thePlayer, id = factionID, lastClick = 0 })
		end
	elseif status == 'accept' then
		local inviteData = thePlayer:getData('faction -> invite') or {}
		if inviteData.factionID then
			local theTeam = getTeamFromfactionID(inviteData.factionID)
			local accountName = exports.stage_core:GetAccountName(thePlayer)
			if theTeam and accountName then
				exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_leader=0, faction_id=?, faction_rank=1, duty=0 WHERE account_name=?", inviteData.factionID, accountName)
				thePlayer.team = theTeam
				thePlayer:setData('faction', inviteData.factionID)
				thePlayer:setData('factionrank', 1)
				thePlayer:setData('factionleader', 0)
				addFactionLog(exports.stage_core:GetAccountName(inviteData.inviter), accountName, 'Birliğe davet edildi.', inviteData.factionID)
				for _, value in ipairs(theTeam.players) do
					outputChatBox('>> Birlik#F9F9F9 ' .. thePlayer.name .. ' isimli birliğe katıldı.', value, 0, 0, 255, true)
				end
				outputChatBox('>>#F9F9F9 ' .. thePlayer.name:gsub('_', ' ') .. ', birlik davetini kabul etti.', inviteData.inviter, 0, 255, 0, true)
				outputChatBox('>>#F9F9F9 Birlik davetini kabul ettiniz.', thePlayer, 0, 255, 0, true)
				thePlayer:removeData('faction -> invite')
			else
				outputChatBox('>>#F9F9F9 Bir hata meydana geldi, geliştiriciye iletin.', thePlayer, 255, 0, 0, true)
			end
		end
	elseif status == 'decline' then
		local inviteData = thePlayer:getData('faction -> invite') or {}
		if inviteData.factionID then
			outputChatBox('>>#F9F9F9 ' .. thePlayer.name:gsub('_', ' ') .. ', birlik davetini reddeti.', inviteData.inviter, 255, 0, 0, true)
			outputChatBox('>>#F9F9F9 Birlik davetini reddetiniz.', thePlayer, 255, 0, 0, true)
			thePlayer:removeData('faction -> invite')
		end
	end
end)

function giveFactionXP(factionID, xp)
	if not (factionID and xp) then return end
	local faction = getTeamFromfactionID(factionID)
	if not faction then return end

	local factionXP = getElementData(faction, 'xp') or 100
	local level = getElementData(faction, 'level') or 1
	setElementData(faction, 'xp', xp + factionXP)
	if (factionXP + xp) >= ((level + 1) ^ 2 * 100) then
		setElementData(faction, 'level', level + 1)
		for _, value in ipairs(faction.players) do
			outputChatBox('>> Birlik#F9F9F9 Birliğiniz seviye atladı, yeni seviyesi: ' .. (level + 1), value, 0, 110, 255, true)
		end
	end
	exports.stage_core:CoreDBExec("UPDATE factions SET level=?, xp=? WHERE id=?", getElementData(faction, 'level'), getElementData(faction, 'xp'), factionID)
end

function givePlayerFactionXP(player, xp)
	if not (isElement(player) and xp) then return end
	local faction = tonumber(getElementData(player, 'faction')) or 0
	if faction > 0 then
		giveFactionXP(faction, xp)
		outputChatBox('>>#FFFFFF Birliğiniz sayenizde ' .. xp .. ' kazandı!', player, 0, 255, 0, true)
	end
end
