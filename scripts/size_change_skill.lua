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
                    local sizeIndex = ActorManager35E.getSize(rSource)
                    local skillChange = math.abs(SizeChangeData.sizeSkillModifiers[sizeIndex] - SizeChangeData.sizeSkillModifiers[sizeIndex + sizeChange])
                    if sizeChange < 0 then
                        skillChange = -skillChange
                    end
                    if sSkillLower == "stealth" or sSkillLower == "hide" then
                        skillChange = skillChange * 2
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
