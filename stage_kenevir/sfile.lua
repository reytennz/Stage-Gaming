-- KENEVİR SİSTEMİ - SERVER (FIXED & ALIGNED)
local normalFiyat = 35000
local kenevirItemID = "kenevir" 

-- HANGAR KÖŞELERİ
local hangarKoseleri = {
    {-292.54974, -2151.90186, 28.58743},
    {-264.60464, -2144.79565, 28.95549},
    {-259.97311, -2163.19165, 29.02292},
    {-287.80783, -2170.20581, 28.66292},
}

-- Hangar Toplama Alanı
toplamaAlani = createColPolygon(
    hangarKoseleri[1][1], hangarKoseleri[1][2],
    hangarKoseleri[2][1], hangarKoseleri[2][2],
    hangarKoseleri[3][1], hangarKoseleri[3][2],
    hangarKoseleri[4][1], hangarKoseleri[4][2]
)

-- Satış Noktası: Client ile tam aynı koordinata alındı (-247.72949, -2225.23242, 28)
local saleX, saleY, saleZ = -247.72949, -2225.23242, 28
satmarker = createMarker(saleX, saleY, saleZ - 1, "cylinder", 3.5, 255, 20, 20, 0)
local satCol = createColSphere(saleX, saleY, saleZ, 3.5)

-- [KOMUT] 2x Etkinliğini Başlat
addCommandHandler("2xkenevir", function(thePlayer)
    local isAdmin = false
    local adminLevel = getElementData(thePlayer, "admin_level") or getElementData(thePlayer, "adminlevel") or 0
    if tonumber(adminLevel) and tonumber(adminLevel) >= 1 then isAdmin = true end

    local hesap = getPlayerAccount(thePlayer)
    if hesap and not isGuestAccount(hesap) then
        local accName = getAccountName(hesap)
        if isObjectInACLGroup("user."..accName, aclGetGroup("Admin")) then
            isAdmin = true
        end
    end

    if isAdmin then
        setElementData(root, "kenevir:etkinlik", true)
        outputChatBox("[Stage Gaming] #00ff00Kenevir 2x Etkinliği Başlatıldı! Tüm satışlar 70.000 TL!", root, 255, 255, 255, true)
    else
        outputChatBox("[!] #ffffffBu komutu sadece yetkililer kullanabilir.", thePlayer, 255, 0, 0, true)
    end
end)

-- [KOMUT] 2x Etkinliğini Kapat
addCommandHandler("2xkenevirkapat", function(thePlayer)
    local isAdmin = false
    local adminLevel = getElementData(thePlayer, "admin_level") or getElementData(thePlayer, "adminlevel") or 0
    if tonumber(adminLevel) and tonumber(adminLevel) >= 1 then isAdmin = true end

    local hesap = getPlayerAccount(thePlayer)
    if hesap and not isGuestAccount(hesap) then
        local accName = getAccountName(hesap)
        if isObjectInACLGroup("user."..accName, aclGetGroup("Admin")) then
            isAdmin = true
        end
    end

    if isAdmin then
        setElementData(root, "kenevir:etkinlik", false)
        outputChatBox("[Stage Gaming] #ff0000Kenevir 2x etkinliği sona erdi. Fiyatlar normale döndü.", root, 255, 255, 255, true)
    else
        outputChatBox("[!] #ffffffBu komutu sadece yetkililer kullanabilir.", thePlayer, 255, 0, 0, true)
    end
end)

function kenevir_gir(thePlayer)
    if not isElement(thePlayer) or isPedInVehicle(thePlayer) then return end
    if getElementData(thePlayer, "bind:engel") then return end
    if getElementData(thePlayer, "dead") == 1 then return end
    
    -- HANGARIN İÇİNDE HERHANGİ BİR YERDEYSE -> TOPLAMA
    if isElementWithinColShape(thePlayer, toplamaAlani) then
        setElementFrozen(thePlayer, true)    
        setPedAnimation(thePlayer, "bomber", "bom_plant_loop", -1, true, false, false, false)
        setElementData(thePlayer, "kenevir:tur", "toplama")
        setElementData(thePlayer, "kenevir:top", true)
        setElementData(thePlayer, "bind:engel", true)
        triggerClientEvent(thePlayer, "kenevir:toplama", thePlayer, 10000)
        
    -- SATIŞ ALANINDA İSE -> SATMA
    elseif isElementWithinColShape(thePlayer, satCol) or isElementWithinMarker(thePlayer, satmarker) then
        local has = exports["stage_inventory"]:hasItem(thePlayer, kenevirItemID) or exports["stage_inventory"]:hasItem(thePlayer, 12)
        if has then
            setPedAnimation(thePlayer, "bomber", "bom_plant_loop", -1, true, false, false, false)
            setElementData(thePlayer, "kenevir:tur", "satma")
            setElementData(thePlayer, "kenevir:top", true)
            setElementData(thePlayer, "bind:engel", true)
            triggerClientEvent(thePlayer, "kenevir:toplama", thePlayer, 5000)
        else
            outputChatBox("[!] #ffffffÜzerinde satacak kenevir yok.", thePlayer, 255, 0, 0, true)
        end
    end
