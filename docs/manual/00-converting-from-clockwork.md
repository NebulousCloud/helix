# Clockwork to Helix Migration

If you are here, you probably want to be converting your code from another framework to Helix. Doing so should not be a difficult task. Most of the previous functions are probably within Helix in one form or another! This means all you need to do is match *x* function found in the old framework to *y* function in Helix. Some headings will contain a link - this will bring you to the documentation for Helix's equivalent library or class.

This tutorial assumes basic to intermediate knowledge and experience with Garry's Mod Lua.

**Before you start!** You will notice that Helix uses client for the variable that represents a player. Clockwork uses player for the variable instead, but this will conflict with the player library. So if you see `_player` being used in Clockwork, it means the Garry's Mod player library. This is just a preference and does not affect anything besides appear. So keep in mind throughout the tutorial, you may see player being used for Clockwork code and client being used for Helix code. They represent the same thing, just with a different name.

If you are converting Clockwork code to Helix, keep in mind that `_player` is not defined so you will need to either define `_player` yourself or switch it to player instead and change the variable name to client for player objects.

# Basics of Conversion

## Folders
Clockwork code and file structure is not too different from Helix. In the schema, the plugins folder and schema folder stay in the same place. There are some minor differences in naming however:

- The `schema/entities` folder should be moved outside out of the schema folder.
- The `libraries` folder needs to be renamed to `libs` to load.
- The `commands` tab will not load as each command is now defined in a single shared file, does not matter which one.

## Deriving from Helix
This is pretty important. If you want to use Helix as the base, you need to set it as the base. So, go to your Clockwork schema's `gamemode` folder. Inside should be two files: `init.lua `and `cl_init.lua`. Open both, and you should see something along the lines of `DeriveGamemode("Clockwork")`. Change this to `DeriveGamemode("helix")`.

# The Schema

## Introduction
Inside of the `schema` folder of the actual schema, you should see a file named `sh_schema.lua`. This is the main schema file in both Clockwork and Helix. Most of your changes may actually be within this file.

## Including Files
Both frameworks come with a utility function to include a file without worrying about sending them to the client and stuff. In Clockwork, this function is `Clockwork.kernel:IncludePrefixed("sh_myfile.lua")`. Change this to `ix.util.Include("sh_myfile.lua") `and save.

# The Plugin

## Introduction
Plugins serve as a means to add on to a schema or framework without directly modifying either. This allows for easier modifications that can be added/removed with ease. It is recommended that you keep all custom modifications left to plugins rather than editing the framework or the schema if possible.

## Structure
All plugins in Clockwork and Helix go into the `plugins` folder. However, there are many differences with the CW plugin structure. First of all, there are two things you see when you open a plugin folder: `plugin` again and `plugin.ini`.

Helix only has one file needed: `sh_plugin.lua` which acts like `sh_schema.lua` but for plugins.

## Conversion
The first step is to move all of the contents from the `plugin` folder to the main folder of the plugin folder. The `sh_plugin.lua` file needs to be changed to provide basic information about the plugin.You need to define three things in `sh_plugin.lua` which can be found within the `plugin.ini` file:

- `PLUGIN.name = "Plugin Name"`
- `PLUGIN.author = "Plugin Author"`
- `PLUGIN.description = "Plugin Description"`

If the plugin uses a special variable (e.g. `cwPluginName`) for the plugin, change it to `PLUGIN`.

- Note that the `PLUGIN` table is removed after the plugin is loaded. So if you want to use `PLUGIN` after the plugin has loaded (such as in console commands, in entities, etc.), add `local PLUGIN = PLUGIN` at the top.
- You can see if a global variable is defined for it by looking for `PLUGIN:SetGlobalAlias("cwMyPlugin")`. So, one would change `cwMyPlugin` to `PLUGIN`.

# The `Character` Object
One main thing that is very notable is how the character is referenced using `client:GetCharacter()` which returns a character object. The way the object works is just like an entity you spawn. It has its own properties like the model, color, etc. that makes it unique. You can access all the characters in a table which stores loaded characters with `ix.char.loaded`.

