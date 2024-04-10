from collections import List, Dict, Optional
from utils.variant import Variant

import src.parser.stmt as stmt
import src.parser.expr as expr
from src.parser.parser import Expr
from src.utils import SharedPtr
from src.lox_types import LoxType
from src.lexer.error_report import report, error

alias Stmt = stmt.StmtFunction.Stmt


@value
struct Resolver(expr.Visitor, stmt.Visitor):
    var scopes : List[Dict[String, Bool]]

    fn __init__(inout self):
        self.scopes = List[Dict[String, Bool]]()    

    fn visitBlockStmt(inout self, inout Blockstmt : stmt.StmtBlock) raises -> None: 
        self.begin_scope()
        self.resolve(Blockstmt.statements)
        self.end_scope()

    fn visitVarStmt(inout self, inout Varstmt : stmt.StmtVar) raises -> None: 
        var name = Varstmt.name.lexeme.get[String]()[]
        self.declare(name)
        if Varstmt.initializer:
            self.resolve(Varstmt.initializer[])
        self.define(name)
        
    fn visitFunctionStmt(inout self, inout Functionstmt : stmt.StmtFunction) raises -> None: 
        var name = Functionstmt.name.lexeme.get[String]()[]        
        self.declare(Functionstmt.name.lexeme.get[String]()[])
        self.define(Functionstmt.name.lexeme.get[String]()[])
        self.resolve_function(Functionstmt)

    fn visitExpressionStmt(inout self, inout Expressionstmt : stmt.StmtExpression) raises -> None: 
        self.resolve(Expressionstmt.expression[])

    fn visitPrintStmt(inout self, inout Printstmt : stmt.StmtPrint) raises -> None: 
        self.resolve(Printstmt.expression[])

    fn visitIfStmt(inout self, inout Ifstmt : stmt.StmtIf) raises -> None: 
        self.resolve(Ifstmt.condition[])
        self.resolve(Ifstmt.then_stmt[])
        if Ifstmt.else_stmt:
            self.resolve(Ifstmt.else_stmt[])

    fn visitWhileStmt(inout self, inout Whilestmt : stmt.StmtWhile) raises -> None: 
        self.resolve(Whilestmt.condition[])
        self.resolve(Whilestmt.body[])

    fn visitReturnStmt(inout self, inout Returnstmt : stmt.StmtReturn) raises -> None: 
        if Returnstmt.value:
            self.resolve(Returnstmt.value)
        
    fn visitVariableExpr[V : Copyable = String](inout self, inout Variableexpr : expr.ExprVariable) raises -> V: 
        if len(self.scopes) and self.scopes[len(self.scopes) - 1].find(Variableexpr.name.lexeme.get[String]()[]).or_else(True) == False:
            error(Variableexpr.name.line, "Can't read local variable in its own initializer.")
        self.resolve_local(Variableexpr, Variableexpr.name.lexeme.get[String]()[])
        return String("")

    fn visitAssignExpr[V : Copyable = String](inout self, inout Assignexpr : expr.ExprAssign) raises -> V: 
        self.resolve(Assignexpr.value[])
        self.resolve_local(Assignexpr, Assignexpr.name.lexeme.get[String]()[])
        return String("")

    fn visitBinaryExpr[V : Copyable = String](inout self, Binaryexpr : expr.ExprBinary) raises -> V: 
        self.resolve(Binaryexpr.left[])
        self.resolve(Binaryexpr.right[])
        return String("")

    fn visitGroupingExpr[V : Copyable = String](inout self, Groupingexpr : expr.ExprGrouping) raises -> V: 
        self.resolve(Groupingexpr.expression[])
        return String("")

    fn visitLiteralExpr[V : Copyable = String](inout self, Literalexpr : expr.ExprLiteral) raises -> V: 
        return String("")

    fn visitUnaryExpr[V : Copyable = String](inout self, Unaryexpr : expr.ExprUnary) raises -> V: 
        self.resolve(Unaryexpr.right[])
        return String("")

    fn visitLogicalExpr[V : Copyable = String](inout self, Logicalexpr : expr.ExprLogical) raises -> V: 
        self.resolve(Logicalexpr.left[])
        self.resolve(Logicalexpr.right[])
        return String("")

    fn visitCallExpr[V : Copyable = String](inout self, inout Callexpr : expr.ExprCall) raises -> V: 
        self.resolve(Callexpr.callee[])
        for arg in Callexpr.arguments:
            self.resolve(arg[])
        return String("")

    fn resolve_function(inout self, inout func : stmt.StmtFunction) raises: 
        self.begin_scope()
        for param in func.params:
            self.declare(param[].lexeme.get[String]()[])
            self.define(param[].lexeme.get[String]()[])
        self.resolve(func.body)
        self.end_scope()

    fn resolve_local(inout self, inout expression : expr.ExprAssign, name : String):
        for i in range(len(self.scopes) - 1, -1, -1):
            if self.scopes[i].find(name):
                expression.distance = UInt64(len(self.scopes) - i - 1)
                return None

    fn resolve_local(inout self, inout expression : expr.ExprVariable, name : String):
        for i in range(len(self.scopes) - 1, -1, -1):
            if self.scopes[i].find(name):
                expression.distance = UInt64(len(self.scopes) - i - 1)
                return None
    
    fn begin_scope(inout self) -> None:
        self.scopes.append(Dict[String, Bool]())

    fn end_scope(inout self) -> None:
        self.scopes.pop_back()

    fn declare(inout self, name : String):
        if len(self.scopes):
            self.scopes[len(self.scopes) - 1][name] = False

    fn define(inout self, name : String):
        if len(self.scopes):
            self.scopes[len(self.scopes) - 1][name] = True

    fn resolve(inout self, inout statements : List[Stmt]) raises:
        var iter = 0 
        for statement in statements:
            self.resolve(statement[])

    fn resolve(inout self, inout statement : Stmt) raises:
        if statement.isa[stmt.StmtPrint]():
            statement.get[stmt.StmtPrint]()[].accept[Self](self)
        elif statement.isa[stmt.StmtExpression]():
            statement.get[stmt.StmtExpression]()[].accept[Self](self)
        elif statement.isa[stmt.StmtVar]():
            statement.get[stmt.StmtVar]()[].accept[Self](self)
        elif statement.isa[stmt.StmtBlock]():
            statement.get[stmt.StmtBlock]()[].accept[Self](self)
        elif statement.isa[stmt.StmtIf]():
            statement.get[stmt.StmtIf]()[].accept[Self](self)
        elif statement.isa[stmt.StmtWhile]():
            statement.get[stmt.StmtWhile]()[].accept[Self](self)
        elif statement.isa[stmt.StmtFunction]():
            statement.get[stmt.StmtFunction]()[].accept[Self](self)
        elif statement.isa[stmt.StmtReturn]():
            statement.get[stmt.StmtReturn]()[].accept[Self](self)


    fn resolve(inout self, inout statement : Expr) raises -> String:
        if statement.isa[expr.ExprBinary]():
            return statement.get[expr.ExprBinary]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprGrouping]():
            return statement.get[expr.ExprGrouping]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprUnary]():
            return statement.get[expr.ExprUnary]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprVariable]():
            return statement.get[expr.ExprVariable]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprAssign]():
            return statement.get[expr.ExprAssign]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprLogical]():
            return statement.get[expr.ExprLogical]()[].accept[Resolver, String](self)
        elif statement.isa[expr.ExprCall]():
            return statement.get[expr.ExprCall]()[].accept[Resolver, String](self)
        else:
            return statement.get[expr.ExprLiteral]()[].accept[Resolver, String](self)

    fn resolve(inout self, inout statement : Optional[Expr]) raises -> String:
        if statement.value().isa[expr.ExprBinary]():
            return statement.value().get[expr.ExprBinary]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprGrouping]():
            return statement.value().get[expr.ExprGrouping]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprUnary]():
            return statement.value().get[expr.ExprUnary]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprVariable]():
            return statement.value().get[expr.ExprVariable]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprAssign]():
            return statement.value().get[expr.ExprAssign]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprLogical]():
            return statement.value().get[expr.ExprLogical]()[].accept[Resolver, String](self)
        elif statement.value().isa[expr.ExprCall]():
            return statement.value().get[expr.ExprCall]()[].accept[Resolver, String](self)
        else:
            return statement.value().get[expr.ExprLiteral]()[].accept[Resolver, String](self)


