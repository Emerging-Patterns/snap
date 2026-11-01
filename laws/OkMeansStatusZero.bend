# For every status `s` holding no newline and every body `b`, `ok(s ++ "\n" ++
# b)` is true exactly when `s` is `"0"`.
import Base
import ../src/answer.bend as Answer
import ./defs/HoldsNoChar.bend as D1

# LAW: `ok` is true exactly when the status is "0"
law ok_reads_zero:
  for +s: String
  for +b: String
  for h: {D1.clear(s, '\n') == True{} : Bool}
  {Answer.ok(s ++ "\n" ++ b) == String.eq(s, "0") : Bool}
