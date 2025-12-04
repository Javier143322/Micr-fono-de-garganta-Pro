-- ==================== THROAT MIC PRO - CLIENT ====================
local ESX = nil
local ThroatMicActive = false
local PlayerData = {}
local Config = {
    PTTKey = 0x76, -- V
    ToggleKey = 0x49, -- F
    ActivateCommand = 'throatmic'
}

-- ==================== INICIALIZACIÓN ESX ====================
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Citizen.Wait(100)
    end
    print("^2[Throat Mic] ESX cargado correctamente^7")
end)

-- ==================== VALIDACIÓN ====================
local Validators = {
    isPlayer = function()
        return PlayerPedId() ~= nil
    end,
    
    isValidFrequency = function(freq)
        return type(freq) == 'number' and freq >= 1 and freq <= 1000
    end,
    
    isValidBattery = function(battery)
        return type(battery) == 'number' and battery >= 0 and battery <= 100
    end
}

-- ==================== UTILIDADES ====================
local function ShowNotification(title, message)
    if not ESX or not ESX.ShowNotification then return end
    ESX.ShowNotification(title .. ": " .. tostring(message))
end

local function IsPlayerInVehicle()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

local function PlayRadioClick()
    PlaySoundFrontend(-1, "CLICK_BACK", "TOGGLE_INPUT_SOUNDSET", true)
end

-- ==================== THROAT MIC SYSTEM ====================
local ThroatMic = {
    equipped = false,
    currentFrequency = 1,
    batteryLevel = 100,
    micMuted = false,
    radioHUD = false,
    lastPTTTime = 0,
    pttCooldown = 100,
    batteryThread = nil
}

local function setVoiceChannel(channel)
    if not exports or not exports['pma-voice'] then
        print("^1[ERROR] pma-voice not found^7")
        return
    end
    
    if channel and type(channel) == 'number' then
        exports['pma-voice']:setRadioChannel(channel)
    else
        exports['pma-voice']:setRadioChannel(0)
    end
end

local function updateRadioHUD()
    if ThroatMic.equipped and ThroatMic.radioHUD then
        SendNUIMessage({
            action = 'updateHUD',
            frequency = ThroatMic.currentFrequency,
            battery = ThroatMic.batteryLevel,
            muted = ThroatMic.micMuted,
            transmitting = IsControlPressed(0, Config.PTTKey)
        })
    else
        SendNUIMessage({action = 'hideHUD'})
    end
end

local function consumeBattery()
    if ThroatMic.equipped and ThroatMic.batteryLevel > 0 then
        ThroatMic.batteryLevel = math.max(0, ThroatMic.batteryLevel - 1)
        
        if ThroatMic.batteryLevel <= 0 then
            ShowNotification("Throat Mic", "~r~Batería agotada")
            setThroatMicState(false)
        end
        
        updateRadioHUD()
    end
end

local function setThroatMicState(state)
    if state == ThroatMic.equipped then return end
    
    ThroatMic.equipped = state
    
    if state then
        ThroatMic.radioHUD = true
        setVoiceChannel(ThroatMic.currentFrequency)
        
        -- Obtener frecuencias disponibles
        if ESX and ESX.TriggerServerCallback then
            ESX.TriggerServerCallback('throatmic:getAvailableFrequencies', function(freqs)
                if freqs and type(freqs) == 'table' then
                    SendNUIMessage({
                        action = 'showFrequencyMenu',
                        frequencies = freqs,
                        currentFrequency = ThroatMic.currentFrequency
                    })
                end
            end)
        end
        
        -- Iniciar batería
        if ThroatMic.batteryThread then
            Citizen.CreateThread(function()
                ThroatMic.batteryThread = false
            end)
        end
        
        ThroatMic.batteryThread = true
        Citizen.CreateThread(function()
            while ThroatMic.batteryThread and ThroatMic.equipped do
                Citizen.Wait(60000)
                if ThroatMic.batteryThread then
                    consumeBattery()
                end
            end
        end)
        
        ShowNotification("Throat Mic", "~g~ACTIVADO~s~")
        
    else
        ThroatMic.radioHUD = false
        setVoiceChannel(nil)
        SendNUIMessage({action = 'hideFrequencyMenu'})
        
        if ThroatMic.batteryThread then
            ThroatMic.batteryThread = false
        end
        
        ShowNotification("Throat Mic", "~r~DESACTIVADO")
    end
    
    updateRadioHUD()
