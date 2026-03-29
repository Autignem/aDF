-- Module: data.lua
-- Purpose: central static data for tracked debuffs and armor mapping.
-- Exports: aDFSpells, aDFDebuffs, aDFArmorVals, aDFOrder.
-- Depends on: none.
-- Used by: logic/aura.lua, logic/update.lua, logic/sort.lua, ui/options_shell.lua.

-- ==== DATA TABLES: SPELLS AND DEBUFFS ==== Esta es la tabla de datos de debuffs

-- Translation table for debuff check on target

aDFSpells = {

	--armor

	["Expose Armor"] = "Expose Armor",
	["Sunder Armor"] = "Sunder Armor",
	["Curse of Recklessness"] = "Curse of Recklessness",
	["Faerie Fire"] = {"Faerie Fire", "Faerie Fire (Feral)"},
	["Decaying Flesh"] = "Decaying Flesh", --x3=400
	["Feast of Hakkar"] = "Feast of Hakkar", --400
	["Cleave Armor"] = "Cleave Armor", --300
	["Shattered Armor"] = "Shattered Armor", --250
	["Holy Sunder"] = "Holy Sunder", --50

	--resistance

	["Curse of Shadows"] = "Curse of Shadow",
	["Curse of the Elements"] = "Curse of the Elements",
	["Fire Vulnerability"] = "Fire Vulnerability",
	["Shadow Weaving"] = "Shadow Weaving",
	["Shadow Vulnerability"] = "Shadow Vulnerability", --lock talent

	--Utility

	["Judgement of Wisdom"] = "Judgement of Wisdom",
	["Nightfall"] = "Spell Vulnerability",
	["Gift of Arthas"] = "Gift of Arthas", --arthas gift
	["Flame Buffet"] = "Flame Buffet", --arcanite dragon/fire buff
	["Elune's Twilight"] = "Elune's Twilight", -- will add
	["Judgement of the Crusader"] = "Judgement of the Crusader", -- crusader
	["Crooked Claw"] = "Crooked Claw", --scythe pet 2% melee

	--damage

	--other
	
	["Demoralizing Shout"] = {"Demoralizing Shout", "Demoralizing Roar"}, --need testing
	["Thunder Clap"] = {"Thunder Clap","Thunderfury", "Frigid Blast"}, --need testing
}

-- Table with debuff names and their icon textures

