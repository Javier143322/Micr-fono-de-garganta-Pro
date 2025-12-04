-- ==================== THROAT MIC PRO - SERVER ====================
local ESX = exports["es_extended"]:getSharedObject()

-- ==================== CONFIGURACIÓN ====================
local FactionFrequencies = {
    police = {1, 2, 3},
    ambulance = {4, 5},
    mechanic = {6},
    mafia = {30, 31, 32},
    cartel = {33, 34, 35},
    ballas = {50},
    families = {51},
    vagos = {52},
    lostmc = {53}
}

local CorporateFactions = {
    police = {
        name = "DEPARTAMENTO DE POLICÍA",
        type = "legal",
        minGrade = 1,
        services = {
            {id = 1, name = "VIGILANCIA AVANZADA", price = 5000, legal = true},
            {id = 2, name = "RASTREO VEHICULAR", price = 7500, legal = true}
        }
    },
    ambulance = {
        name = "SERVICIOS MÉDICOS DE EMERGENCIA", 
        type = "legal",
        minGrade = 1,
        services = {
            {id = 1, name = "RESPUESTA RÁPIDA ÉLITE", price = 3000, legal = true},
            {id = 2, name = "TRANSPORTE MÉDICO ESPECIAL", price = 5000, legal = true}
        }
    },
    mafia = {
        name = "ORGANIZACIÓN MAFIOSA",
        type = "illegal",
        minGrade = 3,
        services = {
            {id = 1, name = "ELIMINACIÓN DE EVIDENCIAS", price = 25000, legal = false},
            {id = 2, name = "TRANSPORTE CLANDESTINO", price = 15000, legal = false}
        }
    },
    cartel = {
        name = "CARTEL DE LA DROGA",
        type = "illegal",
        minGrade = 3,
        services = {
            {id = 1, name = "DISTRIBUCIÓN SEGURA", price = 35000, legal = false},
            {id = 2, name = "LABORATORIO MÓVIL", price = 50000, legal = false}
        }
    },
    ballas = {
        name = "BANDA ORGANIZADA BALLAS",
        type = "illegal",
        minGrade = 1,
        services = {
            {id = 1, name = "CONTROL TERRITORIAL", price = 15000, legal = false},
            {id = 2, name = "PROTECCIÓN EXTORSIVA", price = 12000, legal = false}
        }
    },
    families = {
        name = "FAMILIAS ORGANIZADAS",
        type = "illegal",
        minGrade = 1,
        services = {
            {id = 1, name = "RED DE INFORMANTES", price = 18000, legal = false},
            {id = 2, name = "SISTEMA DE EVASIÓN", price = 22000, legal = false}
        }
    }
}

-- ==================== VALIDACIÓN ====================
local Validators = {
    isValidIdentifier = function(id)
        return type(id) == 'string' and #id > 0 and #id < 100
    end,
    
    isValidFrequency = function(freq)
        return type(freq) == 'number' and freq >= 1 and freq <= 1000
    end,
    
    isValidPassword = function(pass)
        return type(pass) == 'string' and #pass > 0 and #pass <= 50
    end,
    
    isValidPrice = function(price)
        return type(price) == 'number' and price >= 0 and price <= 999999
    end,
    
    isValidServiceId = function(id)
        return type(id) == 'number' and id > 0
    end,
    
    isValidBattery = function(battery)
        return type(battery) == 'number' and battery >= 0 and battery <= 100
    end
}

