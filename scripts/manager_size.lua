getOriginalCreatureSize = nil

function getCreatureSize(rActor)
    local originalSize = getOriginalCreatureSize(rActor)
    local sizeChange = EffectManager35E.getEffectsBonus(rActor, "SIZE", true, {"melee", "ranged"})
    return originalSize + sizeChange
end

function onInit()
    getOriginalCreatureSize = ActorCommonManager.getCreatureSizeDnD3
    ActorCommonManager.getCreatureSizeDnD3 = getCreatureSize
end
