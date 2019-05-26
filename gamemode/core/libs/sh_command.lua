
--[[--
Registration, parsing, and handling of commands.

Commands can be ran through the chat with slash commands or they can be executed through the console. Commands can be manually
restricted to certain usergroups using a [CAMI](https://github.com/glua/CAMI)-compliant admin mod.
]]
-- @module ix.command

--- When registering commands with `ix.command.Add`, you'll need to pass in a valid command structure. This is simply a table
-- with various fields defined to describe the functionality of the command.
-- @realm shared
-- @table CommandStructure
-- @field[type=function] OnRun This function is called when the command has passed all the checks and can execute. The first two
-- arguments will be the running command table and the calling player. If the arguments field has been specified, the arguments
-- will be passed as regular function parameters rather than in a table.
--
-- When the arguments field is defined: `OnRun(self, client, target, length, message)`
--
-- When the arguments field is NOT defined: `OnRun(self, client, arguments)`
-- @field[type=string,opt="@noDesc"] description The help text that appears when the user types in the command. If the string is
-- prefixed with `"@"`, it will use a language phrase.
-- @field[type=table,opt=nil] argumentNames An array of strings corresponding to each argument of the command. This ignores the
-- name that's specified in the `OnRun` function arguments and allows you to use any string to change the text that displays
-- in the command's syntax help. When using this field, make sure that the amount is equal to the amount of arguments, as such:
-- 	COMMAND.arguments = {ix.type.character, ix.type.number}
-- 	COMMAND.argumentNames = {"target char", "cash (1-1000)"}
-- @field[type=table,opt] arguments If this field is defined, then additional checks will be performed to ensure that the
-- arguments given to the command are valid. This removes extra boilerplate code since all the passed arguments are guaranteed
-- to be valid. See `CommandArgumentsStructure` for more information.
-- @field[type=boolean,opt=false] adminOnly Provides an additional check to see if the user is an admin before running.
-- @field[type=boolean,opt=false] superAdminOnly Provides an additional check to see if the user is a superadmin before running.
-- @field[type=string,opt=nil] privilege Manually specify a privilege name for this command. It will always be prefixed with
-- `"Helix - "`. This is used in the case that you want to group commands under the same privilege, or use a privilege that
-- you've already defined (i.e grouping `/CharBan` and `/CharUnban` into the `Helix - Ban Character` privilege).
-- @field[type=function,opt=nil] OnCheckAccess This callback checks whether or not the player is allowed to run the command.
-- This callback should **NOT** be used in conjunction with `adminOnly` or `superAdminOnly`, as populating those
-- fields create a custom a `OnCheckAccess` callback for you internally. This is used in cases where you want more fine-grained
-- access control for your command.
--
-- Keep in mind that this is a **SHARED** callback; the command will not show up the client if the callback returns `false`.

--- Rather than checking the validity for arguments in your command's `OnRun` function, you can have Helix do it for you to
-- reduce the amount of boilerplate code that needs to be written. This can be done by populating the `arguments` field.
--
-- When using the `arguments` field in your command, you are specifying specific types that you expect to receive when the
-- command is ran successfully. This means that before `OnRun` is called, the arguments passed to the command from a user will
-- be verified to be valid. Each argument is an `ix.type` entry that specifies the expected type for that argument. Optional
-- arguments can be specified by using a bitwise OR with the special `ix.type.optional` type. When specified as optional, the
-- argument can be `nil` if the user has not entered anything for that argument - otherwise it will be valid.
--
-- Note that optional arguments must always be at the end of a list of arguments - or rather, they must not follow a required
-- argument. The `syntax` field will be automatically populated when using strict arguments, which means you shouldn't fill out
-- the `syntax` field yourself. The arguments you specify will have the same names as the arguments in your OnRun function.
--
-- Consider this example command:
-- 	ix.command.Add("CharSlap", {
-- 		description = "Slaps a character with a large trout.",
-- 		adminOnly = true,
-- 		arguments = {
-- 			ix.type.character,
-- 			bit.bor(ix.type.number, ix.type.optional)
-- 		},
-- 		OnRun = function(self, client, target, damage)
-- 			-- WHAM!
-- 		end
-- 	})
-- Here, we've specified the first argument called `target` to be of type `character`, and the second argument called `damage`
-- to be of type `number`. The `damage` argument is optional, meaning that the command will still run if the user has not
-- specified any value for the damage. In this case, we'll need to check if it was specified by doing a simple
-- `if (damage) then`. The syntax field will be automatically populated with the value `"<target: character> [damage: number]"`.
-- @realm shared
-- @table CommandArgumentsStructure

ix.command = ix.command or {}
ix.command.list = ix.command.list or {}

local COMMAND_PREFIX = "/"

local function ArgumentCheckStub(command, client, given)
	local arguments = command.arguments
	local result = {}

	for i = 1, #arguments do
		local bOptional = bit.band(arguments[i], ix.type.optional) == ix.type.optional
		local argType = bOptional and bit.bxor(arguments[i], ix.type.optional) or arguments[i]
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
			local bPlayer = argType == ix.type.player
			local value = ix.util.FindPlayer(argument)

			-- FindPlayer emits feedback for us
			if (!value and !bOptional) then
				return L(bPlayer and "plyNoExist" or "charNoExist", client)
			end

			-- check for the character if we're using the character type
			if (!bPlayer) then
				local character = value:GetCharacter()

				if (!character) then
					return L("charNoExist", client)
				end

				value = character
			end

			result[#result + 1] = value
		elseif (argType == ix.type.steamid) then
			local value = argument:match("STEAM_(%d+):(%d+):(%d+)")

			if (!value and bOptional) then
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

--- Creates a new command.
-- @realm shared
-- @string command Name of the command (recommended in UpperCamelCase)
-- @tparam CommandStructure data Data describing the command
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

	-- OnCheckAccess by default will rely on CAMI for access information with adminOnly/superAdminOnly being fallbacks
	if (!data.OnCheckAccess) then
		if (data.group) then
			ErrorNoHalt("Command '" .. data.name .. "' tried to use the deprecated field 'group'!\n")
			return
		end

		local privilege = "Helix - " .. (isstring(data.privilege) and data.privilege or data.name)

		-- we could be using a previously-defined privilege
		if (!CAMI.GetPrivilege(privilege)) then
			CAMI.RegisterPrivilege({
				Name = privilege,
				MinAccess = data.superAdminOnly and "superadmin" or (data.adminOnly and "admin" or "user"),
				Description = data.description
			})
		end

		function data:OnCheckAccess(client)
			local bHasAccess, _ = CAMI.PlayerHasAccess(client, privilege, nil)
			return bHasAccess
		end
	end

	-- if we have an arguments table, then we're using the new command format
	if (data.arguments) then
		local bFirst = true
		local bLastOptional = false
		local bHasArgumentNames = istable(data.argumentNames)

		data.syntax = "" -- @todo deprecate this in favour of argumentNames
		data.argumentNames = bHasArgumentNames and data.argumentNames or {}

		-- if one argument is supplied by itself, put it into a table
		if (!istable(data.arguments)) then
			data.arguments = {data.arguments}
		end

		if (bHasArgumentNames and #data.argumentNames != #data.arguments) then
			return ErrorNoHalt(string.format(
				"Command '%s' doesn't have argument names that correspond to each argument\n", command
			))
		end

		-- check the arguments table to see if its entries are valid
		for i = 1, #data.arguments do
			local argument = data.arguments[i]
			local argumentName = debug.getlocal(data.OnRun, 2 + i)

			if (argument == ix.type.optional) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use an optional argument for #%d without specifying type\n", command, i
				))
			elseif (!isnumber(argument)) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use an invalid type for argument #%d\n", command, i
				))
			elseif (argument == ix.type.array or bit.band(argument, ix.type.array) > 0) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use an unsupported type 'array' for argument #%d\n", command, i
				))
			end

			local bOptional = bit.band(argument, ix.type.optional) > 0
			argument = bOptional and bit.bxor(argument, ix.type.optional) or argument

			if (!ix.type[argument]) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use an invalid type for argument #%d\n", command, i
				))
			elseif (!isstring(argumentName)) then
				return ErrorNoHalt(string.format(
					"Command '%s' is missing function argument for command argument #%d\n", command, i
				))
			elseif (argument == ix.type.text and i != #data.arguments) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use a text argument outside of the last argument\n", command
				))
			elseif (!bOptional and bLastOptional) then
				return ErrorNoHalt(string.format(
					"Command '%s' tried to use an required argument after an optional one\n", command
				))
			end

			-- text is always optional and will return an empty string if nothing is specified, rather than nil
			if (argument == ix.type.text) then
				data.arguments[i] = bit.bor(ix.type.text, ix.type.optional)
				bOptional = true
			end

			if (!bHasArgumentNames) then
				data.argumentNames[i] = argumentName
			end

			data.syntax = data.syntax .. (bFirst and "" or " ") ..
				string.format((bOptional and "[%s: %s]" or "<%s: %s>"), argumentName, ix.type[argument])

			bFirst = false
			bLastOptional = bOptional
		end

		if (data.syntax:len() == 0) then
			data.syntax = "<none>"
		end
	else
		data.syntax = data.syntax or "<none>"
	end

	-- Add the command to the list of commands.
	local alias = data.alias

	if (alias) then
		if (istable(alias)) then
			for _, v in ipairs(alias) do
				ix.command.list[v:lower()] = data
			end
		elseif (isstring(alias)) then
			ix.command.list[alias:lower()] = data
		end
	end

	ix.command.list[command] = data
