--[[
	Purpose: A library for the framework's item system. This includes the registration,
	loading, and player's inventory functions and handles item interaction.
--]]

if (!netstream) then
	include("sh_netstream.lua")
end

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
		if (itemTable.base) then
			local baseTable = nut.item.bases[itemTable.base]

			if (baseTable) then
				itemTable = table.Inherit(itemTable, baseTable)
			else
				error("Attempt to derive item '"..itemTable.uniqueID.."' from unknown base! ("..itemTable.base..")")
			end
		end

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
					if (itemTable.CanTransfer and itemTable:CanTransfer(client, data) == false) then
						return false
					end

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

				if (self.classes) then
					if (!client:CharClass()) then
						return false
					end

					if (!table.HasValue(self.classes, client:CharClass())) then
						return false
					end
				end

				if (self.flag) then
					if (!client:HasFlag(self.flag)) then
						return false
					end
				end

				return true
			end
		end

		if (!itemTable.GetDesc) then
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
	Purpose: Similar to nut.item.Get, but instead of searching through
	the item buffer, it searches through registered base items.
--]]
function nut.item.GetBase(uniqueID)
	return nut.item.bases[uniqueID]
end

--[[
	Purpose: Retrieves all valid item bases that were registered.
--]]
function nut.item.GetBases()
	return nut.item.bases
end

--[[
	Purpose: Loads all of the bases within the items/base folder relative to the
	specified directory. For each base, it will look for items within items/<base name>
	for items that derive from the base item and register them. Finally, regular items
	that are just in the items folder will be registered.
--]]
function nut.item.Load(directory)
	for k, v in pairs(file.Find(directory.."/items/base/*.lua", "LUA")) do
		BASE = {folderName = string.sub(v, 4, -5)}
			BASE.uniqueID = BASE.folderName

			function BASE:Hook(uniqueID, callback)
				self.hooks = self.hooks or {}
				self.hooks[uniqueID] = self.hooks[uniqueID] or {}

				table.insert(self.hooks[uniqueID], callback)
			end

			nut.util.Include(directory.."/items/base/"..v)
			nut.item.Register(BASE, true)
		BASE = nil
	end

	for k, v in pairs(nut.item.GetBases()) do
		local parent = v.folderName

		if (parent) then
			local files = file.Find(directory.."/items/"..parent.."/*.lua", "LUA")

			for k2, v2 in pairs(files) do
				ITEM = table.Inherit({}, v)
					ITEM.uniqueID = string.sub(v2, 4, -5)

					function ITEM:Hook(uniqueID, callback)
						self.hooks = self.hooks or {}
						self.hooks[uniqueID] = self.hooks[uniqueID] or {}

						table.insert(self.hooks[uniqueID], callback)
					end

					nut.util.Include(directory.."/items/"..parent.."/"..v2)

					nut.item.Register(ITEM)
				ITEM = nil
			end
		else
			error("Item base '"..v.uniqueID.."' does not have a folder!")
		end
	end

	for k, v in pairs(file.Find(directory.."/items/*.lua", "LUA")) do
		ITEM =  {}
			ITEM.uniqueID = string.sub(v, 4, -5)
			
			function ITEM:Hook(uniqueID, callback)
				self.hooks = self.hooks or {}
				self.hooks[uniqueID] = self.hooks[uniqueID] or {}

				table.insert(self.hooks[uniqueID], callback)
			end

			nut.util.Include(directory.."/items/"..v)

			nut.item.Register(ITEM)
		ITEM = nil
	end
end

