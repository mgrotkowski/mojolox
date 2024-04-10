from collections.optional import Optional
from collections import List

alias TAB = "   "
alias LINE_BREAK = print()

# CONSTANT: Expr trait and Visitor struct 
# VARIABLE: Expr structs and Visitor visit methods

def variant_gen_fn(derived_classes : List[String], stmt : Bool = False):
    var fn_begin : String = "expr"
    var var_t : String = "var_t"
    var ptr_t : String = "ptr_t"
    if stmt:
        fn_begin = "stmt"
        var_t = "Stmt"
        ptr_t = "Stmt_ptr"

    print("fn " + fn_begin + "_delegate_init(val : " + derived_classes[0] + "." + var_t + ") -> " + derived_classes[0] + "." + ptr_t + ":")
    print(TAB + "if " + "val" + ".isa[" + derived_classes[0] + "]():")
    print(TAB + TAB + "return" + " " + derived_classes[0] + "Delegate",  end = "")
    print("(" + "val" + ".get[" + derived_classes[0] + "]()[])")

    for idx in range(1, len(derived_classes) - 1):
        print(TAB + "elif " + "val" + ".isa[" + derived_classes[idx] + "]():")
        print(TAB + TAB + "return" + " " + derived_classes[idx] + "Delegate",  end = "")
        print("(" + "val" + ".get[" + derived_classes[idx] + "]()[])")

    print(TAB + "else: ")
    print(TAB + TAB + "return" + " " + derived_classes[len(derived_classes) - 1] + "Delegate",  end = "")
    print("(" + "val" + ".get[" + derived_classes[len(derived_classes) - 1] + "]()[])")
    print()