end

--- Returns true if a player is allowed to run a certain command.
-- @realm shared
-- @player client Player to check access for
-- @string command Name of the command to check access for
-- @treturn bool Whether or not the player is allowed to run the command
function ix.command.HasAccess(client, command)
	command = ix.command.list[command:lower()]

	if (command) then
		if (command.OnCheckAccess) then
			return command:OnCheckAccess(client)
		else
			return true
		end
	end

	return false
end

--- Returns a table of arguments from a given string.
-- Words separated by spaces will be considered one argument. To have an argument containing multiple words, they must be
-- contained within quotation marks.
-- @realm shared
-- @string text String to extract arguments from
-- @treturn table Arguments extracted from string
-- @usage PrintTable(ix.command.ExtractArgs("these are \"some arguments\""))
-- > 1 = these
-- > 2 = are
-- > 3 = some arguments
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

--- Returns an array of potential commands by unique id.
-- When bSorted is true, the commands will be sorted by name. When bReorganize is true, it will move any exact match to the top
-- of the array. When bRemoveDupes is true, it will remove any commands that have the same NAME.
-- @realm shared
-- @string identifier Search query
-- @bool[opt=false] bSorted Whether or not to sort the commands by name
-- @bool[opt=false] bReorganize Whether or not any exact match will be moved to the top of the array
-- @bool[opt=false] bRemoveDupes Whether or not to remove any commands that have the same name
-- @treturn table Array of command tables whose name partially or completely matches the search query
function ix.command.FindAll(identifier, bSorted, bReorganize, bRemoveDupes)
	local result = {}
	local iterator = bSorted and SortedPairs or pairs
	local fullMatch

	identifier = identifier:lower()

	if (identifier == "/") then
		-- we don't simply copy because we need numeric indices
		for _, v in iterator(ix.command.list) do
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

	if (bReorganize and fullMatch and fullMatch != 1) then
		result[1], result[fullMatch] = result[fullMatch], result[1]
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

	return result
