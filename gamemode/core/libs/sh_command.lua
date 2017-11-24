ix.command = ix.command or {}
ix.command.list = ix.command.list or {}

local COMMAND_PREFIX = "/"

-- Adds a new command to the list of commands.
function ix.command.Add(command, data)
	data.name = string.gsub(command, "%s", "")
	data.description = data.description or ""
	data.syntax = data.syntax or "[none]"

	command = command:lower()
	data.uniqueID = command

	-- Why bother adding a command if it doesn't do anything.
	if (!data.OnRun) then
		return ErrorNoHalt("Command '"..command.."' does not have a callback, not adding!\n")
	end

	-- Add a function to get the description that can be overridden.
	if (!data.GetDescription) then
		-- Check if the description is using a language string.
		if (data.description:sub(1, 1) == "@") then
			function data:GetDescription()
				return L(self.description:sub(2))
			end
		else
			-- Otherwise just return the raw description.
			function data:GetDescription()
				return self.description
			end
		end
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
				ix.command.list[v] = data
			end
		elseif (type(alias) == "string") then
			ix.command.list[alias] = data
		end
	end

	ix.command.list[command] = data
end

-- Returns whether or not a player is allowed to run a certain command.
function ix.command.HasAccess(client, command)
	command = ix.command.list[command]

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
function ix.command.ExtractArgs(text)
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

-- Returns an array of potential commands by unique id.
-- When bSorted is true, the commands will be sorted by name. When bReorganize is true,
-- it will move any exact match to the top of the array. When bRemoveDupes is true, it
-- will remove any commands that have the same NAME.
function ix.command.FindAll(identifier, bSorted, bReorganize, bRemoveDupes)
	local result = {}
	local iterator = bSorted and SortedPairs or pairs
	local fullMatch

	identifier = identifier:lower()

	if (identifier == "/") then
		-- we don't simply copy because we need numeric indices
		for k, v in iterator(ix.command.list) do
			result[#result + 1] = v
		end
		
		return result
	elseif (identifier:sub(1, 1) == "/") then
		identifier = identifier:sub(2)
	end

	for k, v in iterator(ix.command.list) do
		if (k:match(identifier)) then
			local index = #result + 1
			result[index] = v

			if (k == identifier) then
				fullMatch = index
			end
		end
	end

	if (bRemoveDupes) then
		local commandNames = {}

		-- using pairs intead of ipairs because we might remove from array
		for k, v in pairs(result) do
			if (commandNames[v.name]) then
				table.remove(result, k)
			end

			commandNames[v.name] = true
		end
	end

	if (bReorganize and fullMatch and fullMatch != 1) then
		result[1], result[fullMatch] = result[fullMatch], result[1]
	end
	
	return result
end

if (SERVER) then
	-- Finds a player or gives an error notification.
	function ix.command.FindPlayer(client, name)
		local target = type(name) == "string" and ix.util.FindPlayer(name) or NULL

		if (IsValid(target)) then
			return target
		else
			client:NotifyLocalized("plyNoExist")
		end
	end

	-- Forces a player to run a command.
	function ix.command.Run(client, command, arguments)
		local command = ix.command.list[command]

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
				ix.log.Add(client, "command", COMMAND_PREFIX..command.name, arguments and table.concat(arguments, " "))
			end
		end
	end

	-- Add a function to parse a regular chat string.
	function ix.command.Parse(client, text, realCommand, arguments)
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

			local command = ix.command.list[match]
			-- We have a valid, registered command.
			if (command) then
				-- Get the arguments like a console command.
				if (!arguments) then
					arguments = ix.command.ExtractArgs(text:sub(#match + 3))
				end

				-- Runs the actual command.
				ix.command.Run(client, match, arguments)
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

	concommand.Add("ix", function(client, _, arguments)
		local command = arguments[1]
		table.remove(arguments, 1)

		ix.command.Parse(client, nil, command or "", arguments)
	end)

	netstream.Hook("cmd", function(client, command, arguments)
		if ((client.ixNextCmd or 0) < CurTime()) then
			local arguments2 = {}

			for k, v in ipairs(arguments) do
				if (isstring(v) or isnumber(v)) then
					arguments2[#arguments2 + 1] = tostring(v)
				end
			end

			ix.command.Parse(client, nil, command, arguments2)
			client.ixNextCmd = CurTime() + 0.2
		end
	end)
else
	function ix.command.Send(command, ...)
		netstream.Start("cmd", command, {...})
	end
end
