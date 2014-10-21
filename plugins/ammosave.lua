--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

PLUGIN.name = "Ammo Saver"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Saves the ammo of a character."
PLUGIN.ammoList = {}
nut.ammo = nut.ammo or {}


function nut.ammo.register(name)
	table.insert(PLUGIN.ammoList, name)
end

-- Register Default HL2 Ammunition.
nut.ammo.register("ar2")
nut.ammo.register("pistol")
nut.ammo.register("357")
nut.ammo.register("smg1")
nut.ammo.register("xbowbolt")
nut.ammo.register("buckshot")
nut.ammo.register("rpg_round")
nut.ammo.register("smg1_grenade")
nut.ammo.register("grenade")
nut.ammo.register("ar2altfire")
nut.ammo.register("slam")

-- Register Cut HL2 Ammunition.
nut.ammo.register("alyxgun")
nut.ammo.register("sniperround")
nut.ammo.register("sniperpenetratedround")
nut.ammo.register("thumper")
nut.ammo.register("gravity")
nut.ammo.register("battery")
nut.ammo.register("gaussenergy")
nut.ammo.register("combinecannon")
nut.ammo.register("airboatgun")
nut.ammo.register("striderminigun")
nut.ammo.register("helicoptergun")

-- Called right before the character has its information save.
function PLUGIN:CharacterPreSave(character)
	-- Get the player from the character.
	local client = character:getPlayer()
	-- Check to see if we can get the player's ammo.
	if (IsValid(client)) then
		local ammoTable = {}

		for k, v in ipairs(self.ammoList) do
			local ammo = client:GetAmmoCount(v)

			if (ammo > 0) then
				ammoTable[v] = ammo
			end
		end

		character:setData("ammo", ammoTable)
	end
end

-- Called after the player's loadout has been set.
function PLUGIN:PostPlayerLoadout(client)
	-- Get the saved ammo table from the character data.
	local character = client:getChar()
	local ammoTable = character:getData("ammo")

	-- Check if the ammotable is exists.
	if (ammoTable) then
		for k, v in pairs(ammoTable) do
			client:GiveAmmo(v, k)
		end
	end
end