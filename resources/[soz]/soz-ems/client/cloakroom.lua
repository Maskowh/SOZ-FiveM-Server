RegisterNetEvent("lsmc:client:OpenCloakroomMenu", function()
    EmsJob.Functions.Menu.GenerateMenu(PlayerData.job.id, function(menu)
        menu:AddButton({
            label = "Tenue civile",
            value = nil,
            select = function()
                QBCore.Functions.Progressbar("switch_clothes", "Changement d'habits...", 5000, false, true, {
                    disableMovement = true,
                    disableCombat = true,
                }, {animDict = "anim@mp_yacht@shower@male@", anim = "male_shower_towel_dry_to_get_dressed", flags = 16}, {}, {}, function() -- Done
                    TriggerEvent("soz-character:Client:ApplyCurrentClothConfig")
                end)
            end,
        })

        for name, skin in pairs(Config.Cloakroom[PlayerData.job.id][PlayerData.skin.Model.Hash]) do
            menu:AddButton({
                label = name,
                value = nil,
                select = function()
                    QBCore.Functions.Progressbar("switch_clothes", "Changement d'habits...", 5000, false, true, {
                        disableMovement = true,
                        disableCombat = true,
                    }, {
                        animDict = "anim@mp_yacht@shower@male@",
                        anim = "male_shower_towel_dry_to_get_dressed",
                        flags = 16,
                    }, {}, {}, function() -- Done
                        TriggerEvent("soz-character:Client:ApplyTemporaryClothSet", skin)
                    end)
                end,
            })
        end
    end)
end)
