import sys

from src.run import Lox

def main():
    var args = sys.argv()
    var lox_runner = Lox()

    if len(args) > 2:
        print("Usage: lox [script]")
        sys.ffi.external_call["exit", Int, Int](64)
    elif len(args) == 2:
        lox_runner.RunFile(args[1])
    else:
        lox_runner.RunPrompt()



