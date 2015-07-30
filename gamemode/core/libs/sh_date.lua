nut.date = nut.date or {}
nut.date.cache = nut.date.cache or {}
nut.date.start = nut.date.start or os.time()

if (!nut.config) then
	include("nutscript/gamemode/core/sh_config.lua")
end

nut.config.add("year", 2015, "The starting year of the schema.", nil, {
	data = {min = 0, max = 4000},
	category = "date"
})
nut.config.add("month", 1, "The starting month of the schema.", nil, {
	data = {min = 1, max = 12},
	category = "date"
})
nut.config.add("day", 1, "The starting day of the schema.", nil, {
	data = {min = 1, max = 31},
	category = "date"
})

if (SERVER) then
	function nut.date.get()
		local unixTime = os.time()

		return (unixTime - (nut.date.start or unixTime)) + os.time({
			year = nut.config.get("year"),
			month = nut.config.get("month"),
			day = nut.config.get("day")
		})
	end

	function nut.date.send(client)
		netstream.Start(client, "dateSync", CurTime(), os.time() - nut.date.start)
	end
else
	function nut.date.get()
		local realTime = RealTime()

		-- Add the starting time + offset + current time played.
		return nut.date.start + os.time({
			year = nut.config.get("year"),
			month = nut.config.get("month"),
			day = nut.config.get("day")
		}) + (realTime - (nut.joinTime or realTime))
	end

	netstream.Hook("dateSync", function(curTime, offset)
		offset = offset + (CurTime() - curTime)

		nut.date.start = offset
	end)
end
