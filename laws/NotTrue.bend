import Base

# LAW: what a negation that answered True was told
law not.true:
  for u: Bool
  for e: {Bool.not(u) == True{} : Bool}
  {u == False{} : Bool}
