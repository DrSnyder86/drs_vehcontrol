Config = {}

Config.Locale = 'en'

Config.Command = 'vehcontrol'
Config.DefaultKey = 'U'

Config.AllowPassengers = true
Config.KeepInputWhileOpen = true
Config.CloseOnExitVehicle = true
Config.DisableNonDrivingControls = true

Config.RefreshInterval = 350
Config.ControlRequestTimeout = 850
Config.ActionRefreshDelay = 125

Config.ActionSecurity = {
    Enabled = true,
    Cooldown = 150,
    KeyFobCooldown = 250,
    PrintDeniedActions = false
}

Config.NetworkSync = {
    Enabled = true,
    StateBagName = 'drs_vehcontrol',
    ServerValidationDistance = 50.0,
    ServerRateLimit = 100,
    States = {
        anchor = true,
        hazards = true,
        interiorLight = true,
        radio = true,
        windows = true
    },
    CanUpdate = function(playerId, vehicle, patch)
        -- Add optional server-side ownership/job validation here.
        return true
    end
}

Config.Debug = {
    Enabled = false,
    Command = 'vehcontroldebug'
}

Config.LeaveEngineRunning = {
    Enabled = true,
    KeepIfEngineWasRunning = true,
    LongPressExit = true,
    HoldTime = 150,
    ControlGroup = 0,
    ExitControl = 75, -- F / INPUT_VEH_EXIT
    DriverOnly = true,
    KeepAliveTime = 3500,
    ExitFlags = 0
}

Config.Theme = {
    accent = '#4fd8ff',
    danger = '#f8041d',
    warning = '#ffb02e'
}

Config.InterfaceFrame = {
    Enabled = true
}

Config.Notifications = {
    -- standalone = GTA feed, qb = QBCore, qbx = Qbox, ox/ox_lib = ox_lib, auto = qbx/qb/ox when started, custom = use CustomNotify below.
    Provider = 'standalone',
    Duration = 3500,
    Position = 'top-right',
    TypeMap = {
        inform = 'primary',
        success = 'success',
        error = 'error',
        warning = 'warning'
    },
    CustomNotify = function(message, notifyType, duration)
        -- Add your own notification export/event here when Provider = 'custom'.
    end
}

Config.KeyFob = {
    Enabled = true,
    Command = 'keyfob',
    DefaultKey = 'K',
    MaxDistance = 35.0,
    KeepInput = true,
    AllowedControls = {
        21, -- sprint
        -- 22, -- jump
        30, -- move left/right
        31, -- move forward/back
        32, -- move forward
        33, -- move backward
        34, -- move left
        35, -- move right
        36 -- duck
    },
    -- Leave RequireKey false for standalone behavior. Set true to gate fob actions through KeyProvider.
    RequireKey = false,
    -- standalone, auto, qb/qb-vehiclekeys, qbx/qbx_vehiclekeys, qs/qs-vehiclekeys, wasabi/wasabi_carlock,
    -- 0r/0r-vehiclekeys, msk/msk_vehiclekeys, dusa/dusa_vehiclekeys, renewed/Renewed-Vehiclekeys,
    -- registered/runtime (RegisterKeyCheck export), custom.
    KeyProvider = 'standalone',
    AllowStandaloneFallback = false,
    ProviderPriority = {
        'qbx_vehiclekeys',
        'qb-vehiclekeys',
        'qs-vehiclekeys',
        'wasabi_carlock',
        '0r-vehiclekeys',
        'msk_vehiclekeys',
        'dusa_vehiclekeys',
        'Renewed-Vehiclekeys'
    },
    MessageDuration = 1800,
    PanicDuration = 7000,
    PanicHornInterval = 750,
    Interaction = {
        Animation = true,
        AnimationDict = 'anim@mp_player_intmenu@key_fob@',
        AnimationName = 'fob_click',
        AnimationBlendIn = 3.0,
        AnimationBlendOut = 3.0,
        AnimationDuration = -1,
        AnimationFlag = 49,
        AnimationLoadTimeout = 850,
        ClearTasksDelay = 750,
        Sound = true,
        SoundName = 'Remote_Control_Fob',
        SoundRef = 'PI_Menu_Sounds',
        SoundDuration = 900,
        UseQboxAudio = true,
        ActionDelay = 180
    },
    Actions = {
        locks = true,
        engine = true,
        trunk = true,
        windows = true,
        panic = true
    },
    Feedback = {
        FlashDuration = 130,
        FlashGap = 120,
        BeepDuration = 70,
        BeepGap = 110,
        LockBeeps = 1,
        UnlockBeeps = 2
    },
    -- Set KeyProvider = 'custom' and RequireKey = true to use your own key check.
    HasKey = function(vehicle, plate)
        return true
    end
}

