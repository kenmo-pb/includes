; +--------------+
; | RegEx_Helper |
; +--------------+
; | 2018-06-22 : Creation
; | 2018-09-05 : Match() now forces "^" and "$", Contains() does not
; | 2018-09-20 : Added ReExtract() to get first match
; | 2020-11-24 : Added AppendList option to Extract/List

;   \s = whitespace characters (\S = NOT whitespace characters)
;   \w = word characters (\W = NOT word characters)
;   \d = digits (\D = NOT digits)
;
;   . = any character (newlines optional)
;
;   * = 0 or more (greedy, as much as possible)
;   + = 1 or more (greedy, as much as possible)
;   *? = 0 or more (lazy, as little as possible)
;   +? = 1 or more (lazy, as little as possible)
;
;   ^ = start of string/line
;   $ = end of string/line
;
;   (?=SUFFIX)  = lookahead
;   (?<=PREFIX) = lookbehind

;-
CompilerIf (Not Defined(_RegEx_Helper_Included, #PB_Constant))
#_RegEx_Helper_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;- Procedures

Procedure.s ReReplace(String.s, Pattern.s, Replacement.s, Flags.i = #Null)
  Protected Result.s
  Protected *RE = CreateRegularExpression(#PB_Any, Pattern, Flags)
  If (*RE)
    Result = ReplaceRegularExpression(*RE, String, Replacement)
    FreeRegularExpression(*RE)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s ReRemove(String.s, Pattern.s, Flags.i = #Null)
  ProcedureReturn (ReReplace(String, Pattern, "", Flags))
EndProcedure

Procedure.i ReContains(String.s, Pattern.s, Flags.i = #Null)
  Protected Result.i = #False
  Protected *RE = CreateRegularExpression(#PB_Any, Pattern, Flags)
  If (*RE)
    Result = Bool(MatchRegularExpression(*RE, String))
    FreeRegularExpression(*RE)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ReMatch(String.s, Pattern.s, Flags.i = #Null)
  Protected Result.i = #False
  If (Left(Pattern, 1) <> "^")
    Pattern = "^" + Pattern
  EndIf
  If (Right(Pattern, 1) <> "$")
    Pattern = Pattern + "$"
  EndIf
  Protected *RE = CreateRegularExpression(#PB_Any, Pattern, Flags)
  If (*RE)
    Result = Bool(MatchRegularExpression(*RE, String))
    FreeRegularExpression(*RE)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ReExtractArray(String.s, Pattern.s, Array Match.s(1), Flags.i = #Null)
  Protected Result.i = 0
  Dim Match.s(0)
  Protected *RE = CreateRegularExpression(#PB_Any, Pattern, Flags)
  If (*RE)
    Result = ExtractRegularExpression(*RE, String, Match())
    FreeRegularExpression(*RE)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s ReExtract(String.s, Pattern.s, Flags.i = #Null)
  Protected Result.s
  Dim AMatch.s(0)
  If (ReExtractArray(String, Pattern, AMatch(), Flags) > 0)
    Result = AMatch(0)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ReExtractList(String.s, Pattern.s, List Match.s(), Flags.i = #Null, AppendList.i = #False)
  Protected Result.i
  Dim AMatch.s(0)
  Result = ReExtractArray(String, Pattern, AMatch(), Flags)
  If (AppendList)
    LastElement(Match())
  Else
    ClearList(Match())
  EndIf
  If (Result > 0)
    Protected i.i
    For i = 0 To Result-1
      AddElement(Match())
      Match() = AMatch(i)
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

;- ReQuickResult
Threaded NewList ReQuickResult.s()

Procedure.i ReQuickExtract(String.s, Pattern.s, Flags.i = #Null, AppendList.i = #False)
  ProcedureReturn (ReExtractList(String, Pattern, ReQuickResult(), Flags, AppendList))
EndProcedure




;-
;- Demo

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Debug ReReplace("Hello World!", "\s+", "___")

Debug ReRemove("Hello World!", "l")

Debug ""
Debug ReContains("Hello World!", "World")
Debug ReMatch("Hello World!", "World")

Debug ""
Debug ReQuickExtract("Hello World!", "[a-z]+")
ForEach ReQuickResult()
  Debug ReQuickResult()
Next

CompilerEndIf
CompilerEndIf
;-