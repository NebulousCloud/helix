
# helix

[![Build Status](https://travis-ci.org/NebulousCloud/helix.svg?branch=master)](https://travis-ci.org/NebulousCloud/helix)

Helix is a *work-in-progress* framework for roleplay gamemodes in [Garry's Mod](https://gmod.facepunch.com/), based off of [NutScript 1.1](https://github.com/rebel1324/NutScript). Helix provides a stable, feature-filled, open-source, and DRM-free base so you can focus more on the things you want: making gameplay.

Since Helix is still in active development, we'd advise you not to use it for any of your projects just yet - many things can and will change until we tweak and polish things off enough for an eventual release.

## Documentation
Up-to-date documentation can be found at https://nebulouscloud.github.io/helix/. This is automatically updated when commits are pushed to the master branch. As it currently stands, you might find it a bit lacking. However, this will definitely improve over time as we continue polishing off the framework.

If you have questions that can't be answered through the documentation, we'd recommend you check out the NutScript community since a lot of the concepts can still be applied to Helix.

### Building documentation
We use [LDoc](https://github.com/stevedonovan/LDoc) to build our documentation. The easiest way to start building is through [LuaRocks](https://luarocks.org/).
```
luarocks install ldoc
ldoc -c docs/config.ld ./
```
You may not see the syntax highlighting work on your local copy - you'll need to copy the files in `docs/js` and `docs/css` over into the `docs/html` folder after it's done building.

## Contributing
Feel free to submit a pull request with any fixes/changes that you might find beneficial. Currently, there are no solid contributing guidelines other than keeping your code consistent with the rest of the framework.

## Acknowledgements
Helix is a fork of NutScript 1.1 by [Chessnut](https://github.com/brianhang) and [rebel1234](https://github.com/rebel1324).

- NutScript Discord: https://discord.gg/QUbmYuD
- NutScript Forums: https://nutscript.net/
- NutScript Wiki: https://nutscript.miraheze.org/wiki/Main_Page
- NutScript Gitter: https://gitter.im/Chessnut/NutScript
