> [!WARNING]
> Shadow Engine is under active development and slightly not ready for public use.<br>
> Expect breaking changes, missing features and unstable builds.<br>
> Use at your own risk.

<p align="center">
  <img src="./docs/images/SE_Logo.png" alt="Shadow Engine Logo" width="400" />
</p>

# Friday Night Funkin' - Shadow Engine

A highly modified Psych Engine 0.7.3.

Ready to be source-modded.

> [!NOTE]
> For the lore of this engine see [ORIGIN.md](./docs/ORIGIN.md).

## Differences Between The Original
- Uses our haxelib forks for backporting and fixing stuff
- Uses latest Haxe
- Uses [ANGLE](https://github.com/google/angle) to run Shadow Engine inside [Vulkan](https://en.wikipedia.org/wiki/Vulkan)<br>(Also possibly fixing black boxes in low end? ([with a hack](https://github.com/FNF-SE/angle-build-modified/blob/main/patches/0001-Bend-ANGLE-rules-for-MAX_TEXTURE_SIZE-unconditionally.patch)))
- Uses some code from [P-Slice](https://github.com/Psych-Slice/P-Slice), [Leather Engine (R.I.P.)](https://github.com/Vortex2Oblivion/LeatherEngine), [Codename Engine](https://github.com/CodenameCrew/CodenameEngine)
- Replaced [`flxanimate`](https://github.com/Dot-Stuff/flxanimate) with [`flixel-animate`](https://github.com/MaybeMaru/flixel-animate) for better performance for texture atlases
- Replaced [`hxCodec`](https://github.com/polybiusproxy/hxCodec) with [`hxvlc`](https://github.com/FNF-SE/hxvlc) for better customizability in video cutscenes
- Mobile Support (duh)
- Applies OpenAL Soft Config For better audio
- Slightly more accurate FPS and less RAM Usage
- Unironically winning icons support
- Some 0.6.3 and 1.0 compability
- Little bit Null Safety
- Linux ARM support (FNF on Raspberry Pi baby)
- Kade Engine Results Screen
- PlayState has `changeNoteSkin` for easy in-game note skin changing
- Play as Opponent
- Stripped to only have Test song and some characters<br>(TBD to re-add, see [TODO](./todo/TODO.md))
- Kade Engine Note Timing (man I feel old), VSync and Pop Up Score Option
- Includes all classes as possible into source
- Scriptable States Support!! (ig idk honestly if I [Homura] did good job)
- Supports `.hscript`, `.hxs` and `.hxc` extensions<br>[SIDE NOTE: `.hxc` added as an alias, we don't have scriptable classes support]

Discord server: https://discord.gg/krFK9WWYHg
