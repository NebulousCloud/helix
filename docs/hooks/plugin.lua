
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
--     newPayload.money = payload.attributes["stm"] -- Sets the characters initial money to the stamina attribute value.
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
--     return baseOffset * 2 -- Drain/Regain stamina twice as fast.
-- end
function AdjustStaminaOffset(client, baseOffset)
end

--- Creates the business panel in the tab menu.
-- @realm client
-- @treturn bool Whether or not to create the business menu
-- @usage function PLUGIN:BuildBusinessMenu()
--     return LocalPlayer():IsAdmin() -- Only builds the business menu for admins.
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
--     return false -- Disable auto formatting outright.
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
--     suppress.attributes = true -- Hides the attributes panel from the character info tab
-- end
function CanCreateCharacterInfo(suppress)
end

--- Whether or not the ammo HUD should be drawn.
-- @realm client
-- @entity weapon Weapon the player currently is holding
-- @treturn bool Whether or not to draw the ammo hud
-- @usage function PLUGIN:CanDrawAmmoHUD(weapon)
--     if (weapon:GetClass() == "weapon_frag") then -- Hides the ammo hud when holding grenades.
--         return false
--     end
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
--     return true -- Always allow access.
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
--        local otherItem = ix.item.instances[other]
--
--        if (otherItem and otherItem.uniqueID == "soda") then
--            return false -- disallow combining any item that has a uniqueID equal to `soda`
--        end
--    end
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
--     if (!client:IsAdmin()) then
--         return false, "notNow" -- only allow admins to create a character
--     end
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
--     return false -- Never allow dropping items.
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
--     return client:IsAdmin() -- Restricts earning salary to admins only.
-- end
function CanPlayerEarnSalary(client, faction)
end

--- Whether or not the player is allowed to enter observer mode. This is allowed only for admins by default and can be
-- customized by server owners if the server is using a CAMI-compliant admin mod.
-- @realm server
-- @player client Player attempting to enter observer
-- @treturn bool Whether or not to allow the player to enter observer
-- @usage function PLUGIN:CanPlayerEnterObserver(client)
--     return true -- Always allow observer.
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
--     return client:IsAdmin() -- Restrict equipping items to admins only.
-- end
function CanPlayerEquipItem(client, item)
end

--- Whether or not a player is allowed to hold an entity with the hands SWEP.
-- @realm server
-- @player client Player attempting to hold an entity
-- @entity entity Entity being held
-- @treturn bool Whether or not to allow the player to hold the entity
-- @usage function PLUGIN:CanPlayerHoldObject(client, entity)
--     -- Disallow players in observer from holding objects.
--     return client:GetMoveType() != MOVETYPE_NOCLIP
-- end
function CanPlayerHoldObject(client, entity)
end

--- Whether or not a player is allowed to interact with an entity's interaction menu if it has one.
-- @realm server
-- @player client Player attempting interaction
-- @entity entity Entity being interacted with
-- @string option Option selected by the player
-- @param data any Any data passed with the interaction option
-- @treturn bool Whether or not to allow the player to interact with the entity
-- @usage function PLUGIN:CanPlayerInteractEntity(client, entity, option, data)
--  if (entity:GetClass() == "my_big_entity" and entity:GetPos():Distance(client:GetPos()) < 192) then
--    return true -- Force allow interacting if within larger than default interact range of large entity
--  end
--
--     if (client:GetNetVar("drunk")) then
--    return false -- Disallow interacting with an entity while drunk
--     end
-- end
function CanPlayerInteractEntity(client, entity, option, data)
end

--- Whether or not a player is allowed to interact with an item via an inventory action (e.g picking up, dropping, transferring
-- inventories, etc). Note that this is for an item *table*, not an item *entity*. This is called after `CanPlayerDropItem`
-- and `CanPlayerTakeItem`.
-- @realm server
-- @player client Player attempting interaction
-- @string action The action being performed
-- @param item any Item's instance ID or item table
-- @param data any Any data passed with the action
-- @treturn bool Whether or not to allow the player to interact with the item
-- @usage function PLUGIN:CanPlayerInteractItem(client, action, item, data)
--     return false -- Disallow interacting with any item.
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
--     return client:IsAdmin() -- Restrict joining classes to admins only.
-- end
function CanPlayerJoinClass(client, class, info)
end

--- Whether or not a player can knock on the door with the hands SWEP.
-- @realm server
-- @player client Player attempting to knock
-- @entity entity Door being knocked on
-- @treturn bool Whether or not to allow the player to knock on the door
-- @usage function PLUGIN:CanPlayerKnock(client, entity)
--     return false -- Disable knocking on doors outright.
-- end
function CanPlayerKnock(client, entity)
end

--- Whether or not a player can open a shipment spawned from the business menu.
-- @realm server
-- @player client Player attempting to open the shipment
-- @entity entity Shipment entity
-- @treturn bool Whether or not to allow the player to open the shipment
-- @usage function PLUGIN:CanPlayerOpenShipment(client, entity)
--     return client:Team() == FACTION_BMD -- Restricts opening shipments to FACTION_BMD.
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
--     return client:IsAdmin() -- Restrict spawning containers to admins.
-- end
function CanPlayerSpawnContainer(client, model, entity)
end

