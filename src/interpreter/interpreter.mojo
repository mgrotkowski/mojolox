from collections import Dict
from collections import Optional
from memory.anypointer import AnyPointer
from memory.unsafe import Pointer, Reference

from src.parser.expr import *
import src.parser.stmt as stmt
from src.lexer.token import Token, TokenType
from src.utils import stringify_lox, SharedPtr
from src.lox_types import LoxType, LoxCallable, Clock, LoxFunction, LoxBaseType
from src.parser.parser import Stmt
from src.lexer.error_report import report, error



alias Expr = ExprBinary.Expr

@value
struct Interpreter(Visitor, stmt.Visitor):
   var globals : SharedPtr[Environment]
   var env : SharedPtr[Environment]
   var ret_val : LoxType

   fn __init__(inout self):
        self.globals = SharedPtr[Environment](Environment())
        self.globals.data[].define("clock", LoxCallable(Clock()))
        self.env = self.globals
        self.ret_val = LoxType(LoxBaseType(None))

            
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
        elif statement.isa[stmt.StmtIf]():
            statement.get[stmt.StmtIf]()[].accept[Self](self)
        elif statement.isa[stmt.StmtWhile]():
            statement.get[stmt.StmtWhile]()[].accept[Self](self)
        elif statement.isa[stmt.StmtFunction]():
            statement.get[stmt.StmtFunction]()[].accept[Self](self)
        elif statement.isa[stmt.StmtReturn]():
            statement.get[stmt.StmtReturn]()[].accept[Self](self)

   fn execute_block(inout self, owned statements : List[Stmt], env : SharedPtr[Environment]) raises -> None:
        var env_previous = self.env
        try:
            self.env = env
            for i in range(len(statements)):
                self.execute(statements[i])
        finally:
            self.env = env_previous


   fn visitVarStmt(inout self, inout Varstmt : stmt.StmtVar) raises -> None:
        var name : String = Varstmt.name.lexeme.get[String]()[]
        var value : LoxType = LoxBaseType(None)

        if Varstmt.initializer:
            value = self._evaluate(Varstmt.initializer[])
        self.env.data[].define(name, value)

   fn visitExpressionStmt(inout self, inout Expressionstmt : stmt.StmtExpression) raises -> None: 
        self._evaluate(Expressionstmt.expression[])

   fn visitPrintStmt(inout self, inout Printstmt : stmt.StmtPrint) raises -> None: 
        print(stringify_lox(self._evaluate(Printstmt.expression[])))

   fn visitBlockStmt(inout self, inout Blockstmt : stmt.StmtBlock) raises -> None: 
        self.execute_block(Blockstmt.statements, SharedPtr[Environment](Environment(self.env)))

   fn visitIfStmt(inout self, inout Ifstmt : stmt.StmtIf) raises -> None: 
        if self._is_truthy(self._evaluate(Ifstmt.condition[])):
            self.execute(Ifstmt.then_stmt[])
        elif Ifstmt.else_stmt:
            self.execute(Ifstmt.else_stmt[])

   fn visitWhileStmt(inout self, inout Whilestmt : stmt.StmtWhile) raises -> None: 
        while self._is_truthy(self._evaluate(Whilestmt.condition[])):
            self.execute(Whilestmt.body[])

   fn visitFunctionStmt(inout self, inout Functionstmt : stmt.StmtFunction) raises -> None: 
        var function = LoxFunction(Functionstmt, self.env)
        self.env.data[].define(function.declaration.name.lexeme.get[String]()[], LoxCallable(function))

   fn visitReturnStmt(inout self, inout Returnstmt : stmt.StmtReturn) raises -> None: 
        var value = LoxType(LoxBaseType(None))
        if Returnstmt.value:
            var evaluate_val = Returnstmt.value.take()
            value = self._evaluate(evaluate_val)
        self.ret_val = value
        raise Error("return")


   fn visitCallExpr[V : Copyable = LoxType](inout self, inout Callexpr : ExprCall) raises -> V: 
        var args = List[LoxType]()
        var callee = self._evaluate(Callexpr.callee[])

        for arg in Callexpr.arguments:
            args.append(self._evaluate(arg[]))

        if not callee.isa[LoxCallable]():
            error(Callexpr.paren.line, "Runtime Error : Can only call functions and classes.")


        var arity = self._arity(callee.get[LoxCallable]()[])
        if len(args) != arity:
            error(Callexpr.paren.line, "Runtime Error : Expected " + str(arity) + " arguments, got " + str(len(args)) + ".")

        return self._call(callee.get[LoxCallable]()[], args)        

   fn visitLogicalExpr[V : Copyable = LoxType](inout self, Logicalexpr : ExprLogical) raises -> V: 
        var left_val = self._evaluate(Logicalexpr.left[])
        if Logicalexpr.operator.type == TokenType.OR:
            if self._is_truthy(left_val):
                return left_val
        else:
            if not self._is_truthy(left_val):
                return left_val
        return self._evaluate(Logicalexpr.right[])

   fn visitAssignExpr[V : Copyable = LoxType](inout self, inout Assignexpr : ExprAssign) raises -> V: 
        var value = self._evaluate(Assignexpr.value[])
        #self.env.data[].assign(Assignexpr.name, value)
        if Assignexpr.distance:
            self.env.data[].assign_at(Assignexpr.distance.value(), Assignexpr.name, value)
        else:
            self.globals.data[].assign(Assignexpr.name, value)
        return value

   fn visitVariableExpr[V : Copyable = LoxType](inout self, inout Variableexpr : ExprVariable) raises -> V: 
        return self._lookup_variable(Variableexpr.name, Variableexpr)

   fn visitBinaryExpr[V : Copyable = LoxType](inout self, Binaryexpr : ExprBinary) raises -> V: 
        var result_left = self._evaluate(Binaryexpr.left[]).get[LoxBaseType]()[]
        var result_right = self._evaluate(Binaryexpr.right[]).get[LoxBaseType]()[]
        
        if Binaryexpr.operator.type == TokenType.MINUS:
            self._check_number_operands(result_left, result_right)
            return LoxType(LoxBaseType(result_left.get[Float64]()[] - result_right.get[Float64]()[]))
        if Binaryexpr.operator.type == TokenType.PLUS:
            if result_left.isa[Float64]() and result_right.isa[Float64]():
                return LoxType(LoxBaseType(result_left.get[Float64]()[] + result_right.get[Float64]()[]))
            if result_left.isa[String]() and result_right.isa[String]():
                return LoxType(LoxBaseType(result_left.get[String]()[] + result_right.get[String]()[]))
        if Binaryexpr.operator.type == TokenType.STAR:
            return LoxType(LoxBaseType(result_left.get[Float64]()[] * result_right.get[Float64]()[]))
        if Binaryexpr.operator.type == TokenType.SLASH:
            return LoxType(LoxBaseType(result_left.get[Float64]()[] / result_right.get[Float64]()[]))
        if Binaryexpr.operator.type == TokenType.GREATER:
            var result : Bool = result_left.get[Float64]()[] > result_right.get[Float64]()[]
            return LoxType(LoxBaseType(result))
        if Binaryexpr.operator.type == TokenType.GREATER_EQUAL:
            var result : Bool = result_left.get[Float64]()[] >= result_right.get[Float64]()[]
            return LoxType(LoxBaseType(result))
        if Binaryexpr.operator.type == TokenType.LESS:
            var result : Bool = result_left.get[Float64]()[] < result_right.get[Float64]()[]
            return LoxType(LoxBaseType(result))
        if Binaryexpr.operator.type == TokenType.LESS_EQUAL:
            var result : Bool = result_left.get[Float64]()[] <= result_right.get[Float64]()[]
            return LoxType(LoxBaseType(result))
        if Binaryexpr.operator.type == TokenType.BANG_EQUAL:
            return LoxType(LoxBaseType(not self._is_equal(result_left, result_right)))
        if Binaryexpr.operator.type == TokenType.EQUAL_EQUAL:
            return LoxType(LoxBaseType(self._is_equal(result_left, result_right)))

        if Binaryexpr.operator.type == TokenType.Q_MARK:
            if self._is_truthy(result_left):
                return self._evaluate(Binaryexpr.right[].get[ExprBinary]()[].left[])
            return self._evaluate(Binaryexpr.right[].get[ExprBinary]()[].right[])

        return LoxType(LoxBaseType(None))

   fn visitGroupingExpr[V : Copyable = LoxType](inout self, Groupingexpr : ExprGrouping) raises -> V: 
        return self._evaluate(Groupingexpr.expression[])

   fn visitLiteralExpr[V : Copyable = LoxType](inout self, Literalexpr : ExprLiteral) raises -> V: 
        return LoxType(Literalexpr.value)

   fn visitUnaryExpr[V : Copyable = LoxType](inout self, Unaryexpr : ExprUnary) raises -> V: 
        var result_right = self._evaluate(Unaryexpr.right[]).get[LoxBaseType]()[]

        if Unaryexpr.operator.type == TokenType.MINUS:
            return LoxType(LoxBaseType(-result_right.get[Float64]()[]))
        if Unaryexpr.operator.type == TokenType.BANG:
            return LoxType(LoxBaseType(not self._is_truthy(result_right)))

        return LoxType(LoxBaseType(None))
   
   fn _lookup_variable(inout self, name : Token, expr : ExprVariable) raises -> LoxType:
        if expr.distance:
            return self.env.data[].get_at(expr.distance.value(), name)
        else:
            return self.globals.data[].get(name)

   fn _evaluate(inout self, inout expr : Expr) raises -> LoxType:
        if expr.isa[ExprBinary]():
            return expr.get[ExprBinary]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprGrouping]():
            return expr.get[ExprGrouping]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprUnary]():
            return expr.get[ExprUnary]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprVariable]():
            return expr.get[ExprVariable]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprAssign]():
            return expr.get[ExprAssign]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprLogical]():
            return expr.get[ExprLogical]()[].accept[Interpreter, LoxType](self)
        elif expr.isa[ExprCall]():
            return expr.get[ExprCall]()[].accept[Interpreter, LoxType](self)
        else:
            return expr.get[ExprLiteral]()[].accept[Interpreter, LoxType](self)

   fn _is_truthy(self, obj : LoxType) -> Bool:
        var object = obj.get[LoxBaseType]()[]
        if object.isa[NoneType]():
            return False
        if object.isa[Bool]():
            return object.get[Bool]()[]
        
        return True

   fn _is_equal(self, obj1 : LoxBaseType, obj2 : LoxBaseType) -> Bool:
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

   fn _check_number_operand(self, obj1 : LoxBaseType) raises:
        if not obj1.isa[Float64]():
            raise Error("Operand must be a number.")

   fn _check_number_operands(self, obj1 : LoxBaseType, obj2 : LoxBaseType) raises:
        if not obj1.isa[Float64]() or not obj2.isa[Float64]():
            raise Error("Both operands must be numbers")

   fn _call(inout self, inout callee : LoxCallable, inout args : List[LoxType]) -> LoxType:
        if callee.isa[Clock]():
            return callee.get[Clock]()[].call(self, args)
        elif callee.isa[LoxFunction]():
            return callee.get[LoxFunction]()[].call(self, args)
        return LoxBaseType(None)

   fn _arity(inout self, inout callee : LoxCallable) -> Int:
        if callee.isa[Clock]():
            return callee.get[Clock]()[].arity()
        if callee.isa[LoxFunction]():
            return callee.get[LoxFunction]()[].arity()
        return 0


