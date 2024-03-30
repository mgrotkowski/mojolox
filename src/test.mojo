from collections.dict import Dict
from memory.anypointer import AnyPointer
from utils.variant import Variant


struct B(Movable):
    var my_var : Variant[AnyPointer[A], AnyPointer[B]]

    fn __moveinit__(inout self, owned other : Self):
        self.my_var = other.my_var
        pass

struct A(Movable):
    var my_var : Variant[AnyPointer[A], AnyPointer[B]]

    fn __moveinit__(inout self, owned other : Self):
        self.my_var = other.my_var
        pass

def main():
    var dict_1 = Dict[String, String]()
    var dict_2 = dict_1

    print(dict_1._index.data)
    print(dict_2._index.data)

