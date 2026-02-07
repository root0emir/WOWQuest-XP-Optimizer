QuestXPOptimizer.combinations = {}

function QuestXPOptimizer:UpdateCombinations()
    self.combinations = {}
    local questsByMap = {}
    
    if not self.activeQuests then
        return
    end
    
    for questID, questData in pairs(self.activeQuests) do
        if questData and questData.mapID then
            local mapID = questData.mapID
            if not questsByMap[mapID] then
                questsByMap[mapID] = {}
            end
            table.insert(questsByMap[mapID], questData)
        end
    end
    
    for mapID, quests in pairs(questsByMap) do
        if #quests >= 2 then
            local combination = self:SafeCall(self.CreateCombination, self, mapID, quests)
            if combination then
                self.combinations[mapID] = combination
            end
        end
    end
end

function QuestXPOptimizer:CreateCombination(mapID, quests)
    if not mapID or not quests or #quests == 0 then
        return nil
    end
    
    local totalXP = 0
    local totalTime = 0
    local questIDs = {}
    
    table.sort(quests, function(a, b)
        local aXPM = (a and a.efficiency and a.efficiency.xpPerMinute) or 0
        local bXPM = (b and b.efficiency and b.efficiency.xpPerMinute) or 0
        return aXPM > bXPM
    end)
    
    for _, quest in ipairs(quests) do
        if quest then
            totalXP = totalXP + (quest.xp or 0)
            totalTime = totalTime + ((quest.efficiency and quest.efficiency.estimatedTime) or 5)
            table.insert(questIDs, quest.questID)
        end
    end
    
    local travelBonus = math.max(0, (#quests - 1) * 1.5)
    local adjustedTime = totalTime - travelBonus
    adjustedTime = math.max(adjustedTime, totalTime * 0.6)
    adjustedTime = math.max(adjustedTime, 1)
    
    local combinedXPPerMinute = totalXP / adjustedTime
    
    return {
        mapID = mapID,
        mapName = self:GetMapName(mapID),
        quests = quests,
        questIDs = questIDs,
        totalXP = totalXP,
        totalTime = adjustedTime,
        originalTime = totalTime,
        timeSaved = totalTime - adjustedTime,
        xpPerMinute = combinedXPPerMinute,
        questCount = #quests,
        efficiency = self:GetEfficiencyRating(combinedXPPerMinute),
        color = self:GetEfficiencyColor(combinedXPPerMinute)
    }
end

function QuestXPOptimizer:GetMapName(mapID)
    if not mapID then return "Unknown" end
    
    local mapInfo = self.API.GetMapInfo(mapID)
    if mapInfo and mapInfo.name then
        return mapInfo.name
    end
    return "Unknown Zone"
end

function QuestXPOptimizer:GetCombinationForQuest(questID)
    if not questID then return nil end
    
    local questData = self.activeQuests and self.activeQuests[questID]
    if not questData or not questData.mapID then
        return nil
    end
    
    return self.combinations and self.combinations[questData.mapID]
end

function QuestXPOptimizer:GetBestCombinations(limit)
    local sorted = {}
    
    if not self.combinations then
        return sorted
    end
    
    for mapID, combination in pairs(self.combinations) do
        if combination then
            table.insert(sorted, combination)
        end
    end
    
    table.sort(sorted, function(a, b)
        local aXPM = (a and a.xpPerMinute) or 0
        local bXPM = (b and b.xpPerMinute) or 0
        return aXPM > bXPM
    end)
    
    if limit and limit < #sorted then
        local result = {}
        for i = 1, limit do
            result[i] = sorted[i]
        end
        return result
    end
    
    return sorted
end

function QuestXPOptimizer:HasCombinationsInZone(mapID)
    return self.combinations and self.combinations[mapID] ~= nil
end

function QuestXPOptimizer:GetQuestsInSameZone(questID)
    if not questID then return {} end
    
    local questData = self.activeQuests and self.activeQuests[questID]
    if not questData or not questData.mapID then
        return {}
    end
    
    local combination = self.combinations and self.combinations[questData.mapID]
    if not combination or not combination.quests then
        return {}
    end
    
    local result = {}
    for _, quest in ipairs(combination.quests) do
        if quest and quest.questID ~= questID then
            table.insert(result, quest)
        end
    end
    
    return result
end
