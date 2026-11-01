import Base

# LAW: one step of a split always leaves at least one piece
law fin_cons:
  for h: Char
  for r: List<&2, String>
  for b: Bool
  {List.is_empty(&2, String, String.split.fin(h, r, b)) == False{} : Bool}
