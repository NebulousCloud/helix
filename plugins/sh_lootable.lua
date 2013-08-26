PLUGIN.name = "Loot Plugin"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You leaves your own things when you dead."

PLUGIN.config = {}
PLUGIN.config.enable = false -- ENABLE IT IF YOU WANT TO USE
PLUGIN.config.losechance = 50
PLUGIN.config.staytime = 20
PLUGIN.config.bagmodel = "models/props_junk/garbage_bag001a.mdl"

PLUGIN.config.fixchance = {
	/*
	["comkey"] = 
	{
		[1] = 100, -- Citizen must drops combine key
		[2] = 0, -- Metrocop never drops combine key
	},
	*/
}


function PLUGIN:PlayerDeath( ply, dmg, att )
	if self.config.enable then
		local fct = ply:Team()
		
		ply:StripAmmo() --** This is Normal.
		
		local entity = ents.Create("nut_container") --** Create World Container that should not be saved in the server.
		entity:SetPos( ply:GetPos() + Vector( 0, 0, 10 ) )
		entity:Spawn()
		entity:Activate()
		entity:SetNetVar("inv", {})
		entity:SetNetVar("name", "Belongings" ) --** Yup.
		entity:SetNetVar( "max", 20 )
		entity:SetModel( self.config.bagmodel )
		entity:PhysicsInit(SOLID_VPHYSICS)
		entity.generated = true --** This is it. Container that has this flag won't be saved in the server. 
		local physicsObject = entity:GetPhysicsObject()
		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
				
		for k,v in pairs( ply:GetInventory() ) do
		
			--** Place items on the bag.
			local itemtable = nut.item.Get( k ) 
			if !itemtable then continue end
			
			--** Item drop chances
			local dice = math.random( 0, 100 )
			local chance = math.Clamp( self.config.losechance, 0, 100 )
			if self.config.fixchance[ k ] then
				local t = type( self.config.fixchance[ k ] )
				if self.config.fixchance[ k ][ fct ] then
					chance = math.Clamp( self.config.fixchance[ k ][ fct ], 0, 100 )
				end
			end
			
			--** Get item's data. Including all of indexes
			if dice <= chance then
			
				for index, itemdat in pairs( v ) do
					
					local q = 1
					local dat = itemdat.data or {}
					
					if itemdat.quantity then
						q = math.random( 1, itemdat.quantity ) --** randomize dropping quantity
					end
					if itemtable.CanTransfer and !itemtable:CanTransfer( ply, dat, dropped ) then --** Just adding some parameters for custom items.
						--** if It's can not be transfered by some reason, Just abort transaction to the bag.
						--** It won't work anyway.
						continue
					end
					--** Place the item.
					ply:UpdateInv( k, -q, dat ) 
					entity:UpdateInv( k, q, dat )
					
				end			
			end
			
		end
		
		timer.Simple( self.config.staytime, function() --** Removes the bag when It's lifetime is over.
			if entity:IsValid() then
				entity:Remove()
			end
		end)
		
	end
	
	
end
