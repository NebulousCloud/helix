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
		ply:StripAmmo()
		local entity = ents.Create("nut_container")
		entity:SetPos( ply:GetPos() + Vector( 0, 0, 10 ) )
		entity:Spawn()
		entity:Activate()
		entity:SetNetVar("inv", {})
		entity:SetNetVar("name", "Belongings" )
		entity:SetNetVar( "max", 20 )
		entity:SetModel( self.config.bagmodel )
		entity:PhysicsInit(SOLID_VPHYSICS)
		entity.generated = true
		local physicsObject = entity:GetPhysicsObject()
		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
				
		for k,v in pairs( ply:GetInventory() ) do
			if !nut.item.Get( k ) then continue end
			local dice = math.random( 0, 100 )
			local chance = math.Clamp( self.config.losechance, 0, 100 )
			if self.config.fixchance[ k ] then
				local t = type( self.config.fixchance[ k ] )
				if self.config.fixchance[ k ][ fct ] then
					chance = math.Clamp( self.config.fixchance[ k ][ fct ], 0, 100 )
				end
			end
							
			if dice <= chance then
				local dat = {}
				if v[1] and v[1].data then
					dat = v[1].data
				end
				local q =  1
				if v.quantity then
					q = math.random( 1, v[1].quantity )
				end
				if !dat.Equipped then
					ply:UpdateInv( k, -q, dat ) 
					entity:UpdateInv( k, q, dat )
				end				
			end
		end
		
		timer.Simple( self.config.staytime, function()
			if entity:IsValid() then
				entity:Remove()
			end
		end)
	end
	
end
