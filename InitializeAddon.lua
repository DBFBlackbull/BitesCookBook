BitesCookBook = CreateFrame("Frame")
BitesCookBook.Options = {
	ShowIngredientTooltip = true,
        HideReagentTooltipsButHint = false, -- If true, the reagent tooltips will be hidden, but a hint will still be shown.
        ShowCraftableFirstRank = false, -- In the reagent tooltip, show the first rank of the craftable item.
            ShowCraftableRankRange = false, -- In the reagent tooltip, also show the subsequent rank range of the craftable item.
        ShowCraftableIcon = true, -- In the reagent tooltip, show the icon of the craftable item.
        GrayHighCraftables = false, -- In the reagent tooltip, gray out the craftable if it is too high rank.
        ColorCraftableByRank = true, -- In the reagent tooltip, color the craftable item by rank.
    MinRankCategory = 1, -- The minimum rank category to show in the reagent tooltip.
    MaxRankCategory = 5, -- The maximum rank category to show in the reagent tooltip.
	ShowCraftableTooltip = false, -- In the craftable tooltip, show required reagents.
	ShowEnemyTooltip = true, -- In the enemy tooltip, show droppable reagents.
        ColorDropsByRank = true, -- In the enemy tooltip, color the reagents by the highest ranked recipe that uses it.
	HasModifier = 0, -- 0 = no modifier, true = has modifier, false = has inverse modifier
    ModifierKey = "SHIFT", -- SHIFT, ALT, CTRL
}

function BitesCookBook.ADDON_LOADED(self, event, addonName)
    if addonName ~= "BitesCookBook" then return end

    BitesCookBook:ConfigureSavedVariables() -- Set or load the saved variables.
    BitesCookBook:InitializeOptionsMenu() -- Build the options menu.
    BitesCookBook.Recipes, BitesCookBook.Reagents = BitesCookBook:GetListsForVersion() -- Choose the correct recipe and reagent lists.

    -- Dynamically create a list for all ingredients and their associated recipes, or mobs and their associated reagent drops.
    BitesCookBook.CraftablesForReagent = BitesCookBook:GetAllIngredients(BitesCookBook.Recipes)
    BitesCookBook.MobsDroppingReagent = BitesCookBook:GetAllMobs(BitesCookBook.Reagents)

    -- We keep track of the player's locale/language.
    BitesCookBook.ClientLocale = GetLocale()

    -- We should cache all the item names by loading the items ones.
    -- This prevent the tooltips from appearing empty when the player first opens them.
    -- TODO: Is it at all possible to simply wait for an item to load. Can we pause script execution?
    BitesCookBook:CacheItems(BitesCookBook.Recipes, BitesCookBook.Reagents)
    BitesCookBook:UnregisterEvent(event) -- Finally, the addon-loading event is unregistered.
end

function BitesCookBook.PLAYER_ENTERING_WORLD(BitesCookBook, event)
    -- Get the player's cooking skill level.
    BitesCookBook.CookingSkillRank = BitesCookBook:GetSkillLevel("Cooking")

    -- The player-entering-world event is unregistered.
    BitesCookBook:UnregisterEvent(event)
end

function BitesCookBook.CHAT_MSG_SKILL(BitesCookBook, event)
    -- Update the player's cooking skill level.
    BitesCookBook.CookingSkillRank = BitesCookBook:GetSkillLevel("Cooking")
end

function BitesCookBook.OnEvent(self, Event, AddonName)
    -- Call the function with the same name as the event.
    self[Event](self, Event, AddonName)
end

BitesCookBook:RegisterEvent("CHAT_MSG_SKILL")
BitesCookBook:RegisterEvent("ADDON_LOADED")
BitesCookBook:RegisterEvent("PLAYER_ENTERING_WORLD")
BitesCookBook:SetScript("OnEvent", BitesCookBook.OnEvent)

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

function BitesCookBook:CacheItems(RecipeList, ReagentList)
    -- We load every item in the recipe and reagent lists to cache their names.
    for ID, _ in pairs(RecipeList) do
        GetItemInfo(ID)
    end

    for ID, _ in pairs(ReagentList) do
        GetItemInfo(ID)
    end
