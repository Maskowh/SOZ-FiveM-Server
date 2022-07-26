RegisterNetEvent("admin:gamemaster:giveMoney", function(moneyType, amount)
    if not SozAdmin.Functions.IsPlayerAdmin(source) then
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    if player and moneyType and amount then
        player.Functions.AddMoney(moneyType, tonumber(amount))
    end
end)

RegisterNetEvent("admin:gamemaster:giveLicence", function(licence)
    if not SozAdmin.Functions.IsPlayerAdmin(source) then
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    if player and licence then
        player.Functions.SetLicence(licence, 12)
    end
end)

RegisterNetEvent("admin:gamemaster:unCuff", function(moneyType, amount)
    if not SozAdmin.Functions.IsPlayerHelper(source) then
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    if player and moneyType and amount then
        player.Functions.SetMetaData("ishandcuffed", false)
    end
end)

RegisterNetEvent("admin:gamemaster:godmode", function(val)
    if not SozAdmin.Functions.IsPlayerAdmin(source) then
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    player.Functions.SetMetaData("godmode", val)
end)
