import Base

# LAW: a number compares equal to itself
law u32_cmp_self:
  for +u: U32
  {U32.cmp(u, u) == EQ{} : Cmp}
