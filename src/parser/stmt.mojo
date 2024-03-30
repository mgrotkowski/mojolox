from src.lexer.token import Token, LoxType, stringify_lox
from collections.optional import Optional
from memory.anypointer import AnyPointer
from utils.variant import Variant

from src.parser.expr import ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign
from src.parser.expr import ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate

trait Visitor:
   fn visitExpressionStmt(inout self, Expressionstmt : StmtExpression) raises -> None: ...
   fn visitPrintStmt(inout self, Printstmt : StmtPrint) raises -> None: ...
   fn visitVarStmt(inout self, Varstmt : StmtVar) raises -> None: ...
   fn visitBlockStmt(inout self, Blockstmt : StmtBlock) raises -> None: ...

trait Stmt(CollectionElement):
   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None: ...

struct StmtExpressionDelegate(CollectionElement):
   var ptr : AnyPointer[StmtExpression]
   fn __init__(inout self, expr : StmtExpression):
      self.ptr = AnyPointer[StmtExpression]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtExpression]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct StmtPrintDelegate(CollectionElement):
   var ptr : AnyPointer[StmtPrint]
   fn __init__(inout self, expr : StmtPrint):
      self.ptr = AnyPointer[StmtPrint]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtPrint]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct StmtVarDelegate(CollectionElement):
   var ptr : AnyPointer[StmtVar]
   fn __init__(inout self, expr : StmtVar):
      self.ptr = AnyPointer[StmtVar]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtVar]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct StmtBlockDelegate(CollectionElement):
   var ptr : AnyPointer[StmtBlock]
   fn __init__(inout self, expr : StmtBlock):
      self.ptr = AnyPointer[StmtBlock]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtBlock]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()


struct StmtExpression(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   var expression : Self.ptr_t

   fn __init__(inout self, expression : Self.var_t):
      if expression.isa[ExprBinary]():
         self.expression = ExprBinaryDelegate(expression.get[ExprBinary]()[])
      elif expression.isa[ExprGrouping]():
         self.expression = ExprGroupingDelegate(expression.get[ExprGrouping]()[])
      elif expression.isa[ExprLiteral]():
         self.expression = ExprLiteralDelegate(expression.get[ExprLiteral]()[])
      elif expression.isa[ExprUnary]():
         self.expression = ExprUnaryDelegate(expression.get[ExprUnary]()[])
      elif expression.isa[ExprVariable]():
         self.expression = ExprVariableDelegate(expression.get[ExprVariable]()[])
      else: 
         self.expression = ExprAssignDelegate(expression.get[ExprAssign]()[])


   fn __copyinit__(inout self, other : Self):
       self.expression = other.expression
   fn __moveinit__(inout self, owned other : Self):
      self.expression = other.expression
   fn __str__(self) -> String:
      return String("Expression")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitExpressionStmt(self)

struct StmtPrint(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   var expression : Self.ptr_t

   fn __init__(inout self, expression : Self.var_t):
      if expression.isa[ExprBinary]():
         self.expression = ExprBinaryDelegate(expression.get[ExprBinary]()[])
      elif expression.isa[ExprGrouping]():
         self.expression = ExprGroupingDelegate(expression.get[ExprGrouping]()[])
      elif expression.isa[ExprLiteral]():
         self.expression = ExprLiteralDelegate(expression.get[ExprLiteral]()[])
      elif expression.isa[ExprUnary]():
         self.expression = ExprUnaryDelegate(expression.get[ExprUnary]()[])
      elif expression.isa[ExprVariable]():
         self.expression = ExprVariableDelegate(expression.get[ExprVariable]()[])
      else: 
         self.expression = ExprAssignDelegate(expression.get[ExprAssign]()[])


   fn __copyinit__(inout self, other : Self):
       self.expression = other.expression
   fn __moveinit__(inout self, owned other : Self):
      self.expression = other.expression
   fn __str__(self) -> String:
      return String("Print")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitPrintStmt(self)

struct StmtVar(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   var name : Token
   var initializer : Optional[Self.ptr_t]

   fn __init__(inout self, name : Token, initializer : Optional[Self.var_t]):
      self.name = name
      self.initializer = None
      if initializer:
            if initializer.value().isa[ExprBinary]():
               self.initializer = Self.ptr_t(ExprBinaryDelegate(initializer.value().get[ExprBinary]()[]))
            elif initializer.value().isa[ExprGrouping]():
               self.initializer = Self.ptr_t(ExprGroupingDelegate(initializer.value().get[ExprGrouping]()[]))
            elif initializer.value().isa[ExprLiteral]():
               self.initializer = Self.ptr_t(ExprLiteralDelegate(initializer.value().get[ExprLiteral]()[]))
            elif initializer.value().isa[ExprUnary]():
               self.initializer = Self.ptr_t(ExprUnaryDelegate(initializer.value().get[ExprUnary]()[]))
            elif initializer.value().isa[ExprVariable]():
               self.initializer = Self.ptr_t(ExprVariableDelegate(initializer.value().get[ExprVariable]()[]))
            else: 
               self.initializer = Self.ptr_t(ExprAssignDelegate(initializer.value().get[ExprAssign]()[]))


   fn __copyinit__(inout self, other : Self):
       self.name = other.name
       self.initializer = other.initializer
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.initializer = other.initializer
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitVarStmt(self)

struct StmtBlock(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   alias Stmt = Variant[StmtPrint, StmtExpression, StmtVar, StmtBlock]

   var statements : DynamicVector[Self.Stmt]

   fn __init__(inout self, owned statements : DynamicVector[Self.Stmt]):
      self.statements = statements^

   fn __copyinit__(inout self, other : Self):
       self.statements = other.statements
   fn __moveinit__(inout self, owned other : Self):
      self.statements = other.statements^
   fn __str__(self) -> String:
      return String("Block")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitBlockStmt(self)