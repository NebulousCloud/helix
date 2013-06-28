--[[
	Purpose: The framework needs to define this so the schemas can reference
	the framework without GM.BaseClass since it the baseclass is not defined in time.
--]]

-- Define this so the SCHEMA knows what the baseclass is, since self.BaseClass isn't
-- set in time.
nut = nut or GM

-- Needed includes.
include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")