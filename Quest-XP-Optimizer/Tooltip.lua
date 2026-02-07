local CustomTooltip

local function EnsureTooltip()
    if CustomTooltip then return CustomTooltip end
    
    CustomTooltip = CreateFrame("GameTooltip", "QuestXPOptimizerTooltip", UIParent, "GameTooltipTemplate")
    if CustomTooltip then
        CustomTooltip:SetFrameStrata("TOOLTIP")
        QuestXPOptimizer.tooltip = CustomTooltip
    end
    
    return CustomTooltip
end

function QuestXPOptimizer:ShowQuestTooltip(questID, anchor)
    if not questID or not anchor then return end
    
    local questData = self.activeQuests and self.activeQuests[questID]
    if not questData then return end
    
    local tooltip = EnsureTooltip()
    if not tooltip then return end
    
    tooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    tooltip:ClearLines()
    
    local efficiency = questData.efficiency or self:CreateDefaultEfficiency()
    local colorHex = self:GetEfficiencyColorHex(efficiency.xpPerMinute)
    
    tooltip:AddLine(questData.title or "Unknown Quest", 1, 0.82, 0)
    tooltip:AddLine(" ")
    
    tooltip:AddDoubleLine(
        "XP Reward:", 
        colorHex .. self:FormatXP(questData.xp) .. " XP|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "Est. Time:", 
        self:FormatTime(efficiency.estimatedTime), 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "XP/Minute:", 
        colorHex .. string.format("%.1f", efficiency.xpPerMinute or 0) .. "|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "Efficiency:", 
        colorHex .. self:GetEfficiencyStars(efficiency.xpPerMinute) .. "|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    
    if questData.isComplete then
        tooltip:AddLine(" ")
        tooltip:AddLine("✓ READY TO TURN IN", 0, 1, 0)
    end
    
    local sameZoneQuests = self:GetQuestsInSameZone(questID)
    if sameZoneQuests and #sameZoneQuests > 0 then
        tooltip:AddLine(" ")
        tooltip:AddLine("Same Zone Quests:", 0, 0.8, 1)
        
        for _, quest in ipairs(sameZoneQuests) do
            if quest then
                local qEfficiency = quest.efficiency or self:CreateDefaultEfficiency()
                local qColorHex = self:GetEfficiencyColorHex(qEfficiency.xpPerMinute)
                tooltip:AddDoubleLine(
                    "  " .. (quest.title or "Unknown"),
                    qColorHex .. self:FormatXP(quest.xp) .. " XP|r",
                    0.8, 0.8, 0.8,
                    1, 1, 1
                )
            end
        end
        
        local combination = self:GetCombinationForQuest(questID)
        if combination then
            tooltip:AddLine(" ")
            tooltip:AddLine("Combined Route:", 1, 0.82, 0)
            local combColorHex = self:GetEfficiencyColorHex(combination.xpPerMinute)
            tooltip:AddDoubleLine(
                "Total XP:", 
                combColorHex .. self:FormatXP(combination.totalXP) .. "|r", 
                0.7, 0.7, 0.7, 1, 1, 1
            )
            tooltip:AddDoubleLine(
                "Total Time:", 
                self:FormatTime(combination.totalTime), 
                0.7, 0.7, 0.7, 1, 1, 1
            )
            tooltip:AddDoubleLine(
                "Time Saved:", 
                "|cff00ff00" .. self:FormatTime(combination.timeSaved) .. "|r", 
                0.7, 0.7, 0.7, 1, 1, 1
            )
            tooltip:AddDoubleLine(
                "Combined XP/Min:", 
                combColorHex .. string.format("%.1f", combination.xpPerMinute or 0) .. "|r", 
                0.7, 0.7, 0.7, 1, 1, 1
            )
        end
    end
    
    tooltip:Show()
end

function QuestXPOptimizer:HideQuestTooltip()
    if CustomTooltip then
        CustomTooltip:Hide()
    end
end

function QuestXPOptimizer:ShowCombinationTooltip(mapID, anchor)
    if not mapID or not anchor then return end
    
    local combination = self.combinations and self.combinations[mapID]
    if not combination then return end
    
    local tooltip = EnsureTooltip()
    if not tooltip then return end
    
    tooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    tooltip:ClearLines()
    
    local colorHex = self:GetEfficiencyColorHex(combination.xpPerMinute)
    tooltip:AddLine((combination.mapName or "Unknown") .. " - Quest Route", 1, 0.82, 0)
    tooltip:AddLine(" ")
    
    tooltip:AddDoubleLine("Quests:", tostring(combination.questCount or 0), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine(
        "Total XP:", 
        colorHex .. self:FormatXP(combination.totalXP) .. "|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "Est. Time:", 
        self:FormatTime(combination.totalTime), 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "Time Saved:", 
        "|cff00ff00" .. self:FormatTime(combination.timeSaved) .. "|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    tooltip:AddDoubleLine(
        "XP/Minute:", 
        colorHex .. string.format("%.1f", combination.xpPerMinute or 0) .. "|r", 
        0.7, 0.7, 0.7, 1, 1, 1
    )
    
    if combination.quests and #combination.quests > 0 then
        tooltip:AddLine(" ")
        tooltip:AddLine("Quests in Route:", 0, 0.8, 1)
        
        for i, quest in ipairs(combination.quests) do
            if quest then
                local qEfficiency = quest.efficiency or self:CreateDefaultEfficiency()
                local qColorHex = self:GetEfficiencyColorHex(qEfficiency.xpPerMinute)
                local status = quest.isComplete and "|cff00ff00✓|r " or (tostring(i) .. ". ")
                tooltip:AddDoubleLine(
                    status .. (quest.title or "Unknown"),
                    qColorHex .. self:FormatXP(quest.xp) .. " XP|r",
                    0.8, 0.8, 0.8,
                    1, 1, 1
                )
            end
        end
    end
    
    tooltip:Show()
end
