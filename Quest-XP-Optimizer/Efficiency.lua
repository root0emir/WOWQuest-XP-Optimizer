local EFFICIENCY_THRESHOLDS = {
    EXCELLENT = 200,
    HIGH = 150,
    MEDIUM = 80,
    LOW = 40
}

local EFFICIENCY_COLORS = {
    EXCELLENT = {r = 0.0, g = 1.0, b = 0.5},
    HIGH = {r = 0.0, g = 1.0, b = 0.0},
    MEDIUM_HIGH = {r = 0.5, g = 1.0, b = 0.0},
    MEDIUM = {r = 1.0, g = 1.0, b = 0.0},
    MEDIUM_LOW = {r = 1.0, g = 0.5, b = 0.0},
    LOW = {r = 1.0, g = 0.0, b = 0.0}
}

function QuestXPOptimizer:CalculateEfficiency(questID, xp)
    if not questID then
        return self:CreateDefaultEfficiency()
    end
    
    xp = xp or 0
    local time = self:EstimateQuestTime(questID)
    if not time or time <= 0 then
        time = 1
    end
    
    local xpPerMinute = xp / time
    
    return {
        xpPerMinute = xpPerMinute,
        estimatedTime = time,
        rating = self:GetEfficiencyRating(xpPerMinute),
        color = self:GetEfficiencyColor(xpPerMinute)
    }
end

function QuestXPOptimizer:CreateDefaultEfficiency()
    return {
        xpPerMinute = 0,
        estimatedTime = 5,
        rating = "LOW",
        color = EFFICIENCY_COLORS.LOW
    }
end

function QuestXPOptimizer:GetEfficiencyRating(xpPerMinute)
    if not xpPerMinute then return "LOW" end
    
    if xpPerMinute >= EFFICIENCY_THRESHOLDS.EXCELLENT then
        return "EXCELLENT"
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.HIGH then
        return "HIGH"
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.MEDIUM then
        return "MEDIUM"
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.LOW then
        return "LOW"
    else
        return "VERY_LOW"
    end
end

function QuestXPOptimizer:GetEfficiencyColor(xpPerMinute)
    if not xpPerMinute then return EFFICIENCY_COLORS.LOW end
    
    if xpPerMinute >= EFFICIENCY_THRESHOLDS.EXCELLENT then
        return EFFICIENCY_COLORS.EXCELLENT
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.HIGH then
        return EFFICIENCY_COLORS.HIGH
    elseif xpPerMinute >= (EFFICIENCY_THRESHOLDS.HIGH + EFFICIENCY_THRESHOLDS.MEDIUM) / 2 then
        return EFFICIENCY_COLORS.MEDIUM_HIGH
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.MEDIUM then
        return EFFICIENCY_COLORS.MEDIUM
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.LOW then
        return EFFICIENCY_COLORS.MEDIUM_LOW
    else
        return EFFICIENCY_COLORS.LOW
    end
end

function QuestXPOptimizer:GetEfficiencyColorHex(xpPerMinute)
    local color = self:GetEfficiencyColor(xpPerMinute)
    if not color then
        color = EFFICIENCY_COLORS.LOW
    end
    return string.format("|cff%02x%02x%02x", 
        math.floor((color.r or 1) * 255), 
        math.floor((color.g or 0) * 255), 
        math.floor((color.b or 0) * 255))
end

function QuestXPOptimizer:GetEfficiencyStars(xpPerMinute)
    if not xpPerMinute then return "★☆☆☆☆" end
    
    if xpPerMinute >= EFFICIENCY_THRESHOLDS.EXCELLENT then
        return "★★★★★"
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.HIGH then
        return "★★★★☆"
    elseif xpPerMinute >= (EFFICIENCY_THRESHOLDS.HIGH + EFFICIENCY_THRESHOLDS.MEDIUM) / 2 then
        return "★★★☆☆"
    elseif xpPerMinute >= EFFICIENCY_THRESHOLDS.MEDIUM then
        return "★★☆☆☆"
    else
        return "★☆☆☆☆"
    end
end

function QuestXPOptimizer:FormatXP(xp)
    if not xp then return "0" end
    
    if xp >= 1000000 then
        return string.format("%.1fM", xp / 1000000)
    elseif xp >= 1000 then
        return string.format("%.1fK", xp / 1000)
    else
        return tostring(math.floor(xp))
    end
end

function QuestXPOptimizer:FormatTime(minutes)
    if not minutes then return "0m" end
    
    minutes = math.max(0, minutes)
    
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        local mins = math.floor(minutes % 60)
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", math.floor(minutes))
    end
end
