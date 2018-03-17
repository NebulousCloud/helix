
local nameFormat = "<span class=\"realm %s\" title=\"%s\"></span> %s"

file = "./"
dir = "docs/html"
project = "Helix"
title = "Helix Documentation"

no_space_before_args = true
style = "docs/css"
template = "docs/templates"
format = "markdown"
ignore = true
kind_names = {module = "Libraries"}

custom_tags = {
	{"shared", hidden = true},
	{"client", hidden = true},
	{"server", hidden = true}
}

custom_display_name_handler = function(item, default_handler)
	if (item.type == "function" or item.type == "field" and (item.tags.shared or item.tags.client or item.tags.server)) then
		if (item.tags.shared) then
			item.realm = "shared"
		elseif (item.tags.client) then
			item.realm = "client"
		elseif (item.tags.server) then
			item.realm = "server"
		end

		local name = item.type == "field" and item.module.name .. "." .. default_handler(item) or default_handler(item)
		return nameFormat:format(item.realm, item.realm:sub(1, 1):upper() .. item.realm:sub(2), name)
	end

	return default_handler(item)
end

new_type("player", "Players", true)

tparam_alias("string", "string")
tparam_alias("table", "table")
tparam_alias("bool", "boolean")
tparam_alias("func", "function")
tparam_alias("player", "player")
tparam_alias("entity", "entity")

tparam_alias("ixtype", "ix.type")
tparam_alias("inventory", "inventory")
