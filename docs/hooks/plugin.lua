
-- luacheck: ignore 111

--[[--
Global hooks for general use.

Plugin hooks are regular hooks that can be used in your schema with `Schema:HookName(args)`, in your plugin with
`PLUGIN:HookName(args)`, or in your addon with `hook.Add("HookName", function(args) end)`.
]]
-- @hooks Plugin

--- Called as the last step before character creation to adjust the creation data payload.
-- @realm server
-- @player client Client that is creating the character.
-- @payload table The current payload data to be sent to character creation.
-- @newPayload table A table to be merged with the current payload table.
-- @usage function PLUGIN:AdjustCreationPayload(client, payload, newPayload)
-- 	newPayload.money = payload.attributes["stm"] -- Sets the characters initial money to the stamina attribute value.
-- end
function AdjustCreationPayload(client, payload, newPayload)
end

--- Called when stamina is being changed.
-- @realm shared
-- @player client Client that is draining/gaining stamina.
-- @baseOffset number The current stamina change offset.
-- @treturn number The new stamina change offset.
-- @usage function PLUGIN:AdjustStaminaOffset(client, baseOffset)
-- 	return baseOffset * 2 -- Drain/Regain stamina twice as fast.
-- end
function AdjustStaminaOffset(client, baseOffset)
end

--- Called before the business menu is added to the tab menu.
-- @realm client
-- @tabs table Empty table from the tab menu gui, allows adding more tabs from inside this function.
-- @treturn bool Whether or not to build the business menu for the client.
-- @usage function PLUGIN:BuildBusinessMenu(tabs)
-- 	return LocalPlayer():IsAdmin() -- Only builds the business menu for admins.
-- end
function BuildBusinessMenu(tabs)
end

--- Called before a message is auto formatted.
-- @realm server
-- @speaker player The speaker of the message.
-- @chatType string The chatType of the message.
-- @text string The unformatted text of the message.
-- @treturn bool Whether or not to allow auto formatting on the message.
-- @usage function PLUGIN:CanAutoFormatMessage(speaker, chatType, text)
-- 	return false -- Disable auto formatting outright.
-- end
function CanAutoFormatMessage(speaker, chatType, text)
end

--- Called before creating character info.
-- @realm client
-- @suppress table Table refrenced before creating parts of the character info.
-- @usage function PLUGIN:CanCreateCharacterInfo(suppress)
-- 	suppress.attributes = true -- Hides attributes from the 'you' tab.
-- end
function CanCreateCharacterInfo(suppress)
end

--- Called before drawing the ammo hud.
-- @realm client
-- @weapon entity The weapon the player currently is holding.
-- @treturn bool Whether or not to draw the ammo hud.
-- @usage function PLUGIN:CanDrawAmmoHUD(weapon)
-- 	if (weapon:GetClass() == "weapon_frag") then -- Hides the ammo hud when holding grenades.
--  	return false
-- 	end
-- end
function CanDrawAmmoHUD(weapon)
end

--- Called when the player tries to use abilities on the door, such as locking.
-- @realm shared
-- @client player The client trying something on the door.
-- @door entity The door entity itself.
-- @access number The access level used when called.
-- @treturn bool Whether or not to allow the client access.
-- @usage function PLUGIN:CanPlayerAccessDoor(client, door, access)
-- 	return true -- Always allow access.
-- end
function CanPlayerAccessDoor(client, door, access)
end

--- Called when the player attempts to drop an item.
-- @realm server
-- @client player The client trying to drop the item.
-- @item number The id of the item trying to be dropped.
-- @treturn bool Whether or not to allow the client to drop the item.
-- @usage function PLUGIN:CanPlayerDropItem(client, item)
-- 	return false -- Never allow dropping items.
-- end
function CanPlayerDropItem(client, item)
end

--- Called before salary is given to a player.
-- @realm server
-- @client player The client getting the salary.
-- @faction table The factionTable of the clients faction.
-- @treturn bool Whether or not to allow the client to earn salary.
-- @usage function PLUGIN:CanPlayerEarnSalary(client, faction)
-- 	return client:IsAdmin() -- Restricts earning salary to admins only.
-- end
function CanPlayerEarnSalary(client, faction)
end

--- Called when a player attempts to enter observer.
-- @realm server
-- @client player The client trying to enter observer.
-- @treturn bool Whether or not to allow the client to enter observer.
-- @usage function PLUGIN:CanPlayerEarnSalary(client)
-- 	return true -- Always allow observer.
-- end
function CanPlayerEnterObserver(client)
end

--- Called when the player attempts to equip an item.
-- @realm server
-- @client player The client trying to equip the item.
-- @item number The id of the item trying to be equipped.
-- @treturn bool Whether or not to allow the client to equip the item.
-- @usage function PLUGIN:CanPlayerEquipItem(client, item)
-- 	return client:IsAdmin() -- Restrict equipping items to admins only.
-- end
function CanPlayerEquipItem(client, item)
end

--- Called when the player attempts to hold an entity.
-- @realm server
-- @client player The client trying to hold the entity.
-- @entity entity The entity attempted to be held.
-- @treturn bool Whether or not to allow the client to hold the entity.
-- @usage function PLUGIN:CanPlayerHoldObject(client, entity)
-- 	return (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer holding objects.
-- end
function CanPlayerHoldObject(client, entity)
end

--- Called when the player attempts to interact with an entity.
-- @realm server
-- @client player The client trying to interact.
-- @entity entity The entity being interacted.
-- @option string The interaction option.
-- @data any Any data from passed along.
-- @treturn bool Whether or not to allow the client to interact with the entity.
-- @usage function PLUGIN:CanPlayerInteractEntity(client, entity, option, data)
-- 	return false -- Disallow interacting with any entity.
-- end
function CanPlayerInteractEntity(client, entity, option, data)
end

--- @realm server
function CanPlayerInteractItem(client, action, item, data)
end

--- @realm shared
function CanPlayerJoinClass(client, class, info)
end

--- @realm server
function CanPlayerKnock(client, entity)
end

--- @realm server
function CanPlayerOpenShipment(client, self)
end

--- @realm server
function CanPlayerSpawnContainer(client, model, entity)
end

--- @realm server
function CanPlayerTakeItem(client, item)
end

--- @realm server
function CanPlayerThrowPunch(client)
end

--- @realm server
function CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
end

--- @realm server
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

--- @realm server
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

--- @realm server
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

--- @realm shared
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

--- @realm shared
function OnCharacterDisconnect(client, character)
end

--- @realm shared
function OnCharacterFallover(client, entity, bFallenOver)
end

--- @realm client
function OnCharacterMenuCreated(panel)
end

--- @realm shared
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

--- @realm server
function PrePlayerMessageSend(client, chatType, message, anonymous)
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
