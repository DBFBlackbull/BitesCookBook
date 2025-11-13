local Locale = BitesCookBook.Locales[GetLocale()] or BitesCookBook.Locales["enUS"] -- The default locale is English.

--------------------------------------------------------------------------------
-- Exclusive option functions
--------------------------------------------------------------------------------

local function FrameSwitch(AffectedFrame, ShouldBeEnabled)
    if ShouldBeEnabled then
        AffectedFrame:Enable()
        getglobal(AffectedFrame:GetName() .. 'Text'):SetTextColor(1, 1, 1)
    else
        AffectedFrame:Disable()
        getglobal(AffectedFrame:GetName() .. 'Text'):SetTextColor(0.5, 0.5, 0.5)
        AffectedFrame:SetChecked(false) -- Uncheck the box.
    end
end

local function PreventLevelRange()
    local AffectedFrame = BitesCookBook_ConfigFrame["ShowCraftableRankRange"]

    if not BitesCookBook.Options["ShowCraftableFirstRank"] then -- Beware of the NOT!
        BitesCookBook.Options["ShowCraftableRankRange"] = false
        FrameSwitch(AffectedFrame, false)
    else
        FrameSwitch(AffectedFrame, true)
    end
end

local function PreventColor()
    local AffectedFrame = BitesCookBook_ConfigFrame["ColorCraftableByRank"]

    if BitesCookBook.Options["GrayHighCraftables"] then
        BitesCookBook.Options["ColorCraftableByRank"] = false
        FrameSwitch(AffectedFrame, false)
    else
        FrameSwitch(AffectedFrame, true)
    end
end

local function PreventGray()
    local AffectedFrame = BitesCookBook_ConfigFrame["GrayHighCraftables"]

    if BitesCookBook.Options["ColorCraftableByRank"] then
        BitesCookBook.Options["GrayHighCraftables"] = false
        FrameSwitch(AffectedFrame, false)
    else
        FrameSwitch(AffectedFrame, true)
    end
end

local function PreventDropColor()
    local AffectedFrame = BitesCookBook_ConfigFrame["ColorDropsByRank"]

    if not BitesCookBook.Options["ShowEnemyTooltip"] then
        BitesCookBook.Options["ColorDropsByRank"] = false
        FrameSwitch(AffectedFrame, false)
    else
        FrameSwitch(AffectedFrame, true)
    end
end

local function PreventAllIngredients()
    local AffectedFrames = {"ShowCraftableFirstRank", "ShowCraftableRankRange", "HideReagentTooltipsButHint", "GrayHighCraftables", "ColorCraftableByRank", "ShowCraftableIcon"}
    
    -- Iterate over the frames and disable them if the option is checked.
    for i, frame_name in ipairs(AffectedFrames) do
        local AffectedFrame = BitesCookBook_ConfigFrame[frame_name]
        if not BitesCookBook.Options["ShowIngredientTooltip"] then  -- Beware of the NOT!
            BitesCookBook.Options[frame_name] = false
            FrameSwitch(AffectedFrame, false)
        else
            FrameSwitch(AffectedFrame, true)
        end
        
        -- Update other functions as well. What is the best way to do this?
        PreventLevelRange()
    end
end

local function PreventAllIngredientsFromHint()
    local AffectedFrames = {"ShowCraftableFirstRank", "ShowCraftableRankRange", "GrayHighCraftables", "ColorCraftableByRank", "ShowCraftableIcon"}
    
    -- Iterate over the frames and disable them if the option is checked.
    for i, frame_name in ipairs(AffectedFrames) do
        local AffectedFrame = BitesCookBook_ConfigFrame[frame_name]
        if BitesCookBook.Options["HideReagentTooltipsButHint"] then
            BitesCookBook.Options[frame_name] = false
            FrameSwitch(AffectedFrame, false)
        else
            FrameSwitch(AffectedFrame, true)
        end

        -- Update other functions as well. What is the best way to do this?
        PreventLevelRange()
    end
end

--------------------------------------------------------------------------------

