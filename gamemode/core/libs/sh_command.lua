
ix.command = ix.command or {}
ix.command.list = ix.command.list or {}

local COMMAND_PREFIX = "/"

local function ArgumentCheckStub(command, client, given)
	local arguments = command.arguments
	local result = {}

	for i = 1, #arguments do
		local argType = arguments[i][1]
		local bOptional = arguments[i][3]
		local argument = given[i]

		if (!argument and !bOptional) then
			return L("invalidArg", client, i)
		end

		if (argType == ix.type.string) then
			if (!argument and bOptional) then
				result[#result + 1] = nil
			else
				result[#result + 1] = tostring(argument)
			end
		elseif (argType == ix.type.text) then
			result[#result + 1] = table.concat(given, " ", i) or ""
			break
		elseif (argType == ix.type.number) then
			local value = tonumber(argument)

			if (!bOptional and !value) then
				return L("invalidArg", client, i)
			end

			result[#result + 1] = value
		elseif (argType == ix.type.player or argType == ix.type.character) then
			local value = ix.command.FindPlayer(client, argument)

			-- FindPlayer emits feedback for us
			if (!value and !bOptional) then
				return
			end

			-- check for the character if we're using the character type
			if (argType == ix.type.character) then
				local character = value:GetCharacter()

				if (!character) then
					return L("charNoExist", client)
				end

				value = character
			end

			result[#result + 1] = value
		elseif (argType == ix.type.steamid) then
			local result = argument:match("STEAM_(%d+):(%d+):(%d+)")

			if (!result and bOptional) then
				return L("invalidArg", client, i)
			end

			result[#result + 1] = value
		elseif (argType == ix.type.bool) then
			if (argument == nil and bOptional) then
				result[#result + 1] = nil
			else
				result[#result + 1] = tobool(argument)
			end
		end
	end

	return result
end

--[[
	Adds a new command to the list of commands. You can specify the following fields:
		description (default: "@noDesc")
			The help text that appears when the user types in the command.
		syntax (default: "[none]")
			The arguments that your command accepts. This field is automatically
			populated when using the arguments field. Syntax strings generally take
			the form of "<type argumentName> [type optionalName]" - it is recommended
			to stick to this format to keep consistent with other commands.
		arguments (optional)
			If this field is defined, then additional checks will be performed to ensure
			that the arguments given to the command are valid. This removes extra
			boilerplate code since all the passed arguments are guaranteed to be valid.
		adminOnly (default: false)
			Provides an additional check to see if the user is an admin before running.
		superAdminOnly (default: false)
			Provides an additional check to see if the user is a superadmin before
			running.
		group (default: nil)
			Provides an additional check to see if the user is part of the specified
			usergroup before running. This can be a string or table of strings for
			allowing multiple groups to use the command.
		OnRun (required)
			This function is called when the command has passed all the checks and
			can execute. The first two arguments will be the running command table
			and the calling player. If the arguments field has been specified, the
			arguments will be passed as regular upvalues rather than a table.
			When the arguments table is defined:
				OnRun(self, client, target, length, message)
			When the arguments table is NOT defined:
				OnRun(self, client, arguments)

	The format for the arguments table is as follows:
		arguments = {
			{ix.type.player, "target"}
			{ix.type.number, "length"}
			{ix.type.text, "message", true}
		}
	The types are defined in the ix.type table above. The first argument in the table
	is the type, followed by the name of the argument. The third argument is an optional
	bool that specifies whether or not that argument is optional. Optional arguments must
	always be at the end of a list of arguments - or rather, they must not follow a
	required argument. Optional arguments will either be nil or a valid argument. This
	means you must check for nil in your OnRun method when dealing with optional arguments.
	You may specify one argument instead of a table of arguments if you only have one
	argument that you wish to define. For example:
		arguments = {ix.type.number, "length"}
]]--
function ix.command.Add(command, data)
	data.name = string.gsub(command, "%s", "")
	data.description = data.description or ""

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

	-- if no access checking is specified, we'll generate one based on the
	-- populated fields for admin/superadmin/group
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

	-- if we have an arguments table, then we're using the new command format
	if (data.arguments) then
		local bFirst = true
		local bLastOptional = false
		data.syntax = ""

		-- if one argument is supplied by itself, put it into a table
		if (!istable(data.arguments[1])) then
			local argument = data.arguments
			data.arguments = {argument}
		end

		-- check the arguments table to see if its entries are valid
		for i = 1, #data.arguments do
			local argument = data.arguments[i]

			if (!isnumber(argument[1]) or !ix.type[argument[1]]) then
				return ErrorNoHalt(string.format("Command '%s' tried to use an invalid type for an argument\n", command))
			elseif (!isstring(argument[2])) then
				return ErrorNoHalt(string.format("Command '%s' tried to use a non-string key for an argument\n", command))
			elseif (argument[1] == ix.type.text and i != #data.arguments) then
				return ErrorNoHalt(string.format("Command '%s' tried to use a text argument outside of the last argument\n", command))
			elseif (!argument[3] and bLastOptional) then
				return ErrorNoHalt(string.format("Command '%s' tried to use an required argument after an optional one\n", command))
			end

			-- text is always optional and will return an empty string if nothing is specified, rather than nil
			if (argument[1] == ix.type.text) then
				argument[3] = true
			end

			data.syntax = data.syntax .. (bFirst and "" or " ") .. string.format((argument[3] and "[%s %s]" or "<%s %s>"), ix.type[argument[1]], argument[2])

			bFirst = false
			bLastOptional = argument[3]
		end

		if (data.syntax:len() == 0) then
			data.syntax = "[none]"
		end
	else
		data.syntax = data.syntax or "[none]"
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
		local command = ix.command.list[tostring(command):lower()]

		if (!command) then
			return
		end

		-- we throw it into a table since arguments get unpacked and only
		-- the arguments table gets passed in by default
		local argumentsTable = arguments
		arguments = {argumentsTable}

		-- if feedback is non-nil, we can assume that the command failed
		-- and is a phrase string
		local feedback

		-- check for group access
		if (command.OnCheckAccess) then
			feedback = !command:OnCheckAccess(client) and "@noPerm" or nil
		end

		-- check for strict arguments
		if (!feedback and command.arguments) then
			arguments = ArgumentCheckStub(command, client, argumentsTable)

			if (isstring(arguments)) then
				feedback = arguments
			end
		end

		-- run the command if all the checks passed
		if (!feedback) then
			local results = {command:OnRun(client, unpack(arguments))}
			local phrase = results[1]

			-- check to see if the command has returned a phrase string and display it
			if (isstring(phrase)) then
				if (IsValid(client)) then
					if (phrase:sub(1, 1) == "@") then
						client:NotifyLocalized(phrase:sub(2), unpack(results, 2))
					else
						client:Notify(phrase)
					end
				else
					-- print message since we're running from the server console
					print(phrase)
				end
			end

			if (IsValid(client)) then
				ix.log.Add(client, "command", COMMAND_PREFIX .. command.name, argumentsTable and table.concat(argumentsTable, " "))
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
