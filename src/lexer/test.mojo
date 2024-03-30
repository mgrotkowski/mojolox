from src.lexer.scanner import Token 

trait Structable:
    fn call_my_func[V : Fooable](borrowed self, borrowed visitor : V): ...
    fn foo(borrowed self, x : String): ...

trait Fooable:
    fn my_func[V : Copyable = String](self, borrowed x : MyStruct) -> V:...

struct Foo(Fooable):
    fn __init__(inout self):
        pass
    fn my_func[V : Copyable = String](self,  borrowed x : MyStruct) -> V:
        x.foo("my_func")
        return String("Hello")

struct MyStruct:
    fn __init__(inout self):
        pass
    fn foo(borrowed self, x : String):
        print("Hello" + x)
    fn call_my_func[V : Fooable](borrowed self, borrowed visitor : V):
        visitor.my_func(self)


fn main():
    var z = MyStruct()
    var foo = Foo()

    z.call_my_func(foo)
    
