local entityMeta = FindMetaTable("Entity")

if (SERVER) then
	util.AddNetworkString("nut_EntityVar")
	util.AddNetworkString("nut_NetHandshake")
	util.AddNetworkString("nut_EntityVarClean")

	function entityMeta:SyncVars(client, noDelta)
		if (self.nut_NetVars) then
			for k, v in pairs(self.nut_NetVars) do
				self:SendVar(k, client, nil, noDelta)
			end
		end
	end

	hook.Add("PlayerInitialSpawn", "nut_SyncVars", function(client)
		timer.Simple(5, function()
			for k, v in pairs(ents.GetAll()) do
				v:SyncVars(client, true)
			end
		end)
	end)

	local function initiateHandShake(client, entity, key)
		if (!key or !IsValid(entity)) then
			return
		end

		local uniqueID = "nut_Net"..client:UniqueID()..entity:EntIndex()..key
		
		timer.Create(uniqueID, client:Ping() / 75, 25, function()
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

			net.Start("nut_EntityVar")
				net.WriteUInt(self:EntIndex(), 16)
				net.WriteString(key)
				net.WriteType(value)
			if (receiver) then
				net.Send(receiver)

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
				net.Broadcast()

				if (!noHandShake) then
					for k, v in pairs(player.GetAll()) do
						initiateHandShake(v, self, key)
					end
				end
			end
		end
	end

	function entityMeta:SetNetVar(key, value)
		self.nut_NetVars = self.nut_NetVars or {}
		self.nut_NetVars[key] = value

		self:CallOnRemove("CleanNetVar", function()
			net.Start("nut_EntityVarClean")
				net.WriteUInt(self:EntIndex(), 16)
			net.Broadcast()
		end)

		if (self.nut_NetHooks and self.nut_NetHooks[key]) then
			for k, v in pairs(self.nut_NetHooks[key]) do
				v()
			end
		end

		self:SendVar(key)
	end

	net.Receive("nut_NetHandshake", function(length, client)
		timer.Remove("nut_Net"..client:UniqueID()..net.ReadString())
	end)
	
	-- Clean up player vars.
	gameevent.Listen("player_disconnect")

	hook.Add("player_disconnect", "cn_PlayerVarClean", function(data)
		if (data.userid) then
			for k, v in pairs(player.GetAll()) do
				if (v:UserID() == data.userid) then
					net.Start("cn_EntityVarClean")
						net.WriteUInt(v:EntIndex(), 16)
					net.Broadcast()

					print("Cleaned net vars.")
				end
			end
		end
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

	net.Receive("nut_EntityVarClean", function(length)
		NUT_ENT_REGISTRY[net.ReadUInt(16)] = nil
	end)

	net.Receive("nut_EntityVar", function(length)
		local entIndex = net.ReadUInt(16)
		local key = net.ReadString()
		local index = net.ReadUInt(8)
		local value = net.ReadType(index)

		NUT_ENT_REGISTRY[entIndex] = NUT_ENT_REGISTRY[entIndex] or {}

		local registry = NUT_ENT_REGISTRY[entIndex]

		if (type(value) == "table") then
			value = replacePlaceHolders(table.Merge(registry[key] or {}, value))
		end

		registry[key] = value

		local entity = Entity(entIndex)

		if (IsValid(entity) and entity.nut_NetHooks and entity.nut_NetHooks[key]) then
			for k, v in pairs(entity.nut_NetHooks[key]) do
				v()
			end
		end

		net.Start("nut_NetHandshake")
			net.WriteString(entIndex..key)
		net.SendToServer()
	end)
end

function entityMeta:HookNetVar(key, callback)
	self.nut_NetHooks = self.nut_NetHooks or {}
	self.nut_NetHooks[key] = self.nut_NetHooks[key] or {}

	table.insert(self.nut_NetHooks[key], callback)
end

function entityMeta:GetNetVar(key, default)
	if (SERVER and self.nut_NetVars) then
		return self.nut_NetVars[key] or default
	elseif (CLIENT and NUT_ENT_REGISTRY[self:EntIndex()]) then
		return NUT_ENT_REGISTRY[self:EntIndex()][key] or default
	end

	return default
end
