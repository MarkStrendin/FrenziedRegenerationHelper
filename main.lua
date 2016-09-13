-- ----------------------------------------------
-- If the player is not a druid, stop loading the addon
-- ----------------------------------------------

if select(2, UnitClass("player")) ~= "DRUID" then
	FRHelper_ShowMessage("Will stop loading, as player is not a druid")
	return
end

-- ----------------------------------------------
-- Local variables
-- ----------------------------------------------

-- Variable to track if the window is visible or not
local isDamageWindowVisible = false

-- Create a table to store the past 1 second of damage taken
-- We will keep each second seperate, and prune off anything beyond 5 periodically
-- When we display the numbers, we'll display 
local TrackedDamageTable_Physical = {}
local TrackedDamageTable_Magical = {}
local damageTrackedSinceLastInterval_Physical = 0
local damageTrackedSinceLastInterval_Magical = 0
local damageTrackingTableInitialized = false

-- Is the addon window initialized?
local isMainAddonFrameInitialized = false

-- We want to disable the bulk of this addon's calculating if the player is in a different spec
local isDamageMeterRunning = false

local isPlayerInCombat = false

-- ----------------------------------------------
-- General housekeeping functions
-- ----------------------------------------------

-- How should the damage number be displayed in the window
local function FormatNumber(n) 
	local intValue = math.ceil(n)

	local left,num,right = string.match(intValue,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function HideMainWindow()
	FrenziedRegenerationHelper_DamageWindow:Hide()
	isDamageWindowVisible = false
end

local function ShowMainWindow()
	if (isDamageWindowVisible == false) then
		FrenziedRegenerationHelper_DamageWindow:Show()
		isDamageWindowVisible = true
	end
end

-- Is Frenzied Regeneration available to the player in this spec, or at this level?
-- Note: This will fail to detect the spell if the player has just logged in.
local function CanPlayerUseFrenziedRegen() 
	if (IsPlayerSpell(22842)) then
		return true
	else
		return false
	end
end

local function CheckIfPlayerCanUseFrenziedRegen()
		if (CanPlayerUseFrenziedRegen()) then
			isDamageMeterRunning = true
		else
			isDamageMeterRunning = false
		end
end		

-- ----------------------------------------------
-- Set up the main container frame
-- ----------------------------------------------

local FrenziedRegenerationHelper = CreateFrame("FRAME")

-- Event for when the addon is loaded, so we can print a message indicating such
FrenziedRegenerationHelper:RegisterEvent("ADDON_LOADED")

-- Event for if the player switches forms - we only need to display the window in bear form
FrenziedRegenerationHelper:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

-- Hook the combat log
FrenziedRegenerationHelper:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- When the player changes talent specs
FrenziedRegenerationHelper:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- Track if the player is in combat or not
FrenziedRegenerationHelper:RegisterEvent("PLAYER_REGEN_ENABLED")
FrenziedRegenerationHelper:RegisterEvent("PLAYER_REGEN_DISABLED")



-- ----------------------------------------------
-- Event handlers
-- ----------------------------------------------

-- The shapeshift event is fired constantly during combat for some reason, so
-- this function is going to get called alot of extra times
local function Handler_Shapeshift() 
	-- If the player shapeshifts into bear form, show the addon

	if (FRHelperOptions_Get_HideOutsideBearForm()) then
		if (GetShapeshiftForm() == FRHelperStatic.bearFormID) then
			if (CanPlayerUseFrenziedRegen()) then
				ShowMainWindow()
			end
		else
			HideMainWindow()
		end	
	end
end

local function Handler_ChangeTalentSpec() 
	CheckIfPlayerCanUseFrenziedRegen()
end

-- Player has left combat
local function Handler_PlayerRegenEnabled() 
	isPlayerInCombat = false
end

-- Player has entered combat
local function Handler_PlayerRegenDisabled() 
	isPlayerInCombat = true
	if (isDamageMeterRunning == false) then
		CheckIfPlayerCanUseFrenziedRegen()
	end
end

-- ----------------------------------------------
-- Window initialization logic
-- ----------------------------------------------

local function InitWindow()
	FRHelper_InitSavedVariables()
	FRHelper_ShowDebugMessage("Trying to create window...")
	-- Damage number display window
	FrenziedRegenerationHelper_DamageWindow = CreateFrame("Frame", "FrenziedRegenerationHelper_DamageWindow" ,UIParent)
	FrenziedRegenerationHelper_DamageWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=4,insets={left=0.5,right=0.5,top=0.5,bottom=0.5}})
	FrenziedRegenerationHelper_DamageWindow:SetSize(200, 25)
	FrenziedRegenerationHelper_DamageWindow:SetBackdropColor(r, g, b, 0.5)
	FrenziedRegenerationHelper_DamageWindow:SetBackdropBorderColor(0, 0, 0, 1)
	FrenziedRegenerationHelper_DamageWindow:SetPoint("CENTER", 0, 0)

	-- Here's a list of fonts http://wow.gamepedia.com/API_FontInstance_SetFontObject
	FrenziedRegenerationHelper_DamageWindow.text = FrenziedRegenerationHelper_DamageWindow:CreateFontString("displayString", "BACKGROUND", "GameFontHighlight")
	FrenziedRegenerationHelper_DamageWindow.text:SetAllPoints()
	FrenziedRegenerationHelper_DamageWindow.text:SetText("Damage in last "..FRHelperStatic.frenziedRegenSeconds.."s")
	FrenziedRegenerationHelper_DamageWindow.text:SetPoint("CENTER", 0, 0)

	-- Allow the window to be moved and handle the window being dragged
	FrenziedRegenerationHelper_DamageWindow:SetMovable(true)
	FrenziedRegenerationHelper_DamageWindow:EnableMouse(true)
	FrenziedRegenerationHelper_DamageWindow:RegisterForDrag("LeftButton")
	FrenziedRegenerationHelper_DamageWindow:SetScript("OnDragStart", function(self)
			self:StartMoving()
			end)
	FrenziedRegenerationHelper_DamageWindow:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			end)

	-- Physical/Magic window (experimental)
	DamageTypeWindow = CreateFrame("StatusBar", "damageTypeFrame", FrenziedRegenerationHelper_DamageWindow)
	DamageTypeWindow:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
	DamageTypeWindow:GetStatusBarTexture():SetHorizTile(false)
	DamageTypeWindow:SetMinMaxValues(0, 100)
	DamageTypeWindow:SetValue(100)
	DamageTypeWindow:SetWidth(200)
	DamageTypeWindow:SetHeight(2)
	DamageTypeWindow:SetReverseFill(true)
	DamageTypeWindow:SetPoint("BOTTOMLEFT",FrenziedRegenerationHelper_DamageWindow,"BOTTOMLEFT")
	DamageTypeWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=1,insets={left=0,right=0,top=0,bottom=0}})
	DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim))
	DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim))

	if (FRHelperOptions_Get_ShowDamageTypeBar() == true) then
		DamageTypeWindow:Show()
	else
		DamageTypeWindow:Hide()
	end


	if (FRHelperOptions_Get_HideOutsideBearForm()) then
		HideMainWindow()

		if (GetShapeshiftForm() == FRHelperStatic.bearFormID) then
			ShowMainWindow()
		end	
	end

	isMainAddonFrameInitialized = true

