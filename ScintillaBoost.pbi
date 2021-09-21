; +----------------+
; | ScintillaBoost |
; +----------------+
; | 2014.10.02 . Creation (PureBasic 5.30)
; |        .22 . Added some Stop > Start safety checks
; | 2015.01.05 . Fixed Unicode GetRangeText_(), added "LineTrimmed" functions
; |        .09 . Added Sci_Find, Sci_IsWord, Sci_AdjustView, Sci_IsLineVisible
; |     .02.10 . Replaced some Len() calls with StringByteLength() for UTF8
; |     .03.04 . Converted Sci_Get###Chars functions to use ASCII
; |     .07.08 . Added GetCharacterAndWidth
; |        .27 . Added SetBorder for Windows
; |     .11.25 . Added SetScrollViewBackground for Mac
; | 2016.02.17 . Sci_DeleteForward_() now maps directly to Sci_Clear()
; | 2017.01.05 . Added Sci_AppendNull_()
; |     .05.22 . Multiple-include safe
; | 2018.11.12 . Improved Find_() and GetRangeText_() Unicode handling
; |        .13 . Rewrote Find_() to use native Scintilla search,
; |                added LoadFile_() and SaveFile_(), Find direction macros
; | 2019.01.15 . Find_() now calls ScrollRange(), added ScrollSelection_(),
; |                fixed 0-terminator byte bug in GetRangeText_()
; |     .05.23 . Added Sci_GetScrollYPercent_()
; |        .25 . Added Sci_SetScrollYPercent_()

;   Generated 2021.03.16
;     via "ScintillaBoost_Generator.pb"
;     in PureBasic 5.73
;     processing "ScintillaList-20141002.txt"

