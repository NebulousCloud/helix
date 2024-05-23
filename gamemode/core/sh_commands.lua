
ix.command.Add("Roll", {
	description = "@cmdRoll",
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, maximum)
		maximum = math.Clamp(maximum or 100, 0, 1000000)

		local value = math.random(0, maximum)

		ix.chat.Send(client, "roll", tostring(value), nil, nil, {
			max = maximum
		})

		ix.log.Add(client, "roll", value, maximum)
	end
})

ix.command.Add("Event", {
	description = "@cmdEvent",
	arguments = ix.type.text,
	superAdminOnly = true,
	OnRun = function(self, client, text)
		ix.chat.Send(client, "event", text)
	end
})

ix.command.Add("PM", {
	description = "@cmdPM",
	arguments = {
		ix.type.player,
		ix.type.text
	},
	OnRun = function(self, client, target, message)
		local voiceMail = target:GetData("vm")

		if (voiceMail and voiceMail:find("%S")) then
			return target:GetName()..": "..voiceMail
		end

		if ((client.ixNextPM or 0) < CurTime()) then
			ix.chat.Send(client, "pm", message, false, {client, target}, {target = target})

			client.ixNextPM = CurTime() + 0.5
			target.ixLastPM = client
		end
	end
})

ix.command.Add("Reply", {
	description = "@cmdReply",
	arguments = ix.type.text,
	OnRun = function(self, client, message)
		local target = client.ixLastPM

		if (IsValid(target) and (client.ixNextPM or 0) < CurTime()) then
			ix.chat.Send(client, "pm", message, false, {client, target}, {target = target})
			client.ixNextPM = CurTime() + 0.5
		end
	end
})

ix.command.Add("SetVoicemail", {
	description = "@cmdSetVoicemail",
	arguments = bit.bor(ix.type.text, ix.type.optional),
	OnRun = function(self, client, message)
		if (isstring(message) and message:find("%S")) then
			client:SetData("vm", message:utf8sub(1, 240))
			return "@vmSet"
		else
			client:SetData("vm")
			return "@vmRem"
		end
	end
})

ix.command.Add("CharGiveFlag", {
	description = "@cmdCharGiveFlag",
	privilege = "Manage Character Flags",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, client, target, flags)
		-- show string request if no flags are specified
		if (!flags) then
			local available = ""

			-- sort and display flags the character already has
			for k, _ in SortedPairs(ix.flag.list) do
				if (!target:HasFlags(k)) then
					available = available .. k
				end
			end

			return client:RequestString("@flagGiveTitle", "@cmdCharGiveFlag", function(text)
				ix.command.Run(client, "CharGiveFlag", {target:GetName(), text})
			end, available)
		end

		target:GiveFlags(flags)

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("flagGive", client:GetName(), target:GetName(), flags)
			end
		end
	end
})

ix.command.Add("CharTakeFlag", {
	description = "@cmdCharTakeFlag",
	privilege = "Manage Character Flags",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, client, target, flags)
		if (!flags) then
			return client:RequestString("@flagTakeTitle", "@cmdCharTakeFlag", function(text)
				ix.command.Run(client, "CharTakeFlag", {target:GetName(), text})
			end, target:GetFlags())
		end

		target:TakeFlags(flags)

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("flagTake", client:GetName(), flags, target:GetName())
			end
		end
	end
})

ix.command.Add("ToggleRaise", {
	description = "@cmdToggleRaise",
	OnRun = function(self, client, arguments)
		if (!timer.Exists("ixToggleRaise" .. client:SteamID())) then
			timer.Create("ixToggleRaise" .. client:SteamID(), ix.config.Get("weaponRaiseTime"), 1, function()
				client:ToggleWepRaised()
			end)
		end
	end
})

ix.command.Add("CharSetModel", {
	description = "@cmdCharSetModel",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string
	},
	OnRun = function(self, client, target, model)
		target:SetModel(model)
		target:GetPlayer():SetupHands()

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("cChangeModel", client:GetName(), target:GetName(), model)
			end
		end
	end
})

