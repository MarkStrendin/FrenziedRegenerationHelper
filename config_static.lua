-- ----------------------------------------------
-- Configuration that shouldn't change
-- ----------------------------------------------

FRHelperStatic = {};

-- Addon name, to detect when this addon has been loaded (don't touch this)
FRHelperStatic.addonName = "FrenziedRegenerationHelper";

-- How much of the damage done does Frenzied Regeneration heal back?
FRHelperStatic.frDamagedHealed = 0.5;

-- How much of the player's health is the minimum heal? (detault is 5%)
FRHelperStatic.minimumHealMultiplier = 0.05;


-- Should environmental damage count?
-- Currently, frenzied regeneration dFRHelperStatic.oesn't count it, but I'm not sure if this is intentional or not.
FRHelperStatic.include_environmental_damage = false;

-- How many seconds does frenzied regeneration go back? (default: 5)
FRHelperStatic.frenziedRegenSeconds = 5;

-- How many seconds back should we keep in the table?
FRHelperStatic.damageTableMaxEntries = 5; -- If this value is 1 or lower, this addon will crash

-- What is the stance number of bear form
FRHelperStatic.bearFormID = 1;

-- Store the version of the addon, from the .toc file, so we can display it
FRHelperStatic.addonVersion = GetAddOnMetadata(FRHelperStatic.addonName, "Version");

-- colors
-- Orange: rgb(223, 92, 23)
FRHelperStatic.color_damagetype_physical_r = 223;
FRHelperStatic.color_damagetype_physical_g = 92;
FRHelperStatic.color_damagetype_physical_b = 23;

-- Cyan rgb(86, 165, 220)
FRHelperStatic.color_damagetype_magical_r = 86;
FRHelperStatic.color_damagetype_magical_g = 165;
FRHelperStatic.color_damagetype_magical_b = 220;

-- What color to dim the bar to if theres no damage to display
FRHelperStatic.color_damagetype_dim = 64;