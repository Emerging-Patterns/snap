import Base
import ./defs/HoldsNoChar.bend as D1

# LAW: pieces joined from a first piece, cut back, when none holds the
# separator
law split_join.go:
  for +ps: List<&2, String>
  for +p: String
  for +c: Char
  for ep: {D1.clear(p, c) == True{} : Bool}
  for +eps: {D1.clear.all(ps, c) == True{} : Bool}
  {String.split(String.join.go(ps, p, SCon{c, SNil{}}), c) == p <> ps
    : List<&2, String>}
