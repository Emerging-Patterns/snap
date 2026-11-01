import Base
import ./defs/HoldsNoChar.bend as D1

# LAW: a string that holds no separator is one piece
law split_one:
  for +p: String
  for +c: Char
  for ep: {D1.clear(p, c) == True{} : Bool}
  {String.split(p, c) == [p] : List<&2, String>}
