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
local cruiseVehicle = 0
local cruiseTargetSpeed = 0.0
local cruiseOriginalMaxSpeed = 0.0
local cruiseLastEngineHealth = 0.0
local cruiseLastBodyHealth = 0.0
local cruiseLimiterApplied = false
local cruiseStartedAt = 0
local cruiseBoatEngineRpm = 0.0
local cruiseRuntime = {
    lastSpeed = 0.0,
    adaptiveTargetSpeed = 0.0,
    adaptiveLeadVehicle = 0,
    adaptiveLeadSeenAt = 0,
    adaptiveProbeHandle = 0,
    adaptiveProbeStartedAt = 0,
    adaptiveProbeNextAt = 0,
    adaptiveProbeDistance = 0.0,
    adaptiveLastUpdateAt = 0,
    adaptiveProbeDrains = {},
    adaptiveProbeDrainCount = 0,
    collisionGraceUntil = 0,
    collisionSamples = {},
    commandedSlowdownTotal = 0.0,
    collisionEpisodeBaseline = nil,
    collisionContactLastSeenAt = 0,
    collisionContactReleasedAt = 0,
    roadClasses = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
        [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
        [10] = true, [11] = true, [12] = true, [17] = true, [18] = true,
        [19] = true, [20] = true, [22] = true
    }
}
local autopilotVehicle = 0
local autopilotPed = 0
local autopilotMode = nil
local autopilotBehavior = nil
local autopilotTarget = nil
local autopilotTargetSpeed = 0.0
local autopilotFlightHeight = 0
local autopilotLastSurfaceClearance = 0.0
local autopilotPlaneHoldAltitude = 0.0
local autopilotPlaneNavTarget = nil
local autopilotPlaneOrbitDirection = 0
local autopilotPlaneOrbitRadius = 0.0
local autopilotPlaneOrbitPointAt = 0
local autopilotTargetHeading = -1.0
local autopilotPhase = nil
local autopilotStartedAt = 0
local autopilotInputGraceUntil = 0
local autopilotLastTaskAt = 0
local autopilotStartEngineHealth = 0.0
local autopilotStartBodyHealth = 0.0
local stopAutopilot
local externalCruiseOwnerCache = false
local externalCruiseOwnerCheckedAt = -100000
local MPH_PER_MPS = 2.236936

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

local function getControlOverride(vehicle, name)
    local override = getVehicleOverride(vehicle)
    local controls = override and override.Controls

    if type(controls) == 'table' and controls[name] ~= nil then
        return controls[name] == true
    end

    return nil
end

local function classSupportsControl(vehicle, name, config)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local override = getControlOverride(vehicle, name)
    if override ~= nil then
        return override
    end

    local allowedClasses = type(config) == 'table' and config.AllowedClasses or nil
    return type(allowedClasses) ~= 'table' or allowedClasses[GetVehicleClass(vehicle)] == true
end

local function getExternalCruiseOwner()
    local cruiseConfig = Config.CruiseControl or {}
    local check = cruiseConfig.ExternalResourceCheck

    if type(check) ~= 'table' or check.Enabled ~= true then
        externalCruiseOwnerCache = false
        externalCruiseOwnerCheckedAt = -100000
        return nil
    end

    local now = GetGameTimer()
    local cacheMs = math.max(0, tonumber(check.CacheMs) or 1000)

    if now >= externalCruiseOwnerCheckedAt and now - externalCruiseOwnerCheckedAt < cacheMs then
        return externalCruiseOwnerCache or nil
    end

    externalCruiseOwnerCheckedAt = now
    externalCruiseOwnerCache = false

    if type(check.Resources) == 'table' then
        for _, resource in ipairs(check.Resources) do
            if isResourceStarted(resource) then
                externalCruiseOwnerCache = resource
                break
            end
        end
    end

    return externalCruiseOwnerCache or nil
end

local function isCruiseControlSupported(vehicle)
    return getExternalCruiseOwner() == nil
        and classSupportsControl(vehicle, 'cruise', Config.CruiseControl or {})
end

local function getAutopilotConfig()
    return Config.Autopilot or {}
end

local function getAutopilotAircraftType(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local class = GetVehicleClass(vehicle)
    local model = GetEntityModel(vehicle)

    if IsThisModelAHeli(model) then
        return 'helicopter'
    end

    if IsThisModelAPlane(model) then
        return 'plane'
    end

    if class == 15 then
        return 'helicopter'
    end

    if class == 16 then
        return 'plane'
    end

    return nil
end

local function isAutopilotSupported(vehicle)
    return getAutopilotAircraftType(vehicle) ~= nil
        and classSupportsControl(vehicle, 'autopilot', getAutopilotConfig())
end

local function applyBoatAnchorState(vehicle, anchored)
    if anchored then
        SetBoatFrozenWhenAnchored(vehicle, true)
        SetForcedBoatLocationWhenAnchored(vehicle, true)
        SetBoatAnchor(vehicle, true)
        return
    end

    SetBoatAnchor(vehicle, false)
    SetForcedBoatLocationWhenAnchored(vehicle, false)
    SetBoatFrozenWhenAnchored(vehicle, false)
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
        anchor = false,
        hazards = false,
        interiorLight = false,
        windows = {}
    }

    local networkConfig = getNetworkSyncConfig()
    local hasSyncedAnchor = false
    if networkConfig.Enabled ~= false and NetworkGetEntityIsNetworked(vehicle) then
        local synced = Entity(vehicle).state[networkConfig.StateBagName or 'drs_vehcontrol']

        if type(synced) == 'table' then
            if type(synced.anchor) == 'boolean' then
                stored.anchor = synced.anchor
                hasSyncedAnchor = true
            end

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

    if hasSyncedAnchor and IsThisModelABoat(model) then
        applyBoatAnchorState(vehicle, stored.anchor)
    end

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

local function getCruiseConfig()
    return Config.CruiseControl or {}
end

local function getCruiseLimiterSpeed(config, targetSpeed)
    local allowanceMph = math.max(0.0, tonumber(config.OverspeedAllowanceMph) or 0.75)
    return targetSpeed + allowanceMph / MPH_PER_MPS
end

local function getCruiseHoldSpeed(config, targetSpeed)
    local offsetMph = math.max(0.0, tonumber(config.HoldOffsetMph) or 0.25)
    local variationMph = math.max(0.0, tonumber(config.HoldVariationMph) or 1.0)
    local periodMs = math.max(1000, math.floor(tonumber(config.HoldVariationPeriodMs) or 8000))
    local elapsedMs = math.max(0, GetGameTimer() - cruiseStartedAt)
    local phase = (elapsedMs % periodMs) / periodMs * math.pi * 2.0
    local variation = (1.0 - math.cos(phase)) * 0.5 * variationMph

    return math.max(0.0, targetSpeed - (offsetMph + variation) / MPH_PER_MPS)
end

local function isBoatCruiseVehicle(vehicle)
    return GetVehicleClass(vehicle) == 14 or IsThisModelABoat(GetEntityModel(vehicle))
end

function cruiseRuntime.isAdaptiveRoadVehicle(vehicle)
    return not isBoatCruiseVehicle(vehicle)
        and cruiseRuntime.roadClasses[GetVehicleClass(vehicle)] == true
end

function cruiseRuntime.getAdaptiveDesiredGap(config, currentSpeed)
    local minimumGap = math.max(0.0, tonumber(config.MinimumGapMeters) or 6.0)
    local timeGap = math.max(0.1, tonumber(config.TimeGapSeconds) or 1.0)

    return minimumGap + math.max(0.0, tonumber(currentSpeed) or 0.0) * timeGap
end

function cruiseRuntime.getAdaptiveTargetSpeed(config, setSpeed, currentSpeed, leadSpeed, leadDistance)
    setSpeed = math.max(0.0, tonumber(setSpeed) or 0.0)
    leadSpeed = tonumber(leadSpeed)
    leadDistance = tonumber(leadDistance)

    if leadSpeed == nil or leadDistance == nil then
        return setSpeed
    end

    leadSpeed = math.max(0.0, leadSpeed)

    if setSpeed <= leadSpeed then
        return setSpeed
    end

    local timeGap = math.max(0.1, tonumber(config.TimeGapSeconds) or 1.0)
    local gapError = leadDistance - cruiseRuntime.getAdaptiveDesiredGap(config, currentSpeed)
    local desiredSpeed = leadSpeed + gapError / timeGap

    return math.max(0.0, math.min(setSpeed, desiredSpeed))
end

function cruiseRuntime.stepAdaptiveTargetSpeed(config, currentSpeed, targetSpeed, deltaSeconds)
    currentSpeed = math.max(0.0, tonumber(currentSpeed) or 0.0)
    targetSpeed = math.max(0.0, tonumber(targetSpeed) or 0.0)
    deltaSeconds = math.max(0.0, tonumber(deltaSeconds) or 0.0)

    if currentSpeed == targetSpeed or deltaSeconds <= 0.0 then
        return currentSpeed
    end

    local rateMphPerSecond

    if targetSpeed < currentSpeed then
        rateMphPerSecond = math.max(0.0, tonumber(config.SlowDownRateMphPerSecond) or 30.0)
    else
        rateMphPerSecond = math.max(0.0, tonumber(config.RecoveryRateMphPerSecond) or 8.0)
    end

    local maximumStep = rateMphPerSecond / 2.236936 * deltaSeconds

    if targetSpeed < currentSpeed then
        return math.max(targetSpeed, currentSpeed - maximumStep)
    end

    return math.min(targetSpeed, currentSpeed + maximumStep)
end

function cruiseRuntime.handoffAdaptiveProbe()
    local handle = cruiseRuntime.adaptiveProbeHandle

    if handle ~= 0 and cruiseRuntime.adaptiveProbeDrains[handle] ~= true then
        cruiseRuntime.adaptiveProbeDrains[handle] = true
        cruiseRuntime.adaptiveProbeDrainCount = cruiseRuntime.adaptiveProbeDrainCount + 1
    end

    cruiseRuntime.adaptiveProbeHandle = 0
    cruiseRuntime.adaptiveProbeStartedAt = 0
    cruiseRuntime.adaptiveProbeDistance = 0.0
end

function cruiseRuntime.reset()
    cruiseRuntime.handoffAdaptiveProbe()
    cruiseRuntime.lastSpeed = 0.0
    cruiseRuntime.adaptiveTargetSpeed = 0.0
    cruiseRuntime.adaptiveLeadVehicle = 0
    cruiseRuntime.adaptiveLeadSeenAt = 0
    cruiseRuntime.adaptiveProbeHandle = 0
    cruiseRuntime.adaptiveProbeStartedAt = 0
    cruiseRuntime.adaptiveProbeNextAt = 0
    cruiseRuntime.adaptiveProbeDistance = 0.0
    cruiseRuntime.adaptiveLastUpdateAt = 0
    cruiseRuntime.collisionGraceUntil = 0
    cruiseRuntime.collisionSamples = {}
    cruiseRuntime.commandedSlowdownTotal = 0.0
    cruiseRuntime.collisionEpisodeBaseline = nil
    cruiseRuntime.collisionContactLastSeenAt = 0
    cruiseRuntime.collisionContactReleasedAt = 0
