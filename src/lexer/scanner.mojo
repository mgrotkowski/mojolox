from collections import List
from collections.dict import Dict
from collections.optional import Optional

from src.lexer.error_report import error
from src.lexer.token import Token, TokenType
from src.lox_types import LoxBaseType
from src.utils import str2float


@value
struct Scanner:
   var source_code : String
   var file_size   : Int
   var token_vec   : List[Token]

   var _start       : Int
   var _current     : Int
   var _line        : Int
   var _keywords_dict : Dict[String, TokenType]
   var _one_char_lexemes : Dict[String, TokenType]

   fn __init__(inout self, owned src : String):
       self.source_code = src^
       self.file_size = len(self.source_code)
       self.token_vec = List[Token]()
       self._start = 0
       self._current = 0
       self._line = 1
       self._keywords_dict = Dict[String, TokenType]()
       self._one_char_lexemes = Dict[String, TokenType]()
       self._dict_init()

   fn _dict_init(inout self):
       self._one_char_lexemes["("] = TokenType.LEFT_PAREN 
       self._one_char_lexemes[")"] = TokenType.RIGHT_PAREN 
       self._one_char_lexemes["{"] = TokenType.LEFT_BRACE 
       self._one_char_lexemes["}"] = TokenType.RIGHT_BRACE 
       self._one_char_lexemes[","] = TokenType.COMMA 
       self._one_char_lexemes["."] = TokenType.DOT 
       self._one_char_lexemes["-"] = TokenType.MINUS 
       self._one_char_lexemes["+"] =  TokenType.PLUS 
       self._one_char_lexemes[";"] = TokenType.SEMICOLON 
       self._one_char_lexemes["/"] = TokenType.SLASH 
       self._one_char_lexemes["*"] =  TokenType.STAR 
       self._one_char_lexemes["?"] =  TokenType.Q_MARK 
       self._one_char_lexemes[":"] =  TokenType.COLON 


       self._keywords_dict["and"] = TokenType.AND 
       self._keywords_dict["class"] = TokenType.CLASS 
       self._keywords_dict["else"] =  TokenType.ELSE 
       self._keywords_dict["false"] = TokenType.FALSE 
       self._keywords_dict["fun"] = TokenType.FUN 
       self._keywords_dict["for"] = TokenType.FOR 
       self._keywords_dict["if"] = TokenType.IF 
       self._keywords_dict["nil"] = TokenType.NIL 
       self._keywords_dict["or"] = TokenType.OR 
       self._keywords_dict["print"] = TokenType.PRINT 
       self._keywords_dict["return"] = TokenType.RETURN 
       self._keywords_dict["super"] = TokenType.SUPER 
       self._keywords_dict["this"] =  TokenType.THIS 
       self._keywords_dict["true"] =  TokenType.TRUE 
       self._keywords_dict["var"] = TokenType.VAR 
       self._keywords_dict["while"] = TokenType.WHILE 


   fn scan_tokens(inout self) raises -> List[Token]:
        while self._current < self.file_size:
            self._start = self._current 
            self.scan_token()
        self.token_vec.append(Token(TokenType.EOF, String("EOF"), self._line, "")) 

        return self.token_vec

   fn scan_token(inout self) raises -> None:
        var c = self.source_code[self._current]
        self._current += 1
        var result = self._one_char_lexemes.find(c)
        if result:
            self._add_token(result.take())
        elif c == "!":
            self._add_token(TokenType.BANG if not self._match("=") else TokenType.BANG_EQUAL)
        elif c == "=":
            self._add_token(TokenType.EQUAL if not self._match("=") else TokenType.EQUAL_EQUAL)
        elif c == ">":
            self._add_token(TokenType.GREATER if not self._match("=") else TokenType.GREATER_EQUAL)
        elif c == "<":
            self._add_token(TokenType.LESS if not self._match("=") else TokenType.LESS_EQUAL)
        elif c == "/":
            if self._match('/'):
                while self._peek() != "\n" and not self._is_at_end():
                    self._current += 1
            else:
                self._add_token(TokenType.SLASH)
        elif c == " " or c == "\r" or c == "\t":
            pass
        elif c == "\n":
            self._line += 1
        elif c == '"':
            self._string()
        else:
            if self._is_digit(c):
                self._number()
            elif self._is_alpha(c):
                self._identifier()
            else:
                error(self._line, "Unexpected character.")
        


   fn _add_token(inout self, type : TokenType, literal : String = "", lexeme : Optional[LoxBaseType] = None) -> None:
        var lex = literal
        if not literal:
            lex = self.source_code[self._start : self._current]
        self.token_vec.append(Token(type, lexeme.or_else(lex), self._line, literal)) 

   fn _peek(inout self) -> String:
       if self._is_at_end():
           return ""
       return self.source_code[self._current] 

   fn _peek_next(inout self) -> String:
       if self._current + 1 >= self.file_size:
           return ""
       return self.source_code[self._current + 1] 

   fn _match(inout self, borrowed pattern : String) -> Bool:
        if self._is_at_end():
            return False
        if self.source_code[self._current] !=  pattern: 
            return False
        self._current += 1
        return True

   fn _string(inout self) raises -> None:
        while self._peek() != '"' and not self._is_at_end():
            if self._peek() == "\n":
                self._line += 1
            self._current += 1
        if self._is_at_end():
            error(self._line, "Unterminated string at line")

        self._current += 1 
        self._add_token(TokenType.STRING, self.source_code[self._start + 1 : self._current -1])
   
   fn _is_digit(inout self, borrowed c : String) -> Bool:
        return ord(c) >= ord("0") and ord(c) <= ord("9")
   
   fn _is_alpha(inout self, borrowed c : String) -> Bool:
        var ord_c : UInt8 = ord(c)
        return self._is_digit(c) or (ord_c >= ord("a") and ord_c <= ord("z")) or (ord_c >= ord("A") and ord_c <= ord("Z") or ord_c == ord("_"))


   fn _number(inout self) raises:
        while self._is_digit(self._peek()):
            self._current += 1
        if self._peek() == "." and self._is_digit(self._peek_next()):
            self._current += 1
        elif self._peek() == ".":
            error(self._line, "Trailing . after decimal")
        while self._is_digit(self._peek()):
            self._current += 1
        self._add_token(TokenType.NUMBER, lexeme = LoxBaseType(str2float(self.source_code[self._start : self._current])))

   fn _identifier(inout self):
        var lexeme : Optional[LoxBaseType] = None
        while self._is_alpha(self._peek()):
            self._current += 1
        var s : String = self.source_code[self._start : self._current]
        var result_type = self._keywords_dict.find(s).or_else(TokenType.IDENTIFIER)
        

        if result_type == TokenType.TRUE:
            lexeme = LoxBaseType(True)
        elif result_type == TokenType.FALSE:
            lexeme = LoxBaseType(False)
        elif result_type == TokenType.NIL:
            lexeme = LoxBaseType(None)

        self._add_token(result_type, s, lexeme) 


    
   fn _is_at_end(inout self) -> Bool:
        return self._current >= self.file_size

