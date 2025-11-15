local playerList = {}
local disconnectedPlayers = {}
QB = {}
RegisterKeyMapping('list', 'Open Player List', 'keyboard', 'PAGEUP')
local showingPlayerIds = false

RegisterCommand("list", function()
    TriggerEvent('np-playerlist:client:manualUpdate')
    Wait(500)
    if playerList then 
        SendNUIMessage({
            type = "OPEN",
            data = {
                activePlayers = playerList,
                disconnectedPlayers = disconnectedPlayers
            }
        })
        
        -- Lock camera and disable game controls
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        showingPlayerIds = true
        
        DisplayRadar(false)
        
        CreateThread(function()
            while showingPlayerIds do

                DisableControlAction(0, 1, true)    
                DisableControlAction(0, 2, true)  
                DisableControlAction(0, 106, true)  
                
                DisableControlAction(0, 24, true)  
                DisableControlAction(0, 25, true)  
                DisableControlAction(0, 30, true)  
                DisableControlAction(0, 31, true)  
                
                EnableControlAction(0, 322, true)   
                EnableControlAction(0, 200, true)   
                
                Wait(0)
            end
        end)
        
        TriggerEvent('showPlayerIds', true)
    end
end)

RegisterNetEvent('showPlayerIds')
AddEventHandler('showPlayerIds', function(show)
    if show then
        CreateThread(function()
            while showingPlayerIds do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                for _, playerId in ipairs(GetActivePlayers()) do
                    local otherPed = GetPlayerPed(playerId)
                    if otherPed ~= playerPed then
                        local otherCoords = GetEntityCoords(otherPed)
                        local distance = #(playerCoords - otherCoords)
                        if distance <= 5.0 then
                            DrawText3D(otherCoords.x, otherCoords.y, otherCoords.z + 1.0, tostring(GetPlayerServerId(playerId)))
                        end
                    end
                end
                Wait(0)
            end
        end)
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local scale = 0.35

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end


RegisterNetEvent('np-playerlist:client:manualUpdate')
AddEventHandler('np-playerlist:client:manualUpdate', function(activePlayers,disPlayers)
    TriggerServerEvent('np-playerlist:server:manualUpdate')
    playerList = activePlayers
    disconnectedPlayers = disPlayers
end)

RegisterNUICallback("getData", function(data,cb)
    if data.variable == "online" then
        cb(playerList)
    else
        cb(disconnectedPlayers)
    end
end)
CreateThread(function()
    while true do
        if playerlistOpen then
            for _, player in pairs(GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 10.0)) do
                local PlayerId = GetPlayerServerId(player)
                local PlayerPed = GetPlayerPed(player)
                local PlayerCoords = GetEntityCoords(PlayerPed)
                if not PlayerOptin[PlayerId].permission then
                    DrawText3D(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z + 1.0, '['..PlayerId..']')
                else
                    DrawText3D(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z + 1.0, '~r~ ADMIN ~w~ ['..PlayerId..']')
                end
            end
        end
        Wait(5)
    end
end)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(true)
    showingPlayerIds = false
    TriggerEvent('showPlayerIds', false)
    
    DisplayRadar(true)
    EnableAllControlActions(0)
    
    if cb then cb("ok") end
end)

