if (CLIENT) then
	local HELP_DEFAULT

	hook.Add("CreateMenuButtons", "ixHelpMenu", function(tabs)
		HELP_DEFAULT = [[
			<div id="parent"><div id="child">
				<center>
				    <img src="http://img2.wikia.nocookie.net/__cb20140827051941/nutscript/images/c/c9/Logo.png"></img>
					<br><font size=15>]] .. L"helpDefault" .. [[</font>
				</center>
			</div></div>
		]]

		tabs["help"] = function(panel)
			local html
			local header = [[<html>
			<head>
				<style>
					@import url(http://fonts.googleapis.com/earlyaccess/jejugothic.css);

					#parent {
					    padding: 5% 0;
					}

					#child {
					    padding: 10% 0;
					}

					body {
						color: #FAFAFA;
						font-family: 'Jeju Gothic', serif;
						-webkit-font-smoothing: antialiased;
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
			tree:DockMargin(0, 0, 15, 0)
			tree.OnNodeSelected = function(this, node)
				if (node.OnGetHTML) then
					local source = node:OnGetHTML()

					if (source:sub(1, 4) == "http") then
						html:OpenURL(source)
					else
						html:SetHTML(header..node:OnGetHTML().."</body></html>")
					end
				end
			end

			html = panel:Add("DHTML")
			html:Dock(FILL)
			html:SetHTML(header..HELP_DEFAULT)

			local helpTabs = {}
			hook.Run("BuildHelpMenu", helpTabs)

			for k, v in SortedPairs(helpTabs) do
				if (type(v) != "function") then
					local source = v

					v = function() return tostring(source) end
				end

				tree:AddNode(L(k)).OnGetHTML = v or function() return "" end
			end
		end
	end)
end

hook.Add("BuildHelpMenu", "ixBasicHelp", function(tabs)
	tabs["commands"] = function(node)
		local body = ""

		for commandName, command in SortedPairs(ix.command.list) do
			local allowed = false

			if (command.adminOnly and !LocalPlayer():IsAdmin() or command.superAdminOnly and !LocalPlayer():IsSuperAdmin()) then
				continue
			end

			if (command.group) then
				if (type(command.group) == "table") then
					for _, group in pairs(command.group) do
						if (LocalPlayer():IsUserGroup(group)) then
							allowed = true

							break
						end
					end
				elseif (LocalPlayer():IsUserGroup(command.group)) then
					return true
				end
			else
				allowed = true
			end

			if (allowed) then
				body = body.."<h2>/"..commandName.."</h2><strong>Syntax:</strong> <em>"..command.syntax.."</em><br /><br />"
			end
		end

		return body
	end

	tabs["plugins"] = function(node)
		local body = ""

		for _, v in SortedPairsByMemberValue(ix.plugin.list, "name") do
			body = (body..[[
				<p>
					<span style="font-size: 22;"><b>%s</b><br /></span>
					<span style="font-size: smaller;">
					<b>%s</b>: %s<br />
					<b>%s</b>: %s
			]]):format(v.name or "Unknown", L"description", v.description or L"noDesc", L"author", v.author)

			if (v.version) then
				body = body.."<br /><b>"..L"version".."</b>: "..v.version
			end

			body = body.."</span></p>"
		end

		return body
	end

	tabs["flags"] = function(node)
		local body = [[<table border="0" cellspacing="8px">]]

		for k, v in SortedPairs(ix.flag.list) do
			local icon

			if (LocalPlayer():GetChar():HasFlags(k)) then
				icon = [[<img src="asset://garrysmod/materials/icon16/tick.png" />]]
			else
				icon = [[<img src="asset://garrysmod/materials/icon16/cross.png" />]]
			end

			body = body..Format([[
				<tr>
					<td>%s</td>
					<td><b>%s</b></td>
					<td>%s</td>
				</tr>
			]], icon, k, v.description)
		end

		return body.."</table>"
	end
end)
