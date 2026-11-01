import Base
import ./defs/CompareAnsweredEqual.bend as D1

# LAW: a string comparison read as a bit reads only the comparison, so the
# chars it rebuilt in front do not change it
law eq_fin_rec:
  for h1: Char
  for h2: Char
  for r: (String & String) & Cmp
  {D1.eq.of(String.cmp.rec(h1, h2, r)) == D1.eq.of(r) : Bool}
