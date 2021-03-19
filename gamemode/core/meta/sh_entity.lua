
--[[--
Physical object in the game world.

Entities are physical representations of objects in the game world. Helix extends the functionality of entities to interface
between Helix's own classes, and to reduce boilerplate code.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Entity) for all other methods that the `Player` class has.
]]
-- @classmod Entity

local meta = FindMetaTable("Entity")
local CHAIR_CACHE = {}

-- Add chair models to the cache by checking if its vehicle category is a class.
for _, v in pairs(list.Get("Vehicles")) do
	if (v.Category == "Chairs") then
		CHAIR_CACHE[v.Model] = true
	end
end

--- Returns `true` if this entity is a chair.
-- @realm shared
-- @treturn bool Whether or not this entity is a chair
function meta:IsChair()
	return CHAIR_CACHE[self:GetModel()]
end

--- Returns `true` if this entity is a door. Internally, this checks to see if the entity's class has `door` in its name.
-- @realm shared
-- @treturn bool Whether or not the entity is a door
function meta:IsDoor()
	local class = self:GetClass()

	return (class and class:find("door") != nil)
end

if (SERVER) then
	--- Returns `true` if the given entity is a button or door and is locked.
	-- @realm server
	-- @treturn bool Whether or not this entity is locked; `false` if this entity cannot be locked at all
	-- (e.g not a button or door)
	function meta:IsLocked()
		if (self:IsVehicle()) then
			local datatable = self:GetSaveTable()

			if (datatable) then
				return datatable.VehicleLocked
			end
		else
			local datatable = self:GetSaveTable()

			if (datatable) then
				return datatable.m_bLocked
			end
		end

		return false
	end

	--- Returns the neighbouring door entity for double doors.
	-- @realm shared
	-- @treturn[1] Entity This door's partner
	-- @treturn[2] nil If the door does not have a partner
	function meta:GetDoorPartner()
		return self.ixPartner
	end

	--- Returns the entity that is blocking this door from opening.
	-- @realm server
	-- @treturn[1] Entity Entity that is blocking this door
	-- @treturn[2] nil If this entity is not a door, or there is no blocking entity
	function meta:GetBlocker()
		local datatable = self:GetSaveTable()

		return datatable.pBlocker
	end

	--- Blasts a door off its hinges. Internally, this hides the door entity, spawns a physics prop with the same model, and
	-- applies force to the prop.
	-- @realm server
	-- @vector velocity Velocity to apply to the door
	-- @number lifeTime How long to wait in seconds before the door is put back on its hinges
	-- @bool bIgnorePartner Whether or not to ignore the door's partner in the case of double doors
	-- @treturn[1] Entity The physics prop created for the door
	-- @treturn nil If the entity is not a door
	function meta:BlastDoor(velocity, lifeTime, bIgnorePartner)
		if (!self:IsDoor()) then
			return
		end

		if (IsValid(self.ixDummy)) then
			self.ixDummy:Remove()
		end

		velocity = velocity or VectorRand()*100
		lifeTime = lifeTime or 120

		local partner = self:GetDoorPartner()

		if (IsValid(partner) and !bIgnorePartner) then
			partner:BlastDoor(velocity, lifeTime, true)
		end

		local color = self:GetColor()

		local dummy = ents.Create("prop_physics")
		dummy:SetModel(self:GetModel())
		dummy:SetPos(self:GetPos())
		dummy:SetAngles(self:GetAngles())
		dummy:Spawn()
		dummy:SetColor(color)
		dummy:SetMaterial(self:GetMaterial())
		dummy:SetSkin(self:GetSkin() or 0)
		dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
		dummy:CallOnRemove("restoreDoor", function()
			if (IsValid(self)) then
				self:SetNotSolid(false)
				self:SetNoDraw(false)
				self:DrawShadow(true)
				self.ignoreUse = false
				self.ixIsMuted = false

				for _, v in ipairs(ents.GetAll()) do
					if (v:GetParent() == self) then
						v:SetNotSolid(false)
						v:SetNoDraw(false)

						if (v.OnDoorRestored) then
							v:OnDoorRestored(self)
						end
					end
				end
			end
		end)
		dummy:SetOwner(self)
		dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		self:Fire("unlock")
		self:Fire("open")
		self:SetNotSolid(true)
		self:SetNoDraw(true)
		self:DrawShadow(false)
		self.ignoreUse = true
		self.ixDummy = dummy
		self.ixIsMuted = true
		self:DeleteOnRemove(dummy)

		for _, v in ipairs(self:GetBodyGroups() or {}) do
			dummy:SetBodygroup(v.id, self:GetBodygroup(v.id))
		end

		for _, v in ipairs(ents.GetAll()) do
			if (v:GetParent() == self) then
				v:SetNotSolid(true)
				v:SetNoDraw(true)

				if (v.OnDoorBlasted) then
					v:OnDoorBlasted(self)
				end
			end
		end

		dummy:GetPhysicsObject():SetVelocity(velocity)

		local uniqueID = "doorRestore"..self:EntIndex()
		local uniqueID2 = "doorOpener"..self:EntIndex()

		timer.Create(uniqueID2, 1, 0, function()
			if (IsValid(self) and IsValid(self.ixDummy)) then
				self:Fire("open")
			else
				timer.Remove(uniqueID2)
			end
		end)

		timer.Create(uniqueID, lifeTime, 1, function()
			if (IsValid(self) and IsValid(dummy)) then
				uniqueID = "dummyFade"..dummy:EntIndex()
				local alpha = 255

				timer.Create(uniqueID, 0.1, 255, function()
					if (IsValid(dummy)) then
						alpha = alpha - 1
						dummy:SetColor(ColorAlpha(color, alpha))

						if (alpha <= 0) then
							dummy:Remove()
						end
					else
						timer.Remove(uniqueID)
					end
				end)
			end
		end)

		return dummy
	end

else
	-- Returns the door's slave entity.
	function meta:GetDoorPartner()
		local owner = self:GetOwner() or self.ixDoorOwner

		if (IsValid(owner) and owner:IsDoor()) then
			return owner
		end

		for _, v in ipairs(ents.FindByClass("prop_door_rotating")) do
			if (v:GetOwner() == self) then
				self.ixDoorOwner = v

				return v
			end
		end
	end
end
