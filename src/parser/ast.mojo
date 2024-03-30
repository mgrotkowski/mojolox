from src.parser.expr import *
from src.lexer.token import Token, TokenType

@value
struct ASTVisitor(Visitor):
   fn __init__(inout self):
        pass

   fn parenthesize(self, *expr : String) -> String:
        var ret_str : String = "("
        for expression in expr:
            ret_str += expression[]
        ret_str += ")"

        return ret_str 
        

   fn visitBinaryExpr[V : Copyable = String](inout self, Binaryexpr : ExprBinary) raises -> V: 

        var ret_string_left : String
        var ret_string_right : String

        if Binaryexpr.left.isa[ExprBinaryDelegate]():
            ret_string_left = Binaryexpr.left.get[ExprBinaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Binaryexpr.left.isa[ExprGroupingDelegate]():
            ret_string_left = Binaryexpr.left.get[ExprGroupingDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Binaryexpr.left.isa[ExprUnaryDelegate]():
            ret_string_left = Binaryexpr.left.get[ExprUnaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        else:
            ret_string_left = Binaryexpr.left.get[ExprLiteralDelegate]()[].ptr[].accept[ASTVisitor, String](self)
            
        if Binaryexpr.right.isa[ExprBinaryDelegate]():
            ret_string_right = Binaryexpr.right.get[ExprBinaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Binaryexpr.right.isa[ExprGroupingDelegate]():
            ret_string_right = Binaryexpr.right.get[ExprGroupingDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Binaryexpr.right.isa[ExprUnaryDelegate]():
            ret_string_right = Binaryexpr.right.get[ExprUnaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        else:
            ret_string_right = Binaryexpr.right.get[ExprLiteralDelegate]()[].ptr[].accept[ASTVisitor, String](self)

        return self.parenthesize(str(Binaryexpr.operator) + " ",
                                 ret_string_left + " ",
                                 ret_string_right)

   fn visitGroupingExpr[T : Copyable](inout self, Groupingexpr : ExprGrouping) raises -> T: 
        var ret_string : String
        if Groupingexpr.expression.isa[ExprBinaryDelegate]():
            ret_string = Groupingexpr.expression.get[ExprBinaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Groupingexpr.expression.isa[ExprGroupingDelegate]():
            ret_string = Groupingexpr.expression.get[ExprGroupingDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Groupingexpr.expression.isa[ExprUnaryDelegate]():
            ret_string = Groupingexpr.expression.get[ExprUnaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        else:
            ret_string = Groupingexpr.expression.get[ExprLiteralDelegate]()[].ptr[].accept[ASTVisitor, String](self)
            
        return self.parenthesize("group ", ret_string)

   fn visitLiteralExpr[V : Copyable = String](inout self, Literalexpr : ExprLiteral) raises -> V: 
        return str(Literalexpr)

   fn visitUnaryExpr[T : Copyable](inout self, Unaryexpr : ExprUnary) raises -> T:
        var ret_string : String
        if Unaryexpr.right.isa[ExprBinaryDelegate]():
            ret_string = Unaryexpr.right.get[ExprBinaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Unaryexpr.right.isa[ExprGroupingDelegate]():
            ret_string = Unaryexpr.right.get[ExprGroupingDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        elif Unaryexpr.right.isa[ExprUnaryDelegate]():
            ret_string = Unaryexpr.right.get[ExprUnaryDelegate]()[].ptr[].accept[ASTVisitor, String](self)
        else:
            ret_string = Unaryexpr.right.get[ExprLiteralDelegate]()[].ptr[].accept[ASTVisitor, String](self)
            
        return self.parenthesize(str(Unaryexpr.operator) + " ", ret_string)

   fn print(inout self, expr : ExprBinary.var_t) raises:
        if expr.isa[ExprBinary]():
            var temp_expr = expr.get[ExprBinary]()[]
            print(temp_expr.accept[Self, String](self))
        elif expr.isa[ExprGrouping]():
            var temp_expr = expr.get[ExprGrouping]()[]
            print(temp_expr.accept[Self, String](self))
        elif expr.isa[ExprUnary]():
            var temp_expr = expr.get[ExprUnary]()[]
            print(temp_expr.accept[Self, String](self))
        else:
            var temp_expr = expr.get[ExprLiteral]()[]
            print(temp_expr.accept[Self, String](self))



fn main():
    var expression1 = ExprUnary(Token(TokenType.MINUS, "-", 0, ""), ExprLiteral("123"))
    var expression2 = ExprGrouping(ExprLiteral("46.7"))
    var expression3 = ExprBinary(expression1, Token(TokenType.STAR, "*", 0, ""), expression2)
    var tree = ASTVisitor()
    try:
        tree.print(expression3)
    except Error:
        print("Pretty printer error")
    _ = expression3
