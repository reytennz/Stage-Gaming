--[[
    stage_factions - commands.lua
    goat_factions portu. /abv ve /abg (araç -> birlik) komutları kaldırıldı,
    çünkü stage_arac'ta araç sahiplik veritabanı yok. kurulumUcreti artık shared.lua'da.
]]

addCommandHandler('setfaction', function(thePlayer, commandName, partialNick, factionID)
	if not exports.stage_core:IsAdmin(thePlayer) then return end
	factionID = tonumber(factionID)
	if not (partialNick and factionID) then
		outputChatBox('>>#F9F9F9 /' .. commandName .. ' [Hesap adı] [faction ID]', thePlayer, 195, 184, 116, true)
		return
	end

	local targetPlayer
	for _, p in ipairs(getElementsByType('player')) do
		if p.name:lower():find(partialNick:lower(), 1, true) then
			targetPlayer = p
			break
		end
	end
	if not targetPlayer then
		outputChatBox('>>#F9F9F9 Oyuncu bulunamadı!', thePlayer, 195, 184, 116, true)
		return
	end

	local theTeam = getTeamFromfactionID(factionID)
	if not theTeam and factionID ~= -1 then
		outputChatBox('>>#F9F9F9 Hatalı faction ID!', thePlayer, 195, 184, 116, true)
		return
	end

	local accountName = exports.stage_core:GetAccountName(targetPlayer)
	if not accountName then
		outputChatBox('>>#F9F9F9 Hedef oyuncu hesabına giriş yapmamış!', thePlayer, 195, 184, 116, true)
		return
	end

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_leader=0, faction_id=?, faction_rank=1, duty=0 WHERE account_name=?", factionID, accountName) then
		if factionID > 0 then
			targetPlayer.team = theTeam
			targetPlayer:setData('faction', factionID)
			targetPlayer:setData('factionrank', 1)
			targetPlayer:setData('factionleader', 0)
			outputChatBox('>>#F9F9F9 Başarıyla ' .. targetPlayer.name .. ' isimli oyuncuyu ' .. factionID .. ' ID birliğe atadınız!', thePlayer, 195, 184, 116, true)
			outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli yetkili sizi ' .. factionID .. ' ID birliğe atadı!', targetPlayer, 195, 184, 116, true)
		else
			targetPlayer.team = getTeamFromName('Sivil')
			targetPlayer:setData('faction', -1)
			targetPlayer:setData('factionrank', 1)
			targetPlayer:setData('factionleader', 0)
			outputChatBox('>>#F9F9F9 Başarıyla ' .. targetPlayer.name .. ' isimli oyuncuyu birliğinden çıkardınız!', thePlayer, 195, 184, 116, true)
			outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli yetkili sizi birliğinizden çıkardı!', targetPlayer, 195, 184, 116, true)
		end
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 195, 184, 116, true)
	end
end)

