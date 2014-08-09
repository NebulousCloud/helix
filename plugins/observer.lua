PLUGIN.name = "Observer"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Hides admins who noclip and restoring position."

if (SERVER) then
	function PLUGIN:PlayerNoClip(client)
		if (client:IsAdmin()) then
			if (client:GetMoveType() == MOVETYPE_WALK) then
				client:SetNutVar("noclipPos", client:GetPos())
				client:SetNoDraw(true)
				client:DrawShadow(false)
				client:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				client:SetNutVar("noclipping", true)
				nut.util.AddLog(Format("%s entered observer mode.", client:Name()), LOG_FILTER_CONCOMMAND)
			else
				client:SetNoDraw(false)
				client:DrawShadow(true)
				client:SetCollisionGroup(COLLISION_GROUP_PLAYER)

				if (client:GetInfoNum("nut_observetp", 0) > 0) then
					local position = client:GetNutVar("noclipPos")

					if (position) then
						timer.Simple(0, function()
							client:SetPos(position)
						end)
					end
				end

				client:SetNutVar("noclipPos", nil)
				client:SetNutVar("noclipping", nil)
				nut.util.AddLog(Format("%s quit observer mode.", client:Name()), LOG_FILTER_CONCOMMAND)
			end
		end
	end
else
	CreateClientConVar("nut_observetp", "0", true, true)
	local showESP = CreateClientConVar("nut_observeesp", "1", true, true)

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if (client:IsAdmin() and !IsValid(client:GetObserverTarget()) and client.character and client:GetMoveType() == MOVETYPE_NOCLIP and showESP:GetInt() > 0) then
			for k, v in pairs(player.GetAll()) do
				if (v != client and v.character) then
					local position = v:LocalToWorld(v:OBBCenter()):ToScreen()
					local x, y = position.x, position.y

					nut.util.DrawText(x, y, v:Name(), team.GetColor(v:Team()))
				end
			end
		end
	end
end
