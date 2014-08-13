nut.config.add("maxChars", 5, "The maximum number of characters a player can have.")
nut.config.add("color", Color(75, 119, 190), "The main color theme for the framework.")
nut.config.add("font", "Impact", "The font used to display titles.", function(oldValue, newValue)
	if (CLIENT) then
		hook.Run("LoadFonts", newValue)
	end
end)
nut.config.add("maxAttribs", 30, "The total maximum amount of attribute points allowed.")