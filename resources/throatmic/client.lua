local ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

-- ==================== SISTEMA THROAT MIC ====================
local throatMicEquipped = false
local currentFrequency = 1
local batteryLevel = 100
local micMuted = false
local radioHUD = false
local lastPTTTime = 0
local pttCooldown = 100
local batteryConsumption = nil
local availableFrequencies = {}

local Config = {
    PTTKey = 0x76, -- V
    ToggleKey = 0x49, -- F
    ActivateCommand = 'throatmic'
}

function updateRadioHUD()
    if throatMicEquipped and radioHUD then
        SendNUIMessage({
            action = 'updateHUD',
            frequency = currentFrequency,
            battery = batteryLevel,
            muted = micMuted,
            transmitting = IsControlPressed(0, Config.PTTKey)
        })
    else
        SendNUIMessage({action = 'hideHUD'})
    end
end

function consumeBattery()
    if throatMicEquipped and batteryLevel > 0 then
        batteryLevel = batteryLevel - 1
        if batteryLevel <= 0 then
            ESX.ShowNotification("~r~Throat Mic: Batería agotada")
            setThroatMicState(false)
        end
        updateRadioHUD()
    end
end

function setVoiceChannel(channel)
    if channel ~= nil then
        exports['pma-voice']:setRadioChannel(channel)
    else
        exports['pma-voice']:setRadioChannel(0)
    end
end

function playRadioClick()
    PlaySoundFrontend(-1, "CLICK_BACK", "TOGGLE_INPUT_SOUNDSET", true)
end

function setThroatMicState(state)
    throatMicEquipped = state
    
    if state then
        radioHUD = true
        setVoiceChannel(currentFrequency)
        
        ESX.TriggerServerCallback('throatmic:getAvailableFrequencies', function(freqs)
            availableFrequencies = freqs
            SendNUIMessage({
                action = 'showFrequencyMenu',
                frequencies = freqs,
                currentFrequency = currentFrequency
            })
        end)
        
        if batteryConsumption then
            ClearInterval(batteryConsumption)
        end
        batteryConsumption = SetInterval(consumeBattery, 60000)
        
        ESX.ShowNotification("🎤 ~g~Throat Mic ACTIVADO~s~\nMantén ~y~V~s~ para hablar")
        
    else
        radioHUD = false
        setVoiceChannel(nil)
        SendNUIMessage({action = 'hideFrequencyMenu'})
        
        if batteryConsumption then
            ClearInterval(batteryConsumption)
            batteryConsumption = nil
        end
        
        ESX.ShowNotification("🎤 ~r~Throat Mic DESACTIVADO")
    end
    updateRadioHUD()
end

RegisterNetEvent('throatmic:loadData')
AddEventHandler('throatmic:loadData', function(data)
    batteryLevel = data.battery
    currentFrequency = data.current_frequency
    micMuted = data.mic_muted
end)

RegisterNetEvent('throatmic:useItem')
AddEventHandler('throatmic:useItem', function()
    if not throatMicEquipped then
        ESX.TriggerServerCallback('throatmic:getPlayerData', function(data)
            if data then
                batteryLevel = data.battery
                currentFrequency = data.current_frequency
                micMuted = data.mic_muted
            end
            setThroatMicState(true)
        end)
    else
        TriggerServerEvent('throatmic:updatePlayerData', batteryLevel, currentFrequency, "large", micMuted)
        setThroatMicState(false)
    end
end)

RegisterCommand('throatmic', function()
    TriggerEvent('throatmic:useItem')
end, false)

RegisterKeyMapping('throatmic', 'Activar/Desactivar Throat Mic', 'keyboard', 'F')

