ATTRIBUTE.name = "Stamina"
ATTRIBUTE.desc = "Affects how fast you can run."

function ATTRIBUTE:onSetup(client, value)
	client:SetRunSpeed(nut.config.get("runSpeed") + value)
end