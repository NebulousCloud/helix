PLUGIN.name = "Strength"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a strength attribute."

if (SERVER) then
	function PLUGIN:PlayerGetFistDamage(client, damage, context)
		if (client:GetChar()) then
			-- Add to the total fist damage.
			context.damage = context.damage + (client:GetChar():GetAttrib("str", 0) * nut.config.Get("strMultiplier"))
		end
	end

	function PLUGIN:PlayerThrowPunch(client, hit)
		if (client:GetChar()) then
			client:GetChar():UpdateAttrib("str", 0.001)
		end
	end
end

-- Configuration for the plugin
nut.config.Add("strMultiplier", 0.3, "The strength multiplier scale", nil, {
	form = "Float",
	data = {min=0, max=1.0},
	category = "Strength"
})
