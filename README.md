# AutoForge

An AutoHotkey v2 script for Guild Wars 2 that repeats Mystic Forge crafts for you.
You save two screen positions, the forge's **Refill** button and its **Forge**
button, and AutoForge clicks them in a loop. It can run a set number of crafts or
keep going until you stop it.

## Video tour

A short silent walkthrough of the AutoForge window and every setting: the theme
toggle, the GitHub link, changing hotkeys, theme, text size and updates (about
3 minutes). Press play to watch it here.

https://github.com/user-attachments/assets/0511841d-4a38-4569-a788-128a5fad1267

To watch it offline, [download the MP4](https://github.com/Marthisdil/gw2-autoforge/releases/download/v3.5.0/AutoForge-v3.5.0-tour.mp4)
(7 MB) from the v3.5.0 release.

## Features

- **Two-click cycle:** Refill, then Forge, then a short wait for the forge animation, then repeat.
- **Quantity limit:** Enter how many crafts to make, or leave the box blank to run until stopped.
- **Pause and resume:** Hold the run with a hotkey without losing your cycle count.
- **Automatic pause:** The run holds when you switch away from the game and picks up again when you switch back.
- **Status window:** A small window at the top of the screen shows the cycle count, the current status, and the controls. It stays on top of the game without taking focus.
- **Easy on the eyes:** Light or dark theme, and four text sizes.
- **Updates:** Optionally checks GitHub for a newer version and installs it for you, after asking.

## Requirements

- Windows with [AutoHotkey v2.0](https://www.autohotkey.com/) or later
- Guild Wars 2 (64-bit client, `Gw2-64.exe`)

## Installation

1. [Install AutoHotkey v2](https://www.autohotkey.com/).
2. Download `AutoForge.ahk` from the [latest release](https://github.com/Marthisdil/gw2-autoforge/releases/latest).
3. Double-click `AutoForge.ahk` to start it. The AutoForge window appears at the top of your screen.

After that, AutoForge can keep itself up to date. See [Updating AutoForge](#updating-autoforge).

## How to use it

1. In Guild Wars 2, open the Mystic Forge and make your recipe once by hand, so the forge's **Refill** button is available.
2. Hover over the **Refill** button and press **Ctrl+Alt+Q**.
3. Hover over the **Forge** button and press **Ctrl+Alt+W**.
4. Optional: type a number in the **Quantity** box. Leave it blank to run until you stop it.
5. Click back into the game and press **Ctrl+Alt+J** to start.
6. Press **Ctrl+Alt+P** to pause and resume, or **Ctrl+Alt+L** to stop and close the script.

Saved positions last only while the script is open. If you close it, or move or
resize the game window, save both positions again.

## Controls

| Hotkey | Action |
| --- | --- |
| **Ctrl+Alt+Q** | Save position 1: the **Refill** button |
| **Ctrl+Alt+W** | Save position 2: the **Forge** button |
| **Ctrl+Alt+J** | Start the run |
| **Ctrl+Alt+P** | Pause or resume the run |
| **Ctrl+Alt+L** | Stop and exit the script |

These are the defaults. You can change them, as described below.

## Changing the hotkeys

1. Click the **gear button** (⚙) in the top-right corner of the AutoForge window.
2. Click the box next to an action and press the key combination you want.
   Backspace clears a box, which sets it back to its default.
3. Click **Save**. The new keys work right away, and your saved positions are kept.

**Reset to defaults** fills every box with the original keys (click **Save** to
keep them). The window warns you if two actions use the same key, or if a key has
no Ctrl, Alt, Shift or Win. A key with no modifier stops working in the game while
AutoForge is open. You can't open the window during a run.

### Using the Win key, or editing the file

The key boxes can't record the Windows (Win) key. To use it, edit the settings file
by hand. AutoForge creates `AutoForge.ini` in the same folder as the script the
first time it starts:

```ini
[Hotkeys]
SavePos1=Ctrl+Alt+Q
SavePos2=Ctrl+Alt+W
Start=Ctrl+Alt+J
Pause=Ctrl+Alt+P
Exit=Ctrl+Alt+L

[Settings]
Theme=Light
TextSize=Medium
CheckForUpdates=Off
```

1. In the gear window, click **Open AutoForge.ini** (or open the file in any text editor).
2. Change any key. Use the modifiers `Ctrl`, `Alt`, `Shift` and `Win` joined with `+`, ending in a key, for example `Win+J`, `Ctrl+Alt+Q`, `Shift+F8` or `F9`. See the [AutoHotkey key list](https://www.autohotkey.com/docs/v2/KeyList.htm) for key names.
3. Save the file, then click **Reload file** in the gear window (or restart the script).

If an entry isn't a valid key, or two actions use the same key, AutoForge uses
that action's default and shows a message saying what was wrong. To go back to
the defaults, delete a line or the whole file.

Avoid keys you use in the game. A hotkey with no modifier, such as `F9`, stops
that key from reaching Guild Wars 2.

## Updating AutoForge

AutoForge can check this repository's [releases](https://github.com/Marthisdil/gw2-autoforge/releases)
for a newer version and install it for you. This works from v3.5.0 on. For older
versions, download the new `AutoForge.ahk` by hand once.

- **Automatic check (off by default):** In the gear window, set **Check for updates**
  to **At startup**. AutoForge then checks a few seconds after it starts, and only
  speaks up if there's a newer version.
- **Check now:** Click **Check for updates now** in the gear window at any time. It
  tells you if you're already up to date, or if GitHub couldn't be reached.

When a newer version is available, AutoForge shows what's new and asks before it
downloads anything. If you click **Yes**, it:

1. Downloads the new `AutoForge.ahk` from the release.
2. Checks it: it must be the version it says, and AutoHotkey must be able to load it.
   If not, nothing is changed.
3. Keeps your current script as `AutoForge.ahk.bak` in the same folder.
4. Replaces `AutoForge.ahk` and restarts AutoForge.

Your settings in `AutoForge.ini` are kept. Saved mouse positions aren't, so save
both positions again after an update. To go back to the old version, close
AutoForge, delete `AutoForge.ahk` and rename `AutoForge.ahk.bak` to `AutoForge.ahk`.

AutoForge needs to be able to write to its own folder to update itself. The check
only contacts GitHub (`api.github.com`), and doesn't send anything about you or
your settings.

## The AutoForge window

- **Cycles completed:** How many crafts have run, for example `3 / 10` when you set a quantity.
- **Status:** Shows one of:
  - `Idle`: no run yet.
  - `Running` or `Running (until stopped)`: clicking.
  - `Paused (CTRL+ALT+P to resume)`: you paused the run.
  - `Paused (waiting for game window)`: the game isn't the active window.
  - `Done`: the quantity you set has been reached.
  - `Save both positions first (Q / W)`: you pressed Start before saving both positions.
- **Quantity:** How many crafts to run. Blank means run until stopped.
- **Theme button (☾ / ☀):** Switches between the light and dark theme. The keybinding window has the same choice under **Theme**. Your choice is saved in `AutoForge.ini`.
- **Gear button (⚙):** Opens the keybinding window. It also has a **Text size** choice: Small, Medium (the original size), Large or Extra large. Both windows resize to fit right away, and your choice is saved in `AutoForge.ini`. Its update options are described in [Updating AutoForge](#updating-autoforge).
- The status messages and hotkey list show your current hotkeys, not just the defaults.
- The footer shows the script version, the date it was last updated, and a link to this GitHub page. Click the link to open it in your browser.

## Notes

- **Pausing:** Pausing holds the run before the next click. A click that has already been sent still goes through.
- **Game window:** AutoForge only clicks while Guild Wars 2 is the active window. When you switch back, it waits half a second before clicking again so the game can settle.
- **Overlays:** It may not work properly with overlays such as Blish HUD.
- **Hotkeys:** The default hotkeys use Ctrl+Alt so they don't clash with common game keybinds.
- **Use at your own risk:** Check ArenaNet's rules on macros before you use any automation in the game.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Credits

AutoForge is based on the original
[GW2MysticForgeMacro](https://github.com/OctavoPE/GW2MysticForgeMacro) by
[OctavoPE](https://github.com/OctavoPE). Thanks to them for the original script and idea.

## License

AutoForge is released under the [MIT License](LICENSE). You're free to use, change
and share it, as long as you keep the copyright and license notice. This applies to
all versions of AutoForge, including releases before v3.4.1.
