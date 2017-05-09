; +---------+
; | Complex |
; +---------+
; | 2016.02.03 . Creation (PureBasic 5.42b1)

;-
CompilerIf (Not Defined(__Complex_Included, #PB_Constant))
#__Complex_Included = #True

;- Constants (Private)

CompilerIf (SizeOf(QUAD) <> 8)
  CompilerError #PB_Compiler_Filename + ": SizeOf(QUAD) is incorrect"
CompilerElseIf (SizeOf(FLOAT) <> 4)
  CompilerError #PB_Compiler_Filename + ": SizeOf(FLOAT) is incorrect"
CompilerEndIf

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf






;-
;- Structures (Private)

Structure _Complex
  re.f
  im.f
EndStructure






;-
;- Macros (Private)

Macro Complex
  q
EndMacro







;-
;- Macros (Public)

CompilerIf (#True)

Macro cUnity()
  Complex_Unity()
EndMacro

Macro cNew(Real, Imaginary = 0.0)
  Complex_New(Real, Imaginary)
EndMacro
Macro cReal(x)
  Complex_Real(x)
EndMacro
Macro cImag(x)
  Complex_Imaginary(x)
EndMacro
Macro cStr(x)
  Complex_Str(x)
EndMacro
Macro cConj(x)
  Complex_Conjugate(x)
EndMacro
Macro cNeg(x)
  Complex_Negate(x)
EndMacro
Macro cRecip(x)
  Complex_Reciprocal(x)
EndMacro
Macro cMag(x)
  Complex_Magnitude(x)
EndMacro
Macro cPhase(x)
  Complex_Phase(x)
EndMacro

Macro cAdd(x, y)
  Complex_Add(x, y)
EndMacro
Macro cSub(x, y)
  Complex_Subtract(x, y)
EndMacro
Macro cMult(x, y)
  Complex_Multiply(x, y)
EndMacro
Macro cDiv(x, y)
  Complex_Divide(x, y)
EndMacro

CompilerEndIf










;-
;- Unary Operations

Procedure.Complex Complex_Unity()
  Protected Result.Complex
  PokeF(@Result, 1.0)
  PokeF(@Result + 4, 0.0)
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_New(Real.f, Imaginary.f = 0.0)
  Protected Result.Complex
  PokeF(@Result, Real)
  PokeF(@Result + 4, Imaginary)
  ProcedureReturn Result
EndProcedure

Procedure.f Complex_Real(x.Complex)
  ProcedureReturn PeekF(@x)
EndProcedure

Procedure.f Complex_Imaginary(x.Complex)
  ProcedureReturn PeekF(@x + 4)
EndProcedure

Procedure.s Complex_Str(x.Complex)
  Protected *x._Complex = @x
  If (*x\im < 0.0)
    ProcedureReturn (StrF(*x\re) + " - " + StrF(-*x\im) + "i")
  EndIf
  ProcedureReturn (StrF(*x\re) + " + " + StrF(*x\im) + "i")
EndProcedure

Procedure.Complex Complex_Conjugate(x.Complex)
  Protected Result.Complex
  PokeF(@Result, PeekF(@x))
  PokeF(@Result + 4, -PeekF(@x + 4))
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_Negate(x.Complex)
  Protected Result.Complex
  PokeF(@Result, -PeekF(@x))
  PokeF(@Result + 4, -PeekF(@x + 4))
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_Reciprocal(x.Complex)
  Protected Result.Complex
  Protected *x._Complex = @x
  PokeF(@Result, *x\re / (*x\re * *x\re + *x\im * *x\im))
  PokeF(@Result + 4, -*x\im / (*x\re * *x\re + *x\im * *x\im))
  ProcedureReturn Result
EndProcedure

Procedure.f Complex_Magnitude(x.Complex)
  Protected *x._Complex = @x
  ProcedureReturn Sqr(*x\re * *x\re + *x\im * *x\im)
EndProcedure

Procedure.f Complex_Phase(x.Complex)
  Protected *x._Complex = @x
  ProcedureReturn ATan2(*x\re, *x\im)
EndProcedure








;-
;- Binary Operations

Procedure.Complex Complex_Add(x.Complex, y.Complex)
  Protected Result.Complex
  PokeF(@Result, PeekF(@x) + PeekF(@y))
  PokeF(@Result + 4, PeekF(@x + 4) + PeekF(@y + 4))
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_Subtract(x.Complex, y.Complex)
  Protected Result.Complex
  PokeF(@Result, PeekF(@x) - PeekF(@y))
  PokeF(@Result + 4, PeekF(@x + 4) - PeekF(@y + 4))
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_Multiply(x.Complex, y.Complex)
  Protected Result.Complex
  Protected *x._Complex = @x
  Protected *y._Complex = @y
  PokeF(@Result, *x\re * *y\re - *x\im * *y\im)
  PokeF(@Result + 4, *x\re * *y\im + *x\im * *y\re)
  ProcedureReturn Result
EndProcedure

Procedure.Complex Complex_Divide(x.Complex, y.Complex)
  Protected Result.Complex
  Protected *x._Complex = @x
  Protected *y._Complex = @y
  PokeF(@Result, (*x\re * *y\re + *x\im * *y\im) / (*y\re * *y\re + *y\im * *y\im))
  PokeF(@Result + 4, (*x\im * *y\re - *x\re * *y\im) / (*y\re * *y\re + *y\im * *y\im))
  ProcedureReturn Result
EndProcedure







;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
  DisableExplicit
    
  a.Complex = cNew(3, -4)
  Debug "a = "              + cStr(a)
  Debug "Real Part = "      + StrF(cReal(a))
  Debug "Imaginary Part = " + StrF(cImag(a))
  Debug "Magnitude = "      + StrF(cMag(a))
  Debug "Phase = "          + StrF(Degree(cPhase(a)), 1) + " deg"
  Debug "Negate = "         + cStr(cNeg(a))
  Debug "Conjugate = "      + cStr(cConj(a))
  Debug "Reciprocal = "     + cStr(cRecip(a))
  Debug ""
  
  b.Complex = cNew(2, 1)
  Debug "b = "             + cStr(b)
  Debug "Add(a,b) = "      + cStr(cAdd(a, b))
  Debug "Subtract(a,b) = " + cStr(cSub(a, b))
  Debug "Multiply(a,b) = " + cStr(cMult(a, b))
  Debug "Divide(a,b) = "   + cStr(cDiv(a, b))
  Debug ""
  
CompilerEndIf
CompilerEndIf
;-