--- Whether or not a player is allowed to take an item and put it in their inventory.
-- @realm server
-- @player client Player attempting to take the item
-- @entity item Entity corresponding to the item
-- @treturn bool Whether or not to allow the player to take the item
-- @usage function PLUGIN:CanPlayerTakeItem(client, item)
--     return !(client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer taking items.
-- end
function CanPlayerTakeItem(client, item)
end

--- Whether or not the player is allowed to punch with the hands SWEP.
-- @realm shared
-- @player client Player attempting throw a punch
-- @treturn bool Whether or not to allow the player to punch
-- @usage function PLUGIN:CanPlayerThrowPunch(client)
--     return client:GetCharacter():GetAttribute("str", 0) > 0 -- Only allow players with strength to punch.
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
--     return false -- Disallow trading with vendors outright.
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
--     return false -- Disallow unequipping items.
-- end
function CanPlayerUnequipItem(client, item)
end

--- Whether or not a player can buy an item from the business menu.
-- @realm shared
-- @player client Player that uses a business menu
-- @string uniqueID The uniqueID of the business menu item
-- @treturn bool Whether or not to allow the player to buy an item from the business menu
-- @usage function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
--  return false -- Disallow buying from the business menu.
-- end
function CanPlayerUseBusiness(client, uniqueID)
end

--- Whether or not a player can use a character.
-- @realm shared
-- @player client Player that wants to use a character
-- @char character Character that a player wants to use
-- @treturn bool Whether or not to allow the player to load a character
-- @usage function PLUGIN:CanPlayerUseCharacter(client, character)
--     return false -- Disallow using any character.
-- end
function CanPlayerUseCharacter(client, character)
end

--- Whether or not a player can use a door.
-- @realm server
-- @player client Player that wants to use a door
-- @entity entity Door that a player wants to use
-- @treturn bool Whether or not to allow the player to use a door
-- @usage function PLUGIN:CanPlayerUseDoor(client, entity)
--     return false -- Disallow using any door.
-- end
function CanPlayerUseDoor(client, entity)
end

--- Determines whether a player can use a vendor.
-- @realm server
-- @player activator The player attempting to use the vendor
-- @entity vendor The vendor entity being used
-- @treturn bool Returns false if the player can't use the vendor
-- @usage function PLUGIN:CanPlayerUseVendor(activator, vendor)
--     -- Example: only allow when close enough
--     return activator:GetPos():Distance(vendor:GetPos()) < 128
-- end
function CanPlayerUseVendor(activator, vendor)
end

--- Whether or not a player can view his inventory.
-- @realm client
-- @treturn bool Whether or not to allow the player to view his inventory
-- @usage function PLUGIN:CanPlayerViewInventory()
--     return false -- Prevent player from viewing his inventory.
-- end
function CanPlayerViewInventory()
end

--- Whether or not to save a container.
-- @realm server
-- @entity entity Container entity to save
-- @tab inventory Container inventory
-- @treturn bool Whether or not to save a container
-- @usage function PLUGIN:CanSaveContainer(entity, inventory)
--  return false -- Disallow saving any container.
-- end
function CanSaveContainer(entity, inventory)
end

--- Whether or not an item can be transferred between inventories.
-- @realm shared
-- @tab item Item instance table or ID
-- @tab currentInv Destination inventory
-- @tab oldInv Source inventory (the inventory item is currently in)
-- @treturn bool Return false to disallow the transfer
-- @usage function PLUGIN:CanTransferItem(item, currentInv, oldInv)
--     -- Prevent transferring quest items to any other inventory
--     if (istable(item) and item.isQuestItem) then
--         return false
--     end
-- end
function CanTransferItem(item, currentInv, oldInv)
end

--- Called when a character attribute receives a temporary boost.
-- @realm shared
-- @player client Player owning the character
-- @char character Character that got the boost
-- @string attribID Unique ID of the attribute being boosted
-- @string boostID Unique ID/name of the boost source (e.g. item or effect)
-- @number boostAmount Amount of the boost applied
-- @usage function PLUGIN:CharacterAttributeBoosted(client, character, attribID, boostID, boostAmount)
--     if (attribID == "stm") then
--         client:Notify("You feel energized! (+" .. boostAmount .. " stamina)")
--     end
-- end
function CharacterAttributeBoosted(client, character, attribID, boostID, boostAmount)
end

--- Called when a character attribute value is updated.
-- @realm shared
-- @player client Player owning the character
-- @char self Character whose attribute changed
-- @string key Attribute unique ID
-- @number value New value of the attribute
-- @usage function PLUGIN:CharacterAttributeUpdated(client, self, key, value)
--     if (key == "str" and value >= 10) then
--         client:Notify("You feel exceptionally strong.")
--     end
-- end
function CharacterAttributeUpdated(client, self, key, value)
end

--- Called after a character has been deleted.
-- @realm shared
-- @player client Owner of the deleted character
-- @number id Deleted character ID
-- @bool isCurrentChar If the deleted character was the one currently in use
-- @usage function PLUGIN:CharacterDeleted(client, id, isCurrentChar)
--     ix.log.Add(client, "charDeleted", id, isCurrentChar)
-- end
function CharacterDeleted(client, id, isCurrentChar)
end

--- Called when checking if a character has certain flags.
-- @realm shared
-- @char self Character to check
-- @string flags Flags string to verify
-- @treturn bool Return false to force missing flags
-- @usage function PLUGIN:CharacterHasFlags(self, flags)
--     -- Treat admins as if they had all flags
--     local client = self:GetPlayer()
--     if (IsValid(client) and client:IsAdmin()) then
--         return true
--     end
-- end
function CharacterHasFlags(self, flags)
end

--- Called when a character has finished loading.
-- @realm shared
-- @char character Character that finished loading
-- @usage function PLUGIN:CharacterLoaded(character)
--     local client = character:GetPlayer()
--     if (IsValid(client)) then
--         client:Notify("Welcome back, " .. character:GetName() .. "!")
--     end
-- end
function CharacterLoaded(character)
end

--- Called when a character was saved.
-- @realm server
-- @char character that was saved
-- @usage function PLUGIN:CharacterPostSave(character)
--     print("Character saved: " .. tostring(character:GetID()))
-- end
function CharacterPostSave(character)
end

--- Called before a character is saved to the database.
-- @realm shared
-- @char character Character that will be saved
-- @usage function PLUGIN:CharacterPreSave(character)
--     -- Example: sanitize a custom field before saving
--     local desc = character:GetDescription() or ""
--     character:SetDescription(string.Trim(desc))
-- end
function CharacterPreSave(character)
end

--- Called when character recognition status changes.
-- @realm shared
-- @usage function PLUGIN:CharacterRecognized()
--     print("Character has been recognized by someone!")
-- end
function CharacterRecognized()
end

--- Called when a character was restored.
-- @realm server
-- @char character that was restored
-- @usage function PLUGIN:CharacterRestored(character)
--     print("Character restored: " .. tostring(character:GetID()))
-- end
function CharacterRestored(character)
end

--- Called when a character variable changes.
-- @realm shared
-- @char character Character whose var changed
-- @string key Variable key name
-- @param oldVar any Previous value
-- @param value any New value
-- @usage function PLUGIN:CharacterVarChanged(character, key, oldVar, value)
--     if (key == "name") then
--         local client = character:GetPlayer()
--         if (IsValid(client)) then
--          client:Notify("Name changed to " .. tostring(value))
--      end
--     end
-- end
function CharacterVarChanged(character, key, oldVar, value)
end

--- Called after a player has completed a vendor trade.
-- @realm shared
-- @player client Player that traded
-- @entity entity Vendor entity
-- @string uniqueID Unique ID of item being traded
-- @bool isSellingToVendor True if the player sold to the vendor, false if bought
-- @usage function PLUGIN:CharacterVendorTraded(client, entity, uniqueID, isSellingToVendor)
--     ix.log.Add(client, "vendorTrade", uniqueID, isSellingToVendor)
-- end
function CharacterVendorTraded(client, entity, uniqueID, isSellingToVendor)
end

--- Called when the chatbox UI has been created.
-- @realm client
-- @usage function PLUGIN:ChatboxCreated()
--     -- Apply a custom theme or register extra tabs
--     ix.chatbox.RegisterTab("server", function(panel) panel:SetTitle("Server") end)
-- end
function ChatboxCreated()
end

--- Called when the chatbox position or size changes.
-- @realm client
-- @number x New x position
-- @number y New y position
-- @number width New width
-- @number height New height
-- @usage function PLUGIN:ChatboxPositionChanged(x, y, width, height)
--     print("Chatbox moved to " .. x .. ", " .. y .. " with size " .. width .. "x" .. height)
-- end
function ChatboxPositionChanged(x, y, width, height)
end

--- Called when the Helix color scheme changes.
-- @realm client
-- @param color Color New base color
-- @usage function PLUGIN:ColorSchemeChanged(color)
--     -- Recompute cached tints
--     print("New color scheme applied: " .. tostring(color))
-- end
function ColorSchemeChanged(color)
end

--- Called when a container was removed.
-- @realm server
-- @entity container Container that was removed
-- @tab inventory Container inventory
function ContainerRemoved(container, inventory)
end

--- Build custom character info entries.
-- @realm client
-- @param panel Panel Character info panel to populate
-- @usage function PLUGIN:CreateCharacterInfo(panel)
--     print("Character info panel created: " .. tostring(panel))
-- end
function CreateCharacterInfo(panel)
end

--- Build character info category sections.
-- @realm client
-- @param panel Panel Category parent panel to populate
-- @usage function PLUGIN:CreateCharacterInfoCategory(panel)
--     print("Character info category created: " .. tostring(panel))
-- end
function CreateCharacterInfoCategory(panel)
end

--- Called when creating the right-click interaction menu for an item.
-- @realm client
-- @param icon Panel Icon panel for the item
-- @param menu Panel Context menu to add options to
-- @tab itemTable Item table being interacted with
-- @treturn bool Return true to prevent the default menu from being created
-- @usage function PLUGIN:CreateItemInteractionMenu(icon, menu, itemTable)
--     menu:AddOption("Custom Action", function()
--         -- do something with itemTable
--     end)
-- end
function CreateItemInteractionMenu(icon, menu, itemTable)
end

--- Add or modify buttons in the tab menu.
-- @realm client
-- @tab tabs Table of buttons to add to; modify to insert custom tabs
-- @usage function PLUGIN:CreateMenuButtons(tabs)
--     tabs["rules"] = function(container)
--         local lbl = container:Add("DLabel")
--         lbl:SetText("Be nice to others.")
--     end
-- end
function CreateMenuButtons(tabs)
end

--- Called when a shipment was created.
-- @realm server
-- @player client Player that ordered the shipment
-- @entity entity Shipment entity
-- @usage function PLUGIN:CreateShipment(client, entity)
--     -- Tag shipment with owner for later checks
--     entity:SetNWEntity("shipment_owner", client)
-- end
function CreateShipment(client, entity)
end

--- Called when a server has connected to the database.
-- @realm server
-- @usage function PLUGIN:DatabaseConnected()
--     print("Database connection established.")
-- end
function DatabaseConnected()
end

--- Called when a server failed to connect to the database.
-- @realm server
-- @string error Error that prevented server from connecting to the database
-- @usage function PLUGIN:DatabaseConnectionFailed(error)
--     print("Database connection failed: " .. tostring(error))
-- end
function DatabaseConnectionFailed(error)
end

--- Called when including plugin files; useful for custom include logic.
-- @realm shared
-- @string path Root path of the plugin
-- @tab pluginTable Plugin table (PLUGIN)
-- @usage function PLUGIN:DoPluginIncludes(path, pluginTable)
--     -- Example: include optional file if present
--     local extra = path .. "/sh_extra.lua"
--     if (file.Exists(extra, "LUA")) then
--         ix.util.Include(extra)
--     end
-- end
function DoPluginIncludes(path, pluginTable)
end

--- Draw the character overview screen.
-- @realm client
-- @usage function PLUGIN:DrawCharacterOverview()
--     -- Custom drawing code here
-- end
function DrawCharacterOverview()
end

--- Customize the model view rendering in character screens.
-- @realm client
-- @param panel Panel Model view panel
-- @entity entity Model entity being drawn
-- @usage function PLUGIN:DrawHelixModelView(panel, entity)
--     -- Custom drawing code here
-- end
function DrawHelixModelView(panel, entity)
end

--- Called to draw additional effects on player ragdolls.
-- @realm client
-- @entity entity Ragdoll entity
-- @usage function PLUGIN:DrawPlayerRagdoll(entity)
--     -- Outline ragdoll if it's your own
--     if (entity:GetNetVar("player") == LocalPlayer()) then
--         -- custom outline logic
--     end
-- end
function DrawPlayerRagdoll(entity)
end

--- Returns a formatted character description for display.
-- @realm client
-- @player client Player owning the character
-- @treturn string Formatted description text
-- @usage function PLUGIN:GetCharacterDescription(client)
--     local char = client:GetCharacter()
--     return (char and char:GetDescription()) or "No description."
-- end
function GetCharacterDescription(client)
end

--- Returns the display name for a speaker in a given chat type.
-- @realm shared
-- @player speaker Player speaking
-- @string chatType Chat type identifier (e.g. "ic", "ooc")
-- @treturn string Name to display
-- @usage function PLUGIN:GetCharacterName(speaker, chatType)
--     if (chatType == "ooc") then
--         return speaker:SteamName()
--     end
-- end
function GetCharacterName(speaker, chatType)
end

--- Parses text to determine chat prefix information.
-- @realm shared
-- @string text Raw text entered
-- @treturn[1] string Chat type if a prefix matched
-- @treturn[2] string Stripped message without the prefix
-- @usage function PLUGIN:GetChatPrefixInfo(text)
--     if (text:sub(1,4) == "/me ") then
--         return "me"
--     end
-- end
function GetChatPrefixInfo(text)
end

--- Adjusts the crosshair alpha.
-- @realm client
-- @number curAlpha Current alpha value
-- @treturn number New alpha value
-- @usage function PLUGIN:GetCrosshairAlpha(curAlpha)
--     -- Hide crosshair slightly when sprinting
--     if (LocalPlayer():GetMoveType() == MOVETYPE_WALK and LocalPlayer():KeyDown(IN_SPEED)) then
--         return math.max(0, curAlpha - 50)
--     end
-- end
function GetCrosshairAlpha(curAlpha)
end

--- Adjust the number of default attribute points a new character gets.
-- @realm shared
-- @player client Player creating the character
-- @number count Base attribute point count
-- @treturn number New attribute point count
-- @usage function PLUGIN:GetDefaultAttributePoints(client, count)
--     return count + (client:IsAdmin() and 5 or 0)
-- end
function GetDefaultAttributePoints(client, count)
end

--- Returns a default character name for a new character in a faction.
-- @realm shared
-- @player client Player creating the character
-- @tab faction Faction table selected
-- @treturn string Default name
-- @usage function PLUGIN:GetDefaultCharacterName(client, faction)
--     return faction and (faction.name .. " Recruit") or "Newcomer"
-- end
function GetDefaultCharacterName(client, faction)
end

--- Returns the maximum number of characters the player can have.
-- @realm shared
-- @player client Player
-- @treturn number Max characters allowed
-- @usage function PLUGIN:GetMaxPlayerCharacter(client)
--     return client:IsAdmin() and 5 or 3
-- end
function GetMaxPlayerCharacter(client)
end

--- Returns the sound to emit from the player upon death. If nothing is returned then it will use the default male/female death
-- sounds.
-- @realm server
-- @player client Player that died
-- @treturn[1] string Sound to play
-- @treturn[2] bool `false` if a sound shouldn't be played at all
-- @usage function PLUGIN:GetPlayerDeathSound(client)
--     -- play impact sound every time someone dies
--     return "physics/body/body_medium_impact_hard1.wav"
-- end
-- @usage function PLUGIN:GetPlayerDeathSound(client)
--     -- don't play a sound at all
--     return false
-- end
function GetPlayerDeathSound(client)
end

--- Allows modifying the context menu when interacting with a player entity.
-- @realm client
-- @player client Target player
-- @tab options Table of menu options; modify to add/remove entries
-- @usage function PLUGIN:GetPlayerEntityMenu(client, options)
--     options["Wave"] = function() RunConsoleCommand("act", "wave") end
-- end
function GetPlayerEntityMenu(client, options)
end

--- Returns a Material or texture path for a custom player icon.
-- @realm client
-- @player speaker Player whose icon to fetch
-- @treturn[1] IMaterial Custom material to use
-- @treturn[2] string Texture path
-- @usage function PLUGIN:GetPlayerIcon(speaker)
--     if (speaker:IsAdmin()) then
--         return "icon16/shield.png"
--     end
-- end
function GetPlayerIcon(speaker)
end

--- Returns the sound to emit from the player upon getting damage.
-- @realm server
-- @player client Client that received damage
-- @treturn string Sound to emit
-- @usage function PLUGIN:GetPlayerPainSound(client)
--     return "NPC_MetroPolice.Pain" -- Make players emit MetroPolice pain sound.
-- end
function GetPlayerPainSound(client)
end

--- Adjust the damage dealt by a player's punch.
-- @realm shared
-- @player client Player punching
-- @number damage Base damage
-- @tab context Additional context (e.g. hit bone)
-- @treturn number New damage amount
-- @usage function PLUGIN:GetPlayerPunchDamage(client, damage, context)
--     if (client:GetCharacter():GetAttribute("str", 0) >= 10) then
--         return damage + 5
--     end
-- end
function GetPlayerPunchDamage(client, damage, context)
end

--- Returns the salary that character should get instead of his faction salary.
-- @realm server
-- @player client Client that is receiving salary
-- @tab faction Faction of the player's character
-- @treturn number Character salary
-- @see CanPlayerEarnSalary
-- @usage function PLUGIN:GetSalaryAmount(client, faction)
--  return 0 -- Everyone get no salary.
-- end
function GetSalaryAmount(client, faction)
end

--- Returns an indicator string shown above a player while typing.
-- @realm client
-- @char character Character typing
-- @string text Current text buffer
-- @treturn string Indicator text (e.g. "..."), or nil to use default
-- @usage function PLUGIN:GetTypingIndicator(character, text)
--     if (text and text:find("/me")) then return "emoting..." end
-- end
function GetTypingIndicator(character, text)
end

--- Registers chat classes after the core framework chat classes have been registered. You should usually create your chat
-- classes in this hook - especially if you want to reference the properties of a framework chat class.
-- @realm shared
-- @usage function PLUGIN:InitializedChatClasses()
--     -- let's say you wanted to reference an existing chat class's color
--     ix.chat.Register("myclass", {
--         format = "%s says \"%s\"",
--         GetColor = function(self, speaker, text)
--             -- make the chat class slightly brighter than the "ic" chat class
--             local color = ix.chat.classes.ic:GetColor(speaker, text)
--
--             return Color(color.r + 35, color.g + 35, color.b + 35)
--         end,
--         -- etc.
--     })
-- end
-- @see ix.chat.Register
-- @see ix.chat.classes
function InitializedChatClasses()
end

--- Called after config variables have been registered.
-- @realm shared
-- @usage function PLUGIN:InitializedConfig()
--     -- Read a custom config
--     ix.config.Add("mySetting", true, "Example", nil, true)
-- end
function InitializedConfig()
end

--- Called after plugins are loaded.
-- @realm shared
-- @usage function PLUGIN:InitializedPlugins()
--     print("All plugins initialized")
-- end
function InitializedPlugins()
end

--- Called after the schema is initialized.
-- @realm shared
-- @usage function PLUGIN:InitializedSchema()
--     print("Schema initialized: " .. GAMEMODE.Name)
-- end
function InitializedSchema()
end

--- Called when an item was added to the inventory.
-- @realm server
-- @tab oldInv Previous item inventory
-- @tab inventory New item inventory
-- @tab item Item that was added to the inventory
function InventoryItemAdded(oldInv, inventory, item)
end

--- Called when an item was removed from the inventory.
-- @realm server
-- @tab inventory Inventory from which item was removed
-- @tab item Item that was removed from the inventory
function InventoryItemRemoved(inventory, item)
end

--- Determines if a character recognizes a given identifier.
-- @realm shared
-- @char character Character doing the recognition check
-- @string id Identifier to check (e.g. character ID or name key)
-- @treturn bool Return true if recognized
-- @usage function PLUGIN:IsCharacterRecognized(character, id)
--     return character:GetData("recognized", {})[id] == true
-- end
function IsCharacterRecognized(character, id)
end

--- Whether the local player recognizes the given player.
-- @realm client
-- @player client Player to check
-- @treturn bool True if recognized
-- @usage function PLUGIN:IsPlayerRecognized(client)
--     local myChar = LocalPlayer():GetCharacter()
--     return myChar and (myChar:GetData("recognized", {})[client:SteamID()] == true)
-- end
function IsPlayerRecognized(client)
end

--- Whether recognition affects the given chat type.
-- @realm client
-- @string chatType Chat type (e.g. "ic")
-- @treturn bool True if recognition gating applies
-- @usage function PLUGIN:IsRecognizedChatType(chatType)
--     return chatType == "ic" or chatType == "y"
-- end
function IsRecognizedChatType(chatType)
end

--- Called when server is loading data.
-- @realm server
function LoadData()
end

--- Called to register or override UI fonts.
-- @realm client
-- @string font Preferred schema font name
-- @string genericFont Fallback generic font name
-- @usage function PLUGIN:LoadFonts(font, genericFont)
--     surface.CreateFont("ixBigTitle", {font = font, size = 28, weight = 600})
-- end
function LoadFonts(font, genericFont)
end

--- Called to build the intro screen.
-- @realm client
-- @usage function PLUGIN:LoadIntro()
--     print("Intro screen loaded")
-- end
function LoadIntro()
end

--- Called when a tab menu subpanel is created.
-- @realm client
-- @string subpanelName Name of the subpanel
-- @param panel Panel The created panel instance
-- @usage function PLUGIN:MenuSubpanelCreated(subpanelName, panel)
--     if (subpanelName == "inventory") then panel:SetBackgroundColor(Color(10,10,10,200)) end
-- end
function MenuSubpanelCreated(subpanelName, panel)
end

--- Called when a chat message is received clientside.
-- @realm client
-- @player client Player who sent the message
-- @tab info Message info table (chatType, text, etc.)
-- @usage function PLUGIN:MessageReceived(client, info)
--     if (info.chatType == "ooc") then surface.PlaySound("buttons/button15.wav") end
-- end
function MessageReceived(client, info)
end

--- Called clientside when the local player's area changes.
-- @realm client
-- @string oldID Previous area ID
-- @string newID New area ID
-- @usage function PLUGIN:OnAreaChanged(oldID, newID)
--     chat.AddText(Color(180,180,255), "Entered area: ", newID)
-- end
function OnAreaChanged(oldID, newID)
end

--- Called when a character has been created and assigned to a player.
-- @realm shared
-- @player client Player that owns the newly created character
-- @char character Character instance that was created
-- @usage function PLUGIN:OnCharacterCreated(client, character)
--     print("Created character ID:", character and character:GetID())
-- end
function OnCharacterCreated(client, character)
end

--- Called when a player who uses a character has disconnected.
-- @realm server
-- @player client The player that has disconnected
-- @char character The character that the player was using
-- @usage function PLUGIN:OnCharacterDisconnect(client, character)
--     print("Player disconnected with character ID " .. tostring(character and character:GetID()))
-- end
function OnCharacterDisconnect(client, character)
end

--- Called when a character was ragdolled or unragdolled.
-- @realm server
-- @player client Player that was ragdolled or unradolled
-- @entity entity Ragdoll that represents the player
-- @bool bFallenOver Whether or not the character was ragdolled or unragdolled
-- @usage function PLUGIN:OnCharacterFallover(client, entity, bFallenOver)
--     print((bFallenOver and "Ragdolled" or "Unragdolled") .. " player: " .. client:Name())
-- end
function OnCharacterFallover(client, entity, bFallenOver)
end

--- Called when a character has gotten up from the ground.
-- @realm server
-- @player client Player that has gotten up
-- @entity ragdoll Ragdoll used to represent the player
-- @usage function PLUGIN:OnCharacterGetup(client, ragdoll)
--     print(client:Name() .. " got up.")
-- end
function OnCharacterGetup(client, ragdoll)
end

--- Called when the character selection/menu UI is created.
-- @realm client
-- @param panel Panel Root menu panel
-- @usage function PLUGIN:OnCharacterMenuCreated(panel)
--     panel:SetTitle("Choose your destiny")
-- end
function OnCharacterMenuCreated(panel)
end

--- Called whenever an item entity has spawned in the world. You can access the entity's item table with
-- `entity:GetItemTable()`.
-- @realm server
-- @entity entity Spawned item entity
-- @usage function PLUGIN:OnItemSpawned(entity)
--     local item = entity:GetItemTable()
--     -- do something with the item here
-- end
function OnItemSpawned(entity)
end

--- Called when an item has been transferred between inventories.
-- @realm shared
-- @tab item Item that transferred
-- @tab curInv Previous inventory
-- @tab inventory New inventory
-- @usage function PLUGIN:OnItemTransferred(item, curInv, inventory)
--     ix.log.Add(item:GetOwner(), "itemTransfer", item.uniqueID, curInv and curInv:GetID(), inventory and inventory:GetID())
-- end
function OnItemTransferred(item, curInv, inventory)
end

--- Called when a local networked variable is set.
-- @realm client
-- @string key Variable key
-- @param var any New value
-- @usage function PLUGIN:OnLocalVarSet(key, var)
--     if (key == "viewbob" and var == false) then
--         LocalPlayer():ChatPrint("View bob disabled.")
--     end
-- end
function OnLocalVarSet(key, var)
end

--- Called when a PAC3 part has been moved to another outfit.
-- @realm client
-- @tab part PAC3 part table
-- @usage function PLUGIN:OnPAC3PartTransferred(part)
--     -- Example: print part name
--     print("PAC3 part transferred: " .. tostring(part.name))
-- end
function OnPAC3PartTransferred(part)
end

--- Called when a player has picked up the money from the ground.
-- @realm server
-- @player client Player that picked up the money
-- @entity self Money entity
-- @treturn bool Whether or not to allow the player to pick up the money
-- @usage function PLUGIN:OnPickupMoney(client, self)
--     return false -- Disallow picking up money.
-- end
function OnPickupMoney(client, self)
end

--- Called serverside when a player's area changes.
-- @realm shared
-- @player client Player whose area changed
-- @string oldID Previous area ID
-- @string newID New area ID
-- @usage function PLUGIN:OnPlayerAreaChanged(client, oldID, newID)
--     ix.log.Add(client, "areaChanged", oldID, newID)
-- end
function OnPlayerAreaChanged(client, oldID, newID)
end

--- Called when a player has entered or exited the observer mode.
-- @realm server
-- @player client Player that entered or exited the observer mode
-- @bool state Previous observer state
-- @usage function PLUGIN:OnPlayerObserve(client, state)
--     print(client:Name() .. (client:GetMoveType() == MOVETYPE_NOCLIP and " entered" or " exited") .. " observer.")
-- end
function OnPlayerObserve(client, state)
end

--- Called when a player has selected the entity interaction menu option while interacting with a player.
-- @realm server
-- @player client Player that other player has interacted with
-- @player callingClient Player that has interacted with with other player
-- @string option Option that was selected
-- @usage function PLUGIN:OnPlayerOptionSelected(client, callingClient, option)
--     print(callingClient:Name() .. " selected option '" .. tostring(option) .. "' on " .. client:Name())
-- end
function OnPlayerOptionSelected(client, callingClient, option)
end

--- Called when a player has purchased or sold a door.
-- @realm server
-- @player client Player that has purchased or sold a door
-- @entity entity Door that was purchased or sold
-- @bool bBuying Whether or not the player is bying a door
-- @func bCallOnDoorChild Function to call something on the door child
-- @usage function PLUGIN:OnPlayerPurchaseDoor(client, entity, bBuying, bCallOnDoorChild)
--     print(client:Name() .. (bBuying and " bought" or " sold") .. " a door.")
-- end
function OnPlayerPurchaseDoor(client, entity, bBuying, bCallOnDoorChild)
end

--- Called when a player was restricted.
-- @realm server
-- @player client Player that was restricted
-- @usage function PLUGIN:OnPlayerRestricted(client)
--     print(client:Name() .. " was restricted.")
-- end
function OnPlayerRestricted(client)
end

--- Called when a player was unrestricted.
-- @realm server
-- @player client Player that was unrestricted
-- @usage function PLUGIN:OnPlayerUnRestricted(client)
--     print(client:Name() .. " was unrestricted.")
-- end
function OnPlayerUnRestricted(client)
end

--- Called when a saved items were loaded.
-- @realm server
-- @tab loadedItems Table of items that were loaded
-- @usage function PLUGIN:OnSavedItemLoaded(loadedItems)
--     print("Loaded items count: " .. tostring(#loadedItems))
-- end
function OnSavedItemLoaded(loadedItems)
end

--- Called when server database are being wiped.
-- @realm server
-- @usage function PLUGIN:OnWipeTables()
--     print("Wiping tables...")
-- end
function OnWipeTables()
end

--- Forces a player to play an animation sequence.
-- @realm shared
-- @player client Player entering the sequence
-- @string sequence Sequence name or ID
-- @func callback Callback executed after sequence ends
-- @number time Duration override
-- @bool bNoFreeze If true, player won't be frozen during the sequence
-- @usage function PLUGIN:PlayerEnterSequence(client, sequence, callback, time, bNoFreeze)
--     -- Example wrapper, usually called by framework
-- end
function PlayerEnterSequence(client, sequence, callback, time, bNoFreeze)
end

--- Called when a player has interacted with an entity through the entity's interaction menu.
-- @realm server
-- @player client Player that performed interaction
-- @entity entity Entity being interacted with
-- @string option Option selected by the player
-- @param data any Any data passed with the interaction option
function PlayerInteractEntity(client, entity, option, data)
end

--- Called when a player has interacted with an item.
-- @realm server
-- @player client Player that interacted with an item
-- @string action Action selected by the player
-- @tab item Item being interacted with
function PlayerInteractItem(client, action, item)
end

--- Called when a player has joined a class.
-- @realm server
-- @player client Player that has joined a class
-- @number class Index of the class player has joined to
-- @number oldClass Index of the player's previous class
function PlayerJoinedClass(client, class, oldClass)
end

--- Called when a player stops a forced sequence started with `ForceSequence`.
-- @realm shared
-- @player entity Player leaving the sequence
-- @usage function PLUGIN:PlayerLeaveSequence(entity)
--     print(entity:Name() .. " left a sequence")
-- end
function PlayerLeaveSequence(entity)
end

--- Called when a player has loaded a character.
-- @realm server
-- @player client Player that has loaded a character
-- @char character Character that was loaded
-- @char currentChar Character that player was using
-- @usage function PLUGIN:PlayerLoadedCharacter(client, character, currentChar)
--     print(client:Name() .. " loaded character ID " .. tostring(character and character:GetID()))
-- end
function PlayerLoadedCharacter(client, character, currentChar)
end

--- Called when a player has locked a door.
-- @realm server
-- @player client Player that has locked a door
-- @entity door Door that was locked
-- @entity partner Door partner
-- @usage function PLUGIN:PlayerLockedDoor(client, door, partner)
--     print(client:Name() .. " locked a door.")
-- end
function PlayerLockedDoor(client, door, partner)
end

--- Called when a player has locked a vehicle.
-- @realm server
-- @player client Player that has locked a vehicle
-- @entity vehicle Vehicle that was locked
-- @usage function PLUGIN:PlayerLockedVehicle(client, vehicle)
--     print(client:Name() .. " locked a vehicle.")
-- end
function PlayerLockedVehicle(client, vehicle)
end

--- Called when player has said something in the text chat.
-- @realm server
-- @player speaker Player that has said something in the text chat
-- @string chatType Type of the chat that player used
-- @string text Chat message that player send
-- @bool anonymous Whether or not message was anonymous
-- @tab receivers Players who will hear that message
-- @string rawText Chat message without any formatting
-- @treturn string You can return text that will be shown instead
-- @usage function PLUGIN:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
--  return "Text" -- When a player writes something into chat, he will say "Text" instead.
-- end
function PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
end

--- Called when a player model was changed.
-- @realm server
-- @player client Player whose model was changed
-- @string oldModel Old player model
-- @usage function PLUGIN:PlayerModelChanged(client, oldModel)
--     print(client:Name() .. " changed model from " .. tostring(oldModel))
-- end
function PlayerModelChanged(client, oldModel)
end

--- Called when a player has got stamina.
-- @realm server
-- @player client Player who has got stamina
-- @usage function PLUGIN:PlayerStaminaGained(client)
--     print(client:Name() .. " gained stamina.")
-- end
function PlayerStaminaGained(client)
end

--- Called when a player has lost stamina.
-- @realm server
-- @player client Player who has lost stamina
-- @usage function PLUGIN:PlayerStaminaLost(client)
--     print(client:Name() .. " lost stamina.")
-- end
function PlayerStaminaLost(client)
end

--- Called when a player throws a punch (hands SWEP).
-- @realm shared
-- @usage function PLUGIN:PlayerThrowPunch(client, trace)
--     -- Example: feedback
--     print(client:Name() .. " threw a punch.")
-- end
function PlayerThrowPunch(client, trace)
end

--- Called when a player has unlocked a door.
-- @realm server
-- @player client Player that has unlocked a door
-- @entity door Door that was unlocked
-- @entity partner Door partner
-- @usage function PLUGIN:PlayerUnlockedDoor(client, door, partner)
--     print(client:Name() .. " unlocked a door.")
-- end
function PlayerUnlockedDoor(client, door, partner)
end

--- Called when a player has unlocked a vehicle.
-- @realm server
-- @player client Player that has unlocked a vehicle
-- @entity vehicle Vehicle that was unlocked
-- @usage function PLUGIN:PlayerUnlockedVehicle(client, vehicle)
--     print(client:Name() .. " unlocked a vehicle.")
-- end
function PlayerUnlockedVehicle(client, vehicle)
end

--- Called when a player has used an entity.
-- @realm server
-- @player client Player who has used an entity
-- @entity entity Entity that was used by the player
-- @usage function PLUGIN:PlayerUse(client, entity)
--     print(client:Name() .. " used entity " .. tostring(entity))
-- end
function PlayerUse(client, entity)
end

--- Called when a player has used a door.
-- @realm server
-- @player client Player who has used a door
-- @entity entity Door that was used by the player
-- @usage function PLUGIN:PlayerUseDoor(client, entity)
--     print(client:Name() .. " used a door.")
-- end
function PlayerUseDoor(client, entity)
end

--- Called when a player's active weapon changes clientside or serverside.
-- @realm shared
-- @player client Player whose weapon changed
-- @entity weapon New active weapon (may be NULL on holster)
-- @usage function PLUGIN:PlayerWeaponChanged(client, weapon)
--     -- Log weapon switch
--     print(client:Name() .. " switched to " .. (IsValid(weapon) and weapon:GetClass() or "none"))
-- end
function PlayerWeaponChanged(client, weapon)
end

--- Called when a plugin is loaded.
-- @realm shared
-- @string uniqueID Plugin unique ID
-- @tab pluginTable The PLUGIN table
-- @usage function PLUGIN:PluginLoaded(uniqueID, pluginTable)
--     print("Plugin loaded:", uniqueID)
-- end
function PluginLoaded(uniqueID, pluginTable)
end

--- Allows preventing a plugin from loading.
-- @realm shared
-- @string uniqueID Plugin unique ID
-- @treturn bool Return false to block loading
-- @usage function PLUGIN:PluginShouldLoad(uniqueID)
--     return uniqueID != "experimental"
-- end
function PluginShouldLoad(uniqueID)
end

--- Called when a plugin is unloaded.
-- @realm shared
-- @string uniqueID Plugin unique ID
-- @usage function PLUGIN:PluginUnloaded(uniqueID)
--     print("Plugin unloaded:", uniqueID)
-- end
function PluginUnloaded(uniqueID)
end

--- Populate the character tooltip with extra details.
-- @realm client
-- @player client Player whose character tooltip is shown
-- @char character Character table
-- @param tooltip Panel Tooltip panel to populate
-- @usage function PLUGIN:PopulateCharacterInfo(client, character, tooltip)
--     tooltip:AddRow("ID"):SetText(tostring(character:GetID()))
-- end
function PopulateCharacterInfo(client, character, tooltip)
end

--- Populate the entity tooltip with custom rows.
-- @realm client
-- @entity entity Entity being looked at
-- @param tooltip Panel Tooltip panel
-- @usage function PLUGIN:PopulateEntityInfo(entity, tooltip)
--     if (entity:IsDoor()) then tooltip:AddRow("Lock"):SetText(entity:IsLocked() and "Locked" or "Unlocked") end
-- end
function PopulateEntityInfo(entity, tooltip)
end

-- @realm client
-- @tab categories Table to add categories into
-- @usage function PLUGIN:PopulateHelpMenu(categories)
--     categories["Rules"] = function(panel)
--         panel:Add("DLabel"):SetText("Be respectful.")
--     end
-- end
function PopulateHelpMenu(categories)
end

--- Add high-priority info to the character tooltip.
-- @realm client
-- @entity entity Player entity
-- @char character Character table
-- @param tooltip Panel Tooltip panel
-- @usage function PLUGIN:PopulateImportantCharacterInfo(entity, character, tooltip)
--     tooltip:AddRow("Faction"):SetText(character:GetFaction() and character:GetFaction():GetName() or "Unknown")
-- end
function PopulateImportantCharacterInfo(entity, character, tooltip)
end

--- Populate the item tooltip with additional info rows.
-- @realm client
-- @param tooltip Panel Tooltip panel
-- @tab item Item table
-- @usage function PLUGIN:PopulateItemTooltip(tooltip, item)
--     if (item and item.weight) then tooltip:AddRow("Weight"):SetText(item.weight .. " kg") end
-- end
function PopulateItemTooltip(tooltip, item)
end

--- Populate the player tooltip with extra information.
-- @realm client
-- @player client Player being looked at
-- @param tooltip Panel Tooltip panel
-- @usage function PLUGIN:PopulatePlayerTooltip(client, tooltip)
--     tooltip:AddRow("SteamID"):SetText(client:SteamID())
-- end
function PopulatePlayerTooltip(client, tooltip)
end

--- Add custom options to the scoreboard player context menu.
-- @realm client
-- @player client Player clicked
-- @param menu Panel Context menu panel
-- @usage function PLUGIN:PopulateScoreboardPlayerMenu(client, menu)
--     menu:AddOption("Wave", function() RunConsoleCommand("act", "wave") end)
-- end
function PopulateScoreboardPlayerMenu(client, menu)
end

--- Called after the chatbox is drawn for custom overlays.
-- @realm client
-- @number width Chatbox width
-- @number height Chatbox height
-- @number alpha Current alpha
-- @usage function PLUGIN:PostChatboxDraw(width, height, alpha)
--     -- Custom drawing code here
-- end
function PostChatboxDraw(width, height, alpha)
end

--- Called after drawing the model view to add post-processing.
-- @realm client
-- @param panel Panel Model view panel
-- @entity entity Model entity
-- @usage function PLUGIN:PostDrawHelixModelView(panel, entity)
--     -- Could add halo, overlays, etc.
-- end
function PostDrawHelixModelView(panel, entity)
end

--- Called after the inventory panel is drawn.
-- @realm client
-- @param panel Panel Inventory panel
-- @usage function PLUGIN:PostDrawInventory(panel)
--     -- Draw slot outlines or helper text
-- end
function PostDrawInventory(panel)
end

--- Called when server data was loaded.
-- @realm server
-- @usage function PLUGIN:PostLoadData()
--     print("Server data loaded.")
-- end
function PostLoadData()
end

--- Called after player loadout.
-- @realm server
-- @player client
-- @usage function PLUGIN:PostPlayerLoadout(client)
--     print("Loadout applied to " .. client:Name())
-- end
function PostPlayerLoadout(client)
end

--- Called after player has said something in the text chat.
-- @realm server
-- @player client Player that has said something in the text chat
-- @string chatType Type of the chat that player used
-- @string message Chat message that player send
-- @bool anonymous Whether or not message was anonymous
-- @usage function PLUGIN:PostPlayerSay(client, chatType, message, anonymous)
--     print(client:Name() .. " said (" .. chatType .. "): " .. message)
-- end
function PostPlayerSay(client, chatType, message, anonymous)
end

--- Called after all act sequences have been set up.
-- @realm shared
-- @usage function PLUGIN:PostSetupActs()
--     print("Acts setup complete.")
-- end
function PostSetupActs()
end

--- Called before character deletion.
-- @realm server
-- @player client Character owner
-- @char character Chraracter that will be deleted
-- @usage function PLUGIN:PreCharacterDeleted(client, character)
--     print("Deleting character ID " .. tostring(character and character:GetID()))
-- end
function PreCharacterDeleted(client, character)
end

--- Called before character loading.
-- @realm server
-- @player client Player that loading a character
-- @char character Character that will be loaded
-- @char currentChar Character that player is using
-- @usage function PLUGIN:PrePlayerLoadedCharacter(client, character, currentChar)
--     print("Loading character ID " .. tostring(character and character:GetID()))
-- end
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
--     if (!client:IsAdmin()) then
--         return false -- only allow admins to talk in chat
--     end
-- end
function PrePlayerMessageSend(client, chatType, message, bAnonymous)
end

--- Called when server is saving data.
-- @realm server
-- @usage function PLUGIN:SaveData()
--     print("Saving server data...")
-- end
function SaveData()
end

--- Called when the screen resolution changes.
-- @realm client
-- @number width New width
-- @number height New height
-- @usage function PLUGIN:ScreenResolutionChanged(width, height)
--     print("Resolution changed to " .. width .. "x" .. height)
-- end
function ScreenResolutionChanged(width, height)
end

--- Define and register custom act sequences.
-- @realm shared
-- @usage function PLUGIN:SetupActs()
--     ix.act.Register("salute", ACT_GESTURE_SALUTE, 2)
-- end
function SetupActs()
end

--- Define area properties such as display names and colors.
-- @realm shared
-- @usage function PLUGIN:SetupAreaProperties()
--   ix.area.AddType("spawn")
-- end
function SetupAreaProperties()
end

--- Called when a player has taken a shipment item.
-- @realm server
-- @player client Player that has taken a shipment item
-- @string uniqueID UniqueID of the shipment item that was taken
-- @number amount Amount of the items that were taken
function ShipmentItemTaken(client, uniqueID, amount)
end

--- Allows hiding specific HUD bars.
-- @realm client
-- @param bar Panel Bar panel
-- @treturn bool Return false to prevent drawing
-- @usage function PLUGIN:ShouldBarDraw(bar)
--     return bar.identifier != "stamina"
-- end
function ShouldBarDraw(bar)
end

--- Whether or not the server should delete saved items.
-- @realm server
-- @treturn bool Whether or not the server should delete saved items
-- @usage function PLUGIN:ShouldDeleteSavedItems()
--  return true -- Delete all saved items.
-- end
function ShouldDeleteSavedItems()
end

--- Whether the area HUD should be shown for a given area.
-- @realm client
-- @string newID New area ID
-- @treturn bool Return false to hide
-- @usage function PLUGIN:ShouldDisplayArea(newID)
--     return newID != "restricted"
-- end
function ShouldDisplayArea(newID)
end

--- Whether the crosshair should be drawn.
-- @realm client
-- @player client Local player
-- @entity weapon Current weapon entity
-- @treturn bool Return false to hide
-- @usage function PLUGIN:ShouldDrawCrosshair(client, weapon)
--     return not weapon:IsValid() or weapon:GetClass() != "weapon_physgun"
-- end
function ShouldDrawCrosshair(client, weapon)
end

--- Whether item size (grid dimensions) should be shown in tooltips.
-- @realm client
-- @tab item Item table
-- @treturn bool Return false to hide
-- @usage function PLUGIN:ShouldDrawItemSize(item)
--     return not item.isQuestItem
-- end
function ShouldDrawItemSize(item)
end

--- Whether the HUD bars should be hidden entirely.
-- @realm client
-- @treturn bool Return true to hide
-- @usage function PLUGIN:ShouldHideBars()
--     return LocalPlayer():InVehicle()
-- end
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
--         if (client:IsAdmin()) then
--             return false -- all non-admin players will have their character permakilled
--         end
--     end
function ShouldPermakillCharacter(client, character, inflictor, attacker)
end

--- Whether or not player should drown.
-- @realm server
-- @player client Player that is underwater
-- @treturn bool Whether or not player should drown
-- @usage function PLUGIN:ShouldPlayerDrowned(client)
--  return false -- Players will not drown.
-- end
function ShouldPlayerDrowned(client)
end

--- Whether or not remove player ragdoll on death.
-- @realm server
-- @player client Player that died
-- @treturn bool Whether or not remove player ragdoll on death
-- @usage function PLUGIN:ShouldRemoveRagdollOnDeath(client)
--  return false -- Player ragdolls will not be removed.
-- end
function ShouldRemoveRagdollOnDeath(client)
end

--- Whether or not to restore character inventory.
-- @realm server
-- @number characterID ID of the character
-- @number inventoryID ID of the inventory
-- @string inventoryType Type of the inventory
-- @treturn bool Whether or not to restore character inventory
-- @usage function PLUGIN:ShouldRestoreInventory(characterID, inventoryID, inventoryType)
--  return false -- Character inventories will not be restored.
-- end
function ShouldRestoreInventory(characterID, inventoryID, inventoryType)
end

--- Whether a given player should be visible on the scoreboard.
-- @realm client
-- @player client Player to check
-- @treturn bool Return false to hide
-- @usage function PLUGIN:ShouldShowPlayerOnScoreboard(client)
--     return not client:GetNetVar("hidden")
-- end
function ShouldShowPlayerOnScoreboard(client)
end

--- Whether or not spawn player ragdoll on death.
-- @realm server
-- @player client Player that died
-- @treturn bool Whether or not spawn player ragdoll on death
-- @usage function PLUGIN:ShouldSpawnClientRagdoll(client)
--  return false -- Player ragdolls will not be spawned.
-- end
function ShouldSpawnClientRagdoll(client)
end

--- Show an interaction menu for the looked-at entity.
-- @realm client
-- @entity entity Entity
-- @usage function PLUGIN:ShowEntityMenu(entity)
--     -- Add context options
-- end
function ShowEntityMenu(entity)
end

--- Called when the third-person setting changes.
-- @realm client
-- @bool oldValue Previous value
-- @bool value New value
-- @usage function PLUGIN:ThirdPersonToggled(oldValue, value)
--     chat.AddText(Color(200,200,255), value and "Third person enabled" or "Third person disabled")
-- end
function ThirdPersonToggled(oldValue, value)
end

--- Update existing character info UI.
-- @realm client
-- @param panel Panel Character info panel
-- @char character Character being displayed
-- @usage function PLUGIN:UpdateCharacterInfo(panel, character)
--     panel:InvalidateLayout()
-- end
function UpdateCharacterInfo(panel, character)
end

--- Update existing character info category UI.
-- @realm client
-- @param panel Panel Category panel
-- @char character Character being displayed
-- @usage function PLUGIN:UpdateCharacterInfoCategory(panel, character)
--     panel:InvalidateLayout()
-- end
function UpdateCharacterInfoCategory(panel, character)
end

--- Called when the distance on which the voice can be heard was changed.
-- @realm server
-- @number newValue New voice distance
-- @usage function PLUGIN:VoiceDistanceChanged(newValue)
--     print("Voice distance changed to " .. tostring(newValue))
-- end
function VoiceDistanceChanged(newValue)
end

--- Overrides the sound when cycling weapons via the selection HUD.
-- @realm client
-- @treturn string Sound path
-- @usage function PLUGIN:WeaponCycleSound()
--     return "common/wpn_moveselect.wav"
-- end
function WeaponCycleSound()
end

--- Overrides the sound when selecting a weapon via the selection HUD.
-- @realm client
-- @entity weapon The weapon being selected
-- @treturn string Sound path
-- @usage function PLUGIN:WeaponSelectSound(weapon)
--     return "common/wpn_select.wav"
-- end
function WeaponSelectSound(weapon)
end
