--[[
	Purpose: A library for the framework's item system. This includes the registration,
	loading, and player's inventory functions and handles item interaction.
--]]

nut.item = nut.item or {}
nut.item.buffer = {}
nut.item.list = {}
nut.item.bases = {}
nut.item.queries = {}

function nut.item.RegisterQuery(query, callback, ignoreAction)
	local arguments = {}

	for k, v in ipairs(string.Explode("%s+", query, true)) do
		if (string.match(v, "%b{}")) then
			arguments[k] = true
		end
	end

	nut.item.queries[query] = {
		callback = callback,
		arguments = arguments,
		match = string.gsub(query, "%b{}", "(%%w+)"),
		ignoreAction = ignoreAction
	}
end

nut.item.RegisterQuery("{1} {2} health", function(itemTable, arguments)
	local client = itemTable.player

	if (!IsValid(client)) then
		return
	end

	local action = arguments[1]
	local amount = tonumber(arguments[2]) or 100

	if (action == "give" or action == "add") then
		amount = client:Health() + amount
	elseif (action == "take" or action == "sub") then
		amount = client:Health() - amount
	end

	client:SetHealth(math.max(amount, 1))
end)

nut.item.RegisterQuery("{1} {2} armor", function(itemTable, arguments)
	local client = itemTable.player

	if (!IsValid(client)) then
		return
	end

	local action = arguments[1]
	local amount = tonumber(arguments[2]) or 100

	if (action == "give" or action == "add") then
		amount = client:Armor() + amount
	elseif (action == "take" or action == "sub") then
		amount = client:Armor() - amount
	end

	client:SetArmor(math.max(amount, 0))
end)

nut.item.RegisterQuery("{1} {2} stamina", function(itemTable, arguments)
	local client = itemTable.player

	if (!IsValid(client)) then
		return
	end

	local action = arguments[1]
	local amount = tonumber(arguments[2]) or 100
	local stamina = client.character:GetVar("stamina", 100)

	if (action == "give" or action == "add") then
		amount = stamina + amount
	elseif (action == "take" or action == "sub") then
		amount = stamina - amount
	end

	client.character:SetVar("stamina", math.max(amount, 0))
end)

nut.item.RegisterQuery("{1} {2} money", function(itemTable, arguments)
	local client = itemTable.player

	if (!IsValid(client)) then
		return
	end

	local action = arguments[1]
	local amount = tonumber(arguments[2]) or 100
	local money = client:GetMoney()

	if (action == "give" or action == "add") then
		amount = money + amount
	elseif (action == "take" or action == "sub") then
		amount = money - amount
	end

	client:SetMoney(math.max(math.floor(amount), 0))
end)

nut.item.RegisterQuery("set sound to {1}", function(itemTable, arguments)
	itemTable.useSound = arguments[1]
end)

