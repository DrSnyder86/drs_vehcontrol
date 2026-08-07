local playerRateLimits = {}

local function getSyncConfig()
    return Config.NetworkSync or {}
end

local function stateEnabled(name)
    local config = getSyncConfig()
    local states = config.States or {}

    return config.Enabled ~= false and states[name] ~= false
end

local function resolveVehicle(reference)
    reference = tonumber(reference) or 0

    if reference == 0 then
        return 0
    end

    if DoesEntityExist(reference) and GetEntityType(reference) == 2 then
        return reference
    end

    local vehicle = NetworkGetEntityFromNetworkId(reference)
    if vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2 then
        return vehicle
    end

    return 0
end

local function sanitizeWindows(value)
    if type(value) ~= 'table' then
        return nil
    end

    local windows = {}

    for window = 0, 3 do
        local state = value[window]
        if state == nil then
            state = value[tostring(window)]
        end

        if type(state) == 'boolean' then
            windows[window] = state
        end
    end

    return next(windows) and windows or nil
end

local function sanitizePatch(patch)
    if type(patch) ~= 'table' then
        return nil
    end

    local clean = {}

    for _, name in ipairs({ 'hazards', 'interiorLight', 'radio' }) do
        if stateEnabled(name) and type(patch[name]) == 'boolean' then
            clean[name] = patch[name]
        end
    end

    if stateEnabled('windows') then
        clean.windows = sanitizeWindows(patch.windows)
    end

    return next(clean) and clean or nil
end

local function copySyncedState(value)
    local copy = {
        windows = {}
    }

    if type(value) ~= 'table' then
        return copy
    end

    for _, name in ipairs({ 'hazards', 'interiorLight', 'radio' }) do
        if type(value[name]) == 'boolean' then
            copy[name] = value[name]
        end
    end

    local windows = sanitizeWindows(value.windows)
    if windows then
        copy.windows = windows
    end

    return copy
end

local function setVehicleState(vehicle, patch)
    local config = getSyncConfig()

    if config.Enabled == false or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end

    local clean = sanitizePatch(patch)
    if not clean then
        return false
    end

    local stateName = config.StateBagName or 'drs_vehcontrol'
    local merged = copySyncedState(Entity(vehicle).state[stateName])

    for name, value in pairs(clean) do
        if name == 'windows' then
            for window, windowState in pairs(value) do
                merged.windows[window] = windowState
            end
        else
            merged[name] = value
        end
    end

    Entity(vehicle).state:set(stateName, merged, true)
    return true
end

local function playerNearVehicle(playerId, vehicle)
    local ped = GetPlayerPed(playerId)

    if ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    local maxDistance = tonumber(getSyncConfig().ServerValidationDistance) or 50.0
    return #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) <= maxDistance
end

local function playerCanUpdate(playerId, vehicle, patch)
    local callback = getSyncConfig().CanUpdate

    if type(callback) ~= 'function' then
        return true
    end

    local ok, allowed = pcall(callback, playerId, vehicle, patch)
    return ok and allowed ~= false
end

local function consumeRateLimit(playerId)
    local now = GetGameTimer()
    local expires = playerRateLimits[playerId] or 0

    if expires > now then
        return false
    end

    playerRateLimits[playerId] = now + math.max(0, tonumber(getSyncConfig().ServerRateLimit) or 100)
    return true
end

RegisterNetEvent('drs_vehcontrol:server:setVehicleState', function(netId, patch)
    local playerId = source

    if getSyncConfig().Enabled == false or not consumeRateLimit(playerId) then
        return
    end

    local vehicle = resolveVehicle(netId)
    if vehicle == 0 or not playerNearVehicle(playerId, vehicle) or not playerCanUpdate(playerId, vehicle, patch) then
        return
    end

    setVehicleState(vehicle, patch)
end)

AddEventHandler('playerDropped', function()
    playerRateLimits[source] = nil
end)

exports('SetVehicleState', function(vehicleOrNetId, patch)
    return setVehicleState(resolveVehicle(vehicleOrNetId), patch)
end)

exports('GetVehicleState', function(vehicleOrNetId)
    local vehicle = resolveVehicle(vehicleOrNetId)

    if vehicle == 0 then
        return nil
    end

    return Entity(vehicle).state[getSyncConfig().StateBagName or 'drs_vehcontrol']
end)
