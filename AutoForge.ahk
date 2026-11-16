; AutoForge
; Version: 3.4.1  (AutoHotkey v2 version)
; Date Updated: 2026-11-16
;
; Home page and latest version: https://github.com/Marthisdil/gw2-autoforge
; License: MIT License. Copyright (c) 2026 Marthisdil.
;   You may use, change and share this script, as long as you keep this notice.
;   Full text: https://github.com/Marthisdil/gw2-autoforge/blob/main/LICENSE
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
; Theme: the moon/sun button next to the gear switches between the light and dark
;   theme. The gear window has the same choice. It is saved in AutoForge.ini.
; Text size: pick Small, Medium (the original size), Large or Extra large in the gear
;   window. Both windows resize to fit right away; it is saved in AutoForge.ini.
; Quantity box: enter how many to forge, then press Start. The script stops
;   after that many cycles. Leave it blank to run until you press Stop/Exit.
; Cycle order: Refill > Forge > wait > repeat
; Pause/Resume holds the run before the next click and keeps the cycle count.
; The script also pauses automatically when the game window is not active, and resumes when it is.
; The window is kept on top of the game whenever the game window is active.
; Note: May not work properly if using Overlays such as Blish HUD.

#Requires AutoHotkey v2.0

; ---- Version info ----
scriptVersion := "3.4.1"
scriptDate := "2026-11-16"

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

; ---- Themes (colors are hex RGB, or "Default" for the normal Windows colors) ----
themes := Map(
    "Light", {back: "Default", text: "Default", muted: "Gray",   edit: "Default", dark: false},
    "Dark",  {back: "202020",  text: "E8E8E8",  muted: "9A9A9A", edit: "2D2D2D",  dark: true}
)
themeName := "Light"   ; read from AutoForge.ini after it is created
mutedCtrls := Map()    ; hwnds of the small gray note texts

; ---- Text sizes. Medium is the original look; every font size, width, gap and
;      margin in both windows is multiplied by the chosen scale. ----
textSizes := [
    {id: "Small",      name: "Small",       scale: 0.85},
    {id: "Medium",     name: "Medium",      scale: 1.0},
    {id: "Large",      name: "Large",       scale: 1.25},
    {id: "ExtraLarge", name: "Extra large", scale: 1.5}
]
textSize := "Medium"   ; read from AutoForge.ini after it is created

myGui := ""            ; the main window, built by BuildMainGui(), and its live controls:
themeBtn := "", cycleText := "", statusText := "", qtyEdit := "", helpText := ""
settingsBoxes := ""    ; while the keybinding window is open: id -> key box
settingsChanged := ""  ;   and the ids the user has typed into

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
themeName := ReadTheme()
textSize := ReadTextSize()

; ---- Instruction window (always on top, top centre of the screen) ----
BuildMainGui()

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
    if (helpText != "")
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
    text .= "`n[Settings]`n"
        . "; Theme: Light or Dark (the moon/sun button in the AutoForge window switches it)`n"
        . "Theme=Light`n"
        . "; TextSize: Small, Medium, Large or ExtraLarge (also set in the gear window)`n"
        . "TextSize=Medium`n"
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
    BuildSettingsGui()
}

