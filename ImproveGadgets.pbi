; +--------------------+
; | ImproveGadgets.pbi |
; +--------------------+
; | 2014.06.14 . Creation (PureBasic 5.22)
; | 2016.08.01 . Made Unicode safe, improved backspace deletion
; |        .11 . Added ImproveWebGadget to prevent Script Error popups
; | 2017.02.01 . Cleanup, made multiple-include safe
; | 2019.01.02 . Added hooks to remove native hotkeys from Windows WebGadget
; |        .03 . Merged in SetBrowserEmulation()
; | 2020-09-03 . Add Ctrl+S to the hotkeys you can hook
; | 2021-08-25 . Add Ctrl+A handling for Select All on Win XP StringGadgets


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
;   Set 'Emulation' to a newer IE version
;   Use keyboard hooks to disable Windows native dialogs (requires events)



CompilerIf (Not Defined(__ImproveGadgets_Included, #PB_Constant))
#__ImproveGadgets_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)

;-
;- Variables - Private

Global *_WebGadgetHook = #Null

Global _WebGadgetMenuWin.i =  0
Global _WebGadgetMenuIDN.i = -1
Global _WebGadgetMenuIDO.i = -1
Global _WebGadgetMenuIDS.i = -1


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

Procedure.i __WebGadgetHookCB(nCode.i, wParam.i, lParam.i)
  Protected Ctrl.i = Bool(GetAsyncKeyState_(#VK_CONTROL) & $8000)
  If (Ctrl)
    Protected FirstHit.i = Bool(Not (lParam & $C0000000)) ; MSB = KEYUP, MSB-1 = REPEAT
    Select (nCode)
      Case (#HC_ACTION)
        Select (wParam)
          Case #VK_N
            If ((_WebGadgetMenuIDN >= 0) And (FirstHit))
              PostEvent(#PB_Event_Menu, _WebGadgetMenuWin, _WebGadgetMenuIDN)
            EndIf
            ProcedureReturn (#True) ; block
          Case #VK_O
            If ((_WebGadgetMenuIDO >= 0) And (FirstHit))
              PostEvent(#PB_Event_Menu, _WebGadgetMenuWin, _WebGadgetMenuIDO)
            EndIf
            ProcedureReturn (#True) ; block
          Case #VK_S
            If ((_WebGadgetMenuIDS >= 0) And (FirstHit))
              PostEvent(#PB_Event_Menu, _WebGadgetMenuWin, _WebGadgetMenuIDS)
            EndIf
            ProcedureReturn (#True) ; block
          Case #VK_P, #VK_L
            ProcedureReturn (#True) ; block
          Default
            ;
        EndSelect
    EndSelect
  EndIf
  ProcedureReturn (CallNextHookEx_(0, nCode, wParam, lParam))
EndProcedure

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
  ElseIf ((uMsg = #WM_KEYDOWN) And (wParam = 'A') And ((lParam & $40000000) = 0) And (GetAsyncKeyState_(#VK_CONTROL) & $8000))
    ; Windows XP Ctrl+A fix (PB 5.73 x86)
    If ((OSVersion() = #PB_OS_Windows_XP) Or (#False))
      PostMessage_(hWnd, #EM_SETSEL, 0, -1)
    Else
      ProcedureReturn (CallWindowProc_(GetWindowLongPtr_(hWnd, #GWL_USERDATA), hWnd, uMsg, wParam, lParam))
    EndIf
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

Procedure SetBrowserEmulation(IEVersion.i = 10)
  Protected lpIEVersion
  Select (IEVersion)
    Case (11) : lpIEVersion = 11001
    Case (10) : lpIEVersion = 10001
    Case ( 9) : lpIEVersion =  9999
    Case ( 8) : lpIEVersion =  8888
    Default
      If (IEVersion >= 7000)
        lpIEVersion = IEVersion
      Else
        lpIEVersion = 7000
      EndIf
  EndSelect
  
  Protected lpValueName.s = GetFilePart(ProgramFilename())
  Protected phkResult.i
  Protected lpdwDisposition.l
  If (RegCreateKeyEx_(#HKEY_CURRENT_USER,
      "SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION",
      0, #Null, #REG_OPTION_VOLATILE, #KEY_ALL_ACCESS, #Null, @phkResult, @lpdwDisposition) = #ERROR_SUCCESS)
    RegSetValueEx_(phkResult, lpValueName, 0, #REG_DWORD, @lpIEVersion, SizeOf(LONG))
    RegCloseKey_(phkResult)
  EndIf
EndProcedure
CompilerIf (#True)
  SetBrowserEmulation()
CompilerEndIf



;-
;- Macros - Public

Macro HookWebGadgets(State)
  If ((State) And (Not *_WebGadgetHook))
    *_WebGadgetHook = SetWindowsHookEx_(#WH_KEYBOARD, @__WebGadgetHookCB(), 0, GetCurrentThreadId_())
  ElseIf ((Not State) And (*_WebGadgetHook))
    UnhookWindowsHookEx_(*_WebGadgetHook)
    *_WebGadgetHook = #Null
  EndIf
EndMacro

Macro SetWebGadgetHooks(Window = 0, CtrlN = -1, CtrlO = -1, CtrlS = -1)
  _WebGadgetMenuWin = (Window)
  _WebGadgetMenuIDN = (CtrlN)
  _WebGadgetMenuIDO = (CtrlO)
  _WebGadgetMenuIDS = (CtrlS)
EndMacro





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

Macro HookWebGadgets(State)
  ;
EndMacro

Macro SetWebGadgetHooks(Window = 0, CtrlN = -1, CtrlO = -1)
  ;
EndMacro



CompilerEndIf



;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)

OpenWindow(0, 0, 0, 240, 40, "ImproveStringGadget()", #PB_Window_ScreenCentered|#PB_Window_SystemMenu)
StringGadget(0, 10, 10, 220, 20, "This is a test")
CompilerIf (Defined(PB_Gadget_RequiredSize, #PB_Constant))
  ResizeWindow(0, #PB_Ignore, #PB_Ignore, 2*10 + GadgetWidth(0), 2*10 + GadgetHeight(0, #PB_Gadget_RequiredSize))
CompilerEndIf
ImproveStringGadget(0)
SetActiveGadget(0)
CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  SendMessage_(GadgetID(0), #EM_SETSEL, Len(GetGadgetText(0)), Len(GetGadgetText(0)))
CompilerEndIf
Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow

CompilerEndIf

CompilerEndIf
;-

