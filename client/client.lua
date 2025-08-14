local QBCore = nil
if Config.Core == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Core == 'qbox' then
    QBCore = exports['qbx-core']:GetCoreObject()
end

local currentMotel = nil
local doorObjs = {}

CreateThread(function()
    TriggerServerEvent('monaxy:server:getLockStates')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('monaxy:server:getLockStates')
end)

-- Blips
CreateThread(function()
    if not Config.Blip.enable then return end
    for _, exitCfg in pairs(Config.OdaCik) do
        local blip = AddBlipForCoord(exitCfg.Area)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    for _, exitCfg in pairs(Config.OdaCik) do
        RegisterCommand(exitCfg.Command, function()
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            if #(pcoords - exitCfg.Area) <= exitCfg.Radius then
                SetEntityCoords(ped, exitCfg.Spawn.x, exitCfg.Spawn.y, exitCfg.Spawn.z, 0, 0, 0, 0)
                SetEntityHeading(ped, exitCfg.Spawn.w)
            end
        end, false)
    end
end)

RegisterCommand(Config.OdaDegisCommand, function()
    local count = 0
    for _ in pairs(Config.Oda) do count = count + 1 end
    if count > 0 then
        local target = math.random(1, count)
        currentMotel = target
        if QBCore then
            QBCore.Functions.Notify(("Yeni Motel Odan Verildi! Oda No: %d"):format(target), 'success', 5000)
        end
    end
end, false)

RegisterNetEvent('monaxy:client:sendDoorlockState', function(doorTable)
    for i, st in pairs(doorTable) do
        if Config.Oda[i] then
            Config.Oda[i].locked = st.locked
            local obj = doorObjs[i]
            if obj and DoesEntityExist(obj) then
                FreezeEntityPosition(obj, Config.Oda[i].locked)
                if Config.Oda[i].locked and Config.Oda[i].h then
                    SetEntityHeading(obj, Config.Oda[i].h)
                end
            end
        end
    end
end)

RegisterNetEvent('monaxy:client:sendDoorlockState2', function(doorid, lockstate)
    if Config.Oda[doorid] then
        Config.Oda[doorid].locked = lockstate
        local obj = doorObjs[doorid]
        if obj and DoesEntityExist(obj) then
            FreezeEntityPosition(obj, Config.Oda[doorid].locked)
            if Config.Oda[doorid].locked and Config.Oda[doorid].h then
                SetEntityHeading(obj, Config.Oda[doorid].h)
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        local inArea = false
        for _, ex in pairs(Config.OdaCik) do
            if #(pcoords - ex.Area) <= ex.Radius then
                inArea = true
                break
            end
        end

        if inArea then
            for idx, room in pairs(Config.Oda) do

                if Config.DoorHash and (not doorObjs[idx] or not DoesEntityExist(doorObjs[idx])) then
                    local obj = GetClosestObjectOfType(room.door, 1.5, Config.DoorHash, false, false, false)
                    if obj and DoesEntityExist(obj) then
                        doorObjs[idx] = obj
                        FreezeEntityPosition(obj, room.locked)
                        if room.locked and room.h then SetEntityHeading(obj, room.h) end
                    end
                elseif doorObjs[idx] and DoesEntityExist(doorObjs[idx]) then
                    FreezeEntityPosition(doorObjs[idx], room.locked)
                    if room.locked and room.h then SetEntityHeading(doorObjs[idx], room.h) end
                end

                local distDoor = #(pcoords - room.door)
                local distText = #(pcoords - room.doortext)

                if currentMotel == idx and distText <= 30.0 then
                    sleep = 0
                    DrawMarker(2, room.doortext.x, room.doortext.y, room.doortext.z - 0.3, 0.0,0.0,0.0, 0.0,0.0,0.0, 0.2,0.2,0.2, 32,236,54,100, false,false,0,true)
                end

                if distDoor <= 2.0 then
                    local txt
                    if currentMotel == idx then
                        txt = room.locked and "[E] - Kilitli " or "[E] - Açık "
                    else
                        txt = room.locked and "Kilitli" or "Açık"
                    end
                    DrawText3D(room.doortext.x, room.doortext.y, room.doortext.z, txt)

                    if distDoor <= 1.5 and IsControlJustReleased(0, 38) then
                        if not currentMotel then currentMotel = idx end
                        if currentMotel == idx then
                            TriggerServerEvent('monaxy:server:toggleDoorlock', idx, not room.locked)
                            PlayKeyAnim()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Depo & Kıyafet
CreateThread(function()
    while true do
        local sleep = 500
        if currentMotel and Config.Oda[currentMotel] then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local room = Config.Oda[currentMotel]

            local inArea = false
            for _, ex in pairs(Config.OdaCik) do
                if #(pcoords - ex.Area) <= ex.Radius then
                    inArea = true
                    break
                end
            end

            if inArea then
                if #(pcoords - room.stash) <= 1.5 then
                    DrawText3D(room.stash.x, room.stash.y, room.stash.z, "[E] Depo")
                    if IsControlJustReleased(0, 38) then
                        OpenMotelInventory()
                    end
                    sleep = 0
                elseif #(pcoords - room.clothe) <= 1.5 then
                    DrawText3D(room.clothe.x, room.clothe.y, room.clothe.z, "[E] Kıyafet Dolabı")
                    if IsControlJustReleased(0, 38) then
                        OpenMotelWardrobe()
                    end
                    sleep = 0
                end
            end
        end
        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(1, 128, 0, 128, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextCentre(1)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
        local factor = string.len(text) / 300
        DrawRect(_x, _y + 0.0125, 0.02 + factor, 0.035, 0, 0, 0, 100)
    end
end

function PlayKeyAnim()
    RequestAnimDict("anim@heists@keycard@")
    while not HasAnimDictLoaded("anim@heists@keycard@") do Wait(5) end
    TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, false, false, false)
    Wait(400)
    ClearPedTasks(PlayerPedId())
end

function OpenMotelWardrobe()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end

function OpenMotelInventory()
    local stashId
    if QBCore then
        local PlayerData = QBCore.Functions.GetPlayerData()
        stashId = "Motel_" .. PlayerData.citizenid
    else
        stashId = "Motel_" .. tostring(GetPlayerServerId(PlayerId()))
    end

    if Config.Inv == 'ox' then
        TriggerServerEvent("monaxy-motels:registerstash", stashId)
        exports.ox_inventory:openInventory('stash', { id = stashId })
    else
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
            maxWeight = Config.Depo.StashMaxWeight,
            slots     = Config.Depo.StashSlots
        })
        TriggerEvent("inventory:client:SetCurrentStash", stashId)
    end
end


