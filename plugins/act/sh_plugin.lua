
PLUGIN.name = "Acts"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds acts that can be performed."
PLUGIN.acts = PLUGIN.acts or {}

nut.util.Include("sh_setup.lua")

for k, v in pairs(PLUGIN.acts) do
	local data = {}
		local multiple = false

		for k2, v2 in pairs(v) do
			if (type(v2.sequence) == "table" and #v2.sequence > 1) then
				multiple = true

				break
			end
		end

		if (multiple) then
			data.syntax = "[number type]"
		end

		data.OnRun = function(self, client, arguments)
			if (client.nutSeqUntimed) then
				client:SetNetVar("actAng")
				client:LeaveSequence()
				client.nutSeqUntimed = nil

				return
			end

			if (!client:Alive() or
				client:SetLocalVar("ragdoll")) then
				return
			end

			if ((client.nutNextAct or 0) < CurTime()) then
				local class = nut.anim.GetModelClass(client:GetModel())
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
						local index = math.Clamp(math.floor(tonumber(arguments[1]) or 1), 1, #info.sequence)

						sequence = info.sequence[index]
					else
						sequence = info.sequence
					end

					local duration = client:ForceSequence(sequence, nil, info.untimed and 0 or nil)

					client.nutSeqUntimed = info.untimed
					client.nutNextAct = CurTime() + (info.untimed and 4 or duration) + 1
					client:SetNetVar("actAng", client:GetAngles())

					if (info.offset) then
						client.nutOldPosition = client:GetPos()
						client:SetPos(client:GetPos() + info.offset(client))
					end
				else
					return "@modelNoSeq"
				end
			end
		end
	nut.command.Add("Act"..k, data)
end

function PLUGIN:UpdateAnimation(client, moveData)
	local angles = client:GetNetVar("actAng")

	if (angles) then
		client:SetRenderAngles(angles)
	end
end

function PLUGIN:OnPlayerLeaveSequence(client)
	client:SetNetVar("actAng")
	
	if (client.nutOldPosition) then
		client:SetPos(client.nutOldPosition)
		client.nutOldPosition = nil
	end
end

function PLUGIN:PlayerDeath(client)
	if (client.nutSeqUntimed) then
		client:SetNetVar("actAng")
		client:LeaveSequence()
		client.nutSeqUntimed = nil
	end
end

function PLUGIN:OnCharFallover(client)
	if (client.nutSeqUntimed) then
		client:SetNetVar("actAng")
		client:LeaveSequence()
		client.nutSeqUntimed = nil
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
			nut.command.Send("actsit")

			return true
		end
	end
end
