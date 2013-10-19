PLUGIN.name = "Observer"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Hides admins who noclip and restoring position."

if (SERVER) then
	function PLUGIN:PlayerNoClip(client)
		if (client:IsAdmin()) then
			if (client:GetMoveType() == MOVETYPE_WALK) then
				client:SetNutVar("noclipPos", client:GetPos())
				client:SetNoDraw(true)
				client:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			else
				client:SetNoDraw(false)
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
			end
		end
	end
else
	CreateClientConVar("nut_observetp", "0", true, true)
end