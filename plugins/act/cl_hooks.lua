
local animationTime = 2

local PLUGIN = PLUGIN
PLUGIN.cameraFraction = 0

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

function PLUGIN:PlayerBindPress(client, bind, bPressed)
	if (!client:GetNetVar("actEnterAngle")) then
		return
	end

	if (bind:find("+jump") and bPressed) then
		ix.command.Send("ExitAct")
		return true
	end
end

function PLUGIN:ShouldDrawLocalPlayer(client)
	if (client:GetNetVar("actEnterAngle") and self.cameraFraction > 0.25) then
		return true
	elseif (self.cameraFraction > 0.25) then
		return true
	end
end

local forwardOffset = 16
local backwardOffset = -32
local heightOffset = Vector(0, 0, 20)
local idleHeightOffset = Vector(0, 0, 6)
local traceMin = Vector(-4, -4, -4)
local traceMax = Vector(4, 4, 4)

function PLUGIN:CalcView(client, origin)
	local enterAngle = client:GetNetVar("actEnterAngle")
	local fraction = self.cameraFraction
	local offset = self.bIdle and forwardOffset or backwardOffset
	local height = self.bIdle and idleHeightOffset or heightOffset

	if (!enterAngle) then
		if (fraction > 0) then
			local view = {
				origin = LerpVector(fraction, origin, origin + self.forward * offset + height)
			}

			if (self.cameraTween) then
				self.cameraTween:update(FrameTime())
			end

			return view
		end

		return
	end

	local view = {}
	local forward = enterAngle:Forward()
	local head = GetHeadBone(client)

	local bFirstPerson = true

	if (ix.option.Get("thirdpersonEnabled", false)) then
		local originPosition = head and client:GetBonePosition(head) or client:GetPos()

		-- check if the camera will hit something
		local data = util.TraceHull({
			start = originPosition,
			endpos = originPosition - client:EyeAngles():Forward() * 48,
			mins = traceMin * 0.75,
			maxs = traceMax * 0.75,
			filter = client
		})

		bFirstPerson = data.Hit

		if (!bFirstPerson) then
			view.origin = data.HitPos
		end
	end

	if (bFirstPerson) then
		if (head) then
			local position = client:GetBonePosition(head) + forward * offset + height
			local data = {
				start = (client:GetBonePosition(head) or Vector(0, 0, 64)) + forward * 8,
				endpos = position + forward * offset,
				mins = traceMin,
				maxs = traceMax,
				filter = client
			}

			data = util.TraceHull(data)

			if (data.Hit) then
				view.origin = data.HitPos
			else
				view.origin = position
			end
		else
			view.origin = origin + forward * forwardOffset + height
		end
	end

	view.origin = LerpVector(fraction, origin, view.origin)

	if (self.cameraTween) then
		self.cameraTween:update(FrameTime())
	end

	return view
end

net.Receive("ixActEnter", function()
	PLUGIN.bIdle = net.ReadBool()
	PLUGIN.forward = LocalPlayer():GetNetVar("actEnterAngle"):Forward()
	PLUGIN.cameraTween = ix.tween.new(animationTime, PLUGIN, {
		cameraFraction = 1
	}, "outQuint")
end)

net.Receive("ixActLeave", function()
	PLUGIN.cameraTween = ix.tween.new(animationTime * 0.5, PLUGIN, {
		cameraFraction = 0
	}, "outQuint")
end)
