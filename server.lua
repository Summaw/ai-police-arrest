

RegisterServerEvent('spawnPoliceman')
AddEventHandler('spawnPoliceman', function()
    TriggerClientEvent('spawnPoliceman', -1) -- Trigger the event for all players
end)