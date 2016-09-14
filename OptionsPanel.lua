

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
     local checkBoxes = {
          {
               ["name"] = "hideOutsideBearForm",
               ["value"] = FRHelperOptions_Get_HideOutsideBearForm(),
               ["callback"] = FRHelperOptions_Set_HideOutsideBearForm,
               ["title"] = "Only show when in bear form",
               ["description"] = "Hides the number frame if you are not in bear form."
          },
          {
               ["name"] = "showDamageType",
               ["value"] = FRHelperOptions_Get_ShowDamageTypeBar(),
               ["callback"] = FRHelperOptions_Set_ShowDamageTypeBar,
               ["title"] = "Show damage type indicator",
               ["description"] = "Show a colored bar along the bottom of the frame to indicate how much of the damage taken was physical or magical."
          },
          {
               ["name"] = "showDebugMessages",
               ["value"] = FRHelperOptions_Get_ShowDebugMessages(),
               ["callback"] = FRHelperOptions_Set_ShowDebugMessages,
               ["title"] = "Show Debug Messages",
               ["description"] = "Show extra debug messages in chat window"
          },
     }

     local controls_x =  20;
     local controls_y_start = 70;
     local controls_y_spacing = 40;

     local current_y = controls_y_start;

     for x = 1, #checkBoxes, 1 do
          checkbox = checkBoxes[x];
          placeCheckBox(parent, controls_x, current_y, checkbox.name, checkbox.value , checkbox.callback, checkbox.title, checkbox.description);
          current_y = current_y + controls_y_spacing;
     end
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
