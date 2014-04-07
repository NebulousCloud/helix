local PLUGIN = PLUGIN
PLUGIN.name = "Stamina"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a stamina system to limit running."

nut.util.Include("sv_hooks.lua")

if (CLIENT) then
	nut.bar.Add("stamina", {
		getValue = function()
			if (LocalPlayer().character) then
				return LocalPlayer().character:GetVar("stamina", 0)
			else
				return 0
			end
		end,
		color = Color(245, 200, 30)
	})
end

function PLUGIN:RegisterAttributes()
	ATTRIB_SPD = nut.attribs.SetUp("Speed", "Affects how fast you can run.", "spd", function(client, points)
		client:SetRunSpeed(nut.config.runSpeed + points*3)
	end)

	ATTRIB_END = nut.attribs.SetUp("Endurance", "Affects how long you can run for.", "end")
end

function PLUGIN:CreateCharVars(character)
	character:NewVar("stamina", 100, CHAR_PRIVATE, true)
end