-- ==== UTILITY FUNCTIONS ==== 
-- Utility functions (defaults, debug)

-- Initialize default configuration for debuff checkboxes

function aDF_Default()
	local db = GetDB()  -- Get current configuration
    
	if not db.enabledDebuffs or not next(db.enabledDebuffs) then
		db.enabledDebuffs = {}
		for k, v in pairs(aDFDebuffs) do
			db.enabledDebuffs[k] = true  -- All active by default
		end
	end
end