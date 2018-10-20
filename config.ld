
file = {
	"gamemode",
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

new_type("player", "Players", true)

tparam_alias("string", "string")
tparam_alias("bool", "boolean")
tparam_alias("func", "function")
tparam_alias("player", "player")
tparam_alias("entity", "entity")
tparam_alias("color", "color")
tparam_alias("tab", "table")

tparam_alias("ixtype", "ix.type")
tparam_alias("inventory", "inventory")
tparam_alias("date", "date")
