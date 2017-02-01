; +--------------------+
; | ImproveGadgets.pbi |
; +--------------------+
; | 2014.06.14 . Creation (PureBasic 5.22)
; | 2016.08.01 . Made Unicode safe, improved backspace deletion
; |        .11 . Added ImproveWebGadget to prevent Script Error popups
; | 2017.02.01 . Cleanup, made multiple-include safe


; Various simple improvements to PB gadgets (effects on Windows only)
;
; ImproveStringGadget(), ImproveComboBoxGadget()
;   Enables Ctrl+Backspace for deleting words, delimited by spaces
;
; ImproveContainerGadget()
;   For containers that are entirely covered by child gadgets!
;   Disables ERASEBKGND and NCPAINT messages, which reduces resize flickering
;
; ImproveWebGadget()
;   Disables "Script Error" popups



CompilerIf (Not Defined(__ImproveGadgets_Included, #PB_Constant))
#__ImproveGadgets_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)

;-
;- Structures - Private

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


;-
;- Procedures - Private

Procedure.i __ImproveStringGadgetCB(hWnd.i, uMsg.i, wParam.i, lParam.i)
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

Procedure.i __ImproveContainerGadgetCB(hWnd.i, uMsg.i, wParam.i, lParam.i)
  If ((uMsg = #WM_ERASEBKGND) Or (uMsg = #WM_NCPAINT))
    ProcedureReturn (#Null)
  Else
    ProcedureReturn (CallWindowProc_(GetWindowLongPtr_(hWnd, #GWL_USERDATA), hWnd, uMsg, wParam, lParam))
  EndIf
EndProcedure

;-
;- Procedures - Public

Procedure ImproveStringGadget(Gadget.i)
  If (GadgetType(Gadget) = #PB_GadgetType_String)
    SetWindowLongPtr_(GadgetID(Gadget), #GWL_USERDATA, GetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC))
    SetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC, @__ImproveStringGadgetCB())
  EndIf
EndProcedure

Procedure ImproveComboBoxGadget(Gadget.i)
  If (GadgetType(Gadget) = #PB_GadgetType_ComboBox)
    Protected CBI.COMBOBOXINFO
    CBI\cbSize = SizeOf(COMBOBOXINFO)
    If (GetComboBoxInfo_(GadgetID(Gadget), @CBI))
      SetWindowLongPtr_(CBI\hwndItem, #GWL_USERDATA, GetWindowLongPtr_(CBI\hwndItem, #GWL_WNDPROC))
      SetWindowLongPtr_(CBI\hwndItem, #GWL_WNDPROC, @__ImproveStringGadgetCB())
    EndIf
  EndIf
EndProcedure

Procedure ImproveContainerGadget(Gadget.i)
  If (GadgetType(Gadget) = #PB_GadgetType_Container)
    SetWindowLongPtr_(GadgetID(Gadget), #GWL_USERDATA, GetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC))
    SetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC, @__ImproveContainerGadgetCB())
  EndIf
EndProcedure

Procedure ImproveWebGadget(Gadget.i)
  If (GadgetType(Gadget) = #PB_GadgetType_Web)
    Protected *IWB2.IWebBrowser2 = GetWindowLong_(GadgetID(Gadget), #GWL_USERDATA)
    If (*IWB2)
      *IWB2\put_Silent(#True)
    EndIf
  EndIf
EndProcedure





CompilerElse

;-
;- Macros - Public

Macro ImproveStringGadget(Gadget)
  ;
EndMacro

Macro ImproveComboBoxGadget(Gadget)
  ;
EndMacro

Macro ImproveContainerGadget(Gadget)
  ;
EndMacro

Macro ImproveWebGadget(Gadget)
  ;
EndMacro

CompilerEndIf



;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)

OpenWindow(0, 0, 0, 240, 40, "ImproveStringGadget()", #PB_Window_ScreenCentered|#PB_Window_SystemMenu)
StringGadget(0, 10, 10, 220, 20, "This is a test")
ImproveStringGadget(0)
SetActiveGadget(0)
SendMessage_(GadgetID(0), #EM_SETSEL, Len(GetGadgetText(0)), Len(GetGadgetText(0)))
Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow

CompilerEndIf

CompilerEndIf
;-