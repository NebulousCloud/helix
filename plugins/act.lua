local PLUGIN = PLUGIN
PLUGIN.name = "Player Acts"
PLUGIN.author = "Chessnut and rebel1324"
PLUGIN.desc = "Adds animations that can be performed by players."
PLUGIN.sequences = {}

local function lean(client)
	local data = {
		start = client:GetPos(),
		endpos = client:GetPos() - client:GetForward()*54,
		filter = client
	}
	local trace = util.TraceLine(data)

	if (!trace.HitWorld) then
		nut.util.Notify("You need to be against a wall to perform this act.", client)

		return false
	end
end

local sequences = {}
PLUGIN.sequences["metrocop"] = {
	["threat"] = {"plazathreat1", name = "Melee Threat"},
	["lean"] = {"plazalean", true, lean, name = "Lean Back"},
	["crossarms"] = {"plazathreat2", false, name = "Cross Arms"},
	["point"] = {"point", name = "Point"},
	["block"] = {"blockentry", false, lean, name = "Block Entry"},
	["startle"] = {"canal5breact1", name = "Startle"},
	["warn"] = {"luggagewarn", name = "Warning"},
	["moleft"] = {"motionleft", name = "Motion Left"},
	["moright"] = {"motionright", name = "Motion Right"}
}
PLUGIN.sequences["overwatch"] = {
	["type"] = {"console_type_loop", true, name = "Type Console"},
	["sigadv"] = {"signal_advance", name = "Advance"},
	["sigfor"] = {"signal_forward", name = "Forward"},
	["siggroup"] = {"signal_group", name = "Regroup"},
	["sighalt"] = {"signal_halt", name = "Halt"},
	["sigleft"] = {"signal_left", name = "Left"},
	["sigright"] = {"signal_right", name = "Right"},
	["sigcover"] = {"signal_takecover", name = "Cover"}
}
PLUGIN.sequences["citizen_male"] = {
	["arrestlow"] = {"arrestidle", true, name = "Arrest Idle"},
	["cheer"] = {"cheer1", name = "Cheer"},
	["clap"] = {"cheer2", name = "Clap"},
	["sitwall"] = {"plazaidle4", true, lean, name = "Sit Wall"},
	["stand"] = {"d1_t01_breakroom_watchclock", name = "Stand"},
	["standpockets"] = {"d1_t02_playground_cit2_pockets", true, name = "Stand Pockets"},
	["showid"] = {"d1_t02_plaza_scan_id", name = "Show ID"},
	["pant"] = {"d2_coast03_postbattle_idle02", true, name = "Pant"},
	["leanback"] = {"lean_back", true, lean, name = "Lean Back"},
	["sit"] = {"sit_ground", true, name = "Sit"},
	["lying"] = {"Lying_Down", true, name = "Lying"},
	["examineground"] = {"d1_town05_Daniels_Kneel_Idle", true, name = "Examine Ground"},
	["injured2"] = {"d1_town05_Wounded_Idle_1", true, name = "Injured 1"},
	["injured3"] = {"d1_town05_Wounded_Idle_2", true, name = "Injured 2"},
	["injuredwall"] = {"injured1", true, lean, name = "Injured Wall"},
}
PLUGIN.sequences["citizen_female"] = table.Copy(PLUGIN.sequences["citizen_male"])
local notsupported = {
	"injured3",
	"injured4",
	"injured1",
	"examineground",
	"standpockets",
}
for _, str in pairs( notsupported ) do
	PLUGIN.sequences["citizen_female"][ str ] = nil
end

if (SERVER) then
	function PLUGIN:CanFallOver( client )
		if (client:GetOverrideSeq()) then
			nut.util.Notify("You can't fallover while you're acting.", client)
			return false
		end
	end
	
	function PLUGIN:PlayerStartSeq(client, sequence)
		if (client:GetNutVar("nextAct", 0) >= CurTime()) then
			nut.util.Notify("You can not perform another act yet.", client)

			return
		end

		local data = {}
		data.start = client:GetPos()
		data.endpos = data.start - Vector(0, 0, 1)
		data.filter = client
		data.mins = Vector(-16, -16, 0)
		data.maxs = Vector(16, 16, 16)
		local trace = util.TraceHull(data)

		if (!trace.Hit) then
			nut.util.Notify("You must be on the ground to perform acts.", client)

			return
		end

		if (hook.Run("CanStartSeq", client) == false) then
			return
		end

		local override = client:GetOverrideSeq()
		local class = nut.anim.GetClass(string.lower(client:GetModel()))
		local list = self.sequences[class]

		if (class and list) then
			if (override) then
				for k, v in pairs(list) do
					if (v[1] == override and v[2] == true) then
						self:PlayerExitSeq(client)

						return
					end
				end
			end

			local act = list[sequence]
			
			if (act) then
				if (act[3] and act[3](client) == false) then
					return
				end

				local time

				if (act[2] == true) then
					time = 0
				end

				time = client:SetOverrideSeq(act[1], time, function()
					client:Freeze(true)
					client:SetNetVar("seqCam", true)
				end, function()
					client:Freeze(false)
					client:SetNetVar("seqCam", nil)
				end)

				if (time and time > 0) then
					client:SetNutVar("nextAct", CurTime() + time + 1)
				end

				client:SetNutVar("inAct", true)
			else
				nut.util.Notify("Your model can not perform this act.", client)
			end
		else
			nut.util.Notify("Your model can not perform this act.", client)
		end
	end

	function PLUGIN:PlayerExitSeq(client)
		client:SetNutVar("nextAct", CurTime() + 1)
		client:ResetOverrideSeq()
		client:Freeze(false)
		client:SetNutVar("inAct", false)
	end
	
	function PLUGIN:PlayerDeath(client)
		self:PlayerExitSeq(client)
	end

	function PLUGIN:PlayerSpawn(client)
		self:PlayerExitSeq(client)
	end

	concommand.Add("nut_leaveact", function(client, command, arguments)
		if (IsValid(client) and client:GetNutVar("inAct") and CurTime() >= client:GetNutVar("nextAct", 0)) then
			PLUGIN:PlayerExitSeq(client)
		end
	end)
