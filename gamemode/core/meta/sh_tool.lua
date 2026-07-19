local TOOL = ix.meta.tool or {}

-- code replicated from gamemodes/sandbox/entities/weapons/gmod_tool/stool.lua
function TOOL:Create()
	local object = {}

	setmetatable(object, self)
	self.__index = self

	object.Mode = nil
	object.SWEP = nil
	object.Owner = nil
	object.ClientConVar = {}
	object.ServerConVar = {}
	object.Objects = {}
	object.Stage = 0
	object.Message = "start"
	object.LastMessage = 0
	object.AllowedCVar = 0

	return object
end

function TOOL:CreateConVars()
	local mode = self:GetMode()

	if (CLIENT) then
		for cvar, default in pairs(self.ClientConVar) do
			CreateClientConVar(mode .. "_" .. cvar, default, true, true)
		end

		return
	end

	-- Note: I changed this from replicated because replicated convars don't work when they're created via Lua.
	if (SERVER) then
		self.AllowedCVar = CreateConVar("toolmode_allow_" .. mode, 1, FCVAR_NOTIFY)
	end
end

function TOOL:GetServerInfo(property)
	local mode = self:GetMode()
	return GetConVarString(mode .. "_" .. property)
end

function TOOL:BuildConVarList()
	local mode = self:GetMode()
	local convars = {}

	for k, v in pairs(self.ClientConVar) do
		convars[mode .. "_" .. k] = v
	end

	return convars
end

function TOOL:GetClientInfo(property)
	return self:GetOwner():GetInfo(self:GetMode() .. "_" .. property)
end

function TOOL:GetClientNumber(property, default)
	return self:GetOwner():GetInfoNum(self:GetMode() .. "_" .. property, tonumber(default) or 0)
end

function TOOL:Allowed()
	if (CLIENT) then
		return true
	end

	return self.AllowedCVar:GetBool()
end

-- Now for all the TOOL redirects
function TOOL:Init() end

function TOOL:GetMode()
	return self.Mode
end

function TOOL:GetSWEP()
	return self.SWEP
end

function TOOL:GetOwner()
	return self:GetSWEP().Owner or self.Owner
end

function TOOL:GetWeapon()
	return self:GetSWEP().Weapon or self.Weapon
end

function TOOL:LeftClick()
	return false
end

function TOOL:RightClick()
	return false
end

function TOOL:Reload()
	self:ClearObjects()
end

function TOOL:Deploy()
	self:ReleaseGhostEntity()
	return
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	return
end

function TOOL:Think()
	self:ReleaseGhostEntity()
end

-- Checks the objects before any action is taken
-- This is to make sure that the entities haven't been removed
function TOOL:CheckObjects()
	for _, v in pairs(self.Objects) do
		if (!v.Ent:IsWorld() and !v.Ent:IsValid()) then
			self:ClearObjects()
		end
	end
end

--[[ GhostEntity.lua ]]
--[[---------------------------------------------------------
	Starts up the ghost entity
	The most important part of this is making sure it gets deleted properly
-----------------------------------------------------------]]
function TOOL:MakeGhostEntity(model, pos, angle)
	util.PrecacheModel(model)

	-- We do ghosting serverside in single player
	-- It's done clientside in multiplayer
	if (SERVER && !game.SinglePlayer()) then return end
	if (CLIENT && game.SinglePlayer()) then return end

	-- The reason we need this is because in multiplayer, when you holster a tool serverside,
	-- either by using the spawnnmenu's Weapons tab or by simply entering a vehicle,
	-- the Think hook is called once after Holster is called on the client, recreating the ghost entity right after it was removed.
	if (!IsFirstTimePredicted()) then return end

	-- Release the old ghost entity
	self:ReleaseGhostEntity()

	-- Don't allow ragdolls/effects to be ghosts
	if (!util.IsValidProp(model)) then return end

	if (CLIENT) then
		self.GhostEntity = ents.CreateClientProp(model)
	else
		self.GhostEntity = ents.Create("prop_physics")
	end

	-- If there's too many entities we might not spawn..
	if (!IsValid(self.GhostEntity)) then
		self.GhostEntity = nil
		return
	end

	self.GhostEntity:SetModel(model)
	self.GhostEntity:SetPos(pos)
	self.GhostEntity:SetAngles(angle)
	self.GhostEntity:Spawn()

	-- We do not want physics at all
	self.GhostEntity:PhysicsDestroy()

	-- SOLID_NONE causes issues with Entity.NearestPoint used by Wheel tool
	--self.GhostEntity:SetSolid(SOLID_NONE)
	self.GhostEntity:SetMoveType(MOVETYPE_NONE )
	self.GhostEntity:SetNotSolid(true)
	self.GhostEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self.GhostEntity:SetColor(Color(255, 255, 255, 150))
