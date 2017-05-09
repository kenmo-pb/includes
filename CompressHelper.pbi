; +----------------+
; | CompressHelper |
; +----------------+
; | 2015.05.28 . Creation (PureBasic 5.31)
; |        .29 . Added minimum buffer size (for tiny compressions)

;-
CompilerIf (Not Defined(__CompressHelper_Included, #PB_Constant))
#__CompressHelper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

CompilerIf (#PB_Compiler_Version < 510)
  CompilerError #PB_Compiler_Filename + " requires PB 5.10 or newer"
CompilerEndIf




;- Constants (Private)

#_CompressHelper_HeaderID = $504C4843 ; 'CHLP'

#_CompressHelper_BufferMin = 128




;-
;- Constants (Public)

#Compress_BriefLZ = #PB_PackerPlugin_BriefLZ
#Compress_Zip     = #PB_PackerPlugin_Zip
#Compress_LZMA    = #PB_PackerPlugin_Lzma

#Compress_DefaultPlugin = #Compress_Zip












;-
;- Structures (Private)

Structure _COMPRESSHELPER_HEADER
  HelperID.l
  PluginID.l
  UncompressedBytes.q
  CompressedBytes.q
  Reserved.q
EndStructure
















;-
;- Procedures (Private)

CompilerIf (#PB_Compiler_Debugger)

  Procedure _CompressHelper_CheckPlugin(PluginID.i)
    Protected TempLong.l
    Protected TempString.s = Space(#_CompressHelper_BufferMin)
    If (CompressMemory(@TempLong, SizeOf(TempLong), @TempString, StringByteLength(TempString), PluginID))
      ; OK
    Else
      Select (PluginID)
        Case #Compress_BriefLZ
          Debug "You must call UseBriefLZPacker()."
        Case #Compress_LZMA
          Debug "You must call UseLZMAPacker()."
        Case #Compress_Zip
          Debug "You must call UseZipPacker()."
        Default
          Debug "Compression plugin not recognized or not supported."
      EndSelect
    EndIf
  EndProcedure
  
CompilerElse

  Macro _CompressHelper_CheckPlugin(PluginID)
    ;
  EndMacro
  
CompilerEndIf

Procedure.i _CompressHelper_Size(*Memory, CompressedSize.i = #False)
  Protected Result.i = 0
  
  If (*Memory)
    Protected *Header._COMPRESSHELPER_HEADER = *Memory
    *Header = *Memory
    If (*Header\HelperID = #_CompressHelper_HeaderID)
      If (CompressedSize)
        Result = *Header\CompressedBytes
      Else
        Result = *Header\UncompressedBytes
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure


;-
;- Procedures (Public)

;-

Procedure.i CopyMemoryToFile(*Memory, Bytes.i, File.s)
  Protected Result.i = #False
  
  If (*Memory)
    If (Bytes >= 0)
      If (File)
        Protected FID.i = CreateFile(#PB_Any, File)
        If (FID)
          If (Bytes > 0)
            If (WriteData(FID, *Memory, Bytes) = Bytes)
              Result = #True
            EndIf
          Else
            Result = #True
          EndIf
          CloseFile(FID)
        EndIf
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i CopyFileToMemory(File.s)
  Protected *Buffer = #Null
  
  If (File)
    Protected FID.i = ReadFile(#PB_Any, File)
    If (FID)
      Protected BufferBytes.i = Lof(FID)
      If (BufferBytes > 0)
        *Buffer = AllocateMemory(BufferBytes, #PB_Memory_NoClear)
        If (*Buffer)
          If (ReadData(FID, *Buffer, BufferBytes) = BufferBytes)
            ;
          Else
            FreeMemory(*Buffer)
            *Buffer = #Null
          EndIf
        EndIf
      EndIf
      CloseFile(FID)
    EndIf
  EndIf
  
  ProcedureReturn (*Buffer)
EndProcedure

;-

Procedure.i CompressMemoryToMemory(*Memory, Bytes.i, PluginID.i = #Compress_DefaultPlugin)
  Protected *Compressed = #Null
  
  _CompressHelper_CheckPlugin(PluginID)
  If (*Memory)
    If (Bytes > 0)
      Select (PluginID)
        Case #Compress_BriefLZ, #Compress_Zip, #Compress_LZMA
          Protected BufferBytes.i = Int(Bytes * 1.40)
          If (BufferBytes < #_CompressHelper_BufferMin)
            BufferBytes = #_CompressHelper_BufferMin
          EndIf
          Protected *Buffer = AllocateMemory(BufferBytes, #PB_Memory_NoClear)
          If (*Buffer)
            Protected UsedBytes.i = CompressMemory(*Memory, Bytes, *Buffer, BufferBytes, PluginID)
            If (UsedBytes > 0)
              Protected Offset.i = SizeOf(_COMPRESSHELPER_HEADER)
              *Compressed = AllocateMemory(Offset + UsedBytes, #PB_Memory_NoClear)
              If (*Compressed)
                Protected *Header._COMPRESSHELPER_HEADER = *Compressed
                *Header\HelperID          = #_CompressHelper_HeaderID
                *Header\PluginID          =  PluginID
                *Header\UncompressedBytes =  Bytes
                *Header\CompressedBytes   =  UsedBytes
                *Header\Reserved          = #Null
                CopyMemory(*Buffer, *Compressed + Offset, UsedBytes)
              EndIf
            EndIf
            FreeMemory(*Buffer)
          EndIf
        Default
          ;
      EndSelect
    EndIf
  EndIf
  
  ProcedureReturn (*Compressed)
EndProcedure

Procedure.i UncompressMemoryToMemory(*Memory, Bytes.i = #PB_Default)
  Protected *Uncompressed = #Null
  
  If (*Memory)
    Protected *Header._COMPRESSHELPER_HEADER = *Memory
    If (*Header\HelperID = #_CompressHelper_HeaderID)
      If (*Header\UncompressedBytes > 0)
        If (*Header\CompressedBytes > 0)
          Protected Offset.i = SizeOf(_COMPRESSHELPER_HEADER)
          If (Bytes <= 0)
            Bytes = MemorySize(*Memory)
          EndIf
          If (Bytes = Offset + *Header\CompressedBytes)
            Select (*Header\PluginID)
              Case #Compress_BriefLZ, #Compress_Zip, #Compress_LZMA
                _CompressHelper_CheckPlugin(*Header\PluginID)
                Protected *Buffer = AllocateMemory(*Header\UncompressedBytes, #PB_Memory_NoClear)
                If (*Buffer)
                  If (UncompressMemory(*Memory + Offset, *Header\CompressedBytes, *Buffer, *Header\UncompressedBytes, *Header\PluginID) > 0)
                    *Uncompressed = *Buffer
                  Else
                    FreeMemory(*Buffer)
                    *Buffer = #Null
                  EndIf
                EndIf
              Default
                ;
            EndSelect
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (*Uncompressed)
EndProcedure

;-

Procedure.i CompressMemoryToFile(*Memory, Bytes.i, File.s, PluginID.i = #Compress_DefaultPlugin)
  Protected Result.i = #False
  
  If (File)
    Protected *Compressed = CompressMemoryToMemory(*Memory, Bytes, PluginID)
    If (*Compressed)
      Result = CopyMemoryToFile(*Compressed, MemorySize(*Compressed), File)
      FreeMemory(*Compressed)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i UncompressFileToMemory(File.s)
  Protected *Uncompressed = #Null
  
  If (File)
    Protected *Buffer = CopyFileToMemory(File)
    If (*Buffer)
      *Uncompressed = UncompressMemoryToMemory(*Buffer)
      FreeMemory(*Buffer)
    EndIf
  EndIf
  
  ProcedureReturn (*Uncompressed)
EndProcedure

;-

Procedure.i CompressFileToFile(InputFile.s, OutputFile.s, PluginID.i = #Compress_DefaultPlugin)
  Protected Result.i = #False
  
  If (InputFile)
    If (OutputFile)
      Protected *Uncompressed = CopyFileToMemory(InputFile)
      If (*Uncompressed)
        Result = CompressMemoryToFile(*Uncompressed, MemorySize(*Uncompressed), OutputFile, PluginID)
        FreeMemory(*Uncompressed)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i UncompressFileToFile(InputFile.s, OutputFile.s)
  Protected Result.i = #False
  
  If (InputFile)
    If (OutputFile)
      Protected *Uncompressed = UncompressFileToMemory(InputFile)
      If (*Uncompressed)
        Result = CopyMemoryToFile(*Uncompressed, MemorySize(*Uncompressed), OutputFile)
        FreeMemory(*Uncompressed)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

;-

Procedure.i CompressFileToMemory(File.s, PluginID.i = #Compress_DefaultPlugin)
  Protected *Compressed = #Null
  
  Protected *Buffer = CopyFileToMemory(File)
  If (*Buffer)
    *Compressed = CompressMemoryToMemory(*Buffer, MemorySize(*Buffer), PluginID)
    FreeMemory(*Buffer)
  EndIf
  
  ProcedureReturn (*Compressed)
EndProcedure

Procedure.i UncompressMemoryToFile(*Memory, File.s, Bytes.i = #PB_Default)
  Protected Result.i = #False
  
  If (*Memory)
    If (File)
      Protected *Uncompressed = UncompressMemoryToMemory(*Memory, Bytes)
      If (*Uncompressed)
        If (CopyMemoryToFile(*Uncompressed, MemorySize(*Uncompressed), File))
          Result = #True
        EndIf
        FreeMemory(*Uncompressed)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure





















;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  RandomSeed(1)
  TestString.s = ""
  For i = 1 To 20
    TestString + RSet("", Random(30, 5), Chr(Random('z', 'a')))
  Next i
  TestBytes.i = StringByteLength(TestString) + SizeOf(CHARACTER)
  ;Debug "Input String = " + TestString
  Debug "Input Bytes = " + Str(TestBytes)
  Debug ""
  
  UseZipPacker()
  UseBriefLZPacker()
  UseLZMAPacker()
  TestPlugin.i = #Compress_Zip
  
  *Compressed = CompressMemoryToMemory(@TestString, TestBytes, TestPlugin)
  If (*Compressed)
    NewBytes.i = MemorySize(*Compressed)
    Debug "Compressed Bytes = " + Str(NewBytes) + " (" + StrF(100.0 * NewBytes / TestBytes, 1) + "%)"
    *Uncompressed = UncompressMemoryToMemory(*Compressed)
    If (*Uncompressed)
      Debug "Uncompressed Bytes = " + Str(MemorySize(*Uncompressed))
      If (PeekS(*Uncompressed) <> TestString)
        Debug "Uncompressed string does not match test string!"
      EndIf
      FreeMemory(*Uncompressed)
    Else
      Debug "Failed to uncompress memory!"
    EndIf
    FreeMemory(*Compressed)
  Else
    Debug "Failed to compress memory!"
  EndIf
  Debug ""
  
  TempFile.s = GetTemporaryDirectory() + "temp.pack"
  If (CompressMemoryToFile(@TestString, TestBytes, TempFile, TestPlugin))
    NewBytes.i = FileSize(TempFile)
    Debug "Compressed File Bytes = " + Str(NewBytes) + " (" + StrF(100.0 * NewBytes / TestBytes, 1) + "%)"
    *Uncompressed = UncompressFileToMemory(TempFile)
    If (*Uncompressed)
      Debug "Uncompressed File Bytes = " + Str(MemorySize(*Uncompressed))
      If (PeekS(*Uncompressed) <> TestString)
        Debug "Uncompressed string does not match test string!"
      EndIf
      FreeMemory(*Uncompressed)
    Else
      Debug "Failed to uncompress memory!"
    EndIf
    DeleteFile(TempFile)
  Else
    Debug "Failed to compress to file!"
  EndIf
  Debug ""
  
CompilerEndIf
CompilerEndIf
;-