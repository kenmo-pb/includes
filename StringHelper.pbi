; +------------------+
; | StringHelper.pbi |
; +------------------+
; | 2015.02.17 . Creation (PureBasic 5.31)
; |     .05.07 . Improvements, renames, more helper macros
; | 2016.03.24 . Cleanup, fixed UTF-8 file example
; |     .09.08 . Added ChrU(), AscU() which support Unicode > 0xFFFF
; |     .10.25 . Added constants and procedures for surrogate pairs, multibyte
; |     .11.16 . Added CharByteLength() and UTF8CharBytes()
; |     .11.17 . Added #ReplacementChar$
; | 2017.01.05 . StringBuffer no longer crashes on empty string + 0 nulls
; |     .04.20 . Multiple-include safe, emoji codepoints example,
; |                added UTF32 To StringBuffer() And PeekCharacter()

CompilerIf (Not Defined(__StringHelper_Included, #PB_Constant))
#__StringHelper_Included = #True

;-
;- Compile Switches

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;-
;- Constants

CompilerIf (#PB_Compiler_Unicode)
  ;
  #AsciiMode   = #False
  #UnicodeMode = #True
  #CharSize    =  2
  ;
  #StringMode   = #PB_Unicode
  #StringMode$  = "Unicode"
  #StringIOMode = #PB_UTF8
  ;
CompilerElse
  ;
  #AsciiMode   = #True
  #UnicodeMode = #False
  #CharSize    =  1
  ;
  #StringMode   = #PB_Ascii
  #StringMode$  = "ASCII"
  #StringIOMode = #PB_Ascii
  ;
CompilerEndIf

#SurrogateHighMin = $D800
#SurrogateHighMax = $DBFF
#SurrogateLowMin  = $DC00
#SurrogateLowMax  = $DFFF
;
#SurrogateOffset  = $010000
;
#ReplacementChar  = $FFFD
#ReplacementChar$ =  Chr(#ReplacementChar)





;-
;- Macros - Peek Strings

Macro PeekS_Ascii(Memory, Length = -1)
  PeekS((Memory), (Length), #PB_Ascii)
EndMacro

Macro PeekS_Unicode(Memory, Length = -1)
  PeekS((Memory), (Length), #PB_Unicode)
EndMacro

Macro PeekS_UTF8(Memory, Length = -1)
  PeekS((Memory), (Length), #PB_UTF8)
EndMacro

Macro PeekSFree_Ascii(Memory, Length = -1)
  PeekSFree((Memory), #PB_Ascii, (Length))
EndMacro

Macro PeekSFree_Unicode(Memory, Length = -1)
  PeekSFree((Memory), #PB_Unicode, (Length))
EndMacro

Macro PeekSFree_UTF8(Memory, Length = -1)
  PeekSFree((Memory), #PB_UTF8, (Length))
EndMacro


;-
;- Macros - Poke Strings

Macro PokeS_Ascii(Memory, Text, Length = -1, Flags = #Null)
  PokeS((Memory), (Text), (Length), (Flags) | #PB_Ascii)
EndMacro

Macro PokeS_Unicode(Memory, Text, Length = -1, Flags = #Null)
  PokeS((Memory), (Text), (Length), (Flags) | #PB_Unicode)
EndMacro

Macro PokeS_UTF8(Memory, Text, Length = -1, Flags = #Null)
  PokeS((Memory), (Text), (Length), (Flags) | #PB_UTF8)
EndMacro


;-
;- Macros - String Buffers

Macro StringBuffer_Ascii(Text, NumNulls = 1)
  StringBuffer((Text), #PB_Ascii, (NumNulls))
EndMacro

Macro StringBuffer_Unicode(Text, NumNulls = 1)
  StringBuffer((Text), #PB_Unicode, (NumNulls))
EndMacro

Macro StringBuffer_UTF8(Text, NumNulls = 1)
  StringBuffer((Text), #PB_UTF8, (NumNulls))
EndMacro

Macro StringBuffer_UTF32(Text, NumNulls = 1)
  StringBuffer((Text), #PB_UTF32, (NumNulls))
EndMacro


;-
;- Macros - Other

Macro CharSize()
  (#CharSize)
EndMacro

Macro StringByteLengthN(String, Format = #StringMode)
  (StringByteLength((String), (Format)) + NullCharSize(Format))
EndMacro

Macro CharByteLength(CodePoint, Format = #StringMode)
  (StringByteLength(ChrU(CodePoint), (Format)))
EndMacro

Macro UTF8CharBytes(CodePoint)
  (StringByteLength(ChrU(CodePoint), #PB_UTF8))
EndMacro



;-
;- Procedures - Unicode Characters

Procedure.i IsHighSurrogate(Code.i)
  ProcedureReturn (Bool((Code >= #SurrogateHighMin) And (Code <= #SurrogateHighMax)))
EndProcedure

Procedure.i IsLowSurrogate(Code.i)
  ProcedureReturn (Bool((Code >= #SurrogateLowMin) And (Code <= #SurrogateLowMax)))
EndProcedure

Procedure.i IsLeadUTF8(Code.i)
  ProcedureReturn (Bool(((Code & $E0) = $C0) Or ((Code & $F0) = $E0) Or ((Code & $F8) = $F0)))
EndProcedure

Procedure.i IsContUTF8(Code.i)
  ProcedureReturn (Bool((Code & $C0) = $80))
EndProcedure

Procedure.i ExpectedContBytes(Leading.i)
  Protected Result.i = 0
  If (Leading & $E0 = $C0)
    Result = 1
  ElseIf (Leading & $F0 = $E0)
    Result = 2
  ElseIf (Leading & $F8 = $F0)
    Result = 3
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s ChrU(CodePoint.i)
  CompilerIf (#PB_Compiler_Unicode)
    If (CodePoint <= $FFFF)
      ProcedureReturn (Chr(CodePoint))
    Else
      CodePoint - #SurrogateOffset
      ProcedureReturn (Chr(#SurrogateHighMin + (CodePoint >> 10)) + Chr(#SurrogateLowMin + (CodePoint & $03FF)))
    EndIf
  CompilerElse
    If (CodePoint <= $FF)
      ProcedureReturn (Chr(CodePoint))
    Else
      ProcedureReturn ("?")
    EndIf
  CompilerEndIf
EndProcedure

Procedure.i AscU(String.s)
  CompilerIf (#PB_Compiler_Unicode)
    Protected First.i = Asc(String)
    If (IsHighSurrogate(First))
      Protected Second.i = PeekC(@String + SizeOf(CHARACTER))
      If (IsLowSurrogate(Second))
        First = (First & $03FF) << 10
        First | (Second & $03FF)
        First + #SurrogateOffset
      EndIf
    EndIf
    ProcedureReturn (First)
  CompilerElse
    ProcedureReturn (Asc(String))
  CompilerEndIf
EndProcedure

Procedure.i PeekCharacter(*Memory, Format.i = #StringMode, *NextChar.INTEGER = #Null)
  Protected Result.i = -1
  Protected StepSize.i
  Protected *Next = #Null
  Protected A.i, B.i, C.i, D.i
  Select (Format)
  
    Case (#PB_Ascii)
      Result = PeekA(*Memory)
      StepSize = 1
      
    Case (#PB_Unicode)
      A = PeekU(*Memory)
      If (IsHighSurrogate(A))
        B = PeekU(*Memory + 2)
        If (IsLowSurrogate(B))
          Result = $10000 + ((A - #SurrogateHighMin) << 10) + (B - #SurrogateLowMin)
          StepSize = 4
        Else
          Result = #ReplacementChar
          StepSize = 2
        EndIf
      ElseIf (IsLowSurrogate(A))
        Result = #ReplacementChar
        StepSize = 2
      Else
        Result = A
        StepSize = 2
      EndIf
    
    Case (#PB_UTF32)
      Result = PeekL(*Memory)
      StepSize = 4
      
    Case (#PB_UTF8)
      A = PeekA(*Memory)
      If (IsLeadUTF8(A))
        Select (ExpectedContBytes(A))
          Case 1
            B = PeekA(*Memory + 1)
            If (IsContUTF8(B))
              Result = ((A & $1F) << 6) | (B & $3F)
              StepSize = 2
            Else
              Result = #ReplacementChar
              StepSize = 1
            EndIf
          Case 2
            B = PeekA(*Memory + 1)
            If (IsContUTF8(B))
              C = PeekA(*Memory + 2)
              If (IsContUTF8(C))
                Result = ((A & $0F) << 12) | ((B & $3F) << 6) | (C & $3F)
                StepSize = 3
              Else
                Result = #ReplacementChar
                StepSize = 2
              EndIf
            Else
              Result = #ReplacementChar
              StepSize = 1
            EndIf
          Case 3
            B = PeekA(*Memory + 1)
            If (IsContUTF8(B))
              C = PeekA(*Memory + 2)
              If (IsContUTF8(C))
                D = PeekA(*Memory + 3)
                If (IsContUTF8(D))
                  Result = ((A & $07) << 18) | ((B & $3F) << 12) | ((C & $3F) << 6) | (D & $3F)
                  StepSize = 4
                Else
                  Result = #ReplacementChar
                  StepSize = 3
                EndIf
              Else
                Result = #ReplacementChar
                StepSize = 2
              EndIf
            Else
              Result = #ReplacementChar
              StepSize = 1
            EndIf
        EndSelect
      ElseIf (IsContUTF8(A))
        Result = #ReplacementChar
        StepSize = 1
      Else
        Result = A
        StepSize = 1
      EndIf
      
  EndSelect
  If (Result >= 0)
    If (*NextChar)
      *NextChar\i = *Memory + StepSize
    EndIf
  Else
    If (*NextChar)
      *NextChar\i = #NUL
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure






;-
;- Procedures - String Buffers

Procedure.i NullCharSize(Format.i = #PB_Default)
  If (Format = #PB_Default)
    Format = #StringMode
  EndIf
  Select (Format)
    Case #PB_Ascii, #PB_UTF8
      ProcedureReturn 1
    Case #PB_Unicode
      ProcedureReturn 2
    Case #PB_UTF16BE
      ProcedureReturn 2
    Case #PB_UTF32, #PB_UTF32BE
      ProcedureReturn 4
    Case #PB_Default
      ProcedureReturn 0
  EndSelect
EndProcedure

Procedure.s StringFormatName(Format.i = #PB_Default)
  If (Format = #PB_Default)
    Format = #StringMode
  EndIf
  Select (Format)
    Case #PB_Ascii
      ProcedureReturn "ASCII"
    Case #PB_Unicode
      ProcedureReturn "Unicode"
    Case #PB_UTF8
      ProcedureReturn "UTF-8"
    Case #PB_UTF16BE
      ProcedureReturn "UTF-16 BE"
    Case #PB_UTF32
      ProcedureReturn "UTF-32"
    Case #PB_UTF32BE
      ProcedureReturn "UTF-32 BE"
    Default
      ProcedureReturn ""
  EndSelect
EndProcedure

Procedure.i StringBuffer(Text.s, Format.i = #PB_Default, NumNulls.i = 1)
  Protected *Memory = #Null
  
  If ((Text = "") And (NumNulls < 1))
    ProcedureReturn (#Null)
  EndIf
  
  Select (Format)
    Case #PB_Ascii, #PB_Unicode, #PB_UTF8, #PB_UTF32
      ; OK
    Case #PB_Default
      Format = #StringMode
    Default
      Format = #Null
  EndSelect
  ;
  If (Format)
    If (NumNulls < 0)
      NumNulls = 1
    EndIf
    Protected Bytes.i
    If (Format = #PB_UTF32)
      CompilerIf (#UnicodeMode)
        Protected NumChars.i = 0
        Protected *In = @Text
        While (PeekCharacter(*In, #PB_Unicode, @*In))
          NumChars + 1
        Wend
        If (NumNulls >= 1)
          Bytes   = 4 * (NumChars + NumNulls)
          *Memory = AllocateMemory(Bytes)
        Else
          Bytes   = 4 * (NumChars)
          *Memory = AllocateMemory(Bytes, #PB_Memory_NoClear)
        EndIf
        If (*Memory)
          *In = @Text
          Protected *Out.LONG = *Memory
          While (NumChars)
            *Out\l = PeekCharacter(*In, #PB_Unicode, @*In)
            *Out + SizeOf(LONG)
            NumChars - 1
          Wend
        EndIf
        
      CompilerElse
        If (NumNulls >= 1)
          Bytes = 4 * (Len(Text) + NumNulls)
          *Memory = AllocateMemory(Bytes)
        Else
          Bytes = 4 * Len(Text)
          *Memory = AllocateMemory(Bytes, #PB_Memory_NoClear)
        EndIf
        If (*Memory)
          Protected *In.CHARACTER = @Text
          Protected *Out.LONG = *Memory
          While (*In\c)
            *Out\l = *In\c
            *Out + SizeOf(LONG)
            *In + #CharSize
          Wend
        EndIf
      CompilerEndIf
    Else
      If (NumNulls >= 1)
        Bytes = StringByteLength(Text, Format) + NumNulls * NullCharSize(Format)
        *Memory = AllocateMemory(Bytes)
        If (*Memory)
          PokeS(*Memory, Text, -1, Format)
        EndIf
      Else
        Bytes = StringByteLength(Text, Format)
        *Memory = AllocateMemory(Bytes, #PB_Memory_NoClear)
        If (*Memory)
          PokeS(*Memory, Text, -1, Format | #PB_String_NoZero)
        EndIf
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (*Memory)
EndProcedure

Procedure.s PeekSFree(*Memory, Format.i = #PB_Default, Length.i = -1)
  Protected Text.s = ""
  
  If (*Memory)
    Select (Format)
      Case #PB_Ascii, #PB_Unicode, #PB_UTF8
        ; OK
      Case #PB_Default
        Format = #StringMode
      Default
        Format = #Null
    EndSelect
    If (Format)
      Text = PeekS(*Memory, Length, Format)
    EndIf
    FreeMemory(*Memory)
  EndIf
  
  ProcedureReturn (Text)
EndProcedure

Procedure.i StringByteLengthMax(String.s)
  Protected Result.i  = StringByteLength(String, #PB_Unicode)
  Protected UTF8Len.i = StringByteLength(String, #PB_UTF8)
  If (UTF8Len > Result)
    Result = UTF8Len
  EndIf
  Result = Result + NullCharSize(#PB_Unicode)
  ProcedureReturn (Result)
EndProcedure








;-
;- Procedures - Text Files

Procedure.i CreateFileFromString(FileName.s, Text.s, Format.i = #PB_Default, ForceBOM.i = #False)
  Protected FN.i = #Null
  
  Select (Format)
    Case #PB_Ascii, #PB_Unicode, #PB_UTF8
      ; OK
    Case #PB_Default
      Format = #StringIOMode
    Default
      Format = #Null
  EndSelect
  If (Format)
    FN = CreateFile(#PB_Any, FileName)
    If (FN)
      If ((Format = #PB_Unicode) Or (ForceBOM))
        WriteStringFormat(FN, Format)
      EndIf
      WriteString(FN, Text, Format)
      CloseFile(FN)
    EndIf
  EndIf
  
  ProcedureReturn (Bool(FN))
EndProcedure

Procedure.s ReadFileToString(FileName.s, Format.i = #PB_Default)
  Protected Text.s = ""
  
  Protected FN.i = ReadFile(#PB_Any, FileName)
  If (FN)
    Protected BOM.i = ReadStringFormat(FN)
    Select (Format)
      Case #PB_Ascii, #PB_Unicode, #PB_UTF8
        ; OK
      Case #PB_Default
        Select (BOM)
          Case #PB_Ascii
            Format = #StringIOMode
          Case #PB_UTF8, #PB_Unicode
            Format = BOM
          Default
            Format = #Null
        EndSelect
      Default
        Format = #Null
    EndSelect
    If (Format)
      Text = ReadString(FN, Format | #PB_File_IgnoreEOL)
    EndIf
    CloseFile(FN)
  EndIf
  
  ProcedureReturn (Text)
EndProcedure



;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  
  DisableExplicit
  
  Debug "1. Basics"
  Debug "Compiled in " + #StringMode$ + " Mode (#CharSize = " + Str(#CharSize) + ")"
  Debug "Size of " + StringFormatName(#PB_Ascii) + " char is " + Str(NullCharSize(#PB_Ascii))
  Debug "Size of " + StringFormatName(#PB_Unicode) + " char is " + Str(NullCharSize(#PB_Unicode))
  TestString.s = ComputerName()
  Debug "Native size (including null) of '" + TestString + "' is " + Str(StringByteLengthN(TestString))
  Debug ""
  
  Debug "2. Peek and Poke"
  TestString = "Hello World!"
  *Buffer = AllocateMemory(StringByteLengthMax(TestString))
  PokeS_UTF8(*Buffer, TestString)
  Debug "Poke + Peek UTF8: " + PeekS_UTF8(*Buffer)
  PokeS_Unicode(*Buffer, TestString)
  Debug "Poke + Peek Unicode: " + PeekS_Unicode(*Buffer)
  FreeMemory(*Buffer)
  Debug ""
  
  Debug "3. String Buffers"
  TestString = "Das Blinkenlights"
  *Buffer = StringBuffer(TestString)
  Debug "Native string buffer: " + PeekSFree(*Buffer)
  *Buffer = StringBuffer_Ascii(TestString)
  Debug "ASCII string buffer: " + PeekSFree_Ascii(*Buffer)
  *Buffer = StringBuffer_UTF8(TestString)
  Debug "UTF-8 string buffer: " + PeekSFree_UTF8(*Buffer)
  Debug ""
  
  Debug "4. File I/O"
  TempFile.s = GetTemporaryDirectory() + "temp.txt"
  TestString = "This is a Unicode file."
  CreateFileFromString(TempFile, TestString, #PB_Unicode)
  Debug "Read: " + #DQUOTE$ + ReadFileToString(TempFile) + #DQUOTE$
  TestString = "This is a UTF-8 file with forced BOM."
  CreateFileFromString(TempFile, TestString, #PB_UTF8, #True)
  Debug "Read: " + #DQUOTE$ + ReadFileToString(TempFile) + #DQUOTE$
  Debug ""
  
  Debug "5. Emoji"
  TestString = ChrU($1F602) + ChrU($1F525) + ChrU($26BD)
  Debug TestString
  *Buffer = StringBuffer_UTF32(TestString)
  *Next = *Buffer
  Repeat
    Value.i = PeekCharacter(*Next, #PB_UTF32, @*Next)
    Debug ChrU(Value)
  Until (Value = #NUL)
  FreeMemory(*Buffer)
  
CompilerEndIf

CompilerEndIf

;-