
PLUGIN.name = "Acts"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds acts that can be performed."
PLUGIN.acts = PLUGIN.acts or {}

ix.util.Include("sh_setup.lua")

for k, v in pairs(PLUGIN.acts) do
	local COMMAND = {
		description = "@cmdAct"
	}
	local multiple = false

	for _, v2 in pairs(v) do
		if (type(v2.sequence) == "table" and #v2.sequence > 1) then
			multiple = true

			break
		end
	end

	if (multiple) then
		COMMAND.arguments = bit.bor(ix.type.number, ix.type.optional)
	end

	function COMMAND:GetDescription()
		return L("cmdAct", k)
	end

	function COMMAND:OnRun(client, index)
		if (client.ixSeqUntimed) then
			client:SetNetVar("actAng")
			client:LeaveSequence()
			client.ixSeqUntimed = nil

			return
		end

		if (!client:Alive() or
			client:SetLocalVar("ragdoll") or
			client:WaterLevel() > 0) then
			return
		end

		if ((client.ixNextAct or 0) < CurTime()) then
			local class = ix.anim.GetModelClass(client:GetModel())
			local info = v[class]

			if (info) then
				if (info.onCheck) then
					local result = info.onCheck(client)

					if (result) then
						return result
					end
				end

				local sequence

				if (type(info.sequence) == "table") then
					index = math.Clamp(math.floor(index or 1), 1, #info.sequence)
					sequence = info.sequence[index]
				else
					sequence = info.sequence
				end

				local duration = client:ForceSequence(sequence, nil, info.untimed and 0 or nil)

				client.ixSeqUntimed = info.untimed
				client.ixNextAct = CurTime() + (info.untimed and 4 or duration) + 1
				client:SetNetVar("actAng", client:GetAngles())

				if (info.offset) then
					client.ixOldPosition = client:GetPos()
					client:SetPos(client:GetPos() + info.offset(client))
				end
			else
				return "@modelNoSeq"
			end
		end
	end

	ix.command.Add("Act"..k, COMMAND)
end

function PLUGIN:UpdateAnimation(client, moveData)
	local angles = client:GetNetVar("actAng")

	if (angles) then
		client:SetRenderAngles(angles)
	end
end

function PLUGIN:OnPlayerLeaveSequence(client)
	client:SetNetVar("actAng")

	if (client.ixOldPosition) then
		client:SetPos(client.ixOldPosition)
		client.ixOldPosition = nil
	end
end

function PLUGIN:PlayerDeath(client)
	if (client.ixSeqUntimed) then
		client:SetNetVar("actAng")
		client:LeaveSequence()
		client.ixSeqUntimed = nil
	end
end

function PLUGIN:PlayerSpawn(client)
	if (client.ixSeqUntimed) then
		client:SetNetVar("actAng")
		client:LeaveSequence()
		client.ixSeqUntimed = nil
	end
end

function PLUGIN:OnCharFallover(client)
	if (client.ixSeqUntimed) then
		client:SetNetVar("actAng")
		client:LeaveSequence()
		client.ixSeqUntimed = nil
	end
end

function PLUGIN:ShouldDrawLocalPlayer(client)
	if (client:GetNetVar("actAng")) then
		return true
	end
end

local GROUND_PADDING = Vector(0, 0, 8)
local PLAYER_OFFSET = Vector(0, 0, 72)

function PLUGIN:CalcView(client, origin, angles, fov)
	if (client:GetNetVar("actAng")) then
		local view = {}
			local data = {}
				data.start = client:GetPos() + PLAYER_OFFSET
				data.endpos = data.start - client:EyeAngles():Forward() * 72
				data.mins = Vector(-10, -10, -10)
				data.maxs = Vector(10, 10, 10)
				data.filter = client
			view.origin = util.TraceHull(data).HitPos + GROUND_PADDING
			view.angles = client:EyeAngles()
		return view
	end
end

function PLUGIN:PlayerBindPress(client, bind, pressed)
	if (client:GetNetVar("actAng")) then
		bind = bind:lower()

		if (bind:find("+jump") and pressed) then
			ix.command.Send("actsit")

			return true
		end
	end
end
