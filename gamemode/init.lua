DeriveGamemode("sandbox")
nut = nut or {util = {}}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("shared.lua")

include("core/sh_util.lua")
include("core/sv_data.lua")
include("shared.lua")

nut.db.connect(function()
	nut.db.loadTables()
	
	MsgC(Color(0, 255, 0), "NutScript has connected to the database.\n")
end)

resource.AddFile("materials/nutscript/gui/vignette.png")