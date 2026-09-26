----------------------
-----Panel Boyutu-----
----------------------
sC2,sD2 = guiGetScreenSize()
C2, D2 = 310, 230
A2 = (sC2/2) - (C2/2)
B2 = (sD2/2) - (D2/2)
---------------
-----Panel-----
---------------
panellag = guiCreateWindow(A2, B2, C2, D2,"AntiLag Paneli", false)
guiSetVisible(panellag, false)

grs = guiCreateScrollBar(33, 49, 244, 25, true, false, panellag)
guiScrollBarSetScrollPosition(grs,50)
grslabel = guiCreateLabel(96, 29, 132, 15, "Görüş Mesafesi:", false, panellag)
guiSetFont(grslabel, "default-bold-small")

sis = guiCreateScrollBar(33, 98, 244, 25, true, false, panellag)
guiScrollBarSetScrollPosition(sis,50)
sislabel = guiCreateLabel(106, 79, 116, 16, "Sis Mesafesi:", false, panellag)
guiSetFont(sislabel, "default-bold-small")

art1 = guiCreateLabel(283, 52, 16, 15, "+", false, panellag)
art2 = guiCreateLabel(283, 101, 16, 15, "+", false, panellag)
guiSetFont(art1, "default-bold-small")
guiSetFont(art2, "default-bold-small")

az1 = guiCreateLabel(22, 51, 15, 15, "-", false, panellag)
az2 = guiCreateLabel(22, 100, 15, 15, "-", false, panellag)
guiSetFont(az1, "default-bold-small")
guiSetFont(az2, "default-bold-small")

bilgilabel = guiCreateLabel(25, 130, 288, 39, "Ayarları düşürdükçe FPS seviyeniz artacaktır.", false, panellag)
guiSetFont(bilgilabel, "default-bold-small")
guiLabelSetColor(bilgilabel, 34, 177, 76)

kapatlag = guiCreateButton(130, 200, 175, 25, "Kapat", false, panellag)
-----------------------------------------------------------------------------------------

addEventHandler("onClientGUIScroll", guiRoot,
function ()
if source == grs then
local vis = guiScrollBarGetScrollPosition(grs)
if vis == 100 then
setFarClipDistance( 3000 )
end
if vis == 0 then
setFarClipDistance( 50 )
          end                   
if vis == 10 then
setFarClipDistance( 300 )
          end  
if vis == 20 then
setFarClipDistance( 400 )
          end  
if vis == 30 then
setFarClipDistance( 500 )
          end  
if vis == 40 then
setFarClipDistance( 600 )
          end  
if vis == 50 then
setFarClipDistance( 700 )
          end  
if vis == 60 then
setFarClipDistance( 800 )
          end  
if vis == 70 then
setFarClipDistance( 900 )
          end  
if vis == 80 then
setFarClipDistance( 1000 )
          end       
if vis == 90 then
setFarClipDistance( 2000 )
          end                                  
     end
end
)


addEventHandler("onClientGUIScroll", guiRoot,
function ()
if source == sis then
local nie = guiScrollBarGetScrollPosition(sis)
if nie == 100 then
setFogDistance( 50 )
          end
if nie == 0 then
setFogDistance( 0 )
          end              
if nie == 10 then
setFogDistance( 5 )
          end
if nie == 20 then
setFogDistance( 10 )
          end  
if nie == 30 then
setFogDistance( 15 )
          end
if nie == 40 then
setFogDistance( 20 )
          end
if nie == 50 then
setFogDistance( 25 )
          end
if nie == 60 then
setFogDistance( 30 )
          end
if nie == 70 then
setFogDistance( 35 )
          end
if nie == 80 then
setFogDistance( 40 )
          end  
if nie == 90 then
setFogDistance( 45 )
          end                             
     end
end
)

-----------------------------------------------------------------------------------------

function LagSistemiAc()
if guiGetVisible(panellag) == false then
guiSetVisible(panellag, true)
else
guiSetVisible(panellag, false)
end
end
----------------------
-----Paneli Kapat-----
----------------------
addEventHandler("onClientGUIClick", root,
function()
if source == kapatlag then
guiSetVisible(panellag, false)
end
end)
-------------------------
-----Paneli Aç/Kapat-----
-------------------------
function ackapat()
if (guiGetVisible (panellag) == true) then
guiSetVisible(panellag, false)
end
end
bindKey("F1", "down", ackapat)