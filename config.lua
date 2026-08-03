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
        22, -- jump
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
    -- 0r/0r-vehiclekeys, msk/msk_vehiclekeys, dusa/dusa_vehiclekeys, renewed/Renewed-Vehiclekeys, custom.
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
    76 -- handbrake
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
    trailer = true,
    roof = true,
    extras = true
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
