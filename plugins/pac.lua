-- This Library is just for PAC3 Integration.
-- You must install PAC3 / PAC3_Lite to make this library works.
-- Currently, PAC3 Lite is more friendly to NutScript.
PLUGIN.name = "PAC3 Integration"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "More Upgraded, More well organized PAC3 Integration made by Black Tea"

nut.pac = nut.pac or {}
nut.pac.list = nut.pac.list or {}

local meta = FindMetaTable("Player")


-- this stores pac3 part information to plugin's table'
function nut.pac.registerPart(id, outfit)
	nut.pac.list[id] = outfit
end

-- Fixing the PAC3's default stuffs to fit on Nutscript.
if (CLIENT) then
	-- fixpac command. you can fix the PAC3 errors with this.
	nut.command.add("fixpac", {
		onRun = function(client, arguments)
			RunConsoleCommand("pac_restart")
		end,
		alias = {"새로고침"}
	})

	-- Disable few features of PAC3's feature.
	function PLUGIN:PluginLoaded()
		-- remove useless PAC3 shits

		hook.Remove("HUDPaint", "pac_InPAC3Editor")
		hook.Remove("InitPostEntity", "pace_autoload_parts")
	end

	-- Remove PAC3 LoadParts
	function pace.LoadParts(name, clear, override_part)
		-- fuck your loading, pay me money bitch
	end

	-- Prohibits players from deleting their own PAC3 outfit.
	concommand.Add("pac_clear_parts", function()
		RunConsoleCommand("pac_restart")
		--STOP BREAKING STUFFS!
	end)

	-- Reject unauthorized PAC3 submits
	net.Receive("pac_submit", function(_, ply)
		if (!ply:IsSuperAdmin()) then
			ply:notifyLocalized("illegalAccess")
		return end

		local data = pac.NetDeserializeTable()
		pace.HandleReceivedData(ply, data)
	end)

	-- You should be admin to access PAC3 editor.
	function PLUGIN:PrePACEditorOpen()
		local client = LocalPlayer()

		if (!client:IsSuperAdmin()) then
			return false
		end

		return true
	end
end

-- Get Player's PAC3 Parts.
function meta:getParts()
	if (!pac) then return end
	
	return self:getNetVar("parts", {})
end

if (SERVER) then
	-- PAC3 파트를 입힘과 동시에 플레이어에게 저장한다.
	function meta:addPart(uid, item)
		if (!pac) then
			ErrorNoHalt("NO PAC3!\n")
		return end
		
		local curParts = self:getParts()

		-- wear the parts.
		netstream.Start(player.GetAll(), "partWear", self, uid)
		curParts[uid] = true

		self:setNetVar("parts", curParts)
	end
	
	-- PAC3 파트를 벗김과 동시에 플레이어에게 저장한다.
	function meta:removePart(uid)
		if (!pac) then return end
		
		local curParts = self:getParts()

		-- remove the parts.
		netstream.Start(player.GetAll(), "partRemove", self, uid)
		curParts[uid] = nil

		self:setNetVar("parts", curParts)
	end

	-- 모든 PAC3파트를 없애고 저장된 테이블을 없앤다.
	-- 나가거나, 캐릭터를 바꾸거나, 파트를 모두 잃거나 할때 사용.
	function meta:resetParts()
		if (!pac) then return end
		
		netstream.Start(player.GetAll(), "partReset", self, self:getParts())
		self:setNetVar("parts", {})
	end

	-- 캐릭터를 바꿀때 PAC3 파트를 초기화한다.
	-- 새로 캐릭터를 로딩할때 가지고있는 인벤토리를 기반으로 다시 모든 파트를 입힌다.
	-- If player changes the char, remove all the vehicles on the server.
	function PLUGIN:PlayerLoadedChar(client, curChar, prevChar)
		-- If player is changing the char and the character ID is differs from the current char ID.
		if (prevChar and curChar:getID() != prevChar:getID()) then
			client:resetParts()
		end

		-- After resetting all PAC3 outfits, wear all equipped PAC3 outfits.
		if (curChar) then
			local inv = curChar:getInv()
			for k, v in pairs(inv:getItems()) do
				if (v:getData("equip") == true and v.pacData) then
					client:addPart(v.uniqueID, v)
				end
			end
		end
	end

	-- 처음 들어왔을때 서버에 있는 모든 플레이어의 PAC을 다시 입힌다.
	function PLUGIN:PlayerInitialSpawn(client)
		netstream.Start(client, "updatePAC")
	end

	-- 이건 넛스용 래그돌 지원기능.
	function PLUGIN:OnCharFallover(client, ragdoll, isFallen)
		if (client and ragdoll and client:IsValid() and ragdoll:IsValid() and client:getChar() and isFallen) then
			netstream.Start(player.GetAll(), "ragdollPAC", client, ragdoll, isFallen)
		end
	end
