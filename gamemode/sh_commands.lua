--[[

	Purpose: Creates default chat commands here.

--]]

--[[

	Category: IC Essensial Chat Commands.
	Any Chat Commands that related with character goes here.

--]]

nut.command.Register({
	onRun = function(client, arguments)
		if (client:GetNutVar("nextRaise", 0) < CurTime()) then
			local weapon = client:GetActiveWeapon()

			if (!IsValid(weapon)) then
				return
			end

			if (weapon.AlwaysRaised or nut.config.alwaysRaised[weapon:GetClass()]) then
				return
			end

			client:SetWepRaised(!client:WepRaised())
			client:SetNutVar("nextRaise", CurTime() + 0.6)
		end
	end
}, "toggleraise")

nut.command.Register({
	onRun = function(client, arguments)
		math.randomseed(CurTime())

		local roll = math.random(1, 100)
		roll = nut.schema.Call("GetRollAmount", client, roll) or roll

		nut.chat.Send(client, "roll", client:Name().." has rolled "..roll..".")
	end
}, "roll")

nut.command.Register({
	allowDead = true,
	syntax = "<string name> <string message>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (target) then
			table.remove(arguments, 1)
			local text = table.concat(arguments, " ")

			if (!text or #text < 1) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			local voiceMail = target.character:GetData("voicemail")

			if (voiceMail) then
				nut.chat.Send(client, "pm", target:Name()..": "..voiceMail)

				return
			end
			
			local message = client:Name()..": "..text

			nut.chat.Send(client, "pm", message)
			nut.chat.Send(target, "pm", message)
		end
	end
}, "pm")

nut.command.Register({
	allowDead = true,
	syntax = "[string message]",
	onRun = function(client, arguments)
		local message = table.concat(arguments, " ")
		local delete = false

		if (!string.find(message, "%S")) then
			client.character:SetData("voicemail", nil)
			nut.util.Notify("You have deleted your voicemail.", client)
		else
			client.character:SetData("voicemail", message)
			nut.util.Notify("You have changed your voicemail.", client)
		end
	end
}, "setvoicemail")

nut.command.Register({
	syntax = "<number amount>",
	onRun = function(client, arguments)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*84
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and entity:IsPlayer() and entity.character) then
			local amount = tonumber(arguments[1])

			if (!amount) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			if (amount < 5) then
				nut.util.Notify("The amount must be at least "..nut.currency.GetName(5)..".", client)

				return
			end

			if (client:GetMoney() - amount < 0) then
				nut.util.Notify("You do not have enough money to give that amount.", client)

				return
			end

			entity:GiveMoney(amount)
			client:TakeMoney(amount)
		else
			nut.util.Notify("You are not looking at a valid player.", client)
		end
	end
}, "givemoney")

nut.command.Register({
	syntax = "<number amount>",
	onRun = function(client, arguments)
		local amount = tonumber(arguments[1])

		if (!amount) then
			nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

			return
		end

		if (amount < 5) then
			nut.util.Notify("The amount must be at least "..nut.currency.GetName(5)..".", client)

			return
		end

		if (client:GetMoney() - amount < 0) then
			nut.util.Notify("You do not have enough money to drop that amount.", client)

			return
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*54
			data.filter = client
		local trace = util.TraceLine(data)
		local position = trace.HitPos

		if (position) then
			local entity = nut.currency.Spawn(amount, position + Vector(0, 0, 16), nil, client)

			if (IsValid(entity)) then
				client:TakeMoney(amount)
			end
		end
	end
}, "dropmoney")



--[[

	Category: Actual Player related Chat Commands.
	Any Chat Commands that related with character goes here.

--]]



nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <string flag>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			if (!arguments[2]) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			target:GiveFlag(arguments[2])

			nut.util.Notify(nut.lang.Get("flags_give", client:Name(), arguments[2], target:Name()))
		end
	end
}, "flaggive")

nut.command.Register({
	allowDead = true,
	adminOnly = true,
	syntax = "<string name> <string flag>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])
		local flags = table.concat(arguments, " ", 2)
		local function takeFlag()
			if (IsValid(target)) then
				if (!flags) then
					nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

					return
				end

				target:TakeFlag(flags)

				nut.util.Notify(nut.lang.Get("flags_take", client:Name(), flags, target:Name()))
			end
		end

		if (!string.find(flags, "%S")) then
			client:StringRequest("Take Flags", "Enter the flag(s) to take from the player.", function(text)
				flags = text
				takeFlag()
			end, nil, target:GetFlagString())
		else
			takeFlag()
		end
	end
}, "flagtake")

