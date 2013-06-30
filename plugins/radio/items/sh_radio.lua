ITEM.name = "Radio"
ITEM.uniqueID = "radio"
ITEM.category = "Communication"
ITEM.model = Model("models/props_junk/PopCan01a.mdl")
ITEM.desc = "A radio with its frequency set to %Freq|nothing%.\nThis radio is currently %On|off%."
ITEM.functions = {}
ITEM.functions.Toggle = {
	tip = "Turns the radio on or off.",
	icon = "icon16/weather_sun.png",
	menuOnly = true,
	run = function(itemTable, client, data)
		if (SERVER) then
			local frequency = data.Freq

			if (!data.On or data.On == "off") then
				data.On = "on"
			else
				data.On = "off"
			end

			client.character:Send("inv", client)
		end

		return false
	end
}
ITEM.functions.Freq = {
	alias = "Set Freq",
	icon = "icon16/tag_blue_edit.png",
	menuOnly = true,
	run = function(itemTable, client, data, entity, index)
		if (CLIENT) then
			Derma_StringRequest("Change Frequency", "What would you like the frequency to be?", "000.0", function(frequency)
				if (!string.match(frequency, "%d%d%d%.%d")) then
					nut.util.Notify("Frequencies must follow the ###.# format to be valid.", client)

					return
				end

				net.Start("nut_RadioFreq")
					net.WriteUInt(index, 8)
					net.WriteString(frequency)
				net.SendToServer()
			end)
		end

		return false
	end
}

if (SERVER) then
	util.AddNetworkString("nut_RadioFreq")

	net.Receive("nut_RadioFreq", function(length, client)
		local index = net.ReadUInt(8)
		local frequency = net.ReadString()
		local item = client:GetItem("radio", index)

		if (item) then
			item.data = item.data or {}
			item.data.Freq = frequency

			client.character:Send("inv", client)
		end
	end)
end