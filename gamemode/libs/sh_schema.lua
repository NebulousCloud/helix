--[[
	Purpose: Library for schemas functions and overwriting the hook
	system to include schema hooks before framework hooks.
--]]

if (!nut.plugin) then
	include("sh_plugin.lua")
end

nut.schema = nut.schema or {}

--[[
	Purpose: Will define a schema table when the gamemode loads and
	provides some variables such as the name to be used on the game
	description. It also includes sh_schema which will be used to
	include other files and define custom schema names, authors, etc.
--]]
function nut.schema.Init()
	SCHEMA = SCHEMA or {
		name = "Sample",
		author = "Chessnut",
		desc = "An example schema!",
		uniqueID = GM.FolderName,
		folderName = GM.FolderName
	}

	nut.util.IncludeDir("schema/libs")
	nut.util.Include("schema/sh_schema.lua")
	
	nut.faction.Load(SCHEMA.folderName.."/gamemode/schema")
	nut.class.Load(SCHEMA.folderName.."/gamemode/schema")
	
	nut.util.IncludeDir("schema/derma")

	nut.plugin.Load(SCHEMA.folderName)
	nut.plugin.Load(NSFolderName) -- Load plugins relative to the framework's folder, done here to allow schemas to block base plugins
	
	nut.item.Load(SCHEMA.folderName.."/gamemode/schema")

	hook.Run("SchemaInitialized")
end

--[[
	Purpose: Similar to hook.Call, calls a hook in the schema and uses the returns
	whatever was returned by the hook itself.
--]]

local unpack = unpack

function nut.schema.Call(name, ...)
	if (name == "PlayerSpawn") then
		local arguments = {...}
		local client = arguments[1]

		if (IsValid(client) and !client.character) then
			return
		end
	end

	if (nut.plugin) then
		for k, v in pairs(nut.plugin.GetAll()) do
			if (v[name]) then
				local result = {v[name](v, ...)}

				if (#result > 0) then
					return unpack(result)
				end
			end
		end
	end

	if (SCHEMA and SCHEMA[name]) then
		local result = {SCHEMA[name](SCHEMA, ...)}

		if (#result > 0) then
			return unpack(result)
		end
	end

	if (nut and nut[name]) then
		local result = {nut[name](nut, ...)}

		if (#result > 0) then
			return unpack(result)
		end
	end
end

-- Backup the old hook.Call function.
hook.NutCall = hook.NutCall or hook.Call

--[[
	Purpose: Will overwrite hook.Call so it checks if the schema contains a hook
	and runs it before the framework since if GM was used for the schema, all hooks
	would need to refer to the BaseClass, which is the framework.
--]]
function hook.Call(name, gamemode, ...)
	if (name == "PlayerSpawn") then
		local arguments = {...}
		local client = arguments[1]

		if (IsValid(client) and !client.character) then
			return
		end
	end

	if (nut.plugin) then
		for k, v in pairs(nut.plugin.GetAll()) do
			if (v[name]) then
				local result = v[name](v, ...)

				if (result != nil) then
					return result
				end
			end
		end
	end

	if (SCHEMA and SCHEMA[name]) then
		local result = SCHEMA[name](SCHEMA, ...)

		if (result != nil) then
			return result
		end
	end

	return hook.NutCall(name, gamemode, ...)
end