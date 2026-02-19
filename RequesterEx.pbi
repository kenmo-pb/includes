; +-------------+
; | RequesterEx |
; +-------------+
; | 2015.05.09 . Creation (PureBasic 5.31)
; |     .06.02 . Fixed false extensions on Mac (SelectedFilePattern()=0 on Mac)
; |     .08.18 . Reworked pattern/extension handling (Win and Mac safe)
; |        .19 . Handled files like '.log' correctly,
; |                '*.*' is now guessed for unrecognized default files,
; |                reworked pattern guessing (no more negative parameters),
; |                missing folders now map to top existing parent
; |     .12.16 . Implemented SelectedFileList(), MultiFileRequesterEx()
; | 2017.05.10 . Made PathReq params optional, cleaned up demo,
; |                saved last folder between Open/Save RequesterEx calls,
; |                fixed duplicate extension bug such as (*.txt)(*.txt),
; |                replaced "Guess" params with a Pattern of -1
; | 2017.08.11 . Trim trailing periods on Windows save filenames
; | 2019.11.11 . Added PrepareFileRequesterEx() and related
; | 2019.11.19 . Improved Prepare by moving temp Requester to main thread
; | 2020-02-22 . Replaced dummy-requester Prepare method with path modification
; | 2021-03-19 . Added NextSelectedFileNameEx(), RequesterExAddedExtension()
; | 2021-08-20 . Ensure trailing PS$ if default path is a folder
; | 2021-09-05 . Set ActivationPolicy for MacOS console mode requesters
; | 2026-02-19 . Added Window ParentID support for PB 6.10+ requesters

