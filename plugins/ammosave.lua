
local PLUGIN = PLUGIN

PLUGIN.name = "Ammo Saver"
PLUGIN.author = "Black Tea"
PLUGIN.description = "Saves the ammo of a character."
PLUGIN.ammoList = {}

ix.ammo = ix.ammo or {}

function ix.ammo.Register(name)
	name = name:lower()

	if (!table.HasValue(PLUGIN.ammoList, name)) then
		PLUGIN.ammoList[#PLUGIN.ammoList + 1] = name
	end
end

-- Register Default HL2 Ammunition.
ix.ammo.Register("ar2")
ix.ammo.Register("pistol")
ix.ammo.Register("357")
ix.ammo.Register("smg1")
ix.ammo.Register("xbowbolt")
ix.ammo.Register("buckshot")
ix.ammo.Register("rpg_round")
ix.ammo.Register("smg1_grenade")
ix.ammo.Register("grenade")
ix.ammo.Register("ar2altfire")
ix.ammo.Register("slam")

-- Register Cut HL2 Ammunition.
ix.ammo.Register("alyxgun")
ix.ammo.Register("sniperround")
ix.ammo.Register("sniperpenetratedround")
ix.ammo.Register("thumper")
ix.ammo.Register("gravity")
ix.ammo.Register("battery")
ix.ammo.Register("gaussenergy")
ix.ammo.Register("combinecannon")
ix.ammo.Register("airboatgun")
ix.ammo.Register("striderminigun")
ix.ammo.Register("helicoptergun")

-- Called right before the character has its information save.
function PLUGIN:CharacterPreSave(character)
	-- Get the player from the character.
	local client = character:GetPlayer()

	-- Check to see if we can get the player's ammo.
	if (IsValid(client)) then
		local ammoTable = {}

		for _, v in ipairs(self.ammoList) do
			local ammo = client:GetAmmoCount(v)

			if (ammo > 0) then
				ammoTable[v] = ammo
			end
		end

		character:SetData("ammo", ammoTable)
	end
end

-- Called after the player's loadout has been set.
function PLUGIN:PlayerLoadedCharacter(client)
	timer.Simple(0.25, function()
		if (!IsValid(client)) then
			return
		end

		-- Get the saved ammo table from the character data.
		local character = client:GetCharacter()

		if (!character) then
			return
		end

		local ammoTable = character:GetData("ammo")

		-- Check if the ammotable is exists.
		if (ammoTable) then
			for k, v in pairs(ammoTable) do
				client:SetAmmo(v, tostring(k))
			end
		end
	end)
end
