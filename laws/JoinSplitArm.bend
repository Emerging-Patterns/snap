import Base

# LAW: one char of the split, joined back, with which way the comparison went
# and the pieces of the rest given as parameters
law join_split.arm:
  for +h: Char
  for +t: String
  for +c: Char
  for r: List<&2, String>
  for b: Bool
  for eb: {Char.is_eq(h, c) == b : Bool}
  for er: {List.is_empty(&2, String, r) == False{} : Bool}
  for ih: {String.join(r, SCon{c, SNil{}}) == t : String}
  {String.join(String.split.fin(h, r, b), SCon{c, SNil{}}) == SCon{h, t}
    : String}
