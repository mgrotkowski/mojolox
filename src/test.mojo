from collections.dict import Dict
from memory.anypointer import AnyPointer
from utils.variant import Variant

trait Fooable(Copyable, Movable):
    fn foo(self, str : String) -> None: ...


@value
struct B(Fooable):
    var my_var : String

    fn __init__(inout self):
        self.my_var = "B"

    fn foo(self, comp : String) -> None:
        print(self.my_var + comp)

@value
struct A(Fooable):
    var my_var : String

    fn __init__(inout self):
        self.my_var = "A"

    fn foo(self, comp : String) -> None:
        print(self.my_var + comp)



struct C:
    var my_var : AnyPointer[Fooable]

    fn __init__(inout self, foo : Fooable):
        self.my_var = AnyPointer[Fooable]().alloc(1)
        self.my_var.emplace_value(foo)

    fn __moveinit__(inout self, owned other : Self):
        self.my_var = other.my_var


def main():
    var dict_1 = Dict[String, String]()
    var dict_2 = dict_1

    var c : String = "Hello"

    print(dict_1._index.data)
    print(dict_2._index.data)

