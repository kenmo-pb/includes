; +---------------+
; | FormatDatePHP |
; +---------------+
; |  8.21.2011 . Creation (PB 4.51)
; |   .22.     . Added full date/time combos, Swatch time, difference from GMT
; |   .23.     - Version 1.0 (for PB forums)
; |  5.11.2016 - Version 1.1 (corrected day prefixes such as "st")
; |  1.23.2017 - Version 1.2 (corrected GMT offset bug when passing midnight)
; |  4.13.2018 - Version 1.3 (multiple-include safe, EnableExplicit-safe,
; |                           use time() for GMT calc, cleaned up demo)
;
;-
;
; This procedure mimics the native date() function of the PHP language.
; It can be used as an expanded replacement for PB's FormatDate() function,
; but be aware that it uses completely different syntax!
; The Timestamp argument defaults to -1, which is replaced by the current time.
;
; The format syntax (list of character codes) matches PHP's syntax here:
; ***  http://php.net/manual/en/function.date.php  ***
;
;
;
; Note the following exceptions, and their contribution to the result:
;
; 'u' (microseconds) PB timestamps do not use microseconds,  always becomes "000000"
; 'W' (ISO week number) not implemented,                            becomes "?"
; 'o' (ISO year) not implemented,                                   becomes "?"
; 'e' (time zone ID) not implemented,                               becomes "?"
; 'I' (daylight savings flag) not implemented,                      becomes "?"
; 'T' (time zone abbreviation) not implemented,                     becomes "?"
;

