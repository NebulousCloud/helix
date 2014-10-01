local _R = debug.getregistry()

local CHAR = _R.Character or setmetatable({}, {__tostring = function(self) return "character["..self.id.."]" end})
CHAR.__index = CHAR
CHAR.id = CHAR.id or 0
CHAR.vars = CHAR.vars or {}

function CHAR:getID()
	return self.id
end

if (SERVER) then
	function CHAR:save(callback)
		if (self.isBot) then
			return
		end
		
		local data = {}

		for k, v in pairs(nut.char.vars) do
			if (v.field and self.vars[k] != nil) then
				data[v.field] = self.vars[k]
			end
		end

		local shouldSave = hook.Run("CharacterPreSave", self)

		if (shouldSave != false) then
			nut.db.updateTable(data, function()
				if (callback) then
					callback()
				end

				hook.Run("CharacterPostSave", self)

				if (!nut.shuttingDown) then
					MsgN("Saved character '"..self:getID().."'")
				end
			end, nil, "_id = "..self:getID())
		end
	end

	function CHAR:sync(receiver)
		if (receiver == nil) then
			for k, v in ipairs(player.GetAll()) do
				self:sync(v)
			end
		elseif (receiver == self.player) then
			netstream.Start(self.player, "charInfo", self.vars, self:getID())
		else
			local data = {}

			for k, v in pairs(nut.char.vars) do
				if (!v.noNetworking and !v.isLocalVar) then
					data[k] = self.vars[k]
				end
			end

			netstream.Start(receiver, "charInfo", data, self:getID(), self.player)
		end
	end

	function CHAR:setup(noNetworking)
		local client = self:getPlayer()

		if (IsValid(client)) then
			client:SetModel(self:getModel())
			client:SetTeam(self:getFaction())
			client:setNetVar("char", self:getID())

			if (!noNetworking) then
				self:sync()

				if (!self.firstTimeLoaded) then
					if (!self:getInv()) then
						self.vars.inv = nut.item.createInv(nut.config.get("invW", 6), nut.config.get("invH", 4))
						self.vars.inv:setOwner(self:getID())
					end
				end

				self:getInv():sync(client)
			end

			hook.Run("CharacterLoaded", self:getID())

			netstream.Start(client, "charLoaded")
			self.firstTimeLoaded = true
		end
	end
end

function CHAR:getPlayer()
	if (IsValid(self.player)) then
		return self.player
	elseif (self.steamID) then
		local steamID = self.steamID

		for k, v in ipairs(player.GetAll()) do
			if (v:SteamID64() == steamID) then
				self.player = v

				return v
			end
		end
	end
end

function nut.char.registerVar(key, data)
	nut.char.vars[key] = data
	data.index = data.index or table.Count(nut.char.vars)

	local upperName = key:sub(1, 1):upper()..key:sub(2)

	if (SERVER and !data.isNotModifiable) then
		if (data.onSet) then
			CHAR["set"..upperName] = function(self, value, ...)
				return data.onSet(self, value, ...)
			end
		elseif (data.noNetworking) then
			CHAR["set"..upperName] = function(self, value)
				self.vars[key] = value
			end
		elseif (data.isLocalVar) then
			CHAR["set"..upperName] = function(self, value)
				self.vars[key] = value
				netstream.Start(self.player, "charVar", key, value)
			end
		else
			CHAR["set"..upperName] = function(self, value)
				self.vars[key] = value
				netstream.Start(nil, "charVar", key, value, self.id)
			end
		end
	end

	if (data.onGet) then
		CHAR["get"..upperName] = function(self, default, ...)
			return data.onGet(self, default, ...)
		end
	else
		CHAR["get"..upperName] = function(self, default)
			local value = self.vars[key]

			if (value != nil) then
				return value
			end

			if (default == nil) then
				return nut.char.vars[key] and nut.char.vars[key].default or nil
			end

			return default
		end
	end

	CHAR.vars[key] = data.default
end

_R.Character = CHAR