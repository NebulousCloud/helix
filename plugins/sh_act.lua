local PLUGIN = PLUGIN
PLUGIN.name = "Player Acts"
PLUGIN.author = "Chessnut and rebel1324"
PLUGIN.desc = "Adds animations that can be performed by players."

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
sequences["metrocop"] = {
	["threat"] = {"plazathreat1"},
	["lean"] = {"plazalean", true, lean},
	["crossarms"] = {"plazathreat2", true},
	["point"] = {"point"},
	["block"] = {"blockentry", false, lean},
	["startle"] = {"canal5breact1"},
	["warn"] = {"luggagewarn"},
	["moleft"] = {"motionleft"},
	["moright"] = {"motionright"}
}
sequences["overwatch"] = {
	["type"] = {"console_type_loop", true},
	["sigadv"] = {"signal_advance"},
	["sigfor"] = {"signal_forward"},
	["siggroup"] = {"signal_group"},
	["sighalt"] = {"signal_halt"},
	["sigleft"] = {"signal_left"},
	["sigright"] = {"signal_right"},
	["sigcover"] = {"signal_takecover"}
}
sequences["citizen_male"] = {
	["arrestlow"] = {"arrestidle", true},
	["cheer"] = {"cheer1"},
	["clap"] = {"cheer2"},
	["sitwall"] = {"plazaidle4", true, lean},
	["stand"] = {"d1_t01_breakroom_watchclock"},
	["standpockets"] = {"d1_t02_playground_cit2_pockets", true},
	["showid"] = {"d1_t02_plaza_scan_id"},
	["pant"] = {"d2_coast03_postbattle_idle02", true},
	["leanback"] = {"lean_back", true, lean},
	["sit"] = {"sit_ground", true},
	["sitknees"] = {"sitcouchknees1", true}
}
sequences["citizen_female"] = table.Copy(sequences["citizen_male"])

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

		local data = {
			start = client:GetPos(),
			endpos = client:GetPos() - Vector(0, 0, 16),
			filter = client
		}
		local trace = util.TraceLine(data)

		if (!trace.Hit) then
			nut.util.Notify("You must be on the ground to perform acts.", client)

			return
		end

		local override = client:GetOverrideSeq()
		local class = nut.anim.GetClass(string.lower(client:GetModel()))
		local list = sequences[class]

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
	end
	
	function PLUGIN:PlayerDeath(client)
		self:PlayerExitSeq(client)
	end

	function PLUGIN:PlayerSpawn(client)
		self:PlayerExitSeq(client)
	end
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
	
	function PLUGIN:CalcView(client, origin, angles, fov)
		if (client:GetOverrideSeq() and client:GetNetVar("seqCam")) then
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
end

for k, v in pairs(sequences) do
	for k2, v2 in pairs(v) do
		nut.command.Register({
			onRun = function(client, arguments)
				PLUGIN:PlayerStartSeq(client, k2)
			end
		}, "act"..k2)
	end
end
