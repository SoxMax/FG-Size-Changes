
local function applySizeEffectsToModRoll(rRoll, rSource, rTarget)
    Debug.chat(rRoll)

    if rSource then
		local bEffects = false;

		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)");
		if sSkill then
			sSkillLower = string.lower(StringManager.trim(sSkill));
		end

        if sSkillLower == "fly" or sSkillLower == "stealth" then
            Debug.chat("fly or stealth skill")
            local aSkillFilter = { sSkillLower }
            Debug.chat(EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, aSkillFilter, rTarget, false, rRoll.tags))
            Debug.chat(EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, nil, rTarget, false, rRoll.tags))

            -- If effects, then add them
            if bEffects then
                for _,vDie in ipairs(aAddDice) do
                    if vDie:sub(1,1) == "-" then
                        table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
                    else
                        table.insert(rRoll.aDice, "p" .. vDie:sub(2));
                    end
                end
                rRoll.nMod = rRoll.nMod + nAddMod;

                local sEffects = "";
                local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
                if sMod ~= "" then
                    sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
                else
                    sEffects = "[" .. Interface.getString("effects_tag") .. "]";
                end
                rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
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
end
