; +------------------+
; | SendKeys_Win.pbi |
; +------------------+
; | 2016.09.13 . Creation
; | 2017.05.05 . Multiple-include safe, demo cleanup

;-
CompilerIf (Not Defined(__SendKeys_Win_Included, #PB_Constant))
#__SendKeys_Win_Included = #True

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)

; You can define #SendKeys_Method to change the key press/release method
;#SendKeys_Method = 1
CompilerIf (Not Defined(SendKeys_Method, #PB_Constant))
  ; 0 = use SendInput
  ; 1 = use kbdevent
  ; 2 = use WM_KEYDOWN
  #SendKeys_Method = 0
CompilerEndIf





;- Functions (Private)

Procedure _PressKey_SendInput(VK.i)
  Protected SI.INPUT
  SI\type = #INPUT_KEYBOARD
  With SI\ki
    \wVk = VK
    \wScan = #Null
    \dwFlags = #Null
    \time = 0
    \dwExtraInfo = #Null
  EndWith
  SendInput_(1, @SI, SizeOf(INPUT))
EndProcedure
Procedure _ReleaseKey_SendInput(VK.i)
  Protected SI.INPUT
  SI\type = #INPUT_KEYBOARD
  With SI\ki
    \wVk = VK
    \wScan = #Null
    \dwFlags = #KEYEVENTF_KEYUP
    \time = 0
    \dwExtraInfo = #Null
  EndWith
  SendInput_(1, @SI, SizeOf(INPUT))
EndProcedure

Procedure _PressKey_keybdevent(VK.i)
  keybd_event_(VK, #Null, #Null, #Null)
EndProcedure
Procedure _ReleaseKey_keybdevent(VK.i)
  keybd_event_(VK, #Null, #KEYEVENTF_KEYUP, #Null)
EndProcedure

; WM_KEY method does not seem to work outside of owner process!

Procedure _PressKey_WMKEY(VK.i)
  PostMessage_(GetFocus_(), #WM_KEYDOWN, VK, $00000000)
EndProcedure
Procedure _ReleaseKey_WMKEY(VK.i)
  PostMessage_(GetFocus_(), #WM_KEYUP, VK, $C0000001)
EndProcedure







;-
;- Functions (Public)

CompilerSelect (#SendKeys_Method)
  CompilerCase (1)
    Macro PressKey(VK)
      _PressKey_keybdevent(VK)
    EndMacro
    Macro ReleaseKey(VK)
      _ReleaseKey_keybdevent(VK)
    EndMacro
  CompilerCase (2)
    Macro PressKey(VK)
      _PressKey_WMKEY(VK)
    EndMacro
    Macro ReleaseKey(VK)
      _ReleaseKey_WMKEY(VK)
    EndMacro
  CompilerDefault
    Macro PressKey(VK)
      _PressKey_SendInput(VK)
    EndMacro
    Macro ReleaseKey(VK)
      _ReleaseKey_SendInput(VK)
    EndMacro
CompilerEndSelect

Procedure TapKey(VK.i, msDelay.i = 25)
  PressKey(VK)
  Delay(msDelay)
  ReleaseKey(VK)
  Delay(msDelay)
EndProcedure

CompilerEndIf








;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)

OpenWindow(0, 0, 0, 640, 30, "SendKeys_Win", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
EditorGadget(0, 0, 0, 640, 30)
AddWindowTimer(0, 0, 500)
SetActiveGadget(0)
;Debug "Method " + Str(#SendKeys_Method)

Repeat
  Event = WaitWindowEvent(500)
  If (Event = #PB_Event_Timer)
    TapKey(Random('Z', 'A'))
  EndIf
Until (Event = #PB_Event_CloseWindow)

CompilerEndIf
CompilerEndIf
;-