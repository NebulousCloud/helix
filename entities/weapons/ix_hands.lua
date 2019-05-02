
AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Hands"
	SWEP.Slot = 0
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: Throw/Punch\nSecondary Fire: Knock/Pickup\nReload: Drop"
SWEP.Purpose = "Hitting things and knocking on doors."
SWEP.Drop = false

SWEP.ViewModelFOV = 45
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "rpg"

SWEP.ViewTranslation = 4

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 5
SWEP.Primary.Delay = 0.75

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 0.5

SWEP.ViewModel = Model("models/weapons/c_arms_citizen.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = false
SWEP.LowerAngles = Angle(0, 5, -14)
SWEP.LowerAngles2 = Angle(0, 5, -19)

SWEP.FireWhenLowered = true
SWEP.HoldType = "fist"

SWEP.holdDistance = 64
SWEP.maxHoldDistance = 96 -- how far away the held object is allowed to travel before forcefully dropping
SWEP.maxHoldStress = 4000 -- how much stress the held object can undergo before forcefully dropping
SWEP.allowedHoldableClasses = {
	["ix_item"] = true,
	["prop_physics"] = true,
	["prop_physics_override"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_ragdoll"] = true
}

-- luacheck: globals ACT_VM_FISTS_DRAW ACT_VM_FISTS_HOLSTER
ACT_VM_FISTS_DRAW = 3
ACT_VM_FISTS_HOLSTER = 2

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)

	self.lastHand = 0
	self.maxHoldDistanceSquared = self.maxHoldDistance ^ 2
	self.heldObjectAngle = angle_zero
end

if (CLIENT) then
	function SWEP:PreDrawViewModel(viewModel, weapon, client)
		local hands = player_manager.TranslatePlayerHands(player_manager.TranslateToPlayerModelName(client:GetModel()))

		if (hands and hands.model) then
			viewModel:SetModel(hands.model)
			viewModel:SetSkin(hands.skin)
			viewModel:SetBodyGroups(hands.body)
		end
	end

	function SWEP:DoDrawCrosshair(x, y)
		surface.SetDrawColor(255, 255, 255, 66)
		surface.DrawRect(x - 2, y - 2, 4, 4)
	end
end

function SWEP:Deploy()
	if (!IsValid(self.Owner)) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_DRAW)
	end

	self:DropObject()
	return true
end

function SWEP:Precache()
	util.PrecacheSound("npc/vort/claw_swing1.wav")
	util.PrecacheSound("npc/vort/claw_swing2.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard1.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard2.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard3.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard4.wav")
	util.PrecacheSound("physics/wood/wood_crate_impact_hard2.wav")
	util.PrecacheSound("physics/wood/wood_crate_impact_hard3.wav")
end

function SWEP:OnReloaded()
	self.maxHoldDistanceSquared = self.maxHoldDistance ^ 2
	self:DropObject()
end

function SWEP:Holster()
	if (!IsValid(self.Owner)) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_HOLSTER)
	end

	return true
end

function SWEP:Think()
	if (!IsValid(self.Owner)) then
		return
	end

	if (CLIENT) then
		local viewModel = self.Owner:GetViewModel()

		if (IsValid(viewModel)) then
			viewModel:SetPlaybackRate(1)
		end
	else
		if (self:IsHoldingObject()) then
			local physics = self:GetHeldPhysicsObject()
			local bIsRagdoll = self.heldEntity:IsRagdoll()
			local holdDistance = bIsRagdoll and self.holdDistance * 0.5 or self.holdDistance
			local targetLocation = (self.Owner:GetShootPos() + self.Owner:GetForward() * holdDistance) - self.heldEntity:OBBCenter()

			if (bIsRagdoll) then
				targetLocation.z = math.min(targetLocation.z, self.Owner:GetShootPos().z - 32)
			end

			if (!IsValid(physics)) then
				self:DropObject()
				return
			end

			if (physics:GetPos():DistToSqr(targetLocation) > self.maxHoldDistanceSquared) then
				self:DropObject()
			else
				local physicsObject = self.holdEntity:GetPhysicsObject()

				physicsObject:Wake()
				physicsObject:ComputeShadowControl({
					secondstoarrive = 0.01,
					pos = targetLocation,
					angle = self.heldObjectAngle,
					maxangular = 256,
					maxangulardamp = 10000,
					maxspeed = 256,
					maxspeeddamp = 10000,
					dampfactor = 0.8,
					teleportdistance = self.maxHoldDistance * 0.75,
					deltatime = FrameTime()
				})

				if (physics:GetStress() > self.maxHoldStress) then
					self:DropObject()
				end
			end
		end
	end
