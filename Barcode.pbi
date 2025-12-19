; +-------------+
; | Barcode.pbi |
; +-------------+
; | 2025-12-16 : Creation (PureBasic 6.21), currently just "Code 128" format
; | 2025-12-17 : Added 'Fast' variants of procedures, demo GUI
; | 2025-12-18 : Implemented Code39 with "Mod 43" and "Mod 10" options

; CURRENTLY SUPPORTED BARCODE FORMATS
;   Code 128 (no character limit, as long as you provide enough output pixel width)
;   Code 39  (with optional "Mod 43" or "Mod 10" checksum)

; EASY OUTPUTS TO
;   2DDrawing
;   CanvasGadget
;   Image
;   BMP/PNG/JPEG File (you must call UsePNGImageEncoder() or UseJPEGImageEncoder())

; TO-DO
;   test Code 39 special characters
;   "Full ASCII" Code 39 encoding
;   more control over drawn bar height / stretch to any non-integer-scale dimensions
;   more 1D barcode formats (UPC ?)
;   2D barcode formats (QR ?)

; REFERENCES
;   https://en.wikipedia.org/wiki/Code_128
;   https://en.wikipedia.org/wiki/Code_39
;   https://www.bardecode.com/en1/code-39-barcode-specification/
;   https://www.onbarcode.com/code_39/code39-size-setting.html
;   https://www.onlinebarcodereader.com/
;   https://online-barcode-reader.inliteresearch.com/