;-
CompilerIf (Not Defined(__RequesterEx_Included, #PB_Constant))
#__RequesterEx_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

CompilerIf (#PB_Compiler_Version >= 610)
  #__RequesterEx_ParentIDSupport = #True
CompilerElse
  #__RequesterEx_ParentIDSupport = #False
CompilerEndIf




;- Macros (Private)

Macro __RequesterEx_CountPatterns(PatternString)
  (((CountString((PatternString), "|")) + 1) / 2)
EndMacro

Macro __RequesterEx_PatternName(PatternString, Index)
  ; 0-based index
  Trim(StringField((PatternString), 1 + 2*(Index), "|"))
EndMacro

Macro __RequesterEx_PatternFilter(PatternString, Index)
  ; 0-based index
  RemoveString(StringField((PatternString), 2 + 2*(Index), "|"), " ")
EndMacro

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
Macro __RequesterEx_PS()
  "\"
EndMacro
CompilerElse
Macro __RequesterEx_PS()
  "/"
EndMacro
CompilerEndIf

CompilerIf ((#PB_Compiler_OS = #PB_OS_Windows) And (#True))
Global __RequesterEx_Prepared.i = #False
Macro __RequesterEx_PreparePathVar(PathVar)
  If (Not __RequesterEx_Prepared)
    __RequesterEx_Prepared = #True
    PathVar = GetPathPart(PathVar) + Str(Date()) + "\..\" + GetFilePart(PathVar)
  EndIf
EndMacro
CompilerElse
Macro __RequesterEx_PreparePathVar(PathVar)
  ;
EndMacro
CompilerEndIf

CompilerIf ((#PB_Compiler_OS = #PB_OS_MacOS) And (#True))
Procedure __RequesterEx_SetActivationPolicy()
  CocoaMessage(0, CocoaMessage(0, 0, "NSApplication sharedApplication"), "setActivationPolicy:", 0) ; #NSApplicationActivationPolicyRegular
EndProcedure
CompilerElse
Macro __RequesterEx_SetActivationPolicy()
  ;
EndMacro
CompilerEndIf




;-
;- Variables (Private)

Threaded __RequesterEx_SelectedPattern.i = 0
Threaded __RequesterEx_FirstFile.s       = ""
Threaded __RequesterEx_LastFolder.s      = ""
Threaded __RequesterEx_AddedExtension.i  = #False

CompilerIf (#__RequesterEx_ParentIDSupport)
  Global __RequesterEx_ParentID.i = #Null
CompilerEndIf


;-
;- Procedures (Private)

Procedure.s __RequesterEx_FormatPattern(PatternString.s)
  Protected Result.s = ""
  If (PatternString)
    Protected n.i = __RequesterEx_CountPatterns(PatternString)
    Protected Name.s
    Protected i.i
    For i = 0 To n - 1
      Name = __RequesterEx_PatternName(PatternString, i)
      Result + Name
      If (Not FindString(Name, "("))
        Result + " (" + __RequesterEx_PatternFilter(PatternString, i) + ")"
      EndIf
      Result + "|" + __RequesterEx_PatternFilter(PatternString, i)
      If (i < n - 1)
        Result + "|"
      EndIf
    Next i
  Else
    Result = "All Files (*.*)|*.*"
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i __RequesterEx_GuessPattern(PatternList.s, File.s, DefaultPattern.i)
  Protected Result.i = DefaultPattern
  If (Result < 0)
    Result = 0
  EndIf
  Protected Ext.s
  If (FindString(File, "."))
    Ext = GetExtensionPart(File)
    If (Ext = "")
      Ext = Trim(File, ".")
    EndIf
  Else
    Ext = Trim(File)
  EndIf
  If (Ext)
    PatternList = LCase(PatternList)
    Protected n.i = __RequesterEx_CountPatterns(PatternList)
    If (n > 0)
      Ext = LCase(Ext)
      Protected Found.i = #False
      Protected AllPattern.i = -1
      Protected i.i
      For i = 0 To n - 1
        If (FindString(__RequesterEx_PatternFilter(PatternList, i) + ";", "*." + Ext + ";"))
          Found = #True
          Result = i
          Break
        ElseIf (FindString(__RequesterEx_PatternFilter(PatternList, i) + ";", "*.*;"))
          AllPattern = i
        EndIf
      Next i
      If ((Not Found) And (AllPattern >= 0))
        Result = AllPattern
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s __RequesterEx_TopExisting(Path.s)
  If (Path)
    Path = RTrim(Path, __RequesterEx_PS()) + __RequesterEx_PS()
    While (Path And (FileSize(Path) <> -2))
      Path = GetPathPart(RTrim(Path, __RequesterEx_PS()))
    Wend
  EndIf
  ProcedureReturn (Path)
EndProcedure






;-
;- Macros (Public)

Macro MultiFileRequesterEx(Title = "Open", DefaultFile = "", Pattern = "", PatternPosition = 0)
  OpenFileRequesterEx(Title, DefaultFile, Pattern, (PatternPosition), #True)
EndMacro

Macro NextSelectedFileNameEx()
  NextSelectedFileName()
EndMacro

Macro RequesterExAddedExtension()
  (__RequesterEx_AddedExtension)
EndMacro


;-
;- Procedures (Public)

Procedure.i SetRequesterExParentID(ParentID.i)
  CompilerIf (#__RequesterEx_ParentIDSupport)
    __RequesterEx_ParentID = ParentID
  CompilerEndIf
  ProcedureReturn (#__RequesterEx_ParentIDSupport)
EndProcedure

Procedure.s PathRequesterEx(Title.s = "", InitialPath.s = "")
  __RequesterEx_SetActivationPolicy()
  
  If (Title = "")
    Title = "Path"
  EndIf
  If (InitialPath = "")
    InitialPath = GetHomeDirectory()
  EndIf
  CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
    If (InitialPath = "/")
      InitialPath = "///"
    Else
      CompilerIf (#PB_Compiler_Version <= 531)
        InitialPath + __RequesterEx_PS()
      CompilerEndIf
    EndIf
  CompilerEndIf
  
  CompilerIf (#__RequesterEx_ParentIDSupport)
    ProcedureReturn (PathRequester(Title, InitialPath, __RequesterEx_ParentID))
  CompilerElse
    ProcedureReturn (PathRequester(Title, InitialPath))
  CompilerEndIf
EndProcedure

Procedure.i SelectedRequesterExPattern()
  ProcedureReturn (__RequesterEx_SelectedPattern)
EndProcedure

Procedure.s SaveFileRequesterEx(Title.s = "Save", DefaultFile.s = "", Pattern.s = "", PatternPosition.i = #PB_Default)
  Protected Result.s = ""
  
  __RequesterEx_SetActivationPolicy()
  
  If (DefaultFile = "")
    If (__RequesterEx_LastFolder = "")
      __RequesterEx_LastFolder = GetCurrentDirectory()
    EndIf
    DefaultFile = __RequesterEx_LastFolder
  EndIf
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ReplaceString(DefaultFile, "/", "\", #PB_String_InPlace)
  CompilerEndIf
  If (FileSize(DefaultFile) = -2)
    If (Right(DefaultFile, 1) <> __RequesterEx_PS())
      DefaultFile + __RequesterEx_PS()
    EndIf
  EndIf
  Protected DefPath.s = GetPathPart(DefaultFile)
  Protected DefFile.s = GetFilePart(DefaultFile)
  DefaultFile = __RequesterEx_TopExisting(DefPath) + DefFile
  
  Protected Guess.i = #False
  If (PatternPosition < 0)
    PatternPosition = 0
    Guess = #True
  EndIf
  
  Protected PatternEx.s = __RequesterEx_FormatPattern(Pattern)
  If (DefFile And Guess)
    PatternPosition = __RequesterEx_GuessPattern(PatternEx, DefFile, PatternPosition)
  EndIf
  
  __RequesterEx_PreparePathVar(DefaultFile)
  
  __RequesterEx_AddedExtension = #False
  CompilerIf (#__RequesterEx_ParentIDSupport)
    Result = SaveFileRequester(Title, DefaultFile, PatternEx, PatternPosition, __RequesterEx_ParentID)
  CompilerElse
    Result = SaveFileRequester(Title, DefaultFile, PatternEx, PatternPosition)
  CompilerEndIf
  If (Result)
    __RequesterEx_LastFolder = GetPathPart(Result)
    CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
      __RequesterEx_SelectedPattern = PatternPosition
    CompilerElse
      __RequesterEx_SelectedPattern = SelectedFilePattern()
    CompilerEndIf
    
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      Result = RTrim(Result, ".")
    CompilerEndIf
    
    Protected Extension.s = LCase(GetExtensionPart(Result))
    If ((Extension = "") And (Not FindString(GetFilePart(Result), ".")))
      Protected SelectedFilter.s = __RequesterEx_PatternFilter(Pattern, __RequesterEx_SelectedPattern)
      If ((SelectedFilter = "") Or (SelectedFilter = "*") Or (SelectedFilter = "*.*"))
        ; Append nothing
      Else
        Extension = StringField(SelectedFilter, 1, ";")
        Extension = StringField(Extension, 2, "*.")
        Result + "." + Extension
        __RequesterEx_AddedExtension = #True
      EndIf
    EndIf
    
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s OpenFileRequesterEx(Title.s = "Open", DefaultFile.s = "", Pattern.s = "", PatternPosition.i = #PB_Default, MultiSelect.i = #False)
  Protected Result.s = ""
  
  __RequesterEx_SetActivationPolicy()
  
  If (DefaultFile = "")
    If (__RequesterEx_LastFolder = "")
      __RequesterEx_LastFolder = GetCurrentDirectory()
    EndIf
    DefaultFile = __RequesterEx_LastFolder
  EndIf
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ReplaceString(DefaultFile, "/", "\", #PB_String_InPlace)
  CompilerEndIf
  If (FileSize(DefaultFile) = -2)
    If (Right(DefaultFile, 1) <> __RequesterEx_PS())
      DefaultFile + __RequesterEx_PS()
    EndIf
  EndIf
  Protected DefPath.s = GetPathPart(DefaultFile)
  Protected DefFile.s = GetFilePart(DefaultFile)
  DefaultFile = __RequesterEx_TopExisting(DefPath) + DefFile
  
  Protected Guess.i = #False
  If (PatternPosition < 0)
    PatternPosition = 0
    Guess = #True
  EndIf
  
  Protected PatternEx.s = __RequesterEx_FormatPattern(Pattern)
  If (DefFile And Guess)
    PatternPosition = __RequesterEx_GuessPattern(PatternEx, DefFile, PatternPosition)
  EndIf
  
  __RequesterEx_PreparePathVar(DefaultFile)
  
  __RequesterEx_AddedExtension = #False
  CompilerIf (#__RequesterEx_ParentIDSupport)
    Result = OpenFileRequester(Title, DefaultFile, PatternEx, PatternPosition, Bool(MultiSelect) * #PB_Requester_MultiSelection, __RequesterEx_ParentID)
  CompilerElse
    Result = OpenFileRequester(Title, DefaultFile, PatternEx, PatternPosition, Bool(MultiSelect) * #PB_Requester_MultiSelection)
  CompilerEndIf
  __RequesterEx_FirstFile = Result
  If (Result)
    __RequesterEx_LastFolder = GetPathPart(Result)
    CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
      __RequesterEx_SelectedPattern = PatternPosition
    CompilerElse
      __RequesterEx_SelectedPattern = SelectedFilePattern()
    CompilerEndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s SelectedFileList(Delimiter.s = #LF$)
  Protected Result.s
  If (__RequesterEx_FirstFile)
    Result = __RequesterEx_FirstFile
    Protected File.s = NextSelectedFileName()
    While (File)
      Result + Delimiter + File
      File = NextSelectedFileName()
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure





;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  CompilerIf (#PB_Compiler_Version >= 610)
    OpenWindow(0, 0, 0, 640, 480, #PB_Compiler_Filename, #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
    SetRequesterExParentID(WindowID(0))
  CompilerEndIf
  
  ; All parameters optional
  Debug OpenFileRequesterEx()
  
  ; Last selected path is remembered
  Debug OpenFileRequesterEx("Last Folder")
  
  ; Missing folders are corrected to their parent folder
  Debug OpenFileRequesterEx("Missing Folder", GetTemporaryDirectory() + "Missing_Folder/Not_Found/")
  
  ; Extensions are automatically appended to pattern names
  Debug OpenFileRequesterEx("Pattern Extensions", "", "Text Files|*.txt;*.doc|All Files|*.*")
  
  ; MultiSelect simply a #True/#False (or this macro), results returned in one delimited string
  MultiFileRequesterEx("MultiSelect")
  Debug SelectedFileList()
  
  ; Pattern guessed by default file extension
  Debug OpenFileRequesterEx("Guessed Pattern", GetHomeDirectory() + "test.png", "BMP|*.bmp|PNG|*.png|JPEG|*.jpg;*.jpeg")
  
  
  
  
  
  ; Save parameters optional too
  Debug SaveFileRequesterEx()
  
  ; Extension automatically appended
  Debug SaveFileRequesterEx("Auto Extension", GetTemporaryDirectory() + "tempFile", "JPEG|*.jpg;*.jpeg")
  
  ; Pattern also guessed by default file extension
  Debug SaveFileRequesterEx("Guessed Pattern", GetHomeDirectory() + "test.png", "BMP|*.bmp|PNG|*.png|JPEG|*.jpg;*.jpeg")
  
  
  
  
  ; PathRequesterEx params also optional, Mac bugs are corrected
  Debug PathRequesterEx()
  
CompilerEndIf
CompilerEndIf
;-
