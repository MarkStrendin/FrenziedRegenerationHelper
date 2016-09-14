-- ----------------------------------------------
-- Local variables
-- ----------------------------------------------

-- Variable to track if the window is visible or not
local isDamageWindowVisible = false;
local isDamageTypeBarVisible = false;

local FrenziedRegenerationHelper_HealValueWindow = CreateFrame("Frame", "FrenziedRegenerationHelper_HealValueWindow" ,UIParent);

-- ----------------------------------------------
-- General housekeeping functions
-- ----------------------------------------------

-- How should the damage number be displayed in the window
local function FormatNumber(n)
	local intValue = math.ceil(n);

	local left,num,right = string.match(intValue,'^([^%d]*%d)(%d*)(.-)$');
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right;
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
end

function HealValueDisplayWindow_Init()
	FRHelper_ShowDebugMessage("Trying to create heal value window...");

	-- Damage number display window
	FrenziedRegenerationHelper_HealValueWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=4,insets={left=0.5,right=0.5,top=0.5,bottom=0.5}});
	FrenziedRegenerationHelper_HealValueWindow:SetSize(200, 25);
	FrenziedRegenerationHelper_HealValueWindow:SetBackdropColor(r, g, b, 0.5);
	FrenziedRegenerationHelper_HealValueWindow:SetBackdropBorderColor(0, 0, 0, 1);
	FrenziedRegenerationHelper_HealValueWindow:SetPoint("CENTER", 0, 0);

	-- Here's a list of fonts http://wow.gamepedia.com/API_FontInstance_SetFontObject
	FrenziedRegenerationHelper_HealValueWindow.text = FrenziedRegenerationHelper_HealValueWindow:CreateFontString("displayString", "BACKGROUND", "GameFontHighlight");
	FrenziedRegenerationHelper_HealValueWindow.text:SetAllPoints();
	FrenziedRegenerationHelper_HealValueWindow.text:SetText("Damage in last "..FRHelperStatic.frenziedRegenSeconds.."s");
	FrenziedRegenerationHelper_HealValueWindow.text:SetPoint("CENTER", 0, 0);

	-- Allow the window to be moved and handle the window being dragged
	FrenziedRegenerationHelper_HealValueWindow:SetMovable(true);
	FrenziedRegenerationHelper_HealValueWindow:EnableMouse(true);
	FrenziedRegenerationHelper_HealValueWindow:RegisterForDrag("LeftButton");
	FrenziedRegenerationHelper_HealValueWindow:SetScript("OnDragStart", function(self)
			self:StartMoving();
			end);
	FrenziedRegenerationHelper_HealValueWindow:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing();
			end);

	-- Physical/Magic window (experimental)
	DamageTypeWindow = CreateFrame("StatusBar", "damageTypeFrame", FrenziedRegenerationHelper_HealValueWindow);
	DamageTypeWindow:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground");
	DamageTypeWindow:GetStatusBarTexture():SetHorizTile(false);
	DamageTypeWindow:SetMinMaxValues(0, 100);
	DamageTypeWindow:SetValue(100);
	DamageTypeWindow:SetWidth(200);
	DamageTypeWindow:SetHeight(2);
	DamageTypeWindow:SetReverseFill(true);
	DamageTypeWindow:SetPoint("BOTTOMLEFT",FrenziedRegenerationHelper_HealValueWindow,"BOTTOMLEFT");
	DamageTypeWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=1,insets={left=0,right=0,top=0,bottom=0}});
	DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));
	DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim));

	if (FRHelperOptions_Get_ShowDamageTypeBar() == true) then
		DamageTypeWindow:Show();
	else
		DamageTypeWindow:Hide();
	end

	if (FRHelperOptions_Get_HideOutsideBearForm()) then
		HealValueDisplayWindow_Hide();

		if (GetShapeshiftForm() == FRHelperStatic.bearFormID) then
			HealValueDisplayWindow_Show();
		end
	end
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

local function GetSkysecsHoldBonus()
	if (IsEquippedItem("Skysec's Hold") == true) then
		return UnitHealthMax("player") * 0.15;
	else
		return 0;
	end
end

local function GetAdjustedFRHealingAmount(baseAmount)
	return (baseAmount * (1 + FRHelperOptions_Get_WildFleshBonus() + GetGuardianOfEluneBonus())) + GetSkysecsHoldBonus();
end

function HealValueDisplayWindow_Update()
	-- Check the addon options to see what we should be displayString


	if (isDamageWindowVisible == true) then
		local displayAmount = 0

		-- Color the text acordingly
		FrenziedRegenerationHelper_HealValueWindow.text:SetTextColor(1,1,1, 0.5);

		-- Calculate the amount that would be healed from damage taken
		local amountHealedFromDamage = (FRH_DamageTracking_GetTotalDamage() * FRHelperStatic.frDamagedHealed);

		-- Calculate the minimum amount FR will heal (5% of the players max health)
		local minimumHealAmount = UnitHealthMax("player") * FRHelperStatic.minimumHealMultiplier;

		-- Figure out which would heal more, and display that one
		if (amountHealedFromDamage > minimumHealAmount) then
			displayAmount = amountHealedFromDamage;
			FrenziedRegenerationHelper_HealValueWindow.text:SetTextColor(1,1,1,1);
		else
			displayAmount = minimumHealAmount;
		end

		-- Take into account any bonuses to FR healing
		displayAmount = GetAdjustedFRHealingAmount(displayAmount);

		FrenziedRegenerationHelper_HealValueWindow.text:SetText(FormatNumber(displayAmount));
	else
		FrenziedRegenerationHelper_HealValueWindow.text:SetText("...");
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
