import Base

# LAW: nothing appended to a string leaves the string.
law append_nil:
  for s: String
  {String.append(s, SNil{}) == s : String}
