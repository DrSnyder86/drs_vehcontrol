# drs_vehcontrol

A modern compact vehicle control resource for FiveM. `drs_vehcontrol` adds a bottom-screen backlit touchscreen for in-vehicle controls and a matching smart key fob for controlling the last vehicle you drove while standing nearby.

The resource is standalone by default, with optional compatibility for popular vehicle key resources, QB/Qbox/ox_lib notifications, and `san_andreas_radio`.

## Features

- Compact bottom-screen touchscreen UI.
- Keybind and command support for the vehicle menu.
- Key fob UI for the last driven vehicle when outside the vehicle.
- Supersampled class-matched key fob cases for performance, luxury, rugged, fleet, tactical, motorcycle, and air/marine vehicles, with smooth accent trim that follows the player's selected color.
- Manufacturer-specific text styling in the key fob header, with a clean fallback for custom makes.
- Vehicle make, model, class, fuel, engine health, and San Andreas-style plate display.
- Cinematic class artwork backgrounds for vehicle classes.
- One optional supersampled touchscreen bezel with an accent mask that follows the player's selected color.
- Player UI settings saved locally:
  - Accent color presets.
  - Custom accent color.
  - UI brightness.
  - Photo overlay darkness for both the main UI and key fob LCD.
  - Moveable main UI with 65-100% scaling.
  - Moveable key fob with 62-116% scaling.
- Engine start/stop.
- Lock/unlock.
- Individual doors.
- Close all doors.
- Individual windows.
- All windows up/down.
- Seat switching.
- Radio on/off.
- Hazard lights.
- Interior light.
- Driver-only cruise control with configurable speed limits, safety cancellation, and optional QB/Qbox cruise-resource conflict detection.
- Driver-only waypoint autopilot for supported planes and helicopters, plus a position-and-heading hover mode for helicopters.
- Boat anchor toggle that holds position when the current location is safe and the boat is below the configured speed limit.
- Retractable landing-gear control for supported planes and helicopters.
- Trailer detach when a trailer is attached.
- Convertible roof toggle when supported.
- Vehicle extras toggle.
- Passenger support with limited controls.
- Per-model capability, label, fob-action, and range overrides for custom vehicles.
- Networked anchor, hazard, interior-light, radio-power, and window state through state bags.
- Shared action validation, network-control checks, and configurable cooldowns.
- Client/server exports and events for resource integrations.
- Optional vehicle diagnostics command for custom-model troubleshooting.
- ESC/back closes the UI before opening the pause menu.
- Driving and aircraft flight controls remain usable while the main vehicle menu is open.
- Walking controls remain usable while the key fob is open.
- Optional engine leave-running behavior:
  - Keep engine running when exiting if it was already running.
  - Long-press exit support.
- Key fob feedback:
  - Fob click animation.
  - Remote fob sound when available.
  - Light flashes.
  - Lock/unlock horn beeps.
  - Panic mode.
- Optional key fob key ownership checks through popular key resources.
- Optional QB/Qbox notification providers.
- Optional `san_andreas_radio` power sync from the radio button.

## Default Commands And Keys

| Action | Command | Default Key |
| --- | --- | --- |
| Vehicle touchscreen | `/vehcontrol` | `U` |
| Key fob | `/keyfob` | `K` |

Players can change registered FiveM keybinds in:

`Settings > Key Bindings > FiveM`

## Installation

1. Copy the `drs_vehcontrol` folder into your server resources folder.
2. Keep the folder name as `drs_vehcontrol`.
3. Add this to `server.cfg`:

```cfg
ensure drs_vehcontrol
```

4. If you use optional dependencies, start them before `drs_vehcontrol`:

```cfg
ensure qbx_core
ensure qbx_vehiclekeys
ensure ox_lib
ensure san_andreas_radio
ensure drs_vehcontrol
```

Only include the resources you actually use.

5. Restart the server or run:

```txt
refresh
ensure drs_vehcontrol
```

## Configuration

All main options are in `config.lua`.

### Basic Options

```lua
Config.Locale = 'en'

Config.Command = 'vehcontrol'
Config.DefaultKey = 'U'

Config.KeyFob.Command = 'keyfob'
Config.KeyFob.DefaultKey = 'K'
```

Supported locale codes are `en` (English), `cs` (Czech), `de` (German), `es` (Spanish), `fr` (French), `nl` (Dutch), `pt-br` (Brazilian Portuguese), and `tr` (Turkish).