end

-- ----------------------------------------------
-- Frenzied Regen Bonus calculating logic
-- ----------------------------------------------

local function GetGuardianOfEluneBonus() 
	if (UnitBuff("player", "Guardian of Elune") ~= nil) then
		return 0.20
	else
		return 0
	end
end

local function GetSkysecsHoldBonus()
	if (IsEquippedItem("Skysec's Hold") == true) then
		return UnitHealthMax("player") * 0.15
	else
		return 0
	end
end

local function GetAdjustedFRHealingAmount(baseAmount) 
	return (baseAmount * (1 + FRHelperOptions_Get_WildFleshBonus() + GetGuardianOfEluneBonus())) + GetSkysecsHoldBonus()
end

-- ----------------------------------------------
-- Artifact querying logic
-- ----------------------------------------------

-- This gets called every second ... until I find a better way to do it
local function CalculateWildFleshBonus() 
	-- If the player doesn't have Claws of Ursoc equipped, then theres no bonus from it
	if (IsEquippedItem("Claws of Ursoc") == true) then

		-- Attempt to load the artifact powers. Currently this only works if the artifact UI is open
		local powers = C_ArtifactUI.GetPowers()

		if (powers) then
			for i = 1, #powers do
		        local spellID, _, currentRank = C_ArtifactUI.GetPowerInfo(powers[i])
		     	
		     	if (spellID == 200400) then
					FRHelperOptions_Set_WildFleshBonus(0.05 * currentRank)
		     	end
		    end
		end
	end
end

-- ----------------------------------------------
-- Damage tracking logic
-- ----------------------------------------------

