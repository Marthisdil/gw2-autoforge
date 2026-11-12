; AutoForge
; Version: 3.0.1  (AutoHotkey v2 version)
; Date Updated: 2026-11-12
;
; Requires AutoHotkey v2.0 or later. For AutoHotkey v1.1, use AutoForge v2.7.
;
; Instructions:
; CTRL+ALT+Q - Save Mouse Pos 1 (Refill)
; CTRL+ALT+W - Save Mouse Pos 2 (Forge)
; CTRL+ALT+J - Start
; CTRL+ALT+L - Stop/Exit
; Quantity box: enter how many to forge, then press Start. The script stops
;   after that many cycles. Leave it blank to run until you press Stop/Exit.
; Cycle order: Refill > Forge > wait > repeat
; The script pauses automatically when the game window is not active, and resumes when it is.
; The window is kept on top of the game whenever the game window is active.
; Note: May not work properly if using Overlays such as Blish HUD.

#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2

; ---- Version info ----
scriptVersion := "3.0.1"
scriptDate := "2026-11-12"

; ---- Game window (instruction window is kept on top while this is active) ----
gameExe := "Gw2-64.exe"

; ---- Mouse coordinates: use full-screen coordinates (AHK v2 defaults to window-relative) ----
CoordMode "Mouse", "Screen"

; ---- State (every variable must exist before it is read in v2) ----
pos1X := ""
pos1Y := ""
pos2X := ""
pos2Y := ""
cycleCount := 0
targetQty := 0
running := false
runStatus := "Status: Running"

; ---- Instruction window (always on top, top of screen) ----
guiWidth := 360
guiX := (A_ScreenWidth - guiWidth) // 2
myGui := Gui("+AlwaysOnTop +ToolWindow", "AutoForge")
myGui.SetFont("s9", "Segoe UI")
cycleText := myGui.Add("Text", "w" guiWidth, "Cycles completed: 0")
statusText := myGui.Add("Text", "w" guiWidth " y+2", "Status: Idle")
myGui.Add("Text", "xm y+8 Section", "Quantity (blank = until stopped):")
qtyEdit := myGui.Add("Edit", "x+8 yp-3 w60 Number Limit6")
myGui.Add("Text", "xm w" guiWidth " y+8", "CTRL+ALT+Q - Save Mouse Pos 1 (Refill)`nCTRL+ALT+W - Save Mouse Pos 2 (Forge)`nCTRL+ALT+J - Start`nCTRL+ALT+L - Stop/Exit")
myGui.SetFont("s8 cGray")
myGui.Add("Text", "w" guiWidth " y+6", "Note: May not work properly if using Overlays such as Blish HUD.")
myGui.Add("Text", "w" guiWidth " y+4", "v" scriptVersion "  |  Updated: " scriptDate)
myGui.Show("x" guiX " y0 NoActivate")
guiHwnd := myGui.Hwnd

SetTimer(KeepOnTop, 250)

; ---- Hotkeys ----
^!q::
{
    global pos1X, pos1Y
    CoordMode "Mouse", "Screen"
    MouseGetPos &pos1X, &pos1Y
}

^!w::
{
    global pos2X, pos2Y
    CoordMode "Mouse", "Screen"
    MouseGetPos &pos2X, &pos2Y
}

^!j::
{
    global running, cycleCount, targetQty, runStatus
    if running
        return
    CoordMode "Mouse", "Screen"

    ; Both positions must be saved first
    if (pos1X = "" or pos2X = "")
    {
        statusText.Value := "Status: Save both positions first (Q / W)"
        return
    }

    ; Read the quantity box (blank or 0 = run until stopped)
    qtyText := Trim(qtyEdit.Value)
    targetQty := (qtyText = "") ? 0 : Integer(qtyText)

    running := true
    cycleCount := 0
    cycleText.Value := CounterLabel()
    runStatus := "Status: Running"
    if (targetQty = 0)
        runStatus .= " (until stopped)"
    statusText.Value := runStatus

    Loop
    {
        WaitForGame()
        Click(pos1X, pos1Y)
        Sleep 100
        WaitForGame()
        Click(pos2X, pos2Y)
        Sleep 2500
        cycleCount += 1
        cycleText.Value := CounterLabel()
        if (targetQty > 0 and cycleCount >= targetQty)
            break
    }

    running := false
    statusText.Value := "Status: Done"
}

^!l::ExitApp

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

; Pauses here while the game window is not active, then resumes automatically.
; Stop/Exit (CTRL+ALT+L) still works while paused.
WaitForGame()
{
    if WinActive("ahk_exe " gameExe)
        return
    statusText.Value := "Status: Paused (waiting for game window)"
    WinWaitActive("ahk_exe " gameExe)
    Sleep 500   ; let the game settle before clicking again
    statusText.Value := runStatus
}