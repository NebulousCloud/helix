PLUGIN.commands = {}

local times = {
	{1,"1 Years","1y"},
	{2,"1 Month","1mo"},
	{3,"1 Week","1w"},
	{4,"1 Day","1d"},
	{5,"30 Mins","30m"},
	{6,"1 Min","1m"},
}
local reasons = {
	"Admin disrespect.",
	"FailRP.",
	"Metagaming.",
	"Powergaming.",
	"Disrespectful RP.",
	"Cheater.",
	"Violation of DMCA",
	"Fuck you.",
}

function PLUGIN:GetTimeByString(data)
	if (!data) then
		return 0
	end

	data = string.lower(data)

	local time = 0

	for i = 1, 5 do
		local info = self.timeData[i]

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
	local syntax = data.syntax or "[none]"
	local hasTarget = data.hasTarget
	local allowDead = data.allowDead

	if (hasTarget == nil) then
		hasTarget = true
	end

	if (allowDead == nil) then
		allowDead = true
	end
	data.onMenu = data.onMenu or function( menu, icon, client, command )
		menu:AddOption(client:Name(), function()
			LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'"' )
		end):SetImage(hook.Run("GetUserIcon", client) or icon)
	end
	self.commands[command] = data
	
	nut.command.Register({
		syntax = (hasTarget and "<string target> " or "")..syntax,
		allowDead = allowDead,
		hasPermission = function(client)
			return self:IsAllowed(client, group)
		end,
		silent = (data.silent or false),
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

			if (hasTarget) then
				table.remove(arguments, 1)
			end

			callback(client, arguments, target)
		end
	}, "mod"..command)
end


local PLUGIN = PLUGIN

PLUGIN:CreateCommand({
	text = "Create Rank",
	desc = "Create a new rank." ,
	group = "owner",
	syntax = "<string name> [number immunity]",
	hasTarget = false,
	onMenu = function( menu, icon, client, command )
	end,
	onRun = function(client, arguments)
		local name = arguments[1]
		local immunity = tonumber(arguments[2] or "0") or 0

		if (!name) then
			nut.util.Notify("You need to provide a group name.", client)

			return
		end

		name = string.lower(name)

		PLUGIN:CreateRank(name, immunity)
		nut.util.Notify(client:Name().." has created the '"..name.."' rank with "..immunity.." immunity.")
	end
}, "newrank")

PLUGIN:CreateCommand({
	text = "Delete Rank",
	desc = "Delete exisiting rank." ,
	group = "owner",
	syntax = "<string name>",
	hasTarget = false,
	onMenu = function( menu, icon, client, command )
	end,
	onRun = function(client, arguments)
		local name = arguments[1]

		if (!name) then
			nut.util.Notify("You need to provide a group name.", client)

			return
		end

		name = string.lower(name)
		local removed, realName = PLUGIN:RemoveRank(name)

		if (removed) then
			nut.util.Notify(client:Name().." has removed the '"..realName.."' rank.")
		else
			nut.util.Notify("That rank does not exist.", client)
		end
	end
}, "delrank")

PLUGIN:CreateCommand({
	text = "Slap Player",
	desc = "Slap player with certain amount of force and damage." ,
	group = "operator",
	syntax = "[number force]",
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
	text = "Slay Player",
	desc = "Kill player with moderation power.",
	group = "operator",
	onRun = function(client, arguments, target)
		target:Kill()

		nut.util.Notify(client:Name().." has slayed "..target:Name()..".")
	end
}, "slay")

PLUGIN:CreateCommand({
	text = "Freeze Player",
	desc = "Disallow player to control it's character.",
	group = "operator",
	onRun = function(client, arguments, target)
		target:Lock()

		nut.util.Notify(client:Name().." has frozen "..target:Name()..".")
	end
}, "freeze")

PLUGIN:CreateCommand({
	text = "Unfreeze Player",
	desc = "Allow player to control it's character.",
	group = "operator",
	onRun = function(client, arguments, target)
		target:UnLock()

		nut.util.Notify(client:Name().." has unfrozen "..target:Name()..".")
	end
}, "unfreeze")

