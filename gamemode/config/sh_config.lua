
-- You can change the default language here:
ix.config.language = "english"
ix.config.itemFormat = "<font=ixGenericFont>%s</font>\n<font=ixSmallFont>%s</font>"

--[[
	DO NOT CHANGE ANYTHING BELOW THIS.

	This is the Helix main configuration file.
	This file DOES NOT set any configurations, instead it just prepares them.
	To set the configuration, there is a "Config" tab in the F1 menu for super admins and above.
	Use the menu to change the variables, not this file.
--]]

ix.config.Add("maxChars", 5, "The maximum number of characters a player can have.", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})

ix.config.Add("color", Color(75, 119, 190), "The main color theme for the framework.", function(oldValue, newValue)
	newValue.a = 255
end, {category = "appearance"})

ix.config.Add("font", "Impact", "The font used to display titles.", function(oldValue, newValue)
	if (CLIENT) then
		hook.Run("LoadFonts", newValue, ix.config.Get("genericFont"))
	end
end, {category = "appearance"})

ix.config.Add("genericFont", "Segoe UI", "The font used to display generic texts.", function(oldValue, newValue)
	if (CLIENT) then
		hook.Run("LoadFonts", ix.config.Get("font"), newValue)
	end
end, {category = "appearance"})

ix.config.Add("maxAttributes", 30, "The total maximum amount of attribute points allowed.", nil, {
	data = {min = 1, max = 250},
	category = "characters"
})
ix.config.Add("chatAutoFormat", true, "Whether or not to automatically capitalize and punctuate in-character text.", nil, {
	category = "Chat"
})
ix.config.Add("chatRange", 280, "The maximum distance a person's IC chat message goes to.", nil, {
	form = "Float",
	data = {min = 10, max = 5000},
	category = "chat"
})
ix.config.Add("chatMax", 256, "The maximum amount of characters that can be sent in chat.", nil, {
	data = {min = 32, max = 1024},
	category = "chat"
})
ix.config.Add("chatColor", Color(255, 255, 150), "The default color for IC chat.", nil, {category = "chat"})
ix.config.Add("chatListenColor", Color(175, 255, 150), "The color for IC chat if you are looking at the speaker.", nil, {
	category = "chat"
})
ix.config.Add("oocDelay", 10, "The delay before a player can use OOC chat again in seconds.", nil, {
	data = {min = 0, max = 10000},
	category = "chat"
})
ix.config.Add("allowGlobalOOC", true, "Whether or not Global OOC is enabled.", nil, {
	category = "chat"
})
ix.config.Add("loocDelay", 0, "The delay before a player can use LOOC chat again in seconds.", nil, {
	data = {min = 0, max = 10000},
	category = "chat"
})
ix.config.Add("spawnTime", 5, "The time it takes to respawn.", nil, {
	data = {min = 0, max = 10000},
	category = "characters"
})
ix.config.Add("invW", 6, "How many slots in a row there is in a default inventory.", nil, {
	data = {min = 0, max = 20},
	category = "characters"
})
ix.config.Add("invH", 4, "How many slots in a column there is in a default inventory.", nil, {
	data = {min = 0, max = 20},
	category = "characters"
})
ix.config.Add("minNameLen", 4, "The minimum number of characters in a name.", nil, {
	data = {min = 4, max = 64},
	category = "characters"
})
ix.config.Add("maxNameLen", 32, "The maximum number of characters in a name.", nil, {
	data = {min = 16, max = 128},
	category = "characters"
})
ix.config.Add("minDescLen", 16, "The minimum number of characters in a description.", nil, {
	data = {min = 0, max = 300},
	category = "characters"
})
ix.config.Add("saveInterval", 300, "How often characters save in seconds.", nil, {
	data = {min = 60, max = 3600},
	category = "characters"
})
ix.config.Add("walkSpeed", 130, "How fast a player normally walks.", function(oldValue, newValue)
	for _, v in ipairs(player.GetAll())	do
		v:SetWalkSpeed(newValue)
	end
end, {
	data = {min = 75, max = 500},
	category = "characters"
})
ix.config.Add("runSpeed", 235, "How fast a player normally runs.", function(oldValue, newValue)
	for _, v in ipairs(player.GetAll())	do
		v:SetRunSpeed(newValue)
	end
end, {
	data = {min = 75, max = 500},
	category = "characters"
})
ix.config.Add("walkRatio", 0.5, "How fast one goes when holding ALT.", nil, {
	form = "Float",
	data = {min = 0, max = 1},
	category = "characters"
})
ix.config.Add("punchStamina", 10, "How much stamina punches use up.", nil, {
	data = {min = 0, max = 100},
	category = "characters"
})
ix.config.Add("intro", true, "Whether or not the Helix intro is enabled for new players.", nil, {
	category = "appearance"
})
ix.config.Add("music", "music/hl2_song2.mp3", "The default music played in the character menu.", nil, {
	category = "appearance"
})
ix.config.Add("logo", "https://static.miraheze.org/nutscriptwiki/2/26/Nutscript.png",
	"The icon shown on the character menu. Max size is 86x86", nil, {
	category = "appearance"
})
ix.config.Add("logoURL", "https://nutscript.net/", "The URL opened when the icon is clicked.", nil, {
	category = "appearance"
})
ix.config.Add("vignette", true, "Whether or not the vignette is shown.", nil, {
	category = "appearance"
})
ix.config.Add("scoreboardRecognition", false, "Whether or not recognition is used in the scoreboard.", nil, {
	category = "characters"
})
ix.config.Add("defMoney", 0, "The amount of money that players start with.", nil, {
	category = "characters",
	data = {min = 0, max = 1000}
})
ix.config.Add("allowVoice", false, "Whether or not voice chat is allowed.", nil, {
	category = "server"
})
ix.config.Add("voiceDistance", 600.0, "How far can the voice be heard.", nil, {
	form = "Float",
	category = "server",
	data = {min = 0, max = 5000}
})
ix.config.Add("wepAlwaysRaised", false, "Whether or not weapons are always raised.", nil, {
	category = "server"
})
ix.config.Add("wepRaiseTime", 1, "The time it takes for a weapon to raise.", nil, {
	form = "Float",
	data = {min = 0.1, max = 60},
	category = "server"
})
ix.config.Add("maxHoldWeight", 100, "The maximum weight that a player can carry in their hands.", nil, {
	data = {min = 1, max = 500},
	category = "interaction"
})
ix.config.Add("throwForce", 732, "How hard a player can throw the item that they're holding.", nil, {
	data = {min = 0, max = 8192},
	category = "interaction"
})
ix.config.Add("itemPickupTime", 0.5, "How long it takes to pick up and put an item in your inventory.", nil, {
	form = "Float",
	data = {min = 0, max = 5},
	category = "interaction"
})
