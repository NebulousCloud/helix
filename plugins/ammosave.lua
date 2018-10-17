
PLUGIN.name = "Ammo Saver"
PLUGIN.author = "Black Tea"
PLUGIN.description = "Saves the ammo of a character."
PLUGIN.ammoList = {}

ix.ammo = ix.ammo or {}

function ix.ammo.register(name)
	table.insert(PLUGIN.ammoList, name)
end

-- Register Default HL2 Ammunition.
ix.ammo.register("ar2")
ix.ammo.register("pistol")
ix.ammo.register("357")
ix.ammo.register("smg1")
ix.ammo.register("xbowbolt")
ix.ammo.register("buckshot")
ix.ammo.register("rpg_round")
ix.ammo.register("smg1_grenade")
ix.ammo.register("grenade")
ix.ammo.register("ar2altfire")
ix.ammo.register("slam")

-- Register Cut HL2 Ammunition.
ix.ammo.register("alyxgun")
ix.ammo.register("sniperround")
ix.ammo.register("sniperpenetratedround")
ix.ammo.register("thumper")
ix.ammo.register("gravity")
ix.ammo.register("battery")
ix.ammo.register("gaussenergy")
ix.ammo.register("combinecannon")
ix.ammo.register("airboatgun")
ix.ammo.register("striderminigun")
ix.ammo.register("helicoptergun")

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
