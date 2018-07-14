; +---------------+
; | FTPHelper.pbi |
; +---------------+
; | 2015.06.05 . Creation (PureBasic 5.31)
; | 2017.05.22 . Cleanup
; | 2018.06.15 . Added QuickFTPUpload()
; | 2018.07.07 . Moved RemoteFile formatting from QuickUpload into Upload

;-
CompilerIf (Not Defined(__FTPHelper_Included, #PB_Constant))
#__FTPHelper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;- Procedures (Public)

Procedure.i ChangeFTPDirectory(FTP.i, Directory.s, Create.i = #False)
  Protected Result.i = #False
  If (IsFTP(FTP))
    If (CheckFTPConnection(FTP))
      If (Directory)
        ReplaceString(Directory, "\", "/", #PB_String_InPlace)
        Directory = RTrim(Directory, "/") + "/"
        Protected Current.s
        Current = RTrim(GetFTPDirectory(FTP), "/") + "/"
        If (Left(Directory, 1) <> "/")
          Directory = Current + Directory
        EndIf
        If (Current <> Directory)
          Result = #True
          While (Current <> Left(Directory, Len(Current)))
            If (Not SetFTPDirectory(FTP, ".."))
              Result = #False
              Break
            EndIf
            Current = RTrim(GetFTPDirectory(FTP), "/") + "/"
          Wend
          If (Result)
            While (Len(Current) < Len(Directory))
              Protected Sub.s
              Sub = StringField(Mid(Directory, Len(Current) + 1), 1, "/")
              If (Create)
                CreateFTPDirectory(FTP, Sub)
              EndIf
              If (Not SetFTPDirectory(FTP, Sub))
                Result = #False
                Break
              EndIf
              Current = RTrim(GetFTPDirectory(FTP), "/") + "/"
            Wend
          EndIf
        Else
          Result = #True
        EndIf
      Else
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i UploadFTPFile(FTP.i, LocalFile.s, RemoteFile.s)
  Protected Result.i = #False
  If (IsFTP(FTP))
    If (LocalFile)
      If (RemoteFile = "")
        RemoteFile = "/" + GetFilePart(LocalFile)
      ElseIf (Right(RemoteFile, 1) = "/")
        RemoteFile + GetFilePart(LocalFile)
      EndIf
      If (ChangeFTPDirectory(FTP, GetPathPart(RemoteFile), #True))
        Result = Bool(SendFTPFile(FTP, LocalFile, GetFilePart(RemoteFile)))
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DownloadFTPFile(FTP.i, RemoteFile.s, LocalFile.s)
  Protected Result.i = #False
  If (IsFTP(FTP))
    If (LocalFile)
      If (RemoteFile)
        If (ChangeFTPDirectory(FTP, GetPathPart(RemoteFile), #False))
          Result = Bool(ReceiveFTPFile(FTP, GetFilePart(RemoteFile), LocalFile))
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i QuickFTPUpload(File.s, Server.s, RemoteFile.s = "", User.s = "", Pass.s = "", Port.i = 21, Passive.i = #True)
  Protected Result.i = #False
  If (File And (FileSize(File) >= 0) And Server)
    If (InitNetwork())
      Protected FTP.i = OpenFTP(#PB_Any, Server, User, Pass, Passive, Port)
      If (FTP)
        Result = UploadFTPFile(FTP, File, RemoteFile)
        CloseFTP(FTP)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure





;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  ; ==========================================
  ; Fill these in to test!
  Server.s   = ""
  User.s     = "myUser"
  Password.s = "myPassword"
  RemoteFile.s  = "/www/files/myFile.dat"
  ; ==========================================
  
  Passive.i  = #True
  Port.i     =  21
  
  LocalFile.s   = GetTemporaryDirectory() + GetFilePart(RemoteFile)
  RemoteFile2.s = RemoteFile + ".new"
  
  If (Server)
    If InitNetwork()
      Debug "Connecting to " + Server + "..."
      If OpenFTP(0, Server, User, Password, Passive, Port)
        
        Debug "OK" + #LF$ + "Downloading file..."
        If (DownloadFTPFile(0, RemoteFile, LocalFile))
          Debug "OK" + #LF$ + "Uploading file..."
          If (UploadFTPFile(0, LocalFile, RemoteFile2))
            Debug "OK" + #LF$ + "Resetting to root directory..."
            If (ChangeFTPDirectory(0, "/"))
              Debug "OK" + #LF$ + "Done"
            Else
              Debug "Failed!"
            EndIf
          Else
            Debug "Failed!"
          EndIf
        Else
          Debug "Failed!"
        EndIf
        
        CloseFTP(0)
      Else
        Debug "Could not open FTP connection!"
      EndIf
    EndIf
  Else
    Debug "Please specify a server and username in code"
  EndIf
  
CompilerEndIf
CompilerEndIf
;-