-- Keep track of the vertical position of option items.
local Position = -10
local DeltaP_Box = 29
local RankIdToColor = {"Gray", "Green", "Yellow", "Orange", "Red"}

function BitesCookBook:InitializeOptionsMenu()
    BitesCookBook_ConfigFrame = CreateFrame("Frame", "BitesCookBook_InterfaceOptionsPanel", UIParent)
    BitesCookBook_ConfigFrame.name = "Bites"
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(BitesCookBook_ConfigFrame)
    else
        local category, layout = _G.Settings.RegisterCanvasLayoutCategory(BitesCookBook_ConfigFrame, BitesCookBook_ConfigFrame.name)
		_G.Settings.RegisterAddOnCategory(category)
    end


    BitesCookBook_ConfigFrame.Ingredients = BitesCookBook:CreateTitle("Ingredients", Locale["OptIngTitle"], Locale["OptIngDesc"])

    BitesCookBook:CreateCheckBox("ShowIngredientTooltip", Locale["ShowIngredientTooltip"], PreventAllIngredients)    
    BitesCookBook:CreateCheckBox("HideReagentTooltipsButHint", Locale["HideReagentTooltipsButHint"], PreventAllIngredientsFromHint)

    BitesCookBook:CreateCheckBox("ShowCraftableFirstRank", Locale["ShowCraftableFirstRank"], PreventLevelRange)
    local AllLevelRangesBox = BitesCookBook:CreateCheckBox("ShowCraftableRankRange", Locale["ShowCraftableRankRange"])
    AllLevelRangesBox:SetPoint("TOPLEFT", 20 + 20, -Position + DeltaP_Box)

    BitesCookBook:CreateCheckBox("GrayHighCraftables", Locale["GrayHighCraftables"], PreventColor)
    BitesCookBook:CreateCheckBox("ColorCraftableByRank", Locale["ColorCraftableByRank"], PreventGray)
    BitesCookBook:CreateCheckBox("ShowCraftableIcon", Locale["ShowCraftableIcon"])    
    
    BitesCookBook_ConfigFrame.Misc = BitesCookBook:CreateTitle("Misc", Locale["Misc"], "")
    BitesCookBook:CreateCheckBox("ShowCraftableTooltip", Locale["ShowCraftableTooltip"])
    BitesCookBook:CreateCheckBox("ShowEnemyTooltip", Locale["ShowEnemyTooltip"], PreventDropColor)
    local ColorsDrop = BitesCookBook:CreateCheckBox("ColorDropsByRank", Locale["ColorDropsByRank"])
    ColorsDrop:SetPoint("TOPLEFT", 20 + 20, -Position + DeltaP_Box)
    
    -- A horizontal sliding bar that controls the min level.
    BitesCookBook_ConfigFrame.DeltaRankMin = CreateFrame("Slider", "BitesCookBook_MaxLevel", BitesCookBook_ConfigFrame, "OptionsSliderTemplate")
    BitesCookBook_ConfigFrame.DeltaRankMin:SetMinMaxValues(1, 5)
    BitesCookBook_ConfigFrame.DeltaRankMin:SetValueStep(1)
    BitesCookBook_ConfigFrame.DeltaRankMin:SetObeyStepOnDrag(true)
    BitesCookBook_ConfigFrame.DeltaRankMin:SetOrientation("HORIZONTAL")
    BitesCookBook_ConfigFrame.DeltaRankMin:SetSize(200, 20)
    BitesCookBook_ConfigFrame.DeltaRankMin:SetPoint("TOPLEFT", 10, -Position - DeltaP_Box)
    BitesCookBook_ConfigFrame.DeltaRankMin:SetScript("OnValueChanged",
    function(self, value)
        local RankColor = BitesCookBook.TextColors[RankIdToColor[value]]
        local RankText = Locale["RankColor_".. value]

        BitesCookBook.Options.MinRankCategory = value
        BitesCookBook_ConfigFrame.DeltaRankMin.text:SetText(Locale["LowerLimit"].. " ".. RankColor.. RankText.. "|r")
    end)
    local RankColor = BitesCookBook.TextColors[RankIdToColor[BitesCookBook.Options.MinRankCategory]]
    local RankText = Locale["RankColor_".. BitesCookBook.Options.MinRankCategory]

    BitesCookBook_ConfigFrame.DeltaRankMin.text = BitesCookBook_ConfigFrame.DeltaRankMin:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    BitesCookBook_ConfigFrame.DeltaRankMin.text:SetPoint("BOTTOMLEFT", BitesCookBook_ConfigFrame.DeltaRankMin, "TOPLEFT", 0, 0)
    BitesCookBook_ConfigFrame.DeltaRankMin.text:SetText(Locale["LowerLimit"].. " ".. RankColor.. RankText.. "|r")
    BitesCookBook_ConfigFrame.DeltaRankMin:SetValue(BitesCookBook.Options.MinRankCategory)
    BitesCookBook_ConfigFrame.DeltaRankMin.Low:SetText(BitesCookBook.TextColors["Gray"].. "Gray".. "|r")
    BitesCookBook_ConfigFrame.DeltaRankMin.High:SetText(BitesCookBook.TextColors["Red"].. "Red".. "|r")

    -- A horizontal sliding bar that controls the max level.
    BitesCookBook_ConfigFrame.DeltaRankMax = CreateFrame("Slider", "BitesCookBook_MaxLevel", BitesCookBook_ConfigFrame, "OptionsSliderTemplate")
    BitesCookBook_ConfigFrame.DeltaRankMax:SetMinMaxValues(1, 5)
    BitesCookBook_ConfigFrame.DeltaRankMax:SetValueStep(1)
    BitesCookBook_ConfigFrame.DeltaRankMax:SetObeyStepOnDrag(true)
    BitesCookBook_ConfigFrame.DeltaRankMax:SetOrientation("HORIZONTAL")
    BitesCookBook_ConfigFrame.DeltaRankMax:SetSize(200, 20)
    BitesCookBook_ConfigFrame.DeltaRankMax:SetPoint("TOPLEFT", 250, -Position - DeltaP_Box)
    BitesCookBook_ConfigFrame.DeltaRankMax:SetScript("OnValueChanged",
    function(self, value)
        local RankColor = BitesCookBook.TextColors[RankIdToColor[value]]
        local RankText = Locale["RankColor_".. value]

        BitesCookBook.Options.MaxRankCategory = value
        BitesCookBook_ConfigFrame.DeltaRankMax.text:SetText(Locale["UpperLimit"].. " ".. RankColor.. RankText.. "|r")
    end)
    local RankColor = BitesCookBook.TextColors[RankIdToColor[BitesCookBook.Options.MaxRankCategory]]
    local RankText = Locale["RankColor_".. BitesCookBook.Options.MaxRankCategory]

    BitesCookBook_ConfigFrame.DeltaRankMax.text = BitesCookBook_ConfigFrame.DeltaRankMax:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    BitesCookBook_ConfigFrame.DeltaRankMax.text:SetPoint("BOTTOMLEFT", BitesCookBook_ConfigFrame.DeltaRankMax, "TOPLEFT", 0, 0)
    BitesCookBook_ConfigFrame.DeltaRankMax.text:SetText(Locale["UpperLimit"].. " ".. RankColor.. RankText.. "|r")
    BitesCookBook_ConfigFrame.DeltaRankMax:SetValue(BitesCookBook.Options.MaxRankCategory)
    BitesCookBook_ConfigFrame.DeltaRankMax.Low:SetText(BitesCookBook.TextColors["Gray"].. "Gray".. "|r")
    BitesCookBook_ConfigFrame.DeltaRankMax.High:SetText(BitesCookBook.TextColors["Red"].. "Red".. "|r")

    Position = Position + DeltaP_Box + 20

    PreventColor()
    PreventGray()
    PreventDropColor()
    PreventLevelRange()

    -- A dropdrown frame.
    BitesCookBook_ConfigFrame.show_or_hide = CreateFrame("Frame", "BitesCookBook_Dropdown", BitesCookBook_ConfigFrame, "UIDropDownMenuTemplate")
    BitesCookBook_ConfigFrame.show_or_hide:SetPoint("TOPLEFT", 10, -Position - DeltaP_Box)
    BitesCookBook_ConfigFrame.show_or_hide.text = BitesCookBook_ConfigFrame.show_or_hide:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    BitesCookBook_ConfigFrame.show_or_hide.text:SetPoint("BOTTOMLEFT", BitesCookBook_ConfigFrame.show_or_hide, "TOPLEFT", 21, 0)
    BitesCookBook_ConfigFrame.show_or_hide.text:SetText(Locale["WhenModifierPressed"])
    -- Set the text of the dropdown.
    
    if BitesCookBook.Options.HasModifier == 0 then
        UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["DoNothing"])
    elseif BitesCookBook.Options.HasModifier == 1 then
        UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["UnlockFilters"])
    elseif BitesCookBook.Options.HasModifier == true then
        UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["ShowTooltip"])
    else
        UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["HideTooltip"])
    end

    -- Add the Options to the dropdown.
    UIDropDownMenu_Initialize(BitesCookBook_ConfigFrame.show_or_hide, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.arg1, info.func, info.checked = Locale["DoNothing"], Locale["DoNothing"],
        function(self)
            BitesCookBook.Options.HasModifier = 0
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["DoNothing"])
        end,
        BitesCookBook.Options.HasModifier == 0
        UIDropDownMenu_AddButton(info)

        --------------------
        info.text, info.arg1, info.func, info.checked = Locale["ShowTooltip"], Locale["ShowTooltip"],
        function(self)
            BitesCookBook.Options.HasModifier = true
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["ShowTooltip"])
        end,
        BitesCookBook.Options.HasModifier == true
        UIDropDownMenu_AddButton(info)
        
        --------------------
        info.text, info.arg1, info.func, info.checked = Locale["HideTooltip"], Locale["HideTooltip"],
        function(self)
            BitesCookBook.Options.HasModifier = false
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["HideTooltip"])
        end,
        BitesCookBook.Options.HasModifier == false
        UIDropDownMenu_AddButton(info)

        --------------------
        info.text, info.arg1, info.func, info.checked = Locale["UnlockFilters"], Locale["UnlockFilters"],
        function(self)
            BitesCookBook.Options.HasModifier = 1
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.show_or_hide, Locale["UnlockFilters"])
        end,
        BitesCookBook.Options.HasModifier == 1
        UIDropDownMenu_AddButton(info)
    end)

    -- A dropdrown frame.
    BitesCookBook_ConfigFrame.modifier = CreateFrame("Frame", "BitesCookBook_DropdownModifier", BitesCookBook_ConfigFrame, "UIDropDownMenuTemplate")
    BitesCookBook_ConfigFrame.modifier:SetPoint("TOPLEFT", 250, -Position - DeltaP_Box)
    BitesCookBook_ConfigFrame.modifier.text = BitesCookBook_ConfigFrame.modifier:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    BitesCookBook_ConfigFrame.modifier.text:SetPoint("BOTTOMLEFT", BitesCookBook_ConfigFrame.modifier, "TOPLEFT", 21, 0)
    BitesCookBook_ConfigFrame.modifier.text:SetText(Locale["ModifierKey"])
    
    UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.modifier, BitesCookBook.Options.ModifierKey.. Locale["Key"])

    -- Add the Options to the dropdown.
    UIDropDownMenu_Initialize(BitesCookBook_ConfigFrame.modifier, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.arg1, info.func, info.checked = "SHIFT".. Locale["Key"], "SHIFT".. Locale["Key"],
        function(self)
            BitesCookBook.Options.ModifierKey = "SHIFT"
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.modifier, BitesCookBook.Options.ModifierKey.. Locale["Key"])
        end,
        BitesCookBook.Options.ModifierKey == "SHIFT"
        UIDropDownMenu_AddButton(info)

        --------------------
        info.text, info.arg1, info.func, info.checked = "CTRL".. Locale["Key"], "CTRL".. Locale["Key"],
        function(self)
            BitesCookBook.Options.ModifierKey = "CTRL"
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.modifier, BitesCookBook.Options.ModifierKey.. Locale["Key"])
        end,
        BitesCookBook.Options.ModifierKey == "CTRL"
        UIDropDownMenu_AddButton(info)

        --------------------
        info.text, info.arg1, info.func, info.checked = "ALT".. Locale["Key"], "ALT".. Locale["Key"],
        function(self)
            BitesCookBook.Options.ModifierKey = "ALT"
            UIDropDownMenu_SetText(BitesCookBook_ConfigFrame.modifier, BitesCookBook.Options.ModifierKey.. Locale["Key"])
        end,
        BitesCookBook.Options.ModifierKey == "ALT"
        UIDropDownMenu_AddButton(info)
    end)
