ATTRIBUTE.name = "Stamina"
ATTRIBUTE.description = "Affects how fast you can run."

function ATTRIBUTE:OnSetup(client, value)
	client:SetRunSpeed(nut.config.Get("runSpeed") + value)
end