BitesCookBook = CreateFrame("Frame")
BitesCookBook.Options = {
	ShowCraftableFirstRank = true, -- In the reagent tooltip, show the first rank of the craftable item.
	ShowCraftableRankRange = true, -- In the reagent tooltip, also show the subsequent rank range of the craftable item.
	ShowCraftableFaction = true, -- Show the faction the recipe belongs to.
	ShowCraftableIcon = true, -- In the reagent tooltip, show the icon of the craftable item.
	ShowCraftableBuff = true, -- In the reagent tooltip, show the buff granted by the craftable item.
	GrayHighCraftables = false, -- In the reagent tooltip, gray out the craftable if it is too high rank.
	ColorCraftableByRank = true, -- In the reagent tooltip, color the craftable item by rank.
	MinRankCategory = 1, -- The minimum rank category to show in the reagent tooltip.
	MaxRankCategory = 5, -- The maximum rank category to show in the reagent tooltip.
	HasModifier = 0, -- 0 = no modifier, true = has modifier, false = has inverse modifier
	ModifierKey = "SHIFT", -- SHIFT, ALT, CTRL
}

BitesCookBook.Tooltip = getglobal("BitesCookBookTooltip") or CreateFrame("GameTooltip", "BitesCookBookTooltip", nil, "GameTooltipTemplate")
BitesCookBook.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

function BitesCookBook:Print(string)
	DEFAULT_CHAT_FRAME:AddMessage("[BitesCookBook]: " .. tostring(string))
end

function BitesCookBook:ADDON_LOADED(eventName, addonName)
	eventName = eventName or event
	addonName = addonName or arg1
	if addonName ~= "BitesCookBook" then return end

	-- We should cache all the item names by loading the items once.
	-- This prevent the tooltips from appearing empty when the player first opens them.
	self:CacheItems()

	--BitesCookBook:ConfigureSavedVariables() -- Set or load the saved variables.
	--BitesCookBook:InitializeOptionsMenu() -- Build the options menu.
	self.Recipes = BitesCookBook_RecipesClassic
	-- Dynamically create a list for all ingredients and their associated recipes, or mobs and their associated reagent drops.
	self.CraftablesForReagent = self:GetAllIngredients(self.Recipes)

	-- We keep track of the player's locale/language.
	self.L = (BitesCookBook.Locales[GetLocale()] or BitesCookBook.Locales["enUS"])

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

local wellFedIcon = "Interface\\Icons\\Spell_Misc_Food"

function BitesCookBook:SetBuff(recipe)
	local MAX_LINES = self.Tooltip:NumLines()
	for i = 1, MAX_LINES do
		local lineText = getglobal(self.Tooltip:GetName().."TextLeft"..i):GetText()
		if lineText then
			-- If you spend at least 10 seconds eating you will become well fed and gain 12 Stamina and Spirit for 15 min.
			-- If you spend at least 10 seconds eating you will become well fed and gain 6 Mana every 5 seconds for 15 min.
			local _, _, wellFed = string.find(lineText, "well fed and gain (.-%.)")
			if wellFed then
				recipe.Buff = wellFed
				recipe.BuffIcon = recipe.BuffIcon or wellFedIcon
				return
			end

			-- Occasionally belch flame at enemies struck in melee for the next 10 min.
			local _, _, dragonBreathChili = string.find(lineText, "(Occasionally belch flame at enemies struck in melee for the next 10 min%.)")
			if dragonBreathChili then
				recipe.Buff = dragonBreathChili
				-- buff icon already set
				return
			end

			-- Also increases your Stamina by 10 for 10 min.
			-- Also increases your Stamina by 10 for 10 min.
			-- Also increases your Intellect by 10 for 10 min.
			-- Also increases your Spirit by 10 for 10 min.
			-- If you eat for 10 seconds will also increase your Agility by 10 for 10 min.
			local _, _, fishStat, fishAmount, fishText = string.find(lineText, "[Aa]lso increases? your (.*) by (%d+) (for %d+ min%.)")
			if fishStat and fishAmount and fishText then
				local fishBuff = format("%s %s %s", fishAmount, fishStat, fishText) -- format buff like Well Fed
				recipe.Buff = fishBuff
				-- buff icon already set
				return
			end

			-- Also restores 8 Mana every 5 seconds for 10 min.
			-- Also restores 6 health every 5 seconds for 10 min.
			local _, _, fishRegen = string.find(lineText, "[Aa]lso restores (.-%.)")
			if fishRegen then
				recipe.Buff = fishRegen
				-- buff icon already set
				return
			end
		end
	end
end

--BitesCookBook.ItemCache = {}
function BitesCookBook:CacheItems()
	-- We load every item in the recipe and reagent lists to cache their names.
	local cached = 0
	local total = 0
	for itemID, recipe in pairs(BitesCookBook_RecipesClassic) do
		self.Tooltip:ClearLines()
		self.Tooltip:SetHyperlink("item:"..itemID..":0:0:0") -- Queries the server for the item if not found in the WDB cache
		local itemName, itemLink = self.Tooltip:GetItem()
		self:Print(format("tooltip:GetItem name %s link %s lines %d", tostring(itemName), tostring(itemLink), self.Tooltip:NumLines())) -- test
		if itemName and itemLink and self.Tooltip:NumLines() > 0 then
			self:SetBuff(recipe)
			cached = cached + 1
		end

		--local itemName, itemLink, itemQuality = GetItemInfo(itemID) -- Check WDB cache
		--if itemName and itemLink and itemQuality then
		--	--local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
		--	--local hyperLink = hex.. "|H".. itemLink .."|h["..itemName.."]|h" .. FONT_COLOR_CODE_CLOSE
		--	--self.ItemCache[itemName] = hyperLink
		--
		--
		--	cached = cached + 1
		--end

		total = total + 1
	end

	self:Print(format("Cached %d / %d recipes", cached, total))
	if cached < total then
		self:Print("Some recipes were not cached. Please reload your UI after a few minutes to try again.")
	end
end

--function BitesCookBook:GetItemLinkByName(name)
--	if self.ItemCache[name] then
--		return self.ItemCache[name]
--	end
--
--	for itemID = 1, 25818 do
--		local itemName, itemLink, itemQuality = GetItemInfo(itemID)
--		if itemName == name and itemLink and itemQuality then
--			local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
--			local hyperLink = hex.. "|H".. itemLink .."|h["..itemName.."]|h" .. FONT_COLOR_CODE_CLOSE
--			self.ItemCache[name] = hyperLink
--			return hyperLink
--		end
--	end
--end

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
