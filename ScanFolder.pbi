; +----------------+
; | ScanFolder.pbi |
; +----------------+
; | 2015.06.18 . Creation (PureBasic 5.31)
; |        .19 . Added extension filter, FinishScan, #PB_Defaults, sort
; |     .07.10 . Added optional RecurseDepth limit,
; |                changed Relative flag to Absolute (Relative default),
; |                added relative path Regex-matching (must be enabled)
; |     .08.27 . Use FileSize instead of DirectoryEntryType (for symlinks)
; |        .30 . Added ResetScanEntry, fixed ".." folder ignore
; | 2017.05.20 . Cleanup, added warning if RegexSupport is missing
; | 2020-06-19 . Don't warn about RegEx being disabled if not trying to use it!


CompilerIf (Not Defined(__ScanFolder_Included, #PB_Constant))
#__ScanFolder_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

#ScanFolder_IncludeVersion = 20200619







;-
;- Compile Switches (Public)


CompilerIf (Not Defined(ScanFolder_RegexSupport, #PB_Constant))
  #ScanFolder_RegexSupport = #PB_Compiler_IsMainFile
CompilerEndIf







;-
;- Constants (Public)

Enumeration ; ScanFolder Flags
  #ScanFolder_Recursive    = $0001  ; Scan sub-folders too
  #ScanFolder_Absolute     = $0002  ; Return absolute paths, not relative
  #ScanFolder_Folders      = $0004  ; Include folders in results
  #ScanFolder_NoFiles      = $0008  ; Exclude files from results
  #ScanFolder_NoHidden     = $0010  ; Exclude hidden files/folders
  ;
  #ScanFolder_DefaultFlags = $0000
EndEnumeration







;-
;- Constants (Private)

Enumeration ; ScanFolder Flags
  #_ScanFolder_Filter = $00010000
EndEnumeration

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  #_ScanFolder_PS$  = "\"
  #_ScanFolder_NPS$ = "/"
CompilerElse
  #_ScanFolder_PS$  = "/"
  #_ScanFolder_NPS$ = "\"
CompilerEndIf










;-
;- Structures (Private)

Structure _SCANFOLDER
  Flags.i
  Extensions.s
  Count.i
  Depth.i
  Regex.i
  List Result.s()
EndStructure





;-
;- Variables (Private)

Global _ScanFolder_LastSF.i = #Null










;-
;- Macros (Private)

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  
  Macro _ScanFolder_IsHidden(Root, Relative, Name)
    Bool(GetFileAttributes(Root + Relative + Name) & #PB_FileSystem_Hidden)
  EndMacro
  
CompilerElse

  Macro _ScanFolder_IsHidden(Root, Relative, Name)
    Bool(Left(Name, 1) = ".")
  EndMacro
  
CompilerEndIf










;-
;- Procedures (Private)

Procedure.i _ScanFolder_Examine(*SF._SCANFOLDER, Root.s, Relative.s, SubLevel.i)
  Protected Result.i = #False
  Protected Name.s
  If (*SF)
    Protected Dir.i = ExamineDirectory(#PB_Any, Root + Relative, "")
    If (Dir)
      Protected NewList Folder.s()
      Protected NewList File.s()
      While (NextDirectoryEntry(Dir))
        Name = DirectoryEntryName(Dir)
        If ((Not (*SF\Flags & #ScanFolder_NoHidden)) Or (Not _ScanFolder_IsHidden(Root, Relative, Name)))
          If ((Name = ".") Or (Name = ".."))
            ; do nothing
          ElseIf (FileSize(Root + Relative + Name) = -2)
            AddElement(Folder())
            Folder() = Name
          Else
            AddElement(File())
            File() = Name
          EndIf
        EndIf
      Wend
      FinishDirectory(Dir)
      If (*SF\Flags & #ScanFolder_Recursive)
        If (#True)
          SortList(Folder(), #PB_Sort_Ascending | #PB_Sort_NoCase)
        EndIf
        ForEach (Folder())
          If (*SF\Flags & #ScanFolder_Folders)
            AddElement(*SF\Result())
            *SF\Result() = Relative + Folder() + #_ScanFolder_PS$
          EndIf
          If ((*SF\Depth = 0) Or (SubLevel < *SF\Depth))
            _ScanFolder_Examine(*SF, Root, Relative + Folder() + #_ScanFolder_PS$, SubLevel + 1)
          EndIf
        Next
      ElseIf (*SF\Flags & #ScanFolder_Folders)
        If (#True)
          SortList(Folder(), #PB_Sort_Ascending | #PB_Sort_NoCase)
        EndIf
        ForEach (Folder())
          AddElement(*SF\Result())
          *SF\Result() = Relative + Folder() + #_ScanFolder_PS$
        Next
      EndIf
      If (Not (*SF\Flags & #ScanFolder_NoFiles))
        If (#True)
          SortList(File(), #PB_Sort_Ascending | #PB_Sort_NoCase)
        EndIf
        Protected Add.i
        Protected Ext.s
        ForEach (File())
          Add = #True
          If (*SF\Flags & #_ScanFolder_Filter)
            Ext = GetExtensionPart(File())
            If (Ext)
              If (Not FindString(*SF\Extensions, ";" + LCase(Ext) + ";"))
                Add = #False
              EndIf
            Else
              Add = #False
            EndIf
          EndIf
          CompilerIf (#ScanFolder_RegexSupport)
            If (Add And *SF\Regex)
              If (Not MatchRegularExpression(*SF\Regex, ReplaceString(Relative, "\", "/") + File()))
                Add = #False
              EndIf
            EndIf
          CompilerEndIf
          If (Add)
            AddElement(*SF\Result())
            *SF\Result() = Relative + File()
          EndIf
        Next
      EndIf
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s _ScanFolder_FormatExtensions(Extensions.s)
  Protected Result.s
  
  Protected *C.CHARACTER = @Extensions
  While (*C\c)
    Select (*C\c)
      Case ';', '|', ',', '*', '.'
        *C\c = ' '
      Default
        ;
    EndSelect
    *C + SizeOf(CHARACTER)
  Wend
  Extensions = Trim(Extensions)
  
  If (Extensions)
    Extensions = LCase(Extensions)
    Protected n.i = CountString(Extensions, " ") + 1
    Protected i.i
    Protected Term.s
    For i = 1 To n
      Term = StringField(Extensions, i, " ")
      If (Term)
        Result + ";" + Term
      EndIf
    Next i
    If (Result)
      Result + ";"
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure



















;-
;- Procedures (Public)

Procedure.i FinishScan(*ScanFolder._SCANFOLDER = #PB_Default)
  If (*ScanFolder = #PB_Default)
    *ScanFolder = _ScanFolder_LastSF
  EndIf
  If (*ScanFolder)
    CompilerIf (#ScanFolder_RegexSupport)
      If (*ScanFolder\Regex)
        FreeRegularExpression(*ScanFolder\Regex)
      EndIf
    CompilerEndIf
    ClearList(*ScanFolder\Result())
    ClearStructure(*ScanFolder, _SCANFOLDER)
    FreeMemory(*ScanFolder)
    If (_ScanFolder_LastSF = *ScanFolder)
      _ScanFolder_LastSF = #Null
    EndIf
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i ScanFolder(Folder.s, Flags.i = #Null, Extensions.s = "", RecurseDepth.i = 0, RegexPattern.s = "")
  Protected *SF._SCANFOLDER = #Null
  If (Folder)
    Protected Regex.i = #Null
    CompilerIf (#ScanFolder_RegexSupport)
      If (RegexPattern)
        RegexPattern = ReplaceString(RegexPattern, "\\", "/")
        CompilerIf (#True)
          If (Left(RegexPattern, 1) <> "^")
            RegexPattern = "^" + RegexPattern
          EndIf
          If (Right(RegexPattern, 1) <> "$")
            RegexPattern = RegexPattern + "$"
          EndIf
        CompilerEndIf
        Regex = CreateRegularExpression(#PB_Any, RegexPattern, #PB_RegularExpression_NoCase)
      EndIf
    CompilerElseIf (#PB_Compiler_Debugger)
      If (RegexPattern)
        Debug #PB_Compiler_Filename + " : Please define #ScanFolder_RegexSupport as #True before IncludeFile"
      EndIf
    CompilerEndIf
    If (Regex Or (RegexPattern = ""))
      *SF = AllocateMemory(SizeOf(_SCANFOLDER))
      If (*SF)
        InitializeStructure(*SF, _SCANFOLDER)
        ReplaceString(Folder, #_ScanFolder_NPS$, #_ScanFolder_PS$, #PB_String_InPlace)
        Folder = RTrim(Folder, #_ScanFolder_PS$) + #_ScanFolder_PS$
        If (Flags = #PB_Default)
          Flags = #ScanFolder_DefaultFlags
        EndIf
        If (Flags & #ScanFolder_NoFiles)
          Flags | #ScanFolder_Folders
        EndIf
        If (RecurseDepth > 0)
          Flags | #ScanFolder_Recursive
        ElseIf (RecurseDepth < 0)
          Flags | #ScanFolder_Recursive
          RecurseDepth = 0
        EndIf
        *SF\Extensions = _ScanFolder_FormatExtensions(Extensions)
        If (*SF\Extensions)
          Flags | #_ScanFolder_Filter
        EndIf
        *SF\Flags = Flags
        *SF\Depth = RecurseDepth
        *SF\Regex = Regex
        If (_ScanFolder_Examine(*SF, Folder, "", 0))
          If (Flags & #ScanFolder_Absolute)
            ForEach (*SF\Result())
              *SF\Result() = Folder + *SF\Result()
            Next
          EndIf
          ResetList(*SF\Result())
          _ScanFolder_LastSF = *SF
        Else
          *SF = FinishScan(*SF)
        EndIf
      Else
        CompilerIf (#ScanFolder_RegexSupport)
          If (Regex)
            FreeRegularExpression(Regex)
          EndIf
        CompilerEndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*SF)
EndProcedure

Procedure.i ScanEntryCount(*ScanFolder._SCANFOLDER = #PB_Default)
  Protected Result.i = -1
  If (*ScanFolder = #PB_Default)
    *ScanFolder = _ScanFolder_LastSF
  EndIf
  If (*ScanFolder)
    Result = ListSize(*ScanFolder\Result())
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ResetScanEntry(*ScanFolder._SCANFOLDER = #PB_Default)
  Protected Result.i = #False
  If (*ScanFolder = #PB_Default)
    *ScanFolder = _ScanFolder_LastSF
  EndIf
  If (*ScanFolder)
    ResetList(*ScanFolder\Result())
    Result = #True
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextScanEntry(*ScanFolder._SCANFOLDER = #PB_Default)
  Protected Result.i = #False
  If (*ScanFolder = #PB_Default)
    *ScanFolder = _ScanFolder_LastSF
  EndIf
  If (*ScanFolder)
    Result = Bool(NextElement(*ScanFolder\Result()))
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s ScanEntryPath(*ScanFolder._SCANFOLDER = #PB_Default)
  Protected Result.s = ""
  If (*ScanFolder = #PB_Default)
    *ScanFolder = _ScanFolder_LastSF
  EndIf
  If (*ScanFolder)
    If (ListIndex(*ScanFolder\Result()) >= 0)
      Result = *ScanFolder\Result()
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

















;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  ; Simple example: list files in temp directory
  If ScanFolder(GetTemporaryDirectory())
    Debug "Files in Temporary directory:"
    Debug "-----------------------------"
    While NextScanEntry()
      Debug ScanEntryPath()
    Wend
    Debug ""
    FinishScan()
  EndIf
  
  ; List folders in home directory (two levels deep)
  If ScanFolder(GetHomeDirectory(), #ScanFolder_NoFiles, "", 1)
    Debug "Folders (two levels) in Home directory:"
    Debug "-----------------------------"
    While NextScanEntry()
      Debug ScanEntryPath()
    Wend
    Debug ""
    FinishScan()
  EndIf
  
  ; Text files, excluding hidden, absolute paths
  If ScanFolder(GetHomeDirectory(), #ScanFolder_Absolute | #ScanFolder_NoHidden | #ScanFolder_Recursive, "*.txt")
  ;If ScanFolder(GetHomeDirectory(), #ScanFolder_Absolute | #ScanFolder_NoHidden | #ScanFolder_Recursive, "", 0, ".*\.txt")
    Debug "Text files in Home directory:"
    Debug "-----------------------------"
    While NextScanEntry()
      Debug ScanEntryPath()
    Wend
    FinishScan()
  EndIf
  
CompilerEndIf
CompilerEndIf
;-