-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store NutScript information.
nut = nut or {util = {}, gui = {}}

-- Include core files.
include("core/sh_util.lua")
include("shared.lua")