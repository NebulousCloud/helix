ATTRIBUTE.name = "Stamina"
ATTRIBUTE.description = "Affects how fast you can run."

function ATTRIBUTE:OnSetup(client, value)
	client:UpdateRunSpeedModifier("stmBoost", ix.plugin.list.runspeed.ModifierTypes.ADD, value, true)
end
