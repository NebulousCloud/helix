-- Localize the plugin table so commands can use it.
local PLUGIN = PLUGIN

local COMMAND = {}

function COMMAND:OnRun(client, arguments)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 84
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and PLUGIN:IsDoor(entity)) then
		if (entity:GetNetVar("unownable")) then
			nut.util.Notify("This door can not be owned.", client)

			return
		end

		local cost = nut.config.doorCost

		if (!client:CanAfford(cost)) then
			nut.util.Notify(nut.lang.Get("no_afford"), client)

			return
		end

		if (!PLUGIN:IsDoorOwned(entity)) then
			entity:SetNetVar("owner", client)
			entity:SetNetVar("title", "Purchased Door")

			nut.util.Notify("You have purchased this door for "..nut.currency.GetName(cost)..".", client)
			client:TakeMoney(cost)
		else
			nut.util.Notify("This door has already been purchased.", client)
		end
	else
		nut.util.Notify("You are not looking at a valid door.", client)
	end
end

nut.command.Register(COMMAND, "doorbuy")

local COMMAND = {}

function COMMAND:OnRun(client, arguments)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 84
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and PLUGIN:IsDoor(entity)) then
		if (PLUGIN:GetOwner(entity) == client) then
			entity:SetNetVar("owner", NULL)
			entity:SetNetVar("title", "Door for Sale")

			local amount = nut.config.doorSellAmount

			nut.util.Notify("You have sold this door for "..nut.currency.GetName(amount)..".", client)
			client:GiveMoney(amount)
		end
	else
		nut.util.Notify("You are not looking at a valid door.", client)
	end
end

nut.command.Register(COMMAND, "doorsell")

local COMMAND = {}

function COMMAND:OnRun(client, arguments)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 84
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity
	local title = "Purchased Door"

	if (#arguments > 0) then
		title = table.concat(arguments, " ")
	end
	
	if (IsValid(entity) and PLUGIN:IsDoor(entity)) then
		if (PLUGIN:GetOwner(entity) == client) then
			entity:SetNetVar("title", title)

			nut.util.Notify("You have changed the door's title.", client)
		end
	else
		nut.util.Notify("You are not looking at a valid door.", client)
	end
end

nut.command.Register(COMMAND, "doortitle")

local COMMAND = {}
COMMAND.adminOnly = true

function COMMAND:OnRun(client, arguments)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 84
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and PLUGIN:IsDoor(entity)) then
		local title = "Unownable Door"

		if (#arguments > 0) then
			title = table.concat(arguments, " ")
		end

		entity:SetNetVar("title", title)
		PLUGIN:DoorSetUnownable(entity)
		nut.util.Notify("You have added an unownable door.", client)
	else
		nut.util.Notify("You are not looking at a valid door.", client)
	end
end

nut.command.Register(COMMAND, "doorsetunownable")

local COMMAND = {}
COMMAND.adminOnly = true

function COMMAND:OnRun(client, arguments)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 84
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and PLUGIN:IsDoor(entity)) then
		entity:SetNetVar("title", "Door for Sale")
		PLUGIN:DoorSetOwnable(entity)
		nut.util.Notify("You have made this door ownable.", client)
	else
		nut.util.Notify("You are not looking at a valid door.", client)
	end
end

nut.command.Register(COMMAND, "doorsetownable")