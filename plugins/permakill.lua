PLUGIN.name = "Permakill"
PLUGIN.author = "Thadah Denyse"
PLUGIN.description = "Adds permanent death in the server options."

ix.config.Add("permakill", false, "Whether or not permakill is activated on the server.", nil, {
	category = "Permakill"
})

ix.config.Add("permakillWorld", false, "Whether or not world and self damage produce permanent death.", nil, {
	category = "Permakill"
})

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	local character = client:GetCharacter()

	if (ix.config.Get("permakill")) then
		if !(ix.config.Get("permakillWorld") and (client == attacker or inflictor:IsWorld())) then
			return
		end
		character:SetData("permakilled", true)
	end
end

function PLUGIN:PlayerSpawn(client)
	local character = client:GetCharacter()
	if (ix.config.Get("permakill") and character and character:GetData("permakilled")) then
		character:Ban()
	end
end
