BASE.name = "Base Food"
BASE.uniqueID = "base_food"
BASE.weight = .5
BASE.category = "Consumeable - Food"
BASE.eatsound = "physics/flesh/flesh_bloody_break.wav"
BASE.eatsoundlevel = 75
BASE.eatpitch = 200
BASE.cooktime = 5
BASE.hunger = 5
BASE.hungermultp = 1
BASE.thirst = 0
BASE.thirstmultip = 0
BASE.cookable = true
-- You can use hunger table? i guess? 
BASE.functions = {}
BASE.functions.Eat = {
	text = "Consume",
	tip = "Eat the food.",
	icon = "icon16/cup.png",
	run = function(itemTable, client, data, entity)
		if (SERVER) then
			
			--** Solve Thirst and Hunger.
			local cooklevel = data.cooklevel or 0
			client:EmitSound( itemTable.eatsound, itemTable.eatsoundlevel, itemTable.eatpitch )
			if itemTable.cookable then
				client:SolveHunger( math.Clamp(  itemTable.hunger + itemTable.hungermultp * ( cooklevel - 4 ), 0, HUNGER_MAX ) )
				client:SolveThirst(  math.Clamp( itemTable.thirst + itemTable.thirstmultip * ( cooklevel - 4 ), 0, THIRST_MAX ) )			
			else
				client:SolveHunger( math.Clamp(  itemTable.hunger , 0, HUNGER_MAX ) )
				client:SolveThirst(  math.Clamp( itemTable.thirst , 0, THIRST_MAX ) )			
			end
			
			--** Make Entity/Item consumed.
			if entity && entity:IsValid() then
				--** If you ate Entity
				entity:GetData().usenum = entity:GetData().usenum or 1
				entity:GetData().usenum = entity:GetData().usenum - 1

				netstream.Start(nil, "nut_UpdateData", {entity, entity:GetData().usenum})

				if entity:GetData().usenum <= 0 then
					entity:Remove()
					return true
				end
			else
				--** If you ate Item ( In Inventory. )
				local ndat = table.Copy( data )
				ndat.usenum = ndat.usenum or 1
				ndat.usenum = ndat.usenum - 1 
				client:UpdateInv( itemTable.uniqueID, -1, data ) 
				if ndat.usenum > 0 then
					client:UpdateInv( itemTable.uniqueID, 1, ndat )
				end
				
			end
			
		end
		
		return false
	end
}

BASE.functions.Cook = {
	text = "Cook",
	icon = "icon16/bomb.png",
	menuOnly = true,
	run = function(itemTable, client, data, entity, index)
		if (CLIENT) then
		
			local dat = {}
			dat.start = client:GetShootPos()
			dat.endpos = dat.start + client:GetAimVector() * 96
			dat.filter = client
			local trace = util.TraceLine(dat)
			local entity = trace.Entity
			local cooklevel = data.cooklevel or 0
			
			--** If it's not cookable ( Just making sure! )
			if !itemTable.cookable then nut.util.Notify( Format( cookmod["notice_notcookable"], itemTable.name ), client ) return false end
			
			--** Conditions
			if ( cooklevel == 0 ) then
				if (IsValid(entity) and entity:GetClass() == "nut_stove") then
					if entity:GetNetVar( "active" ) then
						nut.util.Notify( Format( cookmod["notice_cooked"], itemTable.name ) , client)
						netstream.Start("nut_CookItem", {index, itemTable.uniqueID})
					else
						nut.util.Notify( Format( cookmod["notice_turnonstove"], itemTable.name ) , client)
					end
				else
					nut.util.Notify( Format( cookmod["notice_havetofacestove"], itemTable.name ) , client)
				end
			else
				nut.util.Notify(  Format( cookmod["notice_alreadycooked"], itemTable.name ) , client)
			end
			
		end
		return false
	end,
	shouldDisplay = function(itemTable, data, entity)
		return itemTable.cookable
	end
}

if SERVER then
	local cookTable = {
		[0] = nut.lang.Get("food_uncook"),
		[1] = nut.lang.Get("food_worst"),
		[2] = nut.lang.Get("food_reallybad"),
		[3] = nut.lang.Get("food_bad"),
		[4] = nut.lang.Get("food_notgood"),
		[5] = nut.lang.Get("food_normal"),
		[6] = nut.lang.Get("food_good"),
		[7] = nut.lang.Get("food_sogood"),
		[8] = nut.lang.Get("food_reallygood"),
		[9] = nut.lang.Get("food_best"),
	}
	
	netstream.Hook("nut_CookItem", function(client, data)
		local index = data[1]
		local uid = data[2]
		local item = client:GetItem(uid, index)

		if (item) then
			local data = table.Copy(item.data or {})
			
			--** defines it's cooked level
			--** currently Random.
			local wow = math.random( 1, #cookTable )
			data.Cooked = cookTable[wow] --* set description about how it's cooked.
			data.cooklevel = wow --** It's cooked level. ( 5 is normal. )
			
			client:EmitSound( "player/pl_burnpain" .. math.random( 1.3 ) ..".wav", 75, 140 )
			client:UpdateInv(uid, -1, item.data)
			client:UpdateInv(uid, 1, data)
		end
	end)
else
	netstream.Hook("nut_UpdateData", function(client, data) --** For updating dropped Entity's usenum.
		local ent = data[1]
		local var = data[2]
		
		if (IsValid(ent)) then
			ent:GetData().usenum = var
		end
	end)
end
