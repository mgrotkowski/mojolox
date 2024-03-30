from collections import Dict
from collections import Optional
from memory.anypointer import AnyPointer
from memory.unsafe import Pointer, Reference

from src.parser.expr import *
import src.parser.stmt as stmt
from src.lexer.token import Token, TokenType, LoxType, stringify_lox
from src.parser.parser import Stmt
from src.lexer.error_report import report


@value
struct Interpreter(Visitor, stmt.Visitor):
   var env : Environment

   fn __init__(inout self):
        self.env = Environment()

   fn interpert(inout self, inout expression : ExprBinary.var_t) raises:
        print("interpret")
        if expression.isa[ExprBinary]():
            print(stringify_lox(expression.get[ExprBinary]()[].accept[Interpreter, LoxType](self)))
        elif expression.isa[ExprGrouping]():
            print(stringify_lox(expression.get[ExprGrouping]()[].accept[Interpreter, LoxType](self)))
        elif expression.isa[ExprUnary]():
            print(stringify_lox(expression.get[ExprUnary]()[].accept[Interpreter, LoxType](self)))
        elif expression.isa[ExprAssign]():
            print(stringify_lox(expression.get[ExprAssign]()[].accept[Interpreter, LoxType](self)))
        else:
            print(stringify_lox(expression.get[ExprLiteral]()[].accept[Interpreter, LoxType](self)))
            
   fn interpret(inout self, inout statements : List[Stmt]) raises:
        for i in range(len(statements)):
            self.execute(statements[i])
            

   fn execute(inout self, inout statement : Stmt) raises:
        if statement.isa[stmt.StmtPrint]():
            statement.get[stmt.StmtPrint]()[].accept[Self](self)
        elif statement.isa[stmt.StmtExpression]():
            statement.get[stmt.StmtExpression]()[].accept[Self](self)
        elif statement.isa[stmt.StmtVar]():
            statement.get[stmt.StmtVar]()[].accept[Self](self)
        elif statement.isa[stmt.StmtBlock]():
            statement.get[stmt.StmtBlock]()[].accept[Self](self)

   fn execute_block(inout self, owned statements : List[Stmt], owned env : Environment) -> None:
        var env_previous = self.env
        try:
            self.env = env
            for i in range(len(statements)):
                self.execute(statements[i])
                # copy self.env.enclosing and delete, then reassign
                env_previous = self.env.enclosing[]
                _ = self.env
        finally:
            self.env = env_previous

   fn visitVarStmt(inout self, Varstmt : stmt.StmtVar) raises -> None:
        var name : String = Varstmt.name.lexeme.get[String]()[]
        var value : LoxType = None

        if Varstmt.initializer:
            value = self._evaluate(Varstmt.initializer.value())
        self.env.define(name, value)

   fn visitExpressionStmt(inout self, Expressionstmt : stmt.StmtExpression) raises -> None: 
        self._evaluate(Expressionstmt.expression)

   fn visitPrintStmt(inout self, Printstmt : stmt.StmtPrint) raises -> None: 
        print(stringify_lox(self._evaluate(Printstmt.expression)))

   fn visitBlockStmt(inout self, Blockstmt : stmt.StmtBlock) raises -> None: 
        self.execute_block(Blockstmt.statements, Environment(self.env))
        
   fn visitAssignExpr[V : Copyable = LoxType](inout self, Assignexpr : ExprAssign) raises -> V: 
        var value = self._evaluate(Assignexpr.value)
        self.env.assign(Assignexpr.name, value)
        return value

   fn visitVariableExpr[V : Copyable = LoxType](inout self, Variableexpr : ExprVariable) raises -> V: 
        return self.env.get(Variableexpr.name)

   fn visitBinaryExpr[V : Copyable = LoxType](inout self, Binaryexpr : ExprBinary) raises -> V: 
        var result_left = self._evaluate(Binaryexpr.left)
        var result_right = self._evaluate(Binaryexpr.right)
        
        if Binaryexpr.operator.type == TokenType.MINUS:
            self._check_number_operands(result_left, result_right)
            return LoxType(result_left.get[Float64]()[] - result_right.get[Float64]()[])
        if Binaryexpr.operator.type == TokenType.PLUS:
            if result_left.isa[Float64]() and result_right.isa[Float64]():
                return LoxType(result_left.get[Float64]()[] + result_right.get[Float64]()[])
            if result_left.isa[String]() and result_right.isa[String]():
                return LoxType(result_left.get[String]()[] + result_right.get[String]()[])
        if Binaryexpr.operator.type == TokenType.STAR:
            return LoxType(result_left.get[Float64]()[] * result_right.get[Float64]()[])
        if Binaryexpr.operator.type == TokenType.SLASH:
            return LoxType(result_left.get[Float64]()[] / result_right.get[Float64]()[])
        if Binaryexpr.operator.type == TokenType.GREATER:
            var result : Bool = result_left.get[Float64]()[] > result_right.get[Float64]()[]
            return LoxType(result)
        if Binaryexpr.operator.type == TokenType.GREATER_EQUAL:
            var result : Bool = result_left.get[Float64]()[] >= result_right.get[Float64]()[]
            return LoxType(result)
        if Binaryexpr.operator.type == TokenType.LESS:
            var result : Bool = result_left.get[Float64]()[] < result_right.get[Float64]()[]
            return LoxType(result)
        if Binaryexpr.operator.type == TokenType.LESS_EQUAL:
            var result : Bool = result_left.get[Float64]()[] <= result_right.get[Float64]()[]
            return LoxType(result)
        if Binaryexpr.operator.type == TokenType.BANG_EQUAL:
            return LoxType(not self._is_equal(result_left, result_right))
        if Binaryexpr.operator.type == TokenType.EQUAL_EQUAL:
            return LoxType(self._is_equal(result_left, result_right))

        if Binaryexpr.operator.type == TokenType.Q_MARK:
            if self._is_truthy(result_left):
                return self._evaluate(Binaryexpr.right.get[ExprBinaryDelegate]()[].ptr[].left)
            return self._evaluate(Binaryexpr.right.get[ExprBinaryDelegate]()[].ptr[].right)

        return LoxType(None)
   fn visitGroupingExpr[V : Copyable = LoxType](inout self, Groupingexpr : ExprGrouping) raises -> V: 
        return self._evaluate(Groupingexpr.expression)

   fn visitLiteralExpr[V : Copyable = LoxType](inout self, Literalexpr : ExprLiteral) raises -> V: 
        return Literalexpr.value

   fn visitUnaryExpr[V : Copyable = LoxType](inout self, Unaryexpr : ExprUnary) raises -> V: 
        var result_right = self._evaluate(Unaryexpr.right)

        if Unaryexpr.operator.type == TokenType.MINUS:
            return LoxType(-result_right.get[Float64]()[])
        if Unaryexpr.operator.type == TokenType.BANG:
            return LoxType(not self._is_truthy(result_right))

        return LoxType(None)

   fn _evaluate(inout self, borrowed expr : ExprBinary.ptr_t) raises -> LoxType:
        if expr.isa[ExprBinaryDelegate]():
            return expr.get[ExprBinaryDelegate]()[].ptr[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprGroupingDelegate]():
            return expr.get[ExprGroupingDelegate]()[].ptr[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprUnaryDelegate]():
            return expr.get[ExprUnaryDelegate]()[].ptr[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprVariableDelegate]():
            return expr.get[ExprVariableDelegate]()[].ptr[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprAssignDelegate]():
            return expr.get[ExprAssignDelegate]()[].ptr[].accept[Interpreter, LoxType](self)
        else:
            return expr.get[ExprLiteralDelegate]()[].ptr[].accept[Interpreter, LoxType](self)

   fn _is_truthy(self, obj : LoxType) -> Bool:
        if obj.isa[NoneType]():
            return False
        if obj.isa[Bool]():
            return obj.get[Bool]()[]
        
        return True

   fn _is_equal(self, obj1 : LoxType, obj2 : LoxType) -> Bool:
        if obj1.isa[NoneType]() and obj2.isa[NoneType]():
            return True
        if obj1.isa[NoneType]():
            return False

        if obj1.isa[Float64]() and obj2.isa[Float64]():
            return obj1.get[Float64]()[] == obj2.get[Float64]()[]

        if obj1.isa[String]() and obj2.isa[String]():
            return obj1.get[String]()[] == obj2.get[String]()[]

        if obj1.isa[Bool]() and obj2.isa[Bool]():
            return obj1.get[Bool]()[] == obj2.get[Bool]()[]

        return False

   fn _check_number_operand(self, obj1 : LoxType) raises:
        if not obj1.isa[Float64]():
            raise Error("Operand must be a number.")

   fn _check_number_operands(self, obj1 : LoxType, obj2 : LoxType) raises:
        if not obj1.isa[Float64]() or not obj2.isa[Float64]():
            raise Error("Both operands must be numbers")

   fn _stringify(self, obj : LoxType) -> String:
        if obj.isa[NoneType]():
            return str(obj.get[NoneType]()[])
        if obj.isa[Bool]():
            return str(obj.get[Bool]()[])
        if obj.isa[Float64]():
            var ret_str = str(obj.get[Float64]()[])
            try:
                var split = ret_str.split(".")
                if len(split[1]) == 1 and split[1] == "0":
                    ret_str = split[0]
            except Error:
                pass
            return ret_str

        return obj.get[String]()[]
    

