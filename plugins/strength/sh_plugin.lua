PLUGIN.name = "Strength"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a strength attribute."

if (SERVER) then
	-- Scale the amount of damage the attribute adds.
	local STR_MULTIPLIER = 0.3

	function PLUGIN:PlayerGetFistDamage(client, damage, context)
		if (client:getChar()) then
			-- Add to the total fist damage.
			context.damage = context.damage + (client:getChar():getAttrib("str", 0) * STR_MULTIPLIER)
		end
	end

	function PLUGIN:PlayerThrowPunch(client, hit)
		if (client:getChar()) then
			client:getChar():updateAttrib("str", 0.005)
		end
	end
end