### Touchscreen Frame

```lua
Config.InterfaceFrame = {
    Enabled = true
}
```

When enabled, the touchscreen uses `html/img/touchscreen_frames/touchscreen_default.png` with `touchscreen_default_accent.png` as its colorable accent mask. Both assets are rendered with supersampled edges for smooth curves and diagonals. Set `Enabled = false` to use the compact frameless layout. Custom replacements should remain `1440x480` and preserve the transparent screen opening.

### Passenger Controls

Passengers are allowed by default, but only for configured controls:

```lua
Config.AllowPassengers = true

Config.PassengerControls = {
    doors = true,
    seats = true,
    windows = true
}
```

### Enable Or Disable Controls

Use `Config.Controls` to disable controls you do not want:

```lua
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
    autopilot = true,
    anchor = true,
    landingGear = true,
    trailer = true,
    roof = true,
    extras = true
}
```

Headlight and turn signal controls are intentionally not included.

### Boat Anchor

```lua
Config.BoatAnchor = {
    MaxSpeedMph = 10.0,
    MoveAttemptNotifyCooldownMs = 1500,
    MovementControls = { 61, 62, 71, 72 }
}
```

The anchor can only be lowered while the boat is moving below this speed. Raising the anchor is always allowed. Lowering and raising it stay silent; if the driver presses a configured throttle or reverse control while it is down, the resource shows one warning per input attempt. `MoveAttemptNotifyCooldownMs` prevents rapid repeated attempts from spamming notifications.

### Cruise Control

```lua
Config.CruiseControl = {
    MinSpeedMph = 20.0,
    MaxSpeedMph = 120.0,
    HoldOffsetMph = 0.25,
    HoldVariationMph = 1.0,
    HoldVariationPeriodMs = 8000,
    CorrectionToleranceMph = 0.05,
    OverspeedAllowanceMph = 0.75,
    SpeedCorrection = true,
    PauseCorrectionWhileSteering = true,
    UseSpeedLimiter = true,
    DamageCancelThreshold = 75.0,
    CollisionCancel = {
        Enabled = true,
        EngagementGraceMs = 1000,
        CorroborationWindowMs = 750,
        SampleIntervalMs = 10,
        ContactReleaseMs = 150,
        MinimumImpactSpeedMph = 2.0,
        MinimumSpeedDropMph = 2.0,
        MinimumHealthLoss = 1.0
    },
    AdaptiveFollowing = {
        Enabled = true,
        ProbeIntervalMs = 150,
        MaxPendingProbeDrains = 4,
        ProbeRadiusMeters = 1.75,
        MinLookAheadMeters = 10.0,
        MaxLookAheadMeters = 30.0,
        LookAheadBufferMeters = 3.0,
        MinimumGapMeters = 6.0,
        TimeGapSeconds = 1.0,
        LeadLostGraceMs = 500,
        MinimumHeadingAlignment = 0.5,
        SlowDownRateMphPerSecond = 30.0,
        RecoveryRateMphPerSecond = 8.0
    },
    BoatEngineRpm = {
        Enabled = true,
        MinRpm = 0.35,
        MaxRpm = 0.85
    },
    ExternalResourceCheck = {
        Enabled = false,
        CacheMs = 1000,
        Resources = {
            'qbx_smallresources',
            'qb-smallresources'
        }
    },
    AllowedClasses = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [17] = true,
        [18] = true,
        [19] = true,
        [20] = true,
        [21] = true,
        [22] = true
    }
}
```

Cruise stores the current forward speed. For boats, it uses the horizontal forward speed so pitch and wave motion do not inflate the set point. Brake, handbrake, reverse, engine shutdown, loss of network control, leaving the driver seat, changing vehicles, unsupported controls, significant vehicle damage, and a corroborated impact cancel it. Pressing the accelerator temporarily restores the vehicle's normal maximum speed; releasing it returns to the current cruise target. Cruise is client-owned and is not synchronized to other players.

