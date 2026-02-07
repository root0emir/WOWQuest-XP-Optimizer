local QUEST_TIME_ESTIMATES = {
    ["kill"] = 5,
    ["monster"] = 5,
    ["item"] = 6,
    ["collect"] = 6,
    ["object"] = 4,
    ["escort"] = 8,
    ["event"] = 7,
    ["reputation"] = 10,
    ["log"] = 3,
    ["player"] = 8,
    ["progressbar"] = 6,
    ["default"] = 5
}

local LEVEL_XP_MULTIPLIER = {
    [5] = 0.1,
    [4] = 0.2,
    [3] = 0.4,
    [2] = 0.6,
    [1] = 0.8,
    [0] = 1.0,
    [-1] = 1.0,
    [-2] = 1.05,
    [-3] = 1.1,
    [-4] = 1.15,
    [-5] = 1.2
}

local BASE_XP_PER_LEVEL = {
    retail = 50,
    classic = 45,
    cata = 48
}

function QuestXPOptimizer:GetQuestXP(questID)
    if not questID then return 0 end
    
    local xp = self.API.GetQuestLogRewardXP(questID)
    if xp and xp > 0 then
        return xp
    end
    
    local playerLevel = UnitLevel("player") or 1
    local questLevel = self:GetQuestLevel(questID) or playerLevel
    local baseXP = self:CalculateBaseXP(questLevel)
    local levelDiff = playerLevel - questLevel
    local multiplier = self:GetLevelMultiplier(levelDiff)
    
    return math.floor(baseXP * multiplier)
end

function QuestXPOptimizer:GetQuestLevel(questID)
    if not questID then return UnitLevel("player") end
    
    local index = self.API.GetLogIndexForQuestID(questID)
    if index then
        local info = self.API.GetQuestInfo(index)
        if info and info.level and info.level > 0 then
            return info.level
        end
    end
    return UnitLevel("player") or 1
end

function QuestXPOptimizer:CalculateBaseXP(questLevel)
    if not questLevel or questLevel <= 0 then
        questLevel = 1
    end
    
    local baseMultiplier
    if self.isRetail then
        baseMultiplier = BASE_XP_PER_LEVEL.retail
    elseif self.isClassic then
        baseMultiplier = BASE_XP_PER_LEVEL.classic
    else
        baseMultiplier = BASE_XP_PER_LEVEL.cata
    end
    
    return math.floor(questLevel * baseMultiplier + 100)
end

function QuestXPOptimizer:GetLevelMultiplier(levelDiff)
    if not levelDiff then return 1.0 end
    
    levelDiff = math.max(-5, math.min(5, levelDiff))
    
    return LEVEL_XP_MULTIPLIER[levelDiff] or 1.0
end

function QuestXPOptimizer:EstimateQuestTime(questID)
    if not questID then return QUEST_TIME_ESTIMATES["default"] end
    
    local objectives = self.API.GetQuestObjectives(questID)
    local totalTime = 0
    local objectiveCount = 0
    
    if objectives and #objectives > 0 then
        for _, objective in ipairs(objectives) do
            objectiveCount = objectiveCount + 1
            local objType = objective.type or "default"
            objType = string.lower(tostring(objType))
            local estimatedTime = QUEST_TIME_ESTIMATES[objType] or QUEST_TIME_ESTIMATES["default"]
            
            if objective.numRequired and objective.numRequired > 1 then
                estimatedTime = estimatedTime * (1 + (objective.numRequired - 1) * 0.25)
            end
            
            if objective.finished then
                estimatedTime = estimatedTime * 0.2
            end
            
            totalTime = totalTime + estimatedTime
        end
    end
    
    if objectiveCount == 0 then
        totalTime = QUEST_TIME_ESTIMATES["default"]
    end
    
    return math.max(totalTime, 1)
end

function QuestXPOptimizer:GetQuestTypeFromObjectives(questID)
    if not questID then return "default" end
    
    local objectives = self.API.GetQuestObjectives(questID)
    if not objectives or #objectives == 0 then
        return "default"
    end
    
    local types = {}
    for _, objective in ipairs(objectives) do
        local objType = string.lower(tostring(objective.type or "default"))
        types[objType] = (types[objType] or 0) + 1
    end
    
    local maxType = "default"
    local maxCount = 0
    for t, count in pairs(types) do
        if count > maxCount then
            maxType = t
            maxCount = count
        end
    end
    
    return maxType
end
