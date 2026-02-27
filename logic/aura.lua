-- Module: aura.lua
-- Purpose: detect tracked effects on target via debuff/buff scan.
-- Exports: aDF:GetDebuff().
-- Depends on: UnitDebuff/UnitBuff APIs, shared tooltip scanner.
-- Used by: logic/update.lua.

-- ==== DEBUFF DETECTION ====
-- Function to check for a debuff/buff on a unit, by name or tooltip text
-- We need checking debuff and buff because when debuff slot is full, some debuffs are applied as buffs slot

function aDF:GetDebuff(name, buff, wantStacks)
    if not name or not UnitExists(name) then
        if wantStacks then
            return false, 0
        else
            return false
        end
    end
    
    local function CheckAura(auraFunc)
        local a = 1
        while auraFunc(name, a) do
            local _, stacks = auraFunc(name, a)
            aDF_tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            aDF_tooltip:ClearLines()
            if auraFunc == UnitDebuff then
                aDF_tooltip:SetUnitDebuff(name, a)
            else
                aDF_tooltip:SetUnitBuff(name, a)
            end
            local aDFtext = aDF_tooltipTextL:GetText()
            
            if type(buff) == "table" then
                for _, buffName in ipairs(buff) do
                    if aDFtext and string.find(aDFtext, buffName) then
                        return true, stacks
                    end
                end
            else
                if aDFtext and string.find(aDFtext, buff) then
                    return true, stacks
                end
            end
            a = a + 1
        end
        return false, 0
    end
    
    local found, stacks = CheckAura(UnitDebuff)
    if not found then
        found, stacks = CheckAura(UnitBuff)
    end
    
    if wantStacks then
        return stacks
    else
        return found
    end

end
