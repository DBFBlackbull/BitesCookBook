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

local indent = "    "
local questionMarkIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
local wellFedIcon = "Interface\\Icons\\SPELL_Misc_Food" -- test this

local BCB_Tooltip = getglobal("BitesCookBookTooltip") or CreateFrame("GameTooltip", "BitesCookBookTooltip", nil, "GameTooltipTemplate")
local BCB_Prefix = "BitesCookBookTooltip"
local function findBuff(itemLink, buffIcon)
	if not itemLink then
		return
	end

	BCB_Tooltip:ClearLines()
	BCB_Tooltip:SetHyperlink(itemLink)
	local MAX_LINES = BCB_Tooltip:NumLines()
	for i = 1, MAX_LINES do
		local lineText = getglobal(BCB_Prefix.."TextLeft"..i):GetText()
		if lineText then
			-- If you spend at least 10 seconds eating you will become well fed and gain 12 Stamina and Spirit for 15 min.
			-- If you spend at least 10 seconds eating you will become well fed and gain 6 Mana every 5 seconds for 15 min.
			local _, _, wellFed = string.find(lineText, "well fed and gain (.-)%.")
			if wellFed then
				return wellFed, buffIcon or wellFedIcon -- Sagefish Delight and Dirge's Kickin' Chimaerok Chops has custom icons
			end

			-- Occasionally belch flame at enemies struck in melee for the next 10 min.
			local _, _, dragonBreathChili = string.find(lineText, "(Occasionally belch flame at enemies struck in melee for the next 10 min)%.")
			if dragonBreathChili then
				return dragonBreathChili, buffIcon or questionMarkIcon
			end

			-- Also increases your Stamina by 10 for 10 min.
			-- Also increases your Stamina by 10 for 10 min.
			-- Also increases your Intellect by 10 for 10 min.
			-- Also increases your Spirit by 10 for 10 min.
			-- If you eat for 10 seconds will also increase your Agility by 10 for 10 min.
			local _, _, fishStat, fishAmount, fishText = string.find(lineText, "[Aa]lso increases your (.*) by (%d+) (for %d+ min)%.")
			if fishStat and fishAmount and fishText then
				local fishBuff = format("%s %s %s", fishAmount, fishStat, fishText) -- format buff like Well Fed
				return fishBuff, buffIcon or questionMarkIcon
			end

			-- Also restores 8 Mana every 5 seconds for 10 min.
			-- Also restores 6 health every 5 seconds for 10 min.
			local _, _, fishRegen = string.find(lineText, "[Aa]lso restores (.*)%.")
			if fishRegen then
				return fishRegen, buffIcon or questionMarkIcon
			end
		end
	end
end

-- Setup to prevent memory leaks from creating new textures on every run
local iconPool = {}
local activeIcons = {}
local function acquireIcon(tooltip)
	local icon = table.remove(iconPool)
	if not icon then
		icon = tooltip:CreateTexture(nil, "ARTWORK")
	end

	icon:SetParent(tooltip)
	icon:Show()

	table.insert(activeIcons, icon)

	return icon
end

local function hideIcons()
	local icon = table.remove(activeIcons)
	while icon do
		icon:Hide()
		table.insert(iconPool, icon)

		icon = table.remove(activeIcons)
	end
end

local function addIcon(tooltip, iconTexture, xOffset)
	local line = _G[tooltip:GetName().."TextLeft"..tooltip:NumLines()]
	line:SetText(indent .. line:GetText()) -- Indent to make room for the icon
	local _, size = line:GetFont()
	local icon = acquireIcon(tooltip)
	icon:SetTexture(iconTexture)
	icon:SetWidth(size)
	icon:SetHeight(size)
	icon:SetPoint("RIGHT", line, "LEFT", xOffset, 0)
end

