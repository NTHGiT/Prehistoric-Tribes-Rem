local BuildingData = {
    -- INFRASTRUKTUR & VITALITAS
    store = {
        type = "store", name = "Gudang Utama",
        sizeX = 3, sizeY = 3, capacity = 4,
        maxBuilders = 2, maxProgress = 100,
        cost = { wood = 30, stone = 20, bone = 0 },
        desc = "Penyimpanan utama & haus dasar (Kap: 4)"
    },
    well = {
        type = "well", name = "Sumur Purba",
        sizeX = 2, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 60,
        cost = { wood = 10, stone = 20, bone = 0 },
        desc = "Sumber air terdekat (Kap: 2)"
    },
    hut = {
        type = "hut", name = "Tenda Hunian",
        sizeX = 2, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 80,
        cost = { wood = 15, stone = 5, bone = 0 },
        desc = "+2 Limit Pop & istirahat warga (Kap: 2)"
    },
    chief_house = {
        type = "chief_house", name = "Rumah Kepala Suku",
        sizeX = 3, sizeY = 3, capacity = 4,
        maxBuilders = 3, maxProgress = 150,
        cost = { wood = 40, stone = 25, bone = 10 },
        desc = "Pusat komando & pemancar aura (Kap: 4)"
    },

    -- LOGISTIK MAKANAN
    kitchen = {
        type = "kitchen", name = "Restoran / Dapur",
        sizeX = 3, sizeY = 2, capacity = 3, -- 1 Koki + 2 Tamu Makan
        maxBuilders = 3, maxProgress = 120,
        cost = { wood = 25, stone = 10, bone = 0 },
        desc = "Mengolah porsi lezat (Kap: 3)"
    },
    smokehouse = {
        type = "smokehouse", name = "Rumah Pengasapan",
        sizeX = 2, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 90,
        cost = { wood = 20, stone = 10, bone = 0 },
        desc = "Mengolah daging asap (Kap: 2)"
    },

    -- PRODUKSI & MANUFAKTUR
    armory = {
        type = "armory", name = "Tempat Senjata",
        sizeX = 2, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 100,
        cost = { wood = 20, stone = 10, bone = 5 },
        desc = "Perakitan tombak (Kap: 2)"
    },
    tannery = {
        type = "tannery", name = "Penyamakan Kulit",
        sizeX = 2, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 100,
        cost = { wood = 20, stone = 10, bone = 10 },
        desc = "Pengolahan Armor Kulit Purba (Kap: 2)"
    },
    beast_pen = {
        type = "beast_pen", name = "Kandang Peternakan",
        sizeX = 3, sizeY = 3, capacity = 3,
        maxBuilders = 3, maxProgress = 130,
        cost = { wood = 35, stone = 15, bone = 10 },
        desc = "Pembudidayaan hewan ternak (Kap: 3)"
    },

    -- FASILITAS KHUSUS & SOSIAL
    bonfire = {
        type = "bonfire", name = "Api Unggun Utama",
        sizeX = 2, sizeY = 2, capacity = 6,
        maxBuilders = 2, maxProgress = 40,
        cost = { wood = 15, stone = 10, bone = 0 },
        desc = "Pusat hangat malam hari (Kap: 6)"
    },
    disco = {
        type = "disco", name = "Sanggar Disko Purba",
        sizeX = 3, sizeY = 3, capacity = 5,
        maxBuilders = 3, maxProgress = 140,
        cost = { wood = 35, stone = 15, bone = 5 },
        desc = "Pusat hiburan masal (Kap: 5)"
    },
    shaman_shrine = {
        type = "shaman_shrine", name = "Kuil Shaman",
        sizeX = 3, sizeY = 3, capacity = 3,
        maxBuilders = 2, maxProgress = 130,
        cost = { wood = 30, stone = 20, bone = 15 },
        desc = "Penyembuhan & ramuan (Kap: 3)"
    },
    nursery = {
        type = "nursery", name = "Tempat Pengasuhan",
        sizeX = 3, sizeY = 2, capacity = 4,
        maxBuilders = 2, maxProgress = 90,
        cost = { wood = 20, stone = 10, bone = 0 },
        desc = "Perawatan anak suku (Kap: 4)"
    },

    -- PELATIHAN & KEMILITERAN
    gym = {
        type = "gym", name = "Sanggar Olahraga / Gym",
        sizeX = 3, sizeY = 3, capacity = 3,
        maxBuilders = 2, maxProgress = 120,
        cost = { wood = 30, stone = 20, bone = 5 },
        desc = "Latihan fisik militer (Kap: 3)"
    },
    archery = {
        type = "archery", name = "Lapangan Panahan",
        sizeX = 3, sizeY = 2, capacity = 2,
        maxBuilders = 2, maxProgress = 110,
        cost = { wood = 25, stone = 15, bone = 5 },
        desc = "Latihan ketangkasan panahan (Kap: 2)"
    },
    spy_camp = {
        type = "spy_camp", name = "Kompi Mata-Mata",
        sizeX = 3, sizeY = 3, capacity = 2,
        maxBuilders = 2, maxProgress = 120,
        cost = { wood = 30, stone = 15, bone = 10 },
        desc = "Pelatihan Scout (Kap: 2)"
    },
    warrior_camp = {
        type = "warrior_camp", name = "Pos Garda Suku",
        sizeX = 3, sizeY = 3, capacity = 3,
        maxBuilders = 3, maxProgress = 160,
        cost = { wood = 40, stone = 30, bone = 15 },
        desc = "Markas Sheriff / Garda Suku (Kap: 3)"
    }
}

return BuildingData
