--[[
	BLACK TEA ICON LIBRARY FOR NUTSCRIPT 1.1

	The MIT License (MIT)

	Copyright (c) 2017, Kyu Yeon Lee(Black Tea Za rebel1324)

	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
	the Software, and to permit persons to whom the Software is furnished to do so, subject
	to the following conditions:

	The above copyright notice and thispermission notice shall be included in all copies
	or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.

	TL;DR: https://tldrlegal.com/license/mit-license
	OK -
			Commercial Use
			Modify
			Distribute
			Sublicense
			Private Use

	NOT OK -
			Hold Liable

	MUST -
			Include Copyright
			Include License
]]--

--[[
	Default Tables.
]]--

ikon = ikon or {}
ikon.cache = ikon.cache or {}
ikon.requestList = ikon.requestList or {}
ikon.dev = false
ikon.maxSize = 8 -- 8x8 (512^2) is max icon size.

IKON_BUSY = 1
IKON_PROCESSING = 0
IKON_SOMETHINGWRONG = -1

local schemaName = schemaName or (Schema and Schema.folder)

--[[
	Initialize hooks and RT Screens.
	returns nothing
]]--
function ikon:init()
	if (self.dev) then
		hook.Add("HUDPaint", "ikon_dev2", ikon.showResult)
	else
		hook.Remove("HUDPaint", "ikon_dev2")
	end

	--[[
		Being good at gmod is knowing all of stinky hacks
										- Black Tea (2017)
	]]--
	ikon.haloAdd = ikon.haloAdd or halo.Add
	function halo.Add(...)
		if (ikon.rendering != true) then
			ikon.haloAdd(...)
		end
	end

	ikon.haloRender = ikon.haloRender or halo.Render
	function halo.Render(...)
		if (ikon.rendering != true) then
			ikon.haloRender(...)
		end
	end

	file.CreateDir("helix/icons")
	file.CreateDir("helix/icons/" .. schemaName)
end

--[[
	IKON Library Essential Material/Texture Declare
]]--

local TEXTURE_FLAGS_CLAMP_S = 0x0004
local TEXTURE_FLAGS_CLAMP_T = 0x0008

ikon.max = ikon.maxSize * 64
ikon.RT = GetRenderTargetEx("ixIconRendered",
	ikon.max,
	ikon.max,
	RT_SIZE_NO_CHANGE,
	MATERIAL_RT_DEPTH_SHARED,
	bit.bor(TEXTURE_FLAGS_CLAMP_S, TEXTURE_FLAGS_CLAMP_T),
	CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
	IMAGE_FORMAT_RGBA8888
)

local tex_effect = GetRenderTarget("ixIconRenderedOutline", ikon.max, ikon.max)
local mat_outline = CreateMaterial("ixIconRenderedTemp", "UnlitGeneric", {
	["$basetexture"] = tex_effect:GetName(),
	["$translucent"] = 1
})

local lightPositions = {
	BOX_TOP = Color(255, 255, 255),
	BOX_FRONT = Color(255, 255, 255),
}
function ikon:renderHook()
	local entity = ikon.renderEntity

	if (halo.RenderedEntity() == entity) then
		return
	end

	local w, h = ikon.curWidth * 64, ikon.curHeight * 64
	local x, y = 0, 0
	local tab

	if (ikon.info) then
		tab = {
			origin = ikon.info.pos,
			angles = ikon.info.ang,
			fov = ikon.info.fov,
			outline = ikon.info.outline,
			outCol = ikon.info.outlineColor
		}

		if (!tab.origin and !tab.angles and !tab.fov) then
			table.Merge(tab, PositionSpawnIcon(entity, entity:GetPos(), true))
		end
	else
		tab = PositionSpawnIcon(entity, entity:GetPos(), true)
	end

	-- Taking MDave's Tip
	xpcall(function()
			render.OverrideAlphaWriteEnable(true, true) -- some playermodel eyeballs will not render without this
			render.SetWriteDepthToDestAlpha(false)
			render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
			render.SuppressEngineLighting(true)
			render.Clear(0, 0, 0, 0, true, true)

			render.SetLightingOrigin(vector_origin)
			render.ResetModelLighting(200 / 255, 200 / 255, 200 / 255)
			render.SetColorModulation(1, 1, 1)

			for i = 0, 6 do
				local col = lightPositions[i]

				if (col) then
					render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
				end
			end

			if (tab.outline) then
				ix.util.ResetStencilValues()
				render.SetStencilEnable(true)
				render.SetStencilWriteMask(137) -- yeah random number to avoid confliction
				render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
				render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
				render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
			end

			--[[
				Add more effects on the Models!
			]]--
			if (ikon.info and ikon.info.drawHook) then
				ikon.info.drawHook(entity)
			end

			cam.Start3D(tab.origin, tab.angles, tab.fov, 0, 0, w, h)
				render.SetBlend(1)
				entity:DrawModel()
			cam.End3D()

			if (tab.outline) then
				render.PushRenderTarget(tex_effect)
				render.Clear(0, 0, 0, 0)
				render.ClearDepth()
				cam.Start2D()
					cam.Start3D(tab.origin, tab.angles, tab.fov, 0, 0, w, h)
							render.SetBlend(0)
							entity:DrawModel()

							render.SetStencilWriteMask(138) -- could you please?
							render.SetStencilTestMask(1)
							render.SetStencilReferenceValue(1)
							render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
							render.SetStencilPassOperation(STENCILOPERATION_KEEP)
							render.SetStencilFailOperation(STENCILOPERATION_KEEP)
							cam.Start2D()
								surface.SetDrawColor(tab.outCol or color_white)
								surface.DrawRect(0, 0, ScrW(), ScrH())
							cam.End2D()
					cam.End3D()
				cam.End2D()
				render.PopRenderTarget()

				render.SetBlend(1)
				render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)

				--[[
					Thanks for Noiwex
					NxServ.eu
				]]--
				cam.Start2D()
					surface.SetMaterial(mat_outline)
					surface.DrawTexturedRectUV(-2, 0, w, h, 0, 0, w / ikon.max, h / ikon.max)
					surface.DrawTexturedRectUV(2, 0, w, h, 0, 0, w / ikon.max, h / ikon.max)
					surface.DrawTexturedRectUV(0, 2, w, h, 0, 0, w / ikon.max, h / ikon.max)
					surface.DrawTexturedRectUV(0, -2, w, h, 0, 0, w / ikon.max, h / ikon.max)
				cam.End2D()

				render.SetStencilEnable(false)
			end

			render.SuppressEngineLighting(false)
			render.SetWriteDepthToDestAlpha(true)
			render.OverrideAlphaWriteEnable(false)
	end, function(message)
		print(message)
	end)
