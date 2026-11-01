import Base
import ./defs/CompareAnsweredEqual.bend as D1

# LAW: and tails that read as equal
law eq_tail.cmp:
  for x: U32
  for y: U32
  for +t1: String
  for +t2: String
  for c: Cmp
  for ec: {U32.cmp(x, y) == c : Cmp}
  for e: {D1.eq.of(String.cmp.fin(t1, t2, ((Chr{x}, Chr{y}), c)))
    == True{} : Bool}
  {String.eq(t1, t2) == True{} : Bool}