ix.command.Add("CharSetSkin", {
	description = "@cmdCharSetSkin",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, skin)
		target:SetData("skin", skin)
		target:GetPlayer():SetSkin(skin or 0)

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("cChangeSkin", client:GetName(), target:GetName(), skin or 0)
			end
		end
	end
})

ix.command.Add("CharSetBodygroup", {
	description = "@cmdCharSetBodygroup",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, bodygroup, value)
		local index = target:GetPlayer():FindBodygroupByName(bodygroup)

		if (index > -1) then
			if (value and value < 1) then
				value = nil
			end

			local groups = target:GetData("groups", {})
				groups[index] = value
			target:SetData("groups", groups)
			target:GetPlayer():SetBodygroup(index, value or 0)

			ix.util.NotifyLocalized("cChangeGroups", nil, client:GetName(), target:GetName(), bodygroup, value or 0)
		else
			return "@invalidArg", 2
		end
	end
})

ix.command.Add("CharSetAttribute", {
	description = "@cmdCharSetAttribute",
	privilege = "Manage Character Attributes",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		ix.type.number
	},
	OnRun = function(self, client, target, attributeName, level)
		for k, v in pairs(ix.attributes.list) do
			if (ix.util.StringMatches(L(v.name, client), attributeName) or ix.util.StringMatches(k, attributeName)) then
				target:SetAttrib(k, math.abs(level))
				return "@attributeSet", target:GetName(), L(v.name, client), math.abs(level)
			end
		end

		return "@attributeNotFound"
	end
})

ix.command.Add("CharAddAttribute", {
	description = "@cmdCharAddAttribute",
	privilege = "Manage Character Attributes",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		ix.type.number
	},
	OnRun = function(self, client, target, attributeName, level)
		for k, v in pairs(ix.attributes.list) do
			if (ix.util.StringMatches(L(v.name, client), attributeName) or ix.util.StringMatches(k, attributeName)) then
				target:UpdateAttrib(k, math.abs(level))
				return "@attributeUpdate", target:GetName(), L(v.name, client), math.abs(level)
			end
		end

		return "@attributeNotFound"
	end
})

ix.command.Add("CharSetName", {
	description = "@cmdCharSetName",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.text, ix.type.optional)
	},
	OnRun = function(self, client, target, newName)
		-- display string request panel if no name was specified
		if (newName:len() == 0) then
			return client:RequestString("@chgName", "@chgNameDesc", function(text)
				ix.command.Run(client, "CharSetName", {target:GetName(), text})
			end, target:GetName())
		end

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("cChangeName", client:GetName(), target:GetName(), newName)
			end
		end

		target:SetName(newName:gsub("#", "#​"))
	end
})

ix.command.Add("CharGiveItem", {
	description = "@cmdCharGiveItem",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, item, amount)
		local uniqueID = item:lower()

		if (!ix.item.list[uniqueID]) then
			for k, v in SortedPairs(ix.item.list) do
				if (ix.util.StringMatches(v.name, uniqueID)) then
					uniqueID = k

					break
				end
			end
		end

		amount = amount or 1
		local bSuccess, error = target:GetInventory():Add(uniqueID, amount)

		if (bSuccess) then
			target:GetPlayer():NotifyLocalized("itemCreated")

			if (target != client:GetCharacter()) then
				return "@itemCreated"
			end
		else
			return "@" .. tostring(error)
		end
	end
})

ix.command.Add("CharKick", {
	description = "@cmdCharKick",
	adminOnly = true,
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		target:Save(function()
			target:Kick()
		end)

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("charKick", client:GetName(), target:GetName())
			end
		end
	end
})

ix.command.Add("CharBan", {
	description = "@cmdCharBan",
	privilege = "Ban Character",
	arguments = {
		ix.type.character,
		bit.bor(ix.type.number, ix.type.optional)
	},
	adminOnly = true,
	OnRun = function(self, client, target, minutes)
		if (minutes) then
			minutes = minutes * 60
		end

		target:Ban(minutes)
		target:Save()

		for _, v in player.Iterator() do
			if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
				v:NotifyLocalized("charBan", client:GetName(), target:GetName())
			end
		end
	end
})