Road vehicles use the reliable per-frame grounded forward-speed correction found in Qbox-style implementations. They also use one bounded, asynchronous vehicle-only capsule probe at `ProbeIntervalMs` intervals. A pending probe is polled until FiveM reports terminal status 0 or 2; stopping or replacing cruise transfers that handle to a background drain queue instead of abandoning it. `MaxPendingProbeDrains` bounds that queue and temporarily defers new probes when all slots are occupied. When a slower, similarly aligned vehicle is detected ahead, the effective hold and limiter target moves toward the lead vehicle's speed. `MinimumGapMeters + current speed * TimeGapSeconds` determines the desired following gap; the target drops below the lead speed when that gap is too small. `SlowDownRateMphPerSecond` controls how quickly the target is reduced, while the lower `RecoveryRateMphPerSecond` restores the set speed smoothly after the path clears. `LeadLostGraceMs` filters brief missed probes.

The FiveM vehicle-intersection trace used by adaptive following has an approximately 30-meter mission-entity range, so runtime lookahead is hard-limited to 30 meters even if `MaxLookAheadMeters` is configured higher. This makes adaptive following a convenience aid rather than emergency braking, especially at high speed. It only runs for powered road classes; boats, bicycles, trains, and aircraft do not use it. While following, the resource applies the same bounded slowdown rate directly to the road vehicle's forward velocity while preserving lateral and vertical motion. Keep `UseSpeedLimiter = true` so the engine-speed ceiling follows that effective target too; disabling it leaves the direct slowdown active but removes the extra limiter bound.

`CollisionCancel` avoids cancelling from ordinary road and wheel contact by waiting `EngagementGraceMs` after activation and requiring GTA's collision state plus either `MinimumSpeedDropMph` or `MinimumHealthLoss`. Each contact episode captures the sample immediately before impact, then accumulates losses over the rolling `CorroborationWindowMs`, so sustained scraping or pushing can cancel even when no single frame crosses a threshold. `ContactReleaseMs` bridges brief observed collision-signal gaps without carrying evidence into a later unrelated contact. `SampleIntervalMs` keeps the rolling history frame-rate independent; runtime sampling may be coarsened for unusually large windows so the defensive 120-sample cap is retained. Forward-speed reductions deliberately commanded by adaptive following are subtracted from that evidence, preventing the controller's own slowdown from looking like an impact. This also catches lower-damage collisions that do not reach `DamageCancelThreshold`. Set `CollisionCancel.Enabled = false` to retain only the original damage threshold and control-based cancellation.

Boats use a water-only horizontal correction that preserves lateral drift and vertical velocity, allowing GTA's buoyancy and wave physics to remain in control. Instead of maintaining one mathematically exact speed, the internal hold target moves slowly between `HoldOffsetMph` and `HoldOffsetMph + HoldVariationMph` below the displayed set point. `HoldVariationPeriodMs` controls how quickly that subtle variation cycles.

For believable boat engine audio, cruise captures the engine RPM at engagement, clamps it between `BoatEngineRpm.MinRpm` and `BoatEngineRpm.MaxRpm`, and holds it while the real accelerator is released. Actual accelerator input takes over immediately, and cancellation returns RPM control to GTA. Set `BoatEngineRpm.Enabled = false` to disable this behavior. RPM-aware HUD and fuel resources will observe the held value as normal engine load.

`CorrectionToleranceMph` prevents tiny sub-pixel corrections, while `OverspeedAllowanceMph` permits a little natural downhill gain. Ordinary speed recovery pauses while steering by default, but adaptive safety slowdown remains active. Road corrections only run while all wheels are grounded; boat corrections only run while the vessel is in water.

Set `SpeedCorrection = false` if another handling resource should own vehicle velocity. Set `UseSpeedLimiter = false` if another resource owns `SetVehicleMaxSpeed`.

Set `ExternalResourceCheck.Enabled = true` on Qbox or QBCore servers where another resource owns cruise control. While any configured resource is started, the touchscreen cruise button is hidden and an active `drs_vehcontrol` cruise session is cancelled cleanly. The defaults recognize the stock `qbx_smallresources` and `qb-smallresources` cruise implementations; add renamed or custom cruise resource names to `Resources` as needed. This is a resource-ownership check because those stock implementations do not expose their active cruise state.

Aircraft classes 15 and 16 are intentionally excluded from ordinary cruise control by default. They use the waypoint autopilot below, and the two systems cancel one another if their class settings are customized to overlap.

### Aircraft Waypoint Autopilot

