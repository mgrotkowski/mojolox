from collections import List, Dict
from utils.variant import Variant

from src.parser.expr import *
from src.parser.stmt import StmtPrint, StmtExpression, StmtVar, StmtBlock, StmtIf, StmtWhile
from src.lexer.token import Token, TokenType
from src.lexer.error_report import report

alias Expr = ExprBinary.var_t
alias Stmt = StmtExpression.Stmt

@value
struct Parser:
    var tokens : List[Token]
    var current : Int

    fn __init__(inout self, tok_vec : List[Token]):
        self.tokens = tok_vec
        self.current = 0


    fn parse(inout self) raises -> List[Stmt]:
        var statements = List[Stmt]()
        while not self._is_at_end():
            var result = self.declaration()
            if result:
                statements.append(result.value())
            else:
                raise Error("Parse error")
        return statements^

    fn declaration(inout self) -> Optional[Stmt]:
        try:
            if self._match(TokenType.VAR):
                self._advance()
                return Optional[Stmt](self.var_decl())
            return self.statement()
        except Error:
            self._synchronize()

        return None

    fn var_decl(inout self) raises -> Stmt:
        var variable_identifier : Token
        var initializer : Optional[Expr] = None
        variable_identifier = self._consume(TokenType.IDENTIFIER, "Consume variable name.")

        if self._match(TokenType.EQUAL):
            self._advance()
            initializer = self.expression()

        self._consume(TokenType.SEMICOLON, "Expected ';' after variable declaration.")

        return StmtVar(variable_identifier, initializer)


    fn statement(inout self) raises -> Stmt:
        if self._match(TokenType.PRINT):
            self._advance()
            return self.print_statement()
        if self._match(TokenType.LEFT_BRACE):
            self._advance()
            return StmtBlock(self.block_statement())
        if self._match(TokenType.IF):
            self._advance()
            return self.if_statement()
        if self._match(TokenType.WHILE):
            self._advance()
            return self.while_statement()
        if self._match(TokenType.FOR):
            self._advance()
            return self.for_statement()

        return self.expression_statement()

    fn while_statement(inout self) raises -> StmtWhile:
        self._consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.")
        var condition = self.expression()
        self._consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.")
        var body = self.statement()

        return StmtWhile(condition, body)

    fn for_statement(inout self) raises -> Stmt:
        self._consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.")
        var initializer : Optional[Stmt] = None
        var condition : Optional[Expr] = None
        var increment : Optional[Expr] = None

        if self._match(TokenType.SEMICOLON):
            self._advance()
        elif self._match(TokenType.VAR):
            self._advance()
            initializer = self.var_decl()
        else:
            initializer = self.expression_statement()

        if not self._match(TokenType.SEMICOLON):
            condition = self.expression()

        self._consume(TokenType.SEMICOLON, "Expected ';' after loop condition.")
        
        if not self._match(TokenType.RIGHT_PAREN):
            increment = self.expression()

        self._consume(TokenType.RIGHT_PAREN, "Expected ')' after fo clauses.")

        var body = self.statement()

        if increment:
            var loop_statements = List[Stmt]()
            loop_statements.append(body)
            loop_statements.append(StmtExpression(increment.take()))
            body = StmtBlock(loop_statements)

        if not condition:
            condition = Expr(ExprLiteral(String("true")))

        body = StmtWhile(condition.take(), body)

        if initializer:
            var loop_statements = List[Stmt]()
            loop_statements.append(initializer.take())
            loop_statements.append(body)
            body = StmtBlock(loop_statements)

        return body


    fn if_statement(inout self) raises -> StmtIf:
        self._consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.")
        var condition = self.expression()
        self._consume(TokenType.RIGHT_PAREN, "Expect closing ')' after condition.")
        var then_stmt = self.statement()
        var else_stmt : Optional[Stmt] = None

        if self._match(TokenType.ELSE):
            self._advance()
            else_stmt = self.statement()

        return StmtIf(condition, then_stmt, else_stmt)

    fn block_statement(inout self) raises -> List[Stmt]:
        var ret_vec = List[Stmt]()

        while not self._match(TokenType.RIGHT_BRACE) and not self._is_at_end():
            ret_vec.append(self.declaration().value())
        self._consume(TokenType.RIGHT_BRACE, "Expect '}' after block.")
        return ret_vec^
        

    fn print_statement(inout self) raises -> Stmt:
        var value = self.expression()
        self._consume(TokenType.SEMICOLON, "Expected ';' after value.")
        return StmtPrint(value)

    fn expression_statement(inout self) raises -> Stmt:
        var expr = self.expression()
        self._consume(TokenType.SEMICOLON, "Expected ';' after value.")
        return StmtExpression(expr)


    fn expression(inout self) raises -> Expr: 
        return self.comma()

    fn comma(inout self) raises -> Expr:
        var expr = self.assignment()

        while self._match(TokenType.COMMA):
           var operator = self._advance()  
           var expr_right = self.assignment()
           expr = ExprBinary(expr, operator, expr_right)


        return expr 

    fn assignment(inout self) raises -> Expr:
        var expr = self.ternary()

        if self._match(TokenType.EQUAL):
            var equals = self._advance()
            if expr.isa[ExprVariable]():
                expr = ExprAssign(expr.get[ExprVariable]()[].name, self.assignment())
            else:
                report(equals.line, str(equals), "Invalid assignment target")
        return expr
        
    fn ternary(inout self) raises -> Expr:
        var expr = self.Or()

        if self._match(TokenType.Q_MARK):
            var conditional : Expr
            var op1 = self._advance()
            var expr_left = self.comma()
            var op2 = self._consume(TokenType.COLON, "Missing ':' in ternary expression")
            expr = ExprBinary(expr, op1, ExprBinary(expr_left, op2, self.ternary()))
        
        return expr

    fn Or(inout self) raises -> Expr:
        var expr = self.And()
        while self._match(TokenType.OR):
            var operator = self._advance()
            var expr_right = self.And()
            expr = ExprLogical(expr, operator, expr_right)
        return expr

    fn And(inout self) raises -> Expr:
        var expr = self.equality()
        while self._match(TokenType.AND):
            var operator = self._advance()
            var expr_right = self.equality()
            expr = ExprLogical(expr, operator, expr_right)
        return expr

    fn equality(inout self) raises -> Expr: 
        var expr = self.comparison()

        while self._match(TokenType.EQUAL_EQUAL, TokenType.BANG_EQUAL):
           var operator = self._advance()  
           var expr_right = self.comparison()
           expr = ExprBinary(expr, operator, expr_right)


        return expr 
        

    fn comparison(inout self) raises -> Expr: 
        var expr = self.term()

        while (self._match(TokenType.GREATER,
                           TokenType.GREATER_EQUAL,
                           TokenType.LESS,
                           TokenType.LESS_EQUAL)):

            var operator = self._advance()
            var expr_right = self.term()
            expr = ExprBinary(expr, operator, expr_right)

        return expr
        
    fn term(inout self) raises -> Expr: 
        var expr = self.factor()

        while (self._match(TokenType.PLUS, TokenType.MINUS)):
            var operator = self._advance()
            var expr_right = self.factor()
            expr = ExprBinary(expr, operator, expr_right)

        return expr

    fn factor(inout self) raises -> Expr: 
        var expr = self.unary()

        while (self._match(TokenType.SLASH, TokenType.STAR)):
            var operator = self._advance()
            var expr_right = self.unary()
            expr = ExprBinary(expr, operator, expr_right)

        return expr

    fn unary(inout self) raises -> Expr: 
        if self._match(TokenType.BANG, TokenType.MINUS):
            return ExprUnary(self._advance(), self.unary())
        return self.primary()

    fn primary(inout self) raises -> Expr: 

        if self._match(TokenType.FALSE,
                       TokenType.TRUE,
                       TokenType.NIL,
                       TokenType.NUMBER,
                       TokenType.STRING,
                       ):
            return ExprLiteral(self._advance().lexeme)

        if self._match(TokenType.IDENTIFIER):
            return ExprVariable(self._advance())

        if self._match(TokenType.LEFT_PAREN):
            self._advance()
            var expr = self.expression()
            self._consume(TokenType.RIGHT_PAREN, "Expected ')' after expression.")
            return ExprGrouping(expr)

        return ExprLiteral(String(""))


    fn _consume(inout self, tok_type : TokenType, msg : String) raises -> Token:
        if self._match(tok_type):
            return self._advance()
        
        var tok = self._peek()
        if tok.type == TokenType.EOF:
            report(tok.line, " at end: ", msg)
        else: 
            report(tok.line, " at '" + str(tok) + "' ", msg)
        raise Error("Parse Error")

    fn _synchronize(inout self):

        while not self._is_at_end():
            var tok = self._peek()
            if tok.type == TokenType.SEMICOLON:
                break
            if tok.type == TokenType.CLASS:
                pass
            elif tok.type == TokenType.FUN:
                pass
            elif tok.type == TokenType.VAR:
                pass
            elif tok.type == TokenType.FOR:
                pass
            elif tok.type == TokenType.IF:
                pass
            elif tok.type == TokenType.WHILE:
                pass
            elif tok.type == TokenType.PRINT:
                pass
            elif tok.type == TokenType.RETURN:
                pass
            self._advance()




    fn _match(inout self, *toks : TokenType) -> Bool: 
        if self._is_at_end():
            return False

        for tok in toks:
            if self._peek().type == tok:
                return True
        return False

    fn _peek(inout self) -> Token:
        return self.tokens[self.current]

    fn _advance(inout self) -> Token: 
        self.current += 1
        return self.tokens[self.current - 1]

    fn _is_at_end(inout self) -> Bool:
        return self._peek().type == TokenType.EOF
        

