; +------------+
; | CanvasDrag |
; +------------+
; | 2019-04-25 : Creation
; | 2019-11-03 : Added L/R/M mouse button handling
; | 2019-11-04 : Added Start/Stop/Change custom EventTypes, threshold/clamp
; | 2019-11-05 : Added CanvasClickWasDragStop() to avoid double-handling
; | 2019-11-26 : Added LockXY(), ScaleX(), ScaleY(), demo text instructions
; | 2019-11-27 : Get real parent window (WindowFromGadget.pbi required)

; TODO
; release drag on MouseLeave ? depends on OS ?

;-
CompilerIf (Not Defined(_CanvasDrag_Included, #PB_Constant))
#_CanvasDrag_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Constants

Enumeration
  #CanvasDrag_Start = #PB_EventType_FirstCustomValue
  #CanvasDrag_Stop
  #CanvasDrag_Change
EndEnumeration


;-
;- Includes

XIncludeFile "WindowFromGadget.pbi"

;-
;- Globals

Global _CanvasDown.i = #False
Global _CanvasDragging.i = #False
Global _CanvasClamp.i = #False
Global _CanvasWindow.i = 0
Global _CanvasDragThreshold.i = 3
Global _CanvasDragGadget.i
Global _CanvasClickWasDrag.i = #False
Global _CanvasButton.i
Global _CanvasAnchorX.i
Global _CanvasAnchorY.i
Global _CanvasPreviousSelX.i
Global _CanvasPreviousSelY.i
Global _CanvasSelX.i
Global _CanvasSelY.i
Global _CanvasLeftX.i
Global _CanvasRightX.i
Global _CanvasTopY.i
Global _CanvasBottomY.i
Global _CanvasDragX.i
Global _CanvasDragY.i
Global _CanvasDragWidth.i
Global _CanvasDragHeight.i
Global _CanvasDirX.i
Global _CanvasDirY.i
Global _CanvasUserX.d
Global _CanvasUserY.d



;-
;- Procedures

Declare _CanvasDragCallback()

Procedure.i IsCanvasDragging()
  ProcedureReturn (_CanvasDragging)
EndProcedure
Procedure.i CanvasDragGadget()
  ProcedureReturn (_CanvasDragGadget)
EndProcedure
Procedure.i CanvasDragButton()
  ProcedureReturn (_CanvasButton)
EndProcedure
Procedure.i CanvasClickWasDragStop()
  Protected Result.i = _CanvasClickWasDrag
  _CanvasClickWasDrag = #False
  ProcedureReturn (Result)
EndProcedure

Procedure.i CanvasDragAnchorX()
  ProcedureReturn (_CanvasAnchorX)
EndProcedure
Procedure.i CanvasDragAnchorY()
  ProcedureReturn (_CanvasAnchorY)
EndProcedure
Procedure.i CanvasDragCursorX()
  ProcedureReturn (_CanvasSelX)
EndProcedure
Procedure.i CanvasDragCursorY()
  ProcedureReturn (_CanvasSelY)
EndProcedure
Procedure.i CanvasDragDeltaX()
  Protected Result.i = _CanvasSelX - _CanvasPreviousSelX
  _CanvasPreviousSelX = _CanvasSelX
  ProcedureReturn (Result)
EndProcedure
Procedure.i CanvasDragDeltaY()
  Protected Result.i = _CanvasSelY - _CanvasPreviousSelY
  _CanvasPreviousSelY = _CanvasSelY
  ProcedureReturn (Result)
EndProcedure
Procedure.i CanvasDragRelativeX()
  ProcedureReturn (_CanvasDragX)
EndProcedure
Procedure.i CanvasDragRelativeY()
  ProcedureReturn (_CanvasDragY)
EndProcedure
Procedure.i CanvasDragDirX()
  ProcedureReturn (_CanvasDirX)
EndProcedure
Procedure.i CanvasDragDirY()
  ProcedureReturn (_CanvasDirY)
EndProcedure

Procedure.i CanvasDragLeftX()
  ProcedureReturn (_CanvasLeftX)
EndProcedure
Procedure.i CanvasDragRightX()
  ProcedureReturn (_CanvasRightX)
EndProcedure
Procedure.i CanvasDragTopY()
  ProcedureReturn (_CanvasTopY)
EndProcedure
Procedure.i CanvasDragBottomY()
  ProcedureReturn (_CanvasBottomY)
EndProcedure
Procedure.i CanvasDragWidth()
  ProcedureReturn (_CanvasDragWidth)
EndProcedure
Procedure.i CanvasDragHeight()
  ProcedureReturn (_CanvasDragHeight)
EndProcedure

Procedure CanvasDragLockXY(UserX.d, UserY.d)
  _CanvasUserX = UserX
  _CanvasUserY = UserY
EndProcedure
Procedure.d CanvasDragScaleX(ScaleX.d = 1.0)
  ProcedureReturn (ScaleX * _CanvasDragX + _CanvasUserX)
EndProcedure
Procedure.d CanvasDragScaleY(ScaleY.d = 1.0)
  ProcedureReturn (ScaleY * _CanvasDragY + _CanvasUserY)
EndProcedure

Procedure.i CanvasDragContainsPoint(x.i, y.i)
  Protected Result.i = #False
  If (_CanvasDragging)
    If ((x >= _CanvasLeftX) And (x <= _CanvasRightX))
      If ((y >= _CanvasTopY) And (y <= _CanvasBottomY))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CanvasDragContainsBox(x.i, y.i, Width.i, Height.i)
  Protected Result.i = #False
  If (_CanvasDragging)
    If ((x >= _CanvasLeftX) And (x + Width <= _CanvasRightX))
      If ((y >= _CanvasTopY) And (y + Height <= _CanvasBottomY))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CanvasDragIntersectsBox(x.i, y.i, Width.i, Height.i)
  Protected Result.i = #False
  If (_CanvasDragging)
    If ((x <= _CanvasRightX) And (x + Width >= _CanvasLeftX))
      If ((y <= _CanvasBottomY) And (y + Height >= _CanvasTopY))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure SetCanvasDragThreshold(Pixels.i)
  If (Pixels >= 0)
    _CanvasDragThreshold = Pixels
  EndIf
EndProcedure

Procedure SetCanvasDragClamp(State.i)
  _CanvasClamp = Bool(State)
EndProcedure

Procedure CancelCanvasDrag()
  If (_CanvasDragging)
    _CanvasDown = #False
    _CanvasDragging = #False
  EndIf
EndProcedure

Procedure.i TrackCanvasDrag(Gadget.i)
  BindGadgetEvent(Gadget, @_CanvasDragCallback())
EndProcedure

Procedure.i UntrackCanvasDrag(Gadget.i)
  UnbindGadgetEvent(Gadget, @_CanvasDragCallback())
EndProcedure

;-

Procedure _CanvasDragCallback()
  If ((Not _CanvasDown) Or (_CanvasDragGadget = EventGadget()))
    Select (EventType())
      Case #PB_EventType_LeftButtonDown, #PB_EventType_RightButtonDown, #PB_EventType_MiddleButtonDown
        If (Not _CanvasDown)
          _CanvasDown = #True
          _CanvasDragGadget = EventGadget()
          _CanvasAnchorX = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
          _CanvasAnchorY = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
          _CanvasPreviousSelX = _CanvasAnchorX
          _CanvasPreviousSelY = _CanvasAnchorY
          Select (EventType())
            Case #PB_EventType_LeftButtonDown
              _CanvasButton = #PB_Canvas_LeftButton
            Case #PB_EventType_RightButtonDown
              _CanvasButton = #PB_Canvas_RightButton
            Case #PB_EventType_MiddleButtonDown
              _CanvasButton = #PB_Canvas_MiddleButton
          EndSelect
        EndIf
      Case #PB_EventType_LeftButtonUp, #PB_EventType_RightButtonUp, #PB_EventType_MiddleButtonUp
        If (_CanvasDown)
          If (((EventType() = #PB_EventType_LeftButtonUp) And (_CanvasButton = #PB_Canvas_LeftButton)) Or
              ((EventType() = #PB_EventType_RightButtonUp) And (_CanvasButton = #PB_Canvas_RightButton)) Or
              ((EventType() = #PB_EventType_MiddleButtonUp) And (_CanvasButton = #PB_Canvas_MiddleButton)))
            _CanvasDown = #False
            If (_CanvasDragging)
              _CanvasDragging = #False
              PostEvent(#PB_Event_Gadget, _CanvasWindow, EventGadget(), #CanvasDrag_Stop)
            EndIf
          EndIf
        EndIf
      Case #PB_EventType_MouseLeave
        ;
      Case #PB_EventType_MouseMove
        If (_CanvasDown)
          _CanvasSelX = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
          _CanvasSelY = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
          If (_CanvasClamp)
            If (_CanvasSelX < 0)
              _CanvasSelX = 0
            ElseIf (_CanvasSelX >= GadgetWidth(EventGadget()))
              _CanvasSelX = GadgetWidth(EventGadget()) - 1
            EndIf
            If (_CanvasSelY < 0)
              _CanvasSelY = 0
            ElseIf (_CanvasSelY >= GadgetHeight(EventGadget()))
              _CanvasSelY = GadgetHeight(EventGadget()) - 1
            EndIf
          EndIf
          If (Not _CanvasDragging)
            If ((Abs(_CanvasSelX - _CanvasAnchorX) + Abs(_CanvasSelY - _CanvasAnchorY)) >= _CanvasDragThreshold)
              _CanvasClickWasDrag = #True
              _CanvasDragging = #True
              _CanvasWindow = GetWindowFromGadget(_CanvasDragGadget)
              PostEvent(#PB_Event_Gadget, _CanvasWindow, EventGadget(), #CanvasDrag_Start)
            EndIf
          EndIf
          If (_CanvasDragging)
            If (_CanvasSelX > _CanvasAnchorX)
              _CanvasLeftX  = _CanvasAnchorX
              _CanvasRightX = _CanvasSelX
              _CanvasDirX   =  1
            Else
              _CanvasLeftX  = _CanvasSelX
              _CanvasRightX = _CanvasAnchorX
              _CanvasDirX   = -1
            EndIf
            If (_CanvasSelY > _CanvasAnchorY)
              _CanvasTopY    = _CanvasAnchorY
              _CanvasBottomY = _CanvasSelY
              _CanvasDirY    =  1
            Else
              _CanvasTopY    = _CanvasSelY
              _CanvasBottomY = _CanvasAnchorY
              _CanvasDirY    = -1
            EndIf
            _CanvasDragX      = _CanvasSelX    - _CanvasAnchorX
            _CanvasDragY      = _CanvasSelY    - _CanvasAnchorY
            _CanvasDragWidth  = _CanvasRightX  - _CanvasLeftX
            _CanvasDragHeight = _CanvasBottomY - _CanvasTopY
            PostEvent(#PB_Event_Gadget, _CanvasWindow, EventGadget(), #CanvasDrag_Change)
          EndIf
        EndIf
    EndSelect
  EndIf
EndProcedure



;-
;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Global CameraX.i
Global CameraY.i

Procedure DemoRedraw()
  Protected Selecting.i = Bool(IsCanvasDragging() And (CanvasDragButton() <> #PB_Canvas_MiddleButton))
  
  If StartVectorDrawing(CanvasVectorOutput(0))
    
    ; Clear background
    If (Selecting And CanvasDragContainsPoint(CameraX + VectorOutputWidth()/2, CameraY + VectorOutputHeight()/2))
      VectorSourceColor($FFC0FFFF)
    Else
      VectorSourceColor($FFFFFFFF)
    EndIf
    FillVectorOutput()
    
    ; Draw dot to select
    VectorSourceColor($FF000000)
    AddPathCircle(CameraX + 320, CameraY + 240,1)
    FillPath()
    
    ; Draw box to select
    VectorSourceColor($FFc0c0c0)
    If (Selecting)
      If (CanvasDragDirX() > 0) And CanvasDragContainsBox(CameraX + 100, CameraY + 100, 50, 50)
        VectorSourceColor($FFff0000)
      ElseIf (CanvasDragDirX() < 0) And CanvasDragIntersectsBox(CameraX + 100, CameraY + 100, 50, 50)
        VectorSourceColor($FF00ff00)
      EndIf
    EndIf
    AddPathBox(CameraX + 100, CameraY + 100, 50, 50)
    FillPath()
    
    ; Draw text instructions
    VectorSourceColor($FFf0d0d0)
    VectorFont(FontID(0))
    MovePathCursor(CameraX + 200, CameraY + 100)
    DrawVectorText("Drag rightward for contain select")
    MovePathCursor(CameraX + 200, CameraY + 100 + VectorTextHeight(" "))
    DrawVectorText("Drag leftward for intersect select")
    MovePathCursor(CameraX + 200, CameraY + 100 + 2*VectorTextHeight(" "))
    DrawVectorText("Pan with the Middle mouse button")
    
    ; Draw selection box
    If (Selecting)
      If (CanvasDragDirX() > 0)
        Color = #Blue
      Else
        Color = #Green
      EndIf
      Color | $FF000000
      AddPathBox(CanvasDragLeftX(), CanvasDragTopY(), CanvasDragWidth() + 1, CanvasDragHeight() + 1)
      VectorSourceColor(Color)
      If (CanvasDragDirX() > 0)
        StrokePath(1)
      Else
        DashPath(1, 10)
      EndIf
      
    EndIf
    
    StopVectorDrawing()
  EndIf
EndProcedure

Procedure DemoCallback()
  If (EventType() = #CanvasDrag_Start)
    Debug "Start dragging"
    CanvasDragLockXY(CameraX, CameraY)
  ElseIf (EventType() = #CanvasDrag_Stop)
    Debug "Stop"
  ElseIf (EventType() = #CanvasDrag_Change)
    ;Debug "Change"
    If (CanvasDragButton() = #PB_Canvas_MiddleButton)
      CameraX = CanvasDragScaleX()
      CameraY = CanvasDragScaleY()
    EndIf
  ElseIf ((EventType() = #PB_EventType_LeftClick) Or
      (EventType() = #PB_EventType_RightClick))
    If (Not CanvasClickWasDragStop())
      Debug "Click without drag"
    EndIf
  EndIf
  DemoRedraw()
EndProcedure

Procedure DemoCancel()
  CancelCanvasDrag()
  DemoRedraw()
EndProcedure

#Win = 0
LoadFont(0, "Arial", 14)
OpenWindow(#Win, 0, 0, 640, 480, "CanvasDrag", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
CanvasGadget(0, 0, 0, 640, 480)
TrackCanvasDrag(0)
;SetCanvasDragThreshold(40)
;SetCanvasDragClamp(#True)
BindGadgetEvent(0, @DemoCallback())

AddKeyboardShortcut(#Win, #PB_Shortcut_Escape, 1)
BindEvent(#PB_Event_Menu, @DemoCancel(), #Win, 1)
DemoRedraw()

Repeat
  ;
Until (WaitWindowEvent() = #PB_Event_CloseWindow)


CompilerEndIf
CompilerEndIf
;-