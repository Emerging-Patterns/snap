import Base

# LAW: the right half of an `and` that answered True
law and.right:
  for u: Bool
  for v: Bool
  for e: {Bool.and(u, v) == True{} : Bool}
  {v == True{} : Bool}
