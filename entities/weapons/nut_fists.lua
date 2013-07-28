AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Fists"
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: Throw/[RAISED] Punch,\nSecondary Fire: Knock/Pickup"
SWEP.Purpose = "Hitting things and knocking on doors."
SWEP.Drop = false

SWEP.ViewModelFOV = 36
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

SWEP.ViewModel = Model("models/weapons/v_fists.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = true
SWEP.LowerAngles = Angle(0, 5, -20)

SWEP.FireWhenLowered = true

function SWEP:PreDrawViewModel(viewModel, weapon, client)
	local hands = player_manager.RunClass(client, "GetHandsModel")

	if (hands and hands.model) then
		viewModel:SetModel(hands.model)
	end
end

ACT_VM_FISTS_DRAW = 3
ACT_VM_FISTS_HOLSTER = 2

function SWEP:Deploy()
	if ( !IsValid(self.Owner) ) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if ( IsValid(viewModel) ) then
		viewModel:SetPlaybackRate(0.5)
		viewModel:ResetSequence(ACT_VM_FISTS_DRAW)
	end

	return true
end

function SWEP:Holster()
	if ( !IsValid(self.Owner) ) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if ( IsValid(viewModel) ) then
		viewModel:SetPlaybackRate(0.5)
		viewModel:ResetSequence(ACT_VM_FISTS_HOLSTER)
	end

	return true
end

function SWEP:Precache()
	util.PrecacheSound("npc/vort/claw_swing1.wav")
	util.PrecacheSound("npc/vort/claw_swing2.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard1.wav")	
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard2.wav")	
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard3.wav")	
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard4.wav")	
end

function SWEP:Initialize()
	self:SetWeaponHoldType("fist")
	self.LastHand = 0
end

function SWEP:DoPunchAnimation()
	self.LastHand = math.abs(1 - self.LastHand)

	local sequence = 4 + self.LastHand
	local viewModel = self.Owner:GetViewModel()

	if ( IsValid(viewModel) ) then
		viewModel:SetPlaybackRate(0.525)
		viewModel:SetSequence(sequence)
	end
end

function SWEP:PrimaryAttack()	
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if (IsValid(self.grab)) then
		self:StopGrab(240)
	end

	if (!self.Owner:WepRaised()) then
		return
	end

	self:EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")
	
	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector() * 72
		data.filter = self.Owner
	local trace = util.TraceLine(data)
	local damage = self.Primary.Damage

	self:DoPunchAnimation()

	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Owner:ViewPunch( Angle(self.LastHand + 2, self.LastHand + 5, 0.125) )

	timer.Simple(0.085, function()
		if (IsValid(self) and IsValid(self.Owner) and self.Owner:GetPos():Distance(trace.HitPos or vector_origin) <= 108) then
			local shoot = false

			if (trace.Hit) then
				if ( IsValid(trace.Entity) ) then
					if ( trace.Entity:IsPlayer() ) then
						shoot = true
					end

					local class = string.lower( trace.Entity:GetClass() )

					if ( string.find(class, "breakable") ) then
						shoot = true
					end
				end
			end

			if (shoot) then
				local damage = self.Primary.Damage
				local result = nut.schema.Call("PlayerGetFistDamage", self.Owner, damage)

				if (result != nil) then
					damage = result
				end

				local bullet = {}
				bullet.Num = 1
				bullet.Src = self.Owner:GetShootPos()
				bullet.Dir = self.Owner:GetAimVector()
				bullet.Spread = Vector(0, 0, 0)
				bullet.Tracer = 0
				bullet.Force = 5
				bullet.Damage = damage

				self.Owner:FireBullets(bullet)
			elseif ( IsValid(trace.Entity) ) then
				if ( IsValid( trace.Entity:GetPhysicsObject() ) ) then
					trace.Entity:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector() * 500, trace.HitPos)
				end
			end

			nut.schema.Call("PlayerThrowPunch", self.Owner, shoot)
		end
	end)
end

function SWEP:CanCarry(entity, physicsObject)
	if (physicsObject:GetMass() > 100 or !physicsObject:IsMoveable()) then
		return false
	end

	if (IsValid(entity.carrier)) then
		return false
	end

	return true
end

