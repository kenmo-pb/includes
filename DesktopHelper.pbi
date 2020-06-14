; +---------------+
; | DesktopHelper |
; +---------------+
; | 2016.01.21 . Creation (PureBasic 5.41)
; | 2017.05.05 . Cleaned up demo
; | 2019.10.18 . Added Global/Desktop conversions, Size matching
; | 2020-04-03 . Added TopLeft/Center XY, PointInWindow, SetTopWindow

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

Procedure.i DesktopExists(Desktop.i)
  ProcedureReturn (Bool((Desktop >= 0) And (Desktop < DesktopCount())))
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

Procedure.i GlobalToDesktopX(GlobalX.i, Desktop.i)
  ProcedureReturn (GlobalX - DesktopX(Desktop))
EndProcedure

Procedure.i GlobalToDesktopY(GlobalY.i, Desktop.i)
  ProcedureReturn (GlobalY - DesktopY(Desktop))
EndProcedure

Procedure.i DesktopToGlobalX(DesktopX.i, Desktop.i)
  ProcedureReturn (DesktopX + DesktopX(Desktop))
EndProcedure

Procedure.i DesktopToGlobalY(DesktopY.i, Desktop.i)
  ProcedureReturn (DesktopY + DesktopY(Desktop))
EndProcedure

Procedure.i DesktopWindowX(Window.i, Desktop.i = -1)
  Protected Result.i = 0
  If (Desktop < 0)
    Desktop = DesktopFromWindow(Window)
  EndIf
  If (Desktop >= 0)
    Result = GlobalToDesktopX(WindowX(Window), Desktop)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DesktopWindowY(Window.i, Desktop.i = -1)
  Protected Result.i = 0
  If (Desktop < 0)
    Desktop = DesktopFromWindow(Window)
  EndIf
  If (Desktop >= 0)
    Result = GlobalToDesktopY(WindowY(Window), Desktop)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure GetWindowTopLeftXY(Window.i, *x.INTEGER, *y.INTEGER)
  If (*x)
    *x\i = WindowX(Window)
  EndIf
  If (*y)
    *y\i = WindowY(Window)
  EndIf
EndProcedure

Procedure GetWindowCenterXY(Window.i, *cx.INTEGER, *cy.INTEGER)
  If (*cx)
    *cx\i = WindowX(Window) + WindowWidth(Window)/2
  EndIf
  If (*cy)
    *cy\i = WindowY(Window) + WindowHeight(Window)/2
  EndIf
EndProcedure

Procedure.i PointInWindow(x.i, y.i, Window.i)
  If ((x >= WindowX(Window)) And (x < WindowX(Window) + WindowWidth(Window)))
    If ((y >= WindowY(Window)) And (y < WindowY(Window) + WindowHeight(Window)))
      ProcedureReturn (#True)
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i DesktopMatchesSize(Desktop.i, Width.i, Height.i)
  Protected Result.i = #False
  If ((Width > 0) And (Height > 0))
    If ((Desktop >= 0) And (Desktop < DesktopCount()))
      If ((DesktopWidth(Desktop) = Width) And (DesktopHeight(Desktop) = Height))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DesktopBySize(Width.i, Height.i, NotFoundResult.i = -1)
  Protected Result.i = NotFoundResult
  If ((Width > 0) And (Height > 0))
    Protected n.i = DesktopCount()
    Protected i.i
    For i = 0 To n - 1
      If (DesktopMatchesSize(i, Width, Height))
        Result = i
        Break
      EndIf
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GuessWhichDesktop(Width.i, Height.i, PreviousDesktop.i = -1)
  Protected Result.i = 0 ; Default to main screen
  
  If ((PreviousDesktop >= 0) And DesktopMatchesSize(PreviousDesktop, Width, Height))
    ; Previous known desktop ID matches current size = retain it
    Result = PreviousDesktop
  Else
    Protected SizeMatch.i = DesktopBySize(Width, Height, -1)
    If (SizeMatch >= 0)
      ; Found matching display size - ID order probably changed
      Result = SizeMatch
    Else
      If (DesktopExists(PreviousDesktop))
        ; No matching size, so use previous ID (maybe resized?)
        Result = PreviousDesktop
      EndIf
    EndIf
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

Procedure EnsureWindowVisible(Window.i)
  Protected Visible.i = #False
  If (GetWindowState(Window) = #PB_Window_Normal)
    Protected WinX.i = WindowX(Window)
    Protected WinY.i = WindowY(Window)
    Protected WinW.i = WindowWidth(Window)
    Protected WinH.i = WindowHeight(Window)
    Protected n.i = DesktopCount()
    Protected i.i
    For i = 0 To n - 1
      If (WinX < DesktopX(i) + DesktopWidth(i))
        If (WinY < DesktopY(i) + DesktopHeight(i))
          If (WinX + WinW > DesktopX(i))
            If (WinY + WinH > DesktopY(i))
              Visible = #True
              Break
            EndIf
          EndIf
        EndIf
      EndIf
    Next i
    If (Not Visible)
      CenterWindowInDesktop(Window, 0, #False)
    EndIf
  EndIf
EndProcedure

Procedure.i SetTopWindow(Window.i, NoActivate.i = #False)
  Protected Result.i = #False
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    If (NoActivate)
      Protected CurTopmost.i = GetWindowLongPtr_(WindowID(Window), #GWL_EXSTYLE) & #WS_EX_TOPMOST
      SetWindowPos_(WindowID(Window), #HWND_TOPMOST, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOACTIVATE)
      If (Not CurTopmost)
        SetWindowPos_(WindowID(Window), #HWND_NOTOPMOST, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOACTIVATE)
      EndIf
    Else
      Result = Bool(SetForegroundWindow_(WindowID(Window)))
    EndIf
  CompilerElse
    StickyWindow(Window, #True)
    If (Not NoActivate)
      SetActiveWindow(Window)
    EndIf
    StickyWindow(Window, #False)
  CompilerEndIf
  ProcedureReturn (Result)
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