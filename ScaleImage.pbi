; +------------+
; | ScaleImage |
; +------------+
; | 2017.01.24 . Creation (PureBasic 5.51)
; |        .25 . Added "Tile" mode, alignment flags, realtime demo
; |        .30 . Bypass same-size resizes, added FitIfLarger, FitOrCenter
; |        .31 . Fixed demo ghosting with alpha (Canvas instead of ImgGad),
; |                fixed tile offset, FitIfLarger, FitOrCenter


;-
CompilerIf (Not Defined(__ScaleImage_Included, #PB_Constant))
#__ScaleImage_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Constants (Public)

Enumeration
  #ScaleImage_Smooth = #PB_Image_Smooth ; (default)
  #ScaleImage_Raw    = #PB_Image_Raw
  ;
  #ScaleImage_Stretch     = $0000 ; (default)
  #ScaleImage_Fill        = $0100
  #ScaleImage_Fit         = $0200
  #ScaleImage_FitIfLarger = $0400
  #ScaleImage_FitOrCenter = $0800
  #ScaleImage_Tile        = $1000
  #ScaleImage_Center      = $2000
  ;
  #ScaleImage_Top     = $010000
  #ScaleImage_Bottom  = $020000
  #ScaleImage_Left    = $040000
  #ScaleImage_Right   = $080000
  ;
  #ScaleImage_TopLeft      = #ScaleImage_Top    | #ScaleImage_Left
  #ScaleImage_TopMiddle    = #ScaleImage_Top
  #ScaleImage_TopRight     = #ScaleImage_Top    | #ScaleImage_Right
  #ScaleImage_MiddleLeft   = #ScaleImage_Left
  #ScaleImage_Middle       = #Null
  #ScaleImage_MiddleRight  = #ScaleImage_Right
  #ScaleImage_BottomLeft   = #ScaleImage_Bottom | #ScaleImage_Left
  #ScaleImage_BottomMiddle = #ScaleImage_Bottom
  #ScaleImage_BottomRight  = #ScaleImage_Bottom | #ScaleImage_Right
  ;
  #ScaleImage_Default = #PB_Default
  #ScaleImage_Ignore  = #PB_Ignore
EndEnumeration


;-
;- Constants (Private)

#__ScaleImage_BorderColorDefault = $000000
#__ScaleImage_JPEGQualityDefault =  7




;-
;- Variables (Private)

Global __ScaleImage_BorderColor.i = #__ScaleImage_BorderColorDefault
Global __ScaleImage_JPEGQuality.i = #__ScaleImage_JPEGQualityDefault





;-
;- Macros (Private)

Macro __ScaleImage_Round(Number)
  Round(1.0 * Number, #PB_Round_Nearest)
EndMacro







;-
;- Procedures (Public)

Procedure.i ScaleImage(Image.i, Width.i, Height.i, Flags.i = #PB_Default, NewImage.i = #PB_Ignore)
  Protected Result.i = #Null
  
  Protected DestImage.i = #PB_Any
  If (NewImage = #PB_Any)
    NewImage = CopyImage(Image, #PB_Any)
    If (NewImage)
      DestImage = NewImage
      Result    = NewImage
    EndIf
  ElseIf (NewImage <> #PB_Ignore)
    If (CopyImage(Image, NewImage))
      DestImage = NewImage
      Result    = ImageID(NewImage)
    EndIf
  Else
    DestImage = Image
    Result    = ImageID(Image)
  EndIf
  
  If (DestImage <> #PB_Any)
    Protected SrcWidth.i  = ImageWidth(Image)
    Protected SrcHeight.i = ImageHeight(Image)
    If (Flags = #PB_Default)
      Flags = #ScaleImage_Smooth
    EndIf
    Protected Mode.i
    If (Flags & #ScaleImage_Raw)
      Mode = #PB_Image_Raw
    Else
      Mode = #PB_Image_Smooth
    EndIf
    
    Protected TempImage.i, TempWidth.i, TempHeight.i
    Protected dx.i, dy.i
    If (Not (Flags & #ScaleImage_Stretch))
      TempImage = CopyImage(Image, #PB_Any)
      If (Not TempImage)
        Result = #Null
      EndIf
    EndIf
    If (Result)
      
      If (Flags & #ScaleImage_Fill) ;- - Fill
        If ((Width <= 0) And (Height <= 0))
          Width  = SrcWidth
          Height = SrcHeight
        Else
          If (Width <= 0)
            Width = __ScaleImage_Round(SrcWidth * Height / SrcHeight)
          EndIf
          If (Height <= 0)
            Height = __ScaleImage_Round(SrcHeight * Width / SrcWidth)
          EndIf
        EndIf
        If ((Width <> SrcWidth) Or (Height <> SrcHeight) Or (DestImage <> Image))
          If (1.0 * Width / SrcWidth > 1.0 * Height / SrcHeight)
            TempWidth  = Width
            TempHeight = __ScaleImage_Round(SrcHeight * Width / SrcWidth)
          Else
            TempWidth  = __ScaleImage_Round(SrcWidth * Height / SrcHeight)
            TempHeight = Height
          EndIf
          If (ResizeImage(TempImage, TempWidth, TempHeight, Mode))
            If (ResizeImage(DestImage, Width, Height, #PB_Image_Raw))
              If (StartDrawing(ImageOutput(DestImage)))
                DrawingMode(#PB_2DDrawing_AllChannels)
                If (Flags & #ScaleImage_Left)
                  dx = 0
                ElseIf (Flags & #ScaleImage_Right)
                  dx = (Width - TempWidth)
                Else
                  dx = (Width - TempWidth)/2
                EndIf
                If (Flags & #ScaleImage_Top)
                  dy = 0
                ElseIf (Flags & #ScaleImage_Bottom)
                  dy = (Height - TempHeight)
                Else
                  dy = (Height - TempHeight)/2
                EndIf
                DrawImage(ImageID(TempImage), dx, dy)
                StopDrawing()
              Else
                Result = #Null
              EndIf
            Else
              Result = #Null
            EndIf
          Else
            Result = #Null
          EndIf
        EndIf
        
      ElseIf (Flags & (#ScaleImage_Fit | #ScaleImage_FitIfLarger | #ScaleImage_FitOrCenter)) ;- - Fit
        If ((Width <= 0) And (Height <= 0))
          Width  = SrcWidth
          Height = SrcHeight
        Else
          If (Width <= 0)
            Width = __ScaleImage_Round(SrcWidth * Height / SrcHeight)
          EndIf
          If (Height <= 0)
            Height = __ScaleImage_Round(SrcHeight * Width / SrcWidth)
          EndIf
        EndIf
        If ((Width <> SrcWidth) Or (Height <> SrcHeight) Or (DestImage <> Image))
          If (1.0 * Width / SrcWidth < 1.0 * Height / SrcHeight)
            TempWidth  = Width
            TempHeight = __ScaleImage_Round(SrcHeight * Width / SrcWidth)
            If ((Flags & (#ScaleImage_FitIfLarger | #ScaleImage_FitOrCenter)) And (TempWidth > SrcWidth))
              TempWidth  = SrcWidth
              TempHeight = SrcHeight
            EndIf
          Else
            TempWidth  = __ScaleImage_Round(SrcWidth * Height / SrcHeight)
            TempHeight = Height
            If ((Flags & (#ScaleImage_FitIfLarger | #ScaleImage_FitOrCenter)) And (TempHeight > SrcHeight))
              TempWidth  = SrcWidth
              TempHeight = SrcHeight
            EndIf
          EndIf
          If (Flags & #ScaleImage_FitIfLarger)
            Width  = TempWidth
            Height = TempHeight
          EndIf
          If (ResizeImage(TempImage, TempWidth, TempHeight, Mode))
            If (ResizeImage(DestImage, Width, Height, #PB_Image_Raw))
              If (StartDrawing(ImageOutput(DestImage)))
                DrawingMode(#PB_2DDrawing_AllChannels)
                If (Flags & #ScaleImage_Left)
                  dx = 0
                ElseIf (Flags & #ScaleImage_Right)
                  dx = (Width - TempWidth)
                Else
                  dx = (Width - TempWidth)/2
                EndIf
                If (Flags & #ScaleImage_Top)
                  dy = 0
                ElseIf (Flags & #ScaleImage_Bottom)
                  dy = (Height - TempHeight)
                Else
                  dy = (Height - TempHeight)/2
                EndIf
                Box(0, 0, Width, Height, __ScaleImage_BorderColor | $FF000000)
                DrawImage(ImageID(TempImage), dx, dy)
                StopDrawing()
              Else
                Result = #Null
              EndIf
            Else
              Result = #Null
            EndIf
          Else
            Result = #Null
          EndIf
        EndIf
        
      ElseIf (Flags & #ScaleImage_Tile) ;- - Tile
        If (Width <= 0)
          Width = SrcWidth
        EndIf
        If (Height <= 0)
          Height = SrcHeight
        EndIf
        If ((Width <> SrcWidth) Or (Height <> SrcHeight) Or (DestImage <> Image))
          If (ResizeImage(DestImage, Width, Height, #PB_Image_Raw))
            If (StartDrawing(ImageOutput(DestImage)))
              DrawingMode(#PB_2DDrawing_AllChannels)
              If (Flags & #ScaleImage_Left)
                dx = 0
              ElseIf (Flags & #ScaleImage_Right)
                dx = (Width % SrcWidth) - SrcWidth
              Else
                dx = (Width - SrcWidth)/2 - SrcWidth
              EndIf
              While (dx > 0)
                dx - SrcWidth
              Wend
              If (Flags & #ScaleImage_Top)
                dy = 0
              ElseIf (Flags & #ScaleImage_Bottom)
                dy = (Height % SrcHeight) - SrcHeight
              Else
                dy = (Height - SrcHeight)/2 - SrcHeight
              EndIf
              While (dy > 0)
                dy - SrcHeight
              Wend
              Protected gx.i, gy.i
              gy = dy
              While (gy < Height)
                gx = dx
                While (gx < Width)
                  DrawImage(ImageID(TempImage), gx, gy)
                  gx + SrcWidth
                Wend
                gy + SrcHeight
              Wend
              StopDrawing()
            Else
              Result = #Null
            EndIf
          Else
            Result = #Null
          EndIf
        EndIf
        
      ElseIf (Flags & #ScaleImage_Center) ;- - Center
        If (Width <= 0)
          Width = SrcWidth
        EndIf
        If (Height <= 0)
          Height = SrcHeight
        EndIf
        If ((Width <> SrcWidth) Or (Height <> SrcHeight) Or (DestImage <> Image))
          If (ResizeImage(DestImage, Width, Height, #PB_Image_Raw))
            If (StartDrawing(ImageOutput(DestImage)))
              DrawingMode(#PB_2DDrawing_AllChannels)
              Box(0, 0, Width, Height, __ScaleImage_BorderColor | $FF000000)
              If (Flags & #ScaleImage_Left)
                dx = 0
              ElseIf (Flags & #ScaleImage_Right)
                dx = (Width - SrcWidth)
              Else
                dx = (Width - SrcWidth)/2
              EndIf
              If (Flags & #ScaleImage_Top)
                dy = 0
              ElseIf (Flags & #ScaleImage_Bottom)
                dy = (Height - SrcHeight)
              Else
                dy = (Height - SrcHeight)/2
              EndIf
              DrawImage(ImageID(TempImage), dx, dy)
              StopDrawing()
            Else
              Result = #Null
            EndIf
          Else
            Result = #Null
          EndIf
        EndIf
        
      Else ;- - Stretch
        If (Width <= 0)
          Width = SrcWidth
        EndIf
        If (Height <= 0)
          Height = SrcHeight
        EndIf
        If ((Width <> SrcWidth) Or (Height <> SrcHeight))
          If (Not ResizeImage(DestImage, Width, Height, Mode))
            Result = #Null
          EndIf
        EndIf
      EndIf
      
    EndIf
    If (TempImage)
      FreeImage(TempImage)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ScaleImageFile(File.s, Width.i, Height.i, Flags.i = #PB_Default, NewFile.s = "")
  Protected Result.i = #False
  Protected TempImage.i = LoadImage(#PB_Any, File)
  If (TempImage)
    If (ScaleImage(TempImage, Width, Height, Flags))
      If (NewFile = "")
        NewFile = File
      EndIf
      Select (LCase(GetExtensionPart(NewFile)))
        Case "png"
          Result = Bool(SaveImage(TempImage, NewFile, #PB_ImagePlugin_PNG))
        Case "jpg", "jpeg"
          Result = Bool(SaveImage(TempImage, NewFile, #PB_ImagePlugin_JPEG, __ScaleImage_JPEGQuality))
        Case "jp2"
          Result = Bool(SaveImage(TempImage, NewFile, #PB_ImagePlugin_JPEG2000, __ScaleImage_JPEGQuality))
        Default
          Result = Bool(SaveImage(TempImage, NewFile, #PB_ImagePlugin_BMP))
      EndSelect
    EndIf
    FreeImage(TempImage)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SetScaleImageBorderColor(Color.i)
  Protected Result.i = __ScaleImage_BorderColor
  __ScaleImage_BorderColor = Color & $FFFFFFFF
  ProcedureReturn (Result)
EndProcedure

Procedure.i SetScaleImageJPEGQuality(Quality.i)
  Protected Result.i = __ScaleImage_JPEGQuality
  If ((Quality >= 0) And (Quality <= 10))
    __ScaleImage_JPEGQuality = Quality
  Else
    __ScaleImage_JPEGQuality = #__ScaleImage_JPEGQualityDefault
  EndIf
  ProcedureReturn (Result)
EndProcedure











;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Procedure.i DefaultGadgetHeight()
  Static Height.i = -1
  If (Height <= 0)
    Protected TempWin.i = OpenWindow(#PB_Any, 0, 0, 320, 240, "", #PB_Window_Invisible)
    If (TempWin)
      Protected TempGad.i = ButtonGadget(#PB_Any, 0, 0, WindowWidth(TempWin), WindowHeight(TempWin), "ABC123")
      If (TempGad)
        Height = GadgetHeight(TempGad, #PB_Gadget_RequiredSize)
        FreeGadget(TempGad)
      EndIf
      CloseWindow(TempWin)
    EndIf
    If (Height <= 0)
      Height = 20
    EndIf
  EndIf
  ProcedureReturn (Height)
EndProcedure

Procedure Redraw()
  Method = GetGadgetState(0)
  
  Select (Method)
    Case 0 : Flags = #ScaleImage_Stretch
    Default : Flags = #ScaleImage_Fill << (GetGadgetState(0) - 1)
  EndSelect
  
  DisableGadget(1, Bool((Flags = #ScaleImage_Center) Or (Flags = #ScaleImage_Tile)))
  DisableGadget(3, Bool((Flags = #ScaleImage_Stretch) Or (Flags = #ScaleImage_Fill) Or (Flags = #ScaleImage_Tile)))
  DisableGadget(4, Bool((Flags = #ScaleImage_Stretch)))
  
  Flags | (GetGadgetState(1) * #ScaleImage_Raw)
  Flags | GetGadgetItemData(4, GetGadgetState(4))
  
  If (ScaleImage(0, GadgetWidth(2), GadgetHeight(2), Flags, 1))
    If (Flags & #ScaleImage_FitIfLarger) ; Image may be smaller than gadget, so center it
      Flags - #ScaleImage_FitIfLarger
      Flags + #ScaleImage_Center
      ScaleImage(1, GadgetWidth(2), GadgetHeight(2), Flags)
    EndIf
    If (StartDrawing(CanvasOutput(2)))
      CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
        Background = GetSysColor_(#COLOR_3DFACE)
      CompilerElse
        Background = $FFFFFF
      CompilerEndIf
      Box(0, 0, OutputWidth(), OutputHeight(), Background)
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      DrawImage(ImageID(1), 0, 0)
      StopDrawing()
    EndIf
  EndIf
EndProcedure

Procedure Resize()
  If (GetWindowState(0) = #PB_Window_Normal)
    IW.i = WindowWidth(0)
    IH.i = WindowHeight(0) - DefaultGadgetHeight()
    If ((IW > 0) And (IH > 0))
      ResizeGadget(2, #PB_Ignore, #PB_Ignore, IW, IH)
      Redraw()
    EndIf
  EndIf
EndProcedure

Procedure PickColor()
  PrevColor.i = SetScaleImageBorderColor(0)
  NewColor.i = ColorRequester(PrevColor)
  If (NewColor >= 0)
    SetScaleImageBorderColor(NewColor)
    Redraw()
  Else
    SetScaleImageBorderColor(PrevColor)
  EndIf
EndProcedure

Global InFile.s

Procedure PickImage()
  File.s = OpenFileRequester("Image", GetPathPart(InFile), "Images|*.bmp;*.png;*.jpg;*.jpeg", 0)
  If (File)
    InFile = File
    LoadImage(0, InFile)
    Redraw()
  EndIf
EndProcedure

UseJPEGImageDecoder()
UseJPEGImageEncoder()
UsePNGImageDecoder()
UsePNGImageEncoder()

InFile.s = #PB_Compiler_Home + "Examples/3D/Data/Water/Foam.png"
;InFile.s = #PB_Compiler_Home + "Examples/3D/Data/Textures/spheremap.png"
LoadImage(0, InFile)

OpenWindow(0, 0, 0, ImageWidth(0), DefaultGadgetHeight() + ImageHeight(0), "ScaleImage",
    #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget)
ButtonGadget(5, 0, 0, 100, DefaultGadgetHeight(), "Load Image")
ComboBoxGadget(0, 110, 0, 100, DefaultGadgetHeight())
  AddGadgetItem(0, 0, "Stretch")
  AddGadgetItem(0, 1, "Fill")
  AddGadgetItem(0, 2, "Fit")
  AddGadgetItem(0, 3, "Fit If Larger")
  AddGadgetItem(0, 4, "Fit Or Center")
  AddGadgetItem(0, 5, "Tile")
  AddGadgetItem(0, 6, "Center")
  SetGadgetState(0, 0)
  GadgetToolTip(0, "Scale Methods")
CheckBoxGadget(1, 220, 0, 60, DefaultGadgetHeight(), "Raw")
  GadgetToolTip(1, "Raw Resize Flag")
ButtonGadget(3, 290, 0, 100, DefaultGadgetHeight(), "Border Color...")
  GadgetToolTip(3, "Choose Border Color")
ComboBoxGadget(4, 400, 0, 100, DefaultGadgetHeight())
  AddGadgetItem(4, CountGadgetItems(4), "Middle") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_Middle)
  AddGadgetItem(4, CountGadgetItems(4), "Top Left") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_TopLeft)
  AddGadgetItem(4, CountGadgetItems(4), "Left") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_Left)
  AddGadgetItem(4, CountGadgetItems(4), "Bottom Left") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_BottomLeft)
  AddGadgetItem(4, CountGadgetItems(4), "Bottom") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_Bottom)
  AddGadgetItem(4, CountGadgetItems(4), "Bottom Right") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_BottomRight)
  AddGadgetItem(4, CountGadgetItems(4), "Right") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_Right)
  AddGadgetItem(4, CountGadgetItems(4), "Top Right") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_TopRight)
  AddGadgetItem(4, CountGadgetItems(4), "Top") : SetGadgetItemData(4, CountGadgetItems(4)-1, #ScaleImage_Top)
  SetGadgetState(4, 0)
  GadgetToolTip(4, "Alignment Flags")
;
CanvasGadget(2, 0, DefaultGadgetHeight(), 10, 10)
AddKeyboardShortcut(0, #PB_Shortcut_Escape, 1)
SmartWindowRefresh(0, #True)

Resize()
BindEvent(#PB_Event_SizeWindow, @Resize())
BindGadgetEvent(0, @Redraw())
BindGadgetEvent(1, @Redraw())
BindGadgetEvent(3, @PickColor())
BindGadgetEvent(4, @Redraw())
BindGadgetEvent(5, @PickImage())

Repeat
  Event = WaitWindowEvent()
Until ((Event = #PB_Event_CloseWindow) Or (Event = #PB_Event_Menu))

CompilerEndIf
CompilerEndIf
;-