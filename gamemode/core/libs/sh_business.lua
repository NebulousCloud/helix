--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

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