local playerMeta = FindMetaTable("Player")
if SERVER then
	function playerMeta:ResetPartModels()
		return self:SetNetVar( "parts", {} )
	end
	function playerMeta:GetPartModels()
		return self:GetNetVar( "parts", {} )
	end
	function playerMeta:AddPartModel(uid, data)
		local part = self:GetPartModels()
		if (type(data) != "table") then
			print('adding part model should be the modeldata table!')
			return
		end
		part[uid] = data
		self:SetNetVar("parts", part)
	end
	function playerMeta:RemovePartModel(uid)
		local part = self:GetPartModels()
		if (part[uid]) then
			part[uid] = nil
		end
		self:SetNetVar("parts", part)
	end
	function playerMeta:HasPartModel(uid)
		return self:GetPartModels()[uid]
	end
else
	function playerMeta:GetPartModels()
		return self:GetNetVar( "parts", {} )
	end
	local function CanDrawParts(client)
		return (client:IsValid() && client.character)
	end
	-- DRAWCODE MUST BE IMPROVED.
	-- AWWW SHIT
	-- I'm such a bad coder.
	function DrawPlayerParts(client)
		client.drawing = client.drawing or {}
		if (!CanDrawParts(client)) then return end

		-- For generic parts
		local models = client:GetPartModels()
		for k, v in pairs(models) do
			if (!client.drawing[k]) then -- If clientside part model is not exists.
				-- holla holla create model.
				client.drawing[k] = ClientsideModel( v.model, RENDERGROUP_BOTH )
				client.drawing[k]:SetNoDraw( true )
				client.drawing[k]:SetSkin( v.skin or 0 )
				client.drawing[k]:SetColor( v.color or color_white )
				client.drawing[k]:ManipulateBoneScale( 0, v.scale )
				if (v.scale) then
					local matrix = Matrix()
					matrix:Scale( (v.scale or Vector( 1, 1, 1 ))*(v.size or 1) )
					client.drawing[k]:EnableMatrix("RenderMultiply", matrix)
				end
				if (v.material) then
					client.drawing[k]:SetMaterial( v.material )
				end
			else
				-- update position and status.
				if (client:LookupBone(v.bone)) then
					local pos, ang = client:GetBonePosition(client:LookupBone(v.bone))
					local drawingmodel = client.drawing[k] -- localize
					pos = pos + ang:Forward()*v.position.x + ang:Up()*v.position.z + ang:Right()*-v.position.y
					local ang2 = ang
					ang2:RotateAroundAxis( ang:Right(), v.angle.pitch ) -- pitch
					ang2:RotateAroundAxis( ang:Up(),  v.angle.yaw )-- yaw
					ang2:RotateAroundAxis( ang:Forward(), v.angle.roll )-- roll
					drawingmodel:SetRenderOrigin( pos )
					drawingmodel:SetRenderAngles( ang )
					drawingmodel:DrawModel()
				end
			end
		end

		-- For Weapons( eww.. look at this code. )
		-- temp fix.
		for _, wep in pairs(client:GetWeapons()) do
			local class = wep:GetClass()
			local itemTable = nut.item.Get(class)
			if (itemTable and itemTable.wep_partdata) then
				local drawdat = itemTable.wep_partdata
				local uid = "w_"..class
				if (client:GetActiveWeapon():GetClass() != class) then
					if (!client.drawing[uid]) then -- If clientside part model is not exists.
						-- holla holla create model.
						client.drawing[uid] = ClientsideModel( drawdat.model, RENDERGROUP_BOTH )
						client.drawing[uid]:SetNoDraw( true )
						client.drawing[uid]:SetSkin( drawdat.skin or 0 )
						client.drawing[uid]:SetColor( drawdat.color or color_white )
						client.drawing[uid]:ManipulateBoneScale( 0, drawdat.scale )
						if (drawdat.scale) then
							local matrix = Matrix()
							matrix:Scale( (drawdat.scale or Vector( 1, 1, 1 ))*(drawdat.size or 1) )
							client.drawing[uid]:EnableMatrix("RenderMultiply", matrix)
						end
						if (drawdat.material) then
							client.drawing[uid]:SetMaterial( drawdat.material )
						end
					else
						-- update position and status.
						if (client:LookupBone(drawdat.bone)) then
							local pos, ang = client:GetBonePosition( client:LookupBone( drawdat.bone ) )
							local drawingmodel = client.drawing[uid] -- localize
							pos = pos + ang:Forward()*drawdat.position.x + ang:Up()*drawdat.position.z + ang:Right()*-drawdat.position.y
							local ang2 = ang
							ang2:RotateAroundAxis( ang:Right(), drawdat.angle.pitch ) -- pitch
							ang2:RotateAroundAxis( ang:Up(),  drawdat.angle.yaw )-- yaw
							ang2:RotateAroundAxis( ang:Forward(), drawdat.angle.roll )-- roll
							drawingmodel:SetRenderOrigin( pos )
							drawingmodel:SetRenderAngles( ang )
							drawingmodel:DrawModel()
						end
					end
				else
					if (client.drawing[uid]) then -- If clientside part model is exists.
						client.drawing[uid]:Remove()
						client.drawing[uid] = nil
					end
				end
			end
		end


	end
	hook.Add( "PostPlayerDraw", "Nut_BlackTea_PartDrawer", DrawPlayerParts ) -- JVS, thanks for letting me know this awesome hook.
end