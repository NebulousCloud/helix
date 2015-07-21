-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store NutScript information.
nut = nut or {util = {}, gui = {}, meta = {}}

-- Include core files.
include("core/sh_util.lua")
include("shared.lua")

-- Sandbox stuff
CreateConVar("cl_weaponcolor", "0.30 1.80 2.10", {FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD}, "The value is a Vector - so between 0-1 - not between 0-255")

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")