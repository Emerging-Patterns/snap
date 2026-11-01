import Base

# LAW: a char pushed onto the pieces leaves at least one
law push_cons:
  for h: Char
  for r: List<&2, String>
  {List.is_empty(&2, String, String.split.push(h, r)) == False{} : Bool}
