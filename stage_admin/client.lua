local open, players = false, {}
local function inside(x,y,w,h)
    if not isCursorShowing() then return false end
    local mx,my=getCursorPosition(); local sx,sy=guiGetScreenSize(); if not mx then return false end
    mx,my=mx*sx,my*sy; return mx>=x and mx<=x+w and my>=y and my<=y+h
end
addEvent("stage_admin:open",true)
addEventHandler("stage_admin:open",root,function() open=true; showCursor(true); triggerServerEvent("stage_admin:request",localPlayer) end)
addEvent("stage_admin:data",true)
addEventHandler("stage_admin:data",root,function(data) players=data or {} end)
addEventHandler("onClientRender",root,function()
    if not open then return end
    local sw,sh=guiGetScreenSize(); local w,h=math.min(1280,sw*.82),math.min(720,sh*.82); local x,y=(sw-w)/2,(sh-h)/2
    dxDrawRectangle(0,0,sw,sh,tocolor(0,0,0,120)); dxDrawRectangle(x,y,w,h,tocolor(12,15,18,245)); dxDrawRectangle(x+20,y+20,w-40,2,tocolor(35,190,170,255))
    dxDrawText("STAGE GAMING",x+32,y+30,x+w*.6,y+72,tocolor(245,245,245),1.35,"default-bold","left","center"); dxDrawText("ADMIN PANEL",x+32,y+72,x+w*.6,y+102,tocolor(145,155,165),.9,"default-bold","left","center")
    dxDrawText("X",x+w-60,y+28,x+w-25,y+68,tocolor(245,245,245),1.2,"default-bold","center","center")
    dxDrawText("Oyuncular",x+35,y+130,x+w*.55,y+160,tocolor(220,225,230),1,"default-bold","left","center")
    for i,p in ipairs(players) do if i>12 then break end local ry=y+170+(i-1)*38; dxDrawRectangle(x+32,ry,w*.52,32,tocolor(25,29,34,235)); dxDrawText(p.name,x+45,ry,x+w*.4,ry+32,tocolor(240,240,240),.85,"default-bold","left","center"); dxDrawText("ID: "..tostring(p.id),x+w*.42,ry,x+w*.52,ry+32,tocolor(145,155,165),.8,"default","right","center") end
    dxDrawText("Depolar, teleport ve item yönetimi bu panel sekmelerine bağlanacak.",x+w*.60,y+165,x+w-35,y+220,tocolor(150,160,170),.9,"default","left","top",true)
end)
addEventHandler("onClientClick",root,function(btn,state)
    if not open or btn~="left" or state~="up" then return end
    local sw,sh=guiGetScreenSize(); local w,h=math.min(1280,sw*.82),math.min(720,sh*.82); local x,y=(sw-w)/2,(sh-h)/2
    if inside(x+w-70,y+15,60,60) then open=false; showCursor(false); cancelEvent() end
end)
bindKey("escape","down",function() if open then open=false; showCursor(false); cancelEvent() end end)
