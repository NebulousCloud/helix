
local PLUGIN = PLUGIN

function PLUGIN:GetPlayerAreaTrace()
	local client = LocalPlayer()

	return util.TraceLine({
		start = client:GetShootPos(),
		endpos = client:GetShootPos() + client:GetForward() * 96,
		filter = client
	})
end

function PLUGIN:StartEditing()
	ix.area.bEditing = true
	self.editStart = nil
	self.editProperties = nil
end

function PLUGIN:StopEditing()
	ix.area.bEditing = false

	if (IsValid(ix.gui.areaEdit)) then
		ix.gui.areaEdit:Remove()
	end
end