-- ==================== DATABASE INITIALIZATION ====================
MySQL.ready(function()
    -- Tabla Throat Mic
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_throat_mics` (
            `identifier` varchar(50) NOT NULL,
            `battery` int(11) NOT NULL DEFAULT 100,
            `current_frequency` int(11) NOT NULL DEFAULT 1,
            `ptt_type` varchar(20) NOT NULL DEFAULT 'large',
            `mic_muted` tinyint(1) NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`),
            KEY `updated_at` (`updated_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    -- Tabla Frecuencias Personalizadas
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `custom_frequencies` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner_identifier` varchar(50) NOT NULL,
            `frequency` INT NOT NULL,
            `password` VARCHAR(255) DEFAULT NULL,
            `faction_name` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_frequency` (`frequency`),
            KEY `owner_identifier` (`owner_identifier`),
            KEY `created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    -- Tabla Activity Logs
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `corporate_activity_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` varchar(50) NOT NULL,
            `action` VARCHAR(100) NOT NULL,
            `is_legal` TINYINT(1) NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            KEY `identifier` (`identifier`),
            KEY `timestamp` (`timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    -- Tabla Transacciones
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `corporate_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_id` varchar(50) NOT NULL,
            `service_name` VARCHAR(100) NOT NULL,
            `faction_name` VARCHAR(50) NOT NULL,
            `amount` INT NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            KEY `player_id` (`player_id`),
            KEY `timestamp` (`timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    print("^2[Throat Mic] Tablas de base de datos creadas/verificadas^7")
end)

-- ==================== THROAT MIC CALLBACKS ====================
ESX.RegisterServerCallback('throatmic:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(nil)
        return
    end
    
    local identifier = xPlayer.identifier
    if not Validators.isValidIdentifier(identifier) then
        cb(nil)
        return
    end
    
    MySQL.Async.fetchAll(
        'SELECT battery, current_frequency, ptt_type, mic_muted FROM player_throat_mics WHERE identifier = @id LIMIT 1',
        {['@id'] = identifier},
        function(result)
            if result and #result > 0 then
                local data = result[1]
                cb({
                    battery = tonumber(data.battery) or 100,
                    current_frequency = tonumber(data.current_frequency) or 1,
                    ptt_type = tostring(data.ptt_type) or 'large',
                    mic_muted = tonumber(data.mic_muted) or 0
                })
            else
                -- Crear nuevo registro
                MySQL.Async.execute(
                    'INSERT INTO player_throat_mics (identifier) VALUES (@id)',
                    {['@id'] = identifier},
                    function()
                        cb({
                            battery = 100,
                            current_frequency = 1,
                            ptt_type = 'large',
                            mic_muted = 0
                        })
                    end
                )
            end
        end
    )
end)

ESX.RegisterServerCallback('throatmic:getAvailableFrequencies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({})
        return
    end
    
    local playerJob = xPlayer.job.name
    local availableFreqs = {}
    
    -- Frecuencias públicas
    availableFreqs.public = {
        name = "Frecuencias Públicas",
        frequencies = {1, 2, 3, 4, 5, 6, 7, 10, 11, 20},
        type = "public"
    }
    
    -- Frecuencias de facción
    if FactionFrequencies[playerJob] then
        availableFreqs.faction = {
            name = "Frecuencia de Facción",
            frequencies = FactionFrequencies[playerJob],
            type = "faction"
        }
    end
    
    -- Frecuencias personalizadas
    MySQL.Async.fetchAll(
        'SELECT frequency, password, faction_name FROM custom_frequencies WHERE owner_identifier = @id ORDER BY created_at DESC LIMIT 10',
        {['@id'] = xPlayer.identifier},
        function(result)
            if result and #result > 0 then
                availableFreqs.custom = {
                    name = "Frecuencias Personales",
                    frequencies = {},
                    type = "custom"
                }
                for _, freq in ipairs(result) do
                    table.insert(availableFreqs.custom.frequencies, {
                        number = tonumber(freq.frequency),
                        password = freq.password,
                        name = tostring(freq.faction_name)
                    })
                end
            end
            cb(availableFreqs)
        end
    )
end)

ESX.RegisterServerCallback('throatmic:joinFrequencyWithPassword', function(source, cb, frequency, password)
    if not Validators.isValidFrequency(frequency) then
        cb({success = false, message = "Frecuencia inválida"})
        return
    end
    
    if not Validators.isValidPassword(password) then
        cb({success = false, message = "Contraseña inválida"})
        return
    end
    
    MySQL.Async.fetchAll(
        'SELECT password FROM custom_frequencies WHERE frequency = @freq LIMIT 1',
        {['@freq'] = frequency},
        function(result)
            if result and #result > 0 then
                local freqData = result[1]
                if not freqData.password or freqData.password == password then
                    cb({success = true, message = "Conectado a frecuencia " .. frequency})
                else
                    cb({success = false, message = "Contraseña incorrecta"})
                end
            else
                cb({success = false, message = "Frecuencia no encontrada"})
            end
        end
    )
end)

RegisterNetEvent('throatmic:updatePlayerData')
AddEventHandler('throatmic:updatePlayerData', function(battery, frequency, pttType, muted)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    -- Validar datos
    if not Validators.isValidBattery(battery) then battery = math.max(0, math.min(100, battery or 100)) end
    if not Validators.isValidFrequency(frequency) then frequency = 1 end
    if type(pttType) ~= 'string' then pttType = 'large' end
    muted = muted and 1 or 0
    
    MySQL.Async.execute(
        'UPDATE player_throat_mics SET battery = @battery, current_frequency = @freq, ptt_type = @type, mic_muted = @muted WHERE identifier = @id',
        {
            ['@id'] = xPlayer.identifier,
            ['@battery'] = battery,
            ['@freq'] = frequency,
            ['@type'] = pttType,
            ['@muted'] = muted
        }
    )
end)

RegisterNetEvent('throatmic:loadPlayerData')
AddEventHandler('throatmic:loadPlayerData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    TriggerClientEvent('throatmic:useItem', src)
end)

ESX.RegisterUsableItem('throatmic', function(source)
    TriggerClientEvent('throatmic:useItem', source)
end)

-- ==================== CORPORATE SYSTEM ====================
ESX.RegisterServerCallback('corporate:checkAccess', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({hasAccess = false})
        return
    end
    
    local playerJob = xPlayer.job.name
    local playerGrade = xPlayer.job.grade
    
    if not CorporateFactions[playerJob] then
        TriggerEvent('log:activity', {
            action = 'UNAUTHORIZED_CORPORATE_ACCESS',
            identifier = xPlayer.identifier,
            job = playerJob
        })
        cb({hasAccess = false})
        return
    end
    
    local faction = CorporateFactions[playerJob]
    
    if playerGrade < (faction.minGrade or 1) then
        cb({hasAccess = false})
        return
    end
    
    cb({
        hasAccess = true,
        factionData = faction,
        playerMoney = xPlayer.getAccount('money').money,
        playerBank = xPlayer.getAccount('bank').money
    })
end)

ESX.RegisterServerCallback('corporate:processService', function(source, cb, serviceId, finishingOptions)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({success = false, message = "Jugador no encontrado"})
        return
    end
    
    local playerJob = xPlayer.job.name
    local playerGrade = xPlayer.job.grade
    
    if not CorporateFactions[playerJob] then
        cb({success = false, message = "Acceso denegado"})
        TriggerEvent('log:activity', {
            action = 'CORPORATE_ACCESS_DENIED',
            identifier = xPlayer.identifier,
            job = playerJob
        })
        return
    end
    
    if not Validators.isValidServiceId(serviceId) then
        cb({success = false, message = "Servicio inválido"})
        return
    end
    
    local faction = CorporateFactions[playerJob]
    local service = nil
    
    for _, s in ipairs(faction.services) do
        if s.id == serviceId then
            service = s
            break
        end
    end
    
    if not service then
        cb({success = false, message = "Servicio no disponible"})
        return
    end
    
    -- Validar grade para servicios ilegales
    if not service.legal and playerGrade < 3 then
        cb({success = false, message = "Grade insuficiente"})
        TriggerEvent('log:activity', {
            action = 'ILLEGAL_SERVICE_ATTEMPT',
            identifier = xPlayer.identifier,
            service = service.name,
            grade = playerGrade
        })
        return
    end
    
    local basePrice = tonumber(service.price) or 0
    if not Validators.isValidPrice(basePrice) then
        cb({success = false, message = "Precio inválido"})
        return
    end
    
    local finishingCost = 0
    if finishingOptions then
        if finishingOptions.urgency == true then finishingCost = finishingCost + 5000 end
        if finishingOptions.discretion == true then finishingCost = finishingCost + 8000 end
        if finishingOptions.premium == true then finishingCost = finishingCost + 12000 end
    end
    
    local totalCost = basePrice + finishingCost
    
    if xPlayer.getAccount('money').money < totalCost then
        cb({success = false, message = "Fondos insuficientes"})
        return
    end
    
    xPlayer.removeAccountMoney('money', totalCost)
    
    -- Registrar transacción
    MySQL.Async.execute(
        'INSERT INTO corporate_transactions (player_id, service_name, faction_name, amount) VALUES (@player, @service, @faction, @amount)',
        {
            ['@player'] = xPlayer.identifier,
            ['@service'] = service.name,
            ['@faction'] = faction.name,
            ['@amount'] = totalCost
        }
    )
    
    -- Registrar actividad
    MySQL.Async.execute(
        'INSERT INTO corporate_activity_logs (identifier, action, is_legal) VALUES (@id, @action, @legal)',
        {
            ['@id'] = xPlayer.identifier,
            ['@action'] = service.name,
            ['@legal'] = service.legal and 1 or 0
        }
    )
    
    -- Ejecutar servicio
    TriggerClientEvent('corporate:executeService', source, service.name, finishingOptions)
    
    cb({
        success = true,
        message = service.name,
        amount = totalCost
    })
end)

ESX.RegisterServerCallback('corporate:getTransactionHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({})
        return
    end
    
    MySQL.Async.fetchAll(
        'SELECT service_name AS service, faction_name AS faction, amount, UNIX_TIMESTAMP(timestamp) AS timestamp FROM corporate_transactions WHERE player_id = @id ORDER BY timestamp DESC LIMIT 50',
        {['@id'] = xPlayer.identifier},
        function(result)
            if result then
                cb(result)
            else
                cb({})
            end
        end
    )
end)

-- ==================== EVENTOS CORPORATIVOS ====================
RegisterNetEvent('corporate:startSurveillance')
AddEventHandler('corporate:startSurveillance', function()
    TriggerClientEvent('corporate:startSurveillance', source)
end)

RegisterNetEvent('corporate:cleanEvidence')
AddEventHandler('corporate:cleanEvidence', function()
    TriggerClientEvent('corporate:cleanEvidence', source)
end)

RegisterNetEvent('corporate:territoryControl')
AddEventHandler('corporate:territoryControl', function()
    TriggerClientEvent('corporate:territoryControl', source)
end)

-- ==================== LOGGING ====================
local function logActivity(action, identifier, details)
    if not identifier or not action then return end
    
    local log = string.format("[%s] %s - %s", os.date("%Y-%m-%d %H:%M:%S"), action, identifier)
    if details then
        log = log .. " - " .. json.encode(details)
    end
    
    print("^3[Corporate Log]^7 " .. log)
end

TriggerEvent('log:activity', function(data)
    if data and data.action then
        logActivity(data.action, data.identifier or 'UNKNOWN', data)
    end
end)