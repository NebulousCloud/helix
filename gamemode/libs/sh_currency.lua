--[[
	Purpose: A library which provides the ability to register multiple forms of
	currency and defines some functions for the player metatable to give/take/get
	a type of currency.
--]]

nut.currency = nut.currency or {}

-- Setup our player metatable functions.
do
	local playerMeta = FindMetaTable("Player")

	--[[
		Purpose: Retrieves the current amount of a specific currency of the active character
		or return 0.
	--]]
	function playerMeta:GetMoney()
		if (!self.character) then
			error("Attempt to get money in invalid character!")
		end

		return self.character:GetVar("money") or 0
	end

	--[[
		Purpose: Checks if the player has a specific amount of currency.
	--]]
	function playerMeta:HasMoney(amount)
		return self:GetMoney() >= amount
	end

	--[[
		Purpose: Returns true/false depending on whether the player will have any money
		if they were to have a certain amount taken away.
	--]]
	function playerMeta:CanAfford(amount)
		return (self:GetMoney() - amount) >= 0
	end

	-- Serverside since the networking happens here too.
	if (SERVER) then
		-- Sets the character's amount of currency to a specific value.
		function playerMeta:SetMoney(amount)
			if (!self.character) then
				error("Attempt to set money on invalid character!")
			end

			amount = math.Round(amount, 2)

			self.character:SetVar("money", amount)
		end

		-- Quick function to set the money to the current amount plus an amount specified.
		function playerMeta:GiveMoney(amount)
			self:SetMoney(self:GetMoney() + amount)
		end

		-- Takes away a certain amount by inverting the amount specified.
		function playerMeta:TakeMoney(amount)
			self:GiveMoney(-amount)
		end
	end
end

--[[
	Purpose: Determines whether or not at least one currency has been registered.
--]]
function nut.currency.IsSet()
	return nut.currency.data != nil
end

--[[
	Purpose: Registers a new type of currency and adds it to the list of currencies available.
--]]
function nut.currency.SetUp(singular, plural, symbol)
	singular = string.sub(string.upper(singular), 1, 1)..string.sub(string.lower(singular), 2)
	plural = string.sub(string.upper(plural), 1, 1)..string.sub(string.lower(plural), 2)

	nut.currency.data = {singular = singular, plural = plural, symbol = symbol}
end

--[[
	Purpose: Gets the appropriate text to use for getting the name of a currency.
	If the amount is different than one, it will use the plural form of the currency's
	name. If the currency has a symbol, it wil place the symbol infront of the amount.
	
	nut.currency.SetUp("dollar", "dollars", "$")
	print(nut.currency.GetName(1337))

	Would return:
		> $1337 dollars

	Useful for saying someone spent a certain amount or gained.
--]]
function nut.currency.GetName(amount, upper)
	local currency = nut.currency.data

	if (currency) then
		local name = currency.symbol or ""
		name = name..amount

		if (currency.singular and amount == 1) then
			name = name.." "..currency.singular
		else
			name = name.." "..currency.plural
		end

		name = !upper and string.lower(name) or name

		return name
	end
end

if (SERVER) then
	function nut.currency.Spawn(amount, position, angles, client)
		if (amount <= 0) then
			return
		end

		local entity = ents.Create("nut_money")
		entity:SetPos(position or vector_origin)
		entity:SetAngles(angles or Angle(0, 0, 0))
		entity:Spawn()
		entity:Activate()
		entity:SetMoney(amount)

		if (client and client:IsValid()) then
			entity.owner = client

			if client.character then
				entity.charindex = client.character.index
			end
		end

		return entity
	end
end