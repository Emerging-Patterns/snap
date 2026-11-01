import Base

# LAW: and the rest of each reads as equal
law eq_tail:
  for h1: Char
  for h2: Char
  for +t1: String
  for +t2: String
  for e: {String.eq(SCon{h1, t1}, SCon{h2, t2}) == True{} : Bool}
  {String.eq(t1, t2) == True{} : Bool}