end

function SWEP:GetHeldPhysicsObject()
	return IsValid(self.heldEntity) and self.heldEntity:GetPhysicsObject() or nil
end

function SWEP:CanHoldObject(entity)
	local physics = entity:GetPhysicsObject()

	return IsValid(physics) and
		(physics:GetMass() <= ix.config.Get("maxHoldWeight", 100) and physics:IsMoveable()) and
		!self:IsHoldingObject() and
		!IsValid(entity.ixHeldOwner) and
		(self.allowedHoldableClasses[entity:GetClass()] or hook.Run("CanPlayerHoldObject", self.Owner, entity))
end

function SWEP:IsHoldingObject()
	return IsValid(self.heldEntity) and
		IsValid(self.heldEntity.ixHeldOwner) and
		self.heldEntity.ixHeldOwner == self.Owner
end

function SWEP:PickupObject(entity)
	if (self:IsHoldingObject() or
		!IsValid(entity) or
		!IsValid(entity:GetPhysicsObject())) then
		return
	end

	local physics = entity:GetPhysicsObject()
	physics:EnableGravity(false)
	physics:AddGameFlag(FVPHYSICS_PLAYER_HELD)

	entity.ixHeldOwner = self.Owner
	entity.ixCollisionGroup = entity:GetCollisionGroup()
	entity:StartMotionController()
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self.heldObjectAngle = entity:GetAngles()
	self.heldEntity = entity

	self.holdEntity = ents.Create("prop_physics")
	self.holdEntity:SetPos(self.heldEntity:GetPos())
	self.holdEntity:SetAngles(self.heldEntity:GetAngles())
	self.holdEntity:SetModel("models/weapons/w_bugbait.mdl")
	self.holdEntity:SetOwner(self.Owner)

	self.holdEntity:SetNoDraw(true)
	self.holdEntity:SetNotSolid(true)
	self.holdEntity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.holdEntity:DrawShadow(false)

	self.holdEntity:Spawn()

	local trace = self.Owner:GetEyeTrace()
	local physicsObject = self.holdEntity:GetPhysicsObject()

	if (IsValid(physicsObject)) then
		physicsObject:SetMass(2048)
		physicsObject:SetDamping(0, 1000)
		physicsObject:EnableGravity(false)
		physicsObject:EnableCollisions(false)
		physicsObject:EnableMotion(false)
	end

	self.constraint = constraint.Weld(self.holdEntity, self.heldEntity, 0,
		trace.Entity:IsRagdoll() and trace.PhysicsBone or 0, 0, true, true)
end

function SWEP:DropObject(bThrow)
	if (!IsValid(self.heldEntity) or self.heldEntity.ixHeldOwner != self.Owner) then
		return
	end

	self.constraint:Remove()
	self.holdEntity:Remove()

	self.heldEntity:StopMotionController()
	self.heldEntity:SetCollisionGroup(self.heldEntity.ixCollisionGroup)

	local physics = self:GetHeldPhysicsObject()
	physics:EnableGravity(true)
	physics:Wake()
	physics:ClearGameFlag(FVPHYSICS_PLAYER_HELD)

	if (bThrow) then
		timer.Simple(0, function()
			if (IsValid(physics) and IsValid(self.Owner)) then
				physics:AddGameFlag(FVPHYSICS_WAS_THROWN)
				physics:ApplyForceCenter(self.Owner:GetAimVector() * ix.config.Get("throwForce", 732))
			end
		end)
	end

	self.heldEntity.ixHeldOwner = nil
	self.heldEntity.ixCollisionGroup = nil
	self.heldEntity = nil
end

function SWEP:PlayPickupSound(surfaceProperty)
	local result = "Flesh.ImpactSoft"

	if (surfaceProperty != nil) then
		local surfaceName = util.GetSurfacePropName(surfaceProperty)
		local soundName = surfaceName:gsub("^metal$", "SolidMetal") .. ".ImpactSoft"

		if (sound.GetProperties(soundName)) then
			result = soundName
		end
	end

	self.Owner:EmitSound(result, 75, 100, 40)
