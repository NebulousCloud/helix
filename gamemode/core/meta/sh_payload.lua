--[[--
Holds information sent by a client for creating a new character.

The character creation payload is used to hold data about the variables to set on the character once it's created. This will
usually include things like the name, model, and description by default. If you are implementing your own character menu and
want to create a payload to send to the server, you can do so with `ix.charmenu.CreatePayload`. This will populate
`Payload.vars` with an array of character var keys from `ix.char.vars` that will be sent to the server and validated.

Accessing the character var object that this payload has can be done with:
	print(ix.char.vars[payload.uniqueid])
Where `uniqueid` is replaced with the unique id of the character var in `ix.char.vars`.
]]
-- @classmod Payload

local PAYLOAD = {}
PAYLOAD.__index = PAYLOAD

--- An array of character vars that this payload contains data for. By default, this will contain the `name`, `description`,
-- `model`, and `attributes` character vars. This will also include the vars created by plugins and schemas if `bNoDisplay` has
-- not been set. This array will be in order of the `index` that was set for each var.
-- @realm shared
-- @table vars
-- @usage -- this prints the values for each character var
-- for k, v in ipairs(payload.vars) do
-- 	print(payload[v])
-- end
PAYLOAD.vars = {}

--- Returns a string representation of this payload.
-- @realm shared
-- @treturn string String representation
-- @usage print(ix.charmenu.CreatePayload())
-- > "payload[local]
-- 	name = nil
-- 	description = nil"
-- 	-- etc.
function PAYLOAD:__tostring()
	local buffer = {"payload[" .. (SERVER and self.player or "local") .. "]"}

	for _, v in ipairs(self.vars) do
		buffer[#buffer + 1] = string.format("\t%s = %s", v, tostring(self[v]))
	end

	return table.concat(buffer, "\n")
end

--- Checks whether or not this payload is valid. Internally, this will call `OnValidate` on any character vars that do not
-- have `bNoDisplay` set. On the server, this will also check if the assigned player (`payload.player`) is valid.
-- @realm shared
-- @treturn[1] bool `true` if this payload is valid
-- @treturn[2] bool `false` if this payload is invalid
-- @treturn[2] ... Language phrase with arguments
-- @usage print(ix.charmenu.CreatePayload():IsValid())
-- > false	nameMinLen	4
function PAYLOAD:IsValid()
	-- we only check the player on the server since the client's player object will always be valid
	if (SERVER and (!IsValid(self.player) or !self.player:IsPlayer())) then
		return false, "plyNoExist"
	end

	-- validate each character var if they have an OnValidate function
	for _, v in ipairs(self.vars) do
		local var = ix.char.vars[v]

		if (!var) then
			return false, "unknownError"
		end

		if (var.OnValidate) then
			local result = {var:OnValidate(self[v], self, self.player)}

			if (result[1] == false) then
				return false, unpack(result, 2)
			end
		end
	end

	return true
end

if (CLIENT) then
	--- Writes the payload to the current net message that's outbound to the server. This assumes that the data in the payload
	-- is valid, so make sure to make sure with `Payload.IsValid`.
	-- @realm client
	-- @internal
	function PAYLOAD:Serialize()
		for _, v in ipairs(self.vars) do
			net.WriteType(self[v])
		end
	end
else
	--- Populates this payload with the data from the current payload net message. This does not check validity, so you'll want
	-- to check it yourself with `Payload.IsValid`.
	-- @realm server
	-- @internal
	-- @player client The player that this payload originated from
	-- @treturn bool Whether or not the payload has been deserialized
	function PAYLOAD:Deserialize(client)
		if (!IsValid(client) or !client:IsPlayer()) then
			return false
		end

		self.player = client

		for _, v in ipairs(self.vars) do
			self[v] = net.ReadType()
		end

		return true
	end
end

ix.meta.payload = PAYLOAD