; Builds the keybinding window at the current text size. pending (id -> AHK hotkey) refills
; keys typed but not saved yet, and pos ({x, y} in pixels) puts the window back where it
; was; both are used when the window is rebuilt for a new text size.
BuildSettingsGui(pending := "", pos := "")
{
    global settingsGui, settingsBoxes, settingsChanged
    Suspend(true)
    sg := Gui("+AlwaysOnTop +ToolWindow +Owner" myGui.Hwnd, "AutoForge Keybindings")
    sg.MarginX := S(11), sg.MarginY := S(7)
    sg.SetFont("s" FontSize(9), "Segoe UI")
    sg.Add("Text", "w" S(320), "Click a box, then press the key combination you want.`n"
        . "Backspace clears a box, which sets it back to its default.")

    boxes := Map()     ; id -> Hotkey control
    changed := Map()   ; ids the user typed into
    for a in actions
    {
        sg.Add("Text", "xm y+" S(10) " w" S(170), a.desc)
        ; A Win binding can't be shown in a Hotkey control; leave the box blank and keep it unless changed
        box := sg.Add("Hotkey", "x+" S(6) " yp-" S(3) " w" S(144), InStr(a.hk, "#") ? "" : a.hk)
        box.OnEvent("Change", ((id, *) => changed[id] := true).Bind(a.id))
        boxes[a.id] := box
        if (pending != "" and pending.Has(a.id))
        {
            box.Value := pending[a.id]
            changed[a.id] := true
        }
        if InStr(a.hk, "#")
        {
            sg.SetFont("s" FontSize(8) " cGray")
            Muted(sg.Add("Text", "x" (sg.MarginX + S(170) + S(6)) " y+1 w" S(144), "Current: " a.label))
            sg.SetFont("s" FontSize(9) " cDefault")
        }
    }

    sg.SetFont("s" FontSize(8) " cGray")
    Muted(sg.Add("Text", "xm y+" S(12) " w" S(320), "Note: these boxes can't record the Windows (Win) key. "
        . "To use Win in a hotkey, click Open AutoForge.ini, edit the line by hand "
        . "(for example Start=Win+J), save the file, then click Reload file."))
    sg.SetFont("s" FontSize(9) " cDefault")

    ; Theme and text size apply (and are saved) as soon as they are picked, like the moon/sun button
    sg.Add("Text", "xm y+" S(12) " w" S(170), "Theme")
    themeDdl := sg.Add("DropDownList", "x+" S(6) " yp-" S(3) " w" S(144) " vThemeDdl", ["Light", "Dark"])
    themeDdl.Choose(themeName)
    themeDdl.OnEvent("Change", (ctrl, *) => SetTheme(ctrl.Text))

    sizeNames := []
    for t in textSizes
        sizeNames.Push(t.name)
    sg.Add("Text", "xm y+" S(10) " w" S(170), "Text size")
    sizeDdl := sg.Add("DropDownList", "x+" S(6) " yp-" S(3) " w" S(144), sizeNames)
    sizeDdl.Value := TextSizeIndex()
    sizeDdl.OnEvent("Change", (ctrl, *) => SetTextSize(textSizes[ctrl.Value].id))

    sg.Add("Button", "xm y+" S(10) " w" S(78) " Default", "Save").OnEvent("Click", (*) => SaveSettings(boxes, changed))
    sg.Add("Button", "x+" S(6) " w" S(78), "Cancel").OnEvent("Click", CloseSettings)
    sg.Add("Button", "x+" S(6) " w" S(150), "Reset to defaults").OnEvent("Click", (*) => ResetSettings(boxes, changed))
    sg.Add("Button", "xm y+" S(6) " w" S(162), "Open AutoForge.ini").OnEvent("Click", (*) => Run('notepad.exe "' iniFile '"'))
    sg.Add("Button", "x+" S(6) " w" S(150), "Reload file").OnEvent("Click", ReloadFromFile)
    sg.OnEvent("Close", CloseSettings)
    sg.OnEvent("Escape", CloseSettings)

    settingsGui := sg
    settingsBoxes := boxes
    settingsChanged := changed
    ApplyTheme(sg)
    if (pos != "")
    {
        sg.Show("Hide")
        WinMove(pos.x, pos.y,,, sg.Hwnd)
    }
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

; Re-reads AutoForge.ini (after editing it by hand) and reopens the window with its values,
; including the theme and text size.
ReloadFromFile(*)
{
    LoadHotkeys()
    CloseSettings()
    SetTheme(ReadTheme())
    SetTextSize(ReadTextSize())
    OpenSettings()
}

CloseSettings(*)
{
    global settingsGui, settingsBoxes, settingsChanged
    if (settingsGui != "")
        DestroyGui(settingsGui)
    settingsGui := ""
    settingsBoxes := ""
    settingsChanged := ""
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

; ---- Main window ----

; Builds the instruction window at the current text size and theme. When it is rebuilt
; for a new text size, the quantity, counter and status are kept, and it stays centred
; on the same spot at the same height.
BuildMainGui()
{
    global myGui, themeBtn, cycleText, statusText, qtyEdit, helpText
    Critical("On")   ; keep the KeepOnTop timer out while the window is swapped

    oldQty := "", oldCycle := "Cycles completed: 0", oldStatus := "Status: Idle"
    centreX := A_ScreenWidth // 2, topY := 0
    if (myGui != "")
    {
        oldQty := qtyEdit.Value, oldCycle := cycleText.Value, oldStatus := statusText.Value
        WinGetPos(&ox, &oy, &ow,, myGui.Hwnd)
        centreX := ox + ow // 2, topY := oy
        DestroyGui(myGui)
    }

    w := S(360)   ; width of the text area
    g := Gui("+AlwaysOnTop +ToolWindow", "AutoForge")
    g.MarginX := S(15), g.MarginY := S(9)   ; AHK's defaults for this window at Medium
    ; Top right: theme toggle (moon/sun), then the gear button that opens the keybinding window
    g.SetFont("s" FontSize(12), "Segoe UI Symbol")
    themeBtn := g.Add("Button", "x" (g.MarginX + w - S(68)) " ym w" S(32) " h" S(28), ThemeButtonText())
    themeBtn.OnEvent("Click", (*) => SetTheme(themeName = "Dark" ? "Light" : "Dark"))
    g.Add("Button", "x+" S(4) " ym w" S(32) " h" S(28), Chr(0x2699)).OnEvent("Click", OpenSettings)
    g.SetFont("s" FontSize(9), "Segoe UI")
    cycleText := g.Add("Text", "xm ym w" (w - S(72)), oldCycle)
    statusText := g.Add("Text", "w" (w - S(72)) " y+" S(2), oldStatus)
    g.Add("Text", "xm y+" S(8) " Section", "Quantity (blank = until stopped):")
    qtyEdit := g.Add("Edit", "x+" S(8) " yp-" S(3) " w" S(60) " Number Limit6", oldQty)
    helpText := g.Add("Text", "xm w" w " y+" S(8) " r" actions.Length, HotkeyHelpText())
    g.SetFont("s" FontSize(8) " cGray")
    Muted(g.Add("Text", "xm w" w " y+" S(6), "Note: May not work properly if using Overlays such as Blish HUD."))
    Muted(g.Add("Text", "w" w " y+" S(4), "v" scriptVersion "  |  Updated: " scriptDate))
    ApplyTheme(g)

    ; Size it hidden, place it, then show it without taking focus from the game
    g.Show("Hide")
    WinGetPos(,, &nw,, g.Hwnd)
    WinMove(centreX - nw // 2, topY,,, g.Hwnd)
    g.Show("NoActivate")
    myGui := g
    Critical("Off")
}

; Destroys a window and forgets which of its controls were gray notes.
DestroyGui(g)
{
    for hwnd in g
        if mutedCtrls.Has(hwnd)
            mutedCtrls.Delete(hwnd)
    g.Destroy()
}

; ---- Text size functions ----

; Reads the text size from AutoForge.ini. Anything unknown means Medium.
ReadTextSize()
{
    v := Trim(IniRead(iniFile, "Settings", "TextSize", "Medium"))
    for t in textSizes
        if (t.id = v)
            return t.id
    return "Medium"
}

; Position of the current text size in textSizes (for the drop-down).
TextSizeIndex()
{
    for i, t in textSizes
        if (t.id = textSize)
            return i
    return 2
}

; Scales a Medium-size measurement (width, gap or margin) to the current text size.
S(n)
{
    return Round(n * textSizes[TextSizeIndex()].scale)
}

; Scales a Medium-size font point size to the current text size (never below 6).
FontSize(pt)
{
    return Max(6, Round(pt * textSizes[TextSizeIndex()].scale))
}

; Switches to the named text size, saves it, and rebuilds the open windows to fit.
; The keybinding window keeps its position and any keys typed but not saved yet.
SetTextSize(id)
{
    global textSize, settingsGui, settingsBoxes, settingsChanged
    IniWrite(id, iniFile, "Settings", "TextSize")
    if (id = textSize)
        return
    textSize := id

    pending := "", pos := ""
    if (settingsGui != "")
    {
        pending := Map()
        for changedId in settingsChanged
            pending[changedId] := settingsBoxes[changedId].Value
        WinGetPos(&sx, &sy,,, settingsGui.Hwnd)
        pos := {x: sx, y: sy}
        DestroyGui(settingsGui)   ; hotkeys stay suspended: the window is reopened below
        settingsGui := "", settingsBoxes := "", settingsChanged := ""
    }
    BuildMainGui()
    if (pos != "")
        BuildSettingsGui(pending, pos)
}

; ---- Theme functions ----

; Reads the theme from AutoForge.ini. Anything other than Dark means Light.
ReadTheme()
{
    return (Trim(IniRead(iniFile, "Settings", "Theme", "Light")) = "Dark") ? "Dark" : "Light"
}

; Switches to the named theme, saves it, and repaints every open AutoForge window.
SetTheme(name)
{
    global themeName
    themeName := name
    IniWrite(name, iniFile, "Settings", "Theme")
    themeBtn.Text := ThemeButtonText()
    ApplyTheme(myGui)
    if (settingsGui != "")
    {
        settingsGui["ThemeDdl"].Choose(name)
        ApplyTheme(settingsGui)
    }
}

; The toggle shows the theme it switches to: a moon in light mode, a sun in dark mode.
ThemeButtonText()
{
    return (themeName = "Dark") ? Chr(0x2600) : Chr(0x263E)
}

; Marks a text control as a small gray note, so the theme gives it the muted color.
Muted(ctrl)
{
    mutedCtrls[ctrl.Hwnd] := true
    return ctrl
}

; Colors a window and its controls for the current theme. Text and the quantity box
; take the theme colors; buttons and drop-downs use Windows' own dark style; the
; title bar is darkened too (Windows 10 1809 or later). Key boxes stay light.
ApplyTheme(g)
{
    t := themes[themeName]
    g.BackColor := t.back
    for hwnd, ctrl in g
    {
        switch ctrl.Type
        {
            case "Text":
                ctrl.SetFont("c" (mutedCtrls.Has(hwnd) ? t.muted : t.text))
            case "Edit":
                ctrl.Opt("Background" t.edit)
                ctrl.SetFont("c" t.text)
            case "Button":
                SetControlTheme(hwnd, t.dark ? "DarkMode_Explorer" : "")
            case "DDL":
                SetControlTheme(hwnd, t.dark ? "DarkMode_CFD" : "")
        }
    }

    ; Dark title bar: attribute 20 on current Windows, 19 on early Windows 10 builds
    on := t.dark ? 1 : 0
    if DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 20, "Int*", on, "Int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 19, "Int*", on, "Int", 4)

    ; Repaint the frame and every control (no move, resize, z-order change or activation)
    DllCall("SetWindowPos", "Ptr", g.Hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0037)
    DllCall("RedrawWindow", "Ptr", g.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0485)
}

; Gives a control a Windows visual style by name, or its normal style when name is "".
SetControlTheme(hwnd, name)
{
    if (name = "")
        DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Ptr", 0, "Ptr", 0)
    else
        DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", name, "Ptr", 0)
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
        DllCall("SetWindowPos", "Ptr", myGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
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
