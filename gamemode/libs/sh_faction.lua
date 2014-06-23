--[[
	Purpose: Provides a library for creating factions and having
	players able to be whitelisted to certain factions.
--]]

nut.faction = nut.faction or {}
nut.faction.buffer = {}

local playerMeta = FindMetaTable("Player")

-- Player functions to handle data.
do
	local function sameSchema()
		return " AND rpschema = '"..SCHEMA.uniqueID.."'"
	end

	if (SERVER) then
		function playerMeta:InitializeData()
			nut.db.Query("SELECT whitelists, plydata FROM "..nut.config.dbPlyTable.." WHERE steamid = "..(self:SteamID64() or 0)..sameSchema(), function(data)
				if (!IsValid(self)) then
					return
				end

				if (data and table.Count(data) > 0) then
					for k, v in pairs(von.deserialize(data.plydata)) do
						self:SetData(k, v)
					end

					self.whitelists = data.whitelists

					if (self.whitelists != "") then
						netstream.Start(self, "nut_WhitelistData", self.whitelists)
					end

					hook.Run("PlayerLoadedData", self)
				else
					nut.db.InsertTable({
						steamid = self:SteamID64() or 0,
						whitelists = "",
						plydata = {},
						rpschema = SCHEMA.uniqueID
					}, function(data)
						if (IsValid(self)) then
							self:InitializeData()
						end
					end, nut.config.dbPlyTable)
				end
			end)
		end

		function playerMeta:SaveData()
			nut.db.UpdateTable("steamid = "..(self:SteamID64() or 0)..sameSchema(), {
				plydata = self.nut_Vars or {},
				whitelists = self.whitelists or ""
			}, nut.config.dbPlyTable)
		end

		function playerMeta:SetData(key, value, noSend, noSave)
			self.nut_Vars = self.nut_Vars or {}
			self.nut_Vars[key] = value

			if (!noSend) then
				netstream.Start(self, "nut_PlayerData", {key, value})
			end

			if (!noSave) then
				self:SaveData()
			end
		end

		function playerMeta:GiveWhitelist(index, noSend, noSave)
			if (!self.whitelists) then
				return
			end

			local faction = nut.faction.GetByID(index)

			if (faction and !string.find(self.whitelists, faction.uniqueID..",")) then
				self.whitelists = self.whitelists..faction.uniqueID..","

				if (!noSend) then
					netstream.Start(self, "nut_WhitelistData", self.whitelists)
				end

				if (!noSave) then
					self:SaveData()
				end
			end
		end

		function playerMeta:TakeWhitelist(index, noSend)
			if (!self.whitelists) then
				return
			end

			local faction = nut.faction.GetByID(index)

			if (faction and string.find(self.whitelists, faction.uniqueID..",")) then
				self.whitelists = string.gsub(self.whitelists, faction.uniqueID..",", "")

				if (!noSend) then
					netstream.Start(self, "nut_WhitelistData", self.whitelists)
				end
			end
		end

		function playerMeta:GetWhitelists()
			return self.whitelists or ""
		end
	else
		netstream.Hook("nut_WhitelistData", function(data)
			LocalPlayer().whitelists = data
		end)

		netstream.Hook("nut_PlayerData", function(data)
			local key = data[1]
			local value = data[2]

			LocalPlayer().nut_Vars = LocalPlayer().nut_Vars or {}
			LocalPlayer().nut_Vars[key] = value
		end)
	end

	function playerMeta:GetData(key, default)
		self.nut_Vars = self.nut_Vars or {}

		return self.nut_Vars[key] or default
	end

	function playerMeta:GetWhitelists()
		return self.whitelists or ""
	end
end

--[[
	Purpose: Takes an index and registers a faction. The function will apply default
	variables if the faction does not already contain it, like models. A team
	will also be set up for the faction so it makes it easier to network.
--]]
function nut.faction.Register(index, uniqueID, faction)
	if (!faction) then
		error("Attempt to register faction without an actual faction table!")
	end
	
	faction.uniqueID = uniqueID

	if (faction.isDefault == nil) then
		faction.isDefault = true
	end

	faction.maxChars = faction.maxChars or 2
	faction.maleModels = faction.maleModels or MALE_MODELS
	faction.femaleModels = faction.femaleModels or FEMALE_MODELS
	faction.pay = faction.pay or 0
	faction.payTime = faction.payTime or 600

	team.SetUp(index, faction.name, faction.color)
	
	nut.faction.buffer[index] = faction
end

--[[
	Purpose: Returns a faction based upon the unique ID it was registered with, rather
	than the numeric ID.
--]]
function nut.faction.GetByStringID(uniqueID)
	for k, v in pairs(nut.faction.buffer) do
		if (v.uniqueID == uniqueID) then
			return v
		end
	end
end

--[[
	Purpose: Loads all of the factions within the directory's faction sub-directory.
	A global table, FACTION, will be defined and then registered with nut.faction.Register
--]]
function nut.faction.Load(directory)
	for k, v in pairs(file.Find(directory.."/factions/*.lua", "LUA")) do
		local uniqueID = string.sub(v, 4, -5)
		local index = #nut.faction.buffer + 1

		FACTION = nut.faction.GetByStringID(uniqueID) or {index = index}
			nut.util.Include(directory.."/factions/"..v)
			nut.faction.Register(index, uniqueID, FACTION)
		FACTION = nil
	end
end

if (SERVER) then
	timer.Create("nut_PayTick", 1, 0, function()
		for k, v in pairs(player.GetAll()) do
			local faction = nut.faction.GetByID(v:Team())

			if (faction) then
				local nextPay = v:GetNutVar("nextPay")

				if (!nextPay) then
					v:SetNutVar("nextPay", CurTime() + faction.payTime)
					nextPay = v:GetNutVar("nextPay")
				end
				
				if (faction.pay > 0 and nextPay < CurTime()) then
					if (hook.Run("ShouldReceivePay", v) != false) then
						v:GiveMoney(faction.pay)

						nut.util.Notify(nut.lang.Get("pay_received", nut.currency.GetName(faction.pay)), v)
					end

					v:SetNutVar("nextPay", CurTime() + faction.payTime)
				end
			end
		end
	end)
end

--[[
	Purpose: Returns a faction table using the given index, which is the faction
	enum.
--]]
function nut.faction.GetByID(index)
	for k, v in ipairs(nut.faction.buffer) do
		if (v.index == index) then
			return nut.faction.buffer[k]
		end
	end
end

--[[
	Purpose: Checks if the given player is able to be a part of a certain
	faction based off the index given.
--]]
function nut.faction.CanBe(client, index)
	local faction = nut.faction.GetByID(index)

	if (faction.isDefault) then
		return true
	end
	
	local factions = client:GetWhitelists()

	if (faction and string.find(factions, faction.uniqueID..",")) then
		return true
	end

	return false
end

--[[
	Purpose: Returns all of the faction tables.
--]]
function nut.faction.GetAll()
	return nut.faction.buffer
end

--[[
	Purpose: Simply calls table.Count on the faction list and returns the value.
--]]
function nut.faction.Count()
	return table.Count(nut.faction.buffer)
end