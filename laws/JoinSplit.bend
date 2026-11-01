import Base

# LAW: cutting a string at a char and joining the pieces back with it gives
# the string back, whatever it holds
law join_split:
  for s: String
  for +c: Char
  {String.join(String.split(s, c), SCon{c, SNil{}}) == s : String}