```lua
Config.Autopilot = {
    MinActivationHeight = 10.0,
    MinTerrainClearance = 30.0,
    DamageCancelThreshold = 75.0,
    ManualInputThreshold = 0.20,
    ManualInputGraceMs = 500,
    UiCloseInputGraceMs = 250,
    CancelControls = {
        59, 60, 61, 62, 71, 72,
        87, 88, 89, 90,
        107, 108, 109, 110, 111, 112,
        119, 122, 352
    },
    AllowedClasses = {
        [15] = true,
        [16] = true
    },
    Plane = {
        MinSpeedMph = 60.0,
        MaxSpeedMph = 250.0,
        MinWaypointDistance = 500.0,
        ArrivalRadius = 300.0,
        MinTerrainClearance = 100.0,
        OrbitEntryRadius = 1200.0,
        OrbitEntryMargin = 400.0,
        OrbitEntryLeadSeconds = 10.0,
        OrbitMinRadius = 700.0,
        OrbitMaxBankDegrees = 25.0,
        OrbitLeadDegrees = 60.0,
        OrbitTerrainSamples = 12,
        OrbitAdvanceDistance = 300.0,
        OrbitTaskReachedDistance = 75.0,
        OrbitAltitudeBuffer = 100.0,
        OrbitAltitudeTolerance = 10.0,
        OrbitTaskRefreshMs = 3000,
        OrbitPointTimeoutMs = 15000,
        OrbitAltitudeAssistMaxClimbMps = 8.0,
        OrbitEmergencyTerrainClearance = 75.0,
        OrbitEmergencyClimbRateMps = 12.0
    },
    Helicopter = {
        MinSpeedMph = 10.0,
        WaypointSpeedMph = 35.0,
        MaxSpeedMph = 120.0,
        MinWaypointDistance = 50.0,
        ArrivalRadius = 25.0,
        SlowDownDistance = 100.0,
        HoldRefreshMs = 2500,
        HoldRadius = 3.0,
        HoldSpeedMph = 5.0,
        HorizontalControl = {
            Enabled = true,
            AccelerationMps2 = 3.0,
            DecelerationMps2 = 5.0,
            YawRateDegPerSecond = 45.0,
            YawDeadzoneDegrees = 1.0,
            MinimumAlignment = 0.15,
            VelocityDeadzoneMps = 0.05,
            MaxDeltaTimeSeconds = 0.05
        },
        VerticalControl = {
            Enabled = true,
            Gain = 0.35,
            DeadzoneMeters = 1.0,
            MaxClimbMps = 5.0,
            MaxDescentMps = 3.0
        },
        HoverMinActivationHeight = 2.0,
        HoverSpeedMph = 2.0,
        HoverRadius = 2.0,
        HoverSlowDownDistance = 15.0,
        HoverRefreshMs = 1000
    }
}
```

Autopilot is available to the driver of a running, driveable plane or helicopter after a map waypoint is set. In the Vehicle tab, Autopilot replaces Cruise for supported aircraft. Activation must be above `MinActivationHeight` from the ground or calm water surface; planes must already meet `Plane.MinSpeedMph`, and the waypoint must be at least the configured minimum horizontal distance away. Helicopters can engage waypoint flight from a hover or very low speed with no forward-speed activation requirement. `Helicopter.WaypointSpeedMph` is the commanded forward travel speed, while `MinSpeedMph` remains its lower command bound. Speeds are MPH. Heights, waypoint distances, and arrival radii are meters.

Planes capture their current world altitude and fly toward the waypoint. Orbit entry begins at the largest of `OrbitEntryRadius`, the speed-based `OrbitEntryLeadSeconds` distance, or the calculated turn radius plus `OrbitEntryMargin`. The resource establishes a terrain-safe hold altitude using `MinTerrainClearance` and `OrbitAltitudeBuffer`, preserves the plane's arrival speed, and guides it around speed-adaptive moving GOTO points instead of handing it to GTA's native circle mission. Initial orbit altitude samples the waypoint center plus `OrbitTerrainSamples` evenly spaced points around the speed-scaled ring, and every moving target is rechecked against terrain before it is issued. `OrbitMinRadius`, `OrbitMaxBankDegrees`, and `OrbitLeadDegrees` shape the route; the advance-distance, reached-distance, refresh, and timeout settings control when the next point is issued. The altitude-assist and emergency-clearance settings add a final climb guard while orbiting so arrival does not pull the aircraft into the ground.