CompilerIf (Not Defined(__FormatDatePHP_Included, #PB_Constant))
#__FormatDatePHP_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf




;- Imports

CompilerIf (Not Defined(time, #PB_Procedure))
  ImportC ""
    time(*t = #Null)
  EndImport
CompilerEndIf




;-
;- Procedures

Procedure.s FormatDatePHP(Format.s, Timestamp.i = -1)
  Protected Result.s
  Protected Year.i, Month.i, Day.i, Hour.i, Minute.i, Second.i
  Protected FromGMT.i, GMTHour.s, GMTMinute.s, Temp.i
  Protected *C.CHARACTER
 
 
  ; Use current date, by default
  If (Timestamp = -1)
    Timestamp = Date()
  EndIf
 
 
  ; Get time zone / GMT offset
  CompilerIf (#True)
  
    ; Use cross-platform time() function
    Protected GMTTime.i   = time()
    Protected LocalTime.i = Date()
    FromGMT = (LocalTime - GMTTime)/60
    
  CompilerElseIf ((#PB_Compiler_OS = #PB_OS_Windows) And (#True))
    
    ; Use Windows API functions
    Protected GMTTime.SYSTEMTIME, LocalTime.SYSTEMTIME
    GetSystemTime_(GMTTime)
    GetLocalTime_(LocalTime)
    FromGMT = (LocalTime\wHour - GMTTime\wHour)*60 + (LocalTime\wMinute - GMTTime\wMinute)
    If (GMTTime\wDayOfWeek = (LocalTime\wDayOfWeek + 1) % 7)
      FromGMT - 24*60
    ElseIf (GMTTime\wDayOfWeek = (LocalTime\wDayOfWeek + 7 - 1) % 7)
      FromGMT + 24*60
    EndIf
    
  CompilerElse
    FromGMT = 0
  CompilerEndIf
  
  If (FromGMT >= 0)
    GMTHour   = "+" + RSet(Str(FromGMT / 60), 2, "0")
    GMTMinute =       RSet(Str(FromGMT % 60), 2, "0")
  Else
    GMTHour   = "-" + RSet(Str((0-FromGMT) / 60), 2, "0")
    GMTMinute =       RSet(Str((0-FromGMT) % 60), 2, "0")
  EndIf
 
 
  ; Extract numeric timestamp values
  Year   = Year  (Timestamp)
  Month  = Month (Timestamp)
  Day    = Day   (Timestamp)
  Hour   = Hour  (Timestamp)
  Minute = Minute(Timestamp)
  Second = Second(Timestamp)
 
 
  ; Parse through each format character
  Result = ""
  *C     = @Format
  While (*C\c)
    Select (*C\c)
   
      ; Day representations
      Case 'd' : Result + RSet(Str(Day), 2, "0")
      Case 'D'
        Select (DayOfWeek(Timestamp))
          Case 0 : Result + "Sun"
          Case 1 : Result + "Mon"
          Case 2 : Result + "Tue"
          Case 3 : Result + "Wed"
          Case 4 : Result + "Thu"
          Case 5 : Result + "Fri"
          Case 6 : Result + "Sat"
        EndSelect
      Case 'j' : Result + Str(Day)
      Case 'l'
        Select (DayOfWeek(Timestamp))
          Case 0 : Result + "Sunday"
          Case 1 : Result + "Monday"
          Case 2 : Result + "Tuesday"
          Case 3 : Result + "Wednesday"
          Case 4 : Result + "Thursday"
          Case 5 : Result + "Friday"
          Case 6 : Result + "Saturday"
        EndSelect
      Case 'N' : Result + Str(((DayOfWeek(Timestamp) + 6) % 7) + 1)
      Case 'S'
        Select (Day)
          Case 1, 21, 31 : Result + "st"
          Case 2, 22     : Result + "nd"
          Case 3, 23     : Result + "rd"
          Default        : Result + "th"
        EndSelect
      Case 'w' : Result + Str(DayOfWeek(Timestamp))
      Case 'z' : Result + Str(DayOfYear(Timestamp)-1)
     
     
      ; Week representations
      Case 'W' : Result + "?" ; ISO week (not implemented)
     
     
      ; Month representations
      Case 'F'
        Select (Month)
          Case  1 : Result + "January"
          Case  2 : Result + "February"
          Case  3 : Result + "March"
          Case  4 : Result + "April"
          Case  5 : Result + "May"
          Case  6 : Result + "June"
          Case  7 : Result + "July"
          Case  8 : Result + "August"
          Case  9 : Result + "September"
          Case 10 : Result + "October"
          Case 11 : Result + "November"
          Case 12 : Result + "December"
        EndSelect
      Case 'm' : Result + RSet(Str(Month), 2, "0")
      Case 'M'
        Select (Month)
          Case  1 : Result + "Jan"
          Case  2 : Result + "Feb"
          Case  3 : Result + "Mar"
          Case  4 : Result + "Apr"
          Case  5 : Result + "May"
          Case  6 : Result + "Jun"
          Case  7 : Result + "Jul"
          Case  8 : Result + "Aug"
          Case  9 : Result + "Sep"
          Case 10 : Result + "Oct"
          Case 11 : Result + "Nov"
          Case 12 : Result + "Dec"
        EndSelect
      Case 'n' : Result + Str(Month)
      Case 't'
        Select (Month)
          Case 1,3,5,7,8,10,12
            Result + "31"
          Case 2
            If (Year % 400 = 0)
              Result + "29"
            ElseIf (Year % 100 = 0)
              Result + "28"
            ElseIf (Year % 4 = 0)
              Result + "29"
            Else
              Result + "28"
            EndIf
          Case 4,6,9,11
            Result + "30"
        EndSelect
       
     
      ; Year representations
      Case 'L'
        If (Year % 400 = 0)
          Result + "1"
        ElseIf (Year % 100 = 0)
          Result + "0"
        ElseIf (Year % 4 = 0)
          Result + "1"
        Else
          Result + "0"
        EndIf
      Case 'o' : Result + "?" ; ISO year (not implemented)
      Case 'Y' : Result + Str(Year)
      Case 'y' : Result + RSet(Str(Year % 100), 2, "0")
     
     
      ; Time representations
      Case 'a'
        If (Hour >= 12)
          Result + "pm"
        Else
          Result + "am"
        EndIf
      Case 'A'
        If (Hour >= 12)
          Result + "PM"
        Else
          Result + "AM"
        EndIf
      Case 'B'
        Result + RSet(Str((36000*Hour + 600*Minute + 10*Second) / 864), 3, "0")
      Case 'g' : Result + Str(((Hour + 23) % 12) + 1)
      Case 'G' : Result + Str(Hour)
      Case 'h' : Result + RSet(Str(((Hour + 23) % 12) + 1), 2, "0")
      Case 'H' : Result + RSet(Str(Hour), 2, "0")
      Case 'i' : Result + RSet(Str(Minute), 2, "0")
      Case 's' : Result + RSet(Str(Second), 2, "0")
      Case 'u' : Result + "000000" ; microseconds (not implemented)
     
     
      ; Timezone representations
      Case 'e' : Result + "?" ; Timezone identifier (not implemented)
      Case 'I' : Result + "?" ; Daylight savings flag (not implemented)
      Case 'O' : Result + GMTHour + GMTMinute
      Case 'P' : Result + GMTHour + ":" + GMTMinute
      Case 'T' : Result + "?" ; Timezone abbreviation (not implemented)
      Case 'Z' : Result + Str(FromGMT*60)
     
     
      ; Full date/time
      Case 'c' : Result + FormatDatePHP("Y-m-d\TH:i:sP")
      Case 'r' : Result + FormatDatePHP("D, d M Y H:i:s O", Timestamp)
      Case 'U' : Result + RSet(Str(Timestamp), 11, "0")
     
     
      ; Escape or pass all other characters
      Case '\' : *C + SizeOf(CHARACTER) : Result + Chr(*C\c)
      Default  : Result + Chr(*C\c)
     
    EndSelect
    *C + SizeOf(CHARACTER)
  Wend
 
  ProcedureReturn (Result)
EndProcedure











;-
;- Demo Program

CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
  
  ; Create array of all valid codes
  #PHPFormats = 39
  Define i.i = 0
  Dim Format.s(#PHPFormats - 1)
    Format(i) = "\I\t \i\s l \t\h\e jS, \o\f M Y." : i + 1
    Format(i) = "d" : i + 1
    Format(i) = "D" : i + 1
    Format(i) = "j" : i + 1
    Format(i) = "l" : i + 1
    Format(i) = "N" : i + 1
    Format(i) = "S" : i + 1
    Format(i) = "w" : i + 1
    Format(i) = "z" : i + 1
    Format(i) = "W" : i + 1
    Format(i) = "F" : i + 1
    Format(i) = "m" : i + 1
    Format(i) = "M" : i + 1
    Format(i) = "n" : i + 1
    Format(i) = "t" : i + 1
    Format(i) = "L" : i + 1
    Format(i) = "o" : i + 1
    Format(i) = "Y" : i + 1
    Format(i) = "y" : i + 1
    Format(i) = "a" : i + 1
    Format(i) = "A" : i + 1
    Format(i) = "B" : i + 1
    Format(i) = "g" : i + 1
    Format(i) = "G" : i + 1
    Format(i) = "h" : i + 1
    Format(i) = "H" : i + 1
    Format(i) = "i" : i + 1
    Format(i) = "s" : i + 1
    Format(i) = "u" : i + 1
    Format(i) = "e" : i + 1
    Format(i) = "I" : i + 1
    Format(i) = "O" : i + 1
    Format(i) = "P" : i + 1
    Format(i) = "T" : i + 1
    Format(i) = "Z" : i + 1
    Format(i) = "c" : i + 1
    Format(i) = "r" : i + 1
    Format(i) = "U" : i + 1
    Format(i) = "\\" : i + 1
 
  ; Create window with ListIcon
  OpenWindow(0, 0, 0, 440, 400, "FormatDatePHP Demo",
      #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_Invisible | #PB_Window_SizeGadget)
  ListIconGadget(0, 0, 0, WindowWidth(0), WindowHeight(0), "Format", 195,
      #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(0, 1, "Result", 195)
  SmartWindowRefresh(0, #True)
 
  ; Add all valid formats
  Define Event.i, Timestamp.i
  For i = 0 To #PHPFormats - 1
    AddGadgetItem(0, i+1, Format(i))
  Next i
  
  ; Timer to update
  AddWindowTimer(0, 0, 1000)
  
  ; Resize
  Procedure ResizeCB()
    ResizeGadget(0, 0, 0, WindowWidth(0), WindowHeight(0))
  EndProcedure
  BindEvent(#PB_Event_SizeWindow, @ResizeCB())
  
  Repeat
    Event = WaitWindowEvent()
    
    ; Update all fields
    If (Event = #PB_Event_Timer)
      Timestamp.i = Date()
      For i = 0 To #PHPFormats - 1
        SetGadgetItemText(0, i, FormatDatePHP(Format(i), Timestamp), 1)
      Next i
      HideWindow(0, #False)
    EndIf
  Until (Event = #PB_Event_CloseWindow)
  
CompilerEndIf
CompilerEndIf
;-