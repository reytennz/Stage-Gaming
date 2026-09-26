local screenX, screenY = guiGetScreenSize()
local w, h = 800, 470
local x, y = screenX/2-w/2, screenY/2-h/2
local faction = {}
local robotoB = dxCreateFont('files/fonts/default-bold.ttf', 15) or 'default-bold' -- TODO: kendi .ttf dosyanı files/fonts/ altına koy
local robotoB12 = dxCreateFont('files/fonts/default-bold.ttf', 12) or 'default-bold'
local robotoL = dxCreateFont('files/fonts/default.ttf', 10) or 'default'
local robotoL8 = dxCreateFont('files/fonts/default.ttf', 8) or 'default'
local roboto = dxCreateFont('files/fonts/default.ttf', 8) or 'default'
local roboto2 = dxCreateFont('files/fonts/default.ttf', 11) or 'default'
-- UYARI: FontAwesome ikon fontu dahil değildi, bu yüzden default'a düşürüldü.
-- İkon karakterleri (\u{f0..}) düzgün görünmeyecek; kendi files/fonts/fontawesome.ttf dosyanı ekleyip yolu değiştir.
local fontAwesome = dxCreateFont('files/fonts/fontawesome.ttf', 13) or 'default'
local fontAwesome11 = dxCreateFont('files/fonts/fontawesome.ttf', 11) or 'default'
local fontAwesome14 = dxCreateFont('files/fonts/fontawesome.ttf', 50) or 'default'

local fontAwesome15 = dxCreateFont('files/fonts/fontawesome.ttf', 20) or 'default'
local factionLogo = dxCreateTexture('components/logo.png')
local factionPages = {
    {'Genel', ''},
    {'Üyeler', ''},
    {'Kayıtlar', ''},
    {'Araçlar', ''},
    -- {'Finans', ''},
    {'Rütbeler', ''},
    {'Sıralama', ''},
}
local leaderboardRow = 0
local leaderboardMax = 8

local reloadData = {
	factions = {
		['note'] = 'note',
		['ranks'] = 'ranks',
		['wages'] = 'wages',
	},

	player = {
		['factionleader'] = 'isLeader',
	},
}


function openFactionUI()
    if faction.enabled then
        removeEventHandler('onClientRender', root, renderFactionUI)
		showChat(true)
    else
	    showChat(false)
        local playerTeam = localPlayer.team
        faction = {}
        faction.page = 1
        faction.note = playerTeam:getData('note') or ""
        faction.name = playerTeam.name or "Sivil"
        faction.maxUserRow = 8
        faction.maxUserRank = 6
        faction.maxLogRow = 11
        faction.maxVehRow = 9
        faction.maxUserRankEdit = 8
        faction.userRow = 0
        faction.userRank = 0
        faction.logRow = 0
        faction.money = playerTeam:getData('money') or 0
        faction.vehRow = 0
        faction.userRankEdit = 0
        faction.isLeader = localPlayer:getData('factionleader') or 0
        faction.vehicles = {}
        faction.logs = {}
        faction.ranks = playerTeam:getData('ranks') or {}
        faction.id = playerTeam:getData('id') or -1
        faction.wages = playerTeam:getData('wages') or {}
        faction.level = playerTeam:getData('level') or 1
        faction.xp = playerTeam:getData('xp') or 1
        faction.leaderboard = {}
        leaderboardRow = 0
        triggerServerEvent('faction -> receive', localPlayer)
        triggerServerEvent('faction -> leaderboard', localPlayer)
        addEventHandler('onClientRender', root, renderFactionUI)
    end
    faction.lastClick = 0
    faction.enabled = not faction.enabled
end
bindKey( "F3", "down", openFactionUI) 

function loadFactionData(members, vehicles, logs)
    if members then
       faction.members = members
       table.sort(faction.members, function(a, b) return a.faction_rank > b.faction_rank end)
       table.sort(faction.members, function(a, b) return a.faction_leader > b.faction_leader end)
    end 
    if vehicles then
        faction.vehicles = vehicles
    end
    if logs then
        faction.logs = logs
        table.sort(faction.logs, function(a, b) return a.id > b.id end)
    end
end
addEvent('faction -> loadClient', true)
addEventHandler('faction -> loadClient', root, loadFactionData)

addEvent('faction -> loadLeaderboard', true)
addEventHandler('faction -> loadLeaderboard', root, function(rows)
    faction.leaderboard = rows or {}
end)

