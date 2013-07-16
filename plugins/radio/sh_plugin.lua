PLUGIN.name = "Radio"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds usable radios for in-game communication."

if (CLIENT) then
	surface.CreateFont("nut_ChatFontRadio", {
		font = "Courier New",
		size = 18,
		weight = 800
	})

	function PLUGIN:ShouldDrawTargetEntity(entity)
		if (entity:GetClass() == "nut_radio") then
			return true
		end
	end

	function PLUGIN:DrawTargetID(entity, x, y, alpha)
		if (entity:GetClass() == "nut_radio") then
			local mainColor = nut.config.mainColor
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

			nut.util.DrawText(x, y, "Radio", color)
				y = y + nut.config.targetTall

				local text = "No frequency has been set."
				local frequency = entity:GetNetVar("freq")

				if (frequency) then
					text = "Frequency set to "..frequency.."."
				end
			nut.util.DrawText(x, y, text, Color(255, 255, 255, alpha))
		end
	end
else
	function PLUGIN:LoadData()
		local restored = nut.util.ReadTable("radios")

		if (restored) then
			for k, v in pairs(restored) do
				local position = v.position
				local angles = v.angles
				local frequency  = v.freq
				local active = v.active

				local entity = ents.Create("nut_radio")
				entity:SetPos(position)
				entity:SetAngles(angles)
				entity:Spawn()
				entity:Activate()
				entity:SetNetVar("freq", frequency)
				entity:SetNetVar("active", active)
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_radio")) do
			data[#data + 1] = {
				position = v:GetPos(),
				angles = v:GetAngles(),
				freq = v:GetNetVar("freq"),
				active = v:GetNetVar("active")
			}
		end

		nut.util.WriteTable("radios", data)
	end
end

nut.command.Register({
	syntax = "<number freq>",
	onRun = function(client, arguments)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity
		local frequency = arguments[1] or ""

		if (!string.match(frequency, "%d%d%d%.%d")) then
			nut.util.Notify("Frequencies must follow the ###.# format to be valid.", client)

			return
		end

		if (IsValid(entity) and entity:GetClass() == "nut_radio") then
			entity:SetNetVar("freq", frequency)

			nut.util.Notify("You have set this radio's frequency to "..frequency..".", client)
		else
			nut.util.Notify("You must be looking at a radio.", client)
		end
	end
}, "freq")

nut.chat.Register("radio", {
	onChat = function(speaker, text)
		if (LocalPlayer() != speaker and speaker:GetPos():Distance(LocalPlayer():GetPos()) <= nut.config.chatRange) then
			chat.AddText(Color(169, 207, 232), speaker:Name()..": "..text)
		else
			chat.AddText(Color(85, 161, 39), speaker:Name()..": "..text)
		end
	end,
	prefix = {"/radio", "/r"},
	canHear = function(speaker, listener)
		local position = listener:GetPos()
		local chatRange = nut.config.chatRange
		local entities = ents.FindByClass("nut_radio")
		local radioItems = listener:GetItemsByClass("radio")

		if (speaker:GetPos():Distance(position) <= chatRange) then
			return true
		end

		for k, v in pairs(speaker:GetItemsByClass("radio")) do
			if (v.data and v.data.Freq and v.data.On and v.data.On == "on") then
				for k2, v2 in pairs(radioItems) do
					if (v2.data and v2.data.On == "on" and v2.data.Freq and v.data.Freq == v2.data.Freq) then
						return true
					end
				end

				for k2, v2 in pairs(entities) do
					if (v2:GetNetVar("active") and v2:GetNetVar("freq", "") == v.data.Freq and v2:GetPos():Distance(position) <= chatRange) then
						return true
					end
				end
			end
		end

		local data = {}
			data.start = speaker:GetShootPos()
			data.endpos = data.start + speaker:GetAimVector() * 96
			data.filter = speaker
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity)) then
			if (!entity:GetNetVar("active")) then
				return false
			end

			local frequency = entity:GetNetVar("freq", "")

			for k, v in pairs(radioItems) do
				if (v.data and v.data.On and v.data.On == "on" and v.data.Freq and v.data.Freq == frequency) then
					return true
				end
			end
		end 
	end,
	canSay = function(speaker)
		local data = {}
			data.start = speaker:GetShootPos()
			data.endpos = data.start + speaker:GetAimVector() * 96
			data.filter = speaker
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity)) then
			if (entity:GetNetVar("active")) then
				return true
			end
		end

		for k, v in pairs(speaker:GetItemsByClass("radio")) do
			if (v.data and v.data.On and v.data.On == "on") then
				return true
			end
		end

		nut.util.Notify("You need to be looking at or own a radio that is on.", speaker)
	end,
	font = "nut_ChatFontRadio"
})