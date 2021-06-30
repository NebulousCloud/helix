# Getting Started
It's pretty easy to get started with creating your own schema with Helix. It requires a bit of bootstrapping if you're starting from scratch, but you should quickly be on your way to developing your schema after following one of the below sections in this guide.

# Installing the framework
Before you start working on your schema, you'll need to install Helix onto your server. The exact instructions will vary based on your server provider, or if you're hosting the server yourself.

You'll need to download the framework from [GitHub](https://github.com/NebulousCloud/helix) into a folder called `helix`. This folder goes into your server's `gamemodes` folder at `garrysmod/gamemodes/helix`. That's it! The framework is now installed onto your server. Of course, you'll need to restart your server after installing the framework and a schema.

# MySQL usage
By default, Helix will use SQLite (which is built into Garry's Mod) to store player/character data. This requires no configuration and will work "out of the box" after installing and will be fine for most server owners. However, you might want to connect your database to your website or use multiple servers with one database - this will require the usage of an external database accessible elsewhere. This will require the use of a MySQL server. Some server providers will provide you with a MySQL database for free to use with your server.

## Installing
Helix uses the [MySQLOO](https://github.com/FredyH/MySQLOO) library to connect to MySQL databases. You'll need to follow the instructions for installing that library onto your server before continuing. In a nutshell, you need to make sure `gmsv_mysqloo_win32.dll` or `gmsv_mysqloo_linux.dll` (depending on your server's operating system) is in the `garrysmod/lua/bin` folder. 

In older versions of MySQLOO, you previously required a .dll called `libmysql.dll` to place in your `root` server folder, where `srcds`/`srcds_linux` was stored. Newer versions of MySQLOO no longer require this.

## Configuring
Now that you've installed MySQLOO, you need to tell Helix that you want to connect to an external MySQL database instead of using SQLite. This requires creating a `helix.yml` configuration file in the `garrysmod/gamemodes/helix` folder. There is an example one already made for you called `helix.example.yml` that you can copy and rename to `helix.yml`.

The first thing you'll need to change is the `adapter` entry so that it says `mysqloo`. Next is to change the other entries to match your database's connection information. Here is an example of what your `helix.yml` should look like:

```
database:
  adapter: "mysqloo"
  hostname: "myexampledatabase.com"
  username: "myusername"
  password: "mypassword"
  database: "helix"
  port: 3306
```

The `hostname` field can either be a domain name (like `myexampledatabase.com`) or an IP address (`123.123.123.123`). If you don't know what the `port` field should be, simply leave it as the default `3306`; this is the default port for MySQL database connections. The `database` field is the name of the database that you've created for Helix. Note that it does not need to be `helix`, it can be whatever you'd like.

Another important thing to note about this configuration file is that you **must** indent with **two spaces only**. `database` should not have any spacing before it, and all other entries must have two spaces before them. Failing to ensure this will make the configuration file fail to load.

# Starting with the HL2 RP schema (Basic)
This section is for using the existing HL2 RP schema as a base for your own schema. It contains a good amount of example code if you need a stronger foundation than just a skeleton.

First, you'll need to download the schema from [GitHub](https://github.com/NebulousCloud/helix-hl2rp). Make sure that you download the contents of the repository into a folder called `ixhl2rp` and place it into your `garrysmod/gamemodes` folder. That's all you'll need to do to get the schema installed, other than setting your gamemode to `ixhl2rp` in the server's command line.

# Starting with the skeleton (Basic)
If you don't want excess code you might not use, or prefer to build from an almost-empty foundation that covers the basic bootstrapping, then the skeleton schema is for you. The skeleton schema contains a lot of comments explaining why code is laid out in a certain way, and some other helpful tips/explanations. Make sure you give it a read!

You'll need to download the schema from [GitHub](https://github.com/NebulousCloud/helix-skeleton) into the folder name of your choice - just make sure it's all lowercase with no spaces. Our example for the sake of brevity will be `myschema`. Place the folder into `garrysmod/gamemodes`.

Next up is to modify the gamemode info so that Garry's Mod will properly recognize it. Rename `skeleton.txt` in your schema folder to your folder's name. In our example we would rename `skeleton.txt` to `myschema.txt`. Next, you'll need to modify the contents of `myschema.txt` and replace the existing information with your own - making sure to replace the `"skeleton"` at the top of the file to your folder's name. In our case we would replace it with `"myschema"`. Once you've renamed the file, you're all good to go!

# Converting from Clockwork (Intermediate)
If you are looking to switch to Helix from Clockwork, you can follow the @{converting-from-clockwork|conversion guide}.

# Starting from scratch (Intermediate)
You can always create the gamemode files yourself if you'd like (although we suggest the skeleton schema in general). In general, a schema is a gamemode that is derived from `helix` and automatically loads `schema/sh_schema.lua`. You shouldn't have your schema files outside of the `schema` folder. The files you'll need are as follows:

`gamemode/init.lua`
```
AddCSLuaFile("cl_init.lua")
DeriveGamemode("helix")
```

`gamemode/cl_init.lua`
```
DeriveGamemode("helix")
```

`schema/sh_schema.lua`
```
Schema.name = "My Schema"
Schema.author = "me!"
Schema.description = "My awesome schema."

-- include your other schema files
ix.util.Include("cl_schema.lua")
ix.util.Include("sv_schema.lua")
-- etc.
```
