import Base
import ./defs/HoldsNoChar.bend as D1

# LAW: joining pieces with a separator none of them holds, and cutting the
# text at it, gives the pieces back. A list with no pieces joins to the empty
# text, which is one empty piece, so the law is about a list with a first one.
law split_join:
  for +p: String
  for +ps: List<&2, String>
  for +c: Char
  for +e: {D1.clear.all(p <> ps, c) == True{} : Bool}
  {String.split(String.join(p <> ps, SCon{c, SNil{}}), c) == p <> ps
    : List<&2, String>}