function nut.item.ProcessQuery(itemTable, action, client, data, entity, index)
	if (!itemTable.queries) then
		return
	end

	action = string.lower(action)

	for k, v in pairs(itemTable.queries) do
		for k2, query in pairs(nut.item.queries) do
			local actionMatch = "on "..action
			local matchLength = #actionMatch

			if (query.ignoreAction or string.Left(v, matchLength + 1) == (actionMatch..":") or string.Right(v, matchLength) == actionMatch) then
				if (string.match(v, query.match)) then
					if (string.Left(v, matchLength + 1) == (actionMatch..":")) then
						v = string.sub(v, matchLength + 1)
					end

					local exploded = string.Explode("%s+", v, true)
					local queryArgs = query.arguments
					local arguments = {}

					for i = 1, #exploded do
						if (queryArgs[i]) then
							arguments[#arguments + 1] = exploded[i]
						end
					end

					itemTable.player = client
					itemTable.itemData = data
					itemTable.entity = entity
					itemTable.index = index

					local result = query.callback(itemTable, arguments)

					itemTable.player = nil
					itemTable.itemData = nil
					itemTable.entity = nil
					itemTable.index = nil

					if (result != nil) then
						return result
					end
				end
			end
		end
	end
end

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

		if (nut.item.buffer[itemTable.uniqueID]) then
			if (nut.item.buffer[itemTable.uniqueID].override) then 
				return
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
					
					client:EmitSound("physics/body/body_medium_impact_soft"..math.random(1, 3)..".wav")

					local entity = nut.item.Spawn(position, client:EyeAngles(), itemTable, data, client)
					hook.Run("OnItemDropped", client, itemTable, entity)
				end
			end,
			shouldDisplay = function(itemTable, data, entity)
				return !itemTable.cantdrop
			end
		}
		itemTable.functions.Take = {
			entityOnly = true,
			tip = "Put the item in your inventory.",
			icon = "icon16/box.png",
			run = function(item)
				if (SERVER) then
					item.player:EmitSound("physics/body/body_medium_impact_soft"..math.random(5, 7)..".wav")

					local result = hook.Run("OnItemTaken", table.Copy(item))
						if (result == nil) then
							if (item.entity.owner == item.player and item.entity.charindex != item.player.character.index) then
								nut.util.Notify(nut.lang.Get("item_pickup_samechar"), activator)

								return false
							end

							result = item.player:UpdateInv(item.uniqueID, 1, item.itemData)
						end
					return result
				end
			end,
			shouldDisplay = function(itemTable, data, entity)
				return !itemTable.canttake
			end
		}

		function itemTable:Call(action, client, data, entity, index)
			data = data or {}

			local itemFunction = self.functions[action]

			if (itemFunction and itemFunction.run) then
				self.player = client
				self.itemData = data
				self.entity = entity
				self.index = index

				if (hook.Run("PlayerCanUseItem", client, self) == false) then
					self.player = nil
					self.itemData = nil
					self.entity = nil
					self.index = nil

					if (SERVER and client:GetNetVar("tied")) then
						nut.util.Notify(nut.lang.Get("no_perm_tied"), client)
					end
					
					return false, false
				end

				local result, result2 = itemFunction.run(self, client, data, entity or NULL, index)

				self.player = nil
				self.itemData = nil
				self.entity = nil
				self.index = nil

				if (result != nil) then
					return result, result2
				end
			end

			nut.item.ProcessQuery(itemTable, action, client, data, entity, index)

			if (self.hooks and self.hooks[action]) then
				for k, v in pairs(self.hooks[action]) do
					local result, result2 = v(self, client, data or {}, entity or NULL, index)

					if (result != nil) then
						return result, result2
					end
				end
			end
		end

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

					return self.data and self.data[key] or exploded[2]
				end)

				return description
			end
		end

		if (itemTable.queries) then
			for k, query in pairs(itemTable.queries) do
				local action = string.match(query, "on (%w+)")
				local actionID = string.upper(string.sub(action, 1, 1))..string.sub(action, 2)

				if (action and !itemTable.functions[actionID]) then
					itemTable.functions[actionID] = {
						icon = "icon16/world.png",
						run = function(itemTable, client, data)
							if (SERVER) then
								client:EmitSound(itemTable.useSound or "items/battery_pickup.wav")
							end
						end
					}
				end
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

