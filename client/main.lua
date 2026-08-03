local uiOpen = false
local fobOpen = false
local vehicleToggles = {}
local leaveRunningVehicle = 0
local leaveRunningUntil = 0
local lastDrivenVehicle = 0
local fobPanicVehicle = 0
local fobPanicUntil = 0
local fobDisplayMessage = ''
local fobDisplayUntil = 0
local suppressPauseUntil = 0
local defaultCloseControls = { 177, 199, 200, 202, 322 }

local function getLocaleData()
    local localeName = Config.Locale or 'en'
    return (Locales and (Locales[localeName] or Locales.en)) or {}
end

local function findLocaleValue(path)
    local current = getLocaleData()

    for segment in tostring(path):gmatch('[^.]+') do
        if type(current) ~= 'table' then
            return nil
        end

        current = current[segment]
    end

    return current
end

local function replaceLocaleTokens(value, replacements)
    if type(value) ~= 'string' or type(replacements) ~= 'table' then
        return value
    end

    return (value:gsub('{([%w_]+)}', function(key)
        local replacement = replacements[key]

        if replacement == nil then
            return '{' .. key .. '}'
        end

        return tostring(replacement)
    end))
end

local function L(path, replacements, fallback)
    local value = findLocaleValue(path)

    if type(value) ~= 'string' then
        value = fallback or path
    end

    return replaceLocaleTokens(value, replacements)
end

local function fobMessage(name)
    return L('fobMessages.' .. name)
end

local function isResourceStarted(resource)
    return type(resource) == 'string' and resource ~= '' and GetResourceState(resource) == 'started'
end

local function callResourceExport(resource, exportName, ...)
    if not isResourceStarted(resource) then
        return nil
    end

    local ok, result = pcall(function(...)
        local resourceExports = exports[resource]
        local exportFunction = resourceExports and resourceExports[exportName]

        if type(exportFunction) ~= 'function' then
            return nil
        end

        return exportFunction(resourceExports, ...)
    end, ...)

    if not ok then
        return nil
    end

    return result
end

local function setSanAndreasRadioPower(vehicle, powered)
    if not isResourceStarted('san_andreas_radio') or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId > 0 then
        TriggerServerEvent('san_andreas_radio:server:setPower', netId, powered == true)
    end
end

local function normalizePlate(plate)
    return tostring(plate or ''):gsub('^%s*(.-)%s*$', '%1')
end

