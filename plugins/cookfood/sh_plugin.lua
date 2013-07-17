PLUGIN.name = "Cook Food"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "How about getting new foods in Nut Script?"

nut.util.Include("sh_lang.lua")

ATTRIB_COOK = nut.attribs.SetUp("Cooking", "Affects how good is the result of cooking.", "cook")
function PLUGIN:CreateCharVars(character)
	character:NewVar("hunger", 100, CHAR_PRIVATE, true)
	character:NewVar("thirst", 100, CHAR_PRIVATE, true)
end

if (CLIENT) then

	nut.bar.Add("hunger", {
		getValue = function()
			if (LocalPlayer().character) then
				return LocalPlayer().character:GetVar("hunger", 0)
			else
				return 0
			end
		end,
		color = Color(188, 255, 122)
	})

	nut.bar.Add("thirst", {
		getValue = function()
			if (LocalPlayer().character) then
				return LocalPlayer().character:GetVar("thirst", 0)
			else
				return 0
			end
		end,
		color = Color(123, 156, 255)
	})
	
	surface.CreateFont("nut_ChatFontRadio", {
		font = "Courier New",
		size = 18,
		weight = 800
	})

	function PLUGIN:ShouldDrawTargetEntity(entity)
		if (entity:GetClass() == "nut_stove") then
			return true
		end
	end

	function PLUGIN:DrawTargetID(entity, x, y, alpha)
		if (entity:GetClass() == "nut_stove") then
			local mainColor = nut.config.mainColor
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

			nut.util.DrawText(x, y, nut.lang.Get("stove_name"), color)
				y = y + nut.config.targetTall
				local text = nut.lang.Get("stove_desc")
			nut.util.DrawText(x, y, text, Color(255, 255, 255, alpha))
		end
	end
	
else
	
	local HUNGER_SPEED = 100
	local THIRST_SPEED = 120
	HUNGER_MAX = 100
	THIRST_MAX = 100
	local HUNGER_RATE = CurTime()
	local THIRST_RATE = CurTime()
	
	local playerMeta = FindMetaTable("Player")
	
	function playerMeta:SolveHunger( intAmount )
		local hunger = self.character:GetVar("hunger", 0)
		self.character:SetVar("hunger", math.Clamp( hunger + intAmount, 0, HUNGER_MAX ))
	end
	
	function playerMeta:SolveThirst( intAmount )
		local hunger = self.character:GetVar("thirst", 0)
		self.character:SetVar("thirst", math.Clamp( hunger + intAmount, 0, THIRST_MAX ))
	end
	
	hook.Add( "Think", "plg_Hunger", function()
	
		if HUNGER_RATE < CurTime() then
			for _, player in pairs( player.GetAll() ) do
				if player.character then
					local hunger = player.character:GetVar("hunger", 0)
					player.character:SetVar("hunger", math.Clamp( hunger - 10, 0, HUNGER_MAX ))
				end
			end
			HUNGER_RATE = CurTime() + HUNGER_SPEED
		end
		
		if THIRST_RATE < CurTime() then
			for _, player in pairs( player.GetAll() ) do
				if player.character then
					local hunger = player.character:GetVar("thirst", 0)
					player.character:SetVar("thirst", math.Clamp( hunger - 10, 0, THIRST_MAX ))
				end
			end
			THIRST_RATE = CurTime() + THIRST_SPEED
		end
		
	end)
	
	
	function PLUGIN:LoadData()
		local restored = nut.util.ReadTable("stoves")

		if (restored) then
			for k, v in pairs(restored) do
				local position = v.position
				local angles = v.angles
				local active = v.active

				local entity = ents.Create("nut_stove")
				entity:SetPos(position)
				entity:SetAngles(angles)
				entity:Spawn()
				entity:Activate()
				entity:SetNetVar("active", active)
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_stove")) do
			data[#data + 1] = {
				position = v:GetPos(),
				angles = v:GetAngles(),
				active = v:GetNetVar("active")
			}
		end

		nut.util.WriteTable("stoves", data)
	end
end
