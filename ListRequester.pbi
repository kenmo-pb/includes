; +---------------+
; | ListRequester |
; +---------------+
; |  9.08.2012 . Creation (TreeGadget)
; |   .10.     . Added MultiSelect and AllowNoSel flags
; |   .11.     . Added ListIcon, ListView, and EdgeButtons flags
; |   .12.     . Added Tree levels, Select All shortcut, split Value/ImageID
; |   .13.     + Version 1.0 (documented code, added more examples)
; |   .14.     + Version 1.1 (fixed ParentWin and WindowCenter, added Sticky flag)
; |  6.04.2013 . Added support for multi-line messages (with automatic sizing)
; |  7.11.     . Increased requester height on Mac OSX
; |  2.07.2014 . Disabled #PB_Button_Default flag on Mac OSX (causes freeze?)
; |   .08.2016 . GadgetList is now restored (prevents parent program crashes)
; |  5.13.     . ListIcon header is now hidden on Mac too ("setHeaderView:")
; |  5.22.2017 . Multiple-include safe, cleanup

CompilerIf (Not Defined(__ListRequester_Included, #PB_Constant))
#__ListRequester_Included = #True

#ListRequester_IncludeVersion = 20170522

;-
;
; Version 1.2
; 
; This is a general purpose requester which presents a list of options to the user.
;   Each option includes a text string, plus an optional Image ID and user-defined integer.
;   The user may be required to choose EXACTLY one, AT LEAST one, or ANY NUMBER of options.
;   The Cancel action is always available, by design. You may modify this as desired.
;   The options may be presented in a ListIconGadget, ListViewGadget, or TreeGadget (each acts slightly differently).
;   The window size and text is fully customizable, otherwise it will try to reasonably size itself.
;   There are additional procedures to add, clear, and sort the options.
;
; This code may be used and modified however you want. Credit is appreciated.
;   Don't forget to disable or delete the Demo Program at the end!
; 
;
; Result.i = ListRequester( Title.s, Message.s, List Options.ListReq(), [ Flags.i, [ Selected.i, [ ParentWin.i, [ Width, Height ]]]] )
;
;   Title     : Brief text which appears in the requester's title bar (and ListIcon header if applicable)
;   Message   : Text prompt which appears at the top of the requester window
;   Options   : Linked list of options using the ListReq structure (see AddListReqOption for details)
;   Flags     : Bitwise-OR combination of the following constants:
;                 #ListReq_ListIcon    : Use a ListIconGadget for the Options (default, the column header will be hidden if possible)
;                 #ListReq_ListView    : Use a ListViewGadget for the Options (ImageID will be ignored)
;                 #ListReq_Tree        : Use a TreeGadget for the Options (tree levels may be specified by Value)
;                 #ListReq_ReturnVal   : The returned integer will be the Value associated with the selected Option (not its index)
;                 #ListReq_MultiSelect : Allows multiple Options to be selected, returns the total selected count
;                 #ListReq_AllowNoSel  : Used with MultiSelect, allows the user to accept without any Options selected
;                 #ListReq_TreeLevels  : Implies that the Value associated with each Option should be used as its "level" or depth
;                 #ListReq_EdgeButtons : Locates the OK and Cancel buttons at the side rather than the center
;                 #ListReq_Sticky      : Makes the requester "sticky" or always-on-top of other windows
;   Selected  : Specifies the initially selected option (default is -1, or no selection)
;   ParentWin : An optional PureBasic window (not its WindowID) which will be locked while the requester is open
;   Width     : Desired requester width (by default, auto-sizes to accomodate Title)
;   Height    : Desired requester height (by default, auto-sizes to accomodate Options)
;
;
;   Result    : The returned value means one of three things, depending on Flags:
;                 By default, this returns the index of the chosen option (0 or greater)
;                   The chosen option will also become the active list element, for immediate processing
;                 With #ListReq_ReturnVal, this returns the Value associated with the chosen Option (user-defined meaing)
;                 With #ListReq_MultiSelect, this returns the total number of options selected (0 or more)
;                   Note: each Option's Value is overwritten with #True or #False to indicate if it was selected or not
;                 #ListReq_Cancel is returned if the user cancels out
;                 #ListReq_Error is returned if the window cannot be created
;



CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;- Constants (Public)

; Requester Flags
#ListReq_ReturnVal    = $01
#ListReq_MultiSelect  = $04
#ListReq_AllowNoSel   = $08
#ListReq_TreeLevels   = $10
#ListReq_EdgeButtons  = $20
#ListReq_Sticky       = $40

; Gadget Flags
#ListReq_ListIcon     = $0000
#ListReq_ListView     = $0100
#ListReq_Tree         = $0200

; Sort Flags
#ListReq_Alphabetical = $00
#ListReq_ByValue      = $01
#ListReq_Ascending    = $00
#ListReq_Descending   = $02

; Return Codes
#ListReq_Empty  = -1
#ListReq_Cancel = -2
#ListReq_Error  = -3





;-
;- Constants (Private)
#xListReq_Enter  = $01
#xListReq_Escape = $02
#xListReq_CtrlA  = $04






;-
;- OS Constants (Private)
CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  #LVS_NOCOLUMNHEADER = 16384
  #xListReq_Ctrl = #PB_Shortcut_Control
CompilerElse
  #LVS_NOCOLUMNHEADER = #Null
  CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
    #xListReq_Ctrl = #PB_Shortcut_Command
  CompilerElse
    #xListReq_Ctrl = #PB_Shortcut_Control
  CompilerEndIf
CompilerEndIf

CompilerIf (Not Defined(PB_Sort_Integer, #PB_Constant))
  #PB_Sort_Integer = #PB_Integer
  #PB_Sort_String  = #PB_String
CompilerEndIf




;-
;- Structures (Public)

; Define a single ListRequester option
Structure ListReq
  Text.s
  Value.i
  ImageID.i
  Invalid.i
EndStructure





;-
;- Procedures (Private)

Procedure.i xListReq_TextHeight()
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Protected Result.i = 13
    Protected Temp.i
    If (IsWindow(0))
      Temp = TextGadget(#PB_Any, 0, 0, 0, 0, "ABC123")
      If (Temp)
        If (StartDrawing(WindowOutput(0)))
          DrawingFont(GetGadgetFont(Temp))
          Result = TextHeight("ABC123")
          StopDrawing()
        EndIf
        FreeGadget(Temp)
      EndIf
    EndIf
    ProcedureReturn (Result)
  CompilerElse
    ProcedureReturn (20)
  CompilerEndIf
EndProcedure








;-
;- Procedures (Public)

; The main ListRequester function, see detailed description above
Procedure.i ListRequester(Title.s, Message.s, List Options.ListReq(), Flags.i = #Null, Selected.i = -1, ParentWin.i = #Null, Width.i = 0, Height.i = 0)
  Protected Result.i = #ListReq_Cancel
  Protected Window.i, ParentID.i
  Protected MessageGadget.i, ListGadget.i, OKGadget.i, CancelGadget.i
  Protected Event.i, ExitFlag.i, TryOption.i
  Protected Count.i, i.i, j.i, SelFlag.i
  Protected MessageHeight.i
  
  ; Only process a non-empty list
  Count = ListSize(Options())
  If (Count > 0)
  
    ; Auto-fit window if dimensions aren't specified
    If (Width <= 0)
      Width = (Len(Message) / (1 + CountString(Message, #LF$))) * 3 + 190
    EndIf
    If (Height <= 0)
      CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
        Height = Log(ListSize(Options())) * 70 + 120
      CompilerElse
        Height = Log(ListSize(Options())) * 60 + 100
      CompilerEndIf
    EndIf
    
    ; Find parent window handle, if applicable
    If (IsWindow(ParentWin))
      DisableWindow(ParentWin, #True)
      ParentID =  WindowID(ParentWin)
      i        = #PB_Window_WindowCentered
    Else
      ParentID = #Null
      i        = #PB_Window_ScreenCentered
    EndIf
    
    ; Open requester window
    Protected PrevGadgetList.i = UseGadgetList(0)
    Window = OpenWindow(#PB_Any, 0, 0, Width, Height, Title, i|#PB_Window_Invisible|#PB_Window_SystemMenu, ParentID)
    If (Window)
      If (Flags & #ListReq_Sticky)
        StickyWindow(Window, #True)
      EndIf
      
      ; Create text prompt and OK/Cancel buttons
      MessageHeight = 7 + xListReq_TextHeight() * (CountString(Message, #LF$) + 1)
      MessageGadget = TextGadget(#PB_Any, 0, 5, Width, MessageHeight, Message, #PB_Text_Center)
      If (Flags & #ListReq_EdgeButtons)
        i = 5
        j = Width   - 85
      Else
        i = Width/2 - 90
        j = Width/2 + 10
      EndIf
      CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
        OKGadget    = ButtonGadget(#PB_Any, i, Height - 35, 80, 25,     "OK", #Null)
      CompilerElse
        OKGadget    = ButtonGadget(#PB_Any, i, Height - 35, 80, 25,     "OK", #PB_Button_Default)
      CompilerEndIf
      CancelGadget  = ButtonGadget(#PB_Any, j, Height - 35, 80, 25, "Cancel", #Null)
      
      ; Build window with a TreeGadget
      If (Flags & #ListReq_Tree)
        Flags & (~(#ListReq_ListView | #ListReq_ListIcon))
        SelFlag = #PB_Tree_Checked
        i = #PB_Tree_AlwaysShowSelection
        If (Not (Flags & #ListReq_TreeLevels))
          i | #PB_Tree_NoLines | #PB_Tree_NoButtons 
        EndIf
        If (Flags & #ListReq_MultiSelect)
          i | #PB_Tree_CheckBoxes
        EndIf
        ListGadget = TreeGadget(#PB_Any, 5, 5 + MessageHeight, Width - 10, Height - MessageHeight - 50, i)
      
      ; Build window with a ListViewGadget (no images allowed)
      ElseIf (Flags & #ListReq_ListView)
        Flags & (~#ListReq_ListIcon)
        SelFlag = #True
        If (Flags & #ListReq_MultiSelect)
          i = #PB_ListView_ClickSelect
        Else
          i = #Null
        EndIf
        ListGadget = ListViewGadget(#PB_Any, 5, 5 + MessageHeight, Width - 10, Height - MessageHeight - 50, i)
        
      ; Default, build window with a ListIconGadget
      Else
        SelFlag = #PB_ListIcon_Selected
        i = #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect | #LVS_NOCOLUMNHEADER
        If (Flags & #ListReq_MultiSelect)
          i | #PB_ListIcon_MultiSelect
        EndIf
        ListGadget = ListIconGadget(#PB_Any, 5, 5 + MessageHeight, Width - 10, Height - MessageHeight - 50, " ", Width - 30, i)
        CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
          CocoaMessage(0, GadgetID(ListGadget), "setHeaderView:", 0)
        CompilerEndIf
      EndIf
      
      ; Only the TreeGadget allows option levels
      If (Not (Flags & #ListReq_Tree))
        Flags & (~#ListReq_TreeLevels)
      EndIf
      
      ; Only MultiSelect allows "no selection" flag
      If (Not (Flags & #ListReq_MultiSelect))
        Flags & (~#ListReq_AllowNoSel)
      EndIf
      
      
      
      ; Add each option to the list
      ForEach (Options())
        ; 
        If (Flags & #ListReq_TreeLevels)
          j = Options()\Value
        Else
          j = #Null
        EndIf
        AddGadgetItem(ListGadget, ListIndex(Options()), Options()\Text, Options()\ImageID, j)
        
        ; Set pre-selected options
        If (Flags & #ListReq_MultiSelect)
          If (Options()\Value)
            SetGadgetItemState(ListGadget, ListIndex(Options()), SelFlag)
          Else
            SetGadgetItemState(ListGadget, ListIndex(Options()), #Null)
          EndIf
        EndIf
      Next
      
      ; Add standard keyboard shortcuts
      AddKeyboardShortcut(Window, #PB_Shortcut_Return, #xListReq_Enter )
      AddKeyboardShortcut(Window, #PB_Shortcut_Escape, #xListReq_Escape)
      AddKeyboardShortcut(Window, #PB_Shortcut_A|#xListReq_Ctrl, #xListReq_CtrlA)
      
      ; Remove ListIcon header, when possible
      CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
        If (Flags & #ListReq_ListIcon)
          SendMessage_(GadgetID(ListGadget), #LVM_SETCOLUMNWIDTH, 0, #LVSCW_AUTOSIZE | #LVSCW_AUTOSIZE_USEHEADER)
        EndIf
      CompilerEndIf
      
      ; Finalize and show window
      If (Not (Flags & #ListReq_MultiSelect))
        SetGadgetState(ListGadget, Selected)
      EndIf
      HideWindow(Window, #False)
      SetActiveWindow(Window)
      SetActiveGadget(ListGadget)
      
      ; Event loop
      Repeat
        Event = WaitWindowEvent()
        
        ; Handle gadget events
        If (Event = #PB_Event_Gadget)
          Select (EventGadget())
            Case OKGadget
              TryOption = #True
            Case CancelGadget
              Result   = #ListReq_Cancel
              ExitFlag = #True
            Case ListGadget
              If (EventType() = #PB_EventType_LeftDoubleClick)
                TryOption = #True
              EndIf
          EndSelect
        
        ; Handle menu events (shortcuts)
        ElseIf (Event = #PB_Event_Menu)
          Select (EventMenu())
            Case #xListReq_Enter
              TryOption = #True
            Case #xListReq_Escape
              Result   = #ListReq_Cancel
              ExitFlag = #True
            Case #xListReq_CtrlA
              If (Flags & #ListReq_MultiSelect)
                For i = Count - 1 To 0 Step -1
                  SetGadgetItemState(ListGadget, i, SelFlag)
                Next i
              EndIf
          EndSelect
        
        ; Handle other window events
        ElseIf (Event = #PB_Event_CloseWindow)
          Result   = #ListReq_Cancel
          ExitFlag = #True
        EndIf
        
        ; Verify user's selection
        If (TryOption)
          ExitFlag = #True
          
          ; Verify a multi-selection
          If (Flags & #ListReq_MultiSelect)
            Result = 0
            For i = 0 To Count - 1
              SelectElement(Options(), i)
              If ((Not Options()\Invalid) And (GetGadgetItemState(ListGadget, i) & SelFlag))
                Options()\Value = #True
                Result + 1
              Else
                Options()\Value = #False
              EndIf
            Next i
            If ((Result = 0) And (Not (Flags & #ListReq_AllowNoSel)))
              ExitFlag = #False
            EndIf
          
          ; Verify a single selection
          Else
            Selected = GetGadgetState(ListGadget)
            If (Selected >= 0)
              SelectElement(Options(), Selected)
              If (Not Options()\Invalid)
                Result = Selected
              Else
                ExitFlag = #False
              EndIf
            Else
              ExitFlag = #False
            EndIf
          EndIf
          TryOption = #False
        EndIf
        
      Until (ExitFlag)
      CloseWindow(Window)
      UseGadgetList(PrevGadgetList)
      
      ; Select chosen list element, return its Value if desired
      If ((Result >= 0) And (Not (Flags & #ListReq_MultiSelect)))
        SelectElement(Options(), Result)
        If (Flags & #ListReq_ReturnVal)
          Result = Options()\Value
        EndIf
      EndIf
      
    Else
      Result = #ListReq_Error
    EndIf
    
    ; Free up parent window
    If (IsWindow(ParentWin))
      DisableWindow(ParentWin, #False)
      SetActiveWindow(ParentWin)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure















;
; *Result.ListReq = AddListReqOption(List Options.ListReq(), Text.s, [ Value.i, [ ImageID.i, [ Invalid.i ]]] )
; 
;   Text    : The actual Option text the user will see
;   Value   : With #ListReq_MultiSelect, set this #True to pre-select (will be set as #True if chosen by user)
;             With #ListReq_ReturnVal, this is the numeric Value that will be returned if the user selects this
;   ImageID : Valid image ID for this Option's icon (not valid with ListView)
;   Invalid : This option is visible but cannot be chosen (#True or #False)
;
Procedure.i AddListReqOption(List Options.ListReq(), Text.s, Value.i = #Null, ImageID.i = #Null, Invalid.i = #False)
  Protected *Result.ListReq = #Null
  
  *Result = AddElement(Options())
  *Result\Text    = Text
  *Result\Value   = Value
  *Result\ImageID = ImageID
  *Result\Invalid = Invalid
  
  ProcedureReturn (*Result)
EndProcedure



; Clear the provided ListReq options
Procedure ClearListReqOptions(List Options.ListReq())
  ClearList(Options())
EndProcedure



; Sorts the provided ListReq options, alphabetically or by value, ascending or descending
;
;   Flags : Bitwise-OR combination of:
;             #ListReq_Alphabetical
;             #ListReq_ByValue
;             #ListReq_Ascending
;             #ListReq_Descending
;
Procedure SortListReqOptions(List Options.ListReq(), Flags.i = #Null)
  Protected Order.i
  
  If (ListSize(Options()) > 0)
    If (Flags & #ListReq_Descending)
      Order = #PB_Sort_Descending
    Else
      Order = #PB_Sort_Ascending
    EndIf
    If (Flags & #ListReq_ByValue)
      SortStructuredList(Options(), Order, OffsetOf(ListReq\Value), #PB_Sort_Integer)
    Else
      SortStructuredList(Options(), Order | #PB_Sort_NoCase, OffsetOf(ListReq\Text), #PB_Sort_String)
    EndIf
  EndIf
EndProcedure











;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)

; Color Constants
#White = $FFFFFF
#Red   = $0000FF
#Green = $00FF00
#Blue  = $FF0000


; Simple procedure to create colored square images
Procedure.i xListReq_ColorIcon(Color.i)
  Protected img.i = CreateImage(#PB_Any, 16, 16)
  
  If (img)
    If (StartDrawing(ImageOutput(img)))
      Box(0, 0, ImageWidth(img),   ImageHeight(img),   #White)
      Box(1, 1, ImageWidth(img)-2, ImageHeight(img)-2,  Color)
      StopDrawing()
    EndIf
    img = ImageID(img)
  EndIf
  
  ProcedureReturn (img)
EndProcedure





;- Example 1
NewList LRO.ListReq()
  AddListReqOption(LRO(), "Choose this...")
  AddListReqOption(LRO(), "this...")
  AddListReqOption(LRO(), " ...", 0, 0, #True)
  AddListReqOption(LRO(), "or this.")

If (ListRequester("Example 1", "Default requester (ListIcon, choose exactly one)", LRO()) >= 0)
  MessageRequester("Example 1", "You chose: " + LRO()\Text)
EndIf


;- Example 2
ClearListReqOptions(LRO())
  AddListReqOption(LRO(), "Option A")
  AddListReqOption(LRO(), "Option B")
  AddListReqOption(LRO(), "Option C")

If (ListRequester("Example 2", "MultiSelect (choose AT LEAST one) and Sticky", LRO(), #ListReq_MultiSelect | #ListReq_Sticky)) > 0
  ForEach (LRO())
    If (LRO()\Value)
      MessageRequester("Example 2", "Selected: " + LRO()\Text)
    EndIf
  Next
EndIf

;- Example 3
NewList LRO.ListReq()
  AddListReqOption(LRO(), "LV-1")
  AddListReqOption(LRO(), "LV-2")
  AddListReqOption(LRO(), "LV-3")
  AddListReqOption(LRO(), "LV-4")
  AddListReqOption(LRO(), "LV-5")
  AddListReqOption(LRO(), "LV-6")

If (ListRequester("Example 3", "ListView, with 'edge' button placement", LRO(), #ListReq_ListView | #ListReq_EdgeButtons) >= 0)
  MessageRequester("Example 3", "You chose: " + LRO()\Text)
EndIf

;- Example 4
NewList LRO.ListReq()
  AddListReqOption(LRO(), "these")
  AddListReqOption(LRO(), "words")
  AddListReqOption(LRO(), "don't")
  AddListReqOption(LRO(), "really")
  AddListReqOption(LRO(), "matter")

SortListReqOptions(LRO(), #ListReq_Alphabetical)

Define Count.i =ListRequester("Example 4", "MultiSelect ListView, sorted, zero-selection allowed", LRO(), #ListReq_ListView | #ListReq_MultiSelect | #ListReq_AllowNoSel)
If (Count >= 0)
  MessageRequester("Example 4", "You chose " + Str(Count) + " of " + Str(ListSize(LRO())) + " options")
EndIf

;- Example 5
NewList LRO.ListReq()
  AddListReqOption(LRO(), "Audio", 0, 0, #True)
  AddListReqOption(LRO(), ".wav", 1)
  AddListReqOption(LRO(), ".mp3", 1)
  AddListReqOption(LRO(), "Video", 0, 0, #True)
  AddListReqOption(LRO(), ".avi", 1)
  AddListReqOption(LRO(), ".mpg", 1)
  AddListReqOption(LRO(), "Text", 0, 0, #True)
  AddListReqOption(LRO(), ".txt", 1)
  AddListReqOption(LRO(), ".doc", 1)

If (ListRequester("Example 5", "TreeGadget with variable levels, custom size", LRO(), #ListReq_Tree | #ListReq_TreeLevels, -1, 0, 360, 240) >= 0)
  MessageRequester("Example 5", "File type: " + LRO()\Text)
EndIf

;- Example 6
NewList LRO.ListReq()
  AddListReqOption(LRO(), "RED", #Red, xListReq_ColorIcon(#Red))
  AddListReqOption(LRO(), "GREEN", #Green, xListReq_ColorIcon(#Green))
  AddListReqOption(LRO(), "BLUE", #Blue, xListReq_ColorIcon(#Blue))

Define Count.i =ListRequester("Example 6", "Tree with images, returns value (not option index)", LRO(), #ListReq_Tree | #ListReq_ReturnVal)
If (Count >= 0)
  MessageRequester("Example 6", "Color " + Str(ListIndex(LRO())+1) + ": $" + RSet(Hex(Count), 6, "0"))
EndIf

;- Example 7
NewList LRO.ListReq()
  AddListReqOption(LRO(), "Yes 1", #True)
  AddListReqOption(LRO(), "No 2", #False)
  AddListReqOption(LRO(), "Yes 3", #True)
  AddListReqOption(LRO(), "Yes 4", #True)
  AddListReqOption(LRO(), "No 5", #False)

ListRequester("Example 7", "Tree with pre-selected options", LRO(), #ListReq_Tree | #ListReq_MultiSelect)

CompilerEndIf
CompilerEndIf
;-