end

function kenevir_ver(thePlayer)
    if client ~= source then return end
    if not isElement(thePlayer) then return end
    if getElementData(thePlayer, "kenevir:islemde") then return end
    setElementData(thePlayer, "kenevir:islemde", true)

    local tur = getElementData(thePlayer, "kenevir:tur")
    if tur == "toplama" then
        setElementFrozen(thePlayer, false)
        setPedAnimation(thePlayer, nil)
        setElementData(thePlayer, "bind:engel", false)
        setElementData(thePlayer, "kenevir:top", false)
        
        local given = false
        if exports.stage_inventory and exports.stage_inventory.giveItem then
            given = exports.stage_inventory:giveItem(thePlayer, kenevirItemID, 1) or exports.stage_inventory:giveItem(thePlayer, "kenevir", 1) or exports.stage_inventory:giveItem(thePlayer, 12, 1)
        end

        if given then
            outputChatBox("[+] #ffffffBir adet taze kenevir topladın.", thePlayer, 0, 255, 0, true)
        else
            outputChatBox("[!] #ffffffEnvanterin dolu veya işlem başarısız!", thePlayer, 255, 0, 0, true)
        end
    elseif tur == "satma" then
        setElementFrozen(thePlayer, false)
        setPedAnimation(thePlayer, nil)
        setElementData(thePlayer, "bind:engel", false)
        setElementData(thePlayer, "kenevir:top", false)
        
        local count = 0
        if exports.stage_inventory and exports.stage_inventory.getItemCount then
            count = exports.stage_inventory:getItemCount(thePlayer, kenevirItemID) or 0
            if count <= 0 then count = exports.stage_inventory:getItemCount(thePlayer, "kenevir") or 0 end
            if count <= 0 then count = exports.stage_inventory:getItemCount(thePlayer, 12) or 0 end
        end

        if count and count > 0 then
            local taken = false
            if exports.stage_inventory and exports.stage_inventory.takeItem then
                taken = exports.stage_inventory:takeItem(thePlayer, kenevirItemID, count) or exports.stage_inventory:takeItem(thePlayer, "kenevir", count) or exports.stage_inventory:takeItem(thePlayer, 12, count)
            end
            
            if taken then
                local aktifFiyat = normalFiyat
                if getElementData(root, "kenevir:etkinlik") then aktifFiyat = normalFiyat * 2 end
                local toplamPara = count * aktifFiyat
                
                -- Parayı doğrudan güvenli bir şekilde ekle
                if exports.stage_economy and exports.stage_economy.AddCash then
                    exports.stage_economy:AddCash(thePlayer, toplamPara)
                elseif exports.stage_core and exports.stage_core.AddMoney then
                    exports.stage_core:AddMoney(thePlayer, toplamPara, "Kenevir Satışı")
                else
                    givePlayerMoney(thePlayer, toplamPara)
                    setElementData(thePlayer, "money", getPlayerMoney(thePlayer), true)
                end
                
                outputChatBox("[+] #ffffff" .. count .. " adet kenevir sattın. Kazanç: #00ff00$" .. tostring(toplamPara), thePlayer, 255, 255, 255, true)
            end
        else
            outputChatBox("[!] #ffffffÜzerinde satacak kenevir yok.", thePlayer, 255, 0, 0, true)
        end
    end
    setElementData(thePlayer, "kenevir:islemde", false)
end
addEvent("kenevir:ver", true)
addEventHandler("kenevir:ver", root, kenevir_ver)

-- ALAN GİRİŞ ÇIKIŞLARI
addEventHandler("onColShapeHit", toplamaAlani, function(p)
    if getElementType(p) == "player" then
        setElementData(p, "kenevir:e", true)
        setElementData(p, "kenevir:tur", "toplama")
    end
end)
addEventHandler("onColShapeLeave", toplamaAlani, function(p)
    if getElementType(p) == "player" then
        setElementData(p, "kenevir:e", false)
        setElementData(p, "kenevir:tur", false)
    end
end)
addEventHandler("onColShapeHit", satCol, function(p)
    if getElementType(p) == "player" then
        setElementData(p, "kenevir:e", true)
        setElementData(p, "kenevir:tur", "satma")
    end
end)
addEventHandler("onColShapeLeave", satCol, function(p)
    if getElementType(p) == "player" then
        setElementData(p, "kenevir:e", false)
        setElementData(p, "kenevir:tur", false)
    end
end)

function kenevirbindsoygun()
    local players = getElementsByType("player")
    for k, arrayPlayer in ipairs(players) do
        bindKey(arrayPlayer, "e", "down", kenevir_gir)
    end
end
addEventHandler("onResourceStart", getResourceRootElement(), kenevirbindsoygun)
addEventHandler("onPlayerJoin", root, function() bindKey(source, "e", "down", kenevir_gir) end)
