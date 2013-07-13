--[[
	Purpose: A library for the framework's item system. This includes the registration,
	loading, and player's inventory functions and handles item interaction.
--]]

nut.item = nut.item or {}
nut.item.buffer = nut.item.buffer or {}
nut.item.list = nut.item.list or {}
nut.item.bases = nut.item.bases or {}

--[[
	Purpose: If isBase is true, the item will be inserted into the table of available bases
	for other items to derive from. Otherwise, default variables will be applied to the item
	table if they do not exist, and will be inserted to the list of regular items.
--]]
function nut.item.Register(itemTable, isBase)
	if (isBase) then
		nut.item.bases[itemTable.uniqueID] = itemTable
	else
		itemTable.category = itemTable.category or nut.lang.Get("misc")
		itemTable.price = itemTable.price or 0
		itemTable.weight = itemTable.weight or 1
		itemTable.desc = itemTable.desc or nut.lang.Get("no_desc")
		itemTable.functions = itemTable.functions or {}
		itemTable.data = itemTable.data or {}
		itemTable.functions.Drop = {
			menuOnly = true,
			tip = "Drops the item from your inventory.",
			icon = "icon16/world.png",
			run = function(itemTable, client, data)
				if (SERVER) then
					local data2 = {
						start = client:GetShootPos(),
						endpos = client:GetShootPos() + client:GetAimVector() * 72,
						filter = client
					}
					local trace = util.TraceLine(data2)
					local position = trace.HitPos + Vector(0, 0, 16)

					nut.item.Spawn(position, client:EyeAngles(), itemTable, data)
				end
			end
		}
		itemTable.functions.Take = {
			entityOnly = true,
			tip = "Put the item in your inventory.",
			icon = "icon16/box.png",
			run = function(itemTable, client, data, entity)
				if (SERVER) then
					local itemTable = entity:GetItemTable()
					local data = entity:GetData()

					return client:UpdateInv(itemTable.uniqueID, 1, data)
				end
			end
		}

		if (!itemTable.ShouldShowOnBusiness) then
			function itemTable:ShouldShowOnBusiness(client)
				if (self.faction) then
					if (type(self.faction) == "table") then
						if (!table.HasValue(self.faction, client:Team())) then
							return false
						end
					elseif (self.faction != client:Team()) then
						return false
					end
				end

				return true
			end
		end

		function itemTable:GetDesc(data)
			local description = string.gsub(self.desc, "%%.-%%", function(key)
				key = string.sub(key, 2, -2)

				local exploded = string.Explode("|", key)
				key = exploded[1]

				if (data and data[key]) then
					return data[key]
				end

				return self.data[key] or exploded[2]
			end)

			return description
		end

		nut.item.buffer[itemTable.uniqueID] = itemTable
	end
end

--[[
	Purpose: Returns an item table based off the uniqueID given.
--]]
function nut.item.Get(uniqueID)
	return nut.item.buffer[uniqueID]
end

--[[
	Purpose: Loads all of the bases within the items/base folder relative to the
	specified directory. For each base, it will look for items within items/<base name>
	for items that derive from the base item and register them. Finally, regular items
	that are just in the items folder will be registered.
--]]
function nut.item.Load(directory)
	for k, v in pairs(file.Find(directory.."/items/base/*.lua", "LUA")) do
		BASE = {}
			nut.util.Include(directory.."/items/base/"..v)
			nut.item.Register(BASE, true)

			local parent = string.sub(v, 4, -5)
			local files = file.Find(directory.."/items/"..parent.."/*.lua", "LUA")

			for k2, v2 in pairs(files) do
				ITEM = table.Inherit({}, BASE)
					nut.util.Include(directory.."/items/"..parent.."/"..v2)

					nut.item.Register(ITEM)
				ITEM = nil
			end
		BASE = nil
	end

	for k, v in pairs(file.Find(directory.."/items/*.lua", "LUA")) do
		ITEM =  {}
			nut.util.Include(directory.."/items/"..v)

			nut.item.Register(ITEM)
		ITEM = nil
	end
end

-- By default, we include all items in the core folder within the framework.
nut.item.Load(nut.FolderName.."/gamemode/core")

--[[
	Purpose: Returns all of the registered item tables.
--]]
function nut.item.GetAll()
	return nut.item.buffer
