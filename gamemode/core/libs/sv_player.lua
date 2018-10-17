local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
	util.AddNetworkString("ixData")
	util.AddNetworkString("ixDataSync")

	function playerMeta:LoadData(callback)
		local name = self:SteamName()
		local steamID64 = self:SteamID64()
		local timestamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		local query = mysql:Select("ix_players")
			query:Select("data")
			query:Select("play_time")
			query:Where("steamid", steamID64)
			query:Callback(function(result)
				if (IsValid(self) and istable(result) and #result > 0 and result[1].data) then
					local updateQuery = mysql:Update("ix_players")
						updateQuery:Update("last_join_time", timestamp)
						updateQuery:Update("address", ip)
						updateQuery:Where("steamid", steamID64)
					updateQuery:Execute()

					self.ixPlayTime = tonumber(result[1].play_time) or 0
					self.ixData = util.JSONToTable(result[1].data)

					if (callback) then
						callback(self.ixData)
					end
				else
					local insertQuery = mysql:Insert("ix_players")
						insertQuery:Insert("steamid", steamID64)
						insertQuery:Insert("steam_name", name)
						insertQuery:Insert("play_time", 0)
						insertQuery:Insert("address", ip)
						insertQuery:Insert("last_join_time", timestamp)
						insertQuery:Insert("data", util.TableToJSON({}))
					insertQuery:Execute()

					if (callback) then
						callback({})
					end
				end
			end)
		query:Execute()
	end

	function playerMeta:SaveData()
		local name = self:SteamName()
		local steamID64 = self:SteamID64()

		local query = mysql:Update("ix_players")
			query:Update("steam_name", name)
			query:Update("play_time", math.floor((self.ixPlayTime or 0) + (RealTime() - (self.ixJoinTime or RealTime() - 1))))
			query:Update("data", util.TableToJSON(self.ixData))
			query:Where("steamid", steamID64)
		query:Execute()
	end

	function playerMeta:SetData(key, value, bNoNetworking)
		self.ixData = self.ixData or {}
		self.ixData[key] = value

		if (!bNoNetworking) then
			net.Start("ixData")
				net.WriteString(key)
				net.WriteType(value)
			net.Send(self)
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

do
	playerMeta.ixGive = playerMeta.ixGive or playerMeta.Give

	function playerMeta:Give(className, bNoAmmo)
		local weapon

		self.ixWeaponGive = true
			weapon = self:ixGive(className, bNoAmmo)
		self.ixWeaponGive = nil

		return weapon
	end
end