Helicopters capture their current height above the ground or calm water surface and maintain that terrain-relative clearance instead of first climbing to `MinTerrainClearance`. Waypoint mode is controlled entirely by the resource: its deterministic horizontal controller turns the helicopter toward the marker and applies bounded forward velocity, while its vertical controller maintains the captured terrain-relative height. No native helicopter mission task controls the flight axes during waypoint travel. The controller slows near the destination and corrects toward a localized `HoldRadius` at `HoldSpeedMph`. `HorizontalControl` tunes acceleration, deceleration, yaw, alignment, velocity deadzone, and frame-time limits; `VerticalControl` tunes height correction gain, deadzone, climb, and descent limits. Both controller `Enabled` values must remain `true`; waypoint activation is rejected if either required controller is disabled. `Helicopter.HoldRefreshMs` controls how often waypoint state is refreshed.

Helicopters also receive a separate Hover button on the Utility page. Hover can engage at any travel speed once airborne above `HoverMinActivationHeight`; it captures the current position, heading, world Z, and surface clearance. The native helicopter mission is used only for this Utility-page Hover mode and corrects back toward that fixed point at `HoverSpeedMph`. `HoverRadius`, `HoverSlowDownDistance`, and `HoverRefreshMs` tune how tightly and frequently the hold is corrected. Starting Hover replaces waypoint autopilot and starting waypoint autopilot replaces Hover.

`CancelControls` contains GTA gameplay control IDs watched for pilot takeover. After `ManualInputGraceMs`, input at or above `ManualInputThreshold` cancels autopilot or Hover. A manual movement attempt while Hover is active releases Hover and shows one deterministic warning; normal activation and button deactivation stay silent. Frontend/NUI controls are not sampled, and `UiCloseInputGraceMs` lets the touchscreen close input clear without disengaging flight control. It also cancels when the aircraft lands, the driver leaves or changes vehicles, the engine stops, the aircraft becomes undriveable or unsupported, accumulated engine/body damage exceeds `DamageCancelThreshold`, ordinary cruise starts, or the resource stops. Pressing the active Autopilot or Hover button again cancels it manually.

This is an experimental player-pilot feature. Planes combine GTA's aircraft mission tasks with resource-level orbit and altitude corrections; helicopter waypoint travel is solely resource-controlled, with a native helicopter mission reserved for Utility Hover. Direct waypoint travel still requires a clear route and does not guarantee obstacle avoidance. In-game testing is required for the aircraft models and server build you support; plane turns and helicopter hover stability can vary with handling data and native behavior.

### Leave Engine Running

```lua
Config.LeaveEngineRunning = {
    Enabled = true,
    KeepIfEngineWasRunning = true,
    LongPressExit = true,
    HoldTime = 150,
    DriverOnly = true
}
```

When enabled, the engine can stay running when the driver exits. Long-press exit also keeps the engine alive cleanly.

### Notifications

Notification providers:

- `standalone`
- `auto`
- `qb`
- `qbx`
- `ox`
- `ox_lib`
- `custom`

```lua
Config.Notifications = {
    Provider = 'standalone',
    Duration = 3500,
    Position = 'top-right'
}
```

Use `auto` to prefer Qbox when `qbx_core` is started, then QBCore when `qb-core` is started, then ox_lib when `ox_lib` is started, then standalone GTA feed notifications.

For custom notifications:

```lua
Config.Notifications.Provider = 'custom'

Config.Notifications.CustomNotify = function(message, notifyType, duration)
    -- Add your notify export/event here.
end
```

### Key Fob Ownership Checks

Standalone mode does not require a key:

```lua
Config.KeyFob.RequireKey = false
Config.KeyFob.KeyProvider = 'standalone'
```

To gate fob actions through a key resource:

```lua
Config.KeyFob.RequireKey = true
Config.KeyFob.KeyProvider = 'auto'
```

Supported provider names:

- `standalone`
- `auto`
- `qb` or `qb-vehiclekeys`
- `qbx` or `qbx_vehiclekeys`
- `qs` or `qs-vehiclekeys`
- `wasabi` or `wasabi_carlock`
- `0r` or `0r-vehiclekeys`
- `msk` or `msk_vehiclekeys`
- `dusa` or `dusa_vehiclekeys`
- `renewed` or `Renewed-Vehiclekeys`
- `registered` or `runtime`
- `custom`

For custom key checks:

```lua
Config.KeyFob.RequireKey = true
Config.KeyFob.KeyProvider = 'custom'

Config.KeyFob.HasKey = function(vehicle, plate)
    return true
end
```

Set this in `drs_vehcontrol/config.lua`:

