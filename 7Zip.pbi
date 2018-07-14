; +--------------+
; | 7-Zip Helper |
; +--------------+
; | 2015.10.13 . Added Add7ZipFile and password/flags
; | 2017.01.06 . Added Examine Files/Folders, Extract File
; |     .03.16 . Made file multiple-include safe, rewrote demo
; |     .04.06 . Delete temporary unzip folder

;-
CompilerIf (Not Defined(__7Zip_Included, #PB_Constant))
#__7Zip_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;- Constants (Public)

; Can't start a constant's name with a number, like #7Zip_
#SevenZip_IncludeVersion = 20170316

Enumeration ; 7Zip Flags
  #SevenZip_EncryptNames = $01
EndEnumeration



;-
;- Structures (Private)

Structure __7ZIPSTRUCT
  Init.i
  Executable.s
  ExitCode.i
  Output.s
  VersionS.s
  VersionI.i
  Password.s
  Flags.i
  ;
  nFiles.i
  FileList.s
  nFolders.i
  FolderList.s
EndStructure


;-
;- Globals (Private)

Global __7Zip.__7ZIPSTRUCT


;-
;- Procedures (Private)

Procedure.i __7Zip_Run(Executable.s, Parameter.s = "", Directory.s = "")
  Protected PID.i = #Null
  With __7Zip
    \ExitCode = 0
    \Output = ""
    PID = RunProgram(Executable, Parameter, Directory, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read)
    If (PID)
      While (ProgramRunning(PID))
        While (AvailableProgramOutput(PID))
          CompilerIf (#PB_Compiler_Version < 540)
            \Output + ReadProgramString(PID, #PB_Unicode) + #LF$
          CompilerElse
            \Output + ReadProgramString(PID, #PB_UTF8) + #LF$
          CompilerEndIf
        Wend
        Delay(1)
      Wend
      \ExitCode = ProgramExitCode(PID)
      CloseProgram(PID)
    EndIf
  EndWith
  ProcedureReturn (Bool(PID))
EndProcedure


;-
;- Procedures (Public)

Procedure Reset7Zip()
  With __7Zip
    \Password = ""
    \Flags = #Null
  EndWith
EndProcedure

Procedure Set7ZipPassword(Password.s)
  With __7Zip
    \Password = Password
  EndWith
EndProcedure

Procedure Set7ZipFlags(Flags.i)
  With __7Zip
    \Flags = Flags
  EndWith
EndProcedure

Procedure.i Init7Zip(Executable.s = "")
  With __7Zip
    If (Not \Init)
      If (Executable = "")
        Executable = GetCurrentDirectory() + "7za.exe"
      EndIf
      If (__7Zip_Run(Executable))
        Protected i.i = FindString(\Output, "7-Zip (A) ", 1, #PB_String_NoCase)
        If (i)
          \Executable = Executable
          \VersionS = StringField(Trim(Mid(\Output, i + 10)), 1, " ")
          \VersionI = Round(100.0 * ValF(\VersionS), #PB_Round_Nearest)
          Reset7Zip()
          \Init = #True
        EndIf
      EndIf
    EndIf
    ProcedureReturn (\Init)
  EndWith
EndProcedure

Procedure.s Get7ZipVersion()
  With __7Zip
    If (\Init)
      ProcedureReturn (\VersionS)
    Else
      ProcedureReturn ("")
    EndIf
  EndWith
EndProcedure

Procedure.i Get7ZipBuildNumber()
  With __7Zip
    If (\Init)
      ProcedureReturn (\VersionI)
    Else
      ProcedureReturn (0)
    EndIf
  EndWith
EndProcedure

Procedure.i Add7ZipFile(Archive.s, File.s)
  Protected Result.i = #False
  With __7Zip
    If (\Init)
      If (FileSize(File) >= 0)
        Protected Param.s = "a"
        Param + " " + #DQUOTE$ + Archive + #DQUOTE$
        Param + " " + #DQUOTE$ + File    + #DQUOTE$
        If (\Password)
          Param + " -p" + \Password
          If (\Flags & #SevenZip_EncryptNames)
            Param + " -mhe"
          EndIf
        EndIf
        If (__7Zip_Run(\Executable, Param, GetPathPart(Archive)))
          If (\ExitCode = 0)
            Result = #True
          EndIf
        EndIf
      EndIf
    EndIf
  EndWith
  ProcedureReturn (Result)
EndProcedure

Procedure.i Extract7ZipFile(Archive.s, File.s, Destination.s = "")
  Protected Result.i = #False
  With __7Zip
    If (\Init)
      If ((FileSize(Archive) >= 0) And (File))
        If (GetPathPart(Archive) = "")
          Archive = GetCurrentDirectory() + Archive
        EndIf
        If (Destination)
          If (GetPathPart(Destination) = "")
            Destination = GetPathPart(Archive) + Destination
          EndIf
        Else
          Destination = GetPathPart(Archive)
        EndIf
        If (FileSize(Destination) = -2)
          Destination = RTrim(Destination, "\") + "\" + File
        EndIf
        Protected TempDir.s = GetTemporaryDirectory() + "7ZPB" + "\"
        CreateDirectory(TempDir)
        Protected TempFile.s = TempDir + GetFilePart(File)
        DeleteFile(TempFile)
        Protected Param.s = "e"
        Param + " "   + #DQUOTE$ + Archive + #DQUOTE$
        Param + " -o" + #DQUOTE$ + TempDir + #DQUOTE$
        Param + " "   + #DQUOTE$ + File    + #DQUOTE$
        Param + " -y"
        If (\Password)
          Param + " -p" + \Password
          If (\Flags & #SevenZip_EncryptNames)
            Param + " -mhe"
          EndIf
        EndIf
        If (__7Zip_Run(\Executable, Param, GetPathPart(Archive)))
          If (\ExitCode = 0)
            CreateDirectory(GetPathPart(Destination))
            DeleteFile(Destination)
            If (RenameFile(TempFile, Destination))
              Result = #True
            Else
              DeleteFile(TempFile)
            EndIf
          EndIf
        EndIf
        DeleteDirectory(TempDir, "")
      EndIf
    EndIf
  EndWith
  ProcedureReturn (Result)
EndProcedure

Procedure.i Examine7ZipFiles(Archive.s)
  Protected Result.i = 0
  With __7Zip
    If (\Init)
      If (FileSize(Archive) >= 0)
        Protected Param.s = "l"
        Param + " " + #DQUOTE$ + Archive + #DQUOTE$
        If (\Password)
          Param + " -p" + \Password
        EndIf
        If (__7Zip_Run(\Executable, Param, GetPathPart(Archive)))
          If (\ExitCode = 0)
            Protected Lines.i = 1 + CountString(\Output, #LF$)
            \nFiles     = 0
            \FileList   = ""
            \nFolders   = 0
            \FolderList = ""
            Protected i.i
            Protected InList.i = #False
            Protected NameOffset.i
            For i = 1 To Lines
              Protected Line.s = StringField(\Output, i, #LF$)
              If (InList)
                If (Left(Line, 19) = "-------------------")
                  Break
                Else
                  If (Mid(Line, 21, 1) = "D")
                    \FolderList + #LF$ + Mid(Line, NameOffset)
                    \nFolders + 1
                  Else
                    \FileList + #LF$ + Mid(Line, NameOffset)
                    \nFiles + 1
                  EndIf
                EndIf
              Else
                If Right(Line, 6) = "  Name"
                  NameOffset = Len(Line) - 4 + 1
                ElseIf (Left(Line, 19) = "-------------------")
                  InList = #True
                EndIf
              EndIf
            Next i
            \FileList = Mid(\FileList, 2)
            \FolderList = Mid(\FolderList, 2)
            Result = #True
          EndIf
        EndIf
      EndIf
    EndIf
  EndWith
  ProcedureReturn (Result)
EndProcedure

Procedure.i Get7ZipFileCount()
  ProcedureReturn (__7Zip\nFiles)
EndProcedure

Procedure.s Get7ZipFileList()
  ProcedureReturn (__7Zip\FileList)
EndProcedure

Procedure.i Get7ZipFolderCount()
  ProcedureReturn (__7Zip\nFolders)
EndProcedure

Procedure.s Get7ZipFolderList()
  ProcedureReturn (__7Zip\FolderList)
EndProcedure








;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

If (Not Init7Zip())
  File.s = OpenFileRequester("7-Zip Commandline", GetHomeDirectory() + "7za.exe", "Executables (*.exe)|*.exe", 0)
  If (File)
    Init7Zip(File)
  Else
    End
  EndIf
EndIf

If (Init7Zip())
  Debug "Initialized..."
  Debug "Creating dummy files..."
  CreateDirectory(GetTemporaryDirectory() + "7Zip_Demo")
  SetCurrentDirectory(GetTemporaryDirectory() + "7Zip_Demo")
  DeleteFile("simple.7z")
  DeleteFile("password.7z")
  DeleteFile("encrypted.7z")
  If CreateFile(0, "text.txt")
    WriteString(0, "Hello World!!!")
    CloseFile(0)
  EndIf
  If CreateFile(0, "chars.bin")
    For i = 0 To 255
      WriteAsciiCharacter(0, i)
    Next i
    CloseFile(0)
  EndIf
  
  Debug "Creating simple archive..."
  Add7ZipFile("simple.7z", "text.txt")
  Add7ZipFile("simple.7z", "chars.bin")
  
  Debug "Creating archive with password..."
  Set7ZipPassword("pWord")
  Add7ZipFile("password.7z", "text.txt")
  Add7ZipFile("password.7z", "chars.bin")
  
  Debug "Creating archive with encrypted names..."
  Set7ZipFlags(#SevenZip_EncryptNames)
  Add7ZipFile("encrypted.7z", "text.txt")
  Add7ZipFile("encrypted.7z", "chars.bin")
  
  Debug "Examining encrypted archive..."
  Set7ZipPassword("pWord")
  If (Examine7ZipFiles("encrypted.7z"))
    CreateDirectory("Extracted")
    n = Get7ZipFileCount()
    FileList.s = Get7ZipFileList()
    For i = 1 To n
      File.s = StringField(FileList, i, #LF$)
      Debug "Extracting '" + File + "'..."
      Extract7ZipFile("encrypted.7z", File, "Extracted\" + File)
    Next i
  EndIf
  
  Reset7Zip()
  DeleteFile("text.txt")
  DeleteFile("chars.bin")
  Debug "Done"
  RunProgram(GetTemporaryDirectory() + "7Zip_Demo")
Else
  Debug "7-Zip could not be initialized"
EndIf

CompilerEndIf
CompilerEndIf
;-
