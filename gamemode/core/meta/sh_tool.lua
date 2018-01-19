
local TOOL = ix.meta.tool or {}

-- code replicated from gamemodes/sandbox/entities/weapons/gmod_tool/stool.lua
function TOOL:Create()
	local object = {}

	setmetatable(object, self)
	self.__index = self

	object.Mode = nil
	object.SWEP = nil
	object.Owner = nil
	object.ClientConVar = {}
	object.ServerConVar = {}
	object.Objects = {}
	object.Stage = 0
	object.Message = "start"
	object.LastMessage = 0
	object.AllowedCVar = 0

	return object
end

function TOOL:CreateConVars()
	local mode = self:GetMode()

	if (CLIENT) then
		for cvar, default in pairs(self.ClientConVar) do
			CreateClientConVar(mode .. "_" .. cvar, default, true, true)
		end

		return
	end

	-- Note: I changed this from replicated because replicated convars don't work when they're created via Lua.
	if (SERVER) then
		self.AllowedCVar = CreateConVar("toolmode_allow_" .. mode, 1, FCVAR_NOTIFY)
	end
end

function TOOL:GetServerInfo(property)
	local mode = self:GetMode()
	return GetConVarString(mode .. "_" .. property)
end

function TOOL:BuildConVarList()
	local mode = self:GetMode()
	local convars = {}

	for k, v in pairs(self.ClientConVar) do
		convars[mode .. "_" .. k] = v
	end

	return convars
end

function TOOL:GetClientInfo(property)
	return self:GetOwner():GetInfo(self:GetMode() .. "_" .. property)
end

function TOOL:GetClientNumber(property, default)
	return self:GetOwner():GetInfoNum(self:GetMode() .. "_" .. property, tonumber(default) or 0)
end

function TOOL:Allowed()
	if (CLIENT) then
		return true
	end

	return self.AllowedCVar:GetBool()
end

-- Now for all the TOOL redirects
function TOOL:Init()
end

function TOOL:GetMode()
	return self.Mode
end

function TOOL:GetSWEP()
	return self.SWEP
end

function TOOL:GetOwner()
	return self:GetSWEP().Owner or self.Owner
end

function TOOL:GetWeapon()
	return self:GetSWEP().Weapon or self.Weapon
end

function TOOL:LeftClick()
	return false
end

function TOOL:RightClick()
	return false
end

function TOOL:Reload()
	self:ClearObjects()
end

function TOOL:Deploy()
	self:ReleaseGhostEntity()
	return
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	return
end

function TOOL:Think()
	self:ReleaseGhostEntity()
end

-- Checks the objects before any action is taken
-- This is to make sure that the entities haven't been removed
function TOOL:CheckObjects()
	for _, v in pairs(self.Objects) do
		if (!v.Ent:IsWorld() and !v.Ent:IsValid()) then
			self:ClearObjects()
		end
	end
end

ix.meta.tool = TOOL
