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

local function updateActorSpace(rActor, size)
    DB.setValue(DB.findNode(rActor.sCTNode), "space", "number", SizeChangeData.sizeSpace[size])
    if OptionsManager.getOption("TASG") ~= "off" then
        local token = CombatManager.getTokenFromCT(rActor.sCTNode)
        if token then
            TokenManager.autoTokenScale(token)
        end
    end
end

local function playerHasReachWeapon(rActor)
    for _, weaponNode in pairs(DB.getChild(rActor.sCreatureNode, "weaponlist").getChildren()) do
        if DB.getValue(weaponNode, "carried", 0) == 2 then
            local weaponProperties = DB.getValue(weaponNode, "properties", "")
            if weaponProperties ~= "" then
                for _, property in pairs(StringManager.split(weaponProperties, ",", true)) do
                    if property:lower() == "reach" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function hasBonusVsTrip(nodeNPC)
    local sBABGrp = DB.getValue(nodeNPC, "babgrp", "");
    local aSplitBABGrp = StringManager.split(sBABGrp, "/", true);
    if #aSplitBABGrp ~= 3 then
        aSplitBABGrp = StringManager.split(sBABGrp, ";", true);
    end
    return ((aSplitBABGrp[3]:find("vs. trip", 1, true) or aSplitBABGrp[3]:find("can't be tripped", 1, true)) ~= nil)
end

local function updateActorReach(rActor, size)
    local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)
    if sNodeType == "pc" then -- Is Player
        local reachMultiplier = 1
        if playerHasReachWeapon(rActor) then
            reachMultiplier = 2
        end
        DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size] * reachMultiplier)
    else -- Is NPC
        local baseSize = ActorManager35E.getSize(rActor)
        local nSpace, nReach = CombatManager2.getNPCSpaceReach(nodeActor)
        if nSpace < nReach then -- Extra tall
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size] * nReach / nSpace)
        elseif size <= 0 then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size])
        elseif baseSize > 0 then -- Large or bigger by default
            if nSpace == nReach then -- Tall
                DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size])
            elseif nSpace > nReach then -- Long
                DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[size])
            end
        elseif ActorManager35E.isCreatureType(rActor, "dragon,ooze") then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[size])
        elseif ActorManager35E.isCreatureType(rActor, "elemental,fey,giant,humanoid,monstrous humanoid,outsider") then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size])
        elseif hasBonusVsTrip(nodeActor) then
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeLongReach[size])
        else
            DB.setValue(DB.findNode(rActor.sCTNode), "reach", "number", SizeChangeData.sizeTallReach[size])
        end
    end
end

local function updateSpaceAndReach(rActor)
    local size = getTotalSize(rActor)
    updateActorSpace(rActor, size)
    updateActorReach(rActor, size)
end

-- This function is called on alignment, size or race change in the Combat Tracker
local function onCtTypeChanged(nodeType)
    if OptionsManager.isOption(resizeOptionName, "on") then
        local rActor = ActorManager.resolveActor(nodeType.getParent())
        updateSpaceAndReach(rActor)
    end
end

local function effectNodeContainsEffect(nodeEffect, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
    if not sEffect or not nodeEffect then
		return false
	end
	local sLowerEffect = sEffect:lower()
	
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
        bMatch = nMatch > 0
    end

	return bMatch
end

-- This function is called whenever any effect in the Combat Tracker has it's label or isactive attribut updated
local function onEffectChanged(nodeEffectField)
    if OptionsManager.isOption(resizeOptionName, "on") and effectNodeContainsEffect(nodeEffectField.getParent(), "SIZE") then
        local rActor = ActorManager.resolveActor(nodeEffectField.getChild("...."))
        updateSpaceAndReach(rActor)
    end
end

-- This function is called whenever any effects in the Combat Tracker are deleted
local function onEffectDeleted(nodeEffects)
    if OptionsManager.isOption(resizeOptionName, "on") then
        local rActor = ActorManager.resolveActor(nodeEffects.getParent())
        updateSpaceAndReach(rActor)
    end
end

function onInit()
    registerOptions()

    if Session.IsHost then
        -- Check for type changes (size is in here)
        DB.addHandler(DB.getPath("combattracker.list.*.type"), "onUpdate", onCtTypeChanged)
        -- Add handlers for updates on the label or active status (includes adding)
        DB.addHandler(DB.getPath("combattracker.list.*.effects.*.label"), "onUpdate", onEffectChanged)
        DB.addHandler(DB.getPath("combattracker.list.*.effects.*.isactive"), "onUpdate", onEffectChanged)
        -- Check if removed effect changed size
        DB.addHandler(DB.getPath("combattracker.list.*.effects"), "onChildDeleted", onEffectDeleted)
    end
end
