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

PLUGIN.name = "Doors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "A simple door system."

nut.util.include("sv_plugin.lua")
nut.util.include("cl_plugin.lua")
nut.util.include("sh_commands.lua")

DOOR_OWNER = 3
DOOR_TENANT = 2
DOOR_GUEST = 1
DOOR_NONE = 0

-- Configurations for door prices.
nut.config.add("doorCost", 10, "The price to purchase a door.", nil, {
	data = {min = 0, max = 500},
	category = "dConfigName"
})
nut.config.add("doorSellRatio", 0.5, "How much of the door price is returned when selling a door.", nil, {
	form = "Float",
	data = {min = 0, max = 1.0},
	category = "dConfigName"
})