-- Include NutScript content.
resource.AddWorkshop("207739713")

-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store NutScript information.
nut = nut or {util = {}, meta = {}}

-- Send the following files to players.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("shared.lua")

-- Include utility functions, data storage functions, and then shared.lua
include("core/sh_util.lua")
include("core/sv_data.lua")
include("shared.lua")

-- Connect to the database using SQLite, mysqloo, or tmysql4.
nut.db.connect(function()
	-- Create the SQL tables if they do not exist.
	nut.db.loadTables()
	nut.log.loadTables()
	
	MsgC(Color(0, 255, 0), "NutScript has connected to the database.\n")
end)

-- Resources that are required for players to download are here.
resource.AddFile("materials/nutscript/gui/vignette.png")
resource.AddFile("resource/fonts/fontello.ttf")

concommand.Add("nut_setowner", function(client, command, arguments)
    if (!IsValid(client)) then
        MsgC(Color(255, 0, 0), "** 'nut_setowner' has been deprecated in NutScript 1.1\n")
        MsgC(Color(255, 0, 0), "** Instead, please install an admin mod and use that instead.\n")
    end
end)
