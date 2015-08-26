-- Includes a file from the prefix.
function nut.util.include(fileName, state)
	if (!fileName) then
		error("[NutScript] No file name specified for including.")
	end
	
	-- Only include server-side if we're on the server.
	if ((state == "server" or fileName:find("sv_")) and SERVER) then
		include(fileName)
	-- Shared is included by both server and client.
	elseif (state == "shared" or fileName:find("sh_")) then
		if (SERVER) then
			-- Send the file to the client if shared so they can run it.
			AddCSLuaFile(fileName)
		end

		include(fileName)
	-- File is sent to client, included on client.
	elseif (state == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

-- Include files based off the prefix within a directory.
function nut.util.includeDir(directory, fromLua)
	-- By default, we include relatively to NutScript.
	local baseDir = "nutscript"

	-- If we're in a schema, include relative to the schema.
	if (SCHEMA and SCHEMA.folder and SCHEMA.loading) then
		baseDir = SCHEMA.folder.."/schema/"
	else
		baseDir = baseDir.."/gamemode/"
	end

	-- Find all of the files within the directory.
	for k, v in ipairs(file.Find((fromLua and "" or baseDir)..directory.."/*.lua", "LUA")) do
		-- Include the file from the prefix.
		nut.util.include(directory.."/"..v)
	end
end

-- Returns the address:port of the server.
function nut.util.getAddress()
	local address = tonumber(GetConVarString("hostip"))
		
	if (!address) then
		return "127.0.0.1"..":"..GetConVarString("hostport")
	end
	
	local ip = {}
		ip[1] = bit.rshift(bit.band(address, 0xFF000000), 24)
		ip[2] = bit.rshift(bit.band(address, 0x00FF0000), 16)
		ip[3] = bit.rshift(bit.band(address, 0x0000FF00), 8)
		ip[4] = bit.band(address, 0x000000FF)
	return table.concat(ip, ".")..":"..GetConVarString("hostport")
end

-- Returns a table of admin players
function nut.util.getAdmins(isSuper)
	local admins = {}

	for k, v in ipairs(player.GetAll()) do
		if (isSuper) then
			if (v:IsSuperAdmin()) then
				table.insert(admins, v)
			end
		else
			if (v:IsAdmin()) then
				table.insert(admins, v)
			end
		end
	end

	return admins
end

-- Returns a single cached copy of a material or creates it if it doesn't exist.
function nut.util.getMaterial(materialPath)
	-- Cache the material.
	nut.util.cachedMaterials = nut.util.cachedMaterials or {}
	nut.util.cachedMaterials[materialPath] = nut.util.cachedMaterials[materialPath] or Material(materialPath)

	return nut.util.cachedMaterials[materialPath]
end

-- Finds a player by matching their names.
function nut.util.findPlayer(name, allowPatterns)
	if (!allowPatterns) then
		name = string.PatternSafe(name)
	end
	
	for k, v in ipairs(player.GetAll()) do
		if (nut.util.stringMatches(v:Name(), name)) then
			return v
		end
	end
end

-- Returns whether or a not a string matches.
function nut.util.stringMatches(a, b)
	if (a and b) then
		local a2, b2 = a:lower(), b:lower()

		-- Check if the actual letters match.
		if (a == b) then return true end
		if (a2 == b2) then return true end

		-- Be less strict and search.
		if (a:find(b)) then return true end
		if (a2:find(b2)) then return true end
	end
	
	return false
end

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0 and "" or "../../hl2/sound/"

-- Emits sounds one after the other from an entity.
function nut.util.emitQueuedSounds(entity, sounds, delay, spacing, volume, pitch)
	-- Let there be a delay before any sound is played.
	delay = delay or 0
	spacing = spacing or 0.1

	-- Loop through all of the sounds.
	for k, v in ipairs(sounds) do
		local postSet, preSet = 0, 0

		-- Determine if this sound has special time offsets.
		if (type(v) == "table") then
			postSet, preSet = v[2] or 0, v[3] or 0
			v = v[1]
		end

		-- Get the length of the sound.
		local length = SoundDuration(ADJUST_SOUND..v)
		-- If the sound has a pause before it is played, add it here.
		delay = delay + preSet

		-- Have the sound play in the future.
		timer.Simple(delay, function()
			-- Check if the entity still exists and play the sound.
			if (IsValid(entity)) then
				entity:EmitSound(v, volume, pitch)
			end
		end)

		-- Add the delay for the next sound.
		delay = delay + length + postSet + spacing
	end

	-- Return how long it took for the whole thing.
	return delay
end

function nut.util.gridVector(vec, gridSize)
	if (gridSize <= 0) then
		gridSize = 1
	end

	for i = 1, 3 do
		vec[i] = vec[i] / gridSize
		vec[i] = math.Round(vec[i])
		vec[i] = vec[i] * gridSize
	end

	return vec
end

function nut.util.getAllChar()
	local charTable = {}

	for k, v in ipairs(player.GetAll()) do
		if (v:getChar()) then
			table.insert(charTable, v:getChar():getID())
		end
	end

	return charTable
end

if (CLIENT) then
	NUT_CVAR_CHEAP = CreateClientConVar("nut_cheapblur", 0, true)
	
	local useCheapBlur = NUT_CVAR_CHEAP:GetBool()
	local blur = nut.util.getMaterial("pp/blurscreen")

	cvars.AddChangeCallback("nut_cheapblur", function(name, old, new)
		useCheapBlur = (tonumber(new) or 0) > 0
	end)

	-- Draws a blurred material over the screen, to blur things.
	function nut.util.drawBlur(panel, amount, passes)
		-- Intensity of the blur.
		amount = amount or 5
		
		if (useCheapBlur) then
			surface.SetDrawColor(50, 50, 50, amount * 20)
			surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		else
			surface.SetMaterial(blur)
			surface.SetDrawColor(255, 255, 255)

			local x, y = panel:LocalToScreen(0, 0)
			
			for i = -(passes or 0.2), 1, 0.2 do
				-- Do things to the blur material to make it blurry.
				blur:SetFloat("$blur", i * amount)
				blur:Recompute()

				-- Draw the blur material over the screen.
				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			end
		end
	end

	function nut.util.drawBlurAt(x, y, w, h, amount, passes)
		-- Intensity of the blur.
		amount = amount or 5

		if (useCheapBlur) then
			surface.SetDrawColor(30, 30, 30, amount * 20)
			surface.DrawRect(x, y, w, h)
		else
			surface.SetMaterial(blur)
			surface.SetDrawColor(255, 255, 255)

			local scrW, scrH = ScrW(), ScrH()
			local x2, y2 = x / scrW, y / scrH
			local w2, h2 = (x + w) / scrW, (y + h) / scrH

			for i = -(passes or 0.2), 1, 0.2 do
				blur:SetFloat("$blur", i * amount)
				blur:Recompute()

				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRectUV(x, y, w, h, x2, y2, w2, h2)
			end
		end
	end

	-- Draw a text with a shadow.
	function nut.util.drawText(text, x, y, color, alignX, alignY, font, alpha)
		color = color or color_white

		return draw.TextShadow({
			text = text,
			font = font or "nutGenericFont",
			pos = {x, y},
			color = color,
			xalign = alignX or 0,
			yalign = alignY or 0
		}, 1, alpha or (color.a * 0.575))
	end

	-- Wraps text so it does not pass a certain width.
	function nut.util.wrapText(text, width, font)
		font = font or "nutChatFont"
		surface.SetFont(font)

		local exploded = string.Explode("%s", text, true)
		local line = ""
		local lines = {}
		local w = surface.GetTextSize(text)
		local maxW = 0
		
		if (w <= width) then
			return {(text:gsub("%s", " "))}, w
		end
		
		for i = 1, #exploded do
			local word = exploded[i]
			line = line.." "..word
			w = surface.GetTextSize(line)
			
			if (w > width) then
				lines[#lines + 1] = line
				line = ""
				
				if (w > maxW) then
					maxW = w
				end
			end
		end

		if (line != "") then
			lines[#lines + 1] = line
		end
		
		return lines, maxW
	end

	local LAST_WIDTH = ScrW()
	local LAST_HEIGHT = ScrH()

	timer.Create("nutResolutionMonitor", 1, 0, function()
		local scrW, scrH = ScrW(), ScrH()

		if (scrW != LAST_WIDTH or scrH != LAST_HEIGHT) then
			hook.Run("ScreenResolutionChanged", LAST_WIDTH, LAST_HEIGHT)
			
			LAST_WIDTH = scrW
			LAST_HEIGHT = scrH
		end
	end)
end

-- Utility entity extensions.
do
	local entityMeta = FindMetaTable("Entity")

	-- Checks if an entity is a door by comparing its class.
	function entityMeta:isDoor()
		return self:GetClass():find("door")
	end

	-- Make a cache of chairs on start.
	local CHAIR_CACHE = {}

	-- Add chair models to the cache by checking if its vehicle category is a class.
	for k, v in pairs(list.Get("Vehicles")) do
		if (v.Category == "Chairs") then
			CHAIR_CACHE[v.Model] = true
		end
	end

	-- Whether or not a vehicle is a chair by checking its model with the chair list.
	function entityMeta:isChair()
		-- Micro-optimization in-case this gets used a lot.
		return CHAIR_CACHE[self.GetModel(self)]
	end

	if (SERVER) then
		-- Returns the door's slave entity.
		function entityMeta:getDoorPartner()
			return self.nutPartner
		end

		-- Returns whether door/button is locked or not.
		function entityMeta:isLocked()
			if (self:IsVehicle()) then
				local datatable = self:GetSaveTable()

				if (datatable) then
					return (datatable.VehicleLocked)
				end
			else
				local datatable = self:GetSaveTable()

				if (datatable) then
					return (datatable.m_bLocked)
				end
			end

			return
		end

		-- Returns the entity that blocking door's sequence.
		function entityMeta:getBlocker()
			local datatable = self:GetSaveTable()

			return (datatable.pBlocker)
		end
	else
		-- Returns the door's slave entity.
		function entityMeta:getDoorPartner()
			local owner = self:GetOwner() or self.nutDoorOwner

			if (IsValid(owner) and owner:isDoor()) then
				return owner
			end

			for k, v in ipairs(ents.FindByClass("prop_door_rotating")) do
				if (v:GetOwner() == self) then
					self.nutDoorOwner = v

					return v
				end
			end
		end
	end

	-- Makes a fake door to replace it.
	function entityMeta:blastDoor(velocity, lifeTime, ignorePartner)
		if (!self:isDoor()) then
			return
		end

		if (IsValid(self.nutDummy)) then
			self.nutDummy:Remove()
		end

		velocity = velocity or VectorRand()*100
		lifeTime = lifeTime or 120

		local partner = self:getDoorPartner()

		if (IsValid(partner) and !ignorePartner) then
			partner:blastDoor(velocity, lifeTime, true)
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
				self.nutIsMuted = false

				for k, v in ipairs(ents.GetAll()) do
					if (v:GetParent() == self) then
						v:SetNotSolid(false)
						v:SetNoDraw(false)

						if (v.onDoorRestored) then
							v:onDoorRestored(self)
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
		self.nutDummy = dummy
		self.nutIsMuted = true
		self:DeleteOnRemove(dummy)

		for k, v in ipairs(self:GetBodyGroups()) do
			dummy:SetBodygroup(v.id, self:GetBodygroup(v.id))
		end

		for k, v in ipairs(ents.GetAll()) do
			if (v:GetParent() == self) then
				v:SetNotSolid(true)
				v:SetNoDraw(true)

				if (v.onDoorBlasted) then
					v:onDoorBlasted(self)
				end
			end
		end

		dummy:GetPhysicsObject():SetVelocity(velocity)

		local uniqueID = "doorRestore"..self:EntIndex()
		local uniqueID2 = "doorOpener"..self:EntIndex()

		timer.Create(uniqueID2, 1, 0, function()
			if (IsValid(self) and IsValid(self.nutDummy)) then
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
end

-- Misc. player stuff.
do
	local playerMeta = FindMetaTable("Player")
	ALWAYS_RAISED = {}
	ALWAYS_RAISED["weapon_physgun"] = true
	ALWAYS_RAISED["gmod_tool"] = true
	ALWAYS_RAISED["nut_poshelper"] = true

	-- Returns how many seconds the player has played on the server in total.
	if (SERVER) then
		function playerMeta:getPlayTime()
			return self.nutPlayTime + (RealTime() - (self.nutJoinTime or RealTime()))
		end
	else
		nut.playTime = nut.playTime or 0

		function playerMeta:getPlayTime()
			return nut.playTime + (RealTime() - nut.joinTime)
		end
	end

	-- Returns whether or not the player has their weapon raised.
	function playerMeta:isWepRaised()
		local weapon = self.GetActiveWeapon(self)
		local override = hook.Run("ShouldWeaponBeRaised", self, weapon)
		
		-- Allow the hook to check first.
		if (override != nil) then
			return override
		end
		
		-- Some weapons may have their own properties.
		if (IsValid(weapon)) then
			-- If their weapon is always raised, return true.
			if (weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon.GetClass(weapon)]) then
				return true
			-- Return false if always lowered.
			elseif (weapon.IsAlwaysLowered or weapon.NeverRaised) then
				return false
			end
		end

		-- If the player has been forced to have their weapon lowered.
		if (self.getNetVar(self, "restricted")) then
			return false
		end

		-- Let the config decide before actual results.
		if (nut.config.get("wepAlwaysRaised")) then
			return true
		end

		-- Returns what the gamemode decides.
		return self.getNetVar(self, "raised", false)
	end

	local vectorLength2D = FindMetaTable("Vector").Length2D
	
	-- Checks if the player is running by seeing if the speed is faster than walking.
	function playerMeta:isRunning()
		return vectorLength2D(self.GetVelocity(self)) > (self.GetWalkSpeed(self) + 10)
	end

	-- Checks if the player has a female model.
	function playerMeta:isFemale()
		local model = self:GetModel():lower()

		return model:find("female") or model:find("alyx") or model:find("mossman") or nut.anim.getModelClass(model) == "citizen_female"
	end

	-- Returns a good position in front of the player for an entity.
	function playerMeta:getItemDropPos()
		-- Start a trace.
		local data = {}
			-- The trace starts behind the player in case they are looking at a wall.
			data.start = self:GetShootPos() - self:GetAimVector()*64
			-- The trace finishes 86 units infront of the player.
			data.endpos = self:GetShootPos() + self:GetAimVector()*86
			-- Ignore the actual player.
			data.filter = self
		-- Get the end position of the trace.
		local trace = util.TraceLine(data)

		return trace.HitPos + trace.HitNormal*36
	end

	-- Do an action that requires the player to stare at something.
	function playerMeta:doStaredAction(entity, callback, time, onCancel, distance)
		local uniqueID = "nutStare"..self:UniqueID()
		local data = {}
		data.filter = self

		timer.Create(uniqueID, 0.1, time / 0.1, function()
			if (IsValid(self) and IsValid(entity)) then
				data.start = self:GetShootPos()
				data.endpos = data.start + self:GetAimVector()*(distance or 96)

				if (util.TraceLine(data).Entity != entity) then
					timer.Remove(uniqueID)

					if (onCancel) then
						onCancel()
					end
				elseif (callback and timer.RepsLeft(uniqueID) == 0) then
					callback()
				end
			else
				timer.Remove(uniqueID)

				if (onCancel) then
					onCancel()
				end
			end
		end)
	end

	if (SERVER) then
		-- Sets whether or not the weapon is raised.
		function playerMeta:setWepRaised(state)
			-- Sets the networked variable for being raised.
			self:setNetVar("raised", state)

			-- Delays any weapon shooting.
			local weapon = self:GetActiveWeapon()

			if (IsValid(weapon)) then
				weapon:SetNextPrimaryFire(CurTime() + 1)
				weapon:SetNextSecondaryFire(CurTime() + 1)
			end
		end

		-- Inverts whether or not the weapon is raised.
		function playerMeta:toggleWepRaised()
			self:setWepRaised(!self:isWepRaised())

			local weapon = self:GetActiveWeapon()

			if (IsValid(weapon)) then
				if (self:isWepRaised() and weapon.OnRaised) then
					weapon:OnRaised()
				elseif (!self:isWepRaised() and weapon.OnLowered) then
					weapon:OnLowered()
				end
			end
		end

		-- Performs a delayed action on a player.
		function playerMeta:setAction(text, time, callback, startTime, finishTime)
			if (time and time <= 0) then
				if (callback) then
					callback(self)
				end
				
				return
			end

			-- Default the time to five seconds.
			time = time or 5
			startTime = startTime or CurTime()
			finishTime = finishTime or (startTime + time)

			if (text == false) then
				timer.Remove("nutAct"..self:UniqueID())
				netstream.Start(self, "actBar")

				return
			end

			-- Tell the player to draw a bar for the action.
			netstream.Start(self, "actBar", startTime, finishTime, text)

			-- If we have provided a callback, run it delayed.
			if (callback) then
				-- Create a timer that runs once with a delay.
				timer.Create("nutAct"..self:UniqueID(), time, 1, function()
					-- Call the callback if the player is still valid.
					if (IsValid(self)) then
						callback(self)
					end
				end)
			end
		end

		-- Sends a Derma string request to the client.
		function playerMeta:requestString(title, subTitle, callback, default)
			local time = math.floor(os.time())

			self.nutStrReqs = self.nutStrReqs or {}
			self.nutStrReqs[time] = callback

			netstream.Start(self, "strReq", time, title, subTitle, default)
		end

		-- Removes a player's weapon and restricts interactivity.
		function playerMeta:setRestricted(state, noMessage)
			if (state) then
				self:setNetVar("restricted", true)
				
				if (noMessage) then
					self:setLocalVar("restrictNoMsg", true)
				end

				self.nutRestrictWeps = self.nutRestrictWeps or {}

				for k, v in ipairs(self:GetWeapons()) do
					self.nutRestrictWeps[#self.nutRestrictWeps + 1] = v:GetClass()
					v:Remove()
				end

				hook.Run("OnPlayerRestricted", self)
			else
				self:setNetVar("restricted")

				if (self:getLocalVar("restrictNoMsg")) then
					self:setLocalVar("restrictNoMsg")
				end

				if (self.nutRestrictWeps) then
					for k, v in ipairs(self.nutRestrictWeps) do
						self:Give(v)
					end

					self.nutRestrictWeps = nil
				end

				hook.Run("OnPlayerUnRestricted", self)
			end
		end
	end

	-- Player ragdoll utility stuff.
	do
		function nut.util.findEmptySpace(entity, filter, spacing, size, height, tolerance)
			spacing = spacing or 32
			size = size or 3
			height = height or 36
			tolerance = tolerance or 5

			local position = entity:GetPos()
			local angles = Angle(0, 0, 0)
			local mins, maxs = Vector(-spacing * 0.5, -spacing * 0.5, 0), Vector(spacing * 0.5, spacing * 0.5, height)
			local output = {}

			for x = -size, size do
				for y = -size, size do
					local origin = position + Vector(x * spacing, y * spacing, 0)
					local color = green
					local i = 0

					local data = {}
						data.start = origin + mins + Vector(0, 0, tolerance)
						data.endpos = origin + maxs
						data.filter = filter or entity
					local trace = util.TraceLine(data)

					data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
					data.endpos = origin + Vector(mins.x, mins.y, height)

					local trace2 = util.TraceLine(data)

					if (trace.StartSolid or trace.Hit or trace2.StartSolid or trace2.Hit or !util.IsInWorld(origin)) then
						continue
					end

					output[#output + 1] = origin
				end
			end

			table.sort(output, function(a, b)
				return a:Distance(position) < b:Distance(position)
			end)

			return output
		end

		function playerMeta:isStuck()
			return util.TraceEntity({
				start = self:GetPos(),
				endpos = self:GetPos(),
				filter = self
			}, self).StartSolid
		end

		function playerMeta:setRagdolled(state, time, getUpGrace)
			getUpGrace = getUpGrace or time or 5

			if (state) then
				if (IsValid(self.nutRagdoll)) then
					self.nutRagdoll:Remove()
				end

				local entity = ents.Create("prop_ragdoll")
				entity:SetPos(self:GetPos())
				entity:SetAngles(self:EyeAngles())
				entity:SetModel(self:GetModel())
				entity:SetSkin(self:GetSkin())
				entity:Spawn()
				entity:setNetVar("player", self)
				entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				entity:Activate()
				entity:CallOnRemove("fixer", function()
					if (IsValid(self)) then
						self:setLocalVar("blur", nil)
						self:setLocalVar("ragdoll", nil)

						if (!entity.nutNoReset) then
							self:SetPos(entity:GetPos())
						end

						self:SetNoDraw(false)
						self:SetNotSolid(false)
						self:Freeze(false)
						self:SetMoveType(MOVETYPE_WALK)
						self:SetLocalVelocity(IsValid(entity) and entity.nutLastVelocity or vector_origin)
					end

					if (IsValid(self) and !entity.nutIgnoreDelete) then
						if (entity.nutWeapons) then
							for k, v in ipairs(entity.nutWeapons) do
								self:Give(v)
							end
						end

						if (self:isStuck()) then
							entity:DropToFloor()
							self:SetPos(entity:GetPos() + Vector(0, 0, 16))

							local positions = nut.util.findEmptySpace(self, {entity, self})

							for k, v in ipairs(positions) do
								self:SetPos(v)

								if (!self:isStuck()) then
									return
								end
							end
						end
					end
				end)

				local velocity = self:GetVelocity()

				for i = 0, entity:GetPhysicsObjectCount() - 1 do
					local physObj = entity:GetPhysicsObjectNum(i)

					if (IsValid(physObj)) then
						physObj:SetVelocity(velocity)

						local index = entity:TranslatePhysBoneToBone(i)

						if (index) then
							local position, angles = self:GetBonePosition(index)

							physObj:SetPos(position)
							physObj:SetAngles(angles)
						end
					end
				end

				self:setLocalVar("blur", 25)
				self.nutRagdoll = entity

				entity.nutWeapons = {}
				entity.nutPlayer = self

				if (getUpGrace) then
					entity.nutGrace = CurTime() + getUpGrace
				end

				if (time and time > 0) then
					entity.nutStart = CurTime()
					entity.nutFinish = entity.nutStart + time

					self:setAction("@wakingUp", nil, nil, entity.nutStart, entity.nutFinish)
				end

				for k, v in ipairs(self:GetWeapons()) do
					entity.nutWeapons[#entity.nutWeapons + 1] = v:GetClass()
				end

				self:GodDisable()
				self:StripWeapons()
				self:Freeze(true)
				self:SetNoDraw(true)
				self:SetNotSolid(true)

				if (time) then
					local time2 = time
					local uniqueID = "nutUnRagdoll"..self:SteamID()

					timer.Create(uniqueID, 0.33, 0, function()
						if (IsValid(entity) and IsValid(self)) then
							local velocity = entity:GetVelocity()
							entity.nutLastVelocity = velocity
							
							self:SetPos(entity:GetPos())

							if (velocity:Length2D() >= 8) then
								if (!entity.nutPausing) then
									self:setAction()
									entity.nutPausing = true
								end

								return
							elseif (entity.nutPausing) then
								self:setAction("@wakingUp", time)
								entity.nutPausing = false
							end

							time = time - 0.33

							if (time <= 0) then
								entity:Remove()
							end
						else
							timer.Remove(uniqueID)
						end
					end)
				end

				self:setLocalVar("ragdoll", entity:EntIndex())
				hook.Run("OnCharFallover", self, entity, true)
			elseif (IsValid(self.nutRagdoll)) then
				self.nutRagdoll:Remove()

				hook.Run("OnCharFallover", self, entity, false)
			end
		end
	end
end

-- Time related stuff.
do
	-- Gets the current time in the UTC time-zone.
	function nut.util.getUTCTime()
		local date = os.date("!*t")
		local localDate = os.date("*t")
		localDate.isdst = false

		return os.difftime(os.time(date), os.time(localDate))
	end

	-- Setup for time strings.
	local TIME_UNITS = {}
	TIME_UNITS["s"] = 1						-- Seconds
	TIME_UNITS["m"] = 60					-- Minutes
	TIME_UNITS["h"] = 3600					-- Hours
	TIME_UNITS["d"] = TIME_UNITS["h"] * 24	-- Days
	TIME_UNITS["w"] = TIME_UNITS["d"] * 7	-- Weeks
	TIME_UNITS["mo"] = TIME_UNITS["d"] * 30	-- Months
	TIME_UNITS["y"] = TIME_UNITS["d"] * 365	-- Years

	-- Gets the amount of seconds from a given formatted string.
	-- Example: 5y2d7w = 5 years, 2 days, and 7 weeks.
	-- If just given a minute, it is assumed minutes.
	function nut.util.getStringTime(text)
		local minutes = tonumber(text)

		if (minutes) then
			return math.abs(minutes * 60)
		end

		local time = 0

		for amount, unit in text:lower():gmatch("(%d+)(%a+)") do
			amount = tonumber(amount)
			
			if (amount and TIME_UNITS[unit]) then
				time = time + math.abs(amount * TIME_UNITS[unit])
			end
		end

		return time
	end
end