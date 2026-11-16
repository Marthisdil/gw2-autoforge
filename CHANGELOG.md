# Changelog

All notable changes to AutoForge are listed here, newest first.

## 3.4.1 - 2026-11-16
- The script's header comments now give its license (MIT) and a link to the
  GitHub repository, where you can find the latest version. Nothing else changed.

## 3.4.0 - 2026-11-15
- Added a text size choice for easier reading: Small, Medium (the original
  size), Large and Extra large. Pick it under **Text size** in the gear window.
- Both windows resize to fit as soon as you pick a size. Buttons, boxes, spacing
  and margins grow with the text, and the main window stays centred at the top
  of the screen.
- Your quantity, status and any keys you've typed but not saved are kept when
  the windows resize. The size is saved in `AutoForge.ini`.
- **Reload file** in the gear window now also reloads the theme and text size.

## 3.3.0 - 2026-11-15
- Added a dark theme. Click the moon button next to the gear to switch to it,
  and the sun button to switch back. The gear window also has a **Theme** choice.
  The theme is saved in `AutoForge.ini` and used the next time AutoForge starts.

## 3.2.0 - 2026-11-14
- Hotkeys can now be changed. Click the gear button in the AutoForge window,
  click a box, press the new key combination and click **Save**. New keys apply
  right away, and saved mouse positions are kept. The defaults are unchanged.
- Keybindings are stored in `AutoForge.ini` next to the script, created with the
  defaults on first launch. The gear window can't record the Win key; to use
  Win, edit the file by hand and click **Reload file** in the gear window.
- The window and status messages show your current hotkeys.
- Invalid or duplicate keybindings fall back to their defaults, with a message
  listing what was wrong.

## 3.1.0 - 2026-11-12
- Added CTRL+ALT+P to pause and resume a run. Pausing holds the run before the
  next click and keeps the cycle count; the status line shows when it is paused.

## 3.0.1 - 2026-11-12
- Renamed the script from `AutoForge v3.0.ahk` to `AutoForge.ahk`. The version
  is now shown only inside the script and in its window, not in the filename.

## 3.0 - 2026-11-03
- Ported to AutoHotkey v2.
- Added a quantity box: forge a set number of cycles, or leave it blank to run
  until stopped.
- Added a live cycle counter and status line in the instruction window.
- Pauses automatically when the game window is not active and resumes when it is.
- Keeps the instruction window on top of the game without stealing focus.
