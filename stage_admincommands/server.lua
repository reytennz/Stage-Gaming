local commandRows = {
	{ resource = "stage_admin", command = "acsensitivity" },
	{ resource = "stage_admin", command = "setrank" },
	{ resource = "stage_admin", command = "myrank" },
	{ resource = "stage_admin", command = "kick" },
	{ resource = "stage_admin", command = "ban" },
	{ resource = "stage_admin", command = "warn" },
	{ resource = "stage_admin", command = "goto" },
	{ resource = "stage_admin", command = "gethere" },
	{ resource = "stage_admin", command = "tp" },
	{ resource = "stage_admin", command = "freeze" },
	{ resource = "stage_admin", command = "unfreeze" },
	{ resource = "stage_admin", command = "invisible" },
	{ resource = "stage_admin", command = "noclip" },
	{ resource = "stage_admin", command = "fly" },
	{ resource = "stage_admin", command = "god" },
	{ resource = "stage_admin", command = "giveitem" },
	{ resource = "stage_admin", command = "givemoney" },
	{ resource = "stage_admin", command = "givecar" },
	{ resource = "stage_admin", command = "cv" },
	{ resource = "stage_admin", command = "dv" },
	{ resource = "stage_admin", command = "dva" },
	{ resource = "stage_admin", command = "stageadmin" },
	{ resource = "stage_admin", command = "adminpanel" },
	{ resource = "stage_admin", command = "a" },
	{ resource = "stage_admincommands", command = "admincommands" },
	{ resource = "stage_admincommands", command = "noon" },
	{ resource = "stage_admincommands", command = "night" },
	{ resource = "stage_anticheat", command = "anticheat" },
	{ resource = "stage_f1", command = "fr" },
	{ resource = "stage_f1", command = "stopanim" },
	{ resource = "stage_f1", command = "anim" },
	{ resource = "stage_f1", command = "otur" },
	{ resource = "stage_f1", command = "setstyle" },
	{ resource = "stage_f1", command = "addclothes" },
	{ resource = "stage_f1", command = "ac" },
	{ resource = "stage_f1", command = "removeclothes" },
	{ resource = "stage_f1", command = "rc" },
	{ resource = "stage_f1", command = "setweather" },
	{ resource = "stage_f1", command = "sw" },
	{ resource = "stage_f1", command = "devmode" },
	{ resource = "stage_f1", command = "jetpack" },
	{ resource = "stage_f1", command = "jp" },
	{ resource = "stage_f1", command = "getpos" },
	{ resource = "stage_f1", command = "gp" },
	{ resource = "stage_f1", command = "setpos" },
	{ resource = "stage_f1", command = "sp" },
	{ resource = "stage_f1", command = "repair" },
	{ resource = "stage_f1", command = "rp" },
	{ resource = "stage_f1", command = "flip" },
	{ resource = "stage_f1", command = "f" },
	{ resource = "stage_f1", command = "color" },
	{ resource = "stage_f1", command = "cl" },
	{ resource = "stage_f1", command = "paintjob" },
	{ resource = "stage_f1", command = "pj" },
	{ resource = "stage_f1", command = "saat" },
	{ resource = "stage_f1", command = "st" },
	{ resource = "stage_f1", command = "kill" },
	{ resource = "stage_f1", command = "f1about" },
	{ resource = "stage_f1", command = "f1meslek" },
	{ resource = "stage_f1", command = "f1ayar" },
	{ resource = "stage_f1", command = "f1sahibinden" },
	{ resource = "stage_f1", command = "f1air" },
	{ resource = "stage_f1", command = "f1siralama" },
	{ resource = "stage_f1", command = "stok" },
	{ resource = "stage_f1", command = "stokekle" },
	{ resource = "stage_f1", command = "stokayar" },
	{ resource = "stage_f1", command = "stokfiyat" },
	{ resource = "stage_f1", command = "stokisim" },
	{ resource = "stage_f1", command = "hd" },
	{ resource = "stage_gasstation", command = "benzinlikler" },
	{ resource = "stage_gasstation", command = "benzinlik" },
	{ resource = "stage_inventory", command = "depoolustur" },
	{ resource = "stage_inventory", command = "depolar" },
	{ resource = "stage_inventory", command = "items" },
	{ resource = "stage_inventory", command = "inventory" },
	{ resource = "stage_inventory", command = "clearinv" },
	{ resource = "stage_loading", command = "login" },
	{ resource = "stage_loading", command = "resetstats" },
	{ resource = "stage_mobilya", command = "editor" },
	{ resource = "stage_mobilya", command = "mobilya" },
	{ resource = "stage_mobilya", command = "duvarkagidi" },
	{ resource = "stage_phone", command = "telefon" },
	{ resource = "stage_sinema", command = "cinema" },
	{ resource = "stage_sinema", command = "stopcinema" },
	{ resource = "stage_sinema", command = "cinemainfo" },
	{ resource = "stage_vehicle_shop", command = "aracpanel" },
}

local function isAdmin(player)
	local core = getResourceFromName("stage_core")
	if core and getResourceState(core) == "running" then
		local ok, result = pcall(function() return exports.stage_core:IsAdmin(player) end)
		if ok then return result == true end
	end
	return hasObjectPermissionTo(player, "function.kickPlayer", false)
end

addEvent("stage_admincommands:request", true)
addEventHandler("stage_admincommands:request", root, function()
	if not isAdmin(client) then return end
	triggerClientEvent(client, "stage_admincommands:open", resourceRoot, commandRows)
end)

addCommandHandler("admincommands", function(player)
	if not isAdmin(player) then
		outputChatBox("Bu komutu kullanma yetkin yok.", player, 255, 70, 70)
		return
	end
	triggerClientEvent(player, "stage_admincommands:open", resourceRoot, commandRows)
end)

