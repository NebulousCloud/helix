nut.command = nut.command or {}
nut.command.list = nut.command.list or {}

local COMMAND_PREFIX = "/"

-- Adds a new command to the list of commands.
function nut.command.Add(command, data)
	-- For showing users the arguments of the command.
	data.name = string.gsub(command, "%s", "")
	data.syntax = data.syntax or "[none]"

	-- Why bother adding a command if it doesn't do anything.
	if (!data.OnRun) then
		return ErrorNoHalt("Command '"..command.."' does not have a callback, not adding!\n")
	end

	-- Store the old OnRun because we're able to change it.
	if (!data.OnCheckAccess) then
		-- Check if the command is for basic admins only.
		if (data.adminOnly) then
			function data:OnCheckAccess(client)
				return client:IsAdmin()
			end
		-- Or if it is only for super administrators.
		elseif (data.superAdminOnly) then
			function data:OnCheckAccess(client)
				return client:IsSuperAdmin()
			end
		-- Or if we specify a usergroup allowed to use this.
		elseif (data.group) then
			-- The group property can be a table of usergroups.
			if (type(data.group) == "table") then
				function data:OnCheckAccess(client)
					-- Check if the client's group is allowed.
					for k, v in ipairs(self.group) do
						if (client:IsUserGroup(v)) then
							return true
						end
					end

					return false
				end
			-- Otherwise it is most likely a string.
			else
				function data:OnCheckAccess(client)
					return client:IsUserGroup(self.group)
				end
			end
		end
	end

	local OnCheckAccess = data.OnCheckAccess

	-- Only overwrite the OnRun to check for access if there is anything to check.
	if (OnCheckAccess) then
		local OnRun = data.OnRun
		data._OnRun = data.OnRun -- for refactoring purpose.

		function data:OnRun(client, arguments)
			if (!self:OnCheckAccess(client)) then
				return "@noPerm"
			else
				return OnRun(self, client, arguments)
			end
		end
	end

	-- Add the command to the list of commands.
	local alias = data.alias

	if (alias) then
		if (type(alias) == "table") then
			for k, v in ipairs(alias) do
				nut.command.list[v] = data
			end
		elseif (type(alias) == "string") then
			nut.command.list[alias] = data
		end
	end

	nut.command.list[string.lower(command)] = data
end

-- Returns whether or not a player is allowed to run a certain command.
function nut.command.HasAccess(client, command)
	command = nut.command.list[command]

	if (command) then
		if (command.OnCheckAccess) then
			return command.OnCheckAccess(client)
		else
			return true
		end
	end

	return false
end

-- Gets a table of arguments from a string.
function nut.command.ExtractArgs(text)
	local skip = 0
	local arguments = {}
	local curString = ""

	for i = 1, #text do
		if (i <= skip) then continue end

		local c = text:sub(i, i)

		if (c == "\"") then
			local match = text:sub(i):match("%b"..c..c)

			if (match) then
				curString = ""
				skip = i + #match
				arguments[#arguments + 1] = match:sub(2, -2)
			else
				curString = curString..c
			end
		elseif (c == " " and curString != "") then
			arguments[#arguments + 1] = curString
			curString = ""
		else
			if (c == " " and curString == "") then
				continue
			end

			curString = curString..c
		end
	end

	if (curString != "") then
		arguments[#arguments + 1] = curString
	end

	return arguments
end

if (SERVER) then
	-- Finds a player or gives an error notification.
	function nut.command.FindPlayer(client, name)
		local target = type(name) == "string" and nut.util.FindPlayer(name) or NULL

		if (IsValid(target)) then
			return target
		else
			client:NotifyLocalized("plyNoExist")
		end
	end

	-- Forces a player to run a command.
	function nut.command.Run(client, command, arguments)
		local command = nut.command.list[command]

		if (command) then
			-- Run the command's callback and get the return.
			local results = {command:OnRun(client, arguments or {})}
			local result = results[1]
			
			-- If a string is returned, it is a notification.
			if (isstring(result)) then
				-- Normal player here.
				if (IsValid(client)) then
					if (result:sub(1, 1) == "@") then
						client:NotifyLocalized(result:sub(2), unpack(results, 2))
					else
						client:Notify(result)
					end
				else
					-- Show the message in server console since we're running from RCON.
					print(result)
				end
			end

			if (IsValid(client)) then
				nut.log.Add(client, "command", COMMAND_PREFIX..command.name, table.concat(arguments, " "))
			end
		end
	end

	-- Add a function to parse a regular chat string.
	function nut.command.Parse(client, text, realCommand, arguments)
		if (realCommand or text:utf8sub(1, 1) == COMMAND_PREFIX) then
			-- See if the string contains a command.

			local match = realCommand or text:lower():match(COMMAND_PREFIX.."([_%w]+)")

			-- is it unicode text?
			-- i hate unicode.
			if (!match) then
				local post = string.Explode(" ", text)
				local len = string.len(post[1])

				match = post[1]:utf8sub(2, len)
			end

			match = match:lower()

			local command = nut.command.list[match]
			-- We have a valid, registered command.
			if (command) then
				-- Get the arguments like a console command.
				if (!arguments) then
					arguments = nut.command.ExtractArgs(text:sub(#match + 3))
				end

				-- Runs the actual command.
				nut.command.Run(client, match, arguments)
			else
				if (IsValid(client)) then
					client:NotifyLocalized("cmdNoExist")
				else
					print("Sorry, that command does not exist.")
				end
			end

			return true
		end

		return false
	end

	concommand.Add("nut", function(client, _, arguments)
		local command = arguments[1]
		table.remove(arguments, 1)

		nut.command.Parse(client, nil, command or "", arguments)
	end)

	netstream.Hook("cmd", function(client, command, arguments)
		if ((client.nutNextCmd or 0) < CurTime()) then
			local arguments2 = {}

			for k, v in ipairs(arguments) do
				if (isstring(v) or isnumber(v)) then
					arguments2[#arguments2 + 1] = tostring(v)
				end
			end

			nut.command.Parse(client, nil, command, arguments2)
			client.nutNextCmd = CurTime() + 0.2
		end
	end)
else
	function nut.command.Send(command, ...)
		netstream.Start("cmd", command, {...})
	end
end
