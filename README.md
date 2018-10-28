
# helix

[![Build Status](https://travis-ci.org/NebulousCloud/helix.svg?branch=master)](https://travis-ci.org/NebulousCloud/helix) [![Discord](https://img.shields.io/discord/505957257125691423.svg)](https://discord.gg/2AutUcF)

Helix is a framework for roleplay gamemodes in [Garry's Mod](https://gmod.facepunch.com/), based off of [NutScript 1.1](https://github.com/rebel1324/NutScript). Helix provides a stable, feature-filled, open-source, and DRM-free base so you can focus more on the things you want: making gameplay.

## Getting Started
To start working on your gamemode, you'll need to set up a schema for Helix. This is a specially structured gamemode that uses Helix as its base - but instead of creating all the files and bootstrapping properly yourself, you can fork/copy the skeleton schema that has all of this done already at https://github.com/NebulousCloud/helix-skeleton. The skeleton contains all the important elements you need to have a functioning schema so you can get coding right away.

You can also use our HL2 RP schema at https://github.com/NebulousCloud/helix-hl2rp as a base to work off of if you need something more fleshed out.

## Documentation
Up-to-date documentation can be found at https://nebulouscloud.github.io/helix/. This is automatically updated when commits are pushed to the master branch. As it currently stands, you might find it a bit lacking. However, this will definitely improve over time as we continue polishing off the framework.

If you'd like to ask some questions or integrate with the community, you can always join our [Discord](https://discord.gg/2AutUcF) server.

### Building documentation
We use [LDoc](https://github.com/stevedonovan/LDoc) to build our documentation. The easiest way to start building is through [LuaRocks](https://luarocks.org/).
```
luarocks install ldoc
ldoc .
```
You may not see the syntax highlighting work on your local copy - you'll need to copy the files in `docs/js` and `docs/css` over into the `docs/html` folder after it's done building.

## Contributing
Feel free to submit a pull request with any fixes/changes that you might find beneficial. Currently, there are no solid contributing guidelines other than keeping your code consistent with the rest of the framework.

## Acknowledgements
Helix is a fork of NutScript 1.1 by [Chessnut](https://github.com/brianhang) and [rebel1324](https://github.com/rebel1324).