end

--[[---------------------------------------------------------
	Starts up the ghost entity
	The most important part of this is making sure it gets deleted properly
-----------------------------------------------------------]]
function TOOL:StartGhostEntity( ent )
	-- We do ghosting serverside in single player
	-- It's done clientside in multiplayer
	if (SERVER && !game.SinglePlayer()) then return end
	if (CLIENT && game.SinglePlayer()) then return end

	self:MakeGhostEntity(ent:GetModel(), ent:GetPos(), ent:GetAngles())
end

--[[---------------------------------------------------------
	Releases up the ghost entity
-----------------------------------------------------------]]
function TOOL:ReleaseGhostEntity()
	if (self.GhostEntity) then
		if (!IsValid(self.GhostEntity)) then self.GhostEntity = nil return end
		self.GhostEntity:Remove()
		self.GhostEntity = nil
	end

	-- This is unused!
	if (self.GhostEntities) then
		for k,v in pairs(self.GhostEntities) do
			if (IsValid(v)) then v:Remove() end
			self.GhostEntities[k] = nil
		end
		self.GhostEntities = nil
	end

	-- This is unused!
	if (self.GhostOffset) then
		for k,v in pairs(self.GhostOffset) do
			self.GhostOffset[k] = nil
		end
	end
end

--[[---------------------------------------------------------
	Update the ghost entity
-----------------------------------------------------------]]
function TOOL:UpdateGhostEntity()
	if (self.GhostEntity == nil ) then return end
	if (!IsValid(self.GhostEntity)) then self.GhostEntity = nil return end

	local trace = self:GetOwner():GetEyeTrace()
	if (!trace.Hit) then return end

	local Ang1, Ang2 = self:GetNormal(1):Angle(), (trace.HitNormal * -1):Angle()
	local TargetAngle = self:GetEnt(1):AlignAngles(Ang1, Ang2)

	self.GhostEntity:SetPos(self:GetEnt(1):GetPos())
	self.GhostEntity:SetAngles(TargetAngle )

	local TranslatedPos = self.GhostEntity:LocalToWorld( self:GetLocalPos(1) )
	local TargetPos = trace.HitPos + (self:GetEnt(1):GetPos() - TranslatedPos) + trace.HitNormal

	self.GhostEntity:SetPos(TargetPos)
end

--[[ stool_cl.lua ]]
if (CLIENT) then
	-- Tool should return true if freezing the view angles
	function TOOL:FreezeMovement()
		return false 
	end

	-- The tool's opportunity to draw to the HUD
	function TOOL:DrawHUD() end
end

--[[ object.lua ]]
function TOOL:UpdateData()
	self:SetStage(self:NumObjects())
end

function TOOL:SetStage(i)
	if (SERVER) then
		self:GetWeapon():SetNWInt("Stage", i, true)
	end
end

function TOOL:GetStage()
	return self:GetWeapon():GetNWInt("Stage", 0)
end

function TOOL:SetOperation(i)
	if (SERVER) then
		self:GetWeapon():SetNWInt("Op", i, true)
	end
end

function TOOL:GetOperation()
	return self:GetWeapon():GetNWInt("Op", 0)
end

