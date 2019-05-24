; +--------------+
; | PBP_Projects |
; +--------------+
; | 2015.01.23 . Creation (PureBasic 5.31)
; | 2016.10.26 . Added "dll", "so", "dylib" recognition
; | 2017.05.08 . Multiple-include safe, added demo, path separator fixing,
; |                added OS guessing based on icon file
; | 2019.05.24 . Added support for DPIAWARE compile flag (PB 5.70)

;-
CompilerIf (Not Defined(__PBP_Projects_Included, #PB_Constant))
#__PBP_Projects_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf





;- Procedures - PRIVATE

Procedure.i _PBP_IsValidProject(*Project)
  Protected Result.i = #False
  If (*Project And IsXML(*Project))
    Protected *Node = MainXMLNode(*Project)
    If (*Node)
      If (GetXMLNodeName(*Node) = "project")
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _PBP_IsValidTarget(*Target)
  Protected Result.i = #False
  If (*Target)
    If (XMLNodeType(*Target) = #PB_XML_Normal)
      If (GetXMLNodeName(*Target) = "target")
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _PBP_GetTargetsNode(*Project)
  Protected *Result = #Null
  If (_PBP_IsValidProject(*Project))
    *Result = ChildXMLNode(MainXMLNode(*Project))
    While (*Result)
      If (XMLNodeType(*Result) = #PB_XML_Normal)
        If (GetXMLNodeName(*Result) = "section")
          If (GetXMLAttribute(*Result, "name") = "targets")
            Break
          EndIf
        EndIf
      EndIf
      *Result = NextXMLNode(*Result)
    Wend
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.s _PBP_GetTargetValue(*Target, Name.s, Attribute.s = "value")
  Protected Result.s = ""
  If (Name)
    If (_PBP_IsValidTarget(*Target))
      Protected *Node = XMLNodeFromPath(*Target, Name)
      If (*Node)
        Result = GetXMLAttribute(*Node, Attribute)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _PBP_GetTargetOption(*Target, Name.s)
  Protected Result.i = #False
  If (Name)
    If (_PBP_IsValidTarget(*Target))
      Protected *Node = XMLNodeFromPath(*Target, "options")
      If (*Node)
        Result = Bool(GetXMLAttribute(*Node, Name) = "1")
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s _PBP_QuoteIfNeeded(Input.s)
  If ((Input = "") Or (FindString(Input, " ")))
    Input = #DQUOTE$ + Input + #DQUOTE$
  EndIf
  ProcedureReturn (Input)
EndProcedure





;-
;- Procedures - PUBLIC

Procedure.i PBP_LoadProject(File.s)
  Protected XML.i = LoadXML(#PB_Any, File)
  If (XML)
    If (Not _PBP_IsValidProject(XML))
      FreeXML(XML)
      XML = #Null
    EndIf
  EndIf
  ProcedureReturn (XML)
EndProcedure

Procedure.i PBP_FreeProject(*Project)
  If (*Project And IsXML(*Project))
    FreeXML(*Project)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i PBP_CountTargets(*Project)
  Protected Result.i = -1
  Protected *Targets = _PBP_GetTargetsNode(*Project)
  If (*Targets)
    Result = 0
    Protected *Child = ChildXMLNode(*Targets)
    While (*Child)
      If (XMLNodeType(*Child) = #PB_XML_Normal)
        If (GetXMLNodeName(*Child) = "target")
          Result + 1
        EndIf
      EndIf
      *Child = NextXMLNode(*Child)
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i PBP_GetTarget(*Project, Index.i)
  Protected *Result = #Null
  If (Index >= 0)
    Protected *Targets = _PBP_GetTargetsNode(*Project)
    If (*Targets)
      Protected Found.i = 0
      Protected *Child = ChildXMLNode(*Targets)
      While (*Child)
        If (XMLNodeType(*Child) = #PB_XML_Normal)
          If (GetXMLNodeName(*Child) = "target")
            If (Found = Index)
              *Result = *Child
              Break
            Else
              Found + 1
            EndIf
          EndIf
        EndIf
        *Child = NextXMLNode(*Child)
      Wend
    EndIf
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.s PBP_TargetName(*Target)
  Protected Result.s = ""
  If (_PBP_IsValidTarget(*Target))
    Result = GetXMLAttribute(*Target, "name")
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i PBP_TargetByName(*Project, Name.s)
  Protected *Result = #Null
  If (Name)
    Protected n.i = PBP_CountTargets(*Project)
    If (n > 0)
      Protected i.i
      For i = 0 To n -1
        Protected *Target = PBP_GetTarget(*Project, i)
        If (PBP_TargetName(*Target) = Name)
          *Result = *Target
          Break
        EndIf
      Next i
    EndIf
  EndIf
  ProcedureReturn (*Result)
EndProcedure

Procedure.s PBP_TargetInputFile(*Target)
  ProcedureReturn (_PBP_GetTargetValue(*Target, "inputfile"))
EndProcedure

Procedure.s PBP_TargetOutputFile(*Target)
  ProcedureReturn (_PBP_GetTargetValue(*Target, "outputfile"))
EndProcedure

Procedure.i PBP_TargetCurrentOS(*Target)
  Protected Result.i = #False
  Protected OutputFile.s = PBP_TargetOutputFile(*Target)
  If (OutputFile)
    Select (LCase(GetExtensionPart(OutputFile)))
      Case "exe", "dll"
        Result = Bool(#PB_Compiler_OS = #PB_OS_Windows)
      Case "app", "dylib"
        Result = Bool(#PB_Compiler_OS = #PB_OS_MacOS)
      Case "so"
        Result = Bool(#PB_Compiler_OS = #PB_OS_Linux)
      Default
        Protected IconFile.s
        Protected *IconNode = XMLNodeFromPath(*Target, "icon")
        If (*IconNode)
          IconFile = GetXMLNodeText(*IconNode)
        EndIf
        If (IconFile)
          Select (LCase(GetExtensionPart(IconFile)))
            Case "ico"
              Result = Bool(#PB_Compiler_OS = #PB_OS_Windows)
            Case "icns"
              Result = Bool(#PB_Compiler_OS = #PB_OS_MacOS)
            Default
              Result = #True
          EndSelect
        Else
          Result = #True
        EndIf
    EndSelect
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s PBP_TargetBuildString(*Target, ProjectPath.s = "")
  Protected Result.s = ""
  If (_PBP_IsValidTarget(*Target))
    Protected *Node
    Protected Value.s
    
    If (ProjectPath And (FileSize(ProjectPath) > 0))
      ProjectPath = GetPathPart(ProjectPath)
    EndIf
    
    Value = _PBP_GetTargetValue(*Target, "inputfile")
    If (Value)
      CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
        ReplaceString(Value, "/", "\", #PB_String_InPlace)
      CompilerEndIf
      Result = _PBP_QuoteIfNeeded(ProjectPath + Value)
      ;
      Value = _PBP_GetTargetValue(*Target, "outputfile")
      If (Value)
        CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
          ReplaceString(Value, "/", "\", #PB_String_InPlace)
        CompilerEndIf
        Result + " /EXE " + _PBP_QuoteIfNeeded(ProjectPath + Value)
      EndIf
      ;
      *Node = XMLNodeFromPath(*Target, "icon")
      If (*Node)
        Value = GetXMLNodeText(*Node)
        If (Value)
          CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
            ReplaceString(Value, "/", "\", #PB_String_InPlace)
          CompilerEndIf
          If (GetXMLAttribute(*Node, "enable") = "1")
            Result + " /ICON " + _PBP_QuoteIfNeeded(ProjectPath + Value)
          EndIf
        EndIf
      EndIf
      ;
      If (_PBP_GetTargetOption(*Target, "unicode"))
        Result + " /UNICODE"
      EndIf
      If (_PBP_GetTargetOption(*Target, "thread"))
        Result + " /THREAD"
      EndIf
      If (_PBP_GetTargetOption(*Target, "onerror"))
        Result + " /LINENUMBERING"
      EndIf
      If (_PBP_GetTargetOption(*Target, "xpskin"))
        Result + " /XP"
      EndIf
      If (_PBP_GetTargetOption(*Target, "dpiaware"))
        Result + " /DPIAWARE"
      EndIf
      If (_PBP_GetTargetOption(*Target, "admin"))
        Result + " /ADMINISTRATOR"
      ElseIf (_PBP_GetTargetOption(*Target, "user"))
        Result + " /USER"
      EndIf
      ;
      Value = _PBP_GetTargetValue(*Target, "subsystem")
      If (Value)
        Result + " /SUBSYSTEM " + _PBP_QuoteIfNeeded(Value)
      EndIf
      ;
      Select (_PBP_GetTargetValue(*Target, "format", "exe"))
        Case "console"
          Result + " /CONSOLE"
        Case "dll"
          Result + " /DLL"
        Default
          ;
      EndSelect
      ;
      *Node = XMLNodeFromPath(*Target, "constants")
      If (*Node)
        *Node = ChildXMLNode(*Node)
        While (*Node)
          If (XMLNodeType(*Node) = #PB_XML_Normal)
            If (GetXMLNodeName(*Node) = "constant")
              If (GetXMLAttribute(*Node, "enable") = "1")
                Value = GetXMLAttribute(*Node, "value")
                Value = RemoveString(Value, " ")
                Value = RemoveString(Value, "#")
                Result + " /CONSTANT " + Value
              EndIf
            EndIf
          EndIf
          *Node = NextXMLNode(*Node)
        Wend
      EndIf
      ;
      If (#True)
        Result + " /QUIET"
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

ProjectFile.s = OpenFileRequester("Open PB Project", GetHomeDirectory(), "PureBasic Projects (*.pbp)|*.pbp", 0)
If (ProjectFile)
  *Project = PBP_LoadProject(ProjectFile)
  If (*Project)
    NumTargets = PBP_CountTargets(*Project)
    Debug ProjectFile
    Debug "Targets: " + Str(NumTargets)
    
    For i = 0 To NumTargets - 1
      *Target = PBP_GetTarget(*Project, i)
      Debug ""
      Debug "[" + PBP_TargetName(*Target) + "]"
      Debug "Targets this OS? Guess = " + Str(PBP_TargetCurrentOS(*Target))
      Debug "Input = " + PBP_TargetInputFile(*Target)
      Debug "Output = " + PBP_TargetOutputFile(*Target)
      Debug "Compile params = " + PBP_TargetBuildString(*Target, ProjectFile)
    Next i
    
    PBP_FreeProject(*Project)
  Else
    Debug "Could not load project:"
    Debug ProjectFile
  EndIf
EndIf

CompilerEndIf
CompilerEndIf
;-