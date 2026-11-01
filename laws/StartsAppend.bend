import Base

# LAW: one string appended to another leaves the first a prefix of the whole
law starts_append:
  for +a: String
  for b: String
  {String.starts_with(String.append(a, b), a) == True{} : Bool}