else
	PLUGIN.AngMod = Angle( 0, 0, 0 )
	PLUGIN.MouseSensitive = 20

	function PLUGIN:InputMouseApply( cmd, x, y, ang )
		if LocalPlayer():GetOverrideSeq() then
			self.AngMod = self.AngMod - Angle( -y/self.MouseSensitive, x/self.MouseSensitive, 0 )
			self.AngMod.p = math.Clamp( self.AngMod.p, -80, 80 )
		--	self.AngMod.y = math.Clamp( self.AngMod.y, -180, 180 )
		else
			self.AngMod = Angle( 0, 0, 0 )
		end
	end
	
	function PLUGIN:PlayerBindPress(client, bind, pressed)
		if (client:GetOverrideSeq() and bind == "+jump") then
			if (client:GetNutVar("leavingAct")) then
				client:SetNutVar("leavingAct", false)
				timer.Remove("nut_LeavingAct")
			else
				client:SetNutVar("leavingAct", true)
				timer.Create("nut_LeavingAct", 1, 1, function()
					RunConsoleCommand("nut_leaveact")
				end)
			end

			return true
		end
	end

	function PLUGIN:CalcView(client, origin, angles, fov)
		if (client:GetViewEntity() == client and client:GetOverrideSeq() and client:GetNetVar("seqCam")) then
			local view = {}
			local at = client:LookupAttachment( "eyes" )
			if at == 0 then at = client:LookupAttachment( "eye" ) end
			local att = client:GetAttachment( at ) 
			
			local ang = Angle( 0, client:GetAngles().y, 0 ) + self.AngMod
			local data = {
				start = att.Pos,
				endpos = att.Pos + ang:Forward() * -80 + ang:Up() * 20 + ang:Right() * 0
			}
			local trace = util.TraceLine(data)
			local position = trace.HitPos + trace.HitNormal*4

			view.origin = position
			view.angles = ang

			return view
			
		end
	end

	function PLUGIN:ShouldDrawLocalPlayer()
		if (LocalPlayer():GetOverrideSeq() and LocalPlayer():GetNetVar("seqCam")) then
			return true
		end
	end

	function PLUGIN:CreateQuickMenu(panel)
		local label = panel:Add("DLabel")
		label:Dock(TOP)
		label:SetText(" Quick Acts")
		label:SetFont("nut_TargetFont")
		label:SetTextColor(Color(233, 233, 233))
		label:SizeToContents()
		label:SetExpensiveShadow(2, Color(0, 0, 0))
		local category = panel:Add("DPanel")
		category:Dock(TOP)
		category:DockPadding(5, 5, 5, 5)
		category:DockMargin(0, 5, 0, 5)
		category:SetTall(35)
		panel.quickact = category:Add("DButton")
		panel.quickact:Dock(FILL)
		panel.quickact:SetText("Load List >>")
		panel.quickact:SetTextColor(Color(5, 5, 5))
		panel.quickact:SetFont("nut_TargetFontSmall")
		panel.quickact.DoClick = function(pnl)
			local class = nut.anim.GetClass(string.lower(LocalPlayer():GetModel()))
			local list = self.sequences[class]
			local menu = DermaMenu()
			if (list) then
				for uid, actdata in SortedPairs(list) do
					if (list) then
						menu:AddOption((actdata.name or uid), function()
							LocalPlayer():ConCommand(Format("say /act%s", uid))
						end)
					end
				end
			end
			menu:Open()
			menu:SetParent(pnl)
		end
	end

end

for k, v in pairs(PLUGIN.sequences) do
	for k2, v2 in pairs(v) do
		nut.command.Register({
			onRun = function(client, arguments)
				PLUGIN:PlayerStartSeq(client, k2)
			end
		}, "act"..k2)
	end
end