ix.command.Add("CharUnban", {
	description = "@cmdCharUnban",
	privilege = "Ban Character",
	arguments = ix.type.text,
	adminOnly = true,
	OnRun = function(self, client, name)
		if ((client.ixNextSearch or 0) >= CurTime()) then
			return L("charSearching", client)
		end

		for _, v in pairs(ix.char.loaded) do
			if (ix.util.StringMatches(v:GetName(), name)) then
				if (v:GetData("banned")) then
					v:SetData("banned")
				else
					return "@charNotBanned"
				end

				for _, v2 in player.Iterator() do
					if (self:OnCheckAccess(v2) or v2 == v:GetPlayer()) then
						v2:NotifyLocalized("charUnBan", client:GetName(), v:GetName())
					end
				end

				return
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
					local data = util.JSONToTable(result[1].data or "[]")
					name = result[1].name

					client.ixNextSearch = 0

					if (!data.banned) then
						return client:NotifyLocalized("charNotBanned")
					end

					data.banned = nil

					local updateQuery = mysql:Update("ix_characters")
						updateQuery:Update("data", util.TableToJSON(data))
						updateQuery:Where("id", characterID)
					updateQuery:Execute()

					for _, v in player.Iterator() do
						if (self:OnCheckAccess(v)) then
							v:NotifyLocalized("charUnBan", client:GetName(), name)
						end
					end
				end
			end)
		query:Execute()
	end
})

