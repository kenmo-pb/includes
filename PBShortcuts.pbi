; +-----------------+
; | PBShortcuts.pbi |
; +-----------------+
; | 2016.01.07 . Creation
; | 2017.04.06 . General cleanup, and demo added

;-
CompilerIf (Not Defined(__PBShortcuts_Included, #PB_Constant))
#__PBShortcuts_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Structures (Private)

Structure __PBSC_Struct
  Name.s
  Value.i
EndStructure

;-
;- Lists (Private)

Global NewList __PBSC.__PBSC_Struct()
Global NewList __OSSC.__PBSC_Struct()

;-
;- Define PB Shortcuts (Private)

AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Back" : __PBSC()\Value = #PB_Shortcut_Back
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Tab" : __PBSC()\Value = #PB_Shortcut_Tab
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Clear" : __PBSC()\Value = #PB_Shortcut_Clear
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Return" : __PBSC()\Value = #PB_Shortcut_Return
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Menu" : __PBSC()\Value = #PB_Shortcut_Menu
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pause" : __PBSC()\Value = #PB_Shortcut_Pause
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Print" : __PBSC()\Value = #PB_Shortcut_Print
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Capital" : __PBSC()\Value = #PB_Shortcut_Capital
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Escape" : __PBSC()\Value = #PB_Shortcut_Escape
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Space" : __PBSC()\Value = #PB_Shortcut_Space
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_PageUp" : __PBSC()\Value = #PB_Shortcut_PageUp
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_PageDown" : __PBSC()\Value = #PB_Shortcut_PageDown
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_End" : __PBSC()\Value = #PB_Shortcut_End
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Home" : __PBSC()\Value = #PB_Shortcut_Home
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Left" : __PBSC()\Value = #PB_Shortcut_Left
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Up" : __PBSC()\Value = #PB_Shortcut_Up
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Right" : __PBSC()\Value = #PB_Shortcut_Right
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Down" : __PBSC()\Value = #PB_Shortcut_Down
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Select" : __PBSC()\Value = #PB_Shortcut_Select
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Execute" : __PBSC()\Value = #PB_Shortcut_Execute
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Snapshot" : __PBSC()\Value = #PB_Shortcut_Snapshot
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Insert" : __PBSC()\Value = #PB_Shortcut_Insert
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Delete" : __PBSC()\Value = #PB_Shortcut_Delete
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Help" : __PBSC()\Value = #PB_Shortcut_Help
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_0" : __PBSC()\Value = #PB_Shortcut_0
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_1" : __PBSC()\Value = #PB_Shortcut_1
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_2" : __PBSC()\Value = #PB_Shortcut_2
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_3" : __PBSC()\Value = #PB_Shortcut_3
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_4" : __PBSC()\Value = #PB_Shortcut_4
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_5" : __PBSC()\Value = #PB_Shortcut_5
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_6" : __PBSC()\Value = #PB_Shortcut_6
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_7" : __PBSC()\Value = #PB_Shortcut_7
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_8" : __PBSC()\Value = #PB_Shortcut_8
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_9" : __PBSC()\Value = #PB_Shortcut_9
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_A" : __PBSC()\Value = #PB_Shortcut_A
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_B" : __PBSC()\Value = #PB_Shortcut_B
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_C" : __PBSC()\Value = #PB_Shortcut_C
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_D" : __PBSC()\Value = #PB_Shortcut_D
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_E" : __PBSC()\Value = #PB_Shortcut_E
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F" : __PBSC()\Value = #PB_Shortcut_F
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_G" : __PBSC()\Value = #PB_Shortcut_G
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_H" : __PBSC()\Value = #PB_Shortcut_H
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_I" : __PBSC()\Value = #PB_Shortcut_I
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_J" : __PBSC()\Value = #PB_Shortcut_J
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_K" : __PBSC()\Value = #PB_Shortcut_K
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_L" : __PBSC()\Value = #PB_Shortcut_L
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_M" : __PBSC()\Value = #PB_Shortcut_M
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_N" : __PBSC()\Value = #PB_Shortcut_N
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_O" : __PBSC()\Value = #PB_Shortcut_O
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_P" : __PBSC()\Value = #PB_Shortcut_P
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Q" : __PBSC()\Value = #PB_Shortcut_Q
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_R" : __PBSC()\Value = #PB_Shortcut_R
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_S" : __PBSC()\Value = #PB_Shortcut_S
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_T" : __PBSC()\Value = #PB_Shortcut_T
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_U" : __PBSC()\Value = #PB_Shortcut_U
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_V" : __PBSC()\Value = #PB_Shortcut_V
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_W" : __PBSC()\Value = #PB_Shortcut_W
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_X" : __PBSC()\Value = #PB_Shortcut_X
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Y" : __PBSC()\Value = #PB_Shortcut_Y
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Z" : __PBSC()\Value = #PB_Shortcut_Z
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_LeftWindows" : __PBSC()\Value = #PB_Shortcut_LeftWindows
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_RightWindows" : __PBSC()\Value = #PB_Shortcut_RightWindows
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Apps" : __PBSC()\Value = #PB_Shortcut_Apps
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad0" : __PBSC()\Value = #PB_Shortcut_Pad0
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad1" : __PBSC()\Value = #PB_Shortcut_Pad1
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad2" : __PBSC()\Value = #PB_Shortcut_Pad2
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad3" : __PBSC()\Value = #PB_Shortcut_Pad3
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad4" : __PBSC()\Value = #PB_Shortcut_Pad4
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad5" : __PBSC()\Value = #PB_Shortcut_Pad5
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad6" : __PBSC()\Value = #PB_Shortcut_Pad6
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad7" : __PBSC()\Value = #PB_Shortcut_Pad7
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad8" : __PBSC()\Value = #PB_Shortcut_Pad8
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Pad9" : __PBSC()\Value = #PB_Shortcut_Pad9
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Multiply" : __PBSC()\Value = #PB_Shortcut_Multiply
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Add" : __PBSC()\Value = #PB_Shortcut_Add
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Separator" : __PBSC()\Value = #PB_Shortcut_Separator
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Subtract" : __PBSC()\Value = #PB_Shortcut_Subtract
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Decimal" : __PBSC()\Value = #PB_Shortcut_Decimal
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Divide" : __PBSC()\Value = #PB_Shortcut_Divide
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F1" : __PBSC()\Value = #PB_Shortcut_F1
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F2" : __PBSC()\Value = #PB_Shortcut_F2
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F3" : __PBSC()\Value = #PB_Shortcut_F3
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F4" : __PBSC()\Value = #PB_Shortcut_F4
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F5" : __PBSC()\Value = #PB_Shortcut_F5
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F6" : __PBSC()\Value = #PB_Shortcut_F6
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F7" : __PBSC()\Value = #PB_Shortcut_F7
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F8" : __PBSC()\Value = #PB_Shortcut_F8
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F9" : __PBSC()\Value = #PB_Shortcut_F9
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F10" : __PBSC()\Value = #PB_Shortcut_F10
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F11" : __PBSC()\Value = #PB_Shortcut_F11
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F12" : __PBSC()\Value = #PB_Shortcut_F12
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F13" : __PBSC()\Value = #PB_Shortcut_F13
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F14" : __PBSC()\Value = #PB_Shortcut_F14
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F15" : __PBSC()\Value = #PB_Shortcut_F15
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F16" : __PBSC()\Value = #PB_Shortcut_F16
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F17" : __PBSC()\Value = #PB_Shortcut_F17
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F18" : __PBSC()\Value = #PB_Shortcut_F18
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F19" : __PBSC()\Value = #PB_Shortcut_F19
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F20" : __PBSC()\Value = #PB_Shortcut_F20
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F21" : __PBSC()\Value = #PB_Shortcut_F21
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F22" : __PBSC()\Value = #PB_Shortcut_F22
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F23" : __PBSC()\Value = #PB_Shortcut_F23
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_F24" : __PBSC()\Value = #PB_Shortcut_F24
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Numlock" : __PBSC()\Value = #PB_Shortcut_Numlock
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Scroll" : __PBSC()\Value = #PB_Shortcut_Scroll
;
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Control" : __PBSC()\Value = #PB_Shortcut_Control
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Alt" : __PBSC()\Value = #PB_Shortcut_Alt
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Shift" : __PBSC()\Value = #PB_Shortcut_Shift
AddElement(__PBSC()) : __PBSC()\Name = "PB_Shortcut_Command" : __PBSC()\Value = #PB_Shortcut_Command

SortStructuredList(__PBSC(), #PB_Sort_Ascending, OffsetOf(__PBSC_Struct\Value), #PB_Integer)

;-
;- Define OS Shortcuts (Private)

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_PLUS" : __OSSC()\Value = #VK_OEM_PLUS
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_COMMA" : __OSSC()\Value = #VK_OEM_COMMA
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_MINUS" : __OSSC()\Value = #VK_OEM_MINUS
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_PERIOD" : __OSSC()\Value = #VK_OEM_PERIOD
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_1" : __OSSC()\Value = #VK_OEM_1
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_2" : __OSSC()\Value = #VK_OEM_2
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_3" : __OSSC()\Value = #VK_OEM_3
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_4" : __OSSC()\Value = #VK_OEM_4
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_5" : __OSSC()\Value = #VK_OEM_5
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_6" : __OSSC()\Value = #VK_OEM_6
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_7" : __OSSC()\Value = #VK_OEM_7
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_8" : __OSSC()\Value = #VK_OEM_8
  AddElement(__OSSC()) : __OSSC()\Name = "VK_OEM_102" : __OSSC()\Value = #VK_OEM_102
CompilerEndIf






;-
;- PB Shortcut Procedures (Public)

Procedure.i PBSC_ValueFromName(Name.s)
  If (Name)
    Name = LCase(LTrim(Name, "#"))
    If (Not FindString(Name, "_"))
      Name = "pb_shortcut_" + Name
    EndIf
    ForEach __PBSC()
      If (LCase(__PBSC()\Name) = Name)
        ProcedureReturn (__PBSC()\Value)
      EndIf
    Next
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.s PBSC_NameFromValue(Value.i)
  If (Value)
    ForEach __PBSC()
      If (__PBSC()\Value = Value)
        ProcedureReturn ("#" + __PBSC()\Name)
      EndIf
    Next
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure PBSC_DebugAll()
  CompilerIf (#PB_Compiler_Debugger)
    ForEach __PBSC()
      Debug "#" + __PBSC()\Name + " = " + Str(__PBSC()\Value)
    Next
  CompilerEndIf
EndProcedure



;-
;- OS Shortcut Procedures (Public)

Procedure.i OSSC_ValueFromName(Name.s)
  If (Name)
    Name = LCase(LTrim(Name, "#"))
    ForEach __OSSC()
      If (LCase(__OSSC()\Name) = Name)
        ProcedureReturn (__OSSC()\Value)
      EndIf
    Next
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.s OSSC_NameFromValue(Value.i)
  If (Value)
    ForEach __OSSC()
      If (__OSSC()\Value = Value)
        ProcedureReturn ("#" + __OSSC()\Name)
      EndIf
    Next
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure OSSC_DebugAll()
  CompilerIf (#PB_Compiler_Debugger)
    ForEach __OSSC()
      Debug "#" + __OSSC()\Name + " = " + Str(__OSSC()\Value)
    Next
  CompilerEndIf
EndProcedure




;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

OpenWindow(0, 0, 0, 480, 480, "Press Any Keys", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
ListViewGadget(0, 0, 0, 480, 440)
ButtonGadget(1, 0, 440, 240, 40, "Debug All")
ButtonGadget(2, 240, 440, 240, 40, "Quit")
For i = 1 To 255
  AddKeyboardShortcut(0, i, i)
Next i

Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_CloseWindow)
    Done = #True
  ElseIf (Event = #PB_Event_Gadget)
    If (EventGadget() = 1)
      ClearDebugOutput()
      PBSC_DebugAll()
      OSSC_DebugAll()
    ElseIf (EventGadget() = 2)
      Done = #True
    EndIf
  ElseIf (Event = #PB_Event_Menu)
    Name.s = PBSC_NameFromValue(EventMenu())
    If (Name = "")
      Name = OSSC_NameFromValue(EventMenu())
    EndIf
    If (Name)
      AddGadgetItem(0, 0, Name + "  =  " + Str(EventMenu()) + "  =  $" + Hex(EventMenu()))
      ;
      If ((EventMenu() <> PBSC_ValueFromName(Name)) And (EventMenu() <> OSSC_ValueFromName(Name)))
        Debug "Error on EventMenu() = " + Str(EventMenu()) + "!"
      EndIf
    EndIf
    CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
      If (EventMenu() = #PB_Menu_Quit)
        Done = #True
      EndIf
    CompilerEndIf
  EndIf
Until Done

CompilerEndIf

CompilerEndIf
;-