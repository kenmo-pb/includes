; +----------+
; | OS_Names |
; +----------+
; | 2014.12.02 . Creation (PureBasic 5.31)
; |        .05 . Added future support for Win 10, OS X 10.9 and 10.10
; | 2015.07.16 . Added (incomplete) list of OS X nickname constants
; |        .28 . Added OS X 10.11 (El Capitan)
; | 2017.05.18 . Multiple-include safe
; | 2018.02.22 . Placeholders for OS X 10.12, 10.13
; | 2021-09-21 . Placeholders for macOS 10.14, 10.15

;-
CompilerIf (Not Defined(__OS_Names_Included, #PB_Constant))
#__OS_Names_Included = #True


;- Constants (Public)

; MacOSX version aliases
#PB_OS_MacOSX_Leopard      = #PB_OS_MacOSX_10_5
#PB_OS_MacOSX_SnowLeopard  = #PB_OS_MacOSX_10_6
#PB_OS_MacOSX_Lion         = #PB_OS_MacOSX_10_7
#PB_OS_MacOSX_MountainLion = #PB_OS_MacOSX_10_8
CompilerIf (Defined(PB_OS_MacOSX_10_9, #PB_Constant))
  #PB_OS_MacOSX_Mavericks = #PB_OS_MacOSX_10_9
CompilerEndIf
CompilerIf (Defined(PB_OS_MacOSX_10_10, #PB_Constant))
  #PB_OS_MacOSX_Yosemite = #PB_OS_MacOSX_10_10
CompilerEndIf
CompilerIf (Defined(PB_OS_MacOSX_10_11, #PB_Constant))
  #PB_OS_MacOSX_ElCapitan = #PB_OS_MacOSX_10_11
CompilerEndIf

; Older MacOSX version aliases - uncomment if desired
;#PB_OS_MacOSX_Cheetah      = #PB_OS_MacOSX_10_0
;#PB_OS_MacOSX_Puma         = #PB_OS_MacOSX_10_1
;#PB_OS_MacOSX_Jaguar       = #PB_OS_MacOSX_10_2
;#PB_OS_MacOSX_Panther      = #PB_OS_MacOSX_10_3
;#PB_OS_MacOSX_Tiger        = #PB_OS_MacOSX_10_4



;-
;- Structures (Private)

Structure _OS_Pair
  Value.i
  Name.s
EndStructure



;-
;- Procedures (Public)

Procedure.s OSName()
  CompilerSelect (#PB_Compiler_OS)
    CompilerCase (#PB_OS_Windows)
      ProcedureReturn "Windows"
    CompilerCase (#PB_OS_Linux)
      ProcedureReturn "Linux"
    CompilerCase (#PB_OS_MacOS)
      ProcedureReturn "Mac OS X"
    CompilerCase (#PB_OS_AmigaOS)
      ProcedureReturn "Amiga"
    CompilerDefault
      CompilerError "Target OS not recognized"
  CompilerEndSelect
EndProcedure

Procedure.s OSVersionName()
  Protected *Pair._OS_Pair = ?_OS_VersionNames
  While (*Pair\Value)
    If (*Pair\Value = OSVersion())
      ProcedureReturn *Pair\Name
    EndIf
    *Pair + SizeOf(_OS_Pair)
  Wend
  ProcedureReturn OSName()
EndProcedure




;-
;- Data Section (OS Version Names)

DataSection
  
  _OS_VersionNames:
  
  ;- - Windows
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Data.i #PB_OS_Windows_NT3_51
    Data.i @"Windows NT 3.51"
    Data.i #PB_OS_Windows_95
    Data.i @"Windows 95"
    Data.i #PB_OS_Windows_NT_4
    Data.i @"Windows NT 4.0"
    Data.i #PB_OS_Windows_98
    Data.i @"Windows 98"
    Data.i #PB_OS_Windows_ME
    Data.i @"Windows ME"
    Data.i #PB_OS_Windows_2000
    Data.i @"Windows 2000"
    Data.i #PB_OS_Windows_XP
    Data.i @"Windows XP"
    Data.i #PB_OS_Windows_Server_2003
    Data.i @"Windows Server 2003"
    Data.i #PB_OS_Windows_Vista
    Data.i @"Windows Vista"
    Data.i #PB_OS_Windows_Server_2008
    Data.i @"Windows Server 2008"
    Data.i #PB_OS_Windows_7
    Data.i @"Windows 7"
    Data.i #PB_OS_Windows_Server_2008_R2
    Data.i @"Windows Server 2008 R2"
    Data.i #PB_OS_Windows_8
    Data.i @"Windows 8"
    Data.i #PB_OS_Windows_Server_2012
    Data.i @"Windows Server 2012"
    CompilerIf (Defined(PB_OS_Windows_10, #PB_Constant))
      Data.i #PB_OS_Windows_10
      Data.i @"Windows 10"
    CompilerEndIf
  CompilerEndIf
  
  ;- - Mac
  CompilerIf (#PB_Compiler_OS = #PB_OS_MacOS)
    Data.i #PB_OS_MacOSX_10_0
    Data.i @"OS X 10.0"
    Data.i #PB_OS_MacOSX_10_1
    Data.i @"OS X 10.1"
    Data.i #PB_OS_MacOSX_10_2
    Data.i @"OS X 10.2"
    Data.i #PB_OS_MacOSX_10_3
    Data.i @"OS X 10.3"
    Data.i #PB_OS_MacOSX_10_4
    Data.i @"OS X 10.4"
    Data.i #PB_OS_MacOSX_10_5
    Data.i @"OS X 10.5"
    Data.i #PB_OS_MacOSX_10_6
    Data.i @"OS X 10.6"
    Data.i #PB_OS_MacOSX_10_7
    Data.i @"OS X 10.7"
    Data.i #PB_OS_MacOSX_10_8
    Data.i @"OS X 10.8"
    CompilerIf (Defined(PB_OS_MacOSX_10_9, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_9
      Data.i @"OS X 10.9"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_10, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_10
      Data.i @"OS X 10.10"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_11, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_11
      Data.i @"OS X 10.11"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_12, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_12
      Data.i @"OS X 10.12"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_13, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_13
      Data.i @"OS X 10.13"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_14, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_14
      Data.i @"macOS 10.14"
    CompilerEndIf
    CompilerIf (Defined(PB_OS_MacOSX_10_15, #PB_Constant))
      Data.i #PB_OS_MacOSX_10_15
      Data.i @"macOS 10.15"
    CompilerEndIf
  CompilerEndIf
  
  ;- - Linux
  CompilerIf (#PB_Compiler_OS = #PB_OS_Linux)
    Data.i #PB_OS_Linux_2_2
    Data.i @"Linux 2.2"
    Data.i #PB_OS_Linux_2_4
    Data.i @"Linux 2.4"
    Data.i #PB_OS_Linux_2_6
    Data.i @"Linux 2.6"
  CompilerEndIf
  
  Data.i #Null, #Null
  
EndDataSection




;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  Debug "OSName() = " + OSName()
  Debug "OSVersionName() = " + OSVersionName()
CompilerEndIf

CompilerEndIf
;-
