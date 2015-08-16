local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
	function playerMeta:loadNutData(callback)
		local name = self:steamName()
		local steamID64 = self:SteamID64()
		local timeStamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		nut.db.query("SELECT _data, _playTime FROM nut_players WHERE _steamID = "..steamID64, function(data)
			if (IsValid(self) and data and data[1] and data[1]._data) then
				nut.db.updateTable({
					_lastJoin = timeStamp,
					_address = ip
				}, nil, "players", "_steamID = "..steamID64)

				self.nutPlayTime = tonumber(data[1]._playTime) or 0
				self.nutData = util.JSONToTable(data[1]._data)

				if (callback) then
					callback(self.nutData)
				end
			else
				nut.db.insertTable({
					_steamID = steamID64,
					_steamName = name,
					_playTime = 0,
					_address = ip,
					_lastJoin = timeStamp,
					_data = {}
				}, nil, "players")

				if (callback) then
					callback({})
				end
			end
		end)
	end

	function playerMeta:saveNutData()
		local name = self:Name()
		local steamID64 = self:SteamID64()

		nut.db.updateTable({
			_steamName = name,
			_playTime = math.floor((self.nutPlayTime or 0) + (RealTime() - (self.nutJoinTime or RealTime() - 1))),
			_data = self.nutData
		}, nil, "players", "_steamID = "..steamID64)
	end

	function playerMeta:setNutData(key, value, noNetworking)
		self.nutData = self.nutData or {}
		self.nutData[key] = value

		if (!noNetworking) then
			netstream.Start(self, "nutData", key, value)
		end
	end
end

-- Whitelisting information for the player.
do
	function playerMeta:setWhitelisted(faction, whitelisted)
		if (!whitelisted) then
			whitelisted = nil
		end

		local data = nut.faction.indices[faction]

		if (data) then
			local whitelists = self:getNutData("whitelists", {})
			whitelists[SCHEMA.folder] = whitelists[SCHEMA.folder] or {}
			whitelists[SCHEMA.folder][data.uniqueID] = whitelisted and true or nil

			self:setNutData("whitelists", whitelists)
			self:saveNutData()

			return true
		end

		return false
	end
end
