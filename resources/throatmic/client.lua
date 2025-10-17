
local ESX = exports["es_extended"]:getSharedObject()

-- Variables locales
local throatMicEquipped = false
local currentFrequency = 1
local batteryLevel = 100
local micMuted = false
local radioHUD = false
local lastPTTTime = 0
local pttCooldown = 100
local batteryConsumption = nil
local availableFrequencies = {}

-- Configuración SUPER SIMPLE
local Config = {
    PTTKey = 21, -- SHIFT IZQUIERDO (botón fácil para hablar)
    ToggleKey = 288, -- F1 para activar/desactivar
}

-- Función para actualizar HUD
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

-- Función para consumir batería
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

-- Sincronizar con pma-voice
function setVoiceChannel(channel)
    if channel ~= nil then
        exports['pma-voice']:setRadioChannel(channel)
    else
        exports['pma-voice']:setRadioChannel(0)
    end
end

-- Sonido de click de radio
function playRadioClick()
    PlaySoundFrontend(-1, "CLICK_BACK", "TOGGLE_INPUT_SOUNDSET", true)
end

-- Estado principal del Throat Mic
function setThroatMicState(state)
    throatMicEquipped = state
    
    if state then
        radioHUD = true
        setVoiceChannel(currentFrequency)
        
        -- Cargar y mostrar frecuencias automáticamente
        ESX.TriggerServerCallback('throatmic:getAvailableFrequencies', function(freqs)
            availableFrequencies = freqs
            SendNUIMessage({
                action = 'showFrequencyMenu',
                frequencies = freqs,
                currentFrequency = currentFrequency
            })
        end)
        
        -- Iniciar consumo de batería
        if batteryConsumption then
            ClearInterval(batteryConsumption)
        end
        batteryConsumption = SetInterval(consumeBattery, 60000)
        
        ESX.ShowNotification("🎤 ~g~Throat Mic ACTIVADO~s~\nMantén ~y~SHIFT~s~ para hablar")
        
    else
        radioHUD = false
        setVoiceChannel(nil)
        SendNUIMessage({action = 'hideFrequencyMenu'})
        
        -- Detener consumo de batería
        if batteryConsumption then
            ClearInterval(batteryConsumption)
            batteryConsumption = nil
        end
        
        ESX.ShowNotification("🎤 ~r~Throat Mic DESACTIVADO")
    end
    updateRadioHUD()
end

-- Cargar datos del jugador
RegisterNetEvent('throatmic:loadData')
AddEventHandler('throatmic:loadData', function(data)
    batteryLevel = data.battery
    currentFrequency = data.current_frequency
    micMuted = data.mic_muted
end)

-- Usar item del Throat Mic (SUPER SIMPLE)
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

-- Comando de activación SIMPLE
RegisterCommand('throatmic', function()
    TriggerEvent('throatmic:useItem')
end, false)

RegisterKeyMapping('throatmic', 'Activar/Desactivar Throat Mic', 'keyboard', 'F1')

-- Sistema PTT SIMPLIFICADO - UN SOLO BOTÓN PARA HABLAR
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if throatMicEquipped and not micMuted then
            if IsControlPressed(0, Config.PTTKey) then -- SHIFT presionado
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
        end
    end
end)

-- Eventos NUI para manejar frecuencias
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

-- Cerrar menú al moverse o disparar
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if throatMicEquipped then
            if IsPedRunning(PlayerPedId()) or IsPedShooting(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(), false) then
                SendNUIMessage({action = 'hideFrequencyMenu'})
            end
        end
    end
end)

-- Cargar datos al iniciar
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    Citizen.Wait(5000)
    TriggerServerEvent('throatmic:loadPlayerData')
end)

-- Limpiar al desconectar
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if throatMicEquipped then
            setThroatMicState(false)
        end
    end
end)

-- Función SetInterval para consumo de batería
function SetInterval(callback, interval)
    local timer = true
    Citizen.CreateThread(function()
        while timer do
            Citizen.Wait(interval)
            if timer then callback() end
        end
    end)
    return function() timer = false end
end

function ClearInterval(intervalFn)
    if intervalFn then intervalFn() end
end