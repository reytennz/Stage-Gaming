addEvent("furniture:takeMoney",true)
addEventHandler("furniture:takeMoney",root,function(player,money)
	-- Standalone: MTA'nın kendi nakit sistemi kullanılıyor (export yok)
	if getPlayerMoney(player) < money then return end
	takePlayerMoney(player, money)
	outputChatBox("[!]#ffffff Tebrikler, başarıyla mobilyayı satın aldınız!",player,0,255,0,true)
end)