addCommandHandler('setfactionleader', function(thePlayer, commandName, partialNick, factionID)
	if not exports.stage_core:IsAdmin(thePlayer) then return end
	factionID = tonumber(factionID)
	if not (partialNick and factionID) then
		outputChatBox('>>#F9F9F9 /' .. commandName .. ' [Hesap adı] [faction ID]', thePlayer, 195, 184, 116, true)
		return
	end

	local targetPlayer
	for _, p in ipairs(getElementsByType('player')) do
		if p.name:lower():find(partialNick:lower(), 1, true) then
			targetPlayer = p
			break
		end
	end
	if not targetPlayer then
		outputChatBox('>>#F9F9F9 Oyuncu bulunamadı!', thePlayer, 195, 184, 116, true)
		return
	end

	local theTeam = getTeamFromfactionID(factionID)
	if not theTeam and factionID ~= -1 then
		outputChatBox('>>#F9F9F9 Hatalı faction ID!', thePlayer, 195, 184, 116, true)
		return
	end

	local accountName = exports.stage_core:GetAccountName(targetPlayer)
	if not accountName then
		outputChatBox('>>#F9F9F9 Hedef oyuncu hesabına giriş yapmamış!', thePlayer, 195, 184, 116, true)
		return
	end

	if exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_leader=1, faction_id=?, faction_rank=1, duty=0 WHERE account_name=?", factionID, accountName) then
		if factionID > 0 then
			targetPlayer.team = theTeam
			targetPlayer:setData('faction', factionID)
			targetPlayer:setData('factionrank', 1)
			targetPlayer:setData('factionleader', 1)
			outputChatBox('>>#F9F9F9 Başarıyla ' .. targetPlayer.name .. ' isimli oyuncuyu ' .. factionID .. ' ID birliğe lider atadınız!', thePlayer, 195, 184, 116, true)
			outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli yetkili sizi ' .. factionID .. ' ID birliğe lider atadı!', targetPlayer, 195, 184, 116, true)
		else
			targetPlayer.team = getTeamFromName('Sivil')
			targetPlayer:setData('faction', -1)
			targetPlayer:setData('factionrank', 1)
			targetPlayer:setData('factionleader', 0)
			outputChatBox('>>#F9F9F9 Başarıyla ' .. targetPlayer.name .. ' isimli oyuncuyu birliğinden çıkardınız!', thePlayer, 195, 184, 116, true)
			outputChatBox('>>#F9F9F9 ' .. thePlayer.name .. ' isimli yetkili sizi birliğinizden çıkardı!', targetPlayer, 195, 184, 116, true)
		end
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 195, 184, 116, true)
	end
end)

addCommandHandler('birlikonayla', function(thePlayer, commandName, factionID)
	if not exports.stage_core:IsAdmin(thePlayer) then return end
	factionID = tonumber(factionID)
	if not factionID then
		outputChatBox('>>#F9F9F9 /' .. commandName .. ' [Birlik ID]', thePlayer, 195, 184, 116, true)
		return
	end

	local theTeam = getTeamFromfactionID(factionID)
	if not theTeam then
		outputChatBox('>>#F9F9F9 Hatalı faction ID!', thePlayer, 195, 184, 116, true)
		return
	end

	if getElementData(theTeam, 'approval') == 1 then
		exports.stage_core:CoreDBExec("UPDATE factions SET approval=0 WHERE id=?", factionID)
		theTeam:setData('approval', 0)
		for _, value in ipairs(theTeam.players) do
			outputChatBox('Birlik:#D0D0D0 ' .. thePlayer.name .. ' isimli yetkili birliğinizin onayını aldı!', value, 195, 184, 116, true)
		end
	else
		exports.stage_core:CoreDBExec("UPDATE factions SET approval=1 WHERE id=?", factionID)
		theTeam:setData('approval', 1)
		for _, value in ipairs(theTeam.players) do
			outputChatBox('Birlik:#D0D0D0 ' .. thePlayer.name .. ' isimli yetkili birliğinizi onayladı!', value, 195, 184, 116, true)
		end
	end
end)

function adminShowFactions(thePlayer)
	if not exports.stage_core:IsAdmin(thePlayer) then return end
	local rows = exports.stage_core:CoreDBQuery("SELECT id, name, type, (SELECT COUNT(*) FROM faction_members m WHERE m.faction_id = f.id) AS members FROM factions f ORDER BY id ASC")
	if not rows then return end

	local factions = {}
	for _, row in ipairs(rows) do
		local theTeam = getTeamFromName(row.name)
		local online = theTeam and #getPlayersInTeam(theTeam) or "?"
		table.insert(factions, { row.id, row.name, row.type, online .. " / " .. row.members })
	end
	triggerClientEvent(thePlayer, "showFactionList", getRootElement(), factions)
end
addCommandHandler("showfactions", adminShowFactions, false, false)

addCommandHandler("birliksiralama", function(thePlayer)
	local rows = exports.stage_core:CoreDBQuery("SELECT name, bankbalance FROM factions ORDER BY bankbalance DESC LIMIT 50") or {}
	triggerClientEvent(thePlayer, "faction -> showLeaderboardWindow", thePlayer, rows)
end)

