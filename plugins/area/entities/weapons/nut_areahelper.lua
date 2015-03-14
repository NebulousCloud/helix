AddCSLuaFile()

if( CLIENT ) then
	SWEP.PrintName = "Area Helper";
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
	areaPoint = areaPoint or {}

	function SWEP:PrimaryAttack()
		if IsFirstTimePredicted() then
			local trace = LocalPlayer():GetEyeTraceNoCursor()
			local pos = trace.HitPos

			if (areaPoint.startVector) then
				areaPoint.endVector = pos
				surface.PlaySound("buttons/button15.wav")
			else
				areaPoint.startVector = pos
				surface.PlaySound("buttons/button3.wav")
			end
		end
	end

	function SWEP:openAreaManager()		
	end

	function SWEP:Reload()
		if (!self.ohWow and areaPoint.startVector and areaPoint.endVector) then
			self.ohWow = true
			Derma_StringRequest("Area Name?", "Area Name?", "", function(text)
				self.ohWow = false
				netstream.Start("areaAdd", text, areaPoint.startVector, areaPoint.endVector)
			end, function()
				self.ohWow = false 
			end)
		end
	end
	
	function SWEP:SecondaryAttack()
		if (IsFirstTimePredicted()) then
			areaPoint = {}
			
			if (!self.rSnd) then
				surface.PlaySound("buttons/button2.wav")
				self.rSnd = true

				timer.Simple(.5, function()
					self.rSnd = false
				end)
			end
		end

		return false
	end

	function SWEP:Deploy()
	end

	function SWEP:Holster()
		return true
	end

	function SWEP:OnRemove()
	end

	function SWEP:Think()
	end

	function SWEP:DrawHUD()
		local w, h = ScrW(), ScrH()
		local cury = h/4*3
		local tx, ty = draw.SimpleText("Left Click: Set Area Point", "nutMediumFont", w/2, cury, color_white, 1, 1)
		cury = cury + ty
		local tx, ty = draw.SimpleText("Right Click: Reset Area Point", "nutMediumFont", w/2, cury, color_white, 1, 1)
		cury = cury + ty
		local tx, ty = draw.SimpleText("Reload: Register Area", "nutMediumFont", w/2, cury, color_white, 1, 1)

		local trace = LocalPlayer():GetEyeTraceNoCursor()
		local pos = trace.HitPos

		surface.SetDrawColor(255, 0, 0)
		local aimPos = pos:ToScreen()
		if (pos and aimPos) then
			surface.DrawLine(aimPos.x, aimPos.y - 10, aimPos.x, aimPos.y + 10)
			surface.DrawLine(aimPos.x - 10, aimPos.y, aimPos.x + 10, aimPos.y)
		end
	end

	hook.Add("PostDrawOpaqueRenderables", "helperDraw", function()
		if (areaPoint) then
			local sPos, ePos 
			if (areaPoint.startVector and areaPoint.endVector) then
				sPos = areaPoint.startVector
				ePos = areaPoint.endVector
			elseif (areaPoint.startVector and !areaPoint.endVector) then
				sPos = areaPoint.startVector
				local trace = LocalPlayer():GetEyeTraceNoCursor()
				ePos = trace.HitPos
			end

			if (sPos and ePos) then
				local c1, c2, c3, c4
				--render.DrawLine(sPos, ePos, color_white)
				c1 = Vector(sPos[1], ePos[2], sPos[3])
				render.DrawLine(sPos, c1, color_white)
				c2 = Vector(ePos[1], sPos[2], sPos[3])
				render.DrawLine(sPos, c2, color_white)
				c3 = Vector(ePos[1], ePos[2], sPos[3])
				render.DrawLine(c3, c1, color_white)
				c4 = Vector(ePos[1], ePos[2], sPos[3])
				render.DrawLine(c3, c2, color_white)

				c1 = Vector(sPos[1], ePos[2], ePos[3])
				render.DrawLine(ePos, c1, color_white)
				c2 = Vector(ePos[1], sPos[2], ePos[3])
				render.DrawLine(ePos, c2, color_white)
				c3 = Vector(sPos[1], sPos[2], ePos[3])
				render.DrawLine(c3, c1, color_white)
				c4 = Vector(sPos[1], sPos[2], ePos[3])
				render.DrawLine(c3, c2, color_white)

				local c5, c6, c7, c8
				c5 = Vector(sPos[1], ePos[2], sPos[3])
				render.DrawLine(c1, c5, color_white)
				c6 = Vector(ePos[1], sPos[2], sPos[3])
				render.DrawLine(c2, c6, color_white)
				c7 = Vector(sPos[1], sPos[2], sPos[3])
				render.DrawLine(c3, c7, color_white)
				c4 = Vector(ePos[1], ePos[2], ePos[3])
				c8 = Vector(ePos[1], ePos[2], sPos[3])
				render.DrawLine(c4, c8, color_white)
			end
		end
	end)
end