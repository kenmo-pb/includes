; +-------------+
; | GetExifData |
; +-------------+
; | 2019-11-22 : Creation
; | 2020-08-30 : Added LoadImageEXIFRotated() - requires RotateImage.pbi
; | 2020-08-31 : Added multiple Include guard

;-
CompilerIf (Not Defined(_GetExifData_Included, #PB_Constant))
#_GetExifData_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

CompilerIf (Not Defined(ReadU16BE, #PB_Procedure))
Procedure.u ReadU16BE(File.i)
  Protected Result.u
  ReadData(File, @Result + 1, 1)
  ReadData(File, @Result + 0, 1)
  ProcedureReturn (Result)
EndProcedure
CompilerEndIf

CompilerIf (Not Defined(ReadU16Endian, #PB_Procedure))
Procedure.u ReadU16Endian(File.i, BE.i)
  If (BE)
    ProcedureReturn (ReadU16BE(File))
  EndIf
  ProcedureReturn (ReadUnicodeCharacter(File))
EndProcedure
CompilerEndIf

CompilerIf (Not Defined(ReadS32BE, #PB_Procedure))
Procedure.l ReadS32BE(File.i)
  Protected Result.l
  ReadData(File, @Result + 3, 1)
  ReadData(File, @Result + 2, 1)
  ReadData(File, @Result + 1, 1)
  ReadData(File, @Result + 0, 1)
  ProcedureReturn (Result)
EndProcedure
CompilerEndIf

CompilerIf (Not Defined(ReadS32Endian, #PB_Procedure))
Procedure.l ReadS32Endian(File.i, BE.i)
  If (BE)
    ProcedureReturn (ReadS32BE(File))
  EndIf
  ProcedureReturn (ReadLong(File))
EndProcedure
CompilerEndIf

;-
;- EXIF Procedures

Procedure.i GetExifRotation(File.s)
  Protected Result.i = -1
  ;  0 = is rotated correctly
  ;  1 = needs CW rotation (is -90 deg)
  ;  2 = needs 180 rotation
  ;  3 = needs CCW rotation (is +90 deg)
  ; -1 = unknown
  
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    If (ReadUnicodeCharacter(FN) = $D8FF)
      While (Not Eof(FN))
        Protected Marker.i = ReadU16BE(FN)
        Select (Marker)
          Case $FFE1
            Protected App1DataSize.i = ReadU16BE(FN)
            If ((ReadS32BE(FN) = $45786966) And (ReadU16BE(FN) = $0000))
              Protected BE.i = Bool(ReadU16BE(FN) = $4d4d)
              If (ReadU16Endian(FN, BE) = $002A)
                Protected IFD0Offset.i = ReadS32Endian(FN, BE)
                FileSeek(FN, IFD0Offset-8, #PB_Relative)
                While (#True)
                  Protected NumEntries.i = ReadU16Endian(FN, BE)
                  Protected i.i
                  For i = 0 To NumEntries-1
                    Protected Tag.i = ReadU16Endian(FN, BE)
                    Protected Format.i = ReadU16Endian(FN, BE)
                    Protected Components.i = ReadS32Endian(FN, BE)
                    Protected Dat.i = ReadS32Endian(FN, BE)
                    If (Tag = $0112)
                      Select ((Dat >> 16) & $FFFF)
                        Case 1 : Result = 0
                        Case 3 : Result = 2
                        Case 6 : Result = 1
                        Case 8 : Result = 3
                      EndSelect
                      Break 2
                    EndIf
                  Next i
                  Protected NextOffset.i = ReadS32Endian(FN, BE)
                  If (NextOffset = 0)
                    Break
                  EndIf
                  ; jump to next IFD
                  Break
                Wend
              EndIf
            EndIf
            Break
          Case $FFD9
            Break
          Default
            If (Marker & $FF00) = $FF00
              Break
            Else
              Break
            EndIf
        EndSelect
      Wend
    EndIf
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LoadImageEXIFRotated(Image.i, File.s)
  CompilerIf (Defined(RotateImage, #PB_Procedure))
    
    Protected Result.i = #Null
    Protected NeededRot.i = GetExifRotation(File)
    If (NeededRot > 0)
      If (Image = #PB_Any)
        Protected Temp.i = LoadImage(#PB_Any, File)
        If (Temp)
          Result = RotateImage(Temp, NeededRot, #PB_Any)
          FreeImage(Temp)
        EndIf
      Else
        Result = LoadImage(Image, File)
        If (Result)
          RotateImage(Image, NeededRot)
        EndIf
      EndIf
    Else
      Result = LoadImage(Image, File)
    EndIf
    ProcedureReturn (Result)
    
  CompilerElse
    CompilerIf (Defined(DebuggerError, #PB_Function))
      DebuggerError(#PB_Compiler_Procedure + "() requires RotateImage.pbi to be included first")
    CompilerEndIf
    ProcedureReturn (#Null)
  CompilerEndIf
EndProcedure

;-
;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Define File.s = OpenFileRequester("", "", "JPG|*.jpg;*.jpeg", 0)
Select GetExifRotation(File)
  Case 1
    Debug "Need to turn CW"
  Case 2
    Debug "Need to turn 180"
  Case 3
    Debug "Need to turn CCW"
  Case 0
    Debug "0 deg"
  Default
    Debug "Unknown"
EndSelect

CompilerEndIf
CompilerEndIf
;-
