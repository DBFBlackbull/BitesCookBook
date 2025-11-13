local Locale = BitesCookBook.Locales[GetLocale()] or BitesCookBook.Locales["enUS"] -- The default locale is English.

function BitesCookBook.OnReagentTooltip(Tooltip)
    -- Does the player want to see the tooltip?
    if not BitesCookBook.Options.ShowIngredientTooltip then
        return
    end

    -- Do they want to see/hide the tooltip only when holding a modifier key?
    if BitesCookBook:CheckModifierKey() then return end

    -- Find the item link of the item being hovered over.
	local _, ItemLink = Tooltip:GetItem()
	if ItemLink == nil then return end
    local ItemID = Item:CreateFromItemLink(ItemLink):GetItemID()
    

    local IngredientTooltip = BitesCookBook:BuildTooltipForReagent(ItemID)
    if IngredientTooltip == nil then return end

    -- Do we want to hide the information?
    if BitesCookBook.Options.HideReagentTooltipsButHint then
        Tooltip:AddLine(Locale["UsedHint"])
        return
    end
    Tooltip:AddLine(IngredientTooltip)
end

GameTooltip:HookScript("OnTooltipSetItem", BitesCookBook.OnReagentTooltip)

--------------------------------------------------------------------------------
-- Reagent-specific tooltip functions
--------------------------------------------------------------------------------

function BitesCookBook:BuildTooltipForReagent(ReagentID)
    --- Shows all available recipes for that ingredient.
    local CraftablesMadeWithIngredient = BitesCookBook.CraftablesForReagent[ReagentID] -- A list of recipes that use the ingredient.
    if CraftablesMadeWithIngredient == nil then return end
    
    local text = ""
    -- Cycle through all recipes that use the ingredient to create the tooltip.
    for _, RecipeID in ipairs(CraftablesMadeWithIngredient) do
        if BitesCookBook:IsRecipeInRange(RecipeID) then
            local CraftableName = BitesCookBook:GetItemNameByID(RecipeID)
            local CraftableColor = BitesCookBook:GetCraftableColor(RecipeID)

            -- Show the recipe icon if the option is enabled.
            local ShowRecipeIcon = BitesCookBook.Options.ShowCraftableIcon
            local CraftableIcon = BitesCookBook:GetItemIcon(RecipeID)
            CraftableIcon = ShowRecipeIcon and "|T".. CraftableIcon.. ":0|t " or ""

            text = text .."\n    ".. CraftableIcon .. CraftableColor.. CraftableName.. "|r"

            local ShowFirstLevel = BitesCookBook.Options.ShowCraftableFirstRank
            local ShowLevelRange = BitesCookBook.Options.ShowCraftableRankRange
            
            if ShowFirstLevel then
                local RankingRange = BitesCookBook.Recipes[RecipeID]["Range"]
                local FirstRangeText = RankingRange[1] > 1 and RankingRange[1] or Locale["Starter"]

                -- When the first rank is 1, it's a starter recipe.
                text = text .. "-".. BitesCookBook.TextColors["Orange"].. FirstRangeText.. "|r"

                if ShowLevelRange then
                    text = text.. "|r-".. BitesCookBook.TextColors["Yellow"].. RankingRange[2].. "|r-".. BitesCookBook.TextColors["Green"].. RankingRange[3].. "|r-".. BitesCookBook.TextColors["Gray"].. RankingRange[4].. "|r"
                end
            end
            
        end
    end

    if text ~= "" then
        text = Locale["IngredientFor:"].. text
    end
    
    return text
end

function BitesCookBook:GetCraftableColor(CraftableID)
    local RankingRange = BitesCookBook.Recipes[CraftableID]["Range"] -- Range of ranks when recipe level-up changes.
    local MyRank = BitesCookBook.CookingSkillRank
    
    local ShouldGrayTheUnavailable = BitesCookBook.Options.GrayHighCraftables
    if ShouldGrayTheUnavailable and MyRank < RankingRange[1] then
        return BitesCookBook.TextColors["Gray"] -- Gray color.
    end
    
    local ShouldColorByRank = BitesCookBook.Options.ColorCraftableByRank
    if ShouldColorByRank then
        return "|r".. BitesCookBook:GetColorInRange(RankingRange, MyRank)
    end

    -- Default color is white. |r is needed to reset the color and prevents leaks.
    return "|r".. BitesCookBook.TextColors["White"]
end

function BitesCookBook:GetCategoryInRange(RankingRange, Rank)
    for i = 1, 4 do
        if Rank > RankingRange[5 -i] then -- The list goes from red to gray.
            return i
        end
    end
    -- If the player's rank is higher than the highest rank, we return 5 i.e. red.
    return 5
end