Items = {
    ["colt"] = { label="Colt 45", description="Yari otomatik tabanca", image="22.png", weight=1.00, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=22, category="weapons", magazineSize=12, maxAmmo=170 },
    ["pistol_ammo"] = { label="Pistol Ammopack", description="9mm mermi", image="2.png", weight=0.01, stack=250, usable=true, droppable=true, tradable=true, category="ammo", ammoFor=22, magazineSize=12, maxAmmo=170 },
    ["bandage"] = { label="Bandaj", description="Tibbi bandaj", image="3.png", weight=0.05, stack=15, usable=true, droppable=true, tradable=true, category="medical", heal=30 },
    ["water"] = { label="Su Sisesi", description="Icme suyu", image="4.png", weight=0.40, stack=5, usable=true, droppable=true, tradable=true, category="food", heal=10 },
    ["bread"] = { label="Ekmek", description="Taze ekmek", image="5.png", weight=0.25, stack=10, usable=true, droppable=true, tradable=true, category="food", heal=15 },
    ["phone"] = { label="Telefon", description="Akilli telefon", image="6.png", weight=0.18, stack=1, usable=true, droppable=true, tradable=true, category="tools" },
    ["key"] = { label="Anahtar", description="Arac / ev anahtari", image="7.png", weight=0.02, stack=1, usable=false, droppable=true, tradable=false, category="keys" },
    ["lighter"] = { label="Cakmak", description="Standart cakmak", image="8.png", weight=0.03, stack=5, usable=true, droppable=true, tradable=true, category="tools" },
    ["ak47"] = { label="AK-47", description="7.62mm tufek", image="30.png", weight=3.80, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=30, category="weapons", magazineSize=30, maxAmmo=240 },
    ["rifle_ammo"] = { label="Rifle Ammo", description="7.62mm mermi", image="10.png", weight=0.02, stack=150, usable=true, droppable=true, tradable=true, category="ammo", ammoFor=30, magazineSize=30, maxAmmo=240 },
    ["medkit"] = { label="Medkit", description="Gelismis tibbi kit", image="11.png", weight=1.20, stack=3, usable=true, droppable=true, tradable=true, category="medical", heal=100 },
    ["armor"] = { label="Zirh", description="Hafif vucut zirhi", image="12.png", weight=4.50, stack=1, usable=true, droppable=true, tradable=true, category="armor" },
    ["radio"] = { label="Telsiz", description="Walkie-talkie", image="13.png", weight=0.35, stack=1, usable=true, droppable=true, tradable=true, category="tools" },
    ["energy"] = { label="Enerji Icecegi", description="Can yeniler", image="14.png", weight=0.30, stack=8, usable=true, droppable=true, tradable=true, category="food", heal=20 },
    ["mask"] = { label="Maske", description="Kimlik gizleyen maske", image="15.png", weight=0.15, stack=1, usable=true, droppable=true, tradable=true, category="clothing" },
    ["deagle"] = { label="Desert Eagle", description="Agir tabanca", image="24.png", weight=1.90, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=24, category="weapons", magazineSize=7, maxAmmo=70 },
    ["shotgun"] = { label="Pompalı", description="12 kalibre av tufegi", image="25.png", weight=4.00, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=25, category="weapons", magazineSize=8, maxAmmo=80 },
    ["smg"] = { label="SMG", description="Hafif makineli", image="9.png", weight=2.40, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=29, category="weapons", magazineSize=30, maxAmmo=240 },
    ["m4"] = { label="M4", description="5.56mm taarruz tufegi", image="9.png", weight=3.60, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=31, category="weapons", magazineSize=30, maxAmmo=240 },
    ["sniper"] = { label="Sniper", description="Keskin nisanci tufegi", image="9.png", weight=5.00, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=34, category="weapons", magazineSize=5, maxAmmo=40 },
    ["smg_ammo"] = { label="SMG Mermisi", description="9mm sarjor", image="10.png", weight=0.02, stack=150, usable=true, droppable=true, tradable=true, category="ammo", ammoFor=29, magazineSize=30, maxAmmo=240 },
    ["m4_ammo"] = { label="M4 Mermisi", description="5.56mm sarjor", image="10.png", weight=0.02, stack=150, usable=true, droppable=true, tradable=true, category="ammo", ammoFor=31, magazineSize=30, maxAmmo=240 },
    ["uzi"] = { label="UZI", description="Kompakt makineli tabanca", image="28.png", weight=2.10, stack=1, usable=true, droppable=true, tradable=true, weapon=true, weaponID=28, category="weapons", magazineSize=30, maxAmmo=240 },
    ["uzi_ammo"] = { label="UZI Mermisi", description="9mm UZI sarjoru", image="10.png", weight=0.02, stack=150, usable=true, droppable=true, tradable=true, category="ammo", ammoFor=28, magazineSize=30, maxAmmo=240 },
   ["kenevir"] = { label="Kenevir", description="Kenevir Yaprağı", image="12.png", weight=0.10, stack=250, usable=false, droppable=true, tradable=true, category="drugs" },
}

function getItemData(id) return Items[id] end
function calculateWeight(inv)
    local t = 0
    if not inv then return 0 end
    for _, s in pairs(inv) do
        if s and s.item and s.count and Items[s.item] then
            t = t + Items[s.item].weight * s.count
        end
    end
    return math.floor(t * 100 + 0.5) / 100
end

-- Numerik ID Uyumluluk Köprüsü
Items[12] = Items["kenevir"]
Items[22] = Items["colt"]
Items[24] = Items["deagle"]
Items[25] = Items["shotgun"]
Items[28] = Items["uzi"]
Items[29] = Items["smg"]
Items[30] = Items["ak47"]
Items[31] = Items["m4"]
Items[34] = Items["sniper"]

local rawGetItemData = getItemData
function getItemData(id)
    if not id then return nil end
    local num = tonumber(id)
    if num and Items[num] then return Items[num] end
    return Items[id] or (num and Items[num])
end
