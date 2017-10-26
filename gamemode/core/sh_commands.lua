
nut.command.Add("Roll", {
	syntax = "[number maximum]",
	OnRun = function(self, client, arguments)
		nut.chat.Send(client, "roll", math.random(0, math.min(tonumber(arguments[1]) or 100, 100)))
	end
})

nut.command.Add("PM", {
	syntax = "<string target> <string message>",
	OnRun = function(self, client, arguments)
		local message = table.concat(arguments, " ", 2)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local voiceMail = target:GetData("vm")

			if (voiceMail and voiceMail:find("%S")) then
				return target:Name()..": "..voiceMail
			end

			if ((client.nutNextPM or 0) < CurTime()) then
				nut.chat.Send(client, "pm", message, false, {client, target})

				client.nutNextPM = CurTime() + 0.5
				target.nutLastPM = client
			end
		end
	end
})

nut.command.Add("Reply", {
	syntax = "<string message>",
	OnRun = function(self, client, arguments)
		local target = client.nutLastPM

		if (IsValid(target) and (client.nutNextPM or 0) < CurTime()) then
			nut.chat.Send(client, "pm", table.concat(arguments, " "), false, {client, target})
			client.nutNextPM = CurTime() + 0.5
		end
	end
})

nut.command.Add("SetVoicemail", {
	syntax = "[string message]",
	OnRun = function(self, client, arguments)
		local message = table.concat(arguments, " ")

		if (message:find("%S")) then
			client:SetData("vm", message:sub(1, 240))

			return "@vmSet"
		else
			client:SetData("vm")

			return "@vmRem"
		end
	end
})

nut.command.Add("CharGiveFlag", {
	adminOnly = true,
	syntax = "<string name> [string flags]",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local flags = arguments[2]

			if (!flags) then
				local available = ""

				-- Aesthetics~~
				for k, v in SortedPairs(nut.flag.list) do
					if (!target:GetChar():HasFlags(k)) then
						available = available..k
					end
				end

				return client:RequestString("@flagGiveTitle", "@flagGiveDesc", function(text)
					nut.command.Run(client, "flaggive", {target:Name(), text})
				end, available)
			end

			target:GetChar():GiveFlags(flags)

			nut.util.NotifyLocalized("flagGive", nil, client:Name(), target:Name(), flags)
		end
	end
})

nut.command.Add("CharTakeFlag", {
	adminOnly = true,
	syntax = "<string name> [string flags]",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local flags = arguments[2]

			if (!flags) then
				return client:RequestString("@flagTakeTitle", "@flagTakeDesc", function(text)
					nut.command.Run(client, "flagtake", {target:Name(), text})
				end, target:GetChar():GetFlags())
			end

			target:GetChar():TakeFlags(flags)

			nut.util.NotifyLocalized("flagTake", nil, client:Name(), flags, target:Name())
		end
	end
})

nut.command.Add("ToggleRaise", {
	OnRun = function(self, client, arguments)
		if ((client.nutNextToggle or 0) < CurTime()) then
			client:ToggleWepRaised()
			client.nutNextToggle = CurTime() + 0.5
		end
	end
})

nut.command.Add("CharSetModel", {
	adminOnly = true,
	syntax = "<string name> <string model>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			target:GetChar():SetModel(arguments[2])
			target:SetupHands()

			nut.util.NotifyLocalized("cChangeModel", nil, client:Name(), target:Name(), arguments[2])
		end
	end
})

nut.command.Add("CharSetSkin", {
	adminOnly = true,
	syntax = "<string name> [number skin]",
	OnRun = function(self, client, arguments)
		local skin = tonumber(arguments[2])
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			target:GetChar():SetData("skin", skin)
			target:SetSkin(skin or 0)

			nut.util.NotifyLocalized("cChangeSkin", nil, client:Name(), target:Name(), skin or 0)
		end
	end
})

nut.command.Add("CharSetBodygroup", {
	adminOnly = true,
	syntax = "<string name> <string bodyGroup> [number value]",
	OnRun = function(self, client, arguments)
		local value = tonumber(arguments[3])
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local index = target:FindBodygroupByName(arguments[2])

			if (index > -1) then
				if (value and value < 1) then
					value = nil
				end

				local groups = target:GetChar():GetData("groups", {})
					groups[index] = value
				target:GetChar():SetData("groups", groups)
				target:SetBodygroup(index, value or 0)

				nut.util.NotifyLocalized("cChangeGroups", nil, client:Name(), target:Name(), arguments[2], value or 0)
			else
				return "@invalidArg", 2
			end
		end
	end
})

