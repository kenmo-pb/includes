; +----------------+
; | PropertyGadget |
; +----------------+
; | 2017.02.08 . Creation (PureBasic 5.51)
; |     .05.23 . Cleanup

CompilerIf (Not Defined(__PropertyGadget_Included, #PB_Constant))
#__PropertyGadget_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Constants (Public)

#PropertyGadget_Version = 20170523

#Property_Last = -1

Enumeration ; PropertyGadget Flags
  #PropertyGadget_OneOpen   = $0001
  #PropertyGadget_Border    = $0002
  #PropertyGadget_Underline = $0004
EndEnumeration

Enumeration ; PropertyGadget Attributes
  #PropertyGadget_MinLabelWidth    = $0100
  #PropertyGadget_MinFieldWidth    = $0200
  #PropertyGadget_ExpandedImageID  = $0300
  #PropertyGadget_CollapsedImageID = $0400
EndEnumeration

Enumeration ; ColorProperty Flags
  #ColorProperty_CSSFormat = $0001
  #ColorProperty_CFormat   = $0002
  #ColorProperty_PBFormat  = $0004
EndEnumeration

Enumeration ; PropertyChild Gadget IDs
  #PropertyChild_Main
  #PropertyChild_Label
  #PropertyChild_Function
  #PropertyChild_Image
EndEnumeration


;-
;- Constants (Private)

#__PG_MaxSubgadgets = 4

#__PG_Windows = Bool(#PB_Compiler_OS = #PB_OS_Windows)

CompilerIf (Not Defined(__PG_GetBuildWindow, #PB_Constant))
  #__PG_GetBuildWindow = (#True)
CompilerEndIf

CompilerIf (Not Defined(__PG_Debug, #PB_Constant))
  #__PG_Debug = Bool(#PB_Compiler_Debugger And (#True))
CompilerEndIf

Enumeration ; PropertyGadgetItem Type Constants
  #__PG_Header
  ;
  #__PG_Browse
  #__PG_Button
  #__PG_Checkbox
  #__PG_CheckboxLabel
  #__PG_Color
  #__PG_ComboBox
  #__PG_Label
  #__PG_Password
  #__PG_Percent
  #__PG_Progress
  #__PG_Shortcut
  #__PG_Spacer
  #__PG_Spin
  #__PG_String
  #__PG_Trackbar
  ;
  #__PG_TypeCount
  #__PG_None = -1
EndEnumeration







;-
;- Structures (Private)

Structure __PropertyGadgetItem
  Type.i
  Name.s
  ID.s
  SValue.s
  IValue.i
  ExData.i
  Image.i
  ;
  Gadget.i[#__PG_MaxSubgadgets]
EndStructure

Structure __PropertyGadget
  Flags.i
  ;
  Window.i
  ;
  Scroll.i
  Dummy.i
  LockCount.i
  ;
  InnerWidth.i    ; Inner W/H of ScrollAreaGadget
  InnerHeight.i
  VisWidth.i      ; Sum W/H of all visible items, including headers, excluding closed sections
  VisHeight.i
  LabelWidth.i    ; Width of label (left) column
  HasHeaders.i    ; Has any headers, 0 or 1 (determines horizontal spacing)
  ;
  ExpImgID.i
  ColImgID.i
  MinLabelW.i
  MinFieldW.i
  ;
  List PGI.__PropertyGadgetItem()
EndStructure






;-
;- Globals (Private)

Global __PG_Initialized.i = #False

; These apply to all PropertyGadgets in the program!
Global __PG_Margin.i
Global __PG_Padding.i
Global __PG_ToggleSize.i
Global __PG_LabelOffset.i
Global __PG_ImageExpanded.i
Global __PG_ImageCollapsed.i
Global __PG_WinColor.i
Global __PG_TextColor.i
Global __PG_MinWLeft.i
Global __PG_MinWRight.i
Global __PG_HeaderFont.i
Global Dim __PG_ItemHeight.i(#__PG_TypeCount - 1)





;-
;- Macros (Private)

Macro __PG_ReqWidth(_Gadget)
  GadgetWidth((_Gadget), #PB_Gadget_RequiredSize)
EndMacro

Macro __PG_ReqHeight(_Gadget)
  GadgetHeight((_Gadget), #PB_Gadget_RequiredSize)
EndMacro

Macro __PG_Cond(_Condition, _Value)
  (Bool(_Condition) * (_Value))
EndMacro

Macro __PG_Post(_PG, _Index, _Type = #PB_EventType_Change)
  PostEvent(#PB_Event_Gadget, _PG\Window, _PG\Scroll, (_Type), (_Index))
EndMacro

Macro __PG_Select(_Gadget)
  CompilerIf (#__PG_Windows)
    PostMessage_(GadgetID(_Gadget), #EM_SETSEL, 0, -1)
  CompilerEndIf
  SetActiveGadget(_Gadget)
EndMacro

Macro __PG_RepCallback(_Gadget, _Callback)
  CompilerIf (#__PG_Windows)
    SetWindowLongPtr_(GadgetID(_Gadget), #GWLP_USERDATA, GetWindowLongPtr_(GadgetID(_Gadget), #GWLP_WNDPROC))
    SetWindowLongPtr_(GadgetID(_Gadget), #GWLP_WNDPROC, (_Callback))
  CompilerEndIf
EndMacro






;-
;- Macros (Public)

Macro EventProperty()
  EventData()
EndMacro

Macro GetPropertyChildByID(Gadget, ID, SubIndex = 0)
  GetPropertyChild((Gadget), -1, (ID), (SubIndex))
EndMacro

Macro SetPropertyExDataByID(Gadget, ID, ExData)
  SetPropertyExData((Gadget), -1, (ExData), (ID))
EndMacro

Macro GetPropertyStateByID(Gadget, ID)
  GetPropertyState((Gadget), -1, (ID))
EndMacro

Macro SetPropertyStateByID(Gadget, ID, State)
  SetPropertyState((Gadget), -1, (State), (ID))
EndMacro

Macro GetPropertyTextByID(Gadget, ID)
  GetPropertyText((Gadget), -1, (ID))
EndMacro

Macro SetPropertyTextByID(Gadget, ID, Text)
  SetPropertyText((Gadget), -1, (Text), (ID))
EndMacro




;-
;- Prototypes (Private)

Prototype.i __PG_BrowseProto(Gadget.i, ChildGadget.i, ID.i, Index.s)


;-
;- Imports (Private)

CompilerIf (#__PG_GetBuildWindow) ; Need this to get a PB Window number from a WindowID

CompilerIf (#__PG_Windows)
  Import ""
    PB_Object_EnumerateStart(PB_Objects)
    PB_Object_EnumerateNext(PB_Objects, *ID.Integer)
    PB_Object_EnumerateAbort(PB_Objects)
    PB_Window_Objects.i
  EndImport
CompilerElse
  ImportC ""
    PB_Object_EnumerateStart(PB_Objects)
    PB_Object_EnumerateNext(PB_Objects, *ID.Integer)
    PB_Object_EnumerateAbort(PB_Objects)
    PB_Window_Objects.i
  EndImport
CompilerEndIf


ProcedureDLL __PG_EnumerateStartWindow() ; Returns PB window object
  PB_Object_EnumerateStart(PB_Window_Objects)
  ProcedureReturn (PB_Window_Objects)
EndProcedure

ProcedureDLL __PG_EnumerateNextWindow(*Window.Integer) ; Returns next enumerate PB object
  Protected PBObject.i
  Protected Window.i = -1
  PBObject = PB_Object_EnumerateNext(PB_Window_Objects, @Window)
  If (IsWindow(Window))
    PokeI(*Window, PeekI(@Window))
  EndIf
  ProcedureReturn (PBObject)
EndProcedure

ProcedureDLL __PG_EnumerateAbortWindow() ; Abort enumerate window
  ProcedureReturn (PB_Object_EnumerateAbort(PB_Window_Objects))
EndProcedure

Procedure.i __PG_GetBuildWindow()
  Protected Result.i = -1
  Protected BuildID.i = UseGadgetList(0)
  If (__PG_EnumerateStartWindow())
    Protected Window.i
    While (__PG_EnumerateNextWindow(@Window))
      If (WindowID(Window) = BuildID)
        Result = Window
        __PG_EnumerateAbortWindow()
        Break
      EndIf
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf





;-
;- Procedures (Private)

Declare LockPropertyGadget(Gadget.i, State.i)

CompilerIf (#__PG_Windows)

CompilerIf (Not Defined(COMBOBOXINFO, #PB_Structure))
Structure COMBOBOXINFO Align #PB_Structure_AlignC
  cbSize.l
  rcItem.RECT
  rcButton.RECT
  stateButton.l
  hwndCombo.i
  hwndItem.i
  hwndList.i
EndStructure
CompilerEndIf

Procedure.i __PG_MaxI(a.i, b.i)
  If (a > b)
    ProcedureReturn (a)
  EndIf
  ProcedureReturn (b)
EndProcedure

Procedure.i __PG_LoadBoldFont()
  Protected NCM.NONCLIENTMETRICS
  NCM\cbSize = SizeOf(NCM)
  If (SystemParametersInfo_(#SPI_GETNONCLIENTMETRICS, SizeOf(NCM), @NCM, #Null))
    ProcedureReturn (LoadFont(#PB_Any, PeekS(@NCM\lfMenuFont\lfFaceName[0]), NCM\lfMenuFont\lfHeight, #PB_Font_Bold | #PB_Font_HighQuality))
  EndIf
EndProcedure

Procedure.i __PG_StringGadgetCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
  Protected StartPos.i, EndPos.i, *Buffer
  Protected Length.i, *Char.CHARACTER, Spaced.i
  
  If ((uMsg = #WM_CHAR) And (wParam = $7F))
    SendMessage_(hWnd, #EM_GETSEL, @StartPos, @EndPos)
    If (EndPos > StartPos)
      SendMessage_(hWnd, #EM_REPLACESEL, #True, @"")
    ElseIf (StartPos > 0)
      Length = 2 * GetWindowTextLength_(hWnd) + 2
      *Buffer = AllocateMemory(Length)
      If (*Buffer)
        GetWindowText_(hWnd, *Buffer, Length)
        *Char = *Buffer + SizeOf(CHARACTER) * (StartPos - 1)
        While (*Char >= *Buffer)
          Select (*Char\c)
            Case ' ', #TAB, #CR, #LF, #NUL
              If (Spaced)
                Break
              EndIf
            Default
              Spaced = #True
          EndSelect
          *Char - SizeOf(CHARACTER)
          StartPos - 1
        Wend
        If (Not Spaced)
          StartPos = 0
        EndIf
        If (EndPos > StartPos)
          SendMessage_(hWnd, #EM_SETSEL, StartPos, EndPos)
          SendMessage_(hWnd, #EM_REPLACESEL, #True, @"")
        EndIf
        FreeMemory(*Buffer)
      EndIf
    EndIf
    ProcedureReturn (#True)
  Else
    ProcedureReturn (CallWindowProc_(GetWindowLongPtr_(hWnd, #GWL_USERDATA), hWnd, uMsg, wParam, lParam))
  EndIf
EndProcedure
CompilerEndIf

Procedure __ResizePropertyGadget(*PG.__PropertyGadget)
  If (*PG)
    *PG\InnerWidth  = GetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_InnerWidth)
    *PG\InnerHeight = GetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_InnerHeight)
    SetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_InnerWidth,  *PG\VisWidth)
    SetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_InnerHeight, *PG\VisHeight)
    Protected x.i = __PG_Margin
    Protected y.i = __PG_Margin
    Protected i.i
    Protected ToggleOffset.i = 0
    Protected ImgOffset.i = 0
    If (*PG\HasHeaders)
      ToggleOffset = __PG_ToggleSize
    EndIf
    Protected FlexWidth.i = *PG\VisWidth - (x + ToggleOffset + *PG\LabelWidth)
    Protected Collapsed.i = #False
    ForEach (*PG\PGI())
      With *PG\PGI()
        If (\Type = #__PG_Header)
          Collapsed = \IValue
          If (ListIndex(*PG\PGI()) > 0)
            y + __PG_Margin
          EndIf
        EndIf
        If ((Not Collapsed) Or (\Type = #__PG_Header))
          If (\Image <> -1)
            ImgOffset = __PG_ToggleSize
          Else
            ImgOffset = 0
          EndIf
          Select (\Type)
            Case #__PG_Header
              If (Collapsed)
                If (*PG\ColImgID)
                  SetGadgetState(\Gadget[#PropertyChild_Function], *PG\ColImgID)
                Else
                  SetGadgetState(\Gadget[#PropertyChild_Function], ImageID(__PG_ImageCollapsed))
                EndIf
              Else
                If (*PG\ExpImgID)
                  SetGadgetState(\Gadget[#PropertyChild_Function], *PG\ExpImgID)
                Else
                  SetGadgetState(\Gadget[#PropertyChild_Function], ImageID(__PG_ImageExpanded))
                EndIf
              EndIf
              ResizeGadget(\Gadget[#PropertyChild_Function], x, y + __PG_LabelOffset, __PG_ToggleSize, __PG_ToggleSize)
              ResizeGadget(\Gadget[#PropertyChild_Main], x + ToggleOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[0]), __PG_ToggleSize)
            Case #__PG_Spacer
              y + \IValue
            Case #__PG_String, #__PG_Password, #__PG_ComboBox, #__PG_Shortcut, #__PG_Spin
              If (\Gadget[3])
                ResizeGadget(\Gadget[3], x + ToggleOffset, y + __PG_LabelOffset, #PB_Ignore, #PB_Ignore)
              EndIf
              ResizeGadget(\Gadget[1], x + ToggleOffset + ImgOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y, FlexWidth, __PG_ItemHeight(\Type))
            Case #__PG_Checkbox
              ResizeGadget(\Gadget[1], x + ToggleOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y, __PG_ReqWidth(\Gadget[0]) - __PG_Cond(#__PG_Windows, 6), __PG_ItemHeight(\Type))
            Case #__PG_CheckboxLabel
              ResizeGadget(\Gadget[0], x + ToggleOffset, y, __PG_ReqWidth(\Gadget[0]), __PG_ItemHeight(\Type))
            Case #__PG_Button, #__PG_Label
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y, FlexWidth, __PG_ItemHeight(\Type))
            Case #__PG_Color
              ResizeGadget(\Gadget[1], x + ToggleOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[2], x + ToggleOffset + *PG\LabelWidth, y + 1, __PG_ItemHeight(\Type) - 2, __PG_ItemHeight(\Type) - 2)
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth + __PG_ItemHeight(\Type) - 1, y, FlexWidth - __PG_ItemHeight(\Type) + 1, __PG_ItemHeight(\Type))
            Case #__PG_Trackbar, #__PG_Percent
              ResizeGadget(\Gadget[1], x + ToggleOffset, y + __PG_LabelOffset + 1, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y + 1, FlexWidth, __PG_ItemHeight(\Type) - 2)
            Case #__PG_Progress
              ResizeGadget(\Gadget[1], x + ToggleOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y + 2, FlexWidth, __PG_ItemHeight(\Type) - 3)
            Case #__PG_Browse
              ResizeGadget(\Gadget[1], x + ToggleOffset, y + __PG_LabelOffset, __PG_ReqWidth(\Gadget[1]), __PG_ReqHeight(\Gadget[1]))
              ResizeGadget(\Gadget[0], x + ToggleOffset + *PG\LabelWidth, y, FlexWidth - __PG_ReqWidth(\Gadget[2]), __PG_ItemHeight(\Type))
              ResizeGadget(\Gadget[2], GadgetX(\Gadget[0]) + GadgetWidth(\Gadget[0]), y, __PG_ReqWidth(\Gadget[2]), __PG_ItemHeight(\Type))
            Default
              CompilerIf (#__PG_Debug)
                Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(\Type)
              CompilerEndIf
          EndSelect
          y + __PG_Padding + __PG_ItemHeight(\Type)
          For i = 0 To #__PG_MaxSubgadgets - 1
            If (\Gadget[i])
              HideGadget(\Gadget[i], #False)
            EndIf
          Next i
        Else
          For i = 0 To #__PG_MaxSubgadgets - 1
            If (\Gadget[i])
              HideGadget(\Gadget[i], #True)
            EndIf
          Next i
        EndIf
      EndWith
    Next
  EndIf
EndProcedure

Procedure __RecalcPropertyGadget(*PG.__PropertyGadget, Resize.i = #False)
  If (*PG)
    Protected MinWLeft.i  = __PG_MinWLeft
    Protected MinWRight.i = __PG_MinWRight
    If (*PG\MinLabelW)
      MinWLeft = *PG\MinLabelW
    EndIf
    If (*PG\MinFieldW)
      MinWRight = *PG\MinFieldW
    EndIf
    Protected MinWTotal.i = MinWLeft + MinWRight
    ;
    Protected ThisWLeft.i, ThisWRight.i, ThisWTotal.i
    ;
    Protected HTotal.i = 0
    ;
    *PG\HasHeaders = #False
    ForEach (*PG\PGI())
      If (*PG\PGI()\Type = #__PG_Header)
        *PG\HasHeaders = #True
        Break
      EndIf
    Next
    ;
    Protected Collapsed.i = #False
    ForEach (*PG\PGI())
      ThisWLeft  = 0
      ThisWRight = 0
      ThisWTotal = 0
      With *PG\PGI()
        Select (\Type)
          Case #__PG_Header
            ThisWTotal = __PG_ReqWidth(\Gadget[0])
            Collapsed = \IValue
            If (ListIndex(*PG\PGI()) > 0)
              HTotal + __PG_Margin
            EndIf
          Case #__PG_Spacer
            If (Not Collapsed)
              HTotal + \IValue
            EndIf
          Case #__PG_String, #__PG_Password, #__PG_Shortcut, #__PG_Color, #__PG_Trackbar, #__PG_Percent, #__PG_Spin, #__PG_Progress, #__PG_Browse, #__PG_Checkbox
            ThisWLeft = __PG_ReqWidth(\Gadget[1]) + __PG_Margin
          Case #__PG_CheckboxLabel
            ThisWTotal = __PG_ReqWidth(\Gadget[0])
          Case #__PG_Button
            ThisWRight = __PG_ReqWidth(\Gadget[0])
          Case #__PG_ComboBox
            ThisWLeft  = __PG_ReqWidth(\Gadget[1]) + __PG_Margin
            ThisWRight = __PG_ReqWidth(\Gadget[0])
          Case #__PG_Label
            ThisWRight = __PG_ReqWidth(\Gadget[0])
          Default
            CompilerIf (#__PG_Debug)
              Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(\Type)
            CompilerEndIf
        EndSelect
        If (\Image <> -1)
          Select (\Type)
            Case #__PG_Button
              ;
            Default
              ThisWLeft + __PG_ToggleSize
          EndSelect
        EndIf
        If (ThisWLeft > MinWLeft)
          MinWLeft = ThisWLeft
        EndIf
        If (ThisWRight > MinWRight)
          MinWRight = ThisWRight
        EndIf
        If (ThisWTotal > MinWTotal)
          MinWTotal = ThisWTotal
        EndIf
        If ((Not Collapsed) Or (\Type = #__PG_Header))
          HTotal + __PG_Padding + __PG_ItemHeight(\Type)
        EndIf
      EndWith
    Next
    If (MinWLeft + MinWRight > MinWTotal)
      MinWTotal = MinWLeft + MinWRight
    EndIf
    MinWTotal + __PG_Margin
    If (*PG\HasHeaders)
      MinWTotal + __PG_ToggleSize
    EndIf
    HTotal + 3 * __PG_Margin
    If (ListSize(*PG\PGI()))
      HTotal - __PG_Padding
    EndIf
    *PG\VisWidth   = MinWTotal
    *PG\VisHeight  = HTotal
    *PG\LabelWidth = MinWLeft
    If (Resize)
      __ResizePropertyGadget(*PG)
    EndIf
  EndIf
EndProcedure

Procedure.i __FindPropertyGadgetItem(*PG.__PropertyGadget, Gadget.i)
  Protected *PGI.__PropertyGadgetItem
  Protected i.i
  PushListPosition(*PG\PGI())
    ForEach (*PG\PGI())
      For i = 0 To #__PG_MaxSubgadgets - 1
        If (*PG\PGI()\Gadget[i] = Gadget)
          *PGI = @*PG\PGI()
          Break 2
        EndIf
      Next i
    Next
  PopListPosition(*PG\PGI())
  ProcedureReturn (*PGI)
EndProcedure

Procedure __ActivatePropertyHeader(*PG.__PropertyGadget, *PGI.__PropertyGadgetItem)
  If (*PG\Flags & #PropertyGadget_OneOpen)
    ForEach (*PG\PGI())
      If (*PG\PGI()\Type = #__PG_Header)
        If (@*PG\PGI() <> *PGI)
          *PG\PGI()\IValue = #True
        EndIf
      EndIf
    Next
  EndIf
EndProcedure

Procedure __UpdateProperty(*PGI.__PropertyGadgetItem, LeaveText.i = #False)
  If (*PGI)
    Select (*PGI\Type)
      Case #__PG_Color
        If (StartDrawing(CanvasOutput(*PGI\Gadget[2])))
          Box(0, 0, OutputWidth(), OutputHeight(), *PGI\IValue)
          StopDrawing()
        EndIf
        Protected Color.i = *PGI\IValue
        If (Not LeaveText)
          If (*PGI\ExData & #ColorProperty_PBFormat)
            SetGadgetText(*PGI\Gadget[0], "$" + RSet(Hex(Color), 6, "0"))
          ElseIf (*PGI\ExData & #ColorProperty_CFormat)
            SetGadgetText(*PGI\Gadget[0], "0x" + RSet(Hex(Color), 6, "0"))
          Else
            Color = RGB(Blue(Color), Green(Color), Red(Color))
            SetGadgetText(*PGI\Gadget[0], "#" + RSet(Hex(Color), 6, "0"))
          EndIf
        EndIf
      Case #__PG_Percent
        GadgetToolTip(*PGI\Gadget[0], Str(*PGI\IValue) + "%")
    EndSelect
  EndIf
EndProcedure

Procedure __PropertyGadgetCallbackProcess(Gadget.i, EventType.i)
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    Protected *PGI.__PropertyGadgetItem = __FindPropertyGadgetItem(*PG, Gadget)
    CompilerIf (#__PG_Windows)
      If (Gadget = *PG\Scroll)
        If (*PG\Dummy)
          If (GetActiveGadget() <> *PG\Dummy)
            If (Not __FindPropertyGadgetItem(*PG, GetActiveGadget()))
              SetActiveGadget(*PG\Dummy)
            EndIf
          EndIf
        EndIf
      EndIf
    CompilerEndIf
    If (*PGI)
      ChangeCurrentElement(*PG\PGI(), *PGI)
      Protected EventIndex.i = ListIndex(*PG\PGI())
      With *PGI
        Select (\Type)
        
          Case #__PG_Header
            LockPropertyGadget(*PG\Scroll, #True)
            \IValue = Bool(Not \IValue)
            __ActivatePropertyHeader(*PG, *PGI)
            __RecalcPropertyGadget(*PG, #True)
            If (Not \IValue)
              If (#True) ; Auto Scroll
                Protected sy.i = GetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_Y)
                Protected MaxY.i = GadgetY(\Gadget[0])
                Protected DesiredY.i = GadgetY(\Gadget[0])
                If (sy > DesiredY - __PG_Margin)
                  SetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_Y, DesiredY - __PG_Margin)
                  sy = GetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_Y)
                EndIf
                Protected gw.i = GadgetWidth(*PG\Scroll)
                Protected gh.i = GadgetHeight(*PG\Scroll)
                If (*PG\Flags & #PropertyGadget_Border)
                  CompilerIf (#__PG_Windows)
                    gw - GetSystemMetrics_(#SM_CXEDGE) * 2
                    gh - GetSystemMetrics_(#SM_CYEDGE) * 2
                  CompilerElse
                    gw - 4 ;? determine actual border size
                    gh - 4
                  CompilerEndIf
                EndIf
                CompilerIf (#__PG_Windows)
                  If (gw - GetSystemMetrics_(#SM_CXVSCROLL) < *PG\VisWidth)
                    gh - GetSystemMetrics_(#SM_CYHSCROLL)
                  EndIf
                CompilerElse
                  ;? determine height of horizontal scrollbar
                CompilerEndIf
                Protected ViewBottom.i = gh + sy
                DesiredY + GadgetHeight(\Gadget[0])
                ChangeCurrentElement(*PG\PGI(), *PGI)
                While (NextElement(*PG\PGI()))
                  If (*PG\PGI()\Type = #__PG_Spacer)
                    DesiredY + *PG\PGI()\IValue
                  ElseIf (*PG\PGI()\Type <> #__PG_Header)
                    DesiredY + GadgetHeight(*PG\PGI()\Gadget[0])
                  Else
                    Break
                  EndIf
                Wend
                DesiredY + __PG_Margin * 2
                If (DesiredY > ViewBottom)
                  sy + (DesiredY - ViewBottom)
                  If (sy > MaxY)
                    sy = MaxY
                  EndIf
                  SetGadgetAttribute(*PG\Scroll, #PB_ScrollArea_Y, sy)
                EndIf
              EndIf
            EndIf
            LockPropertyGadget(*PG\Scroll, #False)
            If (*PG\Dummy)
              SetActiveGadget(*PG\Dummy)
            EndIf
            
          Case #__PG_String, #__PG_Password
            Select (EventType)
              Case #PB_EventType_Focus
                __PG_Select(Gadget)
              Case #PB_EventType_Change
                __PG_Post(*PG, EventIndex)
            EndSelect
            
          Case #__PG_Button, #__PG_Checkbox, #__PG_CheckboxLabel, #__PG_Shortcut
            __PG_Post(*PG, EventIndex)
            
          Case #__PG_Trackbar, #__PG_Percent, #__PG_Spin
            If (\IValue <> GetGadgetState(Gadget))
              \IValue = GetGadgetState(Gadget)
              If (\Type = #__PG_Percent)
                __UpdateProperty(*PGI)
              EndIf
              __PG_Post(*PG, EventIndex)
            EndIf
            
          Case #__PG_ComboBox
            If (EventType = #PB_EventType_Change)
              __PG_Post(*PG, EventIndex)
            EndIf
            
          Case #__PG_Color
            Protected Color.i, Text.s
            If (Gadget = *PGI\Gadget[0])
              If (EventType = #PB_EventType_Change)
                Color = -1
                Text = Trim(GetGadgetText(Gadget))
                If (Left(Text, 1) = "$")
                  If (RemoveString(Text, "$"))
                    Color = Val(Text)
                  EndIf
                Else
                  Text = RemoveString(Text, "0x")
                  Text = RemoveString(Text, "0X")
                  Text = RemoveString(Text, "#")
                  If (Text)
                    Color = Val("$" + Text)
                    Color = RGB(Blue(Color), Green(Color), Red(Color))
                  EndIf
                EndIf
                If (Color >= 0)
                  *PGI\IValue = Color
                  __UpdateProperty(*PGI, #True)
                  __PG_Post(*PG, EventIndex)
                EndIf
              ElseIf (EventType = #PB_EventType_Focus)
                __PG_Select(Gadget)
              EndIf
            ElseIf (Gadget = *PGI\Gadget[2])
              If ((EventType = #PB_EventType_LeftClick) Or (EventType = #PB_EventType_RightClick))
                Color = ColorRequester(*PGI\IValue)
                If (Color >= 0)
                  *PGI\IValue = Color
                  __UpdateProperty(*PGI)
                  __PG_Select(*PGI\Gadget[0])
                  __PG_Post(*PG, EventIndex)
                EndIf
              EndIf
            EndIf
            
          Case #__PG_Browse
            If (Gadget = *PGI\Gadget[0])
              Select (EventType)
                Case #PB_EventType_Focus
                  __PG_Select(Gadget)
                Case #PB_EventType_Change
                  __PG_Post(*PG, EventIndex)
              EndSelect
            ElseIf (Gadget = *PGI\Gadget[2])
              If (*PGI\ExData)
                Protected Browse.__PG_BrowseProto = *PGI\ExData
                ;If (CallFunctionFast(*PGI\ExData, *PG\Scroll, *PGI\Gadget[0], ListIndex(*PG\PGI()), @*PGI\ID))
                If (Browse(*PG\Scroll, *PGI\Gadget[0], ListIndex(*PG\PGI()), *PGI\ID))
                  __PG_Select(*PGI\Gadget[0])
                  __PG_Post(*PG, EventIndex)
                EndIf
              EndIf
            EndIf
          
          Default
            Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(*PGI\Type)
          
        EndSelect
      EndWith
    EndIf
  EndIf
EndProcedure

Procedure __PropertyGadgetCallback()
  __PropertyGadgetCallbackProcess(EventGadget(), EventType())
EndProcedure

Procedure.i __AddPropertyGadgetItem(*PG.__PropertyGadget, Type.i, Name.s, ID.s, IValue.i, SValue.s)
  Protected Result.i = -1
  If (*PG)
    LastElement(*PG\PGI())
    Protected Flags.i
    Protected First.i
    Protected i.i, n.i, Subtext.s
    Protected *PGI.__PropertyGadgetItem = AddElement(*PG\PGI())
    If (*PGI)
      With *PGI
        OpenGadgetList(*PG\Scroll)
        \Type = #__PG_None
        Select (Type)
          
          Case #__PG_Header
            \Gadget[#PropertyChild_Main] = HyperLinkGadget(#PB_Any, 0, 0, 25, 25, Name, __PG_TextColor,
                __PG_Cond(*PG\Flags & #PropertyGadget_Underline, #PB_HyperLink_Underline))
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Function] = ImageGadget(#PB_Any, 0, 0, __PG_ToggleSize, __PG_ToggleSize, ImageID(__PG_ImageExpanded))
              \Type   = Type
              \IValue = IValue
              If (__PG_HeaderFont)
                SetGadgetFont(\Gadget[#PropertyChild_Main], FontID(__PG_HeaderFont))
              EndIf
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
              BindGadgetEvent(\Gadget[#PropertyChild_Function], @__PropertyGadgetCallback(), #PB_EventType_LeftClick)
              BindGadgetEvent(\Gadget[#PropertyChild_Function], @__PropertyGadgetCallback(), #PB_EventType_LeftDoubleClick)
              If (*PG\Flags & #PropertyGadget_OneOpen) ; Collapse all except first header
                First = #True
                ForEach (*PG\PGI())
                  If (*PG\PGI()\Type = #__PG_Header)
                    *PG\PGI()\IValue = Bool(Not First)
                    First = #False
                  EndIf
                Next
              EndIf
            EndIf
            
          Case #__PG_Browse
            \Gadget[#PropertyChild_Main] = StringGadget(#PB_Any, 0, 0, 25, 25, SValue)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              CompilerIf (#PB_Compiler_Unicode)
                Subtext = Chr($2026)
              CompilerElseIf (#__PG_Windows)
                Subtext = Chr($85)
              CompilerElse
                Subtext = "..."
              CompilerEndIf
              \Gadget[#PropertyChild_Function] = ButtonGadget(#PB_Any, 0, 0, 25, 25, Subtext)
              \Type   = Type
              \ExData = IValue
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
              BindGadgetEvent(\Gadget[#PropertyChild_Function], @__PropertyGadgetCallback())
              __PG_RepCallback(\Gadget[#PropertyChild_Main], @__PG_StringGadgetCallback())
            EndIf
            
          Case #__PG_Button
            \Gadget[#PropertyChild_Main] = ButtonGadget(#PB_Any, 0, 0, 25, 25, Name)
            If (\Gadget[#PropertyChild_Main])
              \Type = Type
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
            
          Case #__PG_CheckboxLabel
            \Gadget[#PropertyChild_Main] = CheckBoxGadget(#PB_Any, 0, 0, 25, 25, Name)
            If (\Gadget[#PropertyChild_Main])
              \Type = Type
              SetGadgetState(\Gadget[#PropertyChild_Main], IValue)
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
            
          Case #__PG_Checkbox
            \Gadget[#PropertyChild_Main] = CheckBoxGadget(#PB_Any, 0, 0, 25, 25, "")
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              SetGadgetState(\Gadget[#PropertyChild_Main], IValue)
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
            
          Case #__PG_Color
            \Gadget[#PropertyChild_Main] = StringGadget(#PB_Any, 0, 0, 25, 25, "")
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Gadget[#PropertyChild_Function] = CanvasGadget(#PB_Any, 0, 0, 25, 25, #PB_Canvas_Border)
              \Type   = Type
              \ExData = IValue
              \IValue = Val(SValue)
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
              BindGadgetEvent(\Gadget[#PropertyChild_Function], @__PropertyGadgetCallback())
              __PG_RepCallback(\Gadget[#PropertyChild_Main], @__PG_StringGadgetCallback())
            EndIf
            
          Case #__PG_ComboBox
            If (IValue)
              Flags = #PB_ComboBox_Editable
            Else
              Flags = #Null
            EndIf
            \Gadget[#PropertyChild_Main] = ComboBoxGadget(#PB_Any, 0, 0, 25, 25, Flags)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              SValue = ReplaceString(SValue, "|", #LF$)
              n = 1 + CountString(SValue, #LF$)
              For i = 0 To n - 1
                AddGadgetItem(\Gadget[#PropertyChild_Main], i, Trim(StringField(SValue, i + 1, #LF$)))
              Next i
              SetGadgetState(\Gadget[#PropertyChild_Main], 0)
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
              CompilerIf (#__PG_Windows)
                If (IValue)
                  Protected CBI.COMBOBOXINFO
                  CBI\cbSize = SizeOf(COMBOBOXINFO)
                  If (GetComboBoxInfo_(GadgetID(\Gadget[#PropertyChild_Main]), @CBI))
                    SetWindowLongPtr_(CBI\hwndItem, #GWL_USERDATA, GetWindowLongPtr_(CBI\hwndItem, #GWL_WNDPROC))
                    SetWindowLongPtr_(CBI\hwndItem, #GWL_WNDPROC, @__PG_StringGadgetCallback())
                  EndIf
                EndIf
              CompilerEndIf
            EndIf
            
          Case #__PG_Label
            \Gadget[#PropertyChild_Main] = TextGadget(#PB_Any, 0, 0, 25, 25, SValue)
            If (\Gadget[#PropertyChild_Main])
              \Type = Type
            EndIf
            
          Case #__PG_Progress
            \Gadget[#PropertyChild_Main] = ProgressBarGadget(#PB_Any, 0, 0, 25, 25, 0, IValue, 0)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
            EndIf
            
          Case #__PG_Shortcut
            \Gadget[#PropertyChild_Main] = ShortcutGadget(#PB_Any, 0, 0, 25, 25, IValue)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
            
          Case #__PG_Spacer
              \Type = Type
              If (IValue < 0)
                IValue = __PG_ToggleSize / 2
              EndIf
              \IValue = IValue
            
          Case #__PG_Spin
            \Gadget[#PropertyChild_Main] = SpinGadget(#PB_Any, 0, 0, 25, 25, 0, IValue, #PB_Spin_ReadOnly | #PB_Spin_Numeric)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              SetGadgetState(\Gadget[#PropertyChild_Main], 0)
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
              
          Case #__PG_String, #__PG_Password
            If (Type = #__PG_Password)
              Flags = #PB_String_Password
            Else
              Flags = #Null
            EndIf
            \Gadget[#PropertyChild_Main] = StringGadget(#PB_Any, 0, 0, 25, 25, SValue, Flags)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
              __PG_RepCallback(\Gadget[#PropertyChild_Main], @__PG_StringGadgetCallback())
            EndIf
            
          Case #__PG_Trackbar, #__PG_Percent
            \Gadget[#PropertyChild_Main] = TrackBarGadget(#PB_Any, 0, 0, 25, 25, 0, IValue)
            If (\Gadget[#PropertyChild_Main])
              \Gadget[#PropertyChild_Label] = TextGadget(#PB_Any, 0, 0, 25, 25, Name)
              \Type = Type
              BindGadgetEvent(\Gadget[#PropertyChild_Main], @__PropertyGadgetCallback())
            EndIf
            
          Default
            CompilerIf (#__PG_Debug)
              Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(Type)
            CompilerEndIf
            
        EndSelect
        
        If (\Type <> #__PG_None) ; Finalize property
          \Name  =  Name
          \ID    =  ID
          \Image = -1
          For i = 0 To #__PG_MaxSubgadgets - 1
            If (\Gadget[i])
              SetGadgetData(\Gadget[i], *PG)
            EndIf
          Next i
          Result = ListIndex(*PG\PGI())
          __UpdateProperty(*PGI)
          __RecalcPropertyGadget(*PG, #True)
        Else
          DeleteElement(*PG\PGI())
        EndIf
        CloseGadgetList()
      EndWith
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure __InitPropertyGadgets()
  Protected TempGadget.i
  Protected DummyText.s = "ABC123"
  
  
  ; Default metrics
  
  __PG_Margin  = 5
  __PG_Padding = 0
  
  ; Determine standard heights of temporary gadgets
  
  CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
    __PG_ItemHeight(#__PG_Button) = 25
  CompilerElse
    TempGadget = ButtonGadget(#PB_Any, 0, 0, 25, 25, DummyText)
      __PG_ItemHeight(#__PG_Button) = __PG_ReqHeight(TempGadget)
      FreeGadget(TempGadget)
  CompilerEndIf
  
  TempGadget = CheckBoxGadget(#PB_Any, 0, 0, 25, 25, DummyText)
    __PG_ItemHeight(#__PG_CheckboxLabel) = __PG_ReqHeight(TempGadget)
    FreeGadget(TempGadget)
  
  TempGadget = ComboBoxGadget(#PB_Any, 0, 0, 25, 25, #PB_ComboBox_Editable)
    SetGadgetText(TempGadget, DummyText)
    __PG_ItemHeight(#__PG_ComboBox) = __PG_ReqHeight(TempGadget)
    FreeGadget(TempGadget)
  
  TempGadget = TextGadget(#PB_Any, 0, 0, 25, 25, DummyText)
    __PG_ItemHeight(#__PG_Label) = __PG_ReqHeight(TempGadget)
    SetGadgetText(TempGadget, "ABC123")
    __PG_MinWLeft = __PG_ReqWidth(TempGadget)
    SetGadgetText(TempGadget, "ABCDEFG1234567")
    __PG_MinWRight = __PG_ReqWidth(TempGadget)
    FreeGadget(TempGadget)
  
  TempGadget = SpinGadget(#PB_Any, 0, 0, 25, 25, 0, 1000, #PB_Spin_ReadOnly)
    __PG_ItemHeight(#__PG_Spin) = __PG_ReqHeight(TempGadget) + 0
    FreeGadget(TempGadget)
  
  TempGadget = StringGadget(#PB_Any, 0, 0, 25, 25, DummyText)
    __PG_ItemHeight(#__PG_String)   = __PG_ReqHeight(TempGadget)
    FreeGadget(TempGadget)
  
  
  ; Load custom Header font
  CompilerIf (#__PG_Windows And (#True))
    __PG_HeaderFont = __PG_LoadBoldFont()
  CompilerEndIf
  
  
  
  ; Determine derivitive standard heights
  
  __PG_LabelOffset = (__PG_ItemHeight(#__PG_String) - __PG_ItemHeight(#__PG_Label) + 1)/2
  __PG_ToggleSize  = (__PG_ItemHeight(#__PG_Label))
  
  __PG_ItemHeight(#__PG_Header)    = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Browse)    = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Color)     = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Checkbox)  = __PG_ItemHeight(#__PG_CheckboxLabel)
  __PG_ItemHeight(#__PG_Password)  = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Progress)  = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Shortcut)  = __PG_ItemHeight(#__PG_String)
  __PG_ItemHeight(#__PG_Spacer)    = 0 ; Actual spacing height determined by IValue
  __PG_ItemHeight(#__PG_Trackbar)  = __PG_ItemHeight(#__PG_Button) + 2
  __PG_ItemHeight(#__PG_Percent)   = __PG_ItemHeight(#__PG_Trackbar)
  
  
  ; Determine standard colors
  CompilerIf (#__PG_Windows)
    __PG_WinColor  = GetSysColor_(#COLOR_MENU)
    __PG_TextColor = GetSysColor_(#COLOR_MENUTEXT)
  CompilerElse
    __PG_WinColor  = $FFFFFF
    __PG_TextColor = $000000
  CompilerEndIf
  
  
  ; Draw expanded image
  Protected Size.i = (__PG_ToggleSize*30/100) | 0;1
  Protected i.i
  __PG_ImageExpanded = CreateImage(#PB_Any, __PG_ToggleSize, __PG_ToggleSize)
  If (__PG_ImageExpanded)
    If (StartDrawing(ImageOutput(__PG_ImageExpanded)))
      Box(0, 0, OutputWidth(), OutputHeight(), __PG_WinColor)
      FrontColor(__PG_TextColor)
      For i = 0 To Size - 1
        Box(__PG_ToggleSize/2 + i, __PG_ToggleSize/2 - Size/2, 1, Size-i)
        Box(__PG_ToggleSize/2 - i, __PG_ToggleSize/2 - Size/2, 1, Size-i)
      Next i
      CompilerIf (#False)
        DrawingMode(#PB_2DDrawing_Outlined)
        Box(1, 1, OutputWidth() - 2, OutputHeight() - 2)
      CompilerEndIf
      StopDrawing()
    EndIf
  EndIf
  
  ; Draw collapsed image
  __PG_ImageCollapsed = CreateImage(#PB_Any, __PG_ToggleSize, __PG_ToggleSize)
  If (__PG_ImageCollapsed)
    If (StartDrawing(ImageOutput(__PG_ImageCollapsed)))
      Box(0, 0, OutputWidth(), OutputHeight(), __PG_WinColor)
      FrontColor(__PG_TextColor)
      For i = 0 To Size - 1
        Box(__PG_ToggleSize/2 - Size/2, __PG_ToggleSize/2 + i, Size-i, 1)
        Box(__PG_ToggleSize/2 - Size/2, __PG_ToggleSize/2 - i, Size-i, 1)
      Next i
      CompilerIf (#False)
        DrawingMode(#PB_2DDrawing_Outlined)
        Box(1, 1, OutputWidth() - 2, OutputHeight() - 2)
      CompilerEndIf
      StopDrawing()
    EndIf
  EndIf
  
  ; Check ItemHeights are non-zero
  CompilerIf (#__PG_Debug)
    For i = 0 To #__PG_TypeCount - 1
      If (__PG_ItemHeight(i) = 0)
        Select (i)
          Case #__PG_Spacer
            ; 0 height expected
          Default
            Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(i)
        EndSelect
      EndIf
    Next i
  CompilerEndIf
  
  __PG_Initialized = #True
EndProcedure
















;-
;- Procedures (Public)

Procedure LockPropertyGadget(Gadget.i, State.i)
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (State)
      *PG\LockCount + 1
      CompilerIf (#__PG_Windows)
        If (*PG\LockCount = 1)
          SendMessage_(GadgetID(*PG\Scroll), #WM_SETREDRAW, #False, #Null)
        EndIf
      CompilerEndIf
    ElseIf (*PG\LockCount > 0)
      *PG\LockCount - 1
      If (*PG\LockCount = 0)
        __ResizePropertyGadget(*PG)
        CompilerIf (#__PG_Windows)
          SendMessage_(GadgetID(*PG\Scroll), #WM_SETREDRAW, #True, #Null)
          InvalidateRect_(GadgetID(*PG\Scroll), #Null, #True)
        CompilerEndIf
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure.i PropertyGadget(Gadget.i, x.i, y.i, Width.i, Height.i, Flags.i = #Null)
  Protected Result.i = #Null
  Protected Scroll.i = ScrollAreaGadget(Gadget, x, y, Width, Height, 25, 25, 20, __PG_Cond(Not (Flags & #PropertyGadget_Border), #PB_ScrollArea_BorderLess))
  If (Scroll)
    Result = Scroll
    If (Gadget <> #PB_Any)
      Scroll = Gadget
    EndIf
    Protected *PG.__PropertyGadget = AllocateStructure(__PropertyGadget)
    If (*PG)
      If (Not __PG_Initialized)
        __InitPropertyGadgets()
      EndIf
      CompilerIf (Defined(__PG_ScrollAreaCallback, #PB_Procedure))
        __PG_RepCallback(Scroll, @__PG_ScrollAreaCallback())
      CompilerEndIf
      *PG\Flags  = Flags
      *PG\Scroll = Scroll
      CompilerIf (#__PG_GetBuildWindow)
        *PG\Window = __PG_GetBuildWindow()
      CompilerElse
        *PG\Window = -1
      CompilerEndIf
      CompilerIf (#__PG_Windows)
        *PG\Dummy = StringGadget(#PB_Any, 0, 0, 0, __PG_ItemHeight(#__PG_String), "", #PB_String_BorderLess)
        SetActiveGadget(*PG\Dummy)
      CompilerEndIf
      SetGadgetData(Scroll, *PG)
      BindGadgetEvent(Scroll, @__PropertyGadgetCallback())
    Else
      Result = #Null
    EndIf
    CloseGadgetList()
    If (Result)
      __RecalcPropertyGadget(*PG, #True)
    Else
      FreeGadget(Scroll)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i FreePropertyGadget(Gadget.i)
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    ForEach (*PG\PGI())
      With *PG\PGI()
        Protected i.i
        For i = 0 To #__PG_MaxSubgadgets - 1
          If (\Gadget[i])
            UnbindGadgetEvent(\Gadget[i], @__PropertyGadgetCallback())
            FreeGadget(\Gadget[i])
          EndIf
        Next i
      EndWith
    Next
    ClearList(*PG\PGI())
    UnbindGadgetEvent(*PG\Scroll, @__PropertyGadgetCallback())
    SetGadgetData(*PG\Scroll, #Null)
    If (*PG\Dummy)
      FreeGadget(*PG\Dummy)
    EndIf
    FreeGadget(*PG\Scroll)
    FreeStructure(*PG)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure ResizePropertyGadget(Gadget.i, x.i, y.i, Width.i = #PB_Ignore, Height.i = #PB_Ignore)
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    LockPropertyGadget(Gadget, #True)
    ResizeGadget(Gadget, x, y, Width, Height)
    __ResizePropertyGadget(*PG)
    LockPropertyGadget(Gadget, #False)
  EndIf
EndProcedure

Procedure SetPropertyGadgetAttribute(Gadget.i, Attribute.i, Value.i)
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    Select (Attribute)
      Case #PropertyGadget_ExpandedImageID, #PropertyGadget_CollapsedImageID
        If (Value = #PB_Default)
          Value = #Null
        EndIf
        If (Attribute = #PropertyGadget_ExpandedImageID)
          *PG\ExpImgID = Value
        Else
          *PG\ColImgID = Value
        EndIf
        __ResizePropertyGadget(*PG) ; this updates header images
      Case #PropertyGadget_MinLabelWidth, #PropertyGadget_MinFieldWidth
        If (Value <= 0)
          Value = 0
        EndIf
        If (Attribute = #PropertyGadget_MinLabelWidth)
          *PG\MinLabelW = Value
        Else
          *PG\MinFieldW = Value
        EndIf
        __RecalcPropertyGadget(*PG, #True)
    EndSelect
  EndIf
EndProcedure

;-

Procedure.i PropertyIndexFromID(Gadget.i, ID.s)
  Protected Result.i = -1
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      ID = LCase(ID)
      PushListPosition(*PG\PGI())
        ForEach (*PG\PGI())
          If (LCase(*PG\PGI()\ID) = ID)
            Result = ListIndex(*PG\PGI())
            Break
          EndIf
        Next
      PopListPosition(*PG\PGI())
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s PropertyIDFromIndex(Gadget.i, Index.i, ReplaceBlank.i = #False)
  Protected Result.s = ""
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      Result = *PG\PGI()\ID
      If (ReplaceBlank)
        If (Result = "")
          Result = Str(Index)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MatchProperty(Gadget.i, Index.i, ID.s)
  ProcedureReturn Bool(LCase(PropertyIDFromIndex(Gadget, Index)) = LCase(ID))
EndProcedure

Procedure SetPropertyExData(Gadget.i, Index.i, ExData.i, ID.s = "")
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      *PG\PGI()\ExData = ExData
      __UpdateProperty(@*PG\PGI())
    EndIf
  EndIf
EndProcedure

Procedure.i GetPropertyChild(Gadget.i, Index.i, ID.s = "", SubIndex.i = 0)
  Protected Result.i = #Null
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If ((SubIndex >= 0) And (SubIndex < #__PG_MaxSubgadgets))
      If (ID)
        Index = PropertyIndexFromID(Gadget, ID)
      ElseIf (Index = #Property_Last)
        Index = ListSize(*PG\PGI()) - 1
      EndIf
      If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
        SelectElement(*PG\PGI(), Index)
        Result = *PG\PGI()\Gadget[SubIndex]
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GetPropertyState(Gadget.i, Index.i, ID.s = "")
  Protected Result.i = 0
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      Select (*PG\PGI()\Type)
        Case #__PG_Header, #__PG_Color
          Result = *PG\PGI()\IValue
        Case #__PG_Browse, #__PG_Label, #__PG_Password, #__PG_String
          Result = Val(GetGadgetText(*PG\PGI()\Gadget[0]))
        Case #__PG_Button, #__PG_ComboBox, #__PG_Percent, #__PG_Progress, #__PG_Shortcut, #__PG_Spin, #__PG_Trackbar
          Result = GetGadgetState(*PG\PGI()\Gadget[0])
        Case #__PG_Checkbox, #__PG_CheckboxLabel
          If (*PG\PGI()\ExData)
            Result = GetGadgetState(*PG\PGI()\Gadget[0]) * *PG\PGI()\ExData
          Else
            Result = GetGadgetState(*PG\PGI()\Gadget[0])
          EndIf
        Case #__PG_Spacer
          ;
        Default
          Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(*PG\PGI()\Type)
      EndSelect
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure SetPropertyState(Gadget.i, Index.i, State.i, ID.s = "")
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      Select (*PG\PGI()\Type)
        Case #__PG_Header
          If (Bool(State) <> *PG\PGI()\IValue)
            __PropertyGadgetCallbackProcess(*PG\PGI()\Gadget[1], #PB_EventType_LeftClick)
          EndIf
        Case #__PG_Browse, #__PG_Password, #__PG_String
          SetGadgetText(*PG\PGI()\Gadget[0], Str(State))
        Case #__PG_Button, #__PG_ComboBox, #__PG_Percent, #__PG_Progress, #__PG_Shortcut, #__PG_Spin, #__PG_Trackbar
          SetGadgetState(*PG\PGI()\Gadget[0], State)
        Case #__PG_Checkbox, #__PG_CheckboxLabel
          SetGadgetState(*PG\PGI()\Gadget[0], Bool(State))
        Case #__PG_Color
          *PG\PGI()\IValue = State
          __UpdateProperty(@*PG\PGI())
        Case #__PG_Label, #__PG_Spacer
          ;
        Default
          Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(*PG\PGI()\Type)
      EndSelect
    EndIf
  EndIf
EndProcedure

Procedure.s GetPropertyText(Gadget.i, Index.i, ID.s = "")
  Protected Result.s = ""
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      Select (*PG\PGI()\Type)
        Case #__PG_Header, #__PG_Button
          Result = *PG\PGI()\SValue
        Case #__PG_Browse, #__PG_Color, #__PG_ComboBox, #__PG_Label, #__PG_Password, #__PG_String
          Result = GetGadgetText(*PG\PGI()\Gadget[0])
        Case #__PG_Checkbox, #__PG_CheckboxLabel, #__PG_Progress, #__PG_Spin, #__PG_Trackbar
          Result = Str(GetGadgetState(*PG\PGI()\Gadget[0]))
        Case #__PG_Percent
          Result = Str(GetGadgetState(*PG\PGI()\Gadget[0])) + "%"
        Case #__PG_Shortcut
          Result = GetGadgetText(*PG\PGI()\Gadget[0])
        Case #__PG_Spacer
          ;
        Default
          Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(*PG\PGI()\Type)
      EndSelect
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure SetPropertyText(Gadget.i, Index.i, Text.s, ID.s = "")
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      Select (*PG\PGI()\Type)
        Case #__PG_Header, #__PG_Browse, #__PG_Button, #__PG_Label
          *PG\PGI()\SValue = Text
          SetGadgetText(*PG\PGI()\Gadget[0], Text)
        Case #__PG_Checkbox
          SetGadgetText(*PG\PGI()\Gadget[1], Text)
        Case #__PG_CheckboxLabel
          SetGadgetText(*PG\PGI()\Gadget[0], Text)
        Case #__PG_Color
          SetGadgetText(*PG\PGI()\Gadget[0], Text)
          __PropertyGadgetCallbackProcess(*PG\PGI()\Gadget[0], #PB_EventType_Change)
        Case #__PG_ComboBox, #__PG_Password, #__PG_String
          SetGadgetText(*PG\PGI()\Gadget[0], Text)
        Case #__PG_Percent, #__PG_Progress, #__PG_Spin, #__PG_Trackbar
          SetGadgetState(*PG\PGI()\Gadget[0], Val(Trim(Text, "%")))
        Case #__PG_Shortcut, #__PG_Spacer
          ;
        Default
          Debug #PB_Compiler_Procedure + "(): Unhandled Type " + Str(*PG\PGI()\Type)
      EndSelect
    EndIf
  EndIf
EndProcedure

CompilerIf (#False)
Procedure SetPropertyImage(Gadget.i, Index.i, Image.i, ID.s = "")
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    If (ID)
      Index = PropertyIndexFromID(Gadget, ID)
    ElseIf (Index = #Property_Last)
      Index = ListSize(*PG\PGI()) - 1
    EndIf
    If ((Index >= 0) And (Index < ListSize(*PG\PGI())))
      SelectElement(*PG\PGI(), Index)
      With *PG\PGI()
        If (Image <> -1)
          \Gadget[#PropertyChild_Image] = ImageGadget(#PB_Any, 0, 0, __PG_ToggleSize, __PG_ToggleSize, ImageID(Image))
          \Image = Image
          __RecalcPropertyGadget(*PG, #True)
        Else
          If (\Image <> -1)
            FreeGadget(\Gadget[#PropertyChild_Image])
            \Gadget[#PropertyChild_Image] = #Null
            \Image = -1
            __RecalcPropertyGadget(*PG, #True)
          EndIf
        EndIf
      EndWith
    EndIf
  EndIf
EndProcedure
CompilerEndIf

Procedure.i CountPropertyItems(Gadget.i)
  Protected Result.i = -1
  Protected *PG.__PropertyGadget = GetGadgetData(Gadget)
  If (*PG)
    Result = ListSize(*PG\PGI())
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-


Procedure.i AddPropertyHeader(Gadget.i, Name.s, Collapsed.i = #False, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Header, Name, ID, Collapsed, ""))
EndProcedure

Procedure.i AddPropertySpacer(Gadget.i, Height.i = #PB_Default)
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Spacer, "", "", Height, ""))
EndProcedure





Procedure.i AddBrowseProperty(Gadget.i, Name.s, Value.s = "", *Callback = #Null, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Browse, Name, ID, *Callback, Value))
EndProcedure

Procedure.i AddButtonProperty(Gadget.i, Name.s, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Button, Name, ID, #Null, ""))
EndProcedure

Procedure.i AddCheckboxProperty(Gadget.i, Name.s, State.i = #False, CheckedValue.i = #PB_Checkbox_Checked, ID.s = "")
  Protected Result.i = __AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Checkbox, Name, ID, State, "")
  If (Result >= 0)
    SetPropertyExData(Gadget, Result, CheckedValue)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i AddCheckboxLabelProperty(Gadget.i, Name.s, State.i = #False, CheckedValue.i = #PB_Checkbox_Checked, ID.s = "")
  Protected Result.i = __AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_CheckboxLabel, Name, ID, State, "")
  If (Result >= 0)
    SetPropertyExData(Gadget, Result, CheckedValue)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i AddColorProperty(Gadget.i, Name.s, Color.i = $FFFFFF, Flags.i = #Null, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Color, Name, ID, Flags, Str(Color)))
EndProcedure

Procedure.i AddComboBoxProperty(Gadget.i, Name.s, ItemList.s, Editable.i = #False, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_ComboBox, Name, ID, Editable, ItemList))
EndProcedure

Procedure.i AddLabelProperty(Gadget.i, Text.s, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Label, ID, ID, #Null, Text))
EndProcedure

Procedure.i AddPasswordProperty(Gadget.i, Name.s, Value.s = "", ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Password, Name, ID, 0, Value))
EndProcedure

Procedure.i AddPercentProperty(Gadget.i, Name.s, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Percent, Name, ID, 100, ""))
EndProcedure

Procedure.i AddProgressProperty(Gadget.i, Name.s, Max.i = 0, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Progress, Name, ID, Max, ""))
EndProcedure

Procedure.i AddShortcutProperty(Gadget.i, Name.s, Shortcut.i = #Null, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Shortcut, Name, ID, Shortcut, ""))
EndProcedure

Procedure.i AddSpinProperty(Gadget.i, Name.s, Max.i, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Spin, Name, ID, Max, ""))
EndProcedure

Procedure.i AddStringProperty(Gadget.i, Name.s, Value.s = "", ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_String, Name, ID, 0, Value))
EndProcedure

Procedure.i AddTrackbarProperty(Gadget.i, Name.s, Max.i, ID.s = "")
  ProcedureReturn (__AddPropertyGadgetItem(GetGadgetData(Gadget), #__PG_Trackbar, Name, ID, Max, ""))
EndProcedure










;-
;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

#DemoWin  = 5
#DemoPG   = 1
#ChildWin = 2

#Enter      = 0
#Escape     = 1
#CloseChild = 2



Procedure DemoResizeCB() ; Resize window callback
  ResizePropertyGadget(#DemoPG, 0, 0, WindowWidth(#DemoWin), WindowHeight(#DemoWin))
EndProcedure

Procedure DemoCreate() ; Create child window with specified properties
  
  Flags.i = #PB_Window_NoActivate ; NoActivate fixed for demo purposes
  For i = PropertyIndexFromID(#DemoPG, "win.sysMenu") To PropertyIndexFromID(#DemoPG, "win.noActivate")
    Flags | GetPropertyState(#DemoPG, i)
  Next i
  
  OpenWindow(#ChildWin, ; Window Number fixed for demo purposes
    GetPropertyStateByID(#DemoPG, "win.x"),
    GetPropertyStateByID(#DemoPG, "win.y"),
    GetPropertyStateByID(#DemoPG, "win.width"),
    GetPropertyStateByID(#DemoPG, "win.height"),
    GetPropertyTextByID(#DemoPG,  "win.title"),
    Flags,
    WindowID(#DemoWin)) ; Parent window fixed for demo purposes
  
  SetWindowColor(#ChildWin, GetPropertyStateByID(#DemoPG, "win.color"))
  AddKeyboardShortcut(#ChildWin, GetPropertyStateByID(#DemoPG, "win.shortcut"), #CloseChild)
EndProcedure

Procedure.i DemoBrowseCB(PropertyGadget.i, ChildGadget.i, Index.i, ID.s) ; File browse callback
  Changed.i = #False
  File.s = GetGadgetText(ChildGadget)
  If (File = "")
    File = GetHomeDirectory()
  EndIf
  File = OpenFileRequester("Select File", File, "All Files (*.*)|*.*", 0)
  If (File)
    SetGadgetText(ChildGadget, File)
    Changed = #True
  EndIf
  ProcedureReturn (Changed)
EndProcedure

Procedure.i DemoHelpCB(PropertyGadget.i, ChildGadget.i, Index.i, ID.s) ; Help "browse" callback
  MessageRequester("Help", "You clicked: " + ID, #PB_MessageRequester_Info)
EndProcedure





; Create window and PropertyGadget

OpenWindow(#DemoWin, 0, 0, 240, 360, "PropertyGadget",
    #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget | #PB_Window_Invisible)
  AddKeyboardShortcut(#DemoWin, #PB_Shortcut_Return, #Enter)
  AddKeyboardShortcut(#DemoWin, #PB_Shortcut_Escape, #Escape)
  
PropertyGadget(#DemoPG, 0, 0, WindowWidth(#DemoWin), WindowHeight(#DemoWin), #PropertyGadget_Border)
  LockPropertyGadget(#DemoPG, #True) ; Prevent redraws while building gadget
  
  AddPropertyHeader(#DemoPG, "Window")
    AddComboBoxProperty(#DemoPG, "Number:",         "#PB_Any", #True,                  "win.number")
    AddStringProperty(#DemoPG,   "Title:",          "Hello World!",                    "win.title")
    AddStringProperty(#DemoPG,   "Parent:",         "",                                "win.parent")
    AddColorProperty(#DemoPG,    "Color:",          $FFFFDD, #ColorProperty_CSSFormat, "win.color")
    AddShortcutProperty(#DemoPG, "Close Shortcut:", #PB_Shortcut_Back,                 "win.shortcut")
    AddButtonProperty(#DemoPG,   "Create Window",                                      "win.create")
    
  AddPropertyHeader(#DemoPG, "Dimensions")
    AddStringProperty(#DemoPG, "x:",      "50",  "win.x")
    AddStringProperty(#DemoPG, "y:",      "50",  "win.y")
    AddStringProperty(#DemoPG, "Width:",  "320", "win.width")
    AddStringProperty(#DemoPG, "Height:", "240", "win.height")
    
  AddPropertyHeader(#DemoPG, "Flags", #True)
    AddCheckboxLabelProperty(#DemoPG, "SystemMenu",     #True,  #PB_Window_SystemMenu,     "win.sysMenu")
    AddCheckboxLabelProperty(#DemoPG, "MinimizeGadget", #True,  #PB_Window_MinimizeGadget, "win.minGadget")
    AddCheckboxLabelProperty(#DemoPG, "MaximizeGadget", #False, #PB_Window_MaximizeGadget, "win.maxGadget")
    AddCheckboxLabelProperty(#DemoPG, "SizeGadget",     #True,  #PB_Window_SizeGadget,     "win.sizeGadget")
    AddPropertySpacer(#DemoPG)
    AddCheckboxLabelProperty(#DemoPG, "Invisible",      #False, #PB_Window_Invisible,      "win.invisible")
    AddCheckboxLabelProperty(#DemoPG, "TitleBar",       #False, #PB_Window_TitleBar,       "win.titleBar")
    AddCheckboxLabelProperty(#DemoPG, "Tool",           #False, #PB_Window_Tool,           "win.tool")
    AddCheckboxLabelProperty(#DemoPG, "Borderless",     #False, #PB_Window_BorderLess,     "win.borderless")
    AddCheckboxLabelProperty(#DemoPG, "ScreenCentered", #False, #PB_Window_ScreenCentered, "win.screenCenter")
    AddCheckboxLabelProperty(#DemoPG, "WindowCentered", #False, #PB_Window_WindowCentered, "win.windowCenter")
    AddPropertySpacer(#DemoPG)
    AddCheckboxLabelProperty(#DemoPG, "Maximize",       #False, #PB_Window_Maximize,       "win.maximize")
    AddCheckboxLabelProperty(#DemoPG, "Minimize",       #False, #PB_Window_Minimize,       "win.minimize")
    AddCheckboxLabelProperty(#DemoPG, "NoGadgets",      #False, #PB_Window_NoGadgets,      "win.noGadgets")
    AddCheckboxLabelProperty(#DemoPG, "NoActivate",     #False, #PB_Window_NoActivate,     "win.noActivate")
    
  AddPropertyHeader(#DemoPG, "Miscellaneous")
    AddCheckboxProperty(#DemoPG, "Checkbox:", #False, #True,                            "misc.checkbox")
    AddPasswordProperty(#DemoPG, "Password:", "Hello World!",                           "misc.password")
    AddComboBoxProperty(#DemoPG, "ComboBox:", "Option A | Option B | Option C", #False, "misc.combobox")
    AddTrackbarProperty(#DemoPG, "Trackbar:", 3,                                        "misc.trackbar")
    AddPercentProperty(#DemoPG,  "Percent:",                                            "misc.percent")
    AddSpinProperty(#DemoPG,     "Spin:",     9,                                        "misc.spin")
    AddBrowseProperty(#DemoPG,   "File:",     "", @DemoBrowseCB(),                      "misc.browseFile")
    AddBrowseProperty(#DemoPG,   "Help:",     "", @DemoHelpCB(),                        "misc.browseHelp")
      SetGadgetText(GetPropertyChild(#DemoPG, 0, "misc.browseHelp", 2), "?")
    AddProgressProperty(#DemoPG, "Progress:", 100,                                      "misc.progress")
      SetPropertyStateByID(#DemoPG, "misc.progress", 75)
    AddLabelProperty(#DemoPG,    "This is just a label!",                               "misc.label")
    AddPropertySpacer(#DemoPG)
    AddButtonProperty(#DemoPG,   "Quit This Demo",                                      "misc.quit")
    
  LockPropertyGadget(#DemoPG, #False)
BindEvent(#PB_Event_SizeWindow, @DemoResizeCB(), #DemoWin)
HideWindow(#DemoWin, #False)






Repeat
  Event = WaitWindowEvent()
  
  If (Event = #PB_Event_CloseWindow)
    If (EventWindow() = #DemoWin)
      Break
    Else
      CloseWindow(EventWindow())
    EndIf
    
  ElseIf (Event = #PB_Event_Menu)
    If (EventMenu() = #Enter)
      DemoCreate()
    ElseIf (EventMenu() = #Escape)
      Break
    ElseIf (EventMenu() = #CloseChild)
      CloseWindow(EventWindow())
    EndIf
    
  ElseIf (Event = #PB_Event_Gadget)
    If ((EventGadget() = #DemoPG) And (EventType() = #PB_EventType_Change))
      If (MatchProperty(#DemoPG, EventProperty(), "win.create"))
        DemoCreate()
      ElseIf (MatchProperty(#DemoPG, EventProperty(), "misc.quit"))
        Break
      Else
        Debug "Event: " + PropertyIDFromIndex(#DemoPG, EventData(), #True) +
            " = " + GetPropertyText(#DemoPG, EventData())
      EndIf
    EndIf
    
  EndIf
ForEver
FreePropertyGadget(#DemoPG)

CompilerEndIf
CompilerEndIf
;-