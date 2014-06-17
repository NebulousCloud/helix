PLUGIN.name = "Save Ammo"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Saves ammunition data for players."

local AMMO_TYPES = {
	"ar2",
	"alyxgun",
	"pistol",
	"smg1",
	"357",
	"xbowbolt",
	"buckshot",
	"rpg_round",
	"smg1_grenade",
	"sniperround",
	"sniperpenetratedround",
	"grenade",
	"thumper",
	"gravity",
	"battery",
	"gaussenergy",
	"combinecannon",
	"airboatgun",
	"striderminigun",
	"helicoptergun",
	"ar2altfire",
	"slam"
}

function PLUGIN:CharacterSave(client)
	local ammo = {}
		for k, v in pairs(AMMO_TYPES) do
			local count = client:GetAmmoCount(v)

			if (count > 0) then
				ammo[v] = count
			end
		end
	client.character:SetData("ammo", ammo)
end

function PLUGIN:PlayerFirstLoaded(client)
	client:RemoveAllAmmo()

	local ammo = client.character:GetData("ammo")

	if (ammo) then
		for ammoType, amount in pairs(ammo) do
			client:SetAmmo(tonumber(amount) or 0, ammoType)
		end

		client.character:SetData("ammo", {})
	end
end
