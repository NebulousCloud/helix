--[[
	NetStream - 2.0.0

	Alexander Grist-Hucker
	http://www.revotech.org

	Credits to:
		thelastpenguin for pON.
		https://github.com/thelastpenguin/gLUA-Library/tree/master/pON
--]]


local type, error, pcall, pairs, _player = type, error, pcall, pairs, player;

if (!pon) then
	include("sh_pon.lua");
end;

AddCSLuaFile();

netstream = netstream or {};
netstream.stored = netstream.stored or {};

-- A function to split data for a data stream.
function netstream.Split(data)
	local index = 1;
	local result = {};
	local buffer = {};

	for i = 0, string.len(data) do
		buffer[#buffer + 1] = string.sub(data, i, i);

		if (#buffer == 32768) then
			result[#result + 1] = table.concat(buffer);
				index = index + 1;
			buffer = {};
		end;
	end;

	result[#result + 1] = table.concat(buffer);

	return result;
end;

-- A function to hook a data stream.
function netstream.Hook(name, Callback)
	netstream.stored[name] = Callback;
end;

if (SERVER) then
	util.AddNetworkString("NetStreamDS");

	-- A function to start a net stream.
	function netstream.Start(player, name, ...)
		local recipients = {};
		local bShouldSend = false;
		local bSendPVS = false;

		if (type(player) != "table") then
			if (!player) then
				player = _player.GetAll();
			elseif (type(player) == "Vector") then
				bSendPVS = true;
			else
				player = {player};
			end;
		end;

		if (type(player) != "Vector") then
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
			bShouldSend = true;
		end;

		local dataTable = {...};
		local encodedData = pon.encode(dataTable);

		if (encodedData and #encodedData > 0 and bShouldSend) then
			net.Start("NetStreamDS");
				net.WriteString(name);
				net.WriteUInt(#encodedData, 32);
				net.WriteData(encodedData, #encodedData);
			if (bSendPVS) then
				net.SendPVS(player);
			else
				net.Send(recipients);
			end;
		end;
	end;

	net.Receive("NetStreamDS", function(length, player)
		local NS_DS_NAME = net.ReadString();
		local NS_DS_LENGTH = net.ReadUInt(32);
		local NS_DS_DATA = net.ReadData(NS_DS_LENGTH);

		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
			player.nsDataStreamName = NS_DS_NAME;
			player.nsDataStreamData = "";

			if (player.nsDataStreamName and player.nsDataStreamData) then
				player.nsDataStreamData = NS_DS_DATA;

				if (netstream.stored[player.nsDataStreamName]) then
					local bStatus, value = pcall(pon.decode, player.nsDataStreamData);

					if (bStatus) then
						netstream.stored[player.nsDataStreamName](player, unpack(value));
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
	function netstream.Start(name, ...)
		local dataTable = {...};
		local encodedData = pon.encode(dataTable);

		if (encodedData and #encodedData > 0) then
			net.Start("NetStreamDS");
				net.WriteString(name);
				net.WriteUInt(#encodedData, 32);
				net.WriteData(encodedData, #encodedData);
			net.SendToServer();
		end;
	end;

	net.Receive("NetStreamDS", function(length)
		local NS_DS_NAME = net.ReadString();
		local NS_DS_LENGTH = net.ReadUInt(32);
		local NS_DS_DATA = net.ReadData(NS_DS_LENGTH);

		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
			if (netstream.stored[NS_DS_NAME]) then
				local bStatus, value = pcall(pon.decode, NS_DS_DATA);

				if (bStatus) then
					netstream.stored[NS_DS_NAME](unpack(value));
				else
					ErrorNoHalt("NetStream: '"..NS_DS_NAME.."'\n"..value.."\n");
				end;
			end;
		end;

		NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil;
	end);
end;
