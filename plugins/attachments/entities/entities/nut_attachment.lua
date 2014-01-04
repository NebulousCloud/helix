AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "WAE Attachment"
ENT.Category = "WAE Attachment"
ENT.Author = "LauScript"

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "AttachOffset");
	self:NetworkVar("Angle", 0, "AttachAngles");
	self:NetworkVar("Entity", 0, "AttachParent");
	self:NetworkVar("Int", 0, "AttachBoneIndex" );
	self:NetworkVar( "String", 0, "AttachClass" );
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl");
		self:SetSolid(SOLID_NONE);
		self:PhysicsInit(SOLID_NONE);
		self:DrawShadow(false)
		self:SetMoveType(MOVETYPE_NONE);

		local physicsObject = self:GetPhysicsObject();

		if (IsValid(physicsObject)) then
			physicsObject:EnableMotion(true);
			physicsObject:Wake();
		end
	end;
end;

function ENT:Think()
	if ( CLIENT ) then
		local pos,ang = self:GetAttachmentPosition();
	
		self:SetPos( pos );
		self:SetAngles( ang );
	end;
end;

function ENT:GetAttachmentPosition()
	local pos,ang = self:GetAttachOffset(), self:GetAttachAngles();
	local parent,bone = self:GetAttachParent(), self:GetAttachBoneIndex();
	
	if ( pos and ang and parent and bone ) then
		local bonepos,boneang = parent:GetBonePosition(bone);
		local x,y,z = boneang:Up() * pos.x, boneang:Right() * pos.y, boneang:Forward() * pos.z;
		
		boneang:RotateAroundAxis(boneang:Forward(), ang.p);
		boneang:RotateAroundAxis(boneang:Right(), ang.y);
		boneang:RotateAroundAxis(boneang:Up(), ang.r);
		
		return bonepos + x + y + z, boneang;
	end;
end;


if ( CLIENT ) then

function ENT:Draw()
	local ap = self:GetAttachParent();
	local active = ap:GetActiveWeapon();
	local client = LocalPlayer()

	if (ap == client and !client:ShouldDrawLocalPlayer()) then
		return
	end

	if ( active and active != NULL ) then
		if ( active:GetClass() == self:GetAttachClass() or not ap:Alive() ) then
			return;
		else
			self:DrawModel();
		end;
	end;
end

end;