PLUGIN:CreateCommand({
	text = "Ignite Player",
	desc = "Set player on fire with moderation power.",
	group = "admin",
	syntax = "[number time]",
	onRun = function(client, arguments, target)
		local time = math.max(tonumber(arguments[1] or "5"), 1)
		target:Ignite(time)

		nut.util.Notify(client:Name().." has ignited "..target:Name().." for "..time.." second(s).")
	end
}, "ignite")

PLUGIN:CreateCommand({
	text = "Unignite Player",
	desc = "Extinguish the fire on the player.",
	group = "admin",
	syntax = "[number time]",
	onRun = function(client, arguments, target)
		target:Extinguish()

		nut.util.Notify(client:Name().." has unignited "..target:Name()..".")
	end
}, "unignite")

PLUGIN:CreateCommand({
	text = "Set Health",
	desc = "Set player's health.",
	group = "operator",
	syntax = "[number health]",
	onMenu = function( menu, icon, client, command )
		local submenu = menu:AddSubMenu( client:Name() )
		for i = 1, 10 do
			submenu:AddOption(i*10, function()
				LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'" '.. i*10 )
			end):SetImage(hook.Run("GetUserIcon", client) or icon)
		end
	end,
	onRun = function(client, arguments, target)
		-- No point of 0 HP, might as well just slay.
		local health = math.max(tonumber(arguments[1] or "100"), 1)
		target:SetHealth(health)

		nut.util.Notify(client:Name().." has set the health of "..target:Name().." to "..health..".")
	end
}, "hp")

PLUGIN:CreateCommand({
	text = "Strip Player Weapons",
	desc = "Remove all of player's weapons.",
	group = "admin",
	onRun = function(client, arguments, target)
		target:StripWeapons()

		nut.util.Notify(client:Name().." has stripped "..target:Name().." of weapons.")
	end
}, "strip")

PLUGIN:CreateCommand({
	text = "Arm Player",
	desc = "Give player default gears.",
	group = "admin",
	onRun = function(client, arguments, target)
		target:SetMainBar()
		target:StripWeapons()
		target:SetModel(target.character.model)
		target:Give("nut_fists")
		target:SetWalkSpeed(nut.config.walkSpeed)
		target:SetRunSpeed(nut.config.runSpeed)
		target:SetWepRaised(false)

		nut.flag.OnSpawn(target)
		nut.attribs.OnSpawn(target)

		nut.util.Notify(client:Name().." has armed "..target:Name()..".")
	end
}, "arm")

PLUGIN:CreateCommand({
	text = "Set Armor",
	desc = "Set player's armor.",
	group = "operator",
	syntax = "[number armor]",
	onMenu = function( menu, icon, client, command )
		local submenu = menu:AddSubMenu( client:Name() )
		for i = 1, 10 do
			submenu:AddOption(i*10, function()
				LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'" '.. i*10 )
			end):SetImage(hook.Run("GetUserIcon", client) or icon)
		end
	end,
	onRun = function(client, arguments, target)
		local armor = math.max(tonumber(arguments[1] or "100"), 0)
		target:SetArmor(armor)

		nut.util.Notify(client:Name().." has set the armor of "..target:Name().." to "..armor..".")
	end
}, "armor")

PLUGIN:CreateCommand({
	text = "Teleport Player",
	desc = "Teleport player A to player B.",
	group = "admin",
	syntax = "[bool toAimPos]",
	onRun = function(client, arguments, target)
		local position = client:GetEyeTraceNoCursor().HitPos
		local toAimPos = util.tobool(arguments[1])

		if (!toAimPos) then
			local data = {}
				data.start = client:GetShootPos() + client:GetAimVector() * 32
				data.endpos = client:GetShootPos() + client:GetAimVector() * 72
				data.filter = client
			local trace = util.TraceLine(data)

			position = trace.HitPos
		end

		if (position) then
			target:SetPos(position)
			nut.util.Notify(client:Name().." has teleported "..target:Name().." to "..(toAimPos and "their aim position" or "their position")..".")
		else
			nut.util.Notify(target:Name().." could not be teleported.", client)
		end
	end
}, "tp")

