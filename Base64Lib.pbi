; +-----------+
; | Base64Lib |
; +-----------+
; | 2017.01.18 . Creation (added decoder, file functions)
; |        .20 . Fixed a Decode bug (allocate OutputBytes = 0), added demo
; |     .03.30 . Multiple-include safe, cleaned up demo

CompilerIf (Not Defined(__Base64Lib_Included, #PB_Constant))
#__Base64Lib_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;-
;- Constants

#Base64_NoPadding = #PB_Cipher_NoPadding
#Base64_URL       = #PB_Cipher_URL









;-
;- Character Mapping

Procedure.i CharacterToBase64Value(Character.i)
  Select (Character)
    Case 'A' To 'Z'
      ProcedureReturn ((Character - 'A') + 0)
    Case 'a' To 'z'
      ProcedureReturn ((Character - 'a') + 26)
    Case '0' To '9'
      ProcedureReturn ((Character - '0') + 52)
    Case '-', '+'
      ProcedureReturn (62)
    Case '_', '/'
      ProcedureReturn (63)
  EndSelect
  ProcedureReturn (-1)
EndProcedure

Procedure.i Base64ValueToCharacter(Value.i, Flags.i = #Null)
  Select (Value)
    Case 0 To 25
      ProcedureReturn ((Value - 0) + 'A')
    Case 26 To 51
      ProcedureReturn ((Value - 26) + 'a')
    Case 52 To 61
      ProcedureReturn ((Value - 52) + '0')
    Case 62
      If (Flags & #Base64_URL)
        ProcedureReturn ('-')
      EndIf
      ProcedureReturn ('+')
    Case 63
      If (Flags & #Base64_URL)
        ProcedureReturn ('_')
      EndIf
      ProcedureReturn ('/')
  EndSelect
  ProcedureReturn (#NUL)
EndProcedure








;-
;- Buffer Size Calculations

Procedure.i Base64EncodeBytesNeeded(InputBytes.i, Flags.i = #Null)
  Protected Result.i
  If (InputBytes > 0)
    Result = (Int((InputBytes + 2)/3) * 4)
    If (Flags & #Base64_NoPadding)
      Select (InputBytes % 3)
        Case 1
          Result - 2
        Case 2
          Result - 1
      EndSelect
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64DecodeBytesNeeded(InputBytes.i)
  Protected Result.i
  If (InputBytes > 0)
    Result = Int(InputBytes / 4) * 3
    Select (InputBytes % 4)
      Case 1
        Result = 0
      Case 2
        Result + 1
      Case 3
        Result + 2
    EndSelect
  EndIf
  ProcedureReturn (Result)
EndProcedure








;-
;- Encode Functions

Procedure.i MemoryToBase64Memory(*Input, InputBytes.i, Flags.i = #Null)
  Protected *Output
  If (*Input And (InputBytes > 0))
    Protected OutputBytes.i = Base64EncodeBytesNeeded(InputBytes, Flags)
    *Output = AllocateMemory(OutputBytes, #PB_Memory_NoClear)
    If (*Output)
      Protected BytesLeft.i  =  InputBytes
      Protected *Read.ASCII  = *Input
      Protected *Write.ASCII = *Output
      Protected Bits.i = 0
      While (BytesLeft > 0)
        If (BytesLeft >= 3)
          *Write\a = Base64ValueToCharacter(*Read\a >> 2, Flags) : *Write + 1
          Bits = (*Read\a & $03) << 4 : *Read + 1
          *Write\a = Base64ValueToCharacter(Bits | (*Read\a >> 4), Flags) : *Write + 1
          Bits = (*Read\a & $0F) << 2 : *Read + 1
          *Write\a = Base64ValueToCharacter(Bits | (*Read\a >> 6), Flags) : *Write + 1
          Bits = (*Read\a & $3F) : *Read + 1
          *Write\a = Base64ValueToCharacter(Bits, Flags) : *Write + 1
          BytesLeft - 3
        ElseIf (BytesLeft = 2)
          *Write\a = Base64ValueToCharacter(*Read\a >> 2, Flags) : *Write + 1
          Bits = (*Read\a & $03) << 4 : *Read + 1
          *Write\a = Base64ValueToCharacter(Bits | *Read\a >> 4, Flags) : *Write + 1
          Bits = (*Read\a & $0F) << 2 : *Read + 1
          *Write\a = Base64ValueToCharacter(Bits, Flags) : *Write + 1
          BytesLeft - 2
          If ((BytesLeft = 0) And (Not (Flags & #Base64_NoPadding)))
            *Write\a = '=' : *Write + 1
          EndIf
        ElseIf (BytesLeft = 1)
          *Write\a = Base64ValueToCharacter(*Read\a >> 2, Flags) : *Write + 1
          *Write\a = Base64ValueToCharacter((*Read\a & $03) << 4, Flags) : *Write + 1
          BytesLeft - 1
          If ((BytesLeft = 0) And (Not (Flags & #Base64_NoPadding)))
            *Write\a = '=' : *Write + 1
            *Write\a = '=' : *Write + 1
          EndIf
        EndIf
      Wend
    EndIf
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.i StringToBase64Memory(Input.s, Flags.i = #Null)
  Protected *Output
  Protected *Buffer = UTF8(Input)
  If (*Buffer)
    *Output = MemoryToBase64Memory(*Buffer, MemorySize(*Buffer) - 1, Flags)
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.i FileToBase64Memory(File.s, Flags.i = #Null)
  Protected *Output
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected BufferSize.i = Lof(FN)
    If (BufferSize > 0)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        If (ReadData(FN, *Buffer, BufferSize) = BufferSize)
          *Output = MemoryToBase64Memory(*Buffer, BufferSize, Flags)
        EndIf
        FreeMemory(*Buffer)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.s MemoryToBase64String(*Input, InputBytes.i, Flags.i = #Null)
  Protected Result.s
  Protected *Output = MemoryToBase64Memory(*Input, InputBytes, Flags)
  If (*Output)
    Result = PeekS(*Output, MemorySize(*Output), #PB_Ascii)
    FreeMemory(*Output)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s StringToBase64String(Input.s, Flags.i = #Null)
  Protected Result.s
  If (Input)
    Protected *Input = UTF8(Input)
    If (*Input)
      Result = MemoryToBase64String(*Input, MemorySize(*Input) - 1, Flags)
      FreeMemory(*Input)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s FileToBase64String(File.s, Flags.i = #Null)
  Protected Result.s
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected BufferSize.i = Lof(FN)
    If (BufferSize > 0)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        If (ReadData(FN, *Buffer, BufferSize) = BufferSize)
          Result = MemoryToBase64String(*Buffer, BufferSize, Flags)
        EndIf
        FreeMemory(*Buffer)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MemoryToBase64File(*Input, InputBytes.i, OutputFile.s, Flags.i = #Null)
  Protected Result.i
  Protected *Output = MemoryToBase64Memory(*Input, InputBytes, Flags)
  If (*Output)
    Protected OFN.i = CreateFile(#PB_Any, OutputFile)
    If (OFN)
      If (WriteData(OFN, *Output, MemorySize(*Output)) = MemorySize(*Output))
        Result = #True
      EndIf
      CloseFile(OFN)
      If (Not Result)
        DeleteFile(OutputFile)
      EndIf
    EndIf
    FreeMemory(*Output)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i StringToBase64File(Input.s, OutputFile.s, Flags.i = #Null)
  Protected Result.i
  Protected *Output = StringToBase64Memory(Input, Flags)
  If (*Output)
    Protected OFN.i = CreateFile(#PB_Any, OutputFile)
    If (OFN)
      If (WriteData(OFN, *Output, MemorySize(*Output)) = MemorySize(*Output))
        Result = #True
      EndIf
      CloseFile(OFN)
      If (Not Result)
        DeleteFile(OutputFile)
      EndIf
    EndIf
    FreeMemory(*Output)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i FileToBase64File(InputFile.s, OutputFile.s, Flags.i = #Null)
  Protected Result.i
  Protected FN.i = ReadFile(#PB_Any, InputFile)
  If (FN)
    Protected OFN.i = CreateFile(#PB_Any, OutputFile)
    If (OFN)
      Protected BufferSize.i = 3 * (1024 * 1024)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        Protected n.i
        Result = #True
        While (Result And (Not Eof(FN)))
          Protected *Chunk
          n = ReadData(FN, *Buffer, BufferSize)
          If (n > 0)
            *Chunk = MemoryToBase64Memory(*Buffer, n, Flags)
            If (*Chunk)
              If (WriteData(OFN, *Chunk, MemorySize(*Chunk)) = MemorySize(*Chunk))
                ;
              Else
                Result = #False
              EndIf
              FreeMemory(*Chunk)
            Else
              Result = #False
            EndIf
          Else
            Result = #False
          EndIf
        Wend
        FreeMemory(*Buffer)
      EndIf
      CloseFile(OFN)
      If (Not Result)
        DeleteFile(OutputFile)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure







;-
;- Decode Functions

Procedure.i Base64MemoryToMemory(*Input, InputBytes.i)
  Protected *Output
  If (*Input And (InputBytes > 0))
    Protected ValidChars.i = 0
    Protected *Read.ASCII = *Input
    Protected BytesLeft.i = InputBytes
    While (BytesLeft > 0)
      If ((*Read\a = '=') Or (*Read\a = #NUL))
        Break
      EndIf
      If (CharacterToBase64Value(*Read\a) >= 0)
        ValidChars + 1
      EndIf
      BytesLeft - 1
      *Read + 1
    Wend
    If (ValidChars > 0)
      Protected OutputBytes.i = Base64DecodeBytesNeeded(ValidChars)
      If (OutputBytes > 0)
        *Output = AllocateMemory(OutputBytes, #PB_Memory_NoClear)
        If (*Output)
          Protected Value.i
          Protected Slot.i = 0
          Protected IntBuffer.i = 0
          Protected *Write.ASCII = *Output
          *Read = *Input
          BytesLeft = ValidChars
          While (BytesLeft > 0)
            Value = CharacterToBase64Value(*Read\a)
            If (Value >= 0)
              Select (Slot)
                Case 0
                  IntBuffer = Value << 18
                Case 1
                  IntBuffer | (Value << 12)
                Case 2
                  IntBuffer | (Value << 6)
                Case 3
                  IntBuffer | (Value << 0)
              EndSelect
              BytesLeft - 1
              If (Slot = 3)
                *Write\a = (IntBuffer >> 16) & $FF : *Write + 1
                *Write\a = (IntBuffer >>  8) & $FF : *Write + 1
                *Write\a = (IntBuffer >>  0) & $FF : *Write + 1
              ElseIf ((Slot = 2) And (BytesLeft = 0))
                *Write\a = (IntBuffer >> 16) & $FF : *Write + 1
                *Write\a = (IntBuffer >>  8) & $FF : *Write + 1
              ElseIf ((Slot = 1) And (BytesLeft = 0))
                *Write\a = (IntBuffer >> 16) & $FF : *Write + 1
              EndIf
              Slot = (Slot + 1) % 4
            EndIf
            *Read + 1
          Wend
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.s Base64MemoryToString(*Input, InputBytes.i)
  Protected Result.s
  Protected *Output = Base64MemoryToMemory(*Input, InputBytes)
  If (*Output)
    Result = PeekS(*Output, MemorySize(*Output), #PB_UTF8 | #PB_ByteLength)
    FreeMemory(*Output)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64MemoryToFile(*Input, InputBytes.i, OutputFile.s)
  Protected Result.i
  Protected *Output = Base64MemoryToMemory(*Input, InputBytes)
  If (*Output)
    Protected OFN.i = CreateFile(#PB_Any, OutputFile)
    If (OFN)
      If (WriteData(OFN, *Output, MemorySize(*Output)) = MemorySize(*Output))
        Result = #True
      EndIf
      CloseFile(OFN)
      If (Not Result)
        DeleteFile(OutputFile)
      EndIf
    EndIf
    FreeMemory(*Output)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64StringToMemory(Input.s)
  Protected *Output
  Protected *Buffer = Ascii(Input)
  If (*Buffer)
    *Output = Base64MemoryToMemory(*Buffer, MemorySize(*Buffer) - 1)
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.s Base64StringToString(Input.s)
  Protected Result.s
  Protected *Buffer = Ascii(Input)
  If (*Buffer)
    Result = Base64MemoryToString(*Buffer, MemorySize(*Buffer) - 1)
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64StringToFile(Input.s, OutputFile.s)
  Protected Result.i
  Protected *Buffer = Ascii(Input)
  If (*Buffer)
    Result = Base64MemoryToFile(*Buffer, MemorySize(*Buffer) - 1, OutputFile)
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64FileToMemory(File.s)
  Protected *Output
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected BufferSize.i = Lof(FN)
    If (BufferSize > 0)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        If (ReadData(FN, *Buffer, BufferSize) = BufferSize)
          *Output = Base64MemoryToMemory(*Buffer, BufferSize)
        EndIf
        FreeMemory(*Buffer)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (*Output)
EndProcedure

Procedure.s Base64FileToString(File.s)
  Protected Result.s
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Protected BufferSize.i = Lof(FN)
    If (BufferSize > 0)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        If (ReadData(FN, *Buffer, BufferSize) = BufferSize)
          Result = Base64MemoryToString(*Buffer, BufferSize)
        EndIf
        FreeMemory(*Buffer)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Base64FileToFile(InputFile.s, OutputFile.s)
  Protected Result.i = 0
  Protected FN.i = ReadFile(#PB_Any, InputFile)
  If (FN)
    Protected OFN.i = CreateFile(#PB_Any, OutputFile)
    If (OFN)
      Protected BufferSize.i = 4 * (1024 * 1024)
      Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
      If (*Buffer)
        Protected n.i
        Result = #True
        While (Result And (Not Eof(FN)))
          Protected *Chunk
          n = ReadData(FN, *Buffer, BufferSize)
          If (n > 0)
            *Chunk = Base64MemoryToMemory(*Buffer, n)
            If (*Chunk)
              If (WriteData(OFN, *Chunk, MemorySize(*Chunk)) = MemorySize(*Chunk))
                ;
              Else
                Result = #False
              EndIf
              FreeMemory(*Chunk)
            Else
              Result = #False
            EndIf
          Else
            Result = #False
          EndIf
        Wend
        FreeMemory(*Buffer)
      EndIf
      CloseFile(OFN)
      If (Not Result)
        DeleteFile(OutputFile)
      EndIf
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure










;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Flags = #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget
OpenWindow(0, 0, 0, 360, 100, "Base64Lib Demo", Flags)
StringGadget(0, 10, 10, WindowWidth(0)-20, 20, "")
StringGadget(1, 10, 40, WindowWidth(0)-20, 20, "")
StringGadget(2, 10, 70, WindowWidth(0)-20, 20, "", #PB_String_ReadOnly)

Procedure DemoUpdate(ChangedGadget.i)
  If (ChangedGadget = 0) ; normal text was entered
    Input.s = GetGadgetText(0)
    SetGadgetText(1, StringToBase64String(Input)) ; directly encode to Base64 string
    
    File.s = GetTemporaryDirectory() + "base64_temp.dat"
    If (StringToBase64File(Input, File)) ; save to a Base64-encoded file
      If (Base64FileToFile(File, File + ".txt")) ; decode a Base64-encoded file to a text file
        If (ReadFile(0, File + ".txt")) ; read text file back to gadget
          SetGadgetText(2, ReadString(0, #PB_File_IgnoreEOL))
          CloseFile(0)
        EndIf
      EndIf
    EndIf
    
  ElseIf (ChangedGadget = 1) ; encoded Base64 was entered
    Input.s = GetGadgetText(1)
    SetGadgetText(0, Base64StringToString(Input)) ; directly decode Base64 to text
    SetGadgetText(2, "")
  EndIf
EndProcedure

SetActiveGadget(0)
Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_CloseWindow)
    Done = #True
  ElseIf ((Event = #PB_Event_Gadget) And (EventType() = #PB_EventType_Change))
    If (EventGadget() = GetActiveGadget())
      DemoUpdate(GetActiveGadget())
    EndIf
  EndIf
Until Done

CompilerEndIf
CompilerEndIf
;-