nut.command.Register({
	superAdminOnly = true,
	allowDead = true,
	syntax = "<string name> <string faction>",
		onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			if (!arguments[2]) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			local faction

			for k, v in pairs(nut.faction.GetAll()) do
				if (nut.util.StringMatches(arguments[2], v.name)) then
					faction = v

					break
				end
			end

			if (faction) then
				if (nut.faction.CanBe(target, faction.index)) then
					nut.util.Notify(nut.lang.Get("already_whitelisted"), target)

					return
				end

				target:GiveWhitelist(faction.index)

				nut.util.Notify(nut.lang.Get("whitelisted", client:Name(), target:Name(), faction.name))
			else
				nut.util.Notify(nut.lang.Get("invalid_faction"), client)
			end
		end
	end
}, "plywhitelist")

nut.command.Register({
	superAdminOnly = true,
	allowDead = true,
	syntax = "<string name> <string faction>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			if (!arguments[2]) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			local faction

			for k, v in pairs(nut.faction.GetAll()) do
				if (nut.util.StringMatches(arguments[2], v.name)) then
					faction = v

					break
				end
			end

			if (faction) then
				if (!nut.faction.CanBe(target, faction.index)) then
					nut.util.Notify(nut.lang.Get("not_whitelisted"), target)

					return
				end

				target:TakeWhitelist(faction.index)

				nut.util.Notify(nut.lang.Get("blacklisted", client:Name(), target:Name(), faction.name))
			else
				nut.util.Notify(nut.lang.Get("invalid_faction"), client)
			end
		end
	end
}, "plyunwhitelist")



--[[

	Category: Character Modification/Management related Chat Commands.
	Any Chat Commands that related with character goes here.

--]]

local function sameSchema() 
	-- Brought from the sh_character.

	return " AND rpschema = '"..SCHEMA.uniqueID.."'"
end

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (target) then

			local index = target.character.index or nil	
			local charname = target.character:GetVar("charname")

			if (index and target.characters and table.HasValue(target.characters, index)) then
				for k, v in pairs(target.characters) do
					if (v == index) then
						target.characters[k] = nil
					end
				end

				nut.db.Query("DELETE FROM "..nut.config.dbTable.." WHERE steamid = "..target:SteamID64().." AND id = "..index..sameSchema(), function(data)
					if (IsValid(target) and target.character and target.character.index == index) then
						if (target.nut_CachedChars) then
							target.nut_CachedChars[target.character.index] = nil
						end
						
						target.character = nil
						target:KillSilent()

						timer.Simple(0, function()
							netstream.Start(target, "nut_CharMenu", {true, true, index})
						end)
					end

					nut.util.AddLog( client:Name().." Deleted character #"..index..", "..charname.."("..target:Name()..").", LOG_FILTER_MAJOR)
				end)
			else
				ErrorNoHalt("Attempt to delete invalid character! ("..index..")")
			end

			nut.util.Notify(client:Name().." has removed "..charname.." from the world.")
		end
	end
}, "chardelete")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <number amount>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (target) then
			local amount = tonumber(arguments[2])

			if (!amount) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			target:GiveMoney(amount)
			nut.util.Notify(client:Name().." has given "..nut.currency.GetName(amount).." to "..target:Name()..".")
		end
	end
}, "chargivemoney")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <number amount>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (target) then
			local amount = tonumber(arguments[2])

			if (!amount) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			target:GiveMoney(-amount)
			nut.util.Notify(client:Name().." has taken "..nut.currency.GetName(amount).." from "..target:Name()..".")
		end
	end
}, "chartakemoney")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <number amount>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (target) then
			local amount = tonumber(arguments[2])

			if (!amount) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			target:SetMoney(amount)
			nut.util.Notify(client:Name().." has set "..target:Name().."'s money to "..amount..".")
		end
	end
}, "charsetmoney")

nut.command.Register({
	allowDead = true,
	onRun = function(client, arguments)
		local text = table.concat(arguments, " ")
		local function changeDesc()
			if (!text) then
				nut.util.Notify("You provided an invalid description.", client)
				
				return
			end

			if (#text < nut.config.descMinChars) then
				nut.util.Notify("Your description needs to be at least "..nut.config.descMinChars.." character(s).", client)

				return
			end

			local description = client.character:GetVar("description", "")
			
			if (string.lower(description) == string.lower(text)) then
				nut.util.Notify("You need to provide a different description.", client)
				
				return
			end
			
			client.character:SetVar("description", text)
			nut.util.Notify("You have changed your character's description.", client)
		end

		if (!string.find(text, "%S")) then
			client:StringRequest("Change Description", "Entire your desired description.", function(text2)
				text = text2
				changeDesc()
			end, nil, client.character:GetVar("description", ""))
		else
			changeDesc()
		end
	end
}, "chardesc")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <string model> [number skin]",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			if (!arguments[2]) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			local model = string.lower(arguments[2])

			target:SetModel(model)
			target:SetSkin(tonumber(arguments[3]) or 0)
			target.character.model = model
			target:UpdateCharInfo()
			
			nut.util.Notify(client:Name().." has changed "..target:Name().."'s model to "..arguments[2]..".")
		end
	end
}, "charsetmodel")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> [string customClass]",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			table.remove(arguments, 1)
			local customClass = table.concat(arguments, " ")

			if (customClass == "") then
				customClass = nil
			end

			target:SetNetVar("customClass", customClass)
			nut.util.Notify(client:Name().." has changed "..target:Name().."'s custom class to "..(customClass or "nothing")..".")
		end
	end	
}, "charsetcustomclass")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <string newName>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			table.remove(arguments, 1)

			local name = table.concat(arguments, " ")
			local function changeName(text)
				if (!IsValid(target) or !IsValid(client)) then
					return
				end

				if (name and string.find(name, "%S")) then
					local oldName = target:Name()
					target.character:SetVar("charname", name)

					nut.util.Notify(client:Name().." has changed "..oldName.."'s name to "..name..".")
				else
					nut.util.Notify("You provided an invalid name.", client)
				end
			end

			if (!string.find(name, "%S")) then
				client:StringRequest("Change Name", "Enter the player's new name.", function(text)
					name = text
					changeName()
				end, nil, target:Name())
			else
				changeName()
			end
		end
	end
}, "charsetname")

