local _PLAYER = FindMetaTable("Player");

nut.Attachment = {};
nut.Attachment.htreg = {};
nut.Attachment.modelreg = {};
nut.Attachment.blacklist = { "weapon_physcannon", "weapon_physgun", "gmod_tool", "gmod_camera" };

-- Register a holdtype.
function nut.Attachment:RegisterHoldtype(holdtype, bone, pos, ang)
	self.htreg[holdtype] = { bone, pos, ang };
end;

-- Register a model.
function nut.Attachment:RegisterModel( model, bone, pos, ang )
	self.modelreg[model] = { bone, pos, ang };
end;


function nut.Attachment:AddBlacklistedWeapon(weapon)
	table.insert( self.blacklist, weapon );
end;

-- Update a players attachments.
function _PLAYER:UpdateWeaponAttachments()
	if ( not self.WeaponAttachments ) then
		self.WeaponAttachments = {};
	end;
	
	for _,weapon in pairs( self:GetWeapons() ) do
		local class = weapon:GetClass();
		if ( not self.WeaponAttachments[class] and not table.HasValue(nut.Attachment.blacklist, class)) then
			if ( nut.Attachment.modelreg[model] ) then
				offsetpos = nut.Attachment.modelreg[model][2];
				offsetang = nut.Attachment.modelreg[model][3];
				bone = nut.Attachment.modelreg[model][1];
			elseif ( nut.Attachment.htreg[ht] ) then
				offsetpos = nut.Attachment.htreg[ht][2];
				offsetang = nut.Attachment.htreg[ht][3];
				bone = nut.Attachment.htreg[ht][1];
			end;

			if (!bone) then
				return
			end
			
			local boneIndex = self:LookupBone(bone)

			if (!boneIndex) then
				return
			end

			local attachment = ents.Create("nut_attachment");
			local offsetpos, offsetang, bone = Vector(-3.96, 4.95, -2.97), Angle(0,0,0), "ValveBiped.Bip01_Spine";
			local ht = weapon:GetHoldType();
			local model = weapon:GetModel();
			
			attachment:SetModel(model);
			attachment:SetAttachParent(self);
			attachment:SetAttachOffset(offsetpos);
			attachment:SetAttachAngles(offsetang);
			attachment:SetAttachBoneIndex(boneIndex);
			attachment:SetAttachClass(weapon:GetClass() );
			attachment:SetParent(self);
			
			self.WeaponAttachments[weapon:GetClass()] = attachment;
		end;
	end;
	
	for k,v in pairs( self.WeaponAttachments ) do
		local gw = self:GetWeapon(k);
		if ( not gw or gw == NULL ) then
			v:Remove();
			self.WeaponAttachments[k] = nil;
		end;
	end;
end;
