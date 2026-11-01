import Base

# LAW: the left half of an `and` that answered True
law and.left:
  for u: Bool
  for v: Bool
  for e: {Bool.and(u, v) == True{} : Bool}
  {u == True{} : Bool}
