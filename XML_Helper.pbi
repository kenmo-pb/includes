; +----------------+
; | XML_Helper.pbi |
; +----------------+
; | 2016.05.26 . Creation (PureBasic 5.42)
; |     .06.01 . Added DeleteXMLChildren()
; | 2017.04.24 . Cleanup

CompilerIf (Not Defined(__XML_Helper_Included, #PB_Constant))
#__XML_Helper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;-
;- Macros

Macro MainXMLNodeName(_XML)
  GetXMLNodeNameSafe(MainXMLNode(_XML))
EndMacro




;-
;- Constants

#XML_Normal  = #PB_XML_Normal
#XML_Comment = #PB_XML_Comment
#XML_Root    = #PB_XML_Root
#XML_Default = #PB_Default





;-
;- Macros

Macro IsNormalXMLNode(_Node)
  Bool(XMLNodeType(_Node) = #XML_Normal)
EndMacro

Macro RemoveXMLComments(_Node, _Recursive = #True)
  DeleteXMLChildren((_Node), "", #XML_Comment, (_Recursive))
EndMacro

Macro RemoveXMLMetadata(_Node, _Recursive = #True)
  DeleteXMLChildren((_Node), "", #PB_XML_CData, (_Recursive))
  DeleteXMLChildren((_Node), "", #PB_XML_DTD, (_Recursive))
  DeleteXMLChildren((_Node), "", #PB_XML_Instruction, (_Recursive))
EndMacro






;-
;- Procedures

Procedure.s GetXMLNodeNameSafe(*Node)
  If (*Node And IsNormalXMLNode(*Node))
    ProcedureReturn (GetXMLNodeName(*Node))
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.i HasXMLAttribute(*Node, Attribute.s)
  Protected Result.i = #False
  If (*Node And IsNormalXMLNode(*Node) And Attribute)
    If (ExamineXMLAttributes(*Node))
      While (NextXMLAttribute(*Node))
        If (XMLAttributeName(*Node) = Attribute)
          Result = #True
          Break
        EndIf
      Wend
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ChildXMLNodeEx(*Node, n.i = 0, Name.s = "", Type.i = #XML_Default)
  Protected *Result = #Null
  If (*Node And IsNormalXMLNode(*Node) And (n >= 0))
    If (Name And (Type = #XML_Default))
      Type = #XML_Normal
    EndIf
    Protected i.i = 0
    Protected ChildType.i
    Protected *Child = ChildXMLNode(*Node)
    While (*Child)
      ChildType = XMLNodeType(*Child)
      If ((Type = #XML_Default) Or (Type = ChildType))
        If ((ChildType <> #XML_Normal) Or (Name = "") Or (GetXMLNodeName(*Child) = Name))
          i + 1
          If (i > n)
            *Result = *Child
            Break
          EndIf
        EndIf
      EndIf
      *Child = NextXMLNode(*Child)
    Wend
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.i NextXMLNodeEx(*Node, Name.s = "", Type.i = #XML_Default)
  Protected *Result = #Null
  If (*Node)
    If (Name And (Type = #XML_Default))
      Type = #XML_Normal
    EndIf
    Protected NodeType.i
    *Node = NextXMLNode(*Node)
    While (*Node)
      NodeType = XMLNodeType(*Node)
      If ((Type = #XML_Default) Or (Type = NodeType))
        If ((NodeType <> #XML_Normal) Or (Name = "") Or (GetXMLNodeName(*Node) = Name))
          *Result = *Node
          Break
        EndIf
      EndIf
      *Node = NextXMLNode(*Node)
    Wend
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.i XMLChildCountEx(*Node, Name.s = "", Type.i = #XML_Default, Recursive.i = #False)
  Protected Result.i = 0
  If (*Node And IsNormalXMLNode(*Node))
    If (Name And (Type = #XML_Default))
      Type = #XML_Normal
    EndIf
    Protected NodeType.i
    Protected *Child = ChildXMLNode(*Node)
    While (*Child)
      NodeType = XMLNodeType(*Child)
      If ((Type = #XML_Default) Or (Type = NodeType))
        If ((NodeType <> #XML_Normal) Or (Name = "") Or (GetXMLNodeName(*Child) = Name))
          Result + 1
        EndIf
      EndIf
      If (Recursive And (NodeType = #XML_Normal))
        Result + XMLChildCountEx(*Child, Name, Type, #True)
      EndIf
      *Child = NextXMLNode(*Child)
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DeleteXMLChildren(*Node, Name.s = "", Type.i = #XML_Default, Recursive.i = #False)
  Protected Result.i = 0
  If (*Node And IsNormalXMLNode(*Node))
    If (Name And (Type = #XML_Default))
      Type = #XML_Normal
    EndIf
    Protected NodeType.i
    Protected *Next
    Protected *Child = ChildXMLNode(*Node)
    While (*Child)
      NodeType = XMLNodeType(*Child)
      If (Recursive And (NodeType = #XML_Normal))
        Result + DeleteXMLChildren(*Child, Name, Type, #True)
      EndIf
      *Next = NextXMLNode(*Child)
      If ((Type = #XML_Default) Or (Type = NodeType))
        If ((NodeType <> #XML_Normal) Or (Name = "") Or (GetXMLNodeName(*Child) = Name))
          DeleteXMLNode(*Child)
          Result + 1
        EndIf
      EndIf
      *Child = *Next
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure


CompilerEndIf
;-