Citizen.CreateThread(function()
    while true do
        if throatMicEquipped and not micMuted then
            Citizen.Wait(0)
            if IsControlPressed(0, Config.PTTKey) then
                if GetGameTimer() - lastPTTTime > pttCooldown then
                    lastPTTTime = GetGameTimer()
                    exports['pma-voice']:setRadioVoice(true)
                    playRadioClick()
                    SendNUIMessage({action = 'transmitting', state = true})
                end
            else
                exports['pma-voice']:setRadioVoice(false)
                SendNUIMessage({action = 'transmitting', state = false})
            end
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNUICallback('selectFrequency', function(data, cb)
    currentFrequency = data.frequency
    setVoiceChannel(currentFrequency)
    ESX.ShowNotification("📡 ~g~Conectado~s~ Frecuencia: ~y~" .. currentFrequency)
    updateRadioHUD()
    SendNUIMessage({action = 'hideFrequencyMenu'})
    cb('ok')
end)

RegisterNUICallback('joinFrequencyWithPassword', function(data, cb)
    ESX.TriggerServerCallback('throatmic:joinFrequencyWithPassword', function(result)
        ESX.ShowNotification(result.message)
        if result.success then
            currentFrequency = data.frequency
            setVoiceChannel(currentFrequency)
            updateRadioHUD()
            SendNUIMessage({action = 'hideFrequencyMenu'})
        end
    end, data.frequency, data.password)
    cb('ok')
end)

RegisterNUICallback('hideMenu', function(data, cb)
    cb('ok')
end)

-- ==================== SISTEMA CORPORATE ÉLITE ====================
local corporateAccess = false
local corporateData = nil

RegisterCommand('corporate', function()
    CheckCorporateAccess()
end, false)

RegisterKeyMapping('corporate', 'Sistema Corporate Élite', 'keyboard', 'G')

function CheckCorporateAccess()
    ESX.TriggerServerCallback('corporate:checkAccess', function(result)
        if result.hasAccess then
            corporateAccess = true
            corporateData = result
            OpenCorporateMenu()
            ESX.ShowNotification("~g~SISTEMA CORPORATE ÉLITE~s~ - Acceso autorizado")
        else
            ESX.ShowNotification("~r~ACCESO DENEGADO~s~\nNo tienes permisos para el sistema corporate")
        end
    end)
end

function OpenCorporateMenu()
    SendNUIMessage({
        action = 'showCorporateMenu',
        factionData = corporateData.factionData,
        playerMoney = corporateData.playerMoney,
        playerBank = corporateData.playerBank
    })
    SetNuiFocus(true, true)
end

function SelectCorporateService(serviceId, finishing)
    ESX.TriggerServerCallback('corporate:processService', function(result)
        if result.success then
            ESX.ShowNotification("~g~SERVICIO EJECUTADO~s~\n" .. result.message .. "\nCosto: ~g~$" .. result.amount)
        else
            ESX.ShowNotification("~r~ERROR~s~\n" .. result.message)
        end
    end, serviceId, finishing)
end

RegisterNUICallback('corporateSelectService', function(data, cb)
    SelectCorporateService(data.serviceId, data.finishingOptions)
    cb('ok')
end)

RegisterNUICallback('corporateClose', function(data, cb)
    SetNuiFocus(false, false)
    corporateAccess = false
    cb('ok')
end)

RegisterNUICallback('corporateGetHistory', function(data, cb)
    ESX.TriggerServerCallback('corporate:getTransactionHistory', function(history)
        cb(history)
    end)
end)

RegisterNUICallback('corporateEmergency', function(data, cb)
    if throatMicEquipped then
        currentFrequency = 911
        setVoiceChannel(currentFrequency)
        ESX.ShowNotification("~y~EMERGENCIA CORPORATE~s~ - Canal de emergencia activado")
    end
    cb('ok')
end)

-- Eventos de servicios Corporate
RegisterNetEvent('corporate:startSurveillance')
AddEventHandler('corporate:startSurveillance', function()
    ESX.ShowNotification("~b~VIGILANCIA ACTIVADA~s~ - Sistema de monitoreo iniciado")
    SetRadarBigmapEnabled(true, false)
    Citizen.Wait(30000)
    SetRadarBigmapEnabled(false, false)
end)

RegisterNetEvent('corporate:cleanEvidence')
AddEventHandler('corporate:cleanEvidence', function()
    ESX.ShowNotification("~g~LIMPIEZA EN PROCESO~s~ - Eliminando rastros...")
    local playerCoords = GetEntityCoords(PlayerPedId())
    AddExplosion(playerCoords.x, playerCoords.y, playerCoords.z, 13, 1.0, true, false, 1.0)
end)

RegisterNetEvent('corporate:territoryControl')
AddEventHandler('corporate:territoryControl', function()
    ESX.ShowNotification("~r~CONTROL TERRITORIAL~s~ - Zona asegurada")
    local playerPed = PlayerPedId()
    SetPlayerHealthRechargeMultiplier(playerPed, 2.0)
    Citizen.Wait(60000)
    SetPlayerHealthRechargeMultiplier(playerPed, 1.0)
end)

-- Cargar datos al iniciar
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    Citizen.Wait(5000)
    TriggerServerEvent('throatmic:loadPlayerData')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if throatMicEquipped then
            setThroatMicState(false)
        end
    end
end)

function SetInterval(callback, interval)
    local running = true
    Citizen.CreateThread(function()
        while running do
            Citizen.Wait(interval)
            if running then callback() end
        end
    end)
    return function() running = false end
end

function ClearInterval(intervalFn)
    if intervalFn then intervalFn() end
end