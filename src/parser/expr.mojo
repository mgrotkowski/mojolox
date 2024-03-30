from src.lexer.token import Token, LoxType, stringify_lox
from collections.optional import Optional
from memory.anypointer import AnyPointer
from utils.variant import Variant

trait Visitor:
   fn visitBinaryExpr[V : Copyable](inout self, Binaryexpr : ExprBinary) raises -> V: ...
   fn visitGroupingExpr[V : Copyable](inout self, Groupingexpr : ExprGrouping) raises -> V: ...
   fn visitLiteralExpr[V : Copyable](inout self, Literalexpr : ExprLiteral) raises -> V: ...
   fn visitUnaryExpr[V : Copyable](inout self, Unaryexpr : ExprUnary) raises -> V: ...
   fn visitVariableExpr[V : Copyable](inout self, Variableexpr : ExprVariable) raises -> V: ...
   fn visitAssignExpr[V : Copyable](inout self, Assignexpr : ExprAssign) raises -> V: ...

trait Expr(CollectionElement):
   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U: ...

struct ExprBinaryDelegate(CollectionElement):
   var ptr : AnyPointer[ExprBinary]
   fn __init__(inout self, expr : ExprBinary):
      self.ptr = AnyPointer[ExprBinary]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprBinary]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprBinary]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct ExprGroupingDelegate(CollectionElement):
   var ptr : AnyPointer[ExprGrouping]
   fn __init__(inout self, expr : ExprGrouping):
      self.ptr = AnyPointer[ExprGrouping]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprGrouping]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprGrouping]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct ExprLiteralDelegate(CollectionElement):
   var ptr : AnyPointer[ExprLiteral]
   fn __init__(inout self, expr : ExprLiteral):
      self.ptr = AnyPointer[ExprLiteral]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprLiteral]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprLiteral]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct ExprUnaryDelegate(CollectionElement):
   var ptr : AnyPointer[ExprUnary]
   fn __init__(inout self, expr : ExprUnary):
      self.ptr = AnyPointer[ExprUnary]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprUnary]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprUnary]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct ExprVariableDelegate(CollectionElement):
   var ptr : AnyPointer[ExprVariable]
   fn __init__(inout self, expr : ExprVariable):
      self.ptr = AnyPointer[ExprVariable]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprVariable]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprVariable]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct ExprAssignDelegate(CollectionElement):
   var ptr : AnyPointer[ExprAssign]
   fn __init__(inout self, expr : ExprAssign):
      self.ptr = AnyPointer[ExprAssign]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[ExprAssign]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
      other.ptr = AnyPointer[ExprAssign]()
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()


struct ExprBinary(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
   var left : Self.ptr_t
   var operator : Token
   var right : Self.ptr_t

   fn __init__(inout self, left : Self.var_t, operator : Token, right : Self.var_t):
      if left.isa[ExprBinary]():
         self.left = ExprBinaryDelegate(left.get[ExprBinary]()[])
      elif left.isa[ExprGrouping]():
         self.left = ExprGroupingDelegate(left.get[ExprGrouping]()[])
      elif left.isa[ExprLiteral]():
         self.left = ExprLiteralDelegate(left.get[ExprLiteral]()[])
      elif left.isa[ExprUnary]():
         self.left = ExprUnaryDelegate(left.get[ExprUnary]()[])
      elif left.isa[ExprVariable]():
         self.left = ExprVariableDelegate(left.get[ExprVariable]()[])
      else: 
         self.left = ExprAssignDelegate(left.get[ExprAssign]()[])

      self.operator = operator
      if right.isa[ExprBinary]():
         self.right = ExprBinaryDelegate(right.get[ExprBinary]()[])
      elif right.isa[ExprGrouping]():
         self.right = ExprGroupingDelegate(right.get[ExprGrouping]()[])
      elif right.isa[ExprLiteral]():
         self.right = ExprLiteralDelegate(right.get[ExprLiteral]()[])
      elif right.isa[ExprUnary]():
         self.right = ExprUnaryDelegate(right.get[ExprUnary]()[])
      elif right.isa[ExprVariable]():
         self.right = ExprVariableDelegate(right.get[ExprVariable]()[])
      else: 
         self.right = ExprAssignDelegate(right.get[ExprAssign]()[])


   fn __copyinit__(inout self, other : Self):
       self.left = other.left
       self.operator = other.operator
       self.right = other.right
   fn __moveinit__(inout self, owned other : Self):
      self.left = other.left
      self.operator = other.operator
      self.right = other.right
   fn __str__(self) -> String:
      return str(self.operator)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitBinaryExpr[U](self)

struct ExprGrouping(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
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
      return String("Grouping")

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitGroupingExpr[U](self)

struct ExprLiteral(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
   var value : LoxType

   fn __init__(inout self, value : LoxType):
      self.value = value

   fn __copyinit__(inout self, other : Self):
       self.value = other.value
   fn __moveinit__(inout self, owned other : Self):
      self.value = other.value
   fn __str__(self) -> String:
      return stringify_lox(self.value)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitLiteralExpr[U](self)

struct ExprUnary(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
   var operator : Token
   var right : Self.ptr_t

   fn __init__(inout self, operator : Token, right : Self.var_t):
      self.operator = operator
      if right.isa[ExprBinary]():
         self.right = ExprBinaryDelegate(right.get[ExprBinary]()[])
      elif right.isa[ExprGrouping]():
         self.right = ExprGroupingDelegate(right.get[ExprGrouping]()[])
      elif right.isa[ExprLiteral]():
         self.right = ExprLiteralDelegate(right.get[ExprLiteral]()[])
      elif right.isa[ExprUnary]():
         self.right = ExprUnaryDelegate(right.get[ExprUnary]()[])
      elif right.isa[ExprVariable]():
         self.right = ExprVariableDelegate(right.get[ExprVariable]()[])
      else: 
         self.right = ExprAssignDelegate(right.get[ExprAssign]()[])


   fn __copyinit__(inout self, other : Self):
       self.operator = other.operator
       self.right = other.right
   fn __moveinit__(inout self, owned other : Self):
      self.operator = other.operator
      self.right = other.right
   fn __str__(self) -> String:
      return str(self.operator)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitUnaryExpr[U](self)

struct ExprVariable(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
   var name : Token

   fn __init__(inout self, name : Token):
      self.name = name

   fn __copyinit__(inout self, other : Self):
       self.name = other.name
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitVariableExpr[U](self)

struct ExprAssign(Expr):
   alias ptr_t = Variant[ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate]
   alias var_t = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign]
   var name : Token
   var value : Self.ptr_t

   fn __init__(inout self, name : Token, value : Self.var_t):
      self.name = name
      if value.isa[ExprBinary]():
         self.value = ExprBinaryDelegate(value.get[ExprBinary]()[])
      elif value.isa[ExprGrouping]():
         self.value = ExprGroupingDelegate(value.get[ExprGrouping]()[])
      elif value.isa[ExprLiteral]():
         self.value = ExprLiteralDelegate(value.get[ExprLiteral]()[])
      elif value.isa[ExprUnary]():
         self.value = ExprUnaryDelegate(value.get[ExprUnary]()[])
      elif value.isa[ExprVariable]():
         self.value = ExprVariableDelegate(value.get[ExprVariable]()[])
      else: 
         self.value = ExprAssignDelegate(value.get[ExprAssign]()[])


   fn __copyinit__(inout self, other : Self):
       self.name = other.name
       self.value = other.value
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.value = other.value
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitAssignExpr[U](self)
