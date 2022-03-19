local lastSpectateCoord = nil
local isSpectating = false

RegisterNetEvent("admin:client:spectate", function(targetPed, coords)
    local myPed = PlayerPedId()
    local targetplayer = GetPlayerFromServerId(targetPed)
    local target = GetPlayerPed(targetplayer)
    if not isSpectating then
        isSpectating = true
        SetEntityVisible(myPed, false)
        SetEntityInvincible(myPed, true)
        SetEntityCollision(myPed, false, false);
        lastSpectateCoord = GetEntityCoords(myPed)
        SetEntityCoords(myPed, coords)
        NetworkSetInSpectatorMode(true, target)
    else
        isSpectating = false
        NetworkSetInSpectatorMode(false, target)
        SetEntityCoords(myPed, lastSpectateCoord)
        SetEntityVisible(myPed, true)
        SetEntityInvincible(myPed, false)
        SetEntityCollision(myPed, true, true);
        lastSpectateCoord = nil
    end
end)