end

function BitesCookBook:CreateTitle(Name, ShortDescription, LongDescription)
    Position = Position +25
    BitesCookBook_ConfigFrame[Name] = CreateFrame("Frame", "BitesCookbook".. Name, BitesCookBook_ConfigFrame)
    BitesCookBook_ConfigFrame[Name]:SetPoint("TOPLEFT", BitesCookBook_ConfigFrame, "TOPLEFT", 10, -Position)

    BitesCookBook_ConfigFrame[Name.. "_Title"] = BitesCookBook_ConfigFrame[Name]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BitesCookBook_ConfigFrame[Name.. "_Title"]:SetPoint("TOPLEFT", BitesCookBook_ConfigFrame, "TOPLEFT", 10, -Position)
    BitesCookBook_ConfigFrame[Name.. "_Title"]:SetText("|r".. ShortDescription .." |r")
    BitesCookBook_ConfigFrame[Name.. "_Title"]:SetFont("Fonts\\FRIZQT__.TTF", 13)

    BitesCookBook_ConfigFrame[Name.. "_Desc"] = BitesCookBook_ConfigFrame[Name]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BitesCookBook_ConfigFrame[Name.. "_Desc"]:SetPoint("TOPLEFT", BitesCookBook_ConfigFrame, "TOPLEFT", 10, -Position -20)
    BitesCookBook_ConfigFrame[Name.. "_Desc"]:SetText("|cffffffff".. LongDescription .." |r")
    BitesCookBook_ConfigFrame[Name.. "_Desc"]:SetFont("Fonts\\FRIZQT__.TTF", 10)

    if LongDescription == "" then
        Position = Position +20
    else
        Position = Position +35
    end

    return BitesCookBook_ConfigFrame[Name]
end

function BitesCookBook:CreateCheckBox(Name, Description, ExtraFunction) -- Warning, name of checkbox is same as the variable it changes!
    BitesCookBook_ConfigFrame[Name] = CreateFrame("CheckButton", "BitesCookBook".. Name, BitesCookBook_ConfigFrame, "UICheckButtonTemplate")
    BitesCookBook_ConfigFrame[Name]:SetPoint("TOPLEFT", 20, -Position)
    
    getglobal(BitesCookBook_ConfigFrame[Name]:GetName() .. 'Text'):SetText(Description)
    getglobal(BitesCookBook_ConfigFrame[Name]:GetName() .. 'Text'):SetTextColor(1, 1, 1, 1)

    BitesCookBook_ConfigFrame[Name]:SetChecked(BitesCookBook.Options[Name])
    BitesCookBook_ConfigFrame[Name]:SetScript("OnClick",
        function()
            BitesCookBook.Options[Name] = not BitesCookBook.Options[Name]

            -- Sometimes we want to do something extra after the checkbox is clicked.
            if ExtraFunction ~= nil then
                ExtraFunction()
            end
        end
    )

    Position = Position +DeltaP_Box

    return BitesCookBook_ConfigFrame[Name]
end