end

local function getHorizontalForwardMotion(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local forward = GetEntityForwardVector(vehicle)
    local horizontalLength = math.sqrt(forward.x * forward.x + forward.y * forward.y)

    if horizontalLength < 0.001 then
        return nil
    end

    local forwardX = forward.x / horizontalLength
    local forwardY = forward.y / horizontalLength
    local forwardSpeed = velocity.x * forwardX + velocity.y * forwardY

    return forwardSpeed, velocity, forwardX, forwardY
end

function cruiseRuntime.getCollisionSpeed(vehicle)
    local forwardSpeed = getHorizontalForwardMotion(vehicle)

    if forwardSpeed ~= nil then
        return math.max(0.0, forwardSpeed)
    end

    return GetEntitySpeed(vehicle)
end

local function getCruiseSetSpeed(vehicle)
    if isBoatCruiseVehicle(vehicle) then
        local forwardSpeed = getHorizontalForwardMotion(vehicle)

        if forwardSpeed then
            return math.max(0.0, forwardSpeed)
        end
    end

    return GetEntitySpeed(vehicle)
end

function cruiseRuntime.getAdaptiveLeadData(vehicle, leadVehicle, config, maximumDistance)
    if leadVehicle == 0
        or leadVehicle == vehicle
        or not DoesEntityExist(leadVehicle)
        or not IsEntityAVehicle(leadVehicle)
    then
        return nil
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    local leadCoords = GetEntityCoords(leadVehicle)
    local forward = GetEntityForwardVector(vehicle)
    local forwardLength = math.sqrt(forward.x * forward.x + forward.y * forward.y)

    if forwardLength < 0.001 then
        return nil
    end

    local forwardX = forward.x / forwardLength
    local forwardY = forward.y / forwardLength
    local offsetX = leadCoords.x - vehicleCoords.x
    local offsetY = leadCoords.y - vehicleCoords.y
    local longitudinalDistance = offsetX * forwardX + offsetY * forwardY

    if longitudinalDistance <= 0.0 then
        return nil
    end

    local leadForward = GetEntityForwardVector(leadVehicle)
    local leadForwardLength = math.sqrt(leadForward.x * leadForward.x + leadForward.y * leadForward.y)

    if leadForwardLength < 0.001 then
        return nil
    end

    local headingAlignment = forwardX * (leadForward.x / leadForwardLength)
        + forwardY * (leadForward.y / leadForwardLength)
    local minimumAlignment = math.max(-1.0, math.min(
        1.0,
        tonumber(config.MinimumHeadingAlignment) or 0.5
    ))

    if headingAlignment < minimumAlignment then
        return nil
    end

    local _, vehicleMaximum = GetModelDimensions(GetEntityModel(vehicle))
    local leadMinimum = GetModelDimensions(GetEntityModel(leadVehicle))
    local vehicleFront = vehicleMaximum and math.max(0.0, vehicleMaximum.y) or 0.0
    local leadRear = leadMinimum and math.max(0.0, -leadMinimum.y) or 0.0
    local gapDistance = math.max(0.0, longitudinalDistance - vehicleFront - leadRear)

    if maximumDistance and gapDistance > maximumDistance then
        return nil
    end

    local leadVelocity = GetEntityVelocity(leadVehicle)
    local leadSpeed = math.max(0.0, leadVelocity.x * forwardX + leadVelocity.y * forwardY)

    return leadSpeed, gapDistance
end

function cruiseRuntime.getAdaptiveLookAhead(config, currentSpeed)
    local configuredMaximum = math.max(1.0, tonumber(config.MaxLookAheadMeters) or 30.0)
    local maximumLookAhead = math.min(30.0, configuredMaximum)
    local minimumLookAhead = math.min(
        maximumLookAhead,
        math.max(1.0, tonumber(config.MinLookAheadMeters) or 10.0)
    )
    local buffer = math.max(0.0, tonumber(config.LookAheadBufferMeters) or 3.0)

    return math.min(
        maximumLookAhead,
        math.max(minimumLookAhead, cruiseRuntime.getAdaptiveDesiredGap(config, currentSpeed) + buffer)
    )
end

function cruiseRuntime.startAdaptiveProbe(config, vehicle, currentSpeed, now)
    local lookAhead = cruiseRuntime.getAdaptiveLookAhead(config, currentSpeed)
    local probeRadius = math.max(0.25, math.min(
        4.0,
        tonumber(config.ProbeRadiusMeters) or 1.75
    ))
    local coords = GetEntityCoords(vehicle)
    local forward = GetEntityForwardVector(vehicle)
    local startZ = coords.z + 0.25

    cruiseRuntime.adaptiveProbeHandle = StartShapeTestCapsule(
        coords.x,
        coords.y,
        startZ,
        coords.x + forward.x * lookAhead,
        coords.y + forward.y * lookAhead,
        startZ + forward.z * lookAhead,
        probeRadius,
        2,
        vehicle,
        7
    ) or 0
    cruiseRuntime.adaptiveProbeStartedAt = now
    cruiseRuntime.adaptiveProbeDistance = lookAhead
    cruiseRuntime.adaptiveProbeNextAt = now + math.max(
        50,
        math.floor(tonumber(config.ProbeIntervalMs) or 150)
    )
end

function cruiseRuntime.updateAdaptiveProbe(config, vehicle, currentSpeed, now)
    if cruiseRuntime.adaptiveProbeHandle ~= 0 then
        local status, hit, hitPosition, surfaceNormal, hitEntity = GetShapeTestResult(
            cruiseRuntime.adaptiveProbeHandle
        )

        if status == 2 then
            cruiseRuntime.adaptiveProbeHandle = 0
            cruiseRuntime.adaptiveProbeStartedAt = 0

            if (hit == true or hit == 1) and hitEntity and hitEntity ~= 0 then
                local maximumDistance = cruiseRuntime.adaptiveProbeDistance
                    + math.max(0.25, tonumber(config.ProbeRadiusMeters) or 1.75)
                local leadSpeed = cruiseRuntime.getAdaptiveLeadData(
                    vehicle,
                    hitEntity,
                    config,
                    maximumDistance
                )

                if leadSpeed ~= nil then
                    cruiseRuntime.adaptiveLeadVehicle = hitEntity
                    cruiseRuntime.adaptiveLeadSeenAt = now
                end
            end
        elseif status == 0 then
            cruiseRuntime.adaptiveProbeHandle = 0
            cruiseRuntime.adaptiveProbeStartedAt = 0
        end
    end

    local maximumDrains = math.max(1, math.min(
        8,
        math.floor(tonumber(config.MaxPendingProbeDrains) or 4)
    ))

    if cruiseRuntime.adaptiveProbeHandle == 0
        and now >= cruiseRuntime.adaptiveProbeNextAt
        and cruiseRuntime.adaptiveProbeDrainCount < maximumDrains
    then
        cruiseRuntime.startAdaptiveProbe(config, vehicle, currentSpeed, now)
    end
end

function cruiseRuntime.updateAdaptiveFollowing(config, vehicle, currentSpeed, now)
    local adaptiveConfig = config.AdaptiveFollowing

    if type(adaptiveConfig) ~= 'table'
        or adaptiveConfig.Enabled == false
        or not cruiseRuntime.isAdaptiveRoadVehicle(vehicle)
    then
        cruiseRuntime.handoffAdaptiveProbe()
        cruiseRuntime.adaptiveLeadVehicle = 0
        cruiseRuntime.adaptiveLeadSeenAt = 0
        cruiseRuntime.adaptiveProbeNextAt = 0
        cruiseRuntime.adaptiveTargetSpeed = cruiseTargetSpeed
        cruiseRuntime.adaptiveLastUpdateAt = now
        return cruiseTargetSpeed
    end

    cruiseRuntime.updateAdaptiveProbe(adaptiveConfig, vehicle, currentSpeed, now)

    local leadSpeed
    local leadDistance
    local leadLostGrace = math.max(
        0,
        math.floor(tonumber(adaptiveConfig.LeadLostGraceMs) or 500)
    )
    local maximumDistance = cruiseRuntime.getAdaptiveLookAhead(adaptiveConfig, currentSpeed)
        + math.max(0.25, tonumber(adaptiveConfig.ProbeRadiusMeters) or 1.75)

    if cruiseRuntime.adaptiveLeadVehicle ~= 0
        and now - cruiseRuntime.adaptiveLeadSeenAt <= leadLostGrace
    then
        leadSpeed, leadDistance = cruiseRuntime.getAdaptiveLeadData(
            vehicle,
            cruiseRuntime.adaptiveLeadVehicle,
            adaptiveConfig,
            maximumDistance
        )
    end

    if leadSpeed == nil then
        cruiseRuntime.adaptiveLeadVehicle = 0
        cruiseRuntime.adaptiveLeadSeenAt = 0
    end

    local desiredSpeed = cruiseRuntime.getAdaptiveTargetSpeed(
        adaptiveConfig,
        cruiseTargetSpeed,
        currentSpeed,
        leadSpeed,
        leadDistance
    )
    local deltaSeconds = cruiseRuntime.adaptiveLastUpdateAt > 0
        and math.min(0.1, math.max(
            0.0,
            (now - cruiseRuntime.adaptiveLastUpdateAt) / 1000.0
        ))
        or 0.0

    cruiseRuntime.adaptiveTargetSpeed = cruiseRuntime.stepAdaptiveTargetSpeed(
        adaptiveConfig,
        cruiseRuntime.adaptiveTargetSpeed,
        desiredSpeed,
        deltaSeconds
    )
    cruiseRuntime.adaptiveLastUpdateAt = now

    return cruiseRuntime.adaptiveTargetSpeed
end

function cruiseRuntime.recordCollisionSample(config, now, currentSpeed, engineHealth, bodyHealth, forceSample)
    local sample = {
        at = now,
        speed = math.max(0.0, tonumber(currentSpeed) or 0.0),
        engineHealth = tonumber(engineHealth) or 0.0,
        bodyHealth = tonumber(bodyHealth) or 0.0,
        commandedSlowdown = cruiseRuntime.commandedSlowdownTotal
    }
    local samples = cruiseRuntime.collisionSamples
    local windowMs = math.max(
        100,
        math.floor(tonumber(config.CorroborationWindowMs) or 750)
    )
    local sampleIntervalMs = math.max(
        1,
        math.floor(tonumber(config.SampleIntervalMs) or 10),
        math.ceil(windowMs / 100)
    )
    local previousSample = samples[#samples]

    if not forceSample and previousSample and now - previousSample.at < sampleIntervalMs then
        samples[#samples] = sample
    else
        samples[#samples + 1] = sample
    end

    local cutoff = now - windowMs

    while #samples > 1 and samples[1].at < cutoff do
        table.remove(samples, 1)
    end

    while #samples > 120 do
        table.remove(samples, 1)
    end

    return samples, sample
end

function cruiseRuntime.shouldCancelForCollision(config, vehicle, now, currentSpeed, engineHealth, bodyHealth)
    local collisionConfig = type(config.CollisionCancel) == 'table' and config.CollisionCancel or config

    if type(collisionConfig) ~= 'table' or collisionConfig.Enabled == false then
        return false
    end

    local collided = HasEntityCollidedWithAnything(vehicle)
    local releaseMs = math.max(
        0,
        math.floor(tonumber(collisionConfig.ContactReleaseMs) or 150)
    )

    if collided
        and (cruiseRuntime.collisionContactReleasedAt or 0) > 0
        and now - (cruiseRuntime.collisionContactReleasedAt or 0) > releaseMs
    then
        cruiseRuntime.collisionEpisodeBaseline = nil
        cruiseRuntime.collisionContactLastSeenAt = 0
    end

    local newEpisode = collided and cruiseRuntime.collisionEpisodeBaseline == nil
    local samples, sample = cruiseRuntime.recordCollisionSample(
        collisionConfig,
        now,
        currentSpeed,
        engineHealth,
        bodyHealth,
        newEpisode
    )

    if not collided then
        if cruiseRuntime.collisionEpisodeBaseline ~= nil then
            if (cruiseRuntime.collisionContactReleasedAt or 0) == 0 then
                cruiseRuntime.collisionContactReleasedAt = now
            elseif now - (cruiseRuntime.collisionContactReleasedAt or 0) > releaseMs then
                cruiseRuntime.collisionEpisodeBaseline = nil
                cruiseRuntime.collisionContactLastSeenAt = 0
                cruiseRuntime.collisionContactReleasedAt = 0
            end
        end

        return false
    end

    if newEpisode then
        cruiseRuntime.collisionEpisodeBaseline = samples[#samples - 1] or sample
    end

    cruiseRuntime.collisionContactLastSeenAt = now
    cruiseRuntime.collisionContactReleasedAt = 0

    local baseline = cruiseRuntime.collisionEpisodeBaseline

    if samples[1].at > baseline.at then
        baseline = samples[1]
        cruiseRuntime.collisionEpisodeBaseline = baseline
    end

    if now < cruiseRuntime.collisionGraceUntil then
        return false
    end

    local minimumImpactSpeed = math.max(
        0.0,
        tonumber(collisionConfig.MinimumImpactSpeedMph) or 2.0
    ) / MPH_PER_MPS

    if baseline.speed < minimumImpactSpeed then
        return false
    end

    local minimumSpeedDrop = math.max(
        0.0,
        tonumber(collisionConfig.MinimumSpeedDropMph) or 2.0
    ) / MPH_PER_MPS
    local minimumHealthLoss = math.max(
        0.0,
        tonumber(collisionConfig.MinimumHealthLoss) or 1.0
    )
    local commandedSlowdown = math.max(
        0.0,
        sample.commandedSlowdown - baseline.commandedSlowdown
    )
    local speedDrop = baseline.speed - sample.speed - commandedSlowdown
    local healthLoss = math.max(
        baseline.engineHealth - sample.engineHealth,
        baseline.bodyHealth - sample.bodyHealth
    )
    local speedCorroborated = minimumSpeedDrop > 0.0 and speedDrop >= minimumSpeedDrop
    local healthCorroborated = minimumHealthLoss > 0.0 and healthLoss >= minimumHealthLoss

    if minimumSpeedDrop <= 0.0 and minimumHealthLoss <= 0.0 then
        return true
    end

    return speedCorroborated or healthCorroborated
end

local function getBoatCruiseEngineRpm(config, vehicle)
    local rpmConfig = config.BoatEngineRpm

    if rpmConfig == false or (type(rpmConfig) == 'table' and rpmConfig.Enabled == false) then
        return nil
    end

    rpmConfig = type(rpmConfig) == 'table' and rpmConfig or {}

    local minRpm = math.min(1.0, math.max(0.0, tonumber(rpmConfig.MinRpm) or 0.35))
    local maxRpm = math.min(1.0, math.max(minRpm, tonumber(rpmConfig.MaxRpm) or 0.85))
    local currentRpm = tonumber(GetVehicleCurrentRpm(vehicle)) or 0.0

    return math.min(maxRpm, math.max(minRpm, currentRpm))
end

local function applyBoatCruiseEngineRpm(config, vehicle)
    if config.BoatEngineRpm == false
        or cruiseBoatEngineRpm <= 0.0
        or not isBoatCruiseVehicle(vehicle)
        or not IsEntityInWater(vehicle)
    then
        return
    end

    SetVehicleCurrentRpm(vehicle, cruiseBoatEngineRpm)
end

local function applyCruiseCorrection(config, vehicle, currentSpeed, targetSpeed, steering)
    if config.SpeedCorrection == false then
        return
    end

    local pauseWhileSteering = config.PauseCorrectionWhileSteering ~= false
    local holdSpeed = getCruiseHoldSpeed(config, targetSpeed)
    local tolerance = math.max(0.0, tonumber(config.CorrectionToleranceMph) or 0.05) / MPH_PER_MPS

    if isBoatCruiseVehicle(vehicle) then
        if pauseWhileSteering and steering then
            return
        end

        if not IsEntityInWater(vehicle) then
            return
        end

        local forwardSpeed, velocity, forwardX, forwardY = getHorizontalForwardMotion(vehicle)

        if forwardSpeed and forwardSpeed < holdSpeed - tolerance then
            local correction = holdSpeed - forwardSpeed

            SetEntityVelocity(
                vehicle,
                velocity.x + forwardX * correction,
                velocity.y + forwardY * correction,
                velocity.z
            )
        end

        return
    end

    if not IsVehicleOnAllWheels(vehicle) then
        return
    end

    local adaptiveConfig = config.AdaptiveFollowing

    if cruiseRuntime.adaptiveLeadVehicle ~= 0
        and type(adaptiveConfig) == 'table'
        and targetSpeed < cruiseTargetSpeed - tolerance
    then
        local forwardSpeed, velocity, forwardX, forwardY = getHorizontalForwardMotion(vehicle)

        if forwardSpeed and forwardSpeed > holdSpeed + tolerance then
            local slowDownRate = math.max(
                0.0,
                tonumber(adaptiveConfig.SlowDownRateMphPerSecond) or 30.0
            ) / MPH_PER_MPS
            local frameTime = math.max(0.0, GetFrameTime())
            local maximumReduction = slowDownRate * math.min(0.1, frameTime)
            local nextForwardSpeed = math.max(holdSpeed, forwardSpeed - maximumReduction)
            local correction = nextForwardSpeed - forwardSpeed

            cruiseRuntime.commandedSlowdownTotal = cruiseRuntime.commandedSlowdownTotal
                + math.max(0.0, -correction)

            SetEntityVelocity(
                vehicle,
                velocity.x + forwardX * correction,
                velocity.y + forwardY * correction,
                velocity.z
            )

            return
        end
    end

    if pauseWhileSteering and steering then
        return
    end

    if currentSpeed < holdSpeed - tolerance then
        SetVehicleForwardSpeed(vehicle, holdSpeed)
    end
end

local function isGameplayControlPressed(control)
    return IsControlPressed(0, control)
        or IsDisabledControlPressed(0, control)
        or IsControlPressed(2, control)
        or IsDisabledControlPressed(2, control)
end

local defaultBoatAnchorMovementControls = { 61, 62, 71, 72 }

local function isBoatAnchorMovementInputPressed()
    local anchorConfig = Config.BoatAnchor or {}
    local controls = type(anchorConfig.MovementControls) == 'table'
        and anchorConfig.MovementControls
        or defaultBoatAnchorMovementControls

    for _, configuredControl in ipairs(controls) do
        local control = tonumber(configuredControl)

        if control and (IsControlPressed(0, control) or IsDisabledControlPressed(0, control)) then
            return true
        end
    end

    return false
end

local function stopCruiseControl(reason, emitAction)
    local vehicle = cruiseVehicle
    local targetSpeed = cruiseTargetSpeed

    if vehicle ~= 0 and DoesEntityExist(vehicle) and cruiseLimiterApplied then
        SetVehicleMaxSpeed(vehicle, math.max(cruiseOriginalMaxSpeed, 0.0))
    end

    cruiseVehicle = 0
    cruiseTargetSpeed = 0.0
    cruiseOriginalMaxSpeed = 0.0
    cruiseLastEngineHealth = 0.0
    cruiseLastBodyHealth = 0.0
    cruiseLimiterApplied = false
    cruiseStartedAt = 0
    cruiseBoatEngineRpm = 0.0
    cruiseRuntime.reset()

    if emitAction ~= false and vehicle ~= 0 and DoesEntityExist(vehicle) then
        emitVehicleAction('cruise', vehicle, {
            active = false,
            targetMph = math.floor(targetSpeed * MPH_PER_MPS + 0.5),
            reason = reason,
            source = 'touchscreen'
        })
    end
end

local function startCruiseControl(vehicle, targetSpeed)
    if autopilotVehicle ~= 0 and stopAutopilot then
        stopAutopilot('cruise', true)
    end

    if cruiseVehicle ~= 0 then
        stopCruiseControl('replaced', true)
    end

    local config = getCruiseConfig()
    local now = GetGameTimer()

    cruiseRuntime.reset()

    cruiseVehicle = vehicle
    cruiseTargetSpeed = targetSpeed
    cruiseOriginalMaxSpeed = math.max(GetVehicleEstimatedMaxSpeed(vehicle), targetSpeed)
    cruiseLastEngineHealth = GetVehicleEngineHealth(vehicle)
    cruiseLastBodyHealth = GetVehicleBodyHealth(vehicle)
    cruiseLimiterApplied = config.UseSpeedLimiter ~= false
    cruiseStartedAt = now
    cruiseBoatEngineRpm = 0.0
    cruiseRuntime.lastSpeed = getCruiseSetSpeed(vehicle)
    cruiseRuntime.adaptiveTargetSpeed = targetSpeed
    cruiseRuntime.adaptiveProbeNextAt = now
    cruiseRuntime.adaptiveLastUpdateAt = now
    cruiseRuntime.collisionSamples = {
        {
            at = now,
            speed = cruiseRuntime.getCollisionSpeed(vehicle),
            engineHealth = cruiseLastEngineHealth,
            bodyHealth = cruiseLastBodyHealth,
            commandedSlowdown = cruiseRuntime.commandedSlowdownTotal
        }
    }

    local collisionConfig = type(config.CollisionCancel) == 'table' and config.CollisionCancel or {}
    cruiseRuntime.collisionGraceUntil = now + math.max(
        0,
        math.floor(tonumber(collisionConfig.EngagementGraceMs) or 1000)
    )

    if isBoatCruiseVehicle(vehicle) then
        cruiseBoatEngineRpm = getBoatCruiseEngineRpm(config, vehicle) or 0.0
    end

    if cruiseLimiterApplied then
        SetVehicleMaxSpeed(vehicle, getCruiseLimiterSpeed(config, targetSpeed))
    end

    emitVehicleAction('cruise', vehicle, {
        active = true,
        targetMph = math.floor(targetSpeed * MPH_PER_MPS + 0.5),
        source = 'touchscreen'
    })
end

local defaultAutopilotCancelControls = {
    59, 60, 61, 62, 71, 72,
    87, 88, 89, 90,
    107, 108, 109, 110, 111, 112,
    119, 122, 352
}

local function getAutopilotModeConfig(mode)
    local config = getAutopilotConfig()
    local modeConfig = mode == 'plane' and config.Plane or config.Helicopter

    return type(modeConfig) == 'table' and modeConfig or {}
end

local function getAutopilotCancelControls()
    local controls = getAutopilotConfig().CancelControls
    return type(controls) == 'table' and controls or defaultAutopilotCancelControls
end

local function isAutopilotCancelControl(control)
    if autopilotVehicle == 0 then
        return false
    end

    for _, configuredControl in ipairs(getAutopilotCancelControls()) do
        if tonumber(configuredControl) == control then
            return true
        end
    end

    return false
end

local function getAutopilotWaypoint(vehicle)
    if not IsWaypointActive() then
        return nil
    end

    local waypoint = GetFirstBlipInfoId(8)

    if waypoint == 0 or not DoesBlipExist(waypoint) then
        return nil
    end

    local waypointCoords = GetBlipInfoIdCoord(waypoint)
    local vehicleCoords = GetEntityCoords(vehicle)

    return {
        x = waypointCoords.x,
        y = waypointCoords.y,
        z = vehicleCoords.z
    }
end

local function getHorizontalDistanceToTarget(vehicle, target)
    if vehicle == 0 or not DoesEntityExist(vehicle) or type(target) ~= 'table' then
        return math.huge
    end

    local coords = GetEntityCoords(vehicle)
    local deltaX = target.x - coords.x
    local deltaY = target.y - coords.y

    return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

local function getAutopilotSurfaceClearance(vehicle)
    local measuredHeight = GetEntityHeightAboveGround(vehicle)
    local clearance = type(measuredHeight) == 'number' and measuredHeight > 0.0
        and measuredHeight
        or nil
    local coords = GetEntityCoords(vehicle)
    local waterFound, waterHeight = GetWaterHeightNoWaves(coords.x, coords.y, coords.z)

    if waterFound and type(waterHeight) == 'number' and waterHeight <= coords.z then
        local waterClearance = math.max(0.0, coords.z - waterHeight)
        clearance = clearance and math.min(clearance, waterClearance) or waterClearance
    end

    return math.max(0.0, clearance or 0.0), clearance ~= nil
end

local function getAutopilotHeadingToTarget(vehicle, target, fallback)
    if vehicle == 0 or not DoesEntityExist(vehicle) or type(target) ~= 'table' then
        return tonumber(fallback) or -1.0
    end

    local coords = GetEntityCoords(vehicle)
    local deltaX = target.x - coords.x
    local deltaY = target.y - coords.y

    if deltaX * deltaX + deltaY * deltaY < 0.25 then
        return tonumber(fallback) or GetEntityHeading(vehicle)
    end

    return GetHeadingFromVector_2d(deltaX, deltaY)
end

local function clampValue(value, minimum, maximum)
    return math.min(maximum, math.max(minimum, value))
end

local function getSignedHeadingDelta(currentHeading, targetHeading)
    return (targetHeading - currentHeading + 540.0) % 360.0 - 180.0
end

local function stepHeadingToward(currentHeading, targetHeading, maximumStep, deadzone)
    local delta = getSignedHeadingDelta(currentHeading, targetHeading)

    if math.abs(delta) <= math.max(0.0, deadzone or 0.0) then
        return currentHeading % 360.0
    end

    return (currentHeading + clampValue(delta, -maximumStep, maximumStep)) % 360.0
end

local function stepHorizontalVelocity(
    currentX,
    currentY,
    currentZ,
    targetX,
    targetY,
    maximumDelta,
    deadzone
)
    local deltaX = targetX - currentX
    local deltaY = targetY - currentY
    local deltaLength = math.sqrt(deltaX * deltaX + deltaY * deltaY)

    if deltaLength <= math.max(0.0, deadzone or 0.0) then
        return targetX, targetY, currentZ
    end

    local ratio = math.min(1.0, math.max(0.0, maximumDelta) / deltaLength)

    return currentX + deltaX * ratio, currentY + deltaY * ratio, currentZ
end

local function getHelicopterRouteSpeed(
    distance,
    arrivalRadius,
    slowDownDistance,
    targetSpeed,
    alignment
)
    if distance <= arrivalRadius then
        return 0.0
    end

    local slowRange = math.max(0.001, slowDownDistance - arrivalRadius)
    local progress = clampValue((distance - arrivalRadius) / slowRange, 0.0, 1.0)

    return math.max(0.0, targetSpeed)
        * math.sqrt(progress)
        * clampValue(alignment, 0.0, 1.0)
end

local function calculatePlaneOrbitRadius(speedMps, minimumRadius, maximumBankDegrees)
    local speed = math.max(0.0, speedMps)
    local minimum = math.max(100.0, minimumRadius)
    local bankRadians = math.rad(clampValue(maximumBankDegrees, 5.0, 45.0))
    local denominator = 9.81 * math.tan(bankRadians)

    if denominator <= 0.001 then
        return minimum
    end

    return math.max(minimum, speed * speed / denominator)
end

local function choosePlaneOrbitDirection(center, coords, travelX, travelY)
    local radialX = coords.x - center.x
    local radialY = coords.y - center.y
    local radialLength = math.sqrt(radialX * radialX + radialY * radialY)
    local travelLength = math.sqrt(travelX * travelX + travelY * travelY)

    if radialLength < 0.001 or travelLength < 0.001 then
        return 1
    end

    radialX = radialX / radialLength
    radialY = radialY / radialLength
    travelX = travelX / travelLength
    travelY = travelY / travelLength

    local counterClockwiseDot = -radialY * travelX + radialX * travelY
    local clockwiseDot = radialY * travelX - radialX * travelY

    return counterClockwiseDot >= clockwiseDot and 1 or -1
end

local function calculatePlaneOrbitTarget(center, coords, direction, radius, leadDegrees, altitude)
    local radialAngle = math.atan(coords.y - center.y, coords.x - center.x)
    local targetAngle = radialAngle + direction * math.rad(leadDegrees)

    return {
        x = center.x + math.cos(targetAngle) * radius,
        y = center.y + math.sin(targetAngle) * radius,
        z = altitude
    }
end

local function getPlaneOrbitTerrainSettings(modeConfig)
    local config = getAutopilotConfig()
    local terrainClearance = math.max(
        0.0,
        tonumber(modeConfig.MinTerrainClearance)
            or tonumber(config.MinTerrainClearance)
            or 100.0
    )
    local altitudeBuffer = math.max(0.0, tonumber(modeConfig.OrbitAltitudeBuffer) or 100.0)

    return terrainClearance, altitudeBuffer
end

local function getPlaneRequiredAltitudeAtPoint(x, y, baseAltitude, terrainClearance, altitudeBuffer)
    local groundFound, groundZ = GetGroundZFor_3dCoord(x, y, baseAltitude + 1000.0, false)

    if groundFound and type(groundZ) == 'number' then
        return math.max(baseAltitude, groundZ + terrainClearance + altitudeBuffer), true
    end

    return baseAltitude, false
end

local function getPlaneOrbitSafeAltitude(center, radius, baseAltitude, modeConfig)
    local terrainClearance, altitudeBuffer = getPlaneOrbitTerrainSettings(modeConfig)
    local sampleCount = math.floor(clampValue(
        tonumber(modeConfig.OrbitTerrainSamples) or 12,
        4,
        36
    ))
    local highestBaseAltitude = baseAltitude
    local centerAltitude, centerFound = getPlaneRequiredAltitudeAtPoint(
        center.x,
        center.y,
        baseAltitude,
        terrainClearance,
        0.0
    )

    if centerFound then
        highestBaseAltitude = math.max(highestBaseAltitude, centerAltitude)
    end

    for sample = 0, sampleCount - 1 do
        local angle = sample / sampleCount * math.pi * 2.0
        local sampleAltitude, sampleFound = getPlaneRequiredAltitudeAtPoint(
            center.x + math.cos(angle) * radius,
            center.y + math.sin(angle) * radius,
            baseAltitude,
            terrainClearance,
            0.0
        )

        if sampleFound then
            highestBaseAltitude = math.max(highestBaseAltitude, sampleAltitude)
        end
    end

    return highestBaseAltitude + altitudeBuffer
end

local function raisePlaneOrbitAltitudeForTarget(target, modeConfig)
    local terrainClearance, altitudeBuffer = getPlaneOrbitTerrainSettings(modeConfig)
    local requiredAltitude, groundFound = getPlaneRequiredAltitudeAtPoint(
        target.x,
        target.y,
        autopilotPlaneHoldAltitude,
        terrainClearance,
        altitudeBuffer
    )

    if groundFound and requiredAltitude > autopilotPlaneHoldAltitude then
        autopilotPlaneHoldAltitude = requiredAltitude
    end

    target.z = autopilotPlaneHoldAltitude
end

local function advancePlaneOrbitTarget(vehicle, modeConfig)
    if vehicle == 0
        or not DoesEntityExist(vehicle)
        or type(autopilotTarget) ~= 'table'
        or autopilotPlaneOrbitDirection == 0
        or autopilotPlaneOrbitRadius <= 0.0
        or autopilotPlaneHoldAltitude <= 0.0
    then
        return false
    end

    local coords = GetEntityCoords(vehicle)
    local leadDegrees = clampValue(tonumber(modeConfig.OrbitLeadDegrees) or 60.0, 15.0, 120.0)

    autopilotPlaneNavTarget = calculatePlaneOrbitTarget(
        autopilotTarget,
        coords,
        autopilotPlaneOrbitDirection,
        autopilotPlaneOrbitRadius,
        leadDegrees,
        autopilotPlaneHoldAltitude
    )
    raisePlaneOrbitAltitudeForTarget(autopilotPlaneNavTarget, modeConfig)
    autopilotPlaneOrbitPointAt = GetGameTimer()

    return true
end

local function preparePlaneOrbit(vehicle, modeConfig, orbitRadius)
    if vehicle == 0 or not DoesEntityExist(vehicle) or type(autopilotTarget) ~= 'table' then
        return false
    end

    local coords = GetEntityCoords(vehicle)
    local safeBaseAltitude = math.max(coords.z, tonumber(autopilotTarget.z) or coords.z)
    autopilotPlaneOrbitRadius = math.max(100.0, orbitRadius)
    autopilotPlaneHoldAltitude = getPlaneOrbitSafeAltitude(
        autopilotTarget,
        autopilotPlaneOrbitRadius,
        safeBaseAltitude,
        modeConfig
    )

    local velocity = GetEntityVelocity(vehicle)
    local travelX = velocity.x
    local travelY = velocity.y

    if travelX * travelX + travelY * travelY < 1.0 then
        local forward = GetEntityForwardVector(vehicle)
        travelX = forward.x
        travelY = forward.y
    end

    autopilotPlaneOrbitDirection = choosePlaneOrbitDirection(
        autopilotTarget,
        coords,
        travelX,
        travelY
    )
    autopilotPhase = 'orbit'

    return advancePlaneOrbitTarget(vehicle, modeConfig)
end

local function applyPlaneOrbitAltitudeSafety(vehicle, modeConfig)
    if autopilotPlaneHoldAltitude <= 0.0 then
        return false
    end

    local coords = GetEntityCoords(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local altitudeTolerance = math.max(0.0, tonumber(modeConfig.OrbitAltitudeTolerance) or 10.0)
    local maximumClimb = math.max(0.0, tonumber(modeConfig.OrbitAltitudeAssistMaxClimbMps) or 8.0)
    local emergencyClearance = math.max(
        0.0,
        tonumber(modeConfig.OrbitEmergencyTerrainClearance) or 75.0
    )
    local emergencyClimb = math.max(
        maximumClimb,
        tonumber(modeConfig.OrbitEmergencyClimbRateMps) or 12.0
    )
    local altitudeError = autopilotPlaneHoldAltitude - coords.z
    local minimumVerticalSpeed = 0.0

    if altitudeError > altitudeTolerance then
        minimumVerticalSpeed = math.min(maximumClimb, math.max(1.0, altitudeError * 0.25))
    end

    if getAutopilotSurfaceClearance(vehicle) < emergencyClearance then
        minimumVerticalSpeed = math.max(minimumVerticalSpeed, emergencyClimb)
    end

    if velocity.z < minimumVerticalSpeed then
        SetEntityVelocity(vehicle, velocity.x, velocity.y, minimumVerticalSpeed)
        return true
    end

    return false
end

local function isHelicopterWaypointControllerEnabled(modeConfig)
    local horizontalConfig = type(modeConfig.HorizontalControl) == 'table'
        and modeConfig.HorizontalControl
        or {}
    local verticalConfig = type(modeConfig.VerticalControl) == 'table'
        and modeConfig.VerticalControl
        or {}

    return horizontalConfig.Enabled ~= false and verticalConfig.Enabled ~= false
end

local function applyHelicopterWaypointControl(vehicle, modeConfig, distance)
    if autopilotMode ~= 'helicopter'
        or autopilotBehavior ~= 'waypoint'
        or vehicle == 0
        or not DoesEntityExist(vehicle)
        or type(autopilotTarget) ~= 'table'
    then
        return false
    end

    local horizontalConfig = type(modeConfig.HorizontalControl) == 'table'
        and modeConfig.HorizontalControl
        or {}
    local verticalConfig = type(modeConfig.VerticalControl) == 'table'
        and modeConfig.VerticalControl
        or {}

    if not isHelicopterWaypointControllerEnabled(modeConfig) then
        return false
    end

    local coords = GetEntityCoords(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local deltaX = autopilotTarget.x - coords.x
    local deltaY = autopilotTarget.y - coords.y
    local horizontalDistance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    local directionX = horizontalDistance > 0.001 and deltaX / horizontalDistance or 0.0
    local directionY = horizontalDistance > 0.001 and deltaY / horizontalDistance or 0.0
    local maximumDeltaTime = math.max(
        0.001,
        tonumber(horizontalConfig.MaxDeltaTimeSeconds) or 0.05
    )
    local deltaTime = clampValue(GetFrameTime(), 0.001, maximumDeltaTime)
    local targetVelocityX = 0.0
    local targetVelocityY = 0.0
    local targetHeading = horizontalDistance > 0.001
        and GetHeadingFromVector_2d(deltaX, deltaY)
        or GetEntityHeading(vehicle)
    local currentHeading = GetEntityHeading(vehicle)
    local headingDelta = getSignedHeadingDelta(currentHeading, targetHeading)
    local minimumAlignment = clampValue(
        tonumber(horizontalConfig.MinimumAlignment) or 0.15,
        0.0,
        1.0
    )
    local alignment = minimumAlignment
        + (1.0 - minimumAlignment) * math.max(0.0, math.cos(math.rad(headingDelta)))

    if horizontalConfig.Enabled ~= false then
        if autopilotPhase == 'holding' then
            local holdRadius = math.max(0.5, tonumber(modeConfig.HoldRadius) or 3.0)

            if distance > holdRadius then
                local holdSpeed = math.max(0.1, tonumber(modeConfig.HoldSpeedMph) or 5.0) / MPH_PER_MPS
                local correctionSpeed = math.min(holdSpeed, math.max(0.5, (distance - holdRadius) * 0.35))
                targetVelocityX = directionX * correctionSpeed
                targetVelocityY = directionY * correctionSpeed
            end
        else
            local arrivalRadius = math.max(0.5, tonumber(modeConfig.ArrivalRadius) or 25.0)
            local slowDownDistance = math.max(
                arrivalRadius + 0.001,
                tonumber(modeConfig.SlowDownDistance) or 100.0
            )
            local routeSpeed = getHelicopterRouteSpeed(
                distance,
                arrivalRadius,
                slowDownDistance,
                autopilotTargetSpeed,
                alignment
            )

            targetVelocityX = directionX * routeSpeed
            targetVelocityY = directionY * routeSpeed
        end
    else
        targetVelocityX = velocity.x
        targetVelocityY = velocity.y
    end

    local currentHorizontalSpeed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
    local targetHorizontalSpeed = math.sqrt(
        targetVelocityX * targetVelocityX + targetVelocityY * targetVelocityY
    )
    local accelerating = targetHorizontalSpeed >= currentHorizontalSpeed
        and velocity.x * targetVelocityX + velocity.y * targetVelocityY >= 0.0
    local response = accelerating
        and math.max(0.0, tonumber(horizontalConfig.AccelerationMps2) or 3.0)
        or math.max(0.0, tonumber(horizontalConfig.DecelerationMps2) or 5.0)
    local nextVelocityX, nextVelocityY, nextVelocityZ = stepHorizontalVelocity(
        velocity.x,
        velocity.y,
        velocity.z,
        targetVelocityX,
        targetVelocityY,
        response * deltaTime,
        math.max(0.0, tonumber(horizontalConfig.VelocityDeadzoneMps) or 0.05)
    )

    if verticalConfig.Enabled ~= false then
        local surfaceClearance, clearanceValid = getAutopilotSurfaceClearance(vehicle)

        if clearanceValid and surfaceClearance > 0.1 then
            autopilotLastSurfaceClearance = surfaceClearance
        else
            surfaceClearance = autopilotLastSurfaceClearance > 0.0
                and autopilotLastSurfaceClearance
                or autopilotFlightHeight
        end

        local clearanceError = autopilotFlightHeight - surfaceClearance
        local verticalDeadzone = math.max(0.0, tonumber(verticalConfig.DeadzoneMeters) or 1.0)

        if math.abs(clearanceError) <= verticalDeadzone then
            nextVelocityZ = 0.0
        else
            local gain = math.max(0.0, tonumber(verticalConfig.Gain) or 0.35)
            local maximumClimb = math.max(0.0, tonumber(verticalConfig.MaxClimbMps) or 5.0)
            local maximumDescent = math.max(0.0, tonumber(verticalConfig.MaxDescentMps) or 3.0)

            nextVelocityZ = clampValue(
                clearanceError * gain,
                -maximumDescent,
                maximumClimb
            )
        end
    end

    SetEntityVelocity(vehicle, nextVelocityX, nextVelocityY, nextVelocityZ)

    if horizontalConfig.Enabled ~= false and horizontalDistance > 1.0 then
        local yawRate = math.max(0.0, tonumber(horizontalConfig.YawRateDegPerSecond) or 45.0)
        local yawDeadzone = math.max(0.0, tonumber(horizontalConfig.YawDeadzoneDegrees) or 1.0)
        local nextHeading = stepHeadingToward(
            currentHeading,
            targetHeading,
            yawRate * deltaTime,
            yawDeadzone
        )

        SetEntityHeading(vehicle, nextHeading)
        autopilotTargetHeading = targetHeading
    end

    return true
end

local function getAutopilotTargetSpeed(mode, currentSpeed)
    local modeConfig = getAutopilotModeConfig(mode)
    local defaultMinimum = mode == 'plane' and 60.0 or 10.0
    local defaultMaximum = mode == 'plane' and 250.0 or 120.0
    local minimumMph = math.max(0.0, tonumber(modeConfig.MinSpeedMph) or defaultMinimum)
    local maximumMph = math.max(minimumMph, tonumber(modeConfig.MaxSpeedMph) or defaultMaximum)
    local currentMph = math.max(0.0, currentSpeed * MPH_PER_MPS)

    if mode == 'plane' and currentMph < minimumMph then
        return nil, minimumMph
    end

    if mode == 'helicopter' then
        local waypointMph = math.max(minimumMph, tonumber(modeConfig.WaypointSpeedMph) or 35.0)
        currentMph = math.max(currentMph, waypointMph)
    end

    return math.min(maximumMph, math.max(minimumMph, currentMph)) / MPH_PER_MPS, minimumMph
end

local function issueAutopilotTask()
    if autopilotVehicle == 0
        or autopilotPed == 0
        or not DoesEntityExist(autopilotVehicle)
        or not DoesEntityExist(autopilotPed)
        or type(autopilotTarget) ~= 'table'
    then
        return false
    end

    local config = getAutopilotConfig()
    local modeConfig = getAutopilotModeConfig(autopilotMode)
    local terrainClearance = math.floor(math.max(
        0.0,
        tonumber(modeConfig.MinTerrainClearance)
            or tonumber(config.MinTerrainClearance)
            or 30.0
    ) + 0.5)

    if autopilotMode == 'plane' then
        local orbiting = autopilotPhase == 'orbit'
        local navigationTarget = orbiting and autopilotPlaneNavTarget or autopilotTarget

        if type(navigationTarget) ~= 'table' then
            return false
        end

        local targetAltitude = orbiting and autopilotPlaneHoldAltitude > 0.0
            and autopilotPlaneHoldAltitude
            or navigationTarget.z
        local flightHeight = math.floor(targetAltitude + 0.5)
        local arrivalRadius = math.max(25.0, tonumber(modeConfig.ArrivalRadius) or 300.0)
        local radius = orbiting
            and math.max(25.0, tonumber(modeConfig.OrbitTaskReachedDistance) or 75.0)
            or arrivalRadius

        TaskPlaneMission(
            autopilotPed,
            autopilotVehicle,
            0,
            0,
            navigationTarget.x,
            navigationTarget.y,
            targetAltitude,
            4,
            autopilotTargetSpeed,
            radius,
            -1.0,
            flightHeight,
            terrainClearance,
            true
        )
        SetPedKeepTask(autopilotPed, true)

        autopilotLastTaskAt = GetGameTimer()

        return true
    end

    local hovering = autopilotBehavior == 'hover'

    if not hovering then
        autopilotLastTaskAt = GetGameTimer()
        return true
    end

    local arrivalRadius = math.max(0.5, tonumber(modeConfig.HoverRadius) or 3.0)
    local targetRadius = arrivalRadius
    local slowDownDistance = math.max(
        arrivalRadius,
        tonumber(modeConfig.HoverSlowDownDistance) or 15.0
    )
    local missionMinHeight = math.min(terrainClearance, autopilotFlightHeight) + 0.0
    local missionSpeed = math.max(0.1, autopilotTargetSpeed)

    TaskHeliMission(
        autopilotPed,
        autopilotVehicle,
        0,
        0,
        autopilotTarget.x,
        autopilotTarget.y,
        autopilotTarget.z,
        4,
        missionSpeed,
        targetRadius,
        autopilotTargetHeading,
        autopilotFlightHeight,
        missionMinHeight,
        slowDownDistance,
        4481 -- start engine, terrain avoidance/height hold, and attain the requested heading
    )
    SetPedKeepTask(autopilotPed, true)

    autopilotLastTaskAt = GetGameTimer()

    return true
end

stopAutopilot = function(reason, emitAction)
    local vehicle = autopilotVehicle
    local ped = autopilotPed
    local mode = autopilotMode
    local behavior = autopilotBehavior
    local phase = autopilotPhase

    if vehicle ~= 0
        and ped ~= 0
        and DoesEntityExist(vehicle)
        and DoesEntityExist(ped)
        and GetPedInVehicleSeat(vehicle, -1) == ped
    then
        ClearPedTasks(ped)
    end

    autopilotVehicle = 0
    autopilotPed = 0
    autopilotMode = nil
    autopilotBehavior = nil
    autopilotTarget = nil
    autopilotTargetSpeed = 0.0
    autopilotFlightHeight = 0
    autopilotLastSurfaceClearance = 0.0
    autopilotPlaneHoldAltitude = 0.0
    autopilotPlaneNavTarget = nil
    autopilotPlaneOrbitDirection = 0
    autopilotPlaneOrbitRadius = 0.0
    autopilotPlaneOrbitPointAt = 0
    autopilotTargetHeading = -1.0
    autopilotPhase = nil
    autopilotStartedAt = 0
    autopilotInputGraceUntil = 0
    autopilotLastTaskAt = 0
    autopilotStartEngineHealth = 0.0
    autopilotStartBodyHealth = 0.0

    if emitAction ~= false and vehicle ~= 0 and DoesEntityExist(vehicle) then
        emitVehicleAction('autopilot', vehicle, {
            active = false,
            aircraftType = mode,
            mode = behavior,
            phase = phase,
            reason = reason,
            source = 'touchscreen'
        })
    end
end

local function startAutopilot(vehicle, mode, behavior, target, targetSpeed, initialPhase)
    if cruiseVehicle ~= 0 then
        stopCruiseControl('autopilot', true)
    end

    if autopilotVehicle ~= 0 then
        stopAutopilot('replaced', true)
    end

    autopilotVehicle = vehicle
    autopilotPed = getPed()
    autopilotMode = mode
    autopilotBehavior = behavior or 'waypoint'
    autopilotTarget = target
    autopilotTargetSpeed = targetSpeed
    local capturedClearance, clearanceValid = getAutopilotSurfaceClearance(vehicle)
    autopilotFlightHeight = mode == 'helicopter'
        and math.floor(math.max(0.1, capturedClearance) + 0.5)
        or 0
    autopilotLastSurfaceClearance = mode == 'helicopter' and clearanceValid
        and capturedClearance
        or 0.0
    autopilotPlaneHoldAltitude = 0.0
    autopilotPlaneNavTarget = nil
    autopilotPlaneOrbitDirection = 0
    autopilotPlaneOrbitRadius = 0.0
    autopilotPlaneOrbitPointAt = 0

    if mode == 'helicopter' then
        autopilotTargetHeading = autopilotBehavior == 'hover'
            and (tonumber(target.heading) or GetEntityHeading(vehicle))
            or getAutopilotHeadingToTarget(vehicle, target, GetEntityHeading(vehicle))
    else
        autopilotTargetHeading = -1.0
    end
    autopilotPhase = initialPhase or 'enroute'
    autopilotStartedAt = GetGameTimer()
    autopilotInputGraceUntil = autopilotStartedAt + math.max(
        0,
        math.floor(tonumber(getAutopilotConfig().ManualInputGraceMs) or 500)
    )
    autopilotLastTaskAt = 0
    autopilotStartEngineHealth = GetVehicleEngineHealth(vehicle)
    autopilotStartBodyHealth = GetVehicleBodyHealth(vehicle)

    issueAutopilotTask()

    emitVehicleAction('autopilot', vehicle, {
        active = true,
        aircraftType = mode,
        mode = autopilotBehavior,
        phase = autopilotPhase,
        targetAltitude = mode == 'plane' and autopilotPlaneHoldAltitude > 0.0
            and autopilotPlaneHoldAltitude
            or target.z,
        targetClearance = mode == 'helicopter' and autopilotFlightHeight or nil,
        targetMph = math.floor(targetSpeed * MPH_PER_MPS + 0.5),
        source = 'touchscreen'
    })
end

local function disableAutopilotControls()
    for _, configuredControl in ipairs(getAutopilotCancelControls()) do
        local control = tonumber(configuredControl)

        if control then
            DisableControlAction(0, control, true)
        end
    end
end

local function hasAutopilotManualInput()
    if uiOpen or GetGameTimer() < autopilotInputGraceUntil then
        return false
    end

    local config = getAutopilotConfig()
    local threshold = math.min(1.0, math.max(0.0, tonumber(config.ManualInputThreshold) or 0.20))

    for _, configuredControl in ipairs(getAutopilotCancelControls()) do
        local control = tonumber(configuredControl)

        if control then
            local input = math.max(
                math.abs(GetControlNormal(0, control)),
                math.abs(GetDisabledControlNormal(0, control))
            )

            if input > 0.0 and input >= threshold then
                return true
            end
        end
    end

    return false
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
    local wasOpen = uiOpen
    uiOpen = visible

    if wasOpen and not visible and autopilotVehicle ~= 0 then
        local closeGraceMs = math.max(
            0,
            math.floor(tonumber(getAutopilotConfig().UiCloseInputGraceMs) or 250)
        )
        autopilotInputGraceUntil = GetGameTimer() + closeGraceMs
    end

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

local function getCruiseControlState(vehicle)
    local externalOwner = getExternalCruiseOwner()
    local supported = isCruiseControlSupported(vehicle)
    local active = supported and cruiseVehicle == vehicle and cruiseTargetSpeed > 0.0

    return {
        supported = supported,
        active = active,
        targetMph = active and math.floor(cruiseTargetSpeed * MPH_PER_MPS + 0.5) or 0,
        externalOwner = externalOwner
    }
end

local function getAutopilotState(vehicle)
    local aircraftType = getAutopilotAircraftType(vehicle)
    local supported = isAutopilotSupported(vehicle)
    local active = supported
        and autopilotVehicle == vehicle
        and type(autopilotTarget) == 'table'

    return {
        supported = supported,
        aircraftType = aircraftType,
        active = active,
        mode = active and autopilotBehavior or nil,
        phase = active and autopilotPhase or nil,
        targetClearance = active and aircraftType == 'helicopter' and autopilotFlightHeight or nil
    }
end

local function isBoatAnchorSupported(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local override = getVehicleOverride(vehicle)
    local controls = override and override.Controls

    if type(controls) == 'table' and controls.anchor ~= nil then
        return controls.anchor == true
    end

    return IsThisModelABoat(GetEntityModel(vehicle))
end

local function getBoatAnchorState(vehicle)
    local supported = isBoatAnchorSupported(vehicle)

    return {
        supported = supported,
        active = supported and getStoredVehicleState(vehicle).anchor or false
    }
end

local function isLandingGearSupported(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local override = getVehicleOverride(vehicle)
    local controls = override and override.Controls

    if type(controls) == 'table' and controls.landingGear ~= nil then
        return controls.landingGear == true
    end

    return DoesVehicleHaveLandingGear(vehicle)
end

local function getLandingGearState(vehicle)
    local supported = isLandingGearSupported(vehicle)

    if not supported then
        return {
            supported = false,
            active = false,
            moving = false,
            broken = false
        }
    end

    local state = GetLandingGearState(vehicle)

    return {
        supported = true,
        active = state == 0 or state == 3,
        moving = state == 1 or state == 3,
        broken = state == 5
    }
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

    if type(synced.anchor) == 'boolean' and networkStateEnabled('anchor') and isBoatAnchorSupported(vehicle) then
        stored.anchor = synced.anchor
        applyBoatAnchorState(vehicle, stored.anchor)
    end

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

    local interfaceFrame = Config.InterfaceFrame or {}

    return {
        canUse = true,
        locale = getLocaleData(),
        plate = GetVehicleNumberPlateText(vehicle),
        vehicleName = getVehicleName(vehicle),
        vehicleClass = vehicleClass,
        vehicleClassName = getVehicleClassName(vehicleClass),
        interfaceFrame = {
            enabled = interfaceFrame.Enabled ~= false
        },
        fuel = fuel,
        engineHealth = math.floor(GetVehicleEngineHealth(vehicle) / 10 + 0.5),
        engine = engineRunning,
        locked = lockStatus == 2 or lockStatus == 3 or lockStatus == 4,
        radio = stored.radio,
        hazards = stored.hazards,
        interiorLight = stored.interiorLight,
        cruise = getCruiseControlState(vehicle),
        autopilot = getAutopilotState(vehicle),
        anchor = getBoatAnchorState(vehicle),
        landingGear = getLandingGearState(vehicle),
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
        cruise = getCruiseControlState(vehicle),
        autopilot = getAutopilotState(vehicle),
        anchor = getBoatAnchorState(vehicle),
        landingGear = getLandingGearState(vehicle),
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

RegisterNUICallback('toggleCruise', function(_, cb)
    local vehicle = getVehicle()
    local externalOwner = getExternalCruiseOwner()
    local supported = isCruiseControlSupported(vehicle)
    local ok, reason

    if externalOwner then
        ok, reason = denyAction('cruise', 'external_cruise_resource')
    elseif not supported then
        ok, reason = denyAction('cruise', 'unsupported_cruise')
    else
        ok, reason = validateVehicleAction('cruise', vehicle, 'cruise')
    end

    if ok then
        if cruiseVehicle == vehicle and cruiseTargetSpeed > 0.0 then
            stopCruiseControl('manual', true)
        else
            local config = getCruiseConfig()
            local minSpeedMph = math.max(0.0, tonumber(config.MinSpeedMph) or 20.0)
            local maxSpeedMph = math.max(minSpeedMph, tonumber(config.MaxSpeedMph) or 120.0)
            local cruiseSpeed = getCruiseSetSpeed(vehicle)
            local speedMph = cruiseSpeed * MPH_PER_MPS
            local forwardSpeed = GetEntitySpeedVector(vehicle, true).y

            if not GetIsVehicleEngineRunning(vehicle) or forwardSpeed <= 0.0 then
                ok, reason = denyAction('cruise', 'cruise_unavailable')
                notify(L('notifications.cruiseUnavailable', nil, 'Cruise control is only available while driving forward with the engine running.'), 'error')
            elseif speedMph < minSpeedMph or speedMph > maxSpeedMph then
                ok, reason = denyAction('cruise', 'cruise_speed')
                notify(L('notifications.cruiseSpeedRange', {
                    min = ('%.0f'):format(minSpeedMph),
                    max = ('%.0f'):format(maxSpeedMph)
                }, ('Cruise control is available between %.0f and %.0f MPH.'):format(minSpeedMph, maxSpeedMph)), 'error')
            else
                startCruiseControl(vehicle, cruiseSpeed)
            end
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

local function validateAutopilotFlightState(action, vehicle, minimumHeight)
    local surfaceClearance = getAutopilotSurfaceClearance(vehicle)

    if not GetIsVehicleEngineRunning(vehicle)
        or not IsVehicleDriveable(vehicle, false)
        or not IsEntityInAir(vehicle)
        or surfaceClearance < minimumHeight
    then
        notify(L(
            'notifications.autopilotUnavailable',
            nil,
            'Autopilot requires you to be airborne in the pilot seat with the engine running.'
        ), 'error')
        return denyAction(action, 'autopilot_unavailable')
    end

    return true
end

RegisterNUICallback('toggleAutopilot', function(_, cb)
    local vehicle = getVehicle()
    local supported = isAutopilotSupported(vehicle)
    local ok, reason

    if not supported then
        ok, reason = denyAction('autopilot', 'unsupported_autopilot')
    else
        ok, reason = validateVehicleAction('autopilot', vehicle, 'autopilot')
    end

    if ok then
        local waypointActive = autopilotVehicle == vehicle
            and autopilotBehavior == 'waypoint'
            and type(autopilotTarget) == 'table'

        if waypointActive then
            stopAutopilot('manual', true)
        else
            local config = getAutopilotConfig()
            local mode = getAutopilotAircraftType(vehicle)
            local modeConfig = getAutopilotModeConfig(mode)
            local minHeight = math.max(0.0, tonumber(config.MinActivationHeight) or 10.0)
            if mode == 'helicopter' and not isHelicopterWaypointControllerEnabled(modeConfig) then
                notify(L(
                    'notifications.autopilotUnavailable',
                    nil,
                    'Autopilot requires both helicopter flight controllers to be enabled.'
                ), 'error')
                ok, reason = denyAction('autopilot', 'autopilot_controller_disabled')
            else
                ok, reason = validateAutopilotFlightState('autopilot', vehicle, minHeight)
            end

            if ok then
                local target = getAutopilotWaypoint(vehicle)

                if not target then
                    ok, reason = denyAction('autopilot', 'autopilot_no_waypoint')
                    notify(L(
                        'notifications.autopilotNoWaypoint',
                        nil,
                        'Set a map waypoint before starting autopilot.'
                    ), 'error')
                else
                    local minDistanceDefault = mode == 'plane' and 500.0 or 50.0
                    local minDistance = math.max(0.0, tonumber(modeConfig.MinWaypointDistance) or minDistanceDefault)
                    local distance = getHorizontalDistanceToTarget(vehicle, target)

                    if distance < minDistance then
                        ok, reason = denyAction('autopilot', 'autopilot_waypoint_too_close')
                        notify(L(
                            'notifications.autopilotWaypointTooClose',
                            { distance = ('%.0f'):format(minDistance) },
                            ('Choose a waypoint at least %.0f meters away.'):format(minDistance)
                        ), 'error')
                    else
                        local currentSpeed = mode == 'plane'
                            and math.max(0.0, GetEntitySpeedVector(vehicle, true).y)
                            or GetEntitySpeed(vehicle)
                        local targetSpeed, minimumSpeed = getAutopilotTargetSpeed(mode, currentSpeed)

                        if not targetSpeed then
                            ok, reason = denyAction('autopilot', 'autopilot_plane_too_slow')
                            notify(L(
                                'notifications.autopilotPlaneTooSlow',
                                { speed = ('%.0f'):format(minimumSpeed) },
                                ('Reach at least %.0f MPH before starting plane autopilot.'):format(minimumSpeed)
                            ), 'error')
                        else
                            startAutopilot(vehicle, mode, 'waypoint', target, targetSpeed, 'enroute')
                        end
                    end
                end
            end
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleHover', function(_, cb)
    local vehicle = getVehicle()
    local aircraftType = getAutopilotAircraftType(vehicle)
    local supported = aircraftType == 'helicopter' and isAutopilotSupported(vehicle)
    local ok, reason

    if not supported then
        ok, reason = denyAction('hover', 'unsupported_hover')
    else
        ok, reason = validateVehicleAction('hover', vehicle, 'autopilot')
    end

    if ok then
        local hoverActive = autopilotVehicle == vehicle
            and autopilotBehavior == 'hover'
            and type(autopilotTarget) == 'table'

        if hoverActive then
            stopAutopilot('manual', true)
        else
            local modeConfig = getAutopilotModeConfig('helicopter')
            local minHeight = math.max(0.0, tonumber(modeConfig.HoverMinActivationHeight) or 2.0)
            ok, reason = validateAutopilotFlightState('hover', vehicle, minHeight)

            if ok then
                local coords = GetEntityCoords(vehicle)
                local hoverSpeedMph = math.max(0.1, tonumber(modeConfig.HoverSpeedMph) or 2.0)
                local target = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = GetEntityHeading(vehicle)
                }

                startAutopilot(
                    vehicle,
                    'helicopter',
                    'hover',
                    target,
                    hoverSpeedMph / MPH_PER_MPS,
                    'hovering'
                )
            end
        end
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

RegisterNUICallback('toggleAnchor', function(_, cb)
    local vehicle = getVehicle()
    local supported = isBoatAnchorSupported(vehicle)
    local ok, reason

    if not supported then
        ok, reason = denyAction('anchor', 'unsupported_anchor')
    else
        ok, reason = validateVehicleAction('anchor', vehicle, 'anchor')
    end

    if ok then
        local stored = getStoredVehicleState(vehicle)
        local anchored = not stored.anchor
        local anchorConfig = Config.BoatAnchor or {}
        local maxSpeedMph = math.max(0.0, tonumber(anchorConfig.MaxSpeedMph) or 10.0)
        local speedMph = GetEntitySpeed(vehicle) * 2.236936

        if anchored and speedMph >= maxSpeedMph then
            ok, reason = denyAction('anchor', 'anchor_too_fast')
            notify(L('notifications.anchorTooFast', {
                speed = ('%.0f'):format(maxSpeedMph)
            }, ('Slow below %.0f MPH before lowering the anchor.'):format(maxSpeedMph)), 'error')
        elseif anchored and not CanAnchorBoatHere(vehicle) then
            ok, reason = denyAction('anchor', 'unsafe_anchor_position')
            notify(L('notifications.cannotAnchorHere', nil, 'Cannot anchor here.'), 'error')
        else
            stored.anchor = anchored
            applyBoatAnchorState(vehicle, anchored)
            syncVehicleState(vehicle, { anchor = anchored })
            emitVehicleAction('anchor', vehicle, { active = anchored, source = 'touchscreen' })
        end
    end

    sendVehicleStateAfterAction()
    cb({ ok = ok, reason = reason })
end)

RegisterNUICallback('toggleLandingGear', function(_, cb)
    local vehicle = getVehicle()
    local landingGear = getLandingGearState(vehicle)
    local ok, reason

    if not landingGear.supported then
        ok, reason = denyAction('landingGear', 'unsupported_landing_gear')
    elseif landingGear.broken then
        ok, reason = denyAction('landingGear', 'broken_landing_gear')
    else
        ok, reason = validateVehicleAction('landingGear', vehicle, 'landingGear')
    end

    if ok then
        local deploy = not landingGear.active
        ControlLandingGear(vehicle, deploy and 2 or 1)
        emitVehicleAction('landingGear', vehicle, { active = deploy, source = 'touchscreen' })
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
                    if not isAutopilotCancelControl(control) then
                        EnableControlAction(0, control, true)
                        EnableControlAction(2, control, true)
                    end
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
    local monitoredVehicle = 0
    local movementHeld = false
    local nextNotificationAt = 0

    while true do
        local vehicle = getVehicle()
        local anchored = vehicle ~= 0
            and DoesEntityExist(vehicle)
            and isDriver(vehicle)
            and isBoatAnchorSupported(vehicle)
            and getStoredVehicleState(vehicle).anchor == true

        if anchored then
            if monitoredVehicle ~= vehicle then
                monitoredVehicle = vehicle
                movementHeld = false
                nextNotificationAt = 0
            end

            local movementPressed = isBoatAnchorMovementInputPressed()
            local now = GetGameTimer()

            if movementPressed and not movementHeld and now >= nextNotificationAt then
                notify(L(
                    'notifications.anchorMoveBlocked',
                    nil,
                    'Raise the anchor before trying to move the boat.'
                ), 'warning')

                local anchorConfig = Config.BoatAnchor or {}
                local cooldownMs = math.max(
                    0,
                    math.floor(tonumber(anchorConfig.MoveAttemptNotifyCooldownMs) or 1500)
                )

                nextNotificationAt = now + cooldownMs
            end

            movementHeld = movementPressed
            Wait(0)
        else
            monitoredVehicle = 0
            movementHeld = false
            nextNotificationAt = 0
            Wait(200)
        end
    end
end)

CreateThread(function()
    while true do
        if cruiseRuntime.adaptiveProbeDrainCount == 0 then
            Wait(200)
        else
            for handle in pairs(cruiseRuntime.adaptiveProbeDrains) do
                local status = GetShapeTestResult(handle)

                if status == 0 or status == 2 then
                    cruiseRuntime.adaptiveProbeDrains[handle] = nil
                    cruiseRuntime.adaptiveProbeDrainCount = math.max(
                        0,
                        cruiseRuntime.adaptiveProbeDrainCount - 1
                    )
                end
            end

            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        if cruiseVehicle == 0 then
            Wait(250)
        else
            local vehicle = cruiseVehicle
            local ped = getPed()
            local config = getCruiseConfig()
            local cancelReason

            if not DoesEntityExist(vehicle) then
                cancelReason = 'vehicle_missing'
            elseif GetVehiclePedIsIn(ped, false) ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                cancelReason = 'driver_changed'
            elseif not GetIsVehicleEngineRunning(vehicle) or not IsVehicleDriveable(vehicle, false) then
                cancelReason = 'engine_off'
            elseif NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) then
                cancelReason = 'network_control'
            elseif getExternalCruiseOwner() then
                cancelReason = 'external_resource'
            elseif not isCruiseControlSupported(vehicle) or not canUseVehicleControl(vehicle, 'cruise') then
                cancelReason = 'control_unavailable'
            elseif isGameplayControlPressed(72) or isGameplayControlPressed(62) then
                cancelReason = 'brake'
            elseif isGameplayControlPressed(76) then
                cancelReason = 'handbrake'
            else
                local forwardSpeed = GetEntitySpeedVector(vehicle, true).y
                local engineHealth = GetVehicleEngineHealth(vehicle)
                local bodyHealth = GetVehicleBodyHealth(vehicle)
                local currentSpeed = GetEntitySpeed(vehicle)
                local collisionSpeed = cruiseRuntime.getCollisionSpeed(vehicle)
                local now = GetGameTimer()
                local damageThreshold = math.max(0.0, tonumber(config.DamageCancelThreshold) or 75.0)

                if forwardSpeed < -0.1 then
                    cancelReason = 'reverse'
                elseif cruiseRuntime.shouldCancelForCollision(
                    config,
                    vehicle,
                    now,
                    collisionSpeed,
                    engineHealth,
                    bodyHealth
                ) then
                    cancelReason = 'collision'
                elseif damageThreshold > 0.0 and (
                    cruiseLastEngineHealth - engineHealth >= damageThreshold
                    or cruiseLastBodyHealth - bodyHealth >= damageThreshold
                ) then
                    cancelReason = 'damage'
                else
                    local acceleratorPressed = isGameplayControlPressed(71) or isGameplayControlPressed(61)
                    local steering = isGameplayControlPressed(63) or isGameplayControlPressed(64)
                    local effectiveTargetSpeed = cruiseRuntime.updateAdaptiveFollowing(
                        config,
                        vehicle,
                        currentSpeed,
                        now
                    )

                    if cruiseLimiterApplied then
                        SetVehicleMaxSpeed(
                            vehicle,
                            acceleratorPressed
                                and cruiseOriginalMaxSpeed
                                or getCruiseLimiterSpeed(config, effectiveTargetSpeed)
                        )
                    end

                    if acceleratorPressed then
                        cruiseStartedAt = now
                    else
                        applyCruiseCorrection(config, vehicle, currentSpeed, effectiveTargetSpeed, steering)
                        applyBoatCruiseEngineRpm(config, vehicle)
                    end

                    cruiseLastEngineHealth = engineHealth
                    cruiseLastBodyHealth = bodyHealth
                    cruiseRuntime.lastSpeed = collisionSpeed
                end
            end

            if cancelReason then
                stopCruiseControl(cancelReason, true)

                if uiOpen then
                    sendVehicleState()
                end
            end

            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        if autopilotVehicle == 0 then
            Wait(50)
        else
            local vehicle = autopilotVehicle
            local ped = getPed()
            local config = getAutopilotConfig()
            local cancelReason

            if not DoesEntityExist(vehicle) then
                cancelReason = 'vehicle_missing'
            elseif autopilotPed == 0 or not DoesEntityExist(autopilotPed) or autopilotPed ~= ped then
                cancelReason = 'pilot_changed'
            elseif IsEntityDead(ped) then
                cancelReason = 'pilot_dead'
            elseif GetVehiclePedIsIn(ped, false) ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                cancelReason = 'driver_changed'
            elseif not IsEntityInAir(vehicle) then
                cancelReason = 'landed'
            elseif not GetIsVehicleEngineRunning(vehicle) or not IsVehicleDriveable(vehicle, false) then
                cancelReason = 'engine_off'
            elseif NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) then
                cancelReason = 'network_control'
            elseif not isAutopilotSupported(vehicle) or not canUseVehicleControl(vehicle, 'autopilot') then
                cancelReason = 'control_unavailable'
            else
                local engineHealth = GetVehicleEngineHealth(vehicle)
                local bodyHealth = GetVehicleBodyHealth(vehicle)
                local damageThreshold = math.max(0.0, tonumber(config.DamageCancelThreshold) or 75.0)

                if damageThreshold > 0.0 and (
                    autopilotStartEngineHealth - engineHealth >= damageThreshold
                    or autopilotStartBodyHealth - bodyHealth >= damageThreshold
                ) then
                    cancelReason = 'damage'
                end
            end

            if not cancelReason then
                disableAutopilotControls()

                if hasAutopilotManualInput() then
                    cancelReason = 'manual_input'
                else
                    local modeConfig = getAutopilotModeConfig(autopilotMode)
                    local defaultArrivalRadius = autopilotMode == 'plane' and 300.0 or 25.0
                    local arrivalRadius = math.max(5.0, tonumber(modeConfig.ArrivalRadius) or defaultArrivalRadius)
                    local distance = getHorizontalDistanceToTarget(vehicle, autopilotTarget)
                    local phaseChanged = false

                    if autopilotBehavior == 'hover' then
                        local refreshMs = math.max(
                            250,
                            math.floor(tonumber(modeConfig.HoverRefreshMs) or 1000)
                        )

                        if GetGameTimer() - autopilotLastTaskAt >= refreshMs then
                            issueAutopilotTask()
                        end
                    elseif autopilotMode == 'plane' and autopilotPhase == 'enroute' then
                        local speed = GetEntitySpeed(vehicle)
                        local orbitRadius = calculatePlaneOrbitRadius(
                            speed,
                            tonumber(modeConfig.OrbitMinRadius) or 700.0,
                            tonumber(modeConfig.OrbitMaxBankDegrees) or 25.0
                        )
                        local entryRadius = math.max(
                            arrivalRadius,
                            tonumber(modeConfig.OrbitEntryRadius) or 1200.0,
                            orbitRadius + math.max(0.0, tonumber(modeConfig.OrbitEntryMargin) or 400.0),
                            speed * math.max(0.0, tonumber(modeConfig.OrbitEntryLeadSeconds) or 10.0)
                        )

                        if distance <= entryRadius then
                            if preparePlaneOrbit(vehicle, modeConfig, orbitRadius)
                                and issueAutopilotTask()
                            then
                                phaseChanged = true
                            else
                                cancelReason = 'navigation_failed'
                            end
                        end
                    elseif autopilotMode == 'plane' and autopilotPhase == 'orbit' then
                        applyPlaneOrbitAltitudeSafety(vehicle, modeConfig)

                        if type(autopilotPlaneNavTarget) ~= 'table' then
                            cancelReason = 'navigation_failed'
                        else
                            local now = GetGameTimer()
                            local refreshMs = math.max(
                                250,
                                math.floor(tonumber(modeConfig.OrbitTaskRefreshMs) or 3000)
                            )
                            local taskReachedDistance = math.max(
                                25.0,
                                tonumber(modeConfig.OrbitTaskReachedDistance) or 75.0
                            )
                            local advanceDistance = math.max(
                                tonumber(modeConfig.OrbitAdvanceDistance) or 300.0,
                                taskReachedDistance + GetEntitySpeed(vehicle) * (refreshMs / 1000.0 + 1.0)
                            )
                            local pointTimeoutMs = math.max(
                                refreshMs,
                                math.floor(tonumber(modeConfig.OrbitPointTimeoutMs) or 15000)
                            )
                            local navigationDistance = getHorizontalDistanceToTarget(
                                vehicle,
                                autopilotPlaneNavTarget
                            )

                            if navigationDistance <= advanceDistance
                                or now - autopilotPlaneOrbitPointAt >= pointTimeoutMs
                            then
                                if not advancePlaneOrbitTarget(vehicle, modeConfig)
                                    or not issueAutopilotTask()
                                then
                                    cancelReason = 'navigation_failed'
                                end
                            elseif now - autopilotLastTaskAt >= refreshMs
                                and not issueAutopilotTask()
                            then
                                cancelReason = 'navigation_failed'
                            end
                        end
                    elseif autopilotMode == 'helicopter'
                        and autopilotPhase == 'enroute'
                        and distance <= arrivalRadius
                    then
                        autopilotPhase = 'holding'
                        phaseChanged = true
                        issueAutopilotTask()
                    elseif autopilotMode == 'helicopter' and autopilotPhase == 'holding' then
                        local resumeDistance = math.max(arrivalRadius * 2.0, arrivalRadius + 10.0)

                        if distance > resumeDistance then
                            autopilotPhase = 'enroute'
                            phaseChanged = true
                            issueAutopilotTask()
                        else
                            local refreshMs = math.max(500, math.floor(tonumber(modeConfig.HoldRefreshMs) or 2500))

                            if GetGameTimer() - autopilotLastTaskAt >= refreshMs then
                                issueAutopilotTask()
                            end
                        end
                    end

                    if not cancelReason
                        and autopilotMode == 'helicopter'
                        and autopilotBehavior == 'waypoint'
                        and not applyHelicopterWaypointControl(vehicle, modeConfig, distance)
                    then
                        cancelReason = 'navigation_failed'
                    end

                    if phaseChanged and not cancelReason then
                        emitVehicleAction('autopilot', vehicle, {
                            active = true,
                            aircraftType = autopilotMode,
                            mode = autopilotBehavior,
                            phase = autopilotPhase,
                            targetAltitude = autopilotMode == 'plane' and autopilotPlaneHoldAltitude > 0.0
                                and autopilotPlaneHoldAltitude
                                or autopilotTarget.z,
                            targetClearance = autopilotMode == 'helicopter' and autopilotFlightHeight or nil,
                            targetMph = math.floor(autopilotTargetSpeed * MPH_PER_MPS + 0.5),
                            source = 'touchscreen'
                        })

                        if uiOpen then
                            sendVehicleState()
                        end
                    end
                end
            end

            if cancelReason then
                local notifyHoverTakeover = cancelReason == 'manual_input'
                    and autopilotBehavior == 'hover'

                stopAutopilot(cancelReason, true)

                if notifyHoverTakeover then
                    notify(L(
                        'notifications.hoverReleasedByInput',
                        nil,
                        'Hover disengaged because pilot input was detected.'
                    ), 'warning')
                end

                if uiOpen then
                    sendVehicleState()
                end
            end

            Wait(0)
        end
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

    if cruiseVehicle ~= 0 then
        stopCruiseControl('resource_stop', false)
    end

    if autopilotVehicle ~= 0 then
        stopAutopilot('resource_stop', false)
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
