
file = {
	"gamemode",
	"plugins",
	exclude = {"gamemode/core/libs/thirdparty"}
}

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
	{"realm", hidden = true},
	{"internal", hidden = true}
}

custom_display_name_handler = function(item, default_handler)
	if (item.type == "function" and item.module and item.module.type == "classmod") then
		return item.module.mod_name .. default_handler(item):gsub(".+:", ":")
	end

	return default_handler(item)
end

-- helix types
tparam_alias("char", "Character")
tparam_alias("inventory", "Inventory")
tparam_alias("item", "Item")
tparam_alias("ixtype", "ix.type")
tparam_alias("date", "date")

-- standard types
tparam_alias("string", "string")
tparam_alias("bool", "boolean")
tparam_alias("func", "function")
tparam_alias("player", "player")
tparam_alias("entity", "entity")
tparam_alias("color", "color")
tparam_alias("tab", "table")
tparam_alias("panel", "panel")
