import Base
import ./defs/HoldsNoChar.bend as D1

# LAW: a string that holds no separator, put in front of text, lands whole in
# front of the text's first piece
law split_front:
  for p: String
  for +s: String
  for +c: Char
  for +y: String
  for +ys: List<&2, String>
  for +ep: {D1.clear(p, c) == True{} : Bool}
  for es: {String.split(s, c) == y <> ys : List<&2, String>}
  {String.split(String.append(p, s), c) == String.append(p, y) <> ys
    : List<&2, String>}