PLUGIN:CreateCommand({
	text = "Go to Player",
	desc = "Go to player.",
	group = "admin",
	syntax = "[bool toAimPos]",
	onRun = function(client, arguments, target)
		local position = target:GetEyeTraceNoCursor().HitPos
		local toAimPos = util.tobool(arguments[1])

		if (!toAimPos) then
			local data = {}
				data.start = target:GetShootPos() + target:GetAimVector() * 32
				data.endpos = target:GetShootPos() + target:GetAimVector() * 72
				data.filter = target
			local trace = util.TraceLine(data)

			position = trace.HitPos
		end

		if (position) then
			client:SetPos(position)
			nut.util.Notify(client:Name().." has teleported to "..target:Name().."'s "..(toAimPos and "aim position" or "position")..".")
		else
			nut.util.Notify("A position could not be found for you.", client)
		end
	end
}, "goto")

PLUGIN:CreateCommand({
	text = "Kick Player",
	desc = "Kick out player from the server.",
	group = "admin",
	syntax = "[string reason]",
	onMenu = function( menu, icon, client, command )
		local submenu = menu:AddSubMenu( client:Name() )
		for _, why in pairs( reasons ) do
			submenu:AddOption(why, function()
				LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'" '.. why )
			end):SetImage(hook.Run("GetUserIcon", client) or icon)
		end
	end,
	onRun = function(client, arguments, target)
		local reason = "no reason"

		if (#arguments > 0) then
			reason = table.concat(arguments, " ")
		end
		
		local name = target:Name()

		target:Kick("Kicked by "..client:Name().." ("..client:SteamID()..") for: "..reason)
		nut.util.Notify(client:Name().." has kicked "..name.." for "..reason..".")
	end
}, "kick")

PLUGIN:CreateCommand({
	text = "Ban Player",
	desc = "Kick out player and disallow rejoin to your server.",
	group = "admin",
	hasTarget = false,
	syntax = "[string time] [string reason]",
	onMenu = function( menu, icon, client, command )
		local submenu = menu:AddSubMenu( client:Name() )
		for _, why in pairs( reasons ) do
			local reasonmenu = submenu:AddSubMenu( why )
			for _, tdat in SortedPairsByMemberValue( times, 1 ) do
				reasonmenu:AddOption(tdat[2], function()
					LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'" "'.. tdat[3] .. '" "'.. why .. '"' )
				end):SetImage(hook.Run("GetUserIcon", client) or icon)
			end
		end
	end,
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1], true)
		local targetname
		if (!target or !target:IsValid()) then
			if (string.StartWith(arguments[1], "STEAM_0")) then
				targetname = arguments[1]
				table.remove(arguments, 1)
			else
				nut.util.Notify(nut.lang.Get("no_ply"), client)
				return
			end
		else
			if (target == client) then
				nut.util.Notify("You tried to ban yourself. Provice more specific name.", client)
				return
			end
			targetname = target:Name()
			table.remove(arguments, 1)
		end
		local time = PLUGIN:GetTimeByString(arguments[1])
		table.remove(arguments, 1)

		local reason = "no reason"
		if (#arguments > 0) then
			reason = table.concat(arguments, " ")
		end
		
		local timetext
		if time == 0 then
			timetext = "permanently"
		else
			timetext = PLUGIN:SecondsToFormattedString(time)
		end

		local bantext = Format("%s has been banned for %s (%s)", targetname, timetext, reason)
		nut.util.AddLog(bantext, LOG_FILTER_MAJOR)
		nut.util.Notify(bantext, unpack(player.GetAll()))

		local steamid
		if target and target:IsValid() then
			steamid = target:SteamID()
		else
			steamid = targetname
		end
		PLUGIN:BanPlayer(steamid, time, reason)
	end
}, "ban")

