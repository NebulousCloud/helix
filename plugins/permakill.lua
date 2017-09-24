PLUGIN.name = "Permakill"
PLUGIN.author = "Thadah Denyse"
PLUGIN.description = "Adds permanent death in the server options."

nut.config.Add("pkActive", false, "Whether or not permakill is activated on the server.", nil, {
	category = "Permakill"
})

nut.config.Add("pkWorld", false, "Whether or not world and self damage produce permanent death.", nil, {
	category = "Permakill"
})

function PLUGIN:PlayerDeath(client, inflictor, attacker)
	local character = client:GetChar()

	if (nut.config.Get("pkActive")) then
		if !(nut.config.Get("pkWorld") and (client == attacker or inflictor:IsWorld())) then
			return
		end
		character:SetData("permakilled", true)
	end
end

function PLUGIN:PlayerSpawn(client)
	local character = client:GetChar()
	if (nut.config.Get("pkActive") and character and character:GetData("permakilled")) then
		character:Ban()
	end
end
