from utils.variant import Variant
alias LoxType = Variant[String, Float64, Bool, NoneType]

@value
struct Token(CollectionElement, Stringable):
    var type : TokenType
    var lexeme : LoxType
    var line : Int
    var literal : String

    fn __init__(
                inout self, 
                owned type : TokenType, 
                owned lexeme : LoxType, 
                owned line : Int, 
                owned literal : String
                ):
        self.type = type
        self.lexeme = lexeme^
        self.line = line
        self.literal = literal^

    fn __str__(self) -> String:
        return stringify_lox(self.lexeme)

#        if self.lexeme.isa[String]():
#            return self.lexeme.get[String]()[]
#        elif self.lexeme.isa[Float64]():
#            var lexeme_str : String
#            lexeme_str = str(self.lexeme.get[Float64]()[])
#            try:
#                var split = lexeme_str.split(".")
#                if len(split[1]) == 1 and split[1] == "0":
#                    lexeme_str = split[0]
#            except Error:
#                pass
#            return lexeme_str
#        elif self.lexeme.isa[Bool]():
#            return str(self.lexeme.get[Bool]()[])
#        else:
#            return str(self.lexeme.get[NoneType]()[])
        
        #return "TokenID: " + str(self.type.value) + " Lexeme: " + lexeme_str + " Literal: " + self.literal


@register_passable("trivial")
struct TokenType(CollectionElement):
    var value : UInt8

    # Single character tokens
    alias LEFT_PAREN = TokenType(0)
    alias RIGHT_PAREN = TokenType(1)
    alias LEFT_BRACE = TokenType(2)
    alias RIGHT_BRACE = TokenType(3)
    alias COMMA = TokenType(4)
    alias DOT = TokenType(5)
    alias MINUS = TokenType(6)
    alias PLUS = TokenType(7)
    alias SEMICOLON = TokenType(8)
    alias SLASH = TokenType(9)
    alias STAR = TokenType(10)
    alias Q_MARK = TokenType(39)
    alias COLON = TokenType(40)


    # One or two character tokens
    alias BANG = TokenType(11)
    alias BANG_EQUAL = TokenType(12)
    alias EQUAL = TokenType(13)
    alias EQUAL_EQUAL = TokenType(14)
    alias GREATER = TokenType(15)
    alias GREATER_EQUAL = TokenType(16)
    alias LESS = TokenType(17)
    alias LESS_EQUAL = TokenType(18)

    # Literals
    alias IDENTIFIER = TokenType(19)
    alias STRING = TokenType(20)
    alias NUMBER = TokenType(21)

    # Keywords
    alias AND = TokenType(22)
    alias CLASS = TokenType(23)
    alias ELSE = TokenType(24)
    alias FALSE = TokenType(25)
    alias FUN = TokenType(26)
    alias FOR = TokenType(27)
    alias IF = TokenType(28)
    alias NIL = TokenType(29)
    alias OR = TokenType(30)
    alias PRINT = TokenType(31)
    alias RETURN = TokenType(32)
    alias SUPER = TokenType(33)
    alias THIS = TokenType(34)
    alias TRUE = TokenType(35)
    alias VAR = TokenType(36)
    alias WHILE = TokenType(37)

    alias EOF = TokenType(38)
    
    fn __init__(value : UInt8) -> Self:
        return Self {value : value}
    
    fn __eq__(self : Self, other : Self) -> Bool:
        return self.value == other.value

fn stringify_lox(value : LoxType) -> String:
    if value.isa[String]():
        return value.get[String]()[]
    elif value.isa[Float64]():
        var lexeme_str : String
        lexeme_str = str(value.get[Float64]()[])
        try:
            var split = lexeme_str.split(".")
            if len(split[1]) == 1 and split[1] == "0":
                lexeme_str = split[0]
        except Error:
            pass
        return lexeme_str
    elif value.isa[Bool]():
        return str(value.get[Bool]()[])
    else:
        return str(value.get[NoneType]()[])

