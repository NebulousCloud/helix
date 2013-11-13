local PLUGIN = PLUGIN

function PLUGIN:PlayerLoadedChar(client)
	timer.Create( "nut.Attachment_Initialize", 1, 1, function()
		client:UpdateWeaponAttachments();
		client.EnableSwitchUpdater = true;
	end);
end;


function PLUGIN:PlayerSwitchWeapon( client, wepold, wepnew )
	if ( client.EnableSwitchUpdater ) then
		client:UpdateWeaponAttachments();
	end;
end;
