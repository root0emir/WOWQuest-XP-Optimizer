QuestXPOptimizer = QuestXPOptimizer or {}

local _, _, _, tocVersion = GetBuildInfo()

QuestXPOptimizer.isRetail = tocVersion >= 100000
QuestXPOptimizer.isClassic = tocVersion < 40000
QuestXPOptimizer.isCata = tocVersion >= 40000 and tocVersion < 100000

QuestXPOptimizer.API = {}

if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
    QuestXPOptimizer.API.GetNumQuestLogEntries = function()
        return C_QuestLog.GetNumQuestLogEntries()
    end
    QuestXPOptimizer.API.GetQuestInfo = function(index)
        return C_QuestLog.GetInfo(index)
    end
    QuestXPOptimizer.API.GetLogIndexForQuestID = function(questID)
        return C_QuestLog.GetLogIndexForQuestID(questID)
    end
    QuestXPOptimizer.API.IsComplete = function(questID)
        return C_QuestLog.IsComplete(questID)
    end
    QuestXPOptimizer.API.GetQuestObjectives = function(questID)
        return C_QuestLog.GetQuestObjectives(questID)
    end
    QuestXPOptimizer.API.GetQuestsOnMap = function(mapID)
        return C_QuestLog.GetQuestsOnMap(mapID)
    end
else
    QuestXPOptimizer.API.GetNumQuestLogEntries = function()
        local numEntries, numQuests = GetNumQuestLogEntries()
        return numEntries
    end
    QuestXPOptimizer.API.GetQuestInfo = function(index)
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(index)
        if not title then return nil end
        return {
            title = title,
            level = level,
            isHeader = isHeader,
            isHidden = false,
            questID = questID
        }
    end
    QuestXPOptimizer.API.GetLogIndexForQuestID = function(questID)
        local numEntries = GetNumQuestLogEntries()
        for i = 1, numEntries do
            local _, _, _, _, _, _, _, qID = GetQuestLogTitle(i)
            if qID == questID then
                return i
            end
        end
        return nil
    end
    QuestXPOptimizer.API.IsComplete = function(questID)
        local index = QuestXPOptimizer.API.GetLogIndexForQuestID(questID)
        if index then
            local _, _, _, _, _, isComplete = GetQuestLogTitle(index)
            return isComplete
        end
        return false
    end
    QuestXPOptimizer.API.GetQuestObjectives = function(questID)
        local index = QuestXPOptimizer.API.GetLogIndexForQuestID(questID)
        if not index then return nil end
        local oldSelection = GetQuestLogSelection()
        SelectQuestLogEntry(index)
        local numObjectives = GetNumQuestLeaderBoards(index)
        local objectives = {}
        for i = 1, numObjectives do
            local text, objType, finished = GetQuestLogLeaderBoard(i, index)
            table.insert(objectives, {
                text = text,
                type = objType,
                finished = finished,
                numRequired = 1
            })
        end
        SelectQuestLogEntry(oldSelection)
        return objectives
    end
    QuestXPOptimizer.API.GetQuestsOnMap = function(mapID)
        return nil
    end
end

if C_Map and C_Map.GetMapInfo then
    QuestXPOptimizer.API.GetMapInfo = function(mapID)
        return C_Map.GetMapInfo(mapID)
    end
    QuestXPOptimizer.API.GetBestMapForUnit = function(unit)
        return C_Map.GetBestMapForUnit(unit)
    end
    QuestXPOptimizer.API.GetPlayerMapPosition = function(mapID, unit)
        return C_Map.GetPlayerMapPosition(mapID, unit)
    end
else
    QuestXPOptimizer.API.GetMapInfo = function(mapID)
        local name = GetMapNameByID and GetMapNameByID(mapID) or "Unknown"
        return { name = name }
    end
    QuestXPOptimizer.API.GetBestMapForUnit = function(unit)
        SetMapToCurrentZone()
        return GetCurrentMapAreaID()
    end
    QuestXPOptimizer.API.GetPlayerMapPosition = function(mapID, unit)
        local x, y = GetPlayerMapPosition(unit)
        if x and y and (x > 0 or y > 0) then
            return { x = x, y = y }
        end
        return nil
    end
end

if GetQuestLogRewardXP then
    QuestXPOptimizer.API.GetQuestLogRewardXP = GetQuestLogRewardXP
else
    QuestXPOptimizer.API.GetQuestLogRewardXP = function(questID)
        return 0
    end
end

if GetQuestUiMapID then
    QuestXPOptimizer.API.GetQuestUiMapID = GetQuestUiMapID
else
    QuestXPOptimizer.API.GetQuestUiMapID = function(questID)
        return nil
    end
end

QuestXPOptimizer.API.HasWorldMap = WorldMapFrame ~= nil

function QuestXPOptimizer:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        if QuestXPOptimizerDB and QuestXPOptimizerDB.debug then
            print("|cffff0000[QuestXPOptimizer Error]|r " .. tostring(result))
        end
        return nil
    end
    return result
end

function QuestXPOptimizer:Debug(message)
    if QuestXPOptimizerDB and QuestXPOptimizerDB.debug then
        print("|cff888888[QXO Debug]|r " .. tostring(message))
    end
end