aDFDebuffs = {

	--armor

	["Expose Armor"] = "Interface\\Icons\\Ability_Warrior_Riposte",
	["Sunder Armor"] = "Interface\\Icons\\Ability_Warrior_Sunder",
	["Faerie Fire"] = "Interface\\Icons\\Spell_Nature_FaerieFire",
	["Curse of Recklessness"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
	["Shattered Armor"] = "Interface\\Icons\\INV_Demonaxe", --400
	["Cleave Armor"] = "Interface\\Icons\\Ability_Warrior_Savageblow", --300
	["Feast of Hakkar"] = "Interface\\Icons\\Spell_Shadow_Bloodboil", --250
	["Holy Sunder"] = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", --50

	--resistance

	["Curse of Shadows"] = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
	["Curse of the Elements"] = "Interface\\Icons\\Spell_Shadow_ChillTouch",
	["Shadow Weaving"] = "Interface\\Icons\\Spell_Shadow_BlackPlague",
	["Fire Vulnerability"] = "Interface\\Icons\\Spell_Fire_SoulBurn",
	["Shadow Vulnerability"] = "Interface\\Icons\\Spell_Shadow_ShadowBolt", --lock talent

	--spells

	["Nightfall"] = "Interface\\Icons\\Spell_Holy_ElunesGrace",
	["Flame Buffet"] = "Interface\\Icons\\Spell_Fire_Fireball",
	["Decaying Flesh"] = "Interface\\Icons\\Spell_Shadow_Lifedrain",
	["Judgement of Wisdom"] = "Interface\\Icons\\Spell_Holy_RighteousnessAura",
	["Judgement of the Crusader"] = "Interface\\Icons\\Spell_Holy_Holysmite", -- crusader
	["Gift of Arthas"] = "Interface\\Icons\\Spell_Nature_NullifyDisease", --arthas gift
	["Crooked Claw"] = "Interface\\Icons\\Ability_Druid_Rake", --scythe pet 2% melee

	--damage

	--other
	
	["Demoralizing Shout"] = "Interface\\Icons\\Ability_Warrior_WarCry", --reduction melee attack
	["Thunder Clap"] = "Interface\\Icons\\Spell_Nature_Cyclone", --slow attack. Use Thunder Clap, Thunderfury or Frigid Blast this icon
}

-- ==== DATA TABLE: ARMOR VALUES ====

-- Armor reduction values by damage amount (identifies which debuff was applied)

aDFArmorVals = {
	[90]   = "Sunder Armor x1", -- r1 x1
	[180]  = "Sunder Armor",    -- r2 x1, or r1 x2
	[270]  = "Sunder Armor",    -- r3 x1, or r1 x3
	[540]  = "Sunder Armor",    -- r3 x2, or r2 x3
	[810]  = "Sunder Armor x3", -- r3 x3
	[360]  = "Sunder Armor",    -- r4 x1, or r1 x4 or r2 x2
	[720]  = "Sunder Armor",    -- r4 x2, or r2 x4
	[1080] = "Sunder Armor",    -- r4 x3, or r3 x4
	[1440] = "Sunder Armor x4", -- r4 x4
	[450]  = "Sunder Armor x1",    -- r5 x1, or r1 x5
	[900]  = "Sunder Armor x2",    -- r5 x2, or r2 x5
	[1350] = "Sunder Armor x3",    -- r5 x3, or r3 x5
	[1800] = "Sunder Armor x4",    -- r5 x4, or r4 x5
	[2250] = "Sunder Armor x5", -- r5 x5
	[725]  = "Untalented Expose Armor",
	[1050] = "Untalented Expose Armor",
	[1375] = "Untalented Expose Armor",
	[2550] = "Improved Expose Armor",
	[1700] = "Untalented Expose Armor",
	[505]  = "Faerie Fire",
	[395]  = "Faerie Fire R3",
	[285]  = "Faerie Fire R2",
	[175]  = "Faerie Fire R1",
	[640]  = "Curse of Recklessness",
	[465]  = "Curse of Recklessness R3",
	[290]  = "Curse of Recklessness R2",
	[140]  = "Curse of Recklessness R1",
	[163]  = "The Ripper / Vile Sting", -- turtle weps. spell=3396 is NPC-only in 1.12. falsely says 60 on tooltip
	[100]  = "Weapon Proc Faerie Fire", -- non-stacking proc spell=13752, Puncture Armor r1 x1 spell=11791

	-- New value to DT
	
	[400] = "Feast of Hakkar", --chest 300 runs
	[250] = "Shattered Armor", --saber weapon
	[300] = "Cleave Armor", --300
	[50]   = "Holy Sunder",
}

-- ==== DATA TABLE: DEBUFF ORDER ===== 
-- In this section is the order in which the debuffs will be displayed
-- Display order of debuffs (Left → Right, Top → Bottom)

aDFOrder = {

	--armor/melee
	
    "Expose Armor",
    "Sunder Armor", --2200
    "Curse of Recklessness",
    "Faerie Fire",
    "Decaying Flesh", --3 stack = Feast of Hakkar
    "Feast of Hakkar", --400
	"Cleave Armor", --300
    "Shattered Armor", --250
    "Holy Sunder", --50

	--other
	
	"Gift of Arthas", --arthas gift
	"Crooked Claw", --scythe pet
	"Demoralizing Shout",
	"Thunder Clap",
	
	--spells/caster
	
	"Judgement of the Crusader", -- crusader
    "Judgement of Wisdom",
    "Curse of Shadows",
    "Curse of the Elements",
	"Fire Vulnerability",
	"Shadow Vulnerability", --lock talent
	"Shadow Weaving",
    "Nightfall",
    "Flame Buffet" --arcanite dragon

}
