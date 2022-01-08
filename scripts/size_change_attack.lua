local function applySizeEffectsToAttackModRoll(rSource, rTarget, rRoll)
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
                    rRoll.sDesc = rRoll.sDesc .. " " .. "[SIZE " .. sMod .. "]"
                end
            end
        end
	end
end

local function systemSpecificGrappleBonus(sizeIndex, sizeChange)
    local multiplier = 1
    if sizeChange < 0 then
        multiplier = -1
    end
    if DataCommon.isPFRPG() then
        return multiplier * math.abs(SizeChangeData.sizeCombatModifiers[sizeIndex] - SizeChangeData.sizeCombatModifiers[sizeIndex + sizeChange])
    else
        return multiplier * math.abs(SizeChangeData.sizeGrappleModifiers[sizeIndex] - SizeChangeData.sizeGrappleModifiers[sizeIndex + sizeChange])
    end
end

local function applySizeEffectsToGrappleModRoll(rSource, rTarget, rRoll)
    if rSource and rRoll.sType == "grapple" then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
        if nSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 then
                local sizeIndex = ActorManager35E.getSize(rSource)
                local effectBonus = systemSpecificGrappleBonus(sizeIndex, sizeChange)
                rRoll.nMod = rRoll.nMod + effectBonus
                local sMod = StringManager.convertDiceToString({}, effectBonus, true);
                if sMod ~= "" then
                    rRoll.sDesc = rRoll.sDesc .. " " .. "[SIZE " .. sMod .. "]"
                end
            end
        end
	end
end

local modAttack = nil
local function modAttackExtended(rSource, rTarget, rRoll, ...)
    modAttack(rSource, rTarget, rRoll, ...)
    applySizeEffectsToAttackModRoll(rSource, rTarget, rRoll)
end

local function modGrappleExtended(rSource, rTarget, rRoll, ...)
    modAttack(rSource, rTarget, rRoll, ...)
    applySizeEffectsToGrappleModRoll(rSource, rTarget, rRoll)
end

function onInit()
    modAttack = ActionAttack.modAttack
    ActionAttack.modAttack = modAttackExtended
	ActionsManager.registerModHandler("attack", modAttackExtended)
	ActionsManager.registerModHandler("grapple", modGrappleExtended)
end