end

-- Player inventory handling.
do
	local playerMeta = FindMetaTable("Player")

	if (SERVER) then
		--[[
			Purpose: Very important inventory function as this handles the way items
			are given/taken for a player. The class is an item's uniqueID while quantity
			is how many to give (or take if it is negative). Data is a table that is for
			persistent item data. noSave and noSend are self-explanatory.
		--]]
		function playerMeta:UpdateInv(class, quantity, data, noSave, noSend)
			if (!self.character) then
				return false
			end

			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				ErrorNoHalt("Attempt to give invalid item '"..class.."'\n")

				return
			end

			quantity = quantity or 1

			local weight, maxWeight = self:GetInvWeight()

			-- Cannot add more items.
			if (quantity > 0 and weight + itemTable.weight > maxWeight) then
				nut.util.Notify(nut.lang.Get("no_invspace"), self)

				return false
			end

			if (itemTable.data) then
				local oldData = data or {}

				data = table.Copy(itemTable.data)
				data = table.Merge(data, oldData)
			end

			local inventory = self.character:GetVar("inv")
			inventory[class] = inventory[class] or {}
			inventory = nut.util.StackInv(inventory, class, quantity, data)

			if (!noSave) then
				-- Limit on how often items should save.
				local shouldSave = false

				if (self:GetNutVar("nextItemSave", 0) < CurTime()) then
					shouldSave = true
					self:SetNutVar("nextItemSave", CurTime() + 30)
				end

				if (shouldSave) then
					nut.char.Save(self)
				end
			end

			-- Stop the inventory from networking to the client.
			if (!noSend) then
				self.character:Send("inv", self)
			end

			return true
		end

		--[[
			Purpose: Physically spawns an item entity (nut_item) at the specified
			position and networks the itemtable and data. Note that this function
			doesn't actually remove the item from an inventory.
		--]]
		function nut.item.Spawn(position, angles, itemTable, data)
			local entity = ents.Create("nut_item")
			entity:SetPos(position)
			entity:SetAngles(angles or Angle())
			entity:Spawn()
			entity:SetModel(itemTable.model)
			entity:PhysicsInit(SOLID_VPHYSICS)
			entity.itemTable = itemTable
			entity:SetItemID(itemTable.uniqueID)

			if (data) then
				entity:SetInternalData(von.serialize(data))
				entity.realData = data
			end

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:EnableMotion(true)
				physicsObject:Wake()
			end

			return entity
		end
	end

	--[[
		Purpose: Returns the inventory character data, which is a table.
		This is just a helping function to reduce checking for the character
		and getting a variable from the character.
	--]]
	function playerMeta:GetInventory()
		if (self.character) then
			return self.character:GetVar("inv")
		end

		return {}
	end

	--[[
		Purpose: Calculate the weight of an inventory by adding up all the item weights.
		This function will also return the maximum weight as another return value by
		retrieving the config for default max weight and adding the absolute value
		of negative weight items.
	--]]
	function playerMeta:GetInvWeight()
		local weight, maxWeight = 0, nut.config.defaultInvWeight

		for uniqueID, items in pairs(self:GetInventory()) do
			local itemTable = nut.item.Get(uniqueID)

			if (itemTable) then
				local quantity = 0

				for k, v in pairs(items) do
					quantity = quantity + v.quantity
				end

				local addition = itemTable.weight * quantity

				if (itemTable.weight < 0) then
					maxWeight = maxWeight + addition
				else
					weight = weight + addition
				end
			end
		end

		return weight, maxWeight
	end

	--[[
		Purpose: Returns true if an item within the player's inventory has the
		same class as the one provided.
	--]]
	function playerMeta:HasItem(class, quantity)
		return table.Count(self:GetItemsByClass(class)) > (quantity or 0)
	end

	--[[
		Purpose: Returns a specific item within the player's inventory using
		the class and an index. If it an index isn't provided, it wil look
		up the first item with the same class in the player's inventory.
	--]]
	function playerMeta:GetItem(class, index)
		if (!self:HasItem(class)) then
			return false
		end

		index = index or 1

		return self:GetInventory()[class][index]
	end

	function playerMeta:GetItemsByClass(class)
		return self:GetInventory()[class] or {}
	end
end

