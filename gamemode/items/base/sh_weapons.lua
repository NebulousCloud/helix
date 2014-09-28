ITEM.name = "Weapon"
ITEM.desc = "A Weapon."
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.class = "weapon_pistol"
ITEM.width = 2
ITEM.height = 2
ITEM.isWeapon = true
ITEM.weaponCategory = "sidearm"

// Inventory drawing
if (CLIENT) then
	function ITEM:paintOver(item, w, h)
		if (item:getData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

// On item is dropped, Remove a weapon from the player and keep the ammo in the item.
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

// On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
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

// On player eqipped the item, Gives a weapon to player and load the ammo data from the item.
ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/world.png",
	onRun = function(item)
		local inv = item.player:getChar():getInv()
		local ammo = item:getData("ammo")
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
			item.player.carryWeapons[item.weaponCategory] = weapon
			item.player:SetActiveWeapon(weapon)
			item.player:EmitSound("items/ammo_pickup.wav", 80)
			item:setData("equip", true)

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

// When player dead, remove all ammo in the gun items and clear out player weapon carrying table.
hook.Add("PlayerDeath", "weapon.reset", function(client)
	client.carryWeapons = {}

	timer.Simple(0, function()
		local inv = client:getChar():getInv():getItems()

		for k, v in pairs(inv) do
			if (v.isWeapon) then
				if (v:getData("equip")) then
					v:setData("ammo", 0)
				end
			end
		end
	end)
end)

// When player spawned, Give all equipped weapon items and load ammo from the item data.
hook.Add("PlayerSpawn", "weapon.reset", function(client)
	timer.Simple(0, function()
		if (client and client:getChar()) then
			local inv = client:getChar():getInv():getItems()

			if (inv) then
				for k, v in pairs(inv) do
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