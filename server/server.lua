local QBCore = nil
if Config.Core == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Core == 'qbox' then
    QBCore = exports['qbx-core']:GetCoreObject()
end

local doorState = {}
for i, v in pairs(Config.Oda) do
    doorState[i] = { locked = v.locked }
end

RegisterNetEvent("monaxy-motels:registerstash", function(motel_label)
    if Config.Inv ~= 'ox' then return end
    local src = source
    local ownerId = tostring(src)
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then ownerId = Player.PlayerData.citizenid end
    end
    exports.ox_inventory:RegisterStash(motel_label, motel_label, Config.Depo.StashSlots, Config.Depo.StashMaxWeight, ownerId)
end)

RegisterNetEvent('monaxy:server:getLockStates', function()
    local src = source
    TriggerClientEvent('monaxy:client:sendDoorlockState', src, doorState)
end)

RegisterNetEvent('monaxy:server:toggleDoorlock', function(doorid, lockstate)
    if type(doorid) ~= 'number' or not doorState[doorid] then return end
    doorState[doorid].locked = lockstate and true or false
    TriggerClientEvent('monaxy:client:sendDoorlockState2', -1, doorid, doorState[doorid].locked)
end)
