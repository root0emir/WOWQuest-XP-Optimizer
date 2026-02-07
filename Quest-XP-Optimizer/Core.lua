QuestXPOptimizer = QuestXPOptimizer or {}
QuestXPOptimizer.version = "1.1.0"
QuestXPOptimizer.activeQuests = {}
QuestXPOptimizer.questData = {}
QuestXPOptimizer.initialized = false

local frame = CreateFrame("Frame", "QuestXPOptimizerFrame", UIParent)
frame.timeSinceLastUpdate = 0
frame.updateInterval = 1.0

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "QuestXPOptimizer" then
            QuestXPOptimizerDB = QuestXPOptimizerDB or {
                enabled = true,
                showWorldMap = true,
                showMinimap = true,
                debug = false
            }
            QuestXPOptimizer:SafeCall(QuestXPOptimizer.Initialize, QuestXPOptimizer)
        end
    elseif not QuestXPOptimizer.initialized then
        return
    elseif event == "QUEST_LOG_UPDATE" or 
           event == "QUEST_ACCEPTED" or 
           event == "QUEST_REMOVED" or
           event == "QUEST_TURNED_IN" or
           event == "PLAYER_LEVEL_UP" or
           event == "ZONE_CHANGED_NEW_AREA" then
        QuestXPOptimizer:SafeCall(QuestXPOptimizer.UpdateQuestData, QuestXPOptimizer)
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", OnEvent)

function QuestXPOptimizer:Initialize()
    if self.initialized then return end
    
    self:Debug("Initializing addon...")
    
    local success = self:UpdateQuestData()
    if not success then
        self:Debug("Initial quest data update failed, will retry")
    end
    
    if self.API.HasWorldMap and QuestXPOptimizerDB.showWorldMap then
        self:SafeCall(self.InitializeWorldMap, self)
    end
    
    if QuestXPOptimizerDB.showMinimap then
        self:SafeCall(self.InitializeMinimap, self)
    end
    
    self:RegisterSlashCommands()
    
    self.initialized = true
    print("|cff00ff00[Quest XP Optimizer]|r v" .. self.version .. " loaded! Type |cff888888/qxo|r for options.")
end

function QuestXPOptimizer:RegisterSlashCommands()
    SLASH_QUESTXPOPTIMIZER1 = "/qxo"
    SLASH_QUESTXPOPTIMIZER2 = "/questxp"
    SlashCmdList["QUESTXPOPTIMIZER"] = function(msg)
        local cmd = string.lower(msg or "")
        if cmd == "debug" then
            QuestXPOptimizerDB.debug = not QuestXPOptimizerDB.debug
            print("|cff00ff00[QXO]|r Debug mode: " .. (QuestXPOptimizerDB.debug and "ON" or "OFF"))
        elseif cmd == "refresh" then
            self:UpdateQuestData()
            print("|cff00ff00[QXO]|r Quest data refreshed!")
        elseif cmd == "minimap" then
            QuestXPOptimizerDB.showMinimap = not QuestXPOptimizerDB.showMinimap
            print("|cff00ff00[QXO]|r Minimap icons: " .. (QuestXPOptimizerDB.showMinimap and "ON" or "OFF"))
            if QuestXPOptimizerDB.showMinimap then
                self:RefreshMinimapIcons()
            else
                self:ClearMinimapIcons()
            end
        elseif cmd == "map" then
            QuestXPOptimizerDB.showWorldMap = not QuestXPOptimizerDB.showWorldMap
            print("|cff00ff00[QXO]|r World map overlays: " .. (QuestXPOptimizerDB.showWorldMap and "ON" or "OFF"))
            if QuestXPOptimizerDB.showWorldMap then
                self:RefreshMapOverlays()
            else
                self:ClearMapOverlays()
            end
        elseif cmd == "status" then
            self:PrintStatus()
        else
            print("|cff00ff00[Quest XP Optimizer]|r Commands:")
            print("  |cff888888/qxo debug|r - Toggle debug mode")
            print("  |cff888888/qxo refresh|r - Refresh quest data")
            print("  |cff888888/qxo minimap|r - Toggle minimap icons")
            print("  |cff888888/qxo map|r - Toggle world map overlays")
            print("  |cff888888/qxo status|r - Show current status")
        end
    end
end

function QuestXPOptimizer:PrintStatus()
    local questCount = 0
    for _ in pairs(self.activeQuests) do
        questCount = questCount + 1
    end
    
    local comboCount = 0
    for _ in pairs(self.combinations or {}) do
        comboCount = comboCount + 1
    end
    
    print("|cff00ff00[Quest XP Optimizer]|r Status:")
    print("  Version: " .. self.version)
    print("  Client: " .. (self.isRetail and "Retail" or (self.isClassic and "Classic" or "Cataclysm")))
    print("  Active Quests: " .. questCount)
    print("  Zone Combos: " .. comboCount)
    print("  World Map: " .. (QuestXPOptimizerDB.showWorldMap and "ON" or "OFF"))
    print("  Minimap: " .. (QuestXPOptimizerDB.showMinimap and "ON" or "OFF"))
end

function QuestXPOptimizer:UpdateQuestData()
    self.activeQuests = {}
    
    local numEntries = self.API.GetNumQuestLogEntries()
    if not numEntries or numEntries == 0 then
        self:Debug("No quest log entries found")
        return false
    end
    
    for i = 1, numEntries do
        local info = self.API.GetQuestInfo(i)
        if info and not info.isHeader and not info.isHidden then
            local questID = info.questID
            if questID then
                local xp = self:SafeCall(self.GetQuestXP, self, questID) or 0
                local efficiency = self:SafeCall(self.CalculateEfficiency, self, questID, xp) or {
                    xpPerMinute = 0,
                    estimatedTime = 5,
                    rating = "LOW",
                    color = {r = 1, g = 0, b = 0}
                }
                local mapID = self:SafeCall(self.GetQuestMapID, self, questID)
                
                self.activeQuests[questID] = {
                    questID = questID,
                    title = info.title or "Unknown Quest",
                    level = info.level or 0,
                    xp = xp,
                    efficiency = efficiency,
                    mapID = mapID,
                    isComplete = self.API.IsComplete(questID) or false
                }
            end
        end
    end
    
    self:SafeCall(self.UpdateCombinations, self)
    self:SafeCall(self.RefreshMapOverlays, self)
    self:SafeCall(self.RefreshMinimapIcons, self)
    
    return true
end

function QuestXPOptimizer:GetQuestMapID(questID)
    if not questID then return nil end
    
    local mapID = self.API.GetQuestUiMapID(questID)
    if mapID and mapID > 0 then
        return mapID
    end
    
    return nil
end
