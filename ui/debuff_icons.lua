-- Module: debuff_icons.lua
-- Purpose: build reusable debuff icon frame objects.
-- Exports: aDF.Create_frame().
-- Depends on: GetDB(), ICON/FONT constants, aDF parent frame.
-- Used by: ui/frames.lua.

-- ==== DEBUFF FRAME CREATION ==== Functions to create debuff frames

-- Creates the debuff frame elements

function aDF.Create_frame(name)
	local db = GetDB()  -- Get current configuration
	local frame = CreateFrame('Button', name, aDF)
	frame:SetBackdrop({ bgFile=[[Interface/Tooltips/UI-Tooltip-Background]] }) --study to delete
	frame:SetBackdropColor(255,255,255,0) --study to delete
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	frame.icon:SetPoint('TOPLEFT', 1, -1)
	frame.icon:SetPoint('BOTTOMRIGHT', -1, 1)
	frame.nr = frame:CreateFontString(nil, "OVERLAY")
	frame.nr:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.nr:SetFont("Fonts\\FRIZQT__.TTF", math.floor(FONT_BASE_NR * db.display.scale + 0.5))
	frame.nr:SetTextColor(255, 255, 255, 1)
	frame.nr:SetShadowOffset(2,-2)
	frame.nr:SetText("1")
	return frame
end