#@value
#struct Token(CollectionElement, Stringable):
#    var type : TokenType
#    var lexeme : String
#    var line : Int
#    var literal : String
#
#    fn __init__(inout self, owned type : TokenType, owned lexeme : String, owned line : Int, owned literal : String):
#        self.type = type
#        self.lexeme = lexeme^
#        self.line = line
#        self.literal = literal^
#
#    fn __str__(self) -> String:
#        return "TokenID: " + str(self.type.value) + " Lexeme: " + self.lexeme + " Literal: " + self.literal
#
#
#@register_passable("trivial")
#struct TokenType(CollectionElement):
#    var value : UInt8
#
#    # Single character tokens
#    alias LEFT_PAREN = TokenType(0)
#    alias RIGHT_PAREN = TokenType(1)
#    alias LEFT_BRACE = TokenType(2)
#    alias RIGHT_BRACE = TokenType(3)
#    alias COMMA = TokenType(4)
#    alias DOT = TokenType(5)
#    alias MINUS = TokenType(6)
#    alias PLUS = TokenType(7)
#    alias SEMICOLON = TokenType(8)
#    alias SLASH = TokenType(9)
#    alias STAR = TokenType(10)
#    alias Q_MARK = TokenType(39)
#    alias COLON = TokenType(40)
#
#
#    # One or two character tokens
#    alias BANG = TokenType(11)
#    alias BANG_EQUAL = TokenType(12)
#    alias EQUAL = TokenType(13)
#    alias EQUAL_EQUAL = TokenType(14)
#    alias GREATER = TokenType(15)
#    alias GREATER_EQUAL = TokenType(16)
#    alias LESS = TokenType(17)
#    alias LESS_EQUAL = TokenType(18)
#
#    # Literals
#    alias IDENTIFIER = TokenType(19)
#    alias STRING = TokenType(20)
#    alias NUMBER = TokenType(21)
#
#    # Keywords
#    alias AND = TokenType(22)
#    alias CLASS = TokenType(23)
#    alias ELSE = TokenType(24)
#    alias FALSE = TokenType(25)
#    alias FUN = TokenType(26)
#    alias FOR = TokenType(27)
#    alias IF = TokenType(28)
#    alias NIL = TokenType(29)
#    alias OR = TokenType(30)
#    alias PRINT = TokenType(31)
#    alias RETURN = TokenType(32)
#    alias SUPER = TokenType(33)
#    alias THIS = TokenType(34)
#    alias TRUE = TokenType(35)
#    alias VAR = TokenType(36)
#    alias WHILE = TokenType(37)
#
#    alias EOF = TokenType(38)
#    
#    fn __init__(value : UInt8) -> Self:
#        return Self {value : value}
#    
#    fn __eq__(self : Self, other : Self) -> Bool:
#        return self.value == other.value
#
#
#      
