--[[
    Meslekler veri tablosu - kolay ekle/cikar
]]

JobsData = {
    { id = 1,  name = "Taksi Soforu",      description = "Sehirde yolcu tasiyarak para kazan.",           salary = 15000, location = "Taksi Merkezi",        x = 1743.0, y = -1861.0, z = 13.6 },
    { id = 2,  name = "Kamyon Soforu",     description = "Yuk tasimaciligi, uzun mesafe teslimat.",       salary = 25000, location = "Liman / Dock",          x = 2197.0, y = -2255.0, z = 14.5 },
    { id = 3,  name = "Otobus Soforu",     description = "Sehir ici hatlarda yolcu tasi.",                salary = 12000, location = "Otobus Terminali",      x = 1785.0, y = -1900.0, z = 13.4 },
    { id = 4,  name = "Cop Toplayici",     description = "Sehir temizligine katki sagla.",                salary = 8000,  location = "Belediye Garaji",       x = 2198.0, y = -1976.0, z = 13.5 },
    { id = 5,  name = "Pizza Dagiticisi",  description = "Siparisleri hizlica teslim et.",                salary = 10000, location = "Well Stacked Pizza",    x = 2105.0, y = -1806.0, z = 13.5 },
    { id = 6,  name = "Tamirci",           description = "Arac tamiri ve bakim isleri.",                  salary = 18000, location = "Transfender",           x = 1041.0, y = -1026.0, z = 32.1 },
    { id = 7,  name = "Balikci",           description = "Balik tut, sat, para kazan.",                   salary = 14000, location = "Balikci Iskelesi",      x = 154.0,  y = -1942.0, z = 3.8  },
    { id = 8,  name = "Madenci",           description = "Madenlerde calis, cevher topla.",               salary = 22000, location = "Maden Bolgesi",         x = -336.0, y = 1360.0,  z = 66.0 },
    { id = 9,  name = "Kurye",             description = "Paket dagitim isi.",                            salary = 11000, location = "Postane",               x = 1368.0, y = -1279.0, z = 13.5 },
    { id = 10, name = "Ciftci",            description = "Tarim urunleri topla ve sat.",                  salary = 13000, location = "Ciftlik",               x = -1060.0,y = -1205.0, z = 129.2},
}

function getJobById(id)
    id = tonumber(id)
    if not id then return nil end
    for _, j in ipairs(JobsData) do
        if j.id == id then return j end
    end
    return nil
end
