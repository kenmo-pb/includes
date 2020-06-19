; +-------------+
; | RotateImage |
; +-------------+
; | 2020-06-13 : Creation (PureBasic 5.72)

; RotateImage(SourceImage.i, QuarterTurnsCW.i, DestImage.i = #PB_Ignore)
;
; - Rotates an image by 90, 180, 270 (or 0) degrees
; - Specify rotation as 1, 2, 3 (or 0) quarter turns clockwise
; - Wraps negative or high-value turns to the 0-3 range
; - Uses API functions when possible, otherwise falls back to native code
;
; Options for DestImage:
;   #PB_Ignore (default) or SourceImage number - rotate image and keep same number
;   #PB_Any - rotated result is stored in a new returned image number
;   <number> - result is stored in the specified image number
;
; Special case / warning:
;   You cannot pass in a dynamic #PB_Any-generated image number for DestImage
;   UNLESS it matches SourceImage AND the original/rotated dimensions match.
;
; Disable API:
;   Define #RotateImage_DisableAPI = #True before IncludeFile
;   to disable the use of any API functions.


;-
CompilerIf (Not Defined(_RotateImage_Included, #PB_Constant))
#_RotateImage_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

CompilerIf (#PB_Ignore = #PB_Any)
  CompilerError #PB_Compiler_Filename + " assumes #PB_Ignore <> #PB_Any"
CompilerEndIf




;- Constants (Public)

CompilerIf (Not Defined(RotateImage_DisableAPI, #PB_Constant))
  #RotateImage_DisableAPI = #False
CompilerEndIf



;-
;- Constants (Private)

#_RotateImage_PreventHighValueIDs = #True
#_RotateImage_HighValueIDStart    = 100000


;-
;- Procedures (Public)

Procedure.i RotateImage(SourceImage.i, QuarterTurnsCW.i, DestImage.i = #PB_Ignore)
  Protected Result.i = #Null
  
  ; Normalize quarter turns (0-3)
  If (QuarterTurnsCW < 0)
    QuarterTurnsCW + ((3 - QuarterTurnsCW)/4) * 4
  Else
    QuarterTurnsCW = QuarterTurnsCW % 4
  EndIf
  
  ; Prepare for rotation
  Protected Width.i    = ImageWidth(SourceImage)
  Protected Height.i   = ImageHeight(SourceImage)
  Protected SameSize.i = Bool((Width = Height) Or (QuarterTurnsCW % 2 = 0))
  Protected CopyBack.i = Bool((DestImage = #PB_Ignore) Or (DestImage = SourceImage))
  If (CopyBack)
    DestImage = SourceImage
  EndIf
  
  CompilerIf (#_RotateImage_PreventHighValueIDs)
    If ((DestImage >= #_RotateImage_HighValueIDStart) And (DestImage <> #PB_Any))
      If (CopyBack)
        If (Not SameSize)
          If (SourceImage >= #_RotateImage_HighValueIDStart)
            CompilerIf (#PB_Compiler_Debugger)
              DebuggerWarning(#PB_Compiler_Filename + ": You cannot rotate a non-square #PB_Any image in-place.")
            CompilerEndIf
            ProcedureReturn (#Null)
          EndIf
        EndIf
      Else
        CompilerIf (#PB_Compiler_Debugger)
          DebuggerWarning(#PB_Compiler_Filename + ": DestImage should be #PB_Any, #PB_Ignore, or a number below " + Str(#_RotateImage_HighValueIDStart) + ".")
        CompilerEndIf
        ProcedureReturn (#Null)
      EndIf
    EndIf
  CompilerEndIf
  
  If (QuarterTurnsCW = 0)
    ; No rotation
    If (CopyBack)
      Result = ImageID(SourceImage)
    Else
      Result = CopyImage(SourceImage, DestImage)
    EndIf
  Else
    Protected NewW.i, NewH.i
    If (QuarterTurnsCW % 2 = 1)
      NewW = Height
      NewH = Width
    Else
      NewW = Width
      NewH = Height
    EndIf
    Protected DrawImage.i
    Protected Valid.i = #False
    
    ;- - Windows API rotation
    CompilerIf ((#PB_Compiler_OS = #PB_OS_Windows) And (Not #RotateImage_DisableAPI))
      Protected MaxSize.i = Width
      If (Height > Width)
        MaxSize = Height
      EndIf
      If (CopyBack And SameSize)
        DrawImage = SourceImage
        Valid = #True
      Else
        DrawImage = CreateImage(#PB_Any, MaxSize, MaxSize, ImageDepth(SourceImage))
        If (DrawImage)
          Valid = #True
        EndIf
      EndIf
      
      If (Valid)
        Protected *DC = StartDrawing(ImageOutput(DrawImage))
        If (*DC)
          Dim Pt.POINT(2)
          If (DrawImage <> SourceImage)
            DrawingMode(#PB_2DDrawing_AllChannels)
            DrawImage(ImageID(SourceImage), 0, 0)
          EndIf
          If (QuarterTurnsCW = 1)
            Pt(0)\x = Height
            Pt(1)\x = Height
            Pt(1)\y = Width
            PlgBlt_(*DC, @Pt(0), *DC, 0, 0, Width, Height, #Null, 0, 0)
          ElseIf (QuarterTurnsCW = 2)
            CompilerIf (#True)
              StretchBlt_(*DC, Width-1, Height-1, -Width, -Height, *DC, 0, 0, Width, Height, #SRCCOPY)
            CompilerElse
              Pt(0)\x = Width
              Pt(0)\y = Height
              Pt(1)\y = Height
              Pt(2)\x = Width
              ; PlgBlt_() at exactly 180 degrees does not give a pixel-perfect output
              PlgBlt_(*DC, @Pt(0), *DC, 0, 0, Width, Height, #Null, 0, 0)
            CompilerEndIf
          ElseIf (QuarterTurnsCW = 3)
            Pt(0)\y = Width
            Pt(2)\x = Height
            Pt(2)\y = Width
            PlgBlt_(*DC, @Pt(0), *DC, 0, 0, Width, Height, #Null, 0, 0)
          EndIf
          StopDrawing()
          
          If (CopyBack And SameSize)
            Result = ImageID(SourceImage)
          Else
            Result = GrabImage(DrawImage, DestImage, 0, 0, NewW, NewH)
          EndIf
          Dim Pt.POINT(0)
        EndIf
        
        If (Not (CopyBack And SameSize))
          FreeImage(DrawImage)
        EndIf
        Valid = #False
      EndIf
    CompilerEndIf
    
    ;- - Software rotation
    If (Not Result)
      Dim Pixel.i(Width - 1, Height - 1)
      If (StartDrawing(ImageOutput(SourceImage)))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Protected x.i, y.i
        For y = 0 To Height - 1
          For x = 0 To Width - 1
            Pixel(x, y) = Point(x, y)
          Next x
        Next y
        StopDrawing()
        
        If (CopyBack And SameSize)
          DrawImage = SourceImage
          Valid = #True
        ElseIf (CopyBack)
          DrawImage = CreateImage(#PB_Any, NewW, NewH, ImageDepth(SourceImage))
          If (DrawImage)
            Valid = #True
          EndIf
        Else
          DrawImage = CreateImage(DestImage, NewW, NewH, ImageDepth(SourceImage))
          If (DrawImage)
            If (DestImage <> #PB_Any)
              DrawImage = DestImage
            EndIf
            Valid = #True
          EndIf
        EndIf
        
        If (Valid)
          If (StartDrawing(ImageOutput(DrawImage)))
            DrawingMode(#PB_2DDrawing_AllChannels)
            If (QuarterTurnsCW = 1)
              For y = 0 To Height - 1
                For x = 0 To Width - 1
                  Plot(Height - 1 - y, x, Pixel(x, y))
                Next x
              Next y
            ElseIf (QuarterTurnsCW = 2)
              For y = 0 To Height - 1
                For x = 0 To Width - 1
                  Plot(Width - 1 - x, Height - 1 - y, Pixel(x, y))
                Next x
              Next y
            ElseIf (QuarterTurnsCW = 3)
              For y = 0 To Height - 1
                For x = 0 To Width - 1
                  Plot(y, Width - 1 - x, Pixel(x, y))
                Next x
              Next y
            EndIf
            StopDrawing()
            
            If (CopyBack And SameSize)
              Result = ImageID(SourceImage)
            ElseIf (CopyBack)
              Result = CopyImage(DrawImage, SourceImage)
              FreeImage(DrawImage)
            Else
              If (DestImage = #PB_Any)
                Result = DrawImage
              Else
                Result = ImageID(DestImage)
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
      Dim Pixel.i(0, 0)
    EndIf
    
  EndIf
  
  ProcedureReturn (Result)
EndProcedure














;-
;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit


UsePNGImageDecoder()
UseJPEGImageDecoder()

UseMD5Fingerprint()



Procedure.s ImageHash(Image.i)
  Protected Result.s
  If (StartDrawing(ImageOutput(Image)))
    Protected FP.i = StartFingerprint(#PB_Any, #PB_Cipher_MD5)
    If (FP)
      Protected x.i, y.i, Pixel.l
      For y = 0 To OutputHeight() - 1
        For x = 0 To OutputWidth() - 1
          Pixel = Point(x, y)
          AddFingerprintBuffer(FP, @Pixel, SizeOf(LONG))
        Next x
      Next y
      Result = FinishFingerprint(FP)
      ;Debug Result
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn (Result)
EndProcedure

Dim KnownHash.s(3)

For TestImage = 1 To 2
  
  Select (TestImage)
    Case 1
      InFile.s = #PB_Compiler_Home + "Examples/Sources/Data/PureBasicLogo.bmp"
      KnownHash(0) = "e642f9addc21d9000c63e87e0319e7a3"
      KnownHash(1) = "e61e52c03e4283576e12cc7970f5df1a"
      KnownHash(2) = "63fb1f9f7063239a1da16c7b9427ba80"
      KnownHash(3) = "33cf161ea39d206327cfc9e23398ebe2"
    Case 2
      InFile.s = #PB_Compiler_Home + "Examples/Sources/Data/world.png"
      KnownHash(0) = "5df93dac50c28a0cbcf39df780180883"
      KnownHash(1) = "be4c701e4e01973e653822de12aedc60"
      KnownHash(2) = "c3e282d2983703e2b114d2f97ad65bca"
      KnownHash(3) = "43695f6be1e4b417d829cb1402f9460c"
  EndSelect
  
  Debug "Test Image #" + Str(TestImage) + " (" + GetFilePart(InFile) + ")"
  
  If (Not LoadImage(0, InFile))
    Debug "Could not load test image: " + InFile
    End
  EndIf
  Debug Str(ImageWidth(0)) + " x " + Str(ImageHeight(0))
  Debug ""
  
  
  
  
  
  
  ; Test 1 - Rotate Image 0 to another Image number
  For i = 0 To 3
    If (RotateImage(0, i, 1))
      ;SaveImage(1, GetTemporaryDirectory() + Str(i) + ".bmp")
      If (ImageHash(1) = KnownHash(i))
        Debug "OK"
      Else
        Debug "Hash check failed!"
      EndIf
    Else
      Debug "Failed to rotate!"
    EndIf
  Next i
  Debug ""
  
  
  ; Test 2 - Rotate Image 0 to a dynamic #PB_Any
  For i = 0 To 3
    NewImg.i = RotateImage(0, i, #PB_Any)
    If (NewImg)
      If (ImageHash(NewImg) = KnownHash(i))
        Debug "OK"
      Else
        Debug "Hash check failed!"
      EndIf
      FreeImage(NewImg)
    Else
      Debug "Failed to rotate!"
    EndIf
  Next i
  Debug ""
  
  
  ; Test 3 - Rotate Image 0 in place, 90 degrees at a time
  For i = 0 To 3
    If (RotateImage(0, 1))
      If (ImageHash(0) = KnownHash((i+1) % 4))
        Debug "OK"
      Else
        Debug "Hash check failed!"
      EndIf
    Else
      Debug "Failed to rotate!"
    EndIf
  Next i
  Debug ""
  
Next TestImage


CompilerEndIf
CompilerEndIf
;-