end

if (SERVER) then
	util.AddNetworkString("ixCommand")

	--- Attempts to find a player by an identifier. If unsuccessful, a notice will be displayed to the specified player. The
	-- search criteria is derived from `ix.util.FindPlayer`.
	-- @realm server
	-- @player client Player to give a notification to if the player could not be found
	-- @string name Search query
	-- @treturn[1] player Player that matches the given search query
	-- @treturn[2] nil If a player could not be found
	-- @see ix.util.FindPlayer
	function ix.command.FindPlayer(client, name)
		local target = isstring(name) and ix.util.FindPlayer(name) or NULL

		if (IsValid(target)) then
			return target
		else
			client:NotifyLocalized("plyNoExist")
		end
	end

	--- Forces a player to execute a command by name.
	-- @realm server
	-- @player client Player who is executing the command
	-- @string command Full name of the command to be executed. This string gets lowered, but it's good practice to stick with
	-- the exact name of the command
	-- @tab arguments Array of arguments to be passed to the command
	-- @usage ix.command.Run(player.GetByID(1), "Roll", {10})
	function ix.command.Run(client, command, arguments)
		if ((client.ixCommandCooldown or 0) > RealTime()) then
			return
		end

		command = ix.command.list[tostring(command):lower()]

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
			local bSuccess, phrase = command:OnCheckAccess(client)
			feedback = !bSuccess and L(phrase and phrase or "noPerm", client) or nil
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

			client.ixCommandCooldown = RealTime() + 0.5

			if (IsValid(client)) then
				ix.log.Add(client, "command", COMMAND_PREFIX .. command.name, argumentsTable and table.concat(argumentsTable, " "))
			end
		else
			client:Notify(feedback)
		end
	end

	--- Parses a chat string and runs the command if one is found. Specifically, it checks for commands in a string with the
	-- format `/CommandName some arguments`
	-- @realm server
	-- @player client Player who is executing the command
	-- @string text Input string to search for the command format
	-- @string[opt] realCommand Specific command to check for. If this is specified, it will not try to run any command that's
	-- found at the beginning - only if it matches `realCommand`
	-- @tab[opt] arguments Array of arguments to pass to the command. If not specified, it will try to extract it from the
	-- string specified in `text` using `ix.command.ExtractArgs`
	-- @treturn bool Whether or not a command has been found
	-- @usage ix.command.Parse(player.GetByID(1), "/roll 10")
	function ix.command.Parse(client, text, realCommand, arguments)
		if (realCommand or text:utf8sub(1, 1) == COMMAND_PREFIX) then
			-- See if the string contains a command.

			local match = realCommand or text:lower():match(COMMAND_PREFIX.."([_%w]+)")

			-- is it unicode text?
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

	net.Receive("ixCommand", function(length, client)
		if ((client.ixNextCmd or 0) < CurTime()) then
			local command = net.ReadString()
			local indices = net.ReadUInt(4)
			local arguments = {}

			for _ = 1, indices do
				local value = net.ReadType()

				if (isstring(value) or isnumber(value)) then
					arguments[#arguments + 1] = tostring(value)
				end
			end

			ix.command.Parse(client, nil, command, arguments)
			client.ixNextCmd = CurTime() + 0.2
		end
	end)
else
	--- Request the server to run a command. This mimics similar functionality to the client typing `/CommandName` in the chatbox.
	-- @realm client
	-- @string command Unique ID of the command
	-- @param ... Arguments to pass to the command
	-- @usage ix.command.Send("roll", 10)
	function ix.command.Send(command, ...)
		local arguments =  {...}

		net.Start("ixCommand")
		net.WriteString(command)
		net.WriteUInt(#arguments, 4)

		for _, v in ipairs(arguments) do
			net.WriteType(v)
		end

		net.SendToServer()
	end
end
