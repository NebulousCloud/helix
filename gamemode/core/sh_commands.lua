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

nut.command.add("toggleraise", {
	onRun = function(client, arguments)
		if ((client.nutNextToggle or 0) < CurTime()) then
			client:toggleWepRaised()
			client.nutNextToggle = CurTime() + 0.5
		end
	end
})

nut.command.add("charsetmodel", {
	syntax = "<string name> <string model>",
	onRun = function(client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.findPlayer(client, arguments[1])

		if (IsValid(target) and target:getChar()) then
			target:getChar():setModel(arguments[2])
			target:SetupHands()
		end
	end
})

nut.command.add("chargiveitem", {
	syntax = "<string name> <string item>",
	onRun = function(client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.findPlayer(client, arguments[1])

		if (IsValid(target) and target:getChar()) then
			local inv = target:getChar():getInv()

			local succ, err = target:getChar():getInv():add(arguments[2])

			if (succ) then
				target:notify("Item successfully created.")
			else
				target:notify(tostring(succ))
				target:notify(tostring(err))
			end
		end
	end
})


nut.command.add("givemoney", {
	syntax = "<number amount> [string target]",
	onRun = function(client, arguments)
		local amount = math.Round(tonumber(arguments[1]))
		if (!amount or amount <= 0) then
			return L("invalidArg", client, 2)
		end

		table.remove(arguments, 1)

		local name = table.concat(arguments)
		if (name or name != "") then
			target = nut.command.findPlayer(client, name)
		else
			local data = {}
				data.start = client:GetShootPos()
				data.endpos = data.start + client:GetAimVector()*96
				data.filter = client
			local trace = util.TraceLine(data)

			if (trace.Entity and trace.Entity:IsPlayer()) then
				target = trace.Entity
			end
		end

		if (IsValid(target) and target:getChar()) then
			-- give money
			print(target)
		end
	end
})

nut.command.add("dropmoney", {
	syntax = "<string name> <string item>",
	onRun = function(client, arguments)
		local amount = math.Round(tonumber(arguments[1]))
		if (!amount or amount <= 0) then
			return L("invalidArg", client, 2)
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local pos = trace.HitPos

		nut.currency.spawn(pos, amount)
	end
})
