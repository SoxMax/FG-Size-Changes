local function registerOptions()
    -- register option for toggling updates to token space on size change
    OptionsManager.registerOption2("RESIZETOKEN", false, "option_header_token", "option_label_RESIZETOKEN", "option_entry_cycler",
            { labels = "option_val_on", values="on", baselabel = "option_val_off", baseval="off", default="off"})
end

local function updateActorSpace(rActor)
    local sizeChange = 0
    local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rActor, "SIZE", true, {"melee", "ranged"})
    if nSizeEffectCount > 0 then
        for _,effect in pairs(tSizeEffects) do
            sizeChange = sizeChange + effect.mod
        end
    end
    local size = ActorManager35E.getSize(rActor) + sizeChange
    DB.setValue(DB.findNode(rActor.sCTNode), "space", "number", SizeChangeData.sizeSpace[size])
end

-- This function is called on alignment, size or race change in the Combat Tracker
local function onCtTypeChanged(nodeType)
    local rActor = ActorManager.resolveActor(nodeType.getParent())
    updateActorSpace(rActor)
end

local function effectNodeContainsEffect(nodeEffect, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
    if not sEffect or not nodeEffect then
		return false
	end
	local sLowerEffect = sEffect:lower()
	
	-- Iterate through each effect
	local bMatch = false
    local nActive = DB.getValue(nodeEffect, "isactive", 0)
    if nActive ~= 0 then
        -- Parse each effect label
        local sLabel = DB.getValue(nodeEffect, "label", "")
        local bTargeted = EffectManager.isTargetedEffect(nodeEffect)
        local aEffectComps = EffectManager.parseEffect(sLabel)

        -- Iterate through each effect component looking for a type match
        local nMatch = 0
        for kEffectComp, sEffectComp in ipairs(aEffectComps) do
            local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp)
            -- Check conditionals
            local rActor = ActorManager.resolveActor(nodeEffect.getChild("..."))
            if rEffectComp.type == "IF" then
                if not EffectManager35E.checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
                    break
                end
            elseif rEffectComp.type == "IFT" then
                if not rTarget then
                    break
                end
                if not EffectManager35E.checkConditional(rTarget, nodeEffect, rEffectComp.remainder, rActor) then
                    break
                end
            -- Check for match
            elseif rEffectComp.original:lower() == sLowerEffect or rEffectComp.type:lower() == sLowerEffect then
                if bTargeted and not bIgnoreEffectTargets then
                    if EffectManager.isEffectTarget(nodeEffect, rTarget) then
                        nMatch = kEffectComp
                    end
                elseif not bTargetedOnly then
                    nMatch = kEffectComp
                end
            end
            
        end
        
        -- If matched, then remove one-off effects
        if nMatch > 0 then
            if nActive == 2 then
                DB.setValue(nodeEffect, "isactive", "number", 1)
            else
                bMatch = true
                local sApply = DB.getValue(nodeEffect, "apply", "")
                if sApply == "action" then
                    EffectManager.notifyExpire(nodeEffect, 0)
                elseif sApply == "roll" then
                    EffectManager.notifyExpire(nodeEffect, 0, true)
                elseif sApply == "single" then
                    EffectManager.notifyExpire(nodeEffect, nMatch, true)
                end
            end
        end
    end

	return bMatch
end

-- This function is call whenever any effect in the Combat Tracker changes
local function onEffectChanged(nodeEffect, bListchanged)
    if effectNodeContainsEffect(nodeEffect, "SIZE") then
        local rActor = ActorManager.resolveActor(nodeEffect.getChild("..."))
        updateActorSpace(rActor)
    end
end

function onInit()
    registerOptions()

    if Session.IsHost then
        -- Check for type changes (size is in here)
        DB.addHandler(DB.getPath("combattracker.list.*.type"), "onUpdate", onCtTypeChanged)
        -- Check for effect changes
        DB.addHandler(DB.getPath("combattracker.list.*.effects.*"), "onChildUpdate", onEffectChanged)
    end
end