The character object comes with many predefined methods. You can look at how they are defined [by clicking here](https://github.com/NebulousCloud/helix/blob/master/gamemode/core/meta/sh_character.lua). The character object makes it very simple to manager character information.

You will notice throughout the framework, the character object is used a lot. The use of the character object makes a large barrier between what belongs to the character and what belongs to the player. For example: flags, models, factions, data, and other things are stored on the character and can be accessed by the character object.

In Clockwork, there is no use of an object. Instead, the character information is intertwined with the player object. For example:

```
-- in Clockwork
player:SetCharacterData("foo", "bar")

-- in Helix
client:GetCharacter():SetData("foo", "bar")
```

The use of the character object allows you to access other characters a player might own without needing to have them be the active character, or even access them when the player is not on the server. Overall, the use of the character object may seem like a complex concept, but will simplify a lot of things once you get the hang of the idea.

# The Libraries

## Animations (`ix.anim`)
Clockwork features many functions to set up animations for a specific model. Helix too has this functionality. Helix has one function instead that pairs a model to a specific "animation class" (grouping of animation types). So, all one needs to do is find the appropriate animation class to match the model with. Looking at the Clockwork function name should tell you.

```
-- before
Clockwork.animation:AddCivilProtectionModel("models/mymodel.mdl")

-- after
ix.anim.SetModelClass("models/mymodel.mdl", "metrocop")
```

## Attributes (`ix.attributes`)
Attributes allow the player to boost certain abilities over time. Both frameworks require one to register attributes, but they are done differently. In Clockwork, the `ATTRIBUTE` table needs to be defined and registered manually. In Helix, the `ATTRIBUTE` table is automatically defined and registered for you. All you need to do is have `ATTRIBUTE.value = "value"`. The basic parts of the attribute needed is `ATTRIBUTE.name` and `ATTRIBUTE.description`.

One extra feature for attributes in Helix is `ATTRIBUTE:OnSetup(client, value)` which is a function that gets called on spawn to apply any effects. For example, the stamina attribute changes the player's run speed by adding the amount of stamina points the player has.

You can find an example at [https://github.com/NebulousCloud/helix/blob/master/plugins/stamina/attributes/sh_stm.lua](https://github.com/NebulousCloud/helix/blob/master/plugins/stamina/attributes/sh_stm.lua)

## Classes (`ix.class`)
Classes are a part of the factions. They basically are a more specific form of a faction. Factions in Helix and Clockwork work similarly. For instance, all classes are placed in the `classes` folder under the schema folder and use `CLASS` as the main variable inside the file.

However:

- You do not need to use `local CLASS = Clockwork.class:New("My Class")`. Instead, `CLASS` is already defined for you and you set the name using `CLASS.name = "My Class"`
- `CLASS.factions` is *not* a table, so `CLASS.factions = {FACTION_MYFACTION}` becomes `CLASS.faction = FACTION_MYFACTION`
- You do not need to use `CLASS:Register()` as classes are registered for you after the file is done processing.
- Classes are *optional* for factions rather than being required.

## Commands (`ix.command`)
Commands no longer need to be in separate files. Instead, they are just placed into one large file. However, if you really wanted you can register multiple commands across multiple files or however you want. One thing you may notice is Clockwork uses a _COMMAND_ table while Helix does not always. It is simply a design preference. You can find examples at [https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_commands.lua](https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_commands.lua)

It should be noted that:

- `COMMAND.tip` is not used.
- `COMMAND.text` is not used.
- `COMMAND.flags` is not used.
- `COMMAND.arguments` does not need to be defined if no arguments are needed but is defined as a table of argument types when needed `arguments = {ix.type.character, ix.type.number}`. See `ix.command.CommandArgumentsStructure` for details.
- `COMMAND.access` for checking whether or not a person is a (super)admin can be replaced with `adminOnly = true` or `superAdminOnly = true` in the command table.

## Configurations (`ix.config`)
In Helix, the method of adding configurations that can be changed by server owners is heavily simplified. [See an example here](https://github.com/NebulousCloud/helix/blob/master/gamemode/config/sh_config.lua).

Adding a configuration is as follows:

```
-- before
Clockwork.config:Add("run_speed", 225)

-- after
ix.config.Add("runSpeed", 235, ...)
```
You'll notice that ellipses (...) were added at the end. This is because there are more arguments since adding configuration information has been placed into one function. Additionally:

- `Clockwork.config:ShareKey()` is not needed.
- The 3rd argument for `Clockwork.config:AddToSystem(name, key, description, min, max)` is also the 3rd argument for `ix.config.Add`
- The 4th argument for `ix.config.Add` is an optional function that is called when the configuration is changed.
- The 5th argument for `ix.config.Add` is a table. You can specify the category for the configuration to group it with other configurations. There is also a data table inside which can be used to determine the minimum value and maximum value for numbers. Check out [an example here](https://github.com/NebulousCloud/helix/blob/master/gamemode/config/sh_config.lua). See also `ix.config`.

## Currency (`ix.currency`)
Updating your currency code is simple:

```
-- before
Clockwork.config:SetKey("name_cash", "Tokens")
Clockwork.config:SetKey("name_cash", "Dollars") -- another example

-- after
ix.currency.Set("", "token", "tokens")
ix.currency.Set("$", "dollar", "dollars")
```

Note that you need to provide a symbol for that currency (€ for Euro, £ for Pound, ¥ for Yen, etc.) or just leave it as an empty string (`""`) and then provide the singular form of the name for the currency, then the plural form.

## Datastream
Helix uses the [net library](http://wiki.garrysmod.com/page/Net_Library_Usage) whereas Clockwork uses datastream ([netstream](https://github.com/alexgrist/NetStream/blob/master/netstream2.lua)).

If you're unfamiliar with the net library, you can include the netstream library to your schema by downloading [netstream](https://github.com/alexgrist/NetStream/blob/master/netstream2.lua) to `schema/libs/thirdparty/sh_netstream2.lua` and adding `ix.util.Include("libs/thirdparty/sh_netstream2.lua")` to your `sh_schema.lua` file.

Starting a datastream:

```
-- before
Clockwork.datastream:Start(receiver, "MessageName", {1, 2, 3});

-- after
netstream.Start(receiver, "MessageName", 1, 2, 3)
```

Receiving a datastream:

```
-- before
Clockwork.datastream:Hook("MessageName", function(player, data)
	local a = data[1];
	local b = data[2];
	local c = data[3];

	print(a, b, c);
end);

-- after
netstream.Hook("MessageName", function(client, a, b, c)
	print(a, b, c)
end)
```

## Factions (`ix.faction`)
Factions, like classes, are pretty similar too. They share pretty much the same differences as classes in Clockwork and Helix do.

For instance:

- You do not need to use `local FACTION = Clockwork.faction:New("Name Here")`, instead `FACTION` is already defined for you and you set the name using `FACTION.name = "Name Here"`
- `FACTION.whitelist = true` is changed to `FACTION.isDefault = false`
- `FACTION.models` does not need a male and female part. Instead, all the models are combined into one big list.
- `function FACTION:GetName(name)` becomes `function FACTION:GetDefaultName(name)`
- `FACTION.description = "Describe me"` is added to the faction.
- `FACTION_MYFACTION = FACTION:Register()` becomes `FACTION_MYFACTION = FACTION.index`

## Flags (`ix.flag`)
Flags are functionally equivalent in Helix. To add a new flag:

```
-- before
Clockwork.flag:Add("x", "Name", "Description")

-- after
ix.flag.Add("x", "Description")
```

To check or manipulate a character's flag(s):

```
-- before
Clockwork.player:GiveFlags(player, flags)
Clockwork.player:TakeFlags(player, flags)
Clockwork.player:HasFlags(player, flags)

-- after
client:GetCharacter():GiveFlags(flags)
client:GetCharacter():TakeFlags(flags)
client:GetCharacter():HasFlags(flags)
```

## Inventories (`Inventory`)
Inventories have also had a change in the way they work that may seem very different than Clockwork. Similar to how characters are their own objects, inventories become their own objects as well. These inventory objects belong to character objects, which belongs to players. So, this creates a chain of objects which is neat. The use of inventories as objects makes it very simple to attach inventories to anything.

To access a player's inventory, you need to use `client:GetCharacter():GetInventory()` which returns the main inventory object for the player's character. You can also access all loaded inventories with `ix.item.inventories` but that is not important right now.

## Items (`Item`)
As discussed above, inventories contain items. Items are still used in inventories and world entities, use default class data, have callback functions, and can contain unique item data per instance.

### Setting up items
Every time needs to be registered, or have information about it (such as the name, model, what it does, etc.) defined. In Clockwork, you have your items defined in schemas/plugins under the items folder.

So let's start with the differences in structure in the item file.

- `local ITEM = Clockwork.item:New();` is removed
- `ITEM.uniqueID` is *completely* optional
- Replace `ITEM.cost` with `ITEM.price`
- `ITEM:Register()` is removed

### Item Sizes
Helix's inventory uses a grid and utilizes width and height instead of weight as a means of inventory capacity. This means you will have to change your item's weight (`ITEM.weight`) to something that might be analagous to the item's size using `ITEM.width` and `ITEM.height`. The item's size must be at least one by one grid cell. It's up to you to balance the sizes of items in your use case - taking into account how many items a character might have at once, the default inventory size set in the config, etc.

### Item Functions
Item functions are defined very differently than they are in Clockwork. For example:

```
-- before
function ITEM:OnUse(player, entity)
	print("My name is: " .. player:Name(), entity)
end

-- after
ITEM.functions.Use = {
	OnRun = function(item)
		print("My name is: " .. item.player, item.entity)
	end
}
```

All item functions are defined in the `ITEM.functions` table. This allows the drop-down menus when using the item a lot easier and cleaner to generate dynamically. There is also more control of the icons used for the options, whether or not the function should be displayed, etc.

You can see an example of a water item here: [https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/items/sh_water.lua](https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/items/sh_water.lua)

Here, we can define what happens when the function is run, what the icon is, and what sound it plays when used. It is basically put into one area rather than being scattered among hooks and stuff.

### Giving/Taking Items
So before we can give/take items, we need to understand what the *item instance* is. Using the analogy earlier about how the inventory system is like a forum, and inside the forum are posts (the items in this case), we can think of instancing an item as making a new post on a forum. So when we talk about an *item instance*, it is an item that has been created in the past. The reason we use an item instance (which is its own object too, neat!) is to make each item ever created unique. Each item instance can have its own data unique to itself.

Clockwork also uses an item instance system where you have to instance an item. So, to instance an item in Clockwork you would use:

```
item = Clockwork.item:CreateInstance("item")
```

And this would create a new instance of an item. Helix's instancing system is slightly different. Instead of having the function return the instance like it does in Clockwork, Helix relies on a callback to pass the instance. The reason for this is the item must be inserted into the database to get a unique number to represent that item. This is not done instantly, otherwise servers would freeze when new items are made. Clockwork uses the time and adds a number to get the numeric ID for an item, which allows the item to be returned which "solves" the issue, but I digress.

The Helix equivalent would be:

```
ix.item.Instance(0, "item", data, x, y, function(item) end)
```

Let's break down the differences:

- For Helix's item instance, the 1st argument (`0`) is the inventory that the item belongs to. You can specify 0 so it does not belong to any inventory.
- The data argument is *optional* and is just a table for the item data.
- *x* and *y* are the position of the items in inventory. You can find an available *x* and *y* with `inventory:FindEmptySlot()`.
- The function is an *optional* argument that passes the item instance. This is where you can directly access the new item.

Keep in mind that Helix will simplify the item system for you when it can. Normally, you would not need to instance an item yourself unless you were doing something advanced.

So you might be wondering, how do I spawn an item in the map, and how do I give a player an item? In Clockwork, you would do the following:

```
-- spawning an item in the map
Clockwork.entity:CreateItem(player, Clockwork.item:CreateInstance("item"), Vector(1, 2, 3));

-- giving a player an item
player:GiveItem(Clockwork.item:CreateInstance("item"));
```

The equivalent in Helix would be:

```
-- spawning an item in the map
ix.item.Spawn("item", Vector(1, 2, 3))

-- giving a player an item
client:GetCharacter():GetInventory():Add("test")
```

So in these two examples, the whole deal of instancing items is done for you in Helix!

# Hooks
You will need to modify the function name and arguments for your schema or plugin hooks.

```
-- before
function Schema:PlayerPlayPainSound(player, gender, damageInfo, hitGroup)
	-- ...
end

-- after
function Schema:GetPlayerPainSound(client)
	-- ...
end
```

You can see the documented hooks for the schema and plugins in the `Plugin` section.

# Conclusion
Overall, most of the conversion from Clockwork to Helix is simply renaming a certain function and/or switching the order of arguments around. Both are frameworks so they function similarly.

You may want to use our HL2 RP schema example for reference which can be found at [https://github.com/NebulousCloud/helix-hl2rp](https://github.com/NebulousCloud/helix-hl2rp)
