; AutoForge
; Version: 3.2.0  (AutoHotkey v2 version)
; Date Updated: 2026-11-14
;
; Requires AutoHotkey v2.0 or later.
;
; Instructions (default hotkeys; change them in AutoForge.ini next to this script):
; CTRL+ALT+Q - Save Mouse Pos 1 (Refill)
; CTRL+ALT+W - Save Mouse Pos 2 (Forge)
; CTRL+ALT+J - Start
; CTRL+ALT+P - Pause/Resume
; CTRL+ALT+L - Stop/Exit
; Keybindings: click the gear button in the AutoForge window to change them.
;   They are saved in AutoForge.ini, which is created with the defaults on first launch.
;   The gear window can't record the Win key; to use Win, edit AutoForge.ini by hand
;   (format: Ctrl, Alt, Shift, Win joined with + and ending in a key, e.g. Win+J),
;   then click "Reload file" in the gear window. An invalid or duplicate entry falls
;   back to its default.
; Quantity box: enter how many to forge, then press Start. The script stops
;   after that many cycles. Leave it blank to run until you press Stop/Exit.
; Cycle order: Refill > Forge > wait > repeat
; Pause/Resume holds the run before the next click and keeps the cycle count.
; The script also pauses automatically when the game window is not active, and resumes when it is.
; The window is kept on top of the game whenever the game window is active.
; Note: May not work properly if using Overlays such as Blish HUD.

#Requires AutoHotkey v2.0

; ---- Version info ----
scriptVersion := "3.2.0"
scriptDate := "2026-11-14"

; ---- Game window (instruction window is kept on top while this is active) ----
gameExe := "Gw2-64.exe"

; ---- Settings file (keybindings) ----
iniFile := A_ScriptDir "\AutoForge.ini"

; ---- Mouse coordinates: use full-screen coordinates (AHK v2 defaults to window-relative) ----
CoordMode "Mouse", "Screen"

; ---- Actions that can be bound to a hotkey (order = order shown in the window) ----
; id is the key name in AutoForge.ini. LoadHotkeys() fills in:
;   raw = the binding in use ("Ctrl+Alt+Q"), hk = AHK syntax ("^!q"), label = "CTRL+ALT+Q".
actions := [
    {id: "SavePos1", default: "Ctrl+Alt+Q", desc: "Save Mouse Pos 1 (Refill)", fn: SavePos1, raw: "", hk: "", label: ""},
    {id: "SavePos2", default: "Ctrl+Alt+W", desc: "Save Mouse Pos 2 (Forge)", fn: SavePos2, raw: "", hk: "", label: ""},
    {id: "Start",    default: "Ctrl+Alt+J", desc: "Start",                     fn: StartRun, raw: "", hk: "", label: ""},
    {id: "Pause",    default: "Ctrl+Alt+P", desc: "Pause/Resume",              fn: TogglePause, raw: "", hk: "", label: ""},
    {id: "Exit",     default: "Ctrl+Alt+L", desc: "Stop/Exit",                 fn: StopExit, raw: "", hk: "", label: ""}
]
keys := Map()   ; id -> display label, e.g. keys["Pause"] = "CTRL+ALT+P"
settingsGui := ""   ; the keybinding window, while it is open

; ---- State (every variable must exist before it is read in v2) ----
pos1X := ""
pos1Y := ""
pos2X := ""
pos2Y := ""
cycleCount := 0
targetQty := 0
running := false
userPaused := false
runStatus := "Status: Running"
pausedStatus := ""

LoadHotkeys()

; ---- Instruction window (always on top, top of screen) ----
guiWidth := 360
guiX := (A_ScreenWidth - guiWidth) // 2
myGui := Gui("+AlwaysOnTop +ToolWindow", "AutoForge")
; Gear button (top right) opens the keybinding window
myGui.SetFont("s12", "Segoe UI Symbol")
gearBtn := myGui.Add("Button", "x" (myGui.MarginX + guiWidth - 32) " ym w32 h28", Chr(0x2699))
gearBtn.OnEvent("Click", OpenSettings)
myGui.SetFont("s9", "Segoe UI")
cycleText := myGui.Add("Text", "xm ym w" (guiWidth - 40), "Cycles completed: 0")
statusText := myGui.Add("Text", "w" (guiWidth - 40) " y+2", "Status: Idle")
myGui.Add("Text", "xm y+8 Section", "Quantity (blank = until stopped):")
qtyEdit := myGui.Add("Edit", "x+8 yp-3 w60 Number Limit6")
helpText := myGui.Add("Text", "xm w" guiWidth " y+8 r" actions.Length, HotkeyHelpText())
myGui.SetFont("s8 cGray")
myGui.Add("Text", "xm w" guiWidth " y+6", "Note: May not work properly if using Overlays such as Blish HUD.")
myGui.Add("Text", "w" guiWidth " y+4", "v" scriptVersion "  |  Updated: " scriptDate)
myGui.Show("x" guiX " y0 NoActivate")
guiHwnd := myGui.Hwnd

