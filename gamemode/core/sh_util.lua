function nut.util.include(fileName, state)
	if ((state == "server" or fileName:find("sv_")) and SERVER) then
		include(fileName)
	elseif (state == "shared" or fileName:find("sh_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end

		include(fileName)
	elseif (state == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

function nut.util.includeDir(directory)
	local baseDir = "nutscript"

	if (SCHEMA and SCHEMA.folder and GM and GM.FolderName != "nutscript") then
		baseDir = SCHEMA.folder
	end

	for k, v in ipairs(file.Find(baseDir.."/gamemode/"..directory.."/*.lua", "LUA")) do
		nut.util.include(directory.."/"..v)
	end
end

function nut.util.getMaterial(materialPath)
	nut.util.cachedMaterials = nut.util.cachedMaterials or {}
	nut.util.cachedMaterials[materialPath] = nut.util.cachedMaterials[materialPath] or Material(materialPath)

	return nut.util.cachedMaterials[materialPath]
end