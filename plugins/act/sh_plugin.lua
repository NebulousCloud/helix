
--[[--
Provides players the ability to perform animations.

]]
-- @module ix.act

local PLUGIN = PLUGIN

PLUGIN.name = "Player Acts"
PLUGIN.description = "Adds animations that can be performed by certain models."
PLUGIN.author = "`impulse"

ix.act = ix.act or {}
ix.act.stored = ix.act.stored or {}

--- Registers a sequence as a performable animation.
-- @realm shared
-- @string name Name of the animation (in CamelCase)
-- @string modelClass Model class to add this animation to
-- @tab data An `ActInfoStructure` table describing the animation
function ix.act.Register(name, modelClass, data)
	ix.act.stored[name] = ix.act.stored[name] or {} -- might be adding onto an existing act

	if (!data.sequence) then
		return ErrorNoHalt(string.format(
			"Act '%s' for '%s' tried to register without a provided sequence\n", name, modelClass
		))
	end

	if (!istable(data.sequence)) then
		data.sequence = {data.sequence}
	end

	if (data.start and istable(data.start) and #data.start != #data.sequence) then
		return ErrorNoHalt(string.format(
			"Act '%s' tried to register without matching number of enter sequences\n", name
		))
	end

	if (data.finish and istable(data.finish) and #data.finish != #data.sequence) then
		return ErrorNoHalt(string.format(
			"Act '%s' tried to register without matching number of exit sequences\n", name
		))
	end

	if (istable(modelClass)) then
		for _, v in ipairs(modelClass) do
			ix.act.stored[name][v] = data
		end
	else
		ix.act.stored[name][modelClass] = data
	end
end

--- Removes a sequence from being performable if it has been previously registered.
-- @realm shared
-- @string name Name of the animation
function ix.act.Remove(name)
	ix.act.stored[name] = nil
	ix.command.list["Act" .. name] = nil
end

ix.util.Include("sh_definitions.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

function PLUGIN:InitializedPlugins()
	hook.Run("SetupActs")
	hook.Run("PostSetupActs")
end

function PLUGIN:ExitAct(client)
	client.ixUntimedSequence = nil
	client:SetNetVar("actEnterAngle")

	net.Start("ixActLeave")
	net.Send(client)
end

function PLUGIN:PostSetupActs()
	-- create chat commands for all stored acts
	for act, classes in pairs(ix.act.stored) do
		local variants = 1
		local COMMAND = {}

		-- check if this act has any variants (i.e /ActSit 2)
		for _, v in pairs(classes) do
			if (#v.sequence > 1) then
				variants = math.max(variants, #v.sequence)
			end
		end

		-- setup command arguments if there are variants for this act
		if (variants > 1) then
			COMMAND.arguments = bit.bor(ix.type.number, ix.type.optional)
			COMMAND.argumentNames = {"variant (1-" .. variants .. ")"}
		end

		COMMAND.GetDescription = function(command)
			return L("cmdAct", act)
		end

		-- we'll perform a model class check in OnCheckAccess to prevent the command from showing up on the client at all
		COMMAND.OnCheckAccess = function(command, client)
			local modelClass = ix.anim.GetModelClass(client:GetModel())

			if (!classes[modelClass]) then
				return false, "modelNoSeq"
			end

			return true
		end

		COMMAND.OnRun = function(command, client, variant)
			variant = math.Clamp(tonumber(variant) or 1, 1, variants)

			if (client:GetNetVar("actEnterAngle")) then
				return "@notNow"
			end

			local modelClass = ix.anim.GetModelClass(client:GetModel())
			local bCanEnter, error = PLUGIN:CanPlayerEnterAct(client, modelClass, variant, classes)

			if (!bCanEnter) then
				return error
			end

			local data = classes[modelClass]
			local mainSequence = data.sequence[variant]
			local mainDuration

			-- check if the main sequence has any extra info
			if (istable(mainSequence)) then
				-- any validity checks to perform (i.e facing a wall)
				if (mainSequence.check) then
					local result = mainSequence.check(client)

					if (result) then
						return result
					end
				end

				-- position offset
				if (mainSequence.offset) then
					client.ixOldPosition = client:GetPos()
					client:SetPos(client:GetPos() + mainSequence.offset(client))
				end

				mainDuration = mainSequence.duration
				mainSequence = mainSequence[1]
			end

			local startSequence = data.start and data.start[variant] or ""
			local startDuration

			if (istable(startSequence)) then
				startDuration = startSequence.duration
				startSequence = startSequence[1]
			end

			client:SetNetVar("actEnterAngle", client:GetAngles())

			client:ForceSequence(startSequence, function()
				-- we've finished the start sequence
				client.ixUntimedSequence = data.untimed -- client can exit after the start sequence finishes playing

				local duration = client:ForceSequence(mainSequence, function()
					-- we've stopped playing the main sequence (either duration expired or user cancelled the act)
					if (data.finish) then
						local finishSequence = data.finish[variant]
						local finishDuration

						if (istable(finishSequence)) then
							finishDuration = finishSequence.duration
							finishSequence = finishSequence[1]
						end

						client:ForceSequence(finishSequence, function()
							-- client has finished the end sequence and is no longer playing any animations
							self:ExitAct(client)
						end, finishDuration)
					else
						-- there's no end sequence so we can exit right away
						self:ExitAct(client)
					end
				end, data.untimed and 0 or (mainDuration or nil))

				if (!duration) then
					-- the model doesn't support this variant
					self:ExitAct(client)
					client:NotifyLocalized("modelNoSeq")

					return
				end
			end, startDuration, nil)

			net.Start("ixActEnter")
				net.WriteBool(data.idle or false)
			net.Send(client)

			client.ixNextAct = CurTime() + 4
		end

		ix.command.Add("Act" .. act, COMMAND)
	end

	-- setup exit act command
	local COMMAND = {
		OnRun = function(command, client)
			if (client.ixUntimedSequence) then
				client:LeaveSequence()
			end
		end
	}

	if (CLIENT) then
		-- hide this command from the command list
		COMMAND.OnCheckAccess = function(client)
			return false
		end
	end

	ix.command.Add("ExitAct", COMMAND)
end

function PLUGIN:UpdateAnimation(client, moveData)
	local angle = client:GetNetVar("actEnterAngle")

	if (angle) then
		client:SetRenderAngles(angle)
	end
end

do
	local keyBlacklist = IN_ATTACK + IN_ATTACK2

	function PLUGIN:StartCommand(client, command)
		if (client:GetNetVar("actEnterAngle")) then
			command:RemoveKey(keyBlacklist)
		end
	end
end