struct Environment(CollectionElement):
   var variable_map : Dict[String, LoxType] 
   var enclosing : SharedPtr[Environment]

   fn __init__(inout self, env_ptr : SharedPtr[Environment]):
        self.variable_map = Dict[String, LoxType]()
        self.enclosing = env_ptr

   fn __init__(inout self):
        self.variable_map = Dict[String, LoxType]()
        self.enclosing = SharedPtr[Environment]()

   fn __copyinit__(inout self, other : Self):
        self.variable_map = other.variable_map
        self.enclosing = other.enclosing

   fn __moveinit__(inout self, owned other : Self):
        self.variable_map = other.variable_map^
        self.enclosing = other.enclosing^

    
   fn define(inout self, name : String, value : LoxType):
        self.variable_map[name] = value

   fn get(inout self, name : Token) raises -> LoxType:
        var ret_val = self.variable_map.find(name.lexeme.get[String]()[])

        if ret_val:
            return ret_val.take()

        if self.enclosing.data:
            return self.enclosing.data[].get(name)

        print("Runtime Error: Undefined reference to variable " + name.lexeme.get[String]()[])
        raise Error("Undefined variable reference.")

   fn get_at(inout self, distance : UInt64, name : Token) raises -> LoxType:
        if not distance:
            return self.get(name)

        var env = self.enclosing

        for i in range(distance):
            env = env.data[].enclosing 

        return env.data[].get(name)

   fn assign(inout self, name : Token, value : LoxType) raises -> None:
        var var_name = name.lexeme.get[String]()[]

        if self.variable_map.find(var_name):
            self.variable_map[var_name] = value
        elif self.enclosing.data:
            self.enclosing.data[].assign(name, value)
        else:
            print("Runtime Error: Assignment to undeclared variable " + name.lexeme.get[String]()[])
            raise Error("Undeclared variable assignment.")

   fn assign_at(inout self, distance : UInt64, name : Token, value : LoxType) raises -> None:
        var env = self.enclosing

        for i in range(distance):
            env = env.data[].enclosing 

        env.data[].assign(name, value)

            


            


