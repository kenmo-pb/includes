; +-----------------+
; | JSON_Helper.pbi |
; +-----------------+
; | 2015.07.09 . Creation (PureBasic 5.31)
; | 2016.03.02 . Added Create, Compose, AddMember/Element, First/Next procs
; |        .05 . Added IsJSON<Type>() macros
; | 2017.04.24 . Cleanup

CompilerIf (Not Defined(_JSON_Helper_Included, #PB_Constant))
#_JSON_Helper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;-
;- Constants (Public)

; JSON Value Types
#JSON_Array   = #PB_JSON_Array
#JSON_Boolean = #PB_JSON_Boolean
#JSON_Null    = #PB_JSON_Null
#JSON_Number  = #PB_JSON_Number
#JSON_Object  = #PB_JSON_Object
#JSON_String  = #PB_JSON_String

; JSON Array Indexes
#JSON_First =  0
#JSON_Last  = -1

; JSON Compose Options
#JSON_UseTabIndent = -1






;-
;- Procedures (Public)

;-
;- - Top-level Managment

Procedure.i MainJSONArray(JSON.i)
  Protected *Object = #Null
  If (IsJSON(JSON))
    *Object = JSONValue(JSON)
    If (JSONType(*Object) <> #JSON_Array)
      *Object = #Null
    EndIf
  EndIf
  ProcedureReturn (*Object)
EndProcedure

Procedure.i MainJSONObject(JSON.i)
  Protected *Object = #Null
  If (IsJSON(JSON))
    *Object = JSONValue(JSON)
    If (JSONType(*Object) <> #JSON_Object)
      *Object = #Null
    EndIf
  EndIf
  ProcedureReturn (*Object)
EndProcedure

Procedure.i CreateJSONArray(JSON.i, Flags.i = #Null)
  Protected Result.i = CreateJSON(JSON, Flags)
  If (Result)
    If (JSON = #PB_Any)
      JSON = Result
    Else
      Result = JSONValue(JSON)
    EndIf
    SetJSONArray(JSONValue(JSON))
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateJSONObject(JSON.i, Flags.i = #Null)
  Protected Result.i = CreateJSON(JSON, Flags)
  If (Result)
    If (JSON = #PB_Any)
      JSON = Result
    Else
      Result = JSONValue(JSON)
    EndIf
    SetJSONObject(JSONValue(JSON))
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- - Traversing by Path

Procedure.i JSONNodeFromPath(*Parent, Path.s, Type.i = #PB_Any)
  Protected *Node = *Parent
  If (*Parent)
    Protected Name.s
    Protected *Start.CHARACTER = @Path
    Protected *C.CHARACTER = *Start
    While (#True)
      Select (*C\c)
        Case 'a' To 'z', 'A' To 'Z', '0' To '9', '_'
          ; OK
        Default
          If (*C > *Start)
            Name = PeekS(*Start, (*C - *Start)/SizeOf(CHARACTER))
            If (JSONType(*Node) = #JSON_Object)
              *Node = GetJSONMember(*Node, Name)
              If (Not *Node)
                Break
              EndIf
            Else
              *Node = #Null
              Break
            EndIf
          EndIf
          If (*C\c = '[')
            If (JSONType(*Node) = #JSON_Array)
              *Start = *C + SizeOf(CHARACTER)
              Repeat
                *C + SizeOf(CHARACTER)
              Until ((*C\c = ']') Or (*C\c = #NUL))
              If (*C\c = ']')
                Name = PeekS(*Start, (*C - *Start)/SizeOf(CHARACTER))
                Protected i.i = Val(Name)
                If ((i >= 0) And (i < JSONArraySize(*Node)))
                  *Node = GetJSONElement(*Node, i)
                  *Start = *C + SizeOf(CHARACTER)
                  Select (*Start\c)
                    Case '.', '/', '\', '[', #NUL
                      ; OK
                    Default
                      *Node = #Null
                      Break
                  EndSelect
                Else
                  *Node = #Null
                  Break
                EndIf
              Else
                *Node = #Null
                Break
              EndIf
            Else
              *Node = #Null
              Break
            EndIf
          EndIf
          If (*C\c = #NUL)
            Break
          EndIf
          *Start = *C + SizeOf(CHARACTER)
      EndSelect
      *C + SizeOf(CHARACTER)
    Wend
    If (*Node)
      If ((Type = #PB_Any) Or (JSONType(*Node) = Type))
        ; OK
      Else
        *Node = #Null
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Node)
EndProcedure

Procedure.i JSONIntegerFromPath(*Parent, Path.s)
  Protected Result.i = 0
  Protected *Node = JSONNodeFromPath(*Parent, Path, #JSON_Number)
  If (*Node)
    Result = GetJSONInteger(*Node)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s JSONStringFromPath(*Parent, Path.s)
  Protected Result.s = ""
  Protected *Node = JSONNodeFromPath(*Parent, Path, #JSON_String)
  If (*Node)
    Result = GetJSONString(*Node)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i JSONObjectFromPath(*Parent, Path.s)
  ProcedureReturn (JSONNodeFromPath(*Parent, Path, #JSON_Object))
EndProcedure

Procedure.i JSONArrayFromPath(*Parent, Path.s)
  ProcedureReturn (JSONNodeFromPath(*Parent, Path, #JSON_Array))
EndProcedure

;-
;- - Traversing by Parent

Procedure.i FirstJSONChild(*Parent)
  Protected *Result = #Null
  If (*Parent)
    If (JSONType(*Parent) = #PB_JSON_Object)
      If (ExamineJSONMembers(*Parent))
        If (NextJSONMember(*Parent))
          *Result = JSONMemberValue(*Parent)
        EndIf
      EndIf
    ElseIf (JSONType(*Parent) = #PB_JSON_Array)
      *Result = GetJSONElement(*Parent, 0)
    EndIf
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.i NextJSONChild(*Parent, *Current)
  Protected *Result = #Null
  If (*Parent And *Current)
    If (JSONType(*Parent) = #PB_JSON_Object)
      If (ExamineJSONMembers(*Parent))
        Protected ReturnNext.i = #False
        While (NextJSONMember(*Parent))
          If (ReturnNext)
            *Result = JSONMemberValue(*Parent)
            Break
          ElseIf (JSONMemberValue(*Parent) = *Current)
            ReturnNext = #True
          EndIf
        Wend
      EndIf
    ElseIf (JSONType(*Parent) = #PB_JSON_Array)
      Protected n.i = JSONArraySize(*Parent)
      Protected i.i
      For i = 0 To n - 2
        If (GetJSONElement(*Parent, i) = *Current)
          *Result = GetJSONElement(*Parent, i + 1)
          Break
        EndIf
      Next i
    EndIf
  EndIf
  ProcedureReturn (*Result)
EndProcedure

;-
;- - Compose String Output

Macro ComposeJSONPretty(JSON)
  ComposeJSON((JSON), #PB_JSON_PrettyPrint)
EndMacro

Procedure.s ComposeJSONTiny(JSON)
  Protected Raw.s = ComposeJSON(JSON)
  Protected Result.s = Raw
  Protected InString.i = #False
  Protected *CI.CHARACTER = @Raw
  Protected *CO.CHARACTER = @Result
  While (*CI\c)
    If ((*CI\c = ' ') And (Not InString))
      ;
    Else
      If (*CI\c = '"')
        InString = Bool(Not InString)
      EndIf
      *CO\c = *CI\c
      *CO + SizeOf(CHARACTER)
    EndIf
    *CI + SizeOf(CHARACTER)
  Wend
  *CO\c = #NUL
  ProcedureReturn (Result)
EndProcedure

Procedure.s ComposeJSONEx(JSON, IndentSpaces.i, NewLine.s = "")
  Protected Raw.s = ComposeJSON(JSON, #PB_JSON_PrettyPrint)
  If (FindString(Raw, #CRLF$))
    If (NewLine = "")
      NewLine = #CRLF$
    EndIf
    Raw = ReplaceString(Raw, #CRLF$, #LF$)
  ElseIf (FindString(Raw, #CR$))
    If (NewLine = "")
      NewLine = #CR$
    EndIf
    Raw = ReplaceString(Raw, #CR$, #LF$)
  Else
    If (NewLine = "")
      NewLine = #LF$
    EndIf
  EndIf
  Protected n.i = 1 + CountString(Raw, #LF$)
  Protected Result.s
  Protected i.i
  For i = 1 To n
    Protected Line.s = StringField(Raw, i, #LF$)
    If (i > 1)
      Result + NewLine
    EndIf
    Protected Indent.i = 0
    Protected *C.CHARACTER = @Line
    While (*C\c = ' ')
      Indent + 1
      *C + SizeOf(CHARACTER)
    Wend
    Indent / 2
    If (Indent)
      If (IndentSpaces >= 1)
        Result + Space(Indent * IndentSpaces)
      ElseIf (IndentSpaces < 0)
        Result + RSet("", Indent, #TAB$)
      EndIf
    EndIf
    Result + PeekS(*C)
  Next i
  ProcedureReturn (Result)
EndProcedure

;-
;- - Add Members to Object

Procedure.i AddJSONMemberArray(*Parent, Key.s)
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONArray(*Result)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONMemberBoolean(*Parent, Key.s, Value.i = #False)
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONBoolean(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONMemberDouble(*Parent, Key.s, Value.d = 0.0)
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONDouble(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONMemberInteger(*Parent, Key.s, Value.i = 0)
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONInteger(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONMemberObject(*Parent, Key.s)
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONObject(*Result)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONMemberString(*Parent, Key.s, Text.s = "")
  Protected *Result = AddJSONMember(*Parent, Key)
  SetJSONString(*Result, Text)
  ProcedureReturn (*Result)
EndProcedure


;-
;- - Add Elements to Array

Procedure.i AddJSONElementArray(*Parent, Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONArray(*Result)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONElementBoolean(*Parent, Value.i = #False, Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONBoolean(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONElementDouble(*Parent, Value.d = 0.0, Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONDouble(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONElementInteger(*Parent, Value.i = 0, Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONInteger(*Result, Value)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONElementObject(*Parent, Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONObject(*Result)
  ProcedureReturn (*Result)
EndProcedure

Procedure.i AddJSONElementString(*Parent, Text.s = "", Index.i = #JSON_Last)
  Protected n.i = JSONArraySize(*Parent)
  If ((Index < 0) Or (Index > n))
    Index = n
  EndIf
  Protected *Result = AddJSONElement(*Parent, Index)
  SetJSONString(*Result, Text)
  ProcedureReturn (*Result)
EndProcedure

;-
;- - Check JSON Value Type

Macro IsJSONArray(Value)
  Bool(JSONType(Value) = #JSON_Array)
EndMacro

Macro IsJSONBoolean(Value)
  Bool(JSONType(Value) = #JSON_Boolean)
EndMacro

Macro IsJSONNull(Value)
  Bool(JSONType(Value) = #JSON_Null)
EndMacro

Macro IsJSONNumber(Value)
  Bool(JSONType(Value) = #JSON_Number)
EndMacro

Macro IsJSONObject(Value)
  Bool(JSONType(Value) = #JSON_Object)
EndMacro

Macro IsJSONString(Value)
  Bool(JSONType(Value) = #JSON_String)
EndMacro






;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

*Array = CreateJSONArray(0)
AddJSONElementString(*Array, "abc")
AddJSONElementString(*Array, "def", #JSON_Last)
AddJSONElementString(*Array, "ghi", 5) ; Out of bounds, so Last
AddJSONElementString(*Array, "ONE", 1) ; Position 1 (0-based)
*Child = FirstJSONChild(*Array)
While (*Child)
  ;Debug GetJSONString(*Child)
  *Child = NextJSONChild(*Array, *Child)
Wend
Debug ComposeJSONTiny(0)

*Object = CreateJSONObject(0)
AddJSONMemberString(*Object, "name", "John Doe")
AddJSONMemberInteger(*Object, "height", 58)
*Child = AddJSONMemberArray(*Object, "favoriteMovies")
  AddJSONElementString(*Child, "Smoke")
  AddJSONElementString(*Child, "Mirrors")
*Child = FirstJSONChild(*Array)
Debug ""
Debug ComposeJSONPretty(0)



CompilerEndIf
CompilerEndIf
;-