def define_expr(base_name : String, types : List[String], exprs : Optional[List[String]] = None, stmt : Bool = False):
    print("trait " + base_name + "(CollectionElement):")
    print(TAB, end = "")
    if not stmt:
        print("fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U: ...")
    else:
        print("fn accept[V : Visitor](inout self, inout visitor : V) raises -> None: ...")

    var var_t : String = "Variant["
    var class_names = List[String]()

    for i in range(len(types)):
        var name : String = types[i].split(":")[0].strip()

        var_t += base_name + name + ", "
        class_names.append(base_name + name)

    if exprs:
        class_names = exprs.value()
    
    for i in range(len(types)):
        print()
        var names : List[String] = types[i].split(":")
        var class_name = names[0].strip()
        var fields : List[String] = names[1].split(",")

        print("struct " + base_name + class_name + "(" + base_name + "):", flush = True)

        if not stmt:
            print(TAB + "alias Expr = " + var_t[:-2] + "]")
        else:
            print(TAB + "alias Stmt = " + var_t[:-2] + "]")

        for j in range(len(fields)):
            print(TAB, end = "")
            var field_names : List[String] = fields[j].split(" ")
            if "Optional" in field_names[1] and "AnyPointer" in field_names[1]:
                print("var " + field_names[2] + " : " + field_names[1].replace("Optional[", "")[:-1], end = "")
            else:
                print("var " + field_names[2] + " : " + field_names[1])
        print()
        print(TAB + "fn __init__(inout self", end = "", flush = True)
        for field in fields:
            print(", ", end = "")
            var field_names : List[String] = field[].split(" ")
            if field_names[1] == "AnyPointer[Self.Expr]":
                print(field_names[2] + " : " + "Self.Expr", end = "")
            elif field_names[1] == "AnyPointer[Expr]":
                print(field_names[2] + " : " + "Expr", end = "")
            elif field_names[1] == "AnyPointer[Self.Stmt]":
                print(field_names[2] + " : " + "Self.Stmt", end = "")
            elif "Optional" in field_names[1] and "AnyPointer" in field_names[1]:
                print(field_names[2] + " : " + field_names[1].replace("[AnyPointer", "")[:-1], end = "")
            else:
                print(field_names[2] + " : " + field_names[1], end = "")
        print("):")


        for field in fields:
            var field_names : List[String] = field[].split(" ")
            var opt_end = ""
            if "Optional" in field_names[1]:
                if "AnyPointer" in field_names[1]:
                    print(TAB + TAB + "self." + field_names[2] + " = " + field_names[1].replace("Optional[", "")[:-1] + "()")
                else:
                    print(TAB + TAB + "self." + field_names[2] + " = None")
                print(TAB + TAB + "if " + field_names[2] + ":")
                if "AnyPointer" in field_names[1]:
                    print(TAB + TAB + TAB + "self." + field_names[2] + " = " + "self." + field_names[2] + ".alloc(1)")
                    print(TAB + TAB + TAB + "self." + field_names[2] + ".emplace_value(" + field_names[2] + ".take())")
                else:
                    print(TAB + TAB + TAB + "self." + field_names[2] + " = " + field_names[2] + ".take()")

            elif "AnyPointer" in field_names[1]:
                print(TAB + TAB + "self." + field_names[2] + " = " + field_names[1] + "().alloc(1)")
                print(TAB + TAB + "self." + field_names[2] + ".emplace_value(" + field_names[2] + ")")
            else:
                print(TAB + TAB + "self." + field_names[2] + " = " + field_names[2])
        print() 

        print(TAB + "fn __copyinit__(inout self, other : Self):")
        for field in fields:
            var field_names = field[].split(" ")
            if  "AnyPointer" in field_names[1]:
                var type = field_names[1]
                if "Optional" in field_names[1]:
                    type = field_names[1].replace("Optional[", "")[:-1]  
                print(TAB + TAB + "self." + field_names[2] + " = " + type + "()")
                print(TAB + TAB + "if other." + field_names[2] + ":")
                print(TAB + TAB + TAB +  "self." + field_names[2] + " = " + type + "().alloc(1)")
                print(TAB + TAB + TAB + "self." + field_names[2] + ".emplace_value(other." + field_names[2] + "[])")
            else:
                print(TAB + TAB + "self." + field_names[2] + " = " + "other." + field_names[2])

        print(TAB + "fn __moveinit__(inout self, owned other : Self):")
        for field in fields:
            var field_names = field[].split(" ")
            print(TAB + TAB + "self." + field_names[2] + " = " + "other." + field_names[2])
            if  "AnyPointer" in field_names[1]:
                if "Optional" in field_names[1]:
                    print(TAB + TAB + "other." + field_names[2] + " = " + field_names[1].replace("Optional[", "")[:-1] + "()")
                else:
                    print(TAB + TAB + "other." + field_names[2] + " = " + field_names[1] + "()")

        print(TAB + "fn __del__(owned  self):")
        var has_anyptr = False
        for field in fields:
            var field_names = field[].split(" ")
            if  "AnyPointer" in field_names[1]:
                has_anyptr = True
                print(TAB + TAB + "if self." + field_names[2] + ":")
                print(TAB + TAB + TAB + "_ = self." + field_names[2] + ".take_value()")
                print(TAB + TAB + TAB + "self." + field_names[2] + ".free()")
        if not has_anyptr:
            print(TAB + TAB + TAB + "pass")


        print(TAB + "fn __str__(self) -> String:")
        var hit = False
        for field in fields:
            var name_type = field[].split(" ")
            var name = name_type[2].strip()
            var type = name_type[1].strip()

            if type == "String":
                print(TAB + TAB + "return self." +  name)
                hit = True
                break
            if type == "Token":
                print(TAB + TAB + "return str(self." +  name + ")")
                hit = True
                break
            if type == "LoxType":
                print(TAB + TAB + "return stringify_lox(self." +  name + ")")
                hit = True
                break


        if not hit:
            print(TAB + TAB + 'return String("' + class_name + '")')
                 
        print()
        if not stmt:
            print(TAB + "fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U:")
            print(TAB + TAB + "return visitor.visit" + class_name + base_name + "[U]" + "(self)")
        else:
            print(TAB + "fn accept[V : Visitor](inout self, inout visitor : V) raises -> None:")
            print(TAB + TAB + "return visitor.visit" + class_name + base_name + "(self)")



