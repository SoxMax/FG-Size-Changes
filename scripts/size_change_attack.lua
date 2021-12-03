local function applySizeEffectsToModRoll(rSource, rTarget, rRoll)
    if rSource and rRoll.sType ~= "grapple" then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
        if nSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 then
                local sizeIndex = ActorManager35E.getSize(rSource)
                local effectBonus = math.abs(SizeChangeData.sizeCombatModifiers[sizeIndex] - SizeChangeData.sizeCombatModifiers[sizeIndex + sizeChange])
                if sizeChange > 0 then
                    effectBonus = -effectBonus
                end
                rRoll.nMod = rRoll.nMod + effectBonus
                local sMod = StringManager.convertDiceToString({}, effectBonus, true);
                if sMod ~= "" then
                    rRoll.sDesc = rRoll.sDesc .. " " .. "[SIZE " .. effectBonus .. "]"
                end
            end
        end
	end
end

local modAttack = nil
local function modAttackExtended(rSource, rTarget, rRoll, ...)
    modAttack(rSource, rTarget, rRoll, ...)
    applySizeEffectsToModRoll(rSource, rTarget, rRoll)
end

function onInit()
    modAttack = ActionAttack.modAttack
    ActionAttack.modAttack = modAttackExtended
	ActionsManager.registerModHandler("attack", modAttackExtended)
end
