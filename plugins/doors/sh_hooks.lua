function PLUGIN:IsDoor(entity)
	return string.find(entity:GetClass(), "door")
end

function PLUGIN:IsDoorOwned(entity)
	return IsValid(entity:GetNetVar("owner"))
end

function PLUGIN:GetOwner(entity)
	return entity:GetNetVar("owner")
end

if (SERVER) then
	function PLUGIN:ShowTeam(client)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 84
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and self:IsDoor(entity)) then
			if (!self:IsDoorOwned(entity)) then
				client:ConCommand("nut doorbuy")
			elseif (self:GetOwner(entity) == client) then
				client:ConCommand("nut doorsell")
			end
		end
	end

	function PLUGIN:PlayerLoadout(client)
		client:Give("nut_keys")
	end

	function PLUGIN:OnCharChanged(client)
		for k, v in pairs(ents.GetAll()) do
			if (v:GetNetVar("owner") == client) then
				v:SetNetVar("title", "Door for Sale")
				v:SetNetVar("owner", NULL)
			end
		end
	end
else
	function PLUGIN:ShouldDrawTargetEntity(entity)
		if (self:IsDoor(entity)) then
			return true
		end
	end

	function PLUGIN:DrawTargetID(entity, x, y, alpha)
		if (self:IsDoor(entity) and !entity:GetNetVar("hidden")) then
			local mainColor = nut.config.mainColor
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

			nut.util.DrawText(x, y, entity:GetNetVar("title", "Door for Sale"), color)

			local owner = entity:GetNetVar("owner")
			y = y + nut.config.targetTall

			local text = "Purchase this door by pressing F2."

			if (entity:GetNetVar("unownable")) then
				text = "This door is unownable."
			elseif (IsValid(owner)) then
				text = "Owned by "..owner:Name().."."
			end

			nut.util.DrawText(x, y, text, Color(255, 255, 255, alpha), "nut_TargetFontSmall")
		end
	end
end