end

-- ==================== EVENTOS ====================
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    Citizen.Wait(5000)
    
    if ESX and ESX.TriggerServerCallback then
        ESX.TriggerServerCallback('throatmic:getPlayerData', function(data)
            if data and type(data) == 'table' then
                if Validators.isValidFrequency(data.current_frequency) then
                    ThroatMic.currentFrequency = data.current_frequency
                end
                if Validators.isValidBattery(data.battery) then
                    ThroatMic.batteryLevel = data.battery
                end
                ThroatMic.micMuted = (data.mic_muted == 1)
            end
        end)
    end
end)

RegisterNetEvent('throatmic:useItem')
AddEventHandler('throatmic:useItem', function()
    if not Validators.isPlayer() then return end
    
    if not ThroatMic.equipped then
        if ESX and ESX.TriggerServerCallback then
            ESX.TriggerServerCallback('throatmic:getPlayerData', function(data)
                if data and type(data) == 'table' then
                    if Validators.isValidFrequency(data.current_frequency) then
                        ThroatMic.currentFrequency = data.current_frequency
                    end
                    if Validators.isValidBattery(data.battery) then
                        ThroatMic.batteryLevel = data.battery
                    end
                    ThroatMic.micMuted = (data.mic_muted == 1)
                end
                setThroatMicState(true)
            end)
        end
    else
        TriggerServerEvent('throatmic:updatePlayerData', 
            ThroatMic.batteryLevel, 
            ThroatMic.currentFrequency, 
            'large', 
            ThroatMic.micMuted and 1 or 0)
        setThroatMicState(false)
    end
end)

RegisterCommand(Config.ActivateCommand, function()
    TriggerEvent('throatmic:useItem')
end, false)

RegisterKeyMapping(Config.ActivateCommand, 'Activar/Desactivar Throat Mic', 'keyboard', 'F')

-- ==================== PTT THREAD ====================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if ThroatMic.equipped and not ThroatMic.micMuted then
            if IsControlPressed(0, Config.PTTKey) then
                local currentTime = GetGameTimer()
                if currentTime - ThroatMic.lastPTTTime > ThroatMic.pttCooldown then
                    ThroatMic.lastPTTTime = currentTime
                    
                    if exports and exports['pma-voice'] then
                        exports['pma-voice']:setRadioVoice(true)
                    end
                    
                    PlayRadioClick()
                    SendNUIMessage({action = 'transmitting', state = true})
                end
            else
                if exports and exports['pma-voice'] then
                    exports['pma-voice']:setRadioVoice(false)
                end
                SendNUIMessage({action = 'transmitting', state = false})
            end
        end
    end
end)

-- ==================== NUI CALLBACKS ====================
RegisterNUICallback('selectFrequency', function(data, cb)
    if not data or not data.frequency then
        cb('error')
        return
    end
    
    if not Validators.isValidFrequency(data.frequency) then
        cb('error')
        return
    end
    
    ThroatMic.currentFrequency = data.frequency
    setVoiceChannel(ThroatMic.currentFrequency)
    ShowNotification("Radio", "~g~Conectado~s~ Frecuencia: ~y~" .. ThroatMic.currentFrequency)
    updateRadioHUD()
    SendNUIMessage({action = 'hideFrequencyMenu'})
    cb('ok')
end)

RegisterNUICallback('joinFrequencyWithPassword', function(data, cb)
    if not data or not data.frequency or not data.password then
        cb('error')
        return
    end
    
    if not Validators.isValidFrequency(data.frequency) or 
       type(data.password) ~= 'string' or 
       #data.password > 50 then
        cb('error')
        return
    end
    
    if ESX and ESX.TriggerServerCallback then
        ESX.TriggerServerCallback('throatmic:joinFrequencyWithPassword', function(result)
            if result and result.success then
                ThroatMic.currentFrequency = data.frequency
                setVoiceChannel(ThroatMic.currentFrequency)
                ShowNotification("Radio", "~g~Conectado~s~ Frecuencia: ~y~" .. ThroatMic.currentFrequency)
                updateRadioHUD()
                SendNUIMessage({action = 'hideFrequencyMenu'})
            else
                ShowNotification("Error", (result and result.message) or 'Contraseña incorrecta')
            end
            cb('ok')
        end, data.frequency, data.password)
    end
end)

