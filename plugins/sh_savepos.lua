PLUGIN.name = "Save Position"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Saves where a character left."

function PLUGIN:PlayerDisconnected(client)
	if (!client.character) then
		return
	end

	client.character:SetData("pos", client:GetPos())
	client.character:SetData("posmap", game.GetMap())
end

function PLUGIN:PlayerSpawn(client)
	local map = client.character:GetData("posmap")
	local position = client.character:GetData("pos")

	if (map and map == game.GetMap() and position) then
		client:SetPos(position + Vector(0, 0, 8))
	end

	client.character:SetData("posmap", nil)
	client.character:SetData("pos", nil)
end