; +------------------+
; | WindowFromGadget |
; +------------------+
; | 2019-11-05 : Creation (PureBasic 5.70)

; TODO
; implement GetWindowFromGadget on non-Windows

;-
CompilerIf (Not Defined(_WindowFromGadget_Included, #PB_Constant))
#_WindowFromGadget_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Imports

CompilerIf (Not Defined(PB_Object_EnumerateStart, #PB_Procedure))
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Import ""
      PB_Object_EnumerateStart(Object.i)
      PB_Object_EnumerateNext(Object.i, *ID.Integer)
      PB_Object_EnumerateAbort(Object.i)
      PB_Object_Count(Objects.i)
      PB_Window_Objects.i
    EndImport
  CompilerElse
    ImportC ""
      PB_Object_EnumerateStart(Object.i)
      PB_Object_EnumerateNext(Object.i, *ID.Integer)
      PB_Object_EnumerateAbort(Object.i)
      PB_Object_Count(Objects.i)
      PB_Window_Objects.i
    EndImport
  CompilerEndIf
CompilerEndIf


;-
;- Procedures

Procedure.i GetWindowFromID(WindowID.i)
  Protected Result.i = -1
  If (WindowID)
    PB_Object_EnumerateStart(PB_Window_Objects)
    If (PB_Window_Objects)
      Protected Window.i
      While (PB_Object_EnumerateNext(PB_Window_Objects, @Window))
        If (WindowID(Window) = WindowID)
          Result = Window
          Break
        EndIf
      Wend
      PB_Object_EnumerateAbort(PB_Window_Objects)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GetWindowFromGadget(Gadget.i)
  Protected Result.i = -1
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Result = GetWindowFromID(GetAncestor_(GadgetID(Gadget), #GA_ROOT))
  CompilerElse
    ;? implement!
  CompilerEndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GetBuildWindow()
  ProcedureReturn (GetWindowFromID(UseGadgetList(0)))
EndProcedure








;-
;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

OpenWindow(5, 0, 0, 320, 240, "", #PB_Window_Invisible)
Debug GetBuildWindow()
Debug GetWindowFromID(WindowID(5))

ContainerGadget(1, 0, 0, 320, 240)
  TextGadget(2, 0, 0, 320, 240, "")
CloseGadgetList()
Debug GetWindowFromGadget(2)

CompilerEndIf
CompilerEndIf
;-