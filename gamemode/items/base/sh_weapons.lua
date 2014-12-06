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

ITEM.name = "Weapon"
ITEM.desc = "A Weapon."
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.class = "weapon_pistol"
ITEM.width = 2
ITEM.height = 2
ITEM.isWeapon = true
ITEM.weaponCategory = "sidearm"
ITEM.camo = {
	-- worldMaterials is for world model texture.
	-- viewMaterials is for view model texture.
	-- example camo data
	/*
		[camoIndex] = {
			worldMaterials = {
				[materialIndex] = "materialPath",
				[materialIndex] = "materialPath",
			}
			viewMaterials = {
				[materialIndex] = "materialPath",
				[materialIndex] = "materialPath",
			}
		},

		[camoIndex] = {
			worldMaterials = {
				[materialIndex] = "materialPath",
				[materialIndex] = "materialPath",
			}
			viewMaterials = {
				[materialIndex] = "materialPath",
				[materialIndex] = "materialPath",
			}
		},
	*/
}

-- Make this true if you're running dev-branch of garrysmod.
-- This comment is written in >> (10/06/2014)
local isDevGarrysmod = false

-- Draw world materials.
local function drawCamoEntity(entity, camoData)
	if (isDevGarrysmod == false) then return end -- I don't want to emit goddamn error for non dev-branch developers. eww

	if (camoData) then
		local worldMaterials = camoData.worldMaterials

		if (worldMaterials) then
			for matIndex, matData in ipairs(worldMaterials) do
				-- Based on GetMaterials().
				entity:SetSubMaterial(matIndex - 1, matData)
			end
		end
	else
		print("[Nutscript] Weapon camo data is not present.")
	end
end

-- Inventory drawing
if (CLIENT) then
	-- Draw camo if it is available.
	function ITEM:drawEntity(entity, item)
		if (isDevGarrysmod == false) then entity:DrawModel() return end -- I don't want to emit goddamn error for non dev-branch developers. eww

		if (!entity.noMaterial or !entity.materialSet) then
			local camoIndex = item:getData("camo")
			if (camoIndex) then
				local camoData = item.camo[camoIndex]

				if (camoData) then
					local viewMaterials = camoData.viewMaterials

					if (viewMaterials) then
						for matIndex, matData in ipairs(viewMaterials) do
							-- Based on GetMaterials().
							entity:SetSubMaterial(matIndex - 1, matData)
						end
					end
				end

				entity.materialSet = true
			else
				entity.noMaterial = true
			end
		end

		entity:DrawModel()
	end

	function ITEM:paintOver(item, w, h)
		if (item:getData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	-- add a hook to set viewmodel's camo.
end

-- On item is dropped, Remove a weapon from the player and keep the ammo in the item.
ITEM:hook("drop", function(item)
	if (item:getData("equip")) then
		item.player.carryWeapons = item.player.carryWeapons or {}
		local weapon = item.player.carryWeapons[item.weaponCategory]

		if (weapon and weapon:IsValid()) then
			item:setData("ammo", weapon:Clip1())
			item.player:StripWeapon(item.class)
			item.player.carryWeapons[item.weaponCategory] = nil
			item.player:EmitSound("items/ammo_pickup.wav", 80)
		end
	end
end)

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.EquipUn = { -- sorry, for name order.
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/world.png",
	onRun = function(item)
		item.player.carryWeapons = item.player.carryWeapons or {}
		local weapon = item.player.carryWeapons[item.weaponCategory]

		if (weapon and weapon:IsValid()) then
			item:setData("ammo", weapon:Clip1())
		
			item.player:StripWeapon(item.class)
		else
			print(Format("[Nutscript] Weapon %s does not exist!", item.class))
		end

		item.player:EmitSound("items/ammo_pickup.wav", 80)
		item.player.carryWeapons[item.weaponCategory] = nil
		item:setData("equip", false)
		
		return false
	end,
	onCanRun = function(item)
		return (!IsValid(item.entity) and item:getData("equip") == true)
	end
}

-- On player eqipped the item, Gives a weapon to player and load the ammo data from the item.
ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/world.png",
	onRun = function(item)
		local inv = item.player:getChar():getInv()
		item.player.carryWeapons = item.player.carryWeapons or {}

		for k, v in pairs(inv.slots) do
			for k2, v2 in pairs(v) do
				if (v2.id != item.id) then
					local itemTable = nut.item.instances[v2.id]

					if (itemTable.isWeapon and item.player.carryWeapons[item.weaponCategory] and itemTable:getData("equip")) then
						item.player:notify("You're already equipping this kind of weapon")

						return false
					end
				end
			end
		end
		
		if (item.player:HasWeapon(item.class)) then
			item.player:StripWeapon(item.class)
		end

		local weapon = item.player:Give(item.class)
		if (weapon and weapon:IsValid()) then
			-- get camo data.
			local camoIndex = item:getData("camo")
			local ammo = item:getData("ammo")

			item.player.carryWeapons[item.weaponCategory] = weapon
			item.player:SelectWeapon(weapon:GetClass())
			item.player:SetActiveWeapon(weapon)
			item.player:EmitSound("items/ammo_pickup.wav", 80)
			item:setData("equip", true)

			if (camoIndex) then
				local camoData = item.camo[camoIndex]

				drawCamoEntity(weapon, camoData)
			end
			
			if (ammo) then
				weapon:SetClip1(ammo)
			end
		else
			print(Format("[Nutscript] Weapon %s does not exist!", item.class))
		end

		return false
	end,
	onCanRun = function(item)
		return (!IsValid(item.entity) and item:getData("equip") != true)
	end
}

function ITEM:onCanBeTransfered(oldInventory, newInventory)
	return !self:getData("equip")
end

-- When player dead, remove all ammo in the gun items and clear out player weapon carrying table.
hook.Add("PlayerDeath", "weapon.reset", function(client)
	client.carryWeapons = {}

	timer.Simple(0, function()
		if (client and client:getChar()) then
			local inv = client:getChar():getInv():getItems()

			for k, v in pairs(inv) do
				if (v.isWeapon) then
					if (v:getData("equip")) then
						v:setData("ammo", 0)
					end
				end
			end
		end
	end)
end)

-- When player spawned, Give all equipped weapon items and load ammo from the item data.
hook.Add("PlayerLoadedChar", "weapon.reset", function(client)
	timer.Simple(0, function()
		if (client and client:getChar()) then
			local inv = client:getChar():getInv()

			if (inv) then
				for k, v in pairs(inv:getItems()) do
					if (v.isWeapon) then
						if (v:getData("equip")) then
							client.carryWeapons = client.carryWeapons or {}

							local ammo = v:getData("ammo")
							local weapon = client:Give(v.class)
							if (weapon and weapon:IsValid()) then
								client.carryWeapons[v.weaponCategory] = weapon

								if (ammo) then
									weapon:SetClip1(ammo)
								end
							end
						end
					end
				end
			end
		end
	end)
end)