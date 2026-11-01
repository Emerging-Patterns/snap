import Base

# LAW: and so does a whole split
law split_cons:
  for s: String
  for +c: Char
  {List.is_empty(&2, String, String.split(s, c)) == False{} : Bool}
