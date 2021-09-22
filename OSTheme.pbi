; +---------+
; | OSTheme |
; +---------+
; | 2021-09-16 : Creation (PureBasic 5.73)

;-
CompilerIf (Not Defined(_OSTheme_Included, #PB_Constant))
#_OSTheme_Included = #True

; Compile switches (testing)
#_OSTheme_TestDefaults = #False
#_OSTheme_TestExtremes = #False

; Define #OSTheme_CopiedIntoSource = #True if you copy this directly into your own source file
CompilerIf (Not Defined(OSTheme_CopiedIntoSource, #PB_Constant))
  #OSTheme_CopiedIntoSource = #False
CompilerEndIf

CompilerIf (#PB_Compiler_IsMainFile And (Not #OSTheme_CopiedIntoSource))
  EnableExplicit
CompilerEndIf


;- Constants (Public)

Enumeration ; OSThemeColor indexes
  #OSTheme_Window
  #OSTheme_WindowText
  #OSTheme_Control
  #OSTheme_ControlText
  #OSTheme_Selection
  #OSTheme_SelectionText
  #OSTheme_Accent
  #OSTheme_Border
  #OSTheme_DisabledText
  ;
  #_OSTheme_Count
EndEnumeration

;-
;- Constants (Private)

#_OSTheme_RGBMask = $00FFFFFF

; Basic colors
#Black = $000000
#White = $FFFFFF


;-
;- Globals

Global Dim _OSTheme_Color.i(#_OSTheme_Count - 1)
Global Dim _OSTheme_PreviousColor.i(#_OSTheme_Count - 1)
Global Dim _OSTheme_DefaultColor.i(#_OSTheme_Count - 1)
  CompilerIf (#_OSTheme_TestExtremes)
    _OSTheme_DefaultColor(#OSTheme_Window)        = #Red
    _OSTheme_DefaultColor(#OSTheme_WindowText)    = #Blue
    _OSTheme_DefaultColor(#OSTheme_Control)       = #White
    _OSTheme_DefaultColor(#OSTheme_ControlText)   = #Gray
    _OSTheme_DefaultColor(#OSTheme_Selection)     = #Black
    _OSTheme_DefaultColor(#OSTheme_SelectionText) = #Yellow
    _OSTheme_DefaultColor(#OSTheme_Accent)        = #Magenta
    _OSTheme_DefaultColor(#OSTheme_Border)        = #Cyan
    _OSTheme_DefaultColor(#OSTheme_DisabledText)  = #Green
  CompilerElse
    _OSTheme_DefaultColor(#OSTheme_Window)        = $E0E0E0
    _OSTheme_DefaultColor(#OSTheme_WindowText)    = $000000
    _OSTheme_DefaultColor(#OSTheme_Control)       = $FFFFFF
    _OSTheme_DefaultColor(#OSTheme_ControlText)   = $202020
    _OSTheme_DefaultColor(#OSTheme_Selection)     = $FF0000
    _OSTheme_DefaultColor(#OSTheme_SelectionText) = $00FFFF
    _OSTheme_DefaultColor(#OSTheme_Accent)        = $FF0000
    _OSTheme_DefaultColor(#OSTheme_Border)        = $A0A0A0
    _OSTheme_DefaultColor(#OSTheme_DisabledText)  = $808080
  CompilerEndIf

Global _OSTheme_Tracking.i      = #False
Global _OSTheme_ChangedFlag.i   = #False
Global _OSTheme_ColorsChanged.i = #False
Global _OSTheme_IsThemeDark.i   = #False

Global _OSTheme_CustomEvent.i = -1
Global _OSTheme_Callback.i    = #Null



;-
;- Declares

Declare   _OSTheme_UpdateColors()
Declare.i OSThemeBlendColors(Index1.i, Index2.i, Fade.f)



;-
;- Macros (Public)

Macro GetOSWindowColor()
  OSThemeColor(#OSTheme_Window)
EndMacro
Macro GetOSWindowTextColor()
  OSThemeColor(#OSTheme_WindowText)
EndMacro
Macro GetOSControlColor()
  OSThemeColor(#OSTheme_Control)
EndMacro
Macro GetOSControlTextColor()
  OSThemeColor(#OSTheme_ControlText)
EndMacro
Macro GetOSSelectionColor()
  OSThemeColor(#OSTheme_Selection)
EndMacro
Macro GetOSSelectionTextColor()
  OSThemeColor(#OSTheme_SelectionText)
EndMacro
Macro GetOSAccentColor()
  OSThemeColor(#OSTheme_Accent)
EndMacro
Macro GetOSBorderColor()
  OSThemeColor(#OSTheme_Border)
EndMacro
Macro GetOSDisabledTextColor()
  OSThemeColor(#OSTheme_DisabledText)
EndMacro






;-
;- - Windows Version

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)

Global _OSTheme_DummyWin.i = #Null

Procedure _OSTheme_UpdateColors_Win()
  CompilerIf (#_OSTheme_TestDefaults Or #_OSTheme_TestExtremes)
    ProcedureReturn
  CompilerEndIf
  _OSTheme_Color(#OSTheme_Window)        = GetSysColor_(#COLOR_BTNFACE)
  _OSTheme_Color(#OSTheme_WindowText)    = GetSysColor_(#COLOR_BTNTEXT)
  _OSTheme_Color(#OSTheme_Control)       = GetSysColor_(#COLOR_WINDOW)
  _OSTheme_Color(#OSTheme_ControlText)   = GetSysColor_(#COLOR_WINDOWTEXT)
  _OSTheme_Color(#OSTheme_Selection)     = GetSysColor_(#COLOR_HIGHLIGHT)
  _OSTheme_Color(#OSTheme_SelectionText) = GetSysColor_(#COLOR_HIGHLIGHTTEXT)
  _OSTheme_Color(#OSTheme_Accent)        = GetSysColor_(#COLOR_MENUHILIGHT)
  _OSTheme_Color(#OSTheme_Border)        = GetSysColor_(#COLOR_3DSHADOW)
  _OSTheme_Color(#OSTheme_DisabledText)  = GetSysColor_(#COLOR_GRAYTEXT)
EndProcedure

Procedure.i _OSTheme_DummyWinCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
  If ((uMsg = #WM_THEMECHANGED) Or (uMsg = #WM_SYSCOLORCHANGE))
    If (_OSTheme_Tracking)
      _OSTheme_UpdateColors()
      If (_OSTheme_ColorsChanged)
        _OSTheme_ChangedFlag = #True
        If (_OSTheme_Callback <> #Null)
          CallFunctionFast(_OSTheme_Callback)
        EndIf
        If (_OSTheme_CustomEvent <> -1)
          PostEvent(_OSTheme_CustomEvent, -1, 0, _OSTheme_CustomEvent, _OSTheme_IsThemeDark)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (#PB_ProcessPureBasicEvents)
EndProcedure

Procedure.i _OSTheme_StartTracking_Win()
  Protected Result.i = #False
  _OSTheme_DummyWin = OpenWindow(#PB_Any, 0, 0, 10, 10, "", #PB_Window_BorderLess | #PB_Window_NoGadgets | #PB_Window_Invisible)
  If (_OSTheme_DummyWin)
    SetWindowCallback(@_OSTheme_DummyWinCallback(), _OSTheme_DummyWin)
    Result = #True
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure _OSTheme_StopTracking_Win()
  If (_OSTheme_DummyWin)
    SetWindowCallback(#Null, _OSTheme_DummyWin)
    CloseWindow(_OSTheme_DummyWin)
    _OSTheme_DummyWin = #Null
  EndIf
EndProcedure

CompilerEndIf







;-
;- - MacOS Version

CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)

#NSKeyValueObservingOptionNew = $01

Global *_OSTheme_NewKey.INTEGER = dlsym_(#RTLD_DEFAULT, "NSKeyValueChangeNewKey")
Global *_OSTheme_OldKey.INTEGER = dlsym_(#RTLD_DEFAULT, "NSKeyValueChangeOldKey")

DeclareC _OSTheme_KVOP(obj.i, sel.i, keyPath.i, object.i, change.i, context.i)

Global _OSTheme_KVO_Class.i = objc_allocateClassPair_(objc_getClass_("NSObject"), "_Cocoa_KVO", 0)
class_addMethod_(_OSTheme_KVO_Class, sel_registerName_("observeValueForKeyPath:ofObject:change:context:"), @_OSTheme_KVOP(), "v@:@@@^v")
objc_registerClassPair_(_OSTheme_KVO_Class)

Global _OSTheme_KVO.i = CocoaMessage(0, 0, "_Cocoa_KVO new")
Global _OSTheme_NSApp.i = CocoaMessage(0, 0, "NSApplication sharedApplication")
CocoaMessage(0, _OSTheme_NSApp, "addObserver:", _OSTheme_KVO, "forKeyPath:$", @"effectiveAppearance", "options:", #NSKeyValueObservingOptionNew, "context:", #nil)

ProcedureC _OSTheme_KVOP(obj.i, sel.i, keyPath.i, object.i, change.i, context.i)
  Select (PeekS(CocoaMessage(0, keyPath, "UTF8String"), -1, #PB_UTF8))
    Case "effectiveAppearance"
      CocoaMessage(0, 0, "NSAppearance setCurrentAppearance:", CocoaMessage(0, change, "objectForKey:", *_OSTheme_NewKey\i))
      If (_OSTheme_Tracking)
        _OSTheme_UpdateColors()
        If (_OSTheme_ColorsChanged)
          _OSTheme_ChangedFlag = #True
          If (_OSTheme_Callback <> #Null)
            CallFunctionFast(_OSTheme_Callback)
          EndIf
          If (_OSTheme_CustomEvent <> -1)
            PostEvent(_OSTheme_CustomEvent, -1, 0, _OSTheme_CustomEvent, _OSTheme_IsThemeDark)
          EndIf
        EndIf
      EndIf
  EndSelect
EndProcedure

CompilerIf (Not Defined(Cocoa_GetSysColor, #PB_Procedure))
Procedure.i Cocoa_GetSysColor(NSColorName.s)
  ; "windowBackgroundColor"
  ; "systemGrayColor"
  ; "controlBackgroundColor"
  ; "textColor"
  
  Protected.CGFloat r, g, b
  Protected NSColor.i, NSColorSpace.i
  
  ; There is no controlAccentColor on macOS < 10.14
  If ((NSColorName = "controlAccentColor") And (OSVersion() < #PB_OS_MacOSX_10_14))
    ProcedureReturn ($D5ABAD)
  EndIf
  
  ; There are no system colors on macOS < 10.10
  If ((Left(NSColorName, 6) = "system") And (OSVersion() < #PB_OS_MacOSX_10_10))
    NSColorName = LCase(Mid(NSColorName, 7, 1)) + Mid(NSColorName, 8)
  EndIf
  
  NSColorSpace = CocoaMessage(0, 0, "NSColorSpace deviceRGBColorSpace")
  NSColor = CocoaMessage(0, CocoaMessage(0, 0, "NSColor " + NSColorName), "colorUsingColorSpace:", NSColorSpace)
  If (NSColor)
    CocoaMessage(@r, NSColor, "redComponent")
    CocoaMessage(@g, NSColor, "greenComponent")
    CocoaMessage(@b, NSColor, "blueComponent")
    ProcedureReturn (RGB(r * 255.0, g * 255.0, b * 255.0))
  EndIf
EndProcedure
CompilerEndIf

Procedure _OSTheme_UpdateColors_Mac()
  CompilerIf (#_OSTheme_TestDefaults Or #_OSTheme_TestExtremes)
    ProcedureReturn
  CompilerEndIf
  _OSTheme_Color(#OSTheme_Window)        = Cocoa_GetSysColor("windowBackgroundColor")
  _OSTheme_Color(#OSTheme_WindowText)    = Cocoa_GetSysColor("textColor")
  _OSTheme_Color(#OSTheme_Control)       = Cocoa_GetSysColor("controlBackgroundColor")
  _OSTheme_Color(#OSTheme_ControlText)   = Cocoa_GetSysColor("controlTextColor")
  _OSTheme_Color(#OSTheme_Selection)     = Cocoa_GetSysColor("selectedControlColor")
  _OSTheme_Color(#OSTheme_SelectionText) = Cocoa_GetSysColor("selectedTextColor")
  
  If (OSVersion() >= #PB_OS_MacOSX_10_14)
    _OSTheme_Color(#OSTheme_Accent) = Cocoa_GetSysColor("controlAccentColor")
  Else
    _OSTheme_Color(#OSTheme_Accent) = Cocoa_GetSysColor("selectedControlColor")
  EndIf
  
  If (OSVersion() >= #PB_OS_MacOSX_10_10)
    _OSTheme_Color(#OSTheme_Border) = Cocoa_GetSysColor("systemGrayColor")
  Else
    _OSTheme_Color(#OSTheme_Border) = OSThemeBlendColors(#OSTheme_Window, #OSTheme_WindowText, 0.50)
  EndIf
  
  _OSTheme_Color(#OSTheme_DisabledText) = _OSTheme_Color(#OSTheme_Border);Cocoa_GetSysColor("disabledControlTextColor")
EndProcedure

Procedure.i _OSTheme_StartTracking_Mac()
  ; nothing to be done here
  ProcedureReturn (#True)
EndProcedure

Procedure _OSTheme_StopTracking_Mac()
  ; nothing to be done here
EndProcedure

CompilerEndIf










;-
;- Procedures (Private)

Procedure.i _OSTheme_IsColorDark(Color.i)
  If (0.30 * Red(Color) + 0.59 * Green(Color) + 0.11 * Blue(Color) < 128)
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure _OSTheme_UpdateColors()
  Protected i.i
  For i = 0 To #_OSTheme_Count - 1
    _OSTheme_PreviousColor(i) = _OSTheme_Color(i)
    _OSTheme_Color(i) = _OSTheme_DefaultColor(i)
  Next i
  
  CompilerSelect (#PB_Compiler_OS)
    CompilerCase (#PB_OS_Windows)
      _OSTheme_UpdateColors_Win()
    CompilerCase (#PB_OS_MacOS)
      _OSTheme_UpdateColors_Mac()
  CompilerEndSelect
  
  _OSTheme_ColorsChanged = #False
  For i = 0 To #_OSTheme_Count - 1
    _OSTheme_Color(i) = _OSTheme_Color(i) & #_OSTheme_RGBMask
    If (_OSTheme_Color(i) <> _OSTheme_PreviousColor(i))
      _OSTheme_ColorsChanged = #True
      Break
    EndIf
  Next i
  
  _OSTheme_IsThemeDark = _OSTheme_IsColorDark(_OSTheme_Color(#OSTheme_Window))
EndProcedure

;-
;- Procedures (Public)

Procedure.i OSThemeColor(Index.i) ; Returns the system color for a given index
  Protected Result.i = -1
  If ((Index >= 0) And (Index < #_OSTheme_Count))
    Result = _OSTheme_Color(Index)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i OSThemeBlendColors(Index1.i, Index2.i, Fade.f) ; Blends two system colors (by index) from 0.0 to 1.0
  Protected Result.i = -1
  If ((Index1 >= 0) And (Index2 < #_OSTheme_Count))
    If ((Index1 >= 0) And (Index2 < #_OSTheme_Count))
      Index1 = OSThemeColor(Index1)
      Index2 = OSThemeColor(Index2)
      Protected R.i = Red(Index1) + (Red(Index2) - Red(Index1)) * Fade
      Protected G.i = Green(Index1) + (Green(Index2) - Green(Index1)) * Fade
      Protected B.i = Blue(Index1) + (Blue(Index2) - Blue(Index1)) * Fade
      Result = RGB(R, G, B)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i OSThemeBasicComplement(BackgroundColor.i, DarkColor.i = #Black, LightColor.i = #White) ; Returns a readable text color for a given background
  If (_OSTheme_IsColorDark(BackgroundColor))
    ProcedureReturn (LightColor)
  EndIf
  ProcedureReturn (DarkColor)
EndProcedure

Procedure.i OSThemeChanged() ; Returns #True if OS color theme changed since last call
  Protected Result.i = _OSTheme_ChangedFlag
  _OSTheme_ChangedFlag = #False
  ProcedureReturn (Result)
EndProcedure

Procedure.i OSThemeIsDark() ; Returns #True if OS color theme has dark background
  ProcedureReturn (_OSTheme_IsThemeDark)
EndProcedure

Procedure.i StartTrackingOSTheme(*Callback = #Null, CustomEvent.i = -1) ; Start tracking OS theme changes, with optional callback or PostEvent
  If (Not _OSTheme_Tracking)
    CompilerSelect (#PB_Compiler_OS)
      CompilerCase (#PB_OS_Windows)
        _OSTheme_Tracking = _OSTheme_StartTracking_Win()
      CompilerCase (#PB_OS_MacOS)
        _OSTheme_Tracking = _OSTheme_StartTracking_Mac()
    CompilerEndSelect
  EndIf
  
  If (_OSTheme_Tracking)
    _OSTheme_Callback    = *Callback
    _OSTheme_CustomEvent = CustomEvent
  EndIf
  
  ProcedureReturn (_OSTheme_Tracking)
EndProcedure

Procedure.i StopTrackingOSTheme() ; Stop tracking OS theme changes
  If (_OSTheme_Tracking)
    CompilerSelect (#PB_Compiler_OS)
      CompilerCase (#PB_OS_Windows)
        _OSTheme_StopTracking_Win()
      CompilerCase (#PB_OS_MacOS)
        _OSTheme_StopTracking_Mac()
    CompilerEndSelect
    _OSTheme_Tracking = #False
  EndIf
  
  _OSTheme_ChangedFlag = #False
  _OSTheme_Callback    = #Null
  _OSTheme_CustomEvent = -1
  
  ProcedureReturn (#Null)
EndProcedure


CompilerIf (#True) ; Ensure colors are updated to OS theme at initial run
  _OSTheme_UpdateColors()
CompilerEndIf



;-
;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile And (Not #OSTheme_CopiedIntoSource))
DisableExplicit

Global DefaultFontID.i

Procedure Redraw()
  If StartDrawing(CanvasOutput(0))
    Box(0, 0, OutputWidth(), OutputHeight(), GetOSWindowColor())
    
    DrawingFont(DefaultFontID)
    
    Protected dx.i = OutputWidth()/10
    Protected dy.i = OutputHeight()/10
    dx = DrawText(dx, dy, "This is WindowTextColor on WindowColor ", GetOSWindowTextColor(), GetOSWindowColor())
    If (OSThemeIsDark())
      DrawText(dx, dy, "(Dark Theme)", GetOSWindowTextColor(), GetOSWindowColor())
    Else
      DrawText(dx, dy, "(Light Theme)", GetOSWindowTextColor(), GetOSWindowColor())
    EndIf
    
    dx = OutputWidth()/10
    dy + 2.0 * TextHeight("A1")
    DrawText(dx, dy, "SelectionTextColor on SelectionColor", GetOSSelectionTextColor(), GetOSSelectionColor())
    
    dx = OutputWidth()/10
    dy + 2.0 * TextHeight("A1")
    DrawText(dx, dy, "DisabledTextColor", GetOSDisabledTextColor(), GetOSWindowColor())
    
    dx = OutputWidth()/10
    dy + 2.0 * TextHeight("A1")
    Box(dx, dy, OutputWidth() * 0.60, OutputHeight() * 0.35, GetOSBorderColor())
    Box(dx + 1, dy + 1, OutputWidth() * 0.60 - 2, OutputHeight() * 0.35 - 2, GetOSControlColor())
    
    dx = OutputWidth()/10 + 4
    dy + 4
    DrawText(dx, dy, "ControlTextColor on ControlColor", GetOSControlTextColor(), GetOSControlColor())
    
    dy + 1.5 * TextHeight("A1")
    DrawText(dx, dy, "BasicComplement on AccentColor", OSThemeBasicComplement(GetOSAccentColor()), GetOSAccentColor())
    
    dy + 1.5 * TextHeight("A1")
    DrawText(dx, dy, "BorderColor", GetOSBorderColor(), GetOSControlColor())
    
    StopDrawing()
  EndIf
EndProcedure




Procedure MyCustomCallback()
  RemoveWindowTimer(0, 0)
  AddGadgetItem(1, -1, "Theme change - detected by custom callback")
  Redraw()
  AddWindowTimer(0, 0, 3*1000)
EndProcedure

#MyCustomEvent = #PB_Event_FirstCustomValue + 123

OpenWindow(0, 0, 0, 480, 360, #PB_Compiler_Filename, #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_Invisible)
  CanvasGadget(0, 10, 10, WindowWidth(0) - 20, WindowHeight(0) - 20 - 100)
  EditorGadget(1, 10, WindowHeight(0) - 10 - 100, WindowWidth(0) - 20, 100)
  TextGadget(2, 0, -20, 100, 20, "")
  DefaultFontID = GetGadgetFont(2)
  AddKeyboardShortcut(0, #PB_Shortcut_Escape, 1)
  StickyWindow(0, #True)
Redraw()
StartTrackingOSTheme(@MyCustomCallback(), #MyCustomEvent)
HideWindow(0, #False)

AddGadgetItem(1, -1, "Watching for OS color theme changes...")

Repeat
  Event = WaitWindowEvent(10)
  If (Event = #MyCustomEvent)
    AddGadgetItem(1, -1, "Theme change - detected by custom posted event")
  ElseIf (Event = #PB_Event_Timer)
    ClearGadgetItems(1)
    AddGadgetItem(1, -1, "...")
    RemoveWindowTimer(0, 0)
  ElseIf (Event = #Null)
    If (OSThemeChanged())
      AddGadgetItem(1, -1, "Theme change - detected by polling OSThemeChanged()")
    EndIf
  EndIf
Until ((Event = #PB_Event_CloseWindow) Or (Event = #PB_Event_Menu))

CloseWindow(0)
StopTrackingOSTheme()
CloseDebugOutput()

CompilerEndIf
CompilerEndIf
;-