```lua
Config.KeyFob.RequireKey = true
Config.KeyFob.KeyProvider = 'registered'
```

Then register the check from another client resource:

```lua
exports['drs_vehcontrol']:RegisterKeyCheck(function(vehicle, plate, modelName)
    return true
end)
```

### Key Fob Interaction Feel

```lua
Config.KeyFob.Interaction = {
    Animation = true,
    AnimationDict = 'anim@mp_player_intmenu@key_fob@',
    AnimationName = 'fob_click',
    Sound = true,
    SoundName = 'Remote_Control_Fob',
    SoundRef = 'PI_Menu_Sounds',
    ActionDelay = 180
}
```

`ActionDelay` controls the short delay after the fob click before the action happens.

### Restricted Vehicle Classes

Disable the UI for any unwanted classes:

```lua
Config.RestrictedVehicleClasses = {
    [13] = true, -- cycles
    [14] = true, -- boats
    [15] = true, -- helicopters
    [16] = true, -- planes
    [21] = true -- trains
}
```

Set a class to `false` or remove it if you want controls available for that class.

### Vehicle Overrides

Use a lowercase spawn name or model hash to correct unusual custom vehicles. `false` hides an item and `true` can force an item that native detection misses.

```lua
Config.VehicleOverrides = {
    ['examplecar'] = {
        Enabled = true,
        Controls = {
            cruise = true,
            autopilot = false,
            anchor = false,
            landingGear = false,
            roof = false,
            extras = false
        },
        FobActions = {
            engine = true,
            trunk = false,
            windows = true
        },
        KeyFobMaxDistance = 25.0,
        Doors = {
            [4] = false,
            [5] = true
        },
        Windows = {
            [2] = false,
            [3] = false
        },
        Seats = {
            [3] = false
        },
        Extras = {
            [1] = false
        },
        Labels = {
            Doors = { [5] = 'Rear Hatch' },
            Windows = {},
            Seats = {},
            Extras = {}
        }
    }
}
```

### Network Synchronization

Auxiliary state is synchronized through a server-owned entity state bag. The server sanitizes state names, verifies the network entity and player distance, and rate-limits updates.

```lua
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
        return true
    end
}
```

Set an individual state to `false` when another resource is its source of truth. `CanUpdate` can add server-side ownership, key, or job validation. Network synchronization requires networked vehicles and a server using OneSync/state bags.

### Action Validation

```lua
Config.ActionSecurity = {
    Enabled = true,
    Cooldown = 150,
    KeyFobCooldown = 250,
    PrintDeniedActions = false
}
```

`Enabled` controls cooldown enforcement; core seat permissions, entity validation, and network-control checks always remain active. The fob also checks keys, range, model permissions, entity existence, and network control again after its animation delay before performing an action.

### Debug Diagnostics

```lua
Config.Debug = {
    Enabled = true,
    Command = 'vehcontroldebug'
}
```

Run `/vehcontroldebug` in or near the last driven vehicle. The F8 console receives model, class, network, key-provider, override, control, door, window, seat, extra, and synchronized-state information.

## Optional Compatibility

### san_andreas_radio

If `san_andreas_radio` is started, the Radio button also sends:

```lua
TriggerServerEvent('san_andreas_radio:server:setPower', netId, powered)
```

This lets the button power off/on the synced custom radio state while preserving native standalone radio behavior.

### Qbox Audio

When available, key fob sounds can use `qbx.playAudio`. This is controlled by:

```lua
Config.KeyFob.Interaction.UseQboxAudio = true
```

If Qbox audio is unavailable, the resource falls back to native FiveM sound playback.

## Integration API

### Client Exports

```lua
exports['drs_vehcontrol']:Open()
exports['drs_vehcontrol']:Close()
exports['drs_vehcontrol']:Toggle()
exports['drs_vehcontrol']:OpenKeyFob()
exports['drs_vehcontrol']:CloseKeyFob()

local isOpen = exports['drs_vehcontrol']:IsOpen()
local openState = exports['drs_vehcontrol']:GetOpenState()
local vehicleState = exports['drs_vehcontrol']:GetVehicleState()
local fobState = exports['drs_vehcontrol']:GetKeyFobState()
local diagnostics = exports['drs_vehcontrol']:GetVehicleDiagnostics(vehicle)
local lastVehicle = exports['drs_vehcontrol']:GetLastVehicle()

exports['drs_vehcontrol']:SetLastVehicle(vehicle)
exports['drs_vehcontrol']:SetSyncedState(vehicle, { hazards = true })
exports['drs_vehcontrol']:ClearKeyCheck()
```