def define_visitor(base_name : String, types : List[String], stmt : Bool = False): 
    print("trait Visitor:")
    for i in range(len(types)):
        type_name = types[i].split(":")[0].strip()
        print(TAB, end = "")
        if not stmt:
            print("fn visit" + type_name +  base_name + "[V : Copyable]" +  "(inout self, " + type_name + base_name.lower() + " : " + base_name + type_name + ") raises -> V: ...") 
        else:
            print("fn visit" + type_name +  base_name + "(inout self, " + type_name + base_name.lower() + " : " + base_name + type_name + ") raises -> None: ...") 

def print_headers(stmt : Bool = False, expr_vec : Optional[List[String]] = None):
    print("from src.lexer.token import Token, LoxType, stringify_lox")
    print("from collections.optional import Optional")
    print("from memory.anypointer import AnyPointer")
    print("from utils.variant import Variant\n")
    if stmt:
        print("from src.parser.expr import ", end = "")
        for i in range(len(expr_vec.value()) - 1):
            print(expr_vec.value()[i] + ", ", end = "")
        print(expr_vec.value()[len(expr_vec.value()) - 1])
        print("alias Expr = " + expr_vec.value()[0] + ".Expr")
    LINE_BREAK



def expr_gen():
    var vec = List[String]()
    vec.append("Binary   : AnyPointer[Self.Expr] left, Token operator, AnyPointer[Self.Expr] right")
    vec.append("Grouping : AnyPointer[Self.Expr] expression")
    vec.append("Literal  : LoxType value")
    vec.append("Unary    : Token operator, AnyPointer[Self.Expr] right")
    vec.append("Variable : Token name")
    vec.append("Assign   : Token name, AnyPointer[Self.Expr] value")
    vec.append("Logical  : AnyPointer[Self.Expr] left, Token operator, AnyPointer[Self.Expr] right")
    vec.append("Call     : AnyPointer[Self.Expr] callee, Token paren, List[Self.Expr] arguments")

    print_headers()
    define_visitor("Expr", vec)
    LINE_BREAK
    define_expr("Expr", vec)
    


def get_classes(str_list : List[String], base_name : String) -> List[String]:
    var ret_list = List[String]()

    for str in str_list:
        ret_list.append(base_name + str[].split(":")[0].strip())

    return ret_list
         
    

def stmt_gen():
    var stmt_vec = List[String]()
    var expr_vec = List[String]()

    stmt_vec.append("Expression  : AnyPointer[Expr] expression")
    stmt_vec.append("Print       : AnyPointer[Expr] expression")
    stmt_vec.append("Var         : Token name, Optional[AnyPointer[Expr]] initializer")
    stmt_vec.append("Block       : List[Self.Stmt] statements")
    stmt_vec.append("If          : AnyPointer[Expr] condition, AnyPointer[Self.Stmt] then_stmt, Optional[AnyPointer[Self.Stmt]] else_stmt")
    stmt_vec.append("While       : AnyPointer[Expr] condition, AnyPointer[Self.Stmt] body")
    stmt_vec.append("Function    : Token name, List[Token] params, List[Self.Stmt] body")
    stmt_vec.append("Return      : Token keyword, Optional[Expr] value")

    expr_vec.append("Binary   : AnyPointer[Self.Expr] left, Token operator, AnyPointer[Expr_t] right")
    expr_vec.append("Grouping : AnyPointer[Self.Expr] expression")
    expr_vec.append("Literal  : LoxType value")
    expr_vec.append("Unary    : Token operator, AnyPointer[Self.Expr] right")
    expr_vec.append("Variable : Token name")
    expr_vec.append("Assign   : Token name, AnyPointer[Self.Expr] value")
    expr_vec.append("Logical  : AnyPointer[Self.Expr] left, Token operator, AnyPointer[Expr_t] right")
    expr_vec.append("Call     : AnyPointer[Self.Expr] callee, Token paren, List[Self.Expr] arguments")

    expr_vec = get_classes(expr_vec, "Expr")    
    print_headers(True, expr_vec)
    define_visitor("Stmt", stmt_vec, stmt = True)
    LINE_BREAK


    define_expr("Stmt", stmt_vec, expr_vec, stmt = True)
    
    

def main():
    stmt_gen()
    #expr_gen()
