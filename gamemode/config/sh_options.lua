
if (CLIENT) then
	ix.option.Add("24hourTime", ix.type.bool, false, {
		category = "general"
	})

	ix.option.Add("altLower", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("alwaysShowBars", ix.type.bool, false, {
		category = "general"
	})

	ix.option.Add("cheapBlur", ix.type.bool, false, {
		category = "performance"
	})

	ix.option.Add("disableAnimations", ix.type.bool, false, {
		category = "performance"
	})
end

ix.option.Add("language", ix.type.array, "english", {
	category = "general",
	bNetworked = true,
	populate = function()
		local entries = {}

		for k, _ in SortedPairs(ix.lang.stored) do
			local name = ix.lang.names[k]
			local name2 = k:sub(1, 1):upper() .. k:sub(2)

			if (name) then
				name = name .. " (" .. name2 .. ")"
			else
				name = name2
			end

			entries[k] = name
		end

		return entries
	end
})
