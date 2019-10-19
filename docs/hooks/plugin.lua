
-- luacheck: ignore 111

--[[--
Global hooks for general use.

Plugin hooks are regular hooks that can be used in your schema with `Schema:HookName(args)`, in your plugin with
`PLUGIN:HookName(args)`, or in your addon with `hook.Add("HookName", function(args) end)`.
]]
-- @hooks Plugin

--- @realm server
function AdjustCreationPayload(client, payload, newPayload)
end

--- @realm shared
function AdjustStaminaOffset(client, baseOffset)
end

--- @realm client
function BuildBusinessMenu(tabs)
end

--- @realm server
function CanAutoFormatMessage(speaker, chatType, text)
end

--- @realm client
function CanCreateCharacterInfo(suppress)
end

--- @realm client
function CanDrawAmmoHUD(weapon)
end

--- @realm shared
function CanPlayerAccessDoor(client, self, access)
end

--- @realm server
function CanPlayerDropItem(client, item)
end

--- @realm server
function CanPlayerEarnSalary(client, faction)
end

--- @realm server
function CanPlayerEnterObserver(client)
end

--- @realm server
function CanPlayerEquipItem(client, item)
end

--- @realm server
function CanPlayerHoldObject(client, entity)
end

--- @realm server
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

--- @realm shared
function PlayerMessageSend(client, chatType, message, anonymous)
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
