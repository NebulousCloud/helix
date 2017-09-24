AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Hands"
	SWEP.Slot = 0
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
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

SWEP.ViewModel = Model("models/weapons/c_arms_cstrike.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = false
SWEP.LowerAngles = Angle(0, 5, -14)
SWEP.LowerAngles2 = Angle(0, 5, -22)

SWEP.FireWhenLowered = true
SWEP.HoldType = "fist"

SWEP.HoldDistance = 64
SWEP.MaxHoldDistance = 72 -- how far away the held object is allowed to travel before forcefully dropping
SWEP.MaxHoldStress = 4000 -- how much stress the held object can undergo before forcefully dropping
SWEP.AllowedHoldableClasses = {
	["nut_item"] = true,
	["prop_physics"] = true,
	-- TODO
	--["prop_ragdoll"] = true
}

ACT_VM_FISTS_DRAW = 3
ACT_VM_FISTS_HOLSTER = 2

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self.LastHand = 0
	self.MaxHoldDistance = self.MaxHoldDistance ^ 2
	self.HeldObjectAngle = angle_zero
end

function SWEP:PreDrawViewModel(viewModel, weapon, client)
	local hands = player_manager.TranslatePlayerHands(player_manager.TranslateToPlayerModelName(client:GetModel()))

	if (hands and hands.model) then
		viewModel:SetModel(hands.model)
		viewModel:SetSkin(hands.skin)
		viewModel:SetBodyGroups(hands.body)
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
	self.MaxHoldDistance = self.MaxHoldDistance ^ 2
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
			local physics = self.HeldEntity:GetPhysicsObject()
			local targetLocation = (self.Owner:GetShootPos() + self.Owner:GetForward() * self.HoldDistance) - self.HeldEntity:OBBCenter()

			if (physics:GetPos():DistToSqr(targetLocation) > self.MaxHoldDistance) then
				self:DropObject()
			else
				physics:UpdateShadow(targetLocation, self.HeldObjectAngle, FrameTime())

				if (physics:GetStress() > self.MaxHoldStress) then
					self:DropObject()
				end
			end
		end
	end
end

function SWEP:CanHoldObject(entity)
	local physics = entity:GetPhysicsObject()

	return (IsValid(physics) and
		(physics:GetMass() <= nut.config.Get("maxHoldWeight", 100) and physics:IsMoveable()) and
		!self:IsHoldingObject() and
		!IsValid(entity.nutHeldOwner) and
		self.AllowedHoldableClasses[entity:GetClass()])
end

function SWEP:IsHoldingObject()
	return (IsValid(self.HeldEntity) and
		IsValid(self.HeldEntity.nutHeldOwner) and 
		self.HeldEntity.nutHeldOwner == self.Owner)
end

function SWEP:PickupObject(entity)
	if (self:IsHoldingObject() or
		!IsValid(entity) or
		!IsValid(entity:GetPhysicsObject())) then
		return
	end

	local physics = entity:GetPhysicsObject()
	physics:Wake()

	entity.nutHeldOwner = self.Owner
	entity.nutCollisionGroup = entity:GetCollisionGroup()

	-- TODO: we might need to make a separate grabber entity instead of modifying the entity's physobj
	entity:StartMotionController()
	entity:MakePhysicsObjectAShadow(true, false)
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self.HeldObjectAngle = entity:GetAngles()
	self.HeldEntity = entity
end

function SWEP:DropObject(bThrow)
	if (!IsValid(self.HeldEntity) or self.HeldEntity.nutHeldOwner != self.Owner) then
		return
	end

	self.HeldEntity:StopMotionController()
	self.HeldEntity:PhysicsInit(SOLID_VPHYSICS)
	self.HeldEntity:SetCollisionGroup(self.HeldEntity.nutCollisionGroup)

	local physics = self.HeldEntity:GetPhysicsObject()
	physics:Wake()
	
	if (bThrow) then
		physics:SetVelocityInstantaneous(self.Owner:GetAimVector() * nut.config.Get("throwForce", 256));
	else
		physics:SetVelocityInstantaneous(vector_origin)
	end

	self.HeldEntity.nutHeldOwner = nil
	self.HeldEntity.nutCollisionGroup = nil
	self.HeldEntity = nil
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
	self.LastHand = math.abs(1 - self.LastHand)

	local sequence = 4 + self.LastHand
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

	local staminaUse = nut.config.Get("punchStamina")

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

	local damage = self.Primary.Damage

	self:DoPunchAnimation()

	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Owner:ViewPunch(Angle(self.LastHand + 2, self.LastHand + 5, 0.125))

	timer.Simple(0.055, function()
		if (IsValid(self) and IsValid(self.Owner)) then
			local damage = self.Primary.Damage
			local context = {damage = damage}
			local result = hook.Run("PlayerGetFistDamage", self.Owner, damage, context)

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
							damageInfo:SetDamageForce(self.Owner:GetAimVector()*10000)
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
		data.endpos = data.start + self.Owner:GetAimVector()*84
		data.filter = {self, self.Owner}
	local trace = util.TraceLine(data)
	local entity = trace.Entity
	
	if (SERVER and IsValid(entity)) then
		if (entity:IsDoor()) then
			if (hook.Run("PlayerCanKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch(Angle(-1.3, 1.8, 0))
			self.Owner:EmitSound("physics/wood/wood_crate_impact_hard"..math.random(2, 3)..".wav")	
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (!entity:IsPlayer() and !entity:IsNPC() and self:CanHoldObject(entity)) then
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

	if (SERVER and IsValid(self.HeldEntity)) then
		self:DropObject()
	end
end
