
--[[--
This library handles the registration, parsing, and handling of commands.

Commands can be ran through the chat with slash commands or they can be executed through the console.

## Command structure
When registering commands with `ix.command.Add`, you'll need to pass in a valid command structure. This is simply a table with
various fields defined. The fields you can specify are as follows:

<ul>
<li><p>
`description`<br />
(default: `"@noDesc"`)<br />
The help text that appears when the user types in the command.
</p></li>


<li><p>
`syntax`<br />
(default: `"[none]"`)<br />
The arguments that your command accepts. This field is automatically populated when using the arguments field. Syntax strings
generally take the form of `"<type argumentName> [type optionalName]"` - it is recommended to stick to this format to keep
consistent with other commands.
</p></li>

<li><p>
`arguments`<br />
(optional)<br />
If this field is defined, then additional checks will be performed to ensure that the arguments given to the command are valid.
This removes extra boilerplate code since all the passed arguments are guaranteed to be valid. See the `Command arguments
structure` for more information.
</p></li>

<li><p>
`adminOnly`<br />
(default: `false`)<br />
Provides an additional check to see if the user is an admin before running.
</p></li>

<li><p>
`superAdminOnly`<br />
(default: `false`)<br />
Provides an additional check to see if the user is a superadmin before running.
</p></li>

<li><p>
`group`<br />
(default: `nil`)<br />
Provides an additional check to see if the user is part of the specified usergroup before running. This can be a string or
table of strings for allowing multiple groups to use the command.
</p></li>

<li><p>
`OnRun`<br />
(required)<br />
This function is called when the command has passed all the checks and can execute. The first two arguments will be the running
command table and the calling player. If the arguments field has been specified, the arguments will be passed as regular
function parameters rather than in a table.
When the `arguments` field is defined:
	OnRun(self, client, target, length, message)
When the `arguments` field is NOT defined:
	OnRun(self, client, arguments)
</p></li>
</ul>

## Command arguments structure
Rather than checking the validity for arguments in your command's `OnRun` function, you can have Helix do it for you to reduce
the amount of boilerplate code that needs to be written. This can be done by populating the `arguments` field.

When using the `arguments` field in your command, you are specifying specific types that you expect to receive when the command
is ran successfully. This means that before `OnRun` is called, the arguments passed to the command from a user will be verified
to be valid. Each argument is an array that holds at least two entries - the type, and the name of the variable. The third entry
is an optional bool that specifies whether or not the argument is optional. In this case, the argument can be nil if not
specified, otherwise it is valid.

Note that optional arguments must always be at the end of a list of arguments - or rather, they must not follow a required
argument. Here is an example:
	ix.command.Add("CharSlap", {
		description = "Slaps a character with a large trout.",
		adminOnly = true,
		arguments = {
			{ix.type.player, "target"},
			{ix.type.number, "damage", true}
		},
		OnRun = function(self, client, target, damage)
			-- WHAM!
		end
	})
Here, we've specified the first argument called `target` to be of type `player`, and the second argument called `damage` to be
of type `number`. The `damage` argument is optional, meaning that the command will still run if the user has not specified
any value for the damage. In this case, we'll need to check if it was specified by doing a simple `if (damage) then`.
]]
-- @module ix.command

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

--- Creates a new command.
-- @shared
-- @string command Name of the command (recommended in UpperCamelCase)
-- @table data Command structure (see above)
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

--- Returns true if a player is allowed to run a certain command.
-- @shared
-- @player client Player to check access for
-- @string command Name of the command to check access for
-- @treturn bool Whether or not the player is allowed to run the command
function ix.command.HasAccess(client, command)
	command = ix.command.list[command]

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
-- @shared
-- @string text String to extract arguments from
-- @treturn table Arguments extracted from string
-- @usage ix.command.ExtractArgs("these are \"some arguments\"")
-- > {"these", "are", "some arguments"}
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
-- @shared
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
	--- Attempts to find a player by an identifier. If unsuccessful, a notice will be displayed to the specified player. The
	-- search criteria is derived from `ix.util.FindPlayer`.
	-- @server
	-- @player client Player to give a notification to if the player could not be found
	-- @string name Search query
	-- @treturn player Player that matches the given search query - this will be `nil` if a player could not be found
	-- @see ix.util.FindPlayer
	function ix.command.FindPlayer(client, name)
		local target = type(name) == "string" and ix.util.FindPlayer(name) or NULL

		if (IsValid(target)) then
			return target
		else
			client:NotifyLocalized("plyNoExist")
		end
	end

	--- Forces a player to execute a command by name.
	-- @server
	-- @player client Player who is executing the command
	-- @string command Full name of the command to be executed. This string gets lowered, but it's good practice to stick with
	-- the exact name of the command
	-- @table arguments Array of arguments to be passed to the command
	-- @usage ix.command.Run(player.GetByID(1), "Roll", {10})
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

	--- Parses a chat string and runs the command if one is found. Specifically, it checks for commands in a string with the
	-- format `/CommandName some arguments`
	-- @server
	-- @player client Player who is executing the command
	-- @string text Input string to search for the command format
	-- @string[opt] realCommand Specific command to check for. If this is specified, it will not try to run any command that's
	-- found at the beginning - only if it matches `realCommand`
	-- @table[opt] arguments Array of arguments to pass to the command. If not specified, it will try to extract it from the
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
