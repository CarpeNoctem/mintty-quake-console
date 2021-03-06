; Mintty quake console: Visor-like functionality for Windows
; URL: https://github.com/CarpeNoctem/mintty-quake-console
; Credits:
;    Forked from: https://github.com/lonepie/mintty-quake-console
;    Originally forked from: https://github.com/marcharding/mintty-quake-console
;    mintty: http://code.google.com/p/mintty/
;    Visor: http://visor.binaryage.com/

;*******************************************************************************
;                Settings                    
;*******************************************************************************
#NoEnv
#SingleInstance force
SendMode Input
DetectHiddenWindows, on
SetWinDelay, -1

; get path to cygwin from registry
RegRead, cygwinRootDir, HKEY_LOCAL_MACHINE, SOFTWARE\Cygwin\setup, rootdir
cygwinBinDir := cygwinRootDir . "\bin"

;*******************************************************************************
;                Preferences & Variables
;*******************************************************************************
VERSION := "ng"
iniFile := "mintty-quake-console.ini"
IniRead, minttyPath, %iniFile%, General, mintty_path, % cygwinBinDir . "\mintty.exe"
IniRead, minttyArgs, %iniFile%, General, mintty_args, -
IniRead, consoleHotkey, %iniFile%, General, hotkey, ^``
IniRead, startWithWindows, %iniFile%, Display, start_with_windows, 0
IniRead, startHidden, %iniFile%, Display, start_hidden, 1
IniRead, initialHeight, %iniFile%, Display, initial_height, 380
IniRead, initialWidth, %iniFile%, Display, initial_width, 100 ; percent
IniRead, autohide, %iniFile%, Display, autohide_by_default, 0
IniRead, animationStep, %iniFile%, Display, animation_step, 20
IniRead, animationTimeout, %iniFile%, Display, animation_timeout, 10
IfNotExist %iniFile%
{
    SaveSettings()
}

; path to mintty (same folder as script), start with default shell
; minttyPath := cygwinBinDir . "\mintty.exe -"
; minttyPath := cygwinBinDir . "\mintty.exe /bin/zsh -li"
minttyPath_args := minttyPath . " " . minttyArgs

; initial height and width of console window
heightConsoleWindow := initialHeight
widthConsoleWindow := initialWidth

isVisible := False

;*******************************************************************************
;                Hotkeys                        
;*******************************************************************************
Hotkey, %consoleHotkey%, ConsoleHotkey

;*******************************************************************************
;                Menu                    
;*******************************************************************************
if !InStr(A_ScriptName, ".exe")
    Menu, Tray, Icon, terminal.ico
Menu, Tray, NoStandard
Menu, Tray, Tip, mintty-quake-console %VERSION%
Menu, Tray, Add, Show/Hide, ToggleVisible
Menu, Tray, Add, Enabled, ToggleScriptState
Menu, Tray, Check, Enabled
Menu, Tray, Add, Auto-Hide, ToggleAutoHide
if (autohide)
    Menu, Tray, Check, Auto-Hide
Menu, Tray, Add
Menu, Tray, Add, Options, ShowOptionsGui
Menu, Tray, Add, About, AboutDlg
Menu, Tray, Add, Reload, ReloadSub
Menu, Tray, Add, Exit, ExitSub

init()
return
;*******************************************************************************
;                Functions / Labels                        
;*******************************************************************************
init()
{
    global
    initCount++
    ; get last active window
    WinGet, hw_current, ID, A
    if !WinExist("ahk_class mintty") {
        Run %minttyPath_args%, %cygwinBinDir%, Hide, hw_mintty
        WinWait ahk_pid %hw_mintty%
    }
    else {
        WinGet, hw_mintty, PID, ahk_class mintty
    }
    
    TaskBarEdge := GetTaskbarEdge()
    ScreenWidth := GetScreenWidth()
    ScreenTop := GetScreenTop()
    ScreenLeft := GetScreenLeft()
    
    WinGetPos, OrigXpos, OrigYpos, OrigWinWidth, OrigWinHeight, ahk_pid %hw_mintty%
    toggleScript("init")
}

