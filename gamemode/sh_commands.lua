--[[
	Purpose: Creates default chat commands here.
--]]

-- Define a table for a command.
local COMMAND = {}

-- Help text will appear in a help menu that describes what the command does.
COMMAND.help = "Either raises or lowers the current weapon."

-- Similar to console commands, gets called when the command is ran either using ns <command> or !<command>.
function COMMAND:OnRun(client, arguments)
	if ((client.nut_NextRaise or 0) < CurTime()) then
		local weapon = client:GetActiveWeapon()

		if (!IsValid(weapon)) then
			return
		end

		if (weapon.AlwaysRaised or nut.config.alwaysRaised[weapon:GetClass()]) then
			return
		end

		client:SetWepRaised(!client:WepRaised())
		client.nut_NextRaise = CurTime() + 0.6
	end
end

-- Registers the command with the command system.
nut.command.Register(COMMAND, "toggleraise")

local COMMAND = {}
COMMAND.adminOnly = true
COMMAND.help = "<string name>"

function COMMAND:OnRun(client, arguments)
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

nut.command.Register(COMMAND, "flaggive")

local COMMAND = {}
COMMAND.adminOnly = true
COMMAND.help = "<string name>"

function COMMAND:OnRun(client, arguments)
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

nut.command.Register(COMMAND, "flagtake")

local COMMAND = {}
COMMAND.superAdminOnly = true
COMMAND.help = "<string name> <string faction>"

function COMMAND:OnRun(client, arguments)
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

nut.command.Register(COMMAND, "plywhitelist")

local COMMAND = {}
COMMAND.superAdminOnly = true
COMMAND.help = "<string name> <string faction>"

function COMMAND:OnRun(client, arguments)
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

nut.command.Register(COMMAND, "plyunwhitelist")

local COMMAND = {}
COMMAND.adminOnly = true
COMMAND.help = "<string name> <string faction>"

function COMMAND:OnRun(client, arguments)
	local target = nut.command.FindPlayer(client, arguments[1])

	if (IsValid(target)) then
		if (!arguments[2]) then
			nut.util.Notify(nut.lang.Get("missing_arg", 2), client)

			return
		end

		target:SetModel(string.lower(arguments[2]))
		nut.util.Notify(client:Name().." has changed "..target:Name().."'s model to "..arguments[2]..".")
	end
end

nut.command.Register(COMMAND, "charsetmodel")