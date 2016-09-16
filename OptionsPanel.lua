

local function checkboxCallbackHandler(sender)
     -- Use this callback to run another callback, passed as a parameter initially
     if (sender:GetChecked() == nil) then
     else
          sender.callback_setter(sender:GetChecked());
     end

     FRH_HealValueDisplayWindow_CheckIfWindowShouldBeShown();
end

local function placeCheckBox(parent, xpos, ypos, checkboxName, in_value, out_callback, checkboxlabel, checkboxtooltip)
     local checkbox = CreateFrame("CheckButton", "chk"..checkboxName, parent, "InterfaceOptionsCheckButtonTemplate");
     checkbox:ClearAllPoints();
     checkbox:SetPoint('TOPLEFT', parent, 'TOPLEFT', xpos, ypos*-1)
     checkbox:SetChecked(FRHelper_ParseBool(in_value));
     checkbox:SetScript("OnClick", checkboxCallbackHandler)

     checkbox.callback_setter = out_callback;

     checkbox.label = _G[checkbox:GetName() .. "Text"] -- I don't understand why this works, but it does
     checkbox.label:SetText(checkboxlabel);
     checkbox.tooltipText = checkboxlabel;
     checkbox.tooltipRequirement = checkboxtooltip;
end

local function sliderCallbackHandler(sender)
     -- Workaround for slider's SetValueStep not working anymore
     -- We feed a rounded value back into it
     sender:SetValue(string.format("%.0f", sender:GetValue()));
     sender.valueText:SetText(sender:GetValue());
     sender.callback_setter(sender);
end

local function placeSlider(parent, xpos, ypos, name, minvalue, maxvalue, in_value, out_callback, label)

     local sliderWidth = 300;

     local newSlider = CreateFrame("Slider", "sld"..name, parent, "OptionsSliderTemplate");
     newSlider:SetWidth(sliderWidth);
     newSlider:SetMinMaxValues(minvalue,maxvalue);
     newSlider:SetValue(in_value);
     newSlider:SetPoint("TOPLEFT", xpos, ypos * -1, "TOPLEFT");
     --newSlider:SetValueStep(1); -- SetValueStep is currently bugged (since Patch 5.4.0), and doesn't do anything
	newSlider:SetScript('OnValueChanged', sliderCallbackHandler);
     newSlider.callback_setter = out_callback;

     _G[newSlider:GetName() .. 'Text']:SetText(label)
	_G[newSlider:GetName() .. 'Text']:SetPoint('BOTTOMLEFT', newSlider, 'TOPLEFT')
	_G[newSlider:GetName() .. 'Low']:SetText(minvalue)
	_G[newSlider:GetName() .. 'High']:SetText(maxvalue);
     newSlider:Show();

     -- Also place a text box
     --local textBoxWidth = 75;
     --local newSliderEditBox = CreateFrame("EditBox", "txt"..name, parent, "InputBoxTemplate");
     --newSliderEditBox:SetAutoFocus(false);
     --newSliderEditBox:SetWidth(textBoxWidth);
     --newSliderEditBox:SetHeight(15);
     --newSliderEditBox:SetPoint("TOPRIGHT", newSlider, "TOPRIGHT", textBoxWidth + 20, 0);
     --newSliderEditBox:SetText(tonumber(string.format("%.3f", in_value)));
     --newSliderEditBox:SetNumeric(true);

     local valueText = newSlider:CreateFontString(nil, 'BACKGROUND', "GameFontHighlightSmall");
     valueText:SetJustifyH("RIGHT");
     valueText:SetPoint("BOTTOMRIGHT", newSlider, "TOPRIGHT");
     valueText:SetText(in_value);
     newSlider.valueText = valueText;

     newSlider.textBox = newSliderEditBox;
end

local function GetClawsOfUrsocBonus()
	if (IsEquippedItem("Claws of Ursoc") == true) then
		return (FRHelperOptions_Get_WildFleshBonus() * 100);
	else
		return 0;
	end
end

