PLUGIN.name = "Moderator"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides a simple administration mod."

PLUGIN.ranks = PLUGIN.ranks or {}
PLUGIN.users = PLUGIN.users or {}
PLUGIN.bans = PLUGIN.bans or {}

local playerMeta = FindMetaTable("Player")

function playerMeta:GetUserGroup()
	return self:GetNWString("usergroup", "user")
end

function PLUGIN:IsAllowed(a, b)
	if (type(a) == "Player") then
		a = self.ranks[string.lower(a:GetUserGroup())]
	else
		a = self.ranks[string.lower(a)]
	end

	if (type(b) == "Player") then
		b = self.ranks[string.lower(b:GetUserGroup())]
	else
		b = self.ranks[string.lower(b)]
	end

	if (a and b) then
		return a >= b
	end

	return true
end

local PLUGIN = PLUGIN

playerMeta.ModIsAdmin = playerMeta.ModIsAdmin or playerMeta.IsAdmin
playerMeta.ModIsSuperAdmin = playerMeta.ModIsSuperAdmin or playerMeta.IsSuperAdmin

PLUGIN.timeData = {
	{"y", 60*60*24*365, "Year"},
	{"mo", 60*60*24*30, "Month"},
	{"w", 60*60*24*7, "Week"},
	{"d", 60*60*24, "Day"},
	{"h", 60*60, "Hour"},
	{"m", 60, "Min"},
	{"s", 1, "Second"}
}

function PLUGIN:SecondsToFormattedString(time)
	local banstring = ""
	for ind, d in ipairs(self.timeData) do
		local subs = math.floor(time/d[2])
		if (subs > 0 ) then
			time = time - subs*d[2]
			banstring = banstring .. subs .. " " .. d[3]
			if (subs > 1) then
				banstring = banstring .. "s"
			end
			if ind != #self.timeData then
				banstring = banstring .. " "
			end
		end
	end
	return banstring
end

function playerMeta:IsSuperAdmin()
	return PLUGIN:IsAllowed(self, "superadmin") or self:ModIsSuperAdmin()
end

function playerMeta:IsAdmin()
	return PLUGIN:IsAllowed(self, "admin") or self:ModIsAdmin()
end

function PLUGIN:LoadData()
	local ranks = nut.util.ReadTable("ranks", true)
	local users = nut.util.ReadTable("users", true)
	local bans = nut.util.ReadTable("bans", true)

	self.ranks = table.Merge(self.ranks, ranks)
	self.users = users
	self.bans = bans
end

-- Permanent ranks, please do not edit this directly.
PLUGIN.ranks.owner = 100
PLUGIN.ranks.superadmin = 75
PLUGIN.ranks.admin = 50
PLUGIN.ranks.operator = 25
PLUGIN.ranks.user = 0

function PLUGIN:PlayerSpawn(client)
	if (!client:GetNutVar("modInit")) then
		local group = self.users[client:SteamID()] or "user"

		if (group != "user") then
			self:SetUserGroup(client:SteamID(), group, client)
		end

		client:ChatPrint("You are currently in the '"..client:GetUserGroup().."' group of the server.")
		client:SetNutVar("modInit", true)
	end
end

function PLUGIN:SetUserGroup(steamID, group, client)
	if (!group) then
		error("No rank was provided.")
	end

	group = string.lower(group)

	if (self.ranks[group]) then
		self.users[steamID] = group

		if (IsValid(client)) then
			client:SetUserGroup(group)
		end

		nut.util.WriteTable("users", self.users, true, true)
	end
end

function PLUGIN:CreateRank(group, immunity)
	self.ranks[group] = immunity
	nut.util.WriteTable("ranks", self.ranks, true, true)
end

function PLUGIN:RemoveRank(group)
	for k, v in pairs(self.ranks) do
		if (nut.util.StringMatches(group, k)) then
			self.ranks[k] = nil
			nut.util.WriteTable("ranks", self.ranks, true, true)

			return true, k
		end
	end

	return false
end

function PLUGIN:BanPlayer(steamID, time, reason)
	local client

	reason = reason or "no reason"
	time = math.max(time or 0, 0)

	local expireTime = os.time() + time

	if (time == 0) then
		expireTime = 0
	end

	self.bans[steamID] = {expire = expireTime, reason = reason}

	for k, v in ipairs(player.GetAll()) do
		if (v:SteamID() == steamID) then
			client = v
		end
	end
	if (IsValid(client)) then
		if (time == 0) then
			time = "permanently"
		else
			time = "for "..self:SecondsToFormattedString(time)
		end

		client:Kick("You have been banned "..time.." with the reason: "..reason)
	end

	nut.util.WriteTable("bans", self.bans, true, true)
end

function PLUGIN:UnbanPlayer(steamID)
	local found = (self.bans[steamID] != nil)
	self.bans[steamID] = nil

	if (found) then
		nut.util.WriteTable("bans", self.bans, true, true)
	end

	return found
end

gameevent.Listen("player_connect")

function PLUGIN:player_connect(data)
	local ban = self.bans[data.networkid]

	if (ban and (ban.expire == 0 or ban.expire >= os.time())) then
		local time = "expire in "..self:SecondsToFormattedString(math.floor(ban.expire - os.time()))

		if (ban.expire == 0) then
			time = "not expire"
		end

		game.ConsoleCommand("kickid "..data.userid.." You have been banned from this server for "..ban.reason..". Your ban will "..time.."\n")
	else
		self.bans[data.networkid] = nil
	end
end

nut.util.Include("sh_commands.lua")
nut.util.Include("cl_derma.lua")

function PLUGIN:PlayerNoClip(client)
	if (!self:IsAllowed(client, "operator")) then
		return false
	end
end