function nut.item.PrepareItemTable(itemTable)
	function itemTable:Hook(uniqueID, callback)
		self.hooks = self.hooks or {}
		self.hooks[uniqueID] = self.hooks[uniqueID] or {}

		table.insert(self.hooks[uniqueID], callback)
	end

	function itemTable:AddQuery(query)
		if (!query) then
			error("No query provided! ("..(itemTable.uniqueID or "null")..")")
		end

		query = string.lower(query)

		self.queries = self.queries or {}
		self.queries[#self.queries + 1] = string.lower(query)
	end
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

			nut.item.PrepareItemTable(BASE)
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
					ITEM.uniqueID = parent.."_"..string.sub(v2, 4, -5)

					nut.item.PrepareItemTable(ITEM)
					nut.util.Include(directory.."/items/"..parent.."/"..v2)

					if (v.OnRegister) then
						v:OnRegister(ITEM)
					end

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
			
			nut.item.PrepareItemTable(ITEM)
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

	function playerMeta:HasInvSpace(itemTable, quantity, forced, noMessage)
		local weight, maxWeight = self:GetInvWeight()
		quantity = quantity or 1

		-- Cannot add more items.
		if (!forced and quantity > 0 and weight + itemTable.weight > maxWeight) then
			if (!noMessage) then
				nut.util.Notify(nut.lang.Get("no_invspace"), self)
			end

			return false
		end

		return true
	end

	if (SERVER) then
		--[[
			Purpose: Very important inventory function as this handles the way items
			are given/taken for a player. The class is an item's uniqueID while quantity
			is how many to give (or take if it is negative). Data is a table that is for
			persistent item data. noSave and noSend are self-explanatory.
		--]]
		function playerMeta:UpdateInv(class, quantity, data, forced, noSave, noSend)
			if (!self.character) then
				return false
			end

			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				ErrorNoHalt("Attempt to give invalid item '"..class.."'\n")

				if (IsValid(self)) then
					nut.util.Notify("Attempt to give invalid item '"..class.."'!", self)
				end

				return false
			end

			quantity = quantity or 1

			if (!self:HasInvSpace(itemTable, quantity, forced)) then
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
					self:SetNutVar("nextItemSave", CurTime() + 120)
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
		function nut.item.Spawn(position, angles, itemTable, data, client)
			if (type(itemTable) == "string") then
				itemTable = nut.item.Get(itemTable)
			end

			if (!itemTable) then
				error("Attempt to spawn item without itemtable!")
			end
			
			local entity = ents.Create("nut_item")
			entity:SetPos(position)
			entity:SetAngles(angles or Angle())
			entity:SetSkin(itemTable.skin or 0)
			entity:Spawn()
			entity:SetModel(itemTable.GetDropModel and itemTable:GetDropModel() or itemTable.model)
			entity:PhysicsInit(SOLID_VPHYSICS)
			entity.itemTable = itemTable
			entity:SetItemID(itemTable.uniqueID)

			if (IsValid(client)) then
				entity:SetCreator(client)
			end

			if (data) then
				entity:SetInternalData(von.serialize(data))
				entity.realData = data
			end

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:EnableMotion(true)
				physicsObject:Wake()
			end

			if (itemTable.OnEntityCreated) then
				itemTable:OnEntityCreated(entity)
			end

			if (client and client:IsValid()) then
				entity.owner = client
				
				if client.character then
					entity.charindex = client.character.index

					if nut.config.itemTime and nut.config.itemTime > 0 then 
						timer.Simple(nut.config.itemTime, function()
							if entity:IsValid() then
								entity:Remove()
							end
						end)
					end
				end
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
	function playerMeta:GetInvWeight(inventory)
		local weight, maxWeight = 0, nut.config.defaultInvWeight

		for uniqueID, items in pairs(inventory or self:GetInventory()) do
			local itemTable = nut.item.Get(uniqueID)

			if (itemTable) then
				local quantity = 0

				for k, v in pairs(items) do
					quantity = quantity + (v.quantity or 0)
				end

				local addition = math.abs(itemTable.weight) * quantity

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
	function playerMeta:GetItem(class, index, data)
		if (!self:HasItem(class)) then
			return false
		end

		index = index or 1

		local entries = self:GetInventory()[class]

		if (data) then
			local oldEntries = entries
			entries = {}

			for k, v in pairs(oldEntries) do
				if (v.data and nut.util.IsSimilarTable(data, v.data)) then
					entries[k] = v
				end
			end
		end

		if (index == 1) then
			return table.GetFirstValue(entries)
		else
			return entries[index]
		end
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

			if (item) then
				local result = itemTable:Call(action, client, item.data, NULL, index)

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
				local result = itemTable:Call(action, client, data, entity)

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

						local option = menu:AddOption(v.alias or v.text or k, function()
							netstream.Start("nut_ItemAction", {itemTable.uniqueID, index, k})

							itemTable:Call(k, LocalPlayer(), item.data, NULL, index)
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

						local option = menu:AddOption(v.alias or v.text or k, function()
							netstream.Start("nut_EntityAction", {entity, k})

							if (v.run) then
								if (entity:IsValid()) then
									itemTable:Call(k, LocalPlayer(), entity:GetData(), entity)
								end
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
	end
end

-- Tie in the business stuff with the items.
do
	if (SERVER) then
		netstream.Hook("nut_BuyItem", function(client, class)
			if (!nut.config.businessEnabled) then
				return
			end
			
			local itemTable = nut.item.Get(class)

			if (!itemTable) then
				return nut.util.Notify("This item is not valid!", client)
			end

			if (itemTable:ShouldShowOnBusiness(client) == false) then
				return nut.util.Notify("You are not allowed to buy this item.", client)
			end

			local price = itemTable.price

			if (!client:HasInvSpace(itemTable)) then
				return nut.util.Notify(nut.lang.Get("no_invspace"), client)
			end

			if (itemTable.faction) then
				if (type(itemTable.faction) == "number" and itemTable.faction != client:Team()) then
					return
				elseif (type(itemTable.faction) == "table" and !table.HasValue(itemTable.faction, client:Team())) then
					return
				end
			end

			local data

			data = hook.Run("GetBusinessItemData", client, itemTable, data)

			if (itemTable.GetBusinessData) then
				data = itemTable:GetBusinessData(client, data)
			end
			
			if (client:CanAfford(price)) then
				client:UpdateInv(class, nil, data)
				client:TakeMoney(price)

				nut.util.Notify(nut.lang.Get("purchased_for", itemTable.name, nut.currency.GetName(price)), client)
			else
				nut.util.Notify(nut.lang.Get("no_afford"), client)
			end

			hook.Run("PlayerBoughtItem", client, itemTable)

			if (itemTable.OnBought) then
				itemTable:OnBought(client)
			end
		end)
	end
end
