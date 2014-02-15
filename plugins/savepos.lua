PLUGIN.name = "Save Position"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Saves where a character left."

function PLUGIN:PlayerDisconnected(client)
	if (!client.character) then
		return
	end

	client.character:SetData("pos", client:GetPos(), nil, true)
	client.character:SetData("posmap", game.GetMap(), nil, true)
end

function PLUGIN:PlayerSpawn(client)
	timer.Simple(0.1, function()
		if (!IsValid(client)) then
			return
		end

		local map = client.character:GetData("posmap")
		local position = client.character:GetData("pos")

		if (map and map == game.GetMap() and position) then
			client:SetPos(position + Vector(0, 0, 8))
		end

		client.character:SetData("posmap", nil, nil, true)
		client.character:SetData("pos", nil, nil, true)
	end)
end