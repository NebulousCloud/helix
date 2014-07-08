local PLUGIN = PLUGIN

if (CLIENT) then
	SWEP.PrintName = "Keys"
	SWEP.Slot = 1
	SWEP.SlotPos = 2
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: Lock\nSecondary Fire: Unlock"
SWEP.Purpose = "Keys to doors you own."
SWEP.Drop = false

SWEP.ViewModelFOV = 45
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "rpg"

SWEP.ViewTranslation = 4

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 15
SWEP.Primary.Delay = 0.75

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = Model("models/weapons/c_arms_cstrike.mdl")
SWEP.WorldModel = ""

SWEP.FireWhenLowered = true
SWEP.AlwaysLowered = true
SWEP.DrawViewModel = false
SWEP.UseHands = false
SWEP.LowerAngles = Angle(0, 5, -14)
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
		viewModel:SetPlaybackRate(0.5)
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
	util.PrecacheSound("doors/door_latch1.wav")
	util.PrecacheSound("doors/door_latch3.wav")
end

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	self.LastHand = 0
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	if (CLIENT) then
		return
	end

	self:EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")
	
	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector() * 84
		data.filter = self.Owner
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity)) then
		if (!PLUGIN:IsDoor(entity)) then
			nut.util.Notify("This is not a valid door.", self.Owner)

			return
		end

		if (entity:GetNetVar("owner") != self.Owner) then
			nut.util.Notify("You are not the owner of this door.", self.Owner)

			return
		end
		
		entity:EmitSound("doors/door_latch1.wav")
		PLUGIN:LockDoor(entity)
	end
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	
	if (CLIENT) then
		return
	end

	self:EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")
	
	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector() * 84
		data.filter = self.Owner
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (SERVER and IsValid(entity)) then
		if (!PLUGIN:IsDoor(entity)) then
			nut.util.Notify("This is not a valid door.", self.Owner)

			return
		end

		if (entity:GetNetVar("owner") != self.Owner) then
			nut.util.Notify("You are not the owner of this door.", self.Owner)

			return
		end

		entity:EmitSound("doors/door_latch3.wav")
		PLUGIN:UnlockDoor(entity)
	end
end