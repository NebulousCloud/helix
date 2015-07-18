AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Hands"
	SWEP.PrintName = "Hands"
	SWEP.Slot = 0
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
SWEP.LowerAngles2 = Angle(0, 5, -22)

SWEP.FireWhenLowered = true
SWEP.HoldType = "fist"

function SWEP:PreDrawViewModel(viewModel, weapon, client)
	local hands = player_manager.TranslatePlayerHands(player_manager.TranslateToPlayerModelName(client:GetModel()))

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
	if (CLIENT) then
		if (self.Owner) then
			local viewModel = self.Owner:GetViewModel()

			if (IsValid(viewModel)) then
				viewModel:SetPlaybackRate(1)
			end
		end
	end
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

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
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

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if (hook.Run("CanPlayerThrowPunch", self.Owner) == false) then
		return
	end

	local staminaUse = nut.config.get("punchStamina")

	if (staminaUse > 0) then
		local value = self.Owner:getLocalVar("stm", 0) - staminaUse

		if (value < 0) then
			return
		elseif (SERVER) then
			self.Owner:setLocalVar("stm", value)
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

				hook.Run("PlayerThrowPunch", self.Owner, trace.Hit)
			self.Owner:LagCompensation(false)
		end
	end)
end

function SWEP:onCanCarry(entity)
	local physicsObject = entity:GetPhysicsObject()

	if (!IsValid(physicsObject)) then
		return false
	end

	if (physicsObject:GetMass() > 100 or !physicsObject:IsMoveable()) then
		return false
	end

	if (IsValid(entity.carrier) or IsValid(self.heldEntity)) then
		return false
	end

	return true
end

function SWEP:doPickup(entity)
	if (entity:IsPlayerHolding()) then
		return
	end

	self.heldEntity = entity

	timer.Simple(0.2, function()
		if (!IsValid(entity) or entity:IsPlayerHolding() or self.heldEntity != entity) then
			self.heldEntity = nil

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

	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector()*84
		data.filter = {self, self.Owner}
	local trace = util.TraceLine(data)
	local entity = trace.Entity
	
	if (SERVER and IsValid(entity)) then
		if (entity:isDoor()) then
			if (hook.Run("PlayerCanKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch(Angle(-1.3, 1.8, 0))
			self.Owner:EmitSound("physics/wood/wood_crate_impact_hard"..math.random(2, 3)..".wav")	
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (!entity:IsPlayer() and !entity:IsNPC() and self:onCanCarry(entity)) then
			local physObj = entity:GetPhysicsObject()
			physObj:Wake()

			self:doPickup(entity)
		elseif (IsValid(self.heldEntity) and !self.heldEntity:IsPlayerHolding()) then
			self.heldEntity = nil
		end
	end
end
