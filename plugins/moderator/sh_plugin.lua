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
		return a <= b
	end

	return true
end

local PLUGIN = PLUGIN

playerMeta.ModIsAdmin = playerMeta.ModIsAdmin or playerMeta.IsAdmin
playerMeta.ModIsSuperAdmin = playerMeta.ModIsSuperAdmin or playerMeta.IsSuperAdmin

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
PLUGIN.ranks.owner = 0
PLUGIN.ranks.superadmin = 1
PLUGIN.ranks.admin = 2
PLUGIN.ranks.operator = 3
PLUGIN.ranks.user = 4

function PLUGIN:PlayerSpawn(client)
	if (!client:GetNutVar("modInit")) then
		self:SetUserGroup(client:SteamID(), self.users[client:SteamID()] or "user", client)

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
	end
end

function PLUGIN:BanPlayer(steamID, time, reason)
	local client

	if (type(steamID) == "Player") then
		client = steamID
		steamID = steamID:SteamID()
	end

	reason = reason or "no reason"
	time = math.max(time or 0, 0)

	local expireTime = os.time() + time

	if (time == 0) then
		expireTime = 0
	end

	self.bans[steamID] = {expire = expireTime, reason = reason}

	if (IsValid(client)) then
		if (time == 0) then
			time = "permanently"
		else
			time = "for "..string.ToMinutesSeconds(time).." minute(s)"
		end

		client:Kick("You have been banned "..time.." with the reason: "..reason)
	end
end

function PLUGIN:UnbanPlayer(steamID)
	local found = self.bans[steamID] != nil
	self.bans[steamID] = nil

	return found
end

gameevent.Listen("player_connect")

function PLUGIN:player_connect(data)
	local ban = self.bans[data.networkid]

	if (ban and (ban.expire == 0 or ban.expire >= os.time())) then
		local time = "expire in "..string.ToMinutesSeconds(math.floor(ban.expire - os.time())).." minute(s)"

		if (ban.expire == 0) then
			time = "not expire"
		end

		game.ConsoleCommand("kickid "..data.userid.." You have been banned from this server for "..ban.reason..". Your ban will "..time.."\n")
	else
		self.bans[data.networkid] = nil
	end
end

function PLUGIN:SaveData()
	-- When saving ranks, we will allow all schemas to use the ranks and regardless of map.
	nut.util.WriteTable("ranks", self.ranks, true, true)
	nut.util.WriteTable("users", self.users, true, true)
	nut.util.WriteTable("bans", self.bans, true, true)
end

nut.util.Include("sh_commands.lua")
nut.util.Include("cl_derma.lua")

function PLUGIN:PlayerNoClip(client)
	return self:IsAllowed(client, "operator")
end