ATTRIBUTE.name = "Stamina"
ATTRIBUTE.desc = "Affects how fast you can run."

function ATTRIBUTE:OnSetup(client, value)
	client:SetRunSpeed(nut.config.Get("runSpeed") + value)
end