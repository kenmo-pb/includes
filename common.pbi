; +------------+
; | common.pbi |
; +------------+
; | 2014.01.24 . Creation (PureBasic 5.21 LTS)
; | 2017.02.02 . Made multiple-include safe


CompilerIf (Not Defined(__Common_Included, #PB_Constant))
#__Common_Included = #True

;-
;- Includes

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf
XIncludeFile #PB_Compiler_FilePath + "os.pbi"

;-
;- Constants

#__Disable = #False
#__Enable  = #True

#__TempTrue  = #True
#__TempFalse = #False

#PB_FileSize_Empty     =  0
#PB_FileSize_Missing   = -1
#PB_FileSize_Directory = -2

#PB_Path_Current = "."
#PB_Path_Parent  = ".."

#PB_Up      = #PB_Round_Up
#PB_Down    = #PB_Round_Down
#PB_Nearest = #PB_Round_Nearest

#PB_BMP      = #PB_ImagePlugin_BMP
#PB_PNG      = #PB_ImagePlugin_PNG
#PB_JPEG     = #PB_ImagePlugin_JPEG
#PB_JPEG2000 = #PB_ImagePlugin_JPEG2000

; 2017-08-29
#ImproveUserAgent = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
;#ImproveUserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0"

CompilerIf (Defined(SW_Title, #PB_Constant))
  #__Title_Info    = #SW_Title
  #__Title_Warn    = #SW_Title
  #__Title_Error   = #SW_Title + " - Error"
  #__Title_Confirm = #SW_Title
CompilerElse
  #__Title_Info    = "Information"
  #__Title_Warn    = "Warning"
  #__Title_Error   = "Error"
  #__Title_Confirm = "Confirm"
CompilerEndIf

#PBWF_Borderless  = #PB_Window_BorderLess
#PBWF_Invisible   = #PB_Window_Invisible
#PBWF_Maximized   = #PB_Window_Maximize
#PBWF_Maximizable = #PB_Window_MaximizeGadget
#PBWF_Minimized   = #PB_Window_Minimize
#PBWF_Minimizable = #PB_Window_MinimizeGadget
#PBWF_NoGadgets   = #PB_Window_NoGadgets
#PBWF_Centered    = #PB_Window_ScreenCentered
#PBWF_Resizable   = #PB_Window_SizeGadget
#PBWF_CloseButton = #PB_Window_SystemMenu
#PBWF_TitleBar    = #PB_Window_TitleBar
#PBWF_WinCentered = #PB_Window_WindowCentered

;-
;- Constants - Time

Enumeration ; Days of Week
  #Sunday = 0
  #Monday
  #Tuesday
  #Wednesday
  #Thursday
  #Friday
  #Saturday
EndEnumeration

Enumeration ; Months of Year
  #January = 1
  #February
  #March
  #April
  #May
  #June
  #July
  #August
  #September
  #October
  #November
  #December
EndEnumeration

#FirstOfMonth = 1
#FirstOfYear  = 1

#SecondsPerMinute =  60
#MinutesPerHour   =  60
#HoursPerDay      =  24
#SecondsPerHour   = #SecondsPerMinute * #MinutesPerHour
#SecondsPerDay    = #SecondsPerHour   * #HoursPerDay
#MinutesPerDay    = #MinutesPerHour   * #HoursPerDay

#Midnight =  0
#Midday   =  12
#Noon     = #Midday


;-
;- Macros - Data Types

Macro Sint8
  b
EndMacro
Macro Uint8
  a
EndMacro
Macro Sint16
  w
EndMacro
Macro Uint16
  u
EndMacro
Macro Sint32
  l
EndMacro
Macro Sint64
  q
EndMacro

Macro Uint32
  (Uint32_Not_Supported)
EndMacro
Macro Uint64
  (Uint64_Not_Supported)
EndMacro

;-
;- Macros - Data

Macro Invert(Expression)
  (Bool(Not (Expression)))
EndMacro

Macro Floor(Value)
  (Round((Value), #PB_Round_Down))
EndMacro

Macro Ceil(Value)
  (Round((Value), #PB_Round_Up))
EndMacro

Macro Same(String1, String2)
  (Bool(LCase(String1) = LCase(String2)))
EndMacro

Macro StartsWith(String, Prefix)
  (Bool(Len(Prefix) And (LCase(Left(String, Len(Prefix))) = LCase(Prefix))))
EndMacro

Macro EndsWith(String, Suffix)
  (Bool(Len(Suffix) And (LCase(Right(String, Len(Suffix))) = LCase(Suffix))))
EndMacro

Macro NotS(String)
  (Bool(String = ""))
EndMacro

Macro Iif(Condition, ValueIfTrue, ValueIfFalse)
  (Bool(Condition) * (ValueIfTrue) + Bool(Not (Condition)) * (ValueIfFalse))
EndMacro

Procedure.s _IifS(Boolean.i, StringIfTrue.s, StringIfFalse.s = "")
  If (Boolean)
    ProcedureReturn (StringIfTrue)
  Else
    ProcedureReturn (StringIfFalse)
  EndIf
EndProcedure

Macro IifS(Condition, StringIfTrue, StringIfFalse = "")
  _IifS(Bool(Condition), (StringIfTrue), (StringIfFalse))
EndMacro

Macro CopyText(Text)
  SetClipboardText(Text)
EndMacro

Macro Quote(String)
  #DQ$ + String + #DQ$
EndMacro

Macro SQuote(String)
  #SQ$ + String + #SQ$
EndMacro

Macro SDQuote(String)
  ReplaceString(String, "'", #DQ$)
EndMacro

Macro LastField(_String, _Delim)
  StringField(_String, 1 + CountString(_String, _Delim), _Delim)
EndMacro

Macro Push(PBList)
  PushListPosition(PBList)
EndMacro

Macro Pop(PBList)
  PopListPosition(PBList)
EndMacro

Macro SelectRandomElement(PBList)
  SelectElement(PBList, Random(ListSize(PBList)-1))
EndMacro

Macro AddString(_List, _String)
  AddElement(_List) : _List = _String
EndMacro

Macro AllocateMemoryFast(Size)
  AllocateMemory(Size, #PB_Memory_NoClear)
EndMacro

;-
;- Macros - Time


CompilerIf (Not Defined(time, #PB_Procedure))
  ImportC ""
    time(*seconds.INTEGER = #Null)
  EndImport
CompilerEndIf

Macro DateUTC()
  time()
EndMacro

Macro Now()
  Date()
EndMacro

Macro Today()
  Date(Year(Now()), Month(Now()), Day(Now()), 0, 0, 0)
EndMacro

Macro Noon()
  Date(Year(Now()), Month(Now()), Day(Now()), #Noon, 0, 0)
EndMacro

Macro Tomorrow()
  AddDate(Today(), #PB_Date_Day, 1)
EndMacro

Macro Yesterday()
  AddDate(Today(), #PB_Date_Day, -1)
EndMacro

Macro MakeDate(Year, Month = #January, Day = #FirstOfMonth, Hour = 0, Minute = 0, Second = 0)
  Date((Year), (Month), (Day), (Hour), (Minute), (Second))
EndMacro

Macro StrDate(Date, Mask = "%yyyy-%mm-%dd")
  FormatDate((Mask), (Date))
EndMacro

Macro StrTime(Date, Mask = "%hh:%ii:%ss")
  FormatDate((Mask), (Date))
EndMacro

Macro StrTimestamp(Date, Mask = "%yyyy-%mm-%dd %hh:%ii:%ss")
  FormatDate((Mask), (Date))
EndMacro

Macro TodayInt()
  (Year(Today()) * 10000 + Month(Today()) * 100 + Day(Today()))
EndMacro


;-
;- Macros - Dialogs

Macro Info(Message)
  MessageRequester(#__Title_Info, Message, #OS_Icon_Information)
EndMacro

Macro Warn(Message)
  MessageRequester(#__Title_Warn, Message, #OS_Icon_Warning)
EndMacro

Macro Error(Message)
  MessageRequester(#__Title_Error, Message, #OS_Icon_Error)
EndMacro

Macro Confirm(Message, Flags = #OS_YesNoCancel)
  MessageRequester(#__Title_Confirm, Message, (Flags) | #OS_Icon_Question)
EndMacro

Macro PasswordRequester(Title, Message, DefaultString = "", Flags = #Null)
  InputRequester(Title, Message, DefaultString, (Flags)|#PB_InputRequester_Password)
EndMacro

;-
;- Macros - Compiler Info

Macro PBAtLeast(Version)
  Bool(#PB_Compiler_Version >= (Version))
EndMacro

Macro PBBefore(Version)
  Bool(#PB_Compiler_Version < (Version))
EndMacro

Macro PBEQ(Version)
  Bool(#PB_Compiler_Version = (Version))
EndMacro
Macro PBLT(Version)
  Bool(#PB_Compiler_Version < (Version))
EndMacro
Macro PBLTE(Version)
  Bool(#PB_Compiler_Version <= (Version))
EndMacro
Macro PBGT(Version)
  Bool(#PB_Compiler_Version > (Version))
EndMacro
Macro PBGTE(Version)
  Bool(#PB_Compiler_Version >= (Version))
EndMacro

;-
;- Macros - Debugger

Macro DebugProc()
  Debug #PB_Compiler_Procedure + "()"
EndMacro

Macro Halt()
  CallDebugger
EndMacro

;-
;- Macros - Gadgets

Macro SelectGadget(Gadget)
  CompilerIf (#Windows)
    SendMessage_(GadgetID(Gadget), #EM_SETSEL, 0, -1)
  CompilerElseIf (#Mac)
    ; SetActiveGadget() seems to automatically "Select All" in StringGadgets
  CompilerEndIf
  SetActiveGadget(Gadget)
EndMacro

Macro GadgetEndX(Gadget)
  (GadgetX(Gadget) + GadgetWidth(Gadget))
EndMacro

Macro GadgetEndY(Gadget)
  (GadgetY(Gadget) + GadgetHeight(Gadget))
EndMacro

Macro AutoSizeGadget(Gadget)
  ResizeGadget((Gadget), #PB_Ignore, #PB_Ignore, GadgetWidth((Gadget), #PB_Gadget_RequiredSize), GadgetHeight((Gadget), #PB_Gadget_RequiredSize))
EndMacro

Macro FitGadgetWidth(Gadget)
  ResizeGadget((Gadget), #PB_Ignore, #PB_Ignore, GadgetWidth((Gadget), #PB_Gadget_RequiredSize), #PB_Ignore)
EndMacro

Macro RemoveGadgetTooltip(Gadget)
  GadgetToolTip((Gadget), "")
EndMacro

Macro GetTrimmedText(_Gadget)
  Trim(GetGadgetText(_Gadget))
EndMacro

Macro RemoveTabShortcuts(_Window)
  RemoveKeyboardShortcut((_Window), #PB_Shortcut_Tab)
  RemoveKeyboardShortcut((_Window), #PB_Shortcut_Tab | #PB_Shortcut_Shift)
EndMacro

CompilerIf (Defined(OS_Shortcut_TabNext, #PB_Constant))
Macro AddTabShortcuts(_Window)
  DisableDebugger
  AddKeyboardShortcut((_Window), #PB_Shortcut_Tab, #OS_Shortcut_TabNext)
  AddKeyboardShortcut((_Window), #PB_Shortcut_Tab | #PB_Shortcut_Shift, #OS_Shortcut_TabPrevious)
  EnableDebugger
EndMacro
CompilerElse
Macro AddTabShortcuts(_Window)
  ;
EndMacro
CompilerEndIf


;-
;- Macros - PB Objects

Macro FreeIfImage(Image)
  If (IsImage(Image))
    FreeImage(Image)
  EndIf
EndMacro

Macro FreeIfSound(Sound)
  If (IsSound(Sound))
    FreeSound(Sound)
  EndIf
EndMacro

Macro FreeIfGadget(Gadget)
  If (IsGadget(Gadget))
    FreeGadget(Gadget)
  EndIf
EndMacro

Macro HideIfWindow(Window, State = #True)
  If (IsWindow(Window))
    HideWindow((Window), (State))
  EndIf
EndMacro

Macro CloseIfWindow(Window)
  If (IsWindow(Window))
    CloseWindow(Window)
  EndIf
EndMacro

Macro OpenBasicWindow(Window, Flags = #Null)
  OpenWindow((Window), 0, 0, 480, 360, GetFilePart(ProgramFilename()), #PBWF_Centered|#PBWF_Minimizable|(Flags))
EndMacro

Macro OpenTitleWindow(Window, Title = "", Flags = #Null)
  OpenWindow((Window), 0, 0, 320, 60, Title, #PBWF_Centered|#PBWF_Minimizable|(Flags))
EndMacro

Macro WaitCloseWindow()
  Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
EndMacro


;-
;- Macros - File I/O

Macro ReadAscii(File)
  ReadAsciiCharacter(File)
EndMacro

Macro ReadUnicode(File)
  ReadUnicodeCharacter(File)
EndMacro

Macro WriteAscii(File, Number)
  WriteAsciiCharacter((File), (Number))
EndMacro

Macro WriteUnicode(File, Number)
  WriteUnicodeCharacter((File), (Number))
EndMacro

Macro WriteStringLF(File, Text, Format = #StringFileMode)
  WriteString((File), Text + #LF$, (Format))
EndMacro


;-
;- Macros - Filesystem

Macro FileExists(File)
  (Bool(FileSize(File) >= #PB_FileSize_Empty))
EndMacro

Macro FileEmpty(File)
  (Bool(FileSize(File) = #PB_FileSize_Empty))
EndMacro

Macro PathExists(Path)
  (Bool(FileSize(Path) = #PB_FileSize_Directory))
EndMacro

Macro AssetExists(Asset)
  (Bool(FileSize(Asset) <> #PB_FileSize_Missing))
EndMacro

CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
Macro IsHidden(Path)
  Bool(GetFileAttributes(Path) & #PB_FileSystem_Hidden)
EndMacro
CompilerElse
Macro IsHidden(Path)
  StartsWith(GetTopPath(Path), ".")
EndMacro
CompilerEndIf

Macro SetParentDirectory()
  SetCurrentDirectory(#PB_Path_Parent)
EndMacro

Macro GetLExtensionPart(_Path)
  LCase(GetExtensionPart(_Path))
EndMacro

Macro RemoveExtension(_File)
  SetExtension(_File, "")
EndMacro

CompilerIf (PBGTE(560))
Macro GetDesktopDirectory()
  GetUserDirectory(#PB_Directory_Desktop)
EndMacro
CompilerEndIf

Macro GetProgramPath()
  GetPathPart(ProgramFilename())
EndMacro

Macro DeleteDirectoryAll(Directory)
  DeleteDirectory(Directory, "", #PB_FileSystem_Force | #PB_FileSystem_Recursive)
EndMacro

Macro GetModifiedDate(File)
  GetFileDate((File), #PB_Date_Modified)
EndMacro

Macro DisableDriveErrors()
  OnWindows(SetErrorMode_(#SEM_FAILCRITICALERRORS))
EndMacro

Macro Download(URL, File, UserAgent = #ImproveUserAgent)
  ReceiveHTTPFile((URL), (File), 0, (UserAgent))
EndMacro

Macro DeleteFileForce(FileName)
  DeleteFile((FileName), #PB_FileSystem_Force)
EndMacro


;-
;- Macros - Drawing

Macro StartDrawingWindow(Window)
  StartDrawing(WindowOutput(Window))
EndMacro

Macro StartDrawingScreen()
  StartDrawing(ScreenOutput())
EndMacro

Macro StartDrawingImage(Image)
  StartDrawing(ImageOutput(Image))
EndMacro

Macro StartDrawingCanvas(Gadget)
  StartDrawing(CanvasOutput(Gadget))
EndMacro

Macro ClearOutput(Color)
  Box(0, 0, OutputWidth(), OutputHeight(), (Color))
EndMacro

Macro ClearCanvas(Gadget, Color = #White)
  If (StartDrawingCanvas(Gadget))
    ClearOutput(Color)
    StopDrawing()
  EndIf
EndMacro

Macro ClearImageRGB(Image, Color = #White)
  If (StartDrawingImage(Image))
    ClearOutput(Color)
    StopDrawing()
  EndIf
EndMacro

Macro ClearImageRGBA(Image, Color = #OpaqueWhite)
  If (StartDrawingImage(Image))
    DrawingMode(#PB_2DDrawing_AllChannels)
    ClearOutput(Color)
    StopDrawing()
  EndIf
EndMacro

Macro Opaque(RGB)
  ((RGB) | $FF000000)
EndMacro


;-
;- Macros - Images

Macro SaveBMP(_Image, _FileName)
  SaveImage((_Image), (_FileName), #PB_ImagePlugin_BMP)
EndMacro
Macro SavePNG(_Image, _FileName)
  SaveImage((_Image), (_FileName), #PB_ImagePlugin_PNG)
EndMacro
Macro SaveJPEG(_Image, _FileName, _Quality = 7)
  SaveImage((_Image), (_FileName), #PB_ImagePlugin_JPEG, (_Quality))
EndMacro

Macro UsePNGCodecs()
  UsePNGImageDecoder()
  UsePNGImageEncoder()
EndMacro
Macro UseJPEGCodecs()
  UseJPEGImageDecoder()
  UseJPEGImageEncoder()
EndMacro

;-
;- Macros - Cipher

CompilerIf (#PB_Compiler_Version < 560)
  Macro Base64EncoderBuffer(_Input, _InputSize, _Output, _OutputSize, _Flags = 0)
    Base64Encoder((_Input), (_InputSize), (_Output), (_OutputSize), (_Flags))
  EndMacro
  Macro Base64DecoderBuffer(_Input, _InputSize, _Output, _OutputSize)
    Base64Decoder((_Input), (_InputSize), (_Output), (_OutputSize))
  EndMacro
CompilerEndIf

CompilerIf (#PB_Compiler_Version >= 540)
  Macro CRC32Fingerprint(Buffer, Size)
    Val("$" + Fingerprint((Buffer), (Size), #PB_Cipher_CRC32))
  EndMacro
  Macro CRC32FileFingerprint(Filename)
    Val("$" + FileFingerprint((Filename), #PB_Cipher_CRC32))
  EndMacro
  Macro MD5FileFingerprint(Filename)
    FileFingerprint((Filename), #PB_Cipher_MD5)
  EndMacro
CompilerElse
  Macro UseCRC32Fingerprint()
    ;
  EndMacro
  Macro UseMD5Fingerprint()
    ;
  EndMacro
CompilerEndIf

;-
;- Procedures - Data Types

Procedure.s YesNo(Boolean.i)
  If (Boolean)
    ProcedureReturn ("Yes")
  Else
    ProcedureReturn ("No")
  EndIf
EndProcedure

Procedure.i MinI(x.i, y.i)
  If (x < y)
    ProcedureReturn (x)
  Else
    ProcedureReturn (y)
  EndIf
EndProcedure

Procedure.i MaxI(x.i, y.i)
  If (x > y)
    ProcedureReturn (x)
  Else
    ProcedureReturn (y)
  EndIf
EndProcedure

Procedure.i PreviousElementPtr(*Element)
  If (*Element)
    Protected *Prev = PeekI(*Element - SizeOf(INTEGER))
    If (*Prev)
      *Prev + 2*SizeOf(INTEGER)
    EndIf
    ProcedureReturn (*Prev)
  Else
    ProcedureReturn (#Null)
  EndIf
EndProcedure

Procedure.i NextElementPtr(*Element)
  If (*Element)
    Protected *Next = PeekI(*Element - 2*SizeOf(INTEGER))
    If (*Next)
      *Next + 2*SizeOf(INTEGER)
    EndIf
    ProcedureReturn (*Next)
  Else
    ProcedureReturn (#Null)
  EndIf
EndProcedure

Procedure.i PercentChance(Percent.i)
  ;If (Percent >= 100)
  ;  ProcedureReturn (#True)
  ;ElseIf (Percent <= 0)
  ;  ProcedureReturn (#False)
  ;EndIf
  ProcedureReturn (Bool(Random(99) < (Percent)))
EndProcedure

;-
;- Procedures - Dialogs

Procedure.i CopyMessage(Message.s, Icon.i = #Null)
  If (Icon = #Null)
    Icon = #OS_Icon_Information
  EndIf
  Protected Result.i = MessageRequester(#__Title_Info, Message + #LFLF$ +
      "Copy to clipboard?", Icon | #OS_YesNo)
  If (Result = #OS_Yes)
    SetClipboardText(Message)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure DisplayText(Text.s, ParentWin.i = #PB_Ignore)
  Protected ParentID.i
  Protected Flags.i = #PB_Window_SystemMenu
  If (ParentWin <> #PB_Ignore)
    Flags | #PB_Window_WindowCentered
    ParentID = WindowID(ParentWin)
  Else
    Flags | #PB_Window_ScreenCentered
  EndIf
  Protected Win.i = OpenWindow(#PB_Any, 0, 0, 320, 240,
      GetFilePart(ProgramFilename()), Flags, ParentID)
  If (Win)
    If (ParentWin <> #PB_Ignore)
      DisableWindow(ParentWin, #True)
    EndIf
    Protected Editor.i = EditorGadget(#PB_Any, 0, 0,
        WindowWidth(Win), WindowHeight(Win), #PB_Editor_ReadOnly)
    If (Editor)
      SetGadgetText(Editor, Text)
      SetActiveGadget(Editor)
      Repeat
        Protected Event.i = WaitWindowEvent()
      Until (Event = #PB_Event_CloseWindow)
      FreeGadget(Editor)
    EndIf
    CloseWindow(Win)
    If (ParentWin <> #PB_Ignore)
      DisableWindow(ParentWin, #False)
    EndIf
  EndIf
EndProcedure

;-
;- Procedures - Time

Procedure.i LocalToUTC(LocalDate.i)
  ProcedureReturn (LocalDate + (DateUTC() - Date()))
EndProcedure

Procedure.s RFCDate(Date.i, IsLocal.i = #False)
  Protected Result.s
  Result = Mid("SunMonTueWedThuFriSat", 1 + DayOfWeek(Date)*3, 3) + ", "
  Result + RSet(Str(Day(Date)), 2, "0") + " "
  Result + Mid("JanFebMarAprMayJunJulAugSepOctNovDec", 1 + (Month(Date)-1)*3, 3) + " "
  Result + RSet(Str(Year(Date)), 4, "0") + " "
  Result + RSet(Str(Hour(Date)), 2, "0") + ":"
  Result + RSet(Str(Minute(Date)), 2, "0") + ":"
  Result + RSet(Str(Second(Date)), 2, "0") + " "
  If (IsLocal)
    Protected Diff.i = (Date() - DateUTC())
    If (Diff >= 0)
      Result + "+"
    Else
      Diff = -Diff
      Result + "-"
    EndIf
    Result + RSet(Str(Diff / 3600), 2, "0") + RSet(Str((Diff % 3600) / 60), 2, "0")
  Else
    Result + "+0000"
  EndIf
  ProcedureReturn (Result)
EndProcedure


;-
;- Procedures - Strings

Procedure.s ReplaceVariations(String.s, StringToFind.s, StringToReplace.s)
  String = ReplaceString(String, StringToFind, StringToReplace)
  String = ReplaceString(String, UCase(StringToFind), UCase(StringToReplace))
  String = ReplaceString(String, LCase(StringToFind), LCase(StringToReplace))
  If (#True)
    String = ReplaceString(String, StringToFind, StringToReplace, #PB_String_NoCase)
  EndIf
  ProcedureReturn (String)
EndProcedure

Procedure.s QuoteIfSpaces(Input.s, DontQuoteEmpty.i = #False)
  If (FindString(Input, " "))
    If ((Left(Input, 1) <> #DQ$) Or (Right(Input, 1) <> #DQ$))
      Input = Quote(Input)
    EndIf
  ElseIf (Input = "")
    If (Not DontQuoteEmpty)
      Input = Quote(Input)
    EndIf
  EndIf
  ProcedureReturn (Input)
EndProcedure

Procedure.s Between(Input.s, Open.s = "", Close.s = "")
  Protected Result.s = ""
  Protected StartPos.i, EndPos.i
  Protected LInput.s
  
  If (#True)
    LInput = LCase(Input)
    Open   = LCase(Open)
    Close  = LCase(Close)
  Else
    LInput = Input
  EndIf
  
  If (Open)
    StartPos = FindString(LInput, Open)
    If (StartPos > 0)
      StartPos + Len(Open)
    EndIf
  Else
    StartPos = 1
  EndIf
  If (StartPos > 0)
    If (Close)
      EndPos = FindString(LInput, Close, StartPos)
      If (EndPos > 0)
        Result = Mid(Input, StartPos, EndPos - StartPos)
      EndIf
    Else
      Result = Mid(Input, StartPos)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s Plural(Count.i, Singular.s, Plural.s = "")
  If (Count = 1)
    ProcedureReturn ("1 " + Singular)
  Else
    If (Plural = "")
      Plural = Singular + "s"
    EndIf
    ProcedureReturn (Str(Count) + " " + Plural)
  EndIf
EndProcedure

Procedure.s Strings(Text.s, Param1.s = "", Param2.s = "", Param3.s = "")
  Text = ReplaceString(Text, "$1", Param1)
  Text = ReplaceString(Text, "$2", Param2)
  Text = ReplaceString(Text, "$3", Param3)
  ProcedureReturn (Text)
EndProcedure

Procedure.s Integers(Text.s, Param1.i = 0, Param2.i = 0, Param3.i = 0)
  Text = ReplaceString(Text, "$1", Str(Param1))
  Text = ReplaceString(Text, "$2", Str(Param2))
  Text = ReplaceString(Text, "$3", Str(Param3))
  ProcedureReturn (Text)
EndProcedure

Procedure.s ByteString(Bytes.q, NumDecimals.i = 1)
  If (Bytes >= 1000*1000*1000)
    Bytes / 1024
    Bytes / 1024
    ProcedureReturn (StrF(Bytes / 1024.0, NumDecimals) + " GB")
  ElseIf (Bytes >= 1000*1000)
    Bytes / 1024
    ProcedureReturn (StrF(Bytes / 1024.0, NumDecimals) + " MB")
  ElseIf (Bytes >= 1024)
    ProcedureReturn (StrF(Bytes / 1024.0, NumDecimals) + " KB")
  Else
    ProcedureReturn (Plural(Bytes, "byte"))
  EndIf
EndProcedure

Procedure.s HexFormat(Value.i, Width.i = #PB_Default, Prefix.s = "", Suffix.s = "", Lower.i = #False)
  Protected Result.s = Hex(Value)
  If (Lower)
    Result = LCase(Result)
  EndIf
  Protected Chars.i = Len(Result)
  If (Width >= 1)
    Chars = Width
  Else
    If (Chars < 2)
      Chars = 2
    ElseIf (Chars & 1)
      Chars + 1
    EndIf
  EndIf
  Result = Prefix + RSet(Result, Chars, "0") + Suffix
  ProcedureReturn (Result)
EndProcedure

Procedure.i SplitString(Input.s, Array Output.s(1), Delimiter.s = "", IgnoreBlanks.i = #False)
  Protected Result.i = 0
  
  Dim Output.s(0)
  If (Delimiter = "")
    Input = ReplaceString(Input, #CRLF$, #LF$)
    Input = ReplaceString(Input, #CR$,   #LF$)
    Delimiter = #LF$
  EndIf
  
  NewList Token.s()
  Protected DelimLen.i = Len(Delimiter)
  Protected StartPos.i = 1
  Protected EndPos.i
  Repeat
    EndPos = FindString(Input, Delimiter, StartPos)
    If (EndPos)
      If ((EndPos > StartPos) Or (Not IgnoreBlanks))
        AddElement(Token())
        Token() = Mid(Input, StartPos, EndPos - StartPos)
        Result + 1
      EndIf
      StartPos = EndPos + DelimLen
    EndIf
  Until (Not EndPos)
  If (StartPos <= Len(Input))
    AddElement(Token())
    Token() = Mid(Input, StartPos)
    Result + 1
  EndIf
  
  If (Result)
    Dim Output.s(Result - 1)
    EndPos = 0
    ForEach (Token())
      Output(EndPos) = Token()
      EndPos + 1
    Next
    FreeList(Token())
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s ProgramParameterString()
  Protected Result.s = ""
  
  Protected n.i = CountProgramParameters()
  Protected i.i
  Protected Param.s
  For i = 0 To n - 1
    Result + " " + QuoteIfSpaces(ProgramParameter(i))
  Next i
  
  ProcedureReturn (Mid(Result, 2))
EndProcedure

Procedure.s Unquote(String.s)
  If (Left(String, 1) = #DQ$)
    If (Right(String, 1) = #DQ$)
      String = Mid(String, 2, Len(String) - 2)
    EndIf
  EndIf
  ProcedureReturn (String)
EndProcedure

Procedure.i UTF8CharBytes(Char.c)
  If (Char >= $0800)
    ProcedureReturn (3)
  ElseIf (Char >= $0080)
    ProcedureReturn (2)
  Else
    ProcedureReturn (1)
  EndIf
EndProcedure

Procedure.s RemoveCharacters(Input.s, CharsToRemove.s, Invert.i = #False)
  Protected *In.CHARACTER  = @Input
  Protected *Out.CHARACTER = @Input
  Protected *Search.CHARACTER
  Protected Found.i
  Invert = Bool(Not Invert)
  While (*In\c)
    Found = #False
    *Search = @CharsToRemove
    While (*Search\c)
      If (*Search\c = *In\c)
        Found = #True
        Break
      EndIf
      *Search + #CharSize
    Wend
    If (Found XOr Invert)
      *Out\c = *In\c
      *Out + #CharSize
    EndIf
    *In + #CharSize
  Wend
  *Out\c = #NUL
  ProcedureReturn (Input)
EndProcedure

Procedure.i FindLastOccurrence(String.s, StringToFind.s, StartPosition.i = 1, Mode.i = 0)
  Protected Result.i = 0
  Protected i.i
  If (String And StringToFind)
    If (StartPosition < 1)
      StartPosition = 1
    EndIf
    Repeat
      i = FindString(String, StringToFind, StartPosition, Mode)
      If (i)
        Result = i
        StartPosition = i + Len(StringToFind)
      EndIf
    Until (Not i)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s GetDotExtensionPart(Path.s)
  Protected Result.s = GetExtensionPart(Path)
  If (Result)
    Result = "." + Result
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s AppendFilename(Path.s, Suffix.s)
  If (Path)
    ProcedureReturn (GetPathPart(Path) + GetFilePart(Path, #PB_FileSystem_NoExtension) + Suffix + GetDotExtensionPart(Path))
  EndIf
EndProcedure


;-
;- Procedures - Paths

Procedure.s EnsurePathSeparator(Path.s)
  If (Path)
    ProcedureReturn (RTrim(Path, #PS$) + #PS$)
  Else
    ProcedureReturn ("")
  EndIf
EndProcedure

Procedure.s RemovePathSeparator(Path.s)
  ProcedureReturn (RTrim(Path, #PS$))
EndProcedure

Procedure.s GetParentPath(Path.s)
  If (Trim(Path, #PS$) = "")
    ProcedureReturn ("")
  Else
    ProcedureReturn (GetPathPart(RTrim(Path, #PS$)))
  EndIf
EndProcedure

Procedure.s GetTopPath(Path.s)
  If (Trim(Path, #PS$) = "")
    ProcedureReturn (Path)
  Else
    Path = GetFilePart(RTrim(Path, #PS$))
    CompilerIf (#PS$ = "\")
      If (Right(Path, 1) = ":")
        Path + #PS$
      EndIf
    CompilerEndIf
  EndIf
  ProcedureReturn (Path)
EndProcedure

Procedure.s TopExistingPath(Path.s)
  Path = EnsurePathSeparator(Path)
  While (Path And (FileSize(Path) <> #PB_FileSize_Directory)) ; use Examine ?
    Path = GetParentPath(Path)
  Wend
  ProcedureReturn (Path)
EndProcedure

Procedure.i IsAbsolutePath(Path.s)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ProcedureReturn (Bool((Left(Path, 2) = "\\") Or (Mid(Path, 2, 1) = ":")))
  CompilerElse
    ProcedureReturn (Bool(Left(Path, 1) = "/"))
  CompilerEndIf
EndProcedure

Procedure.s EnsureAbsolutePath(Path.s, Current.s = "")
  Protected Result.s
  CompilerIf (Not #Windows)
    If (Path = "~")
      Path = GetHomeDirectory()
    ElseIf (StartsWith(Path, "~/"))
      Path = GetHomeDirectory() + Mid(Path, 3)
    EndIf
  CompilerEndIf
  If (Path)
    CompilerIf (#Windows)
      ReplaceString(Path, "/", "\", #PB_String_InPlace)
    CompilerEndIf
    If (IsAbsolutePath(Path))
      Result = Path
    Else
      If (Current)
        CompilerIf (#Windows)
          ReplaceString(Current, "/", "\", #PB_String_InPlace)
        CompilerEndIf
        Current = EnsurePathSeparator(Current)
      Else
        Current = GetCurrentDirectory()
      EndIf
      Result = Current + LTrim(Path, #PS$)
    EndIf
    While (FindString(Result, #PS$ + "." + #PS$))
      Result = ReplaceString(Result, #PS$ + "." + #PS$, #PS$, 0, 1, 1)
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s EnsureAbsoluteFolder(Folder.s, Current.s = "")
  ProcedureReturn (EnsurePathSeparator(EnsureAbsolutePath(Folder, Current)))
EndProcedure

Procedure.s SetExtension(File.s, Extension.s)
  If (File)
    File = GetPathPart(File) + GetFilePart(File, #PB_FileSystem_NoExtension)
    If (Extension)
      File + "." + Extension
    EndIf
  EndIf
  ProcedureReturn (File)
EndProcedure

Procedure.s EnsureSafeFilename(Filename.s)
  Protected *C.CHARACTER = @Filename
  While (*C\c)
    CompilerIf (#Windows)
      Select (*C\c)
        Case '<', '>', ':', '"', '/', '\', '|', '?', '*', 1 To 31
          *C\c = '_'
      EndSelect
    CompilerEndIf
    *C + #CharSize
  Wend
  ProcedureReturn (Filename)
EndProcedure




;-
;- Procedures - Filesystem

Procedure.i IsDirectoryEmpty(Directory.s)
  Protected Result.i = -1
  
  Protected Dir.i = ExamineDirectory(#PB_Any, Directory, "")
  If (Dir)
    Result = #True
    While (NextDirectoryEntry(Dir))
      If ((DirectoryEntryName(Dir) <> #PB_Path_Current) And (DirectoryEntryName(Dir) <> #PB_Path_Parent))
        Result = #False
        Break
      EndIf
    Wend
    FinishDirectory(Dir)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s ConvertPath(Path.s, NewSeparator.s = "")
  If (NewSeparator = "")
    NewSeparator = #PS$
  EndIf
  If (NewSeparator = "\")
    ProcedureReturn (ReplaceString(Path, "/", "\"))
  ElseIf (NewSeparator = "/")
    ProcedureReturn (ReplaceString(Path, "\", "/"))
  Else
    ProcedureReturn (Path)
  EndIf
EndProcedure

Procedure.s UniqueFileName(Path.s = "", Prefix.s = "", Extension.s = "")
  
  If (Path)
    Path = EnsurePathSeparator(Path)
  EndIf
  If (Prefix = "")
    Prefix = "temp"
  EndIf
  If (Extension)
    Extension = "." + Extension
  EndIf
  Protected Name.s = Prefix + Extension
  Protected i.i = 1
  While (FileSize(Path + Name) <> #PB_FileSize_Missing)
    i + 1
    Name = Prefix + "-" + Str(i) + Extension
  Wend
  
  ProcedureReturn (Path + Name)
EndProcedure

Procedure.s UniquePathName(Path.s = "", Prefix.s = "")
  
  If (Path)
    Path = EnsurePathSeparator(Path)
  EndIf
  If (Prefix = "")
    Prefix = "temp"
  EndIf
  Protected Name.s = Prefix
  Protected i.i = 1
  While (FileSize(Path + Name) <> #PB_FileSize_Missing)
    i + 1
    Name = Prefix + "-" + Str(i)
  Wend
  
  ProcedureReturn (Path + Name + #PS$)
EndProcedure

Procedure.s TemporaryFileName(Prefix.s = "", Extension.s = "")
  ProcedureReturn (UniqueFileName(GetTemporaryDirectory(), Prefix, Extension))
EndProcedure

Procedure.s TemporaryPathName(Prefix.s = "")
  ProcedureReturn (UniquePathName(GetTemporaryDirectory(), Prefix))
EndProcedure

Procedure.i AppendFile(File.s, Text.s)
  Protected Result.i = #False
  Protected FN.i = OpenFile(#PB_Any, File)
  If (FN)
    If (Lof(FN) > 0)
      FileSeek(FN, Lof(FN)-1)
      Select (ReadAscii(FN))
        Case #CR, #LF
          ;
        Default
          WriteString(FN, #LF$)
      EndSelect
    Else
      FileSeek(FN, Lof(FN))
    EndIf
    WriteStringLF(FN, Text)
    Result = #True
    CloseFile(FN)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateEmptyFile(FileName.s)
  Protected FN.i = CreateFile(#PB_Any, FileName)
  If (FN)
    CloseFile(FN)
  EndIf
  ProcedureReturn (Bool(FN))
EndProcedure

Procedure.i CanWriteTo(Path.s)
  Protected Result.i = #False
  
  Protected File.s = UniqueFileName(Path)
  If (CreateEmptyFile(File))
    Result = #True
    DeleteFile(File)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateFileFromData(FileName.s, *MemoryBuffer, LengthToWrite.i)
  Protected Result.i = #False
  
  If (*MemoryBuffer And (LengthToWrite >= 0))
    Protected FN.i = CreateFile(#PB_Any, FileName)
    If (FN)
      If (LengthToWrite > 0)
        Result = Bool(WriteData(FN, *MemoryBuffer, LengthToWrite) = LengthToWrite)
      EndIf
      CloseFile(FN)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateDirectoryFull(Path.s)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    ReplaceString(Path, "/", "\", #PB_String_InPlace)
    Path = RTrim(Path, "\")
  CompilerElse
    ReplaceString(Path, "\", "/", #PB_String_InPlace)
    Path = RTrim(Path, "/")
  CompilerEndIf
  If ((Path = "") Or (FileSize(Path) = -2))
    ProcedureReturn (#True)
  Else
    Protected Parent.s = GetPathPart(Path)
    If (CreateDirectoryFull(Parent))
      ProcedureReturn (CreateDirectory(Path))
    EndIf
  EndIf
  ProcedureReturn (#False)
EndProcedure

Procedure.i LocateAsset(Path.s)
  Protected Result.i = #False
  
  ; Prepare strings
  Protected Original.s =  GetCurrentDirectory()
  CompilerIf (#True)
    ReplaceString(Path, #NPS$, #PS$, #PB_String_InPlace)
  CompilerEndIf
  
  ; Check current directory for file/folder asset
  Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
  
  ; Check parent of current directory
  If (Not Result)
    SetCurrentDirectory(#PB_Path_Parent)
    Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
  EndIf
  
  ; Check program directory
  If (Not Result)
    SetCurrentDirectory(GetPathPart(ProgramFilename()))
    Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
  EndIf
  
  ; Check parent of program directory
  If (Not Result)
    SetCurrentDirectory(#PB_Path_Parent)
    Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
  EndIf
  
  ; Mac-specific searches
  CompilerIf (#Mac)
    
    ; Check <.app>/Contents/Resources/
    If (Not Result)
      SetCurrentDirectory("Resources")
      Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
    EndIf
    
    ; Check parent of <.app>
    If (Not Result)
      While (FindString(GetCurrentDirectory(), ".app/"))
        SetCurrentDirectory(#PB_Path_Parent)
      Wend
      Result = Bool(FileSize(Path) <> #PB_FileSize_Missing)
    EndIf
    
  CompilerEndIf
  
  ; Give up search
  If (Not Result)
    SetCurrentDirectory(Original)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.q DirectorySize(Directory.s)
  Protected Size.q = 0
  
  If (FileSize(Directory) = #PB_FileSize_Directory)
    Directory = EnsurePathSeparator(Directory)
    Protected Dir.i = ExamineDirectory(#PB_Any, Directory, "")
    If (Dir)
      While (NextDirectoryEntry(Dir))
        If (DirectoryEntryType(Dir) = #PB_DirectoryEntry_File)
          Size + FileSize(Directory + DirectoryEntryName(Dir))
        Else
          Protected Name.s = DirectoryEntryName(Dir)
          If ((Name <> #PB_Path_Current) And (Name <> #PB_Path_Parent))
            Size + DirectorySize(Directory + Name)
          EndIf
        EndIf
      Wend
      FinishDirectory(Dir)
    EndIf
  Else
    Size = #PB_FileSize_Missing
  EndIf
  
  ProcedureReturn (Size)
EndProcedure

Procedure ShowInExplorer(Path.s)
  If (Path)
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      If (FileSize(Path) >= 0)
        RunProgram("explorer.exe", "/select," + #DQUOTE$ + Path + #DQUOTE$, "")
      ElseIf (FileSize(Path) = -2)
        RunProgram(Path)
      EndIf
    CompilerElseIf (#PB_Compiler_OS = #PB_OS_MacOS)
      If (FileSize(Path) >= 0)
        RunProgram("open", "-R " + #DQUOTE$ + Path + #DQUOTE$, "")
      ElseIf (FileSize(Path) = -2)
        RunProgram("open", #DQUOTE$ + Path + #DQUOTE$, "")
      EndIf
    CompilerEndIf
  EndIf
EndProcedure

Procedure.i FindInListFile(File.s, Query.s)
  Protected Result.i = #False
  If (File And Query)
    Protected FID.i = ReadFile(#PB_Any, File)
    If (FID)
      Protected Raw.s = ReadString(FID, #PB_UTF8 | #PB_File_IgnoreEOL)
      CloseFile(FID)
      If (Raw)
        Raw = ReplaceString(Raw, #CRLF$, #LF$)
        Raw = ReplaceString(Raw, #CR$,   #LF$)
        If (#True)
          Raw   = LCase(Raw)
          Query = LCase(Query)
        EndIf
        Raw = #LF$ + Raw + #LF$
        Query = ReplaceString(Query, #CR$, "<CR>")
        Query = ReplaceString(Query, #LF$, "<LF>")
        Query = #LF$ + Query + #LF$
        Result = Bool(FindString(Raw, Query, 1))
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i AddToListFile(File.s, Query.s)
  Protected Result.i = #False
  If (File And Query)
    Protected FID.i = ReadFile(#PB_Any, File)
    If (FID)
      Protected Raw.s = ReadString(FID, #PB_UTF8 | #PB_File_IgnoreEOL)
      Raw = ReplaceString(Raw, #CRLF$, #LF$)
      Raw = ReplaceString(Raw, #CR$,   #LF$)
      CloseFile(FID)
    EndIf
    FID = CreateFile(#PB_Any, File)
    If (FID)
      Query = ReplaceString(Query, #CR$, "<CR>")
      Query = ReplaceString(Query, #LF$, "<LF>")
      WriteString(FID, Query + #LF$ + LTrim(Raw, #LF$))
      CloseFile(FID)
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure




;-
;- Procecures - Process

Procedure.i FindProgramParameter(Name.s, After.i = 0)
  Protected Result.i = -1
  Protected nParams.i = CountProgramParameters()
  If (nParams >= 1)
    If (Name)
      ReplaceString(Name, "|",  " ", #PB_String_InPlace)
      ReplaceString(Name, ";",  " ", #PB_String_InPlace)
      ReplaceString(Name, ",",  " ", #PB_String_InPlace)
      ReplaceString(Name, "/",  " ", #PB_String_InPlace)
      ReplaceString(Name, #LF$, " ", #PB_String_InPlace)
      Protected nNames.i = 1 + CountString(Name, " ")
      Protected i.i
      
      For i = 1 To nNames
        Protected TryName.s = StringField(Name, i, " ")
        TryName = LTrim(TryName, "-")
        TryName = LTrim(TryName, "/")
        TryName = LCase(TryName)
        If (TryName)
          Protected j.i
          
          For j = 0 To nParams - 1 - After
            Protected TryParam.s = ProgramParameter(j)
            TryParam = LCase(TryParam)
            If ((TryParam = "-" + TryName) Or (TryParam = "--" + TryName) Or
                (TryParam = "/" + TryName))
                ;(TryParam = "/" + TryName) Or (TryParam = TryName))
              ;Result = j + 1 + After
              Result = j + After
              Break 2
            EndIf
          Next j
          
        EndIf
      Next i
      
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s GetProgramParameter(Name.s, After.i = 1, Def.s = "")
  If (After <= 0)
    After = 1
  EndIf
  Protected i.i = FindProgramParameter(Name, After)
  If (i >= 0)
    ProcedureReturn (ProgramParameter(i))
  EndIf
  ProcedureReturn (Def)
EndProcedure

Macro HasProgramParameter(Name)
  Bool(FindProgramParameter(Name) >= 0)
EndMacro

CompilerIf (#PB_Compiler_Thread)

Procedure _DelayedEventThread(*Params)
  If (*Params)
    Delay(PeekI(*Params + 0 * #IntSize))
    PostEvent(PeekI(*Params + 1 * #IntSize),
        PeekI(*Params + 2 * #IntSize),
        PeekI(*Params + 3 * #IntSize),
        PeekI(*Params + 4 * #IntSize),
        PeekI(*Params + 5 * #IntSize))
    FreeMemory(*Params)
  EndIf
EndProcedure

Procedure.i PostDelayedEvent(Milliseconds.i, Event.i, Window.i = -1, Object.i = -1, Type.i = -1, _Data.i = #Null)
  Protected Result.i = #False
  Protected *Params = AllocateMemory(6 * #IntSize, #PB_Memory_NoClear)
  If (*Params)
    PokeI(*Params + 0 * #IntSize, Milliseconds)
    PokeI(*Params + 1 * #IntSize, Event)
    PokeI(*Params + 2 * #IntSize, Window)
    PokeI(*Params + 3 * #IntSize, Object)
    PokeI(*Params + 4 * #IntSize, Type)
    PokeI(*Params + 5 * #IntSize, _Data)
    Result = CreateThread(@_DelayedEventThread(), *Params)
    If (Not Result)
      FreeMemory(*Params)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf

Procedure.i OpenProgram(ProgramName.s, Parameter.s = "", WorkingDirectory.s = "", Flags.i = #Null, SenderProgram.i = #Null)
  Flags | (#PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error)
  ProcedureReturn (RunProgram(ProgramName, Parameter, WorkingDirectory, Flags, SenderProgram))
EndProcedure

Procedure.s RunProgramOutput(ProgramName.s, Parameter.s = "", WorkingDirectory.s = "", Flags.i = #Null)
  Protected Result.s
  Protected PID.i = OpenProgram(ProgramName, Parameter, WorkingDirectory, #PB_Program_Hide | Flags)
  If (PID)
    While (ProgramRunning(PID))
      If (AvailableProgramOutput(PID))
        Result + ReadProgramString(PID) + #LF$
      Else
        Delay(1)
      EndIf
    Wend
    CloseProgram(PID)
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- Procedures - Gadgets

Procedure InsertGadgetText(Gadget.i, Text.s)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    SendMessage_(GadgetID(Gadget), #EM_REPLACESEL, #True, @Text)
    If (GetActiveGadget() <> Gadget)
      SetActiveGadget(Gadget)
    EndIf
  CompilerElseIf (#PB_Compiler_OS = #PB_OS_MacOS)
    Protected *GID = GadgetID(Gadget)
    If (GetActiveGadget() <> Gadget)
      SetActiveGadget(Gadget)
      Protected *Win = CocoaMessage(#Null, *GID, "window")
      Protected *FE  = CocoaMessage(#Null, *Win, "fieldEditor:", #YES, "forObject:", *GID)
      If (*FE)
        Protected Range.NSRange
        Range\location = Len(GetGadgetText(Gadget))
        Range\length = 0
        CocoaMessage(#Null, *FE, "setSelectedRange:@", @Range)
      EndIf
    EndIf
    Protected *CE = CocoaMessage(#Null, *GID, "currentEditor")
    If (*CE)
      CocoaMessage(#Null, *CE, "insertText:$", @Text)
    EndIf
  CompilerEndIf
EndProcedure


;-
;- Procedures - Color

Procedure.i Gray(Level.i)
  ProcedureReturn (RGB(Level, Level, Level))
EndProcedure

Procedure.i RandomGray()
  ProcedureReturn (Gray(Random($FF)))
EndProcedure

Procedure.i RandomColor()
  ProcedureReturn (Random($FFFFFF))
EndProcedure

Procedure.i SwapRGB(Color.i)
  ProcedureReturn (RGBA(Blue(Color), Green(Color), Red(Color), Alpha(Color)))
EndProcedure

Procedure.i AverageRGB(Color.i)
  ProcedureReturn ((Red(Color) + Green(Color) + Blue(Color)) / 3)
EndProcedure

Procedure.i BlendRGB(Color0.i, Color1.i, Mix.f)
  Protected r.i =   Red(Color0) + Mix * (  Red(Color1) -   Red(Color0))
  Protected g.i = Green(Color0) + Mix * (Green(Color1) - Green(Color0))
  Protected b.i =  Blue(Color0) + Mix * ( Blue(Color1) -  Blue(Color0))
  ProcedureReturn (RGB(r, g, b))
EndProcedure


;-
;- Procedures - Images

Procedure.i CreateImageRGB(Image.i, Width.i, Height.i, Color.i = #White)
  Protected Result.i = CreateImage(Image, Width, Height, 32)
  If (Result)
    If (Image = #PB_Any)
      Image = Result
    EndIf
    ClearImageRGB(Image, Color)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreateImageRGBA(Image.i, Width.i, Height.i, Color.i = #OpaqueWhite)
  Protected Result.i = CreateImage(Image, Width, Height, 32)
  If (Result)
    If (Image = #PB_Any)
      Image = Result
    EndIf
    ClearImageRGBA(Image, Color)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ConvertImageFile(File.s, NewFile.s = "", Quality.i = 9)
  Protected Result.i = #False
  Protected Img.i = LoadImage(#PB_Any, File)
  If (Img)
    If (NewFile = "")
      NewFile = File
    EndIf
    Protected Format.i
    Select (LCase(GetExtensionPart(NewFile)))
      Case "jpg", "jpeg"
        Format = #PB_ImagePlugin_JPEG
      Case "jpg2"
        Format = #PB_ImagePlugin_JPEG2000
      Case "png"
        Format = #PB_ImagePlugin_PNG
      Default
        Format = #PB_ImagePlugin_BMP
    EndSelect
    Result = Bool(SaveImage(Img, NewFile, Format, Quality))
    FreeImage(Img)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Global __DisplayedImages.i = 0

Procedure WaitDisplayedImages()
  Repeat
    DisableDebugger
      While WindowEvent() : Wend
    EnableDebugger
    Delay(1)
  Until (__DisplayedImages = 0)
EndProcedure

Procedure.i DisplayedImagesClosed()
  ProcedureReturn (Bool(__DisplayedImages = 0))
EndProcedure

Procedure __DisplayImageClose()
  Protected Win.i = EventWindow()
  HideWindow(Win, #True)
  Protected Gad.i = GetWindowData(Win)
  If (Gad)
    FreeGadget(Gad)
  EndIf
  CloseWindow(Win)
  __DisplayedImages - 1
EndProcedure

Procedure.i DisplayImage(Image.i, Title.s = "", Asynchronous.i = #False)
  Protected Result.i
  Protected Width.i  = ImageWidth(Image)
  Protected Height.i = ImageHeight(Image)
  If (Title = "")
    Title = "Image " + Str(Image)
  EndIf
  Protected Win.i = OpenWindow(#PB_Any, 0, 0, Width, Height, Title,
      #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
  If (Win)
    __DisplayedImages + 1
    Protected Gad.i = ImageGadget(#PB_Any, 0, 0, Width, Height, ImageID(Image))
    If (Gad)
      AddKeyboardShortcut(Win, #PB_Shortcut_Return, 0)
      AddKeyboardShortcut(Win, #PB_Shortcut_Escape, 1)
      SetWindowData(Win, Gad)
      If (Asynchronous)
        BindEvent(#PB_Event_CloseWindow, @__DisplayImageClose(), Win)
        BindEvent(#PB_Event_Menu, @__DisplayImageClose(), Win, 0)
        BindEvent(#PB_Event_Menu, @__DisplayImageClose(), Win, 1)
        Result = Win
      Else
        Protected Event.i
        While (#True)
          Event = WaitWindowEvent()
          If (EventWindow() = Win)
            If (Event = #PB_Event_CloseWindow)
              Break
            ElseIf (Event = #PB_Event_Menu)
              Select (EventMenu())
                Case 0, 1
                  Break
                Default
                  CompilerIf (#Mac)
                    ; Bind Cmd-Q
                  CompilerEndIf
              EndSelect
            EndIf
          EndIf
        Wend
        FreeGadget(Gad)
        CloseWindow(Win)
        __DisplayedImages - 1
        Result = #True
      EndIf
    Else
      CloseWindow(Win)
      __DisplayedImages - 1
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure




;-
;- Procedures - Network

Procedure LaunchURL(URL.s, NoPrefix.i = #False)
  If (URL)
    If (Not NoPrefix) 
      If (Not FindString(URL, "://"))
        URL = "http://" + URL
      EndIf
    EndIf
    CompilerSelect (#OS)
      CompilerCase (#PB_OS_Windows)
        ShellExecute_(#Null, @"open", @URL, #Null, #Null, #SW_SHOWNORMAL)
      CompilerCase (#PB_OS_MacOS)
        RunProgram("open", URL, "")
      CompilerDefault
        RunProgram(URL)
    CompilerEndSelect
  EndIf
EndProcedure

Procedure.s ReceiveHTTPString(URL.s, UserAgent.s = "", Flags.i = #Null)
  If (URL)
    If (UserAgent = "")
      UserAgent = #ImproveUserAgent + "." + Str(Random(999999))
    EndIf
    Protected *Buffer = ReceiveHTTPMemory(URL, Flags, UserAgent)
    If (*Buffer)
      Protected HTML.s = PeekS(*Buffer, MemorySize(*Buffer), #PB_UTF8 | #PB_ByteLength)
      CompilerIf (#Unicode)
        If (Asc(HTML) = $FEFF) ; Unicode BOM character
          HTML = Mid(HTML, 2)
        EndIf
      CompilerEndIf
      FreeMemory(*Buffer)
      ProcedureReturn (HTML)
    EndIf
  EndIf
EndProcedure

CompilerIf (#False)
Procedure.s GetGlobalIP()
  If (InitNetwork())
    ProcedureReturn (ReceiveHTTPString("http://api.ipify.org/"))
  EndIf
EndProcedure
CompilerEndIf

Procedure.i InitNetworkTimeout(Seconds.i = 3*60)
  Protected Result.i = InitNetwork()
  If ((Not Result) And (Seconds > 0))
    Seconds * 1000
    Protected Start.i = ElapsedMilliseconds()
    Repeat
      Delay(500)
      Result = InitNetwork()
    Until (Result Or ((ElapsedMilliseconds() - Start) > Seconds))
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i InitNetworkVerify(Seconds.i = 3*60)
  Protected Result.i = #False
  If (Seconds > 0)
    Protected Start.i = ElapsedMilliseconds()
    If (InitNetworkTimeout(Seconds))
      Seconds * 1000
      Protected TestURL.s = "captive.apple.com?random=" + Str(Random(999999))
      Protected LTestBody.s = "success"
      Repeat
        If (Between(LCase(ReceiveHTTPString(TestURL)), "<body>", "</body>") = LTestBody)
          Result = #True
          Break
        EndIf
        Delay(1*1000)
      Until ((ElapsedMilliseconds() - Start) > Seconds)
    EndIf
  Else
    Result = Bool(InitNetwork())
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i HTTPFileSize(URL.s, UserAgent.s = "")
  Protected Result.i = -1
  If (URL)
    If (UserAgent = "")
      UserAgent = #ImproveUserAgent + "." + Str(Random(999999))
    EndIf
    Protected Raw.s = GetHTTPHeader(URL, #Null, UserAgent)
    Debug Raw
    Protected i.i = FindString(Raw, "Content-Length: ")
    Protected j.i = FindString(Raw, #CRLF$, i)
    If (i And j)
      Result = Val(Mid(Raw, i + Len("Content-Length: "), j - i - Len("Content-Length: ")))
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LoadImageURL(Image.i, URL.s)
  Protected Result.i = #Null
  Protected *Buffer = ReceiveHTTPMemory(URL)
  If (*Buffer)
    Result = CatchImage(Image, *Buffer, MemorySize(*Buffer))
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf
;-
