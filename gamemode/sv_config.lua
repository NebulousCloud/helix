--[[
	Purpose: Provides a table of configuration values that are to be used in the script and allow
	easier customization of the script.
--]]

-- Define a global table for configurations.
nut.config = nut.config or {}

-- The module to use for MySQL. (mysqloo/tmysql4/sqlite)
-- SQLite is local, meaning you DO NOT need a database!
nut.config.dbModule = "sqlite"

-- The IP or address of the host for the database.
nut.config.dbHost = "127.0.0.1"

-- The user to login as.
nut.config.dbUser = "root"

-- What the user's password is.
nut.config.dbPassword = "derp"

-- The database that will be used for the framework. Make sure you have the .sql file already inside!
nut.config.dbDatabase = "nutscript"

-- The table for characters.
nut.config.dbTable = "characters"

-- Table for player whitelists and data.
nut.config.dbPlyTable = "players"

-- The port to connect for the database.
nut.config.dbPort = 3306

-- Whether or not players can suicide.
nut.config.canSuicide = false

-- What the default flags are for players. This does not affect characters that are already made
-- prior to changing this config.
nut.config.defaultFlags = ""

-- What the fall damage is set to by multiplying this scale by the velocity.
nut.config.fallDamageScale = 0.8

-- Whether or not players can use the flashlight.
nut.config.flashlight = true

-- The starting amount of money.
nut.config.startingAmount = 0

-- How high players can jump by default.
nut.config.jumpPower = 128

nut.config.deathTime = 10

-- Determines whether or not voice chat is allowed.
nut.config.allowVoice = false

-- If true, will have voices fade over distance.
nut.config.voice3D = false

-- The delay between OOC messages for a player in seconds.
nut.config.oocDelay = 10

-- Clears the map of unwanted entities. (props, vehicles, etc...)
nut.config.clearMaps = true

-- Whether or not holding C and pressing Persist will NOT persist props.
-- If set to false or nil, the gamemode will automatically turn on sbox_persist.
nut.config.noPersist = false

-- The model for dropped money.
nut.config.moneyModel = "models/props_lab/box01a.mdl"