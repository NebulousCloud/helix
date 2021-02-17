<p align="center">
	<img src="https://raw.githubusercontent.com/NebulousCloud/helix/master/docs/banner.gif" alt="Helix" />
</p>

<p align="center">
	<a href="https://discord.gg/2AutUcF">
		<img src="https://img.shields.io/discord/505957257125691423.svg" alt="Discord" />
	</a>
	<a href="https://github.com/NebulousCloud/helix/actions">
		<img src="https://img.shields.io/github/workflow/status/NebulousCloud/helix/CI" alt="Build Status" />
	</a>
</p>

Helix is a framework for roleplay gamemodes in [Garry's Mod](https://gmod.facepunch.com/), based off of [NutScript 1.1](https://github.com/rebel1324/NutScript). Helix provides a stable, feature-filled, open-source, and DRM-free base so you can focus more on the things you want: making gameplay.

## Getting Started
Visit the getting started guide in the [documentation](https://docs.gethelix.co/manual/getting-started/) for an in-depth guide.

If you know what you're doing, a quick start for bootstrapping your own schema is forking/copying the skeleton schema at https://github.com/nebulouscloud/helix-skeleton. The skeleton contains all the important elements you need to have a functioning schema so you can get to coding right away.

You can also use our HL2 RP schema at https://github.com/nebulouscloud/helix-hl2rp as a base to work off of if you need something more fleshed out.

## Plugins
If you'd like to enhance your gamemode, you can use any of the freely provided plugins available at the [Helix Plugin Center](https://plugins.gethelix.co). It is also encouraged to submit your own plugins for others to find and use at https://github.com/nebulouscloud/helix-plugins

## Documentation
Up-to-date documentation can be found at https://docs.gethelix.co. This is automatically updated when commits are pushed to the master branch.

If you'd like to ask some questions or integrate with the community, you can always join our [Discord](https://discord.gg/2AutUcF) server. We highly encourage you to search through the documentation before posting a question - the docs contain a good deal of information about how the various systems in Helix work, and it might explain what you're looking for.

### Building documentation
If you're planning on contributing to the documentation, you'll probably want to preview your changes before you commit. The documentation can be built using [LDoc](https://github.com/impulsh/ldoc) - note that we use a forked version to add some functionality. You'll need [LuaRocks](https://luarocks.org/) installed in order to get started.

```shell
# installing ldoc
git clone https://github.com/impulsh/ldoc
cd ldoc
luarocks make

# navigate to the helix repo folder and run
ldoc .
```

You may not see the syntax highlighting work on your local copy - you'll need to copy the files in `docs/js` and `docs/css` over into the `docs/html` folder after it's done building.

## Contributing
Feel free to submit a pull request with any fixes/changes that you might find beneficial. Currently, there are no solid contributing guidelines other than keeping your code consistent with the rest of the framework.

## Acknowledgements
Helix is a fork of NutScript 1.1 by [Chessnut](https://github.com/brianhang) and [rebel1324](https://github.com/rebel1324).
