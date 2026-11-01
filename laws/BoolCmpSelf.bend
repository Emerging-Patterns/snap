import Base

# LAW: a bit compares equal to itself
law bool_cmp_self:
  for +b: Bool
  {Bool.cmp(b, b) == EQ{} : Cmp}
