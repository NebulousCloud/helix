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

	return false
end

local timeData = {
	{"y", 525600},
	{"mo", 43200},
	{"w", 10080},
	{"d", 1440},
	{"m", 60}
}

function PLUGIN:GetTimeByString(data)
	if (!data) then
		return 0
	end

	data = string.lower(data)

	local time = 0

	for i = 1, 5 do
		local info = timeData[i]

		data = string.gsub(data, "(%d+)"..info[1], function(match)
			local amount = tonumber(match)

			if (amount) then
				time = time + (amount * info[2])
			end

			return ""
		end)
	end

	local seconds = tonumber(string.match(data, "(%d+)")) or 0

	time = time + seconds

	return math.max(time, 0)
end

function PLUGIN:CreateCommand(data, command)
	if (!data or !command) then
		return
	end

	local callback = data.onRun
	local group = data.group
	local syntax = data.syntax
	local hasTarget = data.target or true
	local allowDead = data.allowDead or true

	nut.command.Register({
		syntax = (hasTarget and "<string target> " or "")..syntax,
		allowDead = allowDead,
		hasPermission = function(client)
			return self:IsAllowed(client, group)
		end,
		onRun = function(client, arguments)
			local target

			if (hasTarget) then
				target = nut.command.FindPlayer(client, arguments[1])

				if (!IsValid(target)) then
					return
				end
			end

			if (IsValid(target) and !self:IsAllowed(client, target)) then
				nut.util.Notify("The target has a higher rank than you.", client)

				return
			end

			if (IsValid(target)) then
				table.remove(arguments, 1)
			end

			callback(client, arguments, target)
		end
	}, "mod"..command)
end

local PLUGIN = PLUGIN

PLUGIN:CreateCommand({
	group = "operator",
	syntax = "[int force]",
	onRun = function(client, arguments, target)
		local power = math.Clamp(tonumber(arguments[1] or "128"), 0, 1000)
		local direction = VectorRand() * power
		direction.z = math.max(power, 128)

		target:SetGroundEntity(NULL)
		target:SetVelocity(direction)
		target:EmitSound("physics/body/body_medium_impact_hard"..math.random(1, 6)..".wav")
		target:ViewPunch(direction:Angle() * (power / 10000))

		nut.util.Notify(client:Name().." has slapped "..target:Name().." with "..power.." power.")
	end
}, "slap")

PLUGIN:CreateCommand({
	group = "admin",
	syntax = "[string reason]",
	onRun = function(client, arguments, target)
		local reason = arguments[1] or "no reason"
		local name = target:Name()

		target:Kick("Kicked by "..client:Name().." ("..client:SteamID()..") for: "..reason)
		nut.util.Notify(client:Name().." has kicked "..name.." for "..reason..".")
	end
}, "kick")

PLUGIN:CreateCommand({
	group = "admin",
	syntax = "[string time] [string reason]",
	onRun = function(client, arguments, target)
		local time = PLUGIN:GetTimeByString(arguments[1])
		local reason = arguments[2] or "no reason"

		PLUGIN:BanPlayer(client, time, reason)
	end
}, "ban")