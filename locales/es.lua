Locales = Locales or {}

Locales.es = {
    ui = {
        vehicle = 'Vehículo',
        noVehicle = 'SIN VEHÍCULO',
        smartKey = 'LLAVE INTELIGENTE',
        sanAndreas = 'San Andreas',
        closeControls = 'Cerrar controles',
        vehicleControlAria = 'Pantalla táctil de control del vehículo',
        vehicleTabsAria = 'Categorías de control del vehículo',
        keyFobAria = 'Mando del vehículo',
        fuel = '{value}% COMBUSTIBLE',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'VEHÍCULO',
            doors = 'PUERTAS',
            windows = 'VENTANAS',
            seats = 'ASIENTOS',
            utility = 'FUNCIONES',
            settings = 'AJUSTES'
        },

        settings = {
            accent = 'Acento',
            custom = 'Personalizado',
            brightness = 'Brillo',
            uiBrightness = 'IU',
            photoOverlay = 'Foto',
            position = 'Posición',
            move = 'Mover',
            reset = 'Restablecer',
            customAccentAria = 'Color de acento personalizado',
            brightnessAria = 'Brillo de la interfaz',
            photoOverlayAria = 'Oscuridad de la foto',
            swatches = {
                cyan = 'Cian',
                amber = 'Ámbar',
                emerald = 'Esmeralda',
                red = 'Rojo',
                violet = 'Violeta',
                white = 'Blanco'
            }
        },

        controls = {
            engineOn = 'Motor encendido',
            engineOff = 'Motor apagado',
            locked = 'Bloqueado',
            unlocked = 'Desbloqueado',
            radioOn = 'Radio encendida',
            radioOff = 'Radio apagada',
            hazards = 'Emergencia',
            interiorLight = 'Luz interior',
            closeAll = 'Cerrar todo',
            allDown = 'Bajar todo',
            allUp = 'Subir todo',
            detach = 'Desacoplar',
            roof = 'Techo',
            extra = 'Extra {number}',
            noVehicleControls = 'Controles del vehículo desactivados',
            noDoorControls = 'Sin controles de puertas',
            noWindowControls = 'Controles de ventanas desactivados',
            noSeatControls = 'Sin controles de asientos',
            noUtilityControls = 'Sin controles adicionales'
        },

        fob = {
            ready = 'LISTO',
            noSignal = 'SIN SEÑAL',
            lock = 'BLOQUEAR',
            unlock = 'DESBLOQUEAR',
            start = 'ARRANCAR',
            stop = 'APAGAR',
            trunk = 'MALETERO',
            closeAction = 'CERRAR',
            windows = 'VENTANAS',
            panic = 'PÁNICO',
            move = 'Mover el mando',
            drag = 'Arrastrar el mando',
            resize = 'Cambiar tamaño del mando',
            resizeWithScale = 'Cambiar tamaño del mando ({scale}%)',
            closeKeyFob = 'Cerrar el mando',
            brandTitle = 'Mando de {make}',
            customBrandTitle = 'Mando de vehículo personalizado'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Los controles solo están disponibles dentro de vehículos compatibles.',
        keyFobDisabled = 'Los controles del mando están desactivados.',
        useTouchscreenInside = 'Usa la pantalla táctil mientras estés dentro del vehículo.',
        noRecentVehicle = 'No se encontró ningún vehículo conducido recientemente.',
        vehicleLockChanged = 'Vehículo {plate} {state}.',
        locked = 'bloqueado',
        unlocked = 'desbloqueado',
        seatOccupied = 'Ese asiento está ocupado.'
    },

    fobMessages = {
        ready = 'LISTO',
        disabled = 'DESACTIVADO',
        exitVehicle = 'SAL DEL VEHÍCULO',
        noVehicle = 'SIN VEHÍCULO',
        unsupported = 'NO COMPATIBLE',
        tooFar = 'DEMASIADO LEJOS',
        noKey = 'SIN LLAVE',
        noSignal = 'SIN SEÑAL',
        locked = 'BLOQUEADO',
        unlocked = 'DESBLOQUEADO',
        engineOn = 'MOTOR ENCENDIDO',
        engineOff = 'MOTOR APAGADO',
        trunkOpen = 'MALETERO ABIERTO',
        trunkClosed = 'MALETERO CERRADO',
        noTrunk = 'SIN MALETERO',
        windowsDown = 'VENTANAS BAJADAS',
        windowsUp = 'VENTANAS SUBIDAS',
        panic = 'PÁNICO',
        panicOff = 'PÁNICO APAGADO'
    },

    keyMappings = {
        touchscreen = 'Alternar controles táctiles del vehículo',
        keyFob = 'Alternar mando del vehículo'
    },

    vehicleClasses = {
        [0] = 'Compactos',
        [1] = 'Sedanes',
        [2] = 'SUV',
        [3] = 'Cupés',
        [4] = 'Muscle',
        [5] = 'Clásicos deportivos',
        [6] = 'Deportivos',
        [7] = 'Superdeportivos',
        [8] = 'Motocicletas',
        [9] = 'Todoterreno',
        [10] = 'Industriales',
        [11] = 'Utilitarios',
        [12] = 'Furgonetas',
        [13] = 'Bicicletas',
        [14] = 'Barcos',
        [15] = 'Helicópteros',
        [16] = 'Aviones',
        [17] = 'Servicio',
        [18] = 'Emergencia',
        [19] = 'Militares',
        [20] = 'Comerciales',
        [21] = 'Trenes',
        [22] = 'Monoplazas'
    },

    doors = {
        [0] = 'Conductor',
        [1] = 'Pasajero',
        [2] = 'Trasera izquierda',
        [3] = 'Trasera derecha',
        [4] = 'Capó',
        [5] = 'Maletero'
    },

    seats = {
        [-1] = 'Conductor',
        [0] = 'Pasajero',
        [1] = 'Trasero izquierdo',
        [2] = 'Trasero derecho',
        [3] = 'Asiento 5',
        [4] = 'Asiento 6'
    },

    generic = {
        door = 'Puerta {number}',
        window = 'Ventana {number}',
        seat = 'Asiento {number}'
    }
}