local function InitializeDamageTable()
	for x=1,FRHelperStatic.damageTableMaxEntries,1 do		

		FRHelper_ShowDebugMessage("Damage table "..x.." initialized to 0")
		TrackedDamageTable_Physical[x] = 0
		TrackedDamageTable_Magical[x] = 0
	end
	damageTrackingTableInitialized = true
end

-- should be called every second, this keeps the damage table up to date for the UI functions
local function CycleDamageTable() 

	-- Physical table
	local updatedDamageTable_Physical = {}

	-- The current up to date value goes in slot 1
	updatedDamageTable_Physical[1] = damageTrackedSinceLastInterval_Physical
	damageTrackedSinceLastInterval_Physical = 0

	-- All other slots are the values from the "active" damage table, shifted down one interval
	for x=2,FRHelperStatic.damageTableMaxEntries,1 do	
		updatedDamageTable_Physical[x] = TrackedDamageTable_Physical[x-1]
	end

	-- Assign our working table to the "active" table, which should dispose of the old values during garbage collection
	TrackedDamageTable_Physical = updatedDamageTable_Physical




	-- Magical table
	local updatedDamageTable_Magical = {}

	-- The current up to date value goes in slot 1
	updatedDamageTable_Magical[1] = damageTrackedSinceLastInterval_Magical
	damageTrackedSinceLastInterval_Magical = 0

	-- All other slots are the values from the "active" damage table, shifted down one interval
	for x=2,FRHelperStatic.damageTableMaxEntries,1 do	
		updatedDamageTable_Magical[x] = TrackedDamageTable_Magical[x-1]
	end

	-- Assign our working table to the "active" table, which should dispose of the old values during garbage collection
	TrackedDamageTable_Magical = updatedDamageTable_Magical
end


local function GetDamageTableTotal_Physical()	
	totalDamage = 0
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do	
		totalDamage = totalDamage + TrackedDamageTable_Physical[x]
	end
	return totalDamage
end

local function GetDamageTableTotal_Magical()
	totalDamage = 0
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do	
		totalDamage = totalDamage + TrackedDamageTable_Magical[x]
	end
	return totalDamage
end

local function GetDamageTableTotal() 
	totalDamage = 0
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do	
		totalDamage = totalDamage + TrackedDamageTable_Physical[x]
		totalDamage = totalDamage + TrackedDamageTable_Magical[x]
	end
	return totalDamage
end

local function  UpdateTotalDisplay() 
	local displayAmount = 0	

	-- Color the text acordingly
	FrenziedRegenerationHelper_DamageWindow.text:SetTextColor(1,1,1, 0.5)

	-- Calculate the amount that would be healed from damage taken
	local amountHealedFromDamage = (GetDamageTableTotal() * FRHelperStatic.frDamagedHealed)

	-- Calculate the minimum amount FR will heal (5% of the players max health)
	local minimumHealAmount = UnitHealthMax("player") * FRHelperStatic.minimumHealMultiplier

	-- Figure out which would heal more, and display that one
	if (amountHealedFromDamage > minimumHealAmount) then
		displayAmount = amountHealedFromDamage
		FrenziedRegenerationHelper_DamageWindow.text:SetTextColor(1,1,1,1)
	else
		displayAmount = minimumHealAmount
	end

	-- Take into account any bonuses to FR healing
	displayAmount = GetAdjustedFRHealingAmount(displayAmount)

	FrenziedRegenerationHelper_DamageWindow.text:SetText(FormatNumber(displayAmount))
end	

local DamageTypeBarActivated = false
local function DimDamageTypeDisplay()
	if (DamageTypeBarActivated == true) then
		DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim))
		DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_dim))
		DamageTypeBarActivated = false
	end
end

local function ActivateDamageTypeDisplay()
	if (DamageTypeBarActivated == false) then
		DamageTypeWindow:SetStatusBarColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_physical_b))
		DamageTypeWindow:SetBackdropColor(FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_r), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_g), FRHelper_ConvertRGBToDecimal(FRHelperStatic.color_damagetype_magical_b))
		DamageTypeBarActivated = true
	end
end


local function UpdateDamageTypeBar()
	local totalDamage = GetDamageTableTotal()
	local totalDamage_Physical = GetDamageTableTotal_Physical()
	if (totalDamage > 0) then
		local percentPhysical = (totalDamage_Physical / totalDamage) * 100
		ActivateDamageTypeDisplay()
		DamageTypeWindow:SetValue(percentPhysical)
	else
		DimDamageTypeDisplay()
		-- Maybe hide the damage type window? Somehow disable it so that it's not displaying anything?
	end
