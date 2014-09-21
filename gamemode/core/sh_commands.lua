nut.command.add("roll", {
	syntax = "[number maximum]",
	onRun = function(client, arguments)
		nut.chat.send(client, "roll", math.random(0, math.min(tonumber(arguments[1]) or 100, 100)))
	end
})

nut.command.add("flaggive", {
	syntax = "<string name> [string flags]",
	onRun = function(client, arguments)
		local target = nut.command.findPlayer(client, arguments[1])

		if (IsValid(target)) then
			local flags = arguments[2]

			if (!flags) then
				-- to-do: create a system to send dialog messages that are networked.
				return L("invalidArg", client, 2)
			end

			target:getChar():giveFlags(flags)

			nut.util.notifyLocalized("flagGive", nil, client:Name(), target:Name(), flags)
		end
	end
})