end

function SWEP:Holster()
	if (!IsFirstTimePredicted() or CLIENT) then
		return
	end

	self:DropObject()
	return true
end

function SWEP:OnRemove()
	if (SERVER) then
		self:DropObject()
	end
end

function SWEP:OwnerChanged()
	if (SERVER) then
		self:DropObject()
	end
end

function SWEP:DoPunchAnimation()
	self.lastHand = math.abs(1 - self.lastHand)

	local sequence = 4 + self.lastHand
	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(0.5)
		viewModel:SetSequence(sequence)
	end
end

function SWEP:PrimaryAttack()
	if (!IsFirstTimePredicted()) then
		return
	end

	if (SERVER and self:IsHoldingObject()) then
		self:DropObject(true)
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if (hook.Run("CanPlayerThrowPunch", self.Owner) == false) then
		return
	end

	local staminaUse = ix.config.Get("punchStamina")

	if (staminaUse > 0) then
		local value = self.Owner:GetLocalVar("stm", 0) - staminaUse

		if (value < 0) then
			return
		elseif (SERVER) then
			self.Owner:SetLocalVar("stm", value)
		end
	end

	if (SERVER) then
		self.Owner:EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")
	end

	self:DoPunchAnimation()

	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Owner:ViewPunch(Angle(self.lastHand + 2, self.lastHand + 5, 0.125))

	timer.Simple(0.055, function()
		if (IsValid(self) and IsValid(self.Owner)) then
			local damage = self.Primary.Damage
			local context = {damage = damage}
			local result = hook.Run("GetPlayerPunchDamage", self.Owner, damage, context)

			if (result != nil) then
				damage = result
			else
				damage = context.damage
			end

			self.Owner:LagCompensation(true)
				local data = {}
					data.start = self.Owner:GetShootPos()
					data.endpos = data.start + self.Owner:GetAimVector()*96
					data.filter = self.Owner
				local trace = util.TraceLine(data)

				if (SERVER and trace.Hit) then
					local entity = trace.Entity

					if (IsValid(entity)) then
						local damageInfo = DamageInfo()
							damageInfo:SetAttacker(self.Owner)
							damageInfo:SetInflictor(self)
							damageInfo:SetDamage(damage)
							damageInfo:SetDamageType(DMG_SLASH)
							damageInfo:SetDamagePosition(trace.HitPos)
							damageInfo:SetDamageForce(self.Owner:GetAimVector() * 1024)
						entity:DispatchTraceAttack(damageInfo, data.start, data.endpos)

						self.Owner:EmitSound("physics/body/body_medium_impact_hard"..math.random(1, 6)..".wav", 80)
					end
				end

				hook.Run("PlayerThrowPunch", self.Owner, trace)
			self.Owner:LagCompensation(false)
		end
	end)
end

function SWEP:SecondaryAttack()
	if (!IsFirstTimePredicted()) then
		return
	end

	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector() * 84
		data.filter = {self, self.Owner}
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (SERVER and IsValid(entity)) then
		if (entity:IsDoor()) then
			if (hook.Run("CanPlayerKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch(Angle(-1.3, 1.8, 0))
			self.Owner:EmitSound("physics/wood/wood_crate_impact_hard"..math.random(2, 3)..".wav")
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (entity:IsPlayer() and ix.config.Get("allowPush", true)) then
			local direction = self.Owner:GetAimVector() * (300 + (self.Owner:GetCharacter():GetAttribute("str", 0) * 3))
				direction.z = 0
			entity:SetVelocity(direction)

			self.Owner:EmitSound("Weapon_Crossbow.BoltHitBody")
			self:SetNextSecondaryFire(CurTime() + 1.5)
			self:SetNextPrimaryFire(CurTime() + 1.5)
		elseif (!entity:IsNPC() and self:CanHoldObject(entity)) then
			self:PickupObject(entity)
			self:PlayPickupSound(trace.SurfaceProps)
			self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
		end
	end
end

function SWEP:Reload()
	if (!IsFirstTimePredicted()) then
		return
	end

	if (SERVER and IsValid(self.heldEntity)) then
		self:DropObject()
	end
end