-- Clear the selected objects
function TOOL:ClearObjects()
	self:ReleaseGhostEntity()
	self.Objects = {}
	self:SetStage(0)
	self:SetOperation(0)
end

--[[---------------------------------------------------------
	Since we're going to be expanding this a lot I've tried
	to add accessors for all of this crap to make it harder
	for us to mess everything up.
-----------------------------------------------------------]]
function TOOL:GetEnt(i)
	if (!self.Objects[i]) then return NULL end

	return self.Objects[i].Ent
end

--[[---------------------------------------------------------
	Returns the world position of the numbered object hit
	We store it as a local vector then convert it to world
	That way even if the object moves it's still valid
-----------------------------------------------------------]]
function TOOL:GetPos(i)
	if (self.Objects[i].Ent:EntIndex() == 0) then
		return self.Objects[i].Pos
	else
		if (IsValid(self.Objects[i].Phys)) then
			return self.Objects[i].Phys:LocalToWorld(self.Objects[i].Pos)
		else
			return self.Objects[i].Ent:LocalToWorld(self.Objects[i].Pos)
		end
	end
end

-- Returns the local position of the numbered hit
function TOOL:GetLocalPos(i)
	return self.Objects[i].Pos
end

-- Returns the physics bone number of the hit (ragdolls)
function TOOL:GetBone(i)
	return self.Objects[i].Bone
end

function TOOL:GetNormal(i)
	if (self.Objects[i].Ent:EntIndex() == 0) then
		return self.Objects[i].Normal
	else
		local norm
		if (IsValid(self.Objects[i].Phys)) then
			norm = self.Objects[i].Phys:LocalToWorld(self.Objects[i].Normal)
		else
			norm = self.Objects[i].Ent:LocalToWorld(self.Objects[i].Normal)
		end

		return norm - self:GetPos(i)
	end
end

-- Returns the physics object for the numbered hit
function TOOL:GetPhys(i)
	if (self.Objects[i].Phys == nil) then
		return self:GetEnt(i):GetPhysicsObject()
	end

	return self.Objects[i].Phys
end

-- Sets a selected object
function TOOL:SetObject(i, ent, pos, phys, bone, norm)
	self.Objects[i] = {}
	self.Objects[i].Ent = ent
	self.Objects[i].Phys = phys
	self.Objects[i].Bone = bone
	self.Objects[i].Normal = norm

	-- Worldspawn is a special case
	if (ent:EntIndex() == 0) then
		self.Objects[i].Phys = nil
		self.Objects[i].Pos = pos
	else
		norm = norm + pos

		-- Convert the position to a local position - so it's still valid when the object moves
		if (IsValid(phys)) then
			self.Objects[i].Normal = self.Objects[i].Phys:WorldToLocal(norm)
			self.Objects[i].Pos = self.Objects[i].Phys:WorldToLocal(pos)
		else
			self.Objects[i].Normal = self.Objects[i].Ent:WorldToLocal(norm)
			self.Objects[i].Pos = self.Objects[i].Ent:WorldToLocal(pos)
		end
	end
end

-- Returns the number of objects in the list
function TOOL:NumObjects()
	if (CLIENT) then
		return self:GetStage()
	end

	return #self.Objects
end

if (CLIENT) then
	-- Returns the number of objects in the list
	function TOOL:GetHelpText()
		return "#tool." .. GetConVarString("gmod_toolmode") .. "." .. self:GetStage()
	end

	function TOOL:DrawToolScreen(w, h)
		surface.SetFont('GModToolScreen')

		local text = language.GetPhrase("#tool." .. GetConVarString("gmod_toolmode") .. ".name")
		local y = 104
		local w, h = surface.GetTextSize(text)

		w = w + 64
		y = y - h * 0.5

		local x = RealTime() * 250 % w * -1

		while x < w do
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(x + 3, y + 3)
			surface.DrawText(text)

			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(x, y)
			surface.DrawText(text)

			x = x + w
		end
	end
end

ix.meta.tool = TOOL
