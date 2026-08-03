Locales = Locales or {}

Locales.fr = {
    ui = {
        vehicle = 'Véhicule',
        noVehicle = 'AUCUN VÉHICULE',
        smartKey = 'CLÉ INTELLIGENTE',
        sanAndreas = 'San Andreas',
        closeControls = 'Fermer les commandes',
        vehicleControlAria = 'Écran tactile de contrôle du véhicule',
        vehicleTabsAria = 'Catégories de contrôle du véhicule',
        keyFobAria = 'Télécommande du véhicule',
        fuel = '{value}% CARBURANT',
        engineHealth = '{value}% MOTEUR',

        tabs = {
            vehicle = 'VÉHICULE',
            doors = 'PORTES',
            windows = 'VITRES',
            seats = 'SIÈGES',
            utility = 'FONCTIONS',
            settings = 'RÉGLAGES'
        },

        settings = {
            accent = 'Accent',
            custom = 'Personnalisé',
            brightness = 'Luminosité',
            uiBrightness = 'IU',
            photoOverlay = 'Photo',
            position = 'Position',
            move = 'Deplacer',
            reset = 'Réinitialiser',
            customAccentAria = 'Couleur accent personnalisée',
            brightnessAria = "Luminosité de l'interface",
            photoOverlayAria = "Obscurité de l'image",
            swatches = {
                cyan = 'Cyan',
                amber = 'Ambre',
                emerald = 'Émeraude',
                red = 'Rouge',
                violet = 'Violet',
                white = 'Blanc'
            }
        },

        controls = {
            engineOn = 'Moteur allumé',
            engineOff = 'Moteur éteint',
            locked = 'Verrouillé',
            unlocked = 'Déverrouillé',
            radioOn = 'Radio allumée',
            radioOff = 'Radio éteinte',
            hazards = 'Feux de détresse',
            interiorLight = 'Éclairage intérieur',
            closeAll = 'Tout fermer',
            allDown = 'Tout baisser',
            allUp = 'Tout monter',
            detach = 'Détacher',
            roof = 'Toit',
            extra = 'Extra {number}',
            noVehicleControls = 'Commandes du véhicule désactivées',
            noDoorControls = 'Aucune commande de porte',
            noWindowControls = 'Commandes des vitres désactivées',
            noSeatControls = 'Aucune commande de siège',
            noUtilityControls = 'Aucune commande supplémentaire'
        },

        fob = {
            ready = 'PRÊT',
            noSignal = 'AUCUN SIGNAL',
            lock = 'VERROUILLER',
            unlock = 'DÉVERROUILLER',
            start = 'DÉMARRER',
            stop = 'ARRÊTER',
            trunk = 'COFFRE',
            closeAction = 'FERMER',
            windows = 'VITRES',
            panic = 'PANIQUE',
            move = 'Déplacer la télécommande',
            drag = 'Faire glisser la télécommande',
            resize = 'Redimensionner la télécommande',
            resizeWithScale = 'Redimensionner la télécommande ({scale}%)',
            closeKeyFob = 'Fermer la télécommande',
            brandTitle = 'Télécommande {make}',
            customBrandTitle = 'Télécommande de véhicule personnalisée'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Les commandes ne sont disponibles que dans les véhicules compatibles.',
        keyFobDisabled = 'Les commandes de la télécommande sont désactivées.',
        useTouchscreenInside = "Utilisez l'écran tactile lorsque vous êtes dans le véhicule.",
        noRecentVehicle = 'Aucun véhicule conduit récemment trouvé.',
        vehicleLockChanged = 'Véhicule {plate} {state}.',
        locked = 'verrouillé',
        unlocked = 'déverrouillé',
        seatOccupied = 'Ce siège est occupé.'
    },

    fobMessages = {
        ready = 'PRÊT',
        disabled = 'DÉSACTIVÉ',
        exitVehicle = 'SORTEZ DU VÉHICULE',
        noVehicle = 'AUCUN VÉHICULE',
        unsupported = 'NON COMPATIBLE',
        tooFar = 'TROP ÉLOIGNÉ',
        noKey = 'AUCUNE CLÉ',
        noSignal = 'AUCUN SIGNAL',
        locked = 'VERROUILLÉ',
        unlocked = 'DÉVERROUILLÉ',
        engineOn = 'MOTEUR ALLUMÉ',
        engineOff = 'MOTEUR ÉTEINT',
        trunkOpen = 'COFFRE OUVERT',
        trunkClosed = 'COFFRE FERMÉ',
        noTrunk = 'AUCUN COFFRE',
        windowsDown = 'VITRES BAISSÉES',
        windowsUp = 'VITRES MONTÉES',
        panic = 'PANIQUE',
        panicOff = 'PANIQUE ARRÊTÉE'
    },

    keyMappings = {
        touchscreen = 'Afficher les commandes tactiles du véhicule',
        keyFob = 'Afficher la télécommande du véhicule'
    },

    vehicleClasses = {
        [0] = 'Compactes',
        [1] = 'Berlines',
        [2] = 'SUV',
        [3] = 'Coupés',
        [4] = 'Muscle cars',
        [5] = 'Sportives classiques',
        [6] = 'Sportives',
        [7] = 'Supersportives',
        [8] = 'Motos',
        [9] = 'Tout-terrain',
        [10] = 'Industriels',
        [11] = 'Utilitaires',
        [12] = 'Fourgons',
        [13] = 'Vélos',
        [14] = 'Bateaux',
        [15] = 'Hélicoptères',
        [16] = 'Avions',
        [17] = 'Service',
        [18] = "Urgence",
        [19] = 'Militaires',
        [20] = 'Commerciaux',
        [21] = 'Trains',
        [22] = 'Monoplaces'
    },

    doors = {
        [0] = 'Conducteur',
        [1] = 'Passager',
        [2] = 'Arrière gauche',
        [3] = 'Arrière droite',
        [4] = 'Capot',
        [5] = 'Coffre'
    },

    seats = {
        [-1] = 'Conducteur',
        [0] = 'Passager',
        [1] = 'Arrière gauche',
        [2] = 'Arrière droite',
        [3] = 'Siège 5',
        [4] = 'Siège 6'
    },

    generic = {
        door = 'Porte {number}',
        window = 'Vitre {number}',
        seat = 'Siège {number}'
    }
}
