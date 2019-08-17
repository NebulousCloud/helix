local PLUGIN = PLUGIN
local playerMeta = FindMetaTable("Player")
PLUGIN.name = "Walk/RunSpeed manager"
PLUGIN.author = "Lapin"
PLUGIN.description = "Allows the gamemode and plugins to apply runspeed/walkspeed modifiers without overwriting existing speed, which allow multiple plugins/addon to coexist"

if not SERVER then return end

PLUGIN.ModifierTypes = {
	MULT = 1,
	ADD = 2,
}

function playerMeta:RunSpeedModifierExists(identifier)
	return self.SpeedModifiers.run[identifier] != nil
end

function playerMeta:WalkSpeedModifierExists(identifier)
	return self.SpeedModifiers.walk[identifier] != nil
end

function playerMeta:UpdateAdvancedRunSpeed()
	PLUGIN:RecalcSpeed(self, false)
end

function playerMeta:UpdateAdvancedWalkSpeed()
	PLUGIN:RecalcSpeed(self, true)
end

function playerMeta:UpdateRunSpeedModifier(identifier, mod_type, value, do_not_recalc)
	self.SpeedModifiers.run[identifier] = self.SpeedModifiers.run[identifier] or {}
	self.SpeedModifiers.run[identifier].mod_type = mod_type
	self.SpeedModifiers.run[identifier].value = value
	if not do_not_recalc then
		PLUGIN:RecalcSpeed(self, false)
	end
end

function playerMeta:UpdateWalkSpeedModifier(identifier, mod_type, value, do_not_recalc)
	self.SpeedModifiers.walk[identifier] = self.SpeedModifiers.walk[identifier] or {}
	self.SpeedModifiers.walk[identifier].mod_type = mod_type
	self.SpeedModifiers.walk[identifier].value = value
	if not do_not_recalc then
		PLUGIN:RecalcSpeed(self, true)
	end
end


function playerMeta:RemoveRunSpeedModifier(identifier, do_not_recalc)
	if identifier == "base" then Error("You can't remove the base modifier") end
	self.SpeedModifiers.run[identifier] = nil
	if not do_not_recalc then
		PLUGIN:RecalcSpeed(self, false)
	end
end

function playerMeta:RemoveWalkSpeedModifier(identifier, do_not_recalc)
	if identifier == "base" then Error("You can't remove the base modifier") end
	self.SpeedModifiers.walk[identifier] = nil
	if not do_not_recalc then
		PLUGIN:RecalcSpeed(self, true)
	end
end


local sortFunc = function( a, b ) return a.mod_type > b.mod_type end -- handle add or 

function PLUGIN:RecalcSpeed(client, walk)
	local targetTable
	local setFunc
	if walk == true then
		targetTable = client.SpeedModifiers.walk
		setFunc = client.SetWalkSpeed
	else
		targetTable = client.SpeedModifiers.run
		setFunc = client.SetRunSpeed
	end
	table.sort( targetTable, sortFunc)
	local baseValue = targetTable.base
	for uniqueIdentifier, tableData in pairs(targetTable) do
		if tableData == targetTable.base then continue end -- faster to compare table pointer than key (string)
		if (tableData.mod_type == PLUGIN.ModifierTypes.MULT) then
			baseValue = baseValue * tableData.value
		else
			baseValue = baseValue + tableData.value
		end
	end

	if (walk == false) then
		baseValue = math.Max(baseValue, client:GetWalkSpeed()) -- you're not supposed to run slower than you walk
	end

	setFunc(client, baseValue)

end

function PLUGIN:PostPlayerLoadout(client)
	client.SpeedModifiers = {
		walk = {
			base = ix.config.Get("walkSpeed")
		},
		run = {
			base = ix.config.Get("runSpeed")
		}
	}
	self:RecalcSpeed(client, true)
	self:RecalcSpeed(client, false)
end


