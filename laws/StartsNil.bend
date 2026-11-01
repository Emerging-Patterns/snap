import Base

# LAW: every string starts with the empty string
law starts_nil:
  for s: String
  {String.starts_with(s, "") == True{} : Bool}
