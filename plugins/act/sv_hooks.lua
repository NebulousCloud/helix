
local PLUGIN = PLUGIN

util.AddNetworkString("ixActEnter")
util.AddNetworkString("ixActLeave")

function PLUGIN:CanPlayerEnterAct(client, modelClass, variant, act)
	if (!client:Alive() or client:GetLocalVar("ragdoll") or client:WaterLevel() > 0 or !client:IsOnGround()) then
		return false, L("notNow", client)
	end

	-- check if player's model class has an entry in this act table
	modelClass = modelClass or ix.anim.GetModelClass(client:GetModel())
	local data = act[modelClass]

	if (!data) then
		return false, L("modelNoSeq", client)
	end

	-- some models don't support certain variants
	local sequence = data.sequence[variant]

	if (!sequence) then
		return false, L("modelNoSeq", client)
	end

	return true
end

function PLUGIN:PlayerDeath(client)
	if (client.ixUntimedSequence) then
		client:SetNetVar("actEnterAngle")
		client:LeaveSequence()
		client.ixUntimedSequence = nil
	end
end

function PLUGIN:PlayerSpawn(client)
	if (client.ixUntimedSequence) then
		client:SetNetVar("actEnterAngle")
		client:LeaveSequence()
		client.ixUntimedSequence = nil
	end
end

function PLUGIN:OnCharacterFallover(client)
	if (client.ixUntimedSequence) then
		client:SetNetVar("actEnterAngle")
		client:LeaveSequence()
		client.ixUntimedSequence = nil
	end
end