SetTimer(KeepOnTop, 250)

; ---- Hotkey actions ----

SavePos1(*)
{
    global pos1X, pos1Y
    CoordMode "Mouse", "Screen"
    MouseGetPos &pos1X, &pos1Y
}

SavePos2(*)
{
    global pos2X, pos2Y
    CoordMode "Mouse", "Screen"
    MouseGetPos &pos2X, &pos2Y
}

StartRun(*)
{
    global running, userPaused, cycleCount, targetQty, runStatus
    if running
        return
    CoordMode "Mouse", "Screen"

    ; Both positions must be saved first
    if (pos1X = "" or pos2X = "")
    {
        SetStatus("Status: Save both positions first (" keys["SavePos1"] " / " keys["SavePos2"] ")")
        return
    }

    ; Read the quantity box (blank or 0 = run until stopped)
    qtyText := Trim(qtyEdit.Value)
    targetQty := (qtyText = "") ? 0 : Integer(qtyText)

    running := true
    userPaused := false
    cycleCount := 0
    cycleText.Value := CounterLabel()
    runStatus := "Status: Running"
    if (targetQty = 0)
        runStatus .= " (until stopped)"
    SetStatus(runStatus)

    Loop
    {
        WaitUntilReady()
        Click(pos1X, pos1Y)
        Sleep 100
        WaitUntilReady()
        Click(pos2X, pos2Y)
        Sleep 2500
        cycleCount += 1
        cycleText.Value := CounterLabel()
        if (targetQty > 0 and cycleCount >= targetQty)
            break
    }

    running := false
    userPaused := false
    SetStatus("Status: Done")
}

; Pause/Resume. Only does something while a run is in progress.
; Takes effect before the next click; a click already sent is not undone.
TogglePause(*)
{
    global userPaused
    if !running
        return
    userPaused := !userPaused
    SetStatus(userPaused ? pausedStatus : runStatus)
}

StopExit(*)
{
    ExitApp
}

; ---- Keybinding functions ----

