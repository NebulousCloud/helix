
AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Keys"
	SWEP.Slot = 0
	SWEP.SlotPos = 2
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: Lock\nSecondary Fire: Unlock"
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

SWEP.ViewModel = Model("models/weapons/c_arms_animations.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = false
SWEP.LowerAngles = Angle(0, 5, -14)
SWEP.LowerAngles2 = Angle(0, 5, -22)

SWEP.IsAlwaysLowered = true
SWEP.FireWhenLowered = true
SWEP.HoldType = "passive"

-- luacheck: globals ACT_VM_FISTS_DRAW ACT_VM_FISTS_HOLSTER
ACT_VM_FISTS_DRAW = 3
ACT_VM_FISTS_HOLSTER = 2

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

function SWEP:Precache()
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	local time = ix.config.Get("doorLockTime", 1)
	local time2 = math.max(time, 1)

	self:SetNextPrimaryFire(CurTime() + time2)
	self:SetNextSecondaryFire(CurTime() + time2)

	if (!IsFirstTimePredicted()) then
		return
	end

	if (CLIENT) then
		return
	end

	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector()*96
		data.filter = self.Owner
	local entity = util.TraceLine(data).Entity

	--[[
		Locks the entity if the contiditon fits:
			1. The entity is door and client has access to the door.
			2. The entity is vehicle and the "owner" variable is same as client's character ID.
	--]]
	if (IsValid(entity) and
		(
			(entity:IsDoor() and entity:CheckDoorAccess(self.Owner)) or
			(entity:IsVehicle() and entity.CPPIGetOwner and entity:CPPIGetOwner() == self.Owner)
		)
	) then
		self.Owner:SetAction("@locking", time, function()
			self:ToggleLock(entity, true)
		end)

		return
	end
end

function SWEP:ToggleLock(door, state)
	if (IsValid(self.Owner) and self.Owner:GetPos():Distance(door:GetPos()) > 96) then
		return
	end

	if (door:IsDoor()) then
		local partner = door:GetDoorPartner()

		if (state) then
			if (IsValid(partner)) then
				partner:Fire("lock")
			end

			door:Fire("lock")
			self.Owner:EmitSound("doors/door_latch3.wav")

			hook.Run("PlayerLockedDoor", self.Owner, door, partner)
		else
			if (IsValid(partner)) then
				partner:Fire("unlock")
			end

			door:Fire("unlock")
			self.Owner:EmitSound("doors/door_latch1.wav")

			hook.Run("PlayerUnlockedDoor", self.Owner, door, partner)
		end
	elseif (door:IsVehicle()) then
		if (state) then
			door:Fire("lock")

			if (door.IsSimfphyscar) then
				door.IsLocked = true
			end

			self.Owner:EmitSound("doors/door_latch3.wav")
			hook.Run("PlayerLockedVehicle", self.Owner, door)
		else
			door:Fire("unlock")

			if (door.IsSimfphyscar) then
				door.IsLocked = nil
			end

			self.Owner:EmitSound("doors/door_latch1.wav")
			hook.Run("PlayerUnlockedVehicle", self.Owner, door)
		end
	end
end

function SWEP:SecondaryAttack()
	local time = ix.config.Get("doorLockTime", 1)
	local time2 = math.max(time, 1)

	self:SetNextPrimaryFire(CurTime() + time2)
	self:SetNextSecondaryFire(CurTime() + time2)

	if (!IsFirstTimePredicted()) then
		return
	end

	if (CLIENT) then
		return
	end

	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector()*96
		data.filter = self.Owner
	local entity = util.TraceLine(data).Entity


	--[[
		Unlocks the entity if the contiditon fits:
			1. The entity is door and client has access to the door.
			2. The entity is vehicle and the "owner" variable is same as client's character ID.
	]]--
	if (IsValid(entity) and
		(
			(entity:IsDoor() and entity:CheckDoorAccess(self.Owner)) or
			(entity:IsVehicle() and entity.CPPIGetOwner and entity:CPPIGetOwner() == self.Owner)
		)
	) then
		self.Owner:SetAction("@unlocking", time, function()
			self:ToggleLock(entity, false)
		end)

		return
	end
end
