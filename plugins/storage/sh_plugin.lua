local PLUGIN = PLUGIN
PLUGIN.name = "Storage"
PLUGIN.author = "Chessnut and rebel1324"
-- Black Tea added few lines.
PLUGIN.desc = "Adds storage items that can store items."

nut.lang.Add("lock_success", "Successfully Locked the Container.")
nut.lang.Add("lock_locked", "The contianer is already locked.")
nut.lang.Add("lock_wrong", "You've entered wrong password.")
nut.lang.Add("lock_try", "The container is locked.")
nut.lang.Add("lock_locked", "The container is locked.")
nut.lang.Add("lock_itsworld", "World Container is cannot be locked.")

nut.util.Include("cl_storage.lua")

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_container")) do
			if (v.itemID) then
				local inventory = v:GetNetVar("inv")
				data[#data + 1] = {
					position = v:GetPos(),
					angles = v:GetAngles(),
					inv = inventory,
					world = v.world,
					lock = v.lock,
					classic = v.classic,
					uniqueID = v.itemID,
					type = v.type
				}
			end
		end

		nut.util.WriteTable("storage", data)
	end

	function PLUGIN:LoadData()
		local storage = nut.util.ReadTable("storage")

		if (storage) then
			for k, v in pairs(storage) do
				local inventory = v.inv
				local position = v.position
				local angles = v.angles
				local itemTable = nut.item.Get(v.uniqueID)
				
				local amt = 0
				for _, __ in pairs( inventory ) do
					amt = amt + 1
				end
				
				if ( amt == 0 && !v.world && !v.lock ) then continue end
				if (itemTable) then
					local entity = ents.Create("nut_container")
					entity:SetPos(position)
					entity:SetAngles(angles)
					entity:Spawn()
					entity:Activate()
					entity:SetNetVar("inv", inventory)
					entity:SetNetVar("name", itemTable.name)
					entity.itemID = v.uniqueID
					entity.lock = v.lock
					entity.classic = v.classic
					if entity.lock then
						entity:SetNetVar( "locked", true )
					end
					entity.world = v.world
					entity.type = v.type

					if (itemTable.maxWeight) then
						entity:SetNetVar("max", itemTable.maxWeight)
					end

					entity:SetModel(itemTable.model)
					entity:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end
	end
else
	
	local locks = {
		"classic_locker_1",
		"digital_locker_1",
	}
	
	local function lck1( entity )
		if !LocalPlayer():HasItem( "classic_locker_1" ) then nut.util.Notify("Lack of required item." , client) return false end
		netstream.Start("nut_RequestLock", {entity, true, ""})
	end
	
	local function lck2( entity )
		if !LocalPlayer():HasItem( "digital_locker_1" ) then nut.util.Notify("Lack of required item." , client) return false end
		Derma_StringRequest( "Password Lock", "Enter the password for the container", "", function( pas ) 
			netstream.Start("nut_RequestLock", {entity, false, pas})
		end)
	end
	
	local storfuncs = {
		aopen = {
			icon = "icon16/star.png",
			name = "Admin Open",
			tip = "Open the container.",
			cond = function( entity )
				return LocalPlayer():IsAdmin()
			end,
			func = function( entity )
				netstream.Start("nut_Storage", entity)
			end,
		},
		open = {
			name = "Open",
			tip = "Open the container.",
			cond = function( entity )
				return true
			end,
			func = function( entity )
				netstream.Start("nut_RequestStorageMenu", entity)
			end,
		},
		pick = {
			name = "Force Unlock",
			cond = function( entity )
				return false
			end,
			func = function( entity )
			end,
		},
		lock = {
			icon = "icon16/key.png",
			name = "Lock",
			cond = function( entity )
				for _, item in pairs( locks ) do
					if LocalPlayer():HasItem( item ) then
						return !entity:GetNetVar( "locked" )
					end
				end
				return false
			end,
			func = function( entity )
				Derma_Query( "Which lock you want to use?", "Confirmation", "Normal Padlock", function() lck1( entity ) end, "Digital Lock", function() lck2( entity ) end, "Cancel", function() end )
			end,
		},
	}
	
	function PLUGIN:ShowStorageMenu( entity )
		if (!IsValid(entity) or !IsValid(LocalPlayer():GetEyeTrace().Entity) or LocalPlayer():GetEyeTrace().Entity != entity) then
			return
		end

		local menu = DermaMenu()
			for k, v in SortedPairs( storfuncs ) do
				
				if v.cond and !v.cond( entity ) then continue end
				
				local material = v.icon or "icon16/briefcase.png"

				local option = menu:AddOption(v.name or k, function()
					if (v.func) then
						if v.func then
							v.func( entity )
						end
					end
				end)
				option:SetImage(material)

				if (v.tip) then
					option:SetToolTip(v.tip)
				end
				
			end
			
		menu:Open()
		menu:Center()
	end

	netstream.Hook("nut_ShowStorageMenu", function(entity)
		PLUGIN:ShowStorageMenu(entity)
	end)
		
	netstream.Hook("nut_RequestPassword", function(entity)
		Derma_StringRequest( "Password Lock", "Enter the password for the container", "", function( pas ) 
			netstream.Start("nut_VerifyPassword", {entity, pas})
		end)
	end)
		
end


nut.command.Register({
	adminOnly = true,
	syntax = "[bool isWorldContainer]",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				if arguments[1] then
					if arguments[1] == "true" || arguments[1] == "false" then
						if arguments[1] == "true" then
							entity.world = true
						else
							entity.world = false
						end
					else
						nut.util.Notify("Must enter valid argument. ( true | false )", client)	
						return
					end
				else
					entity.world = !entity.world
				end
				nut.util.Notify("Container's status updated: isworldcontainer = " .. tostring( entity.world ) , client)			
			else
				nut.util.Notify("You have to face a container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "setworldcontainer")


nut.command.Register({
	adminOnly = true,
	syntax = "[string Password]",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				if arguments[1] then
					entity.classic = false
					entity.lock = arguments[1]
					entity:SetNetVar( "locked", true )
					nut.util.Notify("Lock Set: ".. entity.lock, client)		
				else
					entity.classic = nil
					entity.lock = nil
					entity:SetNetVar( "locked", false )
					nut.util.Notify("Unlocked the Container.", client)		
				end
			else
				nut.util.Notify("You have to face a container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "setcontainerlock")


nut.command.Register({
	adminOnly = true,
	syntax = "",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				nut.util.Notify("Is this World Container? = " .. tostring( entity.world ) , client)			
			else
				nut.util.Notify("You have to face a container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "isworldcontainer")