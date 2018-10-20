
--[[--
Persistent date and time handling.

All of Lua's time functions are dependent on the Unix epoch, which means we can't have dates that go further than 1970. This
library remedies this problem. Time/date is represented by a `date` object that is queried, instead of relying on the seconds
since the epoch.

## Futher documentation
This library makes use of a third-party date library found at https://github.com/Tieske/date - you can find all documentation
regarding the `date` object and its methods there.
]]
-- @module ix.date

ix.date = ix.date or {}
ix.date.lib = ix.date.lib or include("thirdparty/sh_date.lua")
ix.date.cache = ix.date.cache or {}
ix.date.start = ix.date.start or ix.date.lib()

if (SERVER) then
	util.AddNetworkString("ixDateSync")

	--- Loads the date from disk.
	-- @realm server
	-- @internal
	function ix.date.Initialize()
		local startDate = ix.data.Get("date", nil, false, true)

		if (!startDate) then
			startDate = ix.date.lib()
			ix.data.Set("date", ix.date.lib.serialize(startDate), false, true)
		end

		ix.date.start = ix.date.lib.construct(startDate)
	end

	--- Sends the current date to a player. This is done automatically when the player joins the server.
	-- @realm server
	-- @internal
	-- @player client Player to send the date to
	function ix.date.Send(client)
		net.Start("ixDateSync")
			net.WriteFloat(CurTime())
			net.WriteTable(ix.date.lib.serialize(ix.date.lib() - ix.date.start))
		net.Send(client)
	end

	--- Returns the currently set date.
	-- @realm shared
	-- @treturn date Current in-game date
	function ix.date.Get()
		local currentDate = ix.date.lib()

		return (currentDate - (ix.date.start or currentDate)) + ix.date.lib(
			ix.config.Get("year"),
			ix.config.Get("month"),
			ix.config.Get("day")
		)
	end
else
	function ix.date.Get()
		local realTime = RealTime()

		-- Add the starting time + offset + current time played.
		return ix.date.start + ix.date.lib(
			ix.config.Get("year"),
			ix.config.Get("month"),
			ix.config.Get("day")
		):addseconds(realTime - (ix.joinTime or realTime))
	end

	net.Receive("ixDateSync", function()
		local curTime = net.ReadFloat()
		local offsetDate = net.ReadTable()

		ix.date.start = ix.date.lib.construct(offsetDate):addseconds(CurTime() - curTime)
	end)
end

--- Returns a string formatted version of a date.
-- @realm shared
-- @string format Format string
-- @date[opt=nil] currentDate Date to format. If nil, it will use the currently set date
-- @treturn string Formatted date
function ix.date.GetFormatted(format, currentDate)
	return (currentDate or ix.date.Get()):fmt(format)
end

--- Returns a serialized version of a date.
-- @realm shared
-- @date[opt=nil] currentDate Date to serialize. If nil, it will use the currently set date
-- @treturn table Serialized date
function ix.date.GetSerialized(currentDate)
	return ix.date.lib.serialize(currentDate or ix.date.Get())
end

--- Returns a date object from a table or serialized date.
-- @realm shared
-- @param currentDate Date to construct
-- @treturn date Constructed date object
function ix.date.Construct(currentDate)
	return ix.date.lib.construct(currentDate)
end
