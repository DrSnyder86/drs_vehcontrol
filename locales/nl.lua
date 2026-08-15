Locales = Locales or {}

Locales.nl = {
    ui = {
        vehicle = 'Voertuig',
        noVehicle = 'GEEN VOERTUIG',
        smartKey = 'SLIMME SLEUTEL',
        sanAndreas = 'San Andreas',
        closeControls = 'Bediening sluiten',
        vehicleControlAria = 'Touchscreen voor voertuigbediening',
        vehicleTabsAria = 'Categorieën voor voertuigbediening',
        keyFobAria = 'Voertuigsleutel',
        fuel = '{value}% BRANDSTOF',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'VOERTUIG',
            doors = 'DEUREN',
            windows = 'RAMEN',
            seats = 'ZITPLAATSEN',
            utility = 'FUNCTIES',
            settings = 'INSTELLINGEN'
        },

        settings = {
            accent = 'Accent',
            custom = 'Aangepast',
            brightness = 'Helderheid',
            uiBrightness = 'UI',
            photoOverlay = 'Foto',
            position = 'Positie',
            size = 'Grootte',
            move = 'Verplaatsen',
            reset = 'Herstellen',
            customAccentAria = 'Aangepaste accentkleur',
            brightnessAria = 'Helderheid van de interface',
            photoOverlayAria = 'Donkerte van de foto',
            sizeAria = 'Grootte van de voertuigbediening',
            swatches = {
                cyan = 'Cyaan',
                amber = 'Amber',
                emerald = 'Smaragd',
                red = 'Rood',
                violet = 'Violet',
                white = 'Wit'
            }
        },

        controls = {
            engineOn = 'Motor aan',
            engineOff = 'Motor uit',
            locked = 'Vergrendeld',
            unlocked = 'Ontgrendeld',
            radioOn = 'Radio aan',
            radioOff = 'Radio uit',
            hazards = 'Alarmlichten',
            interiorLight = 'Interieurlicht',
            cruiseSet = 'Cruise instellen',
            cruiseActive = 'Cruise {speed}',
            closeAll = 'Alles sluiten',
            allDown = 'Alles omlaag',
            allUp = 'Alles omhoog',
            detach = 'Loskoppelen',
            anchorDown = 'Anker neer',
            anchorUp = 'Anker op',
            gearDown = 'Landingsgestel uit',
            gearUp = 'Landingsgestel in',
            gearBroken = 'Landingsgestel defect',
            roof = 'Dak',
            extra = 'Extra {number}',
            noVehicleControls = 'Voertuigbediening uitgeschakeld',
            noDoorControls = 'Geen deurbediening',
            noWindowControls = 'Raambediening uitgeschakeld',
            noSeatControls = 'Geen stoelbediening',
            noUtilityControls = 'Geen extra functies'
        },

        fob = {
            ready = 'GEREED',
            noSignal = 'GEEN SIGNAAL',
            lock = 'VERGRENDELEN',
            unlock = 'ONTGRENDELEN',
            start = 'START',
            stop = 'STOP',
            trunk = 'KOFFER',
            closeAction = 'SLUITEN',
            windows = 'RAMEN',
            panic = 'PANIEK',
            move = 'Sleutel verplaatsen',
            drag = 'Sleutel verslepen',
            resize = 'Sleutelgrootte wijzigen',
            resizeWithScale = 'Sleutelgrootte wijzigen ({scale}%)',
            closeKeyFob = 'Sleutel sluiten',
            brandTitle = '{make}-voertuigsleutel',
            customBrandTitle = 'Aangepaste voertuigsleutel'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Voertuigbediening is alleen beschikbaar in ondersteunde voertuigen.',
        keyFobDisabled = 'De sleutelbediening is uitgeschakeld.',
        useTouchscreenInside = 'Gebruik het touchscreen wanneer je in het voertuig zit.',
        noRecentVehicle = 'Geen recent bestuurd voertuig gevonden.',
        vehicleLockChanged = 'Voertuig {plate} is {state}.',
        locked = 'vergrendeld',
        unlocked = 'ontgrendeld',
        seatOccupied = 'Die zitplaats is bezet.',
        cannotAnchorHere = 'Hier kan niet worden geankerd.',
        anchorTooFast = 'Vertraag tot onder {speed} MPH voordat je het anker laat zakken.',
        cruiseUnavailable = 'Cruisecontrol is alleen beschikbaar wanneer je vooruit rijdt met een draaiende motor.',
        cruiseSpeedRange = 'Cruisecontrol is beschikbaar tussen {min} en {max} MPH.'
    },

    fobMessages = {
        ready = 'GEREED',
        disabled = 'UITGESCHAKELD',
        exitVehicle = 'VERLAAT VOERTUIG',
        noVehicle = 'GEEN VOERTUIG',
        unsupported = 'NIET ONDERSTEUND',
        tooFar = 'TE VER WEG',
        noKey = 'GEEN SLEUTEL',
        noSignal = 'GEEN SIGNAAL',
        locked = 'VERGRENDELD',
        unlocked = 'ONTGRENDELD',
        engineOn = 'MOTOR AAN',
        engineOff = 'MOTOR UIT',
        trunkOpen = 'KOFFER OPEN',
        trunkClosed = 'KOFFER DICHT',
        noTrunk = 'GEEN KOFFER',
        windowsDown = 'RAMEN OMLAAG',
        windowsUp = 'RAMEN OMHOOG',
        panic = 'PANIEK',
        panicOff = 'PANIEK UIT'
    },

    keyMappings = {
        touchscreen = 'Touchscreenbediening van voertuig omschakelen',
        keyFob = 'Voertuigsleutel omschakelen'
    },

    vehicleClasses = {
        [0] = "Compacte auto's",
        [1] = 'Sedans',
        [2] = 'SUVs',
        [3] = 'Coupés',
        [4] = 'Muscle cars',
        [5] = 'Sportklassiekers',
        [6] = 'Sportwagens',
        [7] = 'Supercars',
        [8] = 'Motorfietsen',
        [9] = 'Terreinwagens',
        [10] = 'Industrieel',
        [11] = 'Nutsvoertuigen',
        [12] = 'Bestelwagens',
        [13] = 'Fietsen',
        [14] = 'Boten',
        [15] = 'Helikopters',
        [16] = 'Vliegtuigen',
        [17] = 'Dienstvoertuigen',
        [18] = 'Hulpdiensten',
        [19] = 'Militair',
        [20] = 'Commercieel',
        [21] = 'Treinen',
        [22] = 'Open wiel'
    },

    doors = {
        [0] = 'Bestuurder',
        [1] = 'Passagier',
        [2] = 'Linksachter',
        [3] = 'Rechtsachter',
        [4] = 'Motorkap',
        [5] = 'Kofferbak'
    },

    seats = {
        [-1] = 'Bestuurder',
        [0] = 'Passagier',
        [1] = 'Linksachter',
        [2] = 'Rechtsachter',
        [3] = 'Zitplaats 5',
        [4] = 'Zitplaats 6'
    },

    generic = {
        door = 'Deur {number}',
        window = 'Raam {number}',
        seat = 'Zitplaats {number}'
    }
}
