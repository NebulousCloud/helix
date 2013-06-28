-- ALl of this just for hands that match the player model.

local PLAYER = {}
PLAYER.DisplayName = "NutScript Player"

local modelList = {}

for k, v in pairs(player_manager.AllValidModels()) do
	modelList[string.lower(v)] = k
end

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Bool", 0, "NutWepRaised")

	if (SERVER and #player.GetAll() > 1) then
		net.Start("nut_PlayerDataTables")
		net.Broadcast()
	end
end

function PLAYER:GetHandsModel()
	local model = string.lower(self.Player:GetModel())

	for k, v in pairs(modelList) do
		if (string.find(string.gsub(model, "_", ""), v)) then
			model = v

			break
		end
	end

	return player_manager.TranslatePlayerHands(model)
end

-- Weapon raising/lowering stuff.
do
	local playerMeta = FindMetaTable("Player")

	function playerMeta:WepRaised()
		if (CLIENT and self != LocalPlayer() and !self.GetNutWepRaised) then
			RunConsoleCommand("ns_sendplydt")
		end
		
		return self.GetNutWepRaised and self:GetNutWepRaised() or false
	end

	if (SERVER) then
		util.AddNetworkString("nut_PlayerDataTables")

		function playerMeta:SetWepRaised(raised, weapon)
			if (!IsValid(self) or !self.character) then
				return
			end

			self:SetNutWepRaised(raised)

			weapon = weapon or self:GetActiveWeapon()

			if (IsValid(weapon)) then
				local time = 9001

				if (weapon.FireWhenLowered or raised) then
					time = 0.8
				end

				weapon:SetNextPrimaryFire(CurTime() + time)
				weapon:SetNextSecondaryFire(CurTime() + time)
			end
		end

		hook.Add("PlayerSwitchWeapon", "nut_AutoLower", function(client, oldWeapon, newWeapon)
			client:DrawViewModel(newWeapon.DrawViewModel != false)

			if (!newWeapon.AlwaysRaised and !nut.config.alwaysRaised[newWeapon:GetClass()]) then
				client:SetWepRaised(false, newWeapon)

				-- Need this some some SWEPs can override the first time we set it to false.
				timer.Simple(0.5, function()
					if (!IsValid(client)) then
						return
					end

					client:SetWepRaised(false, newWeapon)
				end)
			else
				client:SetWepRaised(true, newWeapon)
			end
		end)

		concommand.Add("ns_sendplydt", function(client, command, arguments)
			if (#player.GetAll() < 2) then
				return
			end
			
			if ((client.nut_NextUpdate or 0) < CurTime()) then
				net.Start("nut_PlayerDataTables")
				net.Send(client)

				client.nut_NextUpdate = CurTime() + 10
			end
		end)
	else
		net.Receive("nut_PlayerDataTables", function(length)
			print("Updating player datatables.")

			for k, v in pairs(player.GetAll()) do
				if (v != LocalPlayer() and !v.GetNutWepRaised) then
					player_manager.RunClass(v, "SetupDataTables")
				end
			end
		end)
	end
end

player_manager.RegisterClass("player_nut", PLAYER, "player_default")