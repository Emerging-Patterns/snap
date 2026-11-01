import Base

# LAW: a string compares equal to itself
law string_cmp_self:
  for +s: String
  {String.cmp(s, s) == ((s, s), EQ{}) : (String & String) & Cmp}
