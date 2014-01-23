--[[
	Purpose: Creates a table of configuration values that are to help make customization
	of NutScript easier.
--]]

-- We don't want clients to get our database information.
if (SERVER) then
	-- Include server-side configurations like database information.
	nut.util.Include("sv_config.lua")
end

-- Defines a table to store all the configurations.
nut.config = nut.config or {}

-- What language NutScript shall use.
nut.config.language = "english"

-- The default walk speed.
nut.config.walkSpeed = 90

-- The default run speed.
nut.config.runSpeed = 275

-- Weapons that are always raised and able to shoot.
nut.config.alwaysRaised = {
	weapon_physgun = true,
	gmod_tool = true
}

-- If set to true, holding your reload key will toggleraise.
nut.config.holdReloadToToggle = true

-- How many seconds must the player hold reload for to toggleraise.
nut.config.holdReloadTime = 0.8

-- How often database saving should occur for players (in seconds)
nut.config.saveInterval = 600

-- How wide menus in the F1 menu are. This is a ratio for the screen's width. (0.5 = half of the screen's width)
nut.config.menuWidth = 0.5

-- How tall menus in the F1 menu are. This is a ratio for the screen's height. (0.5 = half the screen's height)
nut.config.menuHeight = 0.75

-- The main color scheme for buttons and such.
nut.config.mainColor = Color(62, 142, 200)

-- Minimum amount of characters for a description.
nut.config.descMinChars = 16

-- How many attribute points a player gets when creating a character.
nut.config.startingPoints = 20

-- Caps attribute points a player gets when a character is gaining attribute experience.
nut.config.maximumPoints = 40

-- When the player is able to run again after stamina has been depleted. (0 = disable)
nut.config.staminaRestore = 50

-- Enable breathing when stamina has been depleted. Breathing stops when stamina
-- is above the restore amount.
nut.config.breathing = true

-- The maximum distance in Source units to hear someone whispering.
nut.config.whisperRange = 160

-- The maximum distance in Source units to hear someone talk.
nut.config.chatRange = 540

-- The maximum distance in Source units to hear someone yell.
nut.config.yellRange = 720

-- The text color for game messages like joining/leaving or console text.
-- Uses a color object which goes red, green, blue. Each ranges from 0 to 255.
nut.config.gameMsgColor = Color(230, 230, 230)

-- How loud the menu music is out of 100.
nut.config.menuMusicVol = 40

-- What the actual menu music is. It can be a URL or game sound. Set to false if you
-- do not want any menu music. This can also be overwritten by the schema.
nut.config.menuMusic = false

-- How long it takes in seconds for the menu music to fade out.
nut.config.menuMusicFade = 15

-- The starting weight for inventories.
nut.config.defaultInvWeight = 20

-- Shows what other people are typing.
-- If set to false, it'll just show Typing... above someone's head when they are.
-- Setting it to true MIGHT cause a little network strain, depending on how many players there are.
nut.config.showTypingText = true

-- The maximum number of characters.
nut.config.maxChars = 4

-- The delay between which someone can buy something.
nut.config.buyDelay = 2

-- If any player can see the business menu.
nut.config.businessEnabled = true

-- The maximum number of characters in a chat message.
nut.config.maxChatLength = 500

-- The initial date that is used by the time system.
nut.config.dateStartMonth = 1
nut.config.dateStartDay = 1
nut.config.dateStartYear = 2014

-- If true, then you can't have multiple rifles, pistols, etc...
nut.config.noMultipleWepSlots = true

-- The maximum number of characters in a name.
nut.config.maxNameLength = 70

-- The maximum number of characters in a description.
nut.config.maxDescLength = 240

-- How many seconds are in a minute.
nut.config.dateMinuteLength = 60

if (CLIENT) then
	-- Whether or not the money is shown in the side menu.
	nut.config.showMoney = true

	-- Whether or not the time is shown in the side menu.
	nut.config.showTime = true

	-- If set to false, then color correction will not be enabled.
	nut.config.sadColors = true

	-- Whether or not to enable the crosshair.
	nut.config.crosshair = true

	-- The dot size of the crosshair.
	nut.config.crossSize = 1

	-- The amount of spacing beween each crosshair dot in pixels.
	nut.config.crossSpacing = 6

	-- How 'see-through' the crosshair is from 0-255, where 0 is invisible and 255 is fully
	-- visible.
	nut.config.crossAlpha = 150

	-- Whether or not to draw the vignette.
	nut.config.drawVignette = true
	
	hook.Add("SchemaInitialized", "nut_FontConfig", function()
		surface.SetFont("nut_TargetFontSmall")

		_, nut.config.targetTall = surface.GetTextSize("W")

		if (nut.config.targetTall) then
			nut.config.targetTall = nut.config.targetTall + 2
		end

		nut.config.targetTall = nut.config.targetTall or 10
	end)

	nut.config.targetTall = nut.config.targetTall or 10
end
