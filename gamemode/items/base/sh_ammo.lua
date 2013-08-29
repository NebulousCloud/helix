--[[
List of ammo types:
	AR2 - Ammunition of the AR2/Pulse Rifle
	AlyxGun - (name in-game "5.7mm Ammo")
	Pistol - Ammunition of the 9MM Pistol 
	SMG1 - Ammunition of the SMG/MP7
	357 - Ammunition of the .357 Magnum
	XBowBolt - Ammunition of the Crossbow
	Buckshot - Ammunition of the Shotgun
	RPG_Round - Ammunition of the RPG/Rocket Launcher
	SMG1_Grenade - Ammunition for the SMG/MP7 grenade launcher (secondary fire)
	SniperRound
	SniperPenetratedRound - (name in-game ".45 Ammo")
	Grenade - Note you must be given the grenade weapon (weapon_frag) before you can throw grenades.
	Thumper - Ammunition cannot exceed 2 (name in-game "Explosive C4 Ammo")
	Gravity - (name in-game "4.6MM Ammo")
	Battery - (name in-game "9MM Ammo")
	GaussEnergy 
	CombineCannon - (name in-game ".50 Ammo")
	AirboatGun - (name in-game "5.56MM Ammo")
	StriderMinigun - (name in-game "7.62MM Ammo")
	HelicopterGun
	AR2AltFire - Ammunition of the AR2/Pulse Rifle 'combine ball' (secondary fire)
	slam - Like Grenade, but for the Selectable Lightweight Attack Munition (S.L.A.M)
--]]

BASE.name = "Base Ammo"
BASE.uniqueID = "base_ammo"
BASE.category = "Ammunition"
BASE.type = "ar2"
BASE.amount = 30
BASE.functions = {}
BASE.functions.Use = {
	run = function(itemTable, client, data)
		if (SERVER) then
			client:GiveAmmo(itemTable.amount, itemTable.type, true)
			client:EmitSound("items/ammo_pickup.wav")
		end
	end
}

--[[
	Example:

	ITEM.name = "9mm Bullets"
	ITEM.uniqueID = "ammo_9mm"
	ITEM.type = "pistol"
	ITEM.amount = 20
	ITEM.model = Model("models/items/boxsRounds.mdl")
--]]