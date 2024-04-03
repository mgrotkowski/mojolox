from src.lexer.token import Token, LoxType, stringify_lox
from collections.optional import Optional
from memory.anypointer import AnyPointer
from utils.variant import Variant

from src.parser.expr import ExprBinary, ExprGrouping, ExprLiteral, ExprUnary, ExprVariable, ExprAssign, ExprLogical
from src.parser.expr import ExprBinaryDelegate, ExprGroupingDelegate, ExprLiteralDelegate, ExprUnaryDelegate, ExprVariableDelegate, ExprAssignDelegate, ExprLogicalDelegate
from src.parser.expr import expr_delegate_init
trait Visitor:
   fn visitExpressionStmt(inout self, Expressionstmt : StmtExpression) raises -> None: ...
   fn visitPrintStmt(inout self, Printstmt : StmtPrint) raises -> None: ...
   fn visitVarStmt(inout self, Varstmt : StmtVar) raises -> None: ...
   fn visitBlockStmt(inout self, Blockstmt : StmtBlock) raises -> None: ...
   fn visitIfStmt(inout self, Ifstmt : StmtIf) raises -> None: ...
   fn visitWhileStmt(inout self, Whilestmt : StmtWhile) raises -> None: ...
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

struct StmtIfDelegate(CollectionElement):
   var ptr : AnyPointer[StmtIf]
   fn __init__(inout self, expr : StmtIf):
      self.ptr = AnyPointer[StmtIf]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtIf]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()

struct StmtWhileDelegate(CollectionElement):
   var ptr : AnyPointer[StmtWhile]
   fn __init__(inout self, expr : StmtWhile):
      self.ptr = AnyPointer[StmtWhile]().alloc(1)
      self.ptr.emplace_value(expr)
   fn __copyinit__(inout self, other : Self):
      self.ptr = AnyPointer[StmtWhile]().alloc(1)
      self.ptr.emplace_value(other.ptr[])
   fn __moveinit__(inout self, owned other : Self):
      self.ptr = other.ptr
   fn __del__(owned self):
      _ = self.ptr.take_value()
      self.ptr.free()


struct StmtExpression(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var expression : Self.ptr_t

   fn __init__(inout self, expression : Self.var_t):
      self.expression = expr_delegate_init(expression)

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
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var expression : Self.ptr_t

   fn __init__(inout self, expression : Self.var_t):
      self.expression = expr_delegate_init(expression)

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
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var name : Token
   var initializer : Optional[Self.ptr_t]

   fn __init__(inout self, name : Token, initializer : Optional[Self.var_t]):
      self.name = name
      self.initializer = None
      if initializer:
         self.initializer = expr_delegate_init(initializer.take())

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
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var statements : List[Self.Stmt]

   fn __init__(inout self, statements : List[Self.Stmt]):
      self.statements = statements

   fn __copyinit__(inout self, other : Self):
       self.statements = other.statements
   fn __moveinit__(inout self, owned other : Self):
      self.statements = other.statements
   fn __str__(self) -> String:
      return String("Block")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitBlockStmt(self)

struct StmtIf(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var condition : Self.ptr_t
   var then_stmt : Self.Stmt_ptr
   var else_stmt : Optional[Self.Stmt_ptr]

   fn __init__(inout self, condition : Self.var_t, then_stmt : Self.Stmt, else_stmt : Optional[Self.Stmt]):
      self.condition = expr_delegate_init(condition)
      self.then_stmt = stmt_delegate_init(then_stmt)
      self.else_stmt = None
      if else_stmt:
         self.else_stmt = stmt_delegate_init(else_stmt.take())

   fn __copyinit__(inout self, other : Self):
       self.condition = other.condition
       self.then_stmt = other.then_stmt
       self.else_stmt = other.else_stmt
   fn __moveinit__(inout self, owned other : Self):
      self.condition = other.condition
      self.then_stmt = other.then_stmt
      self.else_stmt = other.else_stmt
   fn __str__(self) -> String:
      return String("If")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitIfStmt(self)

struct StmtWhile(Stmt):
   alias ptr_t = ExprBinary.ptr_t
   alias var_t = ExprBinary.var_t
   alias Stmt = Variant[StmtExpression, StmtPrint, StmtVar, StmtBlock, StmtIf, StmtWhile]
   alias Stmt_ptr = Variant[StmtExpressionDelegate, StmtPrintDelegate, StmtVarDelegate, StmtBlockDelegate, StmtIfDelegate, StmtWhileDelegate]
   var condition : Self.ptr_t
   var body : Self.Stmt_ptr

   fn __init__(inout self, condition : Self.var_t, body : Self.Stmt):
      self.condition = expr_delegate_init(condition)
      self.body = stmt_delegate_init(body)

   fn __copyinit__(inout self, other : Self):
       self.condition = other.condition
       self.body = other.body
   fn __moveinit__(inout self, owned other : Self):
      self.condition = other.condition
      self.body = other.body
   fn __str__(self) -> String:
      return String("While")

   fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:
      return visitor.visitWhileStmt(self)
fn stmt_delegate_init(val : StmtExpression.Stmt) -> StmtExpression.Stmt_ptr:
   if val.isa[StmtExpression]():
      return StmtExpressionDelegate(val.get[StmtExpression]()[])
   elif val.isa[StmtPrint]():
      return StmtPrintDelegate(val.get[StmtPrint]()[])
   elif val.isa[StmtVar]():
      return StmtVarDelegate(val.get[StmtVar]()[])
   elif val.isa[StmtBlock]():
      return StmtBlockDelegate(val.get[StmtBlock]()[])
   elif val.isa[StmtIf]():
      return StmtIfDelegate(val.get[StmtIf]()[])
   else: 
      return StmtWhileDelegate(val.get[StmtWhile]()[])

