QBCore = exports['qb-core']:GetCoreObject()
local IsHostageCuffed = {}

local function normalize(vector)
    local length = math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    return vector3(vector.x / length, vector.y / length, vector.z / length)
end

local playerPed = PlayerPedId()
local playerCoords = GetEntityCoords(playerPed)
local arresting = false

-- Calculate the position behind the player
local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -5.0, 0.0)

-- Spawn the policeman
local policemanModel = GetHashKey("s_m_y_cop_01") -- You can change the model if desired
RequestModel(policemanModel)
while not HasModelLoaded(policemanModel) do
    Citizen.Wait(10)
end

local policemanPed = CreatePed(4, policemanModel, spawnCoords, 0.0, true, true)
SetEntityAsMissionEntity(policemanPed, true, true)

-- Clear tasks and set as non-aggressive
ClearPedTasks(policemanPed)
SetPedAsCop(policemanPed, true)
SetPedCombatAttributes(policemanPed, 46, true) -- Set as non-aggressive

-- Disable AI for the policeman
SetBlockingOfNonTemporaryEvents(policemanPed, true)
SetPedFleeAttributes(policemanPed, 0, 0)
SetPedCombatAttributes(policemanPed, 17, true)
SetPedCombatAttributes(policemanPed, 1, true)
SetPedCombatAbility(policemanPed, 0)
SetPedCombatRange(policemanPed, 0)
SetPedKeepTask(policemanPed, true)

-- Tackle the player
local targetHeading = GetHeadingFromVector_2d(playerCoords.x - spawnCoords.x, playerCoords.y - spawnCoords.y)
SetEntityHeading(policemanPed, targetHeading)

local tackleForce = 50 -- Adjust the force as needed
local tackleSpeed = 50 -- Adjust the speed as needed

local tackleVector = vector3(playerCoords.x - spawnCoords.x, playerCoords.y - spawnCoords.y, playerCoords.z - spawnCoords.z)
tackleVector = normalize(tackleVector) * tackleForce

ApplyForceToEntity(policemanPed, 3, tackleVector.x, tackleVector.y, tackleVector.z, 0.0, 0.0, 0.0, true, true, true, true, true)

-- Arrest the player
Citizen.Wait(2000) -- Wait for the tackle to occur before arresting
playerCoords = GetEntityCoords(playerPed)

-- Spawn the handcuffs model
local handcuffModel = GetHashKey("prop_cs_cuffs_01")
RequestModel(handcuffModel)
while not HasModelLoaded(handcuffModel) do
    Citizen.Wait(10)
end


