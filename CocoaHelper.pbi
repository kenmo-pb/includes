; +-------------+
; | CocoaHelper |
; +-------------+
; | 2015.11.20 . Creation (PureBasic 5.31)
; | 2017.05.18 . Multiple-include safe

;-
CompilerIf (Not Defined(__CocoaHelper_Included, #PB_Constant))
#__CocoaHelper_Included = #True

CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Procedures

Procedure.i NSColor(RGB.i)
  Protected.CGFloat r, g, b, a
  r = Red(RGB)   / 255.0
  g = Green(RGB) / 255.0
  b = Blue(RGB)  / 255.0
  a = 1.0
  ProcedureReturn (CocoaMessage(0, 0, "NSColor colorWithDeviceRed:@", @r, "green:@", @g, "blue:@", @b, "alpha:@", @a))
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


CompilerEndIf
CompilerEndIf
;-