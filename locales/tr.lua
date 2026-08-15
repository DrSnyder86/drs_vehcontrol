Locales = Locales or {}

Locales.tr = {
    ui = {
        vehicle = 'Araç',
        noVehicle = 'ARAÇ YOK',
        smartKey = 'AKILLI ANAHTAR',
        sanAndreas = 'San Andreas',
        closeControls = 'Kontrolleri kapat',
        vehicleControlAria = 'Araç kontrol dokunmatik ekranı',
        vehicleTabsAria = 'Araç kontrol kategorileri',
        keyFobAria = 'Araç anahtarı',
        fuel = '{value}% YAKIT',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'ARAÇ',
            doors = 'KAPILAR',
            windows = 'CAMLAR',
            seats = 'KOLTUKLAR',
            utility = 'İŞLEMLER',
            settings = 'AYARLAR'
        },

        settings = {
            accent = 'Vurgu',
            custom = 'Özel',
            brightness = 'Parlaklık',
            uiBrightness = 'Arayüz',
            photoOverlay = 'Fotoğraf',
            position = 'Konum',
            size = 'Boyut',
            move = 'Taşı',
            reset = 'Sıfırla',
            customAccentAria = 'Özel vurgu rengi',
            brightnessAria = 'Arayüz parlaklığı',
            photoOverlayAria = 'Fotoğraf karartması',
            sizeAria = 'Araç kontrolü boyutu',
            swatches = {
                cyan = 'Camgöbeği',
                amber = 'Kehribar',
                emerald = 'Zümrüt',
                red = 'Kırmızı',
                violet = 'Mor',
                white = 'Beyaz'
            }
        },

        controls = {
            engineOn = 'Motor açık',
            engineOff = 'Motor kapalı',
            locked = 'Kilitli',
            unlocked = 'Kilitsiz',
            radioOn = 'Radyo açık',
            radioOff = 'Radyo kapalı',
            hazards = 'Dörtlüler',
            interiorLight = 'İç aydınlatma',
            cruiseSet = 'Hızı sabitle',
            cruiseActive = 'Sabit {speed}',
            closeAll = 'Tümünü kapat',
            allDown = 'Hepsini indir',
            allUp = 'Hepsini kaldır',
            detach = 'Ayır',
            anchorDown = 'Çapa aşağıda',
            anchorUp = 'Çapa yukarıda',
            gearDown = 'İniş takımı açık',
            gearUp = 'İniş takımı kapalı',
            gearBroken = 'İniş takımı hasarlı',
            roof = 'Tavan',
            extra = 'Ekstra {number}',
            noVehicleControls = 'Araç kontrolleri devre dışı',
            noDoorControls = 'Kapı kontrolü yok',
            noWindowControls = 'Cam kontrolleri devre dışı',
            noSeatControls = 'Koltuk kontrolü yok',
            noUtilityControls = 'Ek kontrol yok'
        },

        fob = {
            ready = 'HAZIR',
            noSignal = 'SİNYAL YOK',
            lock = 'KİLİTLE',
            unlock = 'KİLİDİ AÇ',
            start = 'ÇALIŞTIR',
            stop = 'DURDUR',
            trunk = 'BAGAJ',
            closeAction = 'KAPAT',
            windows = 'CAMLAR',
            panic = 'PANİK',
            move = 'Anahtarı taşı',
            drag = 'Anahtarı sürükle',
            resize = 'Anahtarı yeniden boyutlandır',
            resizeWithScale = 'Anahtarı yeniden boyutlandır ({scale}%)',
            closeKeyFob = 'Anahtarı kapat',
            brandTitle = '{make} araç anahtarı',
            customBrandTitle = 'Özel araç anahtarı'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Araç kontrolleri yalnızca desteklenen araçların içinde kullanılabilir.',
        keyFobDisabled = 'Anahtar kontrolleri devre dışı.',
        useTouchscreenInside = 'Araçtayken dokunmatik ekranı kullanın.',
        noRecentVehicle = 'Yakın zamanda sürülen araç bulunamadı.',
        vehicleLockChanged = '{plate} plakalı araç {state}.',
        locked = 'kilitlendi',
        unlocked = 'açıldı',
        seatOccupied = 'Bu koltuk dolu.',
        cannotAnchorHere = 'Burada demirlenemez.',
        anchorTooFast = 'Çapayı indirmeden önce {speed} MPH hızın altına düşün.',
        cruiseUnavailable = 'Hız sabitleme yalnızca motor çalışırken ileri sürüşte kullanılabilir.',
        cruiseSpeedRange = 'Hız sabitleme {min} ile {max} MPH arasında kullanılabilir.'
    },

    fobMessages = {
        ready = 'HAZIR',
        disabled = 'DEVRE DIŞI',
        exitVehicle = 'ARAÇTAN ÇIK',
        noVehicle = 'ARAÇ YOK',
        unsupported = 'DESTEKLENMİYOR',
        tooFar = 'ÇOK UZAK',
        noKey = 'ANAHTAR YOK',
        noSignal = 'SİNYAL YOK',
        locked = 'KİLİTLİ',
        unlocked = 'KİLİTSİZ',
        engineOn = 'MOTOR AÇIK',
        engineOff = 'MOTOR KAPALI',
        trunkOpen = 'BAGAJ AÇIK',
        trunkClosed = 'BAGAJ KAPALI',
        noTrunk = 'BAGAJ YOK',
        windowsDown = 'CAMLAR AŞAĞIDA',
        windowsUp = 'CAMLAR YUKARIDA',
        panic = 'PANİK',
        panicOff = 'PANİK KAPALI'
    },

    keyMappings = {
        touchscreen = 'Araç dokunmatik kontrollerini aç/kapat',
        keyFob = 'Araç anahtarını aç/kapat'
    },

    vehicleClasses = {
        [0] = 'Kompakt',
        [1] = 'Sedanlar',
        [2] = "SUV'ler",
        [3] = 'Kupeler',
        [4] = 'Muscle',
        [5] = 'Klasik spor',
        [6] = 'Spor',
        [7] = 'Süper',
        [8] = 'Motosikletler',
        [9] = 'Arazi',
        [10] = 'Endüstriyel',
        [11] = 'Hizmet araçları',
        [12] = 'Minibüsler',
        [13] = 'Bisikletler',
        [14] = 'Tekneler',
        [15] = 'Helikopterler',
        [16] = 'Uçaklar',
        [17] = 'Servis',
        [18] = 'Acil durum',
        [19] = 'Askeri',
        [20] = 'Ticari',
        [21] = 'Trenler',
        [22] = 'Açık teker'
    },

    doors = {
        [0] = 'Sürücü',
        [1] = 'Yolcu',
        [2] = 'Sol arka',
        [3] = 'Sağ arka',
        [4] = 'Kaput',
        [5] = 'Bagaj'
    },

    seats = {
        [-1] = 'Sürücü',
        [0] = 'Yolcu',
        [1] = 'Sol arka',
        [2] = 'Sağ arka',
        [3] = 'Koltuk 5',
        [4] = 'Koltuk 6'
    },

    generic = {
        door = 'Kapı {number}',
        window = 'Cam {number}',
        seat = 'Koltuk {number}'
    }
}
