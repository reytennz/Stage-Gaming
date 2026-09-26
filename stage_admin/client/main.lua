--[[
    stage_admin - client main
]]

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("[Stage Admin] Client script yüklendi. Panel: " .. Config.PanelKey .. " (yedek komut: /adminpanel) | Report: " .. Config.ReportKey, 90, 170, 240)
end)
