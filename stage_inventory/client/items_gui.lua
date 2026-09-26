-- Modern DX /items admin panel
local itemsOpen, selectedId, itemList, amount, scrollOffset = false, nil, {}, 1, 0
local itemHits, buttonHits, texCache = {}, {}, {}
local rounded = {}
local function roundBox(id,x,y,w,h,r,color)
    rounded[id]=rounded[id] or {}
    if not isElement(rounded[id][w]) then
        local svg=string.format('<svg width="%d" height="%d"><rect width="%d" height="%d" rx="%d" fill="#fff"/></svg>',w,h,w,h,math.min(r,math.floor(math.min(w,h)/2)))
        local ok,e=pcall(svgCreate,w,h,svg); rounded[id][w]=ok and e or false
    end
    if rounded[id][w] then dxDrawImage(x,y,w,h,rounded[id][w],0,0,0,color) else dxDrawRectangle(x,y,w,h,color) end
end
local function getIcon(path)
    if not path then return nil end
    if texCache[path] == nil then local ok, t = pcall(dxCreateTexture, "assets/items/" .. path); texCache[path] = ok and t or false end
    return texCache[path] ~= false and texCache[path] or nil
end
local function inside(x,y,w,h)
    if not isCursorShowing() then return false end
    local mx,my = getCursorPosition(); local sx,sy = guiGetScreenSize(); if not mx then return false end
    mx,my=mx*sx,my*sy; return mx>=x and mx<=x+w and my>=y and my<=y+h
end
local function closeItems() itemsOpen=false; selectedId=nil; itemHits={}; buttonHits={}; showCursor(false); guiSetInputEnabled(false) end
function openItemsGUI()
    if itemsOpen then return end
    itemList={}; for id,d in pairs(Items or {}) do itemList[#itemList+1]={id=id,d=d} end
    table.sort(itemList,function(a,b) return (a.d.label or a.id)<(b.d.label or b.id) end)
    selectedId=itemList[1] and itemList[1].id; amount=1; scrollOffset=0; itemsOpen=true; showCursor(true); guiSetInputEnabled(false)
end
addEventHandler("onClientRender",root,function()
    if not itemsOpen then return end
    local sw,sh=guiGetScreenSize(); local w,h=math.min(1240,sw*.82),math.min(680,sh*.8); local x,y=(sw-w)/2,(sh-h)/2
    local left=w*.31; itemHits={}; buttonHits={}
    dxDrawRectangle(0,0,sw,sh,tocolor(0,0,0,115)); roundBox("panel",x,y,w,h,16,tocolor(12,14,17,242)); dxDrawRectangle(x+18,y,w-36,2,tocolor(35,190,170,255))
    dxDrawText("STAGE GAMING",x+28,y+18,x+left,y+48,tocolor(245,245,245),1.2,"default-bold","left","center"); dxDrawText("ITEM YÖNETİMİ",x+28,y+48,x+left,y+72,tocolor(140,150,160),.85,"default-bold","left","center")
    dxDrawText("X",x+w-48,y+16,x+w-18,y+50,tocolor(245,245,245),1.15,"default-bold","center","center"); buttonHits.close={x=x+w-56,y=y+12,w=44,h=44}
    local visible=9
    for row=1,visible do
        local i=row+scrollOffset; local e=itemList[i]
        if not e then break end
        local ry=y+92+(row-1)*64; local sel=e.id==selectedId
        roundBox("row"..i,x+18,ry,left-36,58,8,sel and tocolor(25,92,86,235) or tocolor(22,25,29,225)); local t=getIcon(e.d.image); if t then dxDrawImage(x+26,ry+9,40,40,t) end
        dxDrawText(e.d.label or e.id,x+78,ry+7,x+left-25,ry+31,tocolor(240,242,245),.98,"default-bold","left","center")
        dxDrawText(string.format("%.2f kg  •  %s",e.d.weight or 0,e.d.category or "item"),x+78,ry+30,x+left-25,ry+52,tocolor(145,155,165),.76,"default","left","center")
        itemHits[i]={x=x+18,y=ry,w=left-36,h=58,id=e.id}
    end
    local d=selectedId and Items[selectedId]; local dx0=x+left+26; local dw=w-left-52
    if d then
        dxDrawText(d.label or selectedId,dx0,y+96,dx0+dw,y+136,tocolor(245,245,245),1.45,"default-bold","center","center")
        dxDrawText(d.description or "",dx0,y+138,dx0+dw,y+164,tocolor(150,160,170),.9,"default","center","center")
        local t=getIcon(d.image); if t then dxDrawImage(dx0+dw/2-95,y+185,190,190,t) end
        dxDrawText(string.format("Ağırlık: %.2f kg",d.weight or 0),dx0,y+397,dx0+dw,y+424,tocolor(220,225,230),1,"default-bold","center","center")
        dxDrawText("Kategori: "..tostring(d.category or "item"),dx0,y+430,dx0+dw,y+453,tocolor(145,155,165),.88,"default","center","center")
    end
    local by=y+h-76
    local function btn(k,label,bx,bw,col) roundBox("btn"..k,bx,by,bw,43,9,col); dxDrawText(label,bx,by,bx+bw,by+43,tocolor(245,245,245),.95,"default-bold","center","center"); buttonHits[k]={x=bx,y=by,w=bw,h=43} end
    btn("minus","-",dx0,52,tocolor(48,52,58,255)); dxDrawText(tostring(amount),dx0+52,by,dx0+112,by+43,tocolor(245,245,245),1.05,"default-bold","center","center"); btn("plus","+",dx0+112,52,tocolor(48,52,58,255)); btn("give","ENVANTERE EKLE",dx0+190,205,tocolor(24,125,105,255)); btn("cancel","KAPAT",dx0+410,120,tocolor(53,56,61,255))
end)
addEventHandler("onClientKey",root,function(key,press)
    if not itemsOpen or not press then return end
    if key=="mouse_wheel_down" then scrollOffset=math.min(math.max(0,#itemList-9),scrollOffset+1)
    elseif key=="mouse_wheel_up" then scrollOffset=math.max(0,scrollOffset-1) end
end)
addEventHandler("onClientClick",root,function(btn,state)
    if not itemsOpen or btn~="left" or state~="up" then return end
    for _,hit in pairs(itemHits) do if inside(hit.x,hit.y,hit.w,hit.h) then selectedId=hit.id return end end
    if buttonHits.close and inside(buttonHits.close.x,buttonHits.close.y,buttonHits.close.w,buttonHits.close.h) then closeItems() return end
    if buttonHits.minus and inside(buttonHits.minus.x,buttonHits.minus.y,buttonHits.minus.w,buttonHits.minus.h) then amount=math.max(1,amount-1) return end
    if buttonHits.plus and inside(buttonHits.plus.x,buttonHits.plus.y,buttonHits.plus.w,buttonHits.plus.h) then amount=math.min(1000,amount+1) return end
    if buttonHits.give and inside(buttonHits.give.x,buttonHits.give.y,buttonHits.give.w,buttonHits.give.h) and selectedId then triggerServerEvent("inv:adminGive",localPlayer,selectedId,amount) return end
    if buttonHits.cancel and inside(buttonHits.cancel.x,buttonHits.cancel.y,buttonHits.cancel.w,buttonHits.cancel.h) then closeItems() end
end)
addCommandHandler("items",openItemsGUI)
addEvent("inv:openItems",true); addEventHandler("inv:openItems",root,openItemsGUI)
