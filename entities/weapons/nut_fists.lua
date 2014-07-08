AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Fists"
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: [RAISED] Punch\nSecondary Fire: Knock/Pickup"
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

SWEP.ViewModel = Model("models/weapons/c_arms_cstrike.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = false
SWEP.LowerAngles = Angle(0, 5, -14)

SWEP.FireWhenLowered = true
SWEP.HoldType = "normal"

function SWEP:PreDrawViewModel(viewModel, weapon, client)
	local hands = player_manager.RunClass(client, "GetHandsModel")

	if (hands and hands.model) then
		viewModel:SetModel(hands.model)
		viewModel:SetSkin(hands.skin)
		viewModel:SetBodyGroups(hands.body)
	end
end

ACT_VM_FISTS_DRAW = 3
ACT_VM_FISTS_HOLSTER = 2

function SWEP:Deploy()
	if (!IsValid(self.Owner)) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_DRAW)
	end

	return true
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
	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
	end
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
	self:SetWeaponHoldType(self.HoldType)
	self.LastHand = 0
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

	if (!self.Owner.character) then
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	local stamina = math.Clamp(self.Owner.character:GetVar("stamina", 100) - 10, 0, 100)

	if (!self.Owner:WepRaised() or stamina <= 0) then
		return
	end

	self:EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")

	local damage = self.Primary.Damage

	self:DoPunchAnimation()

	self.Owner.character:SetVar("stamina", stamina)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Owner:ViewPunch(Angle(self.LastHand + 2, self.LastHand + 5, 0.125))

	timer.Simple(0.055, function()
		if (IsValid(self) and IsValid(self.Owner)) then
			local damage = self.Primary.Damage
			local result = hook.Run("PlayerGetFistDamage", self.Owner, damage)

			if (result != nil) then
				damage = result
			end

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

			hook.Run("PlayerThrowPunch", self.Owner, trace.Hit)
		end
	end)
end

function SWEP:CanCarry(entity)
	local physicsObject = entity:GetPhysicsObject()

	if (!IsValid(physicsObject)) then
		return false
	end

	if (physicsObject:GetMass() > 100 or !physicsObject:IsMoveable()) then
		return false
	end

	if (IsValid(entity.carrier)) then
		return false
	end

	return true
end

function SWEP:DoPickup(entity)
	if (entity:IsPlayerHolding()) then
		return
	end

	timer.Simple(FrameTime() * 10, function()
		if (!IsValid(entity) or entity:IsPlayerHolding()) then
			return
		end

		self.Owner:PickupObject(entity)
		self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(1, 3)..".wav", 75)
	end)

	self:SetNextSecondaryFire(CurTime() + 1)
end

function SWEP:SecondaryAttack()
	if (!IsFirstTimePredicted()) then
		return
	end

	local trace = self.Owner:GetEyeTraceNoCursor()
	local entity = trace.Entity

	if (SERVER and IsValid(entity)) then
		local distance = self.Owner:EyePos():Distance(trace.HitPos)

		if (distance > 72) then
			return
		end

		if (string.find(entity:GetClass(), "door")) then
			if (hook.Run("PlayerCanKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch(Angle(-1.3, 1.8, 0))
			self.Owner:EmitSound("physics/plastic/plastic_box_impact_hard"..math.random(1, 4)..".wav")	
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (!entity:IsPlayer() and !entity:IsNPC() and self:CanCarry(entity)) then
			local physObj = entity:GetPhysicsObject()
			physObj:Wake()

			self:DoPickup(entity)
		end
	end
end