else
	-- 클라이언트사이드!

	-- 모든 플레이어의 PAC3 보관 데이터를 읽고 입힌다.
	netstream.Hook("updatePAC", function()
		if (!pac) then return end

		for k, v in ipairs(player.GetAll()) do
			local char = v:getChar()

			if (char) then
				local parts = client:getParts()

				for pacKey, pacValue in pairs(parts) do
					if (nut.pac.list[pacKey]) then
						v:AttachPACPart(nut.pac.list[pacKey])
					end
				end
			end
		end
	end)

	-- 특정 래그돌에 PAC를 입힌다.
	netstream.Hook("ragdollPAC", function(client, ragdoll, isFallen)
		if (!pac) then return end
		
		if (client and ragdoll) then
			local char = client:getChar()
			if (char) then
				local parts = char:getParts()

				pac.SetupENT(ragdoll)

				for pacKey, pacValue in pairs(parts) do
					if (nut.pac.list[pacKey]) then
						ragdoll:AttachPACPart(nut.pac.list[pacKey])
					end
				end
			end
		end
	end)

	-- PAC3 파트를  입힌다.
	netstream.Hook("partWear", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end
		
		local itemTable = nut.item.list[outfitID]
		local newPac = nut.pac.list[outfitID]

		if (nut.pac.list[outfitID]) then
			if (itemTable and itemTable.pacAdjust) then
				newPac = table.Copy(nut.pac.list[outfitID])
				newPac = itemTable:pacAdjust(newPac, wearer)
			end
	
			wearer:AttachPACPart(newPac)
		end
	end)

	-- PAC3 파트를 벗긴다.
	netstream.Hook("partRemove", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			wearer:RemovePACPart(nut.pac.list[outfitID])
		end
	end)

	-- PAC3 파트를 초기화한다.
	netstream.Hook("partReset", function(wearer, outfitList)
		for k, v in pairs(outfitList) do
			wearer:RemovePACPart(nut.pac.list[k])
		end
	end)

	-- 플레이어 메뉴 화면에 PAC3 파트들을 모두 입힌다.
	function PLUGIN:OnCharInfoSetup(infoPanel)
		if (pac and infoPanel.model) then
			-- Get the F1 ModelPanel.
			local mdl = infoPanel.model
			local ent = mdl.Entity

			-- If the ModelPanel's Entity is valid, setup PAC3 Function Table.
			if (ent and IsValid(ent)) then
				-- Setup function table.
				pac.SetupENT(ent)

				local parts = LocalPlayer():getParts()

				-- Wear current player's PAC3 Outfits on the ModelPanel's Clientside Model Entity.
				for k, v in pairs(parts) do
					if (nut.pac.list[k]) then
						ent:AttachPACPart(nut.pac.list[k])
					end
				end
				
				-- Overrride Model Drawing function of ModelPanel. (Function revision: 2015/01/05)
				-- by setting ent.forcedraw true, The PAC3 outfit will drawn on the model even if it's NoDraw Status is true.
				ent.forceDraw = true
			end
		end
	end

	-- PAC3 파트를 드로잉할때 모드를 설정한다.
	function PLUGIN:DrawNutModelView(panel, ent)
		if (LocalPlayer():getChar()) then
			if (pac) then
				pac.RenderOverride(ent, "opaque")
				pac.RenderOverride(ent, "translucent", true)
			end
		end
	end
end

-- 아이템에 저장된 PAC3 정보들을 모두 PAC3 파트 정보로 변환한다.
function PLUGIN:InitializedPlugins()
	local items = nut.item.list

	-- Get all items and If pacData is exists, register new outfit.
	for k, v in pairs(items) do
		if (v.pacData) then
			nut.pac.list[v.uniqueID] = v.pacData
		end
	end
end