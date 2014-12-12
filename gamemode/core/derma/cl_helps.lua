if (CLIENT) then
	local HELP_DEFAULT = [[
		<center>
			<h1>]]..L"helpDefault"..[[
		</center>
	]]

	hook.Add("CreateMenuButtons", "nutHelpMenu", function(tabs)		
		tabs["help"] = function(panel)
			local html
			local header = [[<html>
			<head>
				<style>
					body {
						color: #FAFAFA;
						font-family: Calibri, sans-serif;
					}

					h2 {
						margin: 0;
					}
				</style>
			</head>
			<body>
			]]

			local tree = panel:Add("DTree")
			tree:SetPadding(5)
			tree:Dock(LEFT)
			tree:SetWide(180)
			tree.OnNodeSelected = function(this, node)
				html:SetHTML(header..node:onGetHTML().."</body></html>")
			end

			html = panel:Add("DHTML")
			html:Dock(FILL)
			html:SetHTML(header.."<h1>"..L"helpDefault".."</h1>")

			local tabs = {}
			hook.Run("BuildHelpMenu", tabs)

			for k, v in SortedPairs(tabs) do
				tree:AddNode(k).onGetHTML = v or function() return "" end
			end
		end
	end)
end

hook.Add("BuildHelpMenu", "nutBasicHelp", function(tabs)
	tabs[L"commands"] = function(node)
		local body = ""

		for k, v in SortedPairs(nut.command.list) do
			local allowed = false

			if (v.adminOnly and !LocalPlayer():IsAdmin()or v.superAdminOnly and !LocalPlayer():IsSuperAdmin()) then
				continue
			end

			if (v.group) then
				if (type(v.group) == "table") then
					for k, v in pairs(v.group) do
						if (LocalPlayer():IsUserGroup(v)) then
							allowed = true

							break
						end
					end
				elseif (LocalPlayer():IsUserGroup(v.group)) then
					return true
				end
			else
				allowed = true
			end

			if (allowed) then
				body = body.."<h2>/"..k.."</h2><strong>Syntax:</strong> <em>"..v.syntax.."</em><br /><br />"
			end
		end

		return body
	end

	tabs[L"plugins"] = function(node)
		local body = ""

		for k, v in SortedPairsByMemberValue(nut.plugin.list, "name") do
			body = (body..[[
				<p>
					<span style="font-size: 22;"><b>%s</b><br /></span>
					<span style="font-size: smaller;">
					<b>%s</b>: %s<br />
					<b>%s</b>: %s
			]]):format(v.name or "Unknown", L"desc", v.desc, L"author", v.author)

			if (v.version) then
				body = body.."<br /><b>"..L"version".."</b>: "..v.version
			end

			body = body.."</span></p>"
		end

		return body
	end
end)