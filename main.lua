-- ----------------------------------------------
-- If the player is not a druid, stop loading the addon
-- ----------------------------------------------

if select(2, UnitClass("player")) ~= "DRUID" then
	FRHelper_ShowMessage("Will stop loading, as player is not a druid");
	return;
end

-- Put this in a structure called FRHelper_Status or something
local isPlayerInCombat = false

-- Is the addon window initialized?
local isMainAddonFrameInitialized = false;

-- ----------------------------------------------
-- Set up the main container frame
-- ----------------------------------------------

local FrenziedRegenerationHelper = CreateFrame("FRAME");

-- Event for when the addon is loaded, so we can print a message indicating such
FrenziedRegenerationHelper:RegisterEvent("ADDON_LOADED");

-- Event for if the player switches forms - we only need to display the window in bear form
FrenziedRegenerationHelper:RegisterEvent("UPDATE_SHAPESHIFT_FORM");

-- Hook the combat log
FrenziedRegenerationHelper:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

-- When the player changes talent specs
FrenziedRegenerationHelper:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");

-- Track if the player is in combat or not
FrenziedRegenerationHelper:RegisterEvent("PLAYER_REGEN_ENABLED");
FrenziedRegenerationHelper:RegisterEvent("PLAYER_REGEN_DISABLED");

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
			FRH_DamageTracking_StartMeter()
		else
			FRH_DamageTracking_StopMeter()
		end
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
-- Event handlers
-- ----------------------------------------------

-- The shapeshift event is fired constantly during combat for some reason, so
-- this function is going to get called alot of extra times
local function Handler_Shapeshift()
	-- If the player shapeshifts into bear form, show the addon

	FRH_HealValueDisplayWindow_CheckIfWindowShouldBeShown();
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
	if (FRH_DamageTracking_IsMeterRunning() == false) then
		CheckIfPlayerCanUseFrenziedRegen()
	end
end

-- ----------------------------------------------
-- Window initialization logic
-- ----------------------------------------------

local function InitializeAddon()
	FRHelper_InitSavedVariables();
	FRH_DamageTracking_InitializeDamageTable();
	HealValueDisplayWindow_Init();
	FRH_HealValueDisplayWindow_CheckIfWindowShouldBeShown();
	FRH_UpdateOptionsMenuValues();
	FRHelper_ShowMessage("Version "..FRHelperStatic.addonVersion.." loaded - Window will appear in bear form.");
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
			CalculateWildFleshBonus();
			FRH_DamageTracking_CycleDamageTable_RunMeEverySecond();
			HealValueDisplayWindow_Update();
			if (FRHelperOptions_Get_ShowDamageTypeBar() == true) then
				HealValueDisplayWindow_UpdateDamageType();
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
			InitializeAddon()
			isMainAddonFrameInitialized = true;
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
						FRH_DamageTracking_TrackPhysicalDamage(amount)
					end
				end

				if (eventType == "ENVIRONMENTAL_DAMAGE") then
					if (FRHelperStatic.include_environmental_damage == true) then
						amount = select(11,...)

						if (amount > 0) then
							-- If we were tracking environmental damage, we'd do it here
						end
					end
				end

				if (eventType == "SPELL_DAMAGE" or arg2 == "SPELL_PERIODIC_DAMAGE") then
					amount = select(13,...)

					-- We need to seperate out the "spells" that do physical damage from the ones that don't
					-- Damage schools can be found here: http://wowwiki.wikia.com/wiki/API_COMBAT_LOG_EVENT
					school = select(15,...)

					if (amount > 0) then
						if (school == 1) then -- school 1 is "physical"
							FRH_DamageTracking_TrackPhysicalDamage(amount)
						else
							FRH_DamageTracking_TrackMagicalDamage(amount)
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
