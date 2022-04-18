QBCore.Commands = {}
QBCore.Commands.List = {}

-- Register & Refresh Commands

function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
    if type(permission) == 'string' then
        permission = permission:lower()
    else
        permission = 'user'
    end
    QBCore.Commands.List[name:lower()] = {
        name = name:lower(),
        permission = permission,
        help = help,
        arguments = arguments,
        argsrequired = argsrequired,
        callback = callback
    }
end

function QBCore.Commands.Refresh(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local suggestions = {}
    if Player then
        for command, info in pairs(QBCore.Commands.List) do
            local isGod = QBCore.Functions.HasPermission(src, 'admin')
            local hasPerm = QBCore.Functions.HasPermission(src, QBCore.Commands.List[command].permission)
            local isPrincipal = IsPlayerAceAllowed(src, 'command')
            if isGod or hasPerm or isPrincipal then
                suggestions[#suggestions + 1] = {
                    name = '/' .. command,
                    help = info.help,
                    params = info.arguments
                }
            end
        end
        TriggerClientEvent('chat:addSuggestions', tonumber(source), suggestions)
    end
end

-- Teleport

QBCore.Commands.Add('tp', 'TP To Player or Coords (Admin Only)', { { name = 'id/x', help = 'ID of player or X position' }, { name = 'y', help = 'Y position' }, { name = 'z', help = 'Z position' } }, false, function(source, args)
    local src = source
    for i, v in ipairs(args) do
        args[i] = v:gsub(",", "")
    end
    if args[1] and not args[2] and not args[3] then
        local target = GetPlayerPed(tonumber(args[1]))
        if target ~= 0 then
            local coords = GetEntityCoords(target)
            TriggerClientEvent('QBCore:Command:TeleportToPlayer', src, coords)
        else
            TriggerClientEvent('hud:client:DrawNotification', src, 'Joueur non trouvé', "error")
        end
    else
        if args[1] and args[2] and args[3] then
            local x = tonumber(args[1])
            local y = tonumber(args[2])
            local z = tonumber(args[3])
            if (x ~= 0) and (y ~= 0) and (z ~= 0) then
                TriggerClientEvent('QBCore:Command:TeleportToCoords', src, x, y, z)
            else
                TriggerClientEvent('hud:client:DrawNotification', src, 'Format non valide', "error")
            end
        else
            TriggerClientEvent('hud:client:DrawNotification', src, 'Format non valide', "error")
        end
    end
end, 'admin')

QBCore.Commands.Add('tpm', 'TP To Marker (Admin Only)', {}, false, function(source)
    local src = source
    TriggerClientEvent('QBCore:Command:GoToMarker', src)
end, 'admin')


QBCore.Commands.Add('togglepvp', 'Toggle PVP on the server (Admin Only)', {}, false, function(source)
    local src = source
    local pvp_state = QBConfig.Server.pvp
    QBConfig.Server.pvp = not pvp_state
    TriggerClientEvent('QBCore:Client:PvpHasToggled', -1, QBConfig.Server.pvp)
end, 'admin')

-- Vehicle

QBCore.Commands.Add('car', 'Spawn Vehicle (Admin Only)', { { name = 'model', help = 'Model name of the vehicle' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('QBCore:Command:SpawnVehicle', src, args[1])
end, 'admin')

QBCore.Commands.Add('var', 'Vehicle variation (Admin Only)', { { name = 'id', help = 'vehicle livery' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('QBCore:Command:VehicleVariation', src, args[1])
end, 'admin')

QBCore.Commands.Add('dv', 'Delete Vehicle (Admin Only)', {}, false, function(source)
    local src = source
    TriggerClientEvent('QBCore:Command:DeleteVehicle', src)
end, 'admin')

-- Money

QBCore.Commands.Add('givemoney', 'Give A Player Money (Admin Only)', { { name = 'id', help = 'Player ID' }, { name = 'moneytype', help = 'Type of money (money, marked_money, bank)' }, { name = 'amount', help = 'Amount of money' } }, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('hud:client:DrawNotification', src, 'Joueur non trouvé', "error")
    end
end, 'admin')

QBCore.Commands.Add('setmoney', 'Set Players Money Amount (Admin Only)', { { name = 'id', help = 'Player ID' }, { name = 'moneytype', help = 'Type of money (money, marked_money, bank)' }, { name = 'amount', help = 'Amount of money' } }, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('hud:client:DrawNotification', src, 'Joueur non trouvé', "error")
    end
end, 'admin')

-- Job

QBCore.Commands.Add('job', 'Check Your Job', {}, false, function(source)
    local src = source
    local PlayerJob = QBCore.Functions.GetPlayer(src).PlayerData.job
    TriggerClientEvent('hud:client:DrawNotification', src, string.format('[Job]: %s [Grade]: %s [On Duty]: %s', PlayerJob.id, PlayerJob.grade, PlayerJob.onduty))
end, 'user')

QBCore.Commands.Add('setjob', 'Set A Players Job (Admin Only)', { { name = 'id', help = 'Player ID' }, { name = 'job', help = 'Job name' }, { name = 'grade', help = 'Grade' } }, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetJob(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('hud:client:DrawNotification', src, 'Joueur non trouvé', "error")
    end
end, 'admin')

-- Gang

QBCore.Commands.Add('gang', 'Check Your Gang', {}, false, function(source)
    local src = source
    local PlayerGang = QBCore.Functions.GetPlayer(source).PlayerData.gang
    TriggerClientEvent('hud:client:DrawNotification', src, string.format('[Gang]: %s [Grade]: %s', PlayerGang.label, PlayerGang.grade.name))
end, 'user')

QBCore.Commands.Add('setgang', 'Set A Players Gang (Admin Only)', { { name = 'id', help = 'Player ID' }, { name = 'gang', help = 'Name of a gang' }, { name = 'grade', help = 'Grade' } }, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetGang(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('hud:client:DrawNotification', src, 'Joueur non trouvé', "error")
    end
end, 'admin')
