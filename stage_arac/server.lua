-- ============================================
-- 4 Kapılı Araç Spawn Sistemi (DEBUG)
-- ============================================

local araclar = {
    [1]  = {model = 400, isim = "Landstalker"},
    [2]  = {model = 401, isim = "Bravura"},
    [3]  = {model = 404, isim = "Perennial"},
    [4]  = {model = 405, isim = "Sentinel"},
    [5]  = {model = 409, isim = "Stretch"},
    [6]  = {model = 419, isim = "Esperanto"},
    [7]  = {model = 420, isim = "Taxi"},
    [8]  = {model = 421, isim = "Washington"},
    [9]  = {model = 426, isim = "Premier"},
    [10] = {model = 438, isim = "Cabbie"},
    [11] = {model = 442, isim = "Romero"},
    [12] = {model = 454, isim = "Glendale"},
    [13] = {model = 455, isim = "Sultan"},
    [14] = {model = 456, isim = "Solair"},
    [15] = {model = 458, isim = "Beverly"},
    [16] = {model = 467, isim = "Oceanic"},
    [17] = {model = 470, isim = "Patriot"},
    [18] = {model = 479, isim = "Regina"},
    [19] = {model = 491, isim = "Rancher"},
    [20] = {model = 492, isim = "Greenwood"},
    [21] = {model = 507, isim = "Elegant"},
    [22] = {model = 529, isim = "Willard"},
    [23] = {model = 540, isim = "Vincent"},
    [24] = {model = 542, isim = "Clover"},
    [25] = {model = 546, isim = "Intruder"},
    [26] = {model = 547, isim = "Primo"},
    [27] = {model = 550, isim = "Sunrise"},
    [28] = {model = 551, isim = "Merit"},
    [29] = {model = 445, isim = "Admiral"},
}

addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog("[ARAC] Resource başladı. Toplam araç: " .. tostring(#araclar))
end)

-- /arac [1-29]
addCommandHandler("arac", function(player, cmd, id)
    outputChatBox("[DEBUG] Komut geldi. id = " .. tostring(id), player, 255, 255, 0)

    if not id or id == "" then
        outputChatBox("#FFAA00[Kullanım] #FFFFFF/arac [1-29]", player, 255, 255, 255, true)
        return
    end

    -- String temizle (boşluk vs.)
    id = tostring(id):gsub("%s+", "")
    local sayi = tonumber(id)

    outputChatBox("[DEBUG] tonumber sonucu = " .. tostring(sayi), player, 255, 255, 0)

    if not sayi then
        outputChatBox("#FF0000[Hata] #FFFFFFSayı algılanamadı: '" .. tostring(id) .. "'", player, 255, 255, 255, true)
        return
    end

    local arac = araclar[sayi]
    if not arac then
        outputChatBox("#FF0000[Hata] #FFFFFFBu ID tabloda yok: " .. sayi, player, 255, 255, 255, true)
        return
    end

    local x, y, z = getElementPosition(player)
    local rot = getPedRotation(player)

    -- Spawn pozisyonu (oyuncunun önü)
    local rad = math.rad(rot)
    local spawnX = x - math.sin(rad) * 4
    local spawnY = y + math.cos(rad) * 4

    local vehicle = createVehicle(arac.model, spawnX, spawnY, z + 1, 0, 0, rot)

    if vehicle then
        warpPedIntoVehicle(player, vehicle)
        outputChatBox("#00FF00[OK] #FFFFFF" .. arac.isim .. " #AAAAAA(ID: " .. sayi .. " | Model: " .. arac.model .. ")", player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Hata] #FFFFFFAraç oluşturulamadı! Model: " .. arac.model, player, 255, 255, 255, true)
    end
end)

-- /araclist
addCommandHandler("araclist", function(player)
    outputChatBox("===== 4 KAPILI ARAÇLAR (1-29) =====", player, 255, 170, 0)
    for i = 1, 29 do
        local a = araclar[i]
        if a then
            outputChatBox(i .. " - " .. a.isim .. " (Model: " .. a.model .. ")", player, 255, 255, 255, true)
        end
    end
end)

-- /aracsil
addCommandHandler("aracsil", function(player)
    local v = getPedOccupiedVehicle(player)
    if v then
        destroyElement(v)
        outputChatBox("#00FF00Araç silindi.", player, 0, 255, 0, true)
    else
        outputChatBox("#FF0000Bir araçta değilsin!", player, 255, 0, 0, true)
    end
end)