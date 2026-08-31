Locales = Locales or {}

Locales.en = {
    ui = {
        vehicle = 'Vehicle',
        noVehicle = 'NO VEHICLE',
        smartKey = 'SMART KEY',
        sanAndreas = 'San Andreas',
        closeControls = 'Close controls',
        vehicleControlAria = 'Vehicle control touchscreen',
        vehicleTabsAria = 'Vehicle control categories',
        keyFobAria = 'Vehicle key fob',
        fuel = '{value}% FUEL',
        engineHealth = '{value}% ENG',

        tabs = {
            vehicle = 'VEHICLE',
            doors = 'DOORS',
            windows = 'WINDOWS',
            seats = 'SEATS',
            utility = 'UTILITY',
            settings = 'SETTINGS'
        },

        settings = {
            accent = 'Accent',
            custom = 'Custom',
            brightness = 'Brightness',
            uiBrightness = 'UI',
            photoOverlay = 'Photo',
            position = 'Position',
            size = 'Size',
            move = 'Move',
            reset = 'Reset',
            customAccentAria = 'Custom accent color',
            brightnessAria = 'UI brightness',
            photoOverlayAria = 'Photo overlay darkness',
            sizeAria = 'Vehicle control size',
            swatches = {
                cyan = 'Cyan',
                amber = 'Amber',
                emerald = 'Emerald',
                red = 'Red',
                violet = 'Violet',
                white = 'White'
            }
        },

        controls = {
            engineOn = 'Engine On',
            engineOff = 'Engine Off',
            locked = 'Locked',
            unlocked = 'Unlocked',
            radioOn = 'Radio On',
            radioOff = 'Radio Off',
            hazards = 'Hazards',
            interiorLight = 'Interior Light',
            cruiseSet = 'Set Cruise',
            cruiseActive = 'Cruise {speed}',
            autopilotStart = 'Start Autopilot',
            autopilotEnRoute = 'Autopilot En Route',
            autopilotHolding = 'Autopilot Holding',
            hoverStart = 'Start Hover',
            hoverActive = 'Hovering',
            closeAll = 'Close All',
            allDown = 'All Down',
            allUp = 'All Up',
            detach = 'Detach',
            anchorDown = 'Anchor Down',
            anchorUp = 'Anchor Up',
            gearDown = 'Gear Down',
            gearUp = 'Gear Up',
            gearBroken = 'Gear Broken',
            roof = 'Roof',
            extra = 'Extra {number}',
            noVehicleControls = 'Vehicle controls disabled',
            noDoorControls = 'No door controls',
            noWindowControls = 'Window controls disabled',
            noSeatControls = 'No seat controls',
            noUtilityControls = 'No utility controls'
        },

        fob = {
            ready = 'READY',
            noSignal = 'NO SIGNAL',
            lock = 'LOCK',
            unlock = 'UNLOCK',
            start = 'START',
            stop = 'STOP',
            trunk = 'TRUNK',
            closeAction = 'CLOSE',
            windows = 'WINDOWS',
            panic = 'PANIC',
            move = 'Move key fob',
            drag = 'Drag key fob',
            resize = 'Resize key fob',
            resizeWithScale = 'Resize key fob ({scale}%)',
            closeKeyFob = 'Close key fob',
            brandTitle = '{make} key fob',
            customBrandTitle = 'Custom vehicle key fob'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Vehicle controls are only available inside supported vehicles.',
        keyFobDisabled = 'Key fob controls are disabled.',
        useTouchscreenInside = 'Use the vehicle touchscreen while inside the vehicle.',
        noRecentVehicle = 'No recent driven vehicle found.',
        vehicleLockChanged = 'Vehicle {plate} {state}.',
        locked = 'locked',
        unlocked = 'unlocked',
        seatOccupied = 'That seat is occupied.',
        cannotAnchorHere = 'Cannot anchor here.',
        anchorTooFast = 'Slow below {speed} MPH before lowering the anchor.',
        anchorMoveBlocked = 'Raise the anchor before trying to move the boat.',
        cruiseUnavailable = 'Cruise control is only available while driving forward with the engine running.',
        cruiseSpeedRange = 'Cruise control is available between {min} and {max} MPH.',
        autopilotNoWaypoint = 'Set a map waypoint before starting autopilot.',
        autopilotUnavailable = 'Autopilot requires you to be airborne in the pilot seat with the engine running.',
        autopilotWaypointTooClose = 'Choose a waypoint at least {distance} meters away.',
        autopilotPlaneTooSlow = 'Reach at least {speed} MPH before starting plane autopilot.',
        hoverReleasedByInput = 'Hover disengaged because pilot input was detected.'
    },

    fobMessages = {
        ready = 'READY',
        disabled = 'DISABLED',
        exitVehicle = 'EXIT VEHICLE',
        noVehicle = 'NO VEHICLE',
        unsupported = 'UNSUPPORTED',
        tooFar = 'TOO FAR',
        noKey = 'NO KEY',
        noSignal = 'NO SIGNAL',
        locked = 'LOCKED',
        unlocked = 'UNLOCKED',
        engineOn = 'ENGINE ON',
        engineOff = 'ENGINE OFF',
        trunkOpen = 'TRUNK OPEN',
        trunkClosed = 'TRUNK CLOSED',
        noTrunk = 'NO TRUNK',
        windowsDown = 'WINDOWS DOWN',
        windowsUp = 'WINDOWS UP',
        panic = 'PANIC',
        panicOff = 'PANIC OFF'
    },

    keyMappings = {
        touchscreen = 'Toggle vehicle touchscreen controls',
        keyFob = 'Toggle vehicle key fob'
    },

    vehicleClasses = {
        [0] = 'Compacts',
        [1] = 'Sedans',
        [2] = 'SUVs',
        [3] = 'Coupes',
        [4] = 'Muscle',
        [5] = 'Sports Classics',
        [6] = 'Sports',
        [7] = 'Super',
        [8] = 'Motorcycles',
        [9] = 'Off-road',
        [10] = 'Industrial',
        [11] = 'Utility',
        [12] = 'Vans',
        [13] = 'Cycles',
        [14] = 'Boats',
        [15] = 'Helicopters',
        [16] = 'Planes',
        [17] = 'Service',
        [18] = 'Emergency',
        [19] = 'Military',
        [20] = 'Commercial',
        [21] = 'Trains',
        [22] = 'Open Wheel'
    },

    doors = {
        [0] = 'Driver',
        [1] = 'Passenger',
        [2] = 'Rear Left',
        [3] = 'Rear Right',
        [4] = 'Hood',
        [5] = 'Trunk'
    },

    seats = {
        [-1] = 'Driver',
        [0] = 'Passenger',
        [1] = 'Rear Left',
        [2] = 'Rear Right',
        [3] = 'Seat 5',
        [4] = 'Seat 6'
    },

    generic = {
        door = 'Door {number}',
        window = 'Window {number}',
        seat = 'Seat {number}'
    }
}