Config.AllowedControlsWhileOpen = {
    59, -- vehicle steering
    60, -- vehicle move up/down
    61, -- vehicle accelerate analog
    62, -- vehicle brake analog
    63, -- vehicle left
    64, -- vehicle right
    71, -- accelerate
    72, -- brake/reverse
    -- 76, -- handbrake
    87, -- aircraft throttle up
    88, -- aircraft throttle down
    89, -- aircraft yaw left
    90, -- aircraft yaw right
    107, -- aircraft roll analog
    108, -- aircraft roll left
    109, -- aircraft roll right
    110, -- aircraft pitch analog
    111, -- aircraft pitch up
    112, -- aircraft pitch down
    113, -- aircraft landing gear
    119, -- aircraft vertical flight mode
    352 -- aircraft boost
}

Config.CloseControls = {
    177, -- back/cancel
    199, -- frontend pause
    200, -- pause / ESC
    202, -- frontend cancel
    322 -- ESC fallback
}

Config.Controls = {
    engine = true,
    locks = true,
    doors = true,
    windows = true,
    seats = true,
    radio = true,
    hazards = true,
    interiorLight = true,
    cruise = true,
    anchor = true,
    landingGear = true,
    trailer = true,
    roof = true,
    extras = true
}

Config.BoatAnchor = {
    MaxSpeedMph = 10.0
}

Config.CruiseControl = {
    MinSpeedMph = 20.0,
    MaxSpeedMph = 120.0,
    -- The maintained speed moves slowly below the set point instead of staying mathematically exact.
    HoldOffsetMph = 0.25,
    HoldVariationMph = 1.0,
    HoldVariationPeriodMs = 8000,
    CorrectionToleranceMph = 0.05,
    OverspeedAllowanceMph = 0.75,
    SpeedCorrection = true,
    PauseCorrectionWhileSteering = true,
    UseSpeedLimiter = true,
    DamageCancelThreshold = 75.0,
    -- When enabled, drs_vehcontrol yields cruise ownership while any listed resource is started.
    -- Add renamed or custom QB/Qbox cruise resources to this list.
    ExternalResourceCheck = {
        Enabled = false,
        CacheMs = 1000,
        Resources = {
            'qbx_smallresources',
            'qb-smallresources'
        }
    },
    AllowedClasses = {
        [0] = true, -- compacts
        [1] = true, -- sedans
        [2] = true, -- SUVs
        [3] = true, -- coupes
        [4] = true, -- muscle
        [5] = true, -- sports classics
        [6] = true, -- sports
        [7] = true, -- super
        [8] = true, -- motor
        [9] = true, -- off-road
        [10] = true, -- industrial
        [11] = true, -- utility
        [12] = true, -- vans
        [13] = true, -- cycle
        [14] = true, -- boats
        [15] = true, -- helicopters
        [16] = true, -- planes
        [17] = true, -- service
        [18] = true, -- emergency
        [19] = true, -- military
        [20] = true, -- commercial
        [21] = true, -- trains
        [22] = true, -- opem wheel
    }
}

Config.PassengerControls = {
    doors = true,
    seats = true,
    windows = true
}

Config.RestrictedVehicleClasses = {
    -- [13] = true, -- cycles
    -- [14] = true, -- boats
    -- [15] = true, -- helicopters
    -- [16] = true, -- planes
    -- [21] = true -- trains
}

-- Use a lowercase spawn name or model hash as the key. A false availability value hides that item;
-- true can force custom-model items that FiveM does not detect correctly.
Config.VehicleOverrides = {
    -- ['examplecar'] = {
    --     Enabled = true,
    --     Controls = { cruise = true, anchor = false, landingGear = false, roof = false, extras = false },
    --     FobActions = { engine = true, trunk = false, windows = true },
    --     KeyFobMaxDistance = 25.0,
    --     Doors = { [4] = false, [5] = true },
    --     Windows = { [2] = false, [3] = false },
    --     Seats = { [3] = false },
    --     Extras = { [1] = false },
    --     Labels = {
    --         Doors = { [5] = 'Rear Hatch' },
    --         Windows = {},
    --         Seats = {},
    --         Extras = {}
    --     }
    -- }
}

Config.VehicleClassLabels = {
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
}

Config.DoorLabels = {
    [0] = 'Driver',
    [1] = 'Passenger',
    [2] = 'Rear Left',
    [3] = 'Rear Right',
    [4] = 'Hood',
    [5] = 'Trunk'
}

Config.SeatLabels = {
    [-1] = 'Driver',
    [0] = 'Passenger',
    [1] = 'Rear Left',
    [2] = 'Rear Right',
    [3] = 'Seat 5',
    [4] = 'Seat 6'
}
