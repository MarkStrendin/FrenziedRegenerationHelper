-- ----------------------------------------------
-- Configuration
-- ----------------------------------------------

-- How much of the damage done does Frenzied Regeneration heal back?
local frDamagedHealed = 0.5

-- How much of the player's health is the minimum heal? (detault is 5%)
local minimumHealMultiplier = 0.05

-- Any bonuses to FR, such as the artifact talent "Wildflesh"
local frHealingMultiplier = 1

-- Show debug messages?
local showDebugMessages = true

-- Should we hide the window if the player isn't in bear form?
local hideOutsideBearForm = true

-- ----------------------------------------------
-- You shouldn't need to touch anything past here
-- ----------------------------------------------

-- How many seconds does frenzied regeneration go back? (default: 5)
local frenziedRegenSeconds = 5

-- How many seconds back should we keep in the table?
local damageTableMaxEntries = 5 -- If this value is 1 or lower, this addon will crash

-- What is the stance number of bear form
local bearFormID = 1

-- Addon name, to detect when this addon has been loaded (don't touch this)
local addonName = "FrenziedRegenerationHelper"

local windowVisible = false

-- Track if the player is in combat or not
-- Currently not used, but I think I will use this in the future for something
local isPlayerInCombat = false

-- Create a table to store the past 1 second of damage taken
-- We will keep each second seperate, and prune off anything beyond 5 periodically
-- When we display the numbers, we'll display 
local TrackedDamageTable = {}
local damageTrackedSinceLastInterval = 0
local damageTrackingTableInitialized = false

-- ----------------------------------------------
-- General housekeeping functions
-- ----------------------------------------------

local function ShowDebugMessage(msg)
	if (showDebugMessages == true) then
		print(addonName.."-DEBUG: "..msg)
	end
end

local function ShowMessage(msg) 
	print(msg)
end

local function HideMainWindow()
	DisplayWindow:Hide()
	windowVisible = false
end

local function ShowMainWindow()
	if (windowVisible == false) then
		DisplayWindow:Show()
		windowVisible = true
	end
end

local function FormatNumber(n) 
	local intValue = math.ceil(n)

	local left,num,right = string.match(intValue,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end


-- ----------------------------------------------
-- If the player is not a druid, stop loading the addon
-- ----------------------------------------------

if select(2, UnitClass("player")) ~= "DRUID" then
	ShowMessage("Not loading |cff3399FF"..addonName.."|r, as player is not a druid")
	return
end

-- ----------------------------------------------
-- Set up the main container frame
-- ----------------------------------------------

local DamageInLastFiveFrame = CreateFrame("FRAME")

-- Event for when the addon is loaded, so we can print a message indicating such
DamageInLastFiveFrame:RegisterEvent("ADDON_LOADED")

-- Event for if the player leaves combat
DamageInLastFiveFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Event for if the player enters combat
DamageInLastFiveFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Event for if the player switches forms - we only need to display the window in bear form
DamageInLastFiveFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

-- Hook the combat log
DamageInLastFiveFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


-- ----------------------------------------------
-- Event handlers
-- ----------------------------------------------

local function Handler_PlayerLeaveCombat() 
	isPlayerInCombat = false
end

local function Handler_PlayerEnterCombat()
	isPlayerInCombat = true
end

local function Handler_PlayerDamaged(amount)
	ShowMessage(amount)
end

local function Handler_Shapeshift() 
	-- If the player shapeshifts into bear form, show the addon

	if (hideOutsideBearForm) then
		if (GetShapeshiftForm() == bearFormID) then
			ShowMainWindow()
		else
			HideMainWindow()
		end	
	end
end

-- ----------------------------------------------
-- Window initialization logic
-- ----------------------------------------------

local function InitWindow()
	-- Handle this in XML maybe?
	ShowDebugMessage("Trying to create window...")
	DisplayWindow = CreateFrame("Frame", "containerFrame" ,UIParent)
	DisplayWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=4,insets={left=0.5,right=0.5,top=0.5,bottom=0.5}})
	DisplayWindow:SetSize(200, 22)
	DisplayWindow:SetBackdropColor(r, g, b, 0.5)
	DisplayWindow:SetBackdropBorderColor(0, 0, 0, 1)
	DisplayWindow:SetPoint("CENTER", 0, 0)

	-- Here's a list of fonts http://wow.gamepedia.com/API_FontInstance_SetFontObject
	DisplayWindow.text = DisplayWindow:CreateFontString("displayString", "BACKGROUND", "GameFontHighlight")
	DisplayWindow.text:SetAllPoints()
	DisplayWindow.text:SetText("Damage in last "..frenziedRegenSeconds.."s")
	DisplayWindow.text:SetPoint("CENTER", 0, 0)

	-- Allow the window to be moved and handle the window being dragged
	DisplayWindow:SetMovable(true)
	DisplayWindow:EnableMouse(true)
	DisplayWindow:RegisterForDrag("LeftButton")
	DisplayWindow:SetScript("OnDragStart", function(self)
			self:StartMoving()
			end)
	DisplayWindow:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			end)

	if (hideOutsideBearForm) then
		HideMainWindow()

		if (GetShapeshiftForm() == bearFormID) then
			ShowMainWindow()
		end	
	end