addCommandHandler('renamefaction', function(thePlayer, commandName, ...)
	if thePlayer:getData('factionleader') ~= 1 then return end
	if not (...) then
		outputChatBox('>>#F9F9F9 /' .. commandName .. ' [Yeni İsim]', thePlayer, 195, 184, 116, true)
		return
	end
	if string.len(...) > 16 then
		outputChatBox('>>#F9F9F9 Birlik adı çok uzun olmamalı!', thePlayer, 195, 184, 116, true)
		return
	end

	local theTeam = thePlayer.team
	local factionID = tonumber(thePlayer:getData('faction')) or 0
	if not theTeam then return end

	local newName = table.concat({...}, " ")
	if exports.stage_core:CoreDBExec("UPDATE factions SET name=? WHERE id=?", newName, factionID) then
		for _, value in ipairs(theTeam.players) do
			outputChatBox('Birlik:#D0D0D0 ' .. thePlayer.name .. ' isimli lider birliğin ismini değiştirdi!', value, 195, 184, 116, true)
		end
		theTeam.name = newName
	else
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 195, 184, 116, true)
	end
end)

local function nextFreeFactionID()
	local rows = exports.stage_core:CoreDBQuery("SELECT id FROM factions ORDER BY id ASC")
	local used = {}
	if rows then
		for _, row in ipairs(rows) do used[tonumber(row.id)] = true end
	end
	local id = 1
	while used[id] do id = id + 1 end
	return id
end

local function createFactionForPlayer(thePlayer, name)
	if not exports.stage_core:IsLoggedIn(thePlayer) then return end
	if not name or name == '' then
		outputChatBox('>>#F9F9F9 Birlik adı boş olamaz!', thePlayer, 195, 184, 116, true)
		return
	end

	local playerFact = tonumber(thePlayer:getData('faction')) or -1
	if playerFact > 0 then
		outputChatBox('>>#F9F9F9 Birlik oluşturmak için var olan birliğinizden çıkmalısınız!', thePlayer, 195, 184, 116, true)
		return
	end

	if not exports.stage_core:HasMoney(thePlayer, kurulumUcreti) then
		outputChatBox("[!] Birlik kurabilmek için üzerinizde " .. exports.stage_core:formatMoney(kurulumUcreti) .. " TL olmalı.", thePlayer, 255, 0, 0)
		return
	end

	if string.len(name) > 16 then
		outputChatBox('>>#F9F9F9 Birlik adı çok uzun olmamalı!', thePlayer, 195, 184, 116, true)
		return
	end

	if getTeamFromName(name) then
		outputChatBox('>>#F9F9F9 Birlik adı kullanılıyor!', thePlayer, 195, 184, 116, true)
		return
	end

	local id = nextFreeFactionID()
	local theTeam = Team.create(tostring(name))
	if not theTeam then
		outputChatBox('>>#F9F9F9 Bir hata meydana geldi!', thePlayer, 195, 184, 116, true)
		return
	end

	local rankDefaults, params = {}, { id, name }
	local placeholders = {}
	for i = 1, 20 do
		table.insert(placeholders, "?")
		table.insert(params, "Rank #" .. i)
	end

	exports.stage_core:CoreDBExec("INSERT INTO factions (id, name, bankbalance, type, motd, note) VALUES (?, ?, 0, 0, 'Birliğe hoş geldiniz.', '')", id, name)
	exports.stage_core:CoreDBExec(
		"UPDATE factions SET rank_1=?, rank_2=?, rank_3=?, rank_4=?, rank_5=?, rank_6=?, rank_7=?, rank_8=?, rank_9=?, rank_10=?, rank_11=?, rank_12=?, rank_13=?, rank_14=?, rank_15=?, rank_16=?, rank_17=?, rank_18=?, rank_19=?, rank_20=? WHERE id=?",
		"Rank #1", "Rank #2", "Rank #3", "Rank #4", "Rank #5", "Rank #6", "Rank #7", "Rank #8", "Rank #9", "Rank #10",
		"Rank #11", "Rank #12", "Rank #13", "Rank #14", "Rank #15", "Rank #16", "Rank #17", "Rank #18", "Rank #19", "Rank #20", id
	)

	local accountName = exports.stage_core:GetAccountName(thePlayer)
	exports.stage_core:CoreDBExec("UPDATE faction_members SET faction_leader=1, faction_id=?, faction_rank=1, duty=0 WHERE account_name=?", id, accountName)

	theTeam:setData('type', 0)
	theTeam:setData('money', 0)
	theTeam:setData('id', id)
	local factionRanks = {}
	for i = 1, 20 do factionRanks[i] = "Rank #" .. i end
	theTeam:setData('ranks', factionRanks)
	theTeam:setData('wages', {})
	theTeam:setData('motd', 'Birliğe hoş geldiniz.')
	theTeam:setData('note', '')
	theTeam:setData('fnote', '')
	theTeam:setData('level', 1)
	theTeam:setData('xp', 0)
	theTeam:setData('approval', 0)

	thePlayer.team = theTeam
	thePlayer:setData('faction', id)
	thePlayer:setData('factionrank', 1)
	thePlayer:setData('factionleader', 1)
	exports.stage_core:RemoveMoney(thePlayer, kurulumUcreti, "Birlik kurulumu")
	outputChatBox('>>#F9F9F9 Birliğiniz başarıyla kuruldu, detaylar için F3', thePlayer, 195, 184, 116, true)
