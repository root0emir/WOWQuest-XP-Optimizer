# Quest XP Optimizer

A World of Warcraft addon that displays quest XP rewards on the world map and minimap, calculates XP efficiency (XP/minute), and suggests optimal quest combinations for maximum leveling speed.

## Features

###  World Map XP Display
- Shows XP reward directly on quest markers
- Color-coded efficiency indicators (green = high, red = low)
- Hover for detailed tooltip with all quest information

###  XP Efficiency Calculator
- Calculates XP per minute based on quest objectives
- Star rating system (★★★★★) for quick visual assessment
- Accounts for quest completion progress

###  Quest Combination Suggestions
- Groups quests in the same zone for efficient routing
- Calculates time saved by combining quests
- Shows combined XP/minute for grouped quests

###  Minimap Integration
- Displays top 5 nearby quests with XP values
- Efficiency dot indicator on each icon
- Completed quests highlighted in green

## Installation

1. Download the latest release
2. Extract `QuestXPOptimizer` folder
3. Copy to your WoW AddOns directory:
   - **Retail:** `World of Warcraft\_retail_\Interface\AddOns\`
   - **Classic:** `World of Warcraft\_classic_era_\Interface\AddOns\`
   - **Cataclysm:** `World of Warcraft\_classic_\Interface\AddOns\`
4. Restart WoW or `/reload`

## Slash Commands

| Command | Description |
|---------|-------------|
| `/qxo` | Show help menu |
| `/qxo debug` | Toggle debug mode |
| `/qxo refresh` | Refresh quest data |
| `/qxo minimap` | Toggle minimap icons |
| `/qxo map` | Toggle world map overlays |
| `/qxo status` | Show current status |

## Color Coding

| Color | XP/Minute | Rating |
|-------|-----------|--------|
| 🟢 Bright Green | 200+ | Excellent |
| 🟢 Green | 150+ | High |
| 🟡 Yellow-Green | 115+ | Medium-High |
| 🟡 Yellow | 80+ | Medium |
| 🟠 Orange | 40+ | Medium-Low |
| 🔴 Red | <40 | Low |

## Compatibility

-  WoW Retail (Dragonflight, The War Within)
-  WoW Classic Era
- WoW Classic Cataclysm