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

    var ptr_t : String = "Variant["
    var var_t : String = "Variant["
    var class_names = List[String]()

    for i in range(len(types)):
        var name : String = types[i].split(":")[0].strip()

        ptr_t += base_name + name + "Delegate, "
        var_t += base_name + name + ", "
        class_names.append(base_name + name)

        print("struct " + base_name + name + "Delegate(CollectionElement):")
        print(TAB + "var ptr : AnyPointer[" + base_name + name + "]")
        print(TAB + "fn __init__(inout self, expr : "+ base_name +name + "):")
        print(TAB + TAB +  "self.ptr = AnyPointer[" + base_name + name + "]().alloc(1)")
        print(TAB + TAB + "self.ptr.emplace_value(expr)")

        print(TAB + "fn __copyinit__(inout self, other : Self):")
        print(TAB + TAB + "self.ptr = AnyPointer[" + base_name + name + "]().alloc(1)")
        print(TAB + TAB + "self.ptr.emplace_value(other.ptr[])")

        print(TAB + "fn __moveinit__(inout self, owned other : Self):")
        print(TAB + TAB + "self.ptr = other.ptr")

        print(TAB + "fn __del__(owned self):")
        print(TAB + TAB + "_ = self.ptr.take_value()")
        print(TAB + TAB + "self.ptr.free()")
        print()

    if exprs:
        class_names = exprs.value()
    
    for i in range(len(types)):
        print()
        var names : List[String] = types[i].split(":")
        var class_name = names[0].strip()
        var fields : List[String] = names[1].split(",")

        print("struct " + base_name + class_name + "(" + base_name + "):")

        if not stmt:
            print(TAB + "alias ptr_t = " + ptr_t[:-2] + "]")
            print(TAB + "alias var_t = " + var_t[:-2] + "]")
        else:
            print(TAB + "alias ptr_t = ExprBinary.ptr_t")
            print(TAB + "alias var_t = ExprBinary.var_t")
            print(TAB + "alias Stmt = " + var_t[:-2] + "]")
            print(TAB + "alias Stmt_ptr = " + ptr_t[:-2] + "]")

        for j in range(len(fields)):
            print(TAB, end = "")
            var field_names : List[String] = fields[j].split(" ")
            print("var " + field_names[2] + " : " + field_names[1])
        print()
        print(TAB + "fn __init__(inout self", end = "")
        for field in fields:
            print(", ", end = "")
            var field_names : List[String] = field[].split(" ")
            if field_names[1] == "Self.ptr_t":
                print(field_names[2] + " : " + "Self.var_t", end = "")
            elif field_names[1] == "Self.Stmt_ptr":
                print(field_names[2] + " : " + "Self.Stmt", end = "")
            else:
                print(field_names[2] + " : " + field_names[1], end = "")
        print("):")


        for j in range(len(fields)):
            var field_names : List[String] = fields[j].split(" ")
            var opt_end = ""
            if "Optional" in field_names[1]:
                print(TAB + TAB + "self." + field_names[2] + " = None")
                print(TAB + TAB + "if " + field_names[2] + ":")
                print(TAB, end = "")
                opt_end = ".take()"

            if "Self.ptr_t" in field_names[1]:
                print(TAB + TAB + "self." + field_names[2] + " = expr_delegate_init(" + field_names[2] + opt_end + ")")
            elif "Self.Stmt_ptr" in field_names[1]:
                print(TAB + TAB + "self." + field_names[2] + " = stmt_delegate_init(" + field_names[2] + opt_end + ")")
            else:
                print(TAB + TAB + "self." + field_names[2] + " = " + field_names[2])
        print() 

        print(TAB + "fn __copyinit__(inout self, other : Self):")
        for field in fields:
            var name_type = field[].split(" ")
            var name = name_type[2].strip()
            print(TAB + TAB + " self." + name + " = " + "other." + name)

        print(TAB + "fn __moveinit__(inout self, owned other : Self):")
        for field in fields:
            var name_type = field[].split(" ")
            var name = name_type[2].strip()
            print(TAB + TAB + "self." + name + " = " + "other." + name)

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
        print("from src.parser.expr import ", end = "")
        for i in range(len(expr_vec.value()) - 1):
            print(expr_vec.value()[i] + "Delegate, ", end = "")
        print(expr_vec.value()[len(expr_vec.value()) - 1] + "Delegate")
        print("from src.parser.expr import expr_delegate_init")
    LINE_BREAK



def expr_gen():
    var vec = List[String]()
    vec.append("Binary   : Self.ptr_t left, Token operator, Self.ptr_t right")
    vec.append("Grouping : Self.ptr_t expression")
    vec.append("Literal  : LoxType value")
    vec.append("Unary    : Token operator, Self.ptr_t right")
    vec.append("Variable : Token name")
    vec.append("Assign : Token name, Self.ptr_t value")
    vec.append("Logical   : Self.ptr_t left, Token operator, Self.ptr_t right")

    print_headers()
    define_visitor("Expr", vec)
    LINE_BREAK
    define_expr("Expr", vec)
    LINE_BREAK
    variant_gen_fn(get_classes(vec, "Expr"))
    


def get_classes(str_list : List[String], base_name : String) -> List[String]:
    var ret_list = List[String]()

    for str in str_list:
        ret_list.append(base_name + str[].split(":")[0].strip())

    return ret_list
         
    

def stmt_gen():
    var stmt_vec = List[String]()
    var expr_vec = List[String]()

    stmt_vec.append("Expression  : Self.ptr_t expression")
    stmt_vec.append("Print       : Self.ptr_t expression")
    stmt_vec.append("Var         : Token name, Optional[Self.ptr_t] initializer")
    stmt_vec.append("Block       : List[Self.Stmt] statements")
    stmt_vec.append("If          : Self.ptr_t condition, Self.Stmt_ptr then_stmt, Optional[Self.Stmt_ptr] else_stmt")
    stmt_vec.append("While       : Self.ptr_t condition, Self.Stmt_ptr body")

    expr_vec.append("Binary   : Self.ptr_t left, Token operator, Self.ptr_t right")
    expr_vec.append("Grouping : Self.ptr_t expression")
    expr_vec.append("Literal  : String value")
    expr_vec.append("Unary    : Token operator, Self.ptr_t right")
    expr_vec.append("Variable      : Token name")
    expr_vec.append("Assign : Token name, Self.ptr_t value")
    expr_vec.append("Logical   : Self.ptr_t left, Token operator, Self.ptr_t right")

    expr_vec = get_classes(expr_vec, "Expr")    
    print_headers(True, expr_vec)
    define_visitor("Stmt", stmt_vec, stmt = True)
    LINE_BREAK


    define_expr("Stmt", stmt_vec, expr_vec, stmt = True)
    LINE_BREAK
    variant_gen_fn(get_classes(stmt_vec, "Stmt"), True)
    
    

def main():
    stmt_gen()
    #expr_gen()
