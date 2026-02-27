-- Module: options_registry.lua
-- Purpose: declare options navigation sections and views.
-- Exports: aDF_OptionsRegistry + GetSection().
-- Depends on: none.
-- Used by: ui/options_shell.lua.

-- Registry for 3-column options navigation.

aDF_OptionsRegistry = {
    sections = {
        {
            id = "general",
            text = "General",
            children = {
                { id = "size", text = "Size", view = "general_size" },
                { id = "display", text = "Display", view = "general_display" },
                { id = "locks", text = "Locks", view = "general_locks" },
            }
        },
        {
            id = "notifications",
            text = "Notifications",
            children = {
                { id = "chat", text = "Chat", view = "notifications_chat" },
            }
        },
        {
            id = "debuff",
            text = "Debuff",
            children = {
                { id = "armor", text = "Armor", view = "debuff_armor" },
                { id = "resistance", text = "Resistance", view = "debuff_resistance" },
                { id = "utility", text = "Utility", view = "debuff_utility" },
                { id = "damage", text = "Damage", view = "debuff_damage" },
                { id = "other", text = "Other", view = "debuff_other" },
            }
        },
    }
}

function aDF_OptionsRegistry:GetSection(id)
    for _, section in ipairs(self.sections) do
        if section.id == id then
            return section
        end
    end
    return nil
end

