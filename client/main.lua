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
local actionCooldowns = {}
local runtimeKeyCheck = nil
local vehicleOverrideCache = {}

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

local function getNetworkSyncConfig()
    return Config.NetworkSync or {}
end

local function networkStateEnabled(name)
    local config = getNetworkSyncConfig()
    local states = config.States or {}

    return config.Enabled ~= false and states[name] ~= false
end

local function getVehicleOverride(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local overrides = Config.VehicleOverrides or {}
    local model = GetEntityModel(vehicle)
    local modelName = tostring(GetDisplayNameFromVehicleModel(model) or '')
    local lowerName = modelName:lower()
    local cached = vehicleOverrideCache[model]

    if cached ~= nil then
        return cached or nil
    end

    local override = overrides[model] or overrides[lowerName] or overrides[modelName]

    if not override then
        for key, value in pairs(overrides) do
            if type(key) == 'string' and GetHashKey(key) == model then
                override = value
                break
            end
        end
    end

    vehicleOverrideCache[model] = override or false
    return override
end

local function getOverrideItem(vehicle, section, id)
    local override = getVehicleOverride(vehicle)
    local items = override and override[section]

    if type(items) ~= 'table' then
        return nil
    end

    local value = items[id]
    if value == nil then
        value = items[tostring(id)]
    end

    return value
end

local function getOverrideLabel(vehicle, section, id)
    local override = getVehicleOverride(vehicle)
    local labels = override and override.Labels
    local sectionLabels = type(labels) == 'table' and labels[section] or nil

    if type(sectionLabels) ~= 'table' then
        return nil
    end

    return sectionLabels[id] or sectionLabels[tostring(id)]
end

local function isVehicleSupported(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local override = getVehicleOverride(vehicle)
    if override and override.Enabled == false then
        return false
    end

    return (Config.RestrictedVehicleClasses or {})[GetVehicleClass(vehicle)] ~= true
end

local function vehicleHasDoor(vehicle, door)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local overrideValue = getOverrideItem(vehicle, 'Doors', door)

    if overrideValue ~= nil then
        return overrideValue == true
    end

    return DoesVehicleHaveDoor(vehicle, door)
end

local function isEnabled(name, vehicle)
    local override = getVehicleOverride(vehicle)
    local controls = override and override.Controls

    if type(controls) == 'table' and controls[name] ~= nil then
        return controls[name] == true
    end

    return (Config.Controls or {})[name] ~= false
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
    local model = GetEntityModel(vehicle)
    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local cached = vehicleToggles[key]

    if cached and cached._entity == vehicle and cached._model == model and cached._plate == plate then
        return cached
    end

    local stored = {
        _entity = vehicle,
        _model = model,
        _plate = plate,
        radio = true,
        hazards = false,
        interiorLight = false,
        windows = {}
    }

    local networkConfig = getNetworkSyncConfig()
    if networkConfig.Enabled ~= false and NetworkGetEntityIsNetworked(vehicle) then
        local synced = Entity(vehicle).state[networkConfig.StateBagName or 'drs_vehcontrol']

        if type(synced) == 'table' then
            if type(synced.radio) == 'boolean' then
                stored.radio = synced.radio
            end

            if type(synced.hazards) == 'boolean' then
                stored.hazards = synced.hazards
            end

            if type(synced.interiorLight) == 'boolean' then
                stored.interiorLight = synced.interiorLight
            end

            if type(synced.windows) == 'table' then
                for window = 0, 3 do
                    local value = synced.windows[window]
                    if value == nil then
                        value = synced.windows[tostring(window)]
                    end

                    if type(value) == 'boolean' then
                        stored.windows[window] = value
                    end
                end
            end
        end
    end

    vehicleToggles[key] = stored

    return stored
end

local function hasVehicleAccess(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local ped = getPed()
    if not IsPedInAnyVehicle(ped, false) or GetVehiclePedIsIn(ped, false) ~= vehicle then
        return false
    end

    if not isVehicleSupported(vehicle) then
        return false
    end

    if Config.AllowPassengers then
        return true
    end

    return GetPedInVehicleSeat(vehicle, -1) == ped
end

local function isDriver(vehicle)
    return vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == getPed()
end

local function canUseVehicleControl(vehicle, name)
    if not isEnabled(name, vehicle) then
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

    for name in pairs(Config.Controls or {}) do
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

local function syncVehicleState(vehicle, patch)
    local config = getNetworkSyncConfig()

    if config.Enabled == false or vehicle == 0 or not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) or type(patch) ~= 'table' then
        return false
    end

    local filtered = {}

    for name, value in pairs(patch) do
        if networkStateEnabled(name) then
            filtered[name] = value
        end
    end

    if next(filtered) then
        TriggerServerEvent('drs_vehcontrol:server:setVehicleState', NetworkGetNetworkIdFromEntity(vehicle), filtered)
        return true
    end

    return false
end

local function denyAction(action, reason)
    local security = Config.ActionSecurity or {}

    if security.PrintDeniedActions == true then
        print(('[drs_vehcontrol] Denied action %s: %s'):format(tostring(action), tostring(reason)))
    end

    return false, reason
end

local function consumeActionCooldown(key, duration)
    local security = Config.ActionSecurity or {}

    if security.Enabled == false then
        return true
    end

    local now = GetGameTimer()
    if (actionCooldowns[key] or 0) > now then
        return false
    end

    actionCooldowns[key] = now + math.max(0, tonumber(duration) or tonumber(security.Cooldown) or 150)
    return true
end

local function validateVehicleAction(action, vehicle, controlName)
    if not hasVehicleAccess(vehicle) then
        return denyAction(action, 'vehicle_unavailable')
    end

    if not canUseVehicleControl(vehicle, controlName) then
        return denyAction(action, 'control_not_allowed')
    end

    if not consumeActionCooldown('vehicle:' .. tostring(action)) then
        return denyAction(action, 'cooldown')
    end

    if not requestVehicleControl(vehicle) then
        return denyAction(action, 'network_control')
    end

    return true
end

local function emitVehicleAction(action, vehicle, details)
    local payload = {
        action = action,
        vehicle = vehicle,
        netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0,
        plate = normalizePlate(GetVehicleNumberPlateText(vehicle)),
        details = details or {}
    }

    TriggerEvent('drs_vehcontrol:client:action', payload)
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

    if provider == 'registered' or provider == 'runtime' then
        if type(runtimeKeyCheck) ~= 'function' then
            return true, false
        end

        local ok, allowed = pcall(runtimeKeyCheck, vehicle, plate, modelName)
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

local function keyFobActionEnabled(name, vehicle)
    local actions = getKeyFobActions()
    local override = getVehicleOverride(vehicle)
    local overrideActions = override and override.FobActions

    if type(overrideActions) == 'table' and overrideActions[name] ~= nil then
        return overrideActions[name] == true
    end

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

    if not isVehicleSupported(vehicle) then
        return false, vehicle, fobMessage('unsupported')
    end

    local distance = getVehicleDistance(vehicle)
    local override = getVehicleOverride(vehicle)
    local maxDistance = tonumber(override and override.KeyFobMaxDistance) or tonumber(config.MaxDistance) or 35.0

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

    if not isVehicleSupported(vehicle) then
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

    if not isVehicleSupported(vehicle) then
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
        if vehicleHasDoor(vehicle, door) then
            doors[#doors + 1] = {
                id = door,
                label = getOverrideLabel(vehicle, 'Doors', door) or labels[door] or Config.DoorLabels[door] or L('generic.door', { number = door }, 'Door ' .. door),
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
        if getOverrideItem(vehicle, 'Windows', window) ~= false then
            windows[#windows + 1] = {
                id = window,
                label = getOverrideLabel(vehicle, 'Windows', window) or labels[window] or Config.DoorLabels[window] or L('generic.window', { number = window }, 'Window ' .. window),
                active = getWindowState(vehicle, window)
            }
        end
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
    local override = getVehicleOverride(vehicle)

    if override and type(override.Seats) == 'table' then
        for seat, enabled in pairs(override.Seats) do
            local numericSeat = tonumber(seat)

            if enabled == true and numericSeat and numericSeat > maxSeats then
                maxSeats = numericSeat
            end
        end
    end

    for seat = -1, maxSeats do
        if getOverrideItem(vehicle, 'Seats', seat) ~= false then
            local occupant = GetPedInVehicleSeat(vehicle, seat)

            seats[#seats + 1] = {
                id = seat,
                label = getOverrideLabel(vehicle, 'Seats', seat) or getSeatLabel(seat),
                occupied = occupant ~= 0 and occupant ~= playerPed,
                active = occupant == playerPed
            }
        end
    end

    return seats
end

local function getAvailableExtras(vehicle)
    local extras = {}

    for extra = 1, 14 do
        local overrideValue = getOverrideItem(vehicle, 'Extras', extra)

        if overrideValue == true or (overrideValue ~= false and DoesExtraExist(vehicle, extra)) then
            extras[#extras + 1] = {
                id = extra,
                label = getOverrideLabel(vehicle, 'Extras', extra) or L('ui.controls.extra', { number = extra }, ('Extra %s'):format(extra)),
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
    local available = false

    for window = 0, 3 do
        if getOverrideItem(vehicle, 'Windows', window) ~= false then
            available = true

            if stored.windows[window] ~= true then
                return false
            end
        end
    end

    if not available then
        return false
    end

    return true
end

local function applySyncedVehicleState(vehicle, synced)
    if vehicle == 0 or not DoesEntityExist(vehicle) or type(synced) ~= 'table' then
        return
    end

    local stored = getStoredVehicleState(vehicle)

    if type(synced.radio) == 'boolean' and networkStateEnabled('radio') then
        stored.radio = synced.radio
        SetVehicleRadioEnabled(vehicle, stored.radio)

        if not stored.radio then
            SetVehRadioStation(vehicle, 'OFF')
        end
    end

    if type(synced.hazards) == 'boolean' and networkStateEnabled('hazards') then
        stored.hazards = synced.hazards

        if fobPanicVehicle ~= vehicle or fobPanicUntil <= GetGameTimer() then
            SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
            SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
        end
    end

    if type(synced.interiorLight) == 'boolean' and networkStateEnabled('interiorLight') then
        stored.interiorLight = synced.interiorLight
        SetVehicleInteriorlight(vehicle, stored.interiorLight)
    end

    if type(synced.windows) == 'table' and networkStateEnabled('windows') then
        for window = 0, 3 do
            local value = synced.windows[window]
            if value == nil then
                value = synced.windows[tostring(window)]
            end

            if type(value) == 'boolean' and getOverrideItem(vehicle, 'Windows', window) ~= false then
                stored.windows[window] = value

                if value then
                    RollDownWindow(vehicle, window)
                else
                    RollUpWindow(vehicle, window)
                end
            end
        end
    end
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
    local override = getVehicleOverride(vehicle)

    state.plate = GetVehicleNumberPlateText(vehicle)
    state.vehicleName = identity.vehicleName
    state.makeName = identity.makeName
    state.modelName = identity.modelName
    state.vehicleClass = GetVehicleClass(vehicle)
    state.vehicleClassName = getVehicleClassName(state.vehicleClass)
    state.maxDistance = tonumber(override and override.KeyFobMaxDistance) or tonumber(config.MaxDistance) or 35.0
    state.distance = math.floor(distance + 0.5)
    state.locked = lockStatus == 2 or lockStatus == 3 or lockStatus == 4
    state.engine = GetIsVehicleEngineRunning(vehicle)
    state.trunk = vehicleHasDoor(vehicle, 5) and getDoorState(vehicle, 5)
    state.hasTrunk = vehicleHasDoor(vehicle, 5)
    state.windowsDown = areAllWindowsDown(vehicle)
    state.panic = fobPanicVehicle == vehicle and fobPanicUntil > GetGameTimer()
    state.actions = {
        locks = keyFobActionEnabled('locks', vehicle),
        engine = keyFobActionEnabled('engine', vehicle),
        trunk = keyFobActionEnabled('trunk', vehicle),
        windows = keyFobActionEnabled('windows', vehicle),
        panic = keyFobActionEnabled('panic', vehicle)
    }

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

local function openVehicleUi()
    if fobOpen then
        setFobVisible(false)
    end

    local vehicle = getVehicle()
    if not hasVehicleAccess(vehicle) then
        notify(L('notifications.vehicleControlsUnavailable'), 'error')
        return false, 'vehicle_unavailable'
    end

    setUiVisible(true)
    sendVehicleState()
    return true
end

local function toggleUi()
    if uiOpen then
        setUiVisible(false)
        return
    end

    openVehicleUi()
end

local function openKeyFob()
    local config = getKeyFobConfig()

    if config.Enabled == false then
        notify(L('notifications.keyFobDisabled'), 'error')
        return false, 'disabled'
    end

    if uiOpen then
        setUiVisible(false)
    end

    if IsPedInAnyVehicle(getPed(), false) then
        notify(L('notifications.useTouchscreenInside'), 'inform')
        return false, 'inside_vehicle'
    end

    local vehicle = getLastDrivenVehicle()
    if vehicle == 0 then
        notify(L('notifications.noRecentVehicle'), 'error')
        return false, 'no_vehicle'
    end

    setFobVisible(true)
    sendKeyFobState()
    return true
end

local function toggleKeyFob()
    if fobOpen then
        setFobVisible(false)
        return
    end

    openKeyFob()
end

local function setLastVehicle(vehicle)
    vehicle = tonumber(vehicle) or 0

    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end

    lastDrivenVehicle = vehicle
    return true
end

local function getVehicleDiagnostics(vehicle)
    vehicle = vehicle or getVehicle()

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        vehicle = getLastDrivenVehicle()
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local model = GetEntityModel(vehicle)
    local identity = getVehicleIdentity(vehicle)
    local networkConfig = getNetworkSyncConfig()
    local synced = nil

    if NetworkGetEntityIsNetworked(vehicle) then
        synced = Entity(vehicle).state[networkConfig.StateBagName or 'drs_vehcontrol']
    end

    return {
        entity = vehicle,
        netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0,
        networked = NetworkGetEntityIsNetworked(vehicle),
        hasControl = not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle),
        modelHash = model,
        modelName = getVehicleModelName(vehicle),
        makeName = identity.makeName,
        displayName = identity.vehicleName,
        plate = normalizePlate(GetVehicleNumberPlateText(vehicle)),
        class = GetVehicleClass(vehicle),
        className = getVehicleClassName(GetVehicleClass(vehicle)),
        distance = getVehicleDistance(vehicle),
        supported = isVehicleSupported(vehicle),
        driver = isDriver(vehicle),
        hasOverride = getVehicleOverride(vehicle) ~= nil,
        hasKey = hasKeyFobKey(vehicle),
        controls = getEnabledControls(vehicle),
        doors = getAvailableDoors(vehicle),
        windows = getAvailableWindows(vehicle),
        seats = getAvailableSeats(vehicle),
        extras = getAvailableExtras(vehicle),
        syncedState = synced
    }
end

RegisterCommand(Config.Command, toggleUi, false)
RegisterKeyMapping(Config.Command, L('keyMappings.touchscreen'), 'keyboard', Config.DefaultKey)

if Config.KeyFob and Config.KeyFob.Enabled ~= false then
    RegisterCommand(Config.KeyFob.Command or 'keyfob', toggleKeyFob, false)
    RegisterKeyMapping(Config.KeyFob.Command or 'keyfob', L('keyMappings.keyFob'), 'keyboard', Config.KeyFob.DefaultKey or 'K')
end

if Config.Debug and Config.Debug.Enabled == true then
    RegisterCommand(Config.Debug.Command or 'vehcontroldebug', function()
        local diagnostics = getVehicleDiagnostics()

        if not diagnostics then
            print('[drs_vehcontrol] No current or recent vehicle is available for diagnostics.')
            return
        end

        print(('[drs_vehcontrol] Vehicle diagnostics: %s'):format(json.encode(diagnostics)))
    end, false)
end

exports('Open', openVehicleUi)
exports('Close', function()
    if uiOpen then
        setUiVisible(false)
    end

    if fobOpen then
        setFobVisible(false)
    end
end)
exports('Toggle', toggleUi)
exports('OpenKeyFob', openKeyFob)
exports('CloseKeyFob', function()
    if fobOpen then
        setFobVisible(false)
    end
end)
exports('IsOpen', function()
    return uiOpen or fobOpen
end)
exports('GetOpenState', function()
    return {
        touchscreen = uiOpen,
        keyFob = fobOpen
    }
end)
exports('GetVehicleState', getVehicleState)
exports('GetKeyFobState', getKeyFobState)
exports('GetVehicleDiagnostics', getVehicleDiagnostics)
exports('GetLastVehicle', getLastDrivenVehicle)
exports('SetLastVehicle', setLastVehicle)
exports('SetSyncedState', function(vehicle, patch)
    if getNetworkSyncConfig().Enabled == false or vehicle == 0 or not DoesEntityExist(vehicle) or type(patch) ~= 'table' then
        return false
    end

    applySyncedVehicleState(vehicle, patch)
    return syncVehicleState(vehicle, patch)
end)
exports('RegisterKeyCheck', function(callback)
    if type(callback) ~= 'function' then
        return false
    end

    runtimeKeyCheck = callback
    return true
end)
exports('ClearKeyCheck', function()
    runtimeKeyCheck = nil
end)

RegisterNetEvent('drs_vehcontrol:client:open', openVehicleUi)
RegisterNetEvent('drs_vehcontrol:client:close', function()
    if uiOpen then
        setUiVisible(false)
    end

    if fobOpen then
        setFobVisible(false)
    end
end)
RegisterNetEvent('drs_vehcontrol:client:openKeyFob', openKeyFob)
RegisterNetEvent('drs_vehcontrol:client:setLastVehicle', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    setLastVehicle(vehicle)
end)
RegisterNetEvent('drs_vehcontrol:client:debug', function()
    local diagnostics = getVehicleDiagnostics()
    print(('[drs_vehcontrol] Vehicle diagnostics: %s'):format(diagnostics and json.encode(diagnostics) or 'no vehicle'))
end)

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
    local ok, reason = validateVehicleAction('engine', vehicle, 'engine')

    if ok then
        local running = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not running, false, true)
        emitVehicleAction('engine', vehicle, { active = not running, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleLock', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('locks', vehicle, 'locks')

    if ok then
        local locked = GetVehicleDoorLockStatus(vehicle) >= 2
        SetVehicleDoorsLocked(vehicle, locked and 1 or 2)
        emitVehicleAction('locks', vehicle, { active = not locked, source = 'touchscreen' })

        local plate = GetVehicleNumberPlateText(vehicle)
        notify(L('notifications.vehicleLockChanged', {
            plate = plate,
            state = locked and L('notifications.unlocked') or L('notifications.locked')
        }), 'success')
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local vehicle = getVehicle()
    local door = tonumber(data.id)
    local ok, reason

    if not door or door < 0 or door > 5 or not vehicleHasDoor(vehicle, door) then
        ok, reason = denyAction('door', 'invalid_door')
    else
        ok, reason = validateVehicleAction('door:' .. door, vehicle, 'doors')
    end

    if ok then
        local open = not getDoorState(vehicle, door)

        if getDoorState(vehicle, door) then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end

        emitVehicleAction('door', vehicle, { id = door, active = open, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('closeAllDoors', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('doors:all', vehicle, 'doors')

    if ok then
        for door = 0, 5 do
            if vehicleHasDoor(vehicle, door) then
                SetVehicleDoorShut(vehicle, door, false)
            end
        end

        emitVehicleAction('doors', vehicle, { active = false, all = true, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    local vehicle = getVehicle()
    local window = tonumber(data.id)
    local ok, reason

    if not window or window < 0 or window > 3 or getOverrideItem(vehicle, 'Windows', window) == false then
        ok, reason = denyAction('window', 'invalid_window')
    else
        ok, reason = validateVehicleAction('window:' .. window, vehicle, 'windows')
    end

    if ok then
        local stored = getStoredVehicleState(vehicle)
        local down = not getWindowState(vehicle, window)

        if getWindowState(vehicle, window) then
            RollUpWindow(vehicle, window)
            stored.windows[window] = false
        else
            RollDownWindow(vehicle, window)
            stored.windows[window] = true
        end

        syncVehicleState(vehicle, { windows = stored.windows })
        emitVehicleAction('window', vehicle, { id = window, active = down, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('allWindows', function(data, cb)
    local vehicle = getVehicle()
    local down = data.down == true
    local ok, reason = validateVehicleAction('windows:all', vehicle, 'windows')

    if ok then
        local stored = getStoredVehicleState(vehicle)

        for window = 0, 3 do
            if getOverrideItem(vehicle, 'Windows', window) ~= false then
                if down then
                    RollDownWindow(vehicle, window)
                else
                    RollUpWindow(vehicle, window)
                end

                stored.windows[window] = down
            end
        end

        syncVehicleState(vehicle, { windows = stored.windows })
        emitVehicleAction('windows', vehicle, { active = down, all = true, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('switchSeat', function(data, cb)
    local vehicle = getVehicle()
    local seat = tonumber(data.id)
    local maxSeats = vehicle ~= 0 and GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 or -2
    local forcedSeat = seat and getOverrideItem(vehicle, 'Seats', seat) == true
    local validSeat = seat and seat >= -1 and (seat <= maxSeats or forcedSeat) and getOverrideItem(vehicle, 'Seats', seat) ~= false
    local ok, reason

    if not validSeat then
        ok, reason = denyAction('seat', 'invalid_seat')
    else
        ok, reason = validateVehicleAction('seat:' .. seat, vehicle, 'seats')
    end

    if ok then
        local occupant = GetPedInVehicleSeat(vehicle, seat)

        if occupant == 0 or occupant == getPed() then
            TaskWarpPedIntoVehicle(getPed(), vehicle, seat)
            emitVehicleAction('seat', vehicle, { id = seat, source = 'touchscreen' })
        else
            ok, reason = denyAction('seat', 'seat_occupied')
            notify(L('notifications.seatOccupied'), 'error')
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleRadio', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('radio', vehicle, 'radio')

    if ok then
        local stored = getStoredVehicleState(vehicle)
        stored.radio = not stored.radio
        SetVehicleRadioEnabled(vehicle, stored.radio)
        setSanAndreasRadioPower(vehicle, stored.radio)
        syncVehicleState(vehicle, { radio = stored.radio })

        if not stored.radio then
            SetVehRadioStation(vehicle, 'OFF')
        end

        emitVehicleAction('radio', vehicle, { active = stored.radio, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleHazards', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('hazards', vehicle, 'hazards')

    if ok then
        local stored = getStoredVehicleState(vehicle)
        stored.hazards = not stored.hazards
        SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
        SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
        syncVehicleState(vehicle, { hazards = stored.hazards })
        emitVehicleAction('hazards', vehicle, { active = stored.hazards, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleInteriorLight', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('interiorLight', vehicle, 'interiorLight')

    if ok then
        local stored = getStoredVehicleState(vehicle)
        stored.interiorLight = not stored.interiorLight
        SetVehicleInteriorlight(vehicle, stored.interiorLight)
        syncVehicleState(vehicle, { interiorLight = stored.interiorLight })
        emitVehicleAction('interiorLight', vehicle, { active = stored.interiorLight, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('detachTrailer', function(_, cb)
    local vehicle = getVehicle()
    local ok, reason = validateVehicleAction('trailer', vehicle, 'trailer')

    if ok then
        local attached = hasTrailer(vehicle)

        if attached then
            DetachVehicleFromTrailer(vehicle)
            emitVehicleAction('trailer', vehicle, { active = false, source = 'touchscreen' })
        else
            ok, reason = denyAction('trailer', 'no_trailer')
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleRoof', function(_, cb)
    local vehicle = getVehicle()
    local convertible = vehicle ~= 0 and DoesEntityExist(vehicle) and IsVehicleAConvertible(vehicle, false)
    local ok, reason

    if not convertible then
        ok, reason = denyAction('roof', 'unsupported_roof')
    else
        ok, reason = validateVehicleAction('roof', vehicle, 'roof')
    end

    if ok then
        local state = GetConvertibleRoofState(vehicle)
        local lowering = state == 0 or state == 3

        if lowering then
            LowerConvertibleRoof(vehicle, false)
        else
            RaiseConvertibleRoof(vehicle, false)
        end

        emitVehicleAction('roof', vehicle, { active = lowering, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleExtra', function(data, cb)
    local vehicle = getVehicle()
    local extra = tonumber(data.id)
    local overrideValue = extra and getOverrideItem(vehicle, 'Extras', extra)
    local validExtra = extra and extra >= 1 and extra <= 14 and (overrideValue == true or (overrideValue ~= false and DoesExtraExist(vehicle, extra)))
    local ok, reason

    if not validExtra then
        ok, reason = denyAction('extra', 'invalid_extra')
    else
        ok, reason = validateVehicleAction('extra:' .. extra, vehicle, 'extras')
    end

    if ok then
        local enabled = IsVehicleExtraTurnedOn(vehicle, extra)
        SetVehicleExtra(vehicle, extra, enabled and 1 or 0)
        emitVehicleAction('extra', vehicle, { id = extra, active = not enabled, source = 'touchscreen' })
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
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

    if not actionName then
        sendKeyFobState(fobMessage('disabled'))
        cb({ ok = false, reason = 'invalid_action' })
        return
    end

    local ok, vehicle, status = getKeyFobTargetStatus()
    if not ok then
        sendKeyFobState(status)
        cb({ ok = false, reason = 'target_unavailable' })
        return
    end

    if not keyFobActionEnabled(actionName, vehicle) then
        sendKeyFobState(fobMessage('disabled'))
        cb({ ok = false, reason = 'action_disabled' })
        return
    end

    local security = Config.ActionSecurity or {}
    if not consumeActionCooldown('fob:' .. action, security.KeyFobCooldown) then
        denyAction('fob:' .. action, 'cooldown')
        cb({ ok = false, reason = 'cooldown' })
        return
    end

    if not requestVehicleControl(vehicle) then
        sendKeyFobState(fobMessage('noSignal'))
        cb({ ok = false, reason = 'network_control' })
        return
    end

    local message = fobMessage('ready')
    playKeyFobInteraction(vehicle)

    local actionDelay = tonumber(getKeyFobInteraction().ActionDelay) or 0
    if actionDelay > 0 then
        Wait(actionDelay)
    end

    local stillValid, validatedVehicle, validatedStatus = getKeyFobTargetStatus()
    if not stillValid or validatedVehicle ~= vehicle or not keyFobActionEnabled(actionName, vehicle) then
        sendKeyFobState(validatedStatus or fobMessage('noSignal'))
        cb({ ok = false, reason = 'validation_changed' })
        return
    end

    if not requestVehicleControl(vehicle) then
        sendKeyFobState(fobMessage('noSignal'))
        cb({ ok = false, reason = 'network_control' })
        return
    end

    local details = { source = 'keyfob' }
    local performed = true

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

        details.active = not locked
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
        details.active = not running
    elseif action == 'trunk' then
        if vehicleHasDoor(vehicle, 5) then
            local open = not getDoorState(vehicle, 5)

            if getDoorState(vehicle, 5) then
                SetVehicleDoorShut(vehicle, 5, false)
                message = fobMessage('trunkClosed')
            else
                SetVehicleDoorOpen(vehicle, 5, false, false)
                message = fobMessage('trunkOpen')
            end

            keyFobFeedback(vehicle, 1, 0)
            details.active = open
            details.id = 5
        else
            message = fobMessage('noTrunk')
            performed = false
        end
    elseif action == 'windows' then
        local stored = getStoredVehicleState(vehicle)
        local down = not areAllWindowsDown(vehicle)

        for window = 0, 3 do
            if getOverrideItem(vehicle, 'Windows', window) ~= false then
                if down then
                    RollDownWindow(vehicle, window)
                else
                    RollUpWindow(vehicle, window)
                end

                stored.windows[window] = down
            end
        end

        syncVehicleState(vehicle, { windows = stored.windows })
        keyFobFeedback(vehicle, 1, 0)
        message = down and fobMessage('windowsDown') or fobMessage('windowsUp')
        details.active = down
        details.all = true
    elseif action == 'panic' then
        if fobPanicVehicle == vehicle and fobPanicUntil > GetGameTimer() then
            fobPanicUntil = 0
            fobPanicVehicle = 0
            local stored = getStoredVehicleState(vehicle)
            SetVehicleIndicatorLights(vehicle, 0, stored.hazards)
            SetVehicleIndicatorLights(vehicle, 1, stored.hazards)
            setVehicleLightsForced(vehicle, false)
            message = fobMessage('panicOff')
            details.active = false
        else
            fobPanicVehicle = vehicle
            fobPanicUntil = GetGameTimer() + (tonumber(getKeyFobConfig().PanicDuration) or 7000)
            message = fobMessage('panic')
            details.active = true
        end
    end

    if performed then
        emitVehicleAction(actionName, vehicle, details)
    end

    Wait(tonumber(Config.ActionRefreshDelay) or 125)
    sendKeyFobState(message)
    cb({ ok = performed, reason = performed and nil or 'unsupported' })
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

        if vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped and isVehicleSupported(vehicle) then
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

if getNetworkSyncConfig().Enabled ~= false and type(AddStateBagChangeHandler) == 'function' then
    AddStateBagChangeHandler(getNetworkSyncConfig().StateBagName or 'drs_vehcontrol', nil, function(bagName, _, value)
        if type(value) ~= 'table' or type(GetEntityFromStateBagName) ~= 'function' then
            return
        end

        CreateThread(function()
            local vehicle = 0

            for _ = 1, 10 do
                vehicle = GetEntityFromStateBagName(bagName)

                if vehicle ~= 0 and DoesEntityExist(vehicle) then
                    break
                end

                Wait(50)
            end

            if vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2 then
                applySyncedVehicleState(vehicle, value)
            end
        end)
    end)
end

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
