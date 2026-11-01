import Base
import ./defs/CompareAnsweredEqual.bend as D1

# LAW: a string comparison read as a bit is string equality
law eq_of_cmp:
  for +a: String
  for +b: String
  {D1.eq.of(String.cmp(a, b)) == String.eq(a, b) : Bool}
