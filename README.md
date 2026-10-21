# Monster Hunter 3 Ultimate (MH3U) Ultrawide for Cemu

> Also for MH3U on Cemu: [Damage Multiplier](https://github.com/Juan-Pablo-Barrientos/MH3U-Damage-Multiplier) and [Always Have Map](https://github.com/Juan-Pablo-Barrientos/MH3U-Always-Map).

A Cemu graphic pack for **Monster Hunter 3 Ultimate** (MH3U, also called Monster Hunter Tri Ultimate) on the Wii U emulator. It runs the game at an ultrawide resolution such as 3440x1440. You see more to the sides instead of a stretched 16:9 picture, and the HUD keeps its normal shape in the middle of the screen.

## Requirements

- Monster Hunter 3 Ultimate, **US**, title `00050000-10118300`, **update v32**
- Cemu 2.x, tested on Cemu 2.6 with Vulkan

The code patches only apply to that exact game build: the game code checksum must be `0x9d2f15e5`. EUR and MH3G aren't supported yet.

Don't enable the official **Graphics options** pack's resolution setting at the same time. Both change the same render targets.

## Install

1. Copy the `MH3U_Ultrawide` folder into Cemu's `graphicPacks` folder:
   - Normal install: `%APPDATA%\Cemu\graphicPacks\`. Create the `graphicPacks` folder if it doesn't exist.
   - Portable install: `graphicPacks\` next to `Cemu.exe`
2. **Restart Cemu.** It only reads graphic packs when it starts.
3. Open **Options → Graphic packs → Monster Hunter 3 Ultimate → Mods → Ultrawide**, tick it and pick your resolution.
4. Start the game.

Resolutions: 2560x1080, 3440x1440 (default), 3840x1600, 5120x2160, 3840x1080, 5120x1440, and 1920x1080 to turn the effect off.

To confirm it's active, look in `%APPDATA%\Cemu\log.txt` for:

```
Applying patch group 'MH3U_Ultrawide_US_v32'
```

## What changes

- The 3D view fills the whole screen. The vertical field of view stays the same, and you see more on the left and right.
- The HUD (health and stamina, sharpness, party list, minimap, item bar) is drawn at its normal proportions inside the middle 16:9 of the screen.
- Name tags over party members and Felynes stay over their characters.

Tested on Cemu 2.6 at 3440x1440 in Moga Village and on the Deserted Island at night.

### Not checked yet

- Menus (item box, equipment, quest board), cutscenes and the map screen.
- The GamePad screen. The HUD shaders don't know which screen they draw to, so the GamePad view (if you show it) may look squeezed.

## How it works

Addresses are Wii U addresses for US v32.

### Camera

Each frame, the viewport update at `0x02ba0474` sets every camera's aspect ratio from its viewport's integer rectangle: `(x1 - x0) / (y1 - y0)`. The camera keeps far, near, aspect and FOV at `+0x30`, `+0x34`, `+0x38` and `+0x3C`. The patch replaces that divide with a call that multiplies the result by `(width / height) / (16 / 9)`, but only for the full 1920x1080 TV viewport, so smaller views keep their aspect.

The `[TextureRedefine]` rules then render the 1920x1080 targets (and their half, quarter, eighth and sixteenth size copies) at the chosen resolution, scaling width and height separately.

### HUD

The HUD is drawn by three shaders, replaced in this pack:

| Shader | Draws | Squeezed when |
|---|---|---|
| `718db6158513e6cd` (vertex) | Textured panels, frames, gauges | Output `w != 1` |
| `718db61584b2a64d` (vertex) | Untextured gauges and lines | Output `w != 1` |
| `6e024166d3e6ac16` (geometry) | Text, icons, minimap, item bar | Screen-space path (`w == 1`) |

"Squeezed" means `x *= (16 / 9) / (width / height)`. The night overlay is drawn by `718db61584b2a64d` with `w == 1` and is left full width. The geometry shader also draws 3D particles through a projection matrix; those don't have `w == 1` and are left alone.

### Name tags

Name tags are placed by two functions, which call the screen size function at `0x026181f0`/`0x02618298` and `0x026189b0`/`0x02618a5c`. They compute the position as `fraction * width`, where the fraction is 0 to 1 across the screen and the width comes from a "screen size" function at `0x02617ce0` (1920x1080 from `0x10054918`). The patch widens the fraction around the center by the same factor the HUD is squeezed, at `0x02618214`, `0x026182bc`, `0x026189d4` and `0x02618a7c`.

### How it was found

1. The 16:9 aspect value `0x3FE38E39` only exists in two camera objects on the heap. Writing to it didn't stick, so it's recalculated every frame. Searching the code for a float divide followed by a store to `+0x38` led to the viewport update.
2. The HUD shaders were found by dumping shaders (Cemu **Debug → Dump → Shaders**, with the game's shader cache moved aside so every shader compiles fresh), then giving every vertex shader its own squeeze factor in one test run and measuring how far each HUD element moved.
3. The name tag code was found by changing each module's 1920 "screen size" constant in memory, one at a time, and watching which one moved the tags.

## License

[MIT](LICENSE). The render target list and the blur shader `c750d62d484a9fdb` come from the community "Graphics options" pack for MH3U by Skalfate and FrankyBuster ([cemu_graphic_packs](https://github.com/cemu-project/cemu_graphic_packs), CC0).
