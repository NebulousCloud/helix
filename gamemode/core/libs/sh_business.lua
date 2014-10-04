if (SERVER) then
	netstream.Hook("businessBuy", function(client, id)
		local char = client:getChar()
		local inv = char:getInv()

		if (!char or !inv) then
			return false
		end

		local price = hook.Run("CanPlayerUseBusiness", char, id)

		if (price == false) then
			return false
		end

		price = (price or 0)

		local x, y = inv:add(id, 1, data)
		local item = inv:getItemAt(x, y)
		if (!item or item == false) then
			return
		end

		char:takeMoney(price)
		client:notify(L("businessPurchase", client, item.name, price > 0 and nut.currency.get(price) or "FREE"))

		hook.Run("OnPlayerUseBusiness", char, item)
	end)
end