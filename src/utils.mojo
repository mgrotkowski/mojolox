from src.parser.stmt import *

def str2float(x : String) -> Float64:
    var res_split = x.split(".")
    if len(res_split) == 1:
        return atol(res_split[0]) 
    return atol(res_split[0]) + atol(res_split[1]) / 10**len(res_split[1])


fn stmt_delegate_conversion(val : StmtExpression.Stmt_ptr) -> StmtExpression.Stmt:
   if val.isa[StmtExpressionDelegate]():
      return val.get[StmtExpressionDelegate]()[].ptr[]
   elif val.isa[StmtPrintDelegate]():
      return val.get[StmtPrintDelegate]()[].ptr[]
   elif val.isa[StmtVarDelegate]():
      return val.get[StmtVarDelegate]()[].ptr[]
   elif val.isa[StmtBlockDelegate]():
      return val.get[StmtBlockDelegate]()[].ptr[]
   else: 
      return val.get[StmtIfDelegate]()[].ptr[]



