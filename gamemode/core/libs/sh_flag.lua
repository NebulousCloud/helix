nut.flag = nut.flag or {}
nut.flag.list = nut.flag.list or {}

-- Adds a flag that does something when set.
function nut.flag.add(flag, desc, callback)
	-- Add the flag to a list, storing the description and callback (if there is one).
	nut.flag.list[flag] = {desc = desc, callback = callback}
end

do
	-- Extend the character metatable to allow flag giving/taking.
	local character = FindMetaTable("Character")

	function character:setFlags(flags)
		self:setData("f", flags)
	end

	function character:getFlags()
		return self:getData("f", "")
	end

	function character:giveFlags(flags)
		self:setFlags(self:getFlags()..flags)
	end

	function character:takeFlags(flags)
		self:setFlags(self:getFlags():gsub(flags, ""))
	end

	function character:hasFlags(flags)
		return self:getFlags():find(flags, 1, true) != nil
	end
end