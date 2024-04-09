local diceProgression = {"1d1", "1d2", "1d3", "1d4", "1d6", "1d8", "1d10", "2d6", "2d8", "3d6", "3d8", "4d6", "4d8", "6d6", "6d8", "8d6", "8d8", "12d6", "12d8", "16d6"}

local function dieSplit(die)
    local dieCount, dieSides = die:match("(%d*)d(%d+)")
    return tonumber(dieCount) or 1, tonumber(dieSides) or 1
end

local function transformSpecialDice(die)
    local newDie = die
    local dieCount, dieSides = dieSplit(die)
    if dieSides == 12 then
        newDie = 2 * tonumber(dieCount) .. "d6"
    elseif dieSides == 4 and dieCount > 1 then
        if dieCount % 2 == 0 then
            newDie = dieCount / 2 .. "d8"
        else
            newDie = math.floor(dieCount / 2) + 1 .. "d6"
        end
    elseif dieSides == 10 and dieCount > 1 then
        newDie = diceProgression[9 + (dieCount - 1) * 2]
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

local function isWeaponOfNosizeType(rRoll)
  if #(rRoll.clauses) > 0 then
    local dmgtype = rRoll.clauses[1].dmgtype
    for str in string.gmatch(dmgtype, "([^,]+)") do
      if string.match(str, "^%s*(.-)%s*$") == "nosize" then
        return true
      end
    end
  end
  return false
end

local function applySizeEffectsToModRoll(rRoll, rSource, rTarget)
    if rRoll.sType == "damage" and not isWeaponOfNosizeType(rRoll) then
        local tSizeEffects, nSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "SIZE", true, rRoll.tAttackFilter, rTarget, false, rRoll.tags)
        local tWeapSizeEffects, nWeapSizeEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "ESIZE", true, rRoll.tAttackFilter, rTarget, false, rRoll.tags)
        if nSizeEffectCount > 0 or nWeapSizeEffectCount > 0 then
            local sizeChange = 0
            for _,effect in pairs(tSizeEffects) do
                sizeChange = sizeChange + effect.mod
            end
            for _,effect in pairs(tWeapSizeEffects) do
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
                local sizeIndex = SizeManager.getOriginalCreatureSize(rSource)
                local progressionIndex = nil
                for i = 1, math.abs(sizeChange), 1 do
                    if progressionIndex == nil then
                        progressionIndex = findDiceProgressionIndex(diceString)
                    end
                    if sizeChange > 0 then
                        if progressionIndex < 6 or sizeIndex < 0 then
                            progressionIndex = progressionIndex + 1
                        else
                            progressionIndex = progressionIndex + 2
                        end
                        sizeIndex = sizeIndex + 1
                    else
                        if progressionIndex <= 6 or sizeIndex <= 0 then
                            progressionIndex = progressionIndex - 1
                        else
                            progressionIndex = progressionIndex - 2
                        end
                        sizeIndex = sizeIndex - 1
                    end
                end
                local newDice = convertDiceStringToArray(diceProgression[progressionIndex])
                rRoll.clauses[1].dice = newDice
                updateDiceArray(rRoll)
            end
        end
    end
end


local applyAbilityEffectsToModRoll = nil
local function applyAbilityEffectsToModRollExtended(rRoll, rSource, rTarget, ...)
    applySizeEffectsToModRoll(rRoll, rSource, rTarget)
    applyAbilityEffectsToModRoll(rRoll, rSource, rTarget, ...)
end


function onInit()
    applyAbilityEffectsToModRoll = ActionDamage.applyAbilityEffectsToModRoll
    ActionDamage.applyAbilityEffectsToModRoll = applyAbilityEffectsToModRollExtended
end
