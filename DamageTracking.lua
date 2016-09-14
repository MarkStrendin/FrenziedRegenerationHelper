-- Create a table to store the past 1 second of damage taken
-- We will keep each second seperate, and prune off anything beyond 5 periodically
-- When we display the numbers, we'll display
local TrackedDamageTable_Physical = {};
local TrackedDamageTable_Magical = {};
local damageTrackedSinceLastInterval_Physical = 0;
local damageTrackedSinceLastInterval_Magical = 0;
local damageTrackingTableInitialized = false;

-- We want to disable the bulk of this addon's calculating if the player is in a different spec
local isDamageMeterRunning = false;

function FRH_DamageTracking_InitializeDamageTable()
	for x=1,FRHelperStatic.damageTableMaxEntries,1 do
		--FRHelper_ShowDebugMessage("Damage table "..x.." initialized to 0");
		TrackedDamageTable_Physical[x] = 0;
		TrackedDamageTable_Magical[x] = 0;
	end
	damageTrackingTableInitialized = true;
end

function FRH_DamageTracking_GetTotal_Physical()
	totalDamage = 0;
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do
		totalDamage = totalDamage + TrackedDamageTable_Physical[x];
	end
	return totalDamage;
end

function FRH_DamageTracking_GetTotal_Magical()
	totalDamage = 0;
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do
		totalDamage = totalDamage + TrackedDamageTable_Magical[x];
	end
	return totalDamage;
end

function FRH_DamageTracking_GetTotalDamage()
	totalDamage = 0;
	for x=1,FRHelperStatic.frenziedRegenSeconds,1 do
		totalDamage = totalDamage + TrackedDamageTable_Physical[x];
		totalDamage = totalDamage + TrackedDamageTable_Magical[x];
	end
	return totalDamage;
end

local function CycleDamageTable_Physical()
	local updatedDamageTable_Physical = {};

	-- The current up to date value goes in slot 1
	updatedDamageTable_Physical[1] = damageTrackedSinceLastInterval_Physical;
	damageTrackedSinceLastInterval_Physical = 0;

	-- All other slots are the values from the "active" damage table, shifted down one interval
	for x=2,FRHelperStatic.damageTableMaxEntries,1 do
		updatedDamageTable_Physical[x] = TrackedDamageTable_Physical[x-1];
	end

	-- Assign our working table to the "active" table, which should dispose of the old values during garbage collection
	TrackedDamageTable_Physical = updatedDamageTable_Physical;
end

local function CycleDamageTable_Magic()
	local updatedDamageTable_Magical = {};

	-- The current up to date value goes in slot 1
	updatedDamageTable_Magical[1] = damageTrackedSinceLastInterval_Magical;
	damageTrackedSinceLastInterval_Magical = 0;

	-- All other slots are the values from the "active" damage table, shifted down one interval
	for x=2,FRHelperStatic.damageTableMaxEntries,1 do
		updatedDamageTable_Magical[x] = TrackedDamageTable_Magical[x-1];
	end

	-- Assign our working table to the "active" table, which should dispose of the old values during garbage collection
	TrackedDamageTable_Magical = updatedDamageTable_Magical;
end


-- should be called every second, this keeps the damage table up to date for the UI functions
function FRH_DamageTracking_CycleDamageTable_RunMeEverySecond()
	if (isDamageMeterRunning == true) then
		CycleDamageTable_Magic();
		CycleDamageTable_Physical();
	end
end

function FRH_DamageTracking_TrackPhysicalDamage(dmg)
	if (isDamageMeterRunning == true) then
		--  Check the damage type here with a parameter
		damageTrackedSinceLastInterval_Physical = damageTrackedSinceLastInterval_Physical + dmg;
		if (FRHelperOptions_Get_ShowDebugMessages() == true) then
			FRHelper_ShowDebugMessage("Tracking physical damage: " .. dmg);
		end
	end
end

function FRH_DamageTracking_TrackMagicalDamage(dmg)
	if (isDamageMeterRunning == true) then
		damageTrackedSinceLastInterval_Magical = damageTrackedSinceLastInterval_Magical + dmg;
		if (FRHelperOptions_Get_ShowDebugMessages() == true) then
			FRHelper_ShowDebugMessage("Tracking magical damage: " .. dmg);
		end
	end
end

function FRH_DamageTracking_StopMeter()
	isDamageMeterRunning = false;
end

function FRH_DamageTracking_StartMeter()
	isDamageMeterRunning = true;
end

function FRH_DamageTracking_IsMeterRunning()
	return isDamageMeterRunning;
end