nut.command.Add("CharSetAttribute", {
	adminOnly = true,
	syntax = "<string charname> <string attribname> <number level>",
	OnRun = function(self, client, arguments)
		local attribName = arguments[2]
		if (!attribName) then
			return L("invalidArg", client, 2)
		end

		local attribNumber = arguments[3]
		attribNumber = tonumber(attribNumber)
		if (!attribNumber or !isnumber(attribNumber)) then
			return L("invalidArg", client, 3)
		end

		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in pairs(nut.attribs.list) do
					if (nut.util.StringMatches(L(v.name, client), attribName) or nut.util.StringMatches(k, attribName)) then
						char:SetAttrib(k, math.abs(attribNumber))
						client:NotifyLocalized("attribSet", target:Name(), L(v.name, client), math.abs(attribNumber))

						return
					end
				end
			end
		end
	end
})

nut.command.Add("CharAddAttribute", {
	adminOnly = true,
	syntax = "<string charname> <string attribname> <number level>",
	OnRun = function(self, client, arguments)
		local attribName = arguments[2]
		if (!attribName) then
			return L("invalidArg", client, 2)
		end

		local attribNumber = arguments[3]
		attribNumber = tonumber(attribNumber)
		if (!attribNumber or !isnumber(attribNumber)) then
			return L("invalidArg", client, 3)
		end

		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in pairs(nut.attribs.list) do
					if (nut.util.StringMatches(L(v.name, client), attribName) or nut.util.StringMatches(k, attribName)) then
						char:UpdateAttrib(k, math.abs(attribNumber))
						client:NotifyLocalized("attribUpdate", target:Name(), L(v.name, client), math.abs(attribNumber))

						return
					end
				end
			end
		end
	end
})

nut.command.Add("CharSetName", {
	adminOnly = true,
	syntax = "<string name> [string newName]",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and !arguments[2]) then
			return client:RequestString("@chgName", "@chgNameDesc", function(text)
				nut.command.Run(client, "charsetname", {target:Name(), text})
			end, target:Name())
		end

		table.remove(arguments, 1)

		local targetName = table.concat(arguments, " ")

		if (IsValid(target) and target:GetChar()) then
			nut.util.NotifyLocalized("cChangeName", client:Name(), target:Name(), targetName)

			target:GetChar():SetName(targetName:gsub("#", "#​"))
		end
	end
})

nut.command.Add("CharGiveItem", {
	adminOnly = true,
	syntax = "<string name> <string item>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local uniqueID = arguments[2]:lower()

			if (!nut.item.list[uniqueID]) then
				for k, v in SortedPairs(nut.item.list) do
					if (nut.util.StringMatches(v.name, uniqueID)) then
						uniqueID = k

						break
					end
				end
			end

			local inv = target:GetChar():GetInv()
			local succ, err = target:GetChar():GetInv():Add(uniqueID)

			if (succ) then
				target:NotifyLocalized("itemCreated")
				if(target != client) then
					client:NotifyLocalized("itemCreated")
				end
			else
				target:NotifyLocalized(tostring(err))
			end
		end
	end
})

nut.command.Add("CharKick", {
	adminOnly = true,
	syntax = "<string name>",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in ipairs(player.GetAll()) do
					v:NotifyLocalized("charKick", client:Name(), target:Name())
				end

				char:Kick()
			end
		end
	end
})

nut.command.Add("CharBan", {
	syntax = "<string name>",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()

			if (char) then
				nut.util.NotifyLocalized("charBan", client:Name(), target:Name())
				
				char:SetData("banned", true)
				char:Kick()
			end
		end
	end
})

