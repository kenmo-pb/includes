; +--------+
; | os.pbi |
; +--------+
; | 2014.01.01 . Added character constants/macros
; |        .09 . Added SameFile and NotS
; |        .17 . Added requester constants (such as #OS_YesNoCancel)
; |        .24 . Removed NotS macro (moved to common.pbi)
; |     .07.03 . Cleaned up OS macros, Win/Mac Elses, character constants
; | 2016.04.08 . Added OnWindows/OnLinux/OnMac single-statement macros
; | 2017.02.02 . Made multiple-include safe


CompilerIf (Not Defined(__OS_Included, #PB_Constant))
#__OS_Included = #True

;-
;- OS Macros

CompilerSelect (#PB_Compiler_OS)

  CompilerCase (#PB_OS_Windows)
    Macro WLMO(Windows, Linux, Mac, Other)
      Windows
    EndMacro
    
  CompilerCase (#PB_OS_Linux)
    Macro WLMO(Windows, Linux, Mac, Other)
      Linux
    EndMacro
    
  CompilerCase (#PB_OS_MacOS)
    Macro WLMO(Windows, Linux, Mac, Other)
      Mac
    EndMacro
    
  CompilerDefault
    Macro WLMO(Windows, Linux, Mac, Other)
      Other
    EndMacro
    
CompilerEndSelect


CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
  Macro WindowsElse(This, That)
    This
  EndMacro
  Macro OnWindows(_Statement)
    _Statement
  EndMacro
CompilerElse
  Macro WindowsElse(This, That)
    That
  EndMacro
  Macro OnWindows(_Statement)
    ;
  EndMacro
CompilerEndIf


CompilerIf (#PB_Compiler_OS = #PB_OS_Linux)
  Macro LinuxElse(This, That)
    This
  EndMacro
  Macro OnLinux(_Statement)
    _Statement
  EndMacro
CompilerElse
  Macro LinuxElse(This, That)
    That
  EndMacro
  Macro OnLinux(_Statement)
    ;
  EndMacro
CompilerEndIf


CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
  Macro MacElse(This, That)
    This
  EndMacro
  Macro OnMac(_Statement)
    _Statement
  EndMacro
  Macro LaunchFile(FileName)
    RunProgram("open", FileName, GetPathPart(FileName))
  EndMacro
  Macro EditTextFile(FileName)
    RunProgram("open", "-e " + Quote(FileName), GetPathPart(FileName))
  EndMacro
CompilerElse
  Macro MacElse(This, That)
    That
  EndMacro
  Macro OnMac(_Statement)
    ;
  EndMacro
  Macro LaunchFile(FileName)
    RunProgram(FileName, "", GetPathPart(FileName))
  EndMacro
  Macro EditTextFile(FileName)
    LaunchFile(FileName)
  EndMacro
CompilerEndIf


;-
;- OS Constants

#Windows =  WindowsElse(#True, #False)
#Linux   =  LinuxElse(#True, #False)
#Mac     =  MacElse(#True, #False)
;
#OpenGL  =  WLMO(Subsystem("opengl"), Subsystem("opengl"), #False, #False)
#DirectX =  WLMO((1 - #OpenGL), #False, #False, #False)
#SDL     =  WLMO(#False, (1 - #OpenGL), #False, #False)
#Carbon  =  WLMO(#False, #False, Subsystem("carbon"), #False)
#Cocoa   =  WLMO(#False, #False, (1 - #Carbon), #False)
;
#OS      =  WLMO(#PB_OS_Windows, #PB_OS_Linux, #PB_OS_MacOS, #Null)
#OS$     =  WLMO("Windows", "Linux", "Mac", "")
#PS$     =  WindowsElse("\", "/")
#NPS$    =  WindowsElse("/", "\")
#EOL$    =  WindowsElse(#CRLF$, #LF$)
#CTRL$   =  MacElse("Cmd", "Ctrl")
#CTRLp$  = #CTRL$ + "+"
#tCTRLp$ = #TAB$ + #CTRLp$
;
#NUL     = $00
#SP      = ' '
#SP$     = " "
#SQ      = $27
#SQ$     = "'"
#DQ      = $22
#DQ$     = #DQUOTE$
#LFLF$   = #LF$ + #LF$
;
CompilerIf (#PB_Compiler_Unicode)
  #EL  = $2026
CompilerElseIf (#Mac)
  #EL  = $C9
CompilerElse
  #EL  = $85
CompilerEndIf
CompilerIf (#Mac And (Not #PB_Compiler_Unicode))
  #EL$ = "..."
CompilerElse
  #EL$ = Chr(#EL)
CompilerEndIf
;
#Debugger = #PB_Compiler_Debugger
;
CompilerIf (#PB_Compiler_Version >= 550)
  #OS_Icon_Information = #PB_MessageRequester_Info
  #OS_Icon_Warning     = #PB_MessageRequester_Warning
  #OS_Icon_Error       = #PB_MessageRequester_Error
  #OS_Icon_Question    = WindowsElse(#MB_ICONQUESTION,    #Null)
CompilerElse
  #OS_Icon_Information = WindowsElse(#MB_ICONINFORMATION, #Null)
  #OS_Icon_Warning     = WindowsElse(#MB_ICONWARNING,     #Null)
  #OS_Icon_Error       = WindowsElse(#MB_ICONERROR,       #Null)
  #OS_Icon_Question    = WindowsElse(#MB_ICONQUESTION,    #Null)
CompilerEndIf
;
#OS_Yes         = #PB_MessageRequester_Yes
#OS_No          = #PB_MessageRequester_No
#OS_Cancel      = #PB_MessageRequester_Cancel
#OS_YesNo       = #PB_MessageRequester_YesNo
#OS_YesNoCancel = #PB_MessageRequester_YesNoCancel
;
CompilerIf (#Windows)
  #OS_Shortcut_TabNext     = 64001
  #OS_Shortcut_TabPrevious = 64002
CompilerElse
  ;
CompilerEndIf
;
#YES = #True
#NO  = #False

;-
;- Color Constants

#Black   = $000000
#White   = $FFFFFF
#Red     = $0000FF
#Green   = $00FF00
#Blue    = $FF0000
#Cyan    = $FFFF00
#Magenta = $FF00FF
#Yellow  = $00FFFF

#OpaqueBlack   = #Black   | $FF000000
#OpaqueWhite   = #White   | $FF000000
#OpaqueRed     = #Red     | $FF000000
#OpaqueGreen   = #Green   | $FF000000
#OpaqueBlue    = #Blue    | $FF000000
#OpaqueCyan    = #Cyan    | $FF000000
#OpaqueMagenta = #Magenta | $FF000000
#OpaqueYellow  = #Yellow  | $FF000000

CompilerIf (#Windows)
  Enumeration
    #Console_Black
    #Console_DarkBlue
    #Console_DarkGreen
    #Console_DarkCyan
    #Console_DarkRed
    #Console_DarkMagenta
    #Console_DarkYellow
    #Console_Gray
    #Console_DarkGray
    #Console_Blue
    #Console_Green
    #Console_Cyan
    #Console_Red
    #Console_Magenta
    #Console_Yellow
    #Console_White
  EndEnumeration
  #Console_DefaultForeground = #Console_Gray
  #Console_DefaultBackground = #Console_Black
CompilerEndIf

;-
;- Character Constants

CompilerIf (#PB_Compiler_Unicode)
  #Unicode    = #True
  #Ascii      = #False
  #CharSize   =  2
  ;
  #StringMode     = #PB_Unicode
  #StringModeName = "Unicode"
  #StringFileMode = #PB_UTF8
  ;
  Macro ToChars(Bytes)
    ((Bytes)/2)
  EndMacro
  Macro ToBytes(Chars)
    ((Chars)*2)
  EndMacro
CompilerElse
  #Ascii      = #True
  #Unicode    = #False
  #CharSize   =  1
  ;
  #StringMode     = #PB_Ascii
  #StringModeName = "ASCII"
  #StringFileMode = #PB_Ascii
  ;
  Macro ToChars(Bytes)
    (Bytes)
  EndMacro
  Macro ToBytes(Chars)
    (Chars)
  EndMacro
CompilerEndIf

;-
;- CPU Macros

CompilerIf (SizeOf(INTEGER) = 8)
  #IntSize =  8
  #Is64Bit = #True
  #Is32Bit = #False
CompilerElse
  #IntSize =  4
  #Is64Bit = #False
  #Is32Bit = #True
CompilerEndIf

;-
;- File Macros

CompilerIf (#Windows)
  Macro SameFile(File1, File2)
    Bool(LCase(File1) = LCase(File2))
  EndMacro
CompilerElse
  Macro SameFile(File1, File2)
    Bool(File1 = File2)
  EndMacro
CompilerEndIf

CompilerEndIf

;-