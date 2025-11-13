local Locale = BitesCookBook.Locales[GetLocale()] or BitesCookBook.Locales["enUS"] -- The default locale is English.

function BitesCookBook.OnCraftableTooltip(Tooltip)
    -- Does the player want to see the tooltip?
    if not BitesCookBook.Options.ShowCraftableTooltip then return end

    -- Do they want to see/hide the tooltip only when holding a modifier key?
    if BitesCookBook:CheckModifierKey() then return end

    -- Find the item link of the item being hovered over.
	local _, ItemLink = Tooltip:GetItem()
	if ItemLink == nil then return end
    local ItemID = Item:CreateFromItemLink(ItemLink):GetItemID()

    -- Otherwise build the tooltip.
    local RecipeTooltip = BitesCookBook:BuildTooltipForCraftable(ItemID)
    if RecipeTooltip == nil then return end

    Tooltip:AddLine(RecipeTooltip)
end

GameTooltip:HookScript("OnTooltipSetItem", BitesCookBook.OnCraftableTooltip)

--------------------------------------------------------------------------------
-- Craftable-specific tooltip functions
--------------------------------------------------------------------------------

function BitesCookBook:BuildTooltipForCraftable(CraftableID)
    -- Shows all materials needed for a recipe.
    local Craftable = BitesCookBook.Recipes[CraftableID]

    -- If the item doesn't correspond to a recipe, do nothing.
    if Craftable == nil then return end

    local text = "\n".. Locale["Recipe:"]
    
    -- Cycle through all materials in a recipe to create the tooltip.
    for ReagentID, count in pairs(Craftable.Materials) do
        local ItemName = BitesCookBook:GetItemNameByID(ReagentID)
        local ItemColor = BitesCookBook:GetReagentColor(ReagentID)

        text = text .."\n    ".. ItemColor.. count .. " x " .. ItemName
    end

    return text
end

-- Ingredients in a recipe are always white.
function BitesCookBook:GetReagentColor(ReagentID)
    return "|r".. BitesCookBook.TextColors["White"]
end