CompilerIf (Not Defined(__ScintillaBoost_Included, #PB_Constant))
#__ScintillaBoost_Included = #True

;-
;-
;- ScintillaBoost Header
;-


CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

Procedure.i _Sci_SendProc(Gadget.i, Message.i, Param.i, lParam.i)
  ProcedureReturn (ScintillaSendMessage(Gadget, Message, Param, lParam))
EndProcedure

CompilerIf (Not Defined(SB_UseASCIIStrings, #PB_Constant))
  #SB_UseASCIIStrings = #False
CompilerEndIf
CompilerIf (#SB_UseASCIIStrings)
  Macro _Sci_StrPtr
    p-ascii
  EndMacro
CompilerElse
  Macro _Sci_StrPtr
    p-utf8
  EndMacro
CompilerEndIf

CompilerIf (Not Defined(SB_UsePokeUTF8, #PB_Constant))
  #SB_UsePokeUTF8 = #False
CompilerEndIf
CompilerIf (#SB_UsePokeUTF8)

Procedure.i _Sci_SendStr(Gadget.i, Message.i, Param.i, lParam.s)
  Protected lBuffer.s = Space(3*Len(lParam))
  PokeS(@lBuffer, lParam, -1, #PB_UTF8)
  ProcedureReturn (ScintillaSendMessage(Gadget, Message, Param, @lBuffer))
EndProcedure

Procedure.i _Sci_SendStr2(Gadget.i, Message.i, Param.s, lParam.s)
  Protected Buffer.s  = Space(3*Len(Param))
  PokeS(@Buffer,  Param, -1, #PB_UTF8)
  Protected lBuffer.s = Space(3*Len(lParam))
  PokeS(@lBuffer, lParam, -1, #PB_UTF8)
  ProcedureReturn (ScintillaSendMessage(Gadget, Message, @Buffer, @lBuffer))
EndProcedure

Procedure.i _Sci_SendStrFirst(Gadget.i, Message.i, Param.s, lParam.i)
  Protected Buffer.s = Space(3*Len(Param))
  PokeS(@Buffer, Param, -1, #PB_UTF8)
  ProcedureReturn (ScintillaSendMessage(Gadget, Message, @Buffer, lParam))
EndProcedure

CompilerElse

Prototype.i _Sci_SendStrProto(Gadget.i, Message.i, Param.i, lParam._Sci_StrPtr)
Global      _Sci_SendStr._Sci_SendStrProto = @_Sci_SendProc()
Prototype.i _Sci_SendStr2Proto(Gadget.i, Message.i, Param._Sci_StrPtr, lParam._Sci_StrPtr)
Global      _Sci_SendStr2._Sci_SendStr2Proto = @_Sci_SendProc()
Prototype.i _Sci_SendStrFirstProto(Gadget.i, Message.i, Param._Sci_StrPtr, lParam.i)
Global      _Sci_SendStrFirst._Sci_SendStrFirstProto = @_Sci_SendProc()
Prototype.i _Sci_SendStrAsciiProto(Gadget.i, Message.i, Param.i, lParam.p-ascii)
Global      _Sci_SendStrAscii._Sci_SendStrAsciiProto = @_Sci_SendProc()

#SB_UsePokeUTF8 = #False

CompilerEndIf

Macro _Sci_PeekUTF8(Address)
  PeekS((Address), -1, #PB_UTF8)
EndMacro


;-
;-
;- Text retrieval and modification
;-

Procedure.s Sci_GetText(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETTEXT, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETTEXT, nLenPlus1, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_SetText(Gadget, text)
  _Sci_SendStr((Gadget), #SCI_SETTEXT, #Null, (text))
EndMacro

Macro Sci_SetSavePoint(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SETSAVEPOINT)
EndMacro

Procedure.s Sci_GetLine(Gadget.i, line.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETLINE, line, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETLINE, line, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_ReplaceSel(Gadget, text)
  _Sci_SendStr((Gadget), #SCI_REPLACESEL, #Null, (text))
EndMacro

Macro Sci_SetReadOnly(Gadget, readOnly)
  ScintillaSendMessage((Gadget), #SCI_SETREADONLY, (readOnly))
EndMacro

Macro Sci_GetReadOnly(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETREADONLY)
EndMacro

Macro Sci_GetTextRange(Gadget, tr)
  ScintillaSendMessage((Gadget), #SCI_GETTEXTRANGE, #Null, (tr))
EndMacro

Macro Sci_Allocate(Gadget, bytes)
  ScintillaSendMessage((Gadget), #SCI_ALLOCATE, (bytes))
EndMacro

Procedure.i Sci_AddText(Gadget.i, text.s, length.i = -1)
  If (length = -1)
    CompilerIf (#SB_UseASCIIStrings And (Not #SB_UsePokeUTF8))
      length = Len(text)
    CompilerElse
      length = StringByteLength(text, #PB_UTF8)
    CompilerEndIf
  EndIf
  ProcedureReturn (_Sci_SendStr(Gadget, #SCI_ADDTEXT, length, text))
EndProcedure

Macro Sci_AddStyledText(Gadget, length, s)
  ScintillaSendMessage((Gadget), #SCI_ADDSTYLEDTEXT, (length), (s))
EndMacro

Procedure.i Sci_AppendText(Gadget.i, text.s, length.i = -1)
  If (length = -1)
    CompilerIf (#SB_UseASCIIStrings And (Not #SB_UsePokeUTF8))
      length = Len(text)
    CompilerElse
      length = StringByteLength(text, #PB_UTF8)
    CompilerEndIf
  EndIf
  ProcedureReturn (_Sci_SendStr(Gadget, #SCI_APPENDTEXT, length, text))
EndProcedure

Macro Sci_InsertText(Gadget, text, pos = -1)
  _Sci_SendStr((Gadget), #SCI_INSERTTEXT, (pos), (text))
EndMacro

Procedure.i Sci_ChangeInsertion(Gadget.i, text.s, length.i = -1)
  If (length = -1)
    CompilerIf (#SB_UseASCIIStrings And (Not #SB_UsePokeUTF8))
      length = Len(text)
    CompilerElse
      length = StringByteLength(text, #PB_UTF8)
    CompilerEndIf
  EndIf
  ProcedureReturn (_Sci_SendStr(Gadget, #SCI_CHANGEINSERTION, length, text))
EndProcedure

Macro Sci_ClearAll(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEARALL)
EndMacro

Macro Sci_DeleteRange(Gadget, pos, deleteLength)
  ScintillaSendMessage((Gadget), #SCI_DELETERANGE, (pos), (deleteLength))
EndMacro

Macro Sci_ClearDocumentStyle(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEARDOCUMENTSTYLE)
EndMacro

Macro Sci_GetCharAt(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_GETCHARAT, (position))
EndMacro

Macro Sci_GetStyleAt(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_GETSTYLEAT, (position))
EndMacro

Macro Sci_GetStyledText(Gadget, tr)
  ScintillaSendMessage((Gadget), #SCI_GETSTYLEDTEXT, #Null, (tr))
EndMacro

Macro Sci_ReleaseAllExtendedStyles(Gadget)
  ScintillaSendMessage((Gadget), #SCI_RELEASEALLEXTENDEDSTYLES)
EndMacro

Macro Sci_AllocateExtendedStyles(Gadget, numberStyles)
  ScintillaSendMessage((Gadget), #SCI_ALLOCATEEXTENDEDSTYLES, (numberStyles))
EndMacro

;-
;-
;- Searching
;-

Macro Sci_FindText(Gadget, flags, ttf)
  ScintillaSendMessage((Gadget), #SCI_FINDTEXT, (flags), (ttf))
EndMacro

Macro Sci_SearchAnchor(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SEARCHANCHOR)
EndMacro

Macro Sci_SearchNext(Gadget, searchFlags, text)
  _Sci_SendStr((Gadget), #SCI_SEARCHNEXT, (searchFlags), (text))
EndMacro

Macro Sci_SearchPrev(Gadget, searchFlags, text)
  _Sci_SendStr((Gadget), #SCI_SEARCHPREV, (searchFlags), (text))
EndMacro

;-
;-
;- Search and replace using the target
;-

Macro Sci_SetTargetStart(Gadget, pos)
  ScintillaSendMessage((Gadget), #SCI_SETTARGETSTART, (pos))
EndMacro

Macro Sci_GetTargetStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTARGETSTART)
EndMacro

Macro Sci_SetTargetEnd(Gadget, pos)
  ScintillaSendMessage((Gadget), #SCI_SETTARGETEND, (pos))
EndMacro

Macro Sci_GetTargetEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTARGETEND)
EndMacro

Macro Sci_TargetFromSelection(Gadget)
  ScintillaSendMessage((Gadget), #SCI_TARGETFROMSELECTION)
EndMacro

Macro Sci_SetSearchFlags(Gadget, searchFlags)
  ScintillaSendMessage((Gadget), #SCI_SETSEARCHFLAGS, (searchFlags))
EndMacro

Macro Sci_GetSearchFlags(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSEARCHFLAGS)
EndMacro

Procedure.i Sci_SearchInTarget(Gadget.i, text.s, length.i = -1)
  If (length = -1)
    CompilerIf (#SB_UseASCIIStrings And (Not #SB_UsePokeUTF8))
      length = Len(text)
    CompilerElse
      length = StringByteLength(text, #PB_UTF8)
    CompilerEndIf
  EndIf
  ProcedureReturn (_Sci_SendStr(Gadget, #SCI_SEARCHINTARGET, length, text))
EndProcedure

Macro Sci_ReplaceTarget(Gadget, text, length = -1)
  _Sci_SendStr((Gadget), #SCI_REPLACETARGET, (length), (text))
EndMacro

Macro Sci_ReplaceTargetRE(Gadget, text, length = -1)
  _Sci_SendStr((Gadget), #SCI_REPLACETARGETRE, (length), (text))
EndProcedure

;- ----- Sci_GetTag (int tagNumber, char* tagValue) [Int, StrOut]

;-
;-
;- Overtype
;-

Macro Sci_SetOvertype(Gadget, overType)
  ScintillaSendMessage((Gadget), #SCI_SETOVERTYPE, (overType))
EndMacro

Macro Sci_GetOvertype(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETOVERTYPE)
EndMacro

;-
;-
;- Cut, copy and paste
;-

Macro Sci_Cut(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CUT)
EndMacro

Macro Sci_Copy(Gadget)
  ScintillaSendMessage((Gadget), #SCI_COPY)
EndMacro

Macro Sci_Paste(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PASTE)
EndMacro

Macro Sci_Clear(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEAR)
EndMacro

Macro Sci_CanPaste(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CANPASTE)
EndMacro

Macro Sci_CopyRange(Gadget, start, endPos)
  ScintillaSendMessage((Gadget), #SCI_COPYRANGE, (start), (endPos))
EndMacro

Procedure.i Sci_CopyText(Gadget.i, text.s, length.i = -1)
  If (length = -1)
    CompilerIf (#SB_UseASCIIStrings And (Not #SB_UsePokeUTF8))
      length = Len(text)
    CompilerElse
      length = StringByteLength(text, #PB_UTF8)
    CompilerEndIf
  EndIf
  ProcedureReturn (_Sci_SendStr(Gadget, #SCI_COPYTEXT, length, text))
EndProcedure

Macro Sci_CopyAllowLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_COPYALLOWLINE)
EndMacro

Macro Sci_SetPasteConvertEndings(Gadget, convert)
  ScintillaSendMessage((Gadget), #SCI_SETPASTECONVERTENDINGS, (convert))
EndMacro

Macro Sci_GetPasteConvertEndings(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPASTECONVERTENDINGS)
EndMacro

;-
;-
;- Error handling
;-

Macro Sci_SetStatus(Gadget, status)
  ScintillaSendMessage((Gadget), #SCI_SETSTATUS, (status))
EndMacro

Macro Sci_GetStatus(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSTATUS)
EndMacro

;-
;-
;- Undo and Redo
;-

Macro Sci_Undo(Gadget)
  ScintillaSendMessage((Gadget), #SCI_UNDO)
EndMacro

Macro Sci_CanUndo(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CANUNDO)
EndMacro

Macro Sci_EmptyUndoBuffer(Gadget)
  ScintillaSendMessage((Gadget), #SCI_EMPTYUNDOBUFFER)
EndMacro

Macro Sci_Redo(Gadget)
  ScintillaSendMessage((Gadget), #SCI_REDO)
EndMacro

Macro Sci_CanRedo(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CANREDO)
EndMacro

Macro Sci_SetUndoCollection(Gadget, collectUndo)
  ScintillaSendMessage((Gadget), #SCI_SETUNDOCOLLECTION, (collectUndo))
EndMacro

Macro Sci_GetUndoCollection(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETUNDOCOLLECTION)
EndMacro

Macro Sci_BeginUndoAction(Gadget)
  ScintillaSendMessage((Gadget), #SCI_BEGINUNDOACTION)
EndMacro

Macro Sci_EndUndoAction(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ENDUNDOACTION)
EndMacro

Macro Sci_AddUndoAction(Gadget, token, flags)
  ScintillaSendMessage((Gadget), #SCI_ADDUNDOACTION, (token), (flags))
EndMacro

;-
;-
;- Selection and information
;-

Macro Sci_GetTextLength(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTEXTLENGTH)
EndMacro

Macro Sci_GetLength(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLENGTH)
EndMacro

Macro Sci_GetLineCount(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLINECOUNT)
EndMacro

Macro Sci_SetFirstVisibleLine(Gadget, lineDisplay)
  ScintillaSendMessage((Gadget), #SCI_SETFIRSTVISIBLELINE, (lineDisplay))
EndMacro

Macro Sci_GetFirstVisibleLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETFIRSTVISIBLELINE)
EndMacro

Macro Sci_LinesOnScreen(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINESONSCREEN)
EndMacro

Macro Sci_GetModify(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMODIFY)
EndMacro

Macro Sci_SetSel(Gadget, anchorPos, currentPos)
  ScintillaSendMessage((Gadget), #SCI_SETSEL, (anchorPos), (currentPos))
EndMacro

Macro Sci_GoToPos(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_GOTOPOS, (position))
EndMacro

Macro Sci_GoToLine(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GOTOLINE, (line))
EndMacro

Macro Sci_SetCurrentPos(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_SETCURRENTPOS, (position))
EndMacro

Macro Sci_GetCurrentPos(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCURRENTPOS)
EndMacro

Macro Sci_SetAnchor(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_SETANCHOR, (position))
EndMacro

Macro Sci_GetAnchor(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETANCHOR)
EndMacro

Macro Sci_SetSelectionStart(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONSTART, (position))
EndMacro

Macro Sci_GetSelectionStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONSTART)
EndMacro

Macro Sci_SetSelectionEnd(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONEND, (position))
EndMacro

Macro Sci_GetSelectionEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONEND)
EndMacro

Macro Sci_SetEmptySelection(Gadget, pos)
  ScintillaSendMessage((Gadget), #SCI_SETEMPTYSELECTION, (pos))
EndMacro

Macro Sci_SelectAll(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SELECTALL)
EndMacro

Macro Sci_LineFromPosition(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_LINEFROMPOSITION, (position))
EndMacro

Macro Sci_PositionFromLine(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_POSITIONFROMLINE, (line))
EndMacro

Macro Sci_GetLineEndPosition(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINEENDPOSITION, (line))
EndMacro

Macro Sci_LineLength(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_LINELENGTH, (line))
EndMacro

Macro Sci_GetColumn(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_GETCOLUMN, (position))
EndMacro

Macro Sci_FindColumn(Gadget, line, column)
  ScintillaSendMessage((Gadget), #SCI_FINDCOLUMN, (line), (column))
EndMacro

Macro Sci_PositionFromPoint(Gadget, x, y)
  ScintillaSendMessage((Gadget), #SCI_POSITIONFROMPOINT, (x), (y))
EndMacro

Macro Sci_PositionFromPointClose(Gadget, x, y)
  ScintillaSendMessage((Gadget), #SCI_POSITIONFROMPOINTCLOSE, (x), (y))
EndMacro

Macro Sci_CharPositionFromPoint(Gadget, x, y)
  ScintillaSendMessage((Gadget), #SCI_CHARPOSITIONFROMPOINT, (x), (y))
EndMacro

Macro Sci_CharPositionFromPointClose(Gadget, x, y)
  ScintillaSendMessage((Gadget), #SCI_CHARPOSITIONFROMPOINTCLOSE, (x), (y))
EndMacro

Macro Sci_PointXFromPosition(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_POINTXFROMPOSITION, #Null, (position))
EndMacro

Macro Sci_PointYFromPosition(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_POINTYFROMPOSITION, #Null, (position))
EndMacro

Macro Sci_HideSelection(Gadget, hide)
  ScintillaSendMessage((Gadget), #SCI_HIDESELECTION, (hide))
EndMacro

Procedure.s Sci_GetSelText(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETSELTEXT, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETSELTEXT, 0, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Procedure.s Sci_GetCurLine(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETCURLINE, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETCURLINE, nLenPlus1, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_SelectionIsRectangle(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SELECTIONISRECTANGLE)
EndMacro

Macro Sci_SetSelectionMode(Gadget, mode)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONMODE, (mode))
EndMacro

Macro Sci_GetSelectionMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONMODE)
EndMacro

Macro Sci_GetLineSelStartPosition(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINESELSTARTPOSITION, (line))
EndMacro

Macro Sci_GetLineSelEndPosition(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINESELENDPOSITION, (line))
EndMacro

Macro Sci_MoveCaretInsideView(Gadget)
  ScintillaSendMessage((Gadget), #SCI_MOVECARETINSIDEVIEW)
EndMacro

Macro Sci_WordEndPosition(Gadget, position, onlyWordCharacters)
  ScintillaSendMessage((Gadget), #SCI_WORDENDPOSITION, (position), (onlyWordCharacters))
EndMacro

Macro Sci_WordStartPosition(Gadget, position, onlyWordCharacters)
  ScintillaSendMessage((Gadget), #SCI_WORDSTARTPOSITION, (position), (onlyWordCharacters))
EndMacro

Macro Sci_PositionBefore(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_POSITIONBEFORE, (position))
EndMacro

Macro Sci_PositionAfter(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_POSITIONAFTER, (position))
EndMacro

Macro Sci_PositionRelative(Gadget, position, relative)
  ScintillaSendMessage((Gadget), #SCI_POSITIONRELATIVE, (position), (relative))
EndMacro

Macro Sci_CountCharacters(Gadget, startPos, endPos)
  ScintillaSendMessage((Gadget), #SCI_COUNTCHARACTERS, (startPos), (endPos))
EndMacro

Macro Sci_TextWidth(Gadget, styleNumber, text)
  _Sci_SendStr((Gadget), #SCI_TEXTWIDTH, (styleNumber), (text))
EndMacro

Macro Sci_TextHeight(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_TEXTHEIGHT, (line))
EndMacro

Macro Sci_ChooseCaretX(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHOOSECARETX)
EndMacro

Macro Sci_SetMouseSelectionRectangularSwitch(Gadget, mouseSelectionRectangularSwitch)
  ScintillaSendMessage((Gadget), #SCI_SETMOUSESELECTIONRECTANGULARSWITCH, (mouseSelectionRectangularSwitch))
EndMacro

Macro Sci_GetMouseSelectionRectangularSwitch(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMOUSESELECTIONRECTANGULARSWITCH)
EndMacro

;-
;-
;- Multiple Selection and Virtual Space
;-

Macro Sci_SetMultipleSelection(Gadget, multipleSelection)
  ScintillaSendMessage((Gadget), #SCI_SETMULTIPLESELECTION, (multipleSelection))
EndMacro

Macro Sci_GetMultipleSelection(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMULTIPLESELECTION)
EndMacro

Macro Sci_SetAdditionalSelectionTyping(Gadget, additionalSelectionTyping)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALSELECTIONTYPING, (additionalSelectionTyping))
EndMacro

Macro Sci_GetAdditionalSelectionTyping(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETADDITIONALSELECTIONTYPING)
EndMacro

Macro Sci_SetMultiPaste(Gadget, multiPaste)
  ScintillaSendMessage((Gadget), #SCI_SETMULTIPASTE, (multiPaste))
EndMacro

Macro Sci_GetMultiPaste(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMULTIPASTE)
EndMacro

Macro Sci_SetVirtualSpaceOptions(Gadget, virtualSpaceOptions)
  ScintillaSendMessage((Gadget), #SCI_SETVIRTUALSPACEOPTIONS, (virtualSpaceOptions))
EndMacro

Macro Sci_GetVirtualSpaceOptions(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETVIRTUALSPACEOPTIONS)
EndMacro

Macro Sci_SetRectangularSelectionModifier(Gadget, modifier)
  ScintillaSendMessage((Gadget), #SCI_SETRECTANGULARSELECTIONMODIFIER, (modifier))
EndMacro

Macro Sci_GetRectangularSelectionModifier(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETRECTANGULARSELECTIONMODIFIER)
EndMacro

Macro Sci_GetSelectionS(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONS)
EndMacro

Macro Sci_GetSelectionEmpty(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONEMPTY)
EndMacro

Macro Sci_ClearSelections(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEARSELECTIONS)
EndMacro

Macro Sci_SetSelection(Gadget, caret, anchor)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTION, (caret), (anchor))
EndMacro

Macro Sci_AddSelection(Gadget, caret, anchor)
  ScintillaSendMessage((Gadget), #SCI_ADDSELECTION, (caret), (anchor))
EndMacro

Macro Sci_DropSelectionN(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_DROPSELECTIONN, (selection))
EndMacro

Macro Sci_SetMainSelection(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_SETMAINSELECTION, (selection))
EndMacro

Macro Sci_GetMainSelection(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMAINSELECTION)
EndMacro

Macro Sci_SetSelectionNCaret(Gadget, selection, pos)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNCARET, (selection), (pos))
EndMacro

Macro Sci_GetSelectionNCaret(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNCARET, (selection))
EndMacro

Macro Sci_SetSelectionNCaretVirtualSpace(Gadget, selection, space)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNCARETVIRTUALSPACE, (selection), (space))
EndMacro

Macro Sci_GetSelectionNCaretVirtualSpace(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNCARETVIRTUALSPACE, (selection))
EndMacro

Macro Sci_SetSelectionNAnchor(Gadget, selection, posAnchor)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNANCHOR, (selection), (posAnchor))
EndMacro

Macro Sci_GetSelectionNAnchor(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNANCHOR, (selection))
EndMacro

Macro Sci_SetSelectionNAnchorVirtualSpace(Gadget, selection, space)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNANCHORVIRTUALSPACE, (selection), (space))
EndMacro

Macro Sci_GetSelectionNAnchorVirtualSpace(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNANCHORVIRTUALSPACE, (selection))
EndMacro

Macro Sci_SetSelectionNStart(Gadget, selection, pos)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNSTART, (selection), (pos))
EndMacro

Macro Sci_GetSelectionNStart(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNSTART, (selection))
EndMacro

Macro Sci_SetSelectionNEnd(Gadget, selection, pos)
  ScintillaSendMessage((Gadget), #SCI_SETSELECTIONNEND, (selection), (pos))
EndMacro

Macro Sci_GetSelectionNEnd(Gadget, selection)
  ScintillaSendMessage((Gadget), #SCI_GETSELECTIONNEND, (selection))
EndMacro

Macro Sci_SetRectangularSelectionCaret(Gadget, pos)
  ScintillaSendMessage((Gadget), #SCI_SETRECTANGULARSELECTIONCARET, (pos))
EndMacro

Macro Sci_GetRectangularSelectionCaret(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETRECTANGULARSELECTIONCARET)
EndMacro

Macro Sci_SetRectangularSelectionCaretVirtualSpace(Gadget, space)
  ScintillaSendMessage((Gadget), #SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE, (space))
EndMacro

Macro Sci_GetRectangularSelectionCaretVirtualSpace(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE)
EndMacro

Macro Sci_SetRectangularSelectionAnchor(Gadget, posAnchor)
  ScintillaSendMessage((Gadget), #SCI_SETRECTANGULARSELECTIONANCHOR, (posAnchor))
EndMacro

Macro Sci_GetRectangularSelectionAnchor(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETRECTANGULARSELECTIONANCHOR)
EndMacro

Macro Sci_SetRectangularSelectionAnchorVirtualSpace(Gadget, space)
  ScintillaSendMessage((Gadget), #SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE, (space))
EndMacro

Macro Sci_GetRectangularSelectionAnchorVirtualSpace(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE)
EndMacro

Macro Sci_SetAdditionalSelAlpha(Gadget, alpha)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALSELALPHA, (alpha))
EndMacro

Macro Sci_GetAdditionalSelAlpha(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETADDITIONALSELALPHA)
EndMacro

Macro Sci_SetAdditionalSelFore(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALSELFORE, (colour))
EndMacro

Macro Sci_SetAdditionalSelBack(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALSELBACK, (colour))
EndMacro

Macro Sci_SetAdditionalCaretFore(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALCARETFORE, (colour))
EndMacro

Macro Sci_GetAdditionalCaretFore(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETADDITIONALCARETFORE)
EndMacro

Macro Sci_SetAdditionalCaretSBlink(Gadget, additionalCaretsBlink)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALCARETSBLINK, (additionalCaretsBlink))
EndMacro

Macro Sci_GetAdditionalCaretSBlink(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETADDITIONALCARETSBLINK)
EndMacro

Macro Sci_SetAdditionalCaretSVisible(Gadget, additionalCaretsVisible)
  ScintillaSendMessage((Gadget), #SCI_SETADDITIONALCARETSVISIBLE, (additionalCaretsVisible))
EndMacro

Macro Sci_GetAdditionalCaretSVisible(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETADDITIONALCARETSVISIBLE)
EndMacro

Macro Sci_SwapMainAnchorCaret(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SWAPMAINANCHORCARET)
EndMacro

Macro Sci_RotateSelection(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ROTATESELECTION)
EndMacro

;-
;-
;- Scrolling and automatic scrolling
;-

Macro Sci_Linescroll(Gadget, column, line)
  ScintillaSendMessage((Gadget), #SCI_LINESCROLL, (column), (line))
EndMacro

Macro Sci_ScrollCaret(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SCROLLCARET)
EndMacro

Macro Sci_ScrollRange(Gadget, secondary, primary)
  ScintillaSendMessage((Gadget), #SCI_SCROLLRANGE, (secondary), (primary))
EndMacro

Macro Sci_SetXCaretPolicy(Gadget, caretPolicy, caretSlop)
  ScintillaSendMessage((Gadget), #SCI_SETXCARETPOLICY, (caretPolicy), (caretSlop))
EndMacro

Macro Sci_SetYCaretPolicy(Gadget, caretPolicy, caretSlop)
  ScintillaSendMessage((Gadget), #SCI_SETYCARETPOLICY, (caretPolicy), (caretSlop))
EndMacro

Macro Sci_SetVisiblePolicy(Gadget, caretPolicy, caretSlop)
  ScintillaSendMessage((Gadget), #SCI_SETVISIBLEPOLICY, (caretPolicy), (caretSlop))
EndMacro

Macro Sci_SetHScrollbar(Gadget, visible)
  ScintillaSendMessage((Gadget), #SCI_SETHSCROLLBAR, (visible))
EndMacro

Macro Sci_GetHScrollbar(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHSCROLLBAR)
EndMacro

Macro Sci_SetVScrollbar(Gadget, visible)
  ScintillaSendMessage((Gadget), #SCI_SETVSCROLLBAR, (visible))
EndMacro

Macro Sci_GetVScrollbar(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETVSCROLLBAR)
EndMacro

Macro Sci_GetXOffset(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETXOFFSET)
EndMacro

Macro Sci_SetXOffset(Gadget, xOffset)
  ScintillaSendMessage((Gadget), #SCI_SETXOFFSET, (xOffset))
EndMacro

Macro Sci_SetScrollWidth(Gadget, pixelWidth)
  ScintillaSendMessage((Gadget), #SCI_SETSCROLLWIDTH, (pixelWidth))
EndMacro

Macro Sci_GetScrollWidth(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSCROLLWIDTH)
EndMacro

Macro Sci_SetScrollWidthTracking(Gadget, tracking)
  ScintillaSendMessage((Gadget), #SCI_SETSCROLLWIDTHTRACKING, (tracking))
EndMacro

Macro Sci_GetScrollWidthTracking(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSCROLLWIDTHTRACKING)
EndMacro

Macro Sci_SetEndAtLastLine(Gadget, endAtLastLine)
  ScintillaSendMessage((Gadget), #SCI_SETENDATLASTLINE, (endAtLastLine))
EndMacro

Macro Sci_GetEndAtLastLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETENDATLASTLINE)
EndMacro

;-
;-
;- White space
;-

Macro Sci_SetViewWS(Gadget, wsMode)
  ScintillaSendMessage((Gadget), #SCI_SETVIEWWS, (wsMode))
EndMacro

Macro Sci_GetViewWS(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETVIEWWS)
EndMacro

Macro Sci_SetWhitespaceFore(Gadget, useWhitespaceForeColour, colour)
  ScintillaSendMessage((Gadget), #SCI_SETWHITESPACEFORE, (useWhitespaceForeColour), (colour))
EndMacro

Macro Sci_SetWhitespaceBack(Gadget, useWhitespaceBackColour, colour)
  ScintillaSendMessage((Gadget), #SCI_SETWHITESPACEBACK, (useWhitespaceBackColour), (colour))
EndMacro

Macro Sci_SetWhitespaceSize(Gadget, size)
  ScintillaSendMessage((Gadget), #SCI_SETWHITESPACESIZE, (size))
EndMacro

Macro Sci_GetWhitespaceSize(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWHITESPACESIZE)
EndMacro

Macro Sci_SetExtraAscent(Gadget, extraAscent)
  ScintillaSendMessage((Gadget), #SCI_SETEXTRAASCENT, (extraAscent))
EndMacro

Macro Sci_GetExtraAscent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEXTRAASCENT)
EndMacro

Macro Sci_SetExtraDescent(Gadget, extraDescent)
  ScintillaSendMessage((Gadget), #SCI_SETEXTRADESCENT, (extraDescent))
EndMacro

Macro Sci_GetExtraDescent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEXTRADESCENT)
EndMacro

;-
;-
;- Cursor
;-

Macro Sci_SetCursor(Gadget, curType)
  ScintillaSendMessage((Gadget), #SCI_SETCURSOR, (curType))
EndMacro

Macro Sci_GetCursor(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCURSOR)
EndMacro

;-
;-
;- Mouse capture
;-

Macro Sci_SetMouseDownCaptures(Gadget, captures)
  ScintillaSendMessage((Gadget), #SCI_SETMOUSEDOWNCAPTURES, (captures))
EndMacro

Macro Sci_GetMouseDownCaptures(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMOUSEDOWNCAPTURES)
EndMacro

;-
;-
;- Line endings
;-

Macro Sci_SetEOLMode(Gadget, eolMode)
  ScintillaSendMessage((Gadget), #SCI_SETEOLMODE, (eolMode))
EndMacro

Macro Sci_GetEOLMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEOLMODE)
EndMacro

Macro Sci_ConvertEOLs(Gadget, eolMode)
  ScintillaSendMessage((Gadget), #SCI_CONVERTEOLS, (eolMode))
EndMacro

Macro Sci_SetViewEOL(Gadget, visible)
  ScintillaSendMessage((Gadget), #SCI_SETVIEWEOL, (visible))
EndMacro

Macro Sci_GetViewEOL(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETVIEWEOL)
EndMacro

Macro Sci_GetLineEndTypesSupported(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLINEENDTYPESSUPPORTED)
EndMacro

Macro Sci_SetLineEndTypesAllowed(Gadget, lineEndBitSet)
  ScintillaSendMessage((Gadget), #SCI_SETLINEENDTYPESALLOWED, (lineEndBitSet))
EndMacro

Macro Sci_GetLineEndTypesAllowed(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLINEENDTYPESALLOWED)
EndMacro

Macro Sci_GetLineEndTypesActive(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLINEENDTYPESACTIVE)
EndMacro

;-
;-
;- Styling
;-

Macro Sci_GetEndStyled(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETENDSTYLED)
EndMacro

Macro Sci_StartStyling(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_STARTSTYLING, (position), 31)
EndMacro

Macro Sci_SetStyling(Gadget, length, style)
  ScintillaSendMessage((Gadget), #SCI_SETSTYLING, (length), (style))
EndMacro

Macro Sci_SetStylingEx(Gadget, length, styles)
  ScintillaSendMessage((Gadget), #SCI_SETSTYLINGEX, (length), (styles))
EndMacro

Macro Sci_SetLinestate(Gadget, line, value)
  ScintillaSendMessage((Gadget), #SCI_SETLINESTATE, (line), (value))
EndMacro

Macro Sci_GetLinestate(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINESTATE, (line))
EndMacro

Macro Sci_GetMaxLinestate(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMAXLINESTATE)
EndMacro

;-
;-
;- Style definition
;-

Macro Sci_StyleResetDefault(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STYLERESETDEFAULT)
EndMacro

Macro Sci_StyleClearAll(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STYLECLEARALL)
EndMacro

Macro Sci_StyleSetFont(Gadget, styleNumber, fontName)
  _Sci_SendStr((Gadget), #SCI_STYLESETFONT, (styleNumber), (fontName))
EndMacro

Procedure.s Sci_StyleGetFont(Gadget.i, styleNumber.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_STYLEGETFONT, styleNumber, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_STYLEGETFONT, styleNumber, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_StyleSetSize(Gadget, styleNumber, sizeInPoints)
  ScintillaSendMessage((Gadget), #SCI_STYLESETSIZE, (styleNumber), (sizeInPoints))
EndMacro

Macro Sci_StyleGetSize(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETSIZE, (styleNumber))
EndMacro

Macro Sci_StyleSetSizeFractional(Gadget, styleNumber, sizeInHundredthPoints)
  ScintillaSendMessage((Gadget), #SCI_STYLESETSIZEFRACTIONAL, (styleNumber), (sizeInHundredthPoints))
EndMacro

Macro Sci_StyleGetSizeFractional(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETSIZEFRACTIONAL, (styleNumber))
EndMacro

Macro Sci_StyleSetBold(Gadget, styleNumber, bold)
  ScintillaSendMessage((Gadget), #SCI_STYLESETBOLD, (styleNumber), (bold))
EndMacro

Macro Sci_StyleGetBold(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETBOLD, (styleNumber))
EndMacro

Macro Sci_StyleSetWeight(Gadget, styleNumber, weight)
  ScintillaSendMessage((Gadget), #SCI_STYLESETWEIGHT, (styleNumber), (weight))
EndMacro

Macro Sci_StyleGetWeight(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETWEIGHT, (styleNumber))
EndMacro

Macro Sci_StyleSetItalic(Gadget, styleNumber, italic)
  ScintillaSendMessage((Gadget), #SCI_STYLESETITALIC, (styleNumber), (italic))
EndMacro

Macro Sci_StyleGetItalic(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETITALIC, (styleNumber))
EndMacro

Macro Sci_StyleSetUnderline(Gadget, styleNumber, underline)
  ScintillaSendMessage((Gadget), #SCI_STYLESETUNDERLINE, (styleNumber), (underline))
EndMacro

Macro Sci_StyleGetUnderline(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETUNDERLINE, (styleNumber))
EndMacro

Macro Sci_StyleSetFore(Gadget, styleNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_STYLESETFORE, (styleNumber), (colour))
EndMacro

Macro Sci_StyleGetFore(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETFORE, (styleNumber))
EndMacro

Macro Sci_StyleSetBack(Gadget, styleNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_STYLESETBACK, (styleNumber), (colour))
EndMacro

Macro Sci_StyleGetBack(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETBACK, (styleNumber))
EndMacro

Macro Sci_StyleSetEOLFilled(Gadget, styleNumber, eolFilled)
  ScintillaSendMessage((Gadget), #SCI_STYLESETEOLFILLED, (styleNumber), (eolFilled))
EndMacro

Macro Sci_StyleGetEOLFilled(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETEOLFILLED, (styleNumber))
EndMacro

Macro Sci_StyleSetCharacterSet(Gadget, styleNumber, charSet)
  ScintillaSendMessage((Gadget), #SCI_STYLESETCHARACTERSET, (styleNumber), (charSet))
EndMacro

Macro Sci_StyleGetCharacterSet(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETCHARACTERSET, (styleNumber))
EndMacro

Macro Sci_StyleSetCase(Gadget, styleNumber, caseMode)
  ScintillaSendMessage((Gadget), #SCI_STYLESETCASE, (styleNumber), (caseMode))
EndMacro

Macro Sci_StyleGetCase(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETCASE, (styleNumber))
EndMacro

Macro Sci_StyleSetVisible(Gadget, styleNumber, visible)
  ScintillaSendMessage((Gadget), #SCI_STYLESETVISIBLE, (styleNumber), (visible))
EndMacro

Macro Sci_StyleGetVisible(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETVISIBLE, (styleNumber))
EndMacro

Macro Sci_StyleSetChangeable(Gadget, styleNumber, changeable)
  ScintillaSendMessage((Gadget), #SCI_STYLESETCHANGEABLE, (styleNumber), (changeable))
EndMacro

Macro Sci_StyleGetChangeable(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETCHANGEABLE, (styleNumber))
EndMacro

Macro Sci_StyleSetHotspot(Gadget, styleNumber, hotspot)
  ScintillaSendMessage((Gadget), #SCI_STYLESETHOTSPOT, (styleNumber), (hotspot))
EndMacro

Macro Sci_StyleGetHotspot(Gadget, styleNumber)
  ScintillaSendMessage((Gadget), #SCI_STYLEGETHOTSPOT, (styleNumber))
EndMacro

;-
;-
;- Caret, selection, and hotspot styles
;-

Macro Sci_SetSelFore(Gadget, useSelectionForeColour, colour)
  ScintillaSendMessage((Gadget), #SCI_SETSELFORE, (useSelectionForeColour), (colour))
EndMacro

Macro Sci_SetSelBack(Gadget, useSelectionBackColour, colour)
  ScintillaSendMessage((Gadget), #SCI_SETSELBACK, (useSelectionBackColour), (colour))
EndMacro

Macro Sci_SetSelAlpha(Gadget, alpha)
  ScintillaSendMessage((Gadget), #SCI_SETSELALPHA, (alpha))
EndMacro

Macro Sci_GetSelAlpha(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELALPHA)
EndMacro

Macro Sci_SetSelEOLFilled(Gadget, filled)
  ScintillaSendMessage((Gadget), #SCI_SETSELEOLFILLED, (filled))
EndMacro

Macro Sci_GetSelEOLFilled(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETSELEOLFILLED)
EndMacro

Macro Sci_SetCaretFore(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETCARETFORE, (colour))
EndMacro

Macro Sci_GetCaretFore(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETFORE)
EndMacro

Macro Sci_SetCaretLineVisible(Gadget, show)
  ScintillaSendMessage((Gadget), #SCI_SETCARETLINEVISIBLE, (show))
EndMacro

Macro Sci_GetCaretLineVisible(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETLINEVISIBLE)
EndMacro

Macro Sci_SetCaretLineBack(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETCARETLINEBACK, (colour))
EndMacro

Macro Sci_GetCaretLineBack(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETLINEBACK)
EndMacro

Macro Sci_SetCaretLineBackAlpha(Gadget, alpha)
  ScintillaSendMessage((Gadget), #SCI_SETCARETLINEBACKALPHA, (alpha))
EndMacro

Macro Sci_GetCaretLineBackAlpha(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETLINEBACKALPHA)
EndMacro

Macro Sci_SetCaretLineVisibleAlways(Gadget, alwaysVisible)
  ScintillaSendMessage((Gadget), #SCI_SETCARETLINEVISIBLEALWAYS, (alwaysVisible))
EndMacro

Macro Sci_GetCaretLineVisibleAlways(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETLINEVISIBLEALWAYS)
EndMacro

Macro Sci_SetCaretPeriod(Gadget, milliseconds)
  ScintillaSendMessage((Gadget), #SCI_SETCARETPERIOD, (milliseconds))
EndMacro

Macro Sci_GetCaretPeriod(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETPERIOD)
EndMacro

Macro Sci_SetCaretStyle(Gadget, style)
  ScintillaSendMessage((Gadget), #SCI_SETCARETSTYLE, (style))
EndMacro

Macro Sci_GetCaretStyle(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETSTYLE)
EndMacro

Macro Sci_SetCaretWidth(Gadget, pixels)
  ScintillaSendMessage((Gadget), #SCI_SETCARETWIDTH, (pixels))
EndMacro

Macro Sci_GetCaretWidth(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETWIDTH)
EndMacro

Macro Sci_SetHotspotActiveFore(Gadget, useSetting, colour)
  ScintillaSendMessage((Gadget), #SCI_SETHOTSPOTACTIVEFORE, (useSetting), (colour))
EndMacro

Macro Sci_GetHotspotActiveFore(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHOTSPOTACTIVEFORE)
EndMacro

Macro Sci_SetHotspotActiveBack(Gadget, useSetting, colour)
  ScintillaSendMessage((Gadget), #SCI_SETHOTSPOTACTIVEBACK, (useSetting), (colour))
EndMacro

Macro Sci_GetHotspotActiveBack(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHOTSPOTACTIVEBACK)
EndMacro

Macro Sci_SetHotspotActiveUnderline(Gadget, underline)
  ScintillaSendMessage((Gadget), #SCI_SETHOTSPOTACTIVEUNDERLINE, (underline))
EndMacro

Macro Sci_GetHotspotActiveUnderline(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHOTSPOTACTIVEUNDERLINE)
EndMacro

Macro Sci_SetHotspotSingleLine(Gadget, singleLine)
  ScintillaSendMessage((Gadget), #SCI_SETHOTSPOTSINGLELINE, (singleLine))
EndMacro

Macro Sci_GetHotspotSingleLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHOTSPOTSINGLELINE)
EndMacro

Macro Sci_SetCaretSticky(Gadget, useCaretStickyBehaviour)
  ScintillaSendMessage((Gadget), #SCI_SETCARETSTICKY, (useCaretStickyBehaviour))
EndMacro

Macro Sci_GetCaretSticky(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCARETSTICKY)
EndMacro

Macro Sci_ToggleCaretSticky(Gadget)
  ScintillaSendMessage((Gadget), #SCI_TOGGLECARETSTICKY)
EndMacro

;-
;-
;- Character representations
;-

Macro Sci_SetRepresentation(Gadget, encodedCharacter, representation)
  _Sci_SendStr2((Gadget), #SCI_SETREPRESENTATION, (encodedCharacter), (representation))
EndMacro

Procedure.s Sci_GetRepresentation(Gadget, encodedCharacter.s)
  Protected nLenPlus1.i = _Sci_SendStrFirst(Gadget, #SCI_GETREPRESENTATION, encodedCharacter, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  _Sci_SendStrFirst(Gadget, #SCI_GETREPRESENTATION, encodedCharacter, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_ClearRepresentation(Gadget, encodedCharacter)
  _Sci_SendStrFirst((Gadget), #SCI_CLEARREPRESENTATION, (encodedCharacter), #Null)
EndMacro

Macro Sci_SetControlCharsymbol(Gadget, symbol)
  ScintillaSendMessage((Gadget), #SCI_SETCONTROLCHARSYMBOL, (symbol))
EndMacro

Macro Sci_GetControlCharsymbol(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCONTROLCHARSYMBOL)
EndMacro

;-
;-
;- Margins
;-

Macro Sci_SetMarginTypeN(Gadget, margin, type)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINTYPEN, (margin), (type))
EndMacro

Macro Sci_GetMarginTypeN(Gadget, margin)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINTYPEN, (margin))
EndMacro

Macro Sci_SetMarginWidthN(Gadget, margin, pixelWidth)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINWIDTHN, (margin), (pixelWidth))
EndMacro

Macro Sci_GetMarginWidthN(Gadget, margin)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINWIDTHN, (margin))
EndMacro

Macro Sci_SetMarginMaskN(Gadget, margin, mask)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINMASKN, (margin), (mask))
EndMacro

Macro Sci_GetMarginMaskN(Gadget, margin)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINMASKN, (margin))
EndMacro

Macro Sci_SetMarginSensitiveN(Gadget, margin, sensitive)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINSENSITIVEN, (margin), (sensitive))
EndMacro

Macro Sci_GetMarginSensitiveN(Gadget, margin)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINSENSITIVEN, (margin))
EndMacro

Macro Sci_SetMarginCursorN(Gadget, margin, cursor)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINCURSORN, (margin), (cursor))
EndMacro

Macro Sci_GetMarginCursorN(Gadget, margin)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINCURSORN, (margin))
EndMacro

Macro Sci_SetMarginLeft(Gadget, pixels)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINLEFT, #Null, (pixels))
EndMacro

Macro Sci_GetMarginLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINLEFT)
EndMacro

Macro Sci_SetMarginRight(Gadget, pixels)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINRIGHT, #Null, (pixels))
EndMacro

Macro Sci_GetMarginRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINRIGHT)
EndMacro

Macro Sci_SetFoldMarginColour(Gadget, useSetting, colour)
  ScintillaSendMessage((Gadget), #SCI_SETFOLDMARGINCOLOUR, (useSetting), (colour))
EndMacro

Macro Sci_SetFoldMarginHiColour(Gadget, useSetting, colour)
  ScintillaSendMessage((Gadget), #SCI_SETFOLDMARGINHICOLOUR, (useSetting), (colour))
EndMacro

;- ----- Sci_MarginSetText (int line, char* text) [Int, StrOut]

;- ----- Sci_MarginGetText (int line, char* text) [Int, StrOut]

Macro Sci_MarginSetStyle(Gadget, line, style)
  ScintillaSendMessage((Gadget), #SCI_MARGINSETSTYLE, (line), (style))
EndMacro

Macro Sci_MarginGetStyle(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_MARGINGETSTYLE, (line))
EndMacro

;- ----- Sci_MarginSetStyles (int line, char* styles) [Int, StrOut]

;- ----- Sci_MarginGetStyles (int line, char* styles) [Int, StrOut]

Macro Sci_MarginTextClearAll(Gadget)
  ScintillaSendMessage((Gadget), #SCI_MARGINTEXTCLEARALL)
EndMacro

Macro Sci_MarginSetStyleOffset(Gadget, style)
  ScintillaSendMessage((Gadget), #SCI_MARGINSETSTYLEOFFSET, (style))
EndMacro

Macro Sci_MarginGetStyleOffset(Gadget)
  ScintillaSendMessage((Gadget), #SCI_MARGINGETSTYLEOFFSET)
EndMacro

Macro Sci_SetMarginOptions(Gadget, marginOptions)
  ScintillaSendMessage((Gadget), #SCI_SETMARGINOPTIONS, (marginOptions))
EndMacro

Macro Sci_GetMarginOptions(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMARGINOPTIONS)
EndMacro

;-
;-
;- Annotations
;-

;- ----- Sci_AnnotationSetText (int line, char* text) [Int, StrOut]

;- ----- Sci_AnnotationGetText (int line, char* text) [Int, StrOut]

Macro Sci_AnnotationSetStyle(Gadget, line, style)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONSETSTYLE, (line), (style))
EndMacro

Macro Sci_AnnotationGetStyle(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONGETSTYLE, (line))
EndMacro

;- ----- Sci_AnnotationSetStyles (int line, char* styles) [Int, StrOut]

;- ----- Sci_AnnotationGetStyles (int line, char* styles) [Int, StrOut]

Macro Sci_AnnotationGetLines(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONGETLINES, (line))
EndMacro

Macro Sci_AnnotationClearAll(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONCLEARALL)
EndMacro

Macro Sci_AnnotationSetVisible(Gadget, visible)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONSETVISIBLE, (visible))
EndMacro

Macro Sci_AnnotationGetVisible(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONGETVISIBLE)
EndMacro

Macro Sci_AnnotationSetStyleOffset(Gadget, style)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONSETSTYLEOFFSET, (style))
EndMacro

Macro Sci_AnnotationGetStyleOffset(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ANNOTATIONGETSTYLEOFFSET)
EndMacro

;-
;-
;- Other settings
;-

Macro Sci_SetBufferedDraw(Gadget, isBuffered)
  ScintillaSendMessage((Gadget), #SCI_SETBUFFEREDDRAW, (isBuffered))
EndMacro

Macro Sci_GetBufferedDraw(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETBUFFEREDDRAW)
EndMacro

Macro Sci_SetPhasesDraw(Gadget, phases)
  ScintillaSendMessage((Gadget), #SCI_SETPHASESDRAW, (phases))
EndMacro

Macro Sci_GetPhasesDraw(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPHASESDRAW)
EndMacro

Macro Sci_SetTwoPhaseDraw(Gadget, twoPhase)
  ScintillaSendMessage((Gadget), #SCI_SETTWOPHASEDRAW, (twoPhase))
EndMacro

Macro Sci_GetTwoPhaseDraw(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTWOPHASEDRAW)
EndMacro

Macro Sci_SetTechnology(Gadget, technology)
  ScintillaSendMessage((Gadget), #SCI_SETTECHNOLOGY, (technology))
EndMacro

Macro Sci_GetTechnology(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTECHNOLOGY)
EndMacro

Macro Sci_SetFontQuality(Gadget, fontQuality)
  ScintillaSendMessage((Gadget), #SCI_SETFONTQUALITY, (fontQuality))
EndMacro

Macro Sci_GetFontQuality(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETFONTQUALITY)
EndMacro

Macro Sci_SetCodePage(Gadget, codePage)
  ScintillaSendMessage((Gadget), #SCI_SETCODEPAGE, (codePage))
EndMacro

Macro Sci_GetCodePage(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCODEPAGE)
EndMacro

Macro Sci_SetimeInteraction(Gadget, imeInteraction)
  ScintillaSendMessage((Gadget), #SCI_SETIMEINTERACTION, (imeInteraction))
EndMacro

Macro Sci_GetimeInteraction(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETIMEINTERACTION)
EndMacro

Macro Sci_SetKeysUnicode(Gadget, keysUnicode)
  ScintillaSendMessage((Gadget), #SCI_SETKEYSUNICODE, (keysUnicode))
EndMacro

Macro Sci_GetKeysUnicode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETKEYSUNICODE)
EndMacro

Macro Sci_SetWordChars(Gadget, characters)
  _Sci_SendStrAscii((Gadget), #SCI_SETWORDCHARS, 0, (characters))
EndMacro

Procedure.s Sci_GetWordChars(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETWORDCHARS, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETWORDCHARS, 0, @Buffer)
  ProcedureReturn (PeekS(@Buffer, -1, #PB_Ascii))
EndProcedure

Macro Sci_SetWhitespaceChars(Gadget, characters)
  _Sci_SendStrAscii((Gadget), #SCI_SETWHITESPACECHARS, 0, (characters))
EndMacro

Procedure.s Sci_GetWhitespaceChars(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETWHITESPACECHARS, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETWHITESPACECHARS, 0, @Buffer)
  ProcedureReturn (PeekS(@Buffer, -1, #PB_Ascii))
EndProcedure

Macro Sci_SetPunctuationChars(Gadget, characters)
  _Sci_SendStrAscii((Gadget), #SCI_SETPUNCTUATIONCHARS, 0, (characters))
EndMacro

Procedure.s Sci_GetPunctuationChars(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_GETPUNCTUATIONCHARS, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_GETPUNCTUATIONCHARS, 0, @Buffer)
  ProcedureReturn (PeekS(@Buffer, -1, #PB_Ascii))
EndProcedure

Macro Sci_SetCharsDefault(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SETCHARSDEFAULT)
EndMacro

Macro Sci_GrabFocus(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GRABFOCUS)
EndMacro

Macro Sci_SetFocus(Gadget, focus)
  ScintillaSendMessage((Gadget), #SCI_SETFOCUS, (focus))
EndMacro

Macro Sci_GetFocus(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETFOCUS)
EndMacro

;-
;-
;- Brace highlighting
;-

Macro Sci_BraceHighlight(Gadget, pos1, pos2)
  ScintillaSendMessage((Gadget), #SCI_BRACEHIGHLIGHT, (pos1), (pos2))
EndMacro

Macro Sci_BraceBadLight(Gadget, pos1)
  ScintillaSendMessage((Gadget), #SCI_BRACEBADLIGHT, (pos1))
EndMacro

Macro Sci_BraceHighlightIndicator(Gadget, useBraceHighlightIndicator, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_BRACEHIGHLIGHTINDICATOR, (useBraceHighlightIndicator), (indicatorNumber))
EndMacro

Macro Sci_BraceBadLightIndicator(Gadget, useBraceBadLightIndicator, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_BRACEBADLIGHTINDICATOR, (useBraceBadLightIndicator), (indicatorNumber))
EndMacro

Macro Sci_BraceMatch(Gadget, position, maxReStyle)
  ScintillaSendMessage((Gadget), #SCI_BRACEMATCH, (position), (maxReStyle))
EndMacro

;-
;-
;- Tabs and Indentation Guides
;-

Macro Sci_SetTabWidth(Gadget, widthInChars)
  ScintillaSendMessage((Gadget), #SCI_SETTABWIDTH, (widthInChars))
EndMacro

Macro Sci_GetTabWidth(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTABWIDTH)
EndMacro

Macro Sci_ClearTabstops(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_CLEARTABSTOPS, (line))
EndMacro

Macro Sci_AddTabstop(Gadget, line, x)
  ScintillaSendMessage((Gadget), #SCI_ADDTABSTOP, (line), (x))
EndMacro

Macro Sci_GetNextTabstop(Gadget, line, x)
  ScintillaSendMessage((Gadget), #SCI_GETNEXTTABSTOP, (line), (x))
EndMacro

Macro Sci_SetUseTabs(Gadget, useTabs)
  ScintillaSendMessage((Gadget), #SCI_SETUSETABS, (useTabs))
EndMacro

Macro Sci_GetUseTabs(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETUSETABS)
EndMacro

Macro Sci_SetIndent(Gadget, widthInChars)
  ScintillaSendMessage((Gadget), #SCI_SETINDENT, (widthInChars))
EndMacro

Macro Sci_GetIndent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETINDENT)
EndMacro

Macro Sci_SetTabIndents(Gadget, tabIndents)
  ScintillaSendMessage((Gadget), #SCI_SETTABINDENTS, (tabIndents))
EndMacro

Macro Sci_GetTabIndents(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETTABINDENTS)
EndMacro

Macro Sci_SetBackSpaceUnindents(Gadget, bsUnIndents)
  ScintillaSendMessage((Gadget), #SCI_SETBACKSPACEUNINDENTS, (bsUnIndents))
EndMacro

Macro Sci_GetBackSpaceUnindents(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETBACKSPACEUNINDENTS)
EndMacro

Macro Sci_SetLineIndentation(Gadget, line, indentation)
  ScintillaSendMessage((Gadget), #SCI_SETLINEINDENTATION, (line), (indentation))
EndMacro

Macro Sci_GetLineIndentation(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINEINDENTATION, (line))
EndMacro

Macro Sci_GetLineIndentPosition(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINEINDENTPOSITION, (line))
EndMacro

Macro Sci_SetIndentationGuides(Gadget, indentView)
  ScintillaSendMessage((Gadget), #SCI_SETINDENTATIONGUIDES, (indentView))
EndMacro

Macro Sci_GetIndentationGuides(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETINDENTATIONGUIDES)
EndMacro

Macro Sci_SetHighlightGuide(Gadget, column)
  ScintillaSendMessage((Gadget), #SCI_SETHIGHLIGHTGUIDE, (column))
EndMacro

Macro Sci_GetHighlightGuide(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETHIGHLIGHTGUIDE)
EndMacro

;-
;-
;- Markers
;-

Macro Sci_MarkerDefine(Gadget, markerNumber, markerSymbols)
  ScintillaSendMessage((Gadget), #SCI_MARKERDEFINE, (markerNumber), (markerSymbols))
EndMacro

Macro Sci_MarkerDefinePixMap(Gadget, markerNumber, xpm)
  ScintillaSendMessage((Gadget), #SCI_MARKERDEFINEPIXMAP, (markerNumber), (xpm))
EndMacro

Macro Sci_RGBAImageSetWidth(Gadget, width)
  ScintillaSendMessage((Gadget), #SCI_RGBAIMAGESETWIDTH, (width))
EndMacro

Macro Sci_RGBAImageSetHeight(Gadget, height)
  ScintillaSendMessage((Gadget), #SCI_RGBAIMAGESETHEIGHT, (height))
EndMacro

Macro Sci_RGBAImageSetScale(Gadget, scalePercent)
  ScintillaSendMessage((Gadget), #SCI_RGBAIMAGESETSCALE, (scalePercent))
EndMacro

Macro Sci_MarkerDefineRGBAImage(Gadget, markerNumber, pixels)
  ScintillaSendMessage((Gadget), #SCI_MARKERDEFINERGBAIMAGE, (markerNumber), (pixels))
EndMacro

Macro Sci_MarkerSymbolDefined(Gadget, markerNumber)
  ScintillaSendMessage((Gadget), #SCI_MARKERSYMBOLDEFINED, (markerNumber))
EndMacro

Macro Sci_MarkerSetFore(Gadget, markerNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_MARKERSETFORE, (markerNumber), (colour))
EndMacro

Macro Sci_MarkerSetBack(Gadget, markerNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_MARKERSETBACK, (markerNumber), (colour))
EndMacro

Macro Sci_MarkerSetBackSelected(Gadget, markerNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_MARKERSETBACKSELECTED, (markerNumber), (colour))
EndMacro

Macro Sci_MarkerEnableHighlight(Gadget, enabled)
  ScintillaSendMessage((Gadget), #SCI_MARKERENABLEHIGHLIGHT, (enabled))
EndMacro

Macro Sci_MarkerSetAlpha(Gadget, markerNumber, alpha)
  ScintillaSendMessage((Gadget), #SCI_MARKERSETALPHA, (markerNumber), (alpha))
EndMacro

Macro Sci_MarkerAdd(Gadget, line, markerNumber)
  ScintillaSendMessage((Gadget), #SCI_MARKERADD, (line), (markerNumber))
EndMacro

Macro Sci_MarkerAddSet(Gadget, line, markerMask)
  ScintillaSendMessage((Gadget), #SCI_MARKERADDSET, (line), (markerMask))
EndMacro

Macro Sci_MarkerDelete(Gadget, line, markerNumber)
  ScintillaSendMessage((Gadget), #SCI_MARKERDELETE, (line), (markerNumber))
EndMacro

Macro Sci_MarkerDeleteAll(Gadget, markerNumber)
  ScintillaSendMessage((Gadget), #SCI_MARKERDELETEALL, (markerNumber))
EndMacro

Macro Sci_MarkerGet(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_MARKERGET, (line))
EndMacro

Macro Sci_MarkerNext(Gadget, lineStart, markerMask)
  ScintillaSendMessage((Gadget), #SCI_MARKERNEXT, (lineStart), (markerMask))
EndMacro

Macro Sci_MarkerPrevious(Gadget, lineStart, markerMask)
  ScintillaSendMessage((Gadget), #SCI_MARKERPREVIOUS, (lineStart), (markerMask))
EndMacro

Macro Sci_MarkerLineFromHandle(Gadget, handle)
  ScintillaSendMessage((Gadget), #SCI_MARKERLINEFROMHANDLE, (handle))
EndMacro

Macro Sci_MarkerDeleteHandle(Gadget, handle)
  ScintillaSendMessage((Gadget), #SCI_MARKERDELETEHANDLE, (handle))
EndMacro

;-
;-
;- Indicators
;-

Macro Sci_IndicSetStyle(Gadget, indicatorNumber, indicatorStyle)
  ScintillaSendMessage((Gadget), #SCI_INDICSETSTYLE, (indicatorNumber), (indicatorStyle))
EndMacro

Macro Sci_IndicGetStyle(Gadget, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_INDICGETSTYLE, (indicatorNumber))
EndMacro

Macro Sci_IndicSetFore(Gadget, indicatorNumber, colour)
  ScintillaSendMessage((Gadget), #SCI_INDICSETFORE, (indicatorNumber), (colour))
EndMacro

Macro Sci_IndicGetFore(Gadget, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_INDICGETFORE, (indicatorNumber))
EndMacro

Macro Sci_IndicSetAlpha(Gadget, indicatorNumber, alpha)
  ScintillaSendMessage((Gadget), #SCI_INDICSETALPHA, (indicatorNumber), (alpha))
EndMacro

Macro Sci_IndicGetAlpha(Gadget, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_INDICGETALPHA, (indicatorNumber))
EndMacro

Macro Sci_IndicSetOutLineAlpha(Gadget, indicatorNumber, alpha)
  ScintillaSendMessage((Gadget), #SCI_INDICSETOUTLINEALPHA, (indicatorNumber), (alpha))
EndMacro

Macro Sci_IndicGetOutLineAlpha(Gadget, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_INDICGETOUTLINEALPHA, (indicatorNumber))
EndMacro

Macro Sci_IndicSetUnder(Gadget, indicatorNumber, under)
  ScintillaSendMessage((Gadget), #SCI_INDICSETUNDER, (indicatorNumber), (under))
EndMacro

Macro Sci_IndicGetUnder(Gadget, indicatorNumber)
  ScintillaSendMessage((Gadget), #SCI_INDICGETUNDER, (indicatorNumber))
EndMacro

Macro Sci_SetIndicatorCurrent(Gadget, indicator)
  ScintillaSendMessage((Gadget), #SCI_SETINDICATORCURRENT, (indicator))
EndMacro

Macro Sci_GetIndicatorCurrent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETINDICATORCURRENT)
EndMacro

Macro Sci_SetIndicatorValue(Gadget, value)
  ScintillaSendMessage((Gadget), #SCI_SETINDICATORVALUE, (value))
EndMacro

Macro Sci_GetIndicatorValue(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETINDICATORVALUE)
EndMacro

Macro Sci_IndicatorFillRange(Gadget, position, fillLength)
  ScintillaSendMessage((Gadget), #SCI_INDICATORFILLRANGE, (position), (fillLength))
EndMacro

Macro Sci_IndicatorClearRange(Gadget, position, clearLength)
  ScintillaSendMessage((Gadget), #SCI_INDICATORCLEARRANGE, (position), (clearLength))
EndMacro

Macro Sci_IndicatorAllOnFor(Gadget, position)
  ScintillaSendMessage((Gadget), #SCI_INDICATORALLONFOR, (position))
EndMacro

Macro Sci_IndicatorValueAt(Gadget, indicator, position)
  ScintillaSendMessage((Gadget), #SCI_INDICATORVALUEAT, (indicator), (position))
EndMacro

Macro Sci_Indicatorstart(Gadget, indicator, position)
  ScintillaSendMessage((Gadget), #SCI_INDICATORSTART, (indicator), (position))
EndMacro

Macro Sci_IndicatorEnd(Gadget, indicator, position)
  ScintillaSendMessage((Gadget), #SCI_INDICATOREND, (indicator), (position))
EndMacro

Macro Sci_FindIndicatorsHow(Gadget, start, endPos)
  ScintillaSendMessage((Gadget), #SCI_FINDINDICATORSHOW, (start), (endPos))
EndMacro

Macro Sci_FindIndicatorFlash(Gadget, start, endPos)
  ScintillaSendMessage((Gadget), #SCI_FINDINDICATORFLASH, (start), (endPos))
EndMacro

Macro Sci_FindIndicatorHide(Gadget)
  ScintillaSendMessage((Gadget), #SCI_FINDINDICATORHIDE)
EndMacro

;-
;-
;- Autocompletion
;-

Macro Sci_AutoCShow(Gadget, lenEntered, listText)
  _Sci_SendStr((Gadget), #SCI_AUTOCSHOW, (lenEntered), (listText))
EndMacro

Macro Sci_AutoCCancel(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCCANCEL)
EndMacro

Macro Sci_AutoCActive(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCACTIVE)
EndMacro

Macro Sci_AutoCPosStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCPOSSTART)
EndMacro

Macro Sci_AutoCComplete(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCCOMPLETE)
EndMacro

Macro Sci_AutoCStops(Gadget, chars)
  _Sci_SendStr((Gadget), #SCI_AUTOCSTOPS, #Null, (chars))
EndMacro

Macro Sci_AutoCSetSeparator(Gadget, separator)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETSEPARATOR, (separator))
EndMacro

Macro Sci_AutoCGetSeparator(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETSEPARATOR)
EndMacro

Macro Sci_AutoCSelect(Gadget, selectText)
  _Sci_SendStr((Gadget), #SCI_AUTOCSELECT, #Null, (selectText))
EndMacro

Macro Sci_AutoCGetCurrent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETCURRENT)
EndMacro

Procedure.s Sci_AutoCGetCurrentText(Gadget.i)
  Protected nLenPlus1.i = ScintillaSendMessage(Gadget, #SCI_AUTOCGETCURRENTTEXT, 0, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  ScintillaSendMessage(Gadget, #SCI_AUTOCGETCURRENTTEXT, 0, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

Macro Sci_AutoCSetCancelAtStart(Gadget, cancel)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETCANCELATSTART, (cancel))
EndMacro

Macro Sci_AutoCGetCancelAtStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETCANCELATSTART)
EndMacro

Macro Sci_AutoCSetFillups(Gadget, chars)
  _Sci_SendStr((Gadget), #SCI_AUTOCSETFILLUPS, #Null, (chars))
EndMacro

Macro Sci_AutoCSetChooseSingle(Gadget, chooseSingle)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETCHOOSESINGLE, (chooseSingle))
EndMacro

Macro Sci_AutoCGetChooseSingle(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETCHOOSESINGLE)
EndMacro

Macro Sci_AutoCSetIgnoreCase(Gadget, ignoreCase)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETIGNORECASE, (ignoreCase))
EndMacro

Macro Sci_AutoCGetIgnoreCase(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETIGNORECASE)
EndMacro

Macro Sci_AutoCSetCaseInsensitiveBehaviour(Gadget, behaviour)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR, (behaviour))
EndMacro

Macro Sci_AutoCGetCaseInsensitiveBehaviour(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR)
EndMacro

Macro Sci_AutoCSetMulti(Gadget, multi)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETMULTI, (multi))
EndMacro

Macro Sci_AutoCGetMulti(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETMULTI)
EndMacro

Macro Sci_AutoCSetOrder(Gadget, order)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETORDER, (order))
EndMacro

Macro Sci_AutoCGetOrder(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETORDER)
EndMacro

Macro Sci_AutoCSetAutoHide(Gadget, autoHide)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETAUTOHIDE, (autoHide))
EndMacro

Macro Sci_AutoCGetAutoHide(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETAUTOHIDE)
EndMacro

Macro Sci_AutoCSetDropRestOfWord(Gadget, dropRestOfWord)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETDROPRESTOFWORD, (dropRestOfWord))
EndMacro

Macro Sci_AutoCGetDropRestOfWord(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETDROPRESTOFWORD)
EndMacro

Macro Sci_RegisterImage(Gadget, type, xpmData)
  ScintillaSendMessage((Gadget), #SCI_REGISTERIMAGE, (type), (xpmData))
EndMacro

Macro Sci_RegisterRGBAImage(Gadget, type, pixels)
  ScintillaSendMessage((Gadget), #SCI_REGISTERRGBAIMAGE, (type), (pixels))
EndMacro

Macro Sci_ClearRegisteredImages(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEARREGISTEREDIMAGES)
EndMacro

Macro Sci_AutoCSetTypeseparator(Gadget, separatorCharacter)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETTYPESEPARATOR, (separatorCharacter))
EndMacro

Macro Sci_AutoCGetTypeseparator(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETTYPESEPARATOR)
EndMacro

Macro Sci_AutoCSetMaxHeight(Gadget, rowCount)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETMAXHEIGHT, (rowCount))
EndMacro

Macro Sci_AutoCGetMaxHeight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETMAXHEIGHT)
EndMacro

Macro Sci_AutoCSetMaxWidth(Gadget, characterCount)
  ScintillaSendMessage((Gadget), #SCI_AUTOCSETMAXWIDTH, (characterCount))
EndMacro

Macro Sci_AutoCGetMaxWidth(Gadget)
  ScintillaSendMessage((Gadget), #SCI_AUTOCGETMAXWIDTH)
EndMacro

;-
;-
;- User lists
;-

Macro Sci_UserlistShow(Gadget, listType, listText)
  _Sci_SendStr((Gadget), #SCI_USERLISTSHOW, (listType), (listText))
EndMacro

;-
;-
;- Call tips
;-

Macro Sci_CalltipShow(Gadget, posStart, definition)
  _Sci_SendStr((Gadget), #SCI_CALLTIPSHOW, (posStart), (definition))
EndMacro

Macro Sci_CalltipCancel(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPCANCEL)
EndMacro

Macro Sci_CalltipActive(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPACTIVE)
EndMacro

Macro Sci_CalltipPosStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPPOSSTART)
EndMacro

Macro Sci_CalltipSetPosStart(Gadget, posStart)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETPOSSTART, (posStart))
EndMacro

Macro Sci_CalltipSetHlt(Gadget, highlightStart, highlightEnd)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETHLT, (highlightStart), (highlightEnd))
EndMacro

Macro Sci_CalltipSetBack(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETBACK, (colour))
EndMacro

Macro Sci_CalltipSetFore(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETFORE, (colour))
EndMacro

Macro Sci_CalltipSetForeHlt(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETFOREHLT, (colour))
EndMacro

Macro Sci_CalltipUseStyle(Gadget, tabsize)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPUSESTYLE, (tabsize))
EndMacro

Macro Sci_CalltipSetPosition(Gadget, above)
  ScintillaSendMessage((Gadget), #SCI_CALLTIPSETPOSITION, (above))
EndMacro

;-
;-
;- Keyboard commands
;-

Macro Sci_LineDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEDOWN)
EndMacro

Macro Sci_LineDownExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEDOWNEXTEND)
EndMacro

Macro Sci_LineDownRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEDOWNRECTEXTEND)
EndMacro

Macro Sci_LinescrollDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINESCROLLDOWN)
EndMacro

Macro Sci_LineUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEUP)
EndMacro

Macro Sci_LineUpExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEUPEXTEND)
EndMacro

Macro Sci_LineUpRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEUPRECTEXTEND)
EndMacro

Macro Sci_LinescrollUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINESCROLLUP)
EndMacro

Macro Sci_ParaDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PARADOWN)
EndMacro

Macro Sci_ParaDownExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PARADOWNEXTEND)
EndMacro

Macro Sci_ParaUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PARAUP)
EndMacro

Macro Sci_ParaUpExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PARAUPEXTEND)
EndMacro

Macro Sci_CharLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARLEFT)
EndMacro

Macro Sci_CharLeftExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARLEFTEXTEND)
EndMacro

Macro Sci_CharLeftRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARLEFTRECTEXTEND)
EndMacro

Macro Sci_CharRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARRIGHT)
EndMacro

Macro Sci_CharRightExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARRIGHTEXTEND)
EndMacro

Macro Sci_CharRightRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CHARRIGHTRECTEXTEND)
EndMacro

Macro Sci_WordLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDLEFT)
EndMacro

Macro Sci_WordLeftExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDLEFTEXTEND)
EndMacro

Macro Sci_WordRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDRIGHT)
EndMacro

Macro Sci_WordRightExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDRIGHTEXTEND)
EndMacro

Macro Sci_WordLeftEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDLEFTEND)
EndMacro

Macro Sci_WordLeftEndExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDLEFTENDEXTEND)
EndMacro

Macro Sci_WordRightEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDRIGHTEND)
EndMacro

Macro Sci_WordRightEndExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDRIGHTENDEXTEND)
EndMacro

Macro Sci_WordPartLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDPARTLEFT)
EndMacro

Macro Sci_WordPartLeftExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDPARTLEFTEXTEND)
EndMacro

Macro Sci_WordPartRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDPARTRIGHT)
EndMacro

Macro Sci_WordPartRightExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_WORDPARTRIGHTEXTEND)
EndMacro

Macro Sci_Home(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOME)
EndMacro

Macro Sci_HomeExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMEEXTEND)
EndMacro

Macro Sci_HomeRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMERECTEXTEND)
EndMacro

Macro Sci_HomeDisplay(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMEDISPLAY)
EndMacro

Macro Sci_HomeDisplayExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMEDISPLAYEXTEND)
EndMacro

Macro Sci_HomeWrap(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMEWRAP)
EndMacro

Macro Sci_HomeWrapExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_HOMEWRAPEXTEND)
EndMacro

Macro Sci_VCHome(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOME)
EndMacro

Macro Sci_VCHomeExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMEEXTEND)
EndMacro

Macro Sci_VCHomeRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMERECTEXTEND)
EndMacro

Macro Sci_VCHomeWrap(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMEWRAP)
EndMacro

Macro Sci_VCHomeWrapExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMEWRAPEXTEND)
EndMacro

Macro Sci_VCHomeDisplay(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMEDISPLAY)
EndMacro

Macro Sci_VCHomeDisplayExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VCHOMEDISPLAYEXTEND)
EndMacro

Macro Sci_LineEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEEND)
EndMacro

Macro Sci_LineEndExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDEXTEND)
EndMacro

Macro Sci_LineEndRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDRECTEXTEND)
EndMacro

Macro Sci_LineEndDisplay(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDDISPLAY)
EndMacro

Macro Sci_LineEndDisplayExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDDISPLAYEXTEND)
EndMacro

Macro Sci_LineEndWrap(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDWRAP)
EndMacro

Macro Sci_LineEndWrapExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEENDWRAPEXTEND)
EndMacro

Macro Sci_DocumentStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DOCUMENTSTART)
EndMacro

Macro Sci_DocumentStartExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DOCUMENTSTARTEXTEND)
EndMacro

Macro Sci_DocumentEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DOCUMENTEND)
EndMacro

Macro Sci_DocumentEndExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DOCUMENTENDEXTEND)
EndMacro

Macro Sci_PageUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEUP)
EndMacro

Macro Sci_PageUpExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEUPEXTEND)
EndMacro

Macro Sci_PageUpRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEUPRECTEXTEND)
EndMacro

Macro Sci_PageDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEDOWN)
EndMacro

Macro Sci_PageDownExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEDOWNEXTEND)
EndMacro

Macro Sci_PageDownRectExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_PAGEDOWNRECTEXTEND)
EndMacro

Macro Sci_StutteredPageUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STUTTEREDPAGEUP)
EndMacro

Macro Sci_StutteredPageUpExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STUTTEREDPAGEUPEXTEND)
EndMacro

Macro Sci_StutteredPageDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STUTTEREDPAGEDOWN)
EndMacro

Macro Sci_StutteredPageDownExtend(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STUTTEREDPAGEDOWNEXTEND)
EndMacro

Macro Sci_DeleteBack(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELETEBACK)
EndMacro

Macro Sci_DeleteBackNotLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELETEBACKNOTLINE)
EndMacro

Macro Sci_DelWordLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELWORDLEFT)
EndMacro

Macro Sci_DelWordRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELWORDRIGHT)
EndMacro

Macro Sci_DelWordRightEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELWORDRIGHTEND)
EndMacro

Macro Sci_DelLineLeft(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELLINELEFT)
EndMacro

Macro Sci_DelLineRight(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DELLINERIGHT)
EndMacro

Macro Sci_LineDelete(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEDELETE)
EndMacro

Macro Sci_LineCut(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINECUT)
EndMacro

Macro Sci_LineCopy(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINECOPY)
EndMacro

Macro Sci_LineTranspose(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINETRANSPOSE)
EndMacro

Macro Sci_LineDuplicate(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINEDUPLICATE)
EndMacro

Macro Sci_LowerCase(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LOWERCASE)
EndMacro

Macro Sci_UpperCase(Gadget)
  ScintillaSendMessage((Gadget), #SCI_UPPERCASE)
EndMacro

Macro Sci_Cancel(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CANCEL)
EndMacro

Macro Sci_EditToggleOvertype(Gadget)
  ScintillaSendMessage((Gadget), #SCI_EDITTOGGLEOVERTYPE)
EndMacro

Macro Sci_NewLine(Gadget)
  ScintillaSendMessage((Gadget), #SCI_NEWLINE)
EndMacro

Macro Sci_FormFeed(Gadget)
  ScintillaSendMessage((Gadget), #SCI_FORMFEED)
EndMacro

Macro Sci_Tab(Gadget)
  ScintillaSendMessage((Gadget), #SCI_TAB)
EndMacro

Macro Sci_BackTab(Gadget)
  ScintillaSendMessage((Gadget), #SCI_BACKTAB)
EndMacro

Macro Sci_SelectionDuplicate(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SELECTIONDUPLICATE)
EndMacro

Macro Sci_VerticalCentreCaret(Gadget)
  ScintillaSendMessage((Gadget), #SCI_VERTICALCENTRECARET)
EndMacro

Macro Sci_MoveSelectedLinesUp(Gadget)
  ScintillaSendMessage((Gadget), #SCI_MOVESELECTEDLINESUP)
EndMacro

Macro Sci_MoveSelectedLinesDown(Gadget)
  ScintillaSendMessage((Gadget), #SCI_MOVESELECTEDLINESDOWN)
EndMacro

Macro Sci_ScrollToStart(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SCROLLTOSTART)
EndMacro

Macro Sci_ScrollToEnd(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SCROLLTOEND)
EndMacro

;-
;-
;- Key bindings
;-

Macro Sci_AssignCmdKey(Gadget, keyDefinition, sciCommand)
  ScintillaSendMessage((Gadget), #SCI_ASSIGNCMDKEY, (keyDefinition), (sciCommand))
EndMacro

Macro Sci_ClearCmdKey(Gadget, keyDefinition)
  ScintillaSendMessage((Gadget), #SCI_CLEARCMDKEY, (keyDefinition))
EndMacro

Macro Sci_ClearAllCmdKeys(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CLEARALLCMDKEYS)
EndMacro

Macro Sci_Null(Gadget)
  ScintillaSendMessage((Gadget), #SCI_NULL)
EndMacro

;-
;-
;- Popup edit menu
;-

Macro Sci_UsePopup(Gadget, bEnablePopup)
  ScintillaSendMessage((Gadget), #SCI_USEPOPUP, (bEnablePopup))
EndMacro

;-
;-
;- Macro recording
;-

Macro Sci_StartRecord(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STARTRECORD)
EndMacro

Macro Sci_StopRecord(Gadget)
  ScintillaSendMessage((Gadget), #SCI_STOPRECORD)
EndMacro

;-
;-
;- Printing
;-

Macro Sci_FormatRange(Gadget, bDraw, pfr)
  ScintillaSendMessage((Gadget), #SCI_FORMATRANGE, (bDraw), (pfr))
EndMacro

Macro Sci_SetPrintMagnification(Gadget, magnification)
  ScintillaSendMessage((Gadget), #SCI_SETPRINTMAGNIFICATION, (magnification))
EndMacro

Macro Sci_GetPrintMagnification(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPRINTMAGNIFICATION)
EndMacro

Macro Sci_SetPrintColourMode(Gadget, mode)
  ScintillaSendMessage((Gadget), #SCI_SETPRINTCOLOURMODE, (mode))
EndMacro

Macro Sci_GetPrintColourMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPRINTCOLOURMODE)
EndMacro

Macro Sci_SetPrintWrapMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_SETPRINTWRAPMODE)
EndMacro

Macro Sci_GetPrintWrapMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPRINTWRAPMODE)
EndMacro

;-
;-
;- Direct access
;-

Macro Sci_GetDirectFunction(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETDIRECTFUNCTION)
EndMacro

Macro Sci_GetDirectPointer(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETDIRECTPOINTER)
EndMacro

Macro Sci_GetCharacterPointer(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETCHARACTERPOINTER)
EndMacro

Macro Sci_GetRangePointer(Gadget, position, rangeLength)
  ScintillaSendMessage((Gadget), #SCI_GETRANGEPOINTER, (position), (rangeLength))
EndMacro

Macro Sci_GetGapPosition(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETGAPPOSITION)
EndMacro

;-
;-
;- Multiple views
;-

Macro Sci_GetDocPointer(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETDOCPOINTER)
EndMacro

Macro Sci_SetDocPointer(Gadget, pDoc)
  ScintillaSendMessage((Gadget), #SCI_SETDOCPOINTER, #Null, (pDoc))
EndMacro

Macro Sci_CreateDocument(Gadget)
  ScintillaSendMessage((Gadget), #SCI_CREATEDOCUMENT)
EndMacro

Macro Sci_AddRefDocument(Gadget, pDoc)
  ScintillaSendMessage((Gadget), #SCI_ADDREFDOCUMENT, #Null, (pDoc))
EndMacro

Macro Sci_ReleaseDocument(Gadget, pDoc)
  ScintillaSendMessage((Gadget), #SCI_RELEASEDOCUMENT, #Null, (pDoc))
EndMacro

;-
;-
;- Background loading and saving
;-

Macro Sci_CreateLoader(Gadget, bytes)
  ScintillaSendMessage((Gadget), #SCI_CREATELOADER, (bytes))
EndMacro

;-
;-
;- Folding
;-

Macro Sci_VisibleFromDocLine(Gadget, docLine)
  ScintillaSendMessage((Gadget), #SCI_VISIBLEFROMDOCLINE, (docLine))
EndMacro

Macro Sci_DocLineFromVisible(Gadget, displayLine)
  ScintillaSendMessage((Gadget), #SCI_DOCLINEFROMVISIBLE, (displayLine))
EndMacro

Macro Sci_ShowLines(Gadget, lineStart, lineEnd)
  ScintillaSendMessage((Gadget), #SCI_SHOWLINES, (lineStart), (lineEnd))
EndMacro

Macro Sci_HideLines(Gadget, lineStart, lineEnd)
  ScintillaSendMessage((Gadget), #SCI_HIDELINES, (lineStart), (lineEnd))
EndMacro

Macro Sci_GetLineVisible(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETLINEVISIBLE, (line))
EndMacro

Macro Sci_GetAllLinesVisible(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETALLLINESVISIBLE)
EndMacro

Macro Sci_SetFoldLevel(Gadget, line, level)
  ScintillaSendMessage((Gadget), #SCI_SETFOLDLEVEL, (line), (level))
EndMacro

Macro Sci_GetFoldLevel(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETFOLDLEVEL, (line))
EndMacro

Macro Sci_SetAutomaticFold(Gadget, automaticFold)
  ScintillaSendMessage((Gadget), #SCI_SETAUTOMATICFOLD, (automaticFold))
EndMacro

Macro Sci_GetAutomaticFold(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETAUTOMATICFOLD)
EndMacro

Macro Sci_SetFoldFlags(Gadget, flags)
  ScintillaSendMessage((Gadget), #SCI_SETFOLDFLAGS, (flags))
EndMacro

Macro Sci_GetLastChild(Gadget, line, level)
  ScintillaSendMessage((Gadget), #SCI_GETLASTCHILD, (line), (level))
EndMacro

Macro Sci_GetFoldParent(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETFOLDPARENT, (line))
EndMacro

Macro Sci_SetFoldExpanded(Gadget, line, expanded)
  ScintillaSendMessage((Gadget), #SCI_SETFOLDEXPANDED, (line), (expanded))
EndMacro

Macro Sci_GetFoldExpanded(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_GETFOLDEXPANDED, (line))
EndMacro

Macro Sci_ContractedFoldNext(Gadget, lineStart)
  ScintillaSendMessage((Gadget), #SCI_CONTRACTEDFOLDNEXT, (lineStart))
EndMacro

Macro Sci_ToggleFold(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_TOGGLEFOLD, (line))
EndMacro

Macro Sci_FoldLine(Gadget, line, action)
  ScintillaSendMessage((Gadget), #SCI_FOLDLINE, (line), (action))
EndMacro

Macro Sci_FoldChildren(Gadget, line, action)
  ScintillaSendMessage((Gadget), #SCI_FOLDCHILDREN, (line), (action))
EndMacro

Macro Sci_FoldAll(Gadget, action)
  ScintillaSendMessage((Gadget), #SCI_FOLDALL, (action))
EndMacro

Macro Sci_ExpandChildren(Gadget, line, level)
  ScintillaSendMessage((Gadget), #SCI_EXPANDCHILDREN, (line), (level))
EndMacro

Macro Sci_EnsureVisible(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_ENSUREVISIBLE, (line))
EndMacro

Macro Sci_EnsureVisibleEnforcePolicy(Gadget, line)
  ScintillaSendMessage((Gadget), #SCI_ENSUREVISIBLEENFORCEPOLICY, (line))
EndMacro

;-
;-
;- Line wrapping
;-

Macro Sci_SetWrapMode(Gadget, wrapMode)
  ScintillaSendMessage((Gadget), #SCI_SETWRAPMODE, (wrapMode))
EndMacro

Macro Sci_GetWrapMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWRAPMODE)
EndMacro

Macro Sci_SetWrapVisualFlags(Gadget, wrapVisualFlags)
  ScintillaSendMessage((Gadget), #SCI_SETWRAPVISUALFLAGS, (wrapVisualFlags))
EndMacro

Macro Sci_GetWrapVisualFlags(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWRAPVISUALFLAGS)
EndMacro

Macro Sci_SetWrapVisualFlagsLocation(Gadget, wrapVisualFlagsLocation)
  ScintillaSendMessage((Gadget), #SCI_SETWRAPVISUALFLAGSLOCATION, (wrapVisualFlagsLocation))
EndMacro

Macro Sci_GetWrapVisualFlagsLocation(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWRAPVISUALFLAGSLOCATION)
EndMacro

Macro Sci_SetWrapIndentMode(Gadget, indentMode)
  ScintillaSendMessage((Gadget), #SCI_SETWRAPINDENTMODE, (indentMode))
EndMacro

Macro Sci_GetWrapIndentMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWRAPINDENTMODE)
EndMacro

Macro Sci_SetWrapStartIndent(Gadget, indent)
  ScintillaSendMessage((Gadget), #SCI_SETWRAPSTARTINDENT, (indent))
EndMacro

Macro Sci_GetWrapStartIndent(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETWRAPSTARTINDENT)
EndMacro

Macro Sci_SetLayoutCache(Gadget, cacheMode)
  ScintillaSendMessage((Gadget), #SCI_SETLAYOUTCACHE, (cacheMode))
EndMacro

Macro Sci_GetLayoutCache(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLAYOUTCACHE)
EndMacro

Macro Sci_SetPositionCache(Gadget, size)
  ScintillaSendMessage((Gadget), #SCI_SETPOSITIONCACHE, (size))
EndMacro

Macro Sci_GetPositionCache(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETPOSITIONCACHE)
EndMacro

Macro Sci_LinesSplit(Gadget, pixelWidth)
  ScintillaSendMessage((Gadget), #SCI_LINESSPLIT, (pixelWidth))
EndMacro

Macro Sci_LinesJoin(Gadget)
  ScintillaSendMessage((Gadget), #SCI_LINESJOIN)
EndMacro

Macro Sci_WrapCount(Gadget, docLine)
  ScintillaSendMessage((Gadget), #SCI_WRAPCOUNT, (docLine))
EndMacro

;-
;-
;- Zooming
;-

Macro Sci_ZoomIn(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ZOOMIN)
EndMacro

Macro Sci_ZoomOut(Gadget)
  ScintillaSendMessage((Gadget), #SCI_ZOOMOUT)
EndMacro

Macro Sci_SetZoom(Gadget, zoomInPoints)
  ScintillaSendMessage((Gadget), #SCI_SETZOOM, (zoomInPoints))
EndMacro

Macro Sci_GetZoom(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETZOOM)
EndMacro

;-
;-
;- Long lines
;-

Macro Sci_SetEdgeMode(Gadget, mode)
  ScintillaSendMessage((Gadget), #SCI_SETEDGEMODE, (mode))
EndMacro

Macro Sci_GetEdgeMode(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEDGEMODE)
EndMacro

Macro Sci_SetEdgeColumn(Gadget, column)
  ScintillaSendMessage((Gadget), #SCI_SETEDGECOLUMN, (column))
EndMacro

Macro Sci_GetEdgeColumn(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEDGECOLUMN)
EndMacro

Macro Sci_SetEdgeColour(Gadget, colour)
  ScintillaSendMessage((Gadget), #SCI_SETEDGECOLOUR, (colour))
EndMacro

Macro Sci_GetEdgeColour(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETEDGECOLOUR)
EndMacro

;-
;-
;- Lexer
;-

Macro Sci_SetLexer(Gadget, lexer)
  ScintillaSendMessage((Gadget), #SCI_SETLEXER, (lexer))
EndMacro

Macro Sci_GetLexer(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETLEXER)
EndMacro

Macro Sci_SetLexerLanguage(Gadget, name)
  _Sci_SendStr((Gadget), #SCI_SETLEXERLANGUAGE, #Null, (name))
EndMacro

;- ----- Sci_GetLexerLanguage (<unused>, char* name) [None, StrOut]

Macro Sci_LoadLexerLibrary(Gadget, path)
  _Sci_SendStr((Gadget), #SCI_LOADLEXERLIBRARY, #Null, (path))
EndMacro

Macro Sci_Colourise(Gadget, start, endPos)
  ScintillaSendMessage((Gadget), #SCI_COLOURISE, (start), (endPos))
EndMacro

Macro Sci_ChangeLexerState(Gadget, start, endPos)
  ScintillaSendMessage((Gadget), #SCI_CHANGELEXERSTATE, (start), (endPos))
EndMacro

;- ----- Sci_PropertyNames (<unused>, char* names) [None, StrOut]

Macro Sci_PropertyType(Gadget, name)
  _Sci_SendStrFirst((Gadget), #SCI_PROPERTYTYPE, (name), #Null)
EndMacro

;- ----- Sci_DescribeProperty (const char* name, char* description) [StrIn, StrOut]

Macro Sci_SetProperty(Gadget, key, value)
  _Sci_SendStr2((Gadget), #SCI_SETPROPERTY, (key), (value))
EndMacro

Procedure.s Sci_GetProperty(Gadget, key.s)
  Protected nLenPlus1.i = _Sci_SendStrFirst(Gadget, #SCI_GETPROPERTY, key, #Null)
  Protected Buffer.s = Space(nLenPlus1)
  _Sci_SendStrFirst(Gadget, #SCI_GETPROPERTY, key, @Buffer)
  ProcedureReturn (_Sci_PeekUTF8(@Buffer))
EndProcedure

;- ----- Sci_GetPropertyExpanded (const char* key, char* value) [StrIn, StrOut]

Macro Sci_GetPropertyInt(Gadget, key, defaultInt = 0)
  _Sci_SendStrFirst((Gadget), #SCI_GETPROPERTYINT, (key), (defaultInt))
EndMacro

;- ----- Sci_DescribeKeywordSets (<unused>, char* descriptions) [None, StrOut]

Macro Sci_SetKeywords(Gadget, keyWordSet, keyWordList)
  _Sci_SendStr((Gadget), #SCI_SETKEYWORDS, (keyWordSet), (keyWordList))
EndMacro

;- ----- Sci_GetSubstyleBases (<unused>, char* styles) [None, StrOut]

Macro Sci_DistanceToSecondaryStyles(Gadget)
  ScintillaSendMessage((Gadget), #SCI_DISTANCETOSECONDARYSTYLES)
EndMacro

Macro Sci_AllocateSubstyles(Gadget, styleBase, numberStyles)
  ScintillaSendMessage((Gadget), #SCI_ALLOCATESUBSTYLES, (styleBase), (numberStyles))
EndMacro

Macro Sci_FreeSubstyles(Gadget)
  ScintillaSendMessage((Gadget), #SCI_FREESUBSTYLES)
EndMacro

Macro Sci_GetSubstylesStart(Gadget, styleBase)
  ScintillaSendMessage((Gadget), #SCI_GETSUBSTYLESSTART, (styleBase))
EndMacro

Macro Sci_GetSubstylesLength(Gadget, styleBase)
  ScintillaSendMessage((Gadget), #SCI_GETSUBSTYLESLENGTH, (styleBase))
EndMacro

Macro Sci_GetStyleFromSubstyle(Gadget, subStyle)
  ScintillaSendMessage((Gadget), #SCI_GETSTYLEFROMSUBSTYLE, (subStyle))
EndMacro

Macro Sci_GetPrimaryStyleFromStyle(Gadget, style)
  ScintillaSendMessage((Gadget), #SCI_GETPRIMARYSTYLEFROMSTYLE, (style))
EndMacro

Macro Sci_SetIdentifiers(Gadget, style, identifiers)
  _Sci_SendStr((Gadget), #SCI_SETIDENTIFIERS, (style), (identifiers))
EndMacro

;-
;-
;- Notifications
;-

Macro Sci_SetModEventMask(Gadget, eventMask)
  ScintillaSendMessage((Gadget), #SCI_SETMODEVENTMASK, (eventMask))
EndMacro

Macro Sci_GetModEventMask(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMODEVENTMASK)
EndMacro

Macro Sci_SetMouseDwellTime(Gadget, milliseconds)
  ScintillaSendMessage((Gadget), #SCI_SETMOUSEDWELLTIME, (milliseconds))
EndMacro

Macro Sci_GetMouseDwellTime(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETMOUSEDWELLTIME)
EndMacro

Macro Sci_SetIdentifier(Gadget, identifier)
  ScintillaSendMessage((Gadget), #SCI_SETIDENTIFIER, (identifier))
EndMacro

Macro Sci_GetIdentifier(Gadget)
  ScintillaSendMessage((Gadget), #SCI_GETIDENTIFIER)
EndMacro



;-
;-
;- ScintillaBoost Extra Functions
;-

CompilerIf (Not Defined(_Sci_NoExtraFunctions, #PB_Constant))

#SB_Find_Default   = $00
#SB_Find_MatchCase = $01
#SB_Find_WholeWord = $02
#SB_Find_Backward  = $04
#SB_Find_NoWrap    = $08
#SB_Find_Forward   = $00
#SB_Find_Reverse   = #SB_Find_Backward

Macro Sci_Send_(Gadget, Message, Param = 0, lParam = #Null)
  ScintillaSendMessage((Gadget), (Message), (Param), (lParam))
EndMacro

Macro Sci_SendStr_(Gadget, Message, intParam, strParam)
  _Sci_SendStr((Gadget), (Message), (intParam), (strParam))
EndMacro

Procedure.i Sci_IsLineVisible_(Gadget.i, Line.i = -1)
  Protected Result.i = #False
  If (Line = -1)
    Line = Sci_LineFromPosition(Gadget, Sci_GetSelectionStart(Gadget))
  EndIf
  Protected First.i = Sci_GetFirstVisibleLine(Gadget)
  Protected Last.i  = First + Sci_LinesOnScreen(Gadget)
  If ((Line >= First) And (Line < Last))
    Result = #True
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure Sci_AppendNull_(Gadget.i)
  Protected NullByte.b = $00
  ScintillaSendMessage(Gadget, #SCI_APPENDTEXT, 1, @NullByte)
EndProcedure

Procedure Sci_AdjustView_(Gadget.i)
  If (Not Sci_IsLineVisible_(Gadget))
    Protected i.i = Sci_LineFromPosition(Gadget, Sci_GetSelectionStart(Gadget))
    Protected n.i = Sci_LinesOnScreen(Gadget)
    Protected First.i = i - n/2
    If (First < 0)
      First = 0
    EndIf
    Sci_SetFirstVisibleLine(Gadget, First)
  EndIf
EndProcedure

Procedure.s Sci_GetRangeText_(Gadget.i, StartPos.i, EndPos.i)
  Protected Result.s
  If (EndPos > StartPos)
    Protected Bytes.i = EndPos - StartPos
    Protected *Buffer = AllocateMemory(Bytes + 1)
    If (*Buffer)
      Protected TR.TextRange
      TR\chrg\cpMin = StartPos
      TR\chrg\cpMax = EndPos
      TR\lpstrText  = *Buffer
      Sci_GetTextRange(Gadget, @TR) ; writes 0-terminator byte
      CompilerIf (#PB_Compiler_Unicode)
        Result = PeekS(*Buffer, Bytes, #PB_UTF8 | #PB_ByteLength)
      CompilerElse
        Result = PeekS(*Buffer, Bytes, #PB_Ascii)
      CompilerEndIf
      FreeMemory(*Buffer)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Macro Sci_DeleteForward_(Gadget)
  Sci_Clear(Gadget)
EndMacro

Macro Sci_Deselect_(Gadget)
  Sci_SetEmptySelection((Gadget), Sci_GetCurrentPos(Gadget))
EndMacro

Procedure.i Sci_IsWord_(Gadget.i, Text.s)
  Protected Result.i = #False
  If (IsGadget(Gadget))
    Protected WordChars.s = Sci_GetWordChars(Gadget)
    If (WordChars)
      Protected *C.CHARACTER = @Text
      While (*C\c)
        Result = #False
        Protected *TC.CHARACTER = @WordChars
        While (*TC\c)
          If (*TC\c = *C\c)
            Result = #True
            Break
          EndIf
          *TC + SizeOf(CHARACTER)
        Wend
        If (Not Result)
          Break
        EndIf
        *C + SizeOf(CHARACTER)
      Wend
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Macro Sci_FindForward_(Gadget, Query, Flags = 0)
  Sci_Find_((Gadget), Query, (Flags) | #SB_Find_Forward)
EndMacro

Macro Sci_FindBackward_(Gadget, Query, Flags = 0)
  Sci_Find_((Gadget), Query, (Flags) | #SB_Find_Backward)
EndMacro

Procedure.i Sci_Find_(Gadget.i, Query.s, Flags.i = #SB_Find_Default)
  Protected Result.i = 0 ; Return 0 for Not Found, (1 + StartPos) for Found
  If (Query)
    Protected SelStart.i = Sci_GetSelectionStart(Gadget)
    Protected SelStop.i  = Sci_GetSelectionEnd(Gadget)
    Protected DocLen.i   = Sci_GetLength(Gadget)
    
    Protected SciFlags.i = #Null
    If (Flags & #SB_Find_MatchCase)
      SciFlags | #SCFIND_MATCHCASE
    EndIf
    If (Flags & #SB_Find_WholeWord)
      SciFlags | #SCFIND_WHOLEWORD
    EndIf
    Sci_SetSearchFlags(Gadget, SciFlags)
    
    Protected Wrap.i = #False
    Protected Offset.i = 0
    While (#True)
      If (Flags & #SB_Find_Backward)
        If (Wrap)
          Sci_SetTargetStart(Gadget, DocLen)
          Sci_SetTargetEnd(Gadget, 0)
        Else
          Sci_SetTargetStart(Gadget, SelStart + Offset)
          Sci_SetTargetEnd(Gadget, 0)
        EndIf
      Else
        If (Wrap)
          Sci_SetTargetStart(Gadget, 0)
          Sci_SetTargetEnd(Gadget, DocLen)
        Else
          Sci_SetTargetStart(Gadget, SelStart + Offset)
          Sci_SetTargetEnd(Gadget, DocLen)
        EndIf
      EndIf
      
      If (Sci_SearchInTarget(Gadget, Query) >= 0)
        If ((Sci_GetTargetStart(Gadget) = SelStart) And (Sci_GetTargetEnd(Gadget) = SelStop))
          If (Wrap)
            Result = 1 + Sci_GetTargetStart(Gadget)
            Break
          Else
            If (Flags & #SB_Find_Backward)
              Offset - 1
            Else
              Offset + 1
            EndIf
            ; Search again...
          EndIf
        Else
          Sci_SetSel(Gadget, Sci_GetTargetStart(Gadget), Sci_GetTargetEnd(Gadget))
          If (#True)
            ;Sci_AdjustView_(Gadget)
            Sci_ScrollRange(Gadget, Sci_GetTargetEnd(Gadget), Sci_GetTargetStart(Gadget))
          EndIf
          Result = 1 + Sci_GetTargetStart(Gadget)
          Break
        EndIf
      Else
        If (Wrap Or (Flags & #SB_Find_NoWrap))
          Break
        Else
          Wrap = #True
          ; Search again...
        EndIf
      EndIf
    Wend
    
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i Sci_GetCharacterAndWidth_(Gadget.i, Position.i, *Width.INTEGER = #Null)
  Protected Result.i = #NUL
  Protected Width.i = 0
  Protected Byte.i = ScintillaSendMessage(Gadget, #SCI_GETCHARAT, Position)
  If (Byte & $80)
    Protected ExtraBytes.i = 0
    If (Byte & $E0 = $C0)
      ExtraBytes = 1 : Result = (Byte & $1F)
    ElseIf (Byte & $F0 = $E0)
      ExtraBytes = 2 : Result = (Byte & $0F)
    ElseIf (Byte & $F8 = $F0)
      ExtraBytes = 3 : Result = (Byte & $07)
    ElseIf (Byte & $FC = $F8)
      ExtraBytes = 4 : Result = (Byte & $03)
    ElseIf (Byte & $FE = $FC)
      ExtraBytes = 5 : Result = (Byte & $01)
    EndIf
    If (ExtraBytes)
      Width = 1 + ExtraBytes
      While (ExtraBytes > 0)
        Position + 1
        Byte = ScintillaSendMessage(Gadget, #SCI_GETCHARAT, Position)
        Result = (Result << 6) | (Byte & $3F)
        ExtraBytes - 1
      Wend
    EndIf
  Else
    Result = Byte
    Width = 1
  EndIf
  If (*Width)
    *Width\i = Width
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s Sci_GetContextWord_(Gadget.i, Position.i = -1)
  Protected Start.i, Stop.i
  If (Position < 0)
    Position = Sci_GetCurrentPos(Gadget)
  EndIf
  Start = Sci_WordStartPosition(Gadget, Position, #True)
  Stop  = Sci_WordEndPosition(Gadget, Position, #True)
  If (Stop > Start)
    ProcedureReturn (Sci_GetRangeText_(Gadget, Start, Stop))
  EndIf
  ProcedureReturn ("")
EndProcedure

Macro Sci_GetCurLineNumber_(Gadget)
  Sci_LineFromPosition((Gadget), Sci_GetCurrentPos(Gadget))
EndMacro

Macro Sci_GetCurLineStart_(Gadget)
  Sci_PositionFromLine((Gadget), Sci_GetCurLineNumber_(Gadget))
EndMacro

Procedure.s Sci_GetCurLineTrimmed_(Gadget.i)
  ProcedureReturn (RemoveString(RemoveString(Sci_GetCurLine(Gadget), #CR$), #LF$))
EndProcedure

Procedure.s Sci_GetLineTrimmed_(Gadget.i, Line.i)
  ProcedureReturn (RemoveString(RemoveString(Sci_GetLine(Gadget, Line), #CR$), #LF$))
EndProcedure

Procedure.i Sci_GetSelectionBounds_(Gadget.i, *Start.INTEGER, *Stop.INTEGER)
  *Start\i = Sci_GetSelectionStart(Gadget)
  *Stop\i  = Sci_GetSelectionEnd(Gadget)
  ProcedureReturn (*Stop\i - *Start\i)
EndProcedure

Procedure.i Sci_GetSelOrWordOrCursor_(Gadget.i, *Start.INTEGER, *Stop.INTEGER)
  Protected Start.i = Sci_GetSelectionStart(Gadget)
  Protected Stop.i  = Sci_GetSelectionEnd(Gadget)
  If (Stop > Start) ; User selection
    ; OK
  Else ; No selection
    Start = Sci_WordStartPosition(Gadget, Start, #True)
    Stop  = Sci_WordEndPosition(Gadget, Stop, #True)
  EndIf
  If (*Start)
    *Start\i = Start
  EndIf
  If (*Stop)
    *Stop\i = Stop
  EndIf
  ProcedureReturn (Stop - Start)
EndProcedure

Procedure.d Sci_GetScrollYPercent_(Gadget.i)
  Protected Result.i = 0
  Protected nLines.i = Sci_GetLineCount(Gadget)
  Protected VisLines.i = Sci_LinesOnScreen(Gadget)
  If (nLines > VisLines)
    Protected MaxScroll.i = nLines - VisLines
    Protected TopLine.i = Sci_GetFirstVisibleLine(Gadget)
    Result = 100.0 * TopLine / MaxScroll
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure Sci_SelectLine_(Gadget.i, Line.i, IncludeIndent.i = #False)
  Protected Start.i, Stop.i
  Start = Sci_PositionFromLine(Gadget, Line)
  Stop  = Sci_GetLineEndPosition(Gadget, Line)
  If (Not IncludeIndent)
    ;Start + ScintillaSendMessage(Gadget, #SCI_GETLINEINDENTPOSITION, Line) - Start
    Start = Sci_GetLineIndentPosition(Gadget, Line)
  EndIf
  Sci_SetSelection(Gadget, Start, Stop)
EndProcedure

Procedure Sci_SetBorder_(Gadget.i, State.i)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    If (State)
      SetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE, GetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE) |  #WS_EX_CLIENTEDGE)
    Else
      SetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE, GetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE) & ~#WS_EX_CLIENTEDGE)
    EndIf
  CompilerEndIf
EndProcedure

Procedure Sci_SetRangeStyle_(Gadget.i, Start.i, Stop.i, StyleNumber.i)
  If (Stop > Start)
    Sci_StartStyling(Gadget, Start)
    Sci_SetStyling(Gadget, Stop - Start, StyleNumber)
  EndIf
EndProcedure

Procedure Sci_SetRangeText_(Gadget.i, Start.i, Stop.i, Text.s)
  If (Stop > Start)
    Sci_SetTargetStart(Gadget, Start)
    Sci_SetTargetEnd(Gadget, Stop)
    Sci_ReplaceTarget(Gadget, Text)
  EndIf
EndProcedure

Procedure Sci_SetScrollViewBackground_(Gadget.i, Color.i)
  CompilerIf ((#PB_Compiler_OS = #PB_OS_MacOS) And (#PB_Compiler_Version >= 510))
    Protected.CGFloat r, g, b, a
    r = Red(Color)   / 255.0
    g = Green(Color) / 255.0
    b = Blue(Color)  / 255.0
    a = 1.0
    Protected NSColor.i
    CocoaMessage(@NSColor, 0, "NSColor colorWithDeviceRed:@", @r,
        "green:@", @g, "blue:@", @b, "alpha:@", @a)
    Protected ScrollView.i
    CocoaMessage(@ScrollView, GadgetID(Gadget), "scrollView")
    CocoaMessage(0, ScrollView, "setBackgroundColor:", NSColor)
  CompilerEndIf
EndProcedure

Macro Sci_ScrollSelection_(Gadget)
  Sci_ScrollRange((Gadget), Sci_GetSelectionEnd(Gadget), Sci_GetSelectionStart(Gadget))
EndMacro

Procedure Sci_SetScrollYPercent_(Gadget.i, Percent.d)
  Protected nLines.i = Sci_GetLineCount(Gadget)
  Protected VisLines.i = Sci_LinesOnScreen(Gadget)
  If (nLines > VisLines)
    Protected MaxScroll.i = nLines - VisLines
    Protected TopLine.i = MaxScroll * Percent / 100.0
    Sci_SetFirstVisibleLine(Gadget, TopLine)
  EndIf
EndProcedure

Procedure Sci_StyleLastLine_(Gadget.i, StyleNumber.i, ExtraLines.i = 0)
  Protected n.i     = Sci_GetLineCount(Gadget)
  Protected Start.i = Sci_GetLineIndentPosition(Gadget, n-1 - ExtraLines)
  Protected Stop.i  = Sci_GetLength(Gadget)
  If (Stop > Start)
    Sci_StartStyling(Gadget, Start)
    Sci_SetStyling(Gadget, Stop - Start, StyleNumber)
  EndIf
EndProcedure

Procedure.i Sci_LoadFile_(Gadget.i, File.s)
  Sci_ClearAll(Gadget)
  Protected FN.i = ReadFile(#PB_Any, File)
  If (FN)
    Sci_SetText(Gadget, ReadString(FN, #PB_File_IgnoreEOL))
    CloseFile(FN)
  EndIf
  ProcedureReturn (Bool(FN))
EndProcedure

Procedure.i Sci_SaveFile_(Gadget.i, File.s)
  Protected FN.i = CreateFile(#PB_Any, File)
  If (FN)
    WriteString(FN, Sci_GetText(Gadget))
    CloseFile(FN)
  EndIf
  ProcedureReturn (Bool(FN))
EndProcedure

CompilerEndIf
CompilerEndIf
;-
;-
