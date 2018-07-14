; +------+----------------------------+
; | PSDL | SDL Bindings For PureBasic |
; +------+----------------------------+
; | 2015.01.13 . Creation (PureBasic 5.31)
; |        .19 . Added C-compatible structure alignment

;-
CompilerIf (Not Defined(_PSDL_Included, #PB_Constant))
#_PSDL_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;  NOTES:
;  On Windows: Use VC version (.lib and .dll), not MinGW version (.a)

;- Compile Switches

;   Constant                   Description
; --------------------------  --------------------------------------------------
;  #PSDL_IncludeLibrary        Set #True to load DLL pointers instead of Import
;  #PSDL_NoDataSection         Set #True to not include internal DLL file
;  #PSDL_TempRuntime           Change the temp DLL filename (without path)
;  #PSDL_ImportLib             Filename for Importing functions (Win: lib)
;  #PSDL_Runtime               Filename for loading at runtime (Win: dll)
;  #PSDL_RuntimeInclude        Filename (path optional) for including DLL
;  #PSDL_UseASCIIStrings       Force ASCII instead of UTF-8 prototypes

CompilerIf (Not Defined(PSDL_IncludeLibrary, #PB_Constant))
  #PSDL_IncludeLibrary = #False
CompilerEndIf

CompilerIf (Not Defined(PSDL_NoDataSection, #PB_Constant))
  #PSDL_NoDataSection = #False
CompilerEndIf

CompilerIf (Not Defined(PSDL_TempRuntime, #PB_Constant))
  #PSDL_TempRuntime = ""
CompilerEndIf

CompilerSelect (#PB_Compiler_OS)
  
  CompilerCase (#PB_OS_Windows)
    CompilerIf (Not Defined(PSDL_ImportLib, #PB_Constant))
      #PSDL_ImportLib = "SDL2.lib"
      #PSDL_Runtime   = "SDL2.dll"
    CompilerEndIf
  
  CompilerDefault
    CompilerError "PSDL is not configured for this OS"
    
CompilerEndSelect

CompilerIf (Not Defined(PSDL_RuntimeInclude, #PB_Constant))
  #PSDL_RuntimeInclude = #PB_Compiler_Home + "Compilers/" + #PSDL_Runtime
CompilerEndIf

CompilerIf (Not Defined(PSDL_UseASCIIStrings, #PB_Constant))
  CompilerIf (#PB_Compiler_Version < 531)
    #PSDL_UseASCIIStrings = #True
  CompilerElse
    #PSDL_UseASCIIStrings = #False
  CompilerEndIf
CompilerEndIf

CompilerIf (#PSDL_UseASCIIStrings)
  Macro _PSDL_String
    p-ascii
  EndMacro
CompilerElse
  Macro _PSDL_String
    p-utf8
  EndMacro
CompilerEndIf


;-
;- SDL Constants

; Standard Include

Enumeration ; SDL_bool
  #SDL_FALSE = 0
  #SDL_TRUE  = 1
EndEnumeration

; Initialization and Shutdown

Enumeration ; flags for SDL_Init()
  #SDL_INIT_TIMER          = $00000001
  #SDL_INIT_AUDIO          = $00000010
  #SDL_INIT_VIDEO          = $00000020 ; implies EVENTS
  #SDL_INIT_JOYSTICK       = $00000200 ; implies EVENTS
  #SDL_INIT_HAPTIC         = $00001000
  #SDL_INIT_GAMECONTROLLER = $00002000 ; implies JOYSTICK
  #SDL_INIT_EVENTS         = $00004000
  #SDL_INIT_NOPARACHUTE    = $00100000
  #SDL_INIT_EVERYTHING     = #SDL_INIT_TIMER | #SDL_INIT_AUDIO | #SDL_INIT_VIDEO | #SDL_INIT_EVENTS | #SDL_INIT_JOYSTICK | #SDL_INIT_HAPTIC | #SDL_INIT_GAMECONTROLLER
EndEnumeration

; Configuration Variables

#SDL_HINT_RENDER_SCALE_QUALITY = "SDL_HINT_RENDER_SCALE_QUALITY"

Enumeration ; SDL_HintPriority
  #SDL_HINT_DEFAULT
  #SDL_HINT_NORMAL
  #SDL_HINT_OVERRIDE
EndEnumeration

; Display and Window Management

#SDL_WINDOWPOS_UNDEFINED_MASK = $1FFF0000
Macro SDL_WINDOWPOS_UNDEFINED_DISPLAY(X)
  (#SDL_WINDOWPOS_UNDEFINED_MASK|(X))
EndMacro
#SDL_WINDOWPOS_UNDEFINED = SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)

#SDL_WINDOWPOS_CENTERED_MASK = $2FFF0000
Macro SDL_WINDOWPOS_CENTERED_DISPLAY(X)
  (#SDL_WINDOWPOS_CENTERED_MASK|(X))
EndMacro
#SDL_WINDOWPOS_CENTERED = SDL_WINDOWPOS_CENTERED_DISPLAY(0)

Enumeration ; SDL_WindowFlags
  #SDL_WINDOW_FULLSCREEN         = $00000001
  #SDL_WINDOW_OPENGL             = $00000002
  #SDL_WINDOW_SHOWN              = $00000004
  #SDL_WINDOW_HIDDEN             = $00000008
  #SDL_WINDOW_BORDERLESS         = $00000010
  #SDL_WINDOW_RESIZABLE          = $00000020
  #SDL_WINDOW_MINIMIZED          = $00000040
  #SDL_WINDOW_MAXIMIZED          = $00000080
  #SDL_WINDOW_INPUT_GRABBED      = $00000100
  #SDL_WINDOW_INPUT_FOCUS        = $00000200
  #SDL_WINDOW_MOUSE_FOCUS        = $00000400
  #SDL_WINDOW_FULLSCREEN_DESKTOP = $00001000 | #SDL_WINDOW_FULLSCREEN
  #SDL_WINDOW_FOREIGN            = $00000800
  #SDL_WINDOW_ALLOW_HIGHDPI      = $00002000
EndEnumeration

; 2D Accelerated Rendering

#SDL_ALPHA_OPAQUE      = 255
#SDL_ALPHA_TRANSPARENT =   0

Enumeration ; SDL_TextureAccess
  #SDL_TEXTUREACCESS_STATIC
  #SDL_TEXTUREACCESS_STREAMING
  #SDL_TEXTUREACCESS_TARGET
EndEnumeration

Enumeration ; SDL_BlendMode
  #SDL_BLENDMODE_NONE  = $00000000
  #SDL_BLENDMODE_BLEND = $00000001
  #SDL_BLENDMODE_ADD   = $00000002
  #SDL_BLENDMODE_MOD   = $00000004
EndEnumeration

Enumeration ; SDL_RendererFlags
  #SDL_RENDERER_SOFTWARE      = $00000001
  #SDL_RENDERER_ACCELERATED   = $00000002
  #SDL_RENDERER_PRESENTVSYNC  = $00000004
  #SDL_RENDERER_TARGETTEXTURE = $00000008
EndEnumeration

Enumeration ; SDL_RendererFlip
  #SDL_FLIP_NONE       = $00000000
  #SDL_FLIP_HORIZONTAL = $00000001
  #SDL_FLIP_VERTICAL   = $00000002
EndEnumeration

; Event Handling

Enumeration ; SDL_eventaction
  #SDL_ADDEVENT
  #SDL_PEEKEVENT
  #SDL_GETEVENT
EndEnumeration

#SDL_TEXTEDITINGEVENT_TEXT_SIZE = 32
#SDL_TEXTINPUTEVENT_TEXT_SIZE   = 32

Enumeration ; button for SDL_MouseButtonEvent
  #SDL_BUTTON_LEFT   = 1
  #SDL_BUTTON_MIDDLE = 2
  #SDL_BUTTON_RIGHT  = 3
  #SDL_BUTTON_X1     = 4
  #SDL_BUTTON_X2     = 5
EndEnumeration

; Keyboard Support

Enumeration ; SDL_Scancode
  #SDL_SCANCODE_UNKNOWN = 0
  #SDL_SCANCODE_A = 4
  #SDL_SCANCODE_B = 5
  #SDL_SCANCODE_C = 6
  #SDL_SCANCODE_D = 7
  #SDL_SCANCODE_E = 8
  #SDL_SCANCODE_F = 9
  #SDL_SCANCODE_G = 10
  #SDL_SCANCODE_H = 11
  #SDL_SCANCODE_I = 12
  #SDL_SCANCODE_J = 13
  #SDL_SCANCODE_K = 14
  #SDL_SCANCODE_L = 15
  #SDL_SCANCODE_M = 16
  #SDL_SCANCODE_N = 17
  #SDL_SCANCODE_O = 18
  #SDL_SCANCODE_P = 19
  #SDL_SCANCODE_Q = 20
  #SDL_SCANCODE_R = 21
  #SDL_SCANCODE_S = 22
  #SDL_SCANCODE_T = 23
  #SDL_SCANCODE_U = 24
  #SDL_SCANCODE_V = 25
  #SDL_SCANCODE_W = 26
  #SDL_SCANCODE_X = 27
  #SDL_SCANCODE_Y = 28
  #SDL_SCANCODE_Z = 29
  #SDL_SCANCODE_1 = 30
  #SDL_SCANCODE_2 = 31
  #SDL_SCANCODE_3 = 32
  #SDL_SCANCODE_4 = 33
  #SDL_SCANCODE_5 = 34
  #SDL_SCANCODE_6 = 35
  #SDL_SCANCODE_7 = 36
  #SDL_SCANCODE_8 = 37
  #SDL_SCANCODE_9 = 38
  #SDL_SCANCODE_0 = 39
  #SDL_SCANCODE_RETURN = 40
  #SDL_SCANCODE_ESCAPE = 41
  #SDL_SCANCODE_BACKSPACE = 42
  #SDL_SCANCODE_TAB = 43
  #SDL_SCANCODE_SPACE = 44
  #SDL_SCANCODE_MINUS = 45
  #SDL_SCANCODE_EQUALS = 46
  #SDL_SCANCODE_LEFTBRACKET = 47
  #SDL_SCANCODE_RIGHTBRACKET = 48
  #SDL_SCANCODE_BACKSLASH = 49
  #SDL_SCANCODE_NONUSHASH = 50
  #SDL_SCANCODE_SEMICOLON = 51
  #SDL_SCANCODE_APOSTROPHE = 52
  #SDL_SCANCODE_GRAVE = 53
  #SDL_SCANCODE_COMMA = 54
  #SDL_SCANCODE_PERIOD = 55
  #SDL_SCANCODE_SLASH = 56
  #SDL_SCANCODE_CAPSLOCK = 57
  #SDL_SCANCODE_F1 = 58
  #SDL_SCANCODE_F2 = 59
  #SDL_SCANCODE_F3 = 60
  #SDL_SCANCODE_F4 = 61
  #SDL_SCANCODE_F5 = 62
  #SDL_SCANCODE_F6 = 63
  #SDL_SCANCODE_F7 = 64
  #SDL_SCANCODE_F8 = 65
  #SDL_SCANCODE_F9 = 66
  #SDL_SCANCODE_F10 = 67
  #SDL_SCANCODE_F11 = 68
  #SDL_SCANCODE_F12 = 69
  #SDL_SCANCODE_PRINTSCREEN = 70
  #SDL_SCANCODE_SCROLLLOCK = 71
  #SDL_SCANCODE_PAUSE = 72
  #SDL_SCANCODE_INSERT = 73
  #SDL_SCANCODE_HOME = 74
  #SDL_SCANCODE_PAGEUP = 75
  #SDL_SCANCODE_DELETE = 76
  #SDL_SCANCODE_END = 77
  #SDL_SCANCODE_PAGEDOWN = 78
  #SDL_SCANCODE_RIGHT = 79
  #SDL_SCANCODE_LEFT = 80
  #SDL_SCANCODE_DOWN = 81
  #SDL_SCANCODE_UP = 82
  #SDL_SCANCODE_NUMLOCKCLEAR = 83
  #SDL_SCANCODE_KP_DIVIDE = 84
  #SDL_SCANCODE_KP_MULTIPLY = 85
  #SDL_SCANCODE_KP_MINUS = 86
  #SDL_SCANCODE_KP_PLUS = 87
  #SDL_SCANCODE_KP_ENTER = 88
  #SDL_SCANCODE_KP_1 = 89
  #SDL_SCANCODE_KP_2 = 90
  #SDL_SCANCODE_KP_3 = 91
  #SDL_SCANCODE_KP_4 = 92
  #SDL_SCANCODE_KP_5 = 93
  #SDL_SCANCODE_KP_6 = 94
  #SDL_SCANCODE_KP_7 = 95
  #SDL_SCANCODE_KP_8 = 96
  #SDL_SCANCODE_KP_9 = 97
  #SDL_SCANCODE_KP_0 = 98
  #SDL_SCANCODE_KP_PERIOD = 99
  #SDL_SCANCODE_NONUSBACKSLASH = 100
  #SDL_SCANCODE_APPLICATION = 101
  #SDL_SCANCODE_POWER = 102
  #SDL_SCANCODE_KP_EQUALS = 103
  #SDL_SCANCODE_F13 = 104
  #SDL_SCANCODE_F14 = 105
  #SDL_SCANCODE_F15 = 106
  #SDL_SCANCODE_F16 = 107
  #SDL_SCANCODE_F17 = 108
  #SDL_SCANCODE_F18 = 109
  #SDL_SCANCODE_F19 = 110
  #SDL_SCANCODE_F20 = 111
  #SDL_SCANCODE_F21 = 112
  #SDL_SCANCODE_F22 = 113
  #SDL_SCANCODE_F23 = 114
  #SDL_SCANCODE_F24 = 115
  #SDL_SCANCODE_EXECUTE = 116
  #SDL_SCANCODE_HELP = 117
  #SDL_SCANCODE_MENU = 118
  #SDL_SCANCODE_SELECT = 119
  #SDL_SCANCODE_STOP = 120
  #SDL_SCANCODE_AGAIN = 121
  #SDL_SCANCODE_UNDO = 122
  #SDL_SCANCODE_CUT = 123
  #SDL_SCANCODE_COPY = 124
  #SDL_SCANCODE_PASTE = 125
  #SDL_SCANCODE_FIND = 126
  #SDL_SCANCODE_MUTE = 127
  #SDL_SCANCODE_VOLUMEUP = 128
  #SDL_SCANCODE_VOLUMEDOWN = 129
  #SDL_SCANCODE_KP_COMMA = 133
  #SDL_SCANCODE_KP_EQUALSAS400 = 134
  #SDL_SCANCODE_INTERNATIONAL1 = 135
  #SDL_SCANCODE_INTERNATIONAL2 = 136
  #SDL_SCANCODE_INTERNATIONAL3 = 137
  #SDL_SCANCODE_INTERNATIONAL4 = 138
  #SDL_SCANCODE_INTERNATIONAL5 = 139
  #SDL_SCANCODE_INTERNATIONAL6 = 140
  #SDL_SCANCODE_INTERNATIONAL7 = 141
  #SDL_SCANCODE_INTERNATIONAL8 = 142
  #SDL_SCANCODE_INTERNATIONAL9 = 143
  #SDL_SCANCODE_LANG1 = 144
  #SDL_SCANCODE_LANG2 = 145
  #SDL_SCANCODE_LANG3 = 146
  #SDL_SCANCODE_LANG4 = 147
  #SDL_SCANCODE_LANG5 = 148
  #SDL_SCANCODE_LANG6 = 149
  #SDL_SCANCODE_LANG7 = 150
  #SDL_SCANCODE_LANG8 = 151
  #SDL_SCANCODE_LANG9 = 152
  #SDL_SCANCODE_ALTERASE = 153
  #SDL_SCANCODE_SYSREQ = 154
  #SDL_SCANCODE_CANCEL = 155
  #SDL_SCANCODE_CLEAR = 156
  #SDL_SCANCODE_PRIOR = 157
  #SDL_SCANCODE_RETURN2 = 158
  #SDL_SCANCODE_SEPARATOR = 159
  #SDL_SCANCODE_OUT = 160
  #SDL_SCANCODE_OPER = 161
  #SDL_SCANCODE_CLEARAGAIN = 162
  #SDL_SCANCODE_CRSEL = 163
  #SDL_SCANCODE_EXSEL = 164
  #SDL_SCANCODE_KP_00 = 176
  #SDL_SCANCODE_KP_000 = 177
  #SDL_SCANCODE_THOUSANDSSEPARATOR = 178
  #SDL_SCANCODE_DECIMALSEPARATOR = 179
  #SDL_SCANCODE_CURRENCYUNIT = 180
  #SDL_SCANCODE_CURRENCYSUBUNIT = 181
  #SDL_SCANCODE_KP_LEFTPAREN = 182
  #SDL_SCANCODE_KP_RIGHTPAREN = 183
  #SDL_SCANCODE_KP_LEFTBRACE = 184
  #SDL_SCANCODE_KP_RIGHTBRACE = 185
  #SDL_SCANCODE_KP_TAB = 186
  #SDL_SCANCODE_KP_BACKSPACE = 187
  #SDL_SCANCODE_KP_A = 188
  #SDL_SCANCODE_KP_B = 189
  #SDL_SCANCODE_KP_C = 190
  #SDL_SCANCODE_KP_D = 191
  #SDL_SCANCODE_KP_E = 192
  #SDL_SCANCODE_KP_F = 193
  #SDL_SCANCODE_KP_XOR = 194
  #SDL_SCANCODE_KP_POWER = 195
  #SDL_SCANCODE_KP_PERCENT = 196
  #SDL_SCANCODE_KP_LESS = 197
  #SDL_SCANCODE_KP_GREATER = 198
  #SDL_SCANCODE_KP_AMPERSAND = 199
  #SDL_SCANCODE_KP_DBLAMPERSAND = 200
  #SDL_SCANCODE_KP_VERTICALBAR = 201
  #SDL_SCANCODE_KP_DBLVERTICALBAR = 202
  #SDL_SCANCODE_KP_COLON = 203
  #SDL_SCANCODE_KP_HASH = 204
  #SDL_SCANCODE_KP_SPACE = 205
  #SDL_SCANCODE_KP_AT = 206
  #SDL_SCANCODE_KP_EXCLAM = 207
  #SDL_SCANCODE_KP_MEMSTORE = 208
  #SDL_SCANCODE_KP_MEMRECALL = 209
  #SDL_SCANCODE_KP_MEMCLEAR = 210
  #SDL_SCANCODE_KP_MEMADD = 211
  #SDL_SCANCODE_KP_MEMSUBTRACT = 212
  #SDL_SCANCODE_KP_MEMMULTIPLY = 213
  #SDL_SCANCODE_KP_MEMDIVIDE = 214
  #SDL_SCANCODE_KP_PLUSMINUS = 215
  #SDL_SCANCODE_KP_CLEAR = 216
  #SDL_SCANCODE_KP_CLEARENTRY = 217
  #SDL_SCANCODE_KP_BINARY = 218
  #SDL_SCANCODE_KP_OCTAL = 219
  #SDL_SCANCODE_KP_DECIMAL = 220
  #SDL_SCANCODE_KP_HEXADECIMAL = 221
  #SDL_SCANCODE_LCTRL = 224
  #SDL_SCANCODE_LSHIFT = 225
  #SDL_SCANCODE_LALT = 226
  #SDL_SCANCODE_LGUI = 227
  #SDL_SCANCODE_RCTRL = 228
  #SDL_SCANCODE_RSHIFT = 229
  #SDL_SCANCODE_RALT = 230
  #SDL_SCANCODE_RGUI = 231
  #SDL_SCANCODE_MODE = 257
  #SDL_SCANCODE_AUDIONEXT = 258
  #SDL_SCANCODE_AUDIOPREV = 259
  #SDL_SCANCODE_AUDIOSTOP = 260
  #SDL_SCANCODE_AUDIOPLAY = 261
  #SDL_SCANCODE_AUDIOMUTE = 262
  #SDL_SCANCODE_MEDIASELECT = 263
  #SDL_SCANCODE_WWW = 264
  #SDL_SCANCODE_MAIL = 265
  #SDL_SCANCODE_CALCULATOR = 266
  #SDL_SCANCODE_COMPUTER = 267
  #SDL_SCANCODE_AC_SEARCH = 268
  #SDL_SCANCODE_AC_HOME = 269
  #SDL_SCANCODE_AC_BACK = 270
  #SDL_SCANCODE_AC_FORWARD = 271
  #SDL_SCANCODE_AC_STOP = 272
  #SDL_SCANCODE_AC_REFRESH = 273
  #SDL_SCANCODE_AC_BOOKMARKS = 274
  #SDL_SCANCODE_BRIGHTNESSDOWN = 275
  #SDL_SCANCODE_BRIGHTNESSUP = 276
  #SDL_SCANCODE_DISPLAYSWITCH = 277
  #SDL_SCANCODE_KBDILLUMTOGGLE = 278
  #SDL_SCANCODE_KBDILLUMDOWN = 279
  #SDL_SCANCODE_KBDILLUMUP = 280
  #SDL_SCANCODE_EJECT = 281
  #SDL_SCANCODE_SLEEP = 282
  #SDL_SCANCODE_APP1 = 283
  #SDL_SCANCODE_APP2 = 284
  #SDL_NUM_SCANCODES = 512
EndEnumeration

Enumeration
  #SDL_FIRSTEVENT = 0
  #SDL_QUIT = $100
  #SDL_APP_TERMINATING
  #SDL_APP_LOWMEMORY
  #SDL_APP_WILLENTERBACKGROUND
  #SDL_APP_DIDENTERBACKGROUND
  #SDL_APP_WILLENTERFOREGROUND
  #SDL_APP_DIDENTERFOREGROUND
  #SDL_WINDOWEVENT = $200
  #SDL_SYSWMEVENT
  #SDL_KEYDOWN = $300
  #SDL_KEYUP
  #SDL_TEXTEDITING
  #SDL_TEXTINPUT
  #SDL_MOUSEMOTION = $400
  #SDL_MOUSEBUTTONDOWN
  #SDL_MOUSEBUTTONUP
  #SDL_MOUSEWHEEL
  #SDL_JOYAXISMOTION = $600
  #SDL_JOYBALLMOTION
  #SDL_JOYHATMOTION
  #SDL_JOYBUTTONDOWN
  #SDL_JOYBUTTONUP
  #SDL_JOYDEVICEADDED
  #SDL_JOYDEVICEREMOVED
  #SDL_CONTROLLERAXISMOTION = $650
  #SDL_CONTROLLERBUTTONDOWN
  #SDL_CONTROLLERBUTTONUP
  #SDL_CONTROLLERDEVICEADDED
  #SDL_CONTROLLERDEVICEREMOVED
  #SDL_CONTROLLERDEVICEREMAPPED
  #SDL_FINGERDOWN = $700
  #SDL_FINGERUP
  #SDL_FINGERMOTION
  #SDL_DOLLARGESTURE = $800
  #SDL_DOLLARRECORD
  #SDL_MULTIGESTURE
  #SDL_CLIPBOARDUPDATE = $900
  #SDL_DROPFILE = $1000
  #SDL_RENDER_TARGETS_RESET = $2000
  #SDL_USEREVENT = $8000
  #SDL_LASTEVENT = $FFFF
EndEnumeration

; Game Controller Support

Enumeration ; SDL_GameControllerButton
  #SDL_CONTROLLER_BUTTON_INVALID = -1
  #SDL_CONTROLLER_BUTTON_A
  #SDL_CONTROLLER_BUTTON_B
  #SDL_CONTROLLER_BUTTON_X
  #SDL_CONTROLLER_BUTTON_Y
  #SDL_CONTROLLER_BUTTON_BACK
  #SDL_CONTROLLER_BUTTON_GUIDE
  #SDL_CONTROLLER_BUTTON_START
  #SDL_CONTROLLER_BUTTON_LEFTSTICK
  #SDL_CONTROLLER_BUTTON_RIGHTSTICK
  #SDL_CONTROLLER_BUTTON_LEFTSHOULDER
  #SDL_CONTROLLER_BUTTON_RIGHTSHOULDER
  #SDL_CONTROLLER_BUTTON_DPAD_UP
  #SDL_CONTROLLER_BUTTON_DPAD_DOWN
  #SDL_CONTROLLER_BUTTON_DPAD_LEFT
  #SDL_CONTROLLER_BUTTON_DPAD_RIGHT
  #SDL_CONTROLLER_BUTTON_MAX
EndEnumeration

Enumeration ; SDL_GameControllerAxis
  #SDL_CONTROLLER_AXIS_INVALID = -1
  #SDL_CONTROLLER_AXIS_LEFTX
  #SDL_CONTROLLER_AXIS_LEFTY
  #SDL_CONTROLLER_AXIS_RIGHTX
  #SDL_CONTROLLER_AXIS_RIGHTY
  #SDL_CONTROLLER_AXIS_TRIGGERLEFT
  #SDL_CONTROLLER_AXIS_TRIGGERRIGHT
  #SDL_CONTROLLER_AXIS_MAX
EndEnumeration



;-
;- SDL Structures


Structure SDL_Version Align #PB_Structure_AlignC
  major.a
  minor.a
  patch.a
EndStructure

Structure SDL_Window
EndStructure

Structure SDL_Renderer
EndStructure

Structure SDL_Surface
EndStructure

Structure SDL_Texture
EndStructure

Structure SDL_Joystick
EndStructure

Structure SDL_GameController
EndStructure

Structure SDL_Haptic
EndStructure

Structure SDL_RWops
EndStructure

Structure SDL_Point Align #PB_Structure_AlignC
  x.i
  y.i
EndStructure

Structure SDL_Rect Align #PB_Structure_AlignC
  x.i
  y.i
  w.i
  h.i
EndStructure

Structure SDL_CommonEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
EndStructure

Structure SDL_WindowEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  event.a
  padding1.a
  padding2.a
  padding3.a
  data1.l
  data2.l
EndStructure

Structure SDL_Keysym Align #PB_Structure_AlignC
  scancode.l
  sym.l
  mod.u
  unused.l
EndStructure

Structure SDL_KeyboardEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  state.a
  repeatt.a
  padding2.a
  padding3.a
  keysym.SDL_Keysym
EndStructure

Structure SDL_TextEditingEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  text.a[#SDL_TEXTEDITINGEVENT_TEXT_SIZE]
  start.l
  length.l
EndStructure

Structure SDL_TextInputEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  text.a[#SDL_TEXTINPUTEVENT_TEXT_SIZE]
EndStructure

Structure SDL_MouseMotionEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  which.l
  state.l
  x.l
  y.l
  xrel.l
  yrel.l
EndStructure

Structure SDL_MouseButtonEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  windowID.l
  which.l
  button.a
  state.a
  clicks.a
  padding1.a
  x.l
  y.l
EndStructure

Structure SDL_JoyDeviceEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  which.l
EndStructure

Structure SDL_ControllerDeviceEvent Align #PB_Structure_AlignC
  type.l
  timestamp.l
  which.l
EndStructure

Structure SDL_Event Align #PB_Structure_AlignC
  StructureUnion
    type.l
    common.SDL_CommonEvent
    window.SDL_WindowEvent
    key.SDL_KeyboardEvent
    edit.SDL_TextEditingEvent
    text.SDL_TextInputEvent
    motion.SDL_MouseMotionEvent
    button.SDL_MouseButtonEvent
    ;wheel.SDL_MouseWheelEvent
    ;jaxis.SDL_JoyAxisEvent
    ;jball.SDL_JoyBallEvent
    ;jhat.SDL_JoyHatEvent
    ;jbutton.SDL_JoyButtonEvent
    jdevice.SDL_JoyDeviceEvent
    ;caxis.SDL_ControllerAxisEvent
    ;cbutton.SDL_ControllerButtonEvent
    cdevice.SDL_ControllerDeviceEvent
    ;quit.SDL_QuitEvent
    ;user.SDL_UserEvent
    ;syswm.SDL_SysWMEvent
    ;tfinger.SDL_TouchFingerEvent
    ;mgesture.SDL_MultiGestureEvent
    ;dgesture.SDL_DollarGestureEvent
    ;drop.SDL_DropEvent
    padding.a[56]
  EndStructureUnion
EndStructure




;-
;- SDL Macros

Macro SDL_GameControllerAddMappingsFromFile(filename)
  SDL_GameControllerAddMappingsFromRW(SDL_RWFromFile(filename, "rb"), 1)
EndMacro




;-
;- SDL Functions


CompilerIf (#PSDL_IncludeLibrary)
  
  ;- - Include Library
  
  Global _PSDL_Lib.i = #Null
  
  PrototypeC.i _PSDL_Init_Proto(flags.l)
  PrototypeC   _PSDL_Quit_Proto()
  PrototypeC.l _PSDL_WasInit(flags.l)
  PrototypeC   _PSDL_GetVersion(*ver.SDL_Version)
  PrototypeC.i _PSDL_SetHint(name._PSDL_String, value._PSDL_String)
  PrototypeC.i _PSDL_SetHintWithPriority(name._PSDL_String, value._PSDL_String, priority.i)
  PrototypeC.i _PSDL_CreateWindow(title._PSDL_String, x.i, y.i, w.i, h.i, flags.l)
  PrototypeC   _PSDL_DestroyWindow(*window.SDL_Window)
  PrototypeC.l _PSDL_GetWindowPixelFormat(*window.SDL_Window)
  PrototypeC   _PSDL_GetWindowPosition(*window.SDL_Window, *x.INTEGER, *y.INTEGER)
  PrototypeC   _PSDL_GetWindowSize(*window.SDL_Window, *w.INTEGER, *h.INTEGER)
  PrototypeC   _PSDL_HideWindow(*window.SDL_Window)
  PrototypeC   _PSDL_RaiseWindow(*window.SDL_Window)
  PrototypeC.i _PSDL_SetWindowFullscreen(*window.SDL_Window, flags.l)
  PrototypeC   _PSDL_SetWindowPosition(*window.SDL_Window, x.i, y.i)
  PrototypeC   _PSDL_SetWindowSize(*window.SDL_Window, w.i, h.i)
  PrototypeC   _PSDL_SetWindowTitle(*window.SDL_Window, title._PSDL_String)
  PrototypeC   _PSDL_ShowWindow(*window.SDL_Window)
  PrototypeC.i _PSDL_CreateRenderer(*window.SDL_Window, index.i, flags.l)
  PrototypeC.i _PSDL_CreateTexture(*renderer.SDL_Renderer, format.l, access.i, w.i, h.i)
  PrototypeC.i _PSDL_CreateTextureFromSurface(*renderer.SDL_Renderer, *surface.SDL_Surface)
  PrototypeC   _PSDL_DestroyRenderer(*renderer.SDL_Renderer)
  PrototypeC   _PSDL_DestroyTexture(*texture.SDL_Texture)
  PrototypeC.i _PSDL_GetRendererOutputSize(*renderer.SDL_Renderer, *w.INTEGER, *h.INTEGER)
  PrototypeC.i _PSDL_QueryTexture(*texture.SDL_Texture, *format.LONG, *access.INTEGER, *w.INTEGER, *h.INTEGER)
  PrototypeC.i _PSDL_RenderClear(*renderer.SDL_Renderer)
  PrototypeC.i _PSDL_RenderCopy(*renderer.SDL_Renderer, *texture.SDL_Texture, *srcrect.SDL_Rect, *dstrect.SDL_Rect)
  PrototypeC.i _PSDL_RenderCopyEx(*renderer.SDL_Renderer, *texture.SDL_Texture, *srcrect.SDL_Rect, *dstrect.SDL_Rect, angle.d, *center.SDL_Point, flip.i)
  PrototypeC.i _PSDL_RenderDrawLine(*renderer.SDL_Renderer, x1.i, y1.i, x2.i, y2.i)
  PrototypeC.i _PSDL_RenderDrawPoint(*renderer.SDL_Renderer, x.i, y.i)
  PrototypeC.i _PSDL_RenderFillRect(*renderer.SDL_Renderer, *rect.SDL_Rect)
  PrototypeC   _PSDL_RenderPresent(*renderer.SDL_Renderer)
  PrototypeC.i _PSDL_RenderSetLogicalSize(*renderer.SDL_Renderer, w.i, h.i)
  PrototypeC.i _PSDL_SetColorKey(*surface.SDL_Surface, flag.i, key.l)
  PrototypeC.i _PSDL_SetRenderDrawBlendMode(*renderer.SDL_Renderer, blendMode.i)
  PrototypeC.i _PSDL_SetRenderDrawColor(*renderer.SDL_Renderer, r.a, g.a, b.a, a.a)
  PrototypeC.i _PSDL_SetRenderTarget(*renderer.SDL_Renderer, *texture.SDL_Texture)
  PrototypeC.i _PSDL_SetTextureAlphaMod(*texture.SDL_Texture, alpha.a)
  PrototypeC.i _PSDL_SetTextureColorMod(*texture.SDL_Texture, r.a, g.a, b.a)
  PrototypeC   _PSDL_CreateRGBSurfaceFrom(*pixels, width.i, height.i, depth.i, pitch.i, Rmask.l, Gmask.l, Bmask.l, Amask.l)
  PrototypeC   _PSDL_CreateRGBSurfaceWithFormatFrom(*pixels, width.i, height.i, depth.i, pitch.i, format.l)
  PrototypeC   _PSDL_FreeSurface(*surface.SDL_Surface)
  PrototypeC.i _PSDL_PeepEvents(*events.SDL_Event, numevents.i, action.i, minType.l, maxType.l)
  PrototypeC.i _PSDL_PollEvent(*event.SDL_Event)
  PrototypeC   _PSDL_PumpEvents()
  PrototypeC.i _PSDL_GetKeyboardState(*numkeys.INTEGER)
  PrototypeC.i _PSDL_SetRelativeMouseMode(enabled.i)
  PrototypeC.i _PSDL_ShowCursor(toggle.i)
  PrototypeC   _PSDL_WarpMouseInWindow(*window.SDL_Window, x.i, y.i)
  PrototypeC   _PSDL_JoystickClose(*joystick.SDL_Joystick)
  PrototypeC.i _PSDL_JoystickInstanceID(*joystick.SDL_Joystick)
  PrototypeC.i _PSDL_JoystickName(*joystick.SDL_Joystick)
  PrototypeC.i _PSDL_JoystickNameForIndex(device_index.i)
  PrototypeC.i _PSDL_JoystickOpen(device_index.i)
  PrototypeC   _PSDL_JoystickUpdate()
  PrototypeC.i _PSDL_NumJoysticks()
  PrototypeC.i _PSDL_GameControllerAddMappingsFromRW(*rw.SDL_RWops, freerw.i)
  PrototypeC   _PSDL_GameControllerClose(*gamecontroller.SDL_GameController)
  PrototypeC.i _PSDL_GameControllerFromInstanceID(joyid.i)
  PrototypeC.i _PSDL_GameControllerGetAttached(*gamecontroller.SDL_GameController)
  PrototypeC.w _PSDL_GameControllerGetAxis(*gamecontroller.SDL_GameController, axis.i)
  PrototypeC.i _PSDL_GameControllerGetButton(*gamecontroller.SDL_GameController, button.i)
  PrototypeC.i _PSDL_GameControllerGetJoystick(*gamecontroller.SDL_GameController)
  PrototypeC.i _PSDL_GameControllerName(*gamecontroller.SDL_GameController)
  PrototypeC.i _PSDL_GameControllerOpen(joystick_index.i)
  PrototypeC   _PSDL_GameControllerUpdate()
  PrototypeC.i _PSDL_IsGameController(joystick_index.i)
  PrototypeC.i _PSDL_HapticOpenFromJoystick(*joystick.SDL_Joystick)
  PrototypeC   _PSDL_HapticClose(*haptic.SDL_Haptic)
  PrototypeC.i _PSDL_HapticRumbleInit(*haptic.SDL_Haptic)
  PrototypeC.i _PSDL_HapticRumblePlay(*haptic.SDL_Haptic, strength.f, length.l)
  PrototypeC.i _PSDL_HapticRumbleStop(*haptic.SDL_Haptic)
  PrototypeC.i _PSDL_AddTimer(interval.l, *callback, *param)
  PrototypeC.i _PSDL_RWFromFile(file._PSDL_String, mode._PSDL_String)
  
  Global _PSDL_Init._PSDL_Init_Proto
  Global _PSDL_Quit._PSDL_Quit_Proto
  Global SDL_WasInit._PSDL_WasInit
  Global SDL_GetVersion._PSDL_GetVersion
  Global SDL_SetHint._PSDL_SetHint
  Global SDL_SetHintWithPriority._PSDL_SetHintWithPriority
  Global SDL_CreateWindow._PSDL_CreateWindow
  Global SDL_DestroyWindow._PSDL_DestroyWindow
  Global SDL_GetWindowPixelFormat._PSDL_GetWindowPixelFormat
  Global SDL_GetWindowPosition._PSDL_GetWindowPosition
  Global SDL_GetWindowSize._PSDL_GetWindowSize
  Global SDL_HideWindow._PSDL_HideWindow
  Global SDL_RaiseWindow._PSDL_RaiseWindow
  Global SDL_SetWindowFullscreen._PSDL_SetWindowFullscreen
  Global SDL_SetWindowPosition._PSDL_SetWindowPosition
  Global SDL_SetWindowSize._PSDL_SetWindowSize
  Global SDL_SetWindowTitle._PSDL_SetWindowTitle
  Global SDL_ShowWindow._PSDL_ShowWindow
  Global SDL_CreateRenderer._PSDL_CreateRenderer
  Global SDL_CreateTexture._PSDL_CreateTexture
  Global SDL_CreateTextureFromSurface._PSDL_CreateTextureFromSurface
  Global SDL_DestroyRenderer._PSDL_DestroyRenderer
  Global SDL_DestroyTexture._PSDL_DestroyTexture
  Global SDL_GetRendererOutputSize._PSDL_GetRendererOutputSize
  Global SDL_QueryTexture._PSDL_QueryTexture
  Global SDL_RenderClear._PSDL_RenderClear
  Global SDL_RenderCopy._PSDL_RenderCopy
  Global SDL_RenderCopyEx._PSDL_RenderCopyEx
  Global SDL_RenderDrawLine._PSDL_RenderDrawLine
  Global SDL_RenderDrawPoint._PSDL_RenderDrawPoint
  Global SDL_RenderFillRect._PSDL_RenderFillRect
  Global SDL_RenderPresent._PSDL_RenderPresent
  Global SDL_RenderSetLogicalSize._PSDL_RenderSetLogicalSize
  Global SDL_SetColorKey._PSDL_SetColorKey
  Global SDL_SetRenderDrawBlendMode._PSDL_SetRenderDrawBlendMode
  Global SDL_SetRenderDrawColor._PSDL_SetRenderDrawColor
  Global SDL_SetRenderTarget._PSDL_SetRenderTarget
  Global SDL_SetTextureAlphaMod._PSDL_SetTextureAlphaMod
  Global SDL_SetTextureColorMod._PSDL_SetTextureColorMod
  Global SDL_CreateRGBSurfaceFrom._PSDL_CreateRGBSurfaceFrom
  Global SDL_CreateRGBSurfaceWithFormatFrom._PSDL_CreateRGBSurfaceWithFormatFrom
  Global SDL_FreeSurface._PSDL_FreeSurface
  Global SDL_PeepEvents._PSDL_PeepEvents
  Global SDL_PollEvent._PSDL_PollEvent
  Global SDL_PumpEvents._PSDL_PumpEvents
  Global SDL_GetKeyboardState._PSDL_GetKeyboardState
  Global SDL_SetRelativeMouseMode._PSDL_SetRelativeMouseMode
  Global SDL_ShowCursor._PSDL_ShowCursor
  Global SDL_WarpMouseInWindow._PSDL_WarpMouseInWindow
  Global SDL_JoystickClose._PSDL_JoystickClose
  Global SDL_JoystickInstanceID._PSDL_JoystickInstanceID
  Global SDL_JoystickName._PSDL_JoystickName
  Global SDL_JoystickNameForIndex._PSDL_JoystickNameForIndex
  Global SDL_JoystickOpen._PSDL_JoystickOpen
  Global SDL_JoystickUpdate._PSDL_JoystickUpdate
  Global SDL_NumJoysticks._PSDL_NumJoysticks
  Global SDL_GameControllerAddMappingsFromRW._PSDL_GameControllerAddMappingsFromRW
  Global SDL_GameControllerClose._PSDL_GameControllerClose
  Global SDL_GameControllerFromInstanceID._PSDL_GameControllerFromInstanceID
  Global SDL_GameControllerGetAttached._PSDL_GameControllerGetAttached
  Global SDL_GameControllerGetAxis._PSDL_GameControllerGetAxis
  Global SDL_GameControllerGetButton._PSDL_GameControllerGetButton
  Global SDL_GameControllerGetJoystick._PSDL_GameControllerGetJoystick
  Global SDL_GameControllerName._PSDL_GameControllerName
  Global SDL_GameControllerOpen._PSDL_GameControllerOpen
  Global SDL_GameControllerUpdate._PSDL_GameControllerUpdate
  Global SDL_IsGameController._PSDL_IsGameController
  Global SDL_HapticOpenFromJoystick._PSDL_HapticOpenFromJoystick
  Global SDL_HapticClose._PSDL_HapticClose
  Global SDL_HapticRumbleInit._PSDL_HapticRumbleInit
  Global SDL_HapticRumblePlay._PSDL_HapticRumblePlay
  Global SDL_HapticRumbleStop._PSDL_HapticRumbleStop
  Global SDL_AddTimer._PSDL_AddTimer
  Global SDL_RWFromFile._PSDL_RWFromFile
  
  Procedure.i SDL_Init(flags.l)
    Protected Result.i = -1
    If (Not _PSDL_Lib)
      _PSDL_Lib = OpenLibrary(#PB_Any, #PSDL_Runtime)
      If (Not _PSDL_Lib)
        _PSDL_Lib = OpenLibrary(#PB_Any, GetPathPart(ProgramFilename()) + #PSDL_Runtime)
      EndIf
      CompilerIf (Not #PSDL_NoDataSection)
        If (Not _PSDL_Lib)
          Protected TempFile.s = #PSDL_TempRuntime
          If (TempFile = "")
            TempFile = ReplaceString(GetFilePart(ProgramFilename()), ".", "_") + "_" + #PSDL_Runtime
          EndIf
          TempFile = GetTemporaryDirectory() + TempFile
          Protected TempFN.i = CreateFile(#PB_Any, TempFile)
          If (TempFN)
            WriteData(TempFN, ?_PSDL_RuntimeStart, ?_PSDL_RuntimeEnd - ?_PSDL_RuntimeStart)
            CloseFile(TempFN)
            _PSDL_Lib = OpenLibrary(#PB_Any, TempFile)
          EndIf
        EndIf
      CompilerEndIf
      If (_PSDL_Lib)
        _PSDL_Init = GetFunction(_PSDL_Lib, "SDL_Init")
        If (_PSDL_Init)
          _PSDL_Quit = GetFunction(_PSDL_Lib, "SDL_Quit")
          SDL_WasInit = GetFunction(_PSDL_Lib, "SDL_WasInit")
          SDL_GetVersion = GetFunction(_PSDL_Lib, "SDL_GetVersion")
          SDL_SetHint = GetFunction(_PSDL_Lib, "SDL_SetHint")
          SDL_SetHintWithPriority = GetFunction(_PSDL_Lib, "SDL_SetHintWithPriority")
          SDL_CreateWindow = GetFunction(_PSDL_Lib, "SDL_CreateWindow")
          SDL_DestroyWindow = GetFunction(_PSDL_Lib, "SDL_DestroyWindow")
          SDL_GetWindowPixelFormat = GetFunction(_PSDL_Lib, "SDL_GetWindowPixelFormat")
          SDL_GetWindowPosition = GetFunction(_PSDL_Lib, "SDL_GetWindowPosition")
          SDL_GetWindowSize = GetFunction(_PSDL_Lib, "SDL_GetWindowSize")
          SDL_HideWindow = GetFunction(_PSDL_Lib, "SDL_HideWindow")
          SDL_RaiseWindow = GetFunction(_PSDL_Lib, "SDL_RaiseWindow")
          SDL_SetWindowFullscreen = GetFunction(_PSDL_Lib, "SDL_SetWindowFullscreen")
          SDL_SetWindowPosition = GetFunction(_PSDL_Lib, "SDL_SetWindowPosition")
          SDL_SetWindowSize = GetFunction(_PSDL_Lib, "SDL_SetWindowSize")
          SDL_SetWindowTitle = GetFunction(_PSDL_Lib, "SDL_SetWindowTitle")
          SDL_ShowWindow = GetFunction(_PSDL_Lib, "SDL_ShowWindow")
          SDL_CreateRenderer = GetFunction(_PSDL_Lib, "SDL_CreateRenderer")
          SDL_CreateTexture = GetFunction(_PSDL_Lib, "SDL_CreateTexture")
          SDL_CreateTextureFromSurface = GetFunction(_PSDL_Lib, "SDL_CreateTextureFromSurface")
          SDL_DestroyRenderer = GetFunction(_PSDL_Lib, "SDL_DestroyRenderer")
          SDL_DestroyTexture = GetFunction(_PSDL_Lib, "SDL_DestroyTexture")
          SDL_GetRendererOutputSize = GetFunction(_PSDL_Lib, "SDL_GetRendererOutputSize")
          SDL_QueryTexture = GetFunction(_PSDL_Lib, "SDL_QueryTexture")
          SDL_RenderClear = GetFunction(_PSDL_Lib, "SDL_RenderClear")
          SDL_RenderCopy = GetFunction(_PSDL_Lib, "SDL_RenderCopy")
          SDL_RenderCopyEx = GetFunction(_PSDL_Lib, "SDL_RenderCopyEx")
          SDL_RenderDrawLine = GetFunction(_PSDL_Lib, "SDL_RenderDrawLine")
          SDL_RenderDrawPoint = GetFunction(_PSDL_Lib, "SDL_RenderDrawPoint")
          SDL_RenderFillRect = GetFunction(_PSDL_Lib, "SDL_RenderFillRect")
          SDL_RenderPresent = GetFunction(_PSDL_Lib, "SDL_RenderPresent")
          SDL_RenderSetLogicalSize = GetFunction(_PSDL_Lib, "SDL_RenderSetLogicalSize")
          SDL_SetColorKey = GetFunction(_PSDL_Lib, "SDL_SetColorKey")
          SDL_SetRenderDrawBlendMode = GetFunction(_PSDL_Lib, "SDL_SetRenderDrawBlendMode")
          SDL_SetRenderDrawColor = GetFunction(_PSDL_Lib, "SDL_SetRenderDrawColor")
          SDL_SetRenderTarget = GetFunction(_PSDL_Lib, "SDL_SetRenderTarget")
          SDL_SetTextureAlphaMod = GetFunction(_PSDL_Lib, "SDL_SetTextureAlphaMod")
          SDL_SetTextureColorMod = GetFunction(_PSDL_Lib, "SDL_SetTextureColorMod")
          SDL_CreateRGBSurfaceFrom = GetFunction(_PSDL_Lib, "SDL_CreateRGBSurfaceFrom")
          SDL_CreateRGBSurfaceWithFormatFrom = GetFunction(_PSDL_Lib, "SDL_CreateRGBSurfaceWithFormatFrom")
          SDL_FreeSurface = GetFunction(_PSDL_Lib, "SDL_FreeSurface")
          SDL_PeepEvents = GetFunction(_PSDL_Lib, "SDL_PeepEvents")
          SDL_PollEvent = GetFunction(_PSDL_Lib, "SDL_PollEvent")
          SDL_PumpEvents = GetFunction(_PSDL_Lib, "SDL_PumpEvents")
          SDL_GetKeyboardState = GetFunction(_PSDL_Lib, "SDL_GetKeyboardState")
          SDL_SetRelativeMouseMode = GetFunction(_PSDL_Lib, "SDL_SetRelativeMouseMode")
          SDL_ShowCursor = GetFunction(_PSDL_Lib, "SDL_ShowCursor")
          SDL_WarpMouseInWindow = GetFunction(_PSDL_Lib, "SDL_WarpMouseInWindow")
          SDL_JoystickClose = GetFunction(_PSDL_Lib, "SDL_JoystickClose")
          SDL_JoystickInstanceID = GetFunction(_PSDL_Lib, "SDL_JoystickInstanceID")
          SDL_JoystickName = GetFunction(_PSDL_Lib, "SDL_JoystickName")
          SDL_JoystickNameForIndex = GetFunction(_PSDL_Lib, "SDL_JoystickNameForIndex")
          SDL_JoystickOpen = GetFunction(_PSDL_Lib, "SDL_JoystickOpen")
          SDL_JoystickUpdate = GetFunction(_PSDL_Lib, "SDL_JoystickUpdate")
          SDL_NumJoysticks = GetFunction(_PSDL_Lib, "SDL_NumJoysticks")
          SDL_GameControllerAddMappingsFromRW = GetFunction(_PSDL_Lib, "SDL_GameControllerAddMappingsFromRW")
          SDL_GameControllerClose = GetFunction(_PSDL_Lib, "SDL_GameControllerClose")
          SDL_GameControllerFromInstanceID = GetFunction(_PSDL_Lib, "SDL_GameControllerFromInstanceID")
          SDL_GameControllerGetAttached = GetFunction(_PSDL_Lib, "SDL_GameControllerGetAttached")
          SDL_GameControllerGetAxis = GetFunction(_PSDL_Lib, "SDL_GameControllerGetAxis")
          SDL_GameControllerGetButton = GetFunction(_PSDL_Lib, "SDL_GameControllerGetButton")
          SDL_GameControllerGetJoystick = GetFunction(_PSDL_Lib, "SDL_GameControllerGetJoystick")
          SDL_GameControllerName = GetFunction(_PSDL_Lib, "SDL_GameControllerName")
          SDL_GameControllerOpen = GetFunction(_PSDL_Lib, "SDL_GameControllerOpen")
          SDL_GameControllerUpdate = GetFunction(_PSDL_Lib, "SDL_GameControllerUpdate")
          SDL_IsGameController = GetFunction(_PSDL_Lib, "SDL_IsGameController")
          SDL_HapticOpenFromJoystick = GetFunction(_PSDL_Lib, "SDL_HapticOpenFromJoystick")
          SDL_HapticClose = GetFunction(_PSDL_Lib, "SDL_HapticClose")
          SDL_HapticRumbleInit = GetFunction(_PSDL_Lib, "SDL_HapticRumbleInit")
          SDL_HapticRumblePlay = GetFunction(_PSDL_Lib, "SDL_HapticRumblePlay")
          SDL_HapticRumbleStop = GetFunction(_PSDL_Lib, "SDL_HapticRumbleStop")
          SDL_AddTimer = GetFunction(_PSDL_Lib, "SDL_AddTimer")
          SDL_RWFromFile = GetFunction(_PSDL_Lib, "SDL_RWFromFile")
        Else
          CloseLibrary(_PSDL_Lib)
          _PSDL_Lib = #Null
        EndIf
      EndIf
    EndIf
    If (_PSDL_Lib And _PSDL_Init)
      Result = _PSDL_Init(flags)
    EndIf
    ProcedureReturn (Result)
  EndProcedure
  
  Procedure SDL_Quit()
    If (_PSDL_Lib)
      If (_PSDL_Quit)
        _PSDL_Quit()
      EndIf
      CloseLibrary(_PSDL_Lib)
      _PSDL_Lib = #Null
    EndIf
  EndProcedure
  
  ;- - Data Section
  
  DataSection
    CompilerIf (Not #PSDL_NoDataSection)
      _PSDL_RuntimeStart:
      IncludeBinary #PSDL_RuntimeInclude
      _PSDL_RuntimeEnd:
    CompilerEndIf
  EndDataSection
  
CompilerElse
  
  ;- - Import Functions
  
  ImportC #PSDL_ImportLib
    
    SDL_Init.i(flags.l)
    SDL_Quit()
    SDL_WasInit.l(flags.l)
    SDL_GetVersion(*ver.SDL_Version)
    SDL_SetHint.i(name._PSDL_String, value._PSDL_String)
    SDL_SetHintWithPriority.i(name._PSDL_String, value._PSDL_String, priority.i)
    SDL_CreateWindow.i(title._PSDL_String, x.i, y.i, w.i, h.i, flags.l)
    SDL_DestroyWindow(*window.SDL_Window)
    SDL_GetWindowPixelFormat.l(*window.SDL_Window)
    SDL_GetWindowPosition(*window.SDL_Window, *x.INTEGER, *y.INTEGER)
    SDL_GetWindowSize(*window.SDL_Window, *w.INTEGER, *h.INTEGER)
    SDL_HideWindow(*window.SDL_Window)
    SDL_RaiseWindow(*window.SDL_Window)
    SDL_SetWindowFullscreen.i(*window.SDL_Window, flags.l)
    SDL_SetWindowPosition(*window.SDL_Window, x.i, y.i)
    SDL_SetWindowSize(*window.SDL_Window, w.i, h.i)
    SDL_SetWindowTitle(*window.SDL_Window, title._PSDL_String)
    SDL_ShowWindow(*window.SDL_Window)
    SDL_CreateRenderer.i(*window.SDL_Window, index.i, flags.l)
    SDL_CreateTexture.i(*renderer.SDL_Renderer, format.l, access.i, w.i, h.i)
    SDL_CreateTextureFromSurface.i(*renderer.SDL_Renderer, *surface.SDL_Surface)
    SDL_DestroyRenderer(*renderer.SDL_Renderer)
    SDL_DestroyTexture(*texture.SDL_Texture)
    SDL_GetRendererOutputSize.i(*renderer.SDL_Renderer, *w.INTEGER, *h.INTEGER)
    SDL_QueryTexture.i(*texture.SDL_Texture, *format.LONG, *access.INTEGER, *w.INTEGER, *h.INTEGER)
    SDL_RenderClear.i(*renderer.SDL_Renderer)
    SDL_RenderCopy.i(*renderer.SDL_Renderer, *texture.SDL_Texture, *srcrect.SDL_Rect, *dstrect.SDL_Rect)
    SDL_RenderCopyEx.i(*renderer.SDL_Renderer, *texture.SDL_Texture, *srcrect.SDL_Rect, *dstrect.SDL_Rect, angle.d, *center.SDL_Point, flip.i)
    SDL_RenderDrawLine.i(*renderer.SDL_Renderer, x1.i, y1.i, x2.i, y2.i)
    SDL_RenderDrawPoint.i(*renderer.SDL_Renderer, x.i, y.i)
    SDL_RenderFillRect.i(*renderer.SDL_Renderer, *rect.SDL_Rect)
    SDL_RenderPresent(*renderer.SDL_Renderer)
    SDL_RenderSetLogicalSize.i(*renderer.SDL_Renderer, w.i, h.i)
    SDL_SetColorKey.i(*surface.SDL_Surface, flag.i, key.l)
    SDL_SetRenderDrawBlendMode.i(*renderer.SDL_Renderer, blendMode.i)
    SDL_SetRenderDrawColor.i(*renderer.SDL_Renderer, r.a, g.a, b.a, a.a)
    SDL_SetRenderTarget.i(*renderer.SDL_Renderer, *texture.SDL_Texture)
    SDL_SetTextureAlphaMod.i(*texture.SDL_Texture, alpha.a)
    SDL_SetTextureColorMod.i(*texture.SDL_Texture, r.a, g.a, b.a)
    SDL_CreateRGBSurfaceFrom(*pixels, width.i, height.i, depth.i, pitch.i, Rmask.l, Gmask.l, Bmask.l, Amask.l)
    SDL_CreateRGBSurfaceWithFormatFrom(*pixels, width.i, height.i, depth.i, pitch.i, format.l)
    SDL_FreeSurface(*surface.SDL_Surface)
    SDL_PeepEvents.i(*events.SDL_Event, numevents.i, action.i, minType.l, maxType.l)
    SDL_PollEvent.i(*event.SDL_Event)
    SDL_PumpEvents()
    SDL_GetKeyboardState.i(*numkeys.INTEGER)
    SDL_SetRelativeMouseMode.i(enabled.i)
    SDL_ShowCursor.i(toggle.i)
    SDL_WarpMouseInWindow(*window.SDL_Window, x.i, y.i)
    SDL_JoystickClose(*joystick.SDL_Joystick)
    SDL_JoystickInstanceID.i(*joystick.SDL_Joystick)
    SDL_JoystickName.i(*joystick.SDL_Joystick)
    SDL_JoystickNameForIndex.i(device_index.i)
    SDL_JoystickOpen.i(device_index.i)
    SDL_JoystickUpdate()
    SDL_NumJoysticks.i()
    SDL_GameControllerAddMappingsFromRW.i(*rw.SDL_RWops, freerw.i)
    SDL_GameControllerClose(*gamecontroller.SDL_GameController)
    SDL_GameControllerFromInstanceID.i(joyid.i)
    SDL_GameControllerGetAttached.i(*gamecontroller.SDL_GameController)
    SDL_GameControllerGetAxis.w(*gamecontroller.SDL_GameController, axis.i)
    SDL_GameControllerGetButton.i(*gamecontroller.SDL_GameController, button.i)
    SDL_GameControllerGetJoystick.i(*gamecontroller.SDL_GameController)
    SDL_GameControllerName.i(*gamecontroller.SDL_GameController)
    SDL_GameControllerOpen.i(joystick_index.i)
    SDL_GameControllerUpdate()
    SDL_IsGameController.i(joystick_index.i)
    SDL_HapticOpenFromJoystick.i(*joystick.SDL_Joystick)
    SDL_HapticClose(*haptic.SDL_Haptic)
    SDL_HapticRumbleInit.i(*haptic.SDL_Haptic)
    SDL_HapticRumblePlay.i(*haptic.SDL_Haptic, strength.f, length.l)
    SDL_HapticRumbleStop.i(*haptic.SDL_Haptic)
    SDL_AddTimer.i(interval.l, *callback, *param)
    SDL_RWFromFile.i(file._PSDL_String, mode._PSDL_String)
    
  EndImport
  
CompilerEndIf




CompilerEndIf ; PSDL
;-
; IDE Options = PureBasic 5.61 (Windows - x86)
; EnableXP
; EnableUser
; EnableUnicode
