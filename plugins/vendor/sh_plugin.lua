local PLUGIN = PLUGIN
PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds NPCs that sell things."

nut.util.Include("cl_vendor.lua")

if (SERVER) then
	function PLUGIN:LoadData()
		for k, v in pairs(nut.util.ReadTable("talkers")) do
			local position = v.pos
			local angles = v.angles
			local dialogue = v.dialogue
			local factionData = v.factionData
			local classData = v.classData
			
			
			local vendorAction = v.vendorAction
			local buyadjustment = v.buyadjustment
			local money = v.money
			
			local name = v.name
			local desc = v.desc
			local model = v.model

			local entity = ents.Create("nut_vendor")
			entity:SetPos(position)
			entity:SetAngles(angles)
			entity:Spawn()
			entity:Activate()
			entity:SetNetVar("dialogue", dialogue)
			entity:SetNetVar("factiondata", factionData)
			entity:SetNetVar("classdata", classData)
			entity:SetNetVar("name", name)
			entity:SetNetVar("desc", desc)			
			
			entity:SetNetVar("vendoraction", vendorAction)
			entity:SetNetVar("buyadjustment", cashadjustment)
			entity:SetNetVar("money", money)
			
			entity:SetModel(model)
			entity:SetAnim()
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_vendor")) do
			data[#data + 1] = {
				pos = v:GetPos(),
				angles = v:GetAngles(),
				dialogue = v:GetNetVar("dialogue", {}),			
				factionData = v:GetNetVar("factiondata", {}),
				classData = v:GetNetVar("classdata", {}),
				
				vendorAction = v:GetNetVar("vendoraction", { sell = true, buy = false} ),
				buyadjustment = v:GetNetVar("buyadjustment", .5),
				money = v:GetNetVar("money", 100),
				
				name = v:GetNetVar("name", "John Doe"),
				desc = v:GetNetVar("desc", nut.lang.Get("no_desc")),
				model = v:GetModel()
			}
		end
		nut.util.WriteTable("talkers", data)
	end
end

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "nut_talker") then
			netstream.Start(client, "nut_DialogueEditor", entity)
		else
			nut.util.Notify("You are not looking at a valid nut_talker!", client)
		end
	end
}, "talkersetting")

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		local position = client:GetEyeTraceNoCursor().HitPos
		local angles = client:EyeAngles()
		angles.p = 0
		angles.y = angles.y - 180

		local entity = ents.Create("nut_talker")
		entity:SetPos(position)
		entity:SetAngles(angles)
		entity:Spawn()
		entity:Activate()

		PLUGIN:SaveData()

		nut.util.Notify("You have added a talker.", client)
	end
}, "talkeradd")

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "nut_talker") then
			entity:Remove()

			PLUGIN:SaveData()

			nut.util.Notify("You have removed this nut_talker.", client)
		else
			nut.util.Notify("You are not looking at a valid nut_talker!", client)
		end
	end
}, "talkerremove")