from collections.optional import Optional

alias TAB = "   "
alias LINE_BREAK = print()

# CONSTANT: Expr trait and Visitor struct 
# VARIABLE: Expr structs and Visitor visit methods

def variant_gen(type_name : String, derived_classes : DynamicVector[String]):
    print(TAB + TAB + "if " + type_name + ".isa[" + derived_classes[0] + "]():")
    print_no_newline(TAB + TAB + TAB + "self." + type_name + " = " + derived_classes[0] + "Delegate")
    print("(" + type_name + ".get[" + derived_classes[0] + "]()[])")

    for idx in range(1, len(derived_classes) - 1):
        print(TAB + TAB + "elif " + type_name + ".isa[" + derived_classes[idx] + "]():")
        print_no_newline(TAB + TAB + TAB + "self." + type_name + " = " + derived_classes[idx] + "Delegate")
        print("(" + type_name + ".get[" + derived_classes[idx] + "]()[])")

    print(TAB + TAB + "else: ")
    print_no_newline(TAB + TAB + TAB + "self." + type_name + " = " + derived_classes[len(derived_classes) - 1] + "Delegate")
    print("(" + type_name + ".get[" + derived_classes[len(derived_classes) - 1] + "]()[])")
    print()



def define_expr(base_name : String, types : DynamicVector[String], exprs : Optional[DynamicVector[String]] = None, stmt : Bool = False):
    print("trait " + base_name + "(CollectionElement):")
    print_no_newline(TAB)
    if not stmt:
        print("fn accept[V : Visitor, U : Copyable](inout self, inout visitor : V) raises -> U: ...")
    else:
        print("fn accept[V : Visitor](inout self, inout visitor : V) raises -> None: ...")

    var ptr_t : String = "Variant["
    var var_t : String = "Variant["
    var class_names = DynamicVector[String]()

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
        var names : DynamicVector[String] = types[i].split(":")
        var class_name = names[0].strip()
        var fields : DynamicVector[String] = names[1].split(",")

        print("struct " + base_name + class_name + "(" + base_name + "):")

        if not stmt:
            print(TAB + "alias ptr_t = " + ptr_t[:-2] + "]")
            print(TAB + "alias var_t = " + var_t[:-2] + "]")
        else:
            print(TAB + "alias ptr_t = ExprBinary.ptr_t")
            print(TAB + "alias var_t = ExprBinary.var_t")

        for j in range(len(fields)):
            print_no_newline(TAB)
            var field_names : DynamicVector[String] = fields[j].split(" ")
            print("var " + field_names[2] + " : " + field_names[1])
        print()
        print_no_newline(TAB + "fn __init__(inout self")
        for field in fields:
            print_no_newline(", ")
            var field_names : DynamicVector[String] = field[].split(" ")
            if field_names[1] == "Self.ptr_t":
                print_no_newline(field_names[2] + " : " + "Self.var_t") 
            else:
                print_no_newline(field_names[2] + " : " + field_names[1]) 
        print("):")


        for j in range(len(fields)):
            var field_names : DynamicVector[String] = fields[j].split(" ")
            if field_names[1] == "Self.ptr_t":
                variant_gen(field_names[2], class_names)
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



def define_visitor(base_name : String, types : DynamicVector[String], stmt : Bool = False): 
    print("trait Visitor:")
    for i in range(len(types)):
        type_name = types[i].split(":")[0].strip()
        print_no_newline(TAB)
        if not stmt:
            print("fn visit" + type_name +  base_name + "[V : Copyable]" +  "(inout self, " + type_name + base_name.lower() + " : " + base_name + type_name + ") raises -> V: ...") 
        else:
            print("fn visit" + type_name +  base_name + "(inout self, " + type_name + base_name.lower() + " : " + base_name + type_name + ") raises -> None: ...") 

def print_headers(stmt : Bool = False, expr_vec : Optional[DynamicVector[String]] = None):
    print("from src.lexer.token import Token, LoxType, stringify_lox")
    print("from collections.optional import Optional")
    print("from memory.anypointer import AnyPointer")
    print("from utils.variant import Variant\n")
    if stmt:
        print_no_newline("from src.parser.expr import ")
        for i in range(len(expr_vec.value()) - 1):
            print_no_newline(expr_vec.value()[i] + ", ")
        print(expr_vec.value()[len(expr_vec.value()) - 1])
        print_no_newline("from src.parser.expr import ")
        for i in range(len(expr_vec.value()) - 1):
            print_no_newline(expr_vec.value()[i] + "Delegate, ")
        print(expr_vec.value()[len(expr_vec.value()) - 1] + "Delegate")
    LINE_BREAK



def expr_gen():
    var vec = DynamicVector[String]()
    vec.append("Binary   : Self.ptr_t left, Token operator, Self.ptr_t right")
    vec.append("Grouping : Self.ptr_t expression")
    vec.append("Literal  : LoxType value")
    vec.append("Unary    : Token operator, Self.ptr_t right")
    vec.append("Variable : Token name")
    vec.append("Assign : Token name, Self.ptr_t value")

    print_headers()
    define_visitor("Expr", vec)
    LINE_BREAK
    define_expr("Expr", vec)

def expr_variant_init(expr_vec : DynamicVector[String]):
    pass

def stmt_gen():
    var stmt_vec = DynamicVector[String]()
    var expr_vec = DynamicVector[String]()

    stmt_vec.append("Expression  : Self.ptr_t expression")
    stmt_vec.append("Print       : Self.ptr_t expression")
    stmt_vec.append("Var         : Token name, Self.ptr_t initializer")
    stmt_vec.append("Block       : DynamicVector[Stmt] statements")
    stmt_vec.append("If          : Self.ptr_t condition, Stmt ElseStmt")

    expr_vec.append("Binary   : Self.ptr_t left, Token operator, Self.ptr_t right")
    expr_vec.append("Grouping : Self.ptr_t expression")
    expr_vec.append("Literal  : String value")
    expr_vec.append("Unary    : Token operator, Self.ptr_t right")
    expr_vec.append("Variable      : Token name")
    expr_vec.append("Assign : Token name, Self.ptr_t value")
    expr_vec.append("Assign : Token name, Self.ptr_t value")

    for i in range(len(expr_vec)):
        expr_vec[i] = "Expr" + expr_vec[i].split(":")[0].strip()

    print_headers(True, expr_vec)
    define_visitor("Stmt", stmt_vec, stmt = True)
    LINE_BREAK


    define_expr("Stmt", stmt_vec, expr_vec, stmt = True)
    
    

def main():
    stmt_gen()
    #expr_gen()
