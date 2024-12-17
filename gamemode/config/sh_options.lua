
if (CLIENT) then
	ix.option.Add("animationScale", ix.type.number, 1, {
		category = "appearance", min = 0.3, max = 2, decimals = 1
	})

	ix.option.Add("24hourTime", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("altLower", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("alwaysShowBars", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("minimalTooltips", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("noticeDuration", ix.type.number, 8, {
		category = "appearance", min = 0.1, max = 20, decimals = 1
	})

	ix.option.Add("noticeMax", ix.type.number, 4, {
		category = "appearance", min = 1, max = 20
	})

	ix.option.Add("cheapBlur", ix.type.bool, false, {
		category = "performance"
	})

	ix.option.Add("disableAnimations", ix.type.bool, false, {
		category = "performance"
	})

	ix.option.Add("openBags", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("showIntro", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("escCloseMenu", ix.type.bool, false, {
		category = "general"
	})
end

ix.option.Add("language", ix.type.array, ix.config.language or "english", {
	category = "general",
	bNetworked = true,
	populate = function()
		local entries = {}

		for k, _ in SortedPairs(ix.lang.stored) do
			local name = ix.lang.names[k]
			local name2 = k:utf8sub(1, 1):utf8upper() .. k:utf8sub(2)

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
