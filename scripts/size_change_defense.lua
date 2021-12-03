local sizeCombatModifiers = {8, 4, 2, 1, 0, -1, -2, -4, -8}

function getSizeEffectsBonusForDefender(rDefender, rRoll)
    -- Debug.chat(rDefender, rRoll)
    if rDefender and rRoll.sType ~= "grapple" then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rDefender, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
        if nSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 then
                local sizeIndex = SizeChangeCommon.getActorSize(rDefender)
                local skillChange = math.abs(sizeCombatModifiers[sizeIndex] - sizeCombatModifiers[sizeIndex + sizeChange])
                if sizeChange > 0 then
                    skillChange = -skillChange
                end
                return skillChange
            end
        end
	end
    return 0
end

local getDefenseValue = nil
function getDefenseValueExtended(rAttacker, rDefender, rRoll, ...)
    local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance = getDefenseValue(rAttacker, rDefender, rRoll, ...)
    Debug.chat(nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance)
    nDefEffectsBonus = nDefEffectsBonus + getSizeEffectsBonusForDefender(rDefender, rRoll)
    return nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance
end

function onInit()
    getDefenseValue = ActorManager35E.getDefenseValue
    ActorManager35E.getDefenseValue = getDefenseValueExtended
end
