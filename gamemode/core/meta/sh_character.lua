local _R = debug.getregistry()

local CHAR = setmetatable({}, {__tostring = function(self) return "character["..self.id.."]" end})
CHAR.__index = CHAR
CHAR.id = 0
CHAR.vars = {}

function CHAR:getID()
	return self.id
end

if (SERVER) then
	function CHAR:save(callback)
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
				MsgN("Saved character '"..self:getID().."'")
			end, nil, "_id = "..self:getID())
		end
	end

	function CHAR:sync(receiver)
		if (receiver == nil) then
			for k, v in ipairs(player.GetAll()) do
				self:sync(v)
			end
		elseif (receiver == self.player) then
			netstream.Start(self.player, "charInfo", self.vars, self:getID(), self.player)
		else
			local data = {}

			for k, v in pairs(nut.char.vars) do
				if (!v.noNetworking and !v.isLocalVar) then
					data[k] = self.vars[k]
				end
			end

			netstream.Start(nil, "charInfo", data, self:getID(), self.player)
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

				if (!client.nutFirstLoaded) then
					self:getInv():sync()
				end
			end

			netstream.Start(client, "charLoaded")
			client.nutFirstLoaded = true
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

			return value == nil and default or value
		end
	end

	CHAR.vars[key] = data.default
end

_R.Character = CHAR