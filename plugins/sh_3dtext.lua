local PLUGIN = PLUGIN
PLUGIN.name = "3D Text"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds 3D text that can be placed anywhere."
PLUGIN.text = PLUGIN.text or {}

if (SERVER) then
	util.AddNetworkString("nut_TextData")
	util.AddNetworkString("nut_TextRemove")

	function PLUGIN:PlayerLoadedData(client)
		for k, v in pairs(self.text) do
			net.Start("nut_TextData")
				net.WriteVector(v.pos)
				net.WriteAngle(v.angle)
				net.WriteString(v.text)
			net.Send(client)
		end
	end
else
	net.Receive("nut_TextData", function(length)
		local position = net.ReadVector()
		local angle = net.ReadAngle()
		local text = net.ReadString()

		PLUGIN.text[#PLUGIN.text + 1] = {pos = position, angle = angle, text = text}
	end)

	function PLUGIN:PostDrawTranslucentRenderables()
		local position = LocalPlayer():GetPos()

		for i = 1, #self.text do
			local data = self.text[i]

			if (position:Distance(data) <= 1024) then
				--cam.Start3D2D(data.pos, data.angle, 0.25)
			end
		end
	end
end