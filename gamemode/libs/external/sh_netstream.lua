--[[
	NetStream
	http://www.revotech.org
	
	Copyright (c) 2012 Alexander Grist-Hucker
	
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
	documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
	the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
	and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions 
	of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
	CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
	DEALINGS IN THE SOFTWARE.
	
	Credits to:
		Alexandru-Mihai Maftei aka Vercas for vON.
		https://dl.dropbox.com/u/1217587/GMod/Lua/von%20for%20GMOD.lua
--]]

if (!von) then
	include("sh_von.lua")
end

local type, error, pcall, pairs, AddCSLuaFile, require, _player = type, error, pcall, pairs, AddCSLuaFile, require, player

netstream = netstream or {};
netstream.stored = netstream.stored or {};

-- A function to hook a data stream.
function netstream.Hook(name, Callback)
	netstream.stored[name] = Callback;
end;

if (SERVER) then
	util.AddNetworkString("NetStreamDS");

	-- A function to start a net stream.
	function netstream.Start(player, name, data)
		local recipients = {};
		local bShouldSend = false;
		local sendPVS = false

		if (type(player) == "Vector") then
			sendPVS = true
		elseif (type(player) != "table") then
			if (player) then
				player = {player};
			end;
		end;
		
		if (player and !sendPVS) then
			for k, v in pairs(player) do
				if (type(v) == "Player") then
					recipients[#recipients + 1] = v;
					
					bShouldSend = true;
				elseif (type(k) == "Player") then
					recipients[#recipients + 1] = k;
				
					bShouldSend = true;
				end;
			end;
		else
			bShouldSend = true
		end

		if (data == nil) then
			data = "" -- Fill the data so the length isn't 0.
		end

		local dataTable = {data}
		local encodedData = von.serialize(dataTable);

		if (encodedData and #encodedData > 0 and bShouldSend) then
			net.Start("NetStreamDS");
				net.WriteString(name);
				net.WriteUInt(#encodedData, 32);
				net.WriteData(encodedData, #encodedData);
			if (player) then
				if (sendPVS) then
					net.SendPVS(player)
				else
					net.Send(recipients);
				end
			else
				net.Broadcast()
			end
		end;
	end;

	net.Receive("NetStreamDS", function(length, player)
		local NS_DS_NAME = net.ReadString();
		local NS_DS_LENGTH = net.ReadUInt(32);
		local NS_DS_DATA = net.ReadData(NS_DS_LENGTH);
		
		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
			if (!NS_DS_DATA) then
				error("NetStream: The data failed to decompress!");
				
				return;
			end;
			
			player.nsDataStreamName = NS_DS_NAME;
			player.nsDataStreamData = "";
			
			if (player.nsDataStreamName and player.nsDataStreamData) then
				player.nsDataStreamData = NS_DS_DATA;
								
				if (netstream.stored[player.nsDataStreamName]) then
					local bStatus, value = pcall(von.deserialize, player.nsDataStreamData);
					
					if (bStatus) then
						netstream.stored[player.nsDataStreamName](player, value[1]);
					else
						ErrorNoHalt("NetStream: '"..NS_DS_NAME.."'\n"..value.."\n");
					end;
				end;
				
				player.nsDataStreamName = nil;
				player.nsDataStreamData = nil;
			end;
		end;
		
		NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil;
	end);
else
	-- A function to start a net stream.
	function netstream.Start(name, data)
		data = data or ""
		local dataTable = {data};
		local encodedData = von.serialize(dataTable);
		
		if (encodedData and #encodedData > 0) then
			net.Start("NetStreamDS");
				net.WriteString(name);
				net.WriteUInt(#encodedData, 32);
				net.WriteData(encodedData, #encodedData);
			net.SendToServer();
		end;
	end;
	
	net.Receive("NetStreamDS", function(length)
		NS_DS_NAME = net.ReadString();
		NS_DS_LENGTH = net.ReadUInt(32);
		NS_DS_DATA = net.ReadData(NS_DS_LENGTH);
		
		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
			if (!NS_DS_DATA) then
				error("NetStream: The data failed to decompress!");
				
				return;
			end;
						
			if (netstream.stored[NS_DS_NAME]) then
				local bStatus, value = pcall(von.deserialize, NS_DS_DATA);
			
				if (bStatus) then
					netstream.stored[NS_DS_NAME](value[1]);
				else
					ErrorNoHalt("NetStream: '"..NS_DS_NAME.."'\n"..value.."\n");
				end;
			end;
		end;
		
		NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil;
	end);
end;