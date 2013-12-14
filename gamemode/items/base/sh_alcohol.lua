BASE.name = "Alcohol Base"
BASE.amount = 0.2
BASE.time = 180
BASE.category = "Alcohol"
BASE.functions = {}
BASE.functions.Use = {
	text = "Consume",
	run = function(item)
		if (CLIENT) then return end
		
		local client = item.player
		client:SetNetVar("drunk", client:GetNetVar("drunk", 0) + item.amount)

		timer.Simple(item.time, function()
			if (IsValid(client)) then
				client:SetNetVar("drunk", math.max(client:GetNetVar("drunk", 0) - item.amount, 0))
			end
		end)
	end
}