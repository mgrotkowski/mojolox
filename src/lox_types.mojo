from utils.variant import Variant
from collections import List
from time import now
from src.interpreter.interpreter import Interpreter, Environment
from src.parser.stmt import StmtFunction
from src.utils import SharedPtr


alias LoxBaseType = Variant[String, Float64, Bool, NoneType]
alias LoxCallable = Variant[Clock, LoxFunction]
alias LoxType = Variant[LoxBaseType, LoxCallable]



@value
struct Clock(CollectionElement):
    fn arity(self) -> Int:
        return 0
    fn call(inout self, inout interpreter : Interpreter, inout args : List[LoxType]) -> LoxType: 
        return LoxBaseType(Float64(now()) / 1e9)
    fn __str__(self) -> String:
        return "<native fn>"


@value
struct LoxFunction(CollectionElement):
    alias Environment_ptr = SharedPtr[Environment]
    var declaration : StmtFunction
    var closure : Self.Environment_ptr

    fn __init__(inout self, declaration : StmtFunction, closure : Self.Environment_ptr):
        self.declaration = declaration
        self.closure = closure

    fn arity(self) -> Int:
        return len(self.declaration.params)

    fn call(inout self, inout interpreter : Interpreter, inout args : List[LoxType]) -> LoxType: 
        var env = Environment(self.closure)
        
        for i in range(len(self.declaration.params)):
            var lexeme = self.declaration.params[i].lexeme
            env.define(lexeme.get[String]()[], args[i])
        try:
            interpreter.execute_block(self.declaration.body, env)
        except Error:
            if str(Error) == String("return"):
                return interpreter.ret_val

        return LoxBaseType(None)
    
    fn __str__(self) -> String:
        return "<fn " + self.declaration.name.lexeme.get[String]()[] + ">"

