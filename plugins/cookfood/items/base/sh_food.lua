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
	alias = "Eat",
	tip = "Eat the food.",
	icon = "icon16/cup.png",
	run = function(itemTable, client, data, entity)
		if (SERVER) then
			
			local cooklevel = data.cooklevel or 0
			client:EmitSound( itemTable.eatsound, itemTable.eatsoundlevel, itemTable.eatpitch )
			if itemTable.cookable then
				client:SolveHunger( math.Clamp(  itemTable.hunger + itemTable.hungermultp * ( cooklevel - 4 ), 0, HUNGER_MAX ) )
				client:SolveThirst(  math.Clamp( itemTable.thirst + itemTable.thirstmultip * ( cooklevel - 4 ), 0, THIRST_MAX ) )			
			else
				client:SolveHunger( math.Clamp(  itemTable.hunger , 0, HUNGER_MAX ) )
				client:SolveThirst(  math.Clamp( itemTable.thirst , 0, THIRST_MAX ) )			
			end
			
			if entity && entity:IsValid() then
				entity:GetData().usenum = entity:GetData().usenum or 1
				entity:GetData().usenum = entity:GetData().usenum - 1
				net.Start( "nut_UpdateData" )
					net.WriteEntity( entity )
					net.WriteFloat( entity:GetData().usenum )
				net.Broadcast()
				if entity:GetData().usenum <= 0 then
					entity:Remove()
					return true
				end
			else
				data.usenum = data.usenum or 1
				data.usenum = data.usenum - 1 
				if data.usenum <= 0 then
					return true
				end
			end
			
		end
		return false
	end
}

BASE.functions.Cook = {
	alias = "Cook",
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
			
			if !itemTable.cookable then nut.util.Notify( Format( cookmod["notice_notcookable"], itemTable.name ), client ) return false end
			
			if ( cooklevel == 0 ) then
				if (IsValid(entity) and entity:GetClass() == "nut_stove") then
					if entity:GetNetVar( "active" ) then
						nut.util.Notify( Format( cookmod["notice_cooked"], itemTable.name ) , client)
							
						net.Start("nut_CookItem")
							net.WriteUInt(index, 8)
							net.WriteString( itemTable.uniqueID )
						net.SendToServer()
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
	end
}

if SERVER then

	util.AddNetworkString("nut_CookItem")

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
	
	net.Receive("nut_CookItem", function(length, client)
		local index = net.ReadUInt(8)
		local uid = net.ReadString()
		local item = client:GetItem(uid, index)

		if (item) then
			local data = table.Copy(item.data or {})
			local wow = math.random( 1, #cookTable )
			data.Cooked = cookTable[wow]
			data.cooklevel = wow -- legit
			
			client:EmitSound( "player/pl_burnpain" .. math.random( 1.3 ) ..".wav", 75, 140 )
			client:UpdateInv(uid, -1, item.data)
			client:UpdateInv(uid, 1, data)
		end
	end)
	
	util.AddNetworkString("nut_UpdateData")
else

	net.Receive("nut_UpdateData", function(length, client)
	
		local ent = net.ReadEntity()
		local var = net.ReadFloat()
		
		if ( ent && ent:IsValid() ) then
			ent:GetData().usenum = var
		end
		
	end)

end