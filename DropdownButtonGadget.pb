; +----------------------+
; | DropdownButtonGadget |
; +----------------------+
; | 2014.09.18 . Creation (PureBasic 5.30)
; | 2015.05.10 . Use DrawText API on Windows for better text (PB 5.42)
; | 2017.02.08 . Made multiple-include safe

CompilerIf (Not Defined(__DropdownButtonGadget_Included, #PB_Constant))
#__DropdownButtonGadget_Included = #True


;-
;- Compatibility - PRIVATE

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

CompilerIf (#PB_Compiler_Version < 530)
  Macro ClipOutput(x, y, Width, Height)
    ;
  EndMacro
  Macro UnclipOutput()
    ;
  EndMacro
CompilerEndIf

;-
;- Constants - PRIVATE

#_DropdownButton_None = 0
#_DropdownButton_Item = 1
#_DropdownButton_Drop = 2

#_DropdownButton_Dropping = $010000

;-
;- Structures - PRIVATE

Structure _DROPDOWNBUTTONITEM
  Text.s
  MenuID.i
  ImageID.i
EndStructure

Structure _DROPDOWNBUTTON
  Canvas.i
  Flags.i
  Window.i
  Popup.i
  ;
  ArrowImg.i
  ;
  Width.i
  Height.i
  DropWidthReal.i
  DropWidth.i
  ;
  FontID.i
  ColorFont.i
  ;
  ColorIdleBorder.i
  ColorIdleTop.i
  ColorIdleBottom.i
  ;
  ColorHoverBorder.i
  ColorHoverTop.i
  ColorHoverBottom.i
  ;
  ColorPressBorder.i
  ColorPressTop.i
  ColorPressBottom.i
  ;
  HoverItem.i
  PressItem.i
  ;
  List Item._DROPDOWNBUTTONITEM()
EndStructure

;-
;- Globals - PRIVATE

Global _DropdownButtonLastPopup.i = #Null

;-
;- Macros - PUBLIC

Macro AddDropdownButtonGadgetBar(DBG)
  AddDropdownButtonGadgetItem((DBG), "-")
EndMacro

;-
;- Procedures - PRIVATE

Procedure.i _DropdownButtonArrowImage(Color.i)
  Protected Size.i = 5
  Protected Img.i = CreateImage(#PB_Any, Size*2-1, Size, 32, Color)
  If (StartDrawing(ImageOutput(Img)))
    DrawingMode(#PB_2DDrawing_AllChannels)
    Color & $00FFFFFF
    Box(0, 0, OutputWidth(), OutputHeight(), Color)
    Protected i.i
    For i = 0 To Size - 1
      Plot(Size - 1 - i, Size - i - 1, Color | $4D000000)
      Plot(Size - 1 + i, Size - i - 1, Color | $4D000000)
      If (i < Size - 1)
        Box(Size - 1 - i, 0, 1, Size - 1 - i, Color | $FF000000)
        Box(Size - 1 + i, 0, 1, Size - 1 - i, Color | $FF000000)
      EndIf
    Next i
    StopDrawing()
  EndIf
  ProcedureReturn (Img)
EndProcedure

Procedure _DropdownButtonGadgetRedraw(*DBG._DROPDOWNBUTTON)
  If (*DBG And *DBG\Canvas And IsGadget(*DBG\Canvas))
    With *DBG
      If (Not (*DBG\Flags & #_DropdownButton_Dropping))
        Protected DrawingID.i = StartDrawing(CanvasOutput(\Canvas))
        If (DrawingID)
          Protected TopColor.i, BottomColor.i, BorderColor.i
          ;
          If ((\PressItem = \HoverItem) And (\PressItem = #_DropdownButton_Item))
            TopColor    = \ColorPressTop
            BottomColor = \ColorPressBottom
            BorderColor = \ColorPressBorder
          ElseIf (\HoverItem)
            TopColor    = \ColorHoverTop
            BottomColor = \ColorHoverBottom
            BorderColor = \ColorHoverBorder
          Else
            TopColor    = \ColorIdleTop
            BottomColor = \ColorIdleBottom
            BorderColor = \ColorIdleBorder
          EndIf
          DrawingMode(#PB_2DDrawing_Gradient)
          BackColor(TopColor)
          FrontColor(BottomColor)
          LinearGradient(0, 0, 0, \Height)
          Box(0, 0, \Width - \DropWidthReal, \Height)
          DrawingMode(#PB_2DDrawing_Default)
          Box(0, 0, 1, \Height, BorderColor)
          Box(0, 0, \Width - \DropWidthReal, 1, BorderColor)
          Box(0, \Height - 1, \Width - \DropWidthReal, 1, BorderColor)
          ;
          If ((\PressItem = \HoverItem) And (\PressItem))
            TopColor    = \ColorPressTop
            BottomColor = \ColorPressBottom
            BorderColor = \ColorPressBorder
          ElseIf (\HoverItem)
            TopColor    = \ColorHoverTop
            BottomColor = \ColorHoverBottom
            BorderColor = \ColorHoverBorder
          Else
            TopColor    = \ColorIdleTop
            BottomColor = \ColorIdleBottom
            BorderColor = \ColorIdleBorder
          EndIf
          DrawingMode(#PB_2DDrawing_Gradient)
          BackColor(TopColor)
          FrontColor(BottomColor)
          LinearGradient(0, 0, 0, \Height)
          Box(\Width - \DropWidthReal, 0, \DropWidthReal, \Height)
          DrawingMode(#PB_2DDrawing_Default)
          Box(\Width - 1, 0, 1, \Height, BorderColor)
          Box(\Width - \DropWidthReal - 1, 0, 1, \Height, BorderColor)
          Box(\Width - \DropWidthReal - 1, 0, \DropWidthReal, 1, BorderColor)
          Box(\Width - \DropWidthReal - 1, \Height - 1, \DropWidthReal, 1, BorderColor)
          ;
          If (ListSize(\Item()))
            FirstElement(\Item())
            DrawingFont(\FontID)
            DrawingMode(#PB_2DDrawing_Transparent)
            ClipOutput(1, 1, \Width - \DropWidthReal - 2, \Height - 2)
            CompilerIf ((#PB_Compiler_OS = #PB_OS_Windows) And (#True))
              SelectObject_(DrawingID, \FontID)
              SetTextColor_(DrawingID, \ColorFont)
              SetBkMode_(DrawingID, #TRANSPARENT)
              Protected Rect.RECT
              Rect\left   = 1
              Rect\top    = 1
              Rect\right  = \Width - \DropWidthReal - 1
              Rect\bottom = \Height - 1
              DrawText_(DrawingID, @\Item()\Text, -1, @Rect,
                  #DT_SINGLELINE | #DT_NOPREFIX | #DT_CENTER | #DT_VCENTER)
            CompilerElse
              DrawText((\Width - \DropWidthReal)/2 + 1 - TextWidth(\Item()\Text)/2, \Height/2 - TextHeight(\Item()\Text)/2, \Item()\Text, \ColorFont)
            CompilerEndIf
            UnclipOutput()
            ;
            If (ListSize(\Item()) >= 2)
              DrawingMode(#PB_2DDrawing_AlphaBlend)
              DrawImage(ImageID(\ArrowImg), \Width - \DropWidthReal/2 - ImageWidth(\ArrowImg)/2 - 1, \Height/2 - ImageHeight(\ArrowImg)/2)
            EndIf
          EndIf
          ;
          StopDrawing()
        EndIf
      EndIf
    EndWith
  EndIf
EndProcedure

Procedure _DropdownButtonGadgetUpdate(*DBG._DROPDOWNBUTTON, Redraw.i = #False)
  If (*DBG And *DBG\Canvas And IsGadget(*DBG\Canvas))
    With *DBG
      \Width  = GadgetWidth(\Canvas)
      \Height = GadgetHeight(\Canvas)
      If (ListSize(\Item()) >= 2)
        \DropWidthReal = \DropWidth
      Else
        \DropWidthReal = 0
      EndIf
      If (Redraw)
        _DropdownButtonGadgetRedraw(*DBG)
      EndIf
    EndWith
  EndIf
EndProcedure

Procedure _DropdownButtonCallback()
  Protected *DBG._DROPDOWNBUTTON
  *DBG = GetGadgetData(EventGadget())
  If (*DBG And *DBG\Canvas And IsGadget(*DBG\Canvas))
    With *DBG
      Protected PreHover.i = \HoverItem
      Protected PrePress.i = \PressItem
      
      Select (EventType())
      
        Case #PB_EventType_MouseEnter, #PB_EventType_MouseMove, #PB_EventType_LeftButtonDown
          Protected x.i = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseX)
          Protected y.i = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseY)
          If ((x >= 0) And (x < \Width) And (y >= 0) And (y < \Height))
            If (x < \Width - \DropWidthReal)
              \HoverItem = #_DropdownButton_Item
            Else
              \HoverItem = #_DropdownButton_Drop
            EndIf
          Else
            \HoverItem = #_DropdownButton_None
          EndIf
          If (EventType() = #PB_EventType_LeftButtonDown)
            ;If (ListSize(\Item()))
              \PressItem = \HoverItem
            ;EndIf
          EndIf
        Case #PB_EventType_MouseLeave
          \HoverItem = #_DropdownButton_None
        
        Case #PB_EventType_LeftButtonUp
          If (\PressItem = \HoverItem)
            Select (\PressItem)
              Case #_DropdownButton_Item
                If (ListSize(\Item()))
                  _DropdownButtonLastPopup = *DBG
                  FirstElement(\Item())
                  PostEvent(#PB_Event_Menu, \Window, \Item()\MenuID)
                EndIf
                \PressItem = #_DropdownButton_None
              Case #_DropdownButton_Drop
                If (ListSize(\Item()))
                  If (Not \Popup)
                    \Popup = CreatePopupMenu(#PB_Any)
                    If (\Popup)
                      ForEach (\Item())
                        If (\Item()\Text = "-")
                          MenuBar()
                        Else
                          MenuItem(\Item()\MenuID, \Item()\Text, \Item()\ImageID)
                        EndIf
                      Next
                    EndIf
                  EndIf
                  If (\Popup)
                    \PressItem = #_DropdownButton_None
                    _DropdownButtonGadgetRedraw(*DBG)
                    *DBG\Flags | #_DropdownButton_Dropping
                    ;Debug "Pre-Drop"
                    _DropdownButtonLastPopup = *DBG
                    DisplayPopupMenu(\Popup, WindowID(\Window), GadgetX(\Canvas, #PB_Gadget_ScreenCoordinate), GadgetY(\Canvas, #PB_Gadget_ScreenCoordinate) + \Height)
                    ;Debug "Post-Drop"
                    *DBG\Flags & ~#_DropdownButton_Dropping
                  Else
                    _DropdownButtonLastPopup = #Null
                  EndIf
                EndIf
            EndSelect
          Else
            \PressItem = #_DropdownButton_None
          EndIf
          
          
      EndSelect
      If ((\HoverItem <> PreHover) Or (\PressItem <> PrePress))
        _DropdownButtonGadgetRedraw(*DBG)
      EndIf
    EndWith
  EndIf
EndProcedure

;-
;- Procedures - PUBLIC

Procedure.i EventDropdownButton()
  ProcedureReturn (_DropdownButtonLastPopup)
EndProcedure

Procedure.i FreeDropdownButtonGadget(*DBG._DROPDOWNBUTTON)
  If (*DBG)
    If (*DBG\Canvas And IsGadget(*DBG\Canvas))
      SetGadgetData(*DBG\Canvas, #Null)
      UnbindGadgetEvent(*DBG\Canvas, @_DropdownButtonCallback())
      FreeGadget(*DBG\Canvas)
    EndIf
    If (*DBG\Popup)
      FreeMenu(*DBG\Popup)
    EndIf
    ClearList(*DBG\Item())
    ClearStructure(*DBG, _DROPDOWNBUTTON)
    FreeMemory(*DBG)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i DropdownButtonGadget(x.i, y.i, Width.i = 85, Height.i = 25, Window.i = 0)
  Protected *DBG._DROPDOWNBUTTON = #Null
  If (IsWindow(Window))
    Protected Canvas.i = CanvasGadget(#PB_Any, x, y, Width, Height)
    If (Canvas)
      *DBG = AllocateMemory(SizeOf(_DROPDOWNBUTTON))
      If (*DBG)
        InitializeStructure(*DBG, _DROPDOWNBUTTON)
        With *DBG
          \Canvas    = Canvas
          \ColorFont = RGB(0, 0, 0)
          \DropWidth = 18
          \Window    = Window
          ;
          CompilerSelect (#PB_Compiler_OS)
            CompilerCase (#PB_OS_Windows)
              \FontID = GetGadgetFont(#PB_Default)
            CompilerDefault
              Protected Temp.i = TextGadget(#PB_Any, 0, 0, 25, 25, " ")
              If (Temp)
                \FontID = GetGadgetFont(Temp)
                FreeGadget(Temp)
              EndIf
          CompilerEndSelect
          ;
          ; Default colors (based on Windows 7, Internet Explorer)
          \ColorIdleBorder  = RGB(172, 172, 172)
          \ColorIdleTop     = RGB(240, 240, 240)
          \ColorIdleBottom  = RGB(229, 229, 229)
          \ColorHoverBorder = RGB(126, 180, 234)
          \ColorHoverTop    = RGB(236, 244, 252)
          \ColorHoverBottom = RGB(220, 236, 252)
          \ColorPressBorder = RGB(86, 157, 229)
          \ColorPressTop    = RGB(218, 236, 252)
          \ColorPressBottom = RGB(196, 224, 252)
          ;
          \ArrowImg = _DropdownButtonArrowImage(\ColorFont)
        EndWith
        ;
        SetGadgetData(Canvas, *DBG)
        _DropdownButtonGadgetUpdate(*DBG, #True)
        BindGadgetEvent(Canvas, @_DropdownButtonCallback())
      Else
        FreeGadget(Canvas)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*DBG)
EndProcedure

Procedure.i AddDropdownButtonGadgetItem(*DBG._DROPDOWNBUTTON, Text.s, ID.i = 0, ImageID.i = #Null)
  Protected Result.i = -1
  If (*DBG And *DBG\Canvas And IsGadget(*DBG\Canvas))
    With *DBG
      LastElement(\Item())
      AddElement(\Item())
      \Item()\MenuID  = ID
      \Item()\Text    = Text
      \Item()\ImageID = ImageID
      _DropdownButtonGadgetUpdate(*DBG, #True)
      Result = ListSize(\Item()) - 1
    EndWith
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ClearDropdownButtonGadgetItems(*DBG._DROPDOWNBUTTON)
  Protected Result.i = -1
  If (*DBG And *DBG\Canvas And IsGadget(*DBG\Canvas))
    With *DBG
      ClearList(\Item())
      _DropdownButtonGadgetUpdate(*DBG, #True)
      Result = 0
    EndWith
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- Demo Program - PUBLIC

CompilerIf (#PB_Compiler_IsMainFile)

DisableExplicit
OpenWindow(0, 0, 0, 325, 65, "DropdownButtonGadget Demo", #PB_Window_ScreenCentered|#PB_Window_SystemMenu)
SetWindowColor(0, $FFFFFF)

Dim DBG.i(2)
*DBG = DropdownButtonGadget(20, 20)
  AddDropdownButtonGadgetItem(*DBG, "Open", 1)
  DBG(0) = *DBG
*DBG = DropdownButtonGadget(120, 20)
  AddDropdownButtonGadgetItem(*DBG, "Open", 1)
  AddDropdownButtonGadgetItem(*DBG, "Save", 2)
  AddDropdownButtonGadgetBar(*DBG)
  AddDropdownButtonGadgetItem(*DBG, "Clear Gadget", 5)
  DBG(1) = *DBG
*DBG = DropdownButtonGadget(220, 20)
  AddDropdownButtonGadgetItem(*DBG, "Open", 1)
  AddDropdownButtonGadgetItem(*DBG, "Save", 2)
  AddDropdownButtonGadgetItem(*DBG, "Save as", 3)
  AddDropdownButtonGadgetBar(*DBG)
  AddDropdownButtonGadgetItem(*DBG, "Quit Demo", 4)
  DBG(2) = *DBG
  ;FreeDropdownButtonGadget(*DBG)

Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_Menu)
    Select (EventMenu())
      Case 1
        OpenFileRequester("Open", GetCurrentDirectory(), "All Files|*.*", 0)
      Case 2
        MessageRequester("Saved", "You clicked Save." + #LF$ + #LF$ + "DBG: $" + Hex(EventDropdownButton(), #PB_Long))
      Case 3
        SaveFileRequester("Save As", GetCurrentDirectory(), "All Files|*.*", 0)
      Case 4
        Event = #PB_Event_CloseWindow
      Case 5
        ClearDropdownButtonGadgetItems(EventDropdownButton())
    EndSelect
  EndIf
Until Event = #PB_Event_CloseWindow

FreeDropdownButtonGadget(DBG(0))
FreeDropdownButtonGadget(DBG(1))
FreeDropdownButtonGadget(DBG(2))

CompilerEndIf

CompilerEndIf

;-