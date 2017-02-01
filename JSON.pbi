; +----------+
; | JSON.pbi |
; +----------+
; | 2014.03.28 . Creation (PureBasic 5.22)
; |     .04.05 . Version 1.00
; |        .11 . Version 1.10 (removed PB Lists, all is now pointer-based)
; | 2017.02.01 . Version 1.20 (multiple include safe, PB 5.30+ message)


;-
;- ----- JSON Module -----

CompilerIf (Not Defined(__JSON_Included, #PB_Constant))
#__JSON_Included = #True

CompilerIf (#PB_Compiler_Version >= 530)
  CompilerError #PB_Compiler_Filename + " is not compatible with this compiler version"
CompilerEndIf

CompilerIf (#PB_Compiler_Version >= 520)
DeclareModule JSON
CompilerEndIf
  
  
  ;- Constants
  
  ; JSON module version
  #JSON_Version = 120
  
  ; JSON node types
  #JSON_Invalid = 0
  #JSON_Number  = 1
  #JSON_String  = 2
  #JSON_Boolean = 3
  #JSON_Array   = 4
  #JSON_Object  = 5
  #JSON_Null    = 6
  
  ; SaveJSON() formats
  #JSON_Compact  = $0001
  #JSON_Indented = $0002
  
  ; Other JSON constants
  #JSON_Default  = -1
  #JSON_First    =  0
  #JSON_Last     = -1
  
  
  
  ;- Procedures
  
  ; JSON management
  Declare.i CreateJSON(MainNodeType = #JSON_Object)
  Declare.i CatchJSON(*Address, Length)
  Declare.i LoadJSON(File.s)
  Declare.i SaveJSON(*JSON, File.s, Format = #JSON_Default, IndentSize = 4)
  Declare.i FreeJSON(*JSON)
  
  ; JSON node management
  Declare.i CreateJSONNode(*Parent, Type = #JSON_Object, Key.s = "", *Previous = #JSON_Last)
  Declare.i DeleteJSONNode(*Node)
  Declare.i AddJSONString(*Parent, Text.s, Key.s = "", *Previous = #JSON_Last)
  Declare.i AddJSONNumber(*Parent, Value.f, Key.s = "", *Previous = #JSON_Last)
  Declare.i AddJSONBoolean(*Parent, Value, Key.s = "", *Previous = #JSON_Last)
  Declare.i AddJSONNull(*Parent, Key.s = "", *Previous = #JSON_Last)
  Declare.i AddJSONArray(*Parent, Key.s = "", *Previous = #JSON_Last)
  Declare.i AddJSONObject(*Parent, Key.s = "", *Previous = #JSON_Last)
  
  ; JSON node iteration
  Declare.i MainJSONNode(*JSON)
  Declare.i ChildJSONNode(*Node, Index = #JSON_First)
  Declare.i ParentJSONNode(*Node)
  Declare.i NextJSONNode(*Node)
  Declare.i PreviousJSONNode(*Node)
  Declare.i NamedJSONNode(*Node, Path.s)
  Declare.i FindJSONNodeByID(*Node, Text.s, Key.s = "id")
  
  ; JSON node access
  Declare.s GetJSONNodeText(*Node)
  Declare.f GetJSONNodeValue(*Node)
  Declare.i GetJSONNodeInteger(*Node)
  Declare.s GetJSONNodeKey(*Node)
  Declare.i GetJSONChildCount(*Node)
  Declare.i GetJSONNodeType(*Node)
  Declare.s GetJSONTypeName(Type)
  
  ; JSON node modification
  Declare.i SetJSONNodeText(*Node, Text.s)
  Declare.i SetJSONNodeValue(*Node, Value.f)
  Declare.i SetJSONNodeKey(*Node, Key.s)
  
  
CompilerIf (#PB_Compiler_Version >= 520)
EndDeclareModule
CompilerEndIf

;- ------------------------------



























;-

CompilerIf (#PB_Compiler_Version >= 520)
Module JSON
CompilerEndIf

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



; Constants - Private

; JSON type constants
#xJSON_Types = 7

; JSON node flags
#xJSON_IsRoot = $0001



; Structures - Private

Structure JSONNODE
  *Parent.JSONNODE
  Key.s
  Type.i
  Raw.s
  String.s
  Number.f
  Flags.i
  ;
  *First.JSONNODE
  *Last.JSONNODE
  Children.i
  ;
  *Next.JSONNODE
  *Prev.JSONNODE
EndStructure



; Macros - Private

CompilerIf (#PB_Compiler_Unicode)
  
  Macro Unicode()
    (#True)
  EndMacro
  Macro CharSize()
    (2)
  EndMacro
  Macro ToBytes(Chars)
    ((Chars) * 2)
  EndMacro
  Macro ToChars(Bytes)
    ((Bytes) / 2)
  EndMacro
  
CompilerElse
  
  Macro Unicode()
    (#False)
  EndMacro
  Macro CharSize()
    (1)
  EndMacro
  Macro ToBytes(Chars)
    (Chars)
  EndMacro
  Macro ToChars(Bytes)
    (Bytes)
  EndMacro
CompilerEndIf



;-

; Declares - Private

Declare.i xParseJSONString(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER, *Unescape.INTEGER = #Null)
Declare.i xParseJSONNode(*JN.JSONNODE, *Address, Length.i)



; Procedures - Private

Procedure.s xEscapeJSONString(String.s)
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
    *C + CharSize()
  Wend
  ProcedureReturn (Build)
EndProcedure

Procedure.s xUnescapeJSONString(String.s)
  Protected Result.s = ""
  String = #DQUOTE$ + String + #DQUOTE$
  Protected i.INTEGER
  xParseJSONString(#Null, @String, @String + StringByteLength(String), @i)
  If (i\i)
    Result = PeekS(i\i)
    FreeMemory(i\i)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i xAddJSONNode(*JN.JSONNODE, *Parent.JSONNODE, *Previous.JSONNODE)
  If (*JN And *Parent)
    *JN\Parent = *Parent
    *Parent\Children + 1
    If (*Parent\First)
      If (*Previous = #JSON_First)
        *JN\Prev = #Null
        *JN\Next = *Parent\First
        *Parent\First\Prev = *JN
        *Parent\First = *JN
      ElseIf (*Previous = #JSON_Last)
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

Procedure.i xCreateJSONNode(*Parent.JSONNODE, Type.i, *Previous.JSONNODE = #JSON_Last)
  Protected *JN.JSONNODE = #Null
  If ((Type >= 0) And (Type < #xJSON_Types))
    *JN = AllocateMemory(SizeOf(JSONNODE))
    If (*JN)
      If (*Parent)
        If (xAddJSONNode(*JN, *Parent, *Previous))
          *JN\Type = Type
        Else
          FreeMemory(*JN)
          *JN = #Null
        EndIf
      Else
        *JN\Type   = #JSON_Array
        *JN\Flags  = #xJSON_IsRoot
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*JN)
EndProcedure

Procedure.i xParseJSONString(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER, *Unescape.INTEGER = #Null)
  Protected Type.i = #JSON_Invalid
  If ((*JN Or *Unescape) And *Start And (*End > *Start))
    Type.i = #JSON_String
    Protected *C.CHARACTER = *Start
    Protected *TokenEnd.CHARACTER = #Null
    Protected i.i
    Protected *Build = #Null
    Protected *BC.CHARACTER = #Null
    If (*Unescape)
      *Unescape\i = #Null
    EndIf
    *Build = AllocateMemory((*End - *Start) + CharSize(), #PB_Memory_NoClear)
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
                Type = #JSON_Invalid
            EndSelect
          Case 1
            Select (*C\c)
              Case '"'
                *TokenEnd = *C
                Expecting = 2
              Case '\'
                If (ToChars(*End - *C) >= 1 + 1)
                  *C + CharSize()
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
                      If (ToChars(*End - *C) >= 4 + 1)
                        Protected UValue.u = Val("$" + PeekS(*C + CharSize(), 4))
                        For i = 1 To 4
                          *C + CharSize()
                          Select (*C\c)
                            Case '0' To '9', 'a' To 'f', 'A' To 'F'
                              ;
                            Default
                              Type = #JSON_Invalid
                              Break
                          EndSelect
                        Next i
                        If (Type <> #JSON_Invalid)
                          CompilerIf (Unicode())
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
                        Type = #JSON_Invalid
                      EndIf
                    Default
                      Type = #JSON_Invalid
                  EndSelect
                  *BC + CharSize()
                Else
                  Type = #JSON_Invalid
                EndIf
              Case $00 To $1F
                Type = #JSON_Invalid
              Default
                *BC\c = *C\c
                *BC + CharSize()
            EndSelect
          Case 2
            Select (*C\c)
              Case ' ', #TAB, #CR, #LF
                ;
              Default
                Type = #JSON_Invalid
            EndSelect
        EndSelect
        If (Type = #JSON_Invalid)
          Break
        EndIf
        *C + CharSize()
      Wend
      If (*TokenEnd = #Null)
        *TokenEnd = *End
      EndIf
      *BC\c = #NUL
      If (Type <> #JSON_Invalid)
        If (Expecting = 2)
          If (*JN)
            *JN\Type   = Type
            *JN\Raw    = PeekS(*Start + CharSize(), ToChars(*TokenEnd - *Start) - 1)
            *JN\String = PeekS(*Build)
            *JN\Number = 0.0
          EndIf
        Else
          Type = #JSON_Invalid
        EndIf
      EndIf
      If (*Unescape And (Type = #JSON_String))
        *Unescape\i = *Build
      Else
        FreeMemory(*Build)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i xParseJSONNumber(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #JSON_Invalid
  If (*Start And (*End > *Start))
    Type.i = #JSON_Number
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
              Type = #JSON_Invalid
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
              Type = #JSON_Invalid
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
              Type = #JSON_Invalid
          EndSelect
        Case 3
          Select (*C\c)
            Case '0' To '9'
              ExpDigits + 1
              Expecting = 4
            Case '+', '-'
              Expecting = 4
            Default
              Type = #JSON_Invalid
          EndSelect
        Case 4
          Select (*C\c)
            Case '0' To '9'
              ExpDigits + 1
            Case ' ', #TAB, #CR, #LF
              *TokenEnd = *C
              Expecting = 5
            Default
              Type = #JSON_Invalid
          EndSelect
        Case 5
          Select (*C\c)
            Case ' ', #TAB, #CR, #LF
              ;
            Default
              Type = #JSON_Invalid
          EndSelect
      EndSelect
      If (Type = #JSON_Invalid)
        Break
      EndIf
      *C + CharSize()
    Wend
    If (*TokenEnd = #Null)
      *TokenEnd = *End
    EndIf
    If (Type <> #JSON_Invalid)
      If ((IntDigits > 0) And (FracDigits <> 0) And (ExpDigits <> 0))
        If (*JN)
          *JN\Type   =  Type
          *JN\Raw    =  PeekS(*Start, ToChars(*TokenEnd - *Start))
          *JN\String = *JN\Raw
          *JN\Number =  ValF(*JN\String)
        EndIf
      Else
        Type = #JSON_Invalid
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i xParseJSONWord(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #JSON_Invalid
  If (*JN And *Start And (*End > *Start))
    Type.i = #JSON_Null
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
              Type = #JSON_Invalid
          EndSelect
        Case 1
          Select (*C\c)
            Case ' ', #TAB, #CR, #LF
              ;
            Default
              Type = #JSON_Invalid
          EndSelect
      EndSelect
      If (Type = #JSON_Invalid)
        Break
      EndIf
      *C + CharSize()
    Wend
    If (*TokenEnd = #Null)
      *TokenEnd = *End
    EndIf
    If (Type <> #JSON_Invalid)
      Protected Raw.s = PeekS(*Start, ToChars(*TokenEnd - *Start))
      Select (Raw)
        Case "true"
          Type       = #JSON_Boolean
          *JN\Number =  1.0
        Case "false"
          Type       = #JSON_Boolean
          *JN\Number =  0.0
        Case "null"
          Type       = #JSON_Null
          *JN\Number =  0.0
        Default
          Type = #JSON_Invalid
      EndSelect
      If (Type <> #JSON_Invalid)
        *JN\Type   = Type
        *JN\Raw    = Raw
        *JN\String = Raw
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.i xSkipJSONWhitespace(*Start.CHARACTER, *End.CHARACTER)
  If (*Start And (*End >= *Start))
    While (*Start < *End)
      Select (*Start\c)
        Case ' ', #TAB, #CR, #LF
          ;
        Default
          Break
      EndSelect
      *Start + CharSize()
    Wend
  Else
    *Start = #Null
  EndIf
  ProcedureReturn (*Start)
EndProcedure

Procedure.i xIsJSONWhitespace(*Start.CHARACTER, *End.CHARACTER)
  If (*Start And (*End >= *Start))
    ProcedureReturn (Bool(xSkipJSONWhitespace(*Start, *End) = *End))
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i xFindJSONClose(*Start.CHARACTER, *End.CHARACTER, Symbol.c, AllowAfter.i)
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
              If (ToChars(*End - *C) >= 1 + 1)
                *C + CharSize()
                Select (*C\c)
                  Case '"', '\', '/', 'b', 'f', 'r', 'n', 't'
                    ;
                  Case 'u'
                    If (ToChars(*End - *C) >= 4 + 1)
                      *C + 4 * CharSize()
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
      *C + CharSize()
    Wend
  EndIf
  
  ProcedureReturn (*Found)
EndProcedure

Procedure.i xParseJSONObject(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #JSON_Invalid
  If (*JN And *Start And (*End > *Start))
    If (*Start\c = '{')
      Protected *NodeEnd.CHARACTER = xFindJSONClose(*Start + CharSize(), *End, '}', #False)
      If (*NodeEnd)
        Type = #JSON_Object
        *Start + CharSize()
        Protected *PairEnd.CHARACTER
        Repeat
          *Start = xSkipJSONWhitespace(*Start, *NodeEnd)
          *PairEnd = xFindJSONClose(*Start, *NodeEnd, ',', #True)
          If (Not *PairEnd)
            If (Not xIsJSONWhitespace(*Start, *NodeEnd))
              *PairEnd = *NodeEnd
            EndIf
          EndIf
          If (*PairEnd)
            Type = #JSON_Invalid
            Protected *Divider.CHARACTER = xFindJSONClose(*Start, *PairEnd - CharSize(), ':', #True)
            If ((*Divider > *Start) And (*Divider < *PairEnd))
              Protected NamePtr.INTEGER
              xParseJSONString(#Null, *Start, *Divider, @NamePtr)
              If (NamePtr\i)
                Protected *Child.JSONNODE = xCreateJSONNode(*JN, #JSON_Invalid)
                If (*Child)
                  *Divider + CharSize()
                  If (xParseJSONNode(*Child, *Divider, *PairEnd - *Divider) <> #JSON_Invalid)
                    *Child\Key = PeekS(NamePtr\i)
                    Type = #JSON_Object
                  Else
                    DeleteJSONNode(*Child)
                  EndIf
                EndIf
                FreeMemory(NamePtr\i)
              EndIf
            EndIf
            *Start = *PairEnd + CharSize()
          EndIf
        Until ((Not *PairEnd) Or (*Start >= *NodeEnd) Or (Type = #JSON_Invalid))
        If (Type = #JSON_Object)
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

Procedure.i xParseJSONArray(*JN.JSONNODE, *Start.CHARACTER, *End.CHARACTER)
  Protected Type.i = #JSON_Invalid
  If (*JN And *Start And (*End > *Start))
    If (*Start\c = '[')
      Protected *NodeEnd.CHARACTER = xFindJSONClose(*Start + CharSize(), *End, ']', #False)
      If (*NodeEnd)
        Type = #JSON_Array
        *Start + CharSize()
        Protected *ItemEnd.CHARACTER
        Repeat
          *Start = xSkipJSONWhitespace(*Start, *NodeEnd)
          *ItemEnd = xFindJSONClose(*Start, *NodeEnd, ',', #True)
          If (Not *ItemEnd)
            If (Not xIsJSONWhitespace(*Start, *NodeEnd))
              *ItemEnd = *NodeEnd
            EndIf
          EndIf
          If (*ItemEnd)
            Type = #JSON_Invalid
            Protected *Child.JSONNODE = xCreateJSONNode(*JN, #JSON_Invalid)
            If (*Child)
              If (xParseJSONNode(*Child, *Start, *ItemEnd - *Start) <> #JSON_Invalid)
                Type = #JSON_Array
              Else
                DeleteJSONNode(*Child)
              EndIf
            EndIf
            *Start = *ItemEnd + CharSize()
          EndIf
        Until ((Not *ItemEnd) Or (*Start >= *NodeEnd) Or (Type = #JSON_Invalid))
        If (Type = #JSON_Array)
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

Procedure.i xParseJSONNode(*JN.JSONNODE, *Address, Length.i)
  Protected Type.i = #JSON_Invalid
  
  If (*JN And (*JN\Type = #JSON_Invalid))
    If (*Address And (Length > 0))
      Protected *End.CHARACTER = *Address + Length
      Protected *C.CHARACTER   =  xSkipJSONWhitespace(*Address, *End)
      If (*C < *End)
        Select (*C\c)
          Case '{'
            Type = xParseJSONObject(*JN, *C, *End)
          Case '['
            Type = xParseJSONArray(*JN, *C, *End)
          Case '"'
            Type = xParseJSONString(*JN, *C, *End)
          Case '0' To '9', '-'
            Type = xParseJSONNumber(*JN, *C, *End)
          Case 'a' To 'z', 'A' To 'Z', '_'
            Type = xParseJSONWord(*JN, *C, *End)
          Default
            ;
        EndSelect
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Type)
EndProcedure

Procedure xWriteJSONIndent(FN, Indent.i, Level.i)
  If (IsFile(FN))
    If (Indent > 0)
      WriteString(FN, Space(Indent * Level), #PB_Ascii)
    ElseIf (Indent < 0)
      WriteString(FN, RSet("", -Indent * Level, #TAB$), #PB_Ascii)
    EndIf
  EndIf
EndProcedure

Procedure xWriteJSONNode(FN.i, *JN.JSONNODE, Format.i, Indent.i, Level.i = 0)
  If (IsFile(FN) And *JN)
    Protected EOL.s
    Protected SP.s
    If (Format & #JSON_Indented)
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
    xWriteJSONIndent(FN, Indent, Level)
    If (*JN\Key)
      WriteString(FN, #DQUOTE$ + xEscapeJSONString(*JN\Key) + #DQUOTE$ + ":" + SP, #PB_Ascii)
    EndIf
    Protected *Child.JSONNODE
    Select (*JN\Type)
      Case #JSON_Null
        WriteString(FN, "null", #PB_Ascii)
      Case #JSON_Boolean
        If (*JN\Number)
          WriteString(FN, "true", #PB_Ascii)
        Else
          WriteString(FN, "false", #PB_Ascii)
        EndIf
      Case #JSON_Number
        WriteString(FN, *JN\Raw, #PB_Ascii)
      Case #JSON_String
        WriteString(FN, #DQUOTE$ + *JN\Raw + #DQUOTE$, #PB_Ascii)
      Case #JSON_Object
        WriteString(FN, "{" + EOL, #PB_Ascii)
        *Child = *JN\First
        If (*Child)
          While (#True)
            xWriteJSONNode(FN, *Child, Format, Indent, Level + 1)
            *Child = *Child\Next
            If (*Child)
              WriteString(FN, "," + EOL, #PB_Ascii)
            Else
              WriteString(FN, EOL, #PB_Ascii)
              Break
            EndIf
          Wend
        EndIf
        xWriteJSONIndent(FN, Indent, Level)
        WriteString(FN, "}", #PB_Ascii)
      Case #JSON_Array
        WriteString(FN, "[" + EOL, #PB_Ascii)
        *Child = *JN\First
        If (*Child)
          While (#True)
            xWriteJSONNode(FN, *Child, Format, Indent, Level + 1)
            *Child = *Child\Next
            If (*Child)
              WriteString(FN, "," + EOL, #PB_Ascii)
            Else
              WriteString(FN, EOL, #PB_Ascii)
              Break
            EndIf
          Wend
        EndIf
        xWriteJSONIndent(FN, Indent, Level)
        WriteString(FN, "]", #PB_Ascii)
    EndSelect
  EndIf
EndProcedure

;-

Procedure.i DeleteJSONNode(*JN.JSONNODE)
  If (*JN And (Not (*JN\Flags & #xJSON_IsRoot)))
    If ((*JN\Type = #JSON_Array) Or (*JN\Type = #JSON_Object))
      Protected *Prev.JSONNODE
      Protected *Next.JSONNODE
      Protected *Child.JSONNODE = *JN\First
      While (*Child)
        *Next = *Child\Next
        DeleteJSONNode(*Child)
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

Procedure.i CreateJSONNode(*Parent.JSONNODE, Type.i = #JSON_Object, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *Child.JSONNODE = #Null
  If ((Type >= 0) And (Type < #xJSON_Types) And (Type <> #JSON_Invalid))
    If (*Parent)
      If ((*Parent\Type = #JSON_Array) Or ((*Parent\Type = #JSON_Object) And (Key)))
        If ((*Parent\Children = 0) Or (Not (*Parent\Flags & #xJSON_IsRoot)))
          *Child = xCreateJSONNode(*Parent, Type, *Previous)
          If (*Child)
            If (*Parent\Type = #JSON_Object)
              *Child\Key = Key
            EndIf
            Select (Type)
              Case #JSON_Boolean
                *Child\String = "false"
                *Child\Raw    = *Child\String
              Case #JSON_Null
                *Child\String = "null"
                *Child\Raw    = *Child\String
              Case #JSON_Number
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

Procedure.i AddJSONString(*Parent.JSONNODE, Text.s, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_String, Key, *Previous)
  If (*New)
    SetJSONNodeText(*New, Text)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddJSONNumber(*Parent.JSONNODE, Value.f, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_Number, Key, *Previous)
  If (*New)
    SetJSONNodeValue(*New, Value)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddJSONBoolean(*Parent.JSONNODE, Value.i, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_Boolean, Key, *Previous)
  If (*New)
    SetJSONNodeValue(*New, Value)
  EndIf
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddJSONNull(*Parent.JSONNODE, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_Null, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddJSONArray(*Parent.JSONNODE, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_Array, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

Procedure.i AddJSONObject(*Parent.JSONNODE, Key.s = "", *Previous.JSONNODE = #JSON_Last)
  Protected *New.JSONNODE = #Null
  *New = CreateJSONNode(*Parent, #JSON_Object, Key, *Previous)
  ProcedureReturn (*New)
EndProcedure

;-

Procedure.i FreeJSON(*J.JSONNODE)
  If (*J And (*J\Flags & #xJSON_IsRoot))
    *J\Flags & (~#xJSON_IsRoot)
    DeleteJSONNode(*J)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i SaveJSON(*J.JSONNODE, File.s, Format.i = #JSON_Default, IndentSize.i = 4)
  Protected Result.i = #False
  If (Format = #JSON_Default)
    Format = #JSON_Indented
  EndIf
  If (*J And File)
    Protected FN.i = CreateFile(#PB_Any, File)
    If (FN)
      If (Not (Format & #JSON_Indented))
        IndentSize = 0
      EndIf
      If (*J\Flags & #xJSON_IsRoot)
        If (*J\First)
          xWriteJSONNode(FN, *J\First, Format, IndentSize, 0)
          Result = #True
        EndIf
      Else
        xWriteJSONNode(FN, *J, Format, IndentSize, 0)
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

Procedure.i CatchJSON(*Address, Length.i)
  Protected *J.JSONNODE = #Null
  
  If (*Address And (Length > 0))
    *J = xCreateJSONNode(#Null, #JSON_Array)
    If (*J)
      Protected *Main.JSONNODE = xCreateJSONNode(*J, #JSON_Invalid)
      If (*Main)
        ;
        CompilerIf (Unicode())
          ; Convert apparent ASCII buffer to Unicode buffer
          If ((Length % 2 <> 0) Or (PeekA(*Address + 1) <> #NUL))
            Protected UnicodeCopy.s = PeekS(*Address, Length, #PB_Ascii)
            *Address = @UnicodeCopy
            Length * 2
          EndIf
        CompilerEndIf
        ;
        If (xParseJSONNode(*Main, *Address, Length) <> #JSON_Invalid)
          ; OK
        Else
          *J = FreeJSON(*J)
        EndIf
      Else
        *J = FreeJSON(*J)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (*J)
EndProcedure

Procedure.i LoadJSON(File.s)
  Protected *J.JSONNODE = #Null
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected Length.i = Lof(FN)
    If (Length > 0)
      Protected Buffer.s = ReadString(FN, #PB_Ascii|#PB_File_IgnoreEOL)
      If (Buffer)
        *J = CatchJSON(@Buffer, StringByteLength(Buffer))
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (*J)
EndProcedure

Procedure.i CreateJSON(MainNodeType.i = #JSON_Object)
  Protected *J.JSONNODE = #Null
  If ((MainNodeType >= 0) And (MainNodeType < #xJSON_Types))
    If (MainNodeType <> #JSON_Invalid)
      *J = xCreateJSONNode(#Null, #JSON_Array)
      If (*J)
        Protected *Main.JSONNODE = xCreateJSONNode(*J, MainNodeType)
        If (*Main)
          ; OK
        Else
          *J = DeleteJSONNode(*J)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*J)
EndProcedure

;-

Procedure.i NextJSONNode(*JN.JSONNODE)
  If (*JN And *JN\Parent)
    ProcedureReturn (*JN\Next)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i PreviousJSONNode(*JN.JSONNODE)
  If (*JN And *JN\Parent)
    ProcedureReturn (*JN\Prev)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i MainJSONNode(*J.JSONNODE)
  If (*J)
    If (*J\Flags & #xJSON_IsRoot)
      ProcedureReturn (*J\First)
    ElseIf (*J\Parent)
      ProcedureReturn (MainJSONNode(*J\Parent))
    EndIf
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i ChildJSONNode(*JN.JSONNODE, Index.i = #JSON_First)
  Protected *Child.JSONNODE = #Null
  If (*JN)
    Select (*JN\Type)
      Case #JSON_Array, #JSON_Object
        Protected n.i = *JN\Children
        If (Index = #JSON_Last)
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

Procedure.i ParentJSONNode(*JN.JSONNODE)
  If (*JN And *JN\Parent And (Not (*JN\Parent\Flags & #xJSON_IsRoot)))
    ProcedureReturn (*JN\Parent)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i FindJSONNodeByID(*JN.JSONNODE, Text.s, Key.s = "id")
  Protected *Found.JSONNODE = #Null
  If (*JN And Text And Key)
    Protected *Child.JSONNODE = *JN\First
    While (*Child)
      Select (*Child\Type)
        Case #JSON_Array, #JSON_Object
          *Found = FindJSONNodeByID(*Child, Text, Key)
        Case #JSON_String
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

Procedure.i NamedJSONNode(*JN.JSONNODE, Path.s)
  Protected *Found.JSONNODE = #Null
  If (*JN And Path)
    If (*JN\Flags & #xJSON_IsRoot)
      ProcedureReturn (NamedJSONNode(*JN\First, Path))
    ElseIf (*JN\Type = #JSON_Object)
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
          *Found = NamedJSONNode(*Found, Name)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Found)
EndProcedure

;-

Procedure.i SetJSONNodeValue(*JN.JSONNODE, Value.f)
  If (*JN)
    If (*JN\Type = #JSON_Number)
      *JN\Number =  Value
      *JN\String =  StrF(Value)
      *JN\Raw    = *JN\String
      ProcedureReturn (#True)
    ElseIf (*JN\Type = #JSON_Boolean)
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

Procedure.i IsValidJSONNumber(String.s)
  ProcedureReturn (Bool(xParseJSONNumber(#Null, @String,
      @String + StringByteLength(String)) <> #JSON_Invalid))
EndProcedure

Procedure.i SetJSONNodeText(*JN.JSONNODE, Text.s)
  If (*JN)
    If (*JN\Type = #JSON_String)
      *JN\String =  Text
      *JN\Raw    =  xEscapeJSONString(Text)
      ProcedureReturn (#True)
    ElseIf (*JN\Type = #JSON_Number)
      If (IsValidJSONNumber(Text))
        *JN\String = Text
        *JN\Raw    = Text
        *JN\Number = ValF(Text)
        ProcedureReturn (#True)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i SetJSONNodeKey(*JN.JSONNODE, Key.s)
  If (*JN And *JN\Parent And (*JN\Parent\Type = #JSON_Object))
    If (*JN\Key)
      *JN\Key = Key
    EndIf
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

;-

Procedure.i GetJSONChildCount(*JN.JSONNODE)
  If (*JN)
    Select (*JN\Type)
      Case #JSON_Array, #JSON_Object
        ProcedureReturn (*JN\Children)
    EndSelect
  EndIf
  ProcedureReturn (0)
EndProcedure

Procedure.s GetJSONNodeKey(*JN.JSONNODE)
  If (*JN)
    ProcedureReturn (*JN\Key)
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.s GetJSONNodeText(*JN.JSONNODE)
  If (*JN)
    ProcedureReturn (*JN\String)
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.f GetJSONNodeValue(*JN.JSONNODE)
  If (*JN)
    ProcedureReturn (*JN\Number)
  EndIf
  ProcedureReturn (0.0)
EndProcedure

Procedure.i GetJSONNodeInteger(*JN.JSONNODE)
  If (*JN)
    ;Round(*JN\Number, #PB_Round_Nearest)
    ProcedureReturn (Int(*JN\Number))
  EndIf
  ProcedureReturn (0)
EndProcedure

Procedure.i GetJSONNodeType(*JN.JSONNODE)
  Protected Type.i = #JSON_Invalid
  If (*JN)
    Type = *JN\Type
    If ((Type < 0) Or (Type >= #xJSON_Types))
      Type = #JSON_Invalid
    EndIf
  EndIf
  ProcedureReturn (Type)
EndProcedure

Procedure.s GetJSONTypeName(Type.i)
  Protected Name.s
  Select (Type)
    Case #JSON_Array
      Name = "Array"
    Case #JSON_Boolean
      Name = "Boolean"
    Case #JSON_Null
      Name = "Null"
    Case #JSON_Number
      Name = "Number"
    Case #JSON_Object
      Name = "Object"
    Case #JSON_String
      Name = "String"
    Default
      Name = "Invalid"
  EndSelect
  ProcedureReturn (Name)
EndProcedure

CompilerIf (#PB_Compiler_Version >= 520)
EndModule
CompilerEndIf

CompilerEndIf





















;-
;- ----- JSON Example -----

CompilerIf (#PB_Compiler_IsMainFile)

DisableExplicit

CompilerIf (#PB_Compiler_Version >= 520)
UseModule JSON
CompilerEndIf





;
;- Create a JSON
;
; Here we create an empty JSON from scratch.
; Every valid JSON has exactly one main node (top-level item).
; By default, it will be an Object type.
; But it can be an Array, String, Number, Boolean, or even Null!
;

*JSON = CreateJSON()
If (*JSON)
  *Main = MainJSONNode(*JSON)
  
  
  ;
  ;- Add some items
  ;
  ; You can add sub-items, but only to an Object or Array.
  ; To add anything to an Object, you must specify a Key string!
  ;
  ; Also, the six AddJSON____() procedures are really just
  ; shortcuts for the generic CreateJSONNode() procedure.
  ;
  
  *Obj = AddJSONObject(*Main, "jsonExample")
  
  
  ;
  ; Objects and Arrays can hold any number of child items.
  ; Here we add some basic types to the Object we created.
  ;
  
  AddJSONString(*Obj, FormatDate("%hh:%ii:%ss", #PB_Compiler_Date), "time")
  AddJSONNumber(*Obj, #PB_Compiler_Version, "PB_Compiler_Version")
  AddJSONBoolean(*Obj, #PB_Compiler_Unicode, "PB_Compiler_Unicode")
  AddJSONNull(*Obj, "nullNode")
  
  
  ;
  ; Arrays are similar to Objects, but they don't contain Key strings.
  ; Here we create an Array and add some Numbers to it.
  ;
  
  *Arr = AddJSONArray(*Obj, "randomNumbers")
  For i = 1 To 5
    AddJSONNumber(*Arr, Random(1000))
  Next i
  
  
  ;
  ; Most procedures return #Null (0) if an argument is invalid or it fails.
  ;
  ; Examples:
  ; 1. The main JSON node does not have a parent node.
  ; 2. Array indexes are 0-based, so *Arr does not have an element #5.
  ; 3. You cannot add a second top-level node.
  ; 4. You cannot set the value/text of a wrong type of node.
  ; 5. You cannot an a sub-item to an Object without a Key.
  ;
  
  Debug "Should be 0:"
  Debug "1. " + ParentJSONNode(*Main)
  Debug "2. " + ChildJSONNode(*Arr, 5)
  Debug "3. " + AddJSONString(*JSON, "top-level")
  Debug "4. " + SetJSONNodeText(*Obj, "objectText")
  Debug "5. " + AddJSONNumber(*Obj, 999)
  Debug ""
  
  
  ;
  ;- Save a JSON
  ;
  ; Here we save the JSON to an ASCII text file.
  ; You can specify Indented (default) or Compact format.
  ; The indentation step size can be specified as
  ; spaces (positive number) or tab characters (negative number).
  ;
  
  OutFile.s = GetTemporaryDirectory() + "example.json.txt"
  If (SaveJSON(*JSON, OutFile))
    RunProgram(OutFile)
    
    
    ;
    ;- Reload it
    ;
    ; Here we free the entire JSON, and reload it from the saved file.
    ;
    
    FreeJSON(*JSON)
    *JSON = LoadJSON(OutFile)
    If (*JSON)
      *Main = MainJSONNode(*JSON)
      
      
      ;
      ;- Find items
      ;
      ; You can find sub-items by their numeric index,
      ; or by their Key if they belong to a parent Object.
      ;
      
      *Obj    = ChildJSONNode(*Main)
      *Second = ChildJSONNode(*Obj, 1)
      *Third  = NextJSONNode(*Second)
      *Arr    = NamedJSONNode(*Obj, "randomNumbers")
      
      
      ;
      ;- Delete items
      ;
      ; Deleting items is simple...
      
      DeleteJSONNode(*Third)
      DeleteJSONNode(*Arr)
      
      
      ;
      ;- Modify items
      ;
      ; You can change the Value of a Boolean or Number node.
      ; You can change the Text of a String or Number node.
      ; You can change the Key of any child of an Object.
      ; Strings are escaped automatically (and unescaped when accessed).
      ;
      
      *Time = NamedJSONNode(*JSON, "jsonExample/time")
      SetJSONNodeKey(*Time, "newTime")
      SetJSONNodeText(*Time, FormatDate("%hh:%ii:%ss", Date() + 90))
      SetJSONNodeValue(NamedJSONNode(*Obj, "PB_Compiler_Version"), 567)
      
      UnsafeText.s = "He said " + #DQUOTE$ + "Hello!" + #DQUOTE$ + #LF$ + "The End."
      *Quote = AddJSONString(*Obj, UnsafeText, "quote")
      Debug GetJSONNodeText(*Quote)
      Debug ""
      
      
      ;
      ; Save two more versions of the JSON for comparison.
      ; The first uses tabs instead of spaces for indentation.
      ; The second has no formatting whitespace at all.
      ;
      
      OutFile = GetTemporaryDirectory() + "modified.json.txt"
      If (SaveJSON(*JSON, OutFile, #JSON_Indented, -1))
        RunProgram(OutFile)
      EndIf
      
      OutFile = GetTemporaryDirectory() + "compact.json.txt"
      If (SaveJSON(*JSON, OutFile, #JSON_Compact))
        RunProgram(OutFile)
      EndIf
      
      
      FreeJSON(*JSON)
    Else
      Debug "Could not reload JSON from file!"
    EndIf
    
  Else
    FreeJSON(*JSON)
    Debug "Could not save JSON!"
  EndIf
  
Else
  Debug "JSON could not be created!"
EndIf





CompilerEndIf

;- ------------------------------

;-