;-
CompilerIf (Not Defined(_Barcode_Included, #PB_Constant))
#_Barcode_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;- Compile Switches

CompilerIf (Not Defined(Barcode_Exclude_Code128, #PB_Constant))
  #Barcode_Exclude_Code128 = #False
CompilerEndIf

CompilerIf (Not Defined(Barcode_Exclude_Code39, #PB_Constant))
  #Barcode_Exclude_Code39 = #False ; format not yet implemented
CompilerEndIf

;-
;- Constants (Public)

Enumeration BarcodeFormats
  CompilerIf (Not #Barcode_Exclude_Code128)
    #Barcode_Code128
  CompilerEndIf
  CompilerIf (Not #Barcode_Exclude_Code39)
    #Barcode_Code39
    #Barcode_Code39Mod43
    #Barcode_Code39Mod10
  CompilerEndIf
  ;
  #Barcode_NumFormats
EndEnumeration





;-
;- Constants (Private)

CompilerIf (#Barcode_NumFormats = 0)
  CompilerError "All barcode formats have been excluded!"
CompilerEndIf

CompilerIf (Not #Barcode_Exclude_Code128)

Enumeration
  #_Barcode_Code128_ToggleAB = 98
  #_Barcode_Code128_ShiftC   = 99
  #_Barcode_Code128_StartA   = 103
  #_Barcode_Code128_StartB   = 104
  #_Barcode_Code128_StartC   = 105
  #_Barcode_Code128_Stop     = 106
EndEnumeration

Enumeration
  #_Barcode_Code128_SetUndefined = 0
  #_Barcode_Code128_SetA
  #_Barcode_Code128_SetB
  #_Barcode_Code128_SetC
EndEnumeration

#_Barcode_Code128_SymbolWidth           = 11
#_Barcode_Code128_FinalBarWidth         =  2
#_Barcode_Code128_MinimumQuietZoneWidth = 10
#_Barcode_Code128_DefaultQuietZoneWidth = #_Barcode_Code128_SymbolWidth;#_Barcode_Code128_MinimumQuietZoneWidth

CompilerEndIf

CompilerIf (Not #Barcode_Exclude_Code39)

Enumeration
  #_Barcode_Code39_StartStop = 43;0
EndEnumeration

#_Barcode_Code39_WideToNarrowRatio      = 3
#_Barcode_Code39_SymbolWidth            = (3 * #_Barcode_Code39_WideToNarrowRatio + 6 * 1)
#_Barcode_Code39_IntercharacterWidth    = 1
#_Barcode_Code39_MinimumQuietZoneWidth  = 10
#_Barcode_Code39_DefaultQuietZoneWidth = #_Barcode_Code39_MinimumQuietZoneWidth

CompilerEndIf





;-
;- Structures (Private)

Structure _Barcode_U16Array
  u.u[0]
EndStructure

Structure BarcodeStruct
  Text.s
  Format.i
  IsAllNumeric.i
  List Symbol.i()
  List Bit1D.i()
EndStructure






;-
;- Globals (Private)

Global Dim BarcodeFormatName.s(#Barcode_NumFormats - 1)
CompilerIf (Not #Barcode_Exclude_Code128)
  BarcodeFormatName(#Barcode_Code128) = "Code 128"
  Global _Barcode_Code128_QuietZoneWidth.i = #_Barcode_Code128_DefaultQuietZoneWidth
CompilerEndIf
CompilerIf (Not #Barcode_Exclude_Code39)
  BarcodeFormatName(#Barcode_Code39)      = "Code 39"
  BarcodeFormatName(#Barcode_Code39Mod43) = "Code 39 Mod 43"
  BarcodeFormatName(#Barcode_Code39Mod10) = "Code 39 Mod 10"
  Global _Barcode_Code39_QuietZoneWidth.i = #_Barcode_Code39_DefaultQuietZoneWidth
CompilerEndIf





;-
;- Macros (Private)

Macro _Barcode_AddSymbol(_Barcode, _Symbol)
  AddElement(_Barcode\Symbol())
  _Barcode\Symbol() = (_Symbol)
EndMacro

Macro _Barcode_AddBit1D(_Barcode, _BitValue)
  AddElement(_Barcode\Bit1D())
  _Barcode\Bit1D() = (_BitValue)
EndMacro





;-
;- Procedures (Private)

Declare.i CreateBarcode(Text.s, Format.i)
Declare.i FreeBarcode(*Barcode.BarcodeStruct)

Procedure.i _Barcode_FormatValid(Format.i)
  If ((Format >= 0) And (Format < #Barcode_NumFormats))
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

;-
;- - Code 128

CompilerIf (Not #Barcode_Exclude_Code128)

Procedure.i _Barcode_Code128A_SymbolForChar(c.c)
  Protected Result.i = -1
  Select (c)
    Case ' ' To '_'
      Result = $00 + (c - ' ')
    Case #NUL To #US
      Result = $40 + (c - #NUL)
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _Barcode_Code128B_SymbolForChar(c.c)
  Protected Result.i = -1
  Select (c)
    Case ' ' To '_'
      Result = $00 + (c - ' ')
    Case '`' To #DEL
      Result = $40 + (c - '`')
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _Barcode_Generate_Code128(*Barcode.BarcodeStruct)
  Protected Result.i = #False
  Protected Error.i = #False
  
  ; Add Quiet Zone
  Protected i.i
  For i = 1 To _Barcode_Code128_QuietZoneWidth
    _Barcode_AddBit1D(*Barcode, #False)
  Next i
  
  ; If entirely numeric, can use better-compressed "Set C" symbols
  Protected CharsLeft.i = Len(*Barcode\Text)
  Protected *C.CHARACTER = @*Barcode\Text
  If (*Barcode\IsAllNumeric)
    If ((CharsLeft % 2) = 1) ; odd number of digit chars
      _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_StartA)
      _Barcode_AddSymbol(*Barcode, _Barcode_Code128A_SymbolForChar(*C\c))
      *C + SizeOf(CHARACTER)
      CharsLeft - 1
      _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_ShiftC)
    Else
      _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_StartC)
    EndIf
    While (CharsLeft > 0)
      i = (*C\c - '0') * 10
      *C + SizeOf(CHARACTER)
      i + (*C\c - '0')
      _Barcode_AddSymbol(*Barcode, i)
      *C + SizeOf(CHARACTER)
      CharsLeft - 2
    Wend
  EndIf
  
  ; Map characters to Set A / Set B symbols
  If (Not Error)
    If (CharsLeft > 0)
      Protected FirstSetNeeded.i = #_Barcode_Code128_SetUndefined
      Protected SetASymbol.i, SetBSymbol.i
      ;*C = @*Barcode\Text
      While (*C\c)
        SetASymbol = _Barcode_Code128A_SymbolForChar(*C\c)
        SetBSymbol = _Barcode_Code128B_SymbolForChar(*C\c)
        If (SetASymbol >= 0)
          If (SetBSymbol >= 0)
            ; valid in both Sets A and B
          Else
            ; valid in Set A, not in B!
            If (FirstSetNeeded = #_Barcode_Code128_SetUndefined)
              FirstSetNeeded = #_Barcode_Code128_SetA
            EndIf
          EndIf
        Else
          If (SetBSymbol >= 0)
            ; valid in Set B, not in A!
            If (FirstSetNeeded = #_Barcode_Code128_SetUndefined)
              FirstSetNeeded = #_Barcode_Code128_SetB
            EndIf
          Else
            ; valid in neither set!
            Error = #True
            Break
          EndIf
        EndIf
        *C + SizeOf(CHARACTER)
      Wend
      
      If (Not Error)
        If (FirstSetNeeded = #_Barcode_Code128_SetUndefined)
          FirstSetNeeded = #_Barcode_Code128_SetA
        EndIf
        Protected CurrentSet.i
        If (FirstSetNeeded = #_Barcode_Code128_SetB)
          CurrentSet = #_Barcode_Code128_SetB
          _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_StartB)
        Else
          CurrentSet = #_Barcode_Code128_SetA
          _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_StartA)
        EndIf
        
        *C = @*Barcode\Text
        While (CharsLeft > 0)
          SetASymbol = _Barcode_Code128A_SymbolForChar(*C\c)
          SetBSymbol = _Barcode_Code128B_SymbolForChar(*C\c)
          
          If (CurrentSet = #_Barcode_Code128_StartA)
            If (SetASymbol >= 0)
              _Barcode_AddSymbol(*Barcode, SetASymbol)
            Else
              _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_ToggleAB)
              _Barcode_AddSymbol(*Barcode, SetBSymbol)
              CurrentSet = #_Barcode_Code128_StartB
            EndIf
          Else ; Currently Set B...
            If (SetBSymbol >= 0)
              _Barcode_AddSymbol(*Barcode, SetBSymbol)
            Else
              _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_ToggleAB)
              _Barcode_AddSymbol(*Barcode, SetASymbol)
              CurrentSet = #_Barcode_Code128_StartA
            EndIf
          EndIf
          
          *C + SizeOf(CHARACTER)
          CharsLeft - 1
        Wend
      EndIf
    EndIf
  EndIf
  
  ; Add Check Symbol and Stop Symbol
  If (Not Error)
    Protected Checksum.i = 0
    If (ListSize(*Barcode\Symbol()) > 0)
      FirstElement(*Barcode\Symbol())
      Checksum + *Barcode\Symbol()
      While (NextElement(*Barcode\Symbol()))
        Checksum + *Barcode\Symbol() * ListIndex(*Barcode\Symbol())
      Wend
      _Barcode_AddSymbol(*Barcode, (Checksum % 103))
      _Barcode_AddSymbol(*Barcode, #_Barcode_Code128_Stop)
    Else
      Error = #True
    EndIf
  EndIf
  
  ; Expand Symbol list to Individual Bar/Bits
  If (Not Error)
    Protected *UA._Barcode_U16Array = ?_Barcode_Code128_Patterns
    Protected Pattern.u
    ForEach (*Barcode\Symbol())
      Pattern = *UA\u[*Barcode\Symbol()]
      CompilerIf (#PB_Compiler_Debugger And (#False))
        Select (*Barcode\Symbol())
          Case #_Barcode_Code128_StartA
            Debug "StartA"
          Case #_Barcode_Code128_StartB
            Debug "StartB"
          Case #_Barcode_Code128_StartC
            Debug "StartC"
          Case #_Barcode_Code128_ToggleAB
            Debug "ToggleA/B"
          Case #_Barcode_Code128_ShiftC
            Debug "ShiftC"
        EndSelect
      CompilerEndIf
      For i = 10 To 0 Step -1
        _Barcode_AddBit1D(*Barcode, (Pattern >> i) & $01)
      Next i
    Next
  EndIf
  
  ; Append "Final Bar" and Quiet Zone
  If (Not Error)
    For i = 1 To #_Barcode_Code128_FinalBarWidth
      _Barcode_AddBit1D(*Barcode, #True)
    Next i
    For i = 1 To _Barcode_Code128_QuietZoneWidth
      _Barcode_AddBit1D(*Barcode, #False)
    Next i
  EndIf
  
  If (Error)
    ClearList(*Barcode\Symbol())
    ClearList(*Barcode\Bit1D())
    Result = #False
  Else
    If (ListSize(*Barcode\Bit1D()) > 0)
      Result = #True
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf

;-

;- - Code 39

CompilerIf (Not #Barcode_Exclude_Code39)

Procedure.i _Barcode_FormatIsCode39(Format.i)
  Select (Format)
    Case #Barcode_Code39, #Barcode_Code39Mod43, #Barcode_Code39Mod10
      ProcedureReturn (#True)
  EndSelect
  ProcedureReturn (#False)
EndProcedure

Procedure.i _Barcode_Code39_SymbolForChar(c.c)
  Protected Result.i = -1
  Select (c)
    Case '0' To '9'
      Result = (c - '0' + 0)
    Case 'A' To 'Z'
      Result = (c - 'A' + 10)
    Case 'a' To 'z'
      If (#True) ; Map lowercase to uppercase, rather than error out...
        Result = (c - 'a' + 10)
      EndIf
    Case '-'
      Result = 36
    Case '.'
      Result = 37
    Case ' '
      Result = 38
    Case '$'
      Result = 39
    Case '/'
      Result = 40
    Case '+'
      Result = 41
    Case '%'
      Result = 42
    ;Case '*' ; not allowed within content of text!
    ;  Result = #_Barcode_Code39_StartStop
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _Barcode_Generate_Code39(*Barcode.BarcodeStruct)
  Protected Result.i = #False
  Protected Error.i = #False
  
  ; Add Quiet Zone
  Protected i.i
  For i = 1 To _Barcode_Code39_QuietZoneWidth
    _Barcode_AddBit1D(*Barcode, #False)
  Next i
  
  ; Add Start Symbol
  _Barcode_AddSymbol(*Barcode, #_Barcode_Code39_StartStop)
  
  ; Map characters to symbols
  Protected Checksum.i = 0
  Protected Symbol.i
  Protected Text.s = *Barcode\Text
  Text = LTrim(Text, "*")
  Text = RTrim(Text, "*")
  Protected *C.CHARACTER = @Text
  While (*C\c)
    Symbol = _Barcode_Code39_SymbolForChar(*C\c)
    If (Symbol >= 0)
      If (Symbol <> #_Barcode_Code39_StartStop)
        _Barcode_AddSymbol(*Barcode, Symbol)
        Checksum + Symbol
      EndIf
    Else
      Error = #True
      Break
    EndIf
    *C + SizeOf(CHARACTER)
  Wend
  
  ; Add Checksum Symbol, if applicable
  If (*Barcode\Format = #Barcode_Code39Mod43)
    _Barcode_AddSymbol(*Barcode, (Checksum % 43))
  ElseIf (*Barcode\Format = #Barcode_Code39Mod10)
    _Barcode_AddSymbol(*Barcode, (Checksum % 10))
  EndIf
  
  ; Add Stop Symbol
  _Barcode_AddSymbol(*Barcode, #_Barcode_Code39_StartStop)
  
  ; Expand Symbol list to Individual Bar/Bits
  If (Not Error)
    Protected *UA._Barcode_U16Array = ?_Barcode_Code39_Patterns
    Protected Pattern.u
    ForEach (*Barcode\Symbol())
      Pattern = *UA\u[*Barcode\Symbol()]
      Protected IsBar.i = #True
      For i = 8 To 0 Step -1
        Protected IsWide.i = (Pattern >> i) & $01
        If (IsWide)
          Protected j.i
          For j = 1 To #_Barcode_Code39_WideToNarrowRatio
            _Barcode_AddBit1D(*Barcode, IsBar)
          Next j
        Else
          _Barcode_AddBit1D(*Barcode, IsBar)
        EndIf
        IsBar = (1 - IsBar)
      Next i
      For j = 1 To #_Barcode_Code39_IntercharacterWidth
        _Barcode_AddBit1D(*Barcode, #False)
      Next j
    Next
  EndIf
  
  ; Final Quiet Zone
  If (Not Error)
    For i = 1 To _Barcode_Code39_QuietZoneWidth
      _Barcode_AddBit1D(*Barcode, #False)
    Next i
  EndIf
  
  If (Error)
    ClearList(*Barcode\Symbol())
    ClearList(*Barcode\Bit1D())
    Result = #False
  Else
    If (ListSize(*Barcode\Bit1D()) > 0)
      Result = #True
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf

;-

Procedure.i _Barcode_Generate(*Barcode.BarcodeStruct)
  Protected Result.i = #False
  
  ; Pre-check if entirely numeric
  *Barcode\IsAllNumeric = #True
  Protected *C.CHARACTER = @*Barcode\Text
  While (*C\c)
    Select (*C\c)
      Case '0' To '9'
        ;
      Default
        *Barcode\IsAllNumeric = #False
        Break
    EndSelect
    *C + SizeOf(CHARACTER)
  Wend
  
  Select (*Barcode\Format)
    CompilerIf (Not #Barcode_Exclude_Code128)
    Case #Barcode_Code128
      Result = _Barcode_Generate_Code128(*Barcode)
    CompilerEndIf
    CompilerIf (Not #Barcode_Exclude_Code39)
    Case #Barcode_Code39, #Barcode_Code39Mod43, #Barcode_Code39Mod10
      Result = _Barcode_Generate_Code39(*Barcode)
    CompilerEndIf
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _Barcode_Draw(*Barcode.BarcodeStruct, x.i, y.i, Width.i, Height.i, BarRGBA.i, BackgroundRGBA.i)
  Protected Result.i = #False
  If (*Barcode And _Barcode_FormatValid(*Barcode\Format))
    If ((Width > 0) And (Height > 0))
      If (#False)
        Box(x, y, Width, Height, BackgroundRGBA)
      EndIf
      
      If (#True) ; Draw basic 1D bars... currently the only style we draw...
        Protected N.i = ListSize(*Barcode\Bit1D())
        Protected Scale.i
        Scale = Width / N
        If (Scale >= 1)
          Result = #True
          Protected TotalDrawWidth.i = N * Scale
          Protected HorizontalExtra.i = Width - TotalDrawWidth
          Protected dw.i = Scale
          
          ; Calculate a reasonable bar draw height...
          Protected dh.i = Height
          CompilerIf (Not #Barcode_Exclude_Code128)
            If (*Barcode\Format = #Barcode_Code128)
              dh = Height - 2 * (Scale * #_Barcode_Code128_SymbolWidth)
              If (dh < 2 * (Scale * #_Barcode_Code128_SymbolWidth))
                dh = Height - 1 * (Scale * #_Barcode_Code128_SymbolWidth)
                If (dh < 1 * (Scale * #_Barcode_Code128_SymbolWidth))
                  dh = Height
                EndIf
              EndIf
            EndIf
          CompilerEndIf
          CompilerIf (Not #Barcode_Exclude_Code39)
            If (_Barcode_FormatIsCode39(*Barcode\Format))
              dh = Height - 2 * (Scale * #_Barcode_Code39_SymbolWidth)
              If (dh < 2 * (Scale * #_Barcode_Code39_SymbolWidth))
                dh = Height - 1 * (Scale * #_Barcode_Code39_SymbolWidth)
                If (dh < 1 * (Scale * #_Barcode_Code39_SymbolWidth))
                  dh = Height
                EndIf
              EndIf
            EndIf
          CompilerEndIf
          
          Protected dx.i = (Width - TotalDrawWidth) / 2
          Protected dy.i = (Height - dh) / 2
          ForEach (*Barcode\Bit1D())
            If (*Barcode\Bit1D())
              Box(dx, dy, dw, dh, BarRGBA)
            ElseIf (#False)
              Box(dx, dy, dw, dh, BackgroundRGBA)
            EndIf
            dx + Scale
          Next
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure








;-
;- Procedures (Public)

Procedure.i GetBarcodeFormat(*Barcode.BarcodeStruct)
  Protected Result.i = -1
  If (*Barcode And _Barcode_FormatValid(*Barcode\Format))
    Result = *Barcode\Format
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i GetBarcodeMinimumWidth(*Barcode.BarcodeStruct)
  Protected Result.i = 0
  If (*Barcode)
    Select (*Barcode\Format)
      CompilerIf (Not #Barcode_Exclude_Code128)
      Case #Barcode_Code128
        Result = ListSize(*Barcode\Bit1D())
      CompilerEndIf
      CompilerIf (Not #Barcode_Exclude_Code39)
      Case #Barcode_Code39, #Barcode_Code39Mod43, #Barcode_Code39Mod10
        Result = ListSize(*Barcode\Bit1D())
      CompilerEndIf
    EndSelect
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-

Procedure.i DrawBarcode(*Barcode.BarcodeStruct, x.i, y.i, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  ProcedureReturn (_Barcode_Draw(*Barcode, x, y, Width, Height, BarColor, BackgroundColor))
EndProcedure

Procedure.i DrawBarcodeFast(Text.s, Format.i, x.i, y.i, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  Protected *Barcode.BarcodeStruct = CreateBarcode(Text, Format)
  If (*Barcode)
    DrawBarcode(*Barcode, x, y, Width, Height, BarColor, BackgroundColor)
    FreeBarcode(*Barcode)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DrawBarcodeToCanvasGadget(*Barcode.BarcodeStruct, CanvasGadget.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  If (*Barcode)
    If (StartDrawing(CanvasOutput(CanvasGadget)))
      Box(0, 0, OutputWidth(), OutputHeight(), BackgroundColor)
      Result = DrawBarcode(*Barcode, 0, 0, OutputWidth(), OutputHeight(), BarColor, BackgroundColor)
      StopDrawing()
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i DrawBarcodeToCanvasGadgetFast(Text.s, Format.i, CanvasGadget.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  Protected *Barcode.BarcodeStruct = CreateBarcode(Text, Format)
  If (*Barcode)
    Result = DrawBarcodeToCanvasGadget(*Barcode, CanvasGadget, BarColor, BackgroundColor)
    FreeBarcode(*Barcode)
  Else
    If (#True)
      If (StartDrawing(CanvasOutput(CanvasGadget)))
        Box(0, 0, OutputWidth(), OutputHeight(), BackgroundColor)
        StopDrawing()
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateBarcodeImage(Image.i, *Barcode.BarcodeStruct, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #Null
  If (*Barcode And (Width > 0) And (Height > 0))
    Result = CreateImage(Image, Width, Height, 24, BackgroundColor)
    If (Result)
      If (Image = #PB_Any)
        Image = Result
      EndIf
      If (StartDrawing(ImageOutput(Image)))
        If (DrawBarcode(*Barcode, 0, 0, Width, Height, BarColor, BackgroundColor))
          StopDrawing()
        Else
          StopDrawing()
          FreeImage(Image)
          Result = #Null
        EndIf
      Else
        FreeImage(Image)
        Result = #Null
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateBarcodeImageFast(Image.i, Text.s, Format.i, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  Protected *Barcode.BarcodeStruct = CreateBarcode(Text, Format)
  If (*Barcode)
    Result = CreateBarcodeImage(Image, *Barcode, Width, Height, BarColor, BackgroundColor)
    FreeBarcode(*Barcode)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ExportBarcodeImageFile(File.s, *Barcode.BarcodeStruct, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  If ((File <> "") And (*Barcode))
    Protected Image.i = CreateBarcodeImage(#PB_Any, *Barcode, Width, Height, BarColor, BackgroundColor)
    If (Image)
      Protected Format.i = -1
      Protected Quality.i = 0
      Select (LCase(GetExtensionPart(File)))
        Case "png"
          Format = #PB_ImagePlugin_PNG
        Case "jpg", "jpeg"
          Format = #PB_ImagePlugin_JPEG
          Quality = 10
        Case "bmp"
          Format = #PB_ImagePlugin_BMP
      EndSelect
      If (Format <> -1)
        If (SaveImage(Image, File, Format, Quality))
          Result = #True
        EndIf
      EndIf
      FreeImage(Image)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ExportBarcodeImageFileFast(File.s, Text.s, Format.i, Width.i, Height.i, BarColor.i = #Black, BackgroundColor.i = #White)
  Protected Result.i = #False
  Protected *Barcode.BarcodeStruct = CreateBarcode(Text, Format)
  If (*Barcode)
    Result = ExportBarcodeImageFile(File, *Barcode, Width, Height, BarColor, BackgroundColor)
    FreeBarcode(*Barcode)
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-

Procedure.i FreeBarcode(*Barcode.BarcodeStruct)
  If (*Barcode)
    ClearList(*Barcode\Symbol())
    ClearList(*Barcode\Bit1D())
    FreeStructure(*Barcode)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i CreateBarcode(Text.s, Format.i)
  Protected *Barcode.BarcodeStruct = #Null
  If ((Text <> "") And _Barcode_FormatValid(Format))
    *Barcode = AllocateStructure(BarcodeStruct)
    If (*Barcode)
      *Barcode\Text   = Text
      *Barcode\Format = Format
      If (_Barcode_Generate(*Barcode))
        ; OK
      Else
        *Barcode = FreeBarcode(*Barcode)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*Barcode)
EndProcedure







;-
;- Data Section (Private)

DataSection
  
  ;- - Code128
  CompilerIf (Not #Barcode_Exclude_Code128)
  _Barcode_Code128_Patterns:
  Data.u %11011001100
  Data.u %11001101100
  Data.u %11001100110
  Data.u %10010011000
  Data.u %10010001100
  Data.u %10001001100
  Data.u %10011001000
  Data.u %10011000100
  Data.u %10001100100
  Data.u %11001001000
  Data.u %11001000100
  Data.u %11000100100
  Data.u %10110011100
  Data.u %10011011100
  Data.u %10011001110
  Data.u %10111001100
  Data.u %10011101100
  Data.u %10011100110
  Data.u %11001110010
  Data.u %11001011100
  Data.u %11001001110
  Data.u %11011100100
  Data.u %11001110100
  Data.u %11101101110
  Data.u %11101001100
  Data.u %11100101100
  Data.u %11100100110
  Data.u %11101100100
  Data.u %11100110100
  Data.u %11100110010
  Data.u %11011011000
  Data.u %11011000110
  Data.u %11000110110
  Data.u %10100011000
  Data.u %10001011000
  Data.u %10001000110
  Data.u %10110001000
  Data.u %10001101000
  Data.u %10001100010
  Data.u %11010001000
  Data.u %11000101000
  Data.u %11000100010
  Data.u %10110111000
  Data.u %10110001110
  Data.u %10001101110
  Data.u %10111011000
  Data.u %10111000110
  Data.u %10001110110
  Data.u %11101110110
  Data.u %11010001110
  Data.u %11000101110
  Data.u %11011101000
  Data.u %11011100010
  Data.u %11011101110
  Data.u %11101011000
  Data.u %11101000110
  Data.u %11100010110
  Data.u %11101101000
  Data.u %11101100010
  Data.u %11100011010
  Data.u %11101111010
  Data.u %11001000010
  Data.u %11110001010
  Data.u %10100110000
  Data.u %10100001100
  Data.u %10010110000
  Data.u %10010000110
  Data.u %10000101100
  Data.u %10000100110
  Data.u %10110010000
  Data.u %10110000100
  Data.u %10011010000
  Data.u %10011000010
  Data.u %10000110100
  Data.u %10000110010
  Data.u %11000010010
  Data.u %11001010000
  Data.u %11110111010
  Data.u %11000010100
  Data.u %10001111010
  Data.u %10100111100
  Data.u %10010111100
  Data.u %10010011110
  Data.u %10111100100
  Data.u %10011110100
  Data.u %10011110010
  Data.u %11110100100
  Data.u %11110010100
  Data.u %11110010010
  Data.u %11011011110
  Data.u %11011110110
  Data.u %11110110110
  Data.u %10101111000
  Data.u %10100011110
  Data.u %10001011110
  Data.u %10111101000
  Data.u %10111100010
  Data.u %11110101000
  Data.u %11110100010
  Data.u %10111011110
  Data.u %10111101110
  Data.u %11101011110
  Data.u %11110101110
  Data.u %11010000100
  Data.u %11010010000
  Data.u %11010011100
  Data.u %11000111010
  Data.u %11010111000
  CompilerEndIf
  
  ;- - Code39
  CompilerIf (Not #Barcode_Exclude_Code39)
  _Barcode_Code39_Patterns:
  Data.u %000110100 ; '0'
  Data.u %100100001
  Data.u %001100001
  Data.u %101100000
  Data.u %000110001
  Data.u %100110000
  Data.u %001110000
  Data.u %000100101
  Data.u %100100100
  Data.u %001100100 ; '9'
  Data.u %100001001 ; 'A'
  Data.u %001001001
  Data.u %101001000
  Data.u %000011001
  Data.u %100011000
  Data.u %001011000
  Data.u %000001101
  Data.u %100001100
  Data.u %001001100
  Data.u %000011100
  Data.u %100000011
  Data.u %001000011
  Data.u %101000010
  Data.u %000010011
  Data.u %100010010
  Data.u %001010010
  Data.u %000000111
  Data.u %100000110
  Data.u %001000110
  Data.u %000010110
  Data.u %110000001
  Data.u %011000001
  Data.u %111000000
  Data.u %010010001
  Data.u %110010000
  Data.u %011010000 ; 'Z'
  Data.u %010000101 ; '-'
  Data.u %110000100 ; '.'
  Data.u %011000100 ; ' ' (Space)
  Data.u %010101000 ; '$'
  Data.u %010100010 ; '/'
  Data.u %010001010 ; '+'
  Data.u %000101010 ; '%'
  Data.u %010010100 ; '*' (Start/Stop Symbol)
  CompilerEndIf
  
EndDataSection











;-
;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit



; Create a window with CanvasGadget...

If ExamineDesktops()
  Height = DesktopHeight(0) * 0.40
  Width  = Height * 480 / 360
Else
  Width  = 480
  Height = 360
EndIf
OpenWindow(0, 0, 0, Width, Height, #PB_Compiler_Filename, #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_SystemMenu | #PB_Window_Invisible)
Border = 10

Width = (WindowWidth(0) - 3 * Border) / 2
StringGadget(0, Border, Border, Width, 20, "8675309")
ResizeGadget(0, #PB_Ignore, #PB_Ignore, #PB_Ignore, GadgetHeight(0, #PB_Gadget_RequiredSize))

ComboBoxGadget(1, WindowWidth(0) - Border - Width, Border, Width, GadgetHeight(0))
For i = 0 To (#Barcode_NumFormats - 1)
  AddGadgetItem(1, i, BarcodeFormatName(i))
Next i
SetGadgetState(1, 0)
ResizeGadget(1, #PB_Ignore, #PB_Ignore, #PB_Ignore, GadgetHeight(1, #PB_Gadget_RequiredSize))

CanvasGadget(2, Border, 5 * Border, WindowWidth(0) - 2 * Border, WindowHeight(0) - 6 * Border, #PB_Canvas_Border)





Procedure Redraw()
  ; One simple line of code to redraw a new barcode to CanvasGadget!
  DrawBarcodeToCanvasGadgetFast(GetGadgetText(0), GetGadgetState(1), 2)
EndProcedure

Procedure TryExport()
  Static LastFile.s = ""
  If (LastFile = "")
    LastFile = GetCurrentDirectory()
  EndIf
  Protected File.s = SaveFileRequester("Export Image", LastFile, "BMP File|*.bmp", 0)
  If (File)
    If (GetExtensionPart(File) = "")
      File + ".bmp"
    EndIf
    LastFile = File
    Protected Width.i  = 720
    Protected Height.i = 480
    If (ExportBarcodeImageFileFast(File, GetGadgetText(0), GetGadgetState(1), Width, Height))
      If (#True)
        RunProgram(File)
      EndIf
    Else
      MessageRequester("Error", "Failed to export " + Str(Width) + "x" + Str(Height) + " barcode image file!", #PB_MessageRequester_Warning)
    EndIf
  EndIf
EndProcedure



; Bind keyboard, gadget, mouse events...

AddKeyboardShortcut(0, #PB_Shortcut_Escape, 0)
AddKeyboardShortcut(0, #PB_Shortcut_W | #PB_Shortcut_Command, 0)
AddKeyboardShortcut(0, #PB_Shortcut_Q | #PB_Shortcut_Command, 0)
AddKeyboardShortcut(0, #PB_Shortcut_Return, 1)
AddKeyboardShortcut(0, #PB_Shortcut_S | #PB_Shortcut_Command, 1)
BindEvent(#PB_Event_Menu, @TryExport(), 0, 1)

BindGadgetEvent(0, @Redraw(), #PB_EventType_Change)
BindGadgetEvent(1, @Redraw(), #PB_EventType_Change)

BindGadgetEvent(2, @TryExport(), #PB_EventType_RightClick)


; Final window prep

Redraw()
CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  SendMessage_(GadgetID(0), #EM_SETSEL, 0, -1)
CompilerEndIf
SetActiveGadget(0)
HideWindow(0, #False)

Repeat
  Event = WaitWindowEvent()
  If (Event = #PB_Event_CloseWindow) Or ((Event = #PB_Event_Menu) And (EventMenu() = 0))
    Done = #True
  EndIf
Until Done

CompilerEndIf
CompilerEndIf
;-
