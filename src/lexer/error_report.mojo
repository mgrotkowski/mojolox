fn error(line : Int, message : String) raises -> None:
    report(line, "", message)
    raise Error("Parse error")

def report(line: Int, where : String, message : String) -> None:
    print("[line " + str(line) + "] Error: " + where + message)
    
