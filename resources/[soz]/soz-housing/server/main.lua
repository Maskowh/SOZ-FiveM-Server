local QBCore = exports["qb-core"]:GetCoreObject()

--- @type Property[]
Properties = {}

local function IsPropertyValid(house)
    house = decode_json(house)
    if house.identifier == nil then
        exports["soz-monitor"]:Log("DEBUG", ("Entry #%s skipped because it has no identifier"):format(house.id))
        return false
    end
    if house.entry_zone == nil then
        exports["soz-monitor"]:Log("DEBUG", ("Entry %s skipped because it has no entry_zone"):format(house.identifier))
        return false
    end
    return true
end

local function IsApartmentValid(house)
    house = decode_json(house)
    if house.price == nil then
        exports["soz-monitor"]:Log("DEBUG", ("Entry %s skipped because it has no price"):format(house.label))
        return false
    end
    if house.inside_coord == nil then
        exports["soz-monitor"]:Log("DEBUG", ("Entry %s skipped because it has no inside_coord"):format(house.label))
        return false
    end
    if house.exit_zone == nil then
        exports["soz-monitor"]:Log("DEBUG", ("Entry %s skipped because it has no exit_zone"):format(house.label))
        return false
    end
    return true
end

MySQL.ready(function()
    local timeout = 0

    while MySQL.Sync.fetchSingle("SELECT Count(*) AS count FROM migrations WHERE name = 'clean-apartments-zone'").count == 0 do
        timeout = timeout + 1

        if timeout >= 10 then
            error("Migration 'clean-apartments-zone' is missing")
        end

        Citizen.Wait(1000)
    end

    local properties = MySQL.query.await("SELECT * FROM housing_property")
    for _, property in pairs(properties or {}) do
        Properties[property.id] = Property:new(property.identifier, property.entry_zone, property.garage_zone)
    end

    local apartments = MySQL.query.await("SELECT * FROM housing_apartment")
    for _, apartment in pairs(apartments or {}) do
        Properties[apartment.property_id]:AddApartment(apartment.id,
                                                       Apartment:new(apartment.identifier, apartment.label, apartment.owner, apartment.roommate,
                                                                     apartment.price, apartment.inside_coord, apartment.exit_zone, apartment.fridge_zone,
                                                                     apartment.stash_zone, apartment.closet_zone, apartment.money_zone))
    end
end)

--- Functions
QBCore.Functions.CreateCallback("housing:server:GetAllProperties", function(source, cb)
    local properties = {}

    for propertyId, property in pairs(Properties) do
        if IsPropertyValid(property) then
            properties[propertyId] = property

            for apartmentId, apartment in pairs(property.apartments) do
                if not IsApartmentValid(apartment) then
                    properties[propertyId].apartments[apartmentId] = nil
                end
            end
        end
    end

    cb(properties)
end)

QBCore.Functions.CreateCallback("housing:server:GetPlayerProperties", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return
    end

    local properties = {}
    for propertyId, property in pairs(Properties) do
        if property:HasRentedApartmentForCitizenId(Player.PlayerData.citizenid) then
            properties[propertyId] = property
        end
    end

    cb(properties)
end)

