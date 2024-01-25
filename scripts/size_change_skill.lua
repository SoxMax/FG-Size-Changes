local function applySizeEffectsToModRoll(rSource, rTarget, rRoll)
    if rSource then
		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)");
		if sSkill then
			sSkillLower = string.lower(StringManager.trim(sSkill));
		end
        -- Check if this is a skill affected by size
        if sSkillLower == "fly" or sSkillLower == "stealth" or sSkillLower == "hide" then
            local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, {"melee", "ranged"}, nil, false, rRoll.tags)
            if nSizeEffectCount > 0 then
                local sizeChange = 0
                for _,effect in pairs(tSizeEffects) do
                    sizeChange = sizeChange + effect.mod
                end
                if sizeChange ~= 0 then
                    local sizeIndex = SizeManager.getOriginalCreatureSize(rSource)
                    local effectBonus = math.abs(SizeChangeData.sizeSkillModifiers[sizeIndex] - SizeChangeData.sizeSkillModifiers[sizeIndex + sizeChange])
                    if sizeChange > 0 then
                        effectBonus = -effectBonus
                    end
                    if sSkillLower == "stealth" or sSkillLower == "hide" then
                        effectBonus = effectBonus * 2
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
end

local modSkill = nil
local function modSkillExtended(rSource, rTarget, rRoll, ...)
    modSkill(rSource, rTarget, rRoll, ...)
    applySizeEffectsToModRoll(rSource, rTarget, rRoll)
end

function onInit()
    modSkill = ActionSkill.modSkill
    ActionDamage.modSkill = modSkillExtended
	ActionsManager.registerModHandler("skill", modSkillExtended);
end
