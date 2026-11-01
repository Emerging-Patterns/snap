import Base

# LAW: one char of the split joined back, once the rest is known to have a
# first piece, with which way the comparison went given as a parameter
law join_split.cons:
  for +h: Char
  for +t: String
  for +c: Char
  for +y: String
  for +ys: List<&2, String>
  for b: Bool
  for eb: {Char.is_eq(h, c) == b : Bool}
  for ih: {String.join.go(ys, y, SCon{c, SNil{}}) == t : String}
  {String.join(String.split.fin(h, y <> ys, b), SCon{c, SNil{}}) == SCon{h, t}
    : String}