end

function BitesCookBook:GetAllIngredients(RecipeList)
    -- Dynamically create a list for all ingredients and their associated recipes.
    local Reagents = {}
    
    for recipe_key, recipe in pairs(RecipeList) do
        for ingredient, _ in pairs(recipe["Materials"]) do
            if Reagents[ingredient] == nil then
                Reagents[ingredient] = {recipe_key}
            else
                table.insert(Reagents[ingredient], recipe_key)
            end
        end
    end

    -- sort each ingredient list based on the recipe range[1]
    for ingredient, recipe_list in pairs(Reagents) do
        table.sort(recipe_list, function(a, b)
            return RecipeList[a]["Range"][1] > RecipeList[b]["Range"][1]
        end)
    end

    return Reagents
end

function BitesCookBook:GetAllMobs(ReagentsDict)
    -- Dynamically create a list for all Mobs and their associated reagent drops.
    local MobsAndDrops = {}
    
    for DropID, DropDetails in pairs(ReagentsDict) do
        for MobID, ChangeToDropReagent in pairs(DropDetails.DroppedBy) do
            if MobsAndDrops[MobID] == nil then
                MobsAndDrops[MobID] = {}
            end
            
            table.insert(MobsAndDrops[MobID], DropID)
        end
    end

    -- Sort the ingredient drops of each mobs on the list based on their max-used recipe range.
    for MobID, Drops in pairs(MobsAndDrops) do
        table.sort(Drops, function(IngredientID_A, IngredientID_B)
            local HighestRecipeId_A = BitesCookBook.CraftablesForReagent[IngredientID_A][1] -- The first recipe is the highest ranked one.
            local HighestRanks_A = BitesCookBook.Recipes[HighestRecipeId_A]["Range"]

            local HighestRecipeId_B = BitesCookBook.CraftablesForReagent[IngredientID_B][1] -- The first recipe is the highest ranked one.
            local HighestRanks_B = BitesCookBook.Recipes[HighestRecipeId_B]["Range"]

            return HighestRanks_A[1] > HighestRanks_B[1]
        end)
    end

    return MobsAndDrops
end

function BitesCookBook:GetSkillLevel(SkillName)
    -- Get a profession's skill level.
    for skillIndex = 1, GetNumSkillLines() do
        local SkillInfo = {GetSkillLineInfo(skillIndex)}

        if SkillInfo[1] == SkillName then
            return SkillInfo[4]
        end
    end
    
    -- If we cannot not find the skill, the rank is 0.
    return 0
end

function BitesCookBook:ConfigureSavedVariables()
    -- Set the saved variables to the default values if they are not set.
    if BitesCookBook_SavedVariables == nil then
        BitesCookBook_SavedVariables = self.Options
    else
        -- If new Options were added since last file was saved, we must update it.
        for key, option_value in pairs(self.Options) do
            if BitesCookBook_SavedVariables[key] == nil then
                BitesCookBook_SavedVariables[key] = option_value
            end
        end

        -- if an option was removed, we must also remove it from the saved variables.
        for key, option_value in pairs(BitesCookBook_SavedVariables) do
            if self.Options[key] == nil then
                BitesCookBook_SavedVariables[key] = nil
            end
        end

        -- Let Options be the (updated) saved variables.
        self.Options = BitesCookBook_SavedVariables
    end

    return
end

function BitesCookBook:GetListsForVersion()
    -- Detect if we are in classic.
    local buildversion = select(4, GetBuildInfo())
    local isClassic = select(4, GetBuildInfo()) < 30000
    local isWotLK = select(4, GetBuildInfo()) < 40000

    if isClassic then
        print("BitesCookBook: Classic.")
        return BitesCookBook_RecipesClassic, BitesCookBook_ReagentsClassic
    elseif isWotLK then
        print("BitesCookBook: Wrath of the Lich King.")
        return BitesCookBook_RecipesWotLK, BitesCookBook_ReagentsWotLK
    else
        print("BitesCookBook: Cataclysm.")
        return BitesCookBook_RecipesCata, BitesCookBook_ReagentsCata
    end
end