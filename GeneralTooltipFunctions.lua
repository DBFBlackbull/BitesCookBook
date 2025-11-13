--------------------------------------------------------------------------------
-- General Tooltip functions and Definitions
--------------------------------------------------------------------------------

BitesCookBook.TextColors = {
    ["Red"] = "|c00FF0000",
    ["Orange"] = "|c00FF7F00",
    ["Yellow"] = "|c00FFFF00",
    ["Green"] = "|cff1eff00",
    ["Gray"] = "|c007d7d7d",
    ["White"] = "|cffffffff",
}

BitesCookBook.ModifierKeys = {
    ["SHIFT"] = IsShiftKeyDown,
    ["ALT"] = IsAltKeyDown,
    ["CTRL"] = IsControlKeyDown,
}

-- Returns the name of an item using its WoW ID.
function BitesCookBook:GetItemNameByID(ItemId)
    local ItemName = C_Item.GetItemNameByID(ItemId)

    -- Sometimes WoW won't find the name immediately.
    return ItemName ~= nil and ItemName or ""
end

function BitesCookBook:GetItemIcon(ItemId)
    local ItemIcon = C_Item.GetItemIconByID(ItemId)

    -- Sometimes WoW won't find the icon immediately, so use the default question mark icon.
    return ItemIcon ~= nil and ItemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function BitesCookBook:CheckModifierKey()
    local ModifierValue = BitesCookBook.Options.HasModifier
    if ModifierValue ~= 0 and ModifierValue ~= 1 then
        if BitesCookBook.ModifierKeys[BitesCookBook.Options.ModifierKey]() == not ModifierValue then
            return true
        end
    end
    
    -- Passes the check.
    return false
end

function BitesCookBook:GetColorInRange(Range, Rank)
    if Rank < Range[1] then
        return BitesCookBook.TextColors["Red"] -- Red color.
    elseif Rank < Range[2] then
        return BitesCookBook.TextColors["Orange"] -- Orange color.
    elseif Rank < Range[3] then
        return BitesCookBook.TextColors["Yellow"] -- Yellow color.
    elseif Rank < Range[4] then
        return BitesCookBook.TextColors["Green"] -- Green color.
    else
        return BitesCookBook.TextColors["Gray"] -- Gray color.
    end
end

function BitesCookBook:IsRecipeInRange(RecipeId)
    -- If the user has the modifier key set to "Unlock filters", we should always return true.
    if BitesCookBook.Options.HasModifier == 1 and BitesCookBook.ModifierKeys[BitesCookBook.Options.ModifierKey]() == not ModifierValue then
        return true
    end
    
    -- Otherwise, check if the recipe is in the player's range.
    local RankingRange = BitesCookBook.Recipes[RecipeId]["Range"]
    local MinimumCategory = BitesCookBook.Options.MinRankCategory
    local MaximumCategory = BitesCookBook.Options.MaxRankCategory

    -- We need to find which category the recipe is in based on its RankingRange and the player's rank.
    local RecipeCategory = BitesCookBook:GetCategoryInRange(RankingRange, BitesCookBook.CookingSkillRank)
    if RecipeCategory >= MinimumCategory and RecipeCategory <= MaximumCategory then
        return true
    end

    return false
end
