local ESX = exports["es_extended"]:getSharedObject()

-- ==================== SISTEMA THROAT MIC ====================
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

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_throat_mics` (
            `identifier` varchar(50) NOT NULL,
            `battery` int(11) NOT NULL DEFAULT 100,
            `current_frequency` int(11) NOT NULL DEFAULT 1,
            `ptt_type` varchar(20) NOT NULL DEFAULT 'large',
            `mic_muted` tinyint(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]], {})
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `custom_frequencies` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner_identifier` varchar(50) NOT NULL,
            `frequency` INT NOT NULL,
            `password` VARCHAR(50) DEFAULT NULL,
            `faction_name` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]], {})
end)

-- Throat Mic: Cargar datos jugador
RegisterNetEvent('throatmic:loadPlayerData')
AddEventHandler('throatmic:loadPlayerData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        local identifier = xPlayer.identifier
        MySQL.Async.fetchAll('SELECT * FROM player_throat_mics WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result[1] then
                TriggerClientEvent('throatmic:loadData', src, result[1])
            else
                MySQL.Async.execute('INSERT INTO player_throat_mics (identifier) VALUES (@identifier)', {
                    ['@identifier'] = identifier
                })
                TriggerClientEvent('throatmic:loadData', src, {
                    battery = 100,
                    current_frequency = 1,
                    ptt_type = 'large',
                    mic_muted = false
                })
            end
        end)
    end
end)

-- Throat Mic: Actualizar datos
RegisterNetEvent('throatmic:updatePlayerData')
AddEventHandler('throatmic:updatePlayerData', function(battery, frequency, pttType, muted)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        MySQL.Async.execute(
            'UPDATE player_throat_mics SET battery = @battery, current_frequency = @frequency, ptt_type = @pttType, mic_muted = @muted WHERE identifier = @identifier',
            {
                ['@identifier'] = xPlayer.identifier,
                ['@battery'] = battery,
                ['@frequency'] = frequency,
                ['@pttType'] = pttType,
                ['@muted'] = muted
            }
        )
    end
end)

-- Throat Mic: Callbacks
ESX.RegisterServerCallback('throatmic:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM player_throat_mics WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                cb(result[1])
            else
                cb({
                    battery = 100,
                    current_frequency = 1,
                    ptt_type = 'large',
                    mic_muted = false
                })
            end
        end)
    else
        cb(nil)
    end
end)

ESX.RegisterServerCallback('throatmic:getAvailableFrequencies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerJob = xPlayer.job.name
    local availableFreqs = {}
    
    availableFreqs.public = {
        name = "Frecuencias Públicas",
        frequencies = {1, 2, 3, 4, 5, 6, 7, 10, 11, 20},
        type = "public"
    }
    
    for faction, freqs in pairs(FactionFrequencies) do
        if faction == playerJob then
            availableFreqs.faction = {
                name = "Frecuencia de Facción",
                frequencies = freqs,
                type = "faction"
            }
            break
        end
    end
    
    MySQL.Async.fetchAll('SELECT * FROM custom_frequencies WHERE owner_identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result and #result > 0 then
            availableFreqs.custom = {
                name = "Frecuencias Personales",
                frequencies = {},
                type = "custom"
            }
            for _, freq in ipairs(result) do
                table.insert(availableFreqs.custom.frequencies, {
                    number = freq.frequency,
                    password = freq.password,
                    name = freq.faction_name
                })
            end
        end
        cb(availableFreqs)
    end)
end)

ESX.RegisterServerCallback('throatmic:joinFrequencyWithPassword', function(source, cb, frequency, password)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.Async.fetchAll('SELECT * FROM custom_frequencies WHERE frequency = @freq', {
        ['@freq'] = frequency
    }, function(result)
        if result and #result > 0 then
            local freqData = result[1]
            if freqData.password == nil or freqData.password == password then
                cb({success = true, message = "Conectado a frecuencia " .. frequency})
            else
                cb({success = false, message = "Contraseña incorrecta"})
            end
        else
            cb({success = false, message = "Frecuencia no encontrada"})
        end
    end)
end)

ESX.RegisterServerCallback('throatmic:getPlayerFaction', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.job.name)
end)

ESX.RegisterUsableItem('throatmic', function(source)
    TriggerClientEvent('throatmic:useItem', source)
end)