local function populate_options_panel(parent)

     -- This could be expanded to include things that aren't just checkboxes, if we include a variable to indicate what kind of control it should be
     -- Options to add:
     -- frame width
     -- frame height
     -- Button to reset position
     -- Checkmark to display number as percent

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
               ["name"] = "displayValueAsPercent",
               ["value"] = FRHelperOptions_Get_DisplayValueAsPercent(),
               ["callback"] = FRHelperOptions_Set_DisplayValueAsPercent,
               ["title"] = "Display heal value as percent",
               ["description"] = "Display value as percent, instead of actual number"
          },
          {
               ["name"] = "displayValueAsBar",
               ["value"] = FRHelperOptions_Get_DisplayValueAsBar(),
               ["callback"] = FRHelperOptions_Set_DisplayValueAsBar,
               ["title"] = "Display heal value as a health bar",
               ["description"] = "Display a health bar behind the number indicating the heal value"
          },
          {
               ["name"] = "hideHealValueText",
               ["value"] = FRHelperOptions_Get_HideHealValueText(),
               ["callback"] = FRHelperOptions_Set_HideHealValueText,
               ["title"] = "Hide text",
               ["description"] = "Hide the heal value text (if you want just a health bar)"
          },
          {
               ["name"] = "showDebugMessages",
               ["value"] = FRHelperOptions_Get_ShowDebugMessages(),
               ["callback"] = FRHelperOptions_Set_ShowDebugMessages,
               ["title"] = "Show Debug Messages",
               ["description"] = "Show extra debug messages in chat window"
          },
     }
     local sliders = {
          {
               ["name"] = "frameWidth",
               ["value"] = FRHelperOptions_Get_HealFrameWidth(),
               ["callback"] = FRHelper_windowWidthSliderCallback,
               ["title"] = "Frame width",
               ["minvalue"] = 30,
               ["maxvalue"] = 500,
          },
          {
               ["name"] = "frameHeight",
               ["value"] = FRHelperOptions_Get_HealFrameHeight(),
               ["callback"] = FRHelper_windowHeightSliderCallback,
               ["title"] = "Frame height",
               ["minvalue"] = 20,
               ["maxvalue"] = 200,
          },
          {
               ["name"] = "damageTypeBarHeight",
               ["value"] = FRHelperOptions_Get_DamageTypeBarHeight(),
               ["callback"] = FRHelper_DamageTypeBarHeightSliderCallback,
               ["title"] = "Damage type bar height",
               ["minvalue"] = 1,
               ["maxvalue"] = 200
          },
          {
               ["name"] = "frameAlpha",
               ["value"] = FRHelperOptions_Get_HealFrameBGAlpha(),
               ["callback"] = FRHelper_HealFrameOpacitySlidercallback,
               ["title"] = "Frame background opacity",
               ["minvalue"] = 0,
               ["maxvalue"] = 100
          },
     }
     --slider.name, width, slider.minvalue, slider.maxvalue, slider.step, slider.value, slider.callback, slider.title
     --local function placeSlider(parent, xpos, ypos, name, width, minvalue, maxvalue, step, in_value, out_callback, label)


     local controls_x =  20;
     local controls_y_start = 70;
     local checkbox_spacing = 30;
     local slider_spacing = 60;

     local current_y = controls_y_start;

     for x = 1, #checkBoxes, 1 do
          checkbox = checkBoxes[x];
          placeCheckBox(parent, controls_x, current_y, checkbox.name, checkbox.value , checkbox.callback, checkbox.title, checkbox.description);
          current_y = current_y + checkbox_spacing;
     end

     current_y = controls_y_start;
     for x = 1, #sliders, 1 do
          slider = sliders[x];
          placeSlider(parent, controls_x + 275, current_y, slider.name, slider.minvalue, slider.maxvalue, slider.value, slider.callback, slider.title)
          current_y = current_y + slider_spacing;
     end

     -- Add a blurb about wildflesh and display the current known bonus from it
     lblWildFleshBonus = parent:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge');
     lblWildFleshBonus:SetJustifyV('TOP');
     lblWildFleshBonus:SetJustifyH('LEFT');
     lblWildFleshBonus:SetPoint('BOTTOMLEFT', 16, 36);
     lblWildFleshBonus:SetText("Current known bonus from Claws of Ursoc: "..GetClawsOfUrsocBonus().."%");

     local lblWildFleshBlurb = parent:CreateFontString(nil, 'ARTWORK', 'GameFontNormal');
     lblWildFleshBlurb:SetJustifyV('TOP');
     lblWildFleshBlurb:SetJustifyH('LEFT');
     lblWildFleshBlurb:SetPoint('BOTTOMLEFT', 16, 16);
     lblWildFleshBlurb:SetText("Claws of Ursoc bonus is updated automatically when you open it's talent tree.");
end

function FRH_UpdateOptionsMenuValues()
     lblWildFleshBonus:SetText("Current known bonus from Claws of Ursoc: "..GetClawsOfUrsocBonus().."%");
end

function FRHelper_windowWidthSliderCallback(sender)
     local newWidth = sender:GetValue();
	if (newWidth ~= nil) then
		if (newWidth > 10) then
               HealValueDisplayWindow_SetWidth(newWidth);
               FRHelperOptions_Set_HealFrameWidth(newWidth);
          end
     end
end

function FRHelper_windowHeightSliderCallback(sender)
     local newHeight = sender:GetValue();
	if (newHeight ~= nil) then
		if (newHeight > 3) then
               HealValueDisplayWindow_SetHeight(newHeight);
               FRHelperOptions_Set_HealFrameHeight(newHeight);
          end
     end
end

function FRHelper_DamageTypeBarHeightSliderCallback(sender)
     local newHeight = sender:GetValue();
	if (newHeight ~= nil) then
		if (newHeight > 1) then
               HealValueDisplayWindow_DamageTypeBar_SetHeight(newHeight);
               FRHelperOptions_Set_DamageTypeBarHeight(newHeight);
          end
     end
end

function FRHelper_HealFrameOpacitySlidercallback(sender)
     local newAlpha = sender:GetValue() / 100;

	if (newAlpha ~= nil) then
		if ((newAlpha > 0) and (newAlpha < 1)) then
               HealValueDisplayWindow_SetBGAlpha(newAlpha);
               FRHelperOptions_Set_HealFrameBGAlpha(newAlpha);
          end
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
