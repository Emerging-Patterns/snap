# For every status `s` holding no newline and every body `b`, `text(s ++ "\n"
# ++ b)` is `b`.
import Base
import ../src/answer.bend as Answer
import ./defs/HoldsNoChar.bend as D1

# LAW: `text` reads back the body, whatever it holds
law text_reads_body:
  for +s: String
  for +b: String
  for h: {D1.clear(s, '\n') == True{} : Bool}
  {Answer.text(s ++ "\n" ++ b) == b : String}
