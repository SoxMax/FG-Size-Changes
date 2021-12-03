local sizeCombatModifiers = {8, 4, 2, 1, 0, -1, -2, -4, -8}

local function applySizeEffectsToModRoll(rSource, rTarget, rRoll)
    if rSource and rRoll.sType ~= "grapple" then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
        if nSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 then
                local sizeIndex = SizeChangeCommon.getActorSize(rSource)
                local skillChange = math.abs(sizeCombatModifiers[sizeIndex] - sizeCombatModifiers[sizeIndex + sizeChange])
                if sizeChange > 0 then
                    skillChange = -skillChange
                end
                rRoll.nMod = rRoll.nMod + skillChange
                local sMod = StringManager.convertDiceToString({}, skillChange, true);
                if sMod ~= "" then
                    rRoll.sDesc = rRoll.sDesc .. " " .. "[SIZE " .. skillChange .. "]"
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
    modSkill = ActionSkill.modAttack
    ActionDamage.modAttack = modAttackExtended
	ActionsManager.registerModHandler("attack", modAttackExtended);
end
