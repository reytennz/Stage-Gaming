local open=false
local settings={}
local names={speed="Speed Hack",fly="Fly / Air Walk",teleport="Teleport Hack",superjump="Super Jump",vehicleFly="Vehicle Fly",rapidFire="Rapid Fire",illegalWeapon="Illegal Weapon",health="Health Hack",armor="Armor Hack",eventSpam="Event / Spam Protection",damage="Damage Anomaly",illegalVehicle="Illegal Vehicle"}
local order={"speed","fly","teleport","superjump","vehicleFly","rapidFire","illegalWeapon","health","armor","eventSpam","damage","illegalVehicle"}
local sx,sy=guiGetScreenSize()
local function markF1Teleport() if localPlayer then triggerServerEvent("stageAC:f1Teleport",localPlayer) end end
setTimer(function()
    if type(setPlayerPosition)=="function" and not _G.__stageACWrapped then
        _G.__stageACWrapped=true; local original=setPlayerPosition
        _G.setPlayerPosition=function(x,y,z) markF1Teleport(); return original(x,y,z) end
    end
end,1500,0)

addEvent("stageAC:settings",true)
addEventHandler("stageAC:settings",root,function(s) settings=s end)
addCommandHandler("anticheat",function()
    open=not open
    showCursor(open)
    if open then triggerServerEvent("stageAC:getSettings",localPlayer) end
end)

addEventHandler("onClientRender",root,function()
    if not open then return end
    local w,h=500,590; local x=(sx-w)/2; local y=(sy-h)/2
    dxDrawRectangle(x,y,w,h,tocolor(15,17,23,245)); dxDrawText("STAGE GAMING • ANTICHEAT",x+20,y+18,x+w,y+50,tocolor(255,255,255),1.2,"default-bold")
    dxDrawText("Özellikleri tıklayarak aç/kapat • risk/5 tespit = 10 dk ban",x+20,y+48,x+w,y+70,tocolor(180,185,195),1,"default")
    for i,key in ipairs(order) do
        local yy=y+82+(i-1)*39; local on=settings[key]~=false
        dxDrawRectangle(x+20,yy,w-40,31,tocolor(30,33,42,255))
        dxDrawRectangle(x+28,yy+7,17,17,on and tocolor(60,190,100,255) or tocolor(190,70,70,255))
        dxDrawText(on and "AÇIK" or "KAPALI",x+52,yy+6,x+120,yy+27,on and tocolor(100,230,130) or tocolor(240,110,110),1,"default-bold")
        dxDrawText(names[key],x+130,yy+6,x+w-30,yy+27,tocolor(235,235,240),1,"default")
    end
    dxDrawText("/anticheat • Kapatmak için tekrar yaz",x+20,y+h-28,x+w,y+h-8,tocolor(150,155,165),1,"default")
end)

addEventHandler("onClientClick",root,function(btn,state,cx,cy)
    if not open or btn~="left" or state~="up" then return end
    local w,h=500,590; local x=(sx-w)/2; local y=(sy-h)/2
    for i,key in ipairs(order) do
        local yy=y+82+(i-1)*39
        if cx>=x+20 and cx<=x+w-20 and cy>=yy and cy<=yy+31 then
            triggerServerEvent("stageAC:setSetting",localPlayer,key,settings[key]~=true)
            settings[key]=settings[key]~=true
            return
        end
    end
end)
