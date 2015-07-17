PLUGIN.name = "Permakill"
PLUGIN.author = "Thadah Denyse"
PLUGIN.desc = "Adds permanent death in the server options"

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	local character = client:getChar()
	--if (client == attacker) or inflictor:IsWorld() then return end

	if nut.config.get("Active") then
		character:setData("permakilled", 1)
		if !nut.config.get("World") then
			if (client == attacker) or inflictor:IsWorld() then return end
		end
	end
end

function PLUGIN:PlayerSpawn(client)
	local character = client:getChar()
	if (nut.config.get("Active") and character and character:getData("permakilled") == 1) then
		timer.Create("firstPK", 0.001, 1, function() client:KillSilent() end)
		client:Lock()
		timer.Simple(nut.config.get("spawnTime"), function()
			client:KillSilent()
		end)
	end
end


nut.config.add("Active", false, "Whether or not permakill is activated on the server.", nil, {
	category = "Permakill"
})

nut.config.add("World", false, "Wether or not world and self damage produce permanent death", nil, {
	category = "Permakill"
})