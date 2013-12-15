### Module dmc_kolor ###

`dmc_kolor` is a Lua module which brings back the traditional ways of describing colors using RGBA values ( eg, 255, 180, 34 ) instead of the new way using percentage values (eg, 1, .5, .25 ) brought about by the change to Graphics 2.0.

It also gives additional functionality like the ability to use names when setting object colors like "Aqua" or "Red". The module even includes color tables for all of the X11 color definitions.

#### Reasons to use dmc_kolor####

Here are some of the reasons why you would use this module:

* **Your existing code will still work**

	This is perhaps the biggest win because older projects will still work and don't need to be re-written, even long after Corona Labs discontinues the V1 Compatibility Flag.

* **You don't think in HDR**

	There are those who don't think in percentages and don't want to start, even for new projects.  The library allows them to continue describing colors using traditional RGBA values.

* **You still get all of the new Corona Graphics 2.0 features**

	There's no need to turn on the V1 Compatibility Flag, so the engine is using all of the new features. Even with dmc_kolor all of the new HDR functionalty is still available to you.

* **You don't need the extra color space**

	Part of the move was to allow the engine to start supporting more than 8 bits per color channel. For a lot of applications this is overkill and unnecessary so the switch to HDR is pointless.

* **You get more functionality**

	There is more functionality built in, like being able to used named colors, hex colors, mixing RGB and HDR if necessary, etc.

**Examples**

There are examples in the folder `dmc_kolor/examples/` which show different ways to use the `dmc_kolor` library.

**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_kolor.lua