-- ==================== SISTEMA CORPORATE ÉLITE ====================
local CorporateFactions = {
    police = {
        name = "DEPARTAMENTO DE POLICÍA",
        type = "legal",
        services = {
            {id = 1, name = "VIGILANCIA AVANZADA", price = 5000, legal = true},
            {id = 2, name = "INTERVENCION COMUNICACIONES", price = 10000, legal = true},
            {id = 3, name = "RASTREO VEHICULAR", price = 7500, legal = true}
        }
    },
    ambulance = {
        name = "SERVICIOS MÉDICOS DE EMERGENCIA", 
        type = "legal",
        services = {
            {id = 1, name = "RESPUESTA RÁPIDA ÉLITE", price = 3000, legal = true},
            {id = 2, name = "TRANSPORTE MÉDICO ESPECIAL", price = 5000, legal = true}
        }
    },
    mafia = {
        name = "ORGANIZACIÓN MAFIOSA",
        type = "illegal", 
        services = {
            {id = 1, name = "ELIMINACIÓN DE EVIDENCIAS", price = 25000, legal = false},
            {id = 2, name = "TRANSPORTE CLANDESTINO", price = 15000, legal = false},
            {id = 3, name = "PROTECCIÓN ARMADA", price = 30000, legal = false}
        }
    },
    cartel = {
        name = "CARTEL DE LA DROGA",
        type = "illegal",
        services = {
            {id = 1, name = "DISTRIBUCIÓN SEGURA", price = 35000, legal = false},
            {id = 2, name = "LABORATORIO MÓVIL", price = 50000, legal = false}
        }
    },
    ballas = {
        name = "BANDA ORGANIZADA BALLAS",
        type = "illegal",
        services = {
            {id = 1, name = "CONTROL TERRITORIAL", price = 15000, legal = false},
            {id = 2, name = "PROTECCIÓN EXTORSIVA", price = 12000, legal = false}
        }
    },
    families = {
        name = "FAMILIAS ORGANIZADAS",
        type = "illegal",
        services = {
            {id = 1, name = "RED DE INFORMANTES", price = 18000, legal = false},
            {id = 2, name = "SISTEMA DE EVASIÓN", price = 22000, legal = false}
        }
    }
}

local eliteTransactions = {}

ESX.RegisterServerCallback('corporate:checkAccess', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerJob = xPlayer.job.name
    
    if CorporateFactions[playerJob] then
        cb({
            hasAccess = true,
            factionData = CorporateFactions[playerJob],
            playerMoney = xPlayer.getAccount('money').money,
            playerBank = xPlayer.getAccount('bank').money
        })
    else
        cb({hasAccess = false})
    end
end)

ESX.RegisterServerCallback('corporate:processService', function(source, cb, serviceId, finishingOptions)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerJob = xPlayer.job.name
    
    if not CorporateFactions[playerJob] then
        cb({success = false, message = "Acceso denegado"})
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
    
    local basePrice = service.price
    local finishingCost = 0
    
    if finishingOptions then
        if finishingOptions.urgency then finishingCost = finishingCost + 5000 end
        if finishingOptions.discretion then finishingCost = finishingCost + 8000 end
        if finishingOptions.premium then finishingCost = finishingCost + 12000 end
    end
    
    local totalCost = basePrice + finishingCost
    
    if xPlayer.getAccount('money').money < totalCost then
        cb({success = false, message = "Fondos insuficientes"})
        return
    end
    
    xPlayer.removeAccountMoney('money', totalCost)
    
    local transactionId = #eliteTransactions + 1
    eliteTransactions[transactionId] = {
        id = transactionId,
        player = xPlayer.identifier,
        service = service.name,
        faction = faction.name,
        amount = totalCost,
        timestamp = os.time()
    }
    
    ExecuteService(xPlayer.source, service, finishingOptions)
    
    cb({
        success = true, 
        message = "Servicio ejecutado: " .. service.name,
        amount = totalCost,
        transactionId = transactionId
    })
end)

function ExecuteService(playerSource, service, finishingOptions)
    if service.name == "VIGILANCIA AVANZADA" then
        TriggerClientEvent('corporate:startSurveillance', playerSource)
    elseif service.name == "ELIMINACIÓN DE EVIDENCIAS" then
        TriggerClientEvent('corporate:cleanEvidence', playerSource)
    elseif service.name == "CONTROL TERRITORIAL" then
        TriggerClientEvent('corporate:territoryControl', playerSource)
    end
end

ESX.RegisterServerCallback('corporate:getTransactionHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerTransactions = {}
    
    for _, transaction in pairs(eliteTransactions) do
        if transaction.player == xPlayer.identifier then
            table.insert(playerTransactions, transaction)
        end
    end
    
    cb(playerTransactions)
end)