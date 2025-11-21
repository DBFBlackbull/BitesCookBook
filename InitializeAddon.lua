BitesCookBook = CreateFrame("Frame")
BitesCookBook.Options = {
	ShowCraftableFirstRank = true, -- In the reagent tooltip, show the first rank of the craftable item.
	ShowCraftableRankRange = true, -- In the reagent tooltip, also show the subsequent rank range of the craftable item.
	ShowCraftableFaction = true, -- Show the faction the recipe belongs to.
	GrayHighCraftables = false, -- In the reagent tooltip, gray out the craftable if it is too high rank.
	ColorCraftableByRank = true, -- In the reagent tooltip, color the craftable item by rank.
	MinRankCategory = 1, -- The minimum rank category to show in the reagent tooltip.
	MaxRankCategory = 5, -- The maximum rank category to show in the reagent tooltip.
	HasModifier = 0, -- 0 = no modifier, true = has modifier, false = has inverse modifier
	ModifierKey = "SHIFT", -- SHIFT, ALT, CTRL
}

function BitesCookBook:Print(string)
	DEFAULT_CHAT_FRAME:AddMessage("[BitesCookBook] " .. tostring(string))
end

function BitesCookBook:ADDON_LOADED(eventName, addonName)
	eventName = eventName or event
	addonName = addonName or arg1
	if addonName ~= "BitesCookBook" then return end

	--BitesCookBook:ConfigureSavedVariables() -- Set or load the saved variables.
	--BitesCookBook:InitializeOptionsMenu() -- Build the options menu.
	self.Recipes = BitesCookBook_RecipesClassic
	-- Dynamically create a list for all ingredients and their associated recipes, or mobs and their associated reagent drops.
	self.CraftablesForReagent = self:GetAllIngredients(self.Recipes)

	-- We keep track of the player's locale/language.
	self.L = (BitesCookBook.Locales[GetLocale()] or BitesCookBook.Locales["enUS"])

	-- We should cache all the item names by loading the items ones.
	-- This prevent the tooltips from appearing empty when the player first opens them.
	self:CacheItems(self.Recipes)
	self:HookTooltips()
	self:RegisterEvent("CHAT_MSG_SKILL") -- test this
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:UnregisterEvent(eventName) -- Finally, the addon-loading event is unregistered.
end

function BitesCookBook:SKILL_LINES_CHANGED(eventName)
	eventName = eventName or event

	-- Skill lines are not ready yet
	if GetNumSkillLines() == 0 then
		return
	end

	-- Unregister SKILL_LINES_CHANGED to prevent infinite loop
	self:UnregisterEvent(eventName)

	-- Get the player's cooking skill level.
	self.CookingSkillRank = self:GetSkillLevel("Cooking")
end

function BitesCookBook:CHAT_MSG_SKILL(eventName)
	-- Update the player's cooking skill level.
	self.CookingSkillRank = self:GetSkillLevel("Cooking")
end

function BitesCookBook.OnEvent()
	-- Call the function with the same name as the event.
	BitesCookBook[event](BitesCookBook, event, arg1)
end

BitesCookBook:RegisterEvent("ADDON_LOADED")
BitesCookBook:SetScript("OnEvent", BitesCookBook.OnEvent)

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

BitesCookBook.ItemCache = {}
function BitesCookBook:CacheItems(recipeList)
	-- We load every item in the recipe and reagent lists to cache their names.
	for itemID, _ in pairs(recipeList) do
		local itemName, itemLink, itemQuality = GetItemInfo(itemID)
		if itemName and itemLink and itemQuality then
			local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
			local hyperLink = hex.. "|H".. itemLink .."|h["..itemName.."]|h" .. FONT_COLOR_CODE_CLOSE
			self.ItemCache[itemName] = hyperLink
		end
	end
end

function BitesCookBook:GetItemLinkByName(name)
	if self.ItemCache[name] then
		return self.ItemCache[name]
	end

	for itemID = 1, 25818 do
		local itemName, itemLink, itemQuality = GetItemInfo(itemID)
		if itemName == name and itemLink and itemQuality then
			local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
			local hyperLink = hex.. "|H".. itemLink .."|h["..itemName.."]|h" .. FONT_COLOR_CODE_CLOSE
			self.ItemCache[name] = hyperLink
			return hyperLink
		end
	end
end

local skippedIngredients = {
	[2678] = true, -- Mild Spices
	[2692] = true, -- Hot Spices
	[3713] = true, -- Soothing Spices
	[1179] = true, -- Ice Cold Milk
	[4536] = true, -- Shiny Red Apple
	[159]  = true, -- Refreshing Spring Water
}

function BitesCookBook:GetAllIngredients(RecipeList)
	-- Dynamically create a list for all ingredients and their associated recipes.
	local Reagents = {}

	for recipeItemID, recipe in pairs(RecipeList) do
		for ingredientID, _ in pairs(recipe["Materials"]) do
			if not skippedIngredients[ingredientID] then
				if Reagents[ingredientID] == nil then
					Reagents[ingredientID] = {}
				end

				table.insert(Reagents[ingredientID], recipeItemID)
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

function BitesCookBook:GetSkillLevel(skillName)
	ExpandSkillHeader(0) -- Ensure all skills are expanded

	-- Get a profession's skill level.
	for skillIndex = 1, GetNumSkillLines() do
		local skillLineName, _, _, skillRank = GetSkillLineInfo(skillIndex)

		if skillLineName == skillName then
			return skillRank
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
