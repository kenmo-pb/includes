; +------------------+
; | EnvironmentPaths |
; +------------------+
; | 2016.03.23 . Creation
; | 2017.05.05 . Multiple-include safe, cleaned up code

;-
CompilerIf (Not Defined(__EnvironmentPaths_Included, #PB_Constant))
#__EnvironmentPaths_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Constants (Public)

Enumeration
  #EnvPaths_Sort         = $01
  #EnvPaths_NoDuplicates = $02
  #EnvPaths_NoMissing    = $04
EndEnumeration

;-
;- Lists (Private)

Global NewList _EnvPath.s()

;-
;- Procedures (Public)

Procedure.i ExamineEnvironmentPaths(Flags.i = #Null)
  ClearList(_EnvPath())
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Protected Raw.s = GetEnvironmentVariable("Path")
    If (Raw)
      Protected n.i = 1 + CountString(Raw, ";")
      Protected Invalid.i
      Protected i.i
      For i = 1 To n
        Protected Path.s = StringField(Raw, i, ";")
        If (Path)
          If (Right(Path, 1) <> "\")
            Path + "\"
          EndIf
          Select (FileSize(Path))
            Case -2
              Invalid = #False
            Case -1
              Invalid = Bool(Flags & #EnvPaths_NoMissing)
            Default
              Invalid = #True
          EndSelect
          If (Flags & #EnvPaths_NoDuplicates)
            ForEach (_EnvPath())
              If (LCase(_EnvPath()) = LCase(Path))
                Invalid = #True
                LastElement(_EnvPath())
                Break
              EndIf
            Next
          EndIf
          If (Not Invalid)
            AddElement(_EnvPath())
            _EnvPath() = Path
          EndIf
        EndIf
      Next i
      If (Flags & #EnvPaths_Sort)
        SortList(_EnvPath(), #PB_Sort_Ascending | #PB_Sort_NoCase)
      EndIf
    EndIf
  CompilerEndIf
  ResetList(_EnvPath())
  ProcedureReturn (ListSize(_EnvPath()))
EndProcedure

Procedure.i NextEnvironmentPath()
  ProcedureReturn (NextElement(_EnvPath()))
EndProcedure

Procedure.s EnvironmentPath()
  If (ListIndex(_EnvPath()) >= 0)
    ProcedureReturn (_EnvPath())
  EndIf
EndProcedure

Procedure AddEnvironmentPath(Path.s)
  If (Path)
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      Protected PathList.s = ";" + GetEnvironmentVariable("Path") + ";"
      Path = RTrim(ReplaceString(Path, "/", "\"), "\")
      If (FindString(LCase(PathList), ";" + LCase(Path) + ";") Or
          FindString(LCase(PathList), ";" + LCase(Path) + "\;"))
      Else
        PathList + Path + "\"
      EndIf
      PathList = Trim(PathList, ";")
      SetEnvironmentVariable("Path", PathList)
    CompilerEndIf
  EndIf
EndProcedure




;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Macro Underline(_Text, _Character = "-")
  (_Text + #LF$ + RSet("", 3*Len(_Text)/2, (_Character)))
EndMacro


AddEnvironmentPath("C:\MyFakePath")

Debug Underline("All Paths")
If ExamineEnvironmentPaths()
  While NextEnvironmentPath()
    Debug EnvironmentPath()
  Wend
EndIf

Debug #LF$
Debug Underline("Sort, NoDuplicates, NoMissing")
If ExamineEnvironmentPaths(#EnvPaths_Sort | #EnvPaths_NoDuplicates | #EnvPaths_NoMissing)
  While NextEnvironmentPath()
    Debug EnvironmentPath()
  Wend
EndIf

CompilerEndIf
CompilerEndIf
;-