local entityMeta = FindMetaTable("Entity")

if (SERVER) then
	util.AddNetworkString("nut_EntityVar")

	function entityMeta:SyncVars(client)
		if (self.nut_NetVars) then
			for k, v in pairs(self.nut_NetVars) do
				self:SendVar(k, client)
			end
		end
	end

	hook.Add("PlayerInitialSpawn", "nut_SyncVars", function(client)
		timer.Simple(5, function()
			for k, v in pairs(ents.GetAll()) do
				v:SyncVars(client)
			end
		end)
	end)

	function entityMeta:SendVar(key, receiver)
		if (self.nut_NetVars and self.nut_NetVars[key] != nil) then
			net.Start("nut_EntityVar")
				net.WriteUInt(self:EntIndex(), 16)
				net.WriteString(key)
				net.WriteType(self.nut_NetVars[key])
			if (receiver) then
				net.Send(receiver)
			else
				net.Broadcast()
			end
		end
	end

	function entityMeta:SetNetVar(key, value)
		self.nut_NetVars = self.nut_NetVars or {}
		self.nut_NetVars[key] = value

		self:SendVar(key)
	end
else
	NUT_ENT_REGISTRY = NUT_ENT_REGISTRY or {}

	net.Receive("nut_EntityVar", function(length)
		local entIndex = net.ReadUInt(16)
		local key = net.ReadString()
		local index = net.ReadUInt(8)
		local value = net.ReadType(index)

		NUT_ENT_REGISTRY[entIndex] = NUT_ENT_REGISTRY[entIndex] or {}
		NUT_ENT_REGISTRY[entIndex][key] = value
	end)
end

function entityMeta:GetNetVar(key, default)
	if (SERVER and self.nut_NetVars) then
		return self.nut_NetVars[key] or default
	elseif (CLIENT and NUT_ENT_REGISTRY[self:EntIndex()]) then
		return NUT_ENT_REGISTRY[self:EntIndex()][key] or default
	end

	return default
end