end

-- ----------------------------------------------
-- Damage tracking logic
-- ----------------------------------------------

local function InitializeDamageTable()
	for x=1,damageTableMaxEntries,1 do		

		ShowDebugMessage("Damage table "..x.." initialized to 0")
		TrackedDamageTable[x] = 0
	end
	damageTrackingTableInitialized = true
end

-- should be called every second, this keeps the damage table up to date for the UI functions
local function CycleDamageTable() 
	-- Create a new working table
	local workingDamageTable = {}

	-- The current up to date value goes in slot 1
	workingDamageTable[1] = damageTrackedSinceLastInterval
	damageTrackedSinceLastInterval = 0

	-- All other slots are the values from the "active" damage table, shifted down one interval

	for x=2,damageTableMaxEntries,1 do	
		workingDamageTable[x] = TrackedDamageTable[x-1]
	end

	-- Assign our working table to the "active" table, which should dispose of the old values during garbage collection
	TrackedDamageTable = workingDamageTable
end

local function GetDamageTableTotal() 
	totalDamage = 0
	for x=1,frenziedRegenSeconds,1 do	
		totalDamage = totalDamage + TrackedDamageTable[x]
	end
	return  totalDamage
end

local function  UpdateTotalDisplay() 
	local displayAmount = 0

	-- Calculate the amount that would be healed from damage taken
	local amountHealedFromDamage = GetDamageTableTotal() * frDamagedHealed

	-- Calculate the minimum amount FR will heal (5% of the players max health)
	local minimumHealAmount = UnitHealthMax("player") * minimumHealMultiplier

	-- Figure out which would heal more, and disply that one
	if (amountHealedFromDamage > minimumHealAmount) then
		displayAmount = amountHealedFromDamage
	else
		displayAmount = minimumHealAmount
	end

	-- Take into account any bonuses to FR healing
	displayAmount = displayAmount * frHealingMultiplier

	DisplayWindow.text:SetText(FormatNumber(displayAmount))

end	

local function TrackDamage(dmg)
	damageTrackedSinceLastInterval = damageTrackedSinceLastInterval + dmg
end

-- ----------------------------------------------
-- Debug stuff
-- ----------------------------------------------

local arbitraryCounter = 0
local function debug_DisplayDamageTable() 
	if (damageTrackingTableInitialized == true) then
		arbitraryCounter = arbitraryCounter + 1
		ShowDebugMessage("------------------------ ".. arbitraryCounter)
		ShowDebugMessage("Damage table: ")
		for x=1,damageTableMaxEntries,1 do		
			ShowDebugMessage(" "..x..": "..TrackedDamageTable[x])
		end
		ShowDebugMessage(" Total damage: "..GetDamageTableTotal())
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

		-- Stuff to run every second goes here
		CycleDamageTable()
		UpdateTotalDisplay()

		if (showDebugMessages == true) then
			debug_DisplayDamageTable()
		end

	end
end

-- ----------------------------------------------
-- Main event handler that passes stuff off to other handler functions
-- ----------------------------------------------

local function MainEventHandler(self, event, arg1, eventType, ...)
	if (event == "ADDON_LOADED" and arg1 == addonName) then
			ShowMessage("|cff3399FF"..addonName.."|r loaded. Window will appear in bear form.")
			InitializeDamageTable()
			InitWindow()
		elseif (event == "PLAYER_REGEN_ENABLED") then
			Handler_PlayerLeaveCombat()

		elseif (event == "PLAYER_REGEN_DISABLED") then
			Handler_PlayerEnterCombat()
			UpdateTotalDisplay()

		elseif (event == "UPDATE_SHAPESHIFT_FORM") then
			-- This gets called constantly in combat, and I'm not sure why
			Handler_Shapeshift()

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
					end

					if (eventType == "ENVIRONMENTAL_DAMAGE") then
						amount = select(11,...)
					end

					if (eventType == "SPELL_DAMAGE" or arg2 == "SPELL_PERIODIC_DAMAGE") then
						amount = select(13,...)
					end

					TrackDamage(amount)
				end
			end

		end
end


-- ----------------------------------------------
-- Register event handlers
-- This apparently needs to be done last
-- ----------------------------------------------

DamageInLastFiveFrame:SetScript("OnEvent", MainEventHandler)
DamageInLastFiveFrame:SetScript("OnUpdate", onFrameUpdate)