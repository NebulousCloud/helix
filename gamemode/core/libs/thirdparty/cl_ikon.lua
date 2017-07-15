/*
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
*/

/*
	Default Tables.
*/

ikon = ikon or {}
ikon.dev = false
ikon.maxSize = 8 -- 8x8 (512^2) is max icon size. eitherwise, fuck off.

/*
	Initialize hooks and RT Screens.
	returns nothing
*/
local schemaName = schemaName or (SCHEMA and SCHEMA.folder)

local List = {}
function ikon:init()
	if (self.dev) then
		hook.Add("HUDPaint", "ikon_dev2", ikon.showResult)
	else
		hook.Remove("HUDPaint", "ikon_dev2")
	end	

	/*
		Being good at gmod is knowing all of stinky hacks
										- Black Tea (2017)
	*/
	OLD_HALOADD = OLD_HALOADD or halo.Add
	function halo.Add(...)
		-- shut the fuck up
		if (ikon.rendering != true) then
			OLD_HALOADD(...)
		end
	end

	OLD_HALORENDER = OLD_HALORENDER or halo.Render
	function halo.Render(...)
		-- shut the fuck up
		if (ikon.rendering != true) then
			OLD_HALORENDER(...)
		end
	end

	file.CreateDir("nsIcon")
	file.CreateDir("nsIcon/" .. schemaName)
end

if (schemaName) then
	ikon:init()
end

hook.Add("InitializedSchema", "updatePath", function()
	schemaName = SCHEMA.folder
	ikon:init()
end)

/*
	IKON Library Essential Material/Texture Declare
*/

local TEXTURE_FLAGS_CLAMP_S = 0x0004
local TEXTURE_FLAGS_CLAMP_T = 0x0008
ikon.max = ikon.maxSize * 64
ikon.RT = GetRenderTargetEx("nsIconRendered",
												ikon.max,
												ikon.max, 
												RT_SIZE_NO_CHANGE,
												MATERIAL_RT_DEPTH_SHARED,
												bit.bor(TEXTURE_FLAGS_CLAMP_S, TEXTURE_FLAGS_CLAMP_T),
												CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
 												IMAGE_FORMAT_RGBA8888)

local tex_effect = GetRenderTarget( "nsIconRenderedOutline",
												ikon.max,
												ikon.max)

local mat_outline = CreateMaterial("nsIconRenderedTemp","UnlitGeneric",{
	["$basetexture"] = tex_effect:GetName(),
	["$translucent"] = 1
})

/*
	Developer hook.
	returns nothing.
*/