-- Handle item interaction networking and menus.
do
	if (SERVER) then
		util.AddNetworkString("nut_ItemAction")
		util.AddNetworkString("nut_EntityAction")
		util.AddNetworkString("nut_ShowItemMenu")

		net.Receive("nut_ItemAction", function(length, client)
			local class = net.ReadString()
			
			if (!client:HasItem(class)) then
				return
			end

			local index = net.ReadUInt(16)
			local action = net.ReadString()
			local itemTable = nut.item.Get(class)
			local item = client:GetItem(class, index)
			local itemFunction = itemTable.functions[action]

			if (item and itemFunction) then
				local result = true

				if (itemFunction.run) then
					result = itemFunction.run(itemTable, client, item.data or {}, NULL, index)
				end

				if (result != false) then
					client:UpdateInv(class, -1, item.data)
				end
			end
		end)

		net.Receive("nut_EntityAction", function(length, client)
			local entity = net.ReadEntity()

			if (!IsValid(entity) or entity:GetPos():Distance(client:GetPos()) > 64) then
				return
			end

			entity.client = nil

			local action = net.ReadString()
			local itemTable = entity:GetItemTable()
			local data = entity:GetData()
			local itemFunction = itemTable.functions[action]

			if (itemFunction) then
				local result = true

				if (itemFunction.run) then
					result = itemFunction.run(itemTable, client, data or {}, entity)
				end

				if (result != false) then
					entity:Remove()
				end
			end
		end)
	else
		--[[
			Purpose: Opens the menu for an item within the inventory. This is similar
			to OpenEntityMenu, which can be found below.
		--]]
		function nut.item.OpenMenu(itemTable, item, index)
			if (!LocalPlayer():HasItem(itemTable.uniqueID)) then
				return
			end

			local menu = DermaMenu()
				for k, v in SortedPairs(itemTable.functions) do
					if (!v.entityOnly) then
						local material = v.icon or "icon16/plugin_go.png"

						local option = menu:AddOption(v.text or k, function()
							net.Start("nut_ItemAction")
								net.WriteString(itemTable.uniqueID)
								net.WriteUInt(index, 16)
								net.WriteString(k)
							net.SendToServer()

							if (v.run) then
								v.run(itemTable, LocalPlayer(), item.data or {}, NULL, index)
							end
						end)
						option:SetImage(material)

						if (v.tip) then
							option:SetToolTip(v.tip)
						end
					end
				end
			menu:Open()
		end

		--[[
			Purpose: Opens a DermaMenu with a nut_item entity provided. It will loop through
			the entity's itemtable to find functions that should show up in the menu, and
			insert them into the DermaMenu and specifies what happens when each is clicked.
		--]]
		function nut.item.OpenEntityMenu(entity)
			if (!IsValid(entity) or !IsValid(LocalPlayer():GetEyeTrace().Entity) or LocalPlayer():GetEyeTrace().Entity != entity) then
				return
			end

			local itemTable = entity:GetItemTable()

			if (!itemTable) then
				return
			end

			local menu = DermaMenu()
				for k, v in SortedPairs(itemTable.functions) do
					if (!v.menuOnly) then
						local material = v.icon or "icon16/plugin_go.png"

						local option = menu:AddOption(v.text or k, function()
							net.Start("nut_EntityAction")
								net.WriteEntity(entity)
								net.WriteString(k)
							net.SendToServer()

							if (v.run) then
								v.run(itemTable, LocalPlayer(), entity:GetData() or {}, entity)
							end
						end)
						option:SetImage(material)

						if (v.tip) then
							option:SetToolTip(v.tip)
						end
					end
				end
			menu:Open()
			menu:Center()
		end

		net.Receive("nut_ShowItemMenu", function(length)
			nut.item.OpenEntityMenu(net.ReadEntity())
		end)
	end
end

-- Tie in the business stuff with the items.
do
	if (SERVER) then
		util.AddNetworkString("nut_BuyItem")

		net.Receive("nut_BuyItem", function(length, client)
			local class = net.ReadString()
			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				return
			end

			local price = itemTable.price

			if (client:CanAfford(price)) then
				client:UpdateInv(class)
				client:TakeMoney(price)
			else
				nut.util.Notify(nut.lang.Get("no_afford"), client)
			end
		end)
	end
end