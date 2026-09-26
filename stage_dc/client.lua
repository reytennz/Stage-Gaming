local app_id = "1538981362806169742"
if setDiscordApplicationID(app_id) then 

    setDiscordRichPresenceAsset("dcresim","Stage Gaming")
    setDiscordRichPresenceState("Owner By Reytennz") 
    setDiscordRichPresenceButton(1, "Sunucuya Bağlan", "mtasa://185.158.151.71:22003")
    setDiscordRichPresenceButton(2, "Discord Katıl ", "https://discord.gg/uD8wgksEGA")
	
    outputChatBox("Discord ile bağlantı kuruludu!")

end