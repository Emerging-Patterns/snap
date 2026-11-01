import Base

# LAW: two strings that compare equal are one string
law string_eq_true:
  for a: String
  for b: String
  for +e: {String.eq(a, b) == True{} : Bool}
  {a == b : String}
