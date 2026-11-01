import Base

# LAW: two strings with a first char each, which read as equal, have one
# first char
law eq_head:
  for h1: Char
  for h2: Char
  for +t1: String
  for +t2: String
  for e: {String.eq(SCon{h1, t1}, SCon{h2, t2}) == True{} : Bool}
  {h1 == h2 : Char}
