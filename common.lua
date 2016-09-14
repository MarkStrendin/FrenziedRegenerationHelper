-- ----------------------------------------------
-- Common functions
-- ----------------------------------------------

function FRHelper_ShowMessage(msg)
	print("|cff3399FF"..FRHelperStatic.addonName.."|r: "..msg)
end

function FRHelper_ShowDebugMessage(msg)
	if (FRHelperOptions_Get_ShowDebugMessages() == true) then
		print("|cff3399FF"..FRHelperStatic.addonName.."-DEBUG|r: "..msg)
	end
end

-- Converts an integer RGB value to it's decimal equivalent
function FRHelper_ConvertRGBToDecimal(n)
	if (n == 0) then
		return 0
	else
		return (n/255)
	end
end

function FRHelper_ParseBool(v)
	if (v == true) then
		return true;
	else
		return false;
	end
end