end

local function TrackPhysicalDamage(dmg)
	--  Check the damage type here with a parameter
	damageTrackedSinceLastInterval_Physical = damageTrackedSinceLastInterval_Physical + dmg
	if (FRHelperOptions_Get_ShowDebugMessages() == true) then
		FRHelper_ShowDebugMessage("Tracking physical damage: " .. dmg)
	end
end

local function TrackMagicalDamage(dmg)
	damageTrackedSinceLastInterval_Magical = damageTrackedSinceLastInterval_Magical + dmg
	if (FRHelperOptions_Get_ShowDebugMessages() == true) then
		FRHelper_ShowDebugMessage("Tracking magical damage: " .. dmg)
	end
end

local function TrackEnvironmentalDamage(dmg)
	-- Not currently supported, so add this later

	if (FRHelperStatic.include_environmental_damage == true) then
		if (FRHelperOptions_Get_ShowDebugMessages() == true) then
			FRHelper_ShowDebugMessage("Tracking environment damage: " .. dmg)
		end
	end
end

-- ----------------------------------------------
-- This runs every second, apparently
-- ----------------------------------------------

local totalElapsedSeconds = 0
local function onFrameUpdate(self, elapsed)	

	-- Utilize the onFrameUpdate event to create a 1 second timer
	totalElapsedSeconds = totalElapsedSeconds + elapsed
	if (totalElapsedSeconds >= 1) then
		totalElapsedSeconds = 0

		if (isMainAddonFrameInitialized == true) then
			-- Stuff to run every second goes here
			CalculateWildFleshBonus()

			if (isDamageMeterRunning == true) then
				CycleDamageTable()
				UpdateTotalDisplay()
				if (FRHelperOptions_Get_ShowDamageTypeBar() == true) then
					UpdateDamageTypeBar()
				end
			end			
		end

	end
end

-- ----------------------------------------------
-- Main event handler that passes stuff off to other handler functions
-- ----------------------------------------------
local function MainEventHandler(self, event, arg1, eventType, ...)
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == string.lower(FRHelperStatic.addonName)) then
			FRHelper_ShowMessage("Version "..FRHelperStatic.addonVersion.." loaded - Window will appear in bear form.")
			InitializeDamageTable()
			InitWindow()
		end

	elseif (event == "UPDATE_SHAPESHIFT_FORM") then
		-- This gets called constantly in combat, and I'm not sure why
		Handler_Shapeshift()

	elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
		Handler_ChangeTalentSpec()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		Handler_PlayerRegenEnabled()

	elseif (event == "PLAYER_REGEN_DISABLED") then
		Handler_PlayerRegenDisabled()

	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		-- http://wowwiki.wikia.com/wiki/API_COMBAT_LOG_EVENT

		local unixtime = arg1
		local sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(2,...)
		
		-- We only care about damage IN, so only continue if the destination is the player
		if (destGUID == UnitGUID("player")) then

			-- We only care about events that would DAMAGE the player (as opposed to heals, auras coming and going, interrupts, etc)
			if (eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "ENVIRONMENTAL_DAMAGE") then

				-- The amount of damage is a different parameter depending on what kind of (sub) event it is
				local amount = 0

				if (eventType == "SWING_DAMAGE") then
					amount = select(10,...)
					if (amount > 0) then
						TrackPhysicalDamage(amount)
					end
				end

				if (eventType == "ENVIRONMENTAL_DAMAGE") then
					if (FRHelperStatic.include_environmental_damage == true) then
						amount = select(11,...)

						if (amount > 0) then
							TrackEnvironmentalDamage(amount)
						end
					end					
				end

				if (eventType == "SPELL_DAMAGE" or arg2 == "SPELL_PERIODIC_DAMAGE") then
					amount = select(13,...)

					-- We need to seperate out the "spells" that do physical damage from the ones that don't
					-- Damage schools can be found here: http://wowwiki.wikia.com/wiki/API_COMBAT_LOG_EVENT
					school = select(15,...)

					if (amount > 0) then
						if (school == 1) then
							TrackPhysicalDamage(amount)
						else
							TrackMagicalDamage(amount)
						end
					end
				end

			end
		end

	end
end

-- ----------------------------------------------
-- Register event handlers
-- This apparently needs to be done last
-- ----------------------------------------------

FrenziedRegenerationHelper:SetScript("OnEvent", MainEventHandler)
FrenziedRegenerationHelper:SetScript("OnUpdate", onFrameUpdate)