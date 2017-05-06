; +--------------+
; | RatingGadget |
; +--------------+
; | 2016.01.09 . Rewrite (PureBasic 5.41)
; |        .11 . All attributes now support #PB_Default
; |     .02.26 . Added ReadOnly creation flag, and SetReadOnly() macro

; Default star images by FatCow
;   http://www.fatcow.com/free-icons


CompilerIf (Not Defined(__RatingGadget_Included, #PB_Constant))
#__RatingGadget_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;-
;- Constants (Public)

; RatingGadget Image Constants
#RatingGadget_Default = #PB_Default
#RatingGadget_None    = #RatingGadget_Default - 1

Enumeration ; RatingGadget Creation Flags
  #RatingGadget_Border       = $01
  #RatingGadget_NoRightClick = $02
  #RatingGadget_ReadOnly     = $04
EndEnumeration

; Define #RatingGadget_DisablePNGDecoder to #True (before including this file)
; to disable the UsePNGImageDecoder() call.
CompilerIf (Not Defined(RatingGadget_DisablePNGDecoder, #PB_Constant))
  #RatingGadget_DisablePNGDecoder = #False
CompilerEndIf

; Define #RatingGadget_DisableDefaultImages to #True (before including this file)
; to disable the default star images from the build.
CompilerIf (Not Defined(RatingGadget_DisableDefaultImages, #PB_Constant))
  #RatingGadget_DisableDefaultImages = #False
CompilerEndIf

;-
;- Constants (Private)

Enumeration ; Internal Flags
  #_RG_MouseOver = $01 << 16
  #_RG_MouseDown = $02 << 16
  #_RG_Drawing   = $04 << 16
EndEnumeration

Enumeration ; Dynamic Attributes
  #_RG_State    = $01
  #_RG_OffImage = $02
  #_RG_OnImage  = $03
  #_RG_Color    = $04
  #_RG_Maximum  = $05
  #_RG_ReadOnly = $06
EndEnumeration


;-
;- Structures (Private)

Structure _RatingGadget
  Gadget.i
  State.i
  Maximum.i
  Flags.i
  HoverItem.i
  DrawItem.i
  OffImage.i
  OnImage.i
  ItemWidth.i
  ItemHeight.i
  TotalWidth.i
  TotalHeight.i
  Window.i
  Background.i
EndStructure


;-
;- Globals (Private)

CompilerIf (Not #RatingGadget_DisablePNGDecoder)
  UsePNGImageDecoder()
CompilerEndIf
Global _RG_DefaultOffImage.i = CatchImage(#PB_Any, ?_RG_StarOff_Start, ?_RG_StarOff_End - ?_RG_StarOff_Start)
If (Not _RG_DefaultOffImage)
  _RG_DefaultOffImage = #RatingGadget_None
EndIf
Global _RG_DefaultOnImage.i  = CatchImage(#PB_Any, ?_RG_StarOn_Start, ?_RG_StarOn_End - ?_RG_StarOn_Start)
If (Not _RG_DefaultOnImage)
  _RG_DefaultOnImage = #RatingGadget_None
EndIf

;-
;- Macros (Public)

Macro RatingGadget_Bind(Gadget, Callback)
  BindGadgetEvent((Gadget), (Callback), #PB_EventType_Change)
EndMacro

Macro RatingGadget_SetState(Gadget, State)
  _RG_Set((Gadget), #_RG_State, (State))
EndMacro
Macro RatingGadget_SetColor(Gadget, Color)
  _RG_Set((Gadget), #_RG_Color, (Color))
EndMacro
Macro RatingGadget_SetOnImage(Gadget, Image)
  _RG_Set((Gadget), #_RG_OnImage, (Image))
EndMacro
Macro RatingGadget_SetOffImage(Gadget, Image)
  _RG_Set((Gadget), #_RG_OffImage, (Image))
EndMacro
Macro RatingGadget_SetMaximum(Gadget, Maximum)
  _RG_Set((Gadget), #_RG_Maximum, (Maximum))
EndMacro
Macro RatingGadget_SetReadOnly(Gadget, State)
  _RG_Set((Gadget), #_RG_ReadOnly, (State))
EndMacro

Macro RatingGadget_GetState(Gadget)
  _RG_Get((Gadget), #_RG_State)
EndMacro
Macro RatingGadget_GetMaximum(Gadget)
  _RG_Get((Gadget), #_RG_Maximum)
EndMacro


;-
;- Procedures (Private)

Procedure _RG_UpdateSizes(*RG._RatingGadget)
  With *RG
    If (\Maximum < 1)
      \Maximum = 1
    EndIf
    \ItemWidth = 1
    If (IsImage(\OffImage) And (ImageWidth(\OffImage) > \ItemWidth))
      \ItemWidth = ImageWidth(\OffImage)
    EndIf
    If (IsImage(\OnImage) And (ImageWidth(\OnImage) > \ItemWidth))
      \ItemWidth = ImageWidth(\OnImage)
    EndIf
    \ItemHeight = 1
    If (IsImage(\OffImage) And (ImageHeight(\OffImage) > \ItemHeight))
      \ItemHeight = ImageHeight(\OffImage)
    EndIf
    If (IsImage(\OnImage) And (ImageHeight(\OnImage) > \ItemHeight))
      \ItemHeight = ImageHeight(\OnImage)
    EndIf
    \TotalWidth  = \Maximum * \ItemWidth
    \TotalHeight = \ItemHeight
  EndWith
EndProcedure

Procedure _RG_Redraw(*RG._RatingGadget)
  With *RG
    If (Not (\Flags & #_RG_Drawing))
      If (StartDrawing(CanvasOutput(\Gadget)))
        \Flags | #_RG_Drawing
        Box(0, 0, OutputWidth(), OutputHeight(), \Background)
        DrawingMode(#PB_2DDrawing_AlphaBlend)
        Protected i.i
        If ((\OnImage <> #RatingGadget_None) And (\DrawItem > 0))
          For i = 1 To \DrawItem
            DrawImage(ImageID(\OnImage), (OutputWidth() - \TotalWidth)/2 + (i-1) * \ItemWidth, (OutputHeight() - \TotalHeight)/2)
          Next i
        EndIf
        If ((\OffImage <> #RatingGadget_None) And (\DrawItem < \Maximum))
          For i = \DrawItem + 1 To \Maximum
            DrawImage(ImageID(\OffImage), (OutputWidth() - \TotalWidth)/2 + (i-1) * \ItemWidth, (OutputHeight() - \TotalHeight)/2)
          Next i
        EndIf
        StopDrawing()
        \Flags & ~#_RG_Drawing
      EndIf
    EndIf
  EndWith
EndProcedure

Procedure _RG_HandleEvent(Gadget.i, Type.i, Window.i = -1)
  Protected *RG._RatingGadget
  *RG = GetGadgetData(Gadget)
  If (*RG)
    If ((*RG\Window = -1) And (Window <> -1))
      *RG\Window = Window
    EndIf
    Protected NewHover.i = *RG\HoverItem
    Protected NewDraw.i  = *RG\DrawItem
    Protected x0.i, y0.i
    Protected x.i, y.i
    Select (Type)
      Case #PB_EventType_MouseMove
        x = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX)
        y = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
        x0 = GadgetWidth(Gadget)/2  - *RG\TotalWidth/2
        y0 = GadgetHeight(Gadget)/2 - *RG\TotalHeight/2
        If (((x >= x0) And (y >= y0)) And
            (x < x0 + *RG\TotalWidth) And
            (y < y0 + *RG\TotalHeight) And
            (Not (*RG\Flags & #RatingGadget_ReadOnly)))
          *RG\Flags | #_RG_MouseOver
          NewHover = (x - x0) / *RG\ItemWidth + 1
          If (NewHover <> *RG\HoverItem)
            *RG\HoverItem = NewHover
            NewDraw = NewHover
          EndIf
        Else
          _RG_HandleEvent(Gadget, #PB_EventType_MouseLeave, Window)
          NewDraw = *RG\DrawItem
        EndIf
      Case #PB_EventType_MouseLeave
        *RG\Flags & ~(#_RG_MouseOver | #_RG_MouseDown)
        *RG\HoverItem = #RatingGadget_None
        NewDraw = *RG\State
      Case #PB_EventType_LeftButtonDown
        If ((*RG\Flags & #_RG_MouseOver) And (Not (*RG\Flags & #RatingGadget_ReadOnly)))
          *RG\Flags | #_RG_MouseDown
        EndIf
      Case #PB_EventType_LeftButtonUp
        If (*RG\Flags & #_RG_MouseDown)
          *RG\Flags & ~#_RG_MouseDown
          *RG\State = *RG\HoverItem
          NewDraw = *RG\State
          If (*RG\Window <> -1)
            PostEvent(#PB_Event_Gadget, *RG\Window, Gadget, #PB_EventType_Change, *RG\State)
          EndIf
        EndIf
      Case #PB_EventType_RightButtonDown
        If ((Not (*RG\Flags & #RatingGadget_NoRightClick)) And (Not (*RG\Flags & #RatingGadget_ReadOnly)))
          If (*RG\Flags & #_RG_MouseOver)
            *RG\State = 0
            NewDraw = 0
            If (*RG\Window <> -1)
              PostEvent(#PB_Event_Gadget, *RG\Window, Gadget, #PB_EventType_Change, *RG\State)
            EndIf
          EndIf
        EndIf
    EndSelect
    If (NewDraw <> *RG\DrawItem)
      *RG\DrawItem = NewDraw
      _RG_Redraw(*RG)
    EndIf
  EndIf
EndProcedure

Procedure _RG_Callback()
  _RG_HandleEvent(EventGadget(), EventType(), EventWindow())
EndProcedure

Procedure.i _RG_Default(Attribute.i)
  Protected Result.i = #Null
  Select (Attribute)
    Case #_RG_State
      Result = 0
    Case #_RG_OffImage
      Result = _RG_DefaultOffImage
    Case #_RG_OnImage
      Result = _RG_DefaultOnImage
    Case #_RG_Color
      CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
        Result = GetSysColor_(#COLOR_3DFACE)
      CompilerElse
        Result = $EAEAEA
      CompilerEndIf
    Case #_RG_Maximum
      Result = 5
    Case #_RG_ReadOnly
      Result = #False
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure _RG_Set(Gadget.i, Attribute.i, Value.i)
  If (IsGadget(Gadget))
    Protected *RG._RatingGadget
    *RG = GetGadgetData(Gadget)
    If (*RG)
      Select (Attribute)
        Case #_RG_State
          If (Value < 1)
            *RG\State = 0
          ElseIf (Value > *RG\Maximum)
            *RG\State = *RG\Maximum
          Else
            *RG\State = Value
          EndIf
          *RG\DrawItem = *RG\State
          _RG_Redraw(*RG)
        Case #_RG_Color
          If (Value = #PB_Default)
            *RG\Background = _RG_Default(#_RG_Color)
          Else
            *RG\Background = Value & $FFFFFF
          EndIf
          _RG_Redraw(*RG)
        Case #_RG_OnImage
          If (Value = #RatingGadget_Default)
            *RG\OnImage = _RG_Default(#_RG_OnImage)
          Else
            *RG\OnImage = Value
          EndIf
          _RG_UpdateSizes(*RG)
          _RG_Redraw(*RG)
        Case #_RG_OffImage
          If (Value = #RatingGadget_Default)
            *RG\OffImage = _RG_Default(#_RG_OffImage)
          Else
            *RG\OffImage = Value
          EndIf
          _RG_UpdateSizes(*RG)
          _RG_Redraw(*RG)
        Case #_RG_Maximum
          If (Value = #PB_Default)
            *RG\Maximum = _RG_Default(#_RG_Maximum)
          Else
            *RG\Maximum = Value
          EndIf
          _RG_UpdateSizes(*RG)
          _RG_Set(Gadget, #_RG_State, *RG\State)
        Case #_RG_ReadOnly
          If (Value = #PB_Default)
            Value = _RG_Default(#_RG_ReadOnly)
          EndIf
          If (Value)
            *RG\Flags | #RatingGadget_ReadOnly
            _RG_HandleEvent(*RG\Gadget, #PB_EventType_MouseLeave, *RG\Window)
          Else
            *RG\Flags & ~#RatingGadget_ReadOnly
          EndIf
          _RG_Redraw(*RG)
      EndSelect
    EndIf
  EndIf
EndProcedure

Procedure.i _RG_Get(Gadget.i, Attribute.i)
  Protected Result.i = #Null
  If (IsGadget(Gadget))
    Protected *RG._RatingGadget
    *RG = GetGadgetData(Gadget)
    If (*RG)
      Select (Attribute)
        Case #_RG_State
          Result = *RG\State
        Case #_RG_Color
          Result = *RG\Background
        Case #_RG_Maximum
          Result = *RG\Maximum
      EndSelect
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- Procedures (Public)

Procedure.i RatingGadget(Gadget.i, x.i, y.i, Width.i, Height.i, Flags.i = #PB_Default, Callback.i = #Null)
  Protected Result.i
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  Protected CanvasFlags.i
  If (Flags & #RatingGadget_Border)
    CanvasFlags | #PB_Canvas_Border
  EndIf
  Result = CanvasGadget(Gadget, x, y, Width, Height, CanvasFlags)
  If (Result)
    If (Gadget = #PB_Any)
      Gadget = Result
    EndIf
    Protected *RG._RatingGadget
    *RG = AllocateMemory(SizeOf(_RatingGadget))
    If (*RG)
      *RG\Gadget     =  Gadget
      *RG\Flags      =  Flags
      *RG\Window     = -1
      *RG\State      = _RG_Default(#_RG_State)
      *RG\OffImage   = _RG_Default(#_RG_OffImage)
      *RG\OnImage    = _RG_Default(#_RG_OnImage)
      *RG\Background = _RG_Default(#_RG_Color)
      *RG\Maximum    = _RG_Default(#_RG_Maximum)
      _RG_UpdateSizes(*RG)
      SetGadgetData(Gadget, *RG)
      _RG_Redraw(*RG)
      BindGadgetEvent(Gadget, @_RG_Callback())
    Else
      FreeGadget(Gadget)
      Result = #Null
    EndIf
  EndIf
  If (Result And Callback)
    RatingGadget_Bind(Gadget, Callback)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i RatingGadget_Free(Gadget.i)
  If (IsGadget(Gadget))
    Protected *RG._RatingGadget
    *RG = GetGadgetData(Gadget)
    If (*RG)
      SetGadgetData(Gadget, #Null)
      FreeMemory(*RG)
    EndIf
    FreeGadget(Gadget)
  EndIf
  ProcedureReturn (#Null)
EndProcedure


;-
;- Data Section

DataSection
  _RG_StarOff_Start:
  CompilerIf (Not #RatingGadget_DisableDefaultImages)
    Data.b $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52
    Data.b $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF
    Data.b $61, $00, $00, $00, $06, $62, $4B, $47, $44, $00, $FF, $00, $FF, $00, $FF, $A0
    Data.b $BD, $A7, $93, $00, $00, $00, $09, $70, $48, $59, $73, $00, $00, $0B, $13, $00
    Data.b $00, $0B, $13, $01, $00, $9A, $9C, $18, $00, $00, $00, $07, $74, $49, $4D, $45
    Data.b $07, $E0, $01, $09, $16, $32, $07, $F1, $47, $C9, $08, $00, $00, $02, $14, $49
    Data.b $44, $41, $54, $38, $CB, $95, $93, $4F, $4B, $1B, $51, $14, $C5, $7F, $33, $26
    Data.b $44, $A6, $58, $C2, $68, $34, $B8, $50, $DB, $B4, $AE, $82, $16, $0A, $A2, $4B
    Data.b $41, $BA, $14, $EC, $52, $21, $DB, $2E, $06, $12, $F2, $05, $04, $BF, $81, $E3
    Data.b $40, $92, $6D, $BB, $CB, $07, $70, $D3, $55, $F6, $52, $B0, $81, $80, $92, $90
    Data.b $92, $3F, $64, $53, $99, $48, $04, $C3, $24, $BE, $FB, $BA, $31, $A5, $29, $1D
    Data.b $A9, $07, $2E, $EF, $F1, $EE, $BD, $87, $CB, $39, $F7, $A1, $B5, $26, $0C, $C5
    Data.b $62, $F1, $53, $B1, $58, $74, $C3, $F2, $5A, $6B, $22, $3C, $81, $B5, $B5, $B5
    Data.b $82, $52, $CA, $04, $72, $61, $35, $66, $58, $C2, $F3, $BC, $93, $54, $2A, $65
    Data.b $AE, $AF, $AF, $E3, $79, $DE, $C9, $B3, $08, $0A, $85, $82, $65, $59, $D6, $B1
    Data.b $6D, $DB, $D8, $B6, $8D, $65, $59, $C7, $CF, $22, $78, $78, $78, $28, $A5, $D3
    Data.b $69, $DA, $ED, $36, $ED, $76, $9B, $74, $3A, $8D, $E7, $79, $9F, $FF, $55, $1B
    Data.b $01, $28, $95, $4A, $5F, $94, $52, $1B, $22, $B2, $29, $22, $44, $A3, $51, $6C
    Data.b $DB, $A6, $D7, $EB, $01, $B0, $BC, $BC, $4C, $24, $12, $C9, $9C, $9D, $9D, $65
    Data.b $0C, $C3, $60, $66, $66, $E6, $BB, $69, $9A, $55, $20, $13, $01, $10, $91, $8F
    Data.b $3B, $3B, $3B, $2F, $56, $57, $57, $51, $4A, $11, $8B, $C5, $B8, $BA, $BA, $42
    Data.b $29, $05, $80, $EF, $FB, $1C, $1E, $1E, $12, $04, $01, $22, $42, $A3, $D1, $D8
    Data.b $AC, $56, $AB, $6F, $80, $8C, $A1, $B5, $C6, $30, $8C, $77, $AE, $EB, $7E, $5D
    Data.b $59, $59, $49, $CC, $CD, $CD, $31, $B1, $D6, $30, $8C, $DF, $76, $01, $98, $A6
    Data.b $C9, $60, $30, $A0, $D3, $E9, $FC, $CC, $66, $B3, $1F, $B4, $D6, $97, $13, $0D
    Data.b $2E, $73, $B9, $DC, $5E, $AD, $56, $3B, $BF, $BB, $BB, $23, $1E, $8F, $23, $22
    Data.b $53, $11, $8F, $C7, $E9, $F7, $FB, $D4, $6A, $B5, $F3, $6C, $36, $BB, $07, $5C
    Data.b $02, $4C, $26, $00, $20, $1A, $8D, $BE, $2A, $97, $CB, $CD, $54, $2A, $45, $AF
    Data.b $D7, $9B, $9A, $20, $99, $4C, $52, $AF, $D7, $39, $3A, $3A, $7A, $3D, $1E, $8F
    Data.b $7F, $4C, $DE, $A7, $5C, $38, $3D, $3D, $DD, $4E, $24, $12, $DC, $DC, $DC, $20
    Data.b $22, $68, $AD, $D1, $5A, $23, $22, $F4, $FB, $7D, $16, $16, $16, $70, $5D, $77
    Data.b $3B, $D4, $C6, $F1, $78, $BC, $1B, $8B, $C5, $18, $0E, $87, $04, $41, $40, $B7
    Data.b $DB, $A5, $DB, $ED, $12, $04, $01, $F7, $F7, $F7, $CC, $CE, $CE, $32, $1C, $0E
    Data.b $77, $43, $09, $16, $17, $17, $F7, $6F, $6F, $6F, $F1, $7D, $9F, $56, $AB, $75
    Data.b $ED, $38, $CE, $96, $E3, $38, $5B, $AD, $56, $EB, $DA, $F7, $7D, $82, $20, $60
    Data.b $7E, $7E, $7E, $3F, $94, $40, $29, $B5, $D4, $6C, $36, $A5, $52, $A9, $38, $F9
    Data.b $7C, $FE, $60, $34, $1A, $5D, $8C, $46, $A3, $8B, $7C, $3E, $7F, $50, $A9, $54
    Data.b $9C, $46, $A3, $21, $22, $B2, $F4, $67, $CF, $94, $88, $C0, $FB, $C7, $B3, $0E
    Data.b $0C, $FE, $5A, $BA, $97, $C0, $DB, $C7, $FB, $B7, $89, $88, $C6, $53, $DF, $F9
    Data.b $7F, $F0, $0B, $DB, $C0, $0C, $E4, $92, $AD, $2F, $68, $00, $00, $00, $00, $49
    Data.b $45, $4E, $44, $AE, $42, $60, $82
  CompilerElse
    Data.b #NUL
  CompilerEndIf
  _RG_StarOff_End:
  
  _RG_StarOn_Start:
  CompilerIf (Not #RatingGadget_DisableDefaultImages)
    Data.b $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52
    Data.b $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF
    Data.b $61, $00, $00, $00, $19, $74, $45, $58, $74, $53, $6F, $66, $74, $77, $61, $72
    Data.b $65, $00, $41, $64, $6F, $62, $65, $20, $49, $6D, $61, $67, $65, $52, $65, $61
    Data.b $64, $79, $71, $C9, $65, $3C, $00, $00, $02, $05, $49, $44, $41, $54, $78, $DA
    Data.b $A4, $53, $CF, $4B, $54, $51, $14, $FE, $EE, $7D, $D3, $73, $1C, $19, $0D, $6C
    Data.b $6C, $B0, $A9, $08, $9A, $21, $5D, $64, $31, $69, $83, $42, $20, $49, $B4, $10
    Data.b $89, $96, $2D, $86, $08, $86, $7E, $40, $7F, $80, $1B, $A1, $3F, $A1, $5D, $26
    Data.b $52, $59, $B4, $68, $D5, $C6, $8D, $2D, $5A, $14, $0C, $24, $81, $63, $52, $54
    Data.b $1A, $A1, $92, $4C, $2F, $B5, $86, $99, $A6, $B1, $FB, $CE, $ED, $DC, $E7, $0C
    Data.b $A8, $CD, $13, $A2, $0B, $DF, $7B, $DF, $BD, $F7, $3B, $DF, $3D, $F7, $9C, $F7
    Data.b $A0, $B5, $86, $DF, $F8, $7A, $BF, $F7, $2A, $E3, $B6, $DF, $BE, $17, $BB, $9B
    Data.b $41, $29, $7B, $DD, $2D, $BE, $CC, $E8, $DD, $0C, $A4, $DF, $66, $7E, $3C, $79
    Data.b $CB, $8E, $9D, $97, $0D, $87, $07, $3D, $EE, $A7, $93, $F5, $53, $4F, $85, $64
    Data.b $63, $EB, $48, $60, $7F, $3B, $0C, $0C, $FF, $27, $03, $57, $A9, $3B, $A1, $CE
    Data.b $0B, $A0, $B5, $67, $1E, $0C, $CF, $8F, $9F, $7A, $50, $4F, $1B, $30, $0F, $67
    Data.b $A2, $6F, $42, $BB, $EA, $B8, $26, $D5, $05, $72, $79, $35, $08, $3B, $1A, $05
    Data.b $FD, $7C, $E3, $89, $EC, $E8, $31, $C0, $0A, $A6, $F3, $63, $27, $D3, $90, $16
    Data.b $84, $0C, $E4, $84, $65, $CD, $F2, $56, $DA, $33, $20, $A2, $8B, $2D, $7D, $57
    Data.b $9A, $1A, $8E, $24, $C1, $46, $9C, $57, $2B, $68, $E5, $11, $48, $D1, $66, $9A
    Data.b $95, $1C, $22, $97, $EE, $B1, $70, $15, $02, $15, $FC, $5A, $78, $DE, $55, $98
    Data.b $9E, $3A, $6A, $0C, $84, $A9, $A4, $10, $E2, $C4, $F2, $58, $F7, $D4, $DE, $CE
    Data.b $43, $11, $7B, $5F, $0B, $34, $71, $A0, $E6, $DB, $09, $AB, $5A, $6E, $CE, $4A
    Data.b $10, $4F, $25, $36, $9C, $02, $7E, $BC, $5D, $74, $0E, $64, $5E, $9D, $E3, $D8
    Data.b $99, $5A, $0D, $66, $62, $99, $E9, $81, $F9, $EC, $A7, $49, $23, $90, $8D, $09
    Data.b $6E, $91, $CB, $46, $6A, $13, $CC, $65, $28, $81, $CA, $CA, $3A, $E6, $B3, $0B
    Data.b $93, $1C, $3C, $60, $62, $76, $16, $71, $F6, $F4, $70, $EE, $26, $FD, $E6, $5B
    Data.b $59, $CD, $7C, $28, $6D, $87, $68, $02, $95, $2D, $18, $8D, $D1, $D6, $ED, $C2
    Data.b $D2, $68, $77, $6A, $4F, $5B, $1C, $AA, $F0, $8E, $4F, $76, $4D, $75, $3C, $18
    Data.b $4E, $C5, $0F, $08, $44, $E2, $58, $BA, $DB, $93, $F2, $6D, $63, $49, $A1, $5F
    Data.b $86, $82, $D0, $1B, $0E, $07, $94, $51, $9A, $5B, $F4, $60, $38, $55, $1C, $58
    Data.b $61, $1B, $C5, $B2, $EA, $F7, $35, $08, $B7, $C7, $86, $A8, $F8, $19, $95, $E5
    Data.b $75, $38, $73, $5F, $DE, $1F, $BC, $FC, $A2, $C7, $C0, $70, $B3, $A6, $D5, $77
    Data.b $84, $23, $6D, $43, $7F, $FF, $10, $D5, $B1, $F6, $74, $50, $3B, $0F, $7B, $DD
    Data.b $D1, $6B, $89, $1B, $3C, $ED, $D8, $22, $EB, $30, $6B, $DF, $1E, $9F, $71, $57
    Data.b $9F, $9C, $D5, $5B, $63, $6B, $6D, $AC, $AD, $25, $AB, $EF, $8F, $8C, $C2, $8E
    Data.b $8F, $AE, $99, $11, $AF, $F2, $D7, $DB, $0C, $FE, $67, $FC, $11, $60, $00, $31
    Data.b $FF, $02, $B9, $6F, $7D, $8E, $AD, $00, $00, $00, $00, $49, $45, $4E, $44, $AE
    Data.b $42, $60, $82
  CompilerElse
    Data.b #NUL
  CompilerEndIf
  _RG_StarOn_End:
EndDataSection



;-
;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  Procedure ChangeCallback()
    AddGadgetItem(9, 0,  "#" + Str(EventGadget()) + "  -->  " + Str(EventData()) + " / " + Str(RatingGadget_GetMaximum(EventGadget())))
  EndProcedure
  
  OpenWindow(0, 0, 0, 320, 240, "RatingGadget Demo", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
  EditorGadget(9, 160, 10, 150, 220)
  
  ; Example gadget #0
  RatingGadget(0, 10, 10, 120, 30, #PB_Default, @ChangeCallback())
  
  ; Example gadget #1
  RatingGadget(1, 10, 50, 120, 30, #RatingGadget_Border | #RatingGadget_NoRightClick)
  RatingGadget_SetState(1, 3)
  RatingGadget_SetColor(1, $FFFFFF)
  RatingGadget_Bind(1, @ChangeCallback())
  
  ; Example gadget #2
  RatingGadget(2, 10, 90, 120, 30, #Null, @ChangeCallback())
  RatingGadget_SetState(2, 1)
  RatingGadget_SetColor(2, $20A020)
  RatingGadget_SetOnImage(2, CreateImage(#PB_Any, 16, 16, 32, $00FF00))
  RatingGadget_SetOffImage(2, #RatingGadget_None)
  RatingGadget_SetMaximum(2, 3)
  GadgetToolTip(2, "Custom 'on' image, no 'off' image")
  
  ; Example gadget #3
  RatingGadget(3, 10, 130, 120, 30, #RatingGadget_ReadOnly)
  RatingGadget_SetState(3, 4)
  GadgetToolTip(3, "ReadOnly, no events")
  
  Repeat
    ;
    ; If you don't want to use the Bind event method,
    ; you can also watch for #PB_Event_Gadget/#PB_EventType_Change window events.
    ;
  Until (WaitWindowEvent() = #PB_Event_CloseWindow)
  For i = 0 To 3
    RatingGadget_Free(i)
  Next i
  
CompilerEndIf
CompilerEndIf
;-