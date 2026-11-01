# every string starts with the empty string
import Base
import ../../laws/StartsNil.bend as L1

# the prefix runs out first whatever the string is, so both arms answer True
def L1.starts_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}
