
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
local showDebugMessages = false

-- How long is the interval between updates? (default is 5 seconds)
local secondsInInterval = 5

-- Should we hide the window if the player isn't in bear form?
local hideOutsideBearForm = true

-- ----------------------------------------------
-- You shouldn't need to touch anything past here
-- ----------------------------------------------

-- What is the stance number of bear form
local bearFormID = 1

-- Addon name, to detect when this addon has been loaded (don't touch this)
local addonName = "FrenziedRegenerationHelper"

local windowVisible = false

-- Track if the player is in combat or not
-- Currently not used, but I think I will use this in the future for something
local isPlayerInCombat = false


-- ----------------------------------------------
-- General housekeeping functions
-- ----------------------------------------------

local function ShowDebug(msg)
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
	ShowDebug("Trying to create window...")
	DisplayWindow = CreateFrame("Frame", "containerFrame" ,UIParent)
	DisplayWindow:SetBackdrop({bgFile=[[Interface\ChatFrame\ChatFrameBackground]],edgeFile=[[Interface/Tooltips/UI-Tooltip-Border]],tile=true,tileSize=4,edgeSize=4,insets={left=0.5,right=0.5,top=0.5,bottom=0.5}})
	DisplayWindow:SetSize(200, 22)
	DisplayWindow:SetBackdropColor(r, g, b, 0.5)
	DisplayWindow:SetBackdropBorderColor(0, 0, 0, 1)
	DisplayWindow:SetPoint("CENTER", 0, 0)

	-- Here's a list of fonts http://wow.gamepedia.com/API_FontInstance_SetFontObject
	DisplayWindow.text = DisplayWindow:CreateFontString("displayString", "BACKGROUND", "GameFontHighlight")
	DisplayWindow.text:SetAllPoints()
	DisplayWindow.text:SetText("Damage in last "..secondsInInterval.."s")
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

local TrackedDamageAmount = 0
local function ResetTrackedDamage() 
	ShowDebug("Damage in last 5 seconds was: "..TrackedDamageAmount)
	TrackedDamageAmount = 0
end

local function  UpdateTotalDisplay() 
	local displayAmount = 0

	-- Calculate the amount that would be healed from damage taken
	local amountHealedFromDamage = TrackedDamageAmount * frDamagedHealed

	-- Calculate the minimum amount FR will heal (5% of the players max health)
	local minimumHealAmount = UnitHealthMax("player") * minimumHealMultiplier

	-- Figure out which would heal more, and disply that one
	if (amountHealedFromDamage > minimumHealAmount) then
		displayAmount = amountHealedFromDamage
	else
		displayAmount = minimumHealAmount
	end

	DisplayWindow.text:SetText(FormatNumber(displayAmount))

	ResetTrackedDamage()
end	


local function TrackDamage(dmg)
	TrackedDamageAmount = TrackedDamageAmount + dmg
end


-- ----------------------------------------------
-- This runs every second, apparently
-- Use this to run the update every X seconds
-- ----------------------------------------------

local total = 0
local function onFrameUpdate(self, elapsed)
	total = total + elapsed
	if (total >= secondsInInterval) then
		UpdateTotalDisplay()
		total = 0
	end
end

-- ----------------------------------------------
-- Main event handler that passes stuff off to other handler functions
-- ----------------------------------------------

local function MainEventHandler(self, event, arg1, eventType, ...)
	if (event == "ADDON_LOADED" and arg1 == addonName) then
			ShowMessage("|cff3399FF"..addonName.."|r loaded. Window will appear in bear form.")
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