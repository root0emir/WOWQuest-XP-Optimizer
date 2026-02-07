QuestXPOptimizer.mapOverlays = {}
QuestXPOptimizer.worldMapInitialized = false

local MapOverlayPool = {}

local function CreateMapOverlay()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer or not WorldMapFrame.ScrollContainer.Child then
        return nil
    end
    
    local overlay = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
    overlay:SetSize(50, 20)
    overlay:SetFrameStrata("HIGH")
    
    overlay.background = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.background:SetAllPoints()
    overlay.background:SetColorTexture(0, 0, 0, 0.7)
    
    overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.text:SetPoint("CENTER")
    overlay.text:SetTextColor(1, 1, 1)
    
    overlay.efficiency = overlay:CreateTexture(nil, "ARTWORK")
    overlay.efficiency:SetSize(8, 8)
    overlay.efficiency:SetPoint("LEFT", overlay, "LEFT", 3, 0)
    overlay.efficiency:SetColorTexture(0, 1, 0, 1)
    
    overlay:EnableMouse(true)
    overlay:SetScript("OnEnter", function(self)
        if self.questID then
            QuestXPOptimizer:ShowQuestTooltip(self.questID, self)
        end
    end)
    overlay:SetScript("OnLeave", function(self)
        QuestXPOptimizer:HideQuestTooltip()
    end)
    
    return overlay
end

local function AcquireOverlay()
    local overlay = table.remove(MapOverlayPool)
    if not overlay then
        overlay = CreateMapOverlay()
    end
    if overlay then
        overlay:Show()
    end
    return overlay
end

local function ReleaseOverlay(overlay)
    if overlay then
        overlay:Hide()
        overlay:ClearAllPoints()
        overlay.questID = nil
        table.insert(MapOverlayPool, overlay)
    end
end

function QuestXPOptimizer:InitializeWorldMap()
    if self.worldMapInitialized then return end
    if not WorldMapFrame then
        self:Debug("WorldMapFrame not available")
        return
    end
    
    if WorldMapFrame.OnMapChanged then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            if QuestXPOptimizerDB and QuestXPOptimizerDB.showWorldMap then
                QuestXPOptimizer:SafeCall(QuestXPOptimizer.RefreshMapOverlays, QuestXPOptimizer)
            end
        end)
    end
    
    WorldMapFrame:HookScript("OnShow", function()
        if QuestXPOptimizerDB and QuestXPOptimizerDB.showWorldMap then
            QuestXPOptimizer:SafeCall(QuestXPOptimizer.RefreshMapOverlays, QuestXPOptimizer)
        end
    end)
    
    WorldMapFrame:HookScript("OnHide", function()
        QuestXPOptimizer:SafeCall(QuestXPOptimizer.ClearMapOverlays, QuestXPOptimizer)
    end)
    
    self.worldMapInitialized = true
    self:Debug("World map initialized")
end

function QuestXPOptimizer:RefreshMapOverlays()
    self:ClearMapOverlays()
    
    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        return
    end
    
    if not QuestXPOptimizerDB or not QuestXPOptimizerDB.showWorldMap then
        return
    end
    
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then
        return
    end
    
    if not self.activeQuests then
        return
    end
    
    for questID, questData in pairs(self.activeQuests) do
        if questData and questData.mapID == mapID then
            self:SafeCall(self.CreateQuestOverlay, self, questID, questData)
        end
    end
end

function QuestXPOptimizer:CreateQuestOverlay(questID, questData)
    if not questID or not questData then return end
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer or not WorldMapFrame.ScrollContainer.Child then
        return
    end
    
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then return end
    
    local questsOnMap = self.API.GetQuestsOnMap(mapID)
    if not questsOnMap then return end
    
    for _, questPOI in ipairs(questsOnMap) do
        if questPOI and questPOI.questID == questID then
            local overlay = AcquireOverlay()
            if not overlay then return end
            
            overlay.questID = questID
            
            local x = questPOI.x or 0.5
            local y = questPOI.y or 0.5
            
            local child = WorldMapFrame.ScrollContainer.Child
            local mapWidth = child:GetWidth() or 1
            local mapHeight = child:GetHeight() or 1
            
            overlay:SetPoint("CENTER", child, "TOPLEFT", x * mapWidth, -y * mapHeight + 15)
            
            local efficiency = questData.efficiency or self:CreateDefaultEfficiency()
            local color = efficiency.color or {r = 1, g = 0, b = 0}
            overlay.efficiency:SetColorTexture(color.r or 1, color.g or 0, color.b or 0, 1)
            
            local xpText = self:FormatXP(questData.xp)
            local colorHex = self:GetEfficiencyColorHex(efficiency.xpPerMinute)
            overlay.text:SetText(colorHex .. xpText .. " XP|r")
            
            local textWidth = overlay.text:GetStringWidth() or 50
            overlay:SetWidth(textWidth + 20)
            
            table.insert(self.mapOverlays, overlay)
            break
        end
    end
end

function QuestXPOptimizer:ClearMapOverlays()
    if self.mapOverlays then
        for _, overlay in ipairs(self.mapOverlays) do
            ReleaseOverlay(overlay)
        end
    end
    self.mapOverlays = {}
end
