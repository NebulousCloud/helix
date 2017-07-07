/*
	BLACK TEA ICON LIBRARY FOR NUTSCRIPT 1.1
	VERSION: 0.4 - EXPERIMENTAL

	- FREE TO USE FOR ALL PROJECTS
*/


/*
	Default Tables.
*/
ikon = ikon or {}
ikon.dev = false
ikon.maxSize = 8 -- 8x8 (512^2) is max icon size. eitherwise, fuck off.


local TEXTURE_FLAGS_CLAMP_S = 0x0004
local TEXTURE_FLAGS_CLAMP_T = 0x0008
ikon.RT = GetRenderTargetEx("nsIconRendered",
												ikon.maxSize * 64,
												ikon.maxSize * 64, 
												RT_SIZE_NO_CHANGE,
												MATERIAL_RT_DEPTH_SHARED,
												bit.bor(TEXTURE_FLAGS_CLAMP_S, TEXTURE_FLAGS_CLAMP_T),
												CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
 												IMAGE_FORMAT_RGBA8888)

/*
	Developer hook.
	returns nothing.
*/

function ikon:renderHook(demo)
	local w, h = ikon.curWidth * 64, ikon.curHeight * 64
	
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawOutlinedRect(-1, -1, 0, 0) -- yeah fuck you

	local x, y = 0, 0
	
	local tab
	if (ikon.info) then
		tab = 
		{
			origin = ikon.info.pos,
			angles = ikon.info.ang,
			fov = ikon.info.fov,
		}
		if (!demo) then
			ikon.info = nil
		end
	else
		tab = PositionSpawnIcon(ikon.renderEntity, ikon.renderEntity:GetPos(), true)
	end

	cam.Start3D(tab.origin, tab.angles, tab.fov, 0, 0, w, h) -- ikon.FOV
		xpcall(function()
			-- maybe can add some stencil buffer for neat effects.
			render.SuppressEngineLighting( true )
			render.SetLightingOrigin( ikon.renderEntity:GetPos() )
			render.ResetModelLighting( 1, 1, 1 )
			render.SetColorModulation( 1, 1, 1 ) -- ikon.colorOverride
			render.SetBlend(0.999)

			ikon.renderEntity:DrawModel()

			render.SuppressEngineLighting( false )
		end, function(rrer) print(rrer) end)
	cam.End3D()
end

local testName = "renderedMeme"

function ikon:showResult()
	local x, y = ScrW()/2, ScrH()/2
	local w, h = ikon.curWidth * 64, ikon.curHeight * 64

	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawOutlinedRect(x, 0, w, h)

	local ikon = ikon:getIcon(testName)
	if (ikon) then
		surface.SetMaterial(ikon)
		surface.DrawTexturedRect(x, 0, 128, 64)
	end
end

/*
	Initialize hooks and RT Screens.
	returns nothing
*/
function ikon:init()
	if (self.dev) then
		hook.Add("HUDPaint", "ikon_dev", ikon.renderHook)
		hook.Add("HUDPaint", "ikon_dev2", ikon.showResult)
	
		ikon:renderIcon(testName,
		2,
		1,
		"models/weapons/w_357.mdl",
		{
			ang	= Angle(-10.678423881531, 226.70967102051, 0),
			fov	= 5.1215815407636,
			pos	= Vector(163.49705505371, 166.93612670898, -42.777050018311)
		},
		true)
	else
		hook.Remove("HUDPaint", "ikon_dev")
		hook.Remove("HUDPaint", "ikon_dev2")
	end	

	file.CreateDir("nsIcon")
end

/*
	Renders the Icon with given arguments.
	returns nothing
*/
/*
ikon.example = CreateMaterial("yourmomfaggot23", "UnlitGeneric", {
																	["$ignorez"] = 1,
																	["$vertexcolor"] = 1,
																	["$vertexalpha"] = 1,
																	["$nolod"] = 1,
																	["$alphatest"] = 1,
																	["$basetexture"] = ikon.RT:GetName()
																})*/
ikon.requestList = ikon.requestList or {}




IKON_PROCESSING = 0
IKON_DUMBFUCK = -1
function ikon:renderIcon(name, w, h, mdl, camInfo, updateCache)
	if (ikon.requestList[name]) then return IKON_PROCESSING end
	if (!w or !h or !mdl) then return IKON_DUMBFUCK end
	local akasic
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
	cam.Start2D()			
		-- make america more safer - Donald Trump
		xpcall(function()
			render.ClearDepth()
			render.Clear(255, 255, 255, 0)
		
			render.SetViewPort(0, 0, w, h)
				ikon:renderHook()
			render.SetViewPort(0, 0, sw, sh)
		end, function(rrer) print(rrer) end)				
	cam.End2D()
	
	akasic = render.Capture({
		['format'] = 'png',
		['alpha'] = true,
		['x'] = 0,
		['y'] = 0,
		['w'] = w,
		['h'] = h
	})
	file.Write("nsIcon/" .. name .. ".png", akasic)

	render.PopRenderTarget()

	-- lol blame your shit mate
	if (updateCache) then
		-- it's all your falut
		-- you rendered wrong shit
		-- if you know better solution, give me to it.
		local noshit = tostring(os.time())
		file.Write(noshit .. ".png", akasic)
		timer.Simple(0, function()
		local wtf = Material("../data/".. noshit ..".png")

		ikon.cache[name]  = wtf
		file.Delete(noshit .. ".png")
		end)
		-- make small ass texture and put that thing in here?
	end
	ikon.requestList[name] = nil
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

	if (file.Exists("nsIcon/" .. name .. ".png", "DATA")) then
		ikon.cache[name] = Material("../data/nsIcon/".. name ..".png")
		return ikon.cache[name] -- yeah return cache		
	else
		return false -- retryd
	end
end

ikon:init()