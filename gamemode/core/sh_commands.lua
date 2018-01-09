
ix.command.Add("Roll", {
	description = "@cmdRoll",
	arguments = {ix.type.number, "maximum", true},
	OnRun = function(self, client, maximum)
		ix.chat.Send(client, "roll", math.random(0, math.min(maximum or 100, 100)))
	end
})

ix.command.Add("PM", {
	description = "@cmdPM",
	syntax = "<string target> <string message>",
	OnRun = function(self, client, arguments)
		local message = table.concat(arguments, " ", 2)
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local voiceMail = target:GetData("vm")

			if (voiceMail and voiceMail:find("%S")) then
				return target:Name()..": "..voiceMail
			end

			if ((client.ixNextPM or 0) < CurTime()) then
				ix.chat.Send(client, "pm", message, false, {client, target})

				client.ixNextPM = CurTime() + 0.5
				target.ixLastPM = client
			end
		end
	end
})

ix.command.Add("Reply", {
	description = "@cmdReply",
	syntax = "<string message>",
	OnRun = function(self, client, arguments)
		local target = client.ixLastPM

		if (IsValid(target) and (client.ixNextPM or 0) < CurTime()) then
			ix.chat.Send(client, "pm", table.concat(arguments, " "), false, {client, target})
			client.ixNextPM = CurTime() + 0.5
		end
	end
})

