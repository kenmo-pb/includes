; +-------+--------------+
; | OJSON | Ordered JSON |
; +-------+--------------+
; | 2018-02-09 . Version 1.00 (adapted from JSON.pbi ver 1.20)


; ABOUT:
; This is adapted from JSON.pbi, an include/module written in 2014
; before PureBasic added its own JSON library in version 5.30.
; 
; The main benefit over PB's JSON library is that the order of
; an Object's members is preserved - sometimes this is important!
;
; All custom constants and procedures here have been renamed
; "OJSON" (for Ordered JSON) to avoid compile conflicts in PB 5.30+.
;
; The names were based on PB's XML libary, which is why
; they are different from PB's later JSON library.


;-
CompilerIf (Not Defined(_OJSON_Included, #PB_Constant))
#_OJSON_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Constants (Public)

; OJSON module version (123 = 1.23)
#OJSON_Version = 100

; OJSON node types
CompilerIf (#PB_Compiler_Version >= 530)
  #OJSON_Number  = #PB_JSON_Number
  #OJSON_String  = #PB_JSON_String
  #OJSON_Boolean = #PB_JSON_Boolean
  #OJSON_Array   = #PB_JSON_Array
  #OJSON_Object  = #PB_JSON_Object
  #OJSON_Null    = #PB_JSON_Null
  #OJSON_Invalid = 6
CompilerElse
  #OJSON_Number  = 0
  #OJSON_String  = 1
  #OJSON_Boolean = 2
  #OJSON_Array   = 3
  #OJSON_Object  = 4
  #OJSON_Null    = 5
  #OJSON_Invalid = 6
CompilerEndIf

; SaveOJSON() formats
#OJSON_Compact  = $0001
#OJSON_Indented = $0002

; Other OJSON constants
#OJSON_Default  = -1
#OJSON_First    =  0
#OJSON_Last     = -1






;-
;- Declares (Public)

; OJSON management
Declare.i CreateOJSON(MainNodeType = #OJSON_Object)
Declare.i CatchOJSON(*Address, Length)
Declare.i LoadOJSON(File.s)
Declare.i SaveOJSON(*OJSON, File.s, Format = #OJSON_Default, IndentSize = 4)
Declare.i FreeOJSON(*OJSON)

; OJSON node management
Declare.i CreateOJSONNode(*Parent, Type = #OJSON_Object, Key.s = "", *Previous = #OJSON_Last)
Declare.i DeleteOJSONNode(*Node)
Declare.i AddOJSONString(*Parent, Text.s, Key.s = "", *Previous = #OJSON_Last)
Declare.i AddOJSONNumber(*Parent, Value.f, Key.s = "", *Previous = #OJSON_Last)
Declare.i AddOJSONBoolean(*Parent, Value, Key.s = "", *Previous = #OJSON_Last)
Declare.i AddOJSONNull(*Parent, Key.s = "", *Previous = #OJSON_Last)
Declare.i AddOJSONArray(*Parent, Key.s = "", *Previous = #OJSON_Last)
Declare.i AddOJSONObject(*Parent, Key.s = "", *Previous = #OJSON_Last)

; OJSON node iteration
Declare.i MainOJSONNode(*OJSON)
Declare.i ChildOJSONNode(*Node, Index = #OJSON_First)
Declare.i ParentOJSONNode(*Node)
Declare.i NextOJSONNode(*Node)
Declare.i PreviousOJSONNode(*Node)
Declare.i NamedOJSONNode(*Node, Path.s)
Declare.i FindOJSONNodeByID(*Node, Text.s, Key.s = "id")

; OJSON node access
Declare.s GetOJSONNodeText(*Node)
Declare.f GetOJSONNodeValue(*Node)
Declare.i GetOJSONNodeInteger(*Node)
Declare.s GetOJSONNodeKey(*Node)
Declare.i GetOJSONChildCount(*Node)
Declare.i GetOJSONNodeType(*Node)
Declare.s GetOJSONTypeName(Type)

; OJSON node modification
Declare.i SetOJSONNodeText(*Node, Text.s)
Declare.i SetOJSONNodeValue(*Node, Value.f)
Declare.i SetOJSONNodeKey(*Node, Key.s)




























;-
;- Constants (Private)

; OJSON type constants
#_OJSON_Types = 7

; OJSON node flags
#_OJSON_IsRoot = $0001



;-
;- Structures (Private)

Structure OJSONNODE
  *Parent.OJSONNODE
  Key.s
  Type.i
  Raw.s
  String.s
  Number.f
  Flags.i
  ;
  *First.OJSONNODE
  *Last.OJSONNODE
  Children.i
  ;
  *Next.OJSONNODE
  *Prev.OJSONNODE
EndStructure


;-
;- Macros (Private)

CompilerIf (#PB_Compiler_Unicode)
  
  Macro _Unicode()
    (#True)
  EndMacro
  Macro _CharSize()
    (2)
  EndMacro
  Macro _ToBytes(Chars)
    ((Chars) * 2)
  EndMacro
  Macro _ToChars(Bytes)
    ((Bytes) / 2)
  EndMacro
  
CompilerElse
  
  Macro _Unicode()
    (#False)
  EndMacro
  Macro _CharSize()
    (1)
  EndMacro
  Macro _ToBytes(Chars)
    (Chars)
  EndMacro
  Macro _ToChars(Bytes)
    (Bytes)
  EndMacro
CompilerEndIf



;-
;- Declares (Private)

Declare.i _ParseOJSONString(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER, *Unescape.INTEGER = #Null)
Declare.i _ParseOJSONNode(*JN.OJSONNODE, *Address, Length.i)


;-
;- Procedures (Private)

Procedure.s _EscapeOJSONString(String.s)
  Protected Build.s = ""
  Protected *C.CHARACTER = @String
  While (*C\c)
    Select (*C\c)
      Case '"'
        Build + "\" + #DQUOTE$
      Case '\'
        Build + "\\"
      ;Case '/'
      ;  Build + "\/"
      Case #BS
        Build + "\b"
      Case #FF
        Build + "\f"
      Case #LF
        Build + "\n"
      Case #CR
        Build + "\r"
      Case #TAB
        Build + "\t"
      Default
        If ((*C\c >= $20) And (*C\c <= $FF))
          Build + Chr(*C\c)
        Else
          Build + "\u" + RSet(Hex(*C\c), 4, "0")
        EndIf
    EndSelect
    *C + _CharSize()
  Wend
  ProcedureReturn (Build)
EndProcedure

Procedure.s _UnescapeOJSONString(String.s)
  Protected Result.s = ""
  String = #DQUOTE$ + String + #DQUOTE$
  Protected i.INTEGER
  _ParseOJSONString(#Null, @String, @String + StringByteLength(String), @i)
  If (i\i)
    Result = PeekS(i\i)
    FreeMemory(i\i)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _AddOJSONNode(*JN.OJSONNODE, *Parent.OJSONNODE, *Previous.OJSONNODE)
  If (*JN And *Parent)
    *JN\Parent = *Parent
    *Parent\Children + 1
    If (*Parent\First)
      If (*Previous = #OJSON_First)
        *JN\Prev = #Null
        *JN\Next = *Parent\First
        *Parent\First\Prev = *JN
        *Parent\First = *JN
      ElseIf (*Previous = #OJSON_Last)
        *JN\Prev = *Parent\Last
        *JN\Next = #Null
        *Parent\Last\Next = *JN
        *Parent\Last = *JN
      Else
        If (*Previous\Parent = *Parent)
          *JN\Prev = *Previous
          *JN\Next = *Previous\Next
          *Previous\Next = *JN
          If (*JN\Next)
            *JN\Next\Prev = *JN
          Else
            *Parent\Last = *JN
          EndIf
        Else
          ProcedureReturn (#False)
        EndIf
      EndIf
    Else
      *JN\Prev = #Null
      *JN\Next = #Null
      *Parent\First = *JN
      *Parent\Last  = *JN
    EndIf
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i _CreateOJSONNode(*Parent.OJSONNODE, Type.i, *Previous.OJSONNODE = #OJSON_Last)
  Protected *JN.OJSONNODE = #Null
  If ((Type >= 0) And (Type < #_OJSON_Types))
    *JN = AllocateMemory(SizeOf(OJSONNODE))
    If (*JN)
      If (*Parent)
        If (_AddOJSONNode(*JN, *Parent, *Previous))
          *JN\Type = Type
        Else
          FreeMemory(*JN)
          *JN = #Null
        EndIf
      Else
        *JN\Type   = #OJSON_Array
        *JN\Flags  = #_OJSON_IsRoot
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*JN)
EndProcedure

Procedure.i _ParseOJSONString(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER, *Unescape.INTEGER = #Null)
  Protected Type.i = #OJSON_Invalid
  If ((*JN Or *Unescape) And *Start And (*End > *Start))
    Type.i = #OJSON_String
    Protected *C.CHARACTER = *Start
    Protected *TokenEnd.CHARACTER = #Null
    Protected i.i
    Protected *Build = #Null
    Protected *BC.CHARACTER = #Null
    If (*Unescape)
      *Unescape\i = #Null
    EndIf
    *Build = AllocateMemory((*End - *Start) + _CharSize(), #PB_Memory_NoClear)
    If (*Build)
      *BC = *Build
      Protected Expecting.i  = 0
      While (*C < *End)
        Select (Expecting)
          ; 0 = quote, 1 = characters, 2 = whitespace
          Case 0
            Select (*C\c)
              Case '"'
                Expecting = 1
              Default
                Type = #OJSON_Invalid
            EndSelect
          Case 1
            Select (*C\c)
              Case '"'
                *TokenEnd = *C
                Expecting = 2
              Case '\'
                If (_ToChars(*End - *C) >= 1 + 1)
                  *C + _CharSize()
                  Select (*C\c)
                    Case '"', '\', '/'
                      *BC\c = *C\c
                    Case 'b'
                      *BC\c = #BS
                    Case 'f'
                      *BC\c = #FF
                    Case 'n'
                      *BC\c = #LF
                    Case 'r'
                      *BC\c = #CR
                    Case 't'
                      *BC\c = #TAB
                    Case 'u'
                      If (_ToChars(*End - *C) >= 4 + 1)
                        Protected UValue.u = Val("$" + PeekS(*C + _CharSize(), 4))
                        For i = 1 To 4
                          *C + _CharSize()
                          Select (*C\c)
                            Case '0' To '9', 'a' To 'f', 'A' To 'F'
                              ;
                            Default
                              Type = #OJSON_Invalid
                              Break
                          EndSelect
                        Next i
                        If (Type <> #OJSON_Invalid)
                          CompilerIf (_Unicode())
                            *BC\c = UValue
                          CompilerElse
                            If (UValue <= $FF)
                              *BC\c = UValue
                            Else
                              *BC\c = '?'
                            EndIf
                          CompilerEndIf
                        EndIf
                      Else
                        Type = #OJSON_Invalid
                      EndIf
                    Default
                      Type = #OJSON_Invalid
                  EndSelect
                  *BC + _CharSize()
                Else
                  Type = #OJSON_Invalid
                EndIf
              Case $00 To $1F
                Type = #OJSON_Invalid
              Default
                *BC\c = *C\c
                *BC + _CharSize()
            EndSelect
          Case 2
            Select (*C\c)
              Case ' ', #TAB, #CR, #LF
                ;
              Default
                Type = #OJSON_Invalid
            EndSelect
        EndSelect
        If (Type = #OJSON_Invalid)
          Break
        EndIf
        *C + _CharSize()
      Wend
      If (*TokenEnd = #Null)
        *TokenEnd = *End
      EndIf
      *BC\c = #NUL
      If (Type <> #OJSON_Invalid)
        If (Expecting = 2)
          If (*JN)
            *JN\Type   = Type
            *JN\Raw    = PeekS(*Start + _CharSize(), _ToChars(*TokenEnd - *Start) - 1)
            *JN\String = PeekS(*Build)
            *JN\Number = 0.0
          EndIf
        Else
          Type = #OJSON_Invalid
        EndIf
      EndIf
      If (*Unescape And (Type = #OJSON_String))
        *Unescape\i = *Build
      Else
        FreeMemory(*Build)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i _ParseOJSONNumber(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #OJSON_Invalid
  If (*Start And (*End > *Start))
    Type.i = #OJSON_Number
    Protected *C.CHARACTER = *Start
    Protected *TokenEnd.CHARACTER = #Null
    Protected IntDigits.i  =  0
    Protected FracDigits.i = -1
    Protected ExpDigits.i  = -1
    Protected Expecting.i  =  0
    While (*C < *End)
      Select (Expecting)
        ; 0 = sign, 1 = int, 2 = frac, 3 = expsign, 4 = exp, 5 = whitespace
        Case 0
          Select (*C\c)
            Case '-'
              Expecting = 1
            Case '0' To '9'
              IntDigits + 1
              Expecting = 1
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 1
          Select (*C\c)
            Case '0' To '9'
              IntDigits + 1
            Case '.'
              FracDigits = 0
              Expecting  = 2
            Case 'e', 'E'
              ExpDigits = 0
              Expecting = 3
            Case ' ', #TAB, #CR, #LF
              *TokenEnd = *C
              Expecting =  5
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 2
          Select (*C\c)
            Case '0' To '9'
              FracDigits + 1
            Case 'e', 'E'
              ExpDigits = 0
              Expecting = 3
            Case ' ', #TAB, #CR, #LF
              *TokenEnd = *C
              Expecting = 5
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 3
          Select (*C\c)
            Case '0' To '9'
              ExpDigits + 1
              Expecting = 4
            Case '+', '-'
              Expecting = 4
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 4
          Select (*C\c)
            Case '0' To '9'
              ExpDigits + 1
            Case ' ', #TAB, #CR, #LF
              *TokenEnd = *C
              Expecting = 5
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 5
          Select (*C\c)
            Case ' ', #TAB, #CR, #LF
              ;
            Default
              Type = #OJSON_Invalid
          EndSelect
      EndSelect
      If (Type = #OJSON_Invalid)
        Break
      EndIf
      *C + _CharSize()
    Wend
    If (*TokenEnd = #Null)
      *TokenEnd = *End
    EndIf
    If (Type <> #OJSON_Invalid)
      If ((IntDigits > 0) And (FracDigits <> 0) And (ExpDigits <> 0))
        If (*JN)
          *JN\Type   =  Type
          *JN\Raw    =  PeekS(*Start, _ToChars(*TokenEnd - *Start))
          *JN\String = *JN\Raw
          *JN\Number =  ValF(*JN\String)
        EndIf
      Else
        Type = #OJSON_Invalid
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i _ParseOJSONWord(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #OJSON_Invalid
  If (*JN And *Start And (*End > *Start))
    Type.i = #OJSON_Null
    Protected *C.CHARACTER = *Start
    Protected *TokenEnd.CHARACTER = #Null
    Protected Expecting.i  =  0
    While (*C < *End)
      Select (Expecting)
        ; 0 = characters, 1 = whitespace
        Case 0
          Select (*C\c)
            Case 'a' To 'z', 'A' To 'Z', '0' To '9', '_'
              ;
            Case ' ', #TAB, #CR, #LF
              *TokenEnd = *C
              Expecting = 1
            Default
              Type = #OJSON_Invalid
          EndSelect
        Case 1
          Select (*C\c)
            Case ' ', #TAB, #CR, #LF
              ;
            Default
              Type = #OJSON_Invalid
          EndSelect
      EndSelect
      If (Type = #OJSON_Invalid)
        Break
      EndIf
      *C + _CharSize()
    Wend
    If (*TokenEnd = #Null)
      *TokenEnd = *End
    EndIf
    If (Type <> #OJSON_Invalid)
      Protected Raw.s = PeekS(*Start, _ToChars(*TokenEnd - *Start))
      Select (Raw)
        Case "true"
          Type       = #OJSON_Boolean
          *JN\Number =  1.0
        Case "false"
          Type       = #OJSON_Boolean
          *JN\Number =  0.0
        Case "null"
          Type       = #OJSON_Null
          *JN\Number =  0.0
        Default
          Type = #OJSON_Invalid
      EndSelect
      If (Type <> #OJSON_Invalid)
        *JN\Type   = Type
        *JN\Raw    = Raw
        *JN\String = Raw
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i _SkipOJSONWhitespace(*Start.CHARACTER, *End.CHARACTER)
  If (*Start And (*End >= *Start))
    While (*Start < *End)
      Select (*Start\c)
        Case ' ', #TAB, #CR, #LF
          ;
        Default
          Break
      EndSelect
      *Start + _CharSize()
    Wend
  Else
    *Start = #Null
  EndIf
  ProcedureReturn (*Start)
EndProcedure

Procedure.i _IsOJSONWhitespace(*Start.CHARACTER, *End.CHARACTER)
  If (*Start And (*End >= *Start))
    ProcedureReturn (Bool(_SkipOJSONWhitespace(*Start, *End) = *End))
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i _FindOJSONClose(*Start.CHARACTER, *End.CHARACTER, Symbol.c, AllowAfter.i)
  Protected *Found.CHARACTER = #Null
  
  If (*Start And (*End > *Start))
    Protected *C.CHARACTER = *Start
    Protected Sublevel.i  = 0
    Protected Expecting.i = 0
    While (*C < *End)
      Select (Expecting)
        ; 0 = data, 1 = inString, 2 = whitespace
        Case 0
          If ((*C\c = Symbol) And (Sublevel = 0))
            *Found = *C
            If (AllowAfter)
              Break
            Else
              Expecting = 2
            EndIf
          Else
            Select (*C\c)
              Case '{', '['
                Sublevel + 1
              Case '}', ']'
                Sublevel - 1
                If (Sublevel < 0)
                  Break
                EndIf
              Case '"'
                Expecting = 1
              Default
                ;
            EndSelect
          EndIf
        Case 1
          Select (*C\c)
            Case '"'
              Expecting = 0
            Case $00 To $1F
              Break
            Case '\'
              If (_ToChars(*End - *C) >= 1 + 1)
                *C + _CharSize()
                Select (*C\c)
                  Case '"', '\', '/', 'b', 'f', 'r', 'n', 't'
                    ;
                  Case 'u'
                    If (_ToChars(*End - *C) >= 4 + 1)
                      *C + 4 * _CharSize()
                    Else
                      Break
                    EndIf
                  Default
                    Break
                EndSelect
              Else
                Break
              EndIf
            Default
              ;
          EndSelect
        Case 2
          Select (*C\c)
            Case ' ', #TAB, #CR, #LF
              ;
            Default
              *Found = #Null
              Break
          EndSelect
      EndSelect
      *C + _CharSize()
    Wend
  EndIf
  
  ProcedureReturn (*Found)
EndProcedure

Procedure.i _ParseOJSONObject(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #OJSON_Invalid
  If (*JN And *Start And (*End > *Start))
    If (*Start\c = '{')
      Protected *NodeEnd.CHARACTER = _FindOJSONClose(*Start + _CharSize(), *End, '}', #False)
      If (*NodeEnd)
        Type = #OJSON_Object
        *Start + _CharSize()
        Protected *PairEnd.CHARACTER
        Repeat
          *Start = _SkipOJSONWhitespace(*Start, *NodeEnd)
          *PairEnd = _FindOJSONClose(*Start, *NodeEnd, ',', #True)
          If (Not *PairEnd)
            If (Not _IsOJSONWhitespace(*Start, *NodeEnd))
              *PairEnd = *NodeEnd
            EndIf
          EndIf
          If (*PairEnd)
            Type = #OJSON_Invalid
            Protected *Divider.CHARACTER = _FindOJSONClose(*Start, *PairEnd - _CharSize(), ':', #True)
            If ((*Divider > *Start) And (*Divider < *PairEnd))
              Protected NamePtr.INTEGER
              _ParseOJSONString(#Null, *Start, *Divider, @NamePtr)
              If (NamePtr\i)
                Protected *Child.OJSONNODE = _CreateOJSONNode(*JN, #OJSON_Invalid)
                If (*Child)
                  *Divider + _CharSize()
                  If (_ParseOJSONNode(*Child, *Divider, *PairEnd - *Divider) <> #OJSON_Invalid)
                    *Child\Key = PeekS(NamePtr\i)
                    Type = #OJSON_Object
                  Else
                    DeleteOJSONNode(*Child)
                  EndIf
                EndIf
                FreeMemory(NamePtr\i)
              EndIf
            EndIf
            *Start = *PairEnd + _CharSize()
          EndIf
        Until ((Not *PairEnd) Or (*Start >= *NodeEnd) Or (Type = #OJSON_Invalid))
        If (Type = #OJSON_Object)
          *JN\Type   =  Type
          *JN\Raw    = ""
          *JN\String = ""
          *JN\Number =  0.0
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i _ParseOJSONArray(*JN.OJSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #OJSON_Invalid
  If (*JN And *Start And (*End > *Start))
    If (*Start\c = '[')
      Protected *NodeEnd.CHARACTER = _FindOJSONClose(*Start + _CharSize(), *End, ']', #False)
      If (*NodeEnd)
        Type = #OJSON_Array
        *Start + _CharSize()
        Protected *ItemEnd.CHARACTER
        Repeat
          *Start = _SkipOJSONWhitespace(*Start, *NodeEnd)
          *ItemEnd = _FindOJSONClose(*Start, *NodeEnd, ',', #True)
          If (Not *ItemEnd)
            If (Not _IsOJSONWhitespace(*Start, *NodeEnd))
              *ItemEnd = *NodeEnd
            EndIf
          EndIf
          If (*ItemEnd)
            Type = #OJSON_Invalid
            Protected *Child.OJSONNODE = _CreateOJSONNode(*JN, #OJSON_Invalid)
            If (*Child)
              If (_ParseOJSONNode(*Child, *Start, *ItemEnd - *Start) <> #OJSON_Invalid)
                Type = #OJSON_Array
              Else
                DeleteOJSONNode(*Child)
              EndIf
            EndIf
            *Start = *ItemEnd + _CharSize()
          EndIf
        Until ((Not *ItemEnd) Or (*Start >= *NodeEnd) Or (Type = #OJSON_Invalid))
        If (Type = #OJSON_Array)
          *JN\Type   =  Type
          *JN\Raw    = ""
          *JN\String = ""
          *JN\Number =  0.0
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i _ParseOJSONNode(*JN.OJSONNODE, *Address, Length.i)
  Protected Type.i = #OJSON_Invalid
  
  If (*JN And (*JN\Type = #OJSON_Invalid))
    If (*Address And (Length > 0))
      Protected *End.CHARACTER = *Address + Length
      Protected *C.CHARACTER   =  _SkipOJSONWhitespace(*Address, *End)
      If (*C < *End)
        Select (*C\c)
          Case '{'
            Type = _ParseOJSONObject(*JN, *C, *End)
          Case '['
            Type = _ParseOJSONArray(*JN, *C, *End)
          Case '"'
            Type = _ParseOJSONString(*JN, *C, *End)
          Case '0' To '9', '-'
            Type = _ParseOJSONNumber(*JN, *C, *End)
          Case 'a' To 'z', 'A' To 'Z', '_'
            Type = _ParseOJSONWord(*JN, *C, *End)
          Default
            ;
        EndSelect
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Type)
EndProcedure

Procedure _WriteOJSONIndent(FN, Indent.i, Level.i)
  If (IsFile(FN))
    If (Indent > 0)
      WriteString(FN, Space(Indent * Level), #PB_Ascii)
    ElseIf (Indent < 0)
      WriteString(FN, RSet("", -Indent * Level, #TAB$), #PB_Ascii)
    EndIf
  EndIf
EndProcedure

Procedure _WriteOJSONNode(FN.i, *JN.OJSONNODE, Format.i, Indent.i, Level.i = 0)
  If (IsFile(FN) And *JN)
    Protected EOL.s
    Protected SP.s
    If (Format & #OJSON_Indented)
      CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
        EOL = #CRLF$
      CompilerElse
        EOL = #LF$
      CompilerEndIf
      SP  = " "
    Else
      EOL = ""
      SP  = ""
    EndIf
    ;
    _WriteOJSONIndent(FN, Indent, Level)
    If (*JN\Key)
      WriteString(FN, #DQUOTE$ + _EscapeOJSONString(*JN\Key) + #DQUOTE$ + ":" + SP, #PB_Ascii)
    EndIf
    Protected *Child.OJSONNODE
    Select (*JN\Type)
      Case #OJSON_Null
        WriteString(FN, "null", #PB_Ascii)
      Case #OJSON_Boolean
        If (*JN\Number)
          WriteString(FN, "true", #PB_Ascii)
        Else
          WriteString(FN, "false", #PB_Ascii)
        EndIf
      Case #OJSON_Number
        WriteString(FN, *JN\Raw, #PB_Ascii)
      Case #OJSON_String
        WriteString(FN, #DQUOTE$ + *JN\Raw + #DQUOTE$, #PB_Ascii)
      Case #OJSON_Object
        WriteString(FN, "{" + EOL, #PB_Ascii)
        *Child = *JN\First
        If (*Child)
          While (#True)
            _WriteOJSONNode(FN, *Child, Format, Indent, Level + 1)
            *Child = *Child\Next
            If (*Child)
              WriteString(FN, "," + EOL, #PB_Ascii)
            Else
              WriteString(FN, EOL, #PB_Ascii)
              Break
            EndIf
          Wend
        EndIf
        _WriteOJSONIndent(FN, Indent, Level)
        WriteString(FN, "}", #PB_Ascii)
      Case #OJSON_Array
        WriteString(FN, "[" + EOL, #PB_Ascii)
        *Child = *JN\First
        If (*Child)
          While (#True)
            _WriteOJSONNode(FN, *Child, Format, Indent, Level + 1)
            *Child = *Child\Next
            If (*Child)
              WriteString(FN, "," + EOL, #PB_Ascii)
            Else
              WriteString(FN, EOL, #PB_Ascii)
              Break
            EndIf
          Wend
        EndIf
        _WriteOJSONIndent(FN, Indent, Level)
        WriteString(FN, "]", #PB_Ascii)
    EndSelect
  EndIf
EndProcedure

;-

Procedure.i DeleteOJSONNode(*JN.OJSONNODE)
  If (*JN And (Not (*JN\Flags & #_OJSON_IsRoot)))
    If ((*JN\Type = #OJSON_Array) Or (*JN\Type = #OJSON_Object))
      Protected *Prev.OJSONNODE
      Protected *Next.OJSONNODE
      Protected *Child.OJSONNODE = *JN\First
      While (*Child)
        *Next = *Child\Next
        DeleteOJSONNode(*Child)
        *Child = *Next
      Wend
    EndIf
    ;
    If (*JN\Parent)
      *Prev = *JN\Prev
      *Next = *JN\Next
      If (*Prev)
        *Prev\Next = *Next
      EndIf
      If (*Next)
        *Next\Prev = *Prev
      EndIf
      If (*JN = *JN\Parent\First)
        *JN\Parent\First = *Next
      EndIf
      If (*JN = *JN\Parent\Last)
        *JN\Parent\Last = *Prev
      EndIf
      *JN\Parent\Children - 1
    EndIf
    FreeMemory(*JN)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i CreateOJSONNode(*Parent.OJSONNODE, Type.i = #OJSON_Object, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *Child.OJSONNODE = #Null
  If ((Type >= 0) And (Type < #_OJSON_Types) And (Type <> #OJSON_Invalid))
    If (*Parent)
      If ((*Parent\Type = #OJSON_Array) Or ((*Parent\Type = #OJSON_Object) And (Key)))
        If ((*Parent\Children = 0) Or (Not (*Parent\Flags & #_OJSON_IsRoot)))
          *Child = _CreateOJSONNode(*Parent, Type, *Previous)
          If (*Child)
            If (*Parent\Type = #OJSON_Object)
              *Child\Key = Key
            EndIf
            Select (Type)
              Case #OJSON_Boolean
                *Child\String = "false"
                *Child\Raw    = *Child\String
              Case #OJSON_Null
                *Child\String = "null"
                *Child\Raw    = *Child\String
              Case #OJSON_Number
                *Child\String = "0"
                *Child\Raw    = *Child\String
            EndSelect
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Child)
EndProcedure

Procedure.i AddOJSONString(*Parent.OJSONNODE, Text.s, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_String, Key, *Previous)
  If (*New)
    SetOJSONNodeText(*New, Text)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddOJSONNumber(*Parent.OJSONNODE, Value.f, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_Number, Key, *Previous)
  If (*New)
    SetOJSONNodeValue(*New, Value)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddOJSONBoolean(*Parent.OJSONNODE, Value.i, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_Boolean, Key, *Previous)
  If (*New)
    SetOJSONNodeValue(*New, Value)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddOJSONNull(*Parent.OJSONNODE, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_Null, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddOJSONArray(*Parent.OJSONNODE, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_Array, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddOJSONObject(*Parent.OJSONNODE, Key.s = "", *Previous.OJSONNODE = #OJSON_Last)
  Protected *New.OJSONNODE = #Null
  *New = CreateOJSONNode(*Parent, #OJSON_Object, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

;-

Procedure.i FreeOJSON(*J.OJSONNODE)
  If (*J And (*J\Flags & #_OJSON_IsRoot))
    *J\Flags & (~#_OJSON_IsRoot)
    DeleteOJSONNode(*J)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i SaveOJSON(*J.OJSONNODE, File.s, Format.i = #OJSON_Default, IndentSize.i = 4)
  Protected Result.i = #False
  If (Format = #OJSON_Default)
    Format = #OJSON_Indented
  EndIf
  If (*J And File)
    Protected FN.i = CreateFile(#PB_Any, File)
    If (FN)
      If (Not (Format & #OJSON_Indented))
        IndentSize = 0
      EndIf
      If (*J\Flags & #_OJSON_IsRoot)
        If (*J\First)
          _WriteOJSONNode(FN, *J\First, Format, IndentSize, 0)
          Result = #True
        EndIf
      Else
        _WriteOJSONNode(FN, *J, Format, IndentSize, 0)
        Result = #True
      EndIf
      CloseFile(FN)
      If (Not Result)
        DeleteFile(File)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CatchOJSON(*Address, Length.i)
  Protected *J.OJSONNODE = #Null
  
  If (*Address And (Length > 0))
    *J = _CreateOJSONNode(#Null, #OJSON_Array)
    If (*J)
      Protected *Main.OJSONNODE = _CreateOJSONNode(*J, #OJSON_Invalid)
      If (*Main)
        ;
        CompilerIf (_Unicode())
          ; Convert apparent ASCII buffer to Unicode buffer
          If ((Length % 2 <> 0) Or (PeekA(*Address + 1) <> #NUL))
            Protected UnicodeCopy.s = PeekS(*Address, Length, #PB_Ascii)
            *Address = @UnicodeCopy
            Length * 2
          EndIf
        CompilerEndIf
        ;
        If (_ParseOJSONNode(*Main, *Address, Length) <> #OJSON_Invalid)
          ; OK
        Else
          *J = FreeOJSON(*J)
        EndIf
      Else
        *J = FreeOJSON(*J)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (*J)
EndProcedure

Procedure.i LoadOJSON(File.s)
  Protected *J.OJSONNODE = #Null
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected Length.i = Lof(FN)
    If (Length > 0)
      Protected Buffer.s = ReadString(FN, #PB_Ascii|#PB_File_IgnoreEOL)
      If (Buffer)
        *J = CatchOJSON(@Buffer, StringByteLength(Buffer))
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (*J)
EndProcedure

Procedure.i CreateOJSON(MainNodeType.i = #OJSON_Object)
  Protected *J.OJSONNODE = #Null
  If ((MainNodeType >= 0) And (MainNodeType < #_OJSON_Types))
    If (MainNodeType <> #OJSON_Invalid)
      *J = _CreateOJSONNode(#Null, #OJSON_Array)
      If (*J)
        Protected *Main.OJSONNODE = _CreateOJSONNode(*J, MainNodeType)
        If (*Main)
          ; OK
        Else
          *J = DeleteOJSONNode(*J)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*J)
EndProcedure

;-

Procedure.i NextOJSONNode(*JN.OJSONNODE)
  If (*JN And *JN\Parent)
    ProcedureReturn (*JN\Next)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i PreviousOJSONNode(*JN.OJSONNODE)
  If (*JN And *JN\Parent)
    ProcedureReturn (*JN\Prev)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i MainOJSONNode(*J.OJSONNODE)
  If (*J)
    If (*J\Flags & #_OJSON_IsRoot)
      ProcedureReturn (*J\First)
    ElseIf (*J\Parent)
      ProcedureReturn (MainOJSONNode(*J\Parent))
    EndIf
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i ChildOJSONNode(*JN.OJSONNODE, Index.i = #OJSON_First)
  Protected *Child.OJSONNODE = #Null
  If (*JN)
    Select (*JN\Type)
      Case #OJSON_Array, #OJSON_Object
        Protected n.i = *JN\Children
        If (Index = #OJSON_Last)
          Index = n - 1
        EndIf
        If ((Index >= 0) And (Index < n))
          *Child = *JN\First
          While (Index > 0)
            *Child = *Child\Next
            Index - 1
          Wend
        EndIf
      Default
        ;
    EndSelect
  EndIf
  ProcedureReturn (*Child)
EndProcedure

Procedure.i ParentOJSONNode(*JN.OJSONNODE)
  If (*JN And *JN\Parent And (Not (*JN\Parent\Flags & #_OJSON_IsRoot)))
    ProcedureReturn (*JN\Parent)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i FindOJSONNodeByID(*JN.OJSONNODE, Text.s, Key.s = "id")
  Protected *Found.OJSONNODE = #Null
  If (*JN And Text And Key)
    Protected *Child.OJSONNODE = *JN\First
    While (*Child)
      Select (*Child\Type)
        Case #OJSON_Array, #OJSON_Object
          *Found = FindOJSONNodeByID(*Child, Text, Key)
        Case #OJSON_String
          If ((*Child\Key = Key) And (*Child\String = Text))
            *Found = *JN
          EndIf
      EndSelect
      If (*Found)
        Break
      EndIf
      *Child = *Child\Next
    Wend
  EndIf
  ProcedureReturn (*Found)
EndProcedure

Procedure.i NamedOJSONNode(*JN.OJSONNODE, Path.s)
  Protected *Found.OJSONNODE = #Null
  If (*JN And Path)
    If (*JN\Flags & #_OJSON_IsRoot)
      ProcedureReturn (NamedOJSONNode(*JN\First, Path))
    ElseIf (*JN\Type = #OJSON_Object)
      Protected Name.s
      Protected Paren.i = FindString(Path, "/")
      If (Paren)
        Name = Left(Path, Paren - 1)
      Else
        Name = Path
      EndIf
      If (Name)
        *Found = *JN\First
        While (*Found)
          If (Name = *Found\Key)
            Break
          EndIf
          *Found = *Found\Next
        Wend
        If (*Found And Paren)
          Name = Mid(Path, Paren + 1)
          *Found = NamedOJSONNode(*Found, Name)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Found)
EndProcedure

;-

Procedure.i SetOJSONNodeValue(*JN.OJSONNODE, Value.f)
  If (*JN)
    If (*JN\Type = #OJSON_Number)
      *JN\Number =  Value
      *JN\String =  StrF(Value)
      *JN\Raw    = *JN\String
      ProcedureReturn (#True)
    ElseIf (*JN\Type = #OJSON_Boolean)
      *JN\Number = Bool(Value)
      If (*JN\Number)
        *JN\String = "true"
      Else
        *JN\String = "false"
      EndIf
      *JN\Raw = *JN\String
      ProcedureReturn (#True)
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i IsValidOJSONNumber(String.s)
  ProcedureReturn (Bool(_ParseOJSONNumber(#Null, @String,
      @String + StringByteLength(String)) <> #OJSON_Invalid))
EndProcedure

Procedure.i SetOJSONNodeText(*JN.OJSONNODE, Text.s)
  If (*JN)
    If (*JN\Type = #OJSON_String)
      *JN\String =  Text
      *JN\Raw    =  _EscapeOJSONString(Text)
      ProcedureReturn (#True)
    ElseIf (*JN\Type = #OJSON_Number)
      If (IsValidOJSONNumber(Text))
        *JN\String = Text
        *JN\Raw    = Text
        *JN\Number = ValF(Text)
        ProcedureReturn (#True)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i SetOJSONNodeKey(*JN.OJSONNODE, Key.s)
  If (*JN And *JN\Parent And (*JN\Parent\Type = #OJSON_Object))
    If (*JN\Key)
      *JN\Key = Key
    EndIf
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

;-

Procedure.i GetOJSONChildCount(*JN.OJSONNODE)
  If (*JN)
    Select (*JN\Type)
      Case #OJSON_Array, #OJSON_Object
        ProcedureReturn (*JN\Children)
    EndSelect
  EndIf
  ProcedureReturn (0)
EndProcedure

Procedure.s GetOJSONNodeKey(*JN.OJSONNODE)
  If (*JN)
    ProcedureReturn (*JN\Key)
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.s GetOJSONNodeText(*JN.OJSONNODE)
  If (*JN)
    ProcedureReturn (*JN\String)
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.f GetOJSONNodeValue(*JN.OJSONNODE)
  If (*JN)
    ProcedureReturn (*JN\Number)
  EndIf
  ProcedureReturn (0.0)
EndProcedure

Procedure.i GetOJSONNodeInteger(*JN.OJSONNODE)
  If (*JN)
    ;Round(*JN\Number, #PB_Round_Nearest)
    ProcedureReturn (Int(*JN\Number))
  EndIf
  ProcedureReturn (0)
EndProcedure

Procedure.i GetOJSONNodeType(*JN.OJSONNODE)
  Protected Type.i = #OJSON_Invalid
  If (*JN)
    Type = *JN\Type
    If ((Type < 0) Or (Type >= #_OJSON_Types))
      Type = #OJSON_Invalid
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.s GetOJSONTypeName(Type.i)
  Protected Name.s
  Select (Type)
    Case #OJSON_Array
      Name = "Array"
    Case #OJSON_Boolean
      Name = "Boolean"
    Case #OJSON_Null
      Name = "Null"
    Case #OJSON_Number
      Name = "Number"
    Case #OJSON_Object
      Name = "Object"
    Case #OJSON_String
      Name = "String"
    Default
      Name = "Invalid"
  EndSelect
  ProcedureReturn (Name)
EndProcedure






















;-
;- ----- Demo Program -----

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit





;
;- Create an OJSON
;
; Here we create an empty OJSON from scratch.
; Every valid OJSON has exactly one main node (top-level item).
; By default, it will be an Object type.
; But it can be an Array, String, Number, Boolean, or even Null!
;

*OJSON = CreateOJSON()
If (*OJSON)
  *Main = MainOJSONNode(*OJSON)
  
  
  ;
  ;- Add some items
  ;
  ; You can add sub-items, but only to an Object or Array.
  ; To add anything to an Object, you must specify a Key string!
  ;
  ; Also, the six AddOJSON____() procedures are really just
  ; shortcuts for the generic CreateOJSONNode() procedure.
  ;
  
  *Obj = AddOJSONObject(*Main, "OJSONExample")
  
  
  ;
  ; Objects and Arrays can hold any number of child items.
  ; Here we add some basic types to the Object we created.
  ;
  
  AddOJSONString(*Obj, FormatDate("%hh:%ii:%ss", #PB_Compiler_Date), "time")
  AddOJSONNumber(*Obj, #PB_Compiler_Version, "PB_Compiler_Version")
  AddOJSONBoolean(*Obj, #PB_Compiler_Unicode, "PB_Compiler_Unicode")
  AddOJSONNull(*Obj, "nullNode")
  
  
  ;
  ; Arrays are similar to Objects, but they don't contain Key strings.
  ; Here we create an Array and add some Numbers to it.
  ;
  
  *Arr = AddOJSONArray(*Obj, "randomNumbers")
  For i = 1 To 5
    AddOJSONNumber(*Arr, Random(1000))
  Next i
  
  
  ;
  ; Most procedures return #Null (0) if an argument is invalid or it fails.
  ;
  ; Examples:
  ; 1. The main OJSON node does not have a parent node.
  ; 2. Array indexes are 0-based, so *Arr does not have an element #5.
  ; 3. You cannot add a second top-level node.
  ; 4. You cannot set the value/text of a wrong type of node.
  ; 5. You cannot an a sub-item to an Object without a Key.
  ;
  
  Debug "Should all be 0:"
  Debug "1. " + ParentOJSONNode(*Main)
  Debug "2. " + ChildOJSONNode(*Arr, 5)
  Debug "3. " + AddOJSONString(*OJSON, "top-level")
  Debug "4. " + SetOJSONNodeText(*Obj, "objectText")
  Debug "5. " + AddOJSONNumber(*Obj, 999)
  Debug ""
  
  
  ;
  ;- Save an OJSON
  ;
  ; Here we save the OJSON to an ASCII text file.
  ; You can specify Indented (default) or Compact format.
  ; The indentation step size can be specified as
  ; spaces (positive number) or tab characters (negative number).
  ;
  
  OutFile.s = GetTemporaryDirectory() + "example.OJSON.txt"
  If (SaveOJSON(*OJSON, OutFile))
    RunProgram(OutFile)
    
    
    ;
    ;- Reload it
    ;
    ; Here we free the entire OJSON, and reload it from the saved file.
    ;
    
    FreeOJSON(*OJSON)
    *OJSON = LoadOJSON(OutFile)
    If (*OJSON)
      *Main = MainOJSONNode(*OJSON)
      
      
      ;
      ;- Find items
      ;
      ; You can find sub-items by their numeric index,
      ; or by their Key if they belong to a parent Object.
      ;
      
      *Obj    = ChildOJSONNode(*Main)
      *Second = ChildOJSONNode(*Obj, 1)
      *Third  = NextOJSONNode(*Second)
      *Arr    = NamedOJSONNode(*Obj, "randomNumbers")
      
      
      ;
      ;- Delete items
      ;
      ; Deleting items is simple...
      
      DeleteOJSONNode(*Third)
      DeleteOJSONNode(*Arr)
      
      
      ;
      ;- Modify items
      ;
      ; You can change the Value of a Boolean or Number node.
      ; You can change the Text of a String or Number node.
      ; You can change the Key of any child of an Object.
      ; Strings are escaped automatically (and unescaped when accessed).
      ;
      
      *Time = NamedOJSONNode(*OJSON, "OJSONExample/time")
      SetOJSONNodeKey(*Time, "newTime")
      SetOJSONNodeText(*Time, FormatDate("%hh:%ii:%ss", Date() + 90))
      SetOJSONNodeValue(NamedOJSONNode(*Obj, "PB_Compiler_Version"), 567)
      
      UnsafeText.s = "He said " + #DQUOTE$ + "Hello!" + #DQUOTE$ + #LF$ + "The End."
      *Quote = AddOJSONString(*Obj, UnsafeText, "quote")
      Debug GetOJSONNodeText(*Quote)
      Debug ""
      
      
      ;
      ; Save two more versions of the OJSON for comparison.
      ; The first uses tabs instead of spaces for indentation.
      ; The second has no formatting whitespace at all.
      ;
      
      OutFile = GetTemporaryDirectory() + "modified.OJSON.txt"
      If (SaveOJSON(*OJSON, OutFile, #OJSON_Indented, -1))
        RunProgram(OutFile)
      EndIf
      
      OutFile = GetTemporaryDirectory() + "compact.OJSON.txt"
      If (SaveOJSON(*OJSON, OutFile, #OJSON_Compact))
        RunProgram(OutFile)
      EndIf
      
      
      FreeOJSON(*OJSON)
    Else
      Debug "Could not reload OJSON from file!"
    EndIf
    
  Else
    FreeOJSON(*OJSON)
    Debug "Could not save OJSON!"
  EndIf
  
Else
  Debug "OJSON could not be created!"
EndIf





CompilerEndIf
CompilerEndIf
;-