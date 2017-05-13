ITEM.name = "PAC Outfit"
ITEM.desc = "A PAC Outfit Base."
ITEM.category = "Outfit"
ITEM.model = "models/Gibs/HGIBS.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "hat"
ITEM.pacData = {}

--[[
ITEM.pacData = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Angles"] = Angle(12.919322967529, 6.5696062847564e-006, -1.0949343050015e-005),
					["Position"] = Vector(-2.099609375, 0.019973754882813, 1.0180969238281),
					["UniqueID"] = "4249811628",
					["Size"] = 1.25,
					["Bone"] = "eyes",
					["Model"] = "models/Gibs/HGIBS.mdl",
					["ClassName"] = "model",
				},
			},
		},
		["self"] = {
			["ClassName"] = "group",
			["UniqueID"] = "907159817",
			["EditorExpand"] = true,
		},
	},
}

-- This will change a player's skin after changing the model. Keep in mind it starts at 0.
ITEM.newSkin = 1
-- This will change a certain part of the model.
ITEM.replacements = {"group01", "group02"}
-- This will change the player's model completely.
ITEM.replacements = "models/manhack.mdl"
-- This will have multiple replacements.
ITEM.replacements = {
	{"male", "female"},
	{"group01", "group02"}
}

-- This will apply body groups.
ITEM.bodyGroups = {
	["blade"] = 1,
	["bladeblur"] = 1
}

--]]

-- Inventory drawing
if (CLIENT) then
	-- Draw camo if it is available.
	function ITEM:paintOver(item, w, h)
		if (item:getData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:removePart(client)
	local char = client:getChar()
	
	self:setData("equip", false)
	client:removePart(self.uniqueID)

	if (self.attribBoosts) then
		for k, _ in pairs(self.attribBoosts) do
			char:removeBoost(self.uniqueID, k)
		end
	end
end

-- On item is dropped, Remove a weapon from the player and keep the ammo in the item.
ITEM:hook("drop", function(item)
	if (item:getData("equip")) then
		item:removePart(item.player)
	end
end)

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.EquipUn = { -- sorry, for name order.
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	onRun = function(item)
		item:removePart(item.player)
		
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
	icon = "icon16/tick.png",
	onRun = function(item)
		local char = item.player:getChar()
		local items = char:getInv():getItems()

		for k, v in pairs(items) do
			if (v.id != item.id) then
				local itemTable = nut.item.instances[v.id]

				if (itemTable.pacData and v.outfitCategory == item.outfitCategory and itemTable:getData("equip")) then
					item.player:notify("You're already equipping this kind of outfit")

					return false
				end
			end
		end

		item:setData("equip", true)
		item.player:addPart(item.uniqueID, item)

		if (item.attribBoosts) then
			for k, v in pairs(item.attribBoosts) do
				char:addBoost(item.uniqueID, k, v)
			end
		end
		
		return false
	end,
	onCanRun = function(item)
		return (!IsValid(item.entity) and item:getData("equip") != true)
	end
}

function ITEM:onCanBeTransfered(oldInventory, newInventory)
	if (newInventory and self:getData("equip")) then
		return false
	end

	return true
end
