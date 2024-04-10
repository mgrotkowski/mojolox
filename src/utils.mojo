from src.parser.stmt import *
from src.lox_types import LoxBaseType, LoxType, LoxCallable, Clock, LoxFunction

def str2float(x : String) -> Float64:
    var res_split = x.split(".")
    if len(res_split) == 1:
        return atol(res_split[0]) 
    return atol(res_split[0]) + atol(res_split[1]) / 10**len(res_split[1])

fn stringify_lox(value : LoxType) -> String:
    if value.isa[LoxBaseType]():
        var value = value.get[LoxBaseType]()[]
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
    elif value.isa[LoxCallable]():
        var value = value.get[LoxCallable]()[]
        if value.isa[Clock]():
            return str(value.get[Clock]()[])
        elif value.isa[LoxFunction]():
            return str(value.get[LoxFunction]()[])
    return ""
        
struct SharedPtr[T : CollectionElement](CollectionElement):
    var ref_count : Pointer[UInt64]
    var data : AnyPointer[T]

    fn __init__(inout self, data : T):
        self.data = AnyPointer[T]().alloc(1)
        self.data[] = data

        self.ref_count = Pointer[UInt64]().alloc(1)
        self.ref_count[] = 1

    fn __init__(inout self):
        self.data = AnyPointer[T]()
        self.ref_count = Pointer[UInt64]()

    fn __copyinit__(inout self, other : Self):
        self.data = other.data
        self.ref_count = other.ref_count
        if self.ref_count:
            self.ref_count[] += 1

    fn __moveinit__(inout self, owned other : Self):
        self.data = other.data
        self.ref_count = other.ref_count

        other.data = AnyPointer[T]()
        other.ref_count = Pointer[UInt64]()

    fn __del__(owned self):
        if self.ref_count:
            self.ref_count[] -= 1
            if self.ref_count[] == 0:
                self.data.free()
                self.ref_count.free()
        

        





