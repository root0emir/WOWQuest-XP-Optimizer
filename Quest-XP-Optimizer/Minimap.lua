QuestXPOptimizer.minimapIcons = {}
QuestXPOptimizer.minimapInitialized = false

local MinimapIconPool = {}

local function CreateMinimapIcon()
    if not Minimap then return nil end
    
    local icon = CreateFrame("Frame", nil, Minimap)
    icon:SetSize(24, 24)
    icon:SetFrameStrata("HIGH")
    icon:SetFrameLevel(100)
    
    icon.background = icon:CreateTexture(nil, "BACKGROUND")
    icon.background:SetAllPoints()
    icon.background:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background")
    icon.background:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    icon.border = icon:CreateTexture(nil, "BORDER")
    icon.border:SetSize(28, 28)
    icon.border:SetPoint("CENTER")
    icon.border:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")
    
    icon.xpText = icon:CreateFontString(nil, "OVERLAY")
    icon.xpText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    icon.xpText:SetPoint("CENTER", 0, 0)
    icon.xpText:SetTextColor(1, 1, 1)
    
    icon.efficiencyDot = icon:CreateTexture(nil, "OVERLAY")
    icon.efficiencyDot:SetSize(6, 6)
    icon.efficiencyDot:SetPoint("TOPRIGHT", -2, -2)
    icon.efficiencyDot:SetColorTexture(0, 1, 0, 1)
    
    icon:EnableMouse(true)
    icon:SetScript("OnEnter", function(self)
        if self.questID then
            QuestXPOptimizer:ShowQuestTooltip(self.questID, self)
        end
    end)
    icon:SetScript("OnLeave", function(self)
        QuestXPOptimizer:HideQuestTooltip()
    end)
    
    return icon
end

local function AcquireMinimapIcon()
    local icon = table.remove(MinimapIconPool)
    if not icon then icon = CreateMinimapIcon() end
    if icon then icon:Show() end
    return icon
end

local function ReleaseMinimapIcon(icon)
    if icon then
        icon:Hide()
        icon:ClearAllPoints()
        icon.questID = nil
        table.insert(MinimapIconPool, icon)
    end
end

function QuestXPOptimizer:InitializeMinimap()
    if self.minimapInitialized or not Minimap then return end
    
    self.minimapUpdateFrame = CreateFrame("Frame")
    self.minimapUpdateFrame.elapsed = 0
    self.minimapUpdateFrame:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed >= 0.5 then
            frame.elapsed = 0
            if QuestXPOptimizerDB and QuestXPOptimizerDB.showMinimap then
                QuestXPOptimizer:SafeCall(QuestXPOptimizer.UpdateMinimapIconPositions, QuestXPOptimizer)
            end
        end
    end)
    
    self.minimapInitialized = true
end

function QuestXPOptimizer:RefreshMinimapIcons()
    self:ClearMinimapIcons()
    if not QuestXPOptimizerDB or not QuestXPOptimizerDB.showMinimap then return end
    
    local _, _, playerMapID = self:GetPlayerMapPosition()
    if not playerMapID or not self.activeQuests then return end
    
    local nearby = self:GetNearbyQuests(playerMapID)
    for _, questData in ipairs(nearby) do
        if questData then self:CreateMinimapQuestIcon(questData) end
    end
end

function QuestXPOptimizer:GetPlayerMapPosition()
    local mapID = self.API.GetBestMapForUnit("player")
    if not mapID then return nil, nil, nil end
    local pos = self.API.GetPlayerMapPosition(mapID, "player")
    if pos then return pos.x, pos.y, mapID end
    return nil, nil, mapID
end

function QuestXPOptimizer:GetNearbyQuests(mapID)
    local nearby = {}
    for _, qd in pairs(self.activeQuests or {}) do
        if qd and qd.mapID == mapID then table.insert(nearby, qd) end
    end
    table.sort(nearby, function(a, b)
        return ((a.efficiency and a.efficiency.xpPerMinute) or 0) > ((b.efficiency and b.efficiency.xpPerMinute) or 0)
    end)
    local result = {}
    for i = 1, math.min(5, #nearby) do result[i] = nearby[i] end
    return result
end

function QuestXPOptimizer:CreateMinimapQuestIcon(questData)
    if not questData then return end
    local icon = AcquireMinimapIcon()
    if not icon then return end
    
    icon.questID = questData.questID
    icon.xpText:SetText(self:FormatXPShort(questData.xp))
    
    local eff = questData.efficiency or {color = {r=1,g=0,b=0}}
    local c = eff.color or {r=1,g=0,b=0}
    icon.efficiencyDot:SetColorTexture(c.r or 1, c.g or 0, c.b or 0, 1)
    icon.background:SetVertexColor(questData.isComplete and 0 or 0.1, questData.isComplete and 0.4 or 0.1, questData.isComplete and 0 or 0.1, 0.8)
    
    table.insert(self.minimapIcons, icon)
    self:PositionMinimapIcon(icon, #self.minimapIcons)
end

function QuestXPOptimizer:FormatXPShort(xp)
    if not xp then return "0" end
    return xp >= 1000 and string.format("%.0fK", xp/1000) or tostring(math.floor(xp))
end

function QuestXPOptimizer:PositionMinimapIcon(icon, index)
    if not icon or not Minimap or not self.minimapIcons then return end
    local total = math.max(#self.minimapIcons, 1)
    local angle = (index - 1) * (360 / total)
    local rad = math.rad(angle - 90)
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 45, math.sin(rad) * 45)
end

function QuestXPOptimizer:UpdateMinimapIconPositions()
    for i, icon in ipairs(self.minimapIcons or {}) do
        if icon then self:PositionMinimapIcon(icon, i) end
    end
end

function QuestXPOptimizer:ClearMinimapIcons()
    for _, icon in ipairs(self.minimapIcons or {}) do ReleaseMinimapIcon(icon) end
    self.minimapIcons = {}
end
