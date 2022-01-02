local QBCore = exports['qb-core']:GetCoreObject()
local inventoryMenu = MenuV:CreateMenu("Inventaire", "", 255, 0, 0, 'default_native', 'menuv', 'inventory')
local PlayerData = QBCore.Functions.GetPlayerData()

local currentWeapon, CurrentWeaponData = nil, {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

local function MoneyMenu()
    local moneyItem = MenuV:InheritMenu(inventoryMenu, { Subtitle = 'Argent' })

    inventoryMenu:AddButton({
        label = PlayerData.money['cash'] .. '$',
        value = moneyItem,
        description = "Votre argent"
    })


    local give = moneyItem:AddButton({ label = "Donner", value = 'money', description = "" })
    give:On('select', function(i)
        local player, distance = QBCore.Functions.GetClosestPlayer()
        if player ~= -1 and distance < 2.0 then
            local amount = exports['soz-hud']:Input('Quantité', 5)

            if amount and tonumber(amount) > 0 then
                SetCurrentPedWeapon(PlayerPedId(),'WEAPON_UNARMED',true)
                TriggerServerEvent("inventory:server:GiveMoney", GetPlayerServerId(player), tonumber(amount))
                MenuV:CloseAll()
            end
        else
            exports['soz-hud']:DrawNotification("Personne n'est à portée de vous")
        end
    end)
end

local function ItemsMenu()
    local playerWeight = 0

    for _,item in pairs(PlayerData.items) do
        local itemMenu = MenuV:InheritMenu(inventoryMenu, { Subtitle = item.label })
        playerWeight = playerWeight + item.weight

        if item.useable or item.type == 'weapon' then
            local label = "Utiliser"
            if item.type == 'weapon' then label = "Équiper" end

            local use = itemMenu:AddButton({ label = label, value = item, description = "" })
            use:On('select', function(i)
                TriggerServerEvent('inventory:server:UseItemSlot', i.Value.slot)
                MenuV:CloseAll()
            end)
        end

        local give = itemMenu:AddButton({ label = "Donner", value = item, description = "" })
        give:On('select', function(i)
            local player, distance = QBCore.Functions.GetClosestPlayer()
            if player ~= -1 and distance < 2.0 then
                local amount = exports['soz-hud']:Input('Quantité', 5, item.amount)

                if amount and tonumber(amount) > 0 then
                    SetCurrentPedWeapon(PlayerPedId(),'WEAPON_UNARMED',true)
                    TriggerServerEvent("inventory:server:GiveItem", GetPlayerServerId(player), i.Value, tonumber(amount))
                    MenuV:CloseAll()
                end
            else
                exports['soz-hud']:DrawNotification("Personne n'est à portée de vous")
            end
        end)

        inventoryMenu:AddButton({
            label = item.amount .. ' ' .. item.label,
            value = itemMenu,
            description = item.description
        })
    end

    return playerWeight
end

local function GenerateInventoryMenu()
    inventoryMenu:ClearItems()

    MoneyMenu()
    playerWeight = ItemsMenu()

    inventoryMenu:SetSubtitle(string.format('%s/%s Kg', playerWeight/1000, QBCore.Config.Player.MaxWeight/1000))

    MenuV:CloseAll(function()
        inventoryMenu:Open()
    end)
end

RegisterKeyMapping("inventory", "Ouvrir l'inventaire", "keyboard", "F2")
RegisterCommand("inventory", GenerateInventoryMenu, false)

RegisterNetEvent('inventory:client:UseWeapon', function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    if currentWeapon == weaponName then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        RemoveAllPedWeapons(ped, true)
        TriggerEvent('weapons:client:SetCurrentWeapon', nil, shootbool)
        currentWeapon = nil
    elseif weaponName == "weapon_stickybomb" or weaponName == "weapon_pipebomb" or weaponName == "weapon_smokegrenade" or weaponName == "weapon_flare" or weaponName == "weapon_proxmine" or weaponName == "weapon_ball"  or weaponName == "weapon_molotov" or weaponName == "weapon_grenade" or weaponName == "weapon_bzgas" then
        GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 1)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    elseif weaponName == "weapon_snowball" then
        GiveWeaponToPed(ped, GetHashKey(weaponName), 10, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 10)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerServerEvent('QBCore:Server:RemoveItem', weaponName, 1)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    else
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        QBCore.Functions.TriggerCallback("weapon:server:GetWeaponAmmo", function(result)
            local ammo = tonumber(result)
            if weaponName == "weapon_petrolcan" or weaponName == "weapon_fireextinguisher" then
                ammo = 4000
            end
            GiveWeaponToPed(ped, GetHashKey(weaponName), 0, false, false)
            SetPedAmmo(ped, GetHashKey(weaponName), ammo)
            SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
            if weaponData.info.attachments ~= nil then
                for _, attachment in pairs(weaponData.info.attachments) do
                    GiveWeaponComponentToPed(ped, GetHashKey(weaponName), GetHashKey(attachment.component))
                end
            end
            currentWeapon = weaponName
        end, CurrentWeaponData)
    end
end)
