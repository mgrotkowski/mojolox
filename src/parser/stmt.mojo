from src.lexer.token import Token
from src.utils import stringify_lox
from collections.optional import Optional
from memory.anypointer import AnyPointer
from utils.variant import Variant

from src.parser.expr import ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical, ExprCall
alias Expr = ExprBinary.Expr
trait Visitor:
   fn visitExpressionStmt(inout self, Expressionstmt : StmtExpression) raises -> None: ...
   fn visitPrintStmt(inout self, Printstmt : StmtPrint) raises -> None: ...
   fn visitVarStmt(inout self, Varstmt : StmtVar) raises -> None: ...
   fn visitBlockStmt(inout self, Blockstmt : StmtBlock) raises -> None: ...
   fn visitIfStmt(inout self, Ifstmt : StmtIf) raises -> None: ...
   fn visitWhileStmt(inout self, Whilestmt : StmtWhile) raises -> None: ...
   fn visitFunctionStmt(inout self, Functionstmt : StmtFunction) raises -> None: ...
   fn visitReturnStmt(inout self, Returnstmt : StmtReturn) raises -> None: ...
trait Stmt(CollectionElement):
   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None: ...

struct StmtExpression(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var expression : AnyPointer[Expr]

   fn __init__(inout self, expression : Expr):
      self.expression = AnyPointer[Expr]().alloc(1)
      self.expression.emplace_value(expression)

   fn __copyinit__(inout self, other : Self):
      self.expression = AnyPointer[Expr]()
      if other.expression:
         self.expression = AnyPointer[Expr]().alloc(1)
         self.expression.emplace_value(other.expression[])
   fn __moveinit__(inout self, owned other : Self):
      self.expression = other.expression
      other.expression = AnyPointer[Expr]()
   fn __del__(owned  self):
      if self.expression:
         _ = self.expression.take_value()
         self.expression.free()
   fn __str__(self) -> String:
      return String("Expression")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitExpressionStmt(self)

struct StmtPrint(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var expression : AnyPointer[Expr]

   fn __init__(inout self, expression : Expr):
      self.expression = AnyPointer[Expr]().alloc(1)
      self.expression.emplace_value(expression)

   fn __copyinit__(inout self, other : Self):
      self.expression = AnyPointer[Expr]()
      if other.expression:
         self.expression = AnyPointer[Expr]().alloc(1)
         self.expression.emplace_value(other.expression[])
   fn __moveinit__(inout self, owned other : Self):
      self.expression = other.expression
      other.expression = AnyPointer[Expr]()
   fn __del__(owned  self):
      if self.expression:
         _ = self.expression.take_value()
         self.expression.free()
   fn __str__(self) -> String:
      return String("Print")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitPrintStmt(self)

struct StmtVar(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var name : Token
   var initializer : AnyPointer[Expr]
   fn __init__(inout self, name : Token, initializer : Optional[Expr]):
      self.name = name
      self.initializer = AnyPointer[Expr]()
      if initializer:
         self.initializer = self.initializer.alloc(1)
         self.initializer.emplace_value(initializer.take())

   fn __copyinit__(inout self, other : Self):
      self.name = other.name
      self.initializer = AnyPointer[Expr]()
      if other.initializer:
         self.initializer = AnyPointer[Expr]().alloc(1)
         self.initializer.emplace_value(other.initializer[])
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.initializer = other.initializer
      other.initializer = AnyPointer[Expr]()
   fn __del__(owned  self):
      if self.initializer:
         _ = self.initializer.take_value()
         self.initializer.free()
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitVarStmt(self)

struct StmtBlock(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var statements : List[Self.Stmt]

   fn __init__(inout self, statements : List[Self.Stmt]):
      self.statements = statements

   fn __copyinit__(inout self, other : Self):
      self.statements = other.statements
   fn __moveinit__(inout self, owned other : Self):
      self.statements = other.statements
   fn __del__(owned  self):
         pass
   fn __str__(self) -> String:
      return String("Block")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitBlockStmt(self)

struct StmtIf(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var condition : AnyPointer[Expr]
   var then_stmt : AnyPointer[Self.Stmt]
   var else_stmt : AnyPointer[Self.Stmt]
   fn __init__(inout self, condition : Expr, then_stmt : Self.Stmt, else_stmt : Optional[Self.Stmt]):
      self.condition = AnyPointer[Expr]().alloc(1)
      self.condition.emplace_value(condition)
      self.then_stmt = AnyPointer[Self.Stmt]().alloc(1)
      self.then_stmt.emplace_value(then_stmt)
      self.else_stmt = AnyPointer[Self.Stmt]()
      if else_stmt:
         self.else_stmt = self.else_stmt.alloc(1)
         self.else_stmt.emplace_value(else_stmt.take())

   fn __copyinit__(inout self, other : Self):
      self.condition = AnyPointer[Expr]()
      if other.condition:
         self.condition = AnyPointer[Expr]().alloc(1)
         self.condition.emplace_value(other.condition[])
      self.then_stmt = AnyPointer[Self.Stmt]()
      if other.then_stmt:
         self.then_stmt = AnyPointer[Self.Stmt]().alloc(1)
         self.then_stmt.emplace_value(other.then_stmt[])
      self.else_stmt = AnyPointer[Self.Stmt]()
      if other.else_stmt:
         self.else_stmt = AnyPointer[Self.Stmt]().alloc(1)
         self.else_stmt.emplace_value(other.else_stmt[])
   fn __moveinit__(inout self, owned other : Self):
      self.condition = other.condition
      other.condition = AnyPointer[Expr]()
      self.then_stmt = other.then_stmt
      other.then_stmt = AnyPointer[Self.Stmt]()
      self.else_stmt = other.else_stmt
      other.else_stmt = AnyPointer[Self.Stmt]()
   fn __del__(owned  self):
      if self.condition:
         _ = self.condition.take_value()
         self.condition.free()
      if self.then_stmt:
         _ = self.then_stmt.take_value()
         self.then_stmt.free()
      if self.else_stmt:
         _ = self.else_stmt.take_value()
         self.else_stmt.free()
   fn __str__(self) -> String:
      return String("If")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitIfStmt(self)

struct StmtWhile(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var condition : AnyPointer[Expr]
   var body : AnyPointer[Self.Stmt]

   fn __init__(inout self, condition : Expr, body : Self.Stmt):
      self.condition = AnyPointer[Expr]().alloc(1)
      self.condition.emplace_value(condition)
      self.body = AnyPointer[Self.Stmt]().alloc(1)
      self.body.emplace_value(body)

   fn __copyinit__(inout self, other : Self):
      self.condition = AnyPointer[Expr]()
      if other.condition:
         self.condition = AnyPointer[Expr]().alloc(1)
         self.condition.emplace_value(other.condition[])
      self.body = AnyPointer[Self.Stmt]()
      if other.body:
         self.body = AnyPointer[Self.Stmt]().alloc(1)
         self.body.emplace_value(other.body[])
   fn __moveinit__(inout self, owned other : Self):
      self.condition = other.condition
      other.condition = AnyPointer[Expr]()
      self.body = other.body
      other.body = AnyPointer[Self.Stmt]()
   fn __del__(owned  self):
      if self.condition:
         _ = self.condition.take_value()
         self.condition.free()
      if self.body:
         _ = self.body.take_value()
         self.body.free()
   fn __str__(self) -> String:
      return String("While")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitWhileStmt(self)

struct StmtFunction(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var name : Token
   var params : List[Token]
   var body : List[Self.Stmt]

   fn __init__(inout self, name : Token, params : List[Token], body : List[Self.Stmt]):
      self.name = name
      self.params = params
      self.body = body

   fn __copyinit__(inout self, other : Self):
      self.name = other.name
      self.params = other.params
      self.body = other.body
   fn __moveinit__(inout self, owned other : Self):
      self.name = other.name
      self.params = other.params
      self.body = other.body
   fn __del__(owned  self):
         pass
   fn __str__(self) -> String:
      return str(self.name)

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitFunctionStmt(self)

struct StmtReturn(Stmt):
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile, StmtFunction, StmtReturn]
   var keyword : Token
   var value : Optional[Expr]

   fn __init__(inout self, keyword : Token, value : Optional[Expr]):
      self.keyword = keyword
      self.value = None
      if value:
         self.value = value.take()

   fn __copyinit__(inout self, other : Self):
      self.keyword = other.keyword
      self.value = other.value
   fn __moveinit__(inout self, owned other : Self):
      self.keyword = other.keyword
      self.value = other.value
   fn __del__(owned  self):
         pass
   fn __str__(self) -> String:
      return str(self.keyword)

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitReturnStmt(self)
