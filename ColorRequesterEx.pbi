; +------------------+
; | ColorRequesterEx |
; +------------------+
; | 2017.05.09 . Creation (PureBasic 5.60)

;-
CompilerIf (Not Defined(__ColorRequesterEx, #PB_Constant))
#__ColorRequesterEx_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Constants (Public)

Enumeration
  #ColorReq_UseFile   = $0001
  #ColorReq_PartOpen  = $0100 ; effect only on Windows
  #ColorReq_NoReorder = $0200 ; effect only on Windows
EndEnumeration

;#ColorReq_Default = #PB_Default


;-
;- Constants (Private)

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  #__ColorReq_RecentCount = 16
CompilerElse
  #__ColorReq_RecentCount = 1
CompilerEndIf





;-
;- Variables (Private)

Global Dim __ColorReq_Recent.l(#__ColorReq_RecentCount - 1)
__ColorReq_Recent(0) = #PB_Default

Global __ColorReq_SaveFile.s




;-
;- Macros (Public)

Macro GetColorReqExRecentCount()
  #__ColorReq_RecentCount
EndMacro


;-
;- Procedures (Private)

Procedure __ColorReq_CheckSaveFile()
  If (__ColorReq_SaveFile = "")
    __ColorReq_SaveFile = GetTemporaryDirectory() + GetFilePart(ProgramFilename()) + ".colors"
  EndIf
EndProcedure

Procedure __ColorReq_Load()
  __ColorReq_CheckSaveFile()
  Protected FN.i = ReadFile(#PB_Any, __ColorReq_SaveFile)
  If (FN)
    Protected i.i = 0
    Protected Line.s
    While ((i < #__ColorReq_RecentCount) And (Not Eof(FN)))
      Line = ReadString(FN)
      If ((Left(Line, 1) = "$") And (Len(Line) = 7))
        __ColorReq_Recent(i) = Val(Line)
        i + 1
      Else
        Break
      EndIf
    Wend
    CloseFile(FN)
  EndIf
EndProcedure

Procedure __ColorReq_Save()
  __ColorReq_CheckSaveFile()
  Protected FN.i = CreateFile(#PB_Any, __ColorReq_SaveFile)
  If (FN)
    Protected i.i
    For i = 0 To #__ColorReq_RecentCount - 1
      WriteStringN(FN, "$" + RSet(Hex(__ColorReq_Recent(i)), 6, "0"))
    Next i
    CloseFile(FN)
  EndIf
EndProcedure








;-
;- Procedures (Public)

Procedure.i ColorRequesterEx(Color.i = #PB_Default, Flags.i = #PB_Default, WindowID.i = #PB_Default)
  Protected Result.i = -1
  
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  If (WindowID = #PB_Default)
    WindowID = #Null
  EndIf
  
  Protected i.i, j.i
  If (__ColorReq_Recent(0) = #PB_Default)
    CompilerIf (#__ColorReq_RecentCount > 1)
      For i = 0 To #__ColorReq_RecentCount - 1
        j = i * (255 / (#__ColorReq_RecentCount - 1))
        __ColorReq_Recent(i) = RGB(j, j, j)
      Next i
    CompilerElse
      __ColorReq_Recent(0) = $000000
    CompilerEndIf
  EndIf
  If (Flags & #ColorReq_UseFile)
    __ColorReq_Load()
  EndIf
  
  If (Color = #PB_Default)
    Color = __ColorReq_Recent(0)
  EndIf
  Result = -1
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Protected CC.CHOOSECOLOR
    CC\lStructSize = SizeOf(CHOOSECOLOR)
    CC\hwndOwner = WindowID
    CC\rgbResult = Color
    CC\lpCustColors = @__ColorReq_Recent(0)
    CC\Flags = #CC_ANYCOLOR | #CC_RGBINIT
    If (Not (Flags & #ColorReq_PartOpen))
      CC\Flags | #CC_FULLOPEN
    EndIf
    If (ChooseColor_(@CC))
      Result = CC\rgbResult
    EndIf
  CompilerElse
    Result = ColorRequester(Color)
  CompilerEndIf
  
  If (Result <> -1)
    
    ; Update recent colors list
    j = -1
    For i = 0 To #__ColorReq_RecentCount - 1
      If (__ColorReq_Recent(i) = Result)
        j = i
        Break
      EndIf
    Next i
    If ((j = -1) Or ((j >= 1) And (Not (Flags & #ColorReq_NoReorder))))
      ; Not found, or it's found but not most-recent
      If (j = -1)
        j = #__ColorReq_RecentCount - 1
      EndIf
      For i = j To 1 Step -1
        __ColorReq_Recent(i) = __ColorReq_Recent(i - 1)
      Next i
      __ColorReq_Recent(0) = Result
    EndIf
    If (Flags & #ColorReq_UseFile)
      __ColorReq_Save()
    EndIf
    
  EndIf
  ProcedureReturn (Result)
EndProcedure


Procedure.i GetColorReqExRecent(Index.i)
  If ((Index >= 0) And (Index < #__ColorReq_RecentCount))
    ProcedureReturn (__ColorReq_Recent(Index))
  EndIf
  ProcedureReturn (-1)
EndProcedure

Procedure.i SetColorReqExRecent(Index.i, Color.i)
  If ((Index >= 0) And (Index < #__ColorReq_RecentCount))
    __ColorReq_Recent(Index) = Color
    ProcedureReturn (#True)
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.s GetColorReqExFile()
  __ColorReq_CheckSaveFile()
  ProcedureReturn (__ColorReq_SaveFile)
EndProcedure

Procedure.i SetColorReqExFile(Path.s)
  __ColorReq_SaveFile = Path
  ProcedureReturn (#True)
EndProcedure






;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit


; Specify where to save custom colors (optional)
SetColorReqExFile(GetTemporaryDirectory() + "custom.colors")

; Set default colors (optional)
If (FileSize(GetColorReqExFile()) <= 0)
  For i = 0 To (GetColorReqExRecentCount() - 1)
    SetColorReqExRecent(i, RGB(0, i*17, 255))
    ;Debug Hex(GetColorReqExRecent(i))
  Next i
EndIf


OpenWindow(0, 0, 0, 480, 360, "ColorRequesterEx", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
Color = #PB_Default
Repeat
  ;Color = ColorRequester(Color) ; For comparison
  Color = ColorRequesterEx(Color, #ColorReq_UseFile, WindowID(0))
  If (Color <> -1)
    SetWindowColor(0, Color)
  EndIf
Until (Color = -1)
;DeleteFile(GetColorReqExFile())


CompilerEndIf
CompilerEndIf
;-