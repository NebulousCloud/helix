local entityMeta = FindMetaTable("Entity")

if (SERVER) then
	util.AddNetworkString("nut_InvUpdate")

	function entityMeta:SyncVars(client, noDelta)
		if (self.nut_NetVars) then
			for k, v in pairs(self.nut_NetVars) do
				if (self.nut_NetReceiver and self.nut_NetReceiver[k]) then
					continue
				end

				self:SendVar(k, client, nil, noDelta)
			end
		end
	end

	hook.Add("PlayerInitialSpawn", "nut_SyncVars", function(client)
		timer.Simple(5, function()
			for k, v in pairs(ents.GetAll()) do
				if (IsValid(v)) then
					v:SyncVars(client, true)
				end
			end
		end)
	end)

	local function initiateHandShake(client, entity, key)
		if (!IsValid(client) or !key or !IsValid(entity)) then
			return
		end

		local uniqueID = "nut_Net"..client:UniqueID()..entity:EntIndex()..key
		
		timer.Create(uniqueID, math.max(client:Ping() / 75, 0.75), 25, function()
			if (!IsValid(client) or !IsValid(entity)) then
				timer.Remove(uniqueID)

				return
			end

			entity:SendVar(key, client, true)
		end)
	end

	function entityMeta:SendVar(key, receiver, noHandShake, noDelta)
		if (self.nut_NetVars and self.nut_NetVars[key] != nil) then
			self.nut_NetDeltas = self.nut_NetDeltas or {}

			local value = self.nut_NetVars[key]

			if (!noDelta and type(value) == "table") then
				local oldValue = value
				value = nut.util.GetTableDelta(value, self.nut_NetDeltas[key] or {})

				self.nut_NetDeltas[key] = table.Copy(oldValue)
			end

			if (receiver) then
				netstream.Start(receiver, "nut_EntityVar", {self:EntIndex(), key, value, noDelta}) -- nodelta == override. Description in nut_EntityVar netstream.

				if (!noHandShake) then
					if (type(receiver) == "Player") then
						initiateHandShake(receiver, self, key)
					elseif (type(receiver) == "table") then
						for k, v in pairs(receiver) do
							initiateHandShake(v, self, key)
						end
					end
				end
			else
				netstream.Start(nil, "nut_EntityVar", {self:EntIndex(), key, value})

				if (!noHandShake) then
					for k, v in pairs(player.GetAll()) do
						initiateHandShake(v, self, key)
					end
				end
			end
		elseif (self.nut_NetVars) then
			netstream.Start(receiver, "nut_EntityNilVar", {self:EntIndex(), key})
		end
	end

	function entityMeta:SetNetVar(key, value, receiver)
		self.nut_NetVars = self.nut_NetVars or {}
		self.nut_NetVars[key] = value
		self.nut_NetReceiver = self.nut_NetReceiver or {}
		self.nut_NetReceiver[key] = receiver

		self:CallOnRemove("CleanNetVar", function()
			netstream.Start(nil, "nut_EntityVarClean", self:EntIndex())
		end)

		if (self.nut_NetHooks and self.nut_NetHooks[key]) then
			for k, v in pairs(self.nut_NetHooks[key]) do
				v()
			end
		end

		self:SendVar(key, receiver)
	end

	netstream.Hook("nut_NetHandshake", function(client, data)
		timer.Remove("nut_Net"..client:UniqueID()..data)
	end)
	
	-- Clean up player vars.
	hook.Add("PlayerDisconnected", "cn_PlayerVarClean", function(client)
		netstream.Start(nil, "nut_EntityVarClean", client:EntIndex())
	end)
else
	local function replacePlaceHolders(value)
		for k, v in pairs(value) do
			if (type(v) == "table") then
				v = replacePlaceHolders(v)
			elseif (type(v) == "string" and v == "__nil") then
				value[k] = nil
			end
		end

		return value
	end

	NUT_ENT_REGISTRY = NUT_ENT_REGISTRY or {}

	netstream.Hook("nut_EntityVarClean", function(data)
		NUT_ENT_REGISTRY[data] = nil
	end)

	netstream.Hook("nut_EntityNilVar", function(data)
		if (NUT_ENT_REGISTRY[data[1]]) then
			NUT_ENT_REGISTRY[data[1]][data[2]] = nil
		end
	end)

	netstream.Hook("nut_EntityVar", function(data)
		local entIndex = data[1]
		local key = data[2]
		local value = data[3]
		local override = data[4] -- table override

		NUT_ENT_REGISTRY[entIndex] = NUT_ENT_REGISTRY[entIndex] or {}

		local registry = NUT_ENT_REGISTRY[entIndex]
		if (type(value) == "table") then
			if (!override) then
				value = replacePlaceHolders(table.Merge(registry[key] or {}, value)) -- Temp fix for Storage Left Over.
				-- To generate that bug follow this step
				-- 1. Enter NS Server with 2 player and 1 storage and at least 1 item.
				-- 2. Make one player get items into the storage.
				-- 3. Make another player look into the storage and get out.
				-- 4. One player takes any item in the storage.
				-- 5. When another player look into the storage, It seems normal but you can't get items that one player took out.
				-- 6. Server says It's gone but client sees it's still there.
			end
		end

		registry[key] = value

		local entity = Entity(entIndex)

		if (IsValid(entity) and entity.nut_NetHooks and entity.nut_NetHooks[key]) then
			for k, v in pairs(entity.nut_NetHooks[key]) do
				v()
			end
		end

		netstream.Start("nut_NetHandshake", entIndex..key)
	end)
end

function entityMeta:HookNetVar(key, callback)
	self.nut_NetHooks = self.nut_NetHooks or {}
	self.nut_NetHooks[key] = self.nut_NetHooks[key] or {}

	table.insert(self.nut_NetHooks[key], callback)
end

function entityMeta:GetNetVar(key, default)
	if (SERVER and self.nut_NetVars) then
		local value = self.nut_NetVars[key]

		if (value == nil) then
			return default
		end

		return value
	elseif (CLIENT and NUT_ENT_REGISTRY[self:EntIndex()]) then
		local value = NUT_ENT_REGISTRY[self:EntIndex()][key] 

		if (value == nil) then
			return default
		end
		
		return value
	end

	return default
end