local function getVehicleModelName(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return ''
    end

    return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
end

local function isEnabled(name)
    return Config.Controls[name] ~= false
end

local function getPed()
    return PlayerPedId()
end

local function getVehicle()
    local ped = getPed()

    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end

    return GetVehiclePedIsIn(ped, false)
end

local function getVehicleKey(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return 'none'
    end

    if NetworkGetEntityIsNetworked(vehicle) then
        return ('net:%s'):format(NetworkGetNetworkIdFromEntity(vehicle))
    end

    return ('entity:%s'):format(vehicle)
end

local function getStoredVehicleState(vehicle)
    local key = getVehicleKey(vehicle)

    vehicleToggles[key] = vehicleToggles[key] or {
        radio = true,
        hazards = false,
        interiorLight = false,
        windows = {}
    }

    return vehicleToggles[key]
end

local function hasVehicleAccess(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local class = GetVehicleClass(vehicle)
    if Config.RestrictedVehicleClasses[class] then
        return false
    end

    if Config.AllowPassengers then
        return true
    end

    return GetPedInVehicleSeat(vehicle, -1) == getPed()
end

local function isDriver(vehicle)
    return vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == getPed()
end

local function canUseVehicleControl(vehicle, name)
    if not isEnabled(name) then
        return false
    end

    if isDriver(vehicle) then
        return true
    end

    if not Config.AllowPassengers then
        return false
    end

    local passengerControls = Config.PassengerControls or {}
    return passengerControls[name] == true
end

local function getEnabledControls(vehicle)
    local controls = {}

    for name in pairs(Config.Controls) do
        controls[name] = canUseVehicleControl(vehicle, name)
    end

    return controls
end

local function requestVehicleControl(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    if not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle) then
        return true
    end

    local timeout = GetGameTimer() + (tonumber(Config.ControlRequestTimeout) or 850)

    repeat
        NetworkRequestControlOfEntity(vehicle)
        Wait(0)
    until NetworkHasControlOfEntity(vehicle) or GetGameTimer() > timeout

    return NetworkHasControlOfEntity(vehicle)
end

local function getKeyFobConfig()
    return Config.KeyFob or {}
end

local function getKeyFobActions()
    return getKeyFobConfig().Actions or {}
end

local function getKeyFobFeedback()
    return getKeyFobConfig().Feedback or {}
end

local function getKeyFobInteraction()
    return getKeyFobConfig().Interaction or {}
end

local function getLastDrivenVehicle()
    if lastDrivenVehicle ~= 0 and DoesEntityExist(lastDrivenVehicle) then
        return lastDrivenVehicle
    end

    return 0
end

local function getVehicleDistance(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    return #(GetEntityCoords(getPed()) - GetEntityCoords(vehicle))
end

local function providerReturn(result)
    if result == nil then
        return false, false
    end

    return true, result == true
end

local function checkKeyProvider(provider, vehicle, plate, modelName)
    local providerResource = tostring(provider or '')
    provider = providerResource:lower()

    if provider == 'standalone' then
        return true, true
    end

    if provider == 'custom' then
        local config = getKeyFobConfig()

        if type(config.HasKey) ~= 'function' then
            return true, false
        end

        local ok, allowed = pcall(config.HasKey, vehicle, plate, modelName)
        return true, ok and allowed == true
    end

    if provider == 'qbx' or provider == 'qbx_vehiclekeys' then
        return providerReturn(callResourceExport('qbx_vehiclekeys', 'HasKeys', vehicle))
    end

    if provider == 'qb' or provider == 'qb-vehiclekeys' then
        return providerReturn(callResourceExport('qb-vehiclekeys', 'HasKeys', plate))
    end

    if provider == 'qs' or provider == 'qs-vehiclekeys' then
        return providerReturn(callResourceExport('qs-vehiclekeys', 'GetKey', plate))
    end

    if provider == 'wasabi' or provider == 'wasabi_carlock' then
        return providerReturn(callResourceExport('wasabi_carlock', 'HasKey', plate))
    end

    if provider == '0r' or provider == '0r-vehiclekeys' then
        return providerReturn(callResourceExport('0r-vehiclekeys', 'HasKeys', plate))
    end

    if provider == 'msk' or provider == 'msk_vehiclekeys' then
        local checked, allowed = providerReturn(callResourceExport('msk_vehiclekeys', 'HasPlayerKeyOrIsVehicleOwner', vehicle))

        if checked then
            return checked, allowed
        end

        return providerReturn(callResourceExport('msk_vehiclekeys', 'HasPlayerKey', vehicle))
    end

    if provider == 'dusa' or provider == 'dusa_vehiclekeys' then
        return providerReturn(callResourceExport('dusa_vehiclekeys', 'HasKeys', plate))
    end

    if provider == 'renewed' or provider == 'renewed-vehiclekeys' then
        local checked, allowed = providerReturn(callResourceExport('Renewed-Vehiclekeys', 'hasKey', plate))

        if checked then
            return checked, allowed
        end

        return providerReturn(callResourceExport('Renewed-Vehiclekeys', 'hasKey'))
    end

    return providerReturn(callResourceExport(providerResource, 'HasKeys', plate))
end

local function hasKeyFobKey(vehicle)
    local config = getKeyFobConfig()

    if config.RequireKey ~= true then
        return true
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local modelName = getVehicleModelName(vehicle)
    local provider = config.KeyProvider or 'standalone'

    if provider == 'auto' then
        for _, providerName in ipairs(config.ProviderPriority or {}) do
            local checked, allowed = checkKeyProvider(providerName, vehicle, plate, modelName)

            if checked then
                return allowed
            end
        end

        return config.AllowStandaloneFallback == true
    end

    local checked, allowed = checkKeyProvider(provider, vehicle, plate, modelName)

    if checked then
        return allowed
    end

    return config.AllowStandaloneFallback == true
end

local function keyFobActionEnabled(name)
    local actions = getKeyFobActions()
    return actions[name] ~= false
end

local function getKeyFobTargetStatus()
    local config = getKeyFobConfig()

    if config.Enabled == false then
        return false, 0, fobMessage('disabled')
    end

    if IsPedInAnyVehicle(getPed(), false) then
        return false, 0, fobMessage('exitVehicle')
    end

    local vehicle = getLastDrivenVehicle()
    if vehicle == 0 then
        return false, 0, fobMessage('noVehicle')
    end

    if Config.RestrictedVehicleClasses[GetVehicleClass(vehicle)] then
        return false, vehicle, fobMessage('unsupported')
    end

    local distance = getVehicleDistance(vehicle)
    local maxDistance = tonumber(config.MaxDistance) or 35.0

    if not distance or distance > maxDistance then
        return false, vehicle, fobMessage('tooFar')
    end

    if not hasKeyFobKey(vehicle) then
        return false, vehicle, fobMessage('noKey')
    end

    return true, vehicle, fobMessage('ready')
end

local function setVehicleLightsForced(vehicle, enabled)
    SetVehicleLights(vehicle, enabled and 2 or 0)
    SetVehicleFullbeam(vehicle, enabled)
end

local function flashVehicleLights(vehicle, count)
    local feedback = getKeyFobFeedback()
    local flashDuration = tonumber(feedback.FlashDuration) or 130
    local flashGap = tonumber(feedback.FlashGap) or 120

    CreateThread(function()
        for _ = 1, count do
            if vehicle == 0 or not DoesEntityExist(vehicle) then
                return
            end

            setVehicleLightsForced(vehicle, true)
            Wait(flashDuration)
            setVehicleLightsForced(vehicle, false)
            Wait(flashGap)
        end
    end)
end

local function beepVehicleHorn(vehicle, count)
    local feedback = getKeyFobFeedback()
    local beepDuration = tonumber(feedback.BeepDuration) or 70
    local beepGap = tonumber(feedback.BeepGap) or 110

    CreateThread(function()
        for _ = 1, count do
            if vehicle == 0 or not DoesEntityExist(vehicle) then
                return
            end

            StartVehicleHorn(vehicle, beepDuration, GetHashKey('NORMAL'), false)
            Wait(beepDuration + beepGap)
        end
    end)
end

local function requestAnimDict(dict, timeout)
    if not dict or dict == '' then
        return false
    end

    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)

    local expires = GetGameTimer() + (tonumber(timeout) or 850)

    while not HasAnimDictLoaded(dict) and GetGameTimer() < expires do
        Wait(0)
    end

    return HasAnimDictLoaded(dict)
end

local function playKeyFobSound(vehicle, interaction)
    if interaction.Sound == false or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    local audioName = interaction.SoundName or 'Remote_Control_Fob'
    local audioRef = interaction.SoundRef or 'PI_Menu_Sounds'

    if interaction.UseQboxAudio ~= false and type(qbx) == 'table' and type(qbx.playAudio) == 'function' then
        local ok = pcall(qbx.playAudio, {
            audioName = audioName,
            audioRef = audioRef,
            source = vehicle
        })

        if ok then
            return
        end
    end

    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, audioName, vehicle, audioRef, false, 0)

    CreateThread(function()
        Wait(tonumber(interaction.SoundDuration) or 900)
        ReleaseSoundId(soundId)
    end)
end

local function playKeyFobInteraction(vehicle)
    local interaction = getKeyFobInteraction()
    local ped = getPed()

    playKeyFobSound(vehicle, interaction)

    if interaction.Animation == false or ped == 0 or IsEntityDead(ped) then
        return
    end

    local dict = interaction.AnimationDict or 'anim@mp_player_intmenu@key_fob@'

    if not requestAnimDict(dict, interaction.AnimationLoadTimeout) then
        return
    end

    TaskPlayAnim(
        ped,
        dict,
        interaction.AnimationName or 'fob_click',
        tonumber(interaction.AnimationBlendIn) or 3.0,
        tonumber(interaction.AnimationBlendOut) or 3.0,
        tonumber(interaction.AnimationDuration) or -1,
        tonumber(interaction.AnimationFlag) or 49,
        0.0,
        false,
        false,
        false
    )

    CreateThread(function()
        Wait(tonumber(interaction.ClearTasksDelay) or 750)

        if DoesEntityExist(ped) then
            ClearPedTasks(ped)
        end
    end)
end

local function keyFobFeedback(vehicle, flashes, beeps)
    flashVehicleLights(vehicle, flashes or 1)

    if beeps and beeps > 0 then
        beepVehicleHorn(vehicle, beeps)
    end
end

local function getLeaveEngineConfig()
    return Config.LeaveEngineRunning or {}
end

local function isExitControlJustPressed(config)
    local group = config.ControlGroup or 0
    local control = config.ExitControl or 75

    return IsControlJustPressed(group, control)
        or IsDisabledControlJustPressed(group, control)
        or IsControlJustPressed(0, control)
        or IsDisabledControlJustPressed(0, control)
        or IsControlJustPressed(2, control)
        or IsDisabledControlJustPressed(2, control)
end

local function isExitControlPressed(config)
    local group = config.ControlGroup or 0
    local control = config.ExitControl or 75

    return IsControlPressed(group, control)
        or IsDisabledControlPressed(group, control)
        or IsControlPressed(0, control)
        or IsDisabledControlPressed(0, control)
        or IsControlPressed(2, control)
        or IsDisabledControlPressed(2, control)
end

local function disableExitControl(config)
    local group = config.ControlGroup or 0
    local control = config.ExitControl or 75

    DisableControlAction(group, control, true)
    DisableControlAction(0, control, true)
    DisableControlAction(2, control, true)
end

local function isUiCloseControlPressed()
    local controls = Config.CloseControls or defaultCloseControls

    for _, control in ipairs(controls) do
        if IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control) or IsControlJustPressed(1, control) or IsDisabledControlJustPressed(1, control) or IsControlJustPressed(2, control) or IsDisabledControlJustPressed(2, control) then
            return true
        end
    end

    return false
end

local function disableUiCloseControls()
    local controls = Config.CloseControls or defaultCloseControls

    for _, control in ipairs(controls) do
        DisableControlAction(0, control, true)
        DisableControlAction(1, control, true)
        DisableControlAction(2, control, true)
    end
end

local function keepEngineRunningForExit(vehicle)
    local config = getLeaveEngineConfig()

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    if requestVehicleControl(vehicle) then
        SetVehicleEngineOn(vehicle, true, true, false)
    end

    leaveRunningVehicle = vehicle
    leaveRunningUntil = GetGameTimer() + (tonumber(config.KeepAliveTime) or 3500)
end

local function shouldHandleVehicleExit(vehicle, ped, config)
    if config.Enabled == false or vehicle == 0 or not DoesEntityExist(vehicle) or IsEntityDead(ped) then
        return false
    end

    if uiOpen then
        return true
    end

    if Config.RestrictedVehicleClasses[GetVehicleClass(vehicle)] then
        return false
    end

    if config.DriverOnly ~= false and GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return false
    end

    return GetIsVehicleEngineRunning(vehicle)
end

local function canPreserveEngineForExit(vehicle, ped, config)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not GetIsVehicleEngineRunning(vehicle) then
        return false
    end

    if Config.RestrictedVehicleClasses[GetVehicleClass(vehicle)] then
        return false
    end

    if config.DriverOnly ~= false and GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return false
    end

    return true
end

local function leaveVehicle(vehicle, ped, keepRunning)
    if keepRunning then
        keepEngineRunningForExit(vehicle)
    end

    TaskLeaveVehicle(ped, vehicle, tonumber(getLeaveEngineConfig().ExitFlags) or 0)

    if keepRunning then
        keepEngineRunningForExit(vehicle)
    end
end

local function setUiVisible(visible)
    uiOpen = visible

    if not visible then
        suppressPauseUntil = GetGameTimer() + 650
        SetPauseMenuActive(false)
    end

    SetNuiFocus(visible, visible)
    SetNuiFocusKeepInput(visible and Config.KeepInputWhileOpen)

    SendNUIMessage({
        action = visible and 'open' or 'close'
    })
end

local function setFobVisible(visible)
    local config = getKeyFobConfig()

    fobOpen = visible

    if not visible then
        suppressPauseUntil = GetGameTimer() + 650
        SetPauseMenuActive(false)
    end

    SetNuiFocus(visible, visible)
    SetNuiFocusKeepInput(visible and config.KeepInput ~= false)

    SendNUIMessage({
        action = visible and 'fobOpen' or 'fobClose'
    })
end

local function notify(message, notifyType, duration)
    local config = Config.Notifications or {}
    local provider = config.Provider or 'standalone'
    notifyType = notifyType or 'inform'
    duration = tonumber(duration) or tonumber(config.Duration) or 3500

    if provider == 'auto' then
        if isResourceStarted('qbx_core') then
            provider = 'qbx'
        elseif isResourceStarted('qb-core') then
            provider = 'qb'
        elseif isResourceStarted('ox_lib') then
            provider = 'ox'
        else
            provider = 'standalone'
        end
    end

    if provider == 'custom' and type(config.CustomNotify) == 'function' then
        local ok = pcall(config.CustomNotify, message, notifyType, duration)

        if ok then
            return
        end
    end

    if provider == 'qbx' then
        local qbxType = notifyType == 'primary' and 'inform' or notifyType
        local result = callResourceExport('qbx_core', 'Notify', message, qbxType, duration, nil, config.Position)

        if result ~= nil or isResourceStarted('qbx_core') then
            return
        end
    elseif provider == 'qb' then
        local qbType = (config.TypeMap and config.TypeMap[notifyType]) or notifyType
        local core = callResourceExport('qb-core', 'GetCoreObject')

        if type(core) == 'table' and core.Functions and type(core.Functions.Notify) == 'function' then
            local ok = pcall(core.Functions.Notify, message, qbType, duration)

            if ok then
                return
            end
        end

        if isResourceStarted('qb-core') then
            TriggerEvent('QBCore:Notify', message, qbType, duration)
            return
        end
    elseif provider == 'ox' or provider == 'ox_lib' then
        local oxType = notifyType

        if oxType == 'inform' or oxType == 'primary' then
            oxType = 'info'
        end

        local payload = {
            description = message,
            type = oxType,
            duration = duration,
            position = config.Position
        }

        if type(lib) == 'table' and type(lib.notify) == 'function' then
            local ok = pcall(lib.notify, payload)

            if ok then
                return
            end
        end

        if isResourceStarted('ox_lib') then
            TriggerEvent('ox_lib:notify', payload)
            return
        end
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function getDoorState(vehicle, door)
    return GetVehicleDoorAngleRatio(vehicle, door) > 0.08
end

local function getWindowState(vehicle, window)
    local stored = getStoredVehicleState(vehicle).windows[window]

    if stored ~= nil then
        return stored
    end

    return false
end

local function getAvailableDoors(vehicle)
    local doors = {}
    local locale = getLocaleData()
    local labels = locale.doors or {}

    for door = 0, 5 do
        if DoesVehicleHaveDoor(vehicle, door) then
            doors[#doors + 1] = {
                id = door,
                label = labels[door] or Config.DoorLabels[door] or L('generic.door', { number = door }, 'Door ' .. door),
                active = getDoorState(vehicle, door)
            }
        end
    end

    return doors
end

local function getAvailableWindows(vehicle)
    local windows = {}
    local locale = getLocaleData()
    local labels = locale.doors or {}

    for window = 0, 3 do
        windows[#windows + 1] = {
            id = window,
            label = labels[window] or Config.DoorLabels[window] or L('generic.window', { number = window }, 'Window ' .. window),
            active = getWindowState(vehicle, window)
        }
    end

    return windows
end

local function getSeatLabel(seat)
    local locale = getLocaleData()
    local labels = locale.seats or {}

    if labels[seat] then
        return labels[seat]
    end

    if Config.SeatLabels[seat] then
        return Config.SeatLabels[seat]
    end

    if seat >= 3 then
        return L('generic.seat', { number = seat + 2 }, ('Seat %s'):format(seat + 2))
    end

    return L('generic.seat', { number = seat }, ('Seat %s'):format(seat))
end

local function getAvailableSeats(vehicle)
    local seats = {}
    local playerPed = getPed()
    local model = GetEntityModel(vehicle)
    local maxSeats = GetVehicleModelNumberOfSeats(model) - 2

    for seat = -1, maxSeats do
        local occupant = GetPedInVehicleSeat(vehicle, seat)

        seats[#seats + 1] = {
            id = seat,
            label = getSeatLabel(seat),
            occupied = occupant ~= 0 and occupant ~= playerPed,
            active = occupant == playerPed
        }
    end

    return seats
end

local function getAvailableExtras(vehicle)
    local extras = {}

    for extra = 1, 14 do
        if DoesExtraExist(vehicle, extra) then
            extras[#extras + 1] = {
                id = extra,
                label = L('ui.controls.extra', { number = extra }, ('Extra %s'):format(extra)),
                active = IsVehicleExtraTurnedOn(vehicle, extra)
            }
        end
    end

    return extras
end

local function hasTrailer(vehicle)
    local attached, trailer = GetVehicleTrailerVehicle(vehicle)
    return attached and trailer ~= 0
end

local function getRoofState(vehicle)
    local state = GetConvertibleRoofState(vehicle)

    return {
        supported = IsVehicleAConvertible(vehicle, false),
        active = state == 1 or state == 2
    }
end

local function getVehicleTextLabel(gxtName, fallbackToName)
    if not gxtName or gxtName == '' or gxtName == 'NULL' or gxtName == 'CARNOTFOUND' then
        return nil
    end

    local label = GetLabelText(gxtName)

    if label and label ~= '' and label ~= 'NULL' then
        return label
    end

    if fallbackToName then
        return gxtName
    end

    return nil
end

local function getVehicleIdentity(vehicle)
    local model = GetEntityModel(vehicle)
    local modelName = getVehicleTextLabel(GetDisplayNameFromVehicleModel(model), true) or L('ui.vehicle', nil, 'Vehicle')
    local makeName = nil

    if GetMakeNameFromVehicleModel then
        makeName = getVehicleTextLabel(GetMakeNameFromVehicleModel(model), false)
    end

    local vehicleName = modelName

    if makeName and makeName:lower() ~= modelName:lower() then
        vehicleName = ('%s %s'):format(makeName, modelName)
    end

    return {
        makeName = makeName,
        modelName = modelName,
        vehicleName = vehicleName
    }
end

local function getVehicleName(vehicle)
    return getVehicleIdentity(vehicle).vehicleName
end

local function getVehicleClassName(class)
    local locale = getLocaleData()
    local labels = locale.vehicleClasses or {}

    return labels[class] or Config.VehicleClassLabels[class] or L('ui.vehicle', nil, 'Vehicle')
end

local function areAllWindowsDown(vehicle)
    local stored = getStoredVehicleState(vehicle)

    for window = 0, 3 do
        if stored.windows[window] ~= true then
            return false
        end
    end

    return true
end

local function getKeyFobState(message)
    local config = getKeyFobConfig()
    local vehicle = getLastDrivenVehicle()
    local ok, target, status = getKeyFobTargetStatus()
    local now = GetGameTimer()

    if message then
        fobDisplayMessage = message
        fobDisplayUntil = now + (tonumber(config.MessageDuration) or 1800)
    end

    if vehicle == 0 and target ~= 0 then
        vehicle = target
    end

    local state = {
        canUse = ok,
        message = fobDisplayUntil > now and fobDisplayMessage or status,
        maxDistance = tonumber(config.MaxDistance) or 35.0,
        locale = getLocaleData(),
        theme = Config.Theme
    }

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return state
    end

    local distance = getVehicleDistance(vehicle) or 0
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    local identity = getVehicleIdentity(vehicle)

    state.plate = GetVehicleNumberPlateText(vehicle)
    state.vehicleName = identity.vehicleName
    state.makeName = identity.makeName
    state.modelName = identity.modelName
    state.vehicleClass = GetVehicleClass(vehicle)
    state.vehicleClassName = getVehicleClassName(state.vehicleClass)
    state.distance = math.floor(distance + 0.5)
    state.locked = lockStatus == 2 or lockStatus == 3 or lockStatus == 4
    state.engine = GetIsVehicleEngineRunning(vehicle)
    state.trunk = DoesVehicleHaveDoor(vehicle, 5) and getDoorState(vehicle, 5)
    state.hasTrunk = DoesVehicleHaveDoor(vehicle, 5)
    state.windowsDown = areAllWindowsDown(vehicle)
    state.panic = fobPanicVehicle == vehicle and fobPanicUntil > GetGameTimer()

    if fobDisplayUntil <= now and state.panic then
        state.message = fobMessage('panic')
    end

    return state
end

local function sendKeyFobState(message)
    SendNUIMessage({
        action = 'fobState',
        data = getKeyFobState(message)
    })
end

local function getVehicleState()
    local vehicle = getVehicle()

    if not hasVehicleAccess(vehicle) then
        return nil
    end

    local stored = getStoredVehicleState(vehicle)

    local vehicleClass = GetVehicleClass(vehicle)
    local engineRunning = GetIsVehicleEngineRunning(vehicle)
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    local fuel = 0

    if GetVehicleFuelLevel then
        fuel = math.floor(GetVehicleFuelLevel(vehicle) + 0.5)
    end

    return {
        canUse = true,
        locale = getLocaleData(),
        plate = GetVehicleNumberPlateText(vehicle),
        vehicleName = getVehicleName(vehicle),
        vehicleClass = vehicleClass,
        vehicleClassName = getVehicleClassName(vehicleClass),
        fuel = fuel,
        engineHealth = math.floor(GetVehicleEngineHealth(vehicle) / 10 + 0.5),
        engine = engineRunning,
        locked = lockStatus == 2 or lockStatus == 3 or lockStatus == 4,
        radio = stored.radio,
        hazards = stored.hazards,
        interiorLight = stored.interiorLight,
        trailer = hasTrailer(vehicle),
        roof = getRoofState(vehicle),
        doors = getAvailableDoors(vehicle),
        windows = getAvailableWindows(vehicle),
        seats = getAvailableSeats(vehicle),
        extras = getAvailableExtras(vehicle),
        enabled = getEnabledControls(vehicle),
        theme = Config.Theme
    }
end

local function sendVehicleState()
    local state = getVehicleState()

    if not state then
        if uiOpen then
            setUiVisible(false)
        else
            SendNUIMessage({ action = 'unavailable' })
        end

        return
    end

    SendNUIMessage({
        action = 'state',
        data = state
    })
end

local function sendVehicleStateAfterAction()
    Wait(tonumber(Config.ActionRefreshDelay) or 125)
    sendVehicleState()
end

local function toggleUi()
    if uiOpen then
        setUiVisible(false)
        return
    end

    if fobOpen then
        setFobVisible(false)
    end

    local vehicle = getVehicle()
    if not hasVehicleAccess(vehicle) then
        notify(L('notifications.vehicleControlsUnavailable'), 'error')
        return
    end

    setUiVisible(true)
    sendVehicleState()
end

local function toggleKeyFob()
    local config = getKeyFobConfig()

    if config.Enabled == false then
        notify(L('notifications.keyFobDisabled'), 'error')
        return
    end

    if fobOpen then
        setFobVisible(false)
        return
    end

    if uiOpen then
        setUiVisible(false)
    end

    if IsPedInAnyVehicle(getPed(), false) then
        notify(L('notifications.useTouchscreenInside'), 'inform')
        return
    end

    local vehicle = getLastDrivenVehicle()
    if vehicle == 0 then
        notify(L('notifications.noRecentVehicle'), 'error')
        return
    end

    setFobVisible(true)
    sendKeyFobState()
end

RegisterCommand(Config.Command, toggleUi, false)
RegisterKeyMapping(Config.Command, L('keyMappings.touchscreen'), 'keyboard', Config.DefaultKey)

if Config.KeyFob and Config.KeyFob.Enabled ~= false then
    RegisterCommand(Config.KeyFob.Command or 'keyfob', toggleKeyFob, false)
    RegisterKeyMapping(Config.KeyFob.Command or 'keyfob', L('keyMappings.keyFob'), 'keyboard', Config.KeyFob.DefaultKey or 'K')
end

RegisterNUICallback('close', function(_, cb)
    if uiOpen then
        setUiVisible(false)
    end

    if fobOpen then
        setFobVisible(false)
    end

    cb({ ok = true })
end)

RegisterNUICallback('ready', function(_, cb)
    SendNUIMessage({
        action = 'locale',
        data = getLocaleData()
    })
    cb({ ok = true })
    sendVehicleState()
end)

RegisterNUICallback('toggleEngine', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'engine') and requestVehicleControl(vehicle) then
        local running = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not running, false, true)
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleLock', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'locks') and requestVehicleControl(vehicle) then
        local locked = GetVehicleDoorLockStatus(vehicle) >= 2
        SetVehicleDoorsLocked(vehicle, locked and 1 or 2)

        local plate = GetVehicleNumberPlateText(vehicle)
        notify(L('notifications.vehicleLockChanged', {
            plate = plate,
            state = locked and L('notifications.unlocked') or L('notifications.locked')
        }), 'success')
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local vehicle = getVehicle()
    local door = tonumber(data.id)

    if hasVehicleAccess(vehicle) and door and canUseVehicleControl(vehicle, 'doors') and DoesVehicleHaveDoor(vehicle, door) and requestVehicleControl(vehicle) then
        if getDoorState(vehicle, door) then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('closeAllDoors', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'doors') and requestVehicleControl(vehicle) then
        for door = 0, 5 do
            if DoesVehicleHaveDoor(vehicle, door) then
                SetVehicleDoorShut(vehicle, door, false)
            end
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    local vehicle = getVehicle()
    local window = tonumber(data.id)

    if hasVehicleAccess(vehicle) and window and canUseVehicleControl(vehicle, 'windows') and requestVehicleControl(vehicle) then
        local stored = getStoredVehicleState(vehicle)

        if getWindowState(vehicle, window) then
            RollUpWindow(vehicle, window)
            stored.windows[window] = false
        else
            RollDownWindow(vehicle, window)
            stored.windows[window] = true
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('allWindows', function(data, cb)
    local vehicle = getVehicle()
    local down = data.down == true

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'windows') and requestVehicleControl(vehicle) then
        local stored = getStoredVehicleState(vehicle)

        for window = 0, 3 do
            if down then
                RollDownWindow(vehicle, window)
            else
                RollUpWindow(vehicle, window)
            end

            stored.windows[window] = down
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('switchSeat', function(data, cb)
    local vehicle = getVehicle()
    local seat = tonumber(data.id)

    if hasVehicleAccess(vehicle) and seat and canUseVehicleControl(vehicle, 'seats') and requestVehicleControl(vehicle) then
        local occupant = GetPedInVehicleSeat(vehicle, seat)

        if occupant == 0 or occupant == getPed() then
            TaskWarpPedIntoVehicle(getPed(), vehicle, seat)
        else
            notify(L('notifications.seatOccupied'), 'error')
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleRadio', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'radio') and requestVehicleControl(vehicle) then
        local stored = getStoredVehicleState(vehicle)
        stored.radio = not stored.radio
        SetVehicleRadioEnabled(vehicle, stored.radio)
        setSanAndreasRadioPower(vehicle, stored.radio)

        if not stored.radio then
            SetVehRadioStation(vehicle, 'OFF')
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleHazards', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'hazards') and requestVehicleControl(vehicle) then
        local stored = getStoredVehicleState(vehicle)
        stored.hazards = not stored.hazards
        SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
        SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleInteriorLight', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'interiorLight') and requestVehicleControl(vehicle) then
        local stored = getStoredVehicleState(vehicle)
        stored.interiorLight = not stored.interiorLight
        SetVehicleInteriorlight(vehicle, stored.interiorLight)
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('detachTrailer', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'trailer') and requestVehicleControl(vehicle) then
        local attached = hasTrailer(vehicle)

        if attached then
            DetachVehicleFromTrailer(vehicle)
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleRoof', function(_, cb)
    local vehicle = getVehicle()

    if hasVehicleAccess(vehicle) and canUseVehicleControl(vehicle, 'roof') and IsVehicleAConvertible(vehicle, false) and requestVehicleControl(vehicle) then
        local state = GetConvertibleRoofState(vehicle)

        if state == 0 or state == 3 then
            LowerConvertibleRoof(vehicle, false)
        else
            RaiseConvertibleRoof(vehicle, false)
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('toggleExtra', function(data, cb)
    local vehicle = getVehicle()
    local extra = tonumber(data.id)

    if hasVehicleAccess(vehicle) and extra and canUseVehicleControl(vehicle, 'extras') and DoesExtraExist(vehicle, extra) and requestVehicleControl(vehicle) then
        local enabled = IsVehicleExtraTurnedOn(vehicle, extra)
        SetVehicleExtra(vehicle, extra, enabled and 1 or 0)
    end

    sendVehicleStateAfterAction()
    cb({ ok = true })
end)

RegisterNUICallback('keyFobAction', function(data, cb)
    local action = tostring(data.action or '')
    local actionMap = {
        lock = 'locks',
        engine = 'engine',
        trunk = 'trunk',
        windows = 'windows',
        panic = 'panic'
    }
    local actionName = actionMap[action]

    if not actionName or not keyFobActionEnabled(actionName) then
        sendKeyFobState(fobMessage('disabled'))
        cb({ ok = false })
        return
    end

    local ok, vehicle, status = getKeyFobTargetStatus()
    if not ok then
        sendKeyFobState(status)
        cb({ ok = false })
        return
    end

    if not requestVehicleControl(vehicle) then
        sendKeyFobState(fobMessage('noSignal'))
        cb({ ok = false })
        return
    end

    local message = fobMessage('ready')
    playKeyFobInteraction(vehicle)

    local actionDelay = tonumber(getKeyFobInteraction().ActionDelay) or 0
    if actionDelay > 0 then
        Wait(actionDelay)
    end

    if action == 'lock' then
        local locked = GetVehicleDoorLockStatus(vehicle) >= 2
        local feedback = getKeyFobFeedback()

        SetVehicleDoorsLocked(vehicle, locked and 1 or 2)

        if locked then
            keyFobFeedback(vehicle, 2, tonumber(feedback.UnlockBeeps) or 2)
            message = fobMessage('unlocked')
        else
            keyFobFeedback(vehicle, 1, tonumber(feedback.LockBeeps) or 1)
            message = fobMessage('locked')
        end
    elseif action == 'engine' then
        local running = GetIsVehicleEngineRunning(vehicle)

        if running then
            SetVehicleEngineOn(vehicle, false, true, true)
            message = fobMessage('engineOff')
        else
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineOn(vehicle, true, true, false)
            message = fobMessage('engineOn')
        end

        keyFobFeedback(vehicle, 2, 0)
    elseif action == 'trunk' then
        if DoesVehicleHaveDoor(vehicle, 5) then
            if getDoorState(vehicle, 5) then
                SetVehicleDoorShut(vehicle, 5, false)
                message = fobMessage('trunkClosed')
            else
                SetVehicleDoorOpen(vehicle, 5, false, false)
                message = fobMessage('trunkOpen')
            end

            keyFobFeedback(vehicle, 1, 0)
        else
            message = fobMessage('noTrunk')
        end
    elseif action == 'windows' then
        local stored = getStoredVehicleState(vehicle)
        local down = not areAllWindowsDown(vehicle)

        for window = 0, 3 do
            if down then
                RollDownWindow(vehicle, window)
            else
                RollUpWindow(vehicle, window)
            end

            stored.windows[window] = down
        end

        keyFobFeedback(vehicle, 1, 0)
        message = down and fobMessage('windowsDown') or fobMessage('windowsUp')
    elseif action == 'panic' then
        if fobPanicVehicle == vehicle and fobPanicUntil > GetGameTimer() then
            fobPanicUntil = 0
            fobPanicVehicle = 0
            local stored = getStoredVehicleState(vehicle)
            SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
            SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
            setVehicleLightsForced(vehicle, false)
            message = fobMessage('panicOff')
        else
            fobPanicVehicle = vehicle
            fobPanicUntil = GetGameTimer() + (tonumber(getKeyFobConfig().PanicDuration) or 7000)
            message = fobMessage('panic')
        end
    end

    Wait(tonumber(Config.ActionRefreshDelay) or 125)
    sendKeyFobState(message)
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        local suppressPause = suppressPauseUntil > GetGameTimer()

        if uiOpen or fobOpen or suppressPause then
            disableUiCloseControls()

            if IsPauseMenuActive() then
                SetPauseMenuActive(false)
            end
        end

        if uiOpen then
            if Config.DisableNonDrivingControls then
                DisableAllControlActions(0)
                disableUiCloseControls()

                for _, control in ipairs(Config.AllowedControlsWhileOpen) do
                    EnableControlAction(0, control, true)
                    EnableControlAction(2, control, true)
                end
            else
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 69, true) -- vehicle attack
                DisableControlAction(0, 70, true) -- vehicle attack 2
                DisableControlAction(0, 92, true) -- passenger attack
                DisableControlAction(0, 114, true) -- vehicle fly attack
                DisableControlAction(0, 331, true) -- vehicle fly attack 2
                disableUiCloseControls()
            end

            if isUiCloseControlPressed() then
                setUiVisible(false)
            end
        elseif fobOpen then
            local config = getKeyFobConfig()

            if config.KeepInput ~= false then
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)

                for _, control in ipairs(config.AllowedControls or {}) do
                    EnableControlAction(0, control, true)
                    EnableControlAction(1, control, true)
                    EnableControlAction(2, control, true)
                end
            end

            disableUiCloseControls()

            if isUiCloseControlPressed() then
                setFobVisible(false)
            end
        end

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        local ped = getPed()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped and not Config.RestrictedVehicleClasses[GetVehicleClass(vehicle)] then
            lastDrivenVehicle = vehicle
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        if fobPanicVehicle ~= 0 then
            local vehicle = fobPanicVehicle

            if not DoesEntityExist(vehicle) or GetGameTimer() > fobPanicUntil then
                if DoesEntityExist(vehicle) then
                    local stored = getStoredVehicleState(vehicle)
                    SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
                    SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
                    setVehicleLightsForced(vehicle, false)
                end

                fobPanicVehicle = 0
                fobPanicUntil = 0
                Wait(250)
            else
                if requestVehicleControl(vehicle) then
                    SetVehicleIndicatorLights(vehicle, 0, true)
                    SetVehicleIndicatorLights(vehicle, 1, true)
                    setVehicleLightsForced(vehicle, true)
                    StartVehicleHorn(vehicle, 220, GetHashKey('NORMAL'), false)
                    Wait(160)
                    setVehicleLightsForced(vehicle, false)
                end

                Wait(tonumber(getKeyFobConfig().PanicHornInterval) or 750)
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        local config = getLeaveEngineConfig()

        if config.Enabled == false then
            leaveRunningVehicle = 0
            leaveRunningUntil = 0
            Wait(750)
        else
            local ped = getPed()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if shouldHandleVehicleExit(vehicle, ped, config) then
                disableExitControl(config)

                if isExitControlJustPressed(config) then
                    local canPreserveEngine = canPreserveEngineForExit(vehicle, ped, config)
                    local keepOnExit = canPreserveEngine and config.KeepIfEngineWasRunning ~= false

                    if keepOnExit then
                        leaveVehicle(vehicle, ped, true)
                    elseif config.LongPressExit ~= false and canPreserveEngine then
                        Wait(tonumber(config.HoldTime) or 150)

                        if IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == vehicle and isExitControlPressed(config) and not IsEntityDead(ped) then
                            leaveVehicle(vehicle, ped, true)
                        elseif IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == vehicle and not IsEntityDead(ped) then
                            leaveVehicle(vehicle, ped, false)
                        end
                    elseif uiOpen then
                        leaveVehicle(vehicle, ped, false)
                    end
                end
            end

            if leaveRunningVehicle ~= 0 then
                if GetGameTimer() <= leaveRunningUntil and DoesEntityExist(leaveRunningVehicle) then
                    if requestVehicleControl(leaveRunningVehicle) then
                        SetVehicleEngineOn(leaveRunningVehicle, true, true, false)
                    end
                else
                    leaveRunningVehicle = 0
                    leaveRunningUntil = 0
                end
            end

            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        if uiOpen then
            if Config.CloseOnExitVehicle and not hasVehicleAccess(getVehicle()) then
                setUiVisible(false)
            else
                sendVehicleState()
            end

            Wait(Config.RefreshInterval)
        elseif fobOpen then
            if IsPedInAnyVehicle(getPed(), false) then
                setFobVisible(false)
            else
                sendKeyFobState()
            end

            Wait(Config.RefreshInterval)
        else
            Wait(750)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if uiOpen or fobOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if fobPanicVehicle ~= 0 and DoesEntityExist(fobPanicVehicle) then
        local stored = getStoredVehicleState(fobPanicVehicle)
        SetVehicleIndicatorLights(fobPanicVehicle, 0, stored.hazards)
        SetVehicleIndicatorLights(fobPanicVehicle, 1, stored.hazards)
        setVehicleLightsForced(fobPanicVehicle, false)
    end
end)
