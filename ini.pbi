; +---------+
; | ini.pbi |
; +---------+
; | 2015.05.14 . Version 1.00 release
; |     .08.05 . Added newline after UTF-8 BOM (like PB, to avoid ASCII bug)
; | 2016.03.02 . Version 1.10 release
; |                Updated #INI_Hex integer write for PB 5.42 compatibility
; |     .12.07 . Added #INI_Create
; | 2017.05.05 . Version 1.20 release
; |                Merged separate demo file into this include


CompilerIf (Not Defined(__INI_Included, #PB_Constant))
#__INI_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;
; Similarities to PB's Preference library:
;
;   All Preference functions implemented (as "INI" functions)
;   Same file format and encoding
;   Support for NoSpace and GroupSeparator flags
;   Group and Key names are case-insensitive
;   No Groups with the same name allowed
;   No Keys with the same name allowed (within a Group)
;
;
; Advantages over Preference library:
;
;   Multiple files can be open at once (functions require INI handle)
;   Extra encoding options (CR/LF/CRLF, exclude UTF-8 BOM)
;   Extra format options ('#' for comments, ':' instead of '=')
;   Integers can be written/read in Hex and Binary
;   Colors can be written/read in #RRGGBB or #RRGGBBAA formats
;   Bools can be written/read in 0/1, true/false, yes/no, on/off formats
;   Precision can be specified when writing Floats or Doubles
;   Groups and Keys can be renamed
;   The 'Examine' functions return a count, instead of just non-zero
;   Comments can be removed (all or blank-only)
;   Many parameters are now optional (default to 0 or "")
;   Shorter function names! ("INI" vs. "Preference")
;
;
; Other notes:
;
;   EnableExplicit safe
;   Multiple-include safe
;   Unicode-safe
;   Cross-platform
;








;-
;- Constants (Public)

; IncludeFile version
#INI_Version = 120



; 'Flags' for OpenINI() and CreateINI()
Enumeration
  ;
  #INI_NoSpace        = #PB_Preference_NoSpace
  #INI_GroupSeparator = #PB_Preference_GroupSeparator
  ;
  #INI_NoBOM = $01 << 16      ; No UTF-8 BOM written (when in Unicode mode)
  ;
  #INI_UseCR   = $02 << 16    ; Write CR (0x0D) EOLs
  #INI_UseLF   = $04 << 16    ; Write LF (0x0A) EOLs
  #INI_UseCRLF = $08 << 16    ; Write CRLF (0x0D0A) EOLs
  ;
  #INI_UseColon = $10 << 16   ; Use ':' separator instead of '='
  #INI_UsePound = $20 << 16   ; Use '#' comment prefix instead of ';'
  ;
  #INI_Create   = $40 << 16   ; Forces OpenINI to create file, if missing
  ;
EndEnumeration



; 'Format' for WriteINIInteger()
Enumeration
  ;
  #INI_Dec  = $00         ; Ex:  1234
  #INI_Hex  = $01         ; Ex: $ABCD
  #INI_Bin  = $02         ; Ex: %1010
  #INI_RGB  = $03         ; Ex: #1122BB
  #INI_RGBA = $04         ; Ex: #1122BBAA
  ;
EndEnumeration



; 'Format' for WriteINIBool()
Enumeration
  ;
  #INI_ZeroOne   = $00    ; "0"     or "1"
  #INI_TrueFalse = $01    ; "false" or "true"
  #INI_YesNo     = $02    ; "no"    or "yes"
  #INI_OnOff     = $03    ; "off"   or "on"
  ;
EndEnumeration





;-
;- Constants (Private)

Enumeration
  #__INI_Group
  #__INI_Pair
  #__INI_Comment
  #__INI_Whitespace
EndEnumeration

Enumeration
  #__INI_Modified = $01 << 24
EndEnumeration






;-
;- Structures (Private)

Structure __INIENTRY
  Type.i
  Name.s
  FullText.s
  *Parent.__INIENTRY
EndStructure

Structure __INI
  File.s
  Flags.i
  ;
  EOL.s
  CommentPrefix.s
  Separator.s
  ;
  List Entry.__INIENTRY()
  *CurrentGroup.__INIENTRY
  ;
  *ExamineGroup.__INIENTRY
  *ExaminePair.__INIENTRY
EndStructure








;-
;- Procedures (Private)

Procedure.i __INI_FindGroup(*I.__INI, Name.s)
  Protected *IE.__INIENTRY = #Null
  If (*I)
    PushListPosition(*I\Entry())
      ForEach (*I\Entry())
        If (*I\Entry()\Type = #__INI_Group)
          If (LCase(*I\Entry()\Name) = LCase(Name))
            *IE = @*I\Entry()
            Break
          EndIf
        EndIf
      Next
    PopListPosition(*I\Entry())
  EndIf
  ProcedureReturn (*IE)
EndProcedure

Procedure.i __INI_FindPair(*I.__INI, Key.s, *Group.__INIENTRY = #Null)
  Protected *IE.__INIENTRY = #Null
  If (*I)
    If (Not *Group)
      *Group = *I\CurrentGroup
    EndIf
    PushListPosition(*I\Entry())
      ForEach (*I\Entry())
        If (*I\Entry()\Type = #__INI_Pair)
          If (*I\Entry()\Parent = *Group)
            If (LCase(*I\Entry()\Name) = LCase(Key))
              *IE = @*I\Entry()
              Break
            EndIf
          EndIf
        EndIf
      Next
    PopListPosition(*I\Entry())
  EndIf
  ProcedureReturn (*IE)
EndProcedure

Procedure.s __INI_ExtractValue(*I.__INI, FullText.s)
  Protected Result.s = ""
  Protected i.i = FindString(FullText, *I\Separator)
  If (i)
    Result = Mid(FullText, i + 1)
    If (Not (*I\Flags & #INI_NoSpace))
      If (Left(Result, 1) = " ")
        Result = Mid(Result, 2)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i __INI_AddEntry(*I.__INI, Type.i)
  Protected *IE.__INIENTRY = #Null
  If (*I)
    If (Type = #__INI_Group)
      LastElement(*I\Entry())
      *IE = AddElement(*I\Entry())
      If (*IE)
        *IE\Type = #__INI_Group
      EndIf
    Else
      Protected *LastChild.__INIENTRY = #Null
      LastElement(*I\Entry())
      Repeat
        If (*I\Entry()\Parent = *I\CurrentGroup)
          *LastChild = @*I\Entry()
          Break
        EndIf
      Until (Not PreviousElement(*I\Entry()))
      If (*LastChild)
        ChangeCurrentElement(*I\Entry(), *LastChild)
      Else
        ChangeCurrentElement(*I\Entry(), *I\CurrentGroup)
      EndIf
      *IE = AddElement(*I\Entry())
      If (*IE)
        *IE\Type = Type
        *IE\Parent = *I\CurrentGroup
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*IE)
EndProcedure

Procedure.s __INI_RGBStr(Value.i, IncludeAlpha.i)
  Protected Result.s = "#"
  Result + RSet(Hex(Red(Value)), 2, "0")
  Result + RSet(Hex(Green(Value)), 2, "0")
  Result + RSet(Hex(Blue(Value)), 2, "0")
  If (IncludeAlpha)
    Result + RSet(Hex(Alpha(Value)), 2, "0")
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i __INI_RGBVal(ValueString.s)
  Protected Result.i = 0
  
  If (Left(ValueString, 1) = "#")
    ValueString = Mid(ValueString, 2)
    Protected TempString.s
    Protected BuildString.s
    Protected n.i = Len(ValueString)
    Select (n)
      Case 3
        BuildString = "$"
        TempString = Mid(ValueString, 3, 1)
        BuildString + TempString + TempString
        TempString = Mid(ValueString, 2, 1)
        BuildString + TempString + TempString
        TempString = Mid(ValueString, 1, 1)
        BuildString + TempString + TempString
      Case 6
        BuildString = "$"
        BuildString + Mid(ValueString, 5, 2)
        BuildString + Mid(ValueString, 3, 2)
        BuildString + Mid(ValueString, 1, 2)
      Case 8
        BuildString = "$"
        BuildString + Mid(ValueString, 7, 2)
        BuildString + Mid(ValueString, 5, 2)
        BuildString + Mid(ValueString, 3, 2)
        BuildString + Mid(ValueString, 1, 2)
    EndSelect
    If (BuildString)
      Result = Val(BuildString)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure














;-
;- Procedures (Public)

;-
;- - INI Management

Procedure.i OpenINI(File.s, Flags.i = #Null)
  Protected *I.__INI = #Null
  If (File)
    Protected FN.i
    If (Flags & #INI_Create)
      If (FileSize(File) = -1)
        FN = CreateFile(#PB_Any, File)
        If (FN)
          CloseFile(FN)
        EndIf
      EndIf
    EndIf
    FN = ReadFile(#PB_Any, File)
    If (FN)
      *I = AllocateMemory(SizeOf(__INI))
      If (*I)
        InitializeStructure(*I, __INI)
        *I\File  = File
        *I\Flags = Flags
        ;
        If (Flags & #INI_UseCR)
          *I\EOL = #CR$
        ElseIf (Flags & #INI_UseLF)
          *I\EOL = #LF$
        ElseIf (Flags & #INI_UseCRLF)
          *I\EOL = #CRLF$
        Else
          CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
            *I\EOL = #CRLF$
          CompilerElse
            *I\EOL = #LF$
          CompilerEndIf
        EndIf
        ;
        If (Flags & #INI_UsePound)
          *I\CommentPrefix = "# "
        Else
          *I\CommentPrefix = "; "
        EndIf
        ;
        If (Flags & #INI_UseColon)
          *I\Separator = ":"
        Else
          *I\Separator = "="
        EndIf
        
        *I\CurrentGroup = __INI_AddEntry(*I, #__INI_Group)
        
        Protected i.i
        Protected *IE.__INIENTRY
        Protected Line.s
        Protected Name.s
        While (Not Eof(FN))
          Line = ReadString(FN)
          Protected FirstChar.c = #NUL
          Protected *C.CHARACTER = @Line
          While (*C\c)
            Select (*C\c)
              Case ' ', #TAB, #CR, #LF, #NUL
                ; Whitepsace
              Default
                FirstChar = *C\c
                Break
            EndSelect
            *C + SizeOf(CHARACTER)
          Wend
          Select (FirstChar)
            Case '['
              If (FindString(Line, "]"))
                Name = StringField(StringField(Line, 2, "["), 1, "]")
                If (Not __INI_FindGroup(*I, Name))
                  *IE = __INI_AddEntry(*I, #__INI_Group)
                  *IE\Name = Name
                  *IE\FullText = "[" + *IE\Name + "]"
                  *I\CurrentGroup = *IE
                EndIf
              EndIf
            Case ';', '#'
              *IE = __INI_AddEntry(*I, #__INI_Comment)
              *IE\FullText = Line
            Case #NUL
              *IE = __INI_AddEntry(*I, #__INI_Whitespace)
              *IE\FullText = Line
            Default
              i = FindString(Line, "=")
              If (Not i)
                i = FindString(Line, ":")
              EndIf
              If (i)
                Name = Trim(Left(Line, i - 1))
                If (Not __INI_FindPair(*I, Name))
                  *IE = __INI_AddEntry(*I, #__INI_Pair)
                  *IE\Name = Name
                  *IE\FullText = Left(Line, i - 1) + *I\Separator + Mid(Line, i + 1)
                EndIf
              EndIf
          EndSelect
        Wend
        *I\CurrentGroup = __INI_FindGroup(*I, "")
        
      EndIf
      CloseFile(FN)
    EndIf
  EndIf
  ProcedureReturn (*I)
EndProcedure

Procedure.i CreateINI(File.s, Flags.i = #Null)
  Protected *I.__INI = #Null
  If (File)
    Protected FN.i = CreateFile(#PB_Any, File)
    If (FN)
      CloseFile(FN)
      *I = OpenINI(File, Flags)
    EndIf
  EndIf
  ProcedureReturn (*I)
EndProcedure

Procedure.i FlushINIBuffers(INI.i)
  Protected Result.i = #False
  If (INI)
    Protected *I.__INI = INI
    If (*I\File)
      Protected FN.i = CreateFile(#PB_Any, *I\File)
      If (FN)
        CompilerIf (#PB_Compiler_Unicode)
          If (Not (*I\Flags & #INI_NoBOM))
            WriteStringFormat(FN, #PB_UTF8)
            WriteString(FN, *I\EOL)
          EndIf
        CompilerEndIf
        
        Protected TotalGroups.i
        Protected GroupWritten.i
        ForEach (*I\Entry())
          If (*I\Entry()\Type = #__INI_Group)
            GroupWritten.i = #False
          Else
            If (Not GroupWritten)
              If (*I\Flags & #INI_GroupSeparator)
                If (TotalGroups > 1)
                  WriteString(FN, *I\EOL)
                EndIf
              EndIf
              If (*I\Entry()\Parent\Name)
                WriteString(FN, *I\Entry()\Parent\FullText + *I\EOL)
              EndIf
              GroupWritten = #True
              TotalGroups  +  1
            EndIf
            WriteString(FN, *I\Entry()\FullText + *I\EOL)
          EndIf
        Next
        
        CloseFile(FN)
        *I\Flags & (~#__INI_Modified)
        Result = #True
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CloseINI(INI.i)
  If (INI)
    Protected *I.__INI = INI
    If (*I\Flags & #__INI_Modified)
      FlushINIBuffers(INI)
    EndIf
    ClearList(*I\Entry())
    ClearStructure(*I, __INI)
    FreeMemory(*I)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

;-
;- - Comments and Groups

Procedure INIComment(INI.i, Comment.s = "")
  If (INI)
    Protected *I.__INI = INI
    Protected *IE.__INIENTRY = __INI_AddEntry(*I, #__INI_Comment)
    If (*IE)
      *IE\FullText = *I\CommentPrefix + Comment
      *I\Flags | #__INI_Modified
    EndIf
  EndIf
EndProcedure

Procedure.i INIGroup(INI.i, Name.s)
  Protected *IE.__INIENTRY = #Null
  If (INI)
    Protected *I.__INI = INI
    *IE = __INI_FindGroup(*I, Name)
    If (Not *IE)
      *IE = __INI_AddEntry(*I, #__INI_Group)
      If (*IE)
        *IE\Name = Name
        *IE\FullText = "[" + Name + "]"
      EndIf
    EndIf
    If (*IE)
      *I\CurrentGroup = *IE
    EndIf
  EndIf
  ProcedureReturn (Bool(*IE))
EndProcedure

;-
;- - 'Remove' Procedures

Procedure RemoveINIGroup(INI.i, Name.s)
  If (INI)
    If (Name)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindGroup(*I, Name)
      If (*IE)
        ForEach (*I\Entry())
          If (*I\Entry()\Parent = *IE)
            DeleteElement(*I\Entry())
            *I\Flags | #__INI_Modified
          EndIf
        Next
        ChangeCurrentElement(*I\Entry(), *IE)
        DeleteElement(*I\Entry())
        If (*I\CurrentGroup = *IE)
          *I\CurrentGroup = __INI_FindGroup(*I, "")
        EndIf
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure RemoveINIKey(INI.i, Key.s)
  If (INI)
    If (Key)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindPair(*I, Key)
      If (*IE)
        ChangeCurrentElement(*I\Entry(), *IE)
        DeleteElement(*I\Entry())
        *I\Flags | #__INI_Modified
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure RemoveINIComments(INI.i, BlankOnly.i = #False)
  If (INI)
    Protected *I.__INI = INI
    ForEach (*I\Entry())
      If (*I\Entry()\Type = #__INI_Comment)
        If (Not BlankOnly)
          DeleteElement(*I\Entry())
          *I\Flags | #__INI_Modified
        Else
          Protected Line.s = Trim(*I\Entry()\FullText)
          If ((Line = ";") Or (Line = "#"))
            DeleteElement(*I\Entry())
            *I\Flags | #__INI_Modified
          EndIf
        EndIf
      EndIf
    Next
  EndIf
EndProcedure

;-
;- 'Rename' Procedures

Procedure.i RenameINIGroup(INI.i, OldName.s, NewName.s)
  Protected Result.i = #False
  If (INI)
    If (OldName And NewName)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindGroup(*I, OldName)
      If (*IE)
        If (Not __INI_FindGroup(*I, NewName))
          *IE\Name = NewName
          *IE\FullText = "[" + NewName + "]"
          *I\Flags | #__INI_Modified
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i RenameINIKey(INI.i, OldKey.s, NewKey.s)
  Protected Result.i = #False
  If (INI)
    If (OldKey And NewKey)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindPair(*I, OldKey)
      If (*IE)
        If (Not __INI_FindPair(*I, NewKey))
          *IE\Name = NewKey
          Protected Value.s = __INI_ExtractValue(*I, *IE\FullText)
          If (*I\Flags & #INI_NoSpace)
            *IE\FullText = NewKey + *I\Separator + Value
          Else
            *IE\FullText = NewKey + " " + *I\Separator + " " + Value
          EndIf
          *I\Flags | #__INI_Modified
          Result = #True
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- - 'Read' Procedures

Procedure.s ReadINIString(INI.i, Key.s, DefaultValue.s = "")
  Protected Result.s = DefaultValue
  If (INI)
    If (Key)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindPair(*I, Key)
      If (*IE)
        Result = __INI_ExtractValue(*I, *IE\FullText)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.d ReadINIDouble(INI.i, Key.s, DefaultValue.d = 0.0)
  Protected Result.d = DefaultValue
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    Result = ValD(ValueString)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.f ReadINIFloat(INI.i, Key.s, DefaultValue.f = 0.0)
  Protected Result.f = DefaultValue
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    Result = ValF(ValueString)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ReadINIInteger(INI.i, Key.s, DefaultValue.i = 0)
  Protected Result.i = DefaultValue
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    If (Left(ValueString, 1) = "#")
      Result = __INI_RGBVal(ValueString)
    Else
      Result = Val(ValueString)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ReadINIBool(INI.i, Key.s, DefaultValue.i = #False)
  Protected Result.i = Bool(DefaultValue)
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    Select (LCase(ValueString))
      Case "1", "true", "yes", "on", "enabled", "enable"
        Result = #True
      Default
        Result = #False
    EndSelect
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.l ReadINILong(INI.i, Key.s, DefaultValue.l = 0)
  Protected Result.l = DefaultValue
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    Result = Val(ValueString)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.q ReadINIQuad(INI.i, Key.s, DefaultValue.q = 0)
  Protected Result.q = DefaultValue
  Protected ValueString.s = Trim(ReadINIString(INI, Key))
  If (ValueString)
    Result = Val(ValueString)
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- - 'Write' Procedures

Procedure WriteINIString(INI.i, Key.s, Value.s)
  If (INI)
    If (Key)
      Protected *I.__INI = INI
      Protected *IE.__INIENTRY = __INI_FindPair(*I, Key.s)
      If (Not *IE)
        *IE = __INI_AddEntry(*I, #__INI_Pair)
        *IE\Name = Key
      EndIf
      If (*IE)
        If (*I\Flags & #INI_NoSpace)
          *IE\FullText = Key + *I\Separator + Value
        Else
          *IE\FullText = Key + " " + *I\Separator + " " + Value
        EndIf
        *I\Flags | #__INI_Modified
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure WriteINIDouble(INI.i, Key.s, Value.d, NbDecimal.i = #PB_Default)
  If (NbDecimal = #PB_Default)
    NbDecimal = 16
  EndIf
  WriteINIString(INI, Key, StrD(Value, NbDecimal))
EndProcedure

Procedure WriteINIFloat(INI.i, Key.s, Value.f, NbDecimal.i = #PB_Default)
  If (NbDecimal = #PB_Default)
    NbDecimal = 6
  EndIf
  WriteINIString(INI, Key, StrF(Value, NbDecimal))
EndProcedure

Procedure WriteINIInteger(INI.i, Key.s, Value.i, Format.i = #INI_Dec)
  Select (Format)
    Case #INI_Hex
      CompilerIf (SizeOf(INTEGER) = SizeOf(QUAD))
        WriteINIString(INI, Key, "$" + Hex(Value, #PB_Quad))
      CompilerElse
        WriteINIString(INI, Key, "$" + Hex(Value, #PB_Long))
      CompilerEndIf
    Case #INI_Bin
      WriteINIString(INI, Key, "%" + Bin(Value))
    Case #INI_RGB
      WriteINIString(INI, Key, __INI_RGBStr(Value, #False))
    Case #INI_RGBA
      WriteINIString(INI, Key, __INI_RGBStr(Value, #True))
    Default
      WriteINIString(INI, Key, Str(Value))
  EndSelect
EndProcedure

Procedure WriteINIBool(INI.i, Key.s, Value.i, Format.i = #INI_ZeroOne)
  If (Value)
    Select (Format)
      Case #INI_TrueFalse
        WriteINIString(INI, Key, "true")
      Case #INI_YesNo
        WriteINIString(INI, Key, "yes")
      Case #INI_OnOff
        WriteINIString(INI, Key, "on")
      Default
        WriteINIString(INI, Key, "1")
    EndSelect
  Else
    Select (Format)
      Case #INI_TrueFalse
        WriteINIString(INI, Key, "false")
      Case #INI_YesNo
        WriteINIString(INI, Key, "no")
      Case #INI_OnOff
        WriteINIString(INI, Key, "off")
      Default
        WriteINIString(INI, Key, "0")
    EndSelect
  EndIf
EndProcedure

Procedure WriteINILong(INI.i, Key.s, Value.l)
  WriteINIString(INI, Key, Str(Value))
EndProcedure

Procedure WriteINIQuad(INI.i, Key.s, Value.q)
  WriteINIString(INI, Key, Str(Value))
EndProcedure

;-
;- 'Examine' Procedures

Procedure.i ExamineINIGroups(INI.i)
  Protected Result.i = 0
  If (INI)
    Protected *I.__INI = INI
    *I\ExamineGroup = #Null
    *I\ExaminePair  = #Null
    PushListPosition(*I\Entry())
      ForEach (*I\Entry())
        If (*I\Entry()\Type = #__INI_Group)
          If (*I\Entry()\Name <> "")
            Result + 1
          EndIf
        EndIf
      Next
    PopListPosition(*I\Entry())
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextINIGroup(INI.i)
  Protected Result.i = #False
  If (INI)
    Protected *I.__INI = INI
    If (*I\ExamineGroup = -1)
      ; Done
    Else
      Protected *IE.__INIENTRY = #Null
      PushListPosition(*I\Entry())
        If (*I\ExamineGroup = #Null)
          ResetList(*I\Entry())
        Else
          ChangeCurrentElement(*I\Entry(), *I\ExamineGroup)
        EndIf
        While (NextElement(*I\Entry()))
          If (*I\Entry()\Type = #__INI_Group)
            If (*I\Entry()\Name <> "")
              *IE = @*I\Entry()
              Break
            EndIf
          EndIf
        Wend
      PopListPosition(*I\Entry())
      If (*IE)
        *I\ExamineGroup = *IE
        *I\CurrentGroup = *IE
        Result = #True
      Else
        *I\ExamineGroup = -1
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s INIGroupName(INI.i)
  Protected Result.s = ""
  If (INI)
    Protected *I.__INI = INI
    If (*I\ExamineGroup)
      Result = *I\ExamineGroup\Name
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i ExamineINIKeys(INI.i)
  Protected Result.i = 0
  If (INI)
    Protected *I.__INI = INI
    *I\ExaminePair = #Null
    PushListPosition(*I\Entry())
      ForEach (*I\Entry())
        If (*I\Entry()\Type = #__INI_Pair)
          If (*I\Entry()\Parent = *I\CurrentGroup)
            Result + 1
          EndIf
        EndIf
      Next
    PopListPosition(*I\Entry())
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextINIKey(INI.i)
  Protected Result.i = #False
  If (INI)
    Protected *I.__INI = INI
    If (*I\ExaminePair = -1)
      ; Done
    Else
      Protected *IE.__INIENTRY = #Null
      PushListPosition(*I\Entry())
        If (*I\ExaminePair = #Null)
          ResetList(*I\Entry())
        Else
          ChangeCurrentElement(*I\Entry(), *I\ExaminePair)
        EndIf
        While (NextElement(*I\Entry()))
          If (*I\Entry()\Type = #__INI_Pair)
            If (*I\Entry()\Parent = *I\CurrentGroup)
              *IE = @*I\Entry()
              Break
            EndIf
          EndIf
        Wend
      PopListPosition(*I\Entry())
      If (*IE)
        *I\ExaminePair = *IE
        Result = #True
      Else
        *I\ExaminePair = -1
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s INIKeyName(INI.i)
  Protected Result.s = ""
  If (INI)
    Protected *I.__INI = INI
    If (*I\ExaminePair)
      Result = *I\ExaminePair\Name
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s INIKeyValue(INI.i)
  Protected Result.s = ""
  If (INI)
    Protected *I.__INI = INI
    If (*I\ExaminePair)
      Result = __INI_ExtractValue(*I, *I\ExaminePair\FullText)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure





;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

Path.s  = GetTemporaryDirectory()
File1.s = Path + "test1.ini"
File2.s = Path + "test2.ini"



i1 = CreateINI(File1, #INI_GroupSeparator)
If (i1)
  
  INIComment(i1, "Hello World!")
  INIComment(i1)
  
  INIGroup(i1, "Basics")
  WriteINIString(i1,  "Foo",     "Bar")
  INIComment(i1, "...")
  WriteINIFloat(i1,   "Gravity", 9.81, 2)
  WriteINIInteger(i1, "Version", #INI_Version)
  WriteINIString(i1,  "Empty",   "")
  
  INIGroup(i1, "Integers")
  WriteINIInteger(i1, "Default", 1234)
  WriteINIInteger(i1, "Hex",     1234, #INI_Hex)
  WriteINIInteger(i1, "Binary",  1234, #INI_Bin)
  
  INIGroup(i1, "Colors")
  WriteINIInteger(i1, "Yellow",    RGB(255, 255, 0),      #INI_RGB)
  WriteINIInteger(i1, "WithAlpha", RGBA(255, 255, 0, 64), #INI_RGBA)
  WriteINIInteger(i1, "Green",     RGB(255, 255, 0),      #INI_RGB)
  
  INIGroup(i1, "Empty Group")
  
  INIGroup(i1, "Dummy Group")
  WriteINIString(i1, "Dummy", "You shouldn't see this!")
  RemoveINIGroup(i1, "Dummy Group")
  WriteINIString(i1, "Back to", "default group")
  
  INIGroup(i1, "Colors")
  RemoveINIKey(i1, "Green")
  RenameINIKey(i1, "Yellow", "NotBlue")
  
  FlushINIBuffers(i1)
  
  RenameINIGroup(i1, "Basics", "The Basics")
  
  
  
  
  
  i2 = CreateINI(File2, #INI_NoSpace | #INI_UseLF | #INI_NoBOM)
  If (i2)
    WriteINIString(i2, "This is", "another INI open at the same time!")
    CloseINI(i2)
  EndIf
  
  
  
  
  INIGroup(i1, "Bools")
  WriteINIBool(i1, "PB_Compiler_Unicode",    #PB_Compiler_Unicode)
  WriteINIBool(i1, "PB_Compiler_Debugger",   #PB_Compiler_Debugger,   #INI_OnOff)
  WriteINIBool(i1, "PB_Compiler_Executable", #PB_Compiler_Executable, #INI_TrueFalse)
  WriteINIBool(i1, "PB_Compiler_IsMainFile", #PB_Compiler_IsMainFile, #INI_YesNo)
  
  CloseINI(i1)
  RunProgram(File1)
  Delay(500)
  
  
  
  
  
  i1 = OpenINI(File1)
  If (i1)
    
    Debug "# Groups: " + Str(ExamineINIGroups(i1))
    While (NextINIGroup(i1))
      Debug ""
      Debug "(" + INIGroupName(i1) + ")"
      Debug "   # Keys: " + Str(ExamineINIKeys(i1))
      While (NextINIKey(i1))
        Debug "'" + INIKeyName(i1) + "' is '" + INIKeyValue(i1) + "'"
      Wend
    Wend
    
    Debug ""
    Debug "----------"
    
    INIGroup(i1, "Integers")
    Debug ""
    Debug "Read Integers:"
    Debug ReadINIInteger(i1, "Default")
    Debug ReadINIInteger(i1, "Hex")
    Debug ReadINIInteger(i1, "Binary")
    
    INIGroup(i1, "Colors")
    Debug ""
    Debug "Read Colors:"
    Debug Hex(ReadINIInteger(i1, "NotBlue"))
    Debug Hex(ReadINIInteger(i1, "WithAlpha"))
    
    INIGroup(i1, "Bools")
    Debug ""
    Debug "Read Bools:"
    Debug "Unicode -> "    + ReadINIBool(i1, "PB_Compiler_Unicode")
    Debug "Debugger -> "   + ReadINIBool(i1, "PB_Compiler_Debugger")
    Debug "Executable -> " + ReadINIBool(i1, "PB_Compiler_Executable")
    Debug "IsMainFile -> " + ReadINIBool(i1, "PB_Compiler_IsMainFile")
    
    CloseINI(i1)
  EndIf
  
EndIf

CompilerEndIf
CompilerEndIf
;-