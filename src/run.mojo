from pathlib import Path
from python import Python
from collections import List
from collections.dict import Dict
import sys

from src.lexer.scanner import Scanner, Token
from src.lexer.error_report import error
from src.parser.parser import Parser, Stmt
from src.interpreter.interpreter import Interpreter

@value
struct Lox:
    var hadRuntimeError : Bool
    var interpreter : Interpreter

    fn __init__(inout self):
        self.hadRuntimeError = False
        self.interpreter = Interpreter()

    def RunFile(self, file_name : StringRef):
        with open(Path(file_name), "r") as f:
            try:
                self.Run(f.read())
            except Error:
                if self.hadRuntimeError:
                    sys.ffi.external_call["exit", Int, Int](70)

                sys.ffi.external_call["exit", Int, Int](65)
    
    def RunPrompt(inout self):
        var line : String
        while True:
            print("> ", end = "")
            line = str(Python.evaluate("input()"))
            if line == "q":
                break
            try:
                self.Run(line)
            except Error:
                if self.hadRuntimeError:
                    print("Runtime error")
    
    fn Run(inout self, source_code : String) raises -> None:
        var scanner = Scanner(source_code)
        var tokens = scanner.scan_tokens()
        var parser = Parser(tokens)
        var parse_result = List[Stmt]()
        try:
            parse_result = parser.parse()
        except Error:
            return
        try:
            self.interpreter.interpret(parse_result)
        except Error:
            self.hadRuntimeError = True
            
    

