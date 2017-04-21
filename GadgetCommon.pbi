; +--------------+
; | GadgetCommon |
; +--------------+
; | 2017.04.20 . Expanded demo to 3 different gadgets instead of 1,
; |                added SelectAll and CheckAll procedures

CompilerIf (Not Defined(__GadgetCommon_Included, #PB_Constant))
#__GadgetCommon_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;-
;- Constants

#PB_ListView_Selected = $01

;-
;- Procedures

Procedure.i _CountFlaggedGadgetItems(Gadget.i, Checked.i)
  Protected Result.i = 0
  Protected Flag.i
  Protected n.i
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon
      n = CountGadgetItems(Gadget)
      If (Checked)
        Flag = #PB_ListIcon_Checked
      Else
        Flag = #PB_ListIcon_Selected
      EndIf
    Case #PB_GadgetType_ListView
      n = CountGadgetItems(Gadget)
      If (Not Checked)
        Flag = #PB_ListView_Selected
      EndIf
    Case #PB_GadgetType_Tree
      n = CountGadgetItems(Gadget)
      If (Checked)
        Flag = #PB_Tree_Checked
      Else
        Flag = #PB_Tree_Selected
      EndIf
  EndSelect
  If (Flag And (n > 0))
    Protected i.i
    For i = 0 To n - 1
      If (GetGadgetItemState(Gadget, i) & Flag)
        Result + 1
      EndIf
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CountSelectedGadgetItems(Gadget.i)
  ProcedureReturn (_CountFlaggedGadgetItems(Gadget, #False))
EndProcedure

Procedure.i CountCheckedGadgetItems(Gadget.i)
  ProcedureReturn (_CountFlaggedGadgetItems(Gadget, #True))
EndProcedure

Procedure.i GadgetItemByItemData(Gadget.i, ItemData.i)
  Protected Result.i = -1
  Protected n.i
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon, #PB_GadgetType_ListView, #PB_GadgetType_Tree
      n = CountGadgetItems(Gadget)
  EndSelect
  If (n > 0)
    Protected i.i
    For i = 0 To n - 1
      If (GetGadgetItemData(Gadget, i) = ItemData)
        Result = i
        Break
      EndIf
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SelectedGadgetItemData(Gadget.i)
  Protected Result.i = #Null
  Protected i.i = GetGadgetState(Gadget)
  If (i >= 0)
    Result = GetGadgetItemData(Gadget, i)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure _SetGadgetItemFlagged(Gadget.i, Item.i, State.i, Checked.i)
  Protected Flag.i
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon
      If (Checked)
        Flag = #PB_ListIcon_Checked
      Else
        Flag = #PB_ListIcon_Selected
      EndIf
    Case #PB_GadgetType_ListView
      If (Not Checked)
        Flag = #PB_ListView_Selected
      EndIf
    Case #PB_GadgetType_Tree
      If (Checked)
        Flag = #PB_Tree_Checked
      Else
        Flag = #PB_Tree_Selected
      EndIf
  EndSelect
  If (Flag)
    Protected Flags.i = GetGadgetItemState(Gadget, Item)
    If (State)
      Flags | Flag
    Else
      Flags & ~Flag
    EndIf
    SetGadgetItemState(Gadget, Item, Flags)
  EndIf
EndProcedure

Procedure SetGadgetItemChecked(Gadget.i, Item.i, State.i)
  _SetGadgetItemFlagged(Gadget, Item, State, #True)
EndProcedure

Procedure SetGadgetItemSelected(Gadget.i, Item.i, State.i)
  _SetGadgetItemFlagged(Gadget, Item, State, #False)
EndProcedure

Procedure.i _GetGadgetItemFlagged(Gadget.i, Item.i, Checked.i)
  Protected Result.i = #False
  Protected Flag.i
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon
      If (Checked)
        Flag = #PB_ListIcon_Checked
      Else
        Flag = #PB_ListIcon_Selected
      EndIf
    Case #PB_GadgetType_ListView
      If (Not Checked)
        Flag = #PB_ListView_Selected
      EndIf
    Case #PB_GadgetType_Tree
      If (Checked)
        Flag = #PB_Tree_Checked
      Else
        Flag = #PB_Tree_Selected
      EndIf
  EndSelect
  If (Flag)
    Result = Bool(GetGadgetItemState(Gadget, Item) & Flag)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GetGadgetItemChecked(Gadget.i, Item.i)
  ProcedureReturn (_GetGadgetItemFlagged(Gadget, Item, #True))
EndProcedure

Procedure.i GetGadgetItemSelected(Gadget.i, Item.i)
  ProcedureReturn (_GetGadgetItemFlagged(Gadget, Item, #False))
EndProcedure

Procedure SelectAllGadgetItems(Gadget.i, Deselect.i = #False)
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon
      Protected n.i = CountGadgetItems(Gadget)
      Protected i.i
      If (Deselect)
        SetGadgetState(Gadget, -1)
      Else
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) | #PB_ListIcon_Selected)
        Next i
      EndIf
    Case #PB_GadgetType_ListView
      n = CountGadgetItems(Gadget)
      If (Deselect)
        SetGadgetState(Gadget, -1)
      Else
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) | #PB_ListView_Selected)
        Next i
      EndIf
    Case #PB_GadgetType_Tree
      If (Deselect)
        SetGadgetState(Gadget, -1)
      EndIf
  EndSelect
EndProcedure

Procedure CheckAllGadgetItems(Gadget.i, Uncheck.i = #False)
  Select (GadgetType(Gadget))
    Case #PB_GadgetType_ListIcon
      Protected n.i = CountGadgetItems(Gadget)
      Protected i.i
      If (Uncheck)
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) & (~#PB_ListIcon_Checked))
        Next i
      Else
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) | #PB_ListIcon_Checked)
        Next i
      EndIf
    Case #PB_GadgetType_ListView
      ;
    Case #PB_GadgetType_Tree
      n = CountGadgetItems(Gadget)
      If (Uncheck)
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) & (~#PB_Tree_Checked))
        Next i
      Else
        For i = 0 To n - 1
          SetGadgetItemState(Gadget, i, GetGadgetItemState(Gadget, i) | #PB_Tree_Checked)
        Next i
      EndIf
  EndSelect
EndProcedure

;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

OpenWindow(0, 10, 10, 600, 360, "GadgetCommon", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
ListIconGadget(0, 0, 0, 200, 200, "ListIcon", 100, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_CheckBoxes | #PB_ListIcon_FullRowSelect | #PB_ListIcon_MultiSelect)
ListViewGadget(2, 200, 0, 200, 200, #PB_ListView_MultiSelect)
TreeGadget(4, 400, 0, 200, 200, #PB_Tree_CheckBoxes | #PB_Tree_AlwaysShowSelection)
For g = 0 To 2
  For i = 0 To 5
    AddGadgetItem(g * 2, i, Chr('A' + i))
    SetGadgetItemData(g * 2, i, i + 100)
    If (g <> 2)
      SetGadgetItemSelected(g * 2, i, Random(1))
    EndIf
    If (g <> 1)
      SetGadgetItemChecked(g * 2, i, Random(1))
    EndIf
  Next i
  TextGadget(g*2 + 1, 2 + 200*g, GadgetHeight(0), 200-4, WindowHeight(0) - GadgetHeight(0), "")
Next g

Procedure Update()
  For g = 0 To 2
    Out.s = "CountSelectedGadgetItems = "           + Str(CountSelectedGadgetItems(g*2))
    Out.s + #LF$ + "CountCheckedGadgetItems = "     + Str(CountCheckedGadgetItems(g*2))
    Out.s + #LF$ + "SelectedGadgetItemData = "      + Str(SelectedGadgetItemData(g*2))
    Out.s + #LF$ + "GetGadgetItemSelected(" + Str(g*2) + ", 2) = " + Str(GetGadgetItemSelected(g*2, 2))
    Out.s + #LF$ + "GetGadgetItemChecked(" + Str(g*2) + ", 2) = "  + Str(GetGadgetItemChecked(g*2, 2))
    SetGadgetText(g*2+1, Out)
  Next g
EndProcedure
;Debug GadgetItemByItemData(0, 102)

Update()
SetActiveGadget(0)
AddKeyboardShortcut(0, #PB_Shortcut_A | #PB_Shortcut_Command, 0)
AddKeyboardShortcut(0, #PB_Shortcut_Escape, 1)

Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_CloseWindow)
    Done = #True
  ElseIf (Event = #PB_Event_Gadget)
    Update()
  ElseIf (Event = #PB_Event_Menu)
    Select (EventMenu())
      Case 0
        SelectAllGadgetItems(GetActiveGadget())
        Update()
      Case 1
        Done = #True
    EndSelect
  EndIf
Until (Done)

CompilerEndIf
CompilerEndIf
;-