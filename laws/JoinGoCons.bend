import Base

# LAW: a join that starts from a piece with a char in front has the char in
# front
law join_go_cons:
  for ys: List<&2, String>
  for y: String
  for h: Char
  for +sep: String
  {String.join.go(ys, SCon{h, y}, sep) == SCon{h, String.join.go(ys, y, sep)}
    : String}
