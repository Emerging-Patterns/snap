import Base
import ./defs/CompareAnsweredEqual.bend as D1

# LAW: two strings that read as equal, whose heads compared as the given
# answer, have one head. The answer is a parameter so that the arms it did not
# take can be closed.
law eq_head.cmp:
  for +x: U32
  for +y: U32
  for t1: String
  for t2: String
  for c: Cmp
  for ec: {U32.cmp(x, y) == c : Cmp}
  for e: {D1.eq.of(String.cmp.fin(t1, t2, ((Chr{x}, Chr{y}), c)))
    == True{} : Bool}
  {Chr{x} == Chr{y} : Char}
