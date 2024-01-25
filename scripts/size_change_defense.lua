function getSizeEffectsBonusForDefender(rDefender, rRoll)
    local isGrapple = rRoll.sType == "grapple"
    if rDefender and (not isGrapple or DataCommon.isPFRPG()) then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rDefender, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
        if nSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 then
                local sizeIndex = SizeManager.getOriginalCreatureSize(rDefender)
                local effectBonus = math.abs(SizeChangeData.sizeCombatModifiers[sizeIndex] - SizeChangeData.sizeCombatModifiers[sizeIndex + sizeChange])
                if isGrapple and sizeChange < 0 then
                    effectBonus = -effectBonus
                elseif not isGrapple and sizeChange > 0 then
                    effectBonus = -effectBonus
                end
                return effectBonus
            end
        end
	end
    return 0
end

local getDefenseValue = nil
function getDefenseValueExtended(rAttacker, rDefender, rRoll, ...)
    local defenseVals = { getDefenseValue(rAttacker, rDefender, rRoll, ...) }
    local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance = unpack(defenseVals, 1, 4)
    nDefEffectsBonus = nDefEffectsBonus + getSizeEffectsBonusForDefender(rDefender, rRoll)
    return nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance, unpack(defenseVals, 5)
end

function onInit()
    getDefenseValue = ActorManager35E.getDefenseValue
    ActorManager35E.getDefenseValue = getDefenseValueExtended
end