function BitesCookBook:AddIngredientRecipes(tooltip, itemLink)
	-- Hide icons from last run
	hideIcons()

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
			local recipe = self.Recipes[recipeID]
			local craftableName, craftableLink, _, _, _, _, _, _, craftableIcon = GetItemInfo(recipeID)
			craftableName = craftableName or recipeID
			craftableIcon = craftableIcon or questionMarkIcon
			local craftableColor = self:GetCraftableColor(recipeID)

			-- Show the recipe icon if the option is enabled.
			local text = craftableColor .. craftableName.. FONT_COLOR_CODE_CLOSE

			if self.Options.ShowCraftableFirstRank then
				local RankingRange = recipe["Range"]
				local FirstRangeText = RankingRange[1] > 1 and RankingRange[1] or self.L["Starter"]

				-- When the first rank is 1, it's a starter recipe.
				text = text .. self.TextColors["White"] .. " ("
				text = text .. self.TextColors["Orange"] .. FirstRangeText

				if self.Options.ShowCraftableRankRange then
					text = text .. " " .. self.TextColors["Yellow"] .. RankingRange[2] .. " ".. self.TextColors["Green"].. RankingRange[3] .. " ".. self.TextColors["Gray"].. RankingRange[4]
				end
				text = text .. self.TextColors["White"] .. ")"
			end

			if self.Options.ShowCraftableFaction and recipe["Faction"] then
				text = text .. self.TextColors["White"] .. " (" .. recipe["Faction"] .. ")"
			end

			table.insert(recipes, {text = text, icon = craftableIcon, link = craftableLink, buffIcon = recipe["BuffIcon"]})
		end
	end

	if not recipes[1] then
		return
	end

	tooltip:AddLine(self.L["IngredientFor:"])
	for _, recipe in ipairs(recipes) do
		tooltip:AddLine(indent .. recipe.text)
		if self.Options.ShowCraftableIcon then
			addIcon(tooltip, recipe.icon, 22)
		end

		if self.Options.ShowCraftableBuff then
			local buff, buffIcon = findBuff(recipe.link, recipe.buffIcon)
			if buff then
				tooltip:AddLine(indent .. indent .. buff)
				if self.Options.ShowCraftableIcon then
					addIcon(tooltip, buffIcon, 33)
				end
			end
		end
	end

	tooltip:Show()
end


function BitesCookBook:HookTooltips()
	hooksecurefunc(ItemRefTooltip, "Hide", hideIcons)
	hooksecurefunc(GameTooltip, "Hide", hideIcons)

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
		BitesCookBook:AddIngredientRecipes(GameTooltip, GetInventoryItemLink(unit, slot))
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
		BitesCookBook:AddIngredientRecipes(GameTooltip, BitesCookBook:GetItemLinkByName(itemName))
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
	["Alliance"] = "|cFF162c57",
	["Horde"] = "|cFF8C1616",
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
	if self.Options.HasModifier == 1 and self.ModifierKeys[self.Options.ModifierKey]() == not ModifierValue then
		return true
	end

	-- Otherwise, check if the recipe is in the player's range.
	local RankingRange = self.Recipes[RecipeId]["Range"]
	local MinimumCategory = self.Options.MinRankCategory
	local MaximumCategory = self.Options.MaxRankCategory

	-- We need to find which category the recipe is in based on its RankingRange and the player's rank.
	local RecipeCategory = self:GetCategoryInRange(RankingRange, self.CookingSkillRank)
	if RecipeCategory >= MinimumCategory and RecipeCategory <= MaximumCategory then
		return true
	end

	return false
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

function BitesCookBook:GetCraftableColor(craftableID)
	local RankingRange = self.Recipes[craftableID]["Range"] -- Range of ranks when recipe level-up changes.
	local MyRank = self.CookingSkillRank

	local ShouldGrayTheUnavailable = self.Options.GrayHighCraftables
	if ShouldGrayTheUnavailable and MyRank < RankingRange[1] then
		return self.TextColors["Gray"] -- Gray color.
	end

	local ShouldColorByRank = self.Options.ColorCraftableByRank
	if ShouldColorByRank then
		return self:GetColorInRange(RankingRange, MyRank)
	end

	-- Default color is white.
	return self.TextColors["White"]
end

function BitesCookBook:GetColorInRange(range, rank)
	if rank < range[1] then
		return self.TextColors["Red"]
	end
	if rank < range[2] then
		return self.TextColors["Orange"]
	end
	if rank < range[3] then
		return self.TextColors["Yellow"]
	end
	if rank < range[4] then
		return self.TextColors["Green"]
	end

	return self.TextColors["Gray"]
end
