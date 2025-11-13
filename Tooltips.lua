local _G = getfenv(0)
local function hooksecurefunc(arg1, arg2, arg3)
	if type(arg1) == "string" then
		arg1, arg2, arg3 = _G, arg1, arg2
	end
	local orig = arg1[arg2]
	arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
		local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

		arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

		return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
	end
end

function BitesCookBook:AddIngredientRecipes(tooltip, itemLink)
	--- Shows all available recipes for that ingredient.
	local itemID = self:GetItemIDFromLink(itemLink)
	if not itemID then
		return
	end

	if not self.CraftablesForReagent[itemID] then return end

	local recipes = {}
	-- Cycle through all recipes that use the ingredient to create the tooltip.
	for _, recipeID in ipairs(self.CraftablesForReagent[itemID]) do
		if self:IsRecipeInRange(recipeID) then
			local craftableName, craftableIcon = self:GetItemNameAndIconByID(recipeID)
			local craftableColor = self:GetCraftableColor(recipeID)

			-- Show the recipe icon if the option is enabled.
			craftableIcon = self.Options.ShowCraftableIcon and "|T".. craftableIcon .. ":0|t " or ""

			local text = "    " .. craftableIcon .. craftableColor .. craftableName.. FONT_COLOR_CODE_CLOSE

			local ShowFirstLevel = self.Options.ShowCraftableFirstRank
			local ShowLevelRange = self.Options.ShowCraftableRankRange

			if ShowFirstLevel then
				local RankingRange = self.Recipes[recipeID]["Range"]
				local FirstRangeText = RankingRange[1] > 1 and RankingRange[1] or Locale["Starter"]

				-- When the first rank is 1, it's a starter recipe.
				text = text .. "-" .. self.TextColors["Orange"] .. FirstRangeText .. FONT_COLOR_CODE_CLOSE

				if ShowLevelRange then
					text = text .. FONT_COLOR_CODE_CLOSE .. "-" .. self.TextColors["Yellow"] .. RankingRange[2] .. FONT_COLOR_CODE_CLOSE .. "-".. BitesCookBook.TextColors["Green"].. RankingRange[3].. FONT_COLOR_CODE_CLOSE .. "-".. BitesCookBook.TextColors["Gray"].. RankingRange[4].. FONT_COLOR_CODE_CLOSE
				end
			end

			table.insert(recipes, text)
		end
	end

	if not recipes[1] then
		return
	end

	tooltip:AddLine(self.L["IngredientFor:"])
	for _, recipe in ipairs(recipes) do
		tooltip:AddLine(recipe)
	end

	tooltip:Show()
end


function BitesCookBook:HookTooltips()
	hooksecurefunc("ChatFrame_OnHyperlinkShow", function(itemLink, text, button)
		BitesCookBook:AddIngredientRecipes(ItemRefTooltip, itemLink)
	end)

	-- Hook loot tooltip
	hooksecurefunc(GameTooltip, "SetLootItem", function(tip, lootIndex)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetLootSlotLink(lootIndex))
	end)

	hooksecurefunc(GameTooltip, "SetLootRollItem", function(tip, lootIndex)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetLootRollItemLink(lootIndex))
	end)

	-- Hook bag tooltip
	hooksecurefunc(GameTooltip, "SetBagItem", function(tip, bag, slot)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetContainerItemLink(bag, slot))
	end)

	-- Hook bank tooltip
	hooksecurefunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetInventoryItemCount(unit, slot))
	end)

	-- Hook hyper links, used for BankItems and Bagnon_Forever addons
	hooksecurefunc(GameTooltip, "SetHyperlink", function(tip, itemLink, count)
		BitesCookBook:AddIngredientRecipes(GameTooltip, itemLink)
	end)

	-- Hook player trade tooltip
	hooksecurefunc(GameTooltip, "SetTradePlayerItem", function(self, index)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetTradePlayerItemLink(index))
	end)

	-- Hook target trade tooltip
	hooksecurefunc(GameTooltip, "SetTradeTargetItem", function(self, index)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetTradeTargetItemLink(index))
	end)

	-- Hook inbox items
	hooksecurefunc(GameTooltip, "SetInboxItem", function(self, mailIndex, attachmentIndex)
		if GetInboxItemLink then
			return BitesCookBook:AddIngredientRecipes(GameTooltip, GetInboxItemLink(mailIndex, attachmentIndex))
		end

		local itemName = GetInboxItem(mailIndex, attachmentIndex)
		BitesCookBook:AddIngredientRecipes(GameTooltip, BitesCookBook:GetItemLinkByName(itemName))
	end)

	-- Hook send mail items
	hooksecurefunc(GameTooltip, "SetSendMailItem", function(self, attachmentIndex)
		if GetSendMailItemLink then
			return BitesCookBook:AddIngredientRecipes(GameTooltip, GetSendMailItemLink(attachmentIndex))
		end

		local itemName = GetSendMailItem(attachmentIndex)
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetItemLinkByName(itemName))
	end)
end

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- test the font colors
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

function BitesCookBook:GetItemIDFromLink(itemLink)
	if not itemLink then
		return
	end

	local foundID, _ , itemID = string.find(itemLink, "item:(%d+)")
	if not foundID then
		return
	end

	return tonumber(itemID)
end

function BitesCookBook:GetItemNameAndIconByID(ItemID)
	local itemName, _, _, _, _, _, _, _, itemIcon = GetItemInfo(ItemID)

	-- Sometimes WoW won't find the name immediately.
	itemName = itemName or ""
	itemIcon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
	return itemName, itemIcon
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