toggle()
{
    global

    IfWinActive ahk_pid %hw_mintty%
    {
        Slide("ahk_pid" . hw_mintty, "Out")
        ; reset focus to last active window
        WinActivate, ahk_id %hw_current%
    }
    else
    {
        ; get last active window
        WinGet, hw_current, ID, A

        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
}

Slide(Window, Dir)
{
    global animationStep, animationTimeout, autohide, isVisible, ScreenTop, ScreenLeft, ScreenWidth
    WinGetPos, Xpos, Ypos, WinWidth, WinHeight, %Window%
    left := ScreenLeft + ((ScreenWidth - width) /  2)
    If (Dir = "In") And (Ypos < 0)
        WinShow %Window%
    If (Xpos != %left%)
        WinMove, %Window%,,%left%
    Loop
    {
      If (Dir = "In") And (Ypos >= ScreenTop) Or (Dir = "Out") And (Ypos <= (-WinHeight))
         Break
      
      dRate := animationStep
      dY := % (Dir = "In") ? Ypos + dRate : Ypos - dRate
      WinMove, %Window%,,, dY
      WinGetPos, Xpos, Ypos, WinWidth, WinHeight, %Window%
      Sleep, %animationTimeout%
    }

    If (Dir = "In") And (Ypos >= ScreenTop) {
        WinMove, %Window%,,, ScreenTop
        if (autohide)
            SetTimer, HideWhenInactive, 250
        isVisible := True
    }
    If (Dir = "Out") And (Ypos <= (-WinHeight)) {
        WinHide %Window%
        if (autohide)
            SetTimer, HideWhenInactive, Off
        isVisible := False
    }
}

toggleScript(state) {
    ; enable/disable script effects, hotkeys, etc
    global
    ; WinGetPos, Xpos, Ypos, WinWidth, WinHeight, ahk_pid %hw_mintty%
    if(state = "on" or state = "init") {
        If !WinExist("ahk_pid" . hw_mintty) {
            init()
            return
        }
        WinHide ahk_pid %hw_mintty%
        WinSet, Style, -0xC40000, ahk_pid %hw_mintty% ; hide window borders and caption/title

        width := ScreenWidth * widthConsoleWindow / 100
        left := ScreenLeft + ((ScreenWidth - width) /  2)
        WinMove, ahk_pid %hw_mintty%, , %left%, -%heightConsoleWindow%, %width%, %heightConsoleWindow% ; resize/move
        
        scriptEnabled := True
        Menu, Tray, Check, Enabled
        
        if (state = "init" and initCount = 1 and startHidden) {
            return
        }
        
        WinShow ahk_pid %hw_mintty%
        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
    else if (state = "off") {
        WinSet, Style, +0xC40000, ahk_pid %hw_mintty% ; show window borders and caption/title
        if (OrigYpos >= 0)
            WinMove, ahk_pid %hw_mintty%, , %OrigXpos%, %OrigYpos%, %OrigWinWidth%, %OrigWinHeight% ; restore size / position
        else
            WinMove, ahk_pid %hw_mintty%, , %OrigXpos%, 100, %OrigWinWidth%, %OrigWinHeight%
        WinShow, ahk_pid %hw_mintty% ; show window
        scriptEnabled := False
        Menu, Tray, Uncheck, Enabled
    }
}

HideWhenInactive:
    IfWinNotActive ahk_pid %hw_mintty%
    {
        Slide("ahk_pid" . hw_mintty, "Out")
        SetTimer, HideWhenInactive, Off
    }
return

ToggleVisible:
    if(isVisible)
    {
        Slide("ahk_pid" . hw_mintty, "Out")
    }
    else
    {
        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
return

ToggleScriptState:
    if(scriptEnabled)
        toggleScript("off")
    else
        toggleScript("on")
return

ToggleAutoHide:
    autohide := !autohide
    Menu, Tray, ToggleCheck, Auto-Hide
    SetTimer, HideWhenInactive, Off
return

ConsoleHotkey:
    If (scriptEnabled) {
        IfWinExist ahk_pid %hw_mintty%
        {
            toggle()
        }
        else
        {
            init()
        }
    }
return

ExitSub:
    if A_ExitReason not in Logoff,Shutdown
    {
        MsgBox, 4, mintty-quake-console, Are you sure you want to exit?
        IfMsgBox, No
            return
        toggleScript("off")
    }
ExitApp

ReloadSub:
Reload
return

AboutDlg:
    MsgBox, 64, About, mintty-quake-console AutoHotkey script`nVersion: %VERSION%`nURL: https://github.com/CarpeNoctem/mintty-quake-console
return

ShowOptionsGui:
    OptionsGui()
return

;*******************************************************************************
;                Extra Hotkeys                        
;*******************************************************************************
#IfWinActive ahk_class mintty

^!NumpadAdd::
    if(WinActive("ahk_pid" . hw_mintty)) {
        if(heightConsoleWindow < A_ScreenHeight) {
            heightConsoleWindow += animationStep
            WinMove, ahk_pid %hw_mintty%,,,,, heightConsoleWindow
        }
    }
return
; DecreaseHeight:
^!NumpadSub::
    if(WinActive("ahk_pid" . hw_mintty)) {
        if(heightConsoleWindow > 100) {
            heightConsoleWindow -= animationStep
            WinMove, ahk_pid %hw_mintty%,,,,, heightConsoleWindow
        }
    }
return
#IfWinActive

;*******************************************************************************
;                Options                    
;*******************************************************************************
SaveSettings() {
    global
    IniWrite, %minttyPath%, %iniFile%, General, mintty_path
    IniWrite, %minttyArgs%, %iniFile%, General, mintty_args    
    IniWrite, %consoleHotkey%, %iniFile%, General, hotkey
    IniWrite, %startWithWindows%, %iniFile%, Display, start_with_windows
    IniWrite, %startHidden%, %iniFile%, Display, start_hidden
    IniWrite, %initialHeight%, %iniFile%, Display, initial_height
    IniWrite, %initialWidth%, %iniFile%, Display, initial_width
    IniWrite, %autohide%, %iniFile%, Display, autohide_by_default
    IniWrite, %animationStep%, %inifile%, Display, animation_step
    IniWrite, %animationTimeout%, %iniFile%, Display, animation_timeout
    CheckWindowsStartup(startWithWindows)
}

CheckWindowsStartup(enable) {
    SplitPath, A_ScriptName, , , , OutNameNoExt
    LinkFile=%A_Startup%\%OutNameNoExt%.lnk

    if !FileExist(LinkFile) {
        if (enable) {
            FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%
        }
    }
    else {
        if(!enable) {
            FileDelete, %LinkFile%
        }
    }
}

OptionsGui() {
    global
    If not WinExist("ahk_id" GuiID) {
        Gui, Add, GroupBox, x12 y10 w450 h110 , General
        Gui, Add, GroupBox, x12 y130 w450 h220 , Display
        Gui, Add, Button, x242 y360 w100 h30 Default, Save
        Gui, Add, Button, x362 y360 w100 h30 , Cancel
        Gui, Add, Text, x22 y30 w70 h20 , Mintty Path:
        Gui, Add, Edit, x92 y30 w250 h20 VminttyPath, %minttyPath%
        Gui, Add, Button, x352 y30 w100 h20, Browse
        Gui, Add, Text, x22 y60 w100 h20 , Mintty Arguments:
        Gui, Add, Edit, x122 y60 w330 h20 VminttyArgs, %minttyArgs%
        Gui, Add, Text, x22 y90 w100 h20 , Hotkey Trigger:
        Gui, Add, Hotkey, x122 y90 w100 h20 VconsoleHotkey, %consoleHotkey%
        Gui, Add, CheckBox, x22 y150 w100 h30 VstartHidden Checked%startHidden%, Start Hidden
        Gui, Add, CheckBox, x22 y180 w130 h30 Vautohide Checked%autohide%, Auto-Hide when focus is lost
        Gui, Add, CheckBox, x22 y210 w120 h30 VstartWithWindows Checked%startWithWindows%, Start With Windows
        Gui, Add, Text, x22 y250 w100 h20 , Initial Height (px):
        Gui, Add, Edit, x22 y270 w100 h20 VinitialHeight, %initialHeight%
        Gui, Add, Text, x22 y300 w115 h20 , Initial Width (percent):
        Gui, Add, Edit, x22 y320 w100 h20 VinitialWidth, %initialWidth%
        Gui, Add, Text, x232 y170 w220 h20 , Animation Delta (px):
        Gui, Add, Text, x232 y220 w220 h20 , Animation Time (ms):
        Gui, Add, Slider, x232 y190 w220 h30 VanimationStep Range5-50, %animationStep%
        Gui, Add, Slider, x232 y240 w220 h30 VanimationTimeout Range5-50, %animationTimeout%
        Gui, Add, Text, x232 y280 w220 h20 +Center, Animation Speed = Delta / Time
    }
    ; Initially generated using SmartGUI Creator 4.0
    Gui, Show, h410 w482, TerminalHUD Options
    Gui, +LastFound
    GuiID := WinExist()
    
    Loop {
        ;sleep to reduce CPU load
        Sleep, 100 

        ;exit endless loop, when settings GUI closes 
        If not WinExist("ahk_id" GuiID) 
            Break 
    }

    ButtonSave:
        Gui, Submit
        SaveSettings()
        Reload
    return
    
    ButtonBrowse:
        FileSelectFile, SelectedPath, 3, %A_MyDocuments%, Path to mintty.exe, Executables (*.exe)
        if SelectedPath != 
            GuiControl,, MinttyPath, %SelectedPath%
    return
    
    GuiClose:
    GuiEscape:
    ButtonCancel:
        Gui, Cancel
    return
}

;*******************************************************************************
;                Utility                    
;*******************************************************************************
; Gets the edge that the taskbar is docked to.  Returns:
;   "top"
;   "right"
;   "bottom"
;   "left"
GetTaskbarEdge() {
  WinGetPos,TX,TY,TW,TH,ahk_class Shell_TrayWnd,,,

  if (TW = A_ScreenWidth) { ; Vertical Taskbar
    if (TY = 0) {
      return "top"
    } else {
      return "bottom"
    }
  } else { ; Horizontal Taskbar
    if (TX = 0) {
      return "left"
    } else {
      return "right"
    }
  }
}

GetScreenTop() {
  WinGetPos,TX,TY,TW,TH,ahk_class Shell_TrayWnd,,,
  TaskbarEdge := GetTaskbarEdge()

  if (TaskbarEdge = "top") {
    return TH
  } else {
    return 0
  }
}

GetScreenLeft() {
  WinGetPos,TX,TY,TW,TH,ahk_class Shell_TrayWnd,,,
  TaskbarEdge := GetTaskbarEdge()

  if (TaskbarEdge = "left") {
    return TW
  } else {
    return 0
  }
}

GetScreenWidth() {
  WinGetPos,TX,TY,TW,TH,ahk_class Shell_TrayWnd,,,
  TaskbarEdge := GetTaskbarEdge()

  if (TaskbarEdge = "top" or TaskbarEdge = "bottom") {
    return A_ScreenWidth
  } else {
    return A_ScreenWidth - TW
  }
}

GetScreenHeight() {
  WinGetPos,TX,TY,TW,TH,ahk_class Shell_TrayWnd,,,
  TaskbarEdge := GetTaskbarEdge()

  if (TaskbarEdge = "top" or TaskbarEdge = "bottom") {
    return A_ScreenHeight - TH
  } else {
    return A_ScreenHeight
  }
}