function SWEP:StartGrab(entity, trace)
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)

	local physicsObject = entity:GetPhysicsObject()
	local canCarry = false

	if (IsValid(physicsObject)) then
		canCarry = self:CanCarry(entity, physicsObject)
	end

	if (!canCarry) then
		return
	end

	self.grabbedEntity = entity

	self.grab = ents.Create("prop_physics")
	self.grab:SetPos(self.Owner:GetShootPos() + self.Owner:GetAimVector() * 54)
	self.grab:SetModel("models/props_junk/popcan01a.mdl")
	self.grab:SetNoDraw(true)
	self.grab:Spawn()
	self.grab:Activate()
	self.grab:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.grab:GetPhysicsObject():EnableMotion(false)

	entity:SetPos(self.grab:GetPos())
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	entity:SetOwner(self.Owner)
	entity.carrier = self.Owner

	if (IsValid(physicsObject)) then
		physicsObject:AddGameFlag(FVPHYSICS_PLAYER_HELD)
	end

	self.grabConstraint = constraint.Weld(self.grab, entity, 0, trace.PhysicsBone, 0, true)
	self:DeleteOnRemove(self.grab)

	self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(1, 4)..".wav")

	timer.Simple(0.1, function()
		if (!IsValid(entity)) then
			return
		end

		self:CallOnClient("PickUp", entity:EntIndex())
	end)
end

function SWEP:Holster(weapon)
	if (SERVER) then
		self:StopGrab()
	end

	return true
end

function SWEP:StopGrab(force)
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)

	force = force or 32

	if (IsValid(self.grabConstraint)) then
		self.grabConstraint:Remove()
	end

	if (IsValid(self.grab)) then
		self.grab:Remove()
	end

	local entity = self.grabbedEntity

	self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(5, 7)..".wav")

	timer.Simple(0.05, function()
		if (IsValid(entity)) then
			entity.carrier = nil
			entity:SetOwner(NULL)

			local velocity = self.Owner:GetAimVector() * force
			local physicsObject = entity:GetPhysicsObject()

			if (entity:GetClass() == "prop_ragdoll") then
				for i = 0, entity:GetPhysicsObjectCount() do
					local physicsObject = entity:GetPhysicsObjectNum(i)

					if (IsValid(physicsObject)) then
						physicsObject:SetVelocity(velocity)
					end
				end
			elseif (IsValid(physicsObject)) then
				physicsObject:Wake()
				physicsObject:EnableMotion(true)
				physicsObject:SetVelocity(velocity)
				physicsObject:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
				physicsObject:AddGameFlag(FVPHYSICS_WAS_THROWN)
			end

			entity:SetCollisionGroup(COLLISION_GROUP_NONE)

			timer.Simple(0.1, function()
				if (!IsValid(entity)) then
					return
				end
				print(entity)
				self:CallOnClient("Dropped", entity:EntIndex())
			end)
		end
	end)

	self.grabbedEntity = nil
end

function SWEP:SecondaryAttack()
	local trace = self.Owner:GetEyeTraceNoCursor()
	local entity = trace.Entity

	if (IsValid(self.grab)) then
		self:StopGrab()

		return
	end

	if (SERVER and IsValid(entity)) then
		local distance = self.Owner:EyePos():Distance(trace.HitPos)

		if (distance > 72) then
			return
		end

		if (string.find(entity:GetClass(), "door")) then
			if (nut.schema.Call("PlayerCanKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch( Angle(-1.3, 1.8, 0) )
			self.Owner:EmitSound("physics/plastic/plastic_box_impact_hard"..math.random(1, 4)..".wav")	
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (!entity:IsPlayer() and !entity:IsNPC()) then
			self:StartGrab(entity, trace)
		end
	end
end

function SWEP:Think()
	local grab = self.grab
	local grabbedEntity = self.grabbedEntity

	if (SERVER and IsValid(grab) and IsValid(grabbedEntity)) then
		local data = {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 54,
			filter = {self.Owner, self.grabbedEntity}
		}
		local trace = util.TraceLine(data)

		grab:SetPos(trace.HitPos)
		grabbedEntity:PhysWake()
	end
end

function SWEP:PickUp(index)
	local entity = Entity(tonumber(index))

	if (IsValid(entity) and entity:GetOwner() == LocalPlayer()) then
		local color = entity:GetColor()
		color.a = 200

		entity:SetRenderMode(RENDERMODE_TRANSALPHADD)
		entity:SetColor(color)
	end
end

function SWEP:Dropped(index)
	local entity = Entity(tonumber(index))

	if (IsValid(entity)) then
		local color = entity:GetColor()
		color.a = 255

		entity:SetColor(color)
	end
end