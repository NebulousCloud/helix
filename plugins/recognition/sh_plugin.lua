PLUGIN.name = "Recognition"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Allows players to recognize others."

if (CLIENT) then
	function PLUGIN:IsPlayerRecognized(client)
		local recognized = LocalPlayer().character:GetData("recog", {})

		if (recognized[client.character:GetVar("id", 0)] == true) then
			return true
		end
	end

	local DESC_LENGTH = 37

	function PLUGIN:GetPlayerName(client, mode, text)
		if (client != LocalPlayer() and !nut.schema.Call("IsPlayerRecognized", client)) then
			local fakeName = nut.schema.Call("GetUnknownPlayerName", client)

			if (!fakeName) then
				if (mode) then
					local description = client.character:GetVar("description", "")

					if (#description > DESC_LENGTH) then
						description = string.sub(description, 1, DESC_LENGTH - 3).."..."
					end

					fakeName = "["..description.."]"
				else
					return "Unknown"
				end
			end

			return fakeName
		end
	end
else
	function PLUGIN:SetRecognized(client, other)
		local id = client.character:GetVar("id")
		local recognized = other.character:GetData("recog", {})
			recognized[id] = true
		other.character:SetData("recog", recognized)
	end
end

nut.util.Include("sh_commands.lua")