# drs_vehcontrol

A modern compact vehicle control resource for FiveM. `drs_vehcontrol` adds a bottom-screen backlit touchscreen for in-vehicle controls and a matching smart key fob for controlling the last vehicle you drove while standing nearby.

The resource is standalone by default, with optional compatibility for popular vehicle key resources, QB/Qbox/ox_lib notifications, and `san_andreas_radio`.

## Features

- Compact bottom-screen touchscreen UI.
- Keybind and command support for the vehicle menu.
- Key fob UI for the last driven vehicle when outside the vehicle.
- Class-matched key fob case styles for performance, luxury, rugged, fleet, tactical, motorcycle, and air/marine vehicles, with trim that follows the player's selected accent color.
- Manufacturer-specific text styling in the key fob header, with a clean fallback for custom makes.
- Vehicle make, model, class, fuel, engine health, and San Andreas-style plate display.
- Cinematic class artwork backgrounds for vehicle classes.
- Player UI settings saved locally:
  - Accent color presets.
  - Custom accent color.
  - UI brightness.
  - Photo overlay darkness for both the main UI and key fob LCD.
  - Moveable main UI.
  - Moveable and resizable key fob.
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
- Trailer detach when a trailer is attached.
- Convertible roof toggle when supported.
- Vehicle extras toggle.
- Passenger support with limited controls.
- Per-model capability, label, fob-action, and range overrides for custom vehicles.
- Networked hazard, interior-light, radio-power, and window state through state bags.
- Shared action validation, network-control checks, and configurable cooldowns.
- Client/server exports and events for resource integrations.
- Optional vehicle diagnostics command for custom-model troubleshooting.
- ESC/back closes the UI before opening the pause menu.
- Driving controls remain usable while the main vehicle menu is open.
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
    trailer = true,
    roof = true,
    extras = true
}
```

Headlight and turn signal controls are intentionally not included.

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
    img/icons/
  locales/*.lua
  tools/generate_fob_frames.js
  tools/test_locales.lua
  tools/test_server_sync.lua
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
