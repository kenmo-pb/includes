; +------------+
; | CanvasDrag |
; +------------+
; | 2019-04-25 : Creation

; TODO
; post custom events - start drag, stop drag, drag area change
; release on MouseLeave ? depends on OS ?
; bound within canvas ? optional ?
; configurable drag start threshold

;-
CompilerIf (Not Defined(_CanvasDrag_Included, #PB_Constant))
#_CanvasDrag_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Globals

Global _CanvasDown.i = #False
Global _CanvasDragging.i = #False
Global _CanvasButton.i
Global _CanvasDragThreshold.i = 3
Global _CanvasAnchorX.i
Global _CanvasAnchorY.i
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

;-
;- Procedures

Procedure.i IsCanvasDragging()
  ProcedureReturn (_CanvasDragging)
EndProcedure

Procedure.i CanvasDragButton()
  ProcedureReturn (_CanvasButton)
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
  ProcedureReturn (_CanvasDragX)
EndProcedure
Procedure.i CanvasDragDeltaY()
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

Declare _CanvasDragCallback()
Procedure.i TrackCanvasDrag(Gadget.i)
  BindGadgetEvent(Gadget, @_CanvasDragCallback())
EndProcedure

;-

Procedure _CanvasDragCallback()
  Select (EventType())
    Case #PB_EventType_LeftButtonDown, #PB_EventType_RightButtonDown, #PB_EventType_MiddleButtonDown
      If (Not _CanvasDown)
        _CanvasDown = #True
        _CanvasAnchorX = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        _CanvasAnchorY = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
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
          _CanvasDragging = #False
          ;Debug "Stop"
        EndIf
      EndIf
    Case #PB_EventType_MouseLeave
      ;
    Case #PB_EventType_MouseMove
      If (_CanvasDown)
        _CanvasSelX = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        _CanvasSelY = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        If (Not _CanvasDragging)
          If ((Abs(_CanvasSelX - _CanvasAnchorX) + Abs(_CanvasSelY - _CanvasAnchorY)) >= _CanvasDragThreshold)
            _CanvasDragging = #True
            ;Debug "Start Dragging"
          EndIf
        EndIf
        If (_CanvasDragging)
          _CanvasSelX = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
          _CanvasSelY = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
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
          _CanvasDragX     = _CanvasSelX - _CanvasAnchorX
          _CanvasDragY     = _CanvasSelY - _CanvasAnchorY
          _CanvasDragWidth  = _CanvasRightX  - _CanvasLeftX
          _CanvasDragHeight = _CanvasBottomY - _CanvasTopY
        EndIf
      EndIf
  EndSelect
EndProcedure



;-
;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Procedure DemoCallback()
  If StartVectorDrawing(CanvasVectorOutput(EventGadget()))
    If (CanvasDragContainsPoint(VectorOutputWidth()/2, VectorOutputHeight()/2))
      VectorSourceColor($FFC0FFFF)
    Else
      VectorSourceColor($FFFFFFFF)
    EndIf
    FillVectorOutput()
    
    VectorSourceColor($FF000000)
    AddPathCircle(320,240,1)
    FillPath()
    
    VectorSourceColor($FFc0c0c0)
    If (IsCanvasDragging())
      If (CanvasDragDirX() > 0) And CanvasDragContainsBox(100, 100, 50, 50)
        VectorSourceColor($FFff0000)
      ElseIf (CanvasDragDirX() < 0) And CanvasDragIntersectsBox(100, 100, 50, 50)
        VectorSourceColor($FF00ff00)
      EndIf
    EndIf
    AddPathBox(100, 100, 50, 50)
    FillPath()
    
    If (IsCanvasDragging())
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

OpenWindow(0, 0, 0, 640, 480, "CanvasDrag", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
CanvasGadget(0, 0, 0, 640, 480)
TrackCanvasDrag(0)
BindGadgetEvent(0, @DemoCallback())

Repeat
  ;
Until (WaitWindowEvent() = #PB_Event_CloseWindow)

CompilerEndIf
CompilerEndIf
;-