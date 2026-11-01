# a string comparison read as a bit: whether it answered equal
import Base

# a string comparison read as a bit: whether it answered equal. Since Base
# 2.0.38, `String.eq` is `Cmp.is_eq(String.order(a, b))`, a walk of its own
# (`String.order.go`) that no longer goes through `String.cmp`; `eq_of_cmp`
# below shows the two read the same.
def eq.of(rr: (String & String) & Cmp) -> Bool:
  Cmp.is_eq(Pair.snd(String & String, Cmp, rr))
