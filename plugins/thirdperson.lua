
local PLUGIN = PLUGIN

PLUGIN.name = "New Fancy Third Person"
PLUGIN.author = "Black Tea"
PLUGIN.description = "Third Person plugin."

ix.config.Add("thirdperson", false, "Allow Thirdperson in the server.", nil, {
	category = "server"
})

if (CLIENT) then
	ix.option.Add("thirdpersonEnabled", ix.type.bool, false)
	ix.option.Add("thirdpersonClassic", ix.type.bool, false)

	local IX_CVAR_TP_VERT = CreateClientConVar("ix_tp_vertical", 10, true)
	local IX_CVAR_TP_HORI = CreateClientConVar("ix_tp_horizontal", 0, true)
	local IX_CVAR_TP_DIST = CreateClientConVar("ix_tp_distance", 50, true)

	local PANEL = {}

	local maxValues = {
		height = 30,
		horizontal = 30,
		distance = 100
	}

	function PANEL:Init()
		self:SetTitle(L("thirdpersonConfig"))
		self:SetSize(300, 140)
		self:Center()
		self:MakePopup()

		self.list = self:Add("DPanel")
		self.list:Dock(FILL)
		self.list:DockMargin(0, 0, 0, 0)

		local cfg = self.list:Add("DNumSlider")
		cfg:Dock(TOP)
		cfg:SetText("Height") -- Set the text above the slider
		cfg:SetMin(0)				 -- Set the minimum number you can slide to
		cfg:SetMax(30)				-- Set the maximum number you can slide to
		cfg:SetDecimals(0)			 -- Decimal places - zero for whole number
		cfg:SetConVar("ix_tp_vertical") -- Changes the ConVar when you slide
		cfg:DockMargin(10, 0, 0, 5)

		cfg = self.list:Add("DNumSlider")
		cfg:Dock(TOP)
		cfg:SetText("Horizontal") -- Set the text above the slider
		cfg:SetMin(-30)				 -- Set the minimum number you can slide to
		cfg:SetMax(30)				-- Set the maximum number you can slide to
		cfg:SetDecimals(0)			 -- Decimal places - zero for whole number
		cfg:SetConVar("ix_tp_horizontal") -- Changes the ConVar when you slide
		cfg:DockMargin(10, 0, 0, 5)

		cfg = self.list:Add("DNumSlider")
		cfg:Dock(TOP)
		cfg:SetText("Distance") -- Set the text above the slider
		cfg:SetMin(0)				 -- Set the minimum number you can slide to
		cfg:SetMax(100)				-- Set the maximum number you can slide to
		cfg:SetDecimals(0)			 -- Decimal places - zero for whole number
		cfg:SetConVar("ix_tp_distance") -- Changes the ConVar when you slide
		cfg:DockMargin(10, 0, 0, 5)
	end

	vgui.Register("ixTPConfig", PANEL, "DFrame")

	local function isAllowed()
		return ix.config.Get("thirdperson")
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:CanOverrideView()
		local entity = Entity(self:GetLocalVar("ragdoll", 0))

		if ((ix.gui.char and !ix.gui.char:IsVisible()) and
			ix.option.Get("thirdpersonEnabled", false) and
			!IsValid(self:GetVehicle()) and
			isAllowed() and
			IsValid(self) and
			self:GetChar() and
			!self:GetNetVar("actAng") and
			!IsValid(entity) and
			LocalPlayer():Alive()
			) then
			return true
		end
	end

	local view, traceData, traceData2, aimOrigin, crouchFactor, ft, curAng, owner
	local clmp = math.Clamp
	crouchFactor = 0
	function PLUGIN:CalcView(client, origin, angles, fov)
		ft = FrameTime()

		if (client:CanOverrideView() and LocalPlayer():GetViewEntity() == LocalPlayer()) then
			if ((client:OnGround() and client:KeyDown(IN_DUCK)) or client:Crouching()) then
				crouchFactor = Lerp(ft*5, crouchFactor, 1)
			else
				crouchFactor = Lerp(ft*5, crouchFactor, 0)
			end

			curAng = owner.camAng or Angle(0, 0, 0)
			view = {}
			traceData = {}
				traceData.start = 	client:GetPos() + client:GetViewOffset() +
									curAng:Up() * clmp(IX_CVAR_TP_VERT:GetInt(), 0, maxValues.height) +
									curAng:Right() * clmp(IX_CVAR_TP_HORI:GetInt(), -maxValues.horizontal, maxValues.horizontal) -
									client:GetViewOffsetDucked()*.5 * crouchFactor
				traceData.endpos = traceData.start - curAng:Forward() * clmp(IX_CVAR_TP_DIST:GetInt(), 0, maxValues.distance)
				traceData.filter = client
			view.origin = util.TraceLine(traceData).HitPos
			aimOrigin = view.origin
			view.angles = curAng + client:GetViewPunchAngles()

			traceData2 = {}
				traceData2.start = 	aimOrigin
				traceData2.endpos = aimOrigin + curAng:Forward() * 65535
				traceData2.filter = client

			if ((ix.option.Get("thirdpersonClassic", false) or owner:IsWepRaised() or
				(owner:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) and owner:GetVelocity():Length() >= 10)) ) then
				client:SetEyeAngles((util.TraceLine(traceData2).HitPos - client:GetShootPos()):Angle())
			end

			return view
		end
	end

	local diff, fm, sm
	function PLUGIN:CreateMove(cmd)
		owner = LocalPlayer()

		if (owner:CanOverrideView() and owner:GetMoveType() != MOVETYPE_NOCLIP and
			LocalPlayer():GetViewEntity() == LocalPlayer()) then
			fm = cmd:GetForwardMove()
			sm = cmd:GetSideMove()
			diff = (owner:EyeAngles() - (owner.camAng or Angle(0, 0, 0)))[2] or 0
			diff = diff/90

			cmd:SetForwardMove(fm + sm*diff)
			cmd:SetSideMove(sm + fm*diff)
			return false
		end
	end

	function PLUGIN:InputMouseApply(cmd, x, y, ang)
		owner = LocalPlayer( )

		if (!owner.camAng) then
		    owner.camAng = Angle( 0, 0, 0 )
		end

	    if (owner:CanOverrideView() and LocalPlayer():GetViewEntity() == LocalPlayer()) then

		    owner.camAng.p = clmp(math.NormalizeAngle( owner.camAng.p + y / 50 ), -85, 85)
		    owner.camAng.y = math.NormalizeAngle( owner.camAng.y - x / 50 )

			return true
		end
	end

	function PLUGIN:ShouldDrawLocalPlayer()
		if (LocalPlayer():GetViewEntity() == LocalPlayer() and !IsValid(LocalPlayer():GetVehicle())) then
			return LocalPlayer():CanOverrideView()
		end
	end
end
