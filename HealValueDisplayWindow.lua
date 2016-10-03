-- ----------------------------------------------
-- Local variables
-- ----------------------------------------------

-- Variable to track if the window is visible or not
local healValueWindowInitialized = false;
local isDamageWindowVisible = false;
local isDamageTypeBarVisible = false;
local isDamageHealthBarVisible = false;
local isHealValueTextVisible = false;

local FrenziedRegenerationHelper_HealValueWindow = CreateFrame("Frame", "FrenziedRegenerationHelper_HealValueWindow" ,UIParent);

-- ----------------------------------------------
-- General housekeeping functions
-- ----------------------------------------------

-- How should the damage number be displayed in the window
local function FormatNumber_Numeric(n)
	local intValue = math.ceil(n);

	local left,num,right = string.match(intValue,'^([^%d]*%d)(%d*)(.-)$');
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right;
end

local function FormatNumber_Percent(n)
	local playerHealth = UnitHealthMax("Player");
	if ((n == nil) or (playerHealth == nil)) then return 0; end
	if ((n > 0) and (playerHealth > 0)) then
		return math.ceil((tonumber(n) / tonumber(playerHealth)) * 100)
	else
		return 0;
	end
end

local function HealValueDisplayWindow_Hide()
	if (isDamageWindowVisible == true) then
		FrenziedRegenerationHelper_HealValueWindow:Hide();
		isDamageWindowVisible = false;
	end
end

local function HealValueDisplayWindow_Show()
	if (isDamageWindowVisible == false) then
		FrenziedRegenerationHelper_HealValueWindow:Show();
		isDamageWindowVisible = true;
	end
end

local function DamageTypeBar_Hide()
	if (isDamageTypeBarVisible == true) then
		DamageTypeWindow:Hide();
		isDamageTypeBarVisible = false;
	end
end

local function DamageTypeBar_Show()
	if (isDamageTypeBarVisible == false) then
		DamageTypeWindow:Show();
		isDamageTypeBarVisible = true;
	end
end

local function DamageHealthBar_Show()
	if (isDamageHealthBarVisible == false) then
		HealValueBar:Show();
		isDamageHealthBarVisible = true;
	end
end

local function DamageHealthBar_Hide()
	if (isDamageHealthBarVisible == true) then
		HealValueBar:Hide();
		isDamageHealthBarVisible = false;
	end
end


local function HealValueText_Show()
	if (isHealValueTextVisible == false) then
		HealValueTextFrame.text:Show();
		isHealValueTextVisible = true;
	end
end


local function HealValueText_Hide()
	if (isHealValueTextVisible == true) then
		HealValueTextFrame.text:Hide();
		isHealValueTextVisible = false;
	end
end

function FRH_HealValueDisplayWindow_CheckIfWindowShouldBeShown()
	if (FRHelperOptions_Get_ShowDamageTypeBar() == true) then
		DamageTypeBar_Show();
	else
		DamageTypeBar_Hide();
	end

	if (FRHelperOptions_Get_HideOutsideBearForm() == true) then
		if (GetShapeshiftForm() == FRHelperStatic.bearFormID) then
			HealValueDisplayWindow_Show();
		else
			HealValueDisplayWindow_Hide();
		end
	else
		HealValueDisplayWindow_Show();
	end

	if (FRHelperOptions_Get_DisplayValueAsBar() == true) then
		DamageHealthBar_Show();
	else
		DamageHealthBar_Hide();
	end

	if (FRHelperOptions_Get_HideHealValueText() == true) then
		HealValueText_Hide();
	else
		HealValueText_Show();
	end
end

