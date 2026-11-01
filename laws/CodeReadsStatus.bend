# For every status `s` holding no newline and every body `b`, `code(s ++ "\n"
# ++ b)` is `s`.
import Base
import ../src/answer.bend as Answer
import ./defs/HoldsNoChar.bend as D1

# Reading an answer. An answer is a status on its own first line, then the
# body; the status holds no newline, and the body may hold anything.

# LAW: `code` reads back the status, whatever body follows it
law code_reads_status:
  for +s: String
  for +b: String
  for h: {D1.clear(s, '\n') == True{} : Bool}
  {Answer.code(s ++ "\n" ++ b) == s : String}
