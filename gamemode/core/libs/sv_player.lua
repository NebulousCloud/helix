local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
	function playerMeta:LoadData(callback)
		local name = self:SteamName()
		local steamID64 = self:SteamID64()
		local timeStamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		ix.db.query("SELECT _data, _playTime FROM ix_players WHERE _steamID = "..steamID64, function(data)
			if (IsValid(self) and data and data[1] and data[1]._data) then
				ix.db.UpdateTable({
					_lastJoin = timeStamp,
					_address = ip
				}, nil, "players", "_steamID = "..steamID64)

				self.ixPlayTime = tonumber(data[1]._playTime) or 0
				self.ixData = util.JSONToTable(data[1]._data)

				if (callback) then
					callback(self.ixData)
				end
			else
				ix.db.InsertTable({
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

		ix.db.UpdateTable({
			_steamName = name,
			_playTime = math.floor((self.ixPlayTime or 0) + (RealTime() - (self.ixJoinTime or RealTime() - 1))),
			_data = self.ixData
		}, nil, "players", "_steamID = "..steamID64)
	end

	function playerMeta:SetData(key, value, noNetworking)
		self.ixData = self.ixData or {}
		self.ixData[key] = value

		if (!noNetworking) then
			netstream.Start(self, "ixData", key, value)
		end
	end
end

-- Whitelisting information for the player.
do
	function playerMeta:SetWhitelisted(faction, whitelisted)
		if (!whitelisted) then
			whitelisted = nil
		end

		local data = ix.faction.indices[faction]

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