RegisterNetEvent("housing:server:SetPlayerInApartment", function(propertyId, apartmentId, target)
    local Player = QBCore.Functions.GetPlayerByCitizenId(target)
    if not Player then
        return
    end

    local inside = Player.PlayerData.metadata["inside"]

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("EnterApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    TriggerClientEvent("housing:client:Teleport", Player.PlayerData.source, apartment:GetInsideCoord())

    inside.apartment = apartmentId
    inside.exitCoord = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
    Player.Functions.SetMetaData("inside", inside)
end)

RegisterNetEvent("housing:server:EnterApartment", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return
    end

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("EnterApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if not apartment:HasAccess(Player.PlayerData.citizenid) then
        exports["soz-monitor"]:Log("ERROR", ("EnterApartment %s - Apartment %s | skipped because player has no access"):format(propertyId, apartmentId))
        return
    end

    TriggerEvent("housing:server:SetPlayerInApartment", propertyId, apartmentId, Player.PlayerData.citizenid)
end)

RegisterNetEvent("housing:server:ExitProperty", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)
    local inside = Player.PlayerData.metadata["inside"]

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("ExitProperty %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    TriggerClientEvent("housing:client:Teleport", Player.PlayerData.source, inside.exitCoord)

    inside.apartment = false
    inside.exitCoord = false
    Player.Functions.SetMetaData("inside", inside)
end)

RegisterNetEvent("housing:server:InspectApartment", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return
    end

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("InspectApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("InspectApartment %s - Apartment %s | skipped because it is not available"):format(propertyId, apartmentId))
        return
    end

    TriggerEvent("housing:server:SetPlayerInApartment", propertyId, apartmentId, Player.PlayerData.citizenid)
end)

RegisterNetEvent("housing:server:BellProperty", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("BellProperty %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("BellProperty %s - Apartment %s | skipped because it is available"):format(propertyId, apartmentId))
        return
    end

    local Owner = QBCore.Functions.GetPlayerByCitizenId(apartment:GetOwner())

    if not Owner then
        return
    end

    TriggerClientEvent("housing:client:PlayerRequestEnter", Owner.PlayerData.source, propertyId, apartmentId, Player.PlayerData.citizenid)
end)

RegisterNetEvent("housing:server:BuyApartment", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("BuyApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("BuyApartment %s - Apartment %s | skipped because it is not available"):format(propertyId, apartmentId))
        return
    end

    if Player.Functions.RemoveMoney("money", apartment:GetPrice()) then
        MySQL.update.await("UPDATE housing_apartment SET owner = ? WHERE id = ?", {
            Player.PlayerData.citizenid,
            apartmentId,
        })
        apartment:SetOwner(Player.PlayerData.citizenid)

        TriggerEvent("monitor:server:event", "house_buy", {player_source = Player.PlayerData.source},
                     {house_id = apartment:GetIdentifier(), amount = apartment:GetPrice()})

        TriggerClientEvent("housing:client:UpdateApartment", -1, propertyId, apartmentId, apartment)
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous venez ~g~d'acquérir~s~ une maison pour ~b~$" .. apartment:GetPrice())
    else
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous n'avez pas assez d'argent", "error")
    end
end)

RegisterNetEvent("housing:server:SellApartment", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("SellApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("SellApartment %s - Apartment %s | skipped because it is available"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsOwner(Player.PlayerData.citizenid) then
        exports["soz-monitor"]:Log("ERROR", ("SellApartment %s - Apartment %s | skipped because player has no access"):format(propertyId, apartmentId))
        return
    end

    if Player.Functions.AddMoney("money", apartment:GetResellPrice()) then
        MySQL.update.await("UPDATE housing_apartment SET owner = NULL WHERE id = ?", {apartmentId})
        apartment:SetOwner(nil)

        TriggerEvent("monitor:server:event", "house_sell", {player_source = Player.PlayerData.source},
                     {house_id = apartment:GetIdentifier(), amount = apartment:GetResellPrice()})

        TriggerClientEvent("housing:client:UpdateApartment", -1, propertyId, apartmentId, apartment)
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source,
                           "Vous venez de ~r~céder~s~ votre maison pour ~b~$" .. apartment:GetResellPrice())
    else
        TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous n'avez pas assez d'argent", "error")
    end
end)

RegisterNetEvent("housing:server:AddRoommateApartment", function(propertyId, apartmentId, targetId)
    local Player = QBCore.Functions.GetPlayer(source)
    local Target = QBCore.Functions.GetPlayer(targetId)

    local dist = #(GetEntityCoords(GetPlayerPed(Player.PlayerData.source)) - GetEntityCoords(GetPlayerPed(Target.PlayerData.source)))

    if Player.PlayerData.source == Target.PlayerData.source then
        return
    end
    if dist > 2.0 then
        return TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Personne n'est à portée de vous", "error")
    end

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("AddRoommateApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("AddRoommateApartment %s - Apartment %s | skipped because it is available"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsOwner(Player.PlayerData.citizenid) then
        exports["soz-monitor"]:Log("ERROR", ("AddRoommateApartment %s - Apartment %s | skipped because player has no access"):format(propertyId, apartmentId))
        return
    end

    if apartment:GetRoomMate() then
        exports["soz-monitor"]:Log("ERROR",
                                   ("AddRoommateApartment %s - Apartment %s | skipped because it already has a roommate"):format(propertyId, apartmentId))
        return
    end

    MySQL.update.await("UPDATE housing_apartment SET roommate = ? WHERE id = ?", {
        Target.PlayerData.citizenid,
        apartmentId,
    })
    apartment:SetRoommate(Target.PlayerData.citizenid)

    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous avez ajouté un partenaire à votre maison")
    TriggerClientEvent("hud:client:DrawNotification", Target.PlayerData.source, "Vous avez été ajouté à votre maison")

    TriggerClientEvent("housing:client:UpdateApartment", -1, propertyId, apartmentId, apartment)
end)

RegisterNetEvent("housing:server:RemoveRoommateApartment", function(propertyId, apartmentId)
    local Player = QBCore.Functions.GetPlayer(source)

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("RemoveRoommateApartment %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("RemoveRoommateApartment %s - Apartment %s | skipped because it is available"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsOwner(Player.PlayerData.citizenid) then
        exports["soz-monitor"]:Log("ERROR", ("RemoveRoommateApartment %s - Apartment %s | skipped because player has no access"):format(propertyId, apartmentId))
        return
    end

    if not apartment:GetRoomMate() then
        exports["soz-monitor"]:Log("ERROR", ("RemoveRoommateApartment %s - Apartment %s | skipped because it has no roommate"):format(propertyId, apartmentId))
        return
    end

    local Target = QBCore.Functions.GetPlayerByCitizenId(apartment:GetRoomMate())

    MySQL.update.await("UPDATE housing_apartment SET roommate = NULL WHERE id = ?", {apartmentId})
    apartment:SetRoommate(nil)

    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous avez supprimé un partenaire de votre maison")
    if Target then
        TriggerClientEvent("hud:client:DrawNotification", Target.PlayerData.source, "Vous avez été supprimé de votre maison")
    end

    TriggerClientEvent("housing:client:UpdateApartment", -1, propertyId, apartmentId, apartment)
end)

QBCore.Functions.CreateCallback("housing:server:GetPlayerAccess", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local access = {}

    for propertyId, property in pairs(Properties) do
        for apartmentId, apartment in pairs(property:GetRentedApartmentsForCitizenId(Player.PlayerData.citizenid)) do
            if access[propertyId] == nil then
                access[propertyId] = {}
            end
            access[propertyId][apartmentId] = apartment
        end
    end

    cb(access)
end)

RegisterNetEvent("housing:server:GiveTemporaryAccess", function(propertyId, apartmentId, target)
    local Player = QBCore.Functions.GetPlayer(source)
    local Target = QBCore.Functions.GetPlayer(target)

    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("GiveTemporaryAccess %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    if apartment:IsAvailable() then
        exports["soz-monitor"]:Log("ERROR", ("GiveTemporaryAccess %s - Apartment %s | skipped because it is available"):format(propertyId, apartmentId))
        return
    end

    if not apartment:IsOwner(Player.PlayerData.citizenid) and not apartment:IsRoommate(Player.PlayerData.citizenid) then
        exports["soz-monitor"]:Log("ERROR", ("GiveTemporaryAccess %s - Apartment %s | skipped because player has no access"):format(propertyId, apartmentId))
        return
    end

    apartment:AddTemporaryAccess(Target.PlayerData.citizenid)

    TriggerClientEvent("hud:client:DrawNotification", Player.PlayerData.source, "Vous avez donné un accès à votre maison")
    TriggerClientEvent("hud:client:DrawNotification", Target.PlayerData.source, "Vous avez reçu un accès à une maison")

    TriggerClientEvent("housing:client:UpdateApartment", -1, propertyId, apartmentId, apartment)
end)

---
--- Exports
---
exports("UpdatePropertyZone", function(propertyId, zone_type, zone_config)
    local property = Properties[propertyId]
    if property == nil then
        local propertyBd = MySQL.query.await("SELECT * FROM housing_property WHERE id = ?", {propertyId})
        Properties[propertyId] = Property:new(propertyBd.identifier)
    end

    property:SetZone(zone_type, zone_config)

    if zone_type == "entry_zone" then
        MySQL.update.await("UPDATE housing_property SET entry_zone = ? WHERE id = ?", {
            json.encode(zone_config),
            propertyId,
        })
    elseif zone_type == "garage_zone" then
        MySQL.update.await("UPDATE housing_property SET garage_zone = ? WHERE id = ?", {
            json.encode(zone_config),
            propertyId,
        })
    end

    TriggerClientEvent("housing:client:UpdatePropertyZone", -1, propertyId, zone_type, property:GetZone(zone_type))
end)

exports("SetApartmentIdentifier", function(propertyId, apartmentId, identifier)
    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("SetApartmentIdentifier %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    apartment:SetIdentifier(identifier)

    MySQL.update.await("UPDATE housing_apartment SET identifier = ? WHERE id = ? AND property_id = ?", {
        identifier,
        apartmentId,
        propertyId,
    })
    TriggerClientEvent("housing:client:SetApartmentIdentifier", -1, propertyId, apartmentId, identifier)
end)

exports("SetApartmentLabel", function(propertyId, apartmentId, label)
    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("SetApartmentIdentifier %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    apartment:SetLabel(label)

    MySQL.update.await("UPDATE housing_apartment SET label = ? WHERE id = ? AND property_id = ?", {
        label,
        apartmentId,
        propertyId,
    })
    TriggerClientEvent("housing:client:SetApartmentLabel", -1, propertyId, apartmentId, label)
end)

exports("SetApartmentInsideCoord", function(propertyId, apartmentId, coord)
    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("SetApartmentInsideCoord %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    apartment:SetInsideCoord(coord)

    MySQL.update.await("UPDATE housing_apartment SET inside_coord = ? WHERE id = ? AND property_id = ?", {
        json.encode(coord),
        apartmentId,
        propertyId,
    })
    TriggerClientEvent("housing:client:SetApartmentInsideCoord", -1, propertyId, apartmentId, coord)
end)

exports("UpdateApartmentZone", function(propertyId, apartmentId, zone_type, zone_config)
    local apartment = Properties[propertyId]:GetApartment(apartmentId)
    if apartment == nil then
        exports["soz-monitor"]:Log("ERROR", ("SetApartmentInsideCoord %s - Apartment %s | skipped because it has no apartment"):format(propertyId, apartmentId))
        return
    end

    apartment:SetZone(zone_type, zone_config)

    if zone_type == "exit_zone" then
        MySQL.update.await("UPDATE housing_apartment SET exit_zone = ? WHERE id = ? AND property_id = ?", {
            json.encode(zone_config),
            apartmentId,
            propertyId,
        })
    elseif zone_type == "fridge_zone" then
        MySQL.update.await("UPDATE housing_apartment SET fridge_zone = ? WHERE id = ? AND property_id = ?", {
            json.encode(zone_config),
            apartmentId,
            propertyId,
        })
    elseif zone_type == "stash_zone" then
        MySQL.update.await("UPDATE housing_apartment SET stash_zone = ? WHERE id = ? AND property_id = ?", {
            json.encode(zone_config),
            apartmentId,
            propertyId,
        })
    elseif zone_type == "closet_zone" then
        MySQL.update.await("UPDATE housing_apartment SET closet_zone = ? WHERE id = ? AND property_id = ?", {
            json.encode(zone_config),
            apartmentId,
            propertyId,
        })
    elseif zone_type == "money_zone" then
        MySQL.update.await("UPDATE housing_apartment SET money_zone = ? WHERE id = ? AND property_id = ?", {
            json.encode(zone_config),
            apartmentId,
            propertyId,
        })
    end

    TriggerClientEvent("housing:client:UpdateApartmentZone", -1, propertyId, apartmentId, zone_type, apartment:GetZone(zone_type))
end)