; Reads each action's hotkey from AutoForge.ini and registers it, replacing any
; hotkeys registered by an earlier call (so new keys apply without restarting).
; Creates the file with the defaults if it is missing, and adds any missing entries.
; Invalid or duplicate entries fall back to the default and are reported in one message.
LoadHotkeys()
{
    global pausedStatus
    if !FileExist(iniFile)
        WriteDefaultIni()

    for a in actions
    {
        if (a.hk != "")
            try Hotkey(a.hk, "Off")
        a.hk := ""
    }

    problems := []
    used := Map()   ; AHK hotkey string -> id that claimed it
    for a in actions
    {
        raw := Trim(IniRead(iniFile, "Hotkeys", a.id, ""))
        if (raw = "")
        {
            raw := a.default
            IniWrite(raw, iniFile, "Hotkeys", a.id)
        }

        hk := ParseHotkey(raw, &label)
        if (hk = "")
        {
            problems.Push(a.id "=" raw "  (not a valid key, using " a.default ")")
            raw := a.default
            hk := ParseHotkey(raw, &label)
        }
        else if used.Has(hk)
        {
            problems.Push(a.id "=" raw "  (already used by " used[hk] ", using " a.default ")")
            raw := a.default
            hk := ParseHotkey(raw, &label)
        }

        if used.Has(hk)
        {
            problems.Push(a.id " has no hotkey: its default " a.default " is also taken by " used[hk])
            label := "(unbound)"
        }
        else
        {
            try
            {
                Hotkey(hk, a.fn, "On T2")   ; T2 lets Start ignore a second press while running
                used[hk] := a.id
                a.hk := hk
            }
            catch as err
            {
                problems.Push(a.id "=" raw "  (" err.Message ")")
                label := "(unbound)"
            }
        }
        a.raw := raw
        a.label := label
        keys[a.id] := label
    }

    ; Show the new keys in the main window (it doesn't exist yet on first load)
    pausedStatus := "Status: Paused (" keys["Pause"] " to resume)"
    if IsSet(helpText)
        helpText.Value := HotkeyHelpText()

    if problems.Length
    {
        msg := "Some keybindings in AutoForge.ini could not be used:`n`n"
        for p in problems
            msg .= p "`n"
        msg .= "`nFix them with the gear button, or in " iniFile " and then Reload file."
        MsgBox(msg, "AutoForge keybindings", "Icon! 0x40000")   ; 0x40000 = always on top
    }
}

; Creates AutoForge.ini with the default keybindings and a short how-to.
WriteDefaultIni()
{
    text := "; AutoForge keybindings`n"
        . "; Format: modifiers Ctrl, Alt, Shift, Win joined with + and ending in a key.`n"
        . "; Examples: Ctrl+Alt+Q   Shift+F8   F9   Ctrl+Numpad1`n"
        . "; Key names: https://www.autohotkey.com/docs/v2/KeyList.htm`n"
        . "; Easiest: click the gear button in the AutoForge window. To use the Win key,`n"
        . "; edit this file by hand, save it, then click Reload file in the gear window.`n"
        . "; Delete a line (or this whole file) to go back to the default.`n"
        . "`n[Hotkeys]`n"
    for a in actions
        text .= a.id "=" a.default "`n"
    FileAppend(text, iniFile)
}

; Turns a friendly hotkey such as "Ctrl+Alt+Q" into AHK syntax ("^!q").
; Sets display to an uppercase label ("CTRL+ALT+Q"). Returns "" if it is not valid.
ParseHotkey(text, &display)
{
    display := ""
    parts := StrSplit(Trim(text), "+", " `t")
    if (parts.Length = 0)
        return ""
    key := parts.Pop()
    if (key = "" or GetKeyName(key) = "")
        return ""

    mods := ""
    label := ""
    for part in parts
    {
        switch part, false   ; case-insensitive
        {
            case "Ctrl", "Control": sym := "^", name := "CTRL"
            case "Alt":             sym := "!", name := "ALT"
            case "Shift":           sym := "+", name := "SHIFT"
            case "Win":             sym := "#", name := "WIN"
            default: return ""
        }
        if InStr(mods, sym)
            return ""
        mods .= sym
        label .= name "+"
    }
    display := label StrUpper(key)
    return mods StrLower(key)   ; lowercase so "Q" and "q" count as the same hotkey
}

; Turns AHK syntax from a Hotkey control ("^+Q") into the friendly form ("Ctrl+Shift+Q").
FriendlyHotkey(hk)
{
    out := ""
    while (StrLen(hk) > 1 and InStr("^!+#", SubStr(hk, 1, 1)))
    {
        switch SubStr(hk, 1, 1)
        {
            case "^": out .= "Ctrl+"
            case "!": out .= "Alt+"
            case "+": out .= "Shift+"
            case "#": out .= "Win+"
        }
        hk := SubStr(hk, 2)
    }
    return out (StrLen(hk) = 1 ? StrUpper(hk) : hk)
}

; ---- Keybinding window (gear button) ----

; Opens a small window with one key box per action. Hotkeys are suspended while it is
; open, so pressing a combination types it into the box instead of running the action.
OpenSettings(*)
{
    global settingsGui
    if running
    {
        SetStatus("Status: Wait for the run to finish to change keys")
        return
    }
    if (settingsGui != "")
    {
        settingsGui.Show()
        return
    }

    Suspend(true)
    sg := Gui("+AlwaysOnTop +ToolWindow +Owner" myGui.Hwnd, "AutoForge Keybindings")
    sg.SetFont("s9", "Segoe UI")
    sg.Add("Text", "w320", "Click a box, then press the key combination you want.`n"
        . "Backspace clears a box, which sets it back to its default.")

    boxes := Map()     ; id -> Hotkey control
    changed := Map()   ; ids the user typed into
    for a in actions
    {
        sg.Add("Text", "xm y+10 w170", a.desc)
        ; A Win binding can't be shown in a Hotkey control; leave the box blank and keep it unless changed
        box := sg.Add("Hotkey", "x+6 yp-3 w144", InStr(a.hk, "#") ? "" : a.hk)
        box.OnEvent("Change", ((id, *) => changed[id] := true).Bind(a.id))
        boxes[a.id] := box
        if InStr(a.hk, "#")
        {
            sg.SetFont("s8 cGray")
            sg.Add("Text", "x" (sg.MarginX + 176) " y+1 w144", "Current: " a.label)
            sg.SetFont("s9 cDefault")
        }
    }

    sg.SetFont("s8 cGray")
    sg.Add("Text", "xm y+12 w320", "Note: these boxes can't record the Windows (Win) key. "
        . "To use Win in a hotkey, click Open AutoForge.ini, edit the line by hand "
        . "(for example Start=Win+J), save the file, then click Reload file.")
    sg.SetFont("s9 cDefault")

    sg.Add("Button", "xm y+10 w78 Default", "Save").OnEvent("Click", (*) => SaveSettings(boxes, changed))
    sg.Add("Button", "x+6 w78", "Cancel").OnEvent("Click", CloseSettings)
    sg.Add("Button", "x+6 w150", "Reset to defaults").OnEvent("Click", (*) => ResetSettings(boxes, changed))
    sg.Add("Button", "xm y+6 w162", "Open AutoForge.ini").OnEvent("Click", (*) => Run('notepad.exe "' iniFile '"'))
    sg.Add("Button", "x+6 w150", "Reload file").OnEvent("Click", ReloadFromFile)
    sg.OnEvent("Close", CloseSettings)
    sg.OnEvent("Escape", CloseSettings)

    settingsGui := sg
    sg.Show()
}

; Fills every box with its default (saved only when the user clicks Save).
ResetSettings(boxes, changed)
{
    for a in actions
    {
        boxes[a.id].Value := ParseHotkey(a.default, &unused)
        changed[a.id] := true
    }
}

; Checks the new keys, writes them to AutoForge.ini and applies them right away.
SaveSettings(boxes, changed)
{
    final := Map()
    seen := Map()   ; AHK hotkey -> action description, to catch duplicates
    for a in actions
    {
        if changed.Has(a.id)
        {
            v := boxes[a.id].Value
            final[a.id] := (v = "") ? a.default : FriendlyHotkey(v)
        }
        else
            final[a.id] := a.raw

        hk := ParseHotkey(final[a.id], &label)
        if (hk = "")
        {
            MsgBox(a.desc ": " final[a.id] " isn't a key AutoForge can use. Pick another.", "AutoForge Keybindings", "Icon! 0x40000")
            return
        }
        if seen.Has(hk)
        {
            MsgBox(label " is set for both " seen[hk] " and " a.desc ". Pick a different key for one of them.", "AutoForge Keybindings", "Icon! 0x40000")
            return
        }
        seen[hk] := a.desc
        if !RegExMatch(hk, "^[\^!+#]")
        {
            answer := MsgBox(a.desc " is set to " label " with no Ctrl, Alt, Shift or Win.`n"
                . "That key will stop working in the game while AutoForge is open.`n`nUse it anyway?",
                "AutoForge Keybindings", "YesNo Icon? 0x40000")
            if (answer != "Yes")
                return
        }
    }

    for a in actions
        IniWrite(final[a.id], iniFile, "Hotkeys", a.id)
    LoadHotkeys()
    CloseSettings()
}

; Re-reads AutoForge.ini (after editing it by hand) and reopens the window with its values.
ReloadFromFile(*)
{
    LoadHotkeys()
    CloseSettings()
    OpenSettings()
}

CloseSettings(*)
{
    global settingsGui
    if (settingsGui != "")
        settingsGui.Destroy()
    settingsGui := ""
    Suspend(false)
}

; The list of hotkeys shown in the window, one per line.
HotkeyHelpText()
{
    text := ""
    for a in actions
        text .= (text = "" ? "" : "`n") a.label " - " a.desc
    return text
}

; ---- Functions ----

; Text for the live counter, e.g. "Cycles completed: 3 / 10"
CounterLabel()
{
    label := "Cycles completed: " cycleCount
    if (targetQty > 0)
        label .= " / " targetQty
    return label
}

; Re-raise the instruction window above the game whenever the game is the active window.
; Uses SetWindowPos (HWND_TOPMOST, no activate) so it never steals focus from the game.
KeepOnTop()
{
    if WinActive("ahk_exe " gameExe)
        DllCall("SetWindowPos", "Ptr", guiHwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
}

; Holds the run here while it is paused or the game window is not active,
; then resumes once neither is true. Stop/Exit still works while held.
WaitUntilReady()
{
    waited := false
    Loop
    {
        if userPaused
            SetStatus(pausedStatus)
        else if !WinActive("ahk_exe " gameExe)
            SetStatus("Status: Paused (waiting for game window)")
        else
            break
        waited := true
        Sleep 100
    }
    if waited
    {
        Sleep 500   ; let the game settle before clicking again
        SetStatus(runStatus)
    }
}

; Updates the status line only when the text changes, to avoid flicker.
SetStatus(text)
{
    if (statusText.Value != text)
        statusText.Value := text
}
