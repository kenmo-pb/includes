; +----------+
; | IntStack |
; +----------+
; | 2017.02.23 . Creation (PureBasic 5.51)
; |     .05.05 . Added return value to PushStack() for convenience

;-
CompilerIf (Not Defined(__IntStack_Included, #PB_Constant))
#__IntStack_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;- Macros

Macro NewStack
  NewList
EndMacro

Macro Stack
  List
EndMacro

Macro StackSize(_Stack)
  ListSize(_Stack)
EndMacro

Macro StackEmpty(_Stack)
  Bool(StackSize(_Stack) = 0)
EndMacro

Macro FreeStack(_Stack)
  FreeList(_Stack)
EndMacro

Macro ClearStack(_Stack)
  ClearList(_Stack)
EndMacro

;-
;- Procedures

Procedure.i PushStack(Stack _Stack(), Value.i)
  ;FirstElement(_Stack())
  InsertElement(_Stack())
  _Stack() = Value
  ProcedureReturn (Value)
EndProcedure

Procedure.i PopStack(Stack _Stack())
  ;FirstElement(_Stack())
  Protected Result.i = _Stack()
  DeleteElement(_Stack(), 1)
  ProcedureReturn (Result)
EndProcedure

Procedure.i PeekStack(Stack _Stack())
  ;FirstElement(_Stack())
  ProcedureReturn (_Stack())
EndProcedure




;-
;- Demo

CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

NewStack MyStack() ; can also use NewList so that IDE Auto-completion works

Debug "Push: " + Str(PushStack(MyStack(), 1))
Debug "Push: " + Str(PushStack(MyStack(), 42))
Debug "Push: " + Str(PushStack(MyStack(), 585))
Debug ""

Debug "Size = " + Str(StackSize(MyStack()))
Debug "Peek: " + Str(PeekStack(MyStack()))
Debug ""

Debug "Pop: " + Str(PopStack(MyStack()))
Debug "Pop: " + Str(PopStack(MyStack()))
Debug "Pop: " + Str(PopStack(MyStack()))
Debug ""

Debug "Size = " + Str(StackSize(MyStack()))
;ClearStack(MyStack())
FreeStack(MyStack())

CompilerEndIf
CompilerEndIf
;-