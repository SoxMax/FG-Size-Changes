local diceProgression = {"1d1", "1d2", "1d3", "1d4", "1d6", "1d8", "1d10", "2d6", "2d8", "3d6", "3d8", "4d6", "4d8", "6d6", "6d8", "8d6", "8d8", "12d6", "12d8", "16d6"}
local smallSizes = {"Fine", "Diminutive", "Tiny", "Small"}

local function dieSplit(die)
    local dieCount, dieSides = die:match("(%d*)d(%d+)")
    return tonumber(dieCount) or 1, tonumber(dieSides) or 1
end

local function transformSpecialDice(die)
    local newDie = die
    local dieCount, dieSides = dieSplit(die)
    if dieSides == 12 then
        die = 2 * tonumber(dieCount) .. "d6"
    elseif dieSides == 4 and dieCount > 1 then
        if dieCount % 2 == 0 then
            die = dieCount / 2 .. "d8"
        else
            die = math.floor(dieCount / 2) + 1 .. "d6"
        end
    elseif dieSides == 10 and dieCount > 1 then
        die = diceProgression[9 + (dieCount - 1) * 2]
    end
    return newDie
end

local function findDiceProgressionIndex(diceString)
    local dieCount, dieSides = dieSplit(diceString)
    for progressionIndex,progressionValue in ipairs(diceProgression) do
        local progCount, progSides = dieSplit(progressionValue)
        if diceString == progressionValue then
            return progressionIndex
        elseif dieSides == 6 and dieCount < progCount then
            return progressionIndex - 1
        elseif dieSides == 8 and dieCount < progCount then
            return progressionIndex
        end
    end
end

local function convertDiceStringToArray(dieString)
    local newDiceCount, newDiceSides = dieSplit(dieString)
    local newDice = {}
    local dieString = "d" .. newDiceSides
    for i = 1, newDiceCount, 1 do
        newDice[i] = dieString
    end
    return newDice
end

local function updateDiceArray(rRoll)
    local aDice = {}
    for _,clause in ipairs(rRoll.clauses) do
        for _,die in ipairs(clause.dice) do
            table.insert(aDice, {type=die})
        end
    end
    rRoll.aDice = aDice
end

local function applySizeEffectsToModRoll(rRoll, rSource, rTarget)
    if rRoll.sType == "damage" and rRoll.range == "M" then
        local tEffects, nEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, rRoll.tAttackFilter, rTarget);
        if nEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tEffects) do
                sizeChange = sizeChange + effect.mod
            end
            if sizeChange ~= 0 and #(rRoll.clauses) > 0 then
                local dice = rRoll.clauses[1].dice
                local diceCount = #(dice)
                local diceString = "1d1"
                if diceCount > 0 then
                    diceString = diceCount .. dice[1]
                end
                diceString = transformSpecialDice(diceString)
                local progressionIndex = nil
                for i = 1, math.abs(sizeChange), 1 do
                    if progressionIndex == nil then
                        progressionIndex = findDiceProgressionIndex(diceString)
                    end
                    Debug.chat("Before increase", progressionIndex, diceProgression[progressionIndex])
                    if sizeChange > 0 then
                        if progressionIndex < 6 then
                            progressionIndex = progressionIndex + 1
                        else
                            progressionIndex = progressionIndex + 2
                        end
                    else
                        if progressionIndex <= 6 then
                            progressionIndex = progressionIndex - 1
                        else
                            progressionIndex = progressionIndex - 2
                        end
                    end
                    Debug.chat("After increase", progressionIndex, diceProgression[progressionIndex])
                end
                local newDice = convertDiceStringToArray(diceProgression[progressionIndex])
                rRoll.clauses[1].dice = newDice
                updateDiceArray(rRoll)
            end
        end
    end
end


local applyDmgEffectsToModRoll = nil
local function applyDmgEffectsToModRollExtended(rRoll, rSource, rTarget, ...)
    applySizeEffectsToModRoll(rRoll, rSource, rTarget)
    applyDmgEffectsToModRoll(rRoll, rSource, rTarget, ...)
end


function onInit()
    applyDmgEffectsToModRoll = ActionDamage.applyDmgEffectsToModRoll
    ActionDamage.applyDmgEffectsToModRoll = applyDmgEffectsToModRollExtended
end
