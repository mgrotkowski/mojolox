from src.lexer.token import Token
from src.utils import stringify_lox
from src.lox_types import LoxBaseType
from collections.optional import Optional
from memory.anypointer import AnyPointer
from utils.variant import Variant

trait Visitor:
   fn visitBinaryExpr[V : Copyable](inout self, Binaryexpr : ExprBinary) raises -> V: ...
   fn visitGroupingExpr[V : Copyable](inout self, Groupingexpr : ExprGrouping) raises -> V: ...
   fn visitLiteralExpr[V : Copyable](inout self, Literalexpr : ExprLiteral) raises -> V: ...
   fn visitUnaryExpr[V : Copyable](inout self, Unaryexpr : ExprUnary) raises -> V: ...
   fn visitVariableExpr[V : Copyable](inout self, inout Variableexpr : ExprVariable) raises -> V: ...
   fn visitAssignExpr[V : Copyable](inout self, inout Assignexpr : ExprAssign) raises -> V: ...
   fn visitLogicalExpr[V : Copyable](inout self, Logicalexpr : ExprLogical) raises -> V: ...
   fn visitCallExpr[V : Copyable](inout self, inout Callexpr : ExprCall) raises -> V: ...
trait Expr(CollectionElement):
   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U: ...

struct ExprBinary(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var left : AnyPointer[Self.Expr]
   var operator : Token
   var right : AnyPointer[Self.Expr]

   fn __init__(inout self, left : Self.Expr, operator : Token, right : Self.Expr):
      self.left = AnyPointer[Self.Expr]().alloc(1)
      self.left.emplace_value(left)
      self.operator = operator
      self.right = AnyPointer[Self.Expr]().alloc(1)
      self.right.emplace_value(right)

   fn __copyinit__(inout self, other : Self):
      self.left = AnyPointer[Self.Expr]()
      if other.left:
         self.left = AnyPointer[Self.Expr]().alloc(1)
         self.left.emplace_value(other.left[])
      self.operator = other.operator
      self.right = AnyPointer[Self.Expr]()
      if other.right:
         self.right = AnyPointer[Self.Expr]().alloc(1)
         self.right.emplace_value(other.right[])
   fn __moveinit__(inout self, owned other : Self):
      self.left = other.left
      other.left = AnyPointer[Self.Expr]()
      self.operator = other.operator
      self.right = other.right
      other.right = AnyPointer[Self.Expr]()
   fn __del__(owned  self):
      if self.left:
         _ = self.left.take_value()
         self.left.free()
      if self.right:
         _ = self.right.take_value()
         self.right.free()
   fn __str__(self) -> String:
      return str(self.operator)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitBinaryExpr[U](self)

struct ExprGrouping(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var expression : AnyPointer[Self.Expr]

   fn __init__(inout self, expression : Self.Expr):
      self.expression = AnyPointer[Self.Expr]().alloc(1)
      self.expression.emplace_value(expression)

   fn __copyinit__(inout self, other : Self):
      self.expression = AnyPointer[Self.Expr]()
      if other.expression:
         self.expression = AnyPointer[Self.Expr]().alloc(1)
         self.expression.emplace_value(other.expression[])
   fn __moveinit__(inout self, owned other : Self):
      self.expression = other.expression
      other.expression = AnyPointer[Self.Expr]()
   fn __del__(owned  self):
      if self.expression:
         _ = self.expression.take_value()
         self.expression.free()
   fn __str__(self) -> String:
      return String("Grouping")

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitGroupingExpr[U](self)

struct ExprLiteral(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var value : LoxBaseType

   fn __init__(inout self, value : LoxBaseType):
      self.value = value

   fn __copyinit__(inout self, other : Self):
      self.value = other.value
   fn __moveinit__(inout self, owned other : Self):
      self.value = other.value
   fn __del__(owned  self):
         pass
   fn __str__(self) -> String:
      return stringify_lox(self.value)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitLiteralExpr[U](self)

struct ExprUnary(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var operator : Token
   var right : AnyPointer[Self.Expr]

   fn __init__(inout self, operator : Token, right : Self.Expr):
      self.operator = operator
      self.right = AnyPointer[Self.Expr]().alloc(1)
      self.right.emplace_value(right)

   fn __copyinit__(inout self, other : Self):
      self.operator = other.operator
      self.right = AnyPointer[Self.Expr]()
      if other.right:
         self.right = AnyPointer[Self.Expr]().alloc(1)
         self.right.emplace_value(other.right[])
   fn __moveinit__(inout self, owned other : Self):
      self.operator = other.operator
      self.right = other.right
      other.right = AnyPointer[Self.Expr]()
   fn __del__(owned  self):
      if self.right:
         _ = self.right.take_value()
         self.right.free()
   fn __str__(self) -> String:
      return str(self.operator)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitUnaryExpr[U](self)

struct ExprVariable(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var name : Token
   var distance : Optional[UInt64]

   fn __init__(inout self, name : Token):
      self.name = name
      self.distance = None

   fn __copyinit__(inout self, other : Self):
      self.name = other.name
      self.distance = other.distance
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.distance = other.distance
   fn __del__(owned  self):
         pass
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitVariableExpr[U](self)

struct ExprAssign(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var name : Token
   var value : AnyPointer[Self.Expr]
   var distance : Optional[UInt64]

   fn __init__(inout self, name : Token, value : Self.Expr):
      self.name = name
      self.value = AnyPointer[Self.Expr]().alloc(1)
      self.value.emplace_value(value)
      self.distance = None

   fn __copyinit__(inout self, other : Self):
      self.name = other.name
      self.value = AnyPointer[Self.Expr]()
      self.distance = other.distance
      if other.value:
         self.value = AnyPointer[Self.Expr]().alloc(1)
         self.value.emplace_value(other.value[])
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.value = other.value
      self.distance = other.distance
      other.value = AnyPointer[Self.Expr]()
   fn __del__(owned  self):
      if self.value:
         _ = self.value.take_value()
         self.value.free()
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitAssignExpr[U](self)

struct ExprLogical(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var left : AnyPointer[Self.Expr]
   var operator : Token
   var right : AnyPointer[Self.Expr]

   fn __init__(inout self, left : Self.Expr, operator : Token, right : Self.Expr):
      self.left = AnyPointer[Self.Expr]().alloc(1)
      self.left.emplace_value(left)
      self.operator = operator
      self.right = AnyPointer[Self.Expr]().alloc(1)
      self.right.emplace_value(right)

   fn __copyinit__(inout self, other : Self):
      self.left = AnyPointer[Self.Expr]()
      if other.left:
         self.left = AnyPointer[Self.Expr]().alloc(1)
         self.left.emplace_value(other.left[])
      self.operator = other.operator
      self.right = AnyPointer[Self.Expr]()
      if other.right:
         self.right = AnyPointer[Self.Expr]().alloc(1)
         self.right.emplace_value(other.right[])
   fn __moveinit__(inout self, owned other : Self):
      self.left = other.left
      other.left = AnyPointer[Self.Expr]()
      self.operator = other.operator
      self.right = other.right
      other.right = AnyPointer[Self.Expr]()
   fn __del__(owned  self):
      if self.left:
         _ = self.left.take_value()
         self.left.free()
      if self.right:
         _ = self.right.take_value()
         self.right.free()
   fn __str__(self) -> String:
      return str(self.operator)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitLogicalExpr[U](self)

struct ExprCall(Expr):
   alias Expr = Variant[ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall]
   var callee : AnyPointer[Self.Expr]
   var paren : Token
   var arguments : List[Self.Expr]

   fn __init__(inout self, callee : Self.Expr, paren : Token, arguments : List[Self.Expr]):
      self.callee = AnyPointer[Self.Expr]().alloc(1)
      self.callee.emplace_value(callee)
      self.paren = paren
      self.arguments = arguments

   fn __copyinit__(inout self, other : Self):
      self.callee = AnyPointer[Self.Expr]()
      if other.callee:
         self.callee = AnyPointer[Self.Expr]().alloc(1)
         self.callee.emplace_value(other.callee[])
      self.paren = other.paren
      self.arguments = other.arguments
   fn __moveinit__(inout self, owned other : Self):
      self.callee = other.callee
      other.callee = AnyPointer[Self.Expr]()
      self.paren = other.paren
      self.arguments = other.arguments
   fn __del__(owned  self):
      if self.callee:
         _ = self.callee.take_value()
         self.callee.free()
   fn __str__(self) -> String:
      return str(self.paren)

   fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:
      return visitor.visitCallExpr[U](self)
