import Base

# LAW: a char equals itself
law char_eq_self:
  for +c: Char
  {Char.is_eq(c, c) == True{} : Bool}