nut.command.Add("CharUnban", {
	syntax = "<string name>",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		if ((client.nutNextSearch or 0) >= CurTime()) then
			return L("charSearching", client)
		end

		local name = table.concat(arguments, " ")

		for k, v in pairs(nut.char.loaded) do
			if (nut.util.StringMatches(v:GetName(), name)) then
				if (v:GetData("banned")) then
					v:SetData("banned")
				else
					return "@charNotBanned"
				end

				return nut.util.NotifyLocalized("charUnBan", nil, client:Name(), v:GetName())
			end
		end

		client.nutNextSearch = CurTime() + 15

		nut.db.query("SELECT _id, _name, _data FROM nut_characters WHERE _name LIKE \"%"..nut.db.escape(name).."%\" LIMIT 1", function(data)
			if (data and data[1]) then
				local charID = tonumber(data[1]._id)
				local name = data[1]._name
				local data = util.JSONToTable(data[1]._data or "[]")

				client.nutNextSearch = 0

				if (!data.banned) then
					return client:NotifyLocalized("charNotBanned")
				end

				data.banned = nil
				
				nut.db.UpdateTable({_data = data}, nil, nil, "_id = "..charID)
				nut.util.NotifyLocalized("charUnBan", nil, client:Name(), v:GetName())
			end
		end)
	end
})

nut.command.Add("GiveMoney", {
	syntax = "<number amount>",
	OnRun = function(self, client, arguments)
		local number = tonumber(arguments[1])
		number = number or 0
		local amount = math.floor(number)

		if (!amount or !isnumber(amount) or amount <= 0) then
			return L("invalidArg", client, 1)
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:GetChar()) then
			amount = math.Round(amount)

			if (!client:GetChar():HasMoney(amount)) then
				return
			end

			target:GetChar():GiveMoney(amount)
			client:GetChar():TakeMoney(amount)

			target:NotifyLocalized("moneyTaken", nut.currency.Get(amount))
			client:NotifyLocalized("moneyGiven", nut.currency.Get(amount))
		end
	end
})

nut.command.Add("CharSetMoney", {
	adminOnly = true,
	syntax = "<string target> <number amount>",
	OnRun = function(self, client, arguments)
		local amount = tonumber(arguments[2])

		if (!amount or !isnumber(amount) or amount < 0) then
			return "@invalidArg", 2
		end

		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			
			if (char and amount) then
				amount = math.Round(amount)
				char:SetMoney(amount)
				client:NotifyLocalized("setMoney", target:Name(), nut.currency.Get(amount))
			end
		end
	end
})

nut.command.Add("DropMoney", {
	syntax = "<number amount>",
	OnRun = function(self, client, arguments)
		local amount = tonumber(arguments[1])

		if (!amount or !isnumber(amount) or amount < 1) then
			return "@invalidArg", 1
		end

		amount = math.Round(amount)
		
		if (!client:GetChar():HasMoney(amount)) then
			return
		end

		client:GetChar():TakeMoney(amount)
		local money = nut.currency.Spawn(client:GetItemDropPos(), amount)
		money.client = client
		money.charID = client:GetChar():GetID()
	end
})

nut.command.Add("PlyWhitelist", {
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			local faction = nut.faction.teams[name]

			if (!faction) then
				for k, v in ipairs(nut.faction.indices) do
					if (nut.util.StringMatches(L(v.name, client), name) or nut.util.StringMatches(v.uniqueID, name)) then
						faction = v

						break
					end
				end
			end

			if (faction) then
				if (target:SetWhitelisted(faction.index, true)) then
					for k, v in ipairs(player.GetAll()) do
						v:NotifyLocalized("whitelist", client:Name(), target:Name(), L(faction.name, v))
					end
				end
			else
				return "@invalidFaction"
			end
		end
	end
})

nut.command.Add("CharGetUp", {
	OnRun = function(self, client, arguments)
		local entity = client.nutRagdoll

		if (IsValid(entity) and entity.nutGrace and entity.nutGrace < CurTime() and entity:GetVelocity():Length2D() < 8 and !entity.nutWakingUp) then
			entity.nutWakingUp = true

			client:SetAction("@gettingUp", 5, function()
				if (!IsValid(entity)) then
					return
				end

				entity:Remove()
			end)
		end
	end
})

nut.command.Add("PlyUnwhitelist", {
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			local faction = nut.faction.teams[name]

			if (!faction) then
				for k, v in ipairs(nut.faction.indices) do
					if (nut.util.StringMatches(L(v.name, client), name) or nut.util.StringMatches(v.uniqueID, name)) then
						faction = v

						break
					end
				end
			end

			if (faction) then
				if (target:SetWhitelisted(faction.index, false)) then
					for k, v in ipairs(player.GetAll()) do
						v:NotifyLocalized("unwhitelist", client:Name(), target:Name(), L(faction.name, v))
					end
				end
			else
				return "@invalidFaction"
			end
		end
	end
})