-- ==================== CORPORATE SYSTEM ====================
local Corporate = {
    access = false,
    data = nil
}

RegisterCommand('corporate', function()
    if not Validators.isPlayer() then return end
    
    if not ESX or not ESX.TriggerServerCallback then
        ShowNotification("Error", "ESX no disponible")
        return
    end
    
    ESX.TriggerServerCallback('corporate:checkAccess', function(result)
        if result and result.hasAccess then
            Corporate.access = true
            Corporate.data = result
            SendNUIMessage({
                action = 'showCorporateMenu',
                factionData = result.factionData,
                playerMoney = result.playerMoney,
                playerBank = result.playerBank
            })
            SetNuiFocus(true, true)
            ShowNotification("Corporate", "~g~ACCESO AUTORIZADO")
        else
            ShowNotification("Corporate", "~r~ACCESO DENEGADO")
        end
    end)
end, false)

RegisterKeyMapping('corporate', 'Sistema Corporate Élite', 'keyboard', 'G')

RegisterNUICallback('corporateSelectService', function(data, cb)
    if not data or not data.serviceId then
        cb('error')
        return
    end
    
    if not ESX or not ESX.TriggerServerCallback then
        cb('error')
        return
    end
    
    ESX.TriggerServerCallback('corporate:processService', function(result)
        if result then
            if result.success then
                ShowNotification("Corporate", "~g~EJECUTADO~s~: " .. (result.message or ''))
            else
                ShowNotification("Corporate", "~r~ERROR~s~: " .. (result.message or 'Unknown error'))
            end
        end
    end, data.serviceId, data.finishingOptions)
    
    cb('ok')
end)

RegisterNUICallback('corporateClose', function(data, cb)
    SetNuiFocus(false, false)
    Corporate.access = false
    cb('ok')
end)

RegisterNUICallback('corporateGetHistory', function(data, cb)
    if not ESX or not ESX.TriggerServerCallback then
        cb({})
        return
    end
    
    ESX.TriggerServerCallback('corporate:getTransactionHistory', function(history)
        if history and type(history) == 'table' then
            cb(history)
        else
            cb({})
        end
    end)
end)

RegisterNUICallback('corporateEmergency', function(data, cb)
    if ThroatMic.equipped then
        ThroatMic.currentFrequency = 911
        setVoiceChannel(ThroatMic.currentFrequency)
        ShowNotification("Emergency", "~y~CANAL DE EMERGENCIA ACTIVADO")
    end
    cb('ok')
end)

-- ==================== EVENTOS CORPORATIVOS ====================
RegisterNetEvent('corporate:startSurveillance')
AddEventHandler('corporate:startSurveillance', function()
    ShowNotification("Corporate", "~b~VIGILANCIA ACTIVADA")
    SetRadarBigmapEnabled(true, false)
    Citizen.Wait(30000)
    SetRadarBigmapEnabled(false, false)
end)

RegisterNetEvent('corporate:cleanEvidence')
AddEventHandler('corporate:cleanEvidence', function()
    ShowNotification("Corporate", "~g~LIMPIEZA EN PROCESO")
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Usar partículas en lugar de explosión
    UseParticleFxAsset("core")
    StartParticleFxLoopedAtCoord("ent_sht_blood_sp_trail", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, true)
end)

RegisterNetEvent('corporate:territoryControl')
AddEventHandler('corporate:territoryControl', function()
    ShowNotification("Corporate", "~r~CONTROL TERRITORIAL ACTIVADO")
    local ped = PlayerPedId()
    
    SetPlayerHealthRechargeMultiplier(ped, 2.0)
    Citizen.Wait(60000)
    SetPlayerHealthRechargeMultiplier(ped, 1.0)
end)

-- ==================== CLEANUP ====================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if ThroatMic.equipped then
            setThroatMicState(false)
        end
        
        if ThroatMic.batteryThread then
            ThroatMic.batteryThread = false
        end
        
        SetNuiFocus(false, false)
        
        if exports and exports['pma-voice'] then
            exports['pma-voice']:setRadioVoice(false)
            exports['pma-voice']:setRadioChannel(0)
        end
    end
end)