
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
			client:SetNetVar("actEnterAngle")
			client:LeaveSequence()
			client.ixSeqUntimed = nil

			return
		end

		if (!client:Alive() or
			client:SetLocalVar("ragdoll") or
			client:WaterLevel() > 0 or
			!client:IsOnGround()) then
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
				client:SetNetVar("actEnterAngle", client:GetAngles())

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
	local angles = client:GetNetVar("actEnterAngle")

	if (angles) then
		client:SetRenderAngles(angles)
	end
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function PLUGIN:StartCommand(client, command)
	if (client:GetNetVar("actEnterAngle")) then
		command:RemoveKey(KEY_BLACKLIST)
	end
end

if (SERVER) then
	function PLUGIN:PlayerLeaveSequence(client)
		client:SetNetVar("actEnterAngle")

		if (client.ixOldPosition) then
			client:SetPos(client.ixOldPosition)
			client.ixOldPosition = nil
		end
	end

	function PLUGIN:PlayerDeath(client)
		if (client.ixSeqUntimed) then
			client:SetNetVar("actEnterAngle")
			client:LeaveSequence()
			client.ixSeqUntimed = nil
		end
	end

	function PLUGIN:PlayerSpawn(client)
		if (client.ixSeqUntimed) then
			client:SetNetVar("actEnterAngle")
			client:LeaveSequence()
			client.ixSeqUntimed = nil
		end
	end

	function PLUGIN:OnCharacterFallover(client)
		if (client.ixSeqUntimed) then
			client:SetNetVar("actEnterAngle")
			client:LeaveSequence()
			client.ixSeqUntimed = nil
		end
	end
else
	local function GetHeadBone(client)
		local head

		for i = 1, client:GetBoneCount() do
			local name = client:GetBoneName(i)

			if (string.find(name:lower(), "head")) then
				head = i
				break
			end
		end

		return head
	end

	function PLUGIN:PlayerEnterSequence(client)
		if (client != LocalPlayer()) then
			return
		end

		if (!ix.option.Get("thirdpersonEnabled", false)) then
			local head = GetHeadBone(client)

			if (head) then
				client:ManipulateBoneScale(head, vector_origin)
			end
		end
	end

	function PLUGIN:PlayerLeaveSequence(client)
		if (client != LocalPlayer()) then
			return
		end

		local head = GetHeadBone(client)

		if (head) then
			client:ManipulateBoneScale(head, Vector(1, 1, 1))
		end
	end

	function PLUGIN:ShouldDrawLocalPlayer(client)
		if (client:GetNetVar("actEnterAngle")) then
			return true
		end
	end

	function PLUGIN:ThirdPersonToggled(oldValue, value)
		if (LocalPlayer():GetNetVar("actEnterAngle")) then
			local head = GetHeadBone(LocalPlayer())

			if (head) then
				LocalPlayer():ManipulateBoneScale(head, value and Vector(1, 1, 1) or vector_origin)
			end
		end
	end

	local GROUND_PADDING = Vector(0, 0, 8)
	local PLAYER_OFFSET = Vector(0, 0, 64)

	function PLUGIN:CalcView(client, origin)
		local enterAngle = client:GetNetVar("actEnterAngle")

		if (!enterAngle) then
			return
		end

		local view = {
			angles = client:EyeAngles()
		}

		if (ix.option.Get("thirdpersonEnabled", false)) then
			local data = {}
				data.start = client:GetPos() + PLAYER_OFFSET
				data.endpos = data.start - client:EyeAngles():Forward() * 48
				data.mins = Vector(-10, -10, -10)
				data.maxs = Vector(10, 10, 10)
				data.filter = client
			view.origin = util.TraceHull(data).HitPos + GROUND_PADDING
		else
			local head = GetHeadBone(client)

			if (head) then
				local forward = enterAngle:Forward()
				local position = client:GetBonePosition(head) + forward * 2 + Vector(0, 0, 3.5)

				local data = {
					start = position,
					endpos = position + forward * 5,
					mins = Vector(-2, -2, -2),
					maxs = Vector(2, 2, 2),
					filter = client
				}

				if (util.TraceHull(data).Hit) then
					view.origin = origin
				else
					view.origin = position
				end
			else
				view.origin = origin
			end
		end

		return view
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		if (client:GetNetVar("actEnterAngle")) then
			bind = bind:lower()

			if (bind:find("+jump") and pressed) then
				ix.command.Send("actsit")

				return true
			end
		end
	end
end