nut.command.Add("CharFallOver", {
	syntax = "[number time]",
	OnRun = function(self, client, arguments)
		local time = tonumber(arguments[1]) or 0

		if (time > 0) then
			time = math.Clamp(time, 1, 60)
		else
			time = nil
		end

		if (!IsValid(client.nutRagdoll)) then
			client:SetRagdolled(true, time)
		end
	end
})

nut.command.Add("BecomeClass", {
	syntax = "<string class>",
	OnRun = function(self, client, arguments)
		local class = table.concat(arguments, " ")
		local char = client:GetChar()

		if (IsValid(client) and char) then
			local num = isnumber(tonumber(class)) and tonumber(class) or -1
			
			if (nut.class.list[num]) then
				local v = nut.class.list[num]

				if (char:JoinClass(num)) then
					client:NotifyLocalized("becomeClass", L(v.name, client))

					return
				else
					client:NotifyLocalized("becomeClassFail", L(v.name, client))

					return
				end
			else
				for k, v in ipairs(nut.class.list) do
					if (nut.util.StringMatches(v.uniqueID, class) or nut.util.StringMatches(L(v.name, client), class)) then
						if (char:JoinClass(k)) then
							client:NotifyLocalized("becomeClass", L(v.name, client))

							return
						else
							client:NotifyLocalized("becomeClassFail", L(v.name, client))

							return
						end
					end
				end
			end
			
			client:NotifyLocalized("invalid", L("class", client))
		else
			client:NotifyLocalized("illegalAccess")
		end
	end
})

nut.command.Add("CharDesc", {
	syntax = "<string desc>",
	OnRun = function(self, client, arguments)
		arguments = table.concat(arguments, " ")

		if (!arguments:find("%S")) then
			return client:RequestString("@chgDesc", "@chgDescDesc", function(text)
				nut.command.Run(client, "CharDesc", {text})
			end, client:GetChar():GetDescription())
		end

		local info = nut.char.vars.description
		local result, fault, count = info.OnValidate(arguments)

		if (result == false) then
			return "@"..fault, count
		end

		client:GetChar():SetDescription(arguments)

		return "@descChanged"
	end
})

nut.command.Add("PlyTransfer", {
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target) and target:GetChar()) then
			local faction = nut.faction.teams[name]

			if (!faction) then
				for k, v in pairs(nut.faction.indices) do
					if (nut.util.StringMatches(L(v.name, client), name)) then
						faction = v

						break
					end
				end
			end

			if (faction) then
				target:GetChar().vars.faction = faction.uniqueID
				target:GetChar():SetFaction(faction.index)

				if (faction.OnTransfered) then
					faction:OnTransfered(target)
				end

				for k, v in ipairs(player.GetAll()) do
					nut.util.NotifyLocalized("cChangeFaction", v, client:Name(), target:Name(), L(faction.name, v))
				end
			else
				return "@invalidFaction"
			end
		end
	end
})

nut.command.Add("CharSetClass", {
	adminOnly = true,
	syntax = "<string name> <string class>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = nut.command.FindPlayer(client, arguments[1])
		local targetCharacter = target:GetCharacter()

		if (IsValid(target) and targetCharacter) then
			local class = table.concat(arguments, " ", 2)
			local classTable = nil

			for k, v in ipairs(nut.class.list) do
				if (nut.util.StringMatches(v.uniqueID, class) or nut.util.StringMatches(v.name, name)) then
					classTable = v
				end
			end

			if (classTable) then
				local oldClass = targetCharacter:GetClass()

				if (target:Team() == classTable.faction) then
					targetCharacter:SetClass(classTable.index)
					hook.Run("OnPlayerJoinClass", client, classTable.index, oldClass)

					target:NotifyLocalized("becomeClass", L(classTable.name, target))

					-- only send second notification if the character isn't setting their own class
					if (client != target) then
						client:NotifyLocalized("setClass", targetCharacter:GetName(), L(classTable.name, target))
					end
				else
					client:NotifyLocalized("invalidClassFaction")
				end
			else
				client:NotifyLocalized("invalidClass")
			end
		end
	end
})

nut.command.Add("MapRestart", {
	adminOnly = true,
	syntax = "[number delay]",
	OnRun = function(self, client, arguments)
		local delay = tonumber(arguments[1] or 10)
		nut.util.NotifyLocalized("mapRestarting", nil, delay)

		timer.Simple(delay, function()
			RunConsoleCommand("changelevel", game.GetMap())
		end)
	end
})
