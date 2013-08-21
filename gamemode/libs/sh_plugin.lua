--[[
	Purpose: Library to load plugins from the framework and schema and retrieve
	plugins that have been loaded.
--]]

nut.plugin = nut.plugin or {}
nut.plugin.buffer = nut.plugin.buffer or {}


function nut.plugin.IncludeEntities(directory)
	local entityFiles, entityFolders = file.Find(directory.."/entities/entities/*", "LUA")

	for k, v in pairs(entityFolders) do
		ENT = {}
			ENT.ClassName = v
			nut.util.Include(directory.."/entities/entities/"..ENT.ClassName.."/init.lua", "server")
			nut.util.Include(directory.."/entities/entities/"..ENT.ClassName.."/cl_init.lua")
			scripted_ents.Register(ENT, ENT.ClassName)
		ENT = nil
	end

	for k, v in pairs(entityFiles) do
		ENT = {}
			ENT.ClassName = string.sub(v, 1, -5)
			nut.util.Include(directory.."/entities/entities/"..ENT.ClassName..".lua", "shared")
			scripted_ents.Register(ENT, ENT.ClassName)
		ENT = nil
	end
end

function nut.plugin.IncludeWeapons(directory)
	local weaponFiles, weaponFolders = file.Find(directory.."/entities/weapons/*", "LUA")

	for k, v in pairs(weaponFolders) do
		SWEP = {}
			SWEP.Folder = v
			SWEP.Base = "weapon_base"
			nut.util.Include(directory.."/entities/weapons/"..SWEP.Folder.."/init.lua", "server")
			nut.util.Include(directory.."/entities/weapons/"..SWEP.Folder.."/cl_init.lua")
			weapons.Register(SWEP, SWEP.ClassName)
		SWEP = nil
	end

	for k, v in pairs(weaponFiles) do
		SWEP = {
			Primary = {},
			Secondary = {}
		}
			SWEP.Folder = string.sub(v, 1, -5)
			SWEP.Base = "weapon_base"

			nut.util.Include(directory.."/entities/weapons/"..v, "shared")
			weapons.Register(SWEP, SWEP.Folder)
		SWEP = nil
	end
end

function nut.plugin.IncludeEffects(directory)
	local effectFiles, effectFolders = file.Find(directory.."/entities/effects/*", "LUA")

	for k, v in pairs(effectFolders) do
		EFFECT = {}
			EFFECT.ClassName = v
			nut.util.Include(directory.."/entities/effects/"..EFFECT.ClassName.."/init.lua", "server")
			nut.util.Include(directory.."/entities/effects/"..EFFECT.ClassName.."/cl_init.lua")
			effects.Register(EFFECT, EFFECT.ClassName)
		EFFECT = nil
	end

	for k, v in pairs(effectFiles) do
		EFFECT = {}
			EFFECT.ClassName = string.sub(v, 1, -4)
			nut.util.Include(directory.."/entities/effects/"..EFFECT.ClassName..".lua", "shared")
			effect.Register(EFFECT, EFFECT.ClassName)
		EFFECT = nil
	end
end

--[[
	Purpose: Searches for directories within the given base directory and registers
	a plugin based off the name of the directories within. After that, each individual
	file inside plugins/ will be included. Anything between sh_ and .lua will be the
	plugin's unique id.
--]]
function nut.plugin.Load(directory)
	local files, folders = file.Find(directory.."/plugins/*", "LUA")

	for k, v in pairs(folders) do
		PLUGIN = nut.plugin.Get(v) or {}
			function PLUGIN:WriteTable(data, ignoreMap, global)
				return nut.util.WriteTable(v, value, ignoreMap, global)
			end

			function PLUGIN:ReadTable(ignoreMap, forceRefresh)
				return nut.util.ReadTable(v, ignoreMap, forceRefresh)
			end

			nut.util.Include(directory.."/plugins/"..v.."/sh_plugin.lua")

			local pluginDir = directory.."/plugins/"..v
			nut.plugin.IncludeEntities(pluginDir)
			nut.plugin.IncludeWeapons(pluginDir)
			nut.plugin.IncludeEffects(pluginDir)

			nut.item.Load(pluginDir)
			nut.plugin.buffer[v] = PLUGIN
		PLUGIN = nil
	end

	for k, v in pairs(files) do
		local cleanName = string.sub(v, 4, -5)

		PLUGIN = nut.plugin.Get(cleanName) or {}
			function PLUGIN:WriteTable(data, ignoreMap, global)
				return nut.util.WriteTable(cleanName, value, ignoreMap, global)
			end

			function PLUGIN:ReadTable(ignoreMap, forceRefresh)
				return nut.util.ReadTable(cleanName, ignoreMap, forceRefresh)
			end

			nut.util.Include(directory.."/plugins/"..v)
			nut.plugin.buffer[cleanName] = PLUGIN
		PLUGIN = nil
	end
end

--[[
	Purpose: Retrieves all of the registered plugins.
--]]
function nut.plugin.GetAll()
	return nut.plugin.buffer
end

--[[
	Purpose: Returns a plugin's table based off the uniqueID given.
--]]
function nut.plugin.Get(uniqueID)
	return nut.plugin.buffer[uniqueID]
end

if (CLIENT) then
	hook.Add("BuildHelpOptions", "nut_PluginHelp", function(data)
		data:AddHelp("Plugins", function()
			local html = ""

			for k, v in SortedPairs(nut.plugin.buffer) do
				html = html.."<p><b>"..(v.name or k).."</b><br /><i>Author:</i> "..(v.author or "Anonymous").."<br /><i>Description:</i> "..v.desc or nut.lang.Get("no_desc").."</p>"
			end

			return html
		end)
	end)
end