do
	hook.Add("InitializedConfig", "ixMoneyCommands", function()
		local MONEY_NAME = string.gsub(ix.util.ExpandCamelCase(ix.currency.plural), "%s", "")

		ix.command.Add("Give" .. MONEY_NAME, {
			alias = {"GiveMoney"},
			description = "@cmdGiveMoney",
			arguments = ix.type.number,
			OnRun = function(self, client, amount)
				amount = math.floor(amount)

				if (amount <= 0) then
					return L("invalidArg", client, 1)
				end

				local data = {}
					data.start = client:GetShootPos()
					data.endpos = data.start + client:GetAimVector() * 96
					data.filter = client
				local target = util.TraceLine(data).Entity

				if (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then
					if (!client:GetCharacter():HasMoney(amount)) then
						return
					end

					target:GetCharacter():GiveMoney(amount)
					client:GetCharacter():TakeMoney(amount)

					target:NotifyLocalized("moneyTaken", ix.currency.Get(amount))
					client:NotifyLocalized("moneyGiven", ix.currency.Get(amount))
				end
			end
		})

		ix.command.Add("CharSet" .. MONEY_NAME, {
			alias = {"CharSetMoney"},
			description = "@cmdCharSetMoney",
			superAdminOnly = true,
			arguments = {
				ix.type.character,
				ix.type.number
			},
			OnRun = function(self, client, target, amount)
				amount = math.Round(amount)

				if (amount <= 0) then
					return "@invalidArg", 2
				end

				target:SetMoney(amount)
				client:NotifyLocalized("setMoney", target:GetName(), ix.currency.Get(amount))
			end
		})

		ix.command.Add("Drop" .. MONEY_NAME, {
			alias = {"DropMoney"},
			description = "@cmdDropMoney",
			arguments = ix.type.number,
			OnRun = function(self, client, amount)
				amount = math.Round(amount)

				local minDropAmount = ix.config.Get("minMoneyDropAmount", 1)

				if (amount < minDropAmount) then
					return "@belowMinMoneyDrop", minDropAmount
				end

				if (!client:GetCharacter():HasMoney(amount)) then
					return "@insufficientMoney"
				end

				client:GetCharacter():TakeMoney(amount)

				local money = ix.currency.Spawn(client, amount)
				money.ixCharID = client:GetCharacter():GetID()
				money.ixSteamID = client:SteamID()
			end
		})
	end)
end

ix.command.Add("PlyWhitelist", {
	description = "@cmdPlyWhitelist",
	privilege = "Manage Character Whitelist",
	superAdminOnly = true,
	arguments = {
		ix.type.player,
		ix.type.text
	},
	OnRun = function(self, client, target, name)
		if (name == "") then
			return "@invalidArg", 2
		end

		local faction = ix.faction.teams[name]

		if (!faction) then
			for _, v in ipairs(ix.faction.indices) do
				if (ix.util.StringMatches(L(v.name, client), name) or ix.util.StringMatches(v.uniqueID, name)) then
					faction = v

					break
				end
			end
		end

		if (faction) then
			if (target:SetWhitelisted(faction.index, true)) then
				for _, v in player.Iterator() do
					if (self:OnCheckAccess(v) or v == target) then
						v:NotifyLocalized("whitelist", client:GetName(), target:GetName(), L(faction.name, v))
					end
				end
			end
		else
			return "@invalidFaction"
		end
	end
})

ix.command.Add("CharGetUp", {
	description = "@cmdCharGetUp",
	OnRun = function(self, client, arguments)
		local entity = client.ixRagdoll

		if (IsValid(entity) and entity.ixGrace and entity.ixGrace < CurTime() and
			entity:GetVelocity():Length2D() < 8 and !entity.ixWakingUp) then
			entity.ixWakingUp = true
			entity:CallOnRemove("CharGetUp", function()
				client:SetAction()
			end)

			client:SetAction("@gettingUp", 5, function()
				if (!IsValid(entity)) then
					return
				end

				hook.Run("OnCharacterGetup", client, entity)
				entity:Remove()
			end)
		end
	end
})

ix.command.Add("PlyUnwhitelist", {
	description = "@cmdPlyUnwhitelist",
	privilege = "Manage Character Whitelist",
	superAdminOnly = true,
	arguments = {
		ix.type.string,
		ix.type.text
	},
	OnRun = function(self, client, target, name)
		local faction = ix.faction.teams[name]

		if (!faction) then
			for _, v in ipairs(ix.faction.indices) do
				if (ix.util.StringMatches(L(v.name, client), name) or ix.util.StringMatches(v.uniqueID, name)) then
					faction = v

					break
				end
			end
		end

		if (faction) then
			local targetPlayer = ix.util.FindPlayer(target)

			if (IsValid(targetPlayer) and targetPlayer:SetWhitelisted(faction.index, false)) then
				for _, v in player.Iterator() do
					if (self:OnCheckAccess(v) or v == targetPlayer) then
						v:NotifyLocalized("unwhitelist", client:GetName(), targetPlayer:GetName(), L(faction.name, v))
					end
				end
			else
				local steamID64 = util.SteamIDTo64(target)
				local query = mysql:Select("ix_players")
					query:Select("data")
					query:Where("steamid", steamID64)
					query:Limit(1)
					query:Callback(function(result)
						if (istable(result) and #result > 0) then
							local data = util.JSONToTable(result[1].data or "[]")
							local whitelists = data.whitelists and data.whitelists[Schema.folder]

							if (!whitelists or !whitelists[faction.uniqueID]) then
								return
							end

							whitelists[faction.uniqueID] = nil

							local updateQuery = mysql:Update("ix_players")
								updateQuery:Update("data", util.TableToJSON(data))
								updateQuery:Where("steamid", steamID64)
							updateQuery:Execute()

							for _, v in player.Iterator() do
								if (self:OnCheckAccess(v)) then
									v:NotifyLocalized("unwhitelist", client:GetName(), target, L(faction.name, v))
								end
							end
						end
					end)
				query:Execute()
			end
		else
			return "@invalidFaction"
		end
	end
})

ix.command.Add("CharFallOver", {
	description = "@cmdCharFallOver",
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, time)
		if (!client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP) then
			return "@notNow"
		end

		if (time and time > 0) then
			time = math.Clamp(time, 1, 60)
		end

		if (!IsValid(client.ixRagdoll)) then
			client:SetRagdolled(true, time)
		end
	end
})

ix.command.Add("BecomeClass", {
	description = "@cmdBecomeClass",
	arguments = ix.type.text,
	OnRun = function(self, client, class)
		local character = client:GetCharacter()

		if (character) then
			local num = isnumber(tonumber(class)) and tonumber(class) or -1

			if (ix.class.list[num]) then
				local v = ix.class.list[num]

				if (character:JoinClass(num)) then
					return "@becomeClass", L(v.name, client)
				else
					return "@becomeClassFail", L(v.name, client)
				end
			else
				for k, v in ipairs(ix.class.list) do
					if (ix.util.StringMatches(v.uniqueID, class) or ix.util.StringMatches(L(v.name, client), class)) then
						if (character:JoinClass(k)) then
							return "@becomeClass", L(v.name, client)
						else
							return "@becomeClassFail", L(v.name, client)
						end
					end
				end
			end

			return "@invalid", L("class", client)
		else
			return "@illegalAccess"
		end
	end
})

ix.command.Add("CharDesc", {
	description = "@cmdCharDesc",
	arguments = bit.bor(ix.type.text, ix.type.optional),
	OnRun = function(self, client, description)
		if (!description:find("%S")) then
			return client:RequestString("@cmdCharDescTitle", "@cmdCharDescDescription", function(text)
				ix.command.Run(client, "CharDesc", {text})
			end, client:GetCharacter():GetDescription())
		end

		local info = ix.char.vars.description
		local result, fault, count = info:OnValidate(description)

		if (result == false) then
			return "@" .. fault, count
		end

		client:GetCharacter():SetDescription(description)
		return "@descChanged"
	end
})

ix.command.Add("PlyTransfer", {
	description = "@cmdPlyTransfer",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.text
	},
	OnRun = function(self, client, target, name)
		local faction = ix.faction.teams[name]

		if (!faction) then
			for _, v in pairs(ix.faction.indices) do
				if (ix.util.StringMatches(L(v.name, client), name)) then
					faction = v

					break
				end
			end
		end

		if (faction) then
			local bHasWhitelist = target:GetPlayer():HasWhitelist(faction.index)

			if (bHasWhitelist) then
				target.vars.faction = faction.uniqueID
				target:SetFaction(faction.index)

				if (faction.OnTransferred) then
					faction:OnTransferred(target)
				end

				for _, v in player.Iterator() do
					if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
						v:NotifyLocalized("cChangeFaction", client:GetName(), target:GetName(), L(faction.name, v))
					end
				end
			else
				return "@charNotWhitelisted", target:GetName(), L(faction.name, client)
			end
		else
			return "@invalidFaction"
		end
	end
})

