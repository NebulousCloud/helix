local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
	function playerMeta:LoadData(callback)
		local name = self:SteamName()
		local steamID64 = self:SteamID64()
		local timeStamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		nut.db.query("SELECT _data, _playTime FROM nut_players WHERE _steamID = "..steamID64, function(data)
			if (IsValid(self) and data and data[1] and data[1]._data) then
				nut.db.UpdateTable({
					_lastJoin = timeStamp,
					_address = ip
				}, nil, "players", "_steamID = "..steamID64)

				self.nutPlayTime = tonumber(data[1]._playTime) or 0
				self.nutData = util.JSONToTable(data[1]._data)

				if (callback) then
					callback(self.nutData)
				end
			else
				nut.db.InsertTable({
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

	function playerMeta:SaveData()
		local name = self:Name()
		local steamID64 = self:SteamID64()

		nut.db.UpdateTable({
			_steamName = name,
			_playTime = math.floor((self.nutPlayTime or 0) + (RealTime() - (self.nutJoinTime or RealTime() - 1))),
			_data = self.nutData
		}, nil, "players", "_steamID = "..steamID64)
	end

	function playerMeta:SetData(key, value, noNetworking)
		self.nutData = self.nutData or {}
		self.nutData[key] = value

		if (!noNetworking) then
			netstream.Start(self, "nutData", key, value)
		end
	end
end

-- Whitelisting information for the player.
do
	function playerMeta:SetWhitelisted(faction, whitelisted)
		if (!whitelisted) then
			whitelisted = nil
		end

		local data = nut.faction.indices[faction]

		if (data) then
			local whitelists = self:GetData("whitelists", {})
			whitelists[Schema.folder] = whitelists[Schema.folder] or {}
			whitelists[Schema.folder][data.uniqueID] = whitelisted and true or nil

			self:SetData("whitelists", whitelists)
			self:SaveData()

			return true
		end

		return false
	end
end