ix.command.Add("SetVoicemail", {
	description = "@cmdSetVoicemail",
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

ix.command.Add("CharGiveFlag", {
	description = "@cmdCharGiveFlag",
	adminOnly = true,
	syntax = "<string name> [string flags]",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local flags = arguments[2]

			if (!flags) then
				local available = ""

				-- Aesthetics~~
				for k, v in SortedPairs(ix.flag.list) do
					if (!target:GetChar():HasFlags(k)) then
						available = available..k
					end
				end

				return client:RequestString("@flagGiveTitle", "@cmdCharGiveFlag", function(text)
					ix.command.Run(client, "flaggive", {target:Name(), text})
				end, available)
			end

			target:GetChar():GiveFlags(flags)

			ix.util.NotifyLocalized("flagGive", nil, client:Name(), target:Name(), flags)
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharTakeFlag", {
	description = "@cmdCharTakeFlag",
	adminOnly = true,
	syntax = "<string name> [string flags]",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local flags = arguments[2]

			if (!flags) then
				return client:RequestString("@flagTakeTitle", "@cmdCharTakeFlag", function(text)
					ix.command.Run(client, "flagtake", {target:Name(), text})
				end, target:GetChar():GetFlags())
			end

			target:GetChar():TakeFlags(flags)

			ix.util.NotifyLocalized("flagTake", nil, client:Name(), flags, target:Name())
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("ToggleRaise", {
	description = "@cmdToggleRaise",
	OnRun = function(self, client, arguments)
		if ((client.ixNextToggle or 0) < CurTime()) then
			client:ToggleWepRaised()
			client.ixNextToggle = CurTime() + 0.5
		end
	end
})

ix.command.Add("CharSetModel", {
	description = "@cmdCharSetModel",
	adminOnly = true,
	syntax = "<string name> <string model>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			target:GetChar():SetModel(arguments[2])
			target:SetupHands()

			ix.util.NotifyLocalized("cChangeModel", nil, client:Name(), target:Name(), arguments[2])
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharSetSkin", {
	description = "@cmdCharSetSkin",
	adminOnly = true,
	syntax = "<string name> [number skin]",
	OnRun = function(self, client, arguments)
		local skin = tonumber(arguments[2])
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			target:GetChar():SetData("skin", skin)
			target:SetSkin(skin or 0)

			ix.util.NotifyLocalized("cChangeSkin", nil, client:Name(), target:Name(), skin or 0)
		end
	end
})

ix.command.Add("CharSetBodygroup", {
	description = "@cmdCharSetBodygroup",
	adminOnly = true,
	syntax = "<string name> <string bodyGroup> [number value]",
	OnRun = function(self, client, arguments)
		local value = tonumber(arguments[3])
		local target = ix.command.FindPlayer(client, arguments[1])

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

				ix.util.NotifyLocalized("cChangeGroups", nil, client:Name(), target:Name(), arguments[2], value or 0)
			else
				return "@invalidArg", 2
			end
		end
	end
})

ix.command.Add("CharSetAttribute", {
	description = "@cmdCharSetAttribute",
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

		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in pairs(ix.attributes.list) do
					if (ix.util.StringMatches(L(v.name, client), attribName) or ix.util.StringMatches(k, attribName)) then
						char:SetAttrib(k, math.abs(attribNumber))
						client:NotifyLocalized("attributeSet", target:Name(), L(v.name, client), math.abs(attribNumber))

						return
					end
				end
			end
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharAddAttribute", {
	description = "@cmdCharAddAttribute",
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

		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in pairs(ix.attributes.list) do
					if (ix.util.StringMatches(L(v.name, client), attribName) or ix.util.StringMatches(k, attribName)) then
						char:UpdateAttrib(k, math.abs(attribNumber))
						client:NotifyLocalized("attribUpdate", target:Name(), L(v.name, client), math.abs(attribNumber))

						return
					end
				end
			end
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharSetName", {
	description = "@cmdCharSetName",
	adminOnly = true,
	syntax = "<string name> [string newName]",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])

		-- display string request if no name was specified
		if (IsValid(target) and !arguments[2]) then
			return client:RequestString("@chgName", "@chgNameDesc", function(text)
				ix.command.Run(client, "charsetname", {target:Name(), text})
			end, target:Name())
		end

		table.remove(arguments, 1)

		local targetName = table.concat(arguments, " ")

		if (IsValid(target) and target:GetChar()) then
			ix.util.NotifyLocalized("cChangeName", nil, client:Name(), target:Name(), targetName)

			target:GetChar():SetName(targetName:gsub("#", "#​"))
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharGiveItem", {
	description = "@cmdCharGiveItem",
	adminOnly = true,
	syntax = "<string name> <string item>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target) and target:GetChar()) then
			local uniqueID = arguments[2]:lower()

			if (!ix.item.list[uniqueID]) then
				for k, v in SortedPairs(ix.item.list) do
					if (ix.util.StringMatches(v.name, uniqueID)) then
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
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharKick", {
	description = "@cmdCharKick",
	adminOnly = true,
	syntax = "<string name>",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			if (char) then
				for k, v in ipairs(player.GetAll()) do
					v:NotifyLocalized("charKick", client:Name(), target:Name())
				end

				char:Kick()
			end
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharBan", {
	description = "@cmdCharBan",
	syntax = "<string name>",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()

			if (char) then
				ix.util.NotifyLocalized("charBan", nil, client:Name(), target:Name())
				
				char:SetData("banned", true)
				char:Kick()
			end
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("CharUnban", {
	description = "@cmdCharUnban",
	syntax = "<string name>",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		if ((client.ixNextSearch or 0) >= CurTime()) then
			return L("charSearching", client)
		end

		local name = table.concat(arguments, " ")

		for k, v in pairs(ix.char.loaded) do
			if (ix.util.StringMatches(v:GetName(), name)) then
				if (v:GetData("banned")) then
					v:SetData("banned")
				else
					return "@charNotBanned"
				end

				return ix.util.NotifyLocalized("charUnBan", nil, client:Name(), v:GetName())
			end
		end

		client.ixNextSearch = CurTime() + 15

		local query = mysql:Select("ix_characters")
			query:Select("id")
			query:Select("name")
			query:Select("data")
			query:WhereLike("name", name)
			query:Limit(1)
			query:Callback(function(result)
				if (istable(result) and #result > 0) then
					local characterID = tonumber(result[1].id)
					local name = result[1].name
					local data = util.JSONToTable(result[1].data or "[]")

					client.ixNextSearch = 0

					if (!data.banned) then
						return client:NotifyLocalized("charNotBanned")
					end

					data.banned = nil

					local updateQuery = mysql:Update("ix_characters")
						updateQuery:Update("data", util.TableToJSON(data))
						updateQuery:Where("id", characterID)
					updateQuery:Execute()
					
					ix.util.NotifyLocalized("charUnBan", nil, client:Name(), v:GetName())
				end
			end)
		query:Execute()
	end
})

ix.command.Add("GiveMoney", {
	description = "@cmdGiveMoney",
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

			target:NotifyLocalized("moneyTaken", ix.currency.Get(amount))
			client:NotifyLocalized("moneyGiven", ix.currency.Get(amount))
		end
	end
})

ix.command.Add("CharSetMoney", {
	description = "@cmdCharSetMoney",
	adminOnly = true,
	syntax = "<string target> <number amount>",
	OnRun = function(self, client, arguments)
		local amount = tonumber(arguments[2])

		if (!amount or !isnumber(amount) or amount < 0) then
			return "@invalidArg", 2
		end

		local target = ix.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:GetChar()
			
			if (char and amount) then
				amount = math.Round(amount)
				char:SetMoney(amount)
				client:NotifyLocalized("setMoney", target:Name(), ix.currency.Get(amount))
			end
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("DropMoney", {
	description = "@cmdDropMoney",
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
		local money = ix.currency.Spawn(client, amount)
		money.client = client
		money.charID = client:GetChar():GetID()
	end
})

ix.command.Add("PlyWhitelist", {
	description = "@cmdPlyWhitelist",
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			local faction = ix.faction.teams[name]

			if (!faction) then
				for k, v in ipairs(ix.faction.indices) do
					if (ix.util.StringMatches(L(v.name, client), name) or ix.util.StringMatches(v.uniqueID, name)) then
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

ix.command.Add("CharGetUp", {
	description = "@cmdCharGetUp",
	OnRun = function(self, client, arguments)
		local entity = client.ixRagdoll

		if (IsValid(entity) and entity.ixGrace and entity.ixGrace < CurTime() and entity:GetVelocity():Length2D() < 8 and !entity.ixWakingUp) then
			entity.ixWakingUp = true

			client:SetAction("@gettingUp", 5, function()
				if (!IsValid(entity)) then
					return
				end

				entity:Remove()
			end)
		end
	end
})

ix.command.Add("PlyUnwhitelist", {
	description = "@cmdPlyUnwhitelist",
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target)) then
			local faction = ix.faction.teams[name]

			if (!faction) then
				for k, v in ipairs(ix.faction.indices) do
					if (ix.util.StringMatches(L(v.name, client), name) or ix.util.StringMatches(v.uniqueID, name)) then
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

ix.command.Add("CharFallOver", {
	description = "@cmdCharFallOver",
	syntax = "[number time]",
	OnRun = function(self, client, arguments)
		local time = tonumber(arguments[1]) or 0

		if (time > 0) then
			time = math.Clamp(time, 1, 60)
		else
			time = nil
		end

		if (!IsValid(client.ixRagdoll)) then
			client:SetRagdolled(true, time)
		end
	end
})

ix.command.Add("BecomeClass", {
	description = "@cmdBecomeClass",
	syntax = "<string class>",
	OnRun = function(self, client, arguments)
		local class = table.concat(arguments, " ")
		local char = client:GetChar()

		if (IsValid(client) and char) then
			local num = isnumber(tonumber(class)) and tonumber(class) or -1
			
			if (ix.class.list[num]) then
				local v = ix.class.list[num]

				if (char:JoinClass(num)) then
					client:NotifyLocalized("becomeClass", L(v.name, client))

					return
				else
					client:NotifyLocalized("becomeClassFail", L(v.name, client))

					return
				end
			else
				for k, v in ipairs(ix.class.list) do
					if (ix.util.StringMatches(v.uniqueID, class) or ix.util.StringMatches(L(v.name, client), class)) then
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

ix.command.Add("CharDesc", {
	description = "@cmdCharDesc",
	syntax = "<string desc>",
	OnRun = function(self, client, arguments)
		arguments = table.concat(arguments, " ")

		if (!arguments:find("%S")) then
			return client:RequestString("@chgDesc", "@chgDescDesc", function(text)
				ix.command.Run(client, "CharDesc", {text})
			end, client:GetChar():GetDescription())
		end

		local info = ix.char.vars.description
		local result, fault, count = info.OnValidate(arguments)

		if (result == false) then
			return "@"..fault, count
		end

		client:GetChar():SetDescription(arguments)

		return "@descChanged"
	end
})

ix.command.Add("PlyTransfer", {
	description = "@cmdPlyTransfer",
	adminOnly = true,
	syntax = "<string name> <string faction>",
	OnRun = function(self, client, arguments)
		local target = ix.command.FindPlayer(client, arguments[1])
		local name = table.concat(arguments, " ", 2)

		if (IsValid(target) and target:GetChar()) then
			local faction = ix.faction.teams[name]

			if (!faction) then
				for k, v in pairs(ix.faction.indices) do
					if (ix.util.StringMatches(L(v.name, client), name)) then
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

				ix.util.NotifyLocalized("cChangeFaction", nil, client:Name(), target:Name(), L(faction.name, v))
			else
				return "@invalidFaction"
			end
		end
	end
})

ix.command.Add("CharSetClass", {
	description = "@cmdCharSetClass",
	adminOnly = true,
	syntax = "<string name> <string class>",
	OnRun = function(self, client, arguments)
		if (!arguments[2]) then
			return L("invalidArg", client, 2)
		end

		local target = ix.command.FindPlayer(client, arguments[1])
		local targetCharacter = target:GetCharacter()

		if (IsValid(target) and targetCharacter) then
			local class = table.concat(arguments, " ", 2)
			local classTable = nil

			for k, v in ipairs(ix.class.list) do
				if (ix.util.StringMatches(v.uniqueID, class) or ix.util.StringMatches(v.name, name)) then
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
		else
			return "@charNoExist"
		end
	end
})

ix.command.Add("MapRestart", {
	description = "@cmdMapRestart",
	adminOnly = true,
	syntax = "[number delay]",
	OnRun = function(self, client, arguments)
		local delay = tonumber(arguments[1] or 10)
		ix.util.NotifyLocalized("mapRestarting", nil, delay)

		timer.Simple(delay, function()
			RunConsoleCommand("changelevel", game.GetMap())
		end)
	end
})
