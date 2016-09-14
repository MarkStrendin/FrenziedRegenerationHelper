
local function boolToString(val)
     if (val == true) then
          return "TRUE";
     else
          return "FALSE";
     end
end

local function chkOnChange(self)
     -- Use this callback to run another callback, passed as a parameter initially
     if (self:GetChecked() == nil) then
     else
          self.callback_setter(self:GetChecked());
     end

     FRH_HealValueDisplayWindow_CheckIfWindowShouldBeShown();
end

local function placeCheckBox(parent, xpos, ypos, checkboxName, in_value, out_callback, checkboxlabel, checkboxtooltip)
     local checkbox = CreateFrame("CheckButton", "chk_"..checkboxName, parent, "InterfaceOptionsCheckButtonTemplate");
     checkbox:ClearAllPoints();
     checkbox:SetPoint('TOPLEFT', parent, 'TOPLEFT', xpos, ypos*-1)
     checkbox:SetChecked(FRHelper_ParseBool(in_value));
     checkbox:SetScript("OnClick", chkOnChange)

     checkbox.callback_setter = out_callback;

     checkbox.label = _G[checkbox:GetName() .. "Text"] -- I don't understand why this works, but it does
     checkbox.label:SetText(checkboxlabel);
     checkbox.tooltipText = checkboxlabel;
     checkbox.tooltipRequirement = checkboxtooltip;
end

local function populate_options_panel(parent)
     placeCheckBox(parent, 20, 70, "showDebugMessages", FRHelperOptions_Get_ShowDebugMessages() , FRHelperOptions_Set_ShowDebugMessages, "Show Debug Messages", "Show extra debug messages in chat window");
     placeCheckBox(parent, 20, 100, "hideOutsideBearForm", FRHelperOptions_Get_HideOutsideBearForm() , FRHelperOptions_Set_HideOutsideBearForm, "Only show when in bear form", "Hides the number frame if you are not in bear form.");
     placeCheckBox(parent, 20, 130, "showDamageType",  FRHelperOptions_Get_ShowDamageTypeBar() , FRHelperOptions_Set_ShowDamageTypeBar, "Show damage type indicator", "Show a colored bar along the bottom of the frame to indicate how much of the damage taken was physical or magical.");
end

function FRHelper_initOptionsPanel()
     local OptionsPanel = CreateFrame("Frame", "FrenziedRegenerationOptionsPanel", InterfaceOptionsFramePanelContainer);
     OptionsPanel:Hide()
     OptionsPanel:SetAllPoints()
     OptionsPanel.name = FRHelperStatic.addonName;

     local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
     title:SetPoint("TOPLEFT", 16, -16)
     title:SetText(FRHelperStatic.addonNameWithSpaces)

     local subText = OptionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
     subText:SetMaxLines(3)
     subText:SetNonSpaceWrap(true)
     subText:SetJustifyV('TOP')
     subText:SetJustifyH('LEFT')
     subText:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
     subText:SetPoint('RIGHT', -32, 0)
     subText:SetText("Version " .. FRHelperStatic.addonVersion)

     populate_options_panel(OptionsPanel);

     InterfaceOptions_AddCategory(OptionsPanel, FRHelperStatic.addonName)

end
