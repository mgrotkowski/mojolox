from src.utils import SharedPtr

def main():
    var x = SharedPtr[Int](0)
    var y = x
    y.data[] += 1
    print(x.ref_count[])
    _ = y
    print(x.data[])
    print(x.ref_count[])
    _ = x
