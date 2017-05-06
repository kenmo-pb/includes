; +---------------+
; | DesktopHelper |
; +---------------+
; | 2016.01.21 . Creation (PureBasic 5.41)
; | 2017.05.05 . Cleaned up demo

CompilerIf (Not Defined(__DesktopHelper_Included, #PB_Constant))
#__DesktopHelper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;-
;- Procedures

Procedure.i DesktopCount()
  ProcedureReturn (ExamineDesktops())
EndProcedure

Procedure.i DesktopFromPoint(x.i, y.i)
  Protected Result.i = 0; -1
  Protected n.i = DesktopCount()
  If (n > 0)
    Protected i.i
    For i = 0 To n - 1
      If ((x >= DesktopX(i)) And (y >= DesktopY(i)))
        If (x < DesktopX(i) + DesktopWidth(i))
          If (y < DesktopY(i) + DesktopHeight(i))
            Result = i
            Break
          EndIf
        EndIf
      EndIf
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DesktopFromWindow(Window.i)
  Protected x.i = WindowX(Window) + WindowWidth(Window, #PB_Window_FrameCoordinate)/2
  Protected y.i = WindowY(Window) + WindowHeight(Window, #PB_Window_FrameCoordinate)/4;/2
  ProcedureReturn (DesktopFromPoint(x, y))
EndProcedure

Procedure.i DesktopWindowX(Window.i, Desktop.i = -1)
  Protected Result.i = 0
  If (Desktop < 0)
    Desktop = DesktopFromWindow(Window)
  EndIf
  If (Desktop >= 0)
    Result = WindowX(Window) - DesktopX(Desktop)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DesktopWindowY(Window.i, Desktop.i = -1)
  Protected Result.i = 0
  If (Desktop < 0)
    Desktop = DesktopFromWindow(Window)
  EndIf
  If (Desktop >= 0)
    Result = WindowY(Window) - DesktopY(Desktop)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i IsMinimized(Window.i)
  ProcedureReturn (Bool(GetWindowState(Window) = #PB_Window_Minimize))
EndProcedure

Procedure.i IsMaximized(Window.i)
  ProcedureReturn (Bool(GetWindowState(Window) = #PB_Window_Maximize))
EndProcedure

Procedure CenterWindowInWindow(Window.i, Parent.i)
  If (GetWindowState(Window) <> #PB_Window_Normal)
    SetWindowState(Window, #PB_Window_Normal)
  EndIf
  Protected x.i = WindowX(Parent) + (WindowWidth(Parent)  - WindowWidth(Window))/2
  Protected y.i = WindowY(Parent) + (WindowHeight(Parent) - WindowHeight(Window))/2
  ResizeWindow(Window, x, y, #PB_Ignore, #PB_Ignore)
EndProcedure

Procedure.i SameDesktop(Window.i, Parent.i)
  ProcedureReturn (Bool(DesktopFromWindow(Window) = DesktopFromWindow(Parent)))
EndProcedure

Procedure EnsureSameDesktop(Window.i, Parent.i)
  If (Not SameDesktop(Window, Parent))
    CenterWindowInWindow(Window, Parent)
  EndIf
EndProcedure

Procedure CenterWindowInDesktop(Window.i, Desktop.i = 0, Maximized.i = #False)
  Protected n.i = DesktopCount()
  If (n > 0)
    If ((Desktop < 0) Or (Desktop >= n))
      Desktop = 0
    EndIf
    If (GetWindowState(Window) <> #PB_Window_Normal)
      SetWindowState(Window, #PB_Window_Normal)
    EndIf
    Protected x.i = DesktopX(Desktop) + (DesktopWidth(Desktop)  - WindowWidth(Window, #PB_Window_FrameCoordinate))/2
    Protected y.i = DesktopY(Desktop) + (DesktopHeight(Desktop) - WindowHeight(Window, #PB_Window_FrameCoordinate))/2
    ResizeWindow(Window, x, y, #PB_Ignore, #PB_Ignore)
    If (Maximized)
      SetWindowState(Window, #PB_Window_Maximize)
    EndIf
  EndIf
EndProcedure

Procedure LocateWindowInDesktop(Window.i, x.i, y.i, Desktop.i = 0, Maximized.i = #False)
  Protected n.i = DesktopCount()
  If (n > 0)
    If ((Desktop < 0) Or (Desktop >= n))
      Desktop = 0
    EndIf
    If (GetWindowState(Window) <> #PB_Window_Normal)
      SetWindowState(Window, #PB_Window_Normal)
    EndIf
    x = DesktopX(Desktop) + x
    y = DesktopY(Desktop) + y
    ResizeWindow(Window, x, y, #PB_Ignore, #PB_Ignore)
    If (Maximized)
      SetWindowState(Window, #PB_Window_Maximize)
    EndIf
  EndIf
EndProcedure











;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

OpenWindow(1, 400, 0, 480, 360, "Parent Window", #PB_Window_SystemMenu)
  ButtonGadget(1, 40, 40, 400, 280, "Center in Screen")
OpenWindow(0, 0, 0, 240, 180, "Child Window", #PB_Window_SystemMenu, WindowID(1))
  ButtonGadget(0, 40, 40, 160, 100, "Center in Parent Window")

Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_Gadget)
    If (EventGadget() = 0)
      CenterWindowInWindow(0, 1)
    ElseIf (EventGadget() = 1)
      CenterWindowInDesktop(1, DesktopFromWindow(1))
    EndIf
  EndIf
Until (Event = #PB_Event_CloseWindow)


CompilerEndIf
CompilerEndIf
;-