PLUGIN:CreateCommand({
	text = "Change Server's Map",
	desc = "Change server's map.",
	group = "superadmin",
	syntax = "<string map> [number time]",
	hasTarget = false,
	onMenu = function( menu, icon, client, command )
	end,
	onRun = function(client, arguments)
		local map = arguments[1]
		local time = math.Clamp(tonumber(arguments[2] or "5"), 5, 60)

		if (!map) then
			nut.util.Notify("You need to provide a map.", client)

			return
		end

		map = string.lower(map)

		if (!file.Exists("maps/"..map..".bsp", "GAME")) then
			nut.util.Notify("That map does not exist on the server.", client)

			return
		end

		nut.util.Notify(client:Name().." will change the map to "..map.." in "..time.." seconds.")

		timer.Create("nut_ChangeMap", time, 1, function()
			game.ConsoleCommand("changelevel "..map.."\n")
		end)
	end
}, "map")

PLUGIN:CreateCommand({
	text = "Unban Player",
	desc = "Allows to rejoin certain kicked out player.",
	group = "admin",
	hasTarget = false,
	syntax = "<string steamID>",
	onMenu = function( menu, icon, client, command )
	end,
	onRun = function(client, arguments, target)
		local steamID = arguments[1]

		if (!steamID) then
			nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

			return
		end

		local result = PLUGIN:UnbanPlayer(steamID)

		if (result) then
			local bantext = Format("%s has unbanned %s from the server", client:Name(), steamID)
			nut.util.AddLog(bantext, LOG_FILTER_MAJOR)
			nut.util.Notify(bantext, unpack(player.GetAll()))
		else
			nut.util.Notify("No bans were found with that steamID.", client)
		end
	end
}, "unban")

PLUGIN:CreateCommand({
	text = "Set Rank",
	desc = "Set player's rank.",
	group = "owner",
	syntax = "<string name/steamID> [string group]",
	hasTarget = false,
	onMenu = function( menu, icon, client, command )
		local submenu = menu:AddSubMenu( client:Name() )
		for uid, power in pairs( PLUGIN.ranks ) do
			submenu:AddOption(uid, function()
				LocalPlayer():ConCommand( 'say /mod'..command..' "'..client:Name()..'" '.. uid )
			end):SetImage(hook.Run("GetUserIcon", client) or icon)
		end
	end,
	onRun = function(client, arguments)
		local steamID = arguments[1]
		local group = arguments[2] or "user"

		if (!steamID) then
			nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

			return
		end

		local target

		-- If a player's name is passed since it is not a valid SteamID.
		if (!string.find(steamID, "STEAM_0:[01]:[0-9]+")) then
			target = nut.command.FindPlayer(client, steamID)

			if (!IsValid(target)) then
				return
			end

			steamID = target:SteamID()
		end

		PLUGIN:SetUserGroup(steamID, group, target)
		nut.util.Notify(client:Name().." has set the group of "..(IsValid(target) and target:Name() or steamID).." to "..group..".")
	end
}, "rank")

if (SERVER) then
	concommand.Add("nut_setowner", function(client, command, arguments)
		if (!IsValid(client) or (IsValid(client) and client:IsListenServerHost())) then
			local steamID = arguments[1]

			if (!steamID) then
				print("You did not provide a valid player or SteamID.")

				return
			end

			local target

			-- If a player's name is passed since it is not a valid SteamID.
			if (!string.find(steamID, "STEAM_0:[01]:[0-9]+")) then
				target = nut.util.FindPlayer(steamID)

				if (!IsValid(target)) then
					print("You did not provide a valid player.")

					return
				end

				steamID = target:SteamID()
			end

			PLUGIN:SetUserGroup(steamID, "owner", target)
			print("You have made "..(IsValid(target) and target:Name() or steamID).." an owner.")

			if (IsValid(target)) then
				nut.util.Notify("You have been made an owner by the server console.", target)
			end
		else
			client:ChatPrint("You may only access this command by the server console or the player running a listen server.")
		end
	end)
end
