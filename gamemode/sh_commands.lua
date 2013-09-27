--[[
	Purpose: Creates default chat commands here.
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
	allowDead = true,
	onRun = function(client, arguments)
		local text = table.concat(arguments, " ")
		
		if (!text) then
			nut.util.Notify("You provided an invalid description.", client)
			
			return
		end

		if (#text < nut.config.descMinChars) then
			nut.util.Notify("Your description needs to be at least "..nut.config.descMinChars.." character(s).")

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
}, "chardesc")

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

		if (IsValid(target)) then
			if (!arguments[2]) then
				nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

				return
			end

			target:TakeFlag(arguments[2])

			nut.util.Notify(nut.lang.Get("flags_take", client:Name(), arguments[2], target:Name()))
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
			target.character:SetVar("model", model)
			
			nut.util.Notify(client:Name().." has changed "..target:Name().."'s model to "..arguments[2]..".")
		end
	end
}, "charsetmodel")

nut.command.Register({
	adminOnly = true,
	allowDead = true,
	syntax = "<string name> <string newName>",
	onRun = function(client, arguments)
		local target = nut.command.FindPlayer(client, arguments[1])

		if (IsValid(target)) then
			table.remove(arguments, 1)

			local name = table.concat(arguments, " ")

			if (name and string.find(name, "%S")) then
				local oldName = target:Name()
				target.character:SetVar("charname", name)

				nut.util.Notify(client:Name().." has changed "..oldName.."'s name to "..name..".")
			else
				nut.util.Notify("You provided an invalid name.", client)
			end
		end
	end
}, "charsetname")

nut.command.Register({
	syntax = "[number time]",
	onRun = function(client, arguments)
		local time = math.max(tonumber(arguments[1] or "") or 0, 0)
		local entity = Entity(client:GetNetVar("ragdoll", -1))
		
		if nut.schema.Call( "CanFallOver", client ) == false then return end --** to prevent some bugs with charfallover.
		
		if (!IsValid(entity)) then
			client:SetTimedRagdoll(time)
			client:SetNutVar("fallGrace", CurTime() + 5)
		else
			nut.util.Notify("You are already fallen over.", client)
		end
	end
}, "charfallover")

nut.command.Register({
	onRun = function(client, arguments)
		if (client:GetNutVar("fallGrace", 0) >= CurTime()) then
			nut.util.Notify("You must wait before getting up.", client)

			return
		end
		
		local entity = Entity(client:GetNetVar("ragdoll", -1))

		if (IsValid(entity)) then
			local velocity = entity:GetVelocity():Length2D()

			if (velocity <= 8) then
				client:SetMainBar("You are now getting up.", 5)

				timer.Create("nut_CharGetUp"..client:UniqueID(), 5, 1, function()
					if (IsValid(client)) then
						client:UnRagdoll()
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
					target:UpdateInv(v.uniqueID, amount)

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
	onRun = function(client, arguments)
		math.randomseed(CurTime())

		local roll = math.random(1, 100)
		roll = nut.schema.Call("GetRollAmount", client, roll) or roll

		nut.chat.Send(client, "roll", client:Name().." has rolled "..roll..".")
	end
}, "roll")

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
					target.character:SetData("groups", groups)

					groups[v.id] = 1
					nut.util.Notify(client:Name().." has enabled "..target:Name().."'s "..v.name.." bodygroup.")

					return
				else
					target:SetBodygroup(v.id, 0)
					target.character:SetData("groups", groups)

					groups[v.id] = 0
					nut.util.Notify(client:Name().." has disabled "..target:Name().."'s "..v.name.." bodygroup.")

					return
				end
			end
		end

		nut.util.Notify("You provided an invalid bodygroup.", client)
	end
}, "charsetbodygroup")
