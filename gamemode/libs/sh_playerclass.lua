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
		local position = self:GetPos()
		local entities = ents.FindInBox(position + Vector(-16, -16, 0), position + Vector(16, 16, 64))

		for k, v in pairs(entities) do
			if ((self.ragdoll and self.ragdoll == v) or v == self) then
				continue
			end

			if (string.find(v:GetClass(), "prop_") or v:IsPlayer() or v:IsNPC()) then
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
			self.ragdoll.player = self
			self.ragdoll:CallOnRemove("RestorePlayer", function()
				if (IsValid(self)) then
					self:UnRagdoll()
				end
			end)
			self.ragdoll.grace = CurTime() + 1

			for i = 0, self.ragdoll:GetPhysicsObjectCount() do
				local physicsObject = self.ragdoll:GetPhysicsObjectNum(i)

				if (IsValid(physicsObject)) then
					physicsObject:SetVelocity(self:GetVelocity() * 1.25)
				end
			end

			self.nut_Weapons = {}

			for k, v in pairs(self:GetWeapons()) do
				self.nut_Weapons[#self.nut_Weapons + 1] = v:GetClass()
			end

			self:StripWeapons()
			self:Freeze(true)
			self:SetNetVar("ragdoll", self.ragdoll:EntIndex())
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

		function playerMeta:UnRagdoll(samePos)
			local isValid = IsValid(self.ragdoll)

			if (samePos and isValid) then
				self:SetPos(self.ragdoll:GetPos())
			elseif (self.nut_LastPos) then
				self:SetPos(self.nut_LastPos)
			end

			self:SetMoveType(MOVETYPE_WALK)
			self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
			self:Freeze(false)
			self:SetNoDraw(false)
			self:SetNetVar("ragdoll", 0)
			self:DropToFloor()
			self.nut_LastPos = nil

			if (isValid) then
				local physicsObject = self.ragdoll:GetPhysicsObject()

				if (IsValid(physicsObject)) then
					self:SetVelocity(physicsObject:GetVelocity())
				end
			end

			if (self.nut_Weapons) then
				for k, v in pairs(self.nut_Weapons) do
					self:Give(v)
				end

				self.nut_Weapons = nil
			end

			if (isValid) then
				self.ragdoll:Remove()
			end
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
			client:UnRagdoll(true)
		end)

		hook.Add("EntityTakeDamage", "nut_FallenOver", function(entity, damageInfo)
			if (IsValid(entity.player) and (entity.grace or 0) < CurTime()) then
				entity.player:TakeDamageInfo(damageInfo)
			end
		end)
	else
		hook.Add("CalcView", "nut_RagdollView", function(client, origin, angles, fov)
			local entIndex = client:GetNetVar("ragdoll")

			if (entIndex and entIndex > 0) then
				local entity = Entity(entIndex)

				if (IsValid(entity)) then
					local index = entity:LookupAttachment("eyes")
					local attachment = entity:GetAttachment(index)

					local view = {}
						view.origin = attachment.Pos
						view.angles = attachment.Ang
					return view
				end
			end
		end)
	end
end

player_manager.RegisterClass("player_nut", PLAYER, "player_default")