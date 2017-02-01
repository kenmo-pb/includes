; +------------+
; | Winamp.pbi |
; +------------+
; | 2015.04.14 . Creation (PureBasic 5.31)
; | 2017.02.01 . Made multiple-include safe

CompilerIf (Not Defined(__Winamp_Included, #PB_Constant))
#__Winamp_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;-
;- Constants

#Winamp_Status_Stopped = 0
#Winamp_Status_Playing = 1
#Winamp_Status_Paused  = 2

Enumeration ; WM_COMMAND
  #Winamp_Command_PreviousTrack    = 40044
  #Winamp_Command_NextTrack        = 40048
  #Winamp_Command_Play             = 40045
  #Winamp_Command_PauseResume      = 40046
  #Winamp_Command_Stop             = 40047
  #Winamp_Command_StopFadeout      = 40147
  #Winamp_Command_StopAfterCurrent = 40157
  #Winamp_Command_Forward5Seconds  = 40148
  #Winamp_Command_Rewind5Seconds   = 40144
  #Winamp_Command_StartOfPlaylist  = 40154
  ; ...
  #Winamp_Command_ToggleRepeat     = 40022
  #Winamp_Command_ToggleShuffle    = 40023
  ; ...
EndEnumeration

Enumeration ; WM_USER
  ; ...
  #Winamp_User_PlayTrack     = 100
  #Winamp_User_ClearPlaylist = 101
  #Winamp_User_BeginTrack    = 102
  ; ...
  #Winamp_User_GetStatus     = 104
  ; ...
  #Winamp_User_GetShuffle    = 250
  #Winamp_User_GetRepeat     = 251
  #Winamp_User_SetShuffle    = 252
  #Winamp_User_SetRepeat     = 253
EndEnumeration



;-
;- Variables

Global _hwndWinamp.i = #Null




;-
;- Macros (Private)

Macro _Winamp_Command(Command)
  SendMessage_(_hwndWinamp, #WM_COMMAND, (Command), #Null)
EndMacro

Macro _Winamp_User(ID, UserData = #Null)
  SendMessage_(_hwndWinamp, #WM_USER, (UserData), (ID))
EndMacro






;-
;- Macros (Public)

Macro Winamp_Play()
  _Winamp_Command(#Winamp_Command_Play)
EndMacro

Macro Winamp_Stop()
  _Winamp_Command(#Winamp_Command_Stop)
EndMacro

Macro Winamp_PlayTrack()
  _Winamp_User(#Winamp_User_PlayTrack)
EndMacro

Macro Winamp_BeginTrack()
  _Winamp_User(#Winamp_User_BeginTrack)
EndMacro

Macro Winamp_GetStatus()
  _Winamp_User(#Winamp_User_GetStatus)
EndMacro

Macro Winamp_GetShuffle()
  _Winamp_User(#Winamp_User_GetShuffle)
EndMacro

Macro Winamp_GetRepeat()
  _Winamp_User(#Winamp_User_GetRepeat)
EndMacro

Macro Winamp_ToggleRepeat()
  _Winamp_Command(#Winamp_Command_ToggleRepeat)
EndMacro

Macro Winamp_SetShuffle(State)
  _Winamp_User(#Winamp_User_SetShuffle, Bool(State))
EndMacro

Macro Winamp_SetRepeat(State)
  _Winamp_User(#Winamp_User_SetRepeat, Bool(State))
EndMacro

Macro Winamp_ToggleShuffle()
  _Winamp_Command(#Winamp_Command_ToggleShuffle)
EndMacro

Macro Winamp_IsPlaying()
  Bool(Winamp_GetStatus() = #Winamp_Status_Playing)
EndMacro

Macro Winamp_IsPaused()
  Bool(Winamp_GetStatus() = #Winamp_Status_Paused)
EndMacro

Macro Winamp_IsStopped()
  Bool(Winamp_GetStatus() = #Winamp_Status_Stopped)
EndMacro





;-
;- Procedures

Procedure.i Winamp_Init()
  _hwndWinamp = FindWindow_("Winamp v1.x", #Null)
  ProcedureReturn (_hwndWinamp)
EndProcedure

Procedure.i Winamp_IsClosed()
  If (_hwndWinamp)
    If (IsWindow_(_hwndWinamp))
      ProcedureReturn (#False)
    Else
      _hwndWinamp = #Null
      ProcedureReturn (#True)
    EndIf
  Else
    ProcedureReturn (#True)
  EndIf
EndProcedure


CompilerEndIf
;-