-- By default, we include all items in the core folder within the framework.
nut.item.Load(nut.FolderName.."/gamemode")

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
		function playerMeta:UpdateInv(class, quantity, data, noSave, noSend, forced)
			if (!self.character) then
				return false
			end

			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				ErrorNoHalt("Attempt to give invalid item '"..class.."'\n")

				return false
			end

			quantity = quantity or 1

			local weight, maxWeight = self:GetInvWeight()

			-- Cannot add more items.
			if (!forced and (quantity > 0 and weight + itemTable.weight > maxWeight)) then
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
			entity:SetModel(itemTable.GetDropModel and itemTable:GetDropModel() or itemTable.model)
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
		local amt = 0
		for k, v in pairs( self:GetItemsByClass(class) ) do
			amt = amt + v.quantity
		end
		return amt >= (quantity or 1)
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
		netstream.Hook("nut_ItemAction", function(client, data)
			local class = data[1]
			
			if (!client:HasItem(class)) then
				return
			end

			local index = data[2]
			local action = data[3]
			local itemTable = nut.item.Get(class)
			local item = client:GetItem(class, index)
			local itemFunction = itemTable.functions[action]

			if (item and itemFunction) then
				local result = true

				if (itemFunction.run) then
					result = itemFunction.run(itemTable, client, item.data or {}, NULL, index)

					local result2

					if (itemTable.hooks and itemTable.hooks[action]) then
						for k, v in pairs(itemTable.hooks[action]) do
							result2 = v(itemTable, client, item.data or {}, NULL, index)
						end
					end

					if (result2 != nil) then
						result = result2
					end
				end

				if (result != false) then
					client:UpdateInv(class, -1, item.data)
				end
			end
		end)

		netstream.Hook("nut_EntityAction", function(client, data)
			local entity = data[1]

			if (!IsValid(entity) or entity:GetPos():Distance(client:GetPos()) > 64) then
				return
			end

			entity.client = nil

			local action = data[2]
			local itemTable = entity:GetItemTable()
			local data = entity:GetData()
			local itemFunction = itemTable.functions[action]

			if (itemFunction) then
				local result = true

				if (itemFunction.run) then
					result = itemFunction.run(itemTable, client, data or {}, entity)
				end

				local result2

				if (itemTable.hooks and itemTable.hooks[action]) then
					for k, v in pairs(itemTable.hooks[action]) do
						result2 = v(itemTable, client, item.data or {}, entity)
					end
				end

				if (result2 != nil) then
					result = result2
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
					if (v.shouldDisplay and v.shouldDisplay(itemTable, item.data) == false) then
						continue
					end

					if (!v.entityOnly) then
						local material = v.icon or "icon16/plugin_go.png"

						local option = menu:AddOption(v.text or k, function()
							netstream.Start("nut_ItemAction", {itemTable.uniqueID, index, k})

							if (v.run) then
								if (itemTable.hooks and itemTable.hooks[k]) then
									for k2, v2 in pairs(itemTable.hooks[k]) do
										v2(itemTable, LocalPlayer(), item.data or {}, entity)
									end
								end

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
					if (v.shouldDisplay and v.shouldDisplay(itemTable, entity:GetData(), entity) == false) then
						continue
					end

					if (!v.menuOnly) then
						local material = v.icon or "icon16/plugin_go.png"

						local option = menu:AddOption(v.text or k, function()
							netstream.Start("nut_EntityAction", {entity, k})

							if (v.run) then
								if (itemTable.hooks and itemTable.hooks[k]) then
									for k2, v2 in pairs(itemTable.hooks[k]) do
										v2(itemTable, LocalPlayer(), entity:GetData() or {}, entity)
									end
								end

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

		netstream.Hook("nut_ShowItemMenu", function(entity)
			nut.item.OpenEntityMenu(entity)
		end)
	end
end

-- Tie in the business stuff with the items.
do
	if (SERVER) then
		netstream.Hook("nut_BuyItem", function(client, class)
			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				return
			end

			local price = itemTable.price

			if (client:CanAfford(price)) then
				client:UpdateInv(class)
				client:TakeMoney(price)

				nut.util.Notify(nut.lang.Get("purchased", itemTable.name), client)
			else
				nut.util.Notify(nut.lang.Get("no_afford"), client)
			end
		end)
	end
end
