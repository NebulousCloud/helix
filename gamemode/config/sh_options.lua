
if (CLIENT) then
	ix.option.Add("24hourTime", ix.type.bool, false)
	ix.option.Add("cheapBlur", ix.type.bool, false)
	ix.option.Add("altLower", ix.type.bool, true)
	ix.option.Add("alwaysShowBars", ix.type.bool, false)
end

ix.option.Add("language", bit.bor(ix.type.string, ix.type.array), "english", {
	bNetworked = true,
	populate = function()
		local entries = {}

		for k, _ in SortedPairs(ix.lang.stored) do
			local name = ix.lang.names[k]
			local name2 = k:sub(1, 1):upper()..k:sub(2)

			if (name) then
				name = name.." ("..name2..")"
			else
				name = name2
			end

			entries[k] = name
		end

		return entries
	end
})