function HealValueDisplayWindow_Init()
	local damageTypeBarHeight = FRHelperOptions_Get_DamageTypeBarHeight();
	local width = FRHelperOptions_Get_HealFrameWidth();
	local height = FRHelperOptions_Get_HealFrameHeight();
	local bg_alpha = FRHelperOptions_Get_HealFrameBGAlpha();

	-- Damage number display window
	FrenziedRegenerationHelper_HealValueWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],tile=true,tileSize=4,edgeSize=4,insets={left=0.5,right=0.5,top=0.5,bottom=0.5}});
	FrenziedRegenerationHelper_HealValueWindow:SetBackdropColor(0,0,0, bg_alpha);
	FrenziedRegenerationHelper_HealValueWindow:SetBackdropBorderColor(0, 0, 0, 1);
	FrenziedRegenerationHelper_HealValueWindow:SetSize(width, height);
	FrenziedRegenerationHelper_HealValueWindow:SetPoint("CENTER", 0, 0, "CENTER");

	-- Allow the window to be moved and handle the window being dragged
	FrenziedRegenerationHelper_HealValueWindow:SetMovable(true);
	FrenziedRegenerationHelper_HealValueWindow:EnableMouse(true);
	FrenziedRegenerationHelper_HealValueWindow:RegisterForDrag("LeftButton");
	FrenziedRegenerationHelper_HealValueWindow:SetScript("OnDragStart", function(self)
			if (FRHelperOptions_Get_FramePositionLocked() == false) then
				self:StartMoving();
			end
			end);
	FrenziedRegenerationHelper_HealValueWindow:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing();
			end);
	FrenziedRegenerationHelper_HealValueWindow:Hide();

	-- A health bar indicating the amount of the heal
	HealValueBar = CreateFrame("StatusBar", "damageTypeFrame", FrenziedRegenerationHelper_HealValueWindow);
	HealValueBar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground");
	HealValueBar:GetStatusBarTexture():SetHorizTile(false);
	HealValueBar:SetMinMaxValues(0, 100);
	HealValueBar:SetValue(25);
	HealValueBar:SetWidth(width);
	HealValueBar:SetHeight(height - damageTypeBarHeight);
	HealValueBar:SetReverseFill(false);
	HealValueBar:SetPoint("TOPLEFT",FrenziedRegenerationHelper_HealValueWindow,"TOPLEFT");
	HealValueBar:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=1,insets={left=0,right=0,top=0,bottom=0}});
	HealValueBar:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_b));
	HealValueBar:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_bg_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_bg_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagehealthbar_bg_b));
	HealValueBar:SetAlpha(0.5);
	HealValueBar:Hide();

	-- Physical/Magic window
	DamageTypeWindow = CreateFrame("StatusBar", "damageTypeFrame", FrenziedRegenerationHelper_HealValueWindow);
	DamageTypeWindow:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground");
	DamageTypeWindow:GetStatusBarTexture():SetHorizTile(false);
	DamageTypeWindow:SetMinMaxValues(0, 100);
	DamageTypeWindow:SetValue(0);
	DamageTypeWindow:SetWidth(width);
	DamageTypeWindow:SetHeight(damageTypeBarHeight);
	DamageTypeWindow:SetReverseFill(true);
	DamageTypeWindow:SetPoint("BOTTOMLEFT",FrenziedRegenerationHelper_HealValueWindow,"BOTTOMLEFT");
	DamageTypeWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=1,insets={left=0,right=0,top=0,bottom=0}});
	DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));
	DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));
	DamageTypeWindow:Hide();

	-- The number value
	HealValueTextFrame = CreateFrame("Frame", "healValueTextFrame", FrenziedRegenerationHelper_HealValueWindow);
	HealValueTextFrame:SetSize(width, height);
	HealValueTextFrame:SetPoint("TOPLEFT", 0, 0);

	-- Here's a list of fonts http://wow.gamepedia.com/API_FontInstance_SetFontObjec
	HealValueTextFrame.text = FrenziedRegenerationHelper_HealValueWindow:CreateFontString("displayString", "BACKGROUND", "GameFontHighlight");
	HealValueTextFrame.text:SetAllPoints();
	HealValueTextFrame.text:SetText("Damage in last "..FRHelperStatic.frenziedRegenSeconds.."s");
	HealValueTextFrame.text:SetPoint("CENTER", 0, 0);
	HealValueTextFrame.text:Hide();

	healValueWindowInitialized = true;
end

-- ----------------------------------------------
-- Frenzied Regen Bonus calculating logic
-- ----------------------------------------------

local function GetGuardianOfEluneBonus()
	if (UnitBuff("player", "Guardian of Elune") ~= nil) then
		return 0.20;
	else
		return 0;
	end
end

-- This isn't a multiplier bonus like the others, its an additional 12% of the player's max health
local function GetSkysecsHoldBonus()
	if (IsEquippedItem("Skysec's Hold") == true) then
		return UnitHealthMax("player") * 0.15;
	else
		return 0;
	end
end

local function GetClawsOfUrsocBonus()
	if (IsEquippedItem("Claws of Ursoc") == true) then
		return FRHelperOptions_Get_WildFleshBonus();
	else
		return 0;
	end
end

local function GetAdjustedFRHealingAmount(baseAmount)
	return (baseAmount * (1 + GetGuardianOfEluneBonus() + GetClawsOfUrsocBonus()) + GetSkysecsHoldBonus());
end

