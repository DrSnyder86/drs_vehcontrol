Locales = Locales or {}

Locales.cs = {
    ui = {
        vehicle = 'Vozidlo',
        noVehicle = 'ŽÁDNÉ VOZIDLO',
        smartKey = 'CHYTRÝ KLÍČ',
        sanAndreas = 'San Andreas',
        closeControls = 'Zavřít ovládání',
        vehicleControlAria = 'Dotykové ovládání vozidla',
        vehicleTabsAria = 'Kategorie ovládání vozidla',
        keyFobAria = 'Klíč od vozidla',
        fuel = '{value}% PALIVO',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'VOZIDLO',
            doors = 'DVEŘE',
            windows = 'OKNA',
            seats = 'SEDADLA',
            utility = 'FUNKCE',
            settings = 'NASTAVENÍ'
        },

        settings = {
            accent = 'Akcent',
            custom = 'Vlastní',
            brightness = 'Jas',
            uiBrightness = 'UI',
            photoOverlay = 'Fotka',
            position = 'Pozice',
            size = 'Velikost',
            move = 'Přesunout',
            reset = 'Obnovit',
            customAccentAria = 'Vlastní barva akcentu',
            brightnessAria = 'Jas rozhraní',
            photoOverlayAria = 'Ztmavení fotografie',
            sizeAria = 'Velikost ovládání vozidla',
            swatches = {
                cyan = 'Azurová',
                amber = 'Jantarová',
                emerald = 'Smaragdová',
                red = 'Červená',
                violet = 'Fialová',
                white = 'Bílá'
            }
        },

        controls = {
            engineOn = 'Motor zapnutý',
            engineOff = 'Motor vypnutý',
            locked = 'Zamčeno',
            unlocked = 'Odemčeno',
            radioOn = 'Rádio zapnuto',
            radioOff = 'Rádio vypnuto',
            hazards = 'Výstražná světla',
            interiorLight = 'Vnitřní světlo',
            cruiseSet = 'Nastavit tempomat',
            cruiseActive = 'Tempomat {speed}',
            closeAll = 'Zavřít vše',
            allDown = 'Vše dolů',
            allUp = 'Vše nahoru',
            detach = 'Odpojit',
            anchorDown = 'Kotva spuštěna',
            anchorUp = 'Kotva zvednuta',
            gearDown = 'Podvozek dole',
            gearUp = 'Podvozek nahoře',
            gearBroken = 'Podvozek poškozen',
            roof = 'Střecha',
            extra = 'Doplněk {number}',
            noVehicleControls = 'Ovládání vozidla je vypnuto',
            noDoorControls = 'Žádné ovládání dveří',
            noWindowControls = 'Ovládání oken je vypnuto',
            noSeatControls = 'Žádné ovládání sedadel',
            noUtilityControls = 'Žádné doplňkové ovládání'
        },

        fob = {
            ready = 'PŘIPRAVENO',
            noSignal = 'ŽÁDNÝ SIGNÁL',
            lock = 'ZAMKNOUT',
            unlock = 'ODEMKNOUT',
            start = 'START',
            stop = 'STOP',
            trunk = 'KUFR',
            closeAction = 'ZAVŘÍT',
            windows = 'OKNA',
            panic = 'PANIKA',
            move = 'Přesunout klíč',
            drag = 'Přetáhnout klíč',
            resize = 'Změnit velikost klíče',
            resizeWithScale = 'Změnit velikost klíče ({scale}%)',
            closeKeyFob = 'Zavřít klíč',
            brandTitle = 'Klíč {make}',
            customBrandTitle = 'Vlastní klíč od vozidla'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Ovládání je dostupné pouze uvnitř podporovaných vozidel.',
        keyFobDisabled = 'Ovládání klíče je vypnuto.',
        useTouchscreenInside = 'Uvnitř vozidla použijte dotykovou obrazovku.',
        noRecentVehicle = 'Nebylo nalezeno žádné nedávno řízené vozidlo.',
        vehicleLockChanged = 'Vozidlo {plate} bylo {state}.',
        locked = 'zamčeno',
        unlocked = 'odemčeno',
        seatOccupied = 'Toto sedadlo je obsazené.',
        cannotAnchorHere = 'Zde nelze zakotvit.',
        anchorTooFast = 'Před spuštěním kotvy zpomalte pod {speed} MPH.',
        cruiseUnavailable = 'Tempomat lze použít pouze při jízdě vpřed se spuštěným motorem.',
        cruiseSpeedRange = 'Tempomat je dostupný mezi {min} a {max} MPH.'
    },

    fobMessages = {
        ready = 'PŘIPRAVENO',
        disabled = 'VYPNUTO',
        exitVehicle = 'VYSTUPTE Z VOZIDLA',
        noVehicle = 'ŽÁDNÉ VOZIDLO',
        unsupported = 'NEPODPOROVÁNO',
        tooFar = 'PŘÍLIŠ DALEKO',
        noKey = 'ŽÁDNÝ KLÍČ',
        noSignal = 'ŽÁDNÝ SIGNÁL',
        locked = 'ZAMČENO',
        unlocked = 'ODEMČENO',
        engineOn = 'MOTOR ZAPNUTÝ',
        engineOff = 'MOTOR VYPNUTÝ',
        trunkOpen = 'KUFR OTEVŘENÝ',
        trunkClosed = 'KUFR ZAVŘENÝ',
        noTrunk = 'BEZ KUFRU',
        windowsDown = 'OKNA DOLE',
        windowsUp = 'OKNA NAHOŘE',
        panic = 'PANIKA',
        panicOff = 'PANIKA VYPNUTA'
    },

    keyMappings = {
        touchscreen = 'Přepnout dotykové ovládání vozidla',
        keyFob = 'Přepnout klíč od vozidla'
    },

    vehicleClasses = {
        [0] = 'Kompaktní',
        [1] = 'Sedany',
        [2] = 'SUV',
        [3] = 'Kupé',
        [4] = 'Muscle',
        [5] = 'Sportovní klasiky',
        [6] = 'Sportovní',
        [7] = 'Supersporty',
        [8] = 'Motocykly',
        [9] = 'Terénní',
        [10] = 'Průmyslová',
        [11] = 'Užitková',
        [12] = 'Dodávky',
        [13] = 'Jízdní kola',
        [14] = 'Lodě',
        [15] = 'Vrtulníky',
        [16] = 'Letadla',
        [17] = 'Služební',
        [18] = 'Záchranná',
        [19] = 'Vojenská',
        [20] = 'Nákladní',
        [21] = 'Vlaky',
        [22] = 'Formule'
    },

    doors = {
        [0] = 'Řidič',
        [1] = 'Spolujezdec',
        [2] = 'Levé zadní',
        [3] = 'Pravé zadní',
        [4] = 'Kapota',
        [5] = 'Kufr'
    },

    seats = {
        [-1] = 'Řidič',
        [0] = 'Spolujezdec',
        [1] = 'Levé zadní',
        [2] = 'Pravé zadní',
        [3] = 'Sedadlo 5',
        [4] = 'Sedadlo 6'
    },

    generic = {
        door = 'Dveře {number}',
        window = 'Okno {number}',
        seat = 'Sedadlo {number}'
    }
}