-- Attach handcuffs to the player
local handcuffObject = CreateObject(handcuffModel, playerCoords, true, false, false)
AttachEntityToEntity(handcuffObject, playerPed, GetPedBoneIndex(playerPed, 60309), 0.12, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

RegisterNetEvent('arrestPlayerr:HandcuffAnimations')
AddEventHandler('arrestPlayerr:HandcuffAnimations', function(cufferPed, playerPed)
    local cuffer = cufferPed
    local heading = GetEntityHeading(cuffer)
    loadAnimDict("mp_arrest_paired")
    loadAnimDict("mp_arresting")

    TaskPlayAnim(playerPed, "mp_arrest_paired", "crook_p2_back_right", 3.0, 3.0, -1, 0, 0, 0, 0, 0)
    Citizen.Wait(100)
    SetEntityCoords(playerPed, GetOffsetFromEntityInWorldCoords(cuffer, 0.0, 0.45, 0.0))
    SetEntityHeading(playerPed, heading)
    Citizen.Wait(100)

    -- Put the player on their knees
    TaskPlayAnim(playerPed, "random@arrests", "kneeling_arrest_idle", 3.0, 3.0, -1, 1, 0, false, false, false)
    Citizen.Wait(500) -- Adjust the wait time as desired

    if not DoesEntityExist(squadCar) then
        -- Request a police vehicle
        local squadCarModel = GetHashKey("polscout2")
        RequestModel(squadCarModel)
        while not HasModelLoaded(squadCarModel) do
            Citizen.Wait(10)
        end

        -- Spawn the police vehicle near the player
        local playerCoords = GetEntityCoords(playerPed)
        squadCar = CreateVehicle(squadCarModel, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(playerPed), true, false)
        SetVehicleOnGroundProperly(squadCar)
        TaskWarpPedIntoVehicle(policemanPed, squadCar, -1)
    end

    -- Call for backup to pick up the player
    SetPedAsGroupMember(policemanPed, GetPedGroupIndex(policemanPed))

    TaskVehicleDriveToCoord(policemanPed, squadCar, playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 1.0, GetEntityModel(squadCar), 16777216, 10.0)

    SetVehicleSiren(squadCar, true)
    -- Wait for the police vehicle to arrive
    while GetDistanceBetweenCoords(playerCoords, GetEntityCoords(policemanPed), true) > 5.0 do
        Citizen.Wait(500)
    end

    -- Put the player in the back seat of the police vehicle
    local doorsLocked = false
    local backSeatIndex = GetVehicleModelNumberOfSeats(GetEntityModel(squadCar)) - 2
    SetPedIntoVehicle(playerPed, squadCar, backSeatIndex)

    -- SetVehicleDoorsLocked(squadCar, 2)

    -- Disable player movement
    FreezeEntityPosition(playerPed, false)

    -- Dismiss the police vehicle after a certain time
    Citizen.Wait(1000) -- Adjust the wait time as desired

    local destination = vector3(434.69, -1021.65, 28.73) -- Replace x, y, z with your desired coordinates

-- Load the default police vehicle driving waypoint recording
    -- LoadDrivingWaypointRecording("police")

    -- Set the police vehicle as the waypoint recording entity
    TaskVehicleDriveToCoordLongrange(policemanPed, squadCar, 434.69, -1021.65, 28.73, 10.0, 1074528293, 1.0)

    SetEntityMaxSpeed(squadCar, 75.0)-- Replace 50.0 with your desired speed

    -- Wait until the police officer reaches the destination or a certain distance is reached
    while GetDistanceBetweenCoords(GetEntityCoords(policemanPed), destination, true) > 10.0 do
        Citizen.Wait(500)
    end

    -- Stop the police vehicle when it reaches the destination
    TaskVehicleFollowWaypointRecording(policemanPed, squadCar, "police", 0, 10, 0)


    SetVehicleDoorsLocked(squadCar, 0)
    doorsLocked = false
    -- DeleteVehicle(squadCar)

    -- Enable player movement after dismissing the police vehicle
    -- FreezeEntityPosition(playerPed, false)
end)


local isPlayerInVehicle = false
local isPlayerTryingToEscape = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local squadCarCoords = GetEntityCoords(squadCar)

        -- Check if the player is inside the police vehicle
        if IsPedInVehicle(playerPed, squadCar, false) then
            isPlayerInVehicle = true
        else
            isPlayerInVehicle = false
        end

        -- Check if the player is trying to escape
        if not isPlayerInVehicle and not isPlayerTryingToEscape then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                isPlayerTryingToEscape = true
                TriggerTaseAction()
            end
        end

        -- Check if the player is outside the vehicle and beyond a certain distance
        local distanceThreshold = 15.0 -- Adjust the distance as desired
        if not isPlayerInVehicle and not isPlayerTryingToEscape and #(playerCoords - squadCarCoords) > distanceThreshold then
            isPlayerTryingToEscape = true
            TriggerTaseAction()
        end
    end
end)

function TriggerTaseAction()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Loop through nearby players
    local nearbyPlayers = GetNearbyPlayers(playerCoords, 20.0) -- Adjust the distance as desired
    for _, playerId in ipairs(nearbyPlayers) do
        local targetPed = GetPlayerPed(playerId)
        -- Tase the player if they are aiming at them
        if IsPlayerAimingAtPlayer(playerId, PlayerId()) then
            -- Play taser animation
            TaskPlayAnim(targetPed, "reaction@shocking_taser", "electric_damage_fall", 3.0, 3.0, -1, 0, 0, 0, 0, 0)

            -- Apply taser effect to the player
            SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
            SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
            Citizen.Wait(500) -- Adjust the duration of the taser effect

            -- Add additional actions such as arresting the player or other consequences
            -- based on your desired game mechanics
        end
    end

    -- Trigger the chase behavior
    TriggerChaseAction()
end

function TriggerChaseAction()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Loop through nearby police officers
    local nearbyOfficers = GetNearbyPolicemen(playerCoords, 100.0) -- Adjust the distance as desired
    for _, officerPed in ipairs(nearbyOfficers) do
        -- Make the officer chase the player
        TaskGoToEntity(playerPed, officerPed, -1, 10.0, 2.0, 1073741824, 0)
        SetPedAsCop(officerPed, true)
        SetPedCombatAttributes(officerPed, 46, true) -- Set as non-aggressive
        SetPedCombatAttributes(officerPed, 17, true)
        SetPedCombatAttributes(officerPed, 1, true)
        SetPedCombatAbility(officerPed, 2)
        SetPedCombatRange(officerPed, 2)
        SetPedKeepTask(officerPed, true)

        -- Set the officer's vehicle's sirens and lights
        local vehicle = GetVehiclePedIsIn(officerPed, true)
        SetVehicleSiren(vehicle, true)
        SetVehicleSirenSound(vehicle, 1)

        -- Set the officer's vehicle's speed
        SetVehicleMaxSpeed(vehicle, 80.0) -- Adjust the speed as desired
        TaskVehicleDriveToCoord(officerPed, vehicle, playerCoords.x, playerCoords.y, playerCoords.z, 80.0, 1.0, GetEntityModel(vehicle), 16777216, 10.0)
    end