### Client Events

```lua
TriggerEvent('drs_vehcontrol:client:open')
TriggerEvent('drs_vehcontrol:client:close')
TriggerEvent('drs_vehcontrol:client:openKeyFob')
TriggerEvent('drs_vehcontrol:client:setLastVehicle', netId)
TriggerEvent('drs_vehcontrol:client:debug')

AddEventHandler('drs_vehcontrol:client:action', function(payload)
    print(payload.action, payload.vehicle, payload.netId, payload.plate)
    -- payload.details contains id, active, all, and source where applicable.
end)
```

### Server Exports

```lua
exports['drs_vehcontrol']:SetVehicleState(vehicleOrNetId, {
    hazards = true,
    interiorLight = false,
    radio = true,
    windows = { [0] = false, [1] = false }
})

local syncedState = exports['drs_vehcontrol']:GetVehicleState(vehicleOrNetId)
```

## File Structure

```txt
drs_vehcontrol/
  client/main.lua
  server/main.lua
  config.lua
  fxmanifest.lua
  html/
    index.html
    app.js
    style.css
    img/classes/
    img/fob_frames/
    img/touchscreen_frames/
    img/icons/
  locales/*.lua
```

## Troubleshooting

### The menu does not open

- Make sure you are inside a supported vehicle class.
- Check `Config.RestrictedVehicleClasses`.
- Confirm the resource is started with `ensure drs_vehcontrol`.
- Try the command directly: `/vehcontrol`.
- Check F8/client console for Lua or NUI errors.

### The key fob says no key

- If you want standalone behavior, set:

```lua
Config.KeyFob.RequireKey = false
Config.KeyFob.KeyProvider = 'standalone'
```

- If using a key resource, make sure it starts before `drs_vehcontrol`.
- If using `auto`, verify your key resource name matches the provider list.
- If your key resource uses a custom API, use `KeyProvider = 'custom'` and implement `Config.KeyFob.HasKey`.

### The key fob says no signal

- The fob only targets the last vehicle you drove.
- Move closer to the vehicle.
- Increase this value if needed:

```lua
Config.KeyFob.MaxDistance = 35.0
```

### The UI opens but controls do nothing

- Another resource may be immediately overriding the same vehicle state.

### Nearby players do not see synchronized states

- Confirm OneSync and entity state bags are available on the server.
- Confirm `server/main.lua` is loaded by `fxmanifest.lua`.
- Check that the state is enabled under `Config.NetworkSync.States`.
- Make sure `CanUpdate` is not rejecting the player.
- Increase `ServerValidationDistance` if the configured fob range is larger.
- Disable the relevant synchronized state when another resource owns it.
- Check vehicle ownership/key restrictions.
- Check OneSync/entity control issues if the vehicle is remote or recently spawned.
- Increase this if control requests are timing out:

```lua
Config.ControlRequestTimeout = 850
```

### ESC still opens the pause menu

- Make sure `Config.CloseControls` still includes `200`, `202`, and `322`.
- Check for other resources disabling or capturing frontend controls.

### The radio button does not affect san_andreas_radio

- Confirm `san_andreas_radio` is started.
- Start it before `drs_vehcontrol` in `server.cfg`.
- Make sure the player is in a seat allowed to control the radio by `san_andreas_radio`.
- Check that the target vehicle is networked.

### The UI is too bright or the photos are too visible

Open the Settings tab in the vehicle UI:

- Use `Brightness` > `UI` for overall UI brightness.
- Use `Brightness` > `Photo` for the class artwork overlay darkness.

### The touchscreen or key fob is too large

- Open the touchscreen Settings tab and use `Position` > `Size` to scale the complete main UI from 65% to 100%.
- Use the resize icon beside the fob panic button to cycle through fob sizes from 116% down to 62%.
- Both sizes and positions are saved locally for each player.

### Icons or class artwork are missing

- Confirm these file patterns are still included in `fxmanifest.lua`:

```lua
'html/img/classes/*.png',
'html/img/icons/*.png'
```

- Clear your FiveM cache if old NUI assets are still showing.

## License

This resource is released under the DrSnyder No-Resale License. You may use,
modify, and share it for free, but you may not sell it, include it in paid
resource packs, or sell modified versions. See `LICENSE`.
