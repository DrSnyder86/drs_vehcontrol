# drs_vehcontrol

A modern compact vehicle control resource for FiveM. `drs_vehcontrol` adds a bottom-screen backlit touchscreen for in-vehicle controls and a matching smart key fob for controlling the last vehicle you drove while standing nearby.

The resource is standalone by default, with optional compatibility for popular vehicle key resources, QB/Qbox/ox_lib notifications, and `san_andreas_radio`.

## Features

- Compact bottom-screen touchscreen UI.
- Keybind and command support for the vehicle menu.
- Key fob UI for the last driven vehicle when outside the vehicle.
- Class-matched key fob case styles for performance, luxury, rugged, fleet, tactical, motorcycle, and air/marine vehicles, with trim that follows the player's selected accent color.
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
- `custom`

For custom key checks:

```lua
Config.KeyFob.RequireKey = true
Config.KeyFob.KeyProvider = 'custom'

Config.KeyFob.HasKey = function(vehicle, plate)
    return true
end
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

The UI is disabled for some classes by default:

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

## File Structure

```txt
drs_vehcontrol/
  client/main.lua
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
