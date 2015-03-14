AddCSLuaFile()

if( CLIENT ) then
	SWEP.PrintName = "Entity Position Helper";
	SWEP.Slot = 0;
	SWEP.SlotPos = 0;
	SWEP.CLMode = 0
end
SWEP.HoldType = "fists"

SWEP.Category = "Nutscript"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.Delay			= 1
SWEP.Primary.Recoil			= 0	
SWEP.Primary.Damage			= 0
SWEP.Primary.NumShots		= 0
SWEP.Primary.Cone			= 0 	
SWEP.Primary.ClipSize		= -1	
SWEP.Primary.DefaultClip	= -1	
SWEP.Primary.Automatic   	= false	
SWEP.Primary.Ammo         	= "none"
 
SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= true
SWEP.Secondary.Ammo         = "none"

function SWEP:Initialize()
	self:SetWeaponHoldType("knife")
end
	
function SWEP:Deploy()
	return true
end

function SWEP:Think()
end

local gridsize = 1

if SERVER then
	function SWEP:PrimaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:SecondaryAttack()
	end
end

if CLIENT then
	local PANEL = {}
	local vTxt = "xyz"
	local aTxt = "pyr"
	function PANEL:Init()
		self:SetTitle("HELPER")
		self:SetSize(300, 390)
		self:Center()
		self:MakePopup()

		self.list = self:Add("DPanel")
		self.list:Dock(FILL)
		self.list:DockMargin(0, 0, 0, 0)

		for i = 1, 3 do
			local cfg = self.list:Add("DNumSlider")
			cfg:Dock(TOP)
			cfg:SetText("VECTOR" .. vTxt[i]) 
			cfg:SetMin(-100)				 
			cfg:SetMax(100)				
			cfg:SetDecimals(3)		
			cfg:SetValue(HELPER_INFO.renderPos[i])		 
			cfg:DockMargin(10, 0, 0, 5)
			function cfg:OnValueChanged(value)
				HELPER_INFO.renderPos[i] = value
			end
		end

		for i = 1, 3 do
			local cfg = self.list:Add("DNumSlider")
			cfg:Dock(TOP)
			cfg:SetText("ANGLE" .. aTxt[i]) 
			cfg:SetMin(-180)				 
			cfg:SetMax(180)				
			cfg:SetDecimals(3)	
			cfg:SetValue(HELPER_INFO.renderAng[i])		 
			cfg:DockMargin(10, 0, 0, 5)
			function cfg:OnValueChanged(value)
				HELPER_INFO.renderAng[i] = value
			end
		end

		local textBox = self.list:Add("DTextEntry")
		textBox:SetFont("Default")
		textBox:Dock(TOP)
		textBox:SetTall(30)
		textBox:DockMargin(10, 0, 10, 0)
		textBox:SetValue(HELPER_INFO.modelName)
		function textBox:OnEnter(value)
			HELPER_INFO.modelName = textBox:GetText()

			if (HELPER_INFO.modelObject and IsValid(HELPER_INFO.modelObject)) then
				HELPER_INFO.modelObject:SetModel(HELPER_INFO.modelName)
			end
		end

		local changeModel = self.list:Add("DButton")
		changeModel:SetFont("Default")
		changeModel:Dock(TOP)
		changeModel:SetTall(25)
		changeModel:DockMargin(10, 5, 10, 0)
		changeModel:SetText("Change Model")
		function changeModel:DoClick()
			HELPER_INFO.modelName = textBox:GetText()

			if (HELPER_INFO.modelObject and IsValid(HELPER_INFO.modelObject)) then
				HELPER_INFO.modelObject:SetModel(HELPER_INFO.modelName)
			end
		end

		local toggleZ = self.list:Add("DButton")
		toggleZ:SetFont("Default")
		toggleZ:Dock(TOP)
		toggleZ:SetTall(25)
		toggleZ:DockMargin(10, 5, 10, 0)
		toggleZ:SetText("Toggle IgnoreZ")
		function toggleZ:DoClick()
			HELPER_INFO.ignoreZ = !HELPER_INFO.ignoreZ
		end

		local cpyInfo = self.list:Add("DButton")
		cpyInfo:SetFont("Default")
		cpyInfo:Dock(TOP)
		cpyInfo:SetTall(25)
		cpyInfo:DockMargin(10, 5, 10, 0)
		cpyInfo:SetText("Copy Informations")
		function cpyInfo:DoClick()
			SetClipboardText(Format(
				[[Local Pos, Ang:
				Pos = Vector(%s, %s, %s)
				Ang = Angle(%s, %s, %s)]]
			, HELPER_INFO.renderPos[1], HELPER_INFO.renderPos[2], HELPER_INFO.renderPos[3]
			, HELPER_INFO.renderAng[1], HELPER_INFO.renderAng[2], HELPER_INFO.renderAng[3]))
		end
	end
	vgui.Register("nutHelperFrame", PANEL, "DFrame")

	function SWEP:PrimaryAttack()
		if IsFirstTimePredicted() then
			local trace = LocalPlayer():GetEyeTraceNoCursor()
			local ent = trace.Entity

			if (ent and IsValid(ent)) then
				HELPER_INFO.entity = ent
			end
		end
	end

	function SWEP:Reload()
		if (!self.menuOpen) then
			self.menuOpen = true

			local a = vgui.Create("nutHelperFrame")
			timer.Simple(.3, function()
				self.menuOpen = false
			end)
		end
	end
	
	function SWEP:SecondaryAttack()
		return false
	end

	function SWEP:Deploy()
	end

	function SWEP:Holster()
		HELPER_INFO.renderPos = Vector()
		HELPER_INFO.renderAng = Angle()
		HELPER_INFO.modelAng = Angle()
		HELPER_INFO.entity = nil
		
		if (HELPER_INFO.modelObject and IsValid(HELPER_INFO.modelObject)) then
			HELPER_INFO.modelObject:Remove()
		end

		return true
	end

	function SWEP:OnRemove()
	end

	function SWEP:Think()
	end

	HELPER_INFO = HELPER_INFO or {}
	HELPER_INFO.renderPos = Vector()
	HELPER_INFO.renderAng = Angle()
	HELPER_INFO.modelAng = Angle()
	HELPER_INFO.modelName = "models/props_junk/PopCan01a.mdl"
	HELPER_INFO.ignoreZ = false

	function SWEP:DrawHUD()
		local w, h = ScrW(), ScrH()
		local cury = h/4*3
		local tx, ty = draw.SimpleText("Left Click: Select Entity", "nutMediumFont", w/2, cury, color_white, 1, 1)
		cury = cury + ty
		local tx, ty = draw.SimpleText("Right Click: Deselect Entity", "nutMediumFont", w/2, cury, color_white, 1, 1)
		cury = cury + ty
		local tx, ty = draw.SimpleText("Reload: Register Area", "nutMediumFont", w/2, cury, color_white, 1, 1)
	end

	hook.Add("PostDrawOpaqueRenderables", "helperDrawModel", function()
		local ent = HELPER_INFO.entity

		if (ent and IsValid(ent)) then
			if (HELPER_INFO.modelObject and IsValid(HELPER_INFO.modelObject)) then
				local dPos, dAng = ent:GetPos(), ent:GetAngles()
				dPos, dAng = LocalToWorld(HELPER_INFO.renderPos, HELPER_INFO.renderAng, dPos, dAng)

				HELPER_INFO.modelObject:SetRenderOrigin(dPos)
				HELPER_INFO.modelObject:SetRenderAngles(dAng)
				if (HELPER_INFO.ignoreZ) then
					cam.IgnoreZ(true)
				end
					HELPER_INFO.modelObject:DrawModel()
				if (HELPER_INFO.ignoreZ) then
					cam.IgnoreZ(false)
				end
			else
				HELPER_INFO.modelObject = ClientsideModel(HELPER_INFO.modelName, RENDERGROUP_TRANSLUCENT)
				HELPER_INFO.modelObject:SetNoDraw(true)
			end
		else
			if (HELPER_INFO.modelObject and IsValid(HELPER_INFO.modelObject)) then
				HELPER_INFO.modelObject:Remove()
			end
		end
	end)
end