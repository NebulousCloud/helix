PLUGIN.name = "Strength"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a strength attribute."

if (SERVER) then
	function PLUGIN:PlayerGetFistDamage(client, damage, context)
		if (client:getChar()) then
			-- Add to the total fist damage.
			context.damage = context.damage + (client:getChar():getAttrib("str", 0) * nut.config.get("strMultiplier"))
		end
	end

	function PLUGIN:PlayerThrowPunch(client, hit)
		if (client:getChar()) then
			client:getChar():updateAttrib("str", 0.001)
		end
	end
end

-- Configuration for the plugin
nut.config.add("strMultiplier", 0.3, "The strength multiplier scale", nil, {
	form = "Float",
	data = {min=0, max=1.0},
	category = "Strength"
})
