import Base

# LAW: the separator in front of text is an empty piece in front of the
# text's pieces
law split_sep:
  for +c: Char
  for +s: String
  {String.split(SCon{c, s}, c) == SNil{} <> String.split(s, c)
    : List<&2, String>}