end

function ikon:showResult()
	local x, y = ScrW() / 2, ScrH() / 2
	local w, h = ikon.curWidth * 64, ikon.curHeight * 64

	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawOutlinedRect(x, 0, w, h)

	surface.SetMaterial(mat_outline)
	surface.DrawTexturedRect(x, 0, w, h)
end

--[[
	Renders the Icon with given arguments.
	returns nothing
]]--
function ikon:renderIcon(name, w, h, mdl, camInfo, updateCache)
	if (#ikon.requestList > 0) then return IKON_BUSY end
	if (ikon.requestList[name]) then return IKON_PROCESSING end
	if (!w or !h or !mdl) then return IKON_SOMETHINGWRONG end

	local capturedIcon
	ikon.curWidth = w or 1
	ikon.curHeight = h or 1
	ikon.renderModel = mdl

	if (camInfo) then
		ikon.info = camInfo
	end

	local w, h = ikon.curWidth * 64, ikon.curHeight * 64
	local sw, sh = ScrW(), ScrH()

	if (ikon.renderModel) then
		if (!IsValid(ikon.renderEntity)) then
			ikon.renderEntity = ClientsideModel(ikon.renderModel, RENDERGROUP_BOTH)
			ikon.renderEntity:SetNoDraw(true)
		end
	end

	ikon.renderEntity:SetModel(ikon.renderModel)

	local bone = ikon.renderEntity:LookupBone("ValveBiped.Bip01_Head1")

	if (bone) then
		ikon.renderEntity:SetEyeTarget(ikon.renderEntity:GetBonePosition(bone) + ikon.renderEntity:GetForward() * 32)
	end

	local oldRT = render.GetRenderTarget()
	render.PushRenderTarget(ikon.RT)

	ikon.rendering = true
		ikon:renderHook()
	ikon.rendering = nil

	capturedIcon = render.Capture({
		format = "png",
		alpha = true,
		x = 0,
		y = 0,
		w = w,
		h = h
	})

	file.Write("helix/icons/" .. schemaName .. "/" .. name .. ".png", capturedIcon)
	ikon.info = nil
	render.PopRenderTarget()

	if (updateCache) then
		local materialID = tostring(os.time())
		file.Write(materialID .. ".png", capturedIcon)

		timer.Simple(0, function()
			local material = Material("../data/".. materialID ..".png")

			ikon.cache[name]  = material
			file.Delete(materialID .. ".png")
		end)
	end

	ikon.requestList[name] = nil
	return true
end

--[[
	Gets rendered icon with given unique name.
	returns IMaterial
]]--
function ikon:GetIcon(name)
	if (ikon.cache[name]) then
		return ikon.cache[name] -- yeah return cache
	end

	if (file.Exists("helix/icons/" .. schemaName .. "/" .. name .. ".png", "DATA")) then
		ikon.cache[name] = Material("../data/helix/icons/" .. schemaName .. "/".. name ..".png")
		return ikon.cache[name] -- yeah return cache
	else
		return false -- retryd
	end
end

concommand.Add("ix_flushicon", function()
	local root = "helix/icons/" .. schemaName

	for _, v in pairs(file.Find(root .. "/*.png", "DATA")) do
		file.Delete(root .. "/" .. v)
	end

	ikon.cache = {}
end)

hook.Add("InitializedSchema", "updatePath", function()
	schemaName = Schema.folder
	ikon:init()
end)

if (schemaName) then
	ikon:init()
end
