nut.setting = nut.setting or {}

if (CLIENT) then -- CLIENTSIDE TEST.

	nut.setting.vars = {}

	function nut.setting.Register(data)
		if (!data) then
			
			return
		end

		table.insert(nut.setting.vars, data)
	end

	nut.setting.Register({
		name = "Toggle Vignette",
		var = "drawVignette",
		type = "checker",
		category = "Framework Settings"
	})
	
	nut.setting.Register({
		name = "Toggle Crosshair",
		var = "crosshair",
		type = "checker",
		category = "Framework Settings"
	})
	
	nut.setting.Register({
		name = "Crosshair Size",
		var = "crossSize",
		type = "slider",
		min = 0,
		max = 5,
		category = "Framework Settings"
	})
	
	nut.setting.Register({
		name = "Crosshair Spacing",
		var = "crossSpacing",
		type = "slider",
		min = 0,
		max = 20,
		category = "Framework Settings"
	})

	nut.setting.Register({
		name = "Crosshair Alpha",
		var = "crossAlpha",
		type = "slider",
		min = 0,
		max = 255,
		category = "Framework Settings"
	})	

	hook.Add("SchemaInitialized", "ClientSettingLoad", function()
		local contents 
		local decoded

		if (file.Exists("nutscript/settings.txt", "DATA")) then
			contents = file.Read("nutscript/settings.txt", "DATA")
		end

		if contents then
			decoded = von.deserialize(contents)
		end

		local customSettings = {}
		if decoded then
			customSettings = decoded
		end

		for k, v in pairs(customSettings) do
			nut.config[k] = v
		end
	end)

	hook.Add("ShutDown", "ClientSettingLoad", function()
		local customSettings = {}
		for k, v in pairs(nut.setting.vars) do
			customSettings[v.var] = nut.config[v.var]
		end

		local encoded = von.serialize(customSettings)
		file.CreateDir("nutscript/")
		file.Write("nutscript/settings.txt", encoded)
	end)

	function GM:AddSettingOptions(panel)
		for k, v in pairs(nut.setting.vars) do
			if (!panel.category[v.category]) then
				local category = panel:AddCategory( v.category )

				panel.category[v.category] = category
			end

			local category = panel.category[v.category]

			if (category) then
				if (v.type == "checker") then
					panel:AddChecker(category, v.name, v.var)
				elseif (v.type == "slider") then
					panel:AddSlider(category, v.name, v.min, v.max, v.var, v.demical or 0)
				end
			end
		end
	end

end