ix.command.Add("CharSetClass", {
	description = "@cmdCharSetClass",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.text
	},
	OnRun = function(self, client, target, class)
		local classTable

		for _, v in ipairs(ix.class.list) do
			if (ix.util.StringMatches(v.uniqueID, class) or ix.util.StringMatches(v.name, class)) then
				classTable = v
			end
		end

		if (classTable) then
			local oldClass = target:GetClass()
			local targetPlayer = target:GetPlayer()

			if (targetPlayer:Team() == classTable.faction) then
				target:SetClass(classTable.index)
				hook.Run("PlayerJoinedClass", targetPlayer, classTable.index, oldClass)

				targetPlayer:NotifyLocalized("becomeClass", L(classTable.name, targetPlayer))

				-- only send second notification if the character isn't setting their own class
				if (client != targetPlayer) then
					return "@setClass", target:GetName(), L(classTable.name, client)
				end
			else
				return "@invalidClassFaction"
			end
		else
			return "@invalidClass"
		end
	end
})

ix.command.Add("MapRestart", {
	description = "@cmdMapRestart",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, delay)
		delay = delay or 10
		ix.util.NotifyLocalized("mapRestarting", nil, delay)

		timer.Simple(delay, function()
			RunConsoleCommand("changelevel", game.GetMap())
		end)
	end
})
