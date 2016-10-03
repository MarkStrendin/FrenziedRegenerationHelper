-- ----------------------------------------------
-- Configuration that the player can customize
-- ----------------------------------------------

-- Set a bunch of defaults, then when the addon loads, replace the defaults with
-- values from the player's saved variables

local FRHelperOptions = {};

function FRHelper_InitSavedVariables()
	local defaults = {
		hideOutsideBearForm = true,
		showDamageType = true,
		showDebugMessages = false,
		bonusHealing_WildFlesh = 0,
		healframe_width = 200,
		healframe_height = 25,
		displayValueAsPercents = false,
		displayValueAsBar = false,
		damageTypeBarHeight = 2,
		hideHealValueText = false,
		healframe_background_alpha = 0.5,
		framePositionLocked = false,
		hideOutsideCombat = false
	}

	-- If there are no saved variables at all, set all to defaults
	if (FRHelper_SavedVariables == nil) then
		FRHelper_SavedVariables = defaults
	end

	-- Go through each value to make sure they exist and if not, set to defaults
	for k,v in pairs(defaults) do
		if FRHelper_SavedVariables[k] == nil then
			FRHelper_SavedVariables[k] = v
		end
	end

	FRHelperOptions = FRHelper_SavedVariables;
	if (FRHelperOptions.showDebugMessages == true) then
		FRHelper_ShowDebugMessage("Saved variables: ");
		for k,v in pairs(FRHelperOptions) do
			FRHelper_ShowDebugMessage(" " .. k .. ": " .. tostring(v));
		end
	end

	FRHelper_initOptionsPanel();
end

-- ----------------------------------------------
-- Getters
-- ----------------------------------------------

function FRHelperOptions_Get_WildFleshBonus()
	return FRHelperOptions.bonusHealing_WildFlesh;
end

function FRHelperOptions_Get_ShowDebugMessages()
	return FRHelperOptions.showDebugMessages;
end

function FRHelperOptions_Get_HideOutsideBearForm()
	return FRHelperOptions.hideOutsideBearForm;
end

function FRHelperOptions_Get_ShowDamageTypeBar()
	return FRHelperOptions.showDamageType;
end

function FRHelperOptions_Get_HealFrameWidth()
	return FRHelperOptions.healframe_width;
end

function FRHelperOptions_Get_HealFrameHeight()
	return FRHelperOptions.healframe_height;
end

function FRHelperOptions_Get_DisplayValueAsPercent()
	return FRHelperOptions.displayValueAsPercents;
end

function FRHelperOptions_Get_DisplayValueAsBar()
	return FRHelperOptions.displayValueAsBar;
end

function FRHelperOptions_Get_HideHealValueText()
	return FRHelperOptions.hideHealValueText;
end

function FRHelperOptions_Get_DamageTypeBarHeight()
	return FRHelperOptions.damageTypeBarHeight;
end

function FRHelperOptions_Get_HealFrameBGAlpha()
	return FRHelperOptions.healframe_background_alpha;
end

function FRHelperOptions_Get_FramePositionLocked()
	return FRHelperOptions.framePositionLocked;
end

function FRHelperOptions_Get_HideOutsideCombat()
	return FRHelperOptions.hideOutsideCombat;
end


-- ----------------------------------------------
-- Setters
-- ----------------------------------------------

function FRHelperOptions_Set_WildFleshBonus(bonus)
	-- This seems to fail for some reason if it's comparing numbers, so compare strings intead
	if (tostring(bonus) ~= tostring(FRHelperOptions.bonusHealing_WildFlesh)) then
		FRHelper_ShowMessage("Updating known bonus from Claws of Ursoc to "..(bonus*100).."% (was "..(FRHelperOptions.bonusHealing_WildFlesh*100).."%)")
		FRHelperOptions.bonusHealing_WildFlesh = bonus
		FRH_UpdateOptionsMenuValues();
	end
end

function FRHelperOptions_Set_ShowDebugMessages(v)
	if (FRHelper_ParseBool(v) == false) then
		FRHelper_ShowDebugMessage("Debug messages are now disabled");
	end
	FRHelperOptions.showDebugMessages = FRHelper_ParseBool(v);
	if (FRHelper_ParseBool(v) == true) then
		FRHelper_ShowDebugMessage("Debug messages are now enabled");
	end
end

function FRHelperOptions_Set_HideOutsideBearForm(v)
	FRHelperOptions.hideOutsideBearForm = FRHelper_ParseBool(v);
end

function FRHelperOptions_Set_ShowDamageTypeBar(v)
	FRHelperOptions.showDamageType = FRHelper_ParseBool(v);
end

function FRHelperOptions_Set_HealFrameWidth(val)
	FRHelperOptions.healframe_width = val;
end

function FRHelperOptions_Set_HealFrameHeight(val)
	FRHelperOptions.healframe_height = val;
end

function FRHelperOptions_Set_DisplayValueAsPercent(val)
	FRHelperOptions.displayValueAsPercents = FRHelper_ParseBool(val);
end

function FRHelperOptions_Set_DisplayValueAsBar(val)
	FRHelperOptions.displayValueAsBar = FRHelper_ParseBool(val);
end

function FRHelperOptions_Set_HideHealValueText(val)
	FRHelperOptions.hideHealValueText = FRHelper_ParseBool(val);
end

function FRHelperOptions_Set_DamageTypeBarHeight(val)
	FRHelperOptions.damageTypeBarHeight = tonumber(val);
end

function FRHelperOptions_Set_HealFrameBGAlpha(val)
	FRHelperOptions.healframe_background_alpha = tonumber(val);
end

function FRHelperOptions_Set_FramePositionLocked(val)
	if (FRHelper_ParseBool(val) == true) then
		FRHelper_ShowMessage("Window is now locked")
	else
		FRHelper_ShowMessage("Window is now unlocked and movable")
	end
	FRHelperOptions.framePositionLocked = FRHelper_ParseBool(val);
end

function FRHelperOptions_Set_HideOutsideCombat(val)
	FRHelperOptions.hideOutsideCombat = FRHelper_ParseBool(val);
end
