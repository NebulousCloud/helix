--[[
	Purpose: The framework needs to define this so the schemas can reference
	the framework without GM.BaseClass since it the baseclass is not defined in time.
--]]

-- Set this since self.BaseClass for schemas aren't created in time.
nut = nut or GM

-- A table of vgui elements. This is useful to keep track of stuff or if you can run clientside lua
-- and get a menu stuck on your screen. Happens a lot during development.
nut.gui = nut.gui or {}

-- Include shared.lua since it is very important.
include("shared.lua")

-- Create out fonts here that are going to be used.

-- Quick variable to change all the fonts.
local mainFont = "Trebuchet MS"

surface.CreateFont("nut_TitleFont", {
	font = mainFont,
	size = ScreenScale(48),
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_SubTitleFont", {
	font = mainFont,
	size = ScreenScale(8),
	weight = 500,
	antialias = true
})

surface.CreateFont("nut_ScoreTitleFont", {
	font = mainFont,
	size = ScreenScale(15),
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_ScoreTeamFont", {
	font = mainFont,
	size = ScreenScale(10),
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_HeaderFont", {
	font = mainFont,
	size = ScreenScale(18),
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_MenuButtonFont", {
	font = mainFont,
	size = ScreenScale(10),
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_BigThinFont", {
	font = mainFont,
	size = ScreenScale(11),
	weight = 500,
	antialias = true
})

surface.CreateFont("nut_TargetFont", {
	font = mainFont,
	size = 23,
	weight = 1000,
	antialias = true
})

surface.CreateFont("nut_TargetFontSmall", {
	font = mainFont,
	size = 19,
	weight = 800,
	antialias = true
})

surface.CreateFont("nut_ChatFont", {
	font = mainFont,
	size = 20,
	weight = 1000
})

surface.CreateFont("nut_ChatFontAction", {
	font = mainFont,
	size = 20,
	weight = 1000,
	italic = true
})

surface.CreateFont("nut_ScaledFont", {
	font = mainFont,
	size = 150,
	weight = 1000
})

timer.Destroy("HintSystem_OpeningMenu")
timer.Destroy("HintSystem_Annoy1")
timer.Destroy("HintSystem_Annoy2")

if (!nut.localPlayerValid) then
	hook.Add("Think", "nut_WaitForLocalPlayer", function()
		if (IsValid(LocalPlayer())) then
			netstream.Start("nut_LocalPlayerValid")
			hook.Remove("Think", "nut_WaitForLocalPlayer")
		end
	end)

	nut.localPlayerValid = true
end