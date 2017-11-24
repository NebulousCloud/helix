ix.date = ix.date or {}
ix.date.cache = ix.date.cache or {}
ix.date.start = ix.date.start or os.time()

if (!ix.config) then
	include("helix/gamemode/core/sh_config.lua")
end

ix.config.Add("year", 2015, "The starting year of the schema.", nil, {
	data = {min = 0, max = 4000},
	category = "date"
})
ix.config.Add("month", 1, "The starting month of the schema.", nil, {
	data = {min = 1, max = 12},
	category = "date"
})
ix.config.Add("day", 1, "The starting day of the schema.", nil, {
	data = {min = 1, max = 31},
	category = "date"
})

if (SERVER) then
	function ix.date.Get()
		local unixTime = os.time()

		return (unixTime - (ix.date.start or unixTime)) + os.time({
			year = ix.config.Get("year"),
			month = ix.config.Get("month"),
			day = ix.config.Get("day")
		})
	end

	function ix.date.Send(client)
		netstream.Start(client, "dateSync", CurTime(), os.time() - ix.date.start)
	end
else
	function ix.date.Get()
		local realTime = RealTime()

		-- Add the starting time + offset + current time played.
		return ix.date.start + os.time({
			year = ix.config.Get("year"),
			month = ix.config.Get("month"),
			day = ix.config.Get("day")
		}) + (realTime - (ix.joinTime or realTime))
	end

	netstream.Hook("dateSync", function(curTime, offset)
		offset = offset + (CurTime() - curTime)

		ix.date.start = offset
	end)
end
