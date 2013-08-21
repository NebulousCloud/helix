local RECIPE = {}
RECIPE.uid = "motolov"
RECIPE.name = "Motolov Cocktail"
RECIPE.category = "Consumable Weapons"
RECIPE.model = Model( "models/props_junk/GlassBottle01a.mdl" )
RECIPE.desc = "A Bottle of motolov cocktail. It has use to be thrown."
RECIPE.items = {
	["fuel"] = 1,
	["emptybottle"] = 1,
}
RECIPE.result = {
	["motolov"] = 1,
}
RECIPES:Register( RECIPE )

local RECIPE = {}
RECIPE.uid = "gascan"
RECIPE.name = "Fuel Can"
RECIPE.category = nut.lang.Get( "icat_material" )
RECIPE.model = Model( "models/props_junk/gascan001a.mdl" )
RECIPE.desc = "A Gas Can."
RECIPE.items = {
	["bgas"] = 3,
	["egcan"] = 1,
}
RECIPE.result = {
	["fuel"] = 1,
}
RECIPES:Register( RECIPE )