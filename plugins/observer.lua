PLUGIN.name = "Observer"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds on to the no-clip mode to prevent instrusion."

if (CLIENT) then
	-- Create a setting to see if the player will teleport back after noclipping.
	NUT_CVAR_OBSTPBACK = CreateClientConVar("nut_obstpback", 0, true, true)
	NUT_CVAR_ADMINESP = CreateClientConVar("nut_obsesp", 1, true, true)

	local client, sx, sy, scrPos, marginx, marginy, x, y, teamColor, distance, factor, size, alpha
	local dimDistance = 1024
	function PLUGIN:HUDPaint()
		client = LocalPlayer()
		
		if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle() and NUT_CVAR_ADMINESP:GetBool()) then
			sx, sy = surface.ScreenWidth(), surface.ScreenHeight()

			for k, v in ipairs(player.GetAll()) do
				if (v == client) then continue end

				scrPos = v:GetPos():ToScreen()
				marginx, marginy = sy*.1, sy*.1
				x, y = math.Clamp(scrPos.x, marginx, sx - marginx), math.Clamp(scrPos.y, marginy, sy - marginy)
				teamColor = team.GetColor(v:Team())
				distance = client:GetPos():Distance(v:GetPos())
				factor = 1 - math.Clamp(distance/dimDistance, 0, 1)
				size = math.max(10, 32*factor)
				alpha = math.Clamp(255*factor, 80, 255)

				surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, alpha)
				surface.DrawLine(sx * 0.5, sy * 0.5, x, y)
				surface.DrawTexturedRect(x - size/2, y - size/2, size, size)

				nut.util.drawText(v:Name(), x, y - size, ColorAlpha(teamColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
			end
		end
	end

	function PLUGIN:SetupQuickMenu(menu)
		if (LocalPlayer():IsAdmin()) then
			local button = menu:addCheck(L"toggleESP", function(panel, state)
				if (state) then
					RunConsoleCommand("nut_obsesp", "1")
				else
					RunConsoleCommand("nut_obsesp", "0")
				end
			end, NUT_CVAR_ADMINESP:GetBool())

			menu:addSpacer()
		end
	end
else
	function PLUGIN:PlayerNoClip(client, state)
		-- Observer mode is reserved for administrators.
		if (client:IsAdmin()) then
			-- Check if they are entering noclip.
			if (state) then
				-- Store their old position and looking		 at angle.
				client.nutObsData = {client:GetPos(), client:EyeAngles()}
				-- Hide them so they are not visible.
				client:SetNoDraw(true)
				client:SetNotSolid(true)
				client:DrawWorldModel(false)
				client:DrawShadow(false)
				-- Don't allow the player to get hurt.
				client:GodEnable()
				hook.Run("OnPlayerObserve", client, state)
			else
				if (client.nutObsData) then
					-- Move they player back if they want.
					if (client:GetInfoNum("nut_obstpback", 0) > 0) then
						local position, angles = client.nutObsData[1], client.nutObsData[2]

						-- Do it the next frame since the player can not be moved right now.
						timer.Simple(0, function()
							client:SetPos(position)
							client:SetEyeAngles(angles)
							-- Make sure they stay still when they get back.
							client:SetVelocity(Vector(0, 0, 0))
						end)
					end

					-- Delete the old data.
					client.nutObsData = nil
				end

				-- Make the player visible again.
				client:SetNoDraw(false)
				client:SetNotSolid(false)
				client:DrawWorldModel(true)
				client:DrawShadow(true)
				-- Let the player take damage again.
				client:GodDisable()
				hook.Run("OnPlayerObserve", client, state)
			end
		end
	end
end