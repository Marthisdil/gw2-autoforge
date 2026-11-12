# Changelog

All notable changes to AutoForge are listed here, newest first.

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
