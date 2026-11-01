import Base

# LAW: a string equals itself. Every lookup in this project turns on it.
law string_eq_self:
  for +s: String
  {String.eq(s, s) == True{} : Bool}
