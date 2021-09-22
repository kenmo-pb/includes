; +-------------+
; | CocoaHelper |
; +-------------+
; | 2015.11.20 . Creation (PureBasic 5.31)
; | 2017.05.18 . Multiple-include safe
; | 2020-06-27 . Added IsDarkMode(), GetSysColor(), GuessWindowColor()
; | 2021-02-21 . Key-Value Observer for theme changes, setCurrentAppearance

;-
CompilerIf (Not Defined(__CocoaHelper_Included, #PB_Constant))
#__CocoaHelper_Included = #True

CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)

CompilerIf (Not Defined(CocoaHelper_TrackThemeChanges, #PB_Constant))
  #CocoaHelper_TrackThemeChanges = #False
CompilerEndIf

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;- Imports

EnumerationBinary
  #NSKeyValueObservingOptionNew
  #NSKeyValueObservingOptionOld
EndEnumeration

#kThemeBrushAlertBackgroundActive = 3

ImportC ""
  HIThemeBrushCreateCGColor(Brush, *Color)
  CGColorGetComponents(Color)
  CGColorGetNumberOfComponents(Color)
  CGColorRelease(Color)
EndImport



;-
;- Procedures

Procedure.i NSColor(RGB.i)
  Protected.CGFloat r, g, b, a
  r = Red(RGB)   / 255.0
  g = Green(RGB) / 255.0
  b = Blue(RGB)  / 255.0
  a = 1.0
  ProcedureReturn (CocoaMessage(0, 0, "NSColor colorWithDeviceRed:@", @r, "green:@", @g, "blue:@", @b, "alpha:@", @a))
EndProcedure

Procedure.i Cocoa_IsDarkMode()
  Protected *appearance = CocoaMessage(0, CocoaMessage(0, 0, "NSUserDefaults standardUserDefaults"), "stringForKey:$", @"AppleInterfaceStyle")
  If (*appearance)
    *appearance = CocoaMessage(0, *appearance, "UTF8String")
    If (FindString(PeekS(*appearance, -1, #PB_UTF8), "Dark"))
      ProcedureReturn (#True)
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

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

Procedure.i Cocoa_GuessWindowColor()
  If (OSVersion() >= #PB_OS_MacOSX_10_14)
    ProcedureReturn (Cocoa_GetSysColor("windowBackgroundColor"))
  Else
    Protected Result.i
    Protected CGColor.i
    HIThemeBrushCreateCGColor(#kThemeBrushAlertBackgroundActive, @CGColor)
    If (CGColor)
      Protected.i NbComponents = CGColorGetNumberOfComponents(CGColor)
      Protected *Components  = CGColorGetComponents(CGColor)
      
      Protected.i r, g, b, c
      If (*Components And (NbComponents = 2)) ; gray and alpha
        
        CompilerIf (#PB_Compiler_Processor = #PB_Processor_x64) ; CGFloat is a double on 64-bit system
          c = 255 * PeekD(*Components)
        CompilerElse
          c = 255 * PeekF(*Components)
        CompilerEndIf
        
        Result = RGB(c, c, c)
        
      ElseIf (*Components And (NbComponents = 4)) ; RGBA
        
        CompilerIf (#PB_Compiler_Processor = #PB_Processor_x64)
          r = 255 * PeekD(*Components)
          g = 255 * PeekD(*Components + 8)
          b = 255 * PeekD(*Components + 16)
        CompilerElse
          r = 255 * PeekF(*Components)
          g = 255 * PeekF(*Components + 4)
          b = 255 * PeekF(*Components + 8)
        CompilerEndIf
        
        Result = RGB(r, g, b)
      EndIf
      
      CGColorRelease(CGColor)
      ProcedureReturn (Result)
    EndIf
  EndIf
EndProcedure

Procedure.i Cocoa_SetBackgroundColor(Object.i, RGB.i)
  ProcedureReturn (CocoaMessage(0, Object, "setBackgroundColor:", NSColor(RGB)))
EndProcedure

Procedure.s Cocoa_ClassName(Object.i)
  Protected Result.s = ""
  If (Object)
    CocoaMessage(@Object, Object, "className")
    CocoaMessage(@Object, Object, "UTF8String")
    Result = PeekS(Object, -1, #PB_UTF8)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Cocoa_Superclass(Object.i)
  ProcedureReturn (CocoaMessage(0, Object, "superclass"))
EndProcedure

Procedure.i Cocoa_Superview(Object.i)
  ProcedureReturn (CocoaMessage(0, Object, "superview"))
EndProcedure



;-
;- Theme Change Detection

CompilerIf (#CocoaHelper_TrackThemeChanges) ; Monitor OS color scheme changes
  
  Global *NSKeyValueChangeNewKey.Integer = dlsym_(#RTLD_DEFAULT, "NSKeyValueChangeNewKey")
  Global *NSKeyValueChangeOldKey.Integer = dlsym_(#RTLD_DEFAULT, "NSKeyValueChangeOldKey")
  
  DeclareC KVO(obj, sel, keyPath, object, change, context)
  
  Global _Cocoa_KVO_Class.i = objc_allocateClassPair_(objc_getClass_("NSObject"), "_Cocoa_KVO", 0)
  class_addMethod_(_Cocoa_KVO_Class, sel_registerName_("observeValueForKeyPath:ofObject:change:context:"), @KVO(), "v@:@@@^v")
  objc_registerClassPair_(_Cocoa_KVO_Class)
  
  Global _Cocoa_KVO.i = CocoaMessage(0, 0, "_Cocoa_KVO new")
  Global _Cocoa_NSApp.i = CocoaMessage(0, 0, "NSApplication sharedApplication")
  CocoaMessage(0, _Cocoa_NSApp, "addObserver:", _Cocoa_KVO, "forKeyPath:$", @"effectiveAppearance", "options:", #NSKeyValueObservingOptionNew, "context:", #nil)
  
  Global _Cocoa_ThemeChanged.i = #False
  
  ProcedureC KVO(obj, sel, keyPath, object, change, context)
    Select PeekS(CocoaMessage(0, keyPath, "UTF8String"), -1, #PB_UTF8)
      
      Case "effectiveAppearance":
        CocoaMessage(0, 0, "NSAppearance setCurrentAppearance:", CocoaMessage(0, change, "objectForKey:", *NSKeyValueChangeNewKey\i))
        _Cocoa_ThemeChanged = #True
        
    EndSelect
  EndProcedure
  
  Procedure.i Cocoa_ThemeChanged()
    Protected Result.i = _Cocoa_ThemeChanged
    _Cocoa_ThemeChanged = #False
    ProcedureReturn (Result)
  EndProcedure
  
CompilerEndIf




CompilerEndIf
CompilerEndIf
;-