end

function IsPlayerAimingAtPlayer(player1, player2)
    local player1Ped = GetPlayerPed(player1)
    local player2Ped = GetPlayerPed(player2)

    -- Get the player's aiming coordinates
    local player1Aim = GetPedBoneCoords(player1Ped, 31086, 0, 0, 0)
    local player2Aim = GetPedBoneCoords(player2Ped, 31086, 0, 0, 0)

    -- Perform a raycast to check if player1 is aiming at player2
    local _, _, _, _, result = GetShapeTestResult(StartShapeTestRay(player1Aim.x, player1Aim.y, player1Aim.z, player2Aim.x, player2Aim.y, player2Aim.z, -1, player1Ped, 0))
    return result == player2Ped
end

function GetNearbyPlayers(position, radius)
    local players = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - position)
        if distance <= radius and playerPed ~= PlayerPedId() and IsPedOnFoot(playerPed) then
            table.insert(players, playerId)
        end
    end
    return players
end






function GetNearbyPolicemen(position, radius)
    local policemen = {}
    local nearbyPlayers = GetPlayersFromCoords(position, radius)
    for _, playerId in ipairs(nearbyPlayers) do
        local playerPed = GetPlayerPed(playerId)
        if IsPedAPlayer(playerPed) and IsPedOnFoot(playerPed) then
            table.insert(policemen, playerPed)
        end
    end
    return policemen
end

function GetPlayersFromCoords(position, radius)
    local players = {}
    local allPlayers = GetPlayers()

    for _, playerId in ipairs(allPlayers) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - position)

        if distance <= radius and playerPed ~= PlayerPedId() then
            table.insert(players, playerId)
        end
    end

    return players
end

function GetPlayers()
    local players = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        table.insert(players, playerId)
    end

    return players
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        playerCoords = GetEntityCoords(playerPed)

        -- Calculate the direction vector towards the player
        local direction = vector3(playerCoords.x - GetEntityCoords(policemanPed).x, playerCoords.y - GetEntityCoords(policemanPed).y, playerCoords.z - GetEntityCoords(policemanPed).z)
        local distance = #(GetEntityCoords(policemanPed) - playerCoords)

        if not arresting then
            -- Adjust the movement speed of the police officer
            local runSpeedMultiplier = 1.6 -- Adjust the speed as desired
            SetPedMoveRateOverride(policemanPed, runSpeedMultiplier)
            SetPedMaxMoveBlendRatio(policemanPed, runSpeedMultiplier)

            -- Set the police officer's heading towards the player
            local targetHeading = GetHeadingFromVector_2d(direction.x, direction.y)
            SetEntityHeading(policemanPed, targetHeading)

            -- Move the police officer towards the player
            local movementSpeed = 5.0 -- Adjust the speed as desired
            SetPedDesiredMoveBlendRatio(policemanPed, movementSpeed)
            TaskGoStraightToCoord(policemanPed, playerCoords.x, playerCoords.y, playerCoords.z, movementSpeed, -1, GetEntityHeading(playerPed), 0.01)

            -- Check if the police officer has caught up to the player
            local tackleDistance = 2.0 -- Adjust the distance as desired
            if distance <= tackleDistance then
                arresting = true -- Set the arresting flag to true to prevent continuous execution of this block

                -- Ragdoll the player
                SetPedToRagdoll(playerPed, 5000, 5000, 0, 0, 0, 0)
                Citizen.Wait(500) -- Adjust the wait time as desired

                -- Play the tackle animation for the police officer
                loadAnimDict("missmic4premiere")
                TaskPlayAnim(policemanPed, "missmic4premiere", "mic_4_premiere_knockout_bouncer", 3.0, 3.0, -1, 0, 0, 0, 0, 0)
                Citizen.Wait(2000) -- Adjust the wait time as desired

                -- Trigger the arrest event
                TriggerEvent('arrestPlayerr:HandcuffAnimations', policemanPed, playerPed)
                QBCore.Functions.Notify("You have been arrested!", "error")
                break -- Exit the loop
            end
        end
    end
end)

function GetEmptySeat(vehicle)
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for i = -1, seats - 2 do
        if IsVehicleSeatFree(vehicle, i) then
            return i
        end
    end
    return -1
end

function loadAnimDict(dict)  
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end
