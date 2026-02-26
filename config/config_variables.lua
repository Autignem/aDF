-- ===== CENTRALIZED CONFIGURATION SYSTEM ===== subsection
-- The single variable stored between sessions

-- Default configuration

local DEFAULT_CONFIG = {
    version = 1,
    currentProfile = "default",
    profiles = {
        default = {
            positions = {
                armor = {x = 0, y = 0},
                resistance = {x = 0, y = 30},
                debuffs = {x = 0, y = -50}
            },
            display = {
                scale = 1.10,
                framesVisible = true,
                showArmorBackground = true,
                showResistanceBackground = true,
                showDebuffBackground = true,
                showArmorText = true,
                showResistanceText = true,
            },
            locks = {
                armor = false,
                resistance = false,
                debuffs = false
            },
            notifications = {
                announceArmorDrop = false,
                channel = "Say",
                channels = {"Say", "Yell", "Party", "Raid", "Raid_Warning"}
            },
            enabledDebuffs = {},
            debuffSettings = {
                maxColumns = 7,
                maxRows = 3,
                hideInactive = false,
                dynamicIcons = true
            }
        }
    }
}

-- Function to copy tables (simple, not deep-recursive)

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyTable(v)
        else
            dst[k] = v
        end
    end
    return dst
end


-- Function to ensure the configuration structure is complete

function EnsureConfigStructure()

	-- If missing, create with default values

	if not aDF_Options then
        aDF_Options = CopyTable(DEFAULT_CONFIG)
        return
    end
    
	-- If exists but version is older, migrate while preserving existing profiles

	if not aDF_Options.version or aDF_Options.version < DEFAULT_CONFIG.version then

		-- Preserve existing profiles if present

		local existingProfiles = aDF_Options.profiles or {}
		aDF_Options = CopyTable(DEFAULT_CONFIG)
		aDF_Options.profiles = existingProfiles

		-- Ensure the default profile exists

		if not aDF_Options.profiles["default"] then
			aDF_Options.profiles["default"] = CopyTable(DEFAULT_CONFIG.profiles.default)
		end
		aDF_Options.currentProfile = aDF_Options.currentProfile or "default"
	end

	-- Ensure essential fields

	aDF_Options.profiles = aDF_Options.profiles or {}
	aDF_Options.currentProfile = aDF_Options.currentProfile or "default"

	-- Ensure the current profile exists

	if not aDF_Options.profiles[aDF_Options.currentProfile] then
		aDF_Options.currentProfile = "default"
		if not aDF_Options.profiles["default"] then
			aDF_Options.profiles["default"] = CopyTable(DEFAULT_CONFIG.profiles.default)
		end
	end

	-- Ensure complete structure for the current profile

	local currentProfile = aDF_Options.profiles[aDF_Options.currentProfile]
	local defaultProfile = DEFAULT_CONFIG.profiles.default

	for category, defaultCategory in pairs(defaultProfile) do
		if not currentProfile[category] then
			currentProfile[category] = CopyTable(defaultCategory)
		elseif type(defaultCategory) == "table" then
			for subKey, subDefault in pairs(defaultCategory) do
				if currentProfile[category][subKey] == nil then
					currentProfile[category][subKey] = subDefault
				end
			end
		end
	end
end

-- Safe function to get current configuration (NEVER returns nil)

local function GetConfig()
    EnsureConfigStructure()
    return aDF_Options.profiles[aDF_Options.currentProfile]
end

-- Quick and safe access to the current configuration

function GetDB()
	return GetConfig()
end

-- Base sizes used for scalable UI (multiplied by db.display.scale)

ICON_BASE = 24
FONT_BASE_NR = 16
FONT_BASE_ARMOR = 18
FONT_BASE_RES = 14
