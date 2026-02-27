---########### armor/resistance and Debuff Frame
-- ########### By Atreyyo @ Vanillagaming.org <--original
-- ########### Contributor: Autignem <--reworked/rewrite
-- ########### Version 4.3 (27/02/2026)

-- Module: init.lua
-- Purpose: bootstrap main frames and register core events.
-- Exports: global aDF frame and aDF.Options frame.
-- Depends on: WoW UI API.
-- Used by: all modules through global aDF namespace.

-- ============================================================================
-- aDF modular structure (load order from aDF.toc)
--
-- 1. core\init.lua                 -> frame initialization + base events
-- 2. config\config_variables.lua   -> SavedVariables schema + GetDB()
-- 3. core\state.lua                -> runtime shared state containers
-- 4. core\data.lua                 -> static debuff/armor/order tables
-- 5. config\config_defaults_ini.lua-> default per-profile debuff enables
-- 6. ui\debuff_icons.lua           -> debuff icon frame factory
-- 7. ui\frames.lua                 -> main HUD frames (armor/res/debuff)
-- 8. logic\aura.lua                -> debuff detection (buff/debuff scan)
-- 9. logic\sort.lua                -> icon layout/sorting logic
-- 10. logic\update.lua             -> armor/res/debuff runtime updates
-- 11. ui\options_widgets.lua       -> reusable options UI helpers
-- 12. ui\options_registry.lua      -> options section/subsection registry
-- 13. ui\options_shell.lua         -> 3-column options UI and views
-- 14. core\events.lua              -> OnEvent dispatcher + script binding
-- 15. core\slash.lua               -> /adf commands
-- ============================================================================


-- ==== FRAME INITIALIZATION ==== 
-- Use a distinct global name for the options frame so it doesn't collide with the
-- SavedVariables table `aDF_Options`. UISpecialFrames expects a Frame, not a table.
-- Now the aDF.lua in savedvariables only contains the configuration data.

aDF = CreateFrame('Button', "aDF", UIParent) -- Main event frame
aDF.Options = CreateFrame("Frame","aDF_OptionsFrame",UIParent) -- Options frame (global name for UISpecialFrames ESC handling)

-- Register events

aDF:RegisterEvent("ADDON_LOADED")
aDF:RegisterEvent("UNIT_AURA")

aDF:RegisterEvent("PLAYER_TARGET_CHANGED")

