nut.config.add("maxChars", 5, "The maximum number of characters a player can have.", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})
nut.config.add("color", Color(75, 119, 190), "The main color theme for the framework.", nil, {category = "appearance"})
nut.config.add("font", "Impact", "The font used to display titles.", function(oldValue, newValue)
	if (CLIENT) then
		hook.Run("LoadFonts", newValue)
	end
end, {category = "appearance"})
nut.config.add("maxAttribs", 30, "The total maximum amount of attribute points allowed.", nil, {
	data = {min = 1, max = 250},
	category = "characters"
})
nut.config.add("chatRange", 280, "The maximum distance a person's IC chat message goes to.", nil, {
	form = "Float",
	data = {min = 10, max = 5000},
	category = "chat"
})
nut.config.add("chatColor", Color(255, 239, 150), "The default color for IC chat.", nil, {category = "chat"})
nut.config.add("chatListenColor", Color(168, 240, 170), "The color for IC chat if you are looking at the speaker.", nil, {category = "chat"})
nut.config.add("oocDelay", 10, "The delay before a player can use OOC chat again in seconds.", nil, {
	data = {min = 0, max = 10000},
	category = "chat"
})
nut.config.add("loocDelay", 0, "The delay before a player can use LOOC chat again in seconds.", nil, {
	data = {min = 0, max = 10000},
	category = "chat"
})
nut.config.add("spawnTime", 5, "The time it takes to respawn.", nil, {
	data = {min = 0, max = 10000},
	category = "characters"
})
nut.config.add("invW", 6, "How many slots in a row there is in a default inventory.", nil, {
	data = {min = 0, max = 20},
	category = "characters"
})
nut.config.add("invH", 4, "How many slots in a column there is in a default inventory.", nil, {
	data = {min = 0, max = 20},
	category = "characters"
})
nut.config.add("minDescLen", 16, "The minimum number of characters in a description.", nil, {
	data = {min = 0, max = 300},
	category = "characters"
})
nut.config.add("saveInterval", 300, "How often characters save in seconds.", nil, {
	data = {min = 60, max = 3600},
	category = "characters"
})