-- ALl of this just for hands that match the player model.
-- And we'll include some misc. player stuff too.

local PLAYER = {}
PLAYER.DisplayName = "NutScript Player"

local modelList = {}

for k, v in pairs(player_manager.AllValidModels()) do
	modelList[string.lower(v)] = k
end

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Bool", 0, "NutWepRaised")

	if (SERVER and #player.GetAll() > 1) then
		net.Start("nut_PlayerDataTables")
		net.Broadcast()
	end
end

function PLAYER:GetHandsModel()
	local model = string.lower(self.Player:GetModel())

	for k, v in pairs(modelList) do
		if (string.find(string.gsub(model, "_", ""), v)) then
			model = v

			break
		end
	end

	return player_manager.TranslatePlayerHands(model)
end

local playerMeta = FindMetaTable("Player")

-- Weapon raising/lowering stuff.
do
	function playerMeta:WepRaised()
		if (CLIENT and self != LocalPlayer() and !self.GetNutWepRaised) then
			RunConsoleCommand("ns_sendplydt")
		end
		
		return self.GetNutWepRaised and self:GetNutWepRaised() or false
	end

	if (SERVER) then
		util.AddNetworkString("nut_PlayerDataTables")

		function playerMeta:SetWepRaised(raised, weapon)
			if (!IsValid(self) or !self.character) then
				return
			end

			self:SetNutWepRaised(raised)

			weapon = weapon or self:GetActiveWeapon()

			if (IsValid(weapon)) then
				local time = 9001

				if (weapon.FireWhenLowered or raised) then
					time = 0.8
				end

				weapon:SetNextPrimaryFire(CurTime() + time)
				weapon:SetNextSecondaryFire(CurTime() + time)
			end
		end

		hook.Add("PlayerSwitchWeapon", "nut_AutoLower", function(client, oldWeapon, newWeapon)
			client:DrawViewModel(newWeapon.DrawViewModel != false)

			if (!newWeapon.AlwaysRaised and !nut.config.alwaysRaised[newWeapon:GetClass()]) then
				client:SetWepRaised(false, newWeapon)

				-- Need this some some SWEPs can override the first time we set it to false.
				timer.Simple(0.5, function()
					if (!IsValid(client)) then
						return
					end

					client:SetWepRaised(false, newWeapon)
				end)
			else
				client:SetWepRaised(true, newWeapon)
			end
		end)

		concommand.Add("ns_sendplydt", function(client, command, arguments)
			if (#player.GetAll() < 2) then
				return
			end
			
			if ((client.nut_NextUpdate or 0) < CurTime()) then
				net.Start("nut_PlayerDataTables")
				net.Send(client)

				client.nut_NextUpdate = CurTime() + 10
			end
		end)
	else
		net.Receive("nut_PlayerDataTables", function(length)
			print("Updating player datatables.")

			for k, v in pairs(player.GetAll()) do
				if (v != LocalPlayer() and !v.GetNutWepRaised) then
					player_manager.RunClass(v, "SetupDataTables")
				end
			end
		end)
	end
end

-- Player ragdoll.
do
	function playerMeta:IsPenetrating()
		local physicsObject = self:GetPhysicsObject()
		local entities = ents.FindInBox(self:LocalToWorld(self:OBBMins()), self:LocalToWorld(self:OBBMaxs()))

		for k, v in pairs(entities) do
			if (self.ragdoll and self.ragdoll == v) then
				continue
			end

			if (string.find(v:GetClass(), "prop_")) then
				return true
			end
		end

		if (IsValid(physicsObject)) then
			return physicsObject:IsPenetrating()
		end

		return true
	end

	if (SERVER) then
		function playerMeta:ForceRagdoll()
			self.ragdoll = ents.Create("prop_ragdoll")
			self.ragdoll:SetModel(self:GetModel())
			self.ragdoll:SetPos(self:GetPos())
			self.ragdoll:SetAngles(self:GetAngles())
			self.ragdoll:SetSkin(self:GetSkin())
			self.ragdoll:SetColor(self:GetColor())
			self.ragdoll:Spawn()
			self.ragdoll:Activate()
			self.ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

			self:Freeze(true)
			self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			self:SetNetVar("ragdoll", self.ragdoll)
			self:SetNoDraw(true)

			local uniqueID = "nut_RagSafePos"..self:EntIndex()

			timer.Create(uniqueID, 0.33, 0, function()
				if (!IsValid(self) or !IsValid(self.ragdoll)) then
					if (IsValid(self.ragdoll)) then
						self.ragdoll:Remove()
					end

					timer.Remove(uniqueID)

					return
				end

				self.nut_LastPos = self.nut_LastPos or self:GetPos()

				if (self.nut_LastPos != self:GetPos() and !self:IsPenetrating() and self:IsInWorld()) then
					self.nut_LastPos = self:GetPos()
				end

				self:SetPos(self.ragdoll:GetPos())
			end)
		end

		function playerMeta:UnRagdoll()
			if (IsValid(self.ragdoll)) then
				self.ragdoll:Remove()
			end

			self:SetPos(self.nut_LastPos or self:GetPos())
			self:SetMoveType(MOVETYPE_WALK)
			self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
			self:Freeze(false)
			self:SetNoDraw(false)
			self:SetNetVar("ragdoll", NULL)
			self.nut_LastPos = nil
		end

		function playerMeta:SetTimedRagdoll(time)
			self:ForceRagdoll()

			timer.Create("nut_RagTime"..self:EntIndex(), time, 1, function()
				if (IsValid(self)) then
					self:UnRagdoll()
				end
			end)
		end

		hook.Add("PlayerDeath", "nut_UnRagdoll", function(client)
			client:UnRagdoll()
		end)
	end
end

player_manager.RegisterClass("player_nut", PLAYER, "player_default")