nut.command.Register({
	syntax = "[number time]",
	onRun = function(client, arguments)
		local time

		if (arguments[1] and arguments[1] == "0") then
			time = 0
		else
			time = math.max(tonumber(arguments[1] or "") or 5, 5)
		end
		
		if nut.schema.Call( "CanFallOver", client ) == false then return end --** to prevent some bugs with charfallover.
		
		if (!client:IsRagdolled()) then
			client:SetTimedRagdoll(time)
			client:SetNutVar("fallGrace", CurTime() + 5)
		else
			nut.util.Notify("You are already fallen over.", client)
		end
	end
}, "charfallover")

nut.command.Register({
	onRun = function(client, arguments)
		if (client:GetNutVar("noGetUp")) then
			return
		end

		if (client:GetNutVar("fallGrace", 0) >= CurTime()) then
			nut.util.Notify("You must wait before getting up.", client)

			return
		end

		local ragdolled, entity = client:IsRagdolled()

		if (IsValid(entity) and ragdolled and !client:GetNetVar("gettingUp")) then
			local velocity = entity:GetVelocity():Length2D()

			if (velocity <= 8) then
				client:SetMainBar("You are now getting up.", 5)
				client:SetNetVar("gettingUp", true)

				timer.Create("nut_CharGetUp"..client:UniqueID(), 5, 1, function()
					if (IsValid(client)) then
						client:UnRagdoll()
						client:SetNetVar("gettingUp", false)
					end
				end)
			else
				nut.util.Notify("Your body can not be moving while getting up.", client)
			end
		else
			nut.util.Notify("You have not fallen over.", client)
		end
	end
}, "chargetup")

nut.command.Register({
	adminOnly = true,
	syntax = "<string name> <string item> [number amount]",
	onRun = function(client, arguments)
		local name = arguments[1] or ""
		local find = arguments[2] or ""
		local amount = math.max(tonumber(arguments[3] or "") or 1, 1)
		local target = nut.command.FindPlayer(client, name)

		if (IsValid(target)) then
			for k, v in pairs(nut.item.GetAll()) do
				if (nut.util.StringMatches(find, v.name) or nut.util.StringMatches(find, v.uniqueID)) then
					target:UpdateInv(v.uniqueID, amount, nil, true)

					nut.util.Notify("You have given "..target:Name().." "..amount.." "..v.name.." item(s).", client)
					nut.util.Notify(target:Name().." has given you "..amount.." "..v.name.." item(s).", target)

					return
				end
			end

			nut.util.Notify("You specified an invalid item.", client)
		end
	end
}, "chargiveitem")

nut.command.Register({
	adminOnly = true,
	syntax = "<string name> <string group> [bool active]",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (!IsValid(target)) then
			return
		end

		local group = arguments[2]
		local active = util.tobool(arguments[3] or "true")

		if (!group) then
			nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

			return
		end

		for k, v in pairs(target:GetBodyGroups()) do
			local groups = target.character:GetData("groups", {})

			if (v.id > 0 and (tostring(v.id) == group or nut.util.StringMatches(group, v.name))) then
				if (active) then
					target:SetBodygroup(v.id, 1)
					groups[v.id] = 1
					target.character:SetData("groups", groups, nil, true)

					nut.util.Notify(client:Name().." has enabled "..target:Name().."'s "..v.name.." bodygroup.")

					return
				else
					target:SetBodygroup(v.id, 0)
					groups[v.id] = 0
					target.character:SetData("groups", groups, nil, true)

					nut.util.Notify(client:Name().." has disabled "..target:Name().."'s "..v.name.." bodygroup.")

					return
				end
			end
		end

		nut.util.Notify("You provided an invalid bodygroup.", client)
	end
}, "charsetbodygroup")
