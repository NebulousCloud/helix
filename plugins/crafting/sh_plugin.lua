PLUGIN.name = "Crafting"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Allows you craft some items."
PLUGIN.enabled = false
nut.util.Include("sh_lang.lua")
nut.util.Include("sh_menu.lua")
RECIPES = {}
RECIPES.recipes = {}
function RECIPES:Register( tbl )
	self.recipes[ tbl.uid ] = tbl
end
function RECIPES:Get( name )
	return self.recipes[ name ]
end
function RECIPES:GetAll()
	return self.recipes
end
nut.util.Include("sh_recipies.lua")

function RECIPES:GetItem( item )
	local tblRecipe = self:Get( item )
	return tblRecipe.items
end

function RECIPES:GetResult( item )
	local tblRecipe = self:Get( item )
	return tblRecipe.result
end

function RECIPES:CanCraft( player, item )
	for name, amt in pairs( self:GetItem( item ) ) do
		if !player:HasItem( name, amt ) then 
			return false
		end
	end
	return true
end

if CLIENT then return end


util.AddNetworkString("nut_CraftItem")

net.Receive("nut_CraftItem", function(length, client)
	local item = net.ReadString()
	if RECIPES:CanCraft( client, item ) then
		client:CraftItem( item )
	else
		local tblDat = RECIPES:Get( item )
		nut.util.Notify( nut.lang.Get("needmoremats", tblDat.name), client)
	end
end)

local Player = FindMetaTable("Player")
function Player:CraftItem( item )
	local tblDat = RECIPES:Get( item )
	if RECIPES:CanCraft( self, item ) then
		local tblItems = RECIPES:GetItem( item )
		local tblResult = RECIPES:GetResult( item )
		for n, q in pairs( tblItems ) do
			self:UpdateInv( n, -q )
		end
		for n, q in pairs( tblResult ) do
			self:UpdateInv( n, q )
		end
		nut.util.Notify( nut.lang.Get("donecrafting", tblDat.name), self)
	end
end