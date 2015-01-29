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

PLUGIN.name = "Save Items"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Saves items that were dropped."

function PLUGIN:ShouldCleanDataItems()
	-- We will handle the cleansing of items ourselves.
	return false
end

function PLUGIN:LoadData()
	local items = self:getData()

	if (items) then
		local idRange = {}
		local positions = {}

		for k, v in ipairs(items) do
			idRange[#idRange + 1] = v[1]
			positions[v[1]] = v[2]
		end

		if (#idRange > 0) then
			local range = "("..table.concat(idRange, ", ")..")"

			nut.db.query("SELECT _itemID, _uniqueID, _data FROM nut_items WHERE _itemID IN "..range, function(data)
				if (data) then
					for k, v in ipairs(data) do
						local itemID = tonumber(v._itemID)
						local data = util.JSONToTable(v._data or "[]")
						local uniqueID = v._uniqueID
						local itemTable = nut.item.list[uniqueID]
						local position = positions[itemID]

						if (itemTable and itemID) then
							local position = positions[itemID]
							local item = nut.item.new(uniqueID, itemID)
							item.data = data or {}
							item:spawn(position).nutItemID = itemID
							item.invID = 0
						end
					end
				end
			end)
		end
	end
end

function PLUGIN:SaveData()
	local items = {}

	for k, v in ipairs(ents.FindByClass("nut_item")) do
		if (v.nutItemID) then
			items[#items + 1] = {v.nutItemID, v:GetPos()}
		end
	end

	self:setData(items)
end