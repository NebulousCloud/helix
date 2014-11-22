--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

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

		if (IsValid(target) and target:getChar()) then
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
			nut.util.notify(L("cChangeModel", client, client:Name(), target:Name(), arguments[2]))
		end
	end
})

nut.command.add("charsetname", {
	syntax = "<string name> <string model>",
	onRun = function(client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.findPlayer(client, arguments[1])
		table.remove(arguments, 1)

		local targetName = table.concat(arguments, " ")

		if (IsValid(target) and target:getChar()) then
			nut.util.notify(L("cChangeName", client, client:Name(), target:Name(), targetName))

			target:getChar():setName(targetName)
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

		if (!client:getChar():hasMoney(amount)) then
			return
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

nut.command.add("plywhitelist", {
	adminOnly = true,
	syntax = "<string name> <string faction>",
	onRun = function(client, arguments)
		local target = nut.command.findPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			for k, v in ipairs(nut.faction.indices) do
				if (nut.util.stringMatches(L(v.name, client), name) or nut.util.stringMatches(v.uniqueID, name)) then
					if (target:setWhitelisted(k, true)) then
						for k2, v2 in ipairs(player.GetAll()) do
							v2:notifyLocalized("whitelist", client:Name(), target:Name(), L(v.name, v2))
						end
					end

					return
				end
			end
		end
	end
})

nut.command.add("plyunwhitelist", {
	adminOnly = true,
	syntax = "<string name> <string faction>",
	onRun = function(client, arguments)
		local target = nut.command.findPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			for k, v in ipairs(nut.faction.indices) do
				if (nut.util.stringMatches(L(v.name, client), name) or nut.util.stringMatches(v.uniqueID, name)) then
					if (target:setWhitelisted(k, false)) then
						for k2, v2 in ipairs(player.GetAll()) do
							v2:notifyLocalized("unwhitelist", client:Name(), target:Name(), L(v.name, v2))
						end
					end
					
					return
				end
			end
		end
	end
})