struct Environment(Movable, Copyable):
   var variable_map : Dict[String, LoxType] 
   var enclosing : AnyPointer[Environment]

   fn __init__(inout self):
        self.variable_map = Dict[String, LoxType]()
        self.enclosing = AnyPointer[Environment]()

   fn __init__(inout self, env : Environment):
        self.variable_map = Dict[String, LoxType]()
        self.enclosing = AnyPointer[Environment]().alloc(1)
        self.enclosing.emplace_value(env)


   fn __moveinit__(inout self, owned other : Self):
        self.variable_map = other.variable_map^
        self.enclosing = AnyPointer[Environment]()

        if other.enclosing:
            self.enclosing = AnyPointer[Environment]().alloc(1)
            other.enclosing.move_into(self.enclosing)

        other.enclosing = AnyPointer[Environment]()

   fn __copyinit__(inout self, other : Self):
        self.variable_map = other.variable_map
        self.enclosing = AnyPointer[Environment]()

        if other.enclosing:
            self.enclosing = self.enclosing.alloc(1)
            self.enclosing.emplace_value(other.enclosing[])

   fn __del__(owned self):
        if self.enclosing:
            _ = self.enclosing.take_value()
            self.enclosing.free()

   fn define(inout self, name : String, value : LoxType):
        self.variable_map[name] = value

   fn get(inout self, name : Token) raises -> LoxType:
        var ret_val = self.variable_map.find(name.lexeme.get[String]()[])

        if ret_val:
            return ret_val.take()

        if self.enclosing:
            return self.enclosing[].get(name)

        print("Runtime Error: Undefined reference to variable " + name.lexeme.get[String]()[])
        raise Error("Undefined variable reference.")

   fn assign(inout self, name : Token, value : LoxType) raises -> None:
        var var_name = name.lexeme.get[String]()[]

        if self.variable_map.find(var_name):
            self.variable_map[var_name] = value
        elif self.enclosing: 
            self.enclosing[].assign(name, value)
        else:
            print("Runtime Error: Assignment to undeclared variable " + name.lexeme.get[String]()[])
            raise Error("Undeclared variable assignment.")

            


