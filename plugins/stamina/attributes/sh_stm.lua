ATTRIBUTE.name = "Stamina"
ATTRIBUTE.description = "Affects how fast you can run."

function ATTRIBUTE:OnSetup(client, value)
	client:SetRunSpeed(ix.config.Get("runSpeed") + value)
end
