; +-----------+
; | MemGadget |
; +-----------+
; | 2018-02-06 . Creation (PureBasic 5.62)
; | 2018-02-07 . Started header, margin, scrollbars
; | 2018-02-08 . System colors/metrics, preview pane, absolute margin
; | 2018-02-09 . Added cell / row selection, copy/delete/cut, navigation
; | 2018-02-12 . Fixed row-drag selection, added column-dragging,
; |                started PCell selection, text editing, paste,
; |                fixed horizontal scrollbar max bug, keyboard nav
; | 2018-04-13 . Cmd-Left/Right now act like Home/End, implemented Backspace

; TODO
; optimize (don't redraw whole grid, only changes!)
; buffered editing (instead of editing memory in-place)
; streaming (from file? don't require entire content in memory)
; right-click menu (copy, paste, etc?)
; undo/redo ?
;
; BUGS
; jumpy scrollbars

;-
CompilerIf (Not Defined(_MemGadget_Included, #PB_Constant))
#_MemGadget_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Constants (Public)

#MemGadget_IncludeVersion = 20180212

Enumeration ; MemGadget Flags
  #MemGadget_NoHeader   = $01
  #MemGadget_NoMargin   = $02
  #MemGadget_NoPreview  = $04
  #MemGadget_Editable   = $08
  #MemGadget_Borderless = $10
  #MemGadget_Relative   = $20
EndEnumeration





;-
;- Constants (Private)

#_MemGadget_DefaultColumns  =  16
#_MemGadget_DefaultBorder   =   1
#_MemGadget_DefaultFontName = "Courier New"
#_MemGadget_DefaultFontSize =  10

Enumeration
  #_MemGadget_Locked   = $010000
  #_MemGadget_Dragging = $020000
  #_MemGadget_HasHBar  = $040000
  #_MemGadget_HasVBar  = $080000
EndEnumeration

Enumeration ; Click/Sel Types
  #_MemGadget_None
  #_MemGadget_Cell
  #_MemGadget_PCell
  #_MemGadget_Column
  #_MemGadget_Row
EndEnumeration

#_MemGadget_Windows = Bool(#PB_Compiler_OS = #PB_OS_Windows)

CompilerIf (Not Defined(_MemGadget_DrawTextAPI, #PB_Constant))
  #_MemGadget_DrawTextAPI = #True
CompilerEndIf











;-
;- Structures (Private)

Structure _MemGadgetAscii
  a.a[0]
EndStructure

Structure _MemGadgetCharacter
  c.c[0]
EndStructure

Structure _MemGadgetGlobal
  DefaultFontID.i
  ScrollSize.i
  CompilerIf (#_MemGadget_Windows)
    ContainerProc.i
  CompilerEndIf
EndStructure

Structure _MemGadget
  Container.i
  Canvas.i
  HScroll.i
  VScroll.i
  Flags.i
  CompilerIf (#_MemGadget_Windows)
    Dummy.i
  CompilerEndIf
  ;
  ColorBack.i
  ColorText.i
  ColorMargin.i
  ColorMarginText.i
  ColorSel.i
  ColorSelText.i
  ColorSelFade.i
  ;
  *Buffer._MemGadgetAscii
  BufferSize.i
  DispOffset.i
  ;
  Rows.i
  Columns.i
  ;
  FontID.i
  CharW.i
  CharH.i
  CellW.i
  CellH.i
  ;
  PCellW.i
  PCellH.i
  PreviewW.i
  ;
  Border.i
  HeaderH.i
  MarginW.i
  ;
  CanvasW.i
  CanvasH.i
  ScrollW.i
  ScrollH.i
  ViewW.i
  ViewH.i
  ScrollRows.i
  ScrollPixels.i
  ViewR.i
  ViewX.i
  ;
  ClickType.i
  ClickIndex.i
  ;
  HoverType.i
  HoverIndex.i
  ;
  AnchorType.i
  AnchorIndex.i
  CursorType.i
  CursorIndex.i
  ;
  SelType.i
  SelFirst.i
  SelLast.i
  ;
  mx.i
  my.i
  LastClick.i
  HexInput.s
  Overwrote.i
  ;
  DC.i
EndStructure






;-
;- Variables (Private)

Global _MemGadget._MemGadgetGlobal






;-
;- Macros (Private)

CompilerIf (#_MemGadget_Windows And #_MemGadget_DrawTextAPI)
  Macro _MemGadgetDrawText(x, y, Text, FrontColor, BackColor)
    DrawR\left = (x)
    DrawR\top  = (y)
    SetTextColor_(*MG\DC, (FrontColor))
    SetBkColor_(*MG\DC, (BackColor))
    DrawText_(*MG\DC, @Text, -1, @DrawR, 0)
  EndMacro
CompilerElse
  Macro _MemGadgetDrawText(x, y, Text, FrontColor, BackColor)
    DrawText((x), (y), Text, (FrontColor), (BackColor))
  EndMacro
CompilerEndIf







;-
;- Procedures (Private)

Procedure.i _MemGadgetLimit(Value.i, Min.i, Max.i)
  If (Value < Min)
    Value = Min
  ElseIf (Value > Max)
    Value = Max
  EndIf
  ProcedureReturn (Value)
EndProcedure

Procedure.i _MemGadgetLimitIndex(*MG._MemGadget, Index.i)
  ProcedureReturn (_MemGadgetLimit(Index, 0, *MG\BufferSize - 1))
EndProcedure

Procedure.i _MemGadgetIndexByRC(*MG._MemGadget, Row.i, Column.i)
  ProcedureReturn (Column + *MG\Columns * Row - *MG\DispOffset)
EndProcedure

Procedure.i _MemGadgetRowByIndex(*MG._MemGadget, Index.i)
  ProcedureReturn ((Index + *MG\DispOffset) / *MG\Columns)
EndProcedure

Procedure.i _MemGadgetColumnByIndex(*MG._MemGadget, Index.i)
  ProcedureReturn ((Index + *MG\DispOffset) % *MG\Columns)
EndProcedure

Procedure _MemGadgetShift(*MG._MemGadget)
  ProcedureReturn (Bool(GetGadgetAttribute(*MG\Canvas, #PB_Canvas_Modifiers) & #PB_Canvas_Shift))
EndProcedure

Procedure _MemGadgetCommand(*MG._MemGadget)
  CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
    ProcedureReturn (Bool(GetGadgetAttribute(*MG\Canvas, #PB_Canvas_Modifiers) & #PB_Canvas_Command))
  CompilerElse
    ProcedureReturn (Bool(GetGadgetAttribute(*MG\Canvas, #PB_Canvas_Modifiers) & #PB_Canvas_Control))
  CompilerEndIf
EndProcedure

Procedure _MemGadgetRedraw(*MG._MemGadget)
  If (*MG And (Not (*MG\Flags & #_MemGadget_Locked)))
    With *MG
      ;DisableDebugger
      \DC = StartDrawing(CanvasOutput(\Canvas))
      If (\DC)
        Box(0, 0, OutputWidth(), OutputHeight(), \ColorBack)
        If (\Buffer)
          If (\FontID)
            Protected r.i, c.i, i.i, dx.i, dy.i, St.s
            Protected ox.i, oy.i
            Protected Fore.i, Back.i
            
            DrawingFont(\FontID)
            CompilerIf (#_MemGadget_Windows And #_MemGadget_DrawTextAPI)
              Protected DrawR.RECT
              DrawR\right  = OutputWidth()
              DrawR\bottom = OutputHeight()
              SelectObject_(\DC, \FontID)
            CompilerEndIf
            
            ; Draw Byte Grid
            ox = \MarginW - \ViewX
            oy = \HeaderH
            r = 0 : c = 0
            i = \ViewR * \Columns - \DispOffset
            While (i < \BufferSize)
              If (i >= 0)
                dx = ox + c * \CellW
                dy = oy + r * \CellH
                If (dy >= \CanvasH)
                  Break
                EndIf
                St = Hex(\Buffer\a[i])
                If (Len(St) < 2)
                  St = "0" + St
                EndIf
                If ((\CursorType = #_MemGadget_Cell) And (\CursorIndex = i))
                  Fore = \ColorBack
                  Back = \ColorText
                ElseIf ((\SelType = #_MemGadget_Cell) And (i >= \SelFirst) And (i <= \SelLast))
                  Fore = \ColorSelText
                  Back = \ColorSel
                ElseIf ((\SelType = #_MemGadget_PCell) And (i >= \SelFirst) And (i <= \SelLast))
                  Fore = \ColorText
                  Back = \ColorSelFade
                Else
                  Fore = \ColorText
                  Back = \ColorBack
                EndIf
                If (Back <> \ColorBack)
                  Box(dx, dy, \CellW, \CellH, Back)
                EndIf
                _MemGadgetDrawText(dx + (\CellW - TextWidth(St))/2, dy, St, Fore, Back)
              EndIf
              c + 1
              If (c = \Columns)
                c = 0
                r + 1
              EndIf
              i + 1
            Wend
            
            ; Draw Preview Grid
            If (Not (\Flags & #MemGadget_NoPreview))
              ox = \MarginW - \ViewX + (\ScrollW - \PreviewW) + \Border
              oy = \HeaderH
              r = 0 : c = 0
              i = \ViewR * \Columns - \DispOffset
              While (i < \BufferSize)
                If (i >= 0)
                  dx = ox + c * \PCellW
                  dy = oy + r * \PCellH
                  If (dy >= \CanvasH)
                    Break
                  EndIf
                  Select (\Buffer\a[i])
                    Case #CR, #LF, #TAB
                      St = Chr($B7);" "
                    Case $00 To $1F
                      St = "."
                    Default
                      St = Chr(\Buffer\a[i])
                  EndSelect
                  If ((\CursorType = #_MemGadget_PCell) And (\CursorIndex = i))
                    Fore = \ColorBack
                    Back = \ColorText
                  ElseIf ((\SelType = #_MemGadget_PCell) And (i >= \SelFirst) And (i <= \SelLast))
                    Fore = \ColorSelText
                    Back = \ColorSel
                  ElseIf ((\SelType = #_MemGadget_Cell) And (i >= \SelFirst) And (i <= \SelLast))
                    Fore = #Blue
                    Back = \ColorSelFade
                  Else
                    Fore = #Blue;\ColorText
                    Back = \ColorBack
                  EndIf
                  If (Back <> \ColorBack)
                    Box(dx, dy, \PCellW, \PCellH, \ColorSel)
                  EndIf
                  _MemGadgetDrawText(dx + (\PCellW - TextWidth(St))/2, dy, St, Fore, Back)
                EndIf
                c + 1
                If (c = \Columns)
                  c = 0
                  r + 1
                EndIf
                i + 1
              Wend
              Box(ox - \Border, oy, \Border, \ViewH, \ColorMarginText)
            EndIf
            
            ; Draw Header
            If (Not (\Flags & #MemGadget_NoHeader))
              ox = \MarginW
              Box(0, 0, \CanvasW, \HeaderH, \ColorMargin)
              Box(0, \HeaderH - \Border, \CanvasW, \Border, \ColorMarginText)
              dy = 0
              c = 0
              While (c < \Columns)
                dx = ox + (c + 0.5) * \CellW - \ViewX
                St = Hex(c)
                If (Len(St) < 2)
                  St = "0" + St
                EndIf
                _MemGadgetDrawText(dx - TextWidth(St)/2, dy, St, \ColorMarginText, \ColorMargin)
                c + 1
              Wend
            EndIf
            
            ; Draw Margin
            If (Not (\Flags & #MemGadget_NoMargin))
              oy = \HeaderH
              Box(0, 0, \MarginW, \CanvasH, \ColorMargin)
              Box(\MarginW - \Border, 0, \Border, \CanvasH, \ColorMarginText)
              If (Not (\Flags & #MemGadget_NoHeader))
                Box(0, \HeaderH - \Border, \MarginW, \Border, \ColorMarginText)
              EndIf
              dx = \MarginW / 2
              r = 0
              While (r + \ViewR < \Rows)
                dy = oy + r * \CellH
                If (dy < OutputHeight())
                  If (\Flags & #MemGadget_Relative)
                    St = Hex((r + \ViewR) * \Columns)
                    If (Len(St) < 2)
                      St = "0" + St
                    EndIf
                  Else
                    St = Hex((\Buffer - \DispOffset) + (r + \ViewR) * \Columns)
                  EndIf
                  _MemGadgetDrawText(dx - TextWidth(St)/2, dy, St, \ColorMarginText, \ColorMargin)
                Else
                  Break
                EndIf
                r + 1
              Wend
            EndIf
            
          EndIf
        Else
          If (#False)
            LineXY(0, OutputHeight()-1, OutputWidth()-1, 0, #Red)
            LineXY(0, 0, OutputWidth()-1, OutputHeight()-1, #Red)
          EndIf
        EndIf
        StopDrawing()
      EndIf
      ;EnableDebugger
    EndWith
  EndIf
EndProcedure

Procedure _MemGadgetUpdate(*MG._MemGadget, Redraw.i)
  If (*MG And (Not (*MG\Flags & #_MemGadget_Locked)))
    With *MG
      CompilerIf (#_MemGadget_Windows And #_MemGadget_DrawTextAPI)
        Protected Client.RECT
        GetClientRect_(GadgetID(\Container), @Client)
        \CanvasW = (Client\right - Client\left)
        \CanvasH = (Client\bottom - Client\top)
      CompilerElse
        \CanvasW = GadgetWidth(\Container) - 8
        \CanvasH = GadgetHeight(\Container) - 8
      CompilerEndIf
      
      If (\Columns < 1)
        \Columns = #_MemGadget_DefaultColumns
      EndIf
      \Rows = 1 + Int((\BufferSize + \DispOffset) / \Columns)
      
      If (\Border < 0)
        \Border = #_MemGadget_DefaultBorder
      EndIf
      If (\Flags & #MemGadget_NoHeader)
        \HeaderH = 0
      Else
        \HeaderH = \CharH + \Border
      EndIf
      If (\Flags & #MemGadget_NoMargin)
        \MarginW = 0
      ElseIf (\Flags & #MemGadget_Relative)
        \MarginW = \CharW * 5 + \Border
      Else
        \MarginW = \CharW * 8 + \Border
      EndIf
      If (\Flags & #MemGadget_NoPreview)
        \PreviewW = 0
      Else
        \PreviewW = \Columns * \PCellW + \Border
      EndIf
      
      \ViewW   = \CanvasW - \MarginW
      \ViewH   = \CanvasH - \HeaderH
      \ScrollW = \Columns * \CellW + \PreviewW
      \ScrollH = \Rows    * \CellH
      
      Protected NeedH.i, NeedV.i, Changed.i
      Repeat
        Changed = #False
        If (\ScrollW > \ViewW)
          If (Not NeedH)
            NeedH = #True
            \CanvasH - _MemGadget\ScrollSize
            \ViewH   - _MemGadget\ScrollSize
            Changed = #True
          EndIf
        EndIf
        If (\ScrollH > \ViewH)
          If (Not NeedV)
            NeedV = #True
            \CanvasW - _MemGadget\ScrollSize
            \ViewW   - _MemGadget\ScrollSize
            Changed = #True
          EndIf
        EndIf
      Until ((NeedH And NeedV) Or (Not Changed))
      
      \ScrollRows = \Rows - (\ViewH / \CellH)
      If (\ScrollRows <= 0)
        \ScrollRows = 0
        \ViewR      = 0
      ElseIf (\ViewR > \ScrollRows)
        \ViewR = \ScrollRows
      EndIf
      ;Debug \ScrollRows
      
      \ScrollPixels = \ScrollW - \ViewW
      If (\ScrollPixels < 0)
        \ScrollPixels = 0
        \ViewX = 0
      ElseIf (\ViewX > \ScrollPixels)
        \ViewX = \ScrollPixels
      EndIf
      
      If (Redraw)
        If (NeedH)
          If (\Flags & #_MemGadget_HasHBar)
            ResizeGadget(\HScroll, 0, \CanvasH, \CanvasW, _MemGadget\ScrollSize)
            SetGadgetAttribute(\HScroll, #PB_ScrollBar_Maximum, \ScrollPixels)
          Else
            ;Debug "Show H"
            ResizeGadget(\HScroll, 0, \CanvasH, \CanvasW, _MemGadget\ScrollSize)
            SetGadgetAttribute(\HScroll, #PB_ScrollBar_Maximum, \ScrollPixels)
            HideGadget(\HScroll, #False)
            \Flags | #_MemGadget_HasHBar
          EndIf
        ElseIf (\Flags & #_MemGadget_HasHBar)
          ;Debug "Hide H"
          HideGadget(\HScroll, #True)
          \Flags & (~#_MemGadget_HasHBar)
        EndIf
        If (NeedV)
          If (\Flags & #_MemGadget_HasVBar)
            ResizeGadget(\VScroll, \CanvasW, 0, _MemGadget\ScrollSize, \CanvasH)
            SetGadgetAttribute(\VScroll, #PB_ScrollBar_Maximum, \ScrollRows)
          Else
            ;Debug "Show V"
            ResizeGadget(\VScroll, \CanvasW, 0, _MemGadget\ScrollSize, \CanvasH)
            SetGadgetAttribute(\VScroll, #PB_ScrollBar_Maximum, \ScrollRows)
            HideGadget(\VScroll, #False)
            \Flags | #_MemGadget_HasVBar
          EndIf
        ElseIf (\Flags & #_MemGadget_HasVBar)
          ;Debug "Hide V"
          HideGadget(\VScroll, #True)
          \Flags & (~#_MemGadget_HasVBar)
        EndIf
        If ((\CanvasW <> GadgetWidth(\Canvas)) Or (\CanvasH <> GadgetHeight(\Canvas)))
          ResizeGadget(\Canvas, 0, 0, \CanvasW, \CanvasH)
        EndIf
        CompilerIf (#_MemGadget_Windows)
          If (NeedH And NeedV)
            ResizeGadget(\Dummy, \CanvasW, \CanvasH, _MemGadget\ScrollSize, _MemGadget\ScrollSize)
            HideGadget(\Dummy, #False)
          Else
            HideGadget(\Dummy, #True)
          EndIf
        CompilerEndIf
        _MemGadgetRedraw(*MG)
      EndIf
    EndWith
  EndIf
EndProcedure

Procedure _MemGadgetScrollX(*MG._MemGadget, x.i)
  *MG\ViewX = _MemGadgetLimit(x, 0, *MG\ScrollPixels)
  SetGadgetState(*MG\HScroll, *MG\ViewX)
EndProcedure

Procedure _MemGadgetScrollR(*MG._MemGadget, Row.i)
  *MG\ViewR = Row
  SetGadgetState(*MG\VScroll, *MG\ViewR)
EndProcedure

Procedure _MemGadgetSelect(*MG._MemGadget, Index.i, Extend.i = #False, Preview.i = #False)
  With *MG
    \HexInput = ""
    If (\Buffer)
      Index = _MemGadgetLimitIndex(*MG, Index)
      If (Preview)
        \CursorType = #_MemGadget_PCell
      Else
        \CursorType = #_MemGadget_Cell
      EndIf
      \CursorIndex = Index
      If ((Not Extend) Or (\AnchorType <> \CursorType))
        \AnchorType  = \CursorType
        \AnchorIndex = \CursorIndex
      EndIf
      \SelType  = \CursorType
      \SelFirst = \CursorIndex
      \SelLast  = \AnchorIndex
      If (\SelFirst > \SelLast)
        Swap \SelFirst, \SelLast
      EndIf
      Protected r.i = _MemGadgetRowByIndex(*MG, \CursorIndex)
      If (r < \ViewR)
        _MemGadgetScrollR(*MG, r)
      ElseIf (((r - \ViewR) * \CellH) + (\CellH - 1) >= \ViewH)
        _MemGadgetScrollR(*MG, r - (\ViewH / \CellH) + 1)
      EndIf
      _MemGadgetRedraw(*MG)
    EndIf
  EndWith
EndProcedure

Procedure _MemGadgetSelectRow(*MG._MemGadget, Row.i, Extend.i = #False)
  With *MG
    If (\Buffer)
      If (Extend)
        \CursorType  = #_MemGadget_Cell
        \CursorIndex = _MemGadgetLimitIndex(*MG, _MemGadgetIndexByRC(*MG, Row, 0))
        \SelFirst = \CursorIndex
        \SelLast  = \AnchorIndex
        If (\SelFirst > \SelLast)
          Swap \SelFirst, \SelLast
        EndIf
        \SelFirst = _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \SelFirst), 0)
        \SelLast  = _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \SelLast), \Columns - 1)
        \SelFirst = _MemGadgetLimitIndex(*MG, \SelFirst)
        \SelLast  = _MemGadgetLimitIndex(*MG, \SelLast)
        _MemGadgetRedraw(*MG)
      Else
        \AnchorType  = #_MemGadget_Cell
        \AnchorIndex = _MemGadgetLimit(_MemGadgetIndexByRC(*MG, Row, \Columns - 1),
            0, \BufferSize - 1)
        _MemGadgetSelect(*MG, _MemGadgetIndexByRC(*MG, Row, 0), #True)
      EndIf
    EndIf
  EndWith
EndProcedure

Procedure _MemGadgetCopy(*MG._MemGadget)
  With *MG
    If (\Buffer)
      If ((\SelFirst >= 0) And (\SelLast >= \SelFirst))
        Protected n.i = 1 + (\SelLast - \SelFirst)
        
        If (\SelType = #_MemGadget_Cell)
          Protected Output.s = Space(n * 3 - 1)
          Protected *C._MemGadgetCharacter = @Output
          
          Protected HexSt.s = "0123456789ABCDEF"
          Protected *H._MemGadgetCharacter = @HexSt
          
          Protected i.i
          For i = 0 To n-1
            *C\c[i * 3    ] = *H\c[ (\Buffer\a[i + \SelFirst] >> 4) & $0F]
            *C\c[i * 3 + 1] = *H\c[ (\Buffer\a[i + \SelFirst]     ) & $0F]
          Next i
          SetClipboardText(Output)
          
        ElseIf (\SelType = #_MemGadget_PCell)
          Output = PeekS(\Buffer + \SelFirst, n, #PB_UTF8 | #PB_ByteLength)
          SetClipboardText(Output)
        EndIf
        
      EndIf
    EndIf
  EndWith
EndProcedure

Procedure _MemGadgetPaste(*MG._MemGadget)
  With *MG
    If (\Flags & #MemGadget_Editable)
      If ((\CursorIndex >= 0) And (\CursorIndex < \BufferSize))
        Protected Pasted.i = 0
        Protected St.s, St2.s
        Protected *C.CHARACTER
        Protected i.i, n.i, j.i
        If (\CursorType = #_MemGadget_Cell)
          St = GetClipboardText()
          n = 1 + CountString(St, " ")
          i = \SelFirst
          For j = 1 To n
            St2 = StringField(St, j, " ")
            If (Len(St2) = 2)
              \Buffer\a[i] = Val("$" + St2)
              Pasted + 1
              i + 1
              If (i >= \BufferSize)
                Break
              EndIf
            EndIf
          Next j
          _MemGadgetRedraw(*MG)
          
        ElseIf (\CursorType = #_MemGadget_PCell)
          St = GetClipboardText()
          *C = @St
          i = \SelFirst
          While ((*C\c) And (i < \BufferSize))
            \Buffer\a[i] = *C\c
            Pasted + 1
            *C + SizeOf(CHARACTER)
            i + 1
          Wend
          _MemGadgetRedraw(*MG)
        EndIf
      EndIf
    EndIf
  EndWith
EndProcedure

Procedure _MemGadgetDelete(*MG._MemGadget)
  With *MG
    If (\Flags & #MemGadget_Editable)
      If (\Buffer)
        If ((\SelFirst >= 0) And (\SelLast >= \SelFirst))
          Protected i.i
          For i = \SelFirst To \SelLast
            \Buffer\a[i] = $00
          Next i
          _MemGadgetRedraw(*MG)
        EndIf
      EndIf
    EndIf
  EndWith
EndProcedure

Procedure _MemGadgetResize(*MG._MemGadget)
  If (*MG)
    _MemGadgetUpdate(*MG, #True)
  EndIf
EndProcedure

Procedure _MemGadgetResizeCB()
  _MemGadgetResize(GetGadgetData(EventGadget()))
EndProcedure

Procedure _MemGadgetScroll(*MG._MemGadget, Gadget.i)
  If (*MG)
    With *MG
      If (Gadget = \HScroll)
        \ViewX = GetGadgetState(\HScroll)
      ElseIf (Gadget = \VScroll)
        \ViewR = GetGadgetState(\VScroll)
      EndIf
      _MemGadgetRedraw(*MG)
    EndWith
  EndIf
EndProcedure

Procedure _MemGadgetScrollCB()
  _MemGadgetScroll(GetGadgetData(EventGadget()), EventGadget())
EndProcedure

Procedure.i _MemGadgetHit(*MG._MemGadget, *Type.INTEGER, *Index.INTEGER)
  *Type\i  = #_MemGadget_None
  *Index\i = 0
  Protected r.i, c.i, i.i
  With *MG
    If (\my < -1)
      *Index\i = -1
    ElseIf (\my >= \CanvasH)
      *Index\i = 1
    Else
      If (\mx >= \MarginW)
        If (\my >= \HeaderH)
          If (\PreviewW And (\mx >= \MarginW + (\ScrollW - \PreviewW) + \Border - \ViewX))
            If (\mx < \MarginW + \ScrollW - \ViewX)
              ;Debug "PCell"
              r = (\my - \HeaderH) / \PCellH + \ViewR
              ;Debug r
              c = (\mx - \MarginW - (\ScrollW - \PreviewW) - \Border + \ViewX) / \PCellW
              ;Debug c
              i = _MemGadgetIndexByRC(*MG, r, c)
              If ((i >= 0) And (i < \BufferSize))
                *Type\i  = #_MemGadget_PCell
                *Index\i = i
              ElseIf (i < 0)
                *Index\i = -1
              ElseIf (i >= \BufferSize)
                *Index\i = 1
              EndIf
            EndIf
          ElseIf (\mx - \MarginW + \ViewX < \ScrollW)
            ;Debug "Cell"
            r = (\my - \HeaderH) / \CellH + \ViewR
            ;Debug r
            c = (\mx - \MarginW + \ViewX) / \CellW
            ;Debug c
            i = _MemGadgetIndexByRC(*MG, r, c);c + (r * \Columns) - \DispOffset
            ;Debug i
            If ((i >= 0) And (i < \BufferSize))
              *Type\i  = #_MemGadget_Cell
              *Index\i = i
            ElseIf (i < 0)
              *Index\i = -1
            ElseIf (i >= \BufferSize)
              *Index\i = 1
            EndIf
          EndIf
        Else
          If (\mx - \MarginW + \ViewX < \ScrollW - \PreviewW)
            ;Debug "Header"
            *Type\i  = #_MemGadget_Column
            *Index\i = (\mx - \MarginW + \ViewX) / \CellW
            ;Debug *Index\i
          Else
            *Index\i = -1
          EndIf
        EndIf
      Else
        If (\my >= \HeaderH)
          i = (\my - \HeaderH) / \CellH + \ViewR
          If (i < \Rows)
            ;Debug "Margin"
            *Type\i  = #_MemGadget_Row
            *Index\i = (\my - \HeaderH) / \CellH + \ViewR
          EndIf
        Else
          *Index\i = -1
        EndIf
      EndIf
    EndIf
  EndWith
  ProcedureReturn (*Type\i)
EndProcedure

Procedure _MemGadgetDrag(*MG._MemGadget)
  With *MG
    \mx = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseX)
    \my = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseY)
    _MemGadgetHit(*MG, @\HoverType, @\HoverIndex)
    Select (\ClickType)
    
      Case #_MemGadget_Cell
        If ((\HoverType = #_MemGadget_Cell) Or (\HoverType = #_MemGadget_PCell))
          _MemGadgetSelect(*MG, \HoverIndex, #True, #False)
        ElseIf (\HoverType = #_MemGadget_Row)
          If (\ViewX > 0)
            _MemGadgetScrollX(*MG, \ViewX - \CellW)
          Else
            \CursorType  = #_MemGadget_Cell
            \CursorIndex = \HoverIndex * \Columns - \DispOffset
            If (\CursorIndex > \AnchorIndex)
              \CursorIndex + (\Columns - 1)
            EndIf
            \CursorIndex = _MemGadgetLimitIndex(*MG, \CursorIndex)
            \SelType     = #_MemGadget_Cell
            \SelFirst    = \AnchorIndex
            \SelLast     = \CursorIndex
          EndIf
        ElseIf (\HoverType = #_MemGadget_Column)
          If (\ViewR > 0)
            _MemGadgetScrollR(*MG, \ViewR - 1)
          Else
            \CursorIndex = \HoverIndex - \DispOffset
            If (\CursorIndex < 0)
              \CursorIndex = 0
            EndIf
            If (\CursorIndex >= \BufferSize)
              \CursorIndex = \BufferSize - 1
            EndIf
          EndIf
          \CursorType  = #_MemGadget_Cell
          \SelType     = #_MemGadget_Cell
          \SelFirst    = \AnchorIndex
          \SelLast     = \CursorIndex
        ElseIf (\HoverType = #_MemGadget_None)
          If (\HoverIndex = -1)
            If (\ViewR > 0)
              \ViewR - 1
              SetGadgetState(\VScroll, \ViewR)
            Else
              \CursorIndex = 0
            EndIf
          ElseIf (\HoverIndex = 1)
            If (\ViewR < \ScrollRows)
              \ViewR + 1
              SetGadgetState(\VScroll, \ViewR)
            Else
              \CursorIndex = \BufferSize - 1
            EndIf
          EndIf
          \CursorType  = #_MemGadget_Cell
          \SelType     = #_MemGadget_Cell
          \SelFirst    = \AnchorIndex
          \SelLast     = \CursorIndex
        EndIf
        
      Case #_MemGadget_Row
        If ((\HoverType = #_MemGadget_Row) Or (\HoverType = #_MemGadget_Cell))
          If (\HoverType = #_MemGadget_Cell)
            \HoverType  = #_MemGadget_Row
            \HoverIndex = _MemGadgetRowByIndex(*MG, \HoverIndex)
          EndIf
          _MemGadgetSelectRow(*MG, \HoverIndex, #True)
        ElseIf ((\HoverType = #_MemGadget_Column) Or
            ((\HoverType = #_MemGadget_None) And (\HoverIndex = -1)))
          If (\ViewR > 0)
            _MemGadgetScrollR(*MG, \ViewR - 1)
          Else
            _MemGadgetSelectRow(*MG, 0, #True)
          EndIf
        ElseIf ((\HoverType = #_MemGadget_None) And (\HoverIndex = 1))
          If (\ViewR < \ScrollRows)
            _MemGadgetScrollR(*MG, \ViewR + 1)
          Else
            _MemGadgetSelectRow(*MG, \Rows - 1, #True)
          EndIf
        EndIf
      
      Case #_MemGadget_Column
        If (\HoverType = #_MemGadget_Column)
          _MemGadgetSelect(*MG, _MemGadgetIndexByRC(*MG, \ViewR, \HoverIndex),
              #True, #False)
        ElseIf (\HoverType = #_MemGadget_Cell)
          _MemGadgetSelect(*MG, \HoverIndex, #True, #False)
        ElseIf (\HoverType = #_MemGadget_None)
          If (\HoverIndex = 1)
            If (\ViewR < \ScrollRows)
              _MemGadgetScrollR(*MG, \ViewR + 1)
            Else
              _MemGadgetSelect(*MG, \BufferSize - 1, #True, #False)
            EndIf
          EndIf
        EndIf
        
      Case #_MemGadget_PCell
        If ((\HoverType = #_MemGadget_PCell) Or (\HoverType = #_MemGadget_Cell))
          _MemGadgetSelect(*MG, \HoverIndex, #True, #True)
        ElseIf (\HoverType = #_MemGadget_None)
          If (\HoverIndex = -1)
            If (\ViewR > 0)
              _MemGadgetScrollR(*MG, \ViewR - 1)
            Else
              _MemGadgetSelect(*MG, 0, #True, #True)
            EndIf
          ElseIf (\HoverIndex = 1)
            If (\ViewR < \ScrollRows)
              _MemGadgetScrollR(*MG, \ViewR + 1)
            Else
              _MemGadgetSelect(*MG, \BufferSize - 1, #True, #True)
            EndIf
          EndIf
        EndIf
      
    EndSelect
    If (\SelFirst > \SelLast)
      Swap \SelFirst, \SelLast
    EndIf
    _MemGadgetRedraw(*MG) ;? always ??
  EndWith
EndProcedure

Procedure _MemGadgetCanvas(*MG._MemGadget, Type.i)
  If (*MG)
    With *MG
      Protected i.i
      Select (Type)
      
        Case #PB_EventType_LeftButtonDown
          If (Not (*MG\Flags & #_MemGadget_Dragging))
            If (#False);(((\ClickType = #_MemGadget_Cell) Or (\ClickType = #_MemGadget_PCell)) Or 
                ;((ElapsedMilliseconds() - \LastClick) <= DoubleClickTime()))
              ;Debug "Double click"
              ;_MemGadgetSelectRow(*MG, _MemGadgetRowByIndex(*MG, \ClickIndex), 0)
              ;\LastClick = 0
            Else
              \Flags | #_MemGadget_Dragging
              ;Debug "Click"
              ;\LastClick = ElapsedMilliseconds()
              \mx = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseX)
              \my = GetGadgetAttribute(\Canvas, #PB_Canvas_MouseY)
              Select (_MemGadgetHit(*MG, @\ClickType, @\ClickIndex))
                Case #_MemGadget_Cell
                  _MemGadgetSelect(*MG, \ClickIndex,
                      _MemGadgetShift(*MG), #False)
                Case #_MemGadget_PCell
                  _MemGadgetSelect(*MG, \ClickIndex,
                      _MemGadgetShift(*MG), #True)
                Case #_MemGadget_Row
                  _MemGadgetSelectRow(*MG, \ClickIndex, _MemGadgetShift(*MG))
                Case #_MemGadget_Column
                  _MemGadgetSelect(*MG, _MemGadgetIndexByRC(*MG, \ViewR, \ClickIndex),
                      #False, #False)
                Case #_MemGadget_None
                  If (_MemGadgetShift(*MG))
                    ;
                  Else
                    \SelType     = #_MemGadget_None
                    \CursorType  = #_MemGadget_None
                    \CursorIndex = 0
                  EndIf
              EndSelect
              _MemGadgetDrag(*MG)
            EndIf
          EndIf
        Case #PB_EventType_LeftButtonUp
          If (*MG\Flags & #_MemGadget_Dragging)
            *MG\Flags & (~#_MemGadget_Dragging)
          EndIf
        Case #PB_EventType_MouseMove
          If (*MG\Flags & #_MemGadget_Dragging)
            _MemGadgetDrag(*MG)
          EndIf
        Case #PB_EventType_MouseWheel
          If (\ScrollRows > 0)
            If (GetGadgetAttribute(\Canvas, #PB_Canvas_WheelDelta) > 0)
              If (\ViewR > 0)
                \ViewR - 1 * 3
                If (\ViewR < 0)
                  \ViewR = 0
                EndIf
                SetGadgetState(\VScroll, \ViewR)
                If (\Flags & #_MemGadget_Dragging)
                  _MemGadgetRedraw(*MG)
                  _MemGadgetCanvas(*MG, #PB_EventType_MouseMove)
                Else
                  _MemGadgetRedraw(*MG)
                EndIf
              EndIf
            Else
              If (\ViewR < \ScrollRows)
                \ViewR + 1 * 3
                If (\ViewR > \ScrollRows)
                  \ViewR = \ScrollRows
                EndIf
                SetGadgetState(\VScroll, \ViewR)
                If (\Flags & #_MemGadget_Dragging)
                  _MemGadgetRedraw(*MG)
                  _MemGadgetCanvas(*MG, #PB_EventType_MouseMove)
                Else
                  _MemGadgetRedraw(*MG)
                EndIf
              EndIf
            EndIf
          EndIf
          
        Case #PB_EventType_KeyDown
          Select (GetGadgetAttribute(\Canvas, #PB_Canvas_Key))
            Case #PB_Shortcut_A
              If (_MemGadgetCommand(*MG))
                If (\CursorType = #_MemGadget_PCell)
                  \SelType = #_MemGadget_PCell
                Else
                  \SelType = #_MemGadget_Cell
                EndIf
                \SelFirst = 0
                \SelLast  = \BufferSize - 1
                \AnchorType  = \SelType
                \AnchorIndex = \SelLast
                \CursorType  = \SelType
                \CursorIndex = \SelFirst
                _MemGadgetRedraw(*MG)
              EndIf
            Case #PB_Shortcut_C
              If (_MemGadgetCommand(*MG))
                _MemGadgetCopy(*MG)
              EndIf
            Case #PB_Shortcut_V
              If (_MemGadgetCommand(*MG))
                _MemGadgetPaste(*MG)
              EndIf
            Case #PB_Shortcut_X
              If (_MemGadgetCommand(*MG))
                _MemGadgetCopy(*MG)
                _MemGadgetDelete(*MG)
              EndIf
            Case #PB_Shortcut_Delete
              If (Not _MemGadgetCommand(*MG))
                _MemGadgetDelete(*MG)
              EndIf
            Case #PB_Shortcut_Home
              If (_MemGadgetCommand(*MG))
                _MemGadgetSelect(*MG, 0,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                _MemGadgetSelect(*MG,
                    _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \CursorIndex), 0),
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              EndIf
            Case #PB_Shortcut_End
              If (_MemGadgetCommand(*MG))
                _MemGadgetSelect(*MG, \BufferSize - 1,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                _MemGadgetSelect(*MG,
                    _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \CursorIndex), \Columns - 1),
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              EndIf
            Case #PB_Shortcut_Up
              If (_MemGadgetCommand(*MG))
                i = _MemGadgetIndexByRC(*MG, 0, _MemGadgetColumnByIndex(*MG, \CursorIndex))
                If (i < 0)
                  i + \Columns
                EndIf
                _MemGadgetSelect(*MG, i,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                If (_MemGadgetRowByIndex(*MG, \CursorIndex) > 0)
                  _MemGadgetSelect(*MG, \CursorIndex - \Columns,
                      _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
                EndIf
              EndIf
            Case #PB_Shortcut_Down
              If (_MemGadgetCommand(*MG))
                i = _MemGadgetIndexByRC(*MG, \Rows - 1, _MemGadgetColumnByIndex(*MG, \CursorIndex))
                If (i >= \BufferSize)
                  i - \Columns
                EndIf
                _MemGadgetSelect(*MG, i,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                If (_MemGadgetRowByIndex(*MG, \CursorIndex) < \Rows - 1)
                  _MemGadgetSelect(*MG, \CursorIndex + \Columns,
                      _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
                EndIf
              EndIf
            Case #PB_Shortcut_Left
              If (_MemGadgetCommand(*MG))
                _MemGadgetSelect(*MG,
                    _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \CursorIndex), 0),
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                _MemGadgetSelect(*MG, \CursorIndex - 1,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              EndIf
            Case #PB_Shortcut_Right
              If (_MemGadgetCommand(*MG))
                _MemGadgetSelect(*MG,
                    _MemGadgetIndexByRC(*MG, _MemGadgetRowByIndex(*MG, \CursorIndex), \Columns - 1),
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              Else
                _MemGadgetSelect(*MG, \CursorIndex + 1,
                    _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              EndIf
            Case #PB_Shortcut_PageUp
              _MemGadgetSelect(*MG, \CursorIndex - \Columns * (\ViewH / \CellH),
                  _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
            Case #PB_Shortcut_PageDown
              _MemGadgetSelect(*MG, \CursorIndex + \Columns * (\ViewH / \CellH),
                  _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
            Case #PB_Shortcut_Back
              If ((\CursorType = #_MemGadget_Cell) And (Len(\HexInput) = 1))
                \Buffer\a[\CursorIndex] = \Overwrote;$00
                \HexInput = ""
                _MemGadgetRedraw(*MG)
              Else
                _MemGadgetSelect(*MG, \CursorIndex - 1,
                      _MemGadgetShift(*MG), Bool(\CursorType = #_MemGadget_PCell))
              EndIf
            Case #PB_Shortcut_Return
              _MemGadgetSelect(*MG, \CursorIndex + \Columns * (1 - 2*_MemGadgetShift(*MG)),
                  #False, Bool(\CursorType = #_MemGadget_PCell))
            Case #PB_Shortcut_Tab
              If (_MemGadgetCommand(*MG))
                If (\CursorType = #_MemGadget_Cell)
                  \CursorType = #_MemGadget_PCell
                ElseIf (\CursorType = #_MemGadget_PCell)
                  \CursorType = #_MemGadget_Cell
                EndIf
                \AnchorType = \CursorType
                \SelType    = \CursorType
                _MemGadgetRedraw(*MG)
              Else
                _MemGadgetSelect(*MG, \CursorIndex + 1 - 2*_MemGadgetShift(*MG),
                    #False, Bool(\CursorType = #_MemGadget_PCell))
              EndIf
          EndSelect
        Case #PB_EventType_Input
          If (\Flags & #MemGadget_Editable)
            i = GetGadgetAttribute(\Canvas, #PB_Canvas_Input)
            If (i)
              ;Debug Chr(i)
              If (\CursorType = #_MemGadget_PCell)
                \Buffer\a[\CursorIndex] = i
                _MemGadgetSelect(*MG, \CursorIndex + 1, #False, #True)
              ElseIf (\CursorType = #_MemGadget_Cell)
                Select (i)
                  Case '0' To '9', 'a' To 'f', 'A' To 'F'
                    If (\HexInput)
                      \HexInput = \HexInput + Chr(i)
                      \Buffer\a[\CursorIndex] = Val("$" + \HexInput)
                      _MemGadgetSelect(*MG, \CursorIndex + 1, #False, #False)
                      \HexInput = ""
                    Else
                      \HexInput = Chr(i)
                      \Overwrote = \Buffer\a[\CursorIndex]
                      \Buffer\a[\CursorIndex] = Val("$" + \HexInput)
                      _MemGadgetRedraw(*MG)
                    EndIf
                EndSelect
              EndIf
            EndIf
          EndIf
          
      EndSelect
    EndWith
  EndIf
EndProcedure

Procedure _MemGadgetCanvasCB()
  _MemGadgetCanvas(GetGadgetData(EventGadget()), EventType())
EndProcedure

Procedure.i _DisplayMemGadgetCB()
  ResizeGadget(GetWindowData(EventWindow()), 0, 0,
      WindowWidth(EventWindow()), WindowHeight(EventWindow()))
EndProcedure

CompilerIf (#_MemGadget_Windows)
  Procedure.i _MemGadgetContainerProc(hWnd.i, uMsg.i, wParam.i, lParam.i)
    If ((uMsg = #WM_ERASEBKGND) Or (uMsg = #WM_NCPAINT))
      ;Debug "Prevented flicker"
      ProcedureReturn (#Null)
    Else
      If (uMsg = #WM_SETFOCUS)
        Protected *MG._MemGadget = GetWindowLongPtr_(hWnd, #GWLP_USERDATA)
        SetActiveGadget(*MG\Canvas)
      EndIf
      ProcedureReturn (CallWindowProc_(_MemGadget\ContainerProc, hWnd, uMsg, wParam, lParam))
    EndIf
  EndProcedure
CompilerEndIf









;-
;- Procedures (Public)

Procedure.i SetMemGadgetBuffer(Gadget.i, *Buffer, BufferSize.i)
  Protected Result.i = #False
  Protected *MG._MemGadget = GetGadgetData(Gadget)
  If (*MG)
    With *MG
      If (*Buffer And (BufferSize > 0))
        \Buffer     = *Buffer
        \BufferSize =  BufferSize
        If (\Flags & #MemGadget_Relative)
          \DispOffset = 0
        Else
          \DispOffset = (*Buffer % \Columns)
          ;Debug \DispOffset
        EndIf
        _MemGadgetUpdate(*MG, #True)
        Result      = #True
      EndIf
    EndWith
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ClearMemGadgetBuffer(Gadget.i)
  Protected Result.i = #False
  Protected *MG._MemGadget = GetGadgetData(Gadget)
  If (*MG)
    With *MG
      \Buffer     = #Null
      \BufferSize =  0
      \SelType    = #_MemGadget_None
      \ClickType  = #_MemGadget_None
      \HexInput   = ""
      _MemGadgetUpdate(*MG, #True)
      Result      = #True
    EndWith
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SetMemGadgetFontID(Gadget.i, FontID.i)
  Protected *MG._MemGadget = GetGadgetData(Gadget)
  If (*MG)
    With *MG
      If (FontID = #PB_Default)
        FontID = _MemGadget\DefaultFontID
      EndIf
      \FontID = FontID
      If (\FontID)
        If (StartDrawing(CanvasOutput(\Canvas)))
          DrawingFont(\FontID)
          \CharW  = TextWidth("0")
          \CharH  = TextHeight("0")
          \CellW  = \CharW * 3
          \CellH  = \CharH
          \PCellW = TextWidth("W")
          \PCellH = TextHeight("W")
          StopDrawing()
          _MemGadgetUpdate(*MG, #True)
        EndIf
      EndIf
    EndWith
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i FreeMemGadget(Gadget.i)
  Protected *MG._MemGadget = GetGadgetData(Gadget)
  If (*MG)
    With *MG
      UnbindGadgetEvent(\Container, @_MemGadgetResizeCB())
      If (\Canvas)
        FreeGadget(\Canvas)
      EndIf
      If (\HScroll)
        FreeGadget(\HScroll)
      EndIf
      If (\VScroll)
        FreeGadget(\VScroll)
      EndIf
      If (\Dummy)
        FreeGadget(\Dummy)
      EndIf
    EndWith
    ClearStructure(*MG, _MemGadget)
    FreeMemory(*MG)
  EndIf
  FreeGadget(Gadget)
  ProcedureReturn (#Null)
EndProcedure

Procedure.i MemGadget(Gadget.i, x.i, y.i, Width.i, Height.i, Flags.i = #Null, *Buffer = #Null, BufferSize.i = 0)
  Protected Result.i = ContainerGadget(Gadget, x, y, Width, Height,
      #PB_Container_Double * Bool(Not (Flags & #MemGadget_Borderless)))
  If (Result)
    If (Gadget = #PB_Any)
      Gadget = Result
    EndIf
    Protected *MG._MemGadget = AllocateMemory(SizeOf(_MemGadget))
    If (*MG)
      With *MG
        \Container = Gadget
        \Canvas    = CanvasGadget(#PB_Any, 0, 0, 10, 10, #PB_Canvas_Keyboard)
        \Flags     = (Flags & $FFFF) | #_MemGadget_Locked
        ;
        \HScroll = ScrollBarGadget(#PB_Any, 0, 0, 50, 50, 0, 1, 1, #Null)
        \VScroll = ScrollBarGadget(#PB_Any, 0, 0, 50, 50, 0, 1, 1, #PB_ScrollBar_Vertical)
        HideGadget(\HScroll, #True)
        HideGadget(\VScroll, #True)
        ;
        CompilerIf (#_MemGadget_Windows)
          \Dummy = TextGadget(#PB_Any, 0, 0, 50, 50, "")
          HideGadget(\Dummy, #True)
        CompilerEndIf
        ;
        CompilerIf (#_MemGadget_Windows)
          \ColorBack = GetSysColor_(#COLOR_WINDOW)
          \ColorText = GetSysColor_(#COLOR_WINDOWTEXT)
          \ColorMargin = GetSysColor_(#COLOR_3DFACE)
          \ColorMarginText = GetSysColor_(#COLOR_3DDKSHADOW)
          \ColorSel = GetSysColor_(#COLOR_HIGHLIGHT)
          \ColorSelText = GetSysColor_(#COLOR_HIGHLIGHTTEXT)
          
          If (Not _MemGadget\ContainerProc)
            _MemGadget\ContainerProc = GetWindowLongPtr_(GadgetID(Gadget), #GWLP_WNDPROC)
            SetWindowLongPtr_(GadgetID(Gadget), #GWLP_WNDPROC, @_MemGadgetContainerProc())
            SetWindowLongPtr_(GadgetID(Gadget), #GWLP_USERDATA, *MG)
          EndIf
          
        CompilerElse
          \ColorBack = #White
          \ColorText = #Black
          \ColorMargin = $CCCCCC
          \ColorMarginText = $444444
        CompilerEndIf
        \ColorSelFade = AlphaBlend(\ColorSel | $30000000, \ColorBack | $FF000000) & $FFFFFF
        ;
        \SelType    = #_MemGadget_None
        \CursorType = #_MemGadget_None
        ;
        \Columns = #_MemGadget_DefaultColumns
        \Border  = #_MemGadget_DefaultBorder
        ;
        CloseGadgetList()
        SetGadgetData(Gadget,   *MG)
        SetGadgetData(\Canvas,  *MG)
        SetGadgetData(\HScroll, *MG)
        SetGadgetData(\VScroll, *MG)
        
        If (Not _MemGadget\DefaultFontID)
          CompilerIf (#False)
            _MemGadget\DefaultFontID = GetGadgetFont(#PB_Default)
          CompilerElse
            _MemGadget\DefaultFontID = FontID(LoadFont(#PB_Any,
                #_MemGadget_DefaultFontName, #_MemGadget_DefaultFontSize))
          CompilerEndIf
          CompilerIf (#_MemGadget_Windows)
            _MemGadget\ScrollSize = GetSystemMetrics_(#SM_CYHSCROLL)
          CompilerElse
            _MemGadget\ScrollSize = 20
          CompilerEndIf
        EndIf
        
        SetMemGadgetFontID(Gadget, _MemGadget\DefaultFontID)
        BindGadgetEvent(\Container, @_MemGadgetResizeCB(), #PB_EventType_Resize)
        BindGadgetEvent(\HScroll,   @_MemGadgetScrollCB())
        BindGadgetEvent(\VScroll,   @_MemGadgetScrollCB())
        BindGadgetEvent(\Canvas,    @_MemGadgetCanvasCB())
      EndWith
    Else
      CloseGadgetList()
      FreeGadget(Gadget)
      Result = #Null
    EndIf
  EndIf
  If (Result)
    If (*Buffer And (BufferSize > 0))
      SetMemGadgetBuffer(Gadget, *Buffer, BufferSize)
    EndIf
    *MG\Flags & (~#_MemGadget_Locked)
    _MemGadgetResize(*MG)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DisplayMemGadget(*Buffer, BufferSize.i, Editable.i = #False)
  Protected Result.i = #False
  If (*Buffer And (BufferSize > 0))
    Protected Win.i = OpenWindow(#PB_Any, 0, 0, 640, 480,
        "$" + Hex(*Buffer) + " (" + Str(BufferSize) + " bytes)",
        #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget |
        #PB_Window_SizeGadget | #PB_Window_ScreenCentered |
        #PB_Window_Invisible)
    If (Win)
      Protected Gad.i = MemGadget(#PB_Any, 0, 0, WindowWidth(Win), WindowHeight(Win),
          (#MemGadget_Editable * Bool(Editable)) | 
          ;#MemGadget_NoHeader  |
          ;#MemGadget_NoMargin  |
          ;#MemGadget_NoPreview |
          ;#MemGadget_Relative |
          #MemGadget_Borderless, *Buffer, BufferSize)
      If (Gad)
        RemoveKeyboardShortcut(Win, #PB_Shortcut_Tab)
        RemoveKeyboardShortcut(Win, #PB_Shortcut_Tab | #PB_Shortcut_Shift)
        AddKeyboardShortcut(Win, #PB_Shortcut_Escape, 1)
        SetWindowData(Win, Gad)
        BindEvent(#PB_Event_SizeWindow, @_DisplayMemGadgetCB(), Win)
        HideWindow(Win, #False)
        SetActiveGadget(Gad)
        Protected Event.i
        Repeat
          Event = WaitWindowEvent()
        Until ((Event = #PB_Event_CloseWindow) Or (Event = #PB_Event_Menu))
        UnbindEvent(#PB_Event_SizeWindow, @_DisplayMemGadgetCB(), Win)
        FreeMemGadget(Gad)
      EndIf
      CloseWindow(Win)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure








;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

DataSection
  DataStart:
  ;Data.q 1234
  IncludeBinary #PB_Compiler_Home + "Examples/Sources/Data/ui.xml"
  DataEnd:
EndDataSection

DisplayMemGadget(?DataStart, ?DataEnd - ?DataStart, #True)

CompilerEndIf
CompilerEndIf
;-