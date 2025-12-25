ESX = exports["es_extended"]:getSharedObject()

local inVehicle = false
local hudScale = Config.DefaultScale
local speedLimiter = false
local limiterSpeed = 50
local cruiseControl = false
local cruiseSpeed = 50
local lastEngineFailSound = 0
local lastLimiterToggle = 0
local lastCruiseToggle = 0

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            SetVehicleDamageModifier(vehicle, Config.VehicleDamageMultiplier)
        end
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            if not inVehicle then
                inVehicle = true
                SendNUIMessage({action = "show"})
            end
            
            local speed = GetEntitySpeed(vehicle)
            local speedConverted = Config.SpeedUnit == "MPH" and (speed * 2.236936) or (speed * 3.6)
            
            SendNUIMessage({
                action = "update",
                speed = math.floor(speedConverted),
                unit = Config.SpeedUnit,
                fuel = math.floor(GetVehicleFuelLevel(vehicle)),

                vehicleHash = GetEntityModel(vehicle),
                gear = GetVehicleCurrentGear(vehicle),
                engine = math.floor((GetVehicleEngineHealth(vehicle) - 100) / 9),
                limiter = speedLimiter,
                limiterSpeed = limiterSpeed,
                cruise = cruiseControl,
                cruiseSpeed = cruiseSpeed
            })
            
            if speedLimiter and speedConverted > limiterSpeed then
                SetVehicleMaxSpeed(vehicle, limiterSpeed / (Config.SpeedUnit == "MPH" and 2.236936 or 3.6))
            end
            
            if cruiseControl and IsVehicleOnAllWheels(vehicle) then
                local targetSpeed = cruiseSpeed / (Config.SpeedUnit == "MPH" and 2.236936 or 3.6)
                if speedConverted < cruiseSpeed - 2 then
                    SetVehicleForwardSpeed(vehicle, targetSpeed)
                end
            end
            
            local engineHealth = GetVehicleEngineHealth(vehicle)
            if engineHealth < 300 then
                SetVehicleEngineOn(vehicle, false, true, true)
                local currentTime = GetGameTimer()
                if currentTime - lastEngineFailSound > 3000 then
                    PlaySoundFromEntity(-1, "ENGINE_FAIL", vehicle, "DLC_PILOT_ENGINE_FAILURE_SOUNDS", 0, 0)
                    lastEngineFailSound = currentTime
                end
            end
            
            if cruiseControl and not IsVehicleOnAllWheels(vehicle) then
                cruiseControl = false
            end
            

            
            Wait(100)
        else
            if inVehicle then
                inVehicle = false
                SendNUIMessage({action = "hide"})
            end
            Wait(1000)
        end
    end
end)

RegisterCommand(Config.SettingsCommand, function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showSettings",
        scale = hudScale
    })
end, false)

RegisterNUICallback("saveScale", function(data)
    hudScale = data.scale
end)

RegisterNUICallback("closeSettings", function()
    SetNuiFocus(false, false)
end)

RegisterKeyMapping('togglelimiter', 'Toggle Speed Limiter', 'keyboard', 'Y')
RegisterCommand('togglelimiter', function()
    if inVehicle then
        lastLimiterToggle = GetGameTimer()
        local speed = GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false))
        local currentSpeed = math.floor(Config.SpeedUnit == "MPH" and (speed * 2.236936) or (speed * 3.6))
        
        if not speedLimiter then
            speedLimiter = true
            limiterSpeed = currentSpeed > 10 and currentSpeed or 50
        else
            speedLimiter = false
            SetVehicleMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), 999.0)
        end
    end
end, false)

RegisterKeyMapping('togglecruise', 'Toggle Cruise Control', 'keyboard', 'M')
RegisterCommand('togglecruise', function()
    if inVehicle then
        lastCruiseToggle = GetGameTimer()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local speed = GetEntitySpeed(vehicle)
        local currentSpeed = math.floor(Config.SpeedUnit == "MPH" and (speed * 2.236936) or (speed * 3.6))
        
        local velocity = GetEntityVelocity(vehicle)
        local forward = GetEntityForwardVector(vehicle)
        local dot = velocity.x * forward.x + velocity.y * forward.y + velocity.z * forward.z
        
        if not cruiseControl then
            if dot < 0 then
                -- Cannot activate when moving backwards
            elseif currentSpeed > 20 then
                cruiseControl = true
                cruiseSpeed = currentSpeed
            else
                -- Too slow
            end
        else
            cruiseControl = false
        end
    end
end, false)