function renderFactionUI()
    local playerTeam = localPlayer.team
    local playerTeamName = faction.name
    local teamRanks = faction.ranks
    roundedRectangle('faction-main-ui', x, y, w, h, 10, tocolor(5, 5, 5, 230))
    if factionLogo then
        dxDrawImage(x + 15, y + 12, 34, 34, factionLogo)
    end
    if not playerTeam or playerTeamName == 'Sivil' then
        dxDrawText('Herhangi bir birliğe üye değilsin.', x, y + 150, x+w, y+h, tocolor(186, 28, 28, 220), 1, robotoB, 'center', 'center')
        dxDrawText('', x, y, x+w, y+h, tocolor(186, 28, 28, 220), 1, fontAwesome14, 'center', 'center')

    else
        roundedRectangle('faction-main-colmn', x + 670, y, w - 630, h, 10, tocolor(10, 10, 10, 255))
        local pagesCount = 0
        for index, value in ipairs(factionPages) do
            if index == faction.page then
                roundedRectangle('faction-page-icon', x + w - 120, y + 20 + (pagesCount * 55), 150, 45, 8, tocolor(5,5,5, 255))
                dxDrawText(value[2], x + w - 120, y + 20 + (pagesCount * 55), (x + w - 120) + 45, (y + 20 + (pagesCount * 55)) + 45, tocolor(255, 255, 255, 150), 1, fontAwesome11, 'center', 'center')
                dxDrawText(value[1], x + w + 15, y + 20 + (pagesCount * 55), (x + w - 120) + 45, (y + 20 + (pagesCount * 55)) + 45, tocolor(255, 255, 255, 150), 1, roboto2, 'center', 'center')
         
		 else
                if isInBox(x + w - 120, y + 20 + (pagesCount * 55), 150, 45) then
                    roundedRectangle('faction-page-icon', x + w - 120, y + 20 + (pagesCount * 55), 150, 45, 8, tocolor(138,91,148, 230))
                    dxDrawText(value[1], x + w + 15, y + 20 + (pagesCount * 55), (x + w - 120) + 45, (y + 20 + (pagesCount * 55)) + 45, tocolor(255, 255, 255, 150), 1, roboto2, 'center', 'center')
                    if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                        faction.page = index
                        faction.lastClick = getTickCount() + 300
                    end
                else
                    roundedRectangle('faction-page-icon-selected', x + w - 120, y + 20 + (pagesCount * 55), 150, 45, 8, tocolor(15, 15, 15, 230))
                end
                dxDrawText(value[2], x + w - 120, y + 20 + (pagesCount * 55), (x + w - 120) + 45, (y + 20 + (pagesCount * 55)) + 45, tocolor(255, 255, 255, 150), 1, fontAwesome11, 'center', 'center')
                dxDrawText(value[1], x + w + 15, y + 20 + (pagesCount * 55), (x + w - 120) + 45, (y + 20 + (pagesCount * 55)) + 45, tocolor(255, 255, 255, 150), 1, roboto2, 'center', 'center')
		   end
            pagesCount = pagesCount + 1
        end

        dxDrawRectangle(x + w - 115, y + 340, 140, 1, tocolor(20, 20, 20, 200))

        if isInBox(x + w - 70, y + 350, 45, 45) then
            local cursorX, cursorY = getCursorPosition()
            roundedRectangle('faction-page-icon',  x + w - 70, y + 350, 45, 45, 8, tocolor(138,91,148, 230))
            roundedRectangle('faction-page-selected-info', cursorX*screenX, cursorY*screenY, dxGetTextWidth('Üye davet et',1, roboto) + 20, 30, 1, tocolor(20, 20, 20, 230), true)
            dxDrawText('Üye davet et', cursorX*screenX, cursorY*screenY, (cursorX*screenX) + dxGetTextWidth('Üye davet et',1, roboto) + 20, (cursorY*screenY) + 30, tocolor(255, 255, 255, 190), 1, roboto, 'center', 'center', false, false, true)
            if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                faction.page = 'invite'
                faction.lastClick = getTickCount() + 300
            end
        else
            roundedRectangle('faction-page-icon-selected', x + w - 70, y + 350, 45, 45, 8, tocolor(15, 15, 15, 230))
        end
        dxDrawText('', x + w - 20, y + 350, (x + w - 120) + 45, (y + 350) + 45, tocolor(255, 255, 255, 150), 1, fontAwesome11, 'center', 'center')

        if isInBox(x + w - 70, y + 400, 45, 45) then
            local cursorX, cursorY = getCursorPosition()
            roundedRectangle('faction-page-icon',  x + w - 70, y + 400, 45, 45, 8, tocolor(138,91,148, 230))
            roundedRectangle('faction-page-selected-info', cursorX*screenX, cursorY*screenY, dxGetTextWidth('Birlikten ayrıl',1, roboto) + 20, 30, 1, tocolor(20, 20, 20, 230), true)
            dxDrawText('Birlikten ayrıl', cursorX*screenX, cursorY*screenY, (cursorX*screenX) + dxGetTextWidth('Birlikten ayrıl',1, roboto) + 20, (cursorY*screenY) + 30, tocolor(255, 255, 255, 190), 1, roboto, 'center', 'center', false, false, true)
            if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                openFactionUI()
                triggerServerEvent('faction -> leave', localPlayer)
                faction.lastClick = getTickCount() + 300
            end
        else
            roundedRectangle('faction-page-icon-selected', x + w - 70, y + 400, 45, 45, 8, tocolor(15, 15, 15, 230))
        end
        dxDrawText('', x + w - 20, y + 400, (x + w - 120) + 45, (y + 400) + 45, tocolor(255, 255, 255, 150), 1, fontAwesome11, 'center', 'center')

        if faction.page == 1 then
            factionStatus = {
                {'Toplam Üye:', faction.members and #faction.members or 'Yükleniyor'},
                {'Aktif Üye:', #getOnlineFactionMembers()},
                {'Aktif Lider:', #getOnlineFactionMembers()},
                {'Toplam Taşıt:', #faction.vehicles},
                {'Birlik kasası:', faction.money},
                {'Liderlik:', faction.isLeader == 1 and 'Var' or 'Yok'}
            }
            local addY = 0
            local xC = 1
            for index, value in ipairs(factionStatus) do
                if index % 3 == 1 then
                    xC = xC + 1
                    addY = 0
                else
                    addY = addY + 40
                end
                roundedRectangle('faction-status-rectangle', x - 320 + (xC * 180), y + 70 + (addY), 170, 35, 3, tocolor(10,10,10, 230))
                dxDrawText(value[1]..' '..value[2],x - 320 + (xC * 180), y + 70 + (addY), x - 320 + (xC * 180)+170, y + 70 + (addY)+35, tocolor(255, 255, 255, 170), 1, roboto, 'center', 'center')
            end

            roundedRectangle('faction-status-rectangle-2', x + 410, y + 70, 220, 120, 5, tocolor(10,10,10, 230))

            dxDrawText('Birlik Notu', x + 43, y + 200, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            roundedRectangle('faction-motd', x + 40, y + 230, 590, 170, 5, tocolor(10,10,10, 230))
            dxDrawText(faction.note or "", x + 50, y + 285, (x + 35) + 590, (y + 280) + 170, tocolor(255, 255, 255, 170), 1, robotoL, 'left', 'top', false, true)
            dxDrawText(playerTeamName, x + 420, y+80, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Birlik id: '..faction.id, x + 420, y + 170, w, h, tocolor(255, 255, 255, 170), 1, roboto)
			dxDrawText('goat 1.0',x+10, y+5, 100, 100, tocolor(255, 255, 255, 170), 1,robotoL)
			
            if isInBox(x + 40, y + 280, 590, 170) and getKeyState('mouse1') and getTickCount() > faction.lastClick and faction.isLeader == 1 then
                faction.selectedText = 'motd'
                faction.lastClick = getTickCount() + 400
                faction.note = ''
            end

            if faction.selectedText and faction.selectedText == 'motd' then
                if isInBox(x + 478, y + 195, 150, 30) then
                    roundedRectangle('faction-save-note-effect', x + 478, y + 195, 150, 30, 2, tocolor(47,131,234, 255))
                    dxDrawText('Değişiklikleri kaydet', x + 478, y + 195, (x + 478) + 150, (y + 195) + 30, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                    if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                        triggerServerEvent('faction -> edit -> note', localPlayer, faction.note, faction.id)
                        faction.lastClick = getTickCount() + 400
                    end
                else
                    roundedRectangle('faction-save-note', x + 478, y + 195, 150, 30, 2, tocolor(10, 10, 10, 230))
                    dxDrawText('Değişiklikleri kaydet', x + 478, y + 195, (x + 478) + 150, (y + 195) + 30, tocolor(255, 255, 255, 170), 1, robotoL, 'center', 'center')
                end
            end

          	local tXP = (faction.level+1)^2 * 100
            roundedRectangle('faction-level-bar', x + 40, y + 420, 590, 35, 10, tocolor(10, 10, 10, 230))
            roundedRectangle('faction-level-bar-effect'..tXP, x + 40, y + 420, (faction.xp/tXP)*590, 35, 10, tocolor(235, 211, 52, 220))
            dxDrawText('',  x + 45, y + 420, (x + 40) + 590, ( y + 420) + 35, tocolor(25, 25, 25, 200), 1, fontAwesome11, 'left', 'center')
            dxDrawText('Seviye: '..faction.level..' - '..faction.xp..'/'..tXP,  x + 45, y + 420, (x + 40) + 590, ( y + 420) + 35, tocolor(25, 25, 25, 200), 1, robotoB12, 'center', 'center')
        elseif faction.page == 2 then
            roundedRectangle('faction-userlist', x + 35, y + 30, w - 200, h - 193, 10, tocolor(10, 10, 10, 230))
            dxDrawText('İsim', x + 50, y + 40, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Rütbe', x + 200, y + 40, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Statü', x + 400, y + 40, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Durum', x + 550, y + 40, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawRectangle(x + 37.5 , y + 60, w-205, 1, tocolor(15, 15, 15, 220))
            if faction.members then
                local count = 0
                local y = y + 30
                for index, value in ipairs(faction.members) do
                    if index > faction.userRow and count < faction.maxUserRow then
                        local mousePos = isInBox(x + 50, y + 32 + (count * 30), w - 200, 30)
                        if mousePos or value.charactername == faction.selectedUser then
                            dxDrawText(value.charactername, x + 50, y + 35 + (count * 30), w, h, tocolor(255, 255, 255, 230), 1, robotoL)
                            dxDrawText(teamRanks[value.faction_rank] or teamRanks[1], x + 200, y + 35 + (count * 30), (x + 200) + 40, h, tocolor(255, 255, 255, 230), 1, robotoL, 'center')
                            dxDrawText(value.faction_leader == 1 and 'Lider' or 'Üye', x + 400, y + 35 + (count * 30), (x + 400) + 35, h, tocolor(255, 255, 255, 230), 1, robotoL, 'center')
                            local activeStatus = getPlayerFromName(string.gsub(value.charactername, " ", "_"))
                            local activeW = 70
                            roundedRectangle(isElement(activeStatus) and 'active-green' or 'active-red', (x + 550 + x + 600)/2 - activeW / 2, y + 35 + (count * 30), activeW, 20, 4, isElement(activeStatus) and tocolor(107, 242, 129, 130) or tocolor(242, 107, 107, 130))
                            dxDrawText(isElement(activeStatus) and 'Aktif' or 'İn-aktif', (x + 550 + x + 600)/2 - activeW / 2, y + 35 + (count * 30), ((x + 550 + x + 600)/2 - activeW / 2)+activeW,  y + 35 + (count * 30) + 20, tocolor(255, 255, 255, 230), 0.8, robotoL, 'center', 'center')
                            if mousePos and getKeyState('mouse1') and getTickCount() > faction.lastClick  then
                                faction.selectedUser = value.charactername
                                faction.lastClick = getTickCount() + 300
                            end
                            if value.charactername == faction.selectedUser then
                                dxDrawText('Üye Bilgileri', x + 35 , y + 290, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
                                local y = y + 20
                                dxDrawText(value.charactername, x + 35 , y + 300, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
                                dxDrawText(teamRanks[value.faction_rank] or teamRanks[1], x + 35 , y + 320, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
                                dxDrawText(value.faction_leader == 1 and 'Lider' or 'Üye', x + 35 , y + 340, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
                            end
                        else
                            dxDrawText(value.charactername, x + 50, y + 35 + (count * 30), w, h, tocolor(255, 255, 255, 170), 1, robotoL)
                            dxDrawText(teamRanks[value.faction_rank] or teamRanks[1], x + 200, y + 35 + (count * 30), (x + 200) + 40, h, tocolor(255, 255, 255, 170), 1, robotoL, 'center')
                            dxDrawText(value.faction_leader == 1 and 'Lider' or 'Üye', x + 400, y + 35 + (count * 30), (x + 400) + 35, h, tocolor(255, 255, 255, 170), 1, robotoL, 'center')
                            local activeStatus = getPlayerFromName ( string.gsub(value.charactername, " ", "_") )
                            local activeW = 70
                            roundedRectangle(isElement(activeStatus) and 'active-green' or 'active-red', (x + 550 + x + 600)/2 - activeW / 2, y + 35 + (count * 30), activeW, 20, 4, isElement(activeStatus) and tocolor(107, 242, 129, 80) or tocolor(242, 107, 107, 80))
                            dxDrawText(isElement(activeStatus) and 'Aktif' or 'İn-aktif', (x + 550 + x + 600)/2 - activeW / 2, y + 35 + (count * 30), ((x + 550 + x + 600)/2 - activeW / 2)+activeW,  y + 35 + (count * 30) + 20, tocolor(255, 255, 255, 170), 0.8, robotoL, 'center', 'center')
                        end
                        count = count + 1
                        dxDrawRectangle(x + 37.5 , y + 30.5 + (count * 30), w-205, 1, tocolor(15, 15, 15, 220))
                    end
                end
                if faction.selectedUser and faction.isLeader == 1 then
                    if isInBox(x + 485, y + 300, 150, 50) then
                        roundedRectangle('kick-button-effect', x + 485, y + 300, 150, 50, 5, tocolor(242, 107, 107, 70))
                        dxDrawText('Birlikten at', x + 485, y + 300, (x + 485) + 150, (y + 300) + 50, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                        if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                            triggerServerEvent('faction -> kick', localPlayer, faction.selectedUser, getUserData(faction.selectedUser, 'id'))
                            faction.lastClick = getTickCount() + 400
                        end
                    else
                        roundedRectangle('kick-button', x + 485, y + 300, 150, 50, 5, tocolor(5, 5, 5, 220))
                        dxDrawText('Birlikten at', x + 485, y + 300, (x + 485) + 150, (y + 300) + 50, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
                    end

                    if isInBox(x + 485, y + 360, 150, 50) then
                        roundedRectangle('leader-button-effect', x + 485, y + 360, 150, 50, 5, tocolor(107, 242, 129, 70))
                        dxDrawText(getUserData(faction.selectedUser, 'faction_leader') == 1 and 'Liderliği al' or 'Liderlik ver', x + 485, y + 360, (x + 485) + 150, (y + 360) + 50, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                        if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                            triggerServerEvent('faction -> setLeader', localPlayer, faction.selectedUser, getUserData(faction.selectedUser, 'id'))
                            faction.lastClick = getTickCount() + 400
                        end
                    else
                        roundedRectangle('kick-button', x + 485, y + 360, 150, 50, 5, tocolor(5, 5, 5, 220))
                        dxDrawText(getUserData(faction.selectedUser, 'faction_leader') == 1 and 'Liderliği al' or 'Liderlik ver', x + 485, y + 360, (x + 485) + 150, (y + 360) + 50, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
                    end
                    local count = 0
                    for index, value in ipairs(faction.ranks) do
                        if index > faction.userRank and count < faction.maxUserRank then
                            if isInBox(x + 330, y + 290 + (count * 23), 120, 20) or getUserData(faction.selectedUser, 'faction_rank') == index then
                                roundedRectangle('rank-row-effect', x + 330, y + 290 + (count * 23), 120, 20, 2, tocolor(15, 15, 15, 220))
                                dxDrawText(value, x + 330, y + 290 + (count * 23), (x + 330) + 120, (y + 290 + (count * 23)) + 20, tocolor(255, 255, 255, 230), 0.8, robotoL, 'center', 'center', true)
                                if isInBox(x + 330, y + 290 + (count * 23), 120, 20) and getKeyState('mouse1') and getTickCount() > faction.lastClick then
                                    triggerServerEvent('faction -> rank -> user', localPlayer, faction.selectedUser, index, getUserData(faction.selectedUser, 'id'))
                                    faction.lastClick = getTickCount() + 400
                                end
                            else
                                roundedRectangle('rank-row', x + 330, y + 290 + (count * 23), 120, 20, 2, tocolor(5, 5, 5, 220))
                                dxDrawText(value, x + 330, y + 290 + (count * 23), (x + 330) + 120, (y + 290 + (count * 23)) + 20, tocolor(255, 255, 255, 170), 0.8, robotoL, 'center', 'center', true)
                            end
                            count = count + 1
                        end
                    end

                    createScrollBar(x + 455, y + 290, 10, 135, 20, faction.maxUserRank, faction.userRank)
                elseif not faction.selectedUser and faction.isLeader == 1 then
                    dxDrawText('Yönetmek için üye seçiniz.', x, y + 100, x+w-130, y + 100+h, tocolor(255, 255, 255, 170), 1, robotoB, 'center', 'center')
                end
                createScrollBar(x + 640, y, 10, h - 190, #faction.members, faction.maxUserRow, faction.userRow)
            end
        elseif faction.page == 3 then
            dxDrawText(playerTeamName, x + 40, y + 20, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Birlik geçmişi', x + 40, y + 45, w, h, tocolor(255, 255, 255, 170), 1, roboto)
            local y = y + 30
            roundedRectangle('faction-loglist', x + 35, y + 50, w - 200, h - 110, 10, tocolor(10, 10, 10, 230))
            dxDrawText('Tarih', x + 50, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Yetkili', x + 200, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('İşlem', x + 400, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Üye', x + 550, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawRectangle(x + 37.5 , y + 80, w-205, 1, tocolor(15, 15, 15, 220))
            local count = 0
            local y = y + 50
            for index, value in ipairs(faction.logs) do
                if index > faction.logRow and count < faction.maxLogRow then
                    dxDrawText(value.date, x + 50, y + 35 + (count * 30), w, h, tocolor(255, 255, 255, 170),1 , robotoL8)
                    dxDrawText(tostring(value.admin), x + 205, y + 35 + (count * 30), (x + 205) + 30, h, tocolor(255, 255, 255, 170), 1, robotoL8, 'center')
                    dxDrawText(value.action, x + 400, y + 35 + (count * 30), (x + 400) + 35, h, tocolor(255, 255, 255, 170), 1, robotoL8, 'center')
                    dxDrawText(tostring(value.user), x + 545, y + 35 + (count * 30), (x + 550) + 35, h, tocolor(255, 255, 255, 170), 1, robotoL8, 'center')
                    dxDrawRectangle(x + 37.5 , y + 30.5 + (count * 30), w-205, 1, tocolor(15, 15, 15, 220))
                    count = count + 1
                end
            end
            createScrollBar(x + 640, y, 10, h - 110, #faction.logs, faction.maxLogRow, faction.logRow)
        elseif faction.page == 4 then
            dxDrawText(playerTeamName, x + 40, y + 20, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Birlik araçları', x + 40, y + 45, w, h, tocolor(255, 255, 255, 170), 1, roboto)
            local y = y + 30
            roundedRectangle('faction-vehlist', x + 35, y + 50, w - 200, h - 170, 10, tocolor(10, 10, 10, 230))
            dxDrawText('#', x + 80, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Model', x + 300, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Plaka', x + 500, y + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawRectangle(x + 37.5 , y + 80, w-205, 1, tocolor(15, 15, 15, 220))
            local count = 0
            local y = y + 50
            for index, value in ipairs(faction.vehicles) do
                if index > faction.vehRow and count < faction.maxVehRow then
                    local mousePos = isInBox(x + 50, y + 32 + (count * 30), w - 200, 30)
                    if mousePos or value.id == faction.selectedVeh then
                        dxDrawText(value.id, x + 60, y + 35 + (count * 30), (x + 80) + 30, h, tocolor(255, 255, 255, 230),1 , robotoL8 , 'center')
                        dxDrawText(value.model, x + 300, y + 35 + (count * 30), (x + 310) + 30, h, tocolor(255, 255, 255, 230), 1, robotoL8, 'center')
                        dxDrawText(value.plate, x + 500, y + 35 + (count * 30), (x + 510) + 30, h, tocolor(255, 255, 255, 230), 1, robotoL8, 'center')
                        if mousePos and getKeyState('mouse1') and getTickCount() > faction.lastClick and faction.isLeader == 1  then
                            faction.selectedVeh = value.id
                            faction.lastClick = getTickCount() + 300
                        end
                    else
                        dxDrawText(value.id, x + 60, y + 35 + (count * 30), (x + 80) + 30, h, tocolor(255, 255, 255, 170),1 , robotoL8 , 'center')
                        dxDrawText(value.model, x + 300, y + 35 + (count * 30), (x + 310) + 30, h, tocolor(255, 255, 255, 170), 1, robotoL8, 'center')
                        dxDrawText(value.plate, x + 500, y + 35 + (count * 30), (x + 510) + 30, h, tocolor(255, 255, 255, 170), 1, robotoL8, 'center')
                    end
                    dxDrawRectangle(x + 37.5 , y + 30.5 + (count * 30), w-205, 1, tocolor(15, 15, 15, 220))
                    count = count + 1
                end
            end
            createScrollBar(x + 640, y, 10, h - 170, #faction.vehicles, faction.maxVehRow, faction.vehRow)
            if faction.isLeader == 1 then
                if isInBox(x + 485, y + 320, 150, 50) then
                    roundedRectangle('faction-button-effect', x + 485, y + 320, 150, 50, 5, tocolor(83, 83, 252, 70))
                    dxDrawText('Tüm araçları yenile', x + 485, y + 320, (x + 485) + 150, (y + 320) + 50, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                    if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                        triggerServerEvent('faction -> respawn -> all', localPlayer, faction.id)
                        faction.lastClick = getTickCount() + 400
                    end
                else
                    roundedRectangle('faction-button', x + 485, y + 320, 150, 50, 5, tocolor(5, 5, 5, 220))
                    dxDrawText('Tüm araçları yenile', x + 485, y + 320, (x + 485) + 150, (y + 320) + 50, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
                end

                if faction.selectedVeh then
                    if isInBox(x + 320, y + 320, 150, 50) then
                        roundedRectangle('faction-button-effect', x + 320, y + 320, 150, 50, 5, tocolor(83, 83, 252, 70))
                        dxDrawText('Seçilen aracı yenile', x + 320, y + 320, (x + 320) + 150, (y + 320) + 50, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                        if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                            triggerServerEvent('faction -> respawn', localPlayer, faction.selectedVeh)
                            faction.lastClick = getTickCount() + 400
                        end
                    else
                        roundedRectangle('faction-button', x + 320, y + 320, 150, 50, 5, tocolor(5, 5, 5, 220))
                        dxDrawText('Seçilen aracı yenile', x + 320, y + 320, (x + 320) + 150, (y + 320) + 50, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
                    end
                end
            end
        elseif faction.page == 5 then
            dxDrawText(playerTeamName, x + 40, y + 20, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Birlik rütbe düzenleme', x + 40, y + 45, w, h, tocolor(255, 255, 255, 170), 1, roboto)
            local count = 0
            for index, value in ipairs(faction.ranks) do
                if index > faction.userRankEdit and count < faction.maxUserRankEdit then
                    if isInBox(x + 35, y + 70 + (count * 40), 500, 35) or getUserData(faction.selectedUser, 'faction_rank') == index then
                        roundedRectangle('rank-edit-row-effect', x + 35, y + 70 + (count * 40), 500, 35, 2, tocolor(5, 5, 5, 220))
                        dxDrawText(value, x + 35, y + 70 + (count * 40), (x + 35) + 500, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center', true)
                        if getKeyState('mouse1') and getTickCount() > faction.lastClick and faction.isLeader == 1 then
                            faction.selectedText = 'rank'
                            faction.selectedRank = index
                            faction.lastClick = getTickCount() + 400
                        end
                    else
                        roundedRectangle('rank-edit-row', x + 35, y + 70 + (count * 40), 500, 35, 2, tocolor(5, 5, 5, 170))
                        dxDrawText(value, x + 35, y + 70 + (count * 40), (x + 35) + 500, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 170), 1, robotoL, 'center', 'center', true)
                    end

                    if isInBox(x + 545, y + 70 + (count * 40), 100, 35) then
                        roundedRectangle('wage-edit-row-effect', x + 545, y + 70 + (count * 40), 100, 35, 2, tocolor(5, 5, 5, 220))
                        dxDrawText(faction.wages[index], x + 545, y + 70 + (count * 40), (x + 545) + 100, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center', true)
                        if getKeyState('mouse1') and getTickCount() > faction.lastClick and faction.isLeader == 1 then
                            faction.selectedText = 'wage'
                            faction.selectedRank = index
                            faction.lastClick = getTickCount() + 400
                        end
                    else
                        roundedRectangle('wage-edit-row', x + 545, y + 70 + (count * 40), 100, 35, 2, tocolor(5, 5, 5, 170))
                        dxDrawText(faction.wages[index], x + 545, y + 70 + (count * 40), (x + 545) + 100, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 170), 1, robotoL, 'center', 'center', true)
                    end
                    count = count + 1
                end
            end
            createScrollBar(x + 650, y + 70, 8, 315, 20, faction.maxUserRankEdit, faction.userRankEdit)
            if faction.isLeader == 1 then
                if isInBox(x + 35, y + 400, 610, 50) then
                    roundedRectangle('faction-save-effect',  x + 35, y + 400, 610, 50, 10, tocolor(47,131,234, 200))
                    dxDrawText('Değişiklikleri kaydet', x + 35, y + 400, (x + 35) + 610, (y + 400) + 50, tocolor(255, 255, 255, 230), 1, robotoL, 'center', 'center')
                    if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                        triggerServerEvent('faction -> edit -> rank', localPlayer, faction.ranks, faction.wages, faction.id)
                        faction.lastClick = getTickCount() + 400
                    end
                else
                    roundedRectangle('faction-save', x + 35, y + 400, 610, 50, 10, tocolor(5, 5, 5, 220))
                    dxDrawText('Değişiklikleri kaydet', x + 35, y + 400, (x + 35) + 610, (y + 400) + 50, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
                end
            end
        elseif faction.page == 6 then
            dxDrawText('Birlik Sıralaması', x + 40, y + 20, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Banka bakiyesine göre en zengin birlikler', x + 40, y + 45, w, h, tocolor(255, 255, 255, 170), 1, roboto)
            local ly = y + 30
            roundedRectangle('faction-leaderboard', x + 35, ly + 50, w - 200, h - 110, 10, tocolor(10, 10, 10, 230))
            dxDrawText('#', x + 50, ly + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Birlik', x + 100, ly + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawText('Banka', x + 500, ly + 60, w, h, tocolor(255, 255, 255, 170), 1, robotoL)
            dxDrawRectangle(x + 37.5, ly + 80, w - 205, 1, tocolor(15, 15, 15, 220))
            local count = 0
            local ly2 = ly + 50
            for index, value in ipairs(faction.leaderboard or {}) do
                if index > leaderboardRow and count < leaderboardMax then
                    local rankColor = tocolor(255, 255, 255, 170)
                    if index == 1 then rankColor = tocolor(255, 215, 0, 220)
                    elseif index == 2 then rankColor = tocolor(200, 200, 200, 220)
                    elseif index == 3 then rankColor = tocolor(205, 127, 50, 220) end
                    dxDrawText(index .. '.', x + 50, ly2 + 35 + (count * 30), w, h, rankColor, 1, robotoL8)
                    dxDrawText(tostring(value.name), x + 100, ly2 + 35 + (count * 30), w, h, tocolor(255, 255, 255, 190), 1, robotoL8)
                    dxDrawText(tostring(value.bankbalance) .. ' TL', x + 500, ly2 + 35 + (count * 30), w, h, tocolor(120, 255, 120, 190), 1, robotoL8)
                    dxDrawRectangle(x + 37.5, ly2 + 30.5 + (count * 30), w - 205, 1, tocolor(15, 15, 15, 220))
                    count = count + 1
                end
            end
            createScrollBar(x + 640, ly, 10, h - 110, #(faction.leaderboard or {}), leaderboardMax, leaderboardRow)
        elseif faction.page == 'invite' then
            dxDrawText(playerTeamName, x + 40, y + 20, w, h, tocolor(255, 255, 255, 170), 1, robotoB)
            dxDrawText('Birliğe üye davet et', x + 40, y + 45, w, h, tocolor(255, 255, 255, 170), 1, roboto)
            local count = 0
            for index, value in ipairs(getInvitablePlayers()) do
                if isInBox(x + 35, y + 70 + (count * 40), 600, 35) then
                    roundedRectangle('rank-edit-row', x + 35, y + 70 + (count * 40), 500, 35, 2, tocolor(5, 5, 5, 220))
                    dxDrawText(value.name, x + 35, y + 70 + (count * 40), (x + 35) + 500, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center', true)
                    roundedRectangle('wage-edit-row', x + 545, y + 70 + (count * 40), 100, 35, 2, tocolor(5, 5, 5, 220))
                    dxDrawText('Davet et', x + 545, y + 70 + (count * 40), (x + 545) + 100, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center', true)
                    if getKeyState('mouse1') and getTickCount() > faction.lastClick then
                        triggerServerEvent('faction -> invite', localPlayer, 'send', faction.id, #faction.members, #faction.vehicles, value)
                        faction.lastClick = getTickCount() + 400
                    end
                else
                    roundedRectangle('rank-edit-row-effect', x + 35, y + 70 + (count * 40), 500, 35, 2, tocolor(5, 5, 5, 170))
                    dxDrawText(value.name, x + 35, y + 70 + (count * 40), (x + 35) + 500, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 170), 1, robotoL, 'center', 'center', true)
                    roundedRectangle('wage-edit-row-effect', x + 545, y + 70 + (count * 40), 100, 35, 2, tocolor(5, 5, 5, 170))
                    dxDrawText('Davet et', x + 545, y + 70 + (count * 40), (x + 545) + 100, (y + 70 + (count * 40)) + 35, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center', true)
                end
                count = count + 1
            end
        end
    end
end



addEventHandler("onClientElementDataChange", root, 
	function(theKey, oldValue, newValue)
		if faction.enabled then
			if getElementType(source) == 'team' then
				if source == localPlayer.team then
					if reloadData.factions[theKey] then
						faction[reloadData.factions[theKey]] = newValue
					end
				end
			elseif getElementType(source) == 'player' then
				if source == localPlayer then
					if reloadData.player[theKey] then
						faction[reloadData.player[theKey]] = newValue
					end
				end
			end
		end
	end
)


local faction_invite = {lastClick=0}
function renderFactionInviteUI()
    local w, h = 400, 400
    local x, y = screenX/2-w/2, screenY/2-h/2
    if faction_invite.id then
        local team = faction_invite.player.team
        roundedRectangle('faction-invite', x, y, w, h, 8, tocolor(5, 5, 5, 230))
        roundedRectangle('faction-name-background', x + 20, y + 70, w - 40, 250, 5, tocolor(15, 15, 15, 230))
        dxDrawText('Yeni birlik daveti', x, y + 30, x+w, h, tocolor(255, 255, 255, 170), 1, robotoB12, 'center')
        dxDrawText(faction_invite.player.name:gsub('_', ' ')..' tarafından birliğe davet edildin.', x + 20, y + 80, (x+20)+w-40, h, tocolor(255, 255, 255, 170), 1, robotoL, 'center', 'top', false, true)
        dxDrawRectangle(x + 25, y + 120, w-50, 1, tocolor(25, 25, 25, 230))
        dxDrawText(team.name, x + 20, y + 135, (x+20)+w-40, h, tocolor(255, 255, 255, 170), 1, robotoB, 'center', 'top', false, true)
        factionsP = {
            {'', faction_invite.members..' üye', tocolor(255, 255, 255, 150)},
            {'', faction_invite.vehicles..' taşıt', tocolor(255, 255, 255, 150)},
            {'', team:getData('level')..' seviye', tocolor(235, 211, 52, 150)},
            {'', ((team:getData('approval') or 0) == 1 and 'Onaylı birlik' or 'Onaysız birlik'), tocolor(52, 235, 82, 150)},
        }
        local pX, pY = 0, 0
        for index, value in ipairs(factionsP) do
            if index  % 2 == 1 then
                pX = 0
                pY = pY + 70
            end
            dxDrawText(value[1], x + 87 + (pX * 200), y + 120 +pY, w, h, value[3], 1, fontAwesome11)
            dxDrawText(value[2], x + 70 + (pX * 200), y + 145 +pY, (x + 97 + (pX * 200)) + 30, h, tocolor(255, 255, 255, 180), 1, robotoL, 'center')
            pX = pX + 1
        end
        if isInBox(x + 20, y + 340, 150, 40) then
            roundedRectangle('buton-decline-effect', x + 20, y + 340, 150, 40, 5, tocolor(168, 50, 50, 150))
            dxDrawText('Reddet', x + 20, y + 340, x + 20+150,  y + 340+40, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center')
            if getKeyState('mouse1') and getTickCount() > faction_invite.lastClick then
                triggerServerEvent('faction -> invite', localPlayer, 'decline')
                faction_invite.lastClick = getTickCount() + 400
                removeEventHandler('onClientRender', root, renderFactionInviteUI)
            end
        else
            roundedRectangle('buton-decline', x + 20, y + 340, 150, 40, 5, tocolor(168, 50, 50, 110))
            dxDrawText('Reddet', x + 20, y + 340, x + 20+150,  y + 340+40, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
        end

        if isInBox(x + 230, y + 340, 150, 40) then
            roundedRectangle('buton-accept-effect', x + 230, y + 340, 150, 40, 5, tocolor(50, 168, 82, 150))
            dxDrawText('Kabul et', x + 230, y + 340, x + 230+150,  y + 340+40, tocolor(255, 255, 255, 220), 1, robotoL, 'center', 'center')
            if getKeyState('mouse1') and getTickCount() > faction_invite.lastClick then
                triggerServerEvent('faction -> invite', localPlayer, 'accept')
                faction_invite.lastClick = getTickCount() + 400
                removeEventHandler('onClientRender', root, renderFactionInviteUI)
            end
        else
            roundedRectangle('buton-accept', x + 230, y + 340, 150, 40, 5, tocolor(50, 168, 82, 110))
            dxDrawText('Kabul et', x + 230, y + 340, x + 230+150,  y + 340+40, tocolor(255, 255, 255, 150), 1, robotoL, 'center', 'center')
        end
    end
end



addEvent('faction -> openInvite', true)
addEventHandler('faction -> openInvite', root, function(faction)
    faction_invite = faction
    addEventHandler('onClientRender', root, renderFactionInviteUI)
end)

function getInvitablePlayers()
    local players = {}
    local x, y, z = getElementPosition(localPlayer)
    for index, value in ipairs(getElementsWithinRange(x, y, z, 30, "player")) do
        if value ~= localPlayer and (value:getData('faction') or -1) == -1 and not value:getData('faction -> invite') then
            table.insert(players, value)
        end
    end
    return players
end



function getOnlineFactionMembers(isLeader)
    local onlineMembers = {}
    if faction.members then
        for index, value in ipairs(faction.members) do
            if isLeader and value.faction_leader == 1 and getPlayerFromName ( value.charactername ) or getPlayerFromName ( value.charactername ) then 
                table.insert(onlineMembers, value)
            end
        end
    end
    return onlineMembers
end

function getUserData(userid, data)
    if userid and data then
        for index, value in ipairs(faction.members) do
            if value.charactername == userid and value[data] then
                return value[data]
            end
        end
    end
    return false
end


function createScrollBar(x, y, w, h, total, maxShow, currentShow, color, color2)
    if(total> maxShow) then
        dxDrawRectangle(x, y, w, h, color or tocolor(0,0,0,200))
        dxDrawRectangle(x , y+((currentShow)*(h/(total))), w, h/math.max((total/maxShow),1),color2 or tocolor(255, 255, 255, 150))
    end
end

function key(character)
    if faction.enabled then
        if faction.selectedText == 'rank' then
            if utf8.len(faction.ranks[faction.selectedRank]) < 16 then
                faction.ranks[faction.selectedRank] = faction.ranks[faction.selectedRank]..''..character..''
            end
        elseif faction.selectedText == 'wage' then
            if tonumber(character) then
                if utf8.len(faction.wages[faction.selectedRank]) < 4 then
                    faction.wages[faction.selectedRank] = faction.wages[faction.selectedRank]..''..character..''
                end
            end
        elseif faction.selectedText == 'motd' then
            if utf8.len(faction.note) < 300 then
                faction.note = faction.note..''..character..''
            end
        end
    end
end
addEventHandler('onClientCharacter', root, key)


function delete(button)
    if faction.enabled then
        if button == "backspace" then
            if faction.selectedText == 'rank' then
                if string.len(faction.ranks[faction.selectedRank]) >= 1 then
                    faction.ranks[faction.selectedRank] = string.sub(faction.ranks[faction.selectedRank], 1, string.len(faction.ranks[faction.selectedRank])-1)
                end
            elseif faction.selectedText == 'wage' then
                if string.len(faction.wages[faction.selectedRank]) >= 1 then
                    faction.wages[faction.selectedRank] = string.sub(faction.wages[faction.selectedRank], 1, string.len(faction.wages[faction.selectedRank])-1)
                end
            elseif faction.selectedText == 'motd' then
                if string.len(faction.note) >= 1 then
                    faction.note = string.sub(faction.note, 1, string.len(faction.note)-1)
                end
            end
        end
    end
end
addEventHandler('onClientKey', root, delete)

svgData = {}
function roundedRectangle(name, x, y, width, height, ratio, color1, postGUI)
    if not svgData[name] then
        svgData[name] = {}
        local r,g,b,a = bitExtract(color1,16,8),bitExtract(color1,8,8), bitExtract(color1,0,8), bitExtract(color1,24,8)
        local _color1 = string.format("#%.2X%.2X%.2X", r,g,b)
        --
        local _color2 = string.format("#%.2X%.2X%.2X", r,g,b)
        --
        local rawSvgData = [[
            <svg width="]]..(width+0.5)..[[" height="]]..(height+0.5)..[[">
                <rect x="0.5" y="0.5" rx="]]..ratio..[[" ry="]]..ratio..[[" width="]]..(width-0.5)..[[" height="]]..(height-0.5)..[["
                fill="]].._color1..[[" stroke="]].._color2..[[" stroke-width="0" stroke-opacity="255" opacity="255" />
            </svg>
        ]]
        --
        svgData[name].data = svgCreate(width, height, rawSvgData)
        svgData[name].alpha = a
    end
    if color1 then
        local r,g,b,a = bitExtract(color1,16,8),bitExtract(color1,8,8), bitExtract(color1,0,8), bitExtract(color1,24,8)
        if svgData[name].alpha ~= a then svgData[name].alpha = a end
    end
    return dxDrawImage(x, y, width, height, svgData[name].data, 0, 0, 0, tocolor(255, 255, 255, svgData[name].alpha), postGUI or false)
end


local screenX, screenY = guiGetScreenSize()
function isInBox(xS,yS,wS,hS)
    if (isCursorShowing()) then
        local cursorX, cursorY = getCursorPosition()
        cursorX, cursorY = cursorX*screenX, cursorY*screenY
        if(cursorX >= xS and cursorX <= xS+wS and cursorY >= yS and cursorY <= yS+hS) then
            return true
        else
            return false
        end
    end 
end

addEventHandler("onClientKey",root,
    function(button,state)
        if faction.enabled then
            if button == "mouse_wheel_down" then
                if faction.page == 2 and isInBox(x + 35, y + 30, w - 200, h - 200) then
                    if faction.userRow + faction.maxUserRow < #faction.members then
                        faction.userRow = faction.userRow + 1
                    end
                elseif faction.page == 2 and isInBox(x + 330, y + 270,120,160) then
                    if faction.userRank + faction.maxUserRank < #faction.ranks then
                        faction.userRank = faction.userRank + 1
                    end
                elseif faction.page == 3 and isInBox(x + 35, y + 50, w - 200, h - 100) then
                    if faction.logRow + faction.maxLogRow < #faction.logs then
                        faction.logRow = faction.logRow + 1
                    end
                elseif faction.page == 4 and isInBox(x + 35, y + 50, w - 200, h - 170) then
                    if faction.vehRow + faction.maxVehRow < #faction.vehicles then
                        faction.vehRow = faction.vehRow + 1
                    end
                elseif faction.page == 5 and isInBox(x + 35, y + 50, w - 200, h - 140) then
                     if faction.userRankEdit + faction.maxUserRankEdit < #faction.ranks then
                        faction.userRankEdit = faction.userRankEdit + 1
                    end
                elseif faction.page == 6 and isInBox(x + 35, y + 50, w - 200, h - 110) then
                    if leaderboardRow + leaderboardMax < #(faction.leaderboard or {}) then
                        leaderboardRow = leaderboardRow + 1
                    end
                end
            elseif button == "mouse_wheel_up" then
                if faction.page == 2 and isInBox(x + 35, y + 30, w - 200, h - 200) then
                    if faction.userRow >= 1 then
                        faction.userRow = faction.userRow - 1
                    end
                elseif faction.page == 2 and isInBox(x + 330, y + 270,120,160) then
                    if faction.userRank >= 1 then
                        faction.userRank = faction.userRank - 1
                    end
                elseif faction.page == 3 and isInBox(x + 35, y + 50, w - 200, h - 100) then
                    if faction.logRow >= 1 then
                        faction.logRow = faction.logRow - 1
                    end
                elseif faction.page == 4 and isInBox(x + 35, y + 50, w - 200, h - 170) then
                    if faction.vehRow >= 1 then
                        faction.vehRow = faction.vehRow - 1
                    end
                elseif faction.page == 5 and isInBox(x + 35, y + 50, w - 200, h - 140) then
                    if faction.userRankEdit >= 1 then
                        faction.userRankEdit = faction.userRankEdit - 1
                    end
                elseif faction.page == 6 and isInBox(x + 35, y + 50, w - 200, h - 110) then
                    if leaderboardRow >= 1 then
                        leaderboardRow = leaderboardRow - 1
                    end
                end
            end
        end
    end
)

localPlayer:setData('faction -> invite', nil)

wFactionList, bFactionListClose,gridFactions = nil
function showFactionList(factions)
	if not (wFactionList) then
		wFactionList = guiCreateWindow(0.25, 0.25, 0.5, 0.5, "Faction List", true)
		gridFactions = guiCreateGridList(0.025, 0.1, 0.95, 0.775, true, wFactionList)
		
		local colID = guiGridListAddColumn(gridFactions, "ID", 0.1)
		local colName = guiGridListAddColumn(gridFactions, "Faction Name", 0.62)
		local colPlayers = guiGridListAddColumn(gridFactions, "Players", 0.22)
		
		for key, value in pairs(factions) do
			local factionID = factions[key][1]
			local factionName = tostring(factions[key][2])
			local factionPlayers = factions[key][4]
			
			local row = guiGridListAddRow(gridFactions)
			guiGridListSetItemText(gridFactions, row, colID, factionID, false, false)
			guiGridListSetItemText(gridFactions, row, colName, factionName, false, false)
			guiGridListSetItemText(gridFactions, row, colPlayers, factionPlayers, false, false)
		end
		
		addEventHandler( "onClientGUIDoubleClick", gridFactions,
			function( button )
				local row, col = guiGridListGetSelectedItem( source )
				if row ~= -1 and col ~= -1 then
					local gridID = guiGridListGetItemText( source , row, col )
					
					if button == "left" then
						triggerServerEvent("faction:admin:showplayers", getLocalPlayer(), gridID )
					elseif button == "right" then
						-- Admin kontrolü artık server tarafında IsAdmin() ile doğrulanıyor, client'tan flag göndermiyoruz
					triggerServerEvent("faction:admin:showf3", getLocalPlayer(), gridID)
					end
				else
					outputChatBox( "You need to pick an faction.", 255, 0, 0 )
				end
			end,
			false
		)

		bFactionListClose = guiCreateButton(0.025, 0.9, 0.95, 0.1, "Close", true, wFactionList)
		addEventHandler("onClientGUIClick", bFactionListClose, closeFactionList, false)
	else
		guiSetInputEnabled(false)
		destroyElement(wFactionList)
		wFactionList = nil
	end
end
addEvent("showFactionList", true)
addEventHandler("showFactionList", getRootElement(), showFactionList)

function closeFactionList(button, state)
	if (source==bFactionListClose) and (button=="left") and (state=="up") then
		guiSetInputEnabled(false)
		destroyElement(wFactionList)
		wFactionList, bFactionListClose = nil, nil
	end
end

-- /birliksiralama için herkese açık banka bakiyesi sıralaması penceresi
wLeaderboard, bLeaderboardClose, gridLeaderboard = nil
function showLeaderboardWindow(rows)
	if wLeaderboard then
		guiSetInputEnabled(false)
		destroyElement(wLeaderboard)
		wLeaderboard, bLeaderboardClose, gridLeaderboard = nil, nil, nil
	end

	wLeaderboard = guiCreateWindow(0.3, 0.25, 0.4, 0.5, "Birlik Sıralaması (Banka Bakiyesi)", true)
	guiSetInputEnabled(true)
	gridLeaderboard = guiCreateGridList(0.025, 0.1, 0.95, 0.775, true, wLeaderboard)
	local colRank = guiGridListAddColumn(gridLeaderboard, "#", 0.15)
	local colName = guiGridListAddColumn(gridLeaderboard, "Birlik", 0.55)
	local colMoney = guiGridListAddColumn(gridLeaderboard, "Banka", 0.3)

	for index, value in ipairs(rows or {}) do
		local row = guiGridListAddRow(gridLeaderboard)
		guiGridListSetItemText(gridLeaderboard, row, colRank, tostring(index), false, false)
		guiGridListSetItemText(gridLeaderboard, row, colName, tostring(value.name), false, false)
		guiGridListSetItemText(gridLeaderboard, row, colMoney, tostring(value.bankbalance) .. " TL", false, false)
	end

	bLeaderboardClose = guiCreateButton(0.025, 0.9, 0.95, 0.1, "Kapat", true, wLeaderboard)
	addEventHandler("onClientGUIClick", bLeaderboardClose, function(button, state)
		if button == "left" and state == "up" then
			guiSetInputEnabled(false)
			destroyElement(wLeaderboard)
			wLeaderboard, bLeaderboardClose, gridLeaderboard = nil, nil, nil
		end
	end, false)
end
addEvent("faction -> showLeaderboardWindow", true)
addEventHandler("faction -> showLeaderboardWindow", root, showLeaderboardWindow)

-- /birlikkur: isim yazılan, logolu birlik kurma penceresi
wCreateFaction, imgCreateLogo, editCreateName, btnCreateSubmit, btnCreateCancel = nil
function showCreateFactionWindow()
	if wCreateFaction then
		guiSetInputEnabled(false)
		destroyElement(wCreateFaction)
		wCreateFaction = nil
		return
	end

	wCreateFaction = guiCreateWindow(0.35, 0.35, 0.3, 0.28, "Birlik Kur", true)
	guiSetInputEnabled(true)

	if factionLogo then
		imgCreateLogo = guiCreateStaticImage(0.5 - 0.15, 0.08, 0.3, 0.3, "components/logo.png", true, wCreateFaction)
	end

	guiCreateLabel(0.08, 0.42, 0.84, 0.12, "Birlik adı (en fazla 16 karakter):", true, wCreateFaction)
	editCreateName = guiCreateEdit(0.08, 0.55, 0.84, 0.14, "", true, wCreateFaction)
	guiEditSetMaxLength(editCreateName, 16)

	btnCreateSubmit = guiCreateButton(0.08, 0.75, 0.4, 0.15, "Kur (" .. tostring(kurulumUcreti) .. " TL)", true, wCreateFaction)
	btnCreateCancel = guiCreateButton(0.52, 0.75, 0.4, 0.15, "Vazgeç", true, wCreateFaction)

	addEventHandler("onClientGUIClick", btnCreateSubmit, function(button, state)
		if button == "left" and state == "up" then
			local name = guiGetText(editCreateName)
			if name and name ~= '' then
				triggerServerEvent('faction -> create', localPlayer, name)
				guiSetInputEnabled(false)
				destroyElement(wCreateFaction)
				wCreateFaction = nil
			else
				outputChatBox('>>#F9F9F9 Birlik adı boş olamaz!', 195, 184, 116, true)
			end
		end
	end, false)

	addEventHandler("onClientGUIClick", btnCreateCancel, function(button, state)
		if button == "left" and state == "up" then
			guiSetInputEnabled(false)
			destroyElement(wCreateFaction)
			wCreateFaction = nil
		end
	end, false)
end
addEvent("faction -> openCreateWindow", true)
addEventHandler("faction -> openCreateWindow", root, showCreateFactionWindow)
 