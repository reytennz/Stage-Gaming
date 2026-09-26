--[[
    stage_admin - hızlı komutlar
    Panel dışı kullanım için. Hepsi aynı yetki fonksiyonlarından geçer.
]]

local function findPlayer(cmdPlayer, name)
    if not name then return nil end
    local target = getPlayerFromName(name)
    if not target then
        AdminNotify(cmdPlayer, "Oyuncu bulunamadı: " .. name, "error")
    end
    return target
end

local function checkPerm(player, perm)
    if not AdminHasPermission(player, perm) then
        AdminNotify(player, "Bu komutu kullanma yetkiniz yok.", "error")
        return false
    end
    return true
end

-- Zaman komutlari da diger stage_admin komutlariyla ayni rutbe sistemini kullanir.
local function isAdmin(player)
    return AdminHasPermission(player, "time")
end

-- ================= KONSOL: rank atama (in-game chat'ten kullanılamaz) =================
-- Sadece MTA server konsolundan (Debugscript / server penceresi) çalışır.
-- Kullanım:  setrank <OyuncuAdi> <Rank>
--   örnek:   setrank Reytennz Owner
-- ================= KONSOL: Anti-Cheat hassasiyeti (runtime, restart gerekmez) =================
-- Kullanım (konsoldan): acsensitivity hafif | normal | siki
addCommandHandler("acsensitivity", function(player, _, level)
    if player then return end -- sadece konsol
    level = level and level:lower()
    local preset = level and Config.AntiCheatSensitivityPresets[level]
    if not preset then
        outputServerLog("[stage_admin] Kullanım: acsensitivity hafif|normal|siki")
        return
    end
    Config.AntiCheatSensitivity = level
    Config.AntiCheatTolerance = preset
    outputServerLog("[stage_admin] Anti-Cheat hassasiyeti: " .. level)
end)

addCommandHandler("setrank", function(player, _, name, rank)
    if player then
        -- İçeriden (oyun içi chat) tetiklenmişse reddet, sadece konsol.
        return
    end
    if not name or not rank then
        outputServerLog("[stage_admin] Kullanım: setrank <OyuncuAdi> <Rank>  (Rank: User/Moderator/Admin/SuperAdmin/Developer/Owner)")
        return
    end
    local target = getPlayerFromName(name)
    if not target then
        outputServerLog("[stage_admin] Oyuncu bulunamadı: " .. name)
        return
    end
    local valid = false
    for _, r in ipairs(Config.Ranks) do if r == rank then valid = true break end end
    if not valid then
        outputServerLog("[stage_admin] Geçersiz rank: " .. rank .. " (Kullanılabilir: " .. table.concat(Config.Ranks, ", ") .. ")")
        return
    end
    AdminSetRank(target, rank)
    outputServerLog(("[stage_admin] %s -> %s rütbesine yükseltildi (konsoldan)."):format(name, rank))
    AdminNotify(target, "Rütbeniz " .. rank .. " olarak ayarlandı.", "success")
end)

addCommandHandler("myrank", function(player)
    local rank = AdminGetRank(player)
    local level = tonumber(getElementData(player, "adminlevel")) or 0
    local serial = getPlayerSerial(player)
    AdminNotify(player, ("Rütbeniz: %s | Serial: %s"):format(rank, serial), "info")
    outputChatBox("[Stage Admin] Rütbeniz: " .. rank .. " | adminlevel: " .. level .. " | Serial: " .. serial, 90, 170, 240)
end)

addCommandHandler("kick", function(player, _, name, ...)
    if not checkPerm(player, "kick") then return end
    local target = findPlayer(player, name)
    if target then AdminKick(player, target, table.concat({...}, " ")) end
end)

addCommandHandler("ban", function(player, _, name, durationLabel, ...)
    if not checkPerm(player, "ban") then return end
    local target = findPlayer(player, name)
    if not target then return end
    local seconds = 0
    if durationLabel then
        for _, d in ipairs(Config.BanDurations) do
            if d.label:lower() == durationLabel:lower() then seconds = d.seconds break end
        end
    end
    AdminBanPlayer(player, target, table.concat({...}, " "), seconds)
end)

addCommandHandler("warn", function(player, _, name, ...)
    if not checkPerm(player, "warn") then return end
    local target = findPlayer(player, name)
    if target then AdminWarnPlayer(player, target, table.concat({...}, " ")) end
end)

addCommandHandler("goto", function(player, _, name)
    if not checkPerm(player, "goto") then return end
    local target = findPlayer(player, name)
    if target then AdminTeleportTo(player, target) end
end)

addCommandHandler("gethere", function(player, _, name)
    if not checkPerm(player, "gethere") then return end
    local target = findPlayer(player, name)
    if target then AdminBringTo(player, target) end
end)

addCommandHandler("tp", function(player, _, x, y, z)
    if not checkPerm(player, "tpto") then return end
    AdminTeleportToCoords(player, x, y, z)
end)

addCommandHandler("freeze", function(player, _, name)
    if not checkPerm(player, "freeze") then return end
    local target = findPlayer(player, name)
    if target then AdminFreeze(target, true) AdminLog(player, getPlayerName(target), "freeze", "") end
end)

addCommandHandler("unfreeze", function(player, _, name)
    if not checkPerm(player, "unfreeze") then return end
    local target = findPlayer(player, name)
    if target then AdminFreeze(target, false) AdminLog(player, getPlayerName(target), "unfreeze", "") end
end)

addCommandHandler("invisible", function(player)
    if not checkPerm(player, "invisible") then return end
    local state = not getElementData(player, "admin:invisible")
    AdminSetInvisible(player, state)
    AdminLog(player, getPlayerName(player), "invisible", tostring(state))
end)

addCommandHandler("noclip", function(player)
    if not checkPerm(player, "noclip") then return end
    local state = not getElementData(player, "admin:noclip")
    AdminSetNoClip(player, state)
    AdminLog(player, getPlayerName(player), "noclip", tostring(state))
end)

addCommandHandler("fly", function(player)
    if not checkPerm(player, "fly") then return end
    local state = not getElementData(player, "admin:fly")
    AdminSetFly(player, state)
    AdminLog(player, getPlayerName(player), "fly", tostring(state))
end)

addCommandHandler("god", function(player)
    if not checkPerm(player, "god") then return end
    local state = not getElementData(player, "admin:god")
    AdminSetGod(player, state)
    AdminLog(player, getPlayerName(player), "god", tostring(state))
end)

addCommandHandler("giveitem", function(player, _, name, item, amount)
    if not checkPerm(player, "giveitem") then return end
    local target = findPlayer(player, name)
    if not target then return end
    local ok = AdminGiveItem(target, item, tonumber(amount) or 1)
    if ok then AdminLog(player, getPlayerName(target), "giveitem", tostring(item) .. " x" .. tostring(amount or 1)) end
end)

addCommandHandler("givemoney", function(player, _, name, amount)
    if not checkPerm(player, "givemoney") then return end
    local target = findPlayer(player, name)
    if not target then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount > 0 then
        AdminAddMoney(target, amount)
        AdminLog(player, getPlayerName(target), "givemoney", AdminFormatMoney(amount))
    end
end)

addCommandHandler("givecar", function(player, _, name, model)
    if not checkPerm(player, "givevehicle") then return end
    local target = findPlayer(player, name)
    if not target then return end
    local ok = AdminGiveVehicle(target, tonumber(model))
    if ok then AdminLog(player, getPlayerName(target), "givevehicle", tostring(model)) end
end)

addCommandHandler("cv", function(player, _, model)
    if not checkPerm(player, "givevehicle") then return end
    model = tonumber(model)
    if not model then
        AdminNotify(player, "Kullanım: /cv <araç id>", "error")
        return
    end

    local ok = AdminGiveVehicle(player, model)
    if ok then
        AdminLog(player, getPlayerName(player), "createvehicle", tostring(model))
    else
        AdminNotify(player, "Araç oluşturulamadı. Geçerli bir araç ID'si girin.", "error")
    end
end)

addCommandHandler("dv", function(player)
    if not checkPerm(player, "deletevehicle") then return end
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        AdminNotify(player, "Silmek için bir aracın içinde olmalısınız.", "error")
        return
    end

    destroyElement(vehicle)
    AdminNotify(player, "Bindiğiniz araç silindi.", "success")
    AdminLog(player, getPlayerName(player), "deletevehicle", "current")
end)

addCommandHandler("dva", function(player)
    if not checkPerm(player, "deleteallvehicles") then return end
    if not AdminStartVehicleCleanup() then
        AdminNotify(player, "Araç temizliği zaten geri sayımda.", "warning")
        return
    end

    AdminNotify(player, "Boş araç temizliği için 30 saniyelik geri sayım başladı.", "success")
    AdminLog(player, getPlayerName(player), "deleteallvehicles", "countdown")
end)
addCommandHandler("noon", function(player)
	if not isAdmin(player) then
		outputChatBox("Bu komutu kullanma yetkin yok.", player, 255, 70, 70)
		return
	end
	setTime(12, 0)
	outputChatBox("Saat 12:00 olarak ayarlandı.", player, 90, 220, 140)
end)

addCommandHandler("night", function(player)
	if not isAdmin(player) then
		outputChatBox("Bu komutu kullanma yetkin yok.", player, 255, 70, 70)
		return
	end
	setTime(0, 0)
	outputChatBox("Saat 00:00 olarak ayarlandı.", player, 90, 220, 140)
end) 
