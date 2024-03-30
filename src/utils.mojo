from collections import Dict, KeyElement

def str2float(x : String) -> Float64:
    var res_split = x.split(".")
    if len(res_split) == 1:
        return atol(res_split[0]) 
    return atol(res_split[0]) + atol(res_split[1]) / 10**len(res_split[1])

@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s._as_ptr(), len(self.s))
    
    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s


