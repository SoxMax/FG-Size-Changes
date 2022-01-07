local resizeOptionName = "RESIZETOKEN"

local function registerOptions()
    -- register option for toggling updates to token space on size change
    OptionsManager.registerOption2(resizeOptionName, false, "option_header_token", "option_label_RESIZETOKEN", "option_entry_cycler",
            { labels = "option_val_on", values="on", baselabel = "option_val_off", baseval="off", default="off"})
end

local function getTotalSize(rActor)
    local sizeChange = 0
    local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rActor, "SIZE", true, {"melee", "ranged"})
    if nSizeEffectCount > 0 then
        for _,effect in pairs(tSizeEffects) do
            sizeChange = sizeChange + effect.mod
        end
    end
    return ActorManager35E.getSize(rActor) + sizeChange
end

local function updateActorSpace(rActor)
    local size = getTotalSize(rActor)
    DB.setValue(DB.findNode(rActor.sCTNode), "space", "number", SizeChangeData.sizeSpace[size])
end

local function hasBonusVsTrip(nodeNPC)
    local sBABGrp = DB.getValue(nodeNPC, "babgrp", "");
    local aSplitBABGrp = StringManager.split(sBABGrp, "/", true);
    if #aSplitBABGrp ~= 3 then
        aSplitBABGrp = StringManager.split(sBABGrp, ";", true);
    end
    return ((aSplitBABGrp[3]:find("vs. trip", 1, true) or aSplitBABGrp[3]:find("can't be tripped", 1, true)) ~= nil)
end

local function updateActorReach(rActor)
    local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)
    local totalSize = getTotalSize(rActor)
    if sNodeType == "pc" then -- Is Player
        DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize])
    else -- Is NPC
        local baseSize = ActorManager35E.getSize(rActor)
        local nSpace, nReach = CombatManager2.getNPCSpaceReach(nodeActor)
        if nSpace < nReach then -- Extra tall
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize] * nReach / nSpace)
        elseif totalSize <= 0 then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize])
        elseif baseSize > 0 then -- Large or bigger by default
            if nSpace == nReach then -- Tall
                DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize])
            elseif nSpace > nReach then -- Long
                DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[totalSize])
            end
        elseif ActorManager35E.isCreatureType(rActor, "dragon,ooze") then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[totalSize])
        elseif ActorManager35E.isCreatureType(rActor, "elemental,fey,giant,humanoid,monstrous humanoid,outsider") then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize])
        elseif hasBonusVsTrip(nodeActor) then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[totalSize])
        else
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[totalSize])
        end
    end
end

-- This function is called on alignment, size or race change in the Combat Tracker
local function onCtTypeChanged(nodeType)
    if OptionsManager.isOption(resizeOptionName, "on") then
        local rActor = ActorManager.resolveActor(nodeType.getParent())
        updateActorSpace(rActor)
        updateActorReach(rActor)
    end
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
    if OptionsManager.isOption(resizeOptionName, "on") and effectNodeContainsEffect(nodeEffect, "SIZE") then
        local rActor = ActorManager.resolveActor(nodeEffect.getChild("..."))
        updateActorSpace(rActor)
        updateActorReach(rActor)
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