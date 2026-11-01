import Base

# LAW: two code points that compare equal are one char
law u32_eq:
  for x: U32
  for y: U32
  for e: {U32.is_eq(x, y) == True{} : Bool}
  {Chr{x} == Chr{y} : Char}
