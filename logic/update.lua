-- Module: update.lua
-- Purpose: refresh armor, resistances, alerts and debuff icon states.
-- Exports: aDF:Update().
-- Depends on: GetDB(), aDF_State, GetDebuff(), data tables and frame globals.
-- Used by: core/events.lua and options interactions.

-- ==== UPDATE FUNCTIONS ==== 
-- Update functions. Main update function for armor/resistance display and debuff icon states
local S = aDF_State
local lastIconUpdate = 0
local ICON_UPDATE_THROTTLE = 0.5

function aDF:Update()
	local db = GetDB()  -- Get current configuration
    
    if not S.target or not UnitExists(S.target) or UnitIsDead(S.target) or UnitIsFriend("player", S.target) then
        if aDF_ArmorFrame and aDF_ArmorFrame.armor then
            aDF_ArmorFrame.armor:SetText("")
        end
        if aDF_ResFrame and aDF_ResFrame.res then
            aDF_ResFrame.res:SetText("")
        end
        for i, v in pairs(db.enabledDebuffs) do
            if aDF_frames[i] then
                aDF_frames[i].icon:SetAlpha(0)
                aDF_frames[i].nr:SetText("")
            end
        end
        return
    end
    
    local armorcurr = UnitResistance(S.target,0)
    
    -- update armor text display

    if aDF_ArmorFrame then
        if db.display.showArmorText then
            aDF_ArmorFrame.armor:SetText(armorcurr)
        else
            aDF_ArmorFrame.armor:SetText("")
        end
    end
    
	-- Cache for resistances, only every 2 seconds
	-- this reduces performance impact, but can bug if retargeting very fast

    local now = GetTime()
    if aDF_ResFrame then
        if db.display.showResistanceText then
            if not S.lastResUpdate or (now - S.lastResUpdate) > 2 then
                local fire = UnitResistance(S.target,2)
                local nature = UnitResistance(S.target,3)
                local frost = UnitResistance(S.target,4)
                local shadow = UnitResistance(S.target,5)
                local arcane = UnitResistance(S.target,6)
                aDF_ResFrame.res:SetText("|cffFF0000 "..fire.." |cffADFF2F "..nature.." |cff4AE8F5 "..frost.." |cff9966CC "..shadow.." |cffFEFEFA "..arcane)
                S.lastResUpdate = now
            end
        else
            aDF_ResFrame.res:SetText("")
        end
    end
    
    -- Announce armor drops

    if armorcurr > S.armorPrev then
        local armordiff = armorcurr - S.armorPrev
		local diffreason = ""
		if S.armorPrev ~= 0 and aDFArmorVals[armordiff] then
			diffreason = " (Dropped " .. tostring(aDFArmorVals[armordiff]) .. ")"
		end
		local targetName = UnitName(S.target) or "Unknown"
		local msg = tostring(targetName) .. "'s armor: " .. tostring(S.armorPrev) .. " -> " .. tostring(armorcurr) .. diffreason
        
        if S.target == 'target' and db.notifications.announceArmorDrop then
            SendChatMessage(msg, db.notifications.channel)
        end
    end
    S.armorPrev = armorcurr

    -- Update debuff icon states, use basic throttling

    now = GetTime()
    
	-- Only update icons at most every 500ms
	-- This reduces performance impact during heavy aura changes, but warrior cry because don't see sunder very fast, 0,5s is good i think

	if now - lastIconUpdate > ICON_UPDATE_THROTTLE then
        lastIconUpdate = now
        
        for debuffName, _ in pairs(db.enabledDebuffs) do
            local frame = aDF_frames[debuffName]
            if frame then
                local hasDebuff = aDF:GetDebuff(S.target, aDFSpells[debuffName])
                local stacks = hasDebuff and aDF:GetDebuff(S.target, aDFSpells[debuffName], 1) or 0
                
                frame.icon:SetAlpha(hasDebuff and 1 or 0.3)
                frame.nr:SetText((stacks > 1) and tostring(stacks) or "")
            end
        end
    end

end
