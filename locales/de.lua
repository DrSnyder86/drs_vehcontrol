Locales = Locales or {}

Locales.de = {
    ui = {
        vehicle = 'Fahrzeug',
        noVehicle = 'KEIN FAHRZEUG',
        smartKey = 'SMART-SCHLÜSSEL',
        sanAndreas = 'San Andreas',
        closeControls = 'Steuerung schließen',
        vehicleControlAria = 'Touchscreen-Fahrzeugsteuerung',
        vehicleTabsAria = 'Kategorien der Fahrzeugsteuerung',
        keyFobAria = 'Fahrzeugschlüssel',
        fuel = '{value}% KRAFTSTOFF',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'FAHRZEUG',
            doors = 'TÜREN',
            windows = 'FENSTER',
            seats = 'SITZE',
            utility = 'FUNKTIONEN',
            settings = 'EINSTELLUNGEN'
        },

        settings = {
            accent = 'Akzent',
            custom = 'Benutzerdefiniert',
            brightness = 'Helligkeit',
            uiBrightness = 'UI',
            photoOverlay = 'Foto',
            position = 'Position',
            size = 'Größe',
            move = 'Verschieben',
            reset = 'Zurücksetzen',
            customAccentAria = 'Benutzerdefinierte Akzentfarbe',
            brightnessAria = 'UI-Helligkeit',
            photoOverlayAria = 'Dunkelheit der Fotoüberlagerung',
            sizeAria = 'Größe der Fahrzeugsteuerung',
            swatches = {
                cyan = 'Cyan',
                amber = 'Bernstein',
                emerald = 'Smaragd',
                red = 'Rot',
                violet = 'Violett',
                white = 'Weiß'
            }
        },

        controls = {
            engineOn = 'Motor an',
            engineOff = 'Motor aus',
            locked = 'Verriegelt',
            unlocked = 'Entriegelt',
            radioOn = 'Radio an',
            radioOff = 'Radio aus',
            hazards = 'Warnblinker',
            interiorLight = 'Innenlicht',
            cruiseSet = 'Tempomat setzen',
            cruiseActive = 'Tempomat {speed}',
            closeAll = 'Alle schließen',
            allDown = 'Alle runter',
            allUp = 'Alle hoch',
            detach = 'Abkoppeln',
            anchorDown = 'Anker unten',
            anchorUp = 'Anker oben',
            gearDown = 'Fahrwerk unten',
            gearUp = 'Fahrwerk oben',
            gearBroken = 'Fahrwerk defekt',
            roof = 'Dach',
            extra = 'Extra {number}',
            noVehicleControls = 'Fahrzeugsteuerung deaktiviert',
            noDoorControls = 'Keine Türsteuerung',
            noWindowControls = 'Fenstersteuerung deaktiviert',
            noSeatControls = 'Keine Sitzsteuerung',
            noUtilityControls = 'Keine Zusatzfunktionen'
        },

        fob = {
            ready = 'BEREIT',
            noSignal = 'KEIN SIGNAL',
            lock = 'SPERREN',
            unlock = 'ÖFFNEN',
            start = 'START',
            stop = 'STOPP',
            trunk = 'KOFFERRAUM',
            closeAction = 'SCHLIESSEN',
            windows = 'FENSTER',
            panic = 'PANIK',
            move = 'Schlüssel verschieben',
            drag = 'Schlüssel ziehen',
            resize = 'Schlüsselgröße ändern',
            resizeWithScale = 'Schlüsselgröße ändern ({scale}%)',
            closeKeyFob = 'Schlüssel schließen',
            brandTitle = '{make}-Fahrzeugschlüssel',
            customBrandTitle = 'Benutzerdefinierter Fahrzeugschlüssel'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Die Fahrzeugsteuerung ist nur in unterstützten Fahrzeugen verfügbar.',
        keyFobDisabled = 'Die Schlüsselsteuerung ist deaktiviert.',
        useTouchscreenInside = 'Verwende im Fahrzeug den Touchscreen.',
        noRecentVehicle = 'Kein kürzlich gefahrenes Fahrzeug gefunden.',
        vehicleLockChanged = 'Fahrzeug {plate} wurde {state}.',
        locked = 'verriegelt',
        unlocked = 'entriegelt',
        seatOccupied = 'Dieser Sitz ist belegt.',
        cannotAnchorHere = 'Hier kann nicht geankert werden.',
        anchorTooFast = 'Fahre langsamer als {speed} MPH, bevor du den Anker senkst.',
        cruiseUnavailable = 'Der Tempomat ist nur bei Vorwärtsfahrt mit laufendem Motor verfügbar.',
        cruiseSpeedRange = 'Der Tempomat ist zwischen {min} und {max} MPH verfügbar.'
    },

    fobMessages = {
        ready = 'BEREIT',
        disabled = 'DEAKTIVIERT',
        exitVehicle = 'FAHRZEUG VERLASSEN',
        noVehicle = 'KEIN FAHRZEUG',
        unsupported = 'NICHT UNTERSTÜTZT',
        tooFar = 'ZU WEIT ENTFERNT',
        noKey = 'KEIN SCHLÜSSEL',
        noSignal = 'KEIN SIGNAL',
        locked = 'VERRIEGELT',
        unlocked = 'ENTRIEGELT',
        engineOn = 'MOTOR AN',
        engineOff = 'MOTOR AUS',
        trunkOpen = 'KOFFERRAUM OFFEN',
        trunkClosed = 'KOFFERRAUM ZU',
        noTrunk = 'KEIN KOFFERRAUM',
        windowsDown = 'FENSTER UNTEN',
        windowsUp = 'FENSTER OBEN',
        panic = 'PANIK',
        panicOff = 'PANIK AUS'
    },

    keyMappings = {
        touchscreen = 'Touchscreen-Fahrzeugsteuerung umschalten',
        keyFob = 'Fahrzeugschlüssel umschalten'
    },

    vehicleClasses = {
        [0] = 'Kompaktwagen',
        [1] = 'Limousinen',
        [2] = 'SUVs',
        [3] = 'Coupés',
        [4] = 'Muscle-Cars',
        [5] = 'Sportklassiker',
        [6] = 'Sportwagen',
        [7] = 'Supersportwagen',
        [8] = 'Motorräder',
        [9] = 'Geländefahrzeuge',
        [10] = 'Industriefahrzeuge',
        [11] = 'Nutzfahrzeuge',
        [12] = 'Lieferwagen',
        [13] = 'Fahrräder',
        [14] = 'Boote',
        [15] = 'Hubschrauber',
        [16] = 'Flugzeuge',
        [17] = 'Servicefahrzeuge',
        [18] = 'Einsatzfahrzeuge',
        [19] = 'Militärfahrzeuge',
        [20] = 'Nutzverkehr',
        [21] = 'Züge',
        [22] = 'Formelwagen'
    },

    doors = {
        [0] = 'Fahrer',
        [1] = 'Beifahrer',
        [2] = 'Hinten links',
        [3] = 'Hinten rechts',
        [4] = 'Motorhaube',
        [5] = 'Kofferraum'
    },

    seats = {
        [-1] = 'Fahrer',
        [0] = 'Beifahrer',
        [1] = 'Hinten links',
        [2] = 'Hinten rechts',
        [3] = 'Sitz 5',
        [4] = 'Sitz 6'
    },

    generic = {
        door = 'Tür {number}',
        window = 'Fenster {number}',
        seat = 'Sitz {number}'
    }
}