end

addCommandHandler('birlikkur', function(thePlayer, commandName, ...)
	if ... then
		-- Eski kullanım (chat'ten direkt isimle): hâlâ çalışsın, geriye dönük uyumluluk
		createFactionForPlayer(thePlayer, table.concat({...}, " "))
	else
		triggerClientEvent(thePlayer, 'faction -> openCreateWindow', thePlayer)
	end
end)

addEvent('faction -> create', true)
addEventHandler('faction -> create', root, function(name)
	createFactionForPlayer(source, name)
end)

local togState = {}
function toggleFaction(thePlayer, commandName)
	local pF = getElementData(thePlayer, "faction")
	local fL = getElementData(thePlayer, "factionleader")
	local theTeam = getPlayerTeam(thePlayer)

	if fL ~= 1 then return end

	if togState[pF] == false or not togState[pF] then
		togState[pF] = true
		outputChatBox(">>#F9F9F9 Birlik sohbetini devre dışı bıraktın.", thePlayer, 255, 0, 0, true)
		for _, arrayPlayer in ipairs(getElementsByType("player")) do
			if getPlayerTeam(arrayPlayer) == theTeam and exports.stage_core:IsLoggedIn(arrayPlayer) then
				outputChatBox(">>#F9F9F9 " .. getPlayerName(thePlayer):gsub('_', ' ') .. ' isimli lider birlik sohbetini kapattı.', arrayPlayer, 255, 0, 0, true)
			end
		end
	else
		togState[pF] = false
		outputChatBox(">>#F9F9F9 Birlik sohbetini aktif hale getirdin.", thePlayer, 0, 255, 0, true)
		for _, arrayPlayer in ipairs(getElementsByType("player")) do
			if getPlayerTeam(arrayPlayer) == theTeam and exports.stage_core:IsLoggedIn(arrayPlayer) then
				outputChatBox(">>#F9F9F9 " .. getPlayerName(thePlayer):gsub('_', ' ') .. ' isimli lider birlik sohbetini aktif hale getirdi.', arrayPlayer, 0, 255, 0, true)
			end
		end
	end
end
addCommandHandler("togglef", toggleFaction)
addCommandHandler("togf", toggleFaction)
addCommandHandler("birliksohbet", toggleFaction)

function toggleFactionSelf(thePlayer, commandName)
	if not exports.stage_core:IsLoggedIn(thePlayer) then return end
	local factionBlocked = getElementData(thePlayer, "chat:blockF")

	if factionBlocked == 1 then
		setElementData(thePlayer, "chat:blockF", 0)
		outputChatBox(">>#F9F9F9 Birlik sohbetini görünür hale getirdin.", thePlayer, 255, 0, 0, true)
	else
		setElementData(thePlayer, "chat:blockF", 1)
		outputChatBox(">>#F9F9F9 Birlik sohbetini sessize aldın.", thePlayer, 0, 255, 0, true)
	end
end
addCommandHandler("togglefactionchat", toggleFactionSelf)
addCommandHandler("togglefaction", toggleFactionSelf)
addCommandHandler("togfaction", toggleFactionSelf)
addCommandHandler("birliksustur", toggleFactionSelf)

function factionOOC(thePlayer, commandName, ...)
	if not exports.stage_core:IsLoggedIn(thePlayer) then return end
	local factionRank = tonumber(getElementData(thePlayer, "factionrank"))

	if not (...) then
		outputChatBox(">>#F9F9F9 /" .. commandName .. " [Mesaj]", thePlayer, 255, 194, 14)
		return
	end

	local theTeam = getPlayerTeam(thePlayer)
	local theTeamName = theTeam and getTeamName(theTeam)
	local playerName = getPlayerName(thePlayer)
	local playerFaction = getElementData(thePlayer, "faction")
	local factionRanks = (theTeam and getElementData(theTeam, "ranks")) or {}
	local factionRankTitle = factionRanks[factionRank] or ""

	if not theTeam or theTeamName == "Sivil" then
		outputChatBox(">>#F9F9F9 Bir birlikte bulunmuyorsun.", thePlayer, 255, 0, 0, true)
		return
	end

	local message = table.concat({...}, " ")
	if togState[playerFaction] == true then return end

	for _, arrayPlayer in ipairs(getElementsByType("player")) do
		if getElementData(arrayPlayer, "bigearsfaction") == theTeam then
			outputChatBox("((" .. theTeamName .. ")) " .. playerName .. ": " .. message, arrayPlayer, 3, 157, 157)
		elseif getPlayerTeam(arrayPlayer) == theTeam and exports.stage_core:IsLoggedIn(arrayPlayer) and getElementData(arrayPlayer, "chat:blockF") ~= 1 then
			outputChatBox(">> #F9F9F9[Birlik] - [" .. factionRankTitle .. "] - " .. playerName .. ": " .. message, arrayPlayer, 3, 237, 237, true)
		end
	end
end
addCommandHandler("f", factionOOC, false, false)
addCommandHandler("birlik", factionOOC, false, false)

function factionLeaderOOC(thePlayer, commandName, ...)
	if not exports.stage_core:IsLoggedIn(thePlayer) then return end

	if not (...) then
		outputChatBox(">>#F9F9F9 /" .. commandName .. " [Mesaj]", thePlayer, 255, 194, 14, true)
		return
	end

	local theTeam = getPlayerTeam(thePlayer)
	local theTeamName = theTeam and getTeamName(theTeam)
	local playerName = getPlayerName(thePlayer)
	local playerLeader = getElementData(thePlayer, "factionleader")
	local playerFaction = getElementData(thePlayer, "faction")
	local factionRanks = (theTeam and getElementData(theTeam, "ranks")) or {}
	local factionRank = tonumber(getElementData(thePlayer, "factionrank"))
	local factionRankTitle = factionRanks[factionRank] or ""

	if not theTeam or theTeamName == "Sivil" then
		outputChatBox(">>#F9F9F9 Bir birlikte bulunmuyorsun.", thePlayer, 255, 0, 0, true)
		return
	elseif tonumber(playerLeader) ~= 1 then
		outputChatBox(">>#F9F9F9 Birlik lideri değilsin.", thePlayer, 255, 0, 0, true)
		return
	end

	local message = table.concat({...}, " ")
	if togState[playerFaction] == true then return end

	for _, arrayPlayer in ipairs(getElementsByType("player")) do
		if getElementData(arrayPlayer, "bigearsfaction") == theTeam then
			outputChatBox("((" .. theTeamName .. " Lider )) " .. playerName .. ": " .. message, arrayPlayer, 3, 157, 157)
		elseif getPlayerTeam(arrayPlayer) == theTeam and exports.stage_core:IsLoggedIn(arrayPlayer) and getElementData(arrayPlayer, "chat:blockF") ~= 1 and getElementData(arrayPlayer, "factionleader") == 1 then
			outputChatBox(">> #F9F9F9[Birlik lideri] - [" .. factionRankTitle .. "] - " .. playerName .. ": " .. message, arrayPlayer, 237, 3, 3, true)
		end
	end
end
addCommandHandler("fl", factionLeaderOOC, false, false)
addCommandHandler("birliklideri", factionLeaderOOC, false, false)
