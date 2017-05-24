; +-----------------------+
; | Hg (Mercurial) Module |
; +-----------------------+
; | 2016.07.11 . Started Module rewrite (PB 5.50b1)
; |        .12 . Added Remove, Forget, AddRemove, GetDirectory,
; |                ExamineLog and all Log functions, all Ignore functions
; | 2017.05.23 . Cleanup

CompilerIf (Not Defined(__Hg_Module, #PB_Constant))
#__Hg_Module = #True

;-
;- --------------- Module Interface ---------------

DeclareModule Hg
  
  ;-
  ;- Procedures
  
  ; Hg Interface
  Declare.i Init(Executable.s = "")
  Declare.s GetVersion()
  
  ; Repo Management
  Declare.i CreateRepo(Directory.s = "")
  Declare.i OpenRepo(Directory.s)
  Declare.i CloseRepo(*Repo)
  Declare.s GetDirectory(*Repo)
  
  ; Add and Remove
  Declare.i Add(*Repo, File.s = "")
  Declare.i Forget(*Repo, File.s)
  Declare.i Remove(*Repo, File.s)
  Declare.i AddRemove(*Repo)
  
  ; Commit and Revert
  Declare.i Commit(*Repo, Message.s)
  
  ; Repo Status
  Declare.i ExamineStatus(*Repo)
  Declare.i StatusEntryCount(*Repo)
  Declare.i NextStatusEntry(*Repo)
  Declare.s StatusEntryFile(*Repo)
  Declare.i StatusEntryType(*Repo)
  
  ; Repo Log
  Declare.i ExamineLog(*Repo, Ascending.i = #False)
  Declare.i LogEntryCount(*Repo)
  Declare.i NextLogEntry(*Repo)
  Declare.s LogEntryChangeset(*Repo)
  Declare.s LogEntryTag(*Repo)
  Declare.s LogEntryUser(*Repo)
  Declare.s LogEntryDateString(*Repo)
  Declare.s LogEntrySummary(*Repo)
  Declare.i LogEntryDate(*Repo)
  
  ; Ignore
  Declare.s GetIgnoreFile(*Repo)
  Declare.i Ignore(*Repo, File.s)
  Declare.i IgnoreType(*Repo, Extension.s)
  
  ; Diff
  Declare.i SaveDiff(*Repo, File.s)
  
  
  ;-
  ;- Constants
  
  ; Version of this PB Module
  #Module_Version = 20170523
  
  ; Status Entry Types
  #Status_Modified = 0
  #Status_Add      = 1
  #Status_Remove   = 2
  #Status_Missing  = 3
  #Status_Unknown  = 4
  
  ; Ignore Syntaxes
  #Ignore_RegExp = 0
  #Ignore_Glob   = 1
  
EndDeclareModule



;-
;- --------------- Module Implementation ---------------


Module Hg
EnableExplicit

;-
;- Constants (Private)

#Hg_RepoFolder = ".hg"
#Hg_IgnoreFile = ".hgignore"

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  #PS$  = "\"
  #NPS$ = "/"
CompilerElse
  #PS$  = "/"
  #NPS$ = "\"
CompilerEndIf

;-
;- Structures (Private)

Structure _Hg_Struct
  Init.i
  Executable.s
  Version.s
EndStructure

Structure _Hg_StringInt
  Str.s
  Int.i
EndStructure

Structure _Hg_LogEntry
  Changeset.s
  Tag.s
  User.s
  DateString.s
  Summary.s
  Date.i
EndStructure

Structure _Hg_Repo
  Directory.s
  List Status._Hg_StringInt()
  List Log._Hg_LogEntry()
  List Ignore._Hg_StringInt()
  LastIgnore.i[2]
EndStructure

;-
;- Variables (Private)

Global _Hg._Hg_Struct

;-
;- Macros (Private)

Macro AddStatusEntry(_Repo, _File, _Type)
  AddElement(_Repo\Status())
  _Repo\Status()\Str = _File
  _Repo\Status()\Int = _Type
EndMacro

Macro AddLogEntry(_Repo, _Changeset)
  If (Ascending)
    InsertElement(_Repo\Log())
  Else
    AddElement(_Repo\Log())
  EndIf
  _Repo\Log()\Changeset  = _Changeset
EndMacro

;-
;- Procedures (Private)

Procedure.s FormatPath(Path.s)
  If (Path)
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      ReplaceString(Path, #NPS$, #PS$, #PB_String_InPlace)
    CompilerEndIf
    Path = RTrim(Path, #PS$) + #PS$
  EndIf
  ProcedureReturn (Path)
EndProcedure

Procedure.s FormatFile(File.s)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ReplaceString(File, #NPS$, #PS$, #PB_String_InPlace)
  CompilerEndIf
  ProcedureReturn (File)
EndProcedure

Procedure.s ForwardSlashes(Path.s)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ReplaceString(Path, "\", "/", #PB_String_InPlace)
  CompilerEndIf
  ProcedureReturn (Path)
EndProcedure

Procedure.s Execute(Parameter.s, WorkingDirectory.s = "", ReplaceCR.i = #False)
  Protected Result.s = ""
  If (WorkingDirectory = "")
    WorkingDirectory = GetCurrentDirectory()
  EndIf
  Protected Flags.i = #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide
  Protected PID.i = RunProgram(_hg\Executable, Parameter, WorkingDirectory, Flags)
  If (PID)
    Protected Error.s
    While (ProgramRunning(PID))
      If (AvailableProgramOutput(PID))
        ;? UTF8 flag safe in older PB?
        Result + ReadProgramString(PID, #PB_UTF8) + #LF$
      Else
        Delay(1)
      EndIf
      ;? UTF8 flag safe in older PB?
      Error + ReadProgramError(PID, #PB_UTF8)
    Wend
    CloseProgram(PID)
    Result + Error
  EndIf
  Result = Trim(Result)
  CompilerIf (#False)
    Debug Parameter + " @ " + WorkingDirectory
    Debug Result + #LF$
  CompilerEndIf
  If (ReplaceCR)
    ReplaceString(Result, #CR$, #LF$, #PB_String_InPlace)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Init(Executable.s = "")
  Protected Result.i = #False
  ;
  _Hg\Init    = #False
  _Hg\Version = ""
  If (Executable)
    _Hg\Executable = Executable
  Else
    _Hg\Executable = "hg"
  EndIf
  ;
  Protected Output.s = Execute("version")
  Protected i.i = FindString(Output, "(version ")
  If (i)
    Protected j.i = FindString(Output, ")", i)
    If (j)
      _Hg\Version = Trim(Mid(Mid(Output, i, j - i), 1 + Len("(version ")))
      Result = #True
    EndIf
  EndIf
  ;
  _Hg\Init = Result
  ProcedureReturn (Result)
EndProcedure

Procedure.s GetVersion()
  ProcedureReturn (_Hg\Version)
EndProcedure

Procedure.i CreateRepo(Directory.s = "")
  Protected *Repo._Hg_Repo = #Null
  If (Not _Hg\Init)
    Init()
  EndIf
  If (_Hg\Init)
    If (Directory = "")
      Directory = GetCurrentDirectory()
    EndIf
    If (FileSize(Directory) = -2)
      Protected Output.s = Execute("init", Directory)
      If (Output = "")
        *Repo = OpenRepo(Directory)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Repo)
EndProcedure

Procedure.i OpenRepo(Directory.s)
  Protected *Repo._Hg_Repo = #Null
  If (Not _Hg\Init)
    Init()
  EndIf
  If (_Hg\Init)
    If (Directory)
      Directory = FormatPath(Directory)
      If (FileSize(Directory + #Hg_RepoFolder) = -2)
        *Repo = AllocateMemory(SizeOf(_Hg_Repo))
        If (*Repo)
          InitializeStructure(*Repo, _Hg_Repo)
          *Repo\Directory = Directory
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Repo)
EndProcedure

Procedure.i CloseRepo(*Repo._Hg_Repo)
  If (*Repo)
    ClearList(*Repo\Status())
    ClearList(*Repo\Log())
    ClearList(*Repo\Ignore())
    ClearStructure(*Repo, _Hg_Repo)
    FreeMemory(*Repo)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.s GetDirectory(*Repo._Hg_Repo)
  Protected Result.s
  If (*Repo)
    Result = *Repo\Directory
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ExamineStatus(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      ClearList(*Repo\Status())
      Protected Output.s = Execute("status", *Repo\Directory, #True)
      Protected n.i = CountString(Output, #LF$)
      Protected i.i
      For i = 1 To n + 1
        Protected Line.s = Trim(StringField(Output, i, #LF$))
        Select (Left(Line, 2))
          Case "? "
            AddStatusEntry(*Repo, Mid(Line, 3), #Status_Unknown)
          Case "A "
            AddStatusEntry(*Repo, Mid(Line, 3), #Status_Add)
          Case "R "
            AddStatusEntry(*Repo, Mid(Line, 3), #Status_Remove)
          Case "M "
            AddStatusEntry(*Repo, Mid(Line, 3), #Status_Modified)
          Case "! "
            AddStatusEntry(*Repo, Mid(Line, 3), #Status_Missing)
        EndSelect
      Next i
      ResetList(*Repo\Status())
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i StatusEntryCount(*Repo._Hg_Repo)
  Protected Result.i = 0
  If (_Hg\Init)
    If (*Repo)
      Result = ListSize(*Repo\Status())
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextStatusEntry(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Result = Bool(NextElement(*Repo\Status()))
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s StatusEntryFile(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Status()) >= 0)
      Result = *Repo\Status()\Str
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i StatusEntryType(*Repo._Hg_Repo)
  Protected Result.i = #Status_Unknown
  If (*Repo)
    If (ListIndex(*Repo\Status()) >= 0)
      Result = *Repo\Status()\Int
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Add(*Repo._Hg_Repo, File.s = "")
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Protected Output.s
      If (File)
        If (FindString(File, " "))
          File = #DQUOTE$ + File + #DQUOTE$
        EndIf
        Output = Execute("add " + File, *Repo\Directory)
      Else
        Output = Execute("add", *Repo\Directory)
      EndIf
      If (Not FindString(Output, "cannot find the file"))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Forget(*Repo._Hg_Repo, File.s)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Protected Output.s
      If (File)
        If (FindString(File, " "))
          File = #DQUOTE$ + File + #DQUOTE$
        EndIf
        Output = Execute("forget " + File, *Repo\Directory)
        If (Not FindString(Output, "cannot find the file"))
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Remove(*Repo._Hg_Repo, File.s)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Protected Output.s
      If (File)
        If (FindString(File, " "))
          File = #DQUOTE$ + File + #DQUOTE$
        EndIf
        Output = Execute("remove " + File, *Repo\Directory)
        If (Not FindString(Output, "cannot find the file"))
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i AddRemove(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Protected Output.s
      Output = Execute("addremove", *Repo\Directory)
      If (Not FindString(Output, "cannot find the file"))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Commit(*Repo._Hg_Repo, Message.s)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      If (Message)
        Message = #DQUOTE$ + Message + #DQUOTE$
        Protected Output.s = Execute("commit -m " + Message, *Repo\Directory)
        If (Output = "")
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ExamineLog(*Repo._Hg_Repo, Ascending.i = #False)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      ClearList(*Repo\Log())
      Protected Template.s = "cs:{rev}:{node|short}\n"
      Template + "tg:{tags}\n"
      Template + "us:{author}\n"
      Template + "ds:{date|date}\n"
      Template + "dt:{date}\n"
      Template + "su:{desc}\n"
      Template = #DQUOTE$ + Template + #DQUOTE$
      Protected Output.s = Execute("log --template " + Template, *Repo\Directory, #True)
      Protected n.i = CountString(Output, #LF$)
      Protected i.i
      For i = 1 To n + 1
        Protected Line.s = Trim(StringField(Output, i, #LF$))
        Select (Left(Line, 3))
          Case "cs:"
            AddLogEntry(*Repo, Mid(Line, 4))
          Case "tg:"
            *Repo\Log()\Tag = Mid(Line, 4)
          Case "us:"
            *Repo\Log()\User = Mid(Line, 4)
          Case "ds:"
            *Repo\Log()\DateString = Mid(Line, 4)
          Case "dt:"
            Line = Mid(Line, 4)
            *Repo\Log()\Date = Val(StringField(Line, 1, ".")) - Val(StringField(Line, 2, "."))
          Case "su:"
            *Repo\Log()\Summary = Mid(Line, 4)
        EndSelect
      Next i
      ResetList(*Repo\Log())
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LogEntryCount(*Repo._Hg_Repo)
  Protected Result.i = 0
  If (_Hg\Init)
    If (*Repo)
      Result = ListSize(*Repo\Log())
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextLogEntry(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo)
      Result = Bool(NextElement(*Repo\Log()))
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s LogEntryChangeset(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\Changeset
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s LogEntryTag(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\Tag
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s LogEntryUser(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\User
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s LogEntryDateString(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\DateString
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s LogEntrySummary(*Repo._Hg_Repo)
  Protected Result.s = ""
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\Summary
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LogEntryDate(*Repo._Hg_Repo)
  Protected Result.i = 0
  If (*Repo)
    If (ListIndex(*Repo\Log()) >= 0)
      Result = *Repo\Log()\Date
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SaveDiff(*Repo._Hg_Repo, File.s)
  Protected Result.i = #False
  If (_Hg\Init)
    If (*Repo And File)
      Protected Output.s = Execute("diff", *Repo\Directory)
      Protected FN.i = CreateFile(#PB_Any, File)
      If (FN)
        WriteString(FN, Output, #PB_UTF8)
        CloseFile(FN)
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s GetIgnoreFile(*Repo._Hg_Repo)
  Protected Result.s
  If (*Repo)
    Result = *Repo\Directory + #Hg_IgnoreFile
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LoadIgnoreFile(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (*Repo)
    ClearList(*Repo\Ignore())
    *Repo\LastIgnore[#Ignore_RegExp] = -1
    *Repo\LastIgnore[#Ignore_Glob]   = -1
    ;
    Protected File.s = GetIgnoreFile(*Repo)
    If (FileSize(File) > 0)
      Protected FN.i = ReadFile(#PB_Any, File)
      If (FN)
        Protected Type.i = #Ignore_RegExp
        While (Not Eof(FN))
          Protected Line.s = ReadString(FN, #PB_UTF8)
          Protected LLine.s = LCase(RemoveString(Line, " "))
          Select (LLine)
            Case "syntax:regexp"
              Type = #Ignore_RegExp
            Case "syntax:glob"
              Type = #Ignore_Glob
          EndSelect
          AddElement(*Repo\Ignore())
          *Repo\Ignore()\Str = Line
          *Repo\Ignore()\Int = Type
          If ((*Repo\LastIgnore[Type] = -1) Or (LLine))
            *Repo\LastIgnore[Type] = ListIndex(*Repo\Ignore())
          EndIf
        Wend
        CloseFile(FN)
        Result = #True
      EndIf
    Else
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i AddIgnoreLine(*Repo._Hg_Repo, Text.s, Type.i)
  Protected Result.i = #False
  If (*Repo)
    Protected Exists.i = #False
    If (*Repo\LastIgnore[Type] >= 0)
      ForEach (*Repo\Ignore())
        If ((*Repo\Ignore()\Int = Type) And (*Repo\Ignore()\Str = Text))
          Exists = #True
          Break
        EndIf
      Next
    Else
      LastElement(*Repo\Ignore())
      AddElement(*Repo\Ignore())
      Select (Type)
        Case #Ignore_RegExp
          *Repo\Ignore()\Str = "syntax: regexp"
        Case #Ignore_Glob
          *Repo\Ignore()\Str = "syntax: glob"
      EndSelect
      *Repo\Ignore()\Int = Type
      *Repo\LastIgnore[Type] = ListIndex(*Repo\Ignore())
    EndIf
    If ((*Repo\LastIgnore[Type] >= 0) And (Not Exists))
      SelectElement(*Repo\Ignore(), *Repo\LastIgnore[Type])
      AddElement(*Repo\Ignore())
      *Repo\Ignore()\Str = Text
      *Repo\Ignore()\Int = Type
      Result = #True
    ElseIf (Exists)
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SaveIgnoreFile(*Repo._Hg_Repo)
  Protected Result.i = #False
  If (*Repo)
    Protected FN.i = CreateFile(#PB_Any, GetIgnoreFile(*Repo))
    If (FN)
      ForEach (*Repo\Ignore())
        WriteStringN(FN, *Repo\Ignore()\Str, #PB_UTF8)
      Next
      CloseFile(FN)
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Ignore(*Repo._Hg_Repo, File.s)
  Protected Result.i = #False
  If (*Repo And File)
    File = FormatFile(File)
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      If (LCase(Left(File, Len(*Repo\Directory))) = LCase(*Repo\Directory))
        File = Mid(File, 1 + Len(*Repo\Directory))
      EndIf
    CompilerElse
      If (Left(File, Len(*Repo\Directory)) = *Repo\Directory)
        File = Mid(File, 1 + Len(*Repo\Directory))
      EndIf
    CompilerEndIf
    If (File)
      File = ForwardSlashes(File)
      If (LoadIgnoreFile(*Repo))
        AddIgnoreLine(*Repo, File, #Ignore_Glob)
        If (SaveIgnoreFile(*Repo))
          ;Add(*Repo, GetIgnoreFile(*Repo))
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i IgnoreType(*Repo._Hg_Repo, Extension.s)
  Protected Result.i = #False
  If (*Repo And Extension)
    If (Not FindString(Extension, "*."))
      Extension = "*." + Extension
    EndIf
    Extension = LCase(Extension)
    If (LoadIgnoreFile(*Repo))
      AddIgnoreLine(*Repo, Extension, #Ignore_Glob)
      If (SaveIgnoreFile(*Repo))
        ;Add(*Repo, GetIgnoreFile(*Repo))
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure



EndModule












;-
;- --------------- Demo Program ---------------

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Procedure.i CreateEmptyFile(File.s)
  ProcedureReturn CloseFile(CreateFile(#PB_Any, File))
EndProcedure

If (Hg::Init())
  
  ; Set up a temporary folder
  Debug "Hg Version: " + Hg::GetVersion()
  Path.s = GetTemporaryDirectory() + "_Test Repo"
  DeleteDirectory(Path, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
    Delay(1)
  CreateDirectory(Path)
    Delay(1)
  SetCurrentDirectory(Path)
  
  
  ; Create a Hg repo
  *Repo = Hg::CreateRepo(Path)
  If (*Repo)
    Path = Hg::GetDirectory(*Repo)
    Debug Path
    ;Debug Hg::GetIgnoreFile(*Repo)
    
    ; Create initial files
    CreateEmptyFile("main.txt")
    CreateEmptyFile("sub.txt")
    CreateEmptyFile("third.txt")
    Hg::Add(*Repo)
    
    ; Commit
    If (Hg::Commit(*Repo, "First Commit"))
      
      ; Change: delete a known file
      DeleteFile("sub.txt")
      
      ; Create (and ignore) a new file
      CreateEmptyFile("new.txt")
      Hg::Add(*Repo, "new.txt")
      
      ; Change: create new file
      CreateEmptyFile("fourth.txt")
      
      ; Change: edit a file
      If (CreateFile(0, Path + "main.txt"))
        WriteString(0, "Hello World!")
        CloseFile(0)
      EndIf
      
      ; Change: remove a file
      Hg::Remove(*Repo, "third.txt")
      
      ; Commit again
      ;Debug Hg::SaveDiff(*Repo, Path + "out.diff")
      Delay(3)
      Hg::Commit(*Repo, "SECOND")
      
      ; Create an example hgignore file
      If CreateFile(0, Hg::GetIgnoreFile(*Repo))
        WriteStringN(0, "syntax: glob")
        WriteStringN(0, "*.bmp")
        WriteStringN(0, "*.png")
        WriteStringN(0, "")
        WriteStringN(0, "syntax: regexp")
        WriteStringN(0, ".*\.temp")
        WriteStringN(0, "syntax: glob")
        WriteStringN(0, "*.old.*")
        CloseFile(0)
      EndIf
      
      ; Test ignore file edit
      Hg::Ignore(*Repo, Path + "fourth.txt")
      Hg::Ignore(*Repo, Path + "fourth.txt")
      Hg::Ignore(*Repo, Path + "fourth.txt")
      Hg::Ignore(*Repo, Path + "sub\this\okay.rar")
      Hg::IgnoreType(*Repo, "ZIP")
      
      ; Print out log
      If (#True)
        Debug ""
        If (Hg::ExamineLog(*Repo))
          ;Debug Hg::LogEntryCount(*Repo)
          While (Hg::NextLogEntry(*Repo))
            Debug Hg::LogEntryChangeset(*Repo)
            If (Hg::LogEntryTag(*Repo))
              Debug Hg::LogEntryTag(*Repo)
            EndIf
            Debug Hg::LogEntryUser(*Repo)
            Debug Hg::LogEntryDateString(*Repo)
            Debug Hg::LogEntrySummary(*Repo)
            ;Debug FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Hg::LogEntryDate(*Repo))
            Debug ""
          Wend
        Else
          Debug "Could not examine log"
        EndIf
      EndIf
      
      ; Print out current status
      If (#True)
        Debug ""
        If (Hg::ExamineStatus(*Repo))
          Debug "Status Entries: " + Str(Hg::StatusEntryCount(*Repo))
          While (Hg::NextStatusEntry(*Repo))
            Select (Hg::StatusEntryType(*Repo))
              Case Hg::#Status_Unknown
                Debug "Unknown: " + Hg::StatusEntryFile(*Repo)
              Case Hg::#Status_Add
                Debug "Add: " + Hg::StatusEntryFile(*Repo)
              Case Hg::#Status_Remove
                Debug "Remove: " + Hg::StatusEntryFile(*Repo)
              Case Hg::#Status_Missing
                Debug "Missing: " + Hg::StatusEntryFile(*Repo)
              Case Hg::#Status_Modified
                Debug "Modified: " + Hg::StatusEntryFile(*Repo)
            EndSelect
          Wend
        Else
          Debug "Could not examine status"
        EndIf
      EndIf
    Else
      Debug "Could not commit changes"
    EndIf
  Else
    Debug "Could not create repo"
  EndIf
Else
  Debug "Could not initialize Hg"
EndIf

CompilerEndIf
CompilerEndIf
;-