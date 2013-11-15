--[[
	Purpose: Provides some utility functions that include core
	gamemode files and prepares schemas.
--]]

local startTime = CurTime()

-- Allows us to use the spawn menu and toolgun.
DeriveGamemode("sandbox")

-- Gamemode variables.
nut.Name = "NutScript"
nut.Author = "Chessnut"

-- Include and send needed utility functions.
include("sh_util.lua")
AddCSLuaFile("sh_util.lua")

-- More of a config, but a table of models for factions to use be default.
-- We use Model(modelName) because it also precaches them for us.
FEMALE_MODELS = {
	Model("models/humans/group01/female_01.mdl"),
	Model("models/humans/group01/female_02.mdl"),
	Model("models/humans/group01/female_03.mdl"),
	Model("models/humans/group01/female_06.mdl"),
	Model("models/humans/group01/female_07.mdl"),
	Model("models/humans/group02/female_01.mdl"),
	Model("models/humans/group02/female_03.mdl"),
	Model("models/humans/group02/female_06.mdl"),
	Model("models/humans/group01/female_04")
}

-- Ditto, except they're men.
MALE_MODELS = {
	Model("models/humans/group01/male_01.mdl"),
	Model("models/humans/group01/male_02.mdl"),
	Model("models/humans/group01/male_04.mdl"),
	Model("models/humans/group01/male_05.mdl"),
	Model("models/humans/group01/male_06.mdl"),
	Model("models/humans/group01/male_07.mdl"),
	Model("models/humans/group01/male_08.mdl"),
	Model("models/humans/group01/male_09.mdl"),
	Model("models/humans/group02/male_01.mdl"),
	Model("models/humans/group02/male_03.mdl"),
	Model("models/humans/group02/male_05.mdl"),
	Model("models/humans/group02/male_07.mdl"),
	Model("models/humans/group02/male_09.mdl")
}

-- Include translations and configurations.
nut.util.Include("sh_translations.lua")
nut.util.Include("sh_config.lua")

-- Other core directories. The second argument is true since they're in the framework.
-- If they werne't, it'd try to include them from the schema!
nut.util.IncludeDir("libs", true)
nut.util.IncludeDir("core", true)
nut.util.IncludeDir("derma", true)

-- Load plugins relative to the framework's folder.
nut.plugin.Load(GM.FolderName)

-- Include commands.
nut.util.Include("sh_commands.lua")