-- Okay, sovietUnion wasn't pretty good name for the variation.
local lightPositions = {
	BOX_TOP = Color( 255, 255, 255 ),
	BOX_FRONT = Color( 255, 255, 255 ),
}
function ikon:renderHook()
	-- Go Away, GMOD Halo.
	if ( halo.RenderedEntity() == ikon.renderEntity ) then return end

	local w, h = ikon.curWidth * 64, ikon.curHeight * 64
	local x, y = 0, 0
	
	local tab
	if (ikon.info) then
		tab = 
		{
			origin = ikon.info.pos,
			angles = ikon.info.ang,
			fov = ikon.info.fov,
			outline = ikon.info.outline,
			outCol = ikon.info.outlineColor
		}
	else
		tab = PositionSpawnIcon(ikon.renderEntity, ikon.renderEntity:GetPos(), true)
	end

	-- Taking MDave's Tip
		xpcall(function()
				render.SetWriteDepthToDestAlpha( false )
				render.SuppressEngineLighting( true )
				render.Clear( 0, 0, 0, 0, true, true )

				render.SetLightingOrigin( Vector( 0, 0, 0 ) )
				render.ResetModelLighting( 200/255, 200/255, 200/255 )
				render.SetColorModulation( 1, 1, 1 )

				for i = 0, 6 do
					local col = lightPositions[i]
					if ( col ) then
						render.SetModelLighting( i, col.r / 255, col.g / 255, col.b / 255 )
					end
				end

				if (tab.outline) then
					render.SetStencilEnable(true)
					render.ClearStencil()
					render.SetStencilWriteMask(137) -- yeah random number to avoid confliction
					render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
					render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
					render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
				end
				
				/*
					Add more effects on the Models!
				*/
				if (ikon.info and ikon.info.drawHook) then
					ikon.info.drawHook(ikon.renderEntity)
				end

				cam.Start3D(tab.origin, tab.angles, tab.fov, 0, 0, w, h) 
					render.SetBlend(1)
					ikon.renderEntity:DrawModel()	
				cam.End3D()

				if (tab.outline) then
					render.PushRenderTarget( tex_effect )
					render.Clear(0,0,0,0)
					render.ClearDepth()
					cam.Start2D()
						cam.Start3D(tab.origin, tab.angles, tab.fov, 0, 0, w, h)
								render.SetBlend(0)
								ikon.renderEntity:DrawModel()	

								render.SetStencilWriteMask(138) -- could you please?
								render.SetStencilTestMask(1)
								render.SetStencilReferenceValue(1)
								render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
								render.SetStencilPassOperation(STENCILOPERATION_KEEP)
								render.SetStencilFailOperation(STENCILOPERATION_KEEP)
								cam.Start2D()
									surface.SetDrawColor( tab.outCol or color_white )
									surface.DrawRect( 0,0,ScrW(),ScrH() )
								cam.End2D()
						cam.End3D()
					cam.End2D()
					render.PopRenderTarget()
					
					render.SetBlend(1)
					render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
					
					/*
						Thanks for Noiwex
						NxServ.eu
					*/
					cam.Start2D()
						surface.SetMaterial( mat_outline )
						surface.DrawTexturedRectUV( -2,0, w, h, 0, 0, w/ikon.max, h/ikon.max)
						surface.DrawTexturedRectUV( 2,0, w, h, 0, 0, w/ikon.max, h/ikon.max)
						surface.DrawTexturedRectUV( 0,2, w, h, 0, 0, w/ikon.max, h/ikon.max)
						surface.DrawTexturedRectUV( 0,-2, w, h, 0, 0, w/ikon.max, h/ikon.max)
					cam.End2D()

					render.SetStencilEnable(false)
				end
				
				render.SuppressEngineLighting( false )
				render.SetWriteDepthToDestAlpha( true )
		end, function(rrer) print(rrer) end)
end

local testName = "renderedMeme"

function ikon:showResult()
	local x, y = ScrW()/2, ScrH()/2
	local w, h = ikon.curWidth * 64, ikon.curHeight * 64

	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawOutlinedRect(x, 0, w, h)

	surface.SetMaterial(mat_outline)
	surface.DrawTexturedRect(x, 0, w, h)
end

/*
	Renders the Icon with given arguments.
	returns nothing
*/
ikon.requestList = ikon.requestList or {}

IKON_BUSY = 1
IKON_PROCESSING = 0
IKON_SOMETHINGWRONG = -1
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
	local oldRT = render.GetRenderTarget()
	render.PushRenderTarget(ikon.RT)
	
	ikon.rendering = true
		ikon:renderHook()
	ikon.rendering = nil

	capturedIcon = render.Capture({
		['format'] = 'png',
		['alpha'] = true,
		['x'] = 0,
		['y'] = 0,
		['w'] = w,
		['h'] = h
	})
	file.Write("nsIcon/" .. schemaName .. "/" .. name .. ".png", capturedIcon)
	ikon.info = nil
	render.PopRenderTarget()

	-- lol blame your shit mate
	if (updateCache) then
		-- it's all your falut
		-- you rendered wrong shit
		-- if you know better solution, give me to it.
		local noshit = tostring(os.time())
		file.Write(noshit .. ".png", capturedIcon)

		timer.Simple(0, function()
		local wtf = Material("../data/".. noshit ..".png")

		ikon.cache[name]  = wtf
		file.Delete(noshit .. ".png")
		end)
		-- make small ass texture and put that thing in here?
	end
	ikon.requestList[name] = nil
	return true
end

/*
	Gets rendered icon with given unique name.
	returns IMaterial
*/
ikon.cache = ikon.cache or {}
function ikon:getIcon(name)
	if (ikon.cache[name]) then
		return ikon.cache[name] -- yeah return cache
	end

	if (file.Exists("nsIcon/" .. schemaName .. "/" .. name .. ".png", "DATA")) then
		ikon.cache[name] = Material("../data/nsIcon/" .. schemaName .. "/".. name ..".png")
		return ikon.cache[name] -- yeah return cache		
	else
		return false -- retryd
	end
end

-- use this command for memergency case.
-- like ruining everyone's dream.
concommand.Add("nut_flushicon", function()
	ikon.cache = {}
	file.Delete("nsIcon/" .. schemaName)
end)