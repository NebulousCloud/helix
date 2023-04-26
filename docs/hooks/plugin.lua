
-- luacheck: ignore 111

--[[--
Global hooks for general use.

Plugin hooks are regular hooks that can be used in your schema with `Schema:HookName(args)`, in your plugin with
`PLUGIN:HookName(args)`, or in your addon with `hook.Add("HookName", function(args) end)`.
]]
-- @hooks Plugin

--- Adjusts the data used just before creating a new character.
-- @realm server
-- @player client Player that is creating the character
-- @tab payload Table of data to be used for character creation
-- @tab newPayload Table of data be merged with the current payload
-- @usage function PLUGIN:AdjustCreationPayload(client, payload, newPayload)
-- 	newPayload.money = payload.attributes["stm"] -- Sets the characters initial money to the stamina attribute value.
-- end
function AdjustCreationPayload(client, payload, newPayload)
end

--- Adjusts a player's current stamina offset amount. This is called when the player's stamina is about to be changed; every
-- `0.25` seconds on the server, and every frame on the client.
-- @realm shared
-- @player client Player whose stamina is changing
-- @number baseOffset Amount the stamina is changing by. This can be a positive or negative number depending if they are
-- exhausting or regaining stamina
-- @treturn number New offset to use
-- @usage function PLUGIN:AdjustStaminaOffset(client, baseOffset)
-- 	return baseOffset * 2 -- Drain/Regain stamina twice as fast.
-- end
function AdjustStaminaOffset(client, baseOffset)
end

--- Creates the business panel in the tab menu.
-- @realm client
-- @treturn bool Whether or not to create the business menu
-- @usage function PLUGIN:BuildBusinessMenu()
-- 	return LocalPlayer():IsAdmin() -- Only builds the business menu for admins.
-- end
function BuildBusinessMenu()
end

--- Whether or not a message can be auto formatted with punctuation and capitalization.
-- @realm server
-- @player speaker Player that sent the message
-- @string chatType Chat type of the message. This will be something registered with `ix.chat.Register` - like `ic`, `ooc`, etc.
-- @string text Unformatted text of the message
-- @treturn bool Whether or not to allow auto formatting on the message
-- @usage function PLUGIN:CanAutoFormatMessage(speaker, chatType, text)
-- 	return false -- Disable auto formatting outright.
-- end
function CanAutoFormatMessage(speaker, chatType, text)
end

--- Whether or not certain information can be displayed in the character info panel in the tab menu.
-- @realm client
-- @tab suppress Information to **NOT** display in the UI - modify this to change the behaviour. This is a table of the names of
-- some panels to avoid displaying. Valid names include:
--
-- - `time` - current in-game time
-- - `name` - name of the character
-- - `description` - description of the character
-- - `characterInfo` - entire panel showing a list of additional character info
-- - `faction` - faction name of the character
-- - `class` - name of the character's class if they're in one
-- - `money` - current money the character has
-- - `attributes` - attributes list for the character
--
-- Note that schemas/plugins can add additional character info panels.
-- @usage function PLUGIN:CanCreateCharacterInfo(suppress)
-- 	suppress.attributes = true -- Hides the attributes panel from the character info tab
-- end
function CanCreateCharacterInfo(suppress)
end

--- Whether or not the ammo HUD should be drawn.
-- @realm client
-- @entity weapon Weapon the player currently is holding
-- @treturn bool Whether or not to draw the ammo hud
-- @usage function PLUGIN:CanDrawAmmoHUD(weapon)
-- 	if (weapon:GetClass() == "weapon_frag") then -- Hides the ammo hud when holding grenades.
-- 		return false
-- 	end
-- end
function CanDrawAmmoHUD(weapon)
end

--- Called when a player tries to use abilities on the door, such as locking.
-- @realm shared
-- @player client The client trying something on the door.
-- @entity door The door entity itself.
-- @number access The access level used when called.
-- @treturn bool Whether or not to allow the client access.
-- @usage function PLUGIN:CanPlayerAccessDoor(client, door, access)
-- 	return true -- Always allow access.
-- end
function CanPlayerAccessDoor(client, door, access)
end

--- Whether or not a player is allowed to combine an item `other` into the given `item`.
-- @realm server
-- @player client Player attempting to combine an item into another
-- @number item instance ID of the item being dropped onto
-- @number other instance ID of the item being combined into the first item, this can be invalid due to it being from clientside
-- @treturn bool Whether or not to allow the player to combine the items
-- @usage function PLUGIN:CanPlayerCombineItem(client, item, other)
--		local otherItem = ix.item.instances[other]
--
--		if (otherItem and otherItem.uniqueID == "soda") then
--			return false -- disallow combining any item that has a uniqueID equal to `soda`
--		end
--	end
function CanPlayerCombineItem(client, item, other)
end

--- Whether or not a player is allowed to create a new character with the given payload.
-- @realm server
-- @player client Player attempting to create a new character
-- @tab payload Data that is going to be used for creating the character
-- @treturn bool Whether or not the player is allowed to create the character. This function defaults to `true`, so you
-- should only ever return `false` if you're disallowing creation. Otherwise, don't return anything as you'll prevent any other
-- calls to this hook from running.
-- @treturn string Language phrase to use for the error message
-- @treturn ... Arguments to use for the language phrase
-- @usage function PLUGIN:CanPlayerCreateCharacter(client, payload)
-- 	if (!client:IsAdmin()) then
-- 		return false, "notNow" -- only allow admins to create a character
-- 	end
-- end
-- -- non-admins will see the message "You are not allowed to do this right now!"
function CanPlayerCreateCharacter(client, payload)
end

--- Whether or not a player is allowed to drop the given `item`.
-- @realm server
-- @player client Player attempting to drop an item
-- @number item instance ID of the item being dropped
-- @treturn bool Whether or not to allow the player to drop the item
-- @usage function PLUGIN:CanPlayerDropItem(client, item)
-- 	return false -- Never allow dropping items.
-- end
function CanPlayerDropItem(client, item)
end

--- Whether or not a player can earn money at regular intervals. This hook runs only if the player's character faction has
-- a salary set - i.e `FACTION.pay` is set to something other than `0` for their faction.
-- @realm server
-- @player client Player to give money to
-- @tab faction Faction of the player's character
-- @treturn bool Whether or not to allow the player to earn salary
-- @usage function PLUGIN:CanPlayerEarnSalary(client, faction)
-- 	return client:IsAdmin() -- Restricts earning salary to admins only.
-- end
function CanPlayerEarnSalary(client, faction)
end

--- Whether or not the player is allowed to enter observer mode. This is allowed only for admins by default and can be
-- customized by server owners if the server is using a CAMI-compliant admin mod.
-- @realm server
-- @player client Player attempting to enter observer
-- @treturn bool Whether or not to allow the player to enter observer
-- @usage function PLUGIN:CanPlayerEnterObserver(client)
-- 	return true -- Always allow observer.
-- end
function CanPlayerEnterObserver(client)
end

--- Whether or not a player can equip the given `item`. This is called for items with `outfit`, `pacoutfit`, or `weapons` as
-- their base. Schemas/plugins can utilize this hook for their items.
-- @realm server
-- @player client Player attempting to equip the item
-- @tab item Item being equipped
-- @treturn bool Whether or not to allow the player to equip the item
-- @see CanPlayerUnequipItem
-- @usage function PLUGIN:CanPlayerEquipItem(client, item)
-- 	return client:IsAdmin() -- Restrict equipping items to admins only.
-- end
function CanPlayerEquipItem(client, item)
end

--- Whether or not a player is allowed to hold an entity with the hands SWEP.
-- @realm server
-- @player client Player attempting to hold an entity
-- @entity entity Entity being held
-- @treturn bool Whether or not to allow the player to hold the entity
-- @usage function PLUGIN:CanPlayerHoldObject(client, entity)
-- 	return !(client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer holding objects.
-- end
function CanPlayerHoldObject(client, entity)
end

--- Whether or not a player is allowed to interact with an entity's interaction menu if it has one.
-- @realm server
-- @player client Player attempting interaction
-- @entity entity Entity being interacted with
-- @string option Option selected by the player
-- @param data Any data passed with the interaction option
-- @treturn bool Whether or not to allow the player to interact with the entity
-- @usage function PLUGIN:CanPlayerInteractEntity(client, entity, option, data)
-- 	return false -- Disallow interacting with any entity.
-- end
function CanPlayerInteractEntity(client, entity, option, data)
end

--- Whether or not a player is allowed to interact with an item via an inventory action (e.g picking up, dropping, transferring
-- inventories, etc). Note that this is for an item *table*, not an item *entity*. This is called after `CanPlayerDropItem`
-- and `CanPlayerTakeItem`.
-- @realm server
-- @player client Player attempting interaction
-- @string action The action being performed
-- @param item Item's instance ID or item table
-- @param data Any data passed with the action
-- @treturn bool Whether or not to allow the player to interact with the item
-- @usage function PLUGIN:CanPlayerInteractItem(client, action, item, data)
-- 	return false -- Disallow interacting with any item.
-- end
function CanPlayerInteractItem(client, action, item, data)
end

--- Whether or not a plyer is allowed to join a class.
-- @realm shared
-- @player client Player attempting to join
-- @number class ID of the class
-- @tab info The class table
-- @treturn bool Whether or not to allow the player to join the class
-- @usage function PLUGIN:CanPlayerJoinClass(client, class, info)
-- 	return client:IsAdmin() -- Restrict joining classes to admins only.
-- end
function CanPlayerJoinClass(client, class, info)
end

--- Whether or not a player can knock on the door with the hands SWEP.
-- @realm server
-- @player client Player attempting to knock
-- @entity entity Door being knocked on
-- @treturn bool Whether or not to allow the player to knock on the door
-- @usage function PLUGIN:CanPlayerKnock(client, entity)
-- 	return false -- Disable knocking on doors outright.
-- end
function CanPlayerKnock(client, entity)
end

--- Whether or not a player can open a shipment spawned from the business menu.
-- @realm server
-- @player client Player attempting to open the shipment
-- @entity entity Shipment entity
-- @treturn bool Whether or not to allow the player to open the shipment
-- @usage function PLUGIN:CanPlayerOpenShipment(client, entity)
-- 	return client:Team() == FACTION_BMD -- Restricts opening shipments to FACTION_BMD.
-- end
function CanPlayerOpenShipment(client, entity)
end

--- Whether or not a player is allowed to spawn a container entity.
-- @realm server
-- @player client Player attempting to spawn a container
-- @string model Model of the container being spawned
-- @entity entity Container entity
-- @treturn bool Whether or not to allow the player to spawn the container
-- @usage function PLUGIN:CanPlayerSpawnContainer(client, model, entity)
-- 	return client:IsAdmin() -- Restrict spawning containers to admins.
-- end
function CanPlayerSpawnContainer(client, model, entity)
end

--- Whether or not a player is allowed to take an item and put it in their inventory.
-- @realm server
-- @player client Player attempting to take the item
-- @entity item Entity corresponding to the item
-- @treturn bool Whether or not to allow the player to take the item
-- @usage function PLUGIN:CanPlayerTakeItem(client, item)
-- 	return !(client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer taking items.
-- end
function CanPlayerTakeItem(client, item)
end

--- Whether or not the player is allowed to punch with the hands SWEP.
-- @realm shared
-- @player client Player attempting throw a punch
-- @treturn bool Whether or not to allow the player to punch
-- @usage function PLUGIN:CanPlayerThrowPunch(client)
-- 	return client:GetCharacter():GetAttribute("str", 0) > 0 -- Only allow players with strength to punch.
-- end
function CanPlayerThrowPunch(client)
end

--- Whether or not a player can trade with a vendor.
-- @realm server
-- @player client Player attempting to trade
-- @entity entity Vendor entity
-- @string uniqueID The uniqueID of the item being traded.
-- @bool isSellingToVendor If the client is selling to the vendor
-- @treturn bool Whether or not to allow the client to trade with the vendor
-- @usage function PLUGIN:CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
-- 	return false -- Disallow trading with vendors outright.
-- end
function CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
end

--- Whether or not a player can unequip an item.
-- @realm server
-- @player client Player attempting to unequip an item
-- @tab item Item being unequipped
-- @treturn bool Whether or not to allow the player to unequip the item
-- @see CanPlayerEquipItem
-- @usage function PLUGIN:CanPlayerUnequipItem(client, item)
-- 	return false -- Disallow unequipping items.
-- end
function CanPlayerUnequipItem(client, item)
end

--- @realm shared
function CanPlayerUseBusiness(client, uniqueID)
end

--- @realm shared
function CanPlayerUseCharacter(client, character)
end

--- @realm server
function CanPlayerUseDoor(client, entity)
end

--- @realm server
function CanPlayerUseVendor(activator)
end

--- @realm client
function CanPlayerViewInventory()
end

--- @realm server
function CanSaveContainer(entity, inventory)
end

--- @realm shared
function CanTransferItem(item, currentInv, oldInv)
end

--- @realm shared
function CharacterAttributeBoosted(client, character, attribID, boostID, boostAmount)
end

--- @realm shared
function CharacterAttributeUpdated(client, self, key, value)
end

--- @realm shared
function CharacterDeleted(client, id, isCurrentChar)
end

--- @realm shared
function CharacterHasFlags(self, flags)
end

--- @realm shared
function CharacterLoaded(character)
end

--- @realm server
function CharacterPostSave(character)
end

--- @realm shared
function CharacterPreSave(character)
end

--- @realm shared
function CharacterRecognized()
end

--- @realm server
function CharacterRestored(character)
end

--- @realm shared
function CharacterVarChanged(character, key, oldVar, value)
end

--- @realm shared
function CharacterVendorTraded(client, entity, uniqueID, isSellingToVendor)
end

--- @realm client
function ChatboxCreated()
end

--- @realm client
function ChatboxPositionChanged(x, y, width, height)
end

--- @realm client
function ColorSchemeChanged(color)
end

--- @realm server
function ContainerRemoved(container, inventory)
end

--- @realm client
function CreateCharacterInfo(panel)
end

--- @realm client
function CreateCharacterInfoCategory(panel)
end

--- @realm client
function CreateItemInteractionMenu(icon, menu, itemTable)
end

--- @realm client
function CreateMenuButtons(tabs)
end

--- @realm server
function CreateShipment(client, entity)
end

--- @realm server
function DatabaseConnected()
end

--- @realm server
function DatabaseConnectionFailed(error)
end

--- @realm shared
function DoPluginIncludes(path, pluginTable)
end

--- @realm client
function DrawCharacterOverview()
end

--- @realm client
function DrawHelixModelView(panel, entity)
end

--- @realm client
function DrawPlayerRagdoll(entity)
end

--- @realm client
function GetCharacterDescription(client)
end

--- @realm shared
function GetCharacterName(speaker, chatType)
end

--- @realm shared
function GetChatPrefixInfo(text)
end

--- @realm client
function GetCrosshairAlpha(curAlpha)
end

--- @realm shared
function GetDefaultAttributePoints(client, count)
end

--- @realm shared
function GetDefaultCharacterName(client, faction)
end

--- @realm shared
function GetMaxPlayerCharacter(client)
end

--- Returns the sound to emit from the player upon death. If nothing is returned then it will use the default male/female death
-- sounds.
-- @realm server
-- @player client Player that died
-- @treturn[1] string Sound to play
-- @treturn[2] bool `false` if a sound shouldn't be played at all
-- @usage function PLUGIN:GetPlayerDeathSound(client)
-- 	-- play impact sound every time someone dies
-- 	return "physics/body/body_medium_impact_hard1.wav"
-- end
-- @usage function PLUGIN:GetPlayerDeathSound(client)
-- 	-- don't play a sound at all
-- 	return false
-- end
function GetPlayerDeathSound(client)
end

--- @realm client
function GetPlayerEntityMenu(client, options)
end

--- @realm client
function GetPlayerIcon(speaker)
end

--- @realm server
function GetPlayerPainSound(client)
end

--- @realm shared
function GetPlayerPunchDamage(client, damage, context)
end

--- @realm server
function GetSalaryAmount(client, faction)
end

--- @realm client
function GetTypingIndicator(character, text)
end

--- Registers chat classes after the core framework chat classes have been registered. You should usually create your chat
-- classes in this hook - especially if you want to reference the properties of a framework chat class.
-- @realm shared
-- @usage function PLUGIN:InitializedChatClasses()
-- 	-- let's say you wanted to reference an existing chat class's color
-- 	ix.chat.Register("myclass", {
-- 		format = "%s says \"%s\"",
-- 		GetColor = function(self, speaker, text)
-- 			-- make the chat class slightly brighter than the "ic" chat class
-- 			local color = ix.chat.classes.ic:GetColor(speaker, text)
--
-- 			return Color(color.r + 35, color.g + 35, color.b + 35)
-- 		end,
-- 		-- etc.
-- 	})
-- end
-- @see ix.chat.Register
-- @see ix.chat.classes
function InitializedChatClasses()
end

--- @realm shared
function InitializedConfig()
end

--- @realm shared
function InitializedPlugins()
end

--- @realm shared
function InitializedSchema()
end

--- @realm server
function InventoryItemAdded(oldInv, inventory, item)
end

--- @realm server
function InventoryItemRemoved(inventory, item)
end

--- @realm shared
function IsCharacterRecognized(character, id)
end

--- @realm client
function IsPlayerRecognized(client)
end

--- @realm client
function IsRecognizedChatType(chatType)
end

--- @realm server
function LoadData()
end

--- @realm client
function LoadFonts(font, genericFont)
end

--- @realm client
function LoadIntro()
end

--- @realm client
function MenuSubpanelCreated(subpanelName, panel)
end

--- @realm client
function MessageReceived(client, info)
end

--- @realm client
function OnAreaChanged(oldID, newID)
end

--- @realm shared
function OnCharacterCreated(client, character)
end

--- @realm server
function OnCharacterDisconnect(client, character)
end

--- @realm server
function OnCharacterFallover(client, entity, bFallenOver)
end

--- Called when a character has gotten up from the ground.
-- @realm server
-- @player client Player that has gotten up
-- @entity ragdoll Ragdoll used to represent the player
function OnCharacterGetup(client, ragdoll)
end

--- @realm client
function OnCharacterMenuCreated(panel)
end

--- Called whenever an item entity has spawned in the world. You can access the entity's item table with
-- `entity:GetItemTable()`.
-- @realm server
-- @entity entity Spawned item entity
-- @usage function PLUGIN:OnItemSpawned(entity)
-- 	local item = entity:GetItemTable()
-- 	-- do something with the item here
-- end
function OnItemSpawned(entity)
end

--- @realm shared
function OnItemTransferred(item, curInv, inventory)
end

--- @realm client
function OnLocalVarSet(key, var)
end

--- @realm client
function OnPAC3PartTransferred(part)
end

--- @realm server
function OnPickupMoney(client, self)
end

--- @realm shared
function OnPlayerAreaChanged(client, oldID, newID)
end

--- @realm server
function OnPlayerObserve(client, state)
end

--- @realm server
function OnPlayerOptionSelected(client, callingClient, option)
end

--- @realm server
function OnPlayerPurchaseDoor(client, entity, bBuying, bCallOnDoorChild)
end

--- @realm server
function OnPlayerRestricted(client)
end

--- @realm server
function OnPlayerUnRestricted(client)
end

--- @realm server
function OnSavedItemLoaded(loadedItems)
end

--- @realm server
function OnWipeTables()
end

--- @realm shared
function PlayerEnterSequence(client, sequence, callback, time, bNoFreeze)
end

--- @realm server
function PlayerInteractEntity(client, entity, option, data)
end

--- @realm server
function PlayerInteractItem(client, action, item)
end

--- @realm server
function PlayerJoinedClass(client, class, oldClass)
end

--- @realm shared
function PlayerLeaveSequence(entity)
end

--- @realm server
function PlayerLoadedCharacter(client, character, currentChar)
end

--- @realm server
function PlayerLockedDoor(client, door, partner)
end

--- @realm server
function PlayerLockedVehicle(client, vehicle)
end

--- @realm server
function PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
end

--- @realm shared
function PlayerModelChanged(client, model)
end

--- @realm server
function PlayerStaminaGained(client)
end

--- @realm server
function PlayerStaminaLost(client)
end

--- @realm shared
function PlayerThrowPunch(client, trace)
end

--- @realm server
function PlayerUnlockedDoor(client, door, partner)
end

--- @realm server
function PlayerUnlockedVehicle(client, door)
end

--- @realm server
function PlayerUse(client, entity)
end

--- @realm server
function PlayerUseDoor(client, entity)
end

--- @realm shared
function PlayerWeaponChanged(client, weapon)
end

--- @realm shared
function PluginLoaded(uniqueID, pluginTable)
end

--- @realm shared
function PluginShouldLoad(uniqueID)
end

--- @realm shared
function PluginUnloaded(uniqueID)
end

--- @realm client
function PopulateCharacterInfo(client, character, tooltip)
end

--- @realm client
function PopulateEntityInfo(entity, tooltip)
end

--- @realm client
function PopulateHelpMenu(categories)
end

--- @realm client
function PopulateImportantCharacterInfo(entity, character, tooltip)
end

--- @realm client
function PopulateItemTooltip(tooltip, item)
end

--- @realm client
function PopulatePlayerTooltip(client, tooltip)
end

--- @realm client
function PopulateScoreboardPlayerMenu(client, menu)
end

--- @realm client
function PostChatboxDraw(width, height, alpha)
end

--- @realm client
function PostDrawHelixModelView(panel, entity)
end

--- @realm client
function PostDrawInventory(panel)
end

--- @realm server
function PostLoadData()
end

--- @realm server
function PostPlayerLoadout(client)
end

--- @realm server
function PostPlayerSay(client, chatType, message, anonymous)
end

--- @realm shared
function PostSetupActs()
end

--- @realm server
function PreCharacterDeleted(client, character)
end

--- @realm server
function PrePlayerLoadedCharacter(client, character, currentChar)
end

--- Called before a message sent by a player is processed to be sent to other players - i.e this is ran as early as possible
-- and before things like the auto chat formatting. Can be used to prevent the message from being sent at all.
-- @realm server
-- @player client Player sending the message
-- @string chatType Chat class of the message
-- @string message Contents of the message
-- @bool bAnonymous Whether or not the player is sending the message anonymously
-- @treturn bool Whether or not to prevent the message from being sent
-- @usage function PLUGIN:PrePlayerMessageSend(client, chatType, message, bAnonymous)
-- 	if (!client:IsAdmin()) then
-- 		return false -- only allow admins to talk in chat
-- 	end
-- end
function PrePlayerMessageSend(client, chatType, message, bAnonymous)
end

--- @realm server
function SaveData()
end

--- @realm client
function ScreenResolutionChanged(width, height)
end

--- @realm shared
function SetupActs()
end

--- @realm shared
function SetupAreaProperties()
end

--- @realm server
function ShipmentItemTaken(client, uniqueID, amount)
end

--- @realm client
function ShouldBarDraw(bar)
end

--- @realm server
function ShouldDeleteSavedItems()
end

--- @realm client
function ShouldDisplayArea(newID)
end

--- @realm client
function ShouldDrawCrosshair(client, weapon)
end

--- @realm client
function ShouldDrawItemSize(item)
end

--- @realm client
function ShouldHideBars()
end

--- Whether or not a character should be permakilled upon death. This is only called if the `permakill` server config is
-- enabled.
-- @realm server
-- @player client Player to permakill
-- @char character Player's current character
-- @entity inflictor Entity that inflicted the killing blow
-- @entity attacker Other player or entity that killed the player
-- @treturn bool `false` if the player should not be permakilled
-- @usage function PLUGIN:ShouldPermakillCharacter(client, character, inflictor, attacker)
-- 		if (client:IsAdmin()) then
-- 			return false -- all non-admin players will have their character permakilled
-- 		end
-- 	end
function ShouldPermakillCharacter(client, character, inflictor, attacker)
end

--- @realm server
function ShouldPlayerDrowned(v)
end

--- @realm server
function ShouldRemoveRagdollOnDeath(client)
end

--- @realm server
function ShouldRestoreInventory(characterID, inventoryID, inventoryType)
end

--- @realm client
function ShouldShowPlayerOnScoreboard(client)
end

--- @realm server
function ShouldSpawnClientRagdoll(client)
end

--- @realm client
function ShowEntityMenu(entity)
end

--- @realm client
function ThirdPersonToggled(oldValue, value)
end

--- @realm client
function UpdateCharacterInfo(panel, character)
end

--- @realm client
function UpdateCharacterInfoCategory(panel, character)
end

--- @realm server
function VoiceDistanceChanged(newValue)
end

--- @realm client
function WeaponCycleSound()
end

--- @realm client
function WeaponSelectSound(weapon)
end