function HealValueDisplayWindow_SetWidth(newWidth_raw)
	if (healValueWindowInitialized == true) then
		if (newWidth_raw ~= nil) then
			local newWidth = math.ceil(newWidth_raw);
			if (newWidth > 10) then
				FrenziedRegenerationHelper_HealValueWindow:SetWidth(newWidth);
				DamageTypeWindow:SetWidth(newWidth);
				HealValueTextFrame:SetWidth(newWidth);
				HealValueBar:SetWidth(newWidth);
			end
		end
	end
end

function HealValueDisplayWindow_SetHeight(newHeight_raw)
	if (healValueWindowInitialized == true) then
		if (newHeight_raw ~= nil) then
			local newHeight = math.ceil(newHeight_raw);
			if (newHeight > 3) then
				FrenziedRegenerationHelper_HealValueWindow:SetHeight(newHeight);
				HealValueTextFrame:SetHeight(newHeight);
				HealValueBar:SetHeight(newHeight - FRHelperOptions_Get_DamageTypeBarHeight());
			end
		end
	end
end

function HealValueDisplayWindow_DamageTypeBar_SetHeight(newHeight_raw)
	if (healValueWindowInitialized == true) then
		if (newHeight_raw ~= nil) then
			local newHeight = math.ceil(newHeight_raw);
			if (newHeight > 1) then
				HealValueBar:SetHeight(FRHelperOptions_Get_HealFrameHeight() - newHeight);
				DamageTypeWindow:SetHeight(newHeight);
			end
		end
	end
end

function HealValueDisplayWindow_SetBGAlpha(newValue_raw)
	if (healValueWindowInitialized == true) then
		if (newValue_raw ~= nil) then
			local newValue = tonumber(newValue_raw);
			if ((newValue > 0) and (newValue < 1)) then
				FrenziedRegenerationHelper_HealValueWindow:SetBackdropColor(0,0,0, newValue);
			end
		end
	end
end

function HealValueDisplayWindow_Update()
	if (isDamageWindowVisible == true) then
		local displayAmount = 0

		local playerHealth = UnitHealthMax("player");

		-- Color the text acordingly
		HealValueTextFrame.text:SetTextColor(1,1,1, 0.5);

		-- Calculate the amount that would be healed from damage taken
		local amountHealedFromDamage = (FRH_DamageTracking_GetTotalDamage() * FRHelperStatic.frDamagedHealed);

		-- Calculate the minimum amount FR will heal (5% of the players max health)
		local minimumHealAmount = playerHealth * FRHelperStatic.minimumHealMultiplier;

		-- Figure out which would heal more, and display that one
		if (amountHealedFromDamage > minimumHealAmount) then
			displayAmount = amountHealedFromDamage;
			HealValueTextFrame.text:SetTextColor(1,1,1,1);
		else
			displayAmount = minimumHealAmount;
		end

		-- Take into account any bonuses to FR healing
		displayAmount = GetAdjustedFRHealingAmount(displayAmount);

		if (FRHelperOptions_Get_DisplayValueAsPercent() == true) then
			displayAmount_formatted = FormatNumber_Percent(displayAmount, playerHealth) .. "%";
		else
			displayAmount_formatted = FormatNumber_Numeric(displayAmount);
		end

		HealValueTextFrame.text:SetText(displayAmount_formatted);
		HealValueDisplayWindow_UpdateDamageHealthBar(displayAmount)
	else
		HealValueTextFrame.text:SetText("...");
	end
end

local DamageTypeBarActivated = false
local function DimDamageTypeDisplay()
	if (DamageTypeBarActivated == true) then
		DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));
		DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));
		DamageTypeBarActivated = false;
	end
end

local function ActivateDamageTypeDisplay()
	if (DamageTypeBarActivated == false) then
		DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_b));
		DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_b));
		DamageTypeBarActivated = true;
	end
end


function HealValueDisplayWindow_UpdateDamageHealthBar(healValue)
	local damageHealBarValue =FormatNumber_Percent(healValue)
	HealValueBar:SetValue(damageHealBarValue);
end

function HealValueDisplayWindow_UpdateDamageType()
	local totalDamage = FRH_DamageTracking_GetTotalDamage();
	local totalDamage_Physical = FRH_DamageTracking_GetTotal_Physical();
	if (totalDamage > 0) then
		local percentPhysical = (totalDamage_Physical / totalDamage) * 100;
		ActivateDamageTypeDisplay();
		DamageTypeWindow:SetValue(percentPhysical);
	else
		DimDamageTypeDisplay();
	end
end
