
PLUGIN.name = "Observer"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds on to the no-clip mode to prevent intrusion."

CAMI.RegisterPrivilege({
	Name = "Helix - Observer",
	MinAccess = "admin"
})

ix.option.Add("observerTeleportBack", ix.type.bool, true, {
	bNetworked = true,
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer", nil)
	end
})

if (CLIENT) then
	ix.option.Add("observerESP", ix.type.bool, true, {
		category = "observer",
		hidden = function()
			return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer", nil)
		end
	})

	local dimDistance = 1024
	local aimLength = 128
	local barHeight = 2

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if (ix.option.Get("observerESP", true) and client:GetMoveType() == MOVETYPE_NOCLIP and
			!client:InVehicle() and CAMI.PlayerHasAccess(client, "Helix - Observer", nil)) then
			local scrW, scrH = ScrW(), ScrH()

			for _, v in ipairs(player.GetAll()) do
				if (v == client or !v:GetCharacter() or client:GetAimVector():Dot((v:GetPos() - client:GetPos()):GetNormal()) < 0.65) then
					continue
				end

				local screenPosition = v:GetPos():ToScreen()
				local aimPosition = (v:GetPos() + v:GetAimVector() * aimLength):ToScreen()

				local marginX, marginY = scrH * .1, scrH * .1
				local x, y = math.Clamp(screenPosition.x, marginX, scrW - marginX), math.Clamp(screenPosition.y, marginY, scrH - marginY)
				local aimX, aimY = math.Clamp(aimPosition.x, marginX, scrW - marginX), math.Clamp(aimPosition.y, marginY, scrH - marginY)

				local teamColor = team.GetColor(v:Team())
				local distance = client:GetPos():Distance(v:GetPos())
				local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
				local size = math.max(10, 32 * factor)
				local alpha = math.max(255 * factor, 80)
				local aimAlpha = (1 - factor * 1.5) * 80

				surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, alpha)
				surface.SetFont("ixGenericFont")

				local text = v:Name()
				local textWidth, textHeight = surface.GetTextSize(text)
				local barWidth = math.Clamp((v:Health() / v:GetMaxHealth()) * textWidth, 0, textWidth)

				surface.DrawRect(x - size / 2, y - size / 2, size, size)

				-- we can assume that if we're using cheap blur, we'd want to save some fps here
				if (!ix.option.Get("cheapBlur", false)) then
					local data = {}
					data.start = client:EyePos()
					data.endpos = v:EyePos()
					data.filter = {client, v}

					if (util.TraceLine(data).Hit) then
						aimAlpha = alpha
					else
						aimAlpha = (1 - factor * 4) * 80
					end
				end

				if (aimPosition.visible) then
					surface.SetDrawColor(teamColor.r * 1.2, teamColor.g * 1.2, teamColor.b * 1.2, aimAlpha)
					surface.DrawLine(x, y, aimX, aimY)
					surface.DrawLine(x, y + 1, aimX, aimY + 1)
				end

				surface.SetDrawColor(teamColor.r * 1.6, teamColor.g * 1.6, teamColor.b * 1.6, alpha)
				surface.DrawRect(x - barWidth / 2, y - size - textHeight / 2, barWidth, barHeight)

				ix.util.DrawText(text, x, y - size, ColorAlpha(teamColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
			end
		end
	end

	function PLUGIN:ShouldPopulateEntityInfo(entity)
		if (IsValid(entity)) then
			if ((entity:IsPlayer() or IsValid(entity:GetNetVar("player"))) and entity:GetMoveType() == MOVETYPE_NOCLIP) then
				return false
			end
		end
	end

	function PLUGIN:DrawPhysgunBeam(client, physgun, enabled, target, bone, hitPos)
		if (client != LocalPlayer() and client:GetMoveType() == MOVETYPE_NOCLIP) then
			return false
		end
	end

	function PLUGIN:PrePlayerDraw(client)
		if (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) then
			return true
		end
	end
else
	ix.log.AddType("observerEnter", function(client, ...)
		return string.format("%s entered observer.", client:Name())
	end)

	ix.log.AddType("observerExit", function(client, ...)
		if (ix.option.Get(client, "observerTeleportBack", true)) then
			return string.format("%s exited observer.", client:Name())
		else
			return string.format("%s exited observer at their location.", client:Name())
		end
	end)

	function PLUGIN:CanPlayerEnterObserver(client)
		if (CAMI.PlayerHasAccess(client, "Helix - Observer", nil)) then
			return true
		end
	end

	function PLUGIN:PlayerNoClip(client, state)
		if (hook.Run("CanPlayerEnterObserver", client)) then
			if (state) then
				client.ixObsData = {client:GetPos(), client:EyeAngles()}

				-- Hide them so they are not visible.
				client:SetNoDraw(true)
				client:SetNotSolid(true)
				client:DrawWorldModel(false)
				client:DrawShadow(false)
				client:GodEnable()
				client:SetNoTarget(true)

				hook.Run("OnPlayerObserve", client, state)
			else
				if (client.ixObsData) then
					-- Move they player back if they want.
					if (ix.option.Get(client, "observerTeleportBack", true)) then
						local position, angles = client.ixObsData[1], client.ixObsData[2]

						-- Do it the next frame since the player can not be moved right now.
						timer.Simple(0, function()
							client:SetPos(position)
							client:SetEyeAngles(angles)
							client:SetVelocity(Vector(0, 0, 0))
						end)
					end

					client.ixObsData = nil
				end

				-- Make the player visible again.
				client:SetNoDraw(false)
				client:SetNotSolid(false)
				client:DrawWorldModel(true)
				client:DrawShadow(true)
				client:GodDisable()
				client:SetNoTarget(false)

				hook.Run("OnPlayerObserve", client, state)
			end

			return true
		end
	end

	function PLUGIN:OnPlayerObserve(client, state)
		if (state) then
			ix.log.Add(client, "observerEnter")
		else
			ix.log.Add(client, "observerExit")
		end
	end
end
