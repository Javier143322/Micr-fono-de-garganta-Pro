
local ESX = exports["es_extended"]:getSharedObject()

-- Configuración de frecuencias por facción
local FactionFrequencies = {
    -- FACCIÓN POLICIAL
    police = {
        name = "Policía",
        frequencies = {1, 2, 3},
        type = "official"
    },
    sheriff = {
        name = "Sheriff", 
        frequencies = {4, 5},
        type = "official"
    },
    state = {
        name = "Policía Estatal",
        frequencies = {6, 7},
        type = "official"
    },
    
    -- FACCIÓN MÉDICA
    ambulance = {
        name = "EMS",
        frequencies = {10, 11},
        type = "official"
    },
    
    -- MECÁNICOS
    mechanic = {
        name = "Mecánicos",
        frequencies = {20},
        type = "civil"
    },
    
    -- MAFIAS ORGANIZADAS
    mafia = {
        name = "Mafia",
        frequencies = {30, 31, 32},
        type = "mafia"
    },
    cartel = {
        name = "Cartel",
        frequencies = {33, 34, 35},
        type = "mafia" 
    },
    yakuza = {
        name = "Yakuza",
        frequencies = {36, 37},
        type = "mafia"
    },
    
    -- GRUPOS ÉLITE
    swat = {
        name = "SWAT",
        frequencies = {40, 41},
        type = "elite",
        password = "swat123"
    },
    army = {
        name = "Ejército",
        frequencies = {42, 43},
        type = "elite", 
        password = "army123"
    },
    security = {
        name = "Seguridad Élite",
        frequencies = {44},
        type = "elite",
        password = "secure123"
    },
    
    -- BANDAS CALLEJERAS
    ballas = {
        name = "Ballas",
        frequencies = {50},
        type = "gang"
    },
    families = {
        name = "Families", 
        frequencies = {51},
        type = "gang"
    },
    vagos = {
        name = "Vagos",
        frequencies = {52},
        type = "gang"
    },
    lostmc = {
        name = "Lost MC",
        frequencies = {53},
        type = "gang"
    },
    
    -- GRUPOS SANGUINARIOS
    bloods = {
        name = "Bloods",
        frequencies = {60},
        type = "blood",
        password = "blood123"
    },
    crips = {
        name = "Crips",
        frequencies = {61},
        type = "blood", 
        password = "crip123"
    },
    maras = {
        name = "Maras",
        frequencies = {62},
        type = "blood",
        password = "mara123"
    }
}

-- Tablas de la base de datos
MySQL.ready(function()
    -- Tabla principal de usuarios
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
    
    -- Tabla de frecuencias personalizadas
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

-- Obtener frecuencias disponibles para el jugador
ESX.RegisterServerCallback('throatmic:getAvailableFrequencies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerJob = xPlayer.job.name
    local availableFreqs = {}
    
    -- Añadir frecuencias públicas
    availableFreqs.public = {
        name = "Frecuencias Públicas",
        frequencies = {1, 2, 3, 4, 5, 6, 7, 10, 11, 20},
        type = "public"
    }
    
    -- Añadir frecuencias según la facción del jugador
    for faction, data in pairs(FactionFrequencies) do
        if faction == playerJob then
            availableFreqs.faction = {
                name = data.name,
                frequencies = data.frequencies,
                type = data.type,
                password = data.password
            }
            break
        end
    end
    
    -- Obtener frecuencias personalizadas del jugador
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

-- Crear frecuencia personalizada
ESX.RegisterServerCallback('throatmic:createCustomFrequency', function(source, cb, frequency, password, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Verificar si la frecuencia está disponible
    if frequency < 100 or frequency > 999 then
        cb({success = false, message = "La frecuencia debe estar entre 100 y 999"})
        return
    end
    
    -- Verificar si ya existe
    MySQL.Async.fetchAll('SELECT * FROM custom_frequencies WHERE frequency = @freq', {
        ['@freq'] = frequency
    }, function(result)
        if result and #result > 0 then
            cb({success = false, message = "Esta frecuencia ya está en uso"})
        else
            -- Crear frecuencia personalizada
            MySQL.Async.execute(
                'INSERT INTO custom_frequencies (owner_identifier, frequency, password, faction_name) VALUES (@owner, @freq, @pass, @name)',
                {
                    ['@owner'] = xPlayer.identifier,
                    ['@freq'] = frequency,
                    ['@pass'] = password,
                    ['@name'] = name
                },
                function(rowsChanged)
                    cb({success = true, message = "Frecuencia " .. frequency .. " creada exitosamente"})
                end
            )
        end
    end)
end)

-- Unirse a frecuencia con contraseña
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

-- Sistema de datos del jugador
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

ESX.RegisterServerCallback('throatmic:getPlayerFaction', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.job.name)
end)

ESX.RegisterUsableItem('throatmic', function(source)
    